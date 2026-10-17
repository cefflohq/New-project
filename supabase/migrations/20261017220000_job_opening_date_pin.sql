-- Hiring form (Founder 2026-10-17): a start date and an optional map pin for
-- the pickup area. New optional parameters; existing callers keep working.
alter table public.rider_job_openings
  add column if not exists start_date date,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

drop function if exists public.save_job_opening(uuid, text, time without time zone, smallint[], rider_vehicle_type, numeric, integer, numeric, uuid, integer);
create function public.save_job_opening(p_business_id uuid, p_area_label text, p_pickup_time time without time zone, p_days smallint[], p_vehicle_type rider_vehicle_type, p_pay_per_drop numeric, p_drivers_needed integer, p_reach_km numeric default 10, p_opening_id uuid default null, p_drops_per_run integer default null, p_start_date date default null, p_latitude double precision default null, p_longitude double precision default null)
returns rider_job_openings
language plpgsql
security definer
set search_path to 'public'
as $fn$
                              declare v rider_job_openings; c countries;
                              begin
                                if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
                                  if not exists (select 1 from businesses b where b.id = p_business_id
                                                    and nullif(btrim(b.address), '') is not null
                                                                      and b.service_origin_latitude is not null
                                                                                        and b.service_origin_longitude is not null) then
                                                                                            raise exception 'business profile incomplete';
                                                                                              end if;
                                                                                                if p_pickup_time is null then raise exception 'pickup time is required'; end if;
  if p_start_date is not null and p_start_date < current_date - 1 then raise exception 'start date is in the past'; end if;
  if (p_latitude is null) <> (p_longitude is null) or (p_latitude is not null and (abs(p_latitude) > 90 or abs(p_longitude) > 180)) then raise exception 'invalid pin'; end if;
                                                                                                  select c2.* into c from businesses b join countries c2 on c2.iso2 = b.country_iso2 where b.id = p_business_id;
                                                                                                    if p_pay_per_drop is null or p_pay_per_drop < coalesce(c.min_pay_per_drop, 0.01) then
                                                                                                        raise exception 'minimum % % per drop', c.currency, coalesce(c.min_pay_per_drop, 0.01);
                                                                                                          end if;
                                                                                                            if p_pay_per_drop > coalesce(c.min_pay_per_drop, 1) * 1000 then raise exception 'pay per drop too high'; end if;
                                                                                                              if coalesce(p_reach_km, 10) not between 1 and 15 then raise exception 'driver reach must be 1-15 km'; end if;
                                                                                                                if p_drops_per_run is not null and p_drops_per_run not between 1 and 50 then raise exception 'drops per run must be 1-50'; end if;
                                                                                                                  if p_opening_id is null then
                                                                                                                      insert into rider_job_openings(business_id, area_label, shift_start, shift_end, days, vehicle_type,
                                                                                                                                                         pay_amount, pay_unit, riders_needed, radius_km, drops_per_run, start_date, latitude, longitude, created_by)
                                                                                                                                                               values (p_business_id, btrim(p_area_label), p_pickup_time, null,
                                                                                                                                                                             (select array_agg(distinct d order by d) from unnest(p_days) d), p_vehicle_type,
                                                                                                                                                                                           round(p_pay_per_drop, 2), 'drop', p_drivers_needed, coalesce(p_reach_km, 10), p_drops_per_run, p_start_date, p_latitude, p_longitude, auth.uid())
                                                                                                                                                                                                 returning * into v;
                                                                                                                                                                                                   else
                                                                                                                                                                                                       update rider_job_openings set
                                                                                                                                                                                                             area_label = btrim(p_area_label), shift_start = p_pickup_time, shift_end = null,
                                                                                                                                                                                                                   days = (select array_agg(distinct d order by d) from unnest(p_days) d),
                                                                                                                                                                                                                         vehicle_type = p_vehicle_type, pay_amount = round(p_pay_per_drop, 2), pay_unit = 'drop',
                                                                                                                                                                                                                               riders_needed = p_drivers_needed, radius_km = coalesce(p_reach_km, 10),
                                                                                                                                                                                                                                     drops_per_run = p_drops_per_run, start_date = p_start_date, latitude = p_latitude, longitude = p_longitude,
                                                                                                                                                                                                                                           status = 'open', updated_at = now()
                                                                                                                                                                                                                                               where id = p_opening_id and business_id = p_business_id
                                                                                                                                                                                                                                                   returning * into v;
                                                                                                                                                                                                                                                       if v.id is null then raise exception 'opening not found'; end if;
                                                                                                                                                                                                                                                         end if;
                                                                                                                                                                                                                                                           insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
                                                                                                                                                                                                                                                               values (p_business_id, 'rider_job.saved', auth.uid(), 'vendor', jsonb_build_object('opening_id', v.id));
                                                                                                                                                                                                                                                                 return v;
                                                                                                                                                                                                                                                                 end $fn$;
revoke all on function public.save_job_opening(uuid, text, time without time zone, smallint[], rider_vehicle_type, numeric, integer, numeric, uuid, integer, date, double precision, double precision) from public, anon;
grant execute on function public.save_job_opening(uuid, text, time without time zone, smallint[], rider_vehicle_type, numeric, integer, numeric, uuid, integer, date, double precision, double precision) to authenticated;
