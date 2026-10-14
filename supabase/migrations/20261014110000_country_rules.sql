-- Country rules (Country Pack Guideline §8 step 1, 2026-10-14): the driver
-- pay minimum per drop and the official areas follow the business country
-- instead of Malaysia-only constants. Malaysia keeps RM3.00 and its loaded
-- areas; nothing changes for Malaysian businesses.

-- 1. Minimum pay per drop, in the country's currency. Malaysia is the
-- Founder-locked RM3.00; every other value is a planning figure to confirm
-- before that country goes live.
alter table public.countries add column if not exists min_pay_per_drop numeric(12, 2);
update public.countries c set min_pay_per_drop = v.m
from (values
  ('MY', 3.00), ('BN', 1.00), ('SG', 3.00), ('ID', 8000), ('TH', 30), ('PH', 50), ('VN', 15000),
  ('KH', 4000), ('LA', 15000), ('MM', 2000), ('TL', 1.00), ('HK', 15), ('TW', 50), ('JP', 300),
  ('KR', 3000), ('IN', 30), ('GB', 3.00), ('IE', 3.00), ('DE', 3.00), ('FR', 3.00), ('NL', 3.00),
  ('BE', 3.00), ('ES', 3.00), ('PT', 2.50), ('IT', 3.00), ('PL', 12), ('SE', 35), ('DK', 25),
  ('NO', 40), ('FI', 3.00)
) as v(iso2, m)
where c.iso2 = v.iso2 and c.min_pay_per_drop is null;

-- The table-level ringgit rules move into save_job_opening (per country).
alter table public.rider_job_openings drop constraint if exists rider_job_openings_per_drop_min_check;
alter table public.rider_job_openings drop constraint if exists rider_job_openings_pay_amount_check;
alter table public.rider_job_openings alter column pay_amount type numeric(12, 2);
alter table public.rider_job_openings add constraint rider_job_openings_pay_amount_check check (pay_amount > 0);

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
declare v rider_job_openings; c countries;
begin
  if not is_business_owner(p_business_id) then raise exception 'forbidden'; end if;
  if p_pickup_time is null then raise exception 'pickup time is required'; end if;
  select c2.* into c from businesses b join countries c2 on c2.iso2 = b.country_iso2 where b.id = p_business_id;
  if p_pay_per_drop is null or p_pay_per_drop < coalesce(c.min_pay_per_drop, 0.01) then
    raise exception 'minimum % % per drop', c.currency, coalesce(c.min_pay_per_drop, 0.01);
  end if;
  if p_pay_per_drop > coalesce(c.min_pay_per_drop, 1) * 1000 then raise exception 'pay per drop too high'; end if;
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

-- 2. Official areas carry their country; zone suggestions stay inside the
-- business's country. Loaded Malaysian rows become MY.
alter table public.admin_areas
  add column if not exists country_iso2 text not null default 'MY' references public.countries(iso2);
create index if not exists admin_areas_country_idx on public.admin_areas (country_iso2);

drop function if exists public.search_admin_areas(text);
create or replace function public.search_admin_areas(p_query text, p_country text default 'MY')
returns table (id text, label text, kind text, state text)
language sql
stable
security invoker
set search_path to 'public'
as $function$
  with q as (select lower(btrim(coalesce(p_query, ''))) as t,
                    upper(btrim(coalesce(p_country, 'MY'))) as cc),
  hits as (
    select distinct on (lower(a.label), a.state)
      a.id, a.label, a.kind, a.state, (lower(a.label) like q.t || '%') as prefix
    from admin_areas a, q
    where length(q.t) >= 2
      and a.country_iso2 = q.cc
      and a.area_km2 >= 1
      and (lower(a.label) like q.t || '%' or lower(a.label) like '% ' || q.t || '%')
    order by lower(a.label), a.state,
             array_position(array['Bandar', 'Daerah', 'Pekan', 'Mukim', 'Kawasan', 'Area'], a.kind)
  )
  select id, label, kind, state from hits
  order by prefix desc, label, state
  limit 8;
$function$;

revoke all on function public.search_admin_areas(text, text) from public, anon;
grant execute on function public.search_admin_areas(text, text) to authenticated;
