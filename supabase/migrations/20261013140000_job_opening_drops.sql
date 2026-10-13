-- Find Jobs card shows drops per run instead of distance (Founder
-- 2026-10-13): the vendor gives an estimated number of drops per run when
-- posting an opening; Find Jobs returns it. Optional, 1-50; older posts
-- have none and the card then falls back to the distance.

alter table public.rider_job_openings
  add column if not exists drops_per_run integer
  check (drops_per_run is null or drops_per_run between 1 and 50);

drop function if exists public.save_job_opening(uuid, text, time, smallint[], public.rider_vehicle_type, numeric, int, numeric, uuid);

create or replace function public.save_job_opening(
  p_business_id uuid,
  p_area_label text,
  p_pickup_time time,
  p_days smallint[],
  p_vehicle_type public.rider_vehicle_type,
  p_pay_per_drop numeric,
  p_drivers_needed int,
  p_reach_km numeric default 10,
  p_opening_id uuid default null,
  p_drops_per_run int default null
)
returns public.rider_job_openings
language plpgsql security definer set search_path = public as $$
declare v rider_job_openings;
begin
  if not is_business_owner(p_business_id) then raise exception 'forbidden'; end if;
  if p_pickup_time is null then raise exception 'pickup time is required'; end if;
  if p_pay_per_drop is null or p_pay_per_drop < 3.00 then raise exception 'minimum RM3.00 per drop'; end if;
  if coalesce(p_reach_km, 10) not between 1 and 15 then raise exception 'driver reach must be 1-15 km'; end if;
  if p_drops_per_run is not null and p_drops_per_run not between 1 and 50 then raise exception 'drops per run must be 1-50'; end if;
  if p_opening_id is null then
    insert into rider_job_openings(business_id, area_label, shift_start, shift_end, days, vehicle_type,
                                   pay_amount, pay_unit, riders_needed, radius_km, drops_per_run, created_by)
      values (p_business_id, btrim(p_area_label), p_pickup_time, null,
              (select array_agg(distinct d order by d) from unnest(p_days) d), p_vehicle_type,
              round(p_pay_per_drop, 2), 'drop', p_drivers_needed, coalesce(p_reach_km, 10), p_drops_per_run, auth.uid())
      returning * into v;
  else
    update rider_job_openings set
      area_label = btrim(p_area_label), shift_start = p_pickup_time, shift_end = null,
      days = (select array_agg(distinct d order by d) from unnest(p_days) d),
      vehicle_type = p_vehicle_type, pay_amount = round(p_pay_per_drop, 2), pay_unit = 'drop',
      riders_needed = p_drivers_needed, radius_km = coalesce(p_reach_km, 10),
      drops_per_run = p_drops_per_run,
      status = 'open', updated_at = now()
    where id = p_opening_id and business_id = p_business_id
    returning * into v;
    if v.id is null then raise exception 'opening not found'; end if;
  end if;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'rider_job.saved', auth.uid(), 'vendor', jsonb_build_object('opening_id', v.id));
  return v;
end $$;

revoke all on function public.save_job_opening(uuid, text, time, smallint[], public.rider_vehicle_type, numeric, int, numeric, uuid, int) from public, anon;
grant execute on function public.save_job_opening(uuid, text, time, smallint[], public.rider_vehicle_type, numeric, int, numeric, uuid, int) to authenticated;

drop function if exists public.find_job_openings(double precision, double precision, integer);

create function public.find_job_openings(p_lat double precision, p_lng double precision, p_radius_km integer DEFAULT 20)
 RETURNS TABLE(opening_id uuid, business_name text, area_label text, distance_km numeric, within_radius boolean, radius_km numeric, shift_start time without time zone, shift_end time without time zone, days smallint[], vehicle_type rider_vehicle_type, pay_amount numeric, pay_unit text, riders_needed integer, my_status text, clash text, vehicle_match boolean, area_lat numeric, area_lng numeric, drops_per_run integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    select o.*, b.name as bname, b.service_origin_latitude, b.service_origin_longitude,
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
      -- Driver reach (Founder contract): only drivers within the post's
      -- reach see it.
      and x.dist <= x.radius_km
  )
  select x.id, x.bname, x.area_label,
    (round(x.dist * 2) / 2)::numeric,
    x.dist <= x.radius_km,
    x.radius_km, x.shift_start, x.shift_end, x.days, x.vehicle_type, x.pay_amount, x.pay_unit, x.riders_needed,
    (select r.status from rider_job_requests r
      where r.opening_id = x.id and r.auth_user_id = auth.uid() and r.status in ('pending','approved') limit 1),
    x.clash_reason,
    (v_vehicle is null or x.vehicle_type = v_vehicle),
    -- Approximate work area only (~1 km grid), never the pickup point.
    round(x.service_origin_latitude::numeric, 2),
    round(x.service_origin_longitude::numeric, 2),
    x.drops_per_run
  from ranked x
  order by (x.clash_reason is not null),
           (v_vehicle is not null and x.vehicle_type <> v_vehicle),
           x.dist, x.shift_start
  limit 100;
end $function$;

revoke all on function public.find_job_openings(double precision, double precision, integer) from public, anon;
grant execute on function public.find_job_openings(double precision, double precision, integer) to authenticated;
