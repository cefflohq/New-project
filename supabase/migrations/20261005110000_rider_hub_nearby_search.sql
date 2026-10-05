-- D-75 refinement (Founder 2026-10-05): Find Jobs is nearby-first, never a
-- nationwide feed.
-- * A search point is required: the rider's GPS position or a town they
--   chose with "Change location". It is used only to compute distance and
--   is never stored.
-- * Radius 5 / 10 / 20 / 30 / 50 km (default 20, 50 max for V1).
-- * Distance is measured from the vendor's pickup origin
--   (businesses.service_origin_*); openings without an origin are not listed.
-- * Ranking: schedule-compatible first, then vehicle-compatible (the rider's
--   own vehicle), then distance, then start time.
-- * Results stay a safe projection: business name, area label, rounded
--   distance, shift, pay, vehicle. Never an address, phone or coordinates.

drop function if exists public.find_job_openings(double precision, double precision);

create or replace function public.find_job_openings(
  p_lat double precision,
  p_lng double precision,
  p_radius_km int default 20
)
returns table (
  opening_id uuid, business_name text, area_label text, distance_km numeric, within_radius boolean,
  radius_km numeric, shift_start time, shift_end time, days smallint[], vehicle_type public.rider_vehicle_type,
  pay_amount numeric, pay_unit text, riders_needed int, my_status text, clash text, vehicle_match boolean
)
language plpgsql stable security definer set search_path = public as $$
declare v_vehicle public.rider_vehicle_type;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'location required';
  end if;
  if p_radius_km is null or p_radius_km not in (5, 10, 20, 30, 50) then
    raise exception 'radius must be 5, 10, 20, 30 or 50 km';
  end if;

  -- The rider's own vehicle: latest relationship, else Driver registration.
  select coalesce(
    (select r.vehicle_type from riders r where r.auth_user_id = auth.uid() and r.vehicle_type is not null
       order by r.updated_at desc limit 1),
    (select case when u.raw_user_meta_data -> 'driver_registration' ->> 'vehicle_type' in ('motorcycle','car','van')
       then (u.raw_user_meta_data -> 'driver_registration' ->> 'vehicle_type')::public.rider_vehicle_type end
       from auth.users u where u.id = auth.uid()))
  into v_vehicle;

  return query
  with base as (
    select o.*, b.name as bname,
      2 * 6371 * asin(sqrt(
        power(sin(radians(b.service_origin_latitude - p_lat) / 2), 2) +
        cos(radians(p_lat)) * cos(radians(b.service_origin_latitude)) *
        power(sin(radians(b.service_origin_longitude - p_lng) / 2), 2))) as dist
    from rider_job_openings o join businesses b on b.id = o.business_id
    where o.status = 'open'
      and b.service_origin_latitude is not null and b.service_origin_longitude is not null
      -- cheap bounding box before the exact distance
      and b.service_origin_latitude between p_lat - p_radius_km / 111.0 and p_lat + p_radius_km / 111.0
  ), ranked as (
    select x.*, _rider_job_clash(auth.uid(), x.id) as clash_reason
    from base x
    where x.dist <= p_radius_km
  )
  select x.id, x.bname, x.area_label,
    (round(x.dist * 2) / 2)::numeric,
    x.dist <= x.radius_km,
    x.radius_km, x.shift_start, x.shift_end, x.days, x.vehicle_type, x.pay_amount, x.pay_unit, x.riders_needed,
    (select r.status from rider_job_requests r
      where r.opening_id = x.id and r.auth_user_id = auth.uid() and r.status in ('pending','approved') limit 1),
    x.clash_reason,
    (v_vehicle is null or x.vehicle_type = v_vehicle)
  from ranked x
  order by (x.clash_reason is not null),
           (v_vehicle is not null and x.vehicle_type <> v_vehicle),
           x.dist, x.shift_start
  limit 100;
end $$;

revoke all on function public.find_job_openings(double precision, double precision, int) from public, anon;
grant execute on function public.find_job_openings(double precision, double precision, int) to authenticated;
