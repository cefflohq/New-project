-- S4-11 Batch 2 (Grow V1 Flow 2, A2): real service-coverage decision.
--
-- Flow 1 finding (audit report §3/§7): the only "coverage" logic that has
-- ever existed reads `zone.coverageRadiusKm`, a property that does not
-- exist on the real `zones` table (vendor/index.html:7937-7947) -- a
-- frontend-only mock. `zones` itself is a deliberate, Founder-confirmed
-- manual label with "no geospatial data, no polygons, no lat/lng, no
-- automatic detection" (its own S4-06 migration comment) -- that design is
-- NOT reopened here. Coverage is a genuinely separate concept: a real,
-- backend-computed decision of whether an order's resolved location falls
-- inside the business's own service area, independent of the Zone label.
--
-- Simplest reliable V1 model: one circular service area per business
-- (origin + radius). Bounded, deterministic, no polygon/GIS extension
-- required -- matches "simplest reliable V1 model consistent with frozen
-- scope/current architecture" (Master MD §8). A business that has not
-- configured a service area is 'unconfigured' (never silently blocking);
-- once configured, every located order gets a real covered/out_of_coverage
-- verdict, visible to the Vendor as an operational exception (not a hard
-- backend dispatch block -- see build_rider_run in the next batch, which
-- blocks only on vehicle/capacity, per the Founder-locked distinction
-- between those two exception classes in the frozen scope).

alter table public.businesses
  add column service_origin_latitude double precision,
  add column service_origin_longitude double precision,
  add column service_coverage_radius_km numeric check (service_coverage_radius_km is null or service_coverage_radius_km > 0);

-- Owner or Operator (any active business member, matching update_business_profile's
-- existing precedent for business-level configuration) may set the service area.
create function public.set_business_service_area(
  p_business_id uuid,
  p_origin_latitude double precision,
  p_origin_longitude double precision,
  p_radius_km numeric
) returns public.businesses
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.businesses;
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_origin_latitude is null or p_origin_longitude is null or p_radius_km is null then
    raise exception 'origin and radius are all required to configure a service area';
  end if;
  if p_radius_km <= 0 then
    raise exception 'radius must be positive';
  end if;

  update public.businesses set
    service_origin_latitude = p_origin_latitude,
    service_origin_longitude = p_origin_longitude,
    service_coverage_radius_km = p_radius_km,
    updated_at = now()
  where id = p_business_id
  returning * into b;

  -- No delivery_events row here by design: that table is order-scoped
  -- (order_id is NOT NULL) throughout this schema, and a business-level
  -- settings change has no natural order to attach to -- forcing one would
  -- fabricate a fake order reference. The updated_at bump above is the
  -- change record for this action.

  return b;
end;
$$;

revoke all on function public.set_business_service_area(uuid, double precision, double precision, numeric) from public, anon, authenticated;
grant execute on function public.set_business_service_area(uuid, double precision, double precision, numeric) to authenticated;

-- Haversine great-circle distance in km. STABLE, pure math, no table access
-- -- reusable by coverage, ETA (A5) and the optimizer (A4) alike so all
-- three use one identical distance definition, never three slightly
-- different ones.
create function public.haversine_km(
  p_lat1 double precision, p_lng1 double precision,
  p_lat2 double precision, p_lng2 double precision
) returns double precision
language sql immutable
as $$
select 6371 * 2 * asin(sqrt(
  sin(radians(p_lat2 - p_lat1) / 2) ^ 2 +
  cos(radians(p_lat1)) * cos(radians(p_lat2)) * sin(radians(p_lng2 - p_lng1) / 2) ^ 2
))
$$;

-- Real coverage verdict for one order, computed live (not stored/trigger-
-- maintained -- keeps the write paths from A1/create_delivery untouched and
-- avoids a second place coverage truth could drift from the location it's
-- based on). STABLE + SECURITY DEFINER + tenant-scoped: callable by any
-- business member for their own orders only.
create function public.order_coverage_status(p_order_id uuid) returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  o public.orders;
  b public.businesses;
  d double precision;
begin
  select * into o from public.orders where id = p_order_id;
  if o.id is null or not is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;
  select * into b from public.businesses where id = o.business_id;

  if b.service_coverage_radius_km is null then
    return 'unconfigured';
  end if;
  if o.location_status <> 'resolved' then
    return 'pending_location';
  end if;

  d := haversine_km(b.service_origin_latitude, b.service_origin_longitude, o.latitude, o.longitude);
  if d <= b.service_coverage_radius_km then
    return 'covered';
  end if;
  return 'out_of_coverage';
end;
$$;

revoke all on function public.order_coverage_status(uuid) from public, anon;
grant execute on function public.order_coverage_status(uuid) to authenticated;

-- Batch planning-eligibility view used by both the Vendor run-builder UI and
-- the A4 optimizer proposal RPC -- one shared definition of "what does this
-- business's un-dispatched order book currently look like," so the UI and
-- the optimizer can never see two different realities.
create function public.list_plannable_orders(p_business_id uuid) returns table(
  order_id uuid,
  public_ref text,
  customer_name text,
  delivery_address text,
  latitude double precision,
  longitude double precision,
  location_status public.order_location_status,
  coverage_status text,
  zone_id uuid,
  approved_at timestamptz,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  return query
    select o.id, o.public_ref, o.customer_name, o.delivery_address, o.latitude, o.longitude,
           o.location_status, order_coverage_status(o.id), o.zone_id, o.approved_at, o.created_at
    from public.orders o
    where o.business_id = p_business_id
      and o.delivery_status = 'created'
      and o.approved_at is not null
      and o.assigned_rider_id is null
    order by o.created_at asc;
end;
$$;

revoke all on function public.list_plannable_orders(uuid) from public, anon;
grant execute on function public.list_plannable_orders(uuid) to authenticated;
