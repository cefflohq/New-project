-- CEFFLO Flow 2 Canonical Backend Completion Master, F2-08: Rider Location
-- Backend Contract. rider_locations (table + RLS) already exists from the
-- foundation migration and was correctly updated to the multi-business
-- is_current_rider() identity model in S4-07 Batch 3a -- reused, not
-- rebuilt. Two real gaps found by inspection, closed here:
--
-- 1. The existing INSERT policy (`with check (is_current_rider(rider_id))`)
--    validates rider identity but never validates that the row's own
--    business_id actually matches that Rider's real business -- an
--    authenticated Rider client could insert a row with a spoofed
--    business_id for a DIFFERENT tenant while still passing rider_id
--    identity. Tightened below to check both.
-- 2. No RPC existed at all -- callers had to know and correctly supply
--    business_id themselves via a raw PostgREST insert, the one place in
--    this schema that broke from the "RPC is the sole mutation path"
--    convention every other table follows. record_rider_location below
--    derives business_id server-side from the Rider's own row (never
--    client-supplied) and becomes the documented, tested write path for
--    Flow 5's real Rider Flutter GPS writes -- this migration does not
--    implement background GPS itself (explicitly Flow 5's job), only
--    makes the backend ready for it.

drop policy if exists locations_rider on public.rider_locations;
create policy locations_rider on public.rider_locations for insert
  with check (
    is_current_rider(rider_id)
    and business_id = (select r.business_id from riders r where r.id = rider_id)
  );

-- Reject anonymous writes explicitly, defense-in-depth on top of RLS
-- (is_current_rider() already resolves to false for a null auth.uid()) --
-- the RPC's own forbidden-check below is the primary guard callers
-- actually exercise.
create function public.record_rider_location(
  p_rider_id uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_accuracy double precision default null,
  p_heading double precision default null,
  p_speed double precision default null
) returns public.rider_locations
language plpgsql
security definer
set search_path = public
as $$
declare
  r riders;
  active_assignment_id uuid;
  row_out rider_locations;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'forbidden';
  end if;
  if p_latitude is null or p_longitude is null then
    raise exception 'coordinates required';
  end if;
  if p_latitude < -90 or p_latitude > 90 or p_longitude < -180 or p_longitude > 180 then
    raise exception 'coordinates out of range';
  end if;

  select * into r from riders where id = p_rider_id and status = 'active';
  if r.id is null then
    raise exception 'forbidden';
  end if;

  -- Best-effort association with the Rider's current active run, if any --
  -- purely contextual (lets a later read join straight to the relevant
  -- assignment); a location write is never blocked by having no active
  -- assignment (a Rider may be online between runs).
  select a.id into active_assignment_id
    from rider_assignments a
    where a.rider_id = p_rider_id
      and a.status not in ('completed', 'cancelled', 'declined')
    order by a.assigned_at desc
    limit 1;

  insert into rider_locations(business_id, rider_id, assignment_id, latitude, longitude, accuracy, heading, speed)
    values (r.business_id, p_rider_id, active_assignment_id, p_latitude, p_longitude, p_accuracy, p_heading, p_speed)
    returning * into row_out;

  return row_out;
end;
$$;

revoke all on function public.record_rider_location(uuid, double precision, double precision, double precision, double precision, double precision) from public, anon;
grant execute on function public.record_rider_location(uuid, double precision, double precision, double precision, double precision, double precision) to authenticated;

-- Tenant-safe read for the Vendor's own "latest known location" use case
-- (e.g. a future Live Ops map) -- the most recent row per Rider, scoped to
-- the caller's own business via the existing locations_vendor SELECT
-- policy (is_business_member(business_id), untouched by this migration).
create function public.latest_rider_locations(p_business_id uuid) returns table(
  rider_id uuid,
  latitude double precision,
  longitude double precision,
  accuracy double precision,
  recorded_at timestamptz
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
    select distinct on (l.rider_id) l.rider_id, l.latitude, l.longitude, l.accuracy, l.recorded_at
    from rider_locations l
    where l.business_id = p_business_id
    order by l.rider_id, l.recorded_at desc;
end;
$$;

revoke all on function public.latest_rider_locations(uuid) from public, anon;
grant execute on function public.latest_rider_locations(uuid) to authenticated;
