-- S4-11 Batch 1 (Grow V1 Flow 2, A1): canonical geocoding contract.
--
-- Flow 1 finding (CEFFLO_GROW_V1_SCOPE_LOCK_AUDIT_REPORT.md §2/§3/§7): orders
-- already carry latitude/longitude, but nothing in this schema's history has
-- ever populated them -- no geocoding call exists anywhere in the codebase.
-- This migration adds the missing resolution-state contract only: it never
-- invents coordinates, and it does not perform geocoding itself (Postgres
-- has no outbound HTTP access here) -- an external worker/Edge Function
-- calls the service-role-only RPC below with a real result.
--
-- One location contract for every intake path (Manual, Storefront, CSV/XLSX
-- import, S4-11 Batch 5) -- all three write orders.latitude/longitude and
-- location_status identically; none gets a parallel/competing location model.

create type public.order_location_status as enum (
  'unresolved',   -- default: address captured, no coordinate resolution attempted/succeeded yet
  'resolved',      -- latitude/longitude are trustworthy for planning
  'ambiguous',     -- provider returned multiple plausible matches; needs human correction
  'failed'         -- provider attempted and could not resolve; needs human correction
);

alter table public.orders
  add column location_status public.order_location_status not null default 'unresolved',
  add column location_provider text,
  add column location_resolved_at timestamptz,
  add column location_error text;

create index orders_location_status_idx on public.orders(business_id, location_status);

-- Existing rows: latitude/longitude have always been nullable and nothing
-- has ever set them, so every existing order is genuinely 'unresolved' --
-- the default already reflects real truth; no backfill UPDATE is needed
-- or safe to fabricate.

-- Service-role-only write path for the automated geocoding worker (an Edge
-- Function using the service-role key, never the anon/authenticated client
-- keys). Centralizing the write here -- instead of letting the worker issue
-- a raw UPDATE -- keeps the resolution contract auditable and enum-checked
-- in one place, matching this project's existing "RPC is the only mutation
-- path" convention (05_DECISIONS.md / every prior migration).
--
-- Never invent coordinates: p_status='resolved' requires both coordinates;
-- 'ambiguous'/'failed' must NOT carry coordinates (the whole point of those
-- states is "do not trust any single candidate"); 'unresolved' is the
-- pre-attempt default and is not a valid target for this RPC (nothing should
-- ever explicitly regress an order back to "not yet attempted").
create function public.set_order_location(
  p_order_id uuid,
  p_status public.order_location_status,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_provider text default null,
  p_error text default null
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
begin
  if p_status = 'unresolved' then
    raise exception 'unresolved is the default pre-attempt state, not a settable result';
  end if;
  if p_status = 'resolved' and (p_latitude is null or p_longitude is null) then
    raise exception 'resolved requires both coordinates';
  end if;
  if p_status in ('ambiguous','failed') and (p_latitude is not null or p_longitude is not null) then
    raise exception '% must not carry coordinates', p_status;
  end if;

  select * into o from public.orders where id = p_order_id for update;
  if o.id is null then
    raise exception 'order not found';
  end if;

  update public.orders set
    location_status = p_status,
    latitude = case when p_status = 'resolved' then p_latitude else null end,
    longitude = case when p_status = 'resolved' then p_longitude else null end,
    location_provider = p_provider,
    location_resolved_at = now(),
    location_error = p_error,
    updated_at = now()
  where id = p_order_id
  returning * into o;

  insert into delivery_events(business_id, order_id, event_type, actor_role, metadata)
    values (o.business_id, o.id, 'order.location_resolved', 'system',
            jsonb_build_object('status', p_status, 'provider', p_provider, 'error', p_error));

  return o;
end;
$$;

revoke all on function public.set_order_location(uuid, public.order_location_status, double precision, double precision, text, text) from public, anon, authenticated;
grant execute on function public.set_order_location(uuid, public.order_location_status, double precision, double precision, text, text) to service_role;

-- Vendor-facing manual correction path -- required by the Task Master
-- ("provenance/error information sufficient for operational correction"):
-- a business member can pin/fix a location by hand when the automated
-- worker fails or gets it wrong. Distinct from the service-role RPC above
-- so this one is tenant-scoped and always provider='manual_correction'.
create function public.set_order_location_manual(
  p_order_id uuid,
  p_latitude double precision,
  p_longitude double precision
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
begin
  if p_latitude is null or p_longitude is null then
    raise exception 'both coordinates required';
  end if;
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;

  update public.orders set
    location_status = 'resolved',
    latitude = p_latitude,
    longitude = p_longitude,
    location_provider = 'manual_correction',
    location_resolved_at = now(),
    location_error = null,
    updated_at = now()
  where id = p_order_id
  returning * into o;

  insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role, metadata)
    values (o.business_id, o.id, 'order.location_resolved', auth.uid(), 'vendor',
            jsonb_build_object('status', 'resolved', 'provider', 'manual_correction'));

  return o;
end;
$$;

revoke all on function public.set_order_location_manual(uuid, double precision, double precision) from public, anon;
grant execute on function public.set_order_location_manual(uuid, double precision, double precision) to authenticated;
