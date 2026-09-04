-- CEFFLO Flow 2 Canonical Backend Completion Master, D-03: "Use nullable
-- integer max_active_orders. No kg/volume/dimension model." Repo truth
-- (S4-11 Batch 3) already built exactly this concept -- a nullable
-- per-Rider integer capacity override, falling back to a vehicle-type
-- default when null -- under the name `capacity_override`. Renaming to
-- the Founder-locked canonical field name only; the underlying nullable-
-- integer, vehicle-default-fallback semantics are unchanged and preserved
-- exactly (this Master's own instruction: "repo truth wins for exact
-- implementation details; Founder-locked product behaviour... wins for
-- product behaviour" -- the locked behaviour here is the field's public
-- name/type, not a mandate to drop the existing default-tiering logic).
--
-- Null semantics (documented once, referenced everywhere else): NULL
-- means "no Vendor-set override for this Rider -- use
-- default_capacity_for_vehicle(vehicle_type)." A non-null value is an
-- explicit per-Rider ceiling that always wins over the vehicle default.

alter table public.riders rename column capacity_override to max_active_orders;

-- rider_effective_capacity: same body, new column reference.
create or replace function public.rider_effective_capacity(p_rider_id uuid) returns integer
language sql stable
security definer
set search_path = public
as $$
select coalesce(r.max_active_orders, default_capacity_for_vehicle(r.vehicle_type))
from riders r where r.id = p_rider_id
$$;

-- update_rider_details: parameter renamed to match. Type list is
-- unchanged (uuid,text,text,text,rider_vehicle_type,integer) but Postgres
-- still refuses to rename a parameter via CREATE OR REPLACE -- drop first,
-- matching this codebase's own established convention for that exact
-- situation.
drop function if exists public.update_rider_details(uuid,text,text,text,public.rider_vehicle_type,integer);

create function public.update_rider_details(
  p_rider_id uuid,
  p_name text default null,
  p_phone text default null,
  p_vehicle_plate text default null,
  p_vehicle_type public.rider_vehicle_type default null,
  p_max_active_orders integer default null
) returns public.riders
language plpgsql security definer set search_path = public
as $$
declare
  r public.riders;
begin
  select * into r from public.riders where id = p_rider_id for update;
  if r.id is null or not public.is_business_operational(r.business_id) then
    raise exception 'forbidden';
  end if;
  if p_max_active_orders is not null and p_max_active_orders <= 0 then
    raise exception 'max_active_orders must be positive';
  end if;
  update public.riders set
    name = coalesce(p_name, name),
    phone = coalesce(p_phone, phone),
    vehicle_plate = coalesce(p_vehicle_plate, vehicle_plate),
    vehicle_type = coalesce(p_vehicle_type, vehicle_type),
    max_active_orders = case when p_max_active_orders is not null then p_max_active_orders else max_active_orders end,
    updated_at = now()
  where id = p_rider_id
  returning * into r;
  return r;
end;
$$;

revoke all on function public.update_rider_details(uuid,text,text,text,public.rider_vehicle_type,integer) from public, anon, authenticated;
grant execute on function public.update_rider_details(uuid,text,text,text,public.rider_vehicle_type,integer) to authenticated;
