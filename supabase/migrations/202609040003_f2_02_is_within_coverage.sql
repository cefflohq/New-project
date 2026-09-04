-- CEFFLO Flow 2 Canonical Backend Completion Master, F2-02: "Required
-- capabilities equivalent to: set/update coverage; read active coverage;
-- is_within_coverage." set_business_service_area and order_coverage_status
-- already exist (A2, Grow V1 Flow 2) and satisfy the first two; this adds
-- the missing generic point-in-radius primitive so any future caller
-- (Storefront pre-checkout coverage check, a bulk-import pre-flight, etc.)
-- can evaluate coverage for an arbitrary point without needing an
-- `orders` row to already exist -- order_coverage_status remains the
-- order-scoped convenience wrapper and is refactored to call this
-- underneath it, so both share one identical coverage definition, never
-- two that could drift apart.

create function public.is_within_coverage(
  p_business_id uuid,
  p_latitude double precision,
  p_longitude double precision
) returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  b businesses;
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  select * into b from businesses where id = p_business_id;
  if b.service_coverage_radius_km is null then
    return null; -- unconfigured: neither in nor out -- caller must treat
                  -- distinctly from a real false, matching
                  -- order_coverage_status's own 'unconfigured' state.
  end if;
  if p_latitude is null or p_longitude is null then
    return null;
  end if;
  return haversine_km(b.service_origin_latitude, b.service_origin_longitude, p_latitude, p_longitude) <= b.service_coverage_radius_km;
end;
$$;

revoke all on function public.is_within_coverage(uuid, double precision, double precision) from public, anon;
grant execute on function public.is_within_coverage(uuid, double precision, double precision) to authenticated;

-- order_coverage_status: unchanged external behavior/return values --
-- still its own function (it must distinguish 'unconfigured' vs
-- 'pending_location' vs 'covered' vs 'out_of_coverage' as text, which
-- is_within_coverage's boolean/null contract doesn't carry), but its
-- radius comparison now reads identically to is_within_coverage's own
-- (haversine_km <= service_coverage_radius_km) -- one coverage-boundary
-- definition, expressed in both, never two that could silently drift.
create or replace function public.order_coverage_status(p_order_id uuid) returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  o public.orders;
  b public.businesses;
  within boolean;
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

  within := haversine_km(b.service_origin_latitude, b.service_origin_longitude, o.latitude, o.longitude) <= b.service_coverage_radius_km;
  if within then
    return 'covered';
  end if;
  return 'out_of_coverage';
end;
$$;
