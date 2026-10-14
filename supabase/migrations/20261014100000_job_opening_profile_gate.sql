-- Hiring posts require a complete Business profile (Founder 2026-10-14):
-- the business address and the pickup location (service origin) must be set
-- before save_job_opening creates, edits or reopens a post. Find Jobs places
-- posts by the pickup location, so a post without it was invisible to
-- drivers with no feedback to the vendor.

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
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  -- Founder 2026-10-14: a hiring post needs a complete Business profile
  -- (address and pickup location). Without the pickup pin the post can never
  -- appear in Find Jobs, so it is refused instead of silently hidden.
  if not exists (select 1 from businesses b where b.id = p_business_id
                  and nullif(btrim(b.address), '') is not null
                  and b.service_origin_latitude is not null
                  and b.service_origin_longitude is not null) then
    raise exception 'business profile incomplete';
  end if;
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
