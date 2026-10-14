-- Cefflo staging bundle 2026-10-14: run once in Supabase SQL Editor (cefflo-staging).
begin;

-- ===== supabase/migrations/20261014150000_country_foundation.sql
-- International country foundation (Country Pack Guideline §3, 2026-10-14).
-- Reference table of country packs plus the country on businesses and
-- profiles. Malaysia is the only live country; every other pack is a ready
-- blueprint (status 'planned') that is switched on by changing its status.
-- No Malaysian behaviour changes: existing businesses become MY, which
-- matches their current MYR currency and Asia/Kuala_Lumpur timezone.

create table if not exists public.countries (
  iso2 text primary key check (iso2 ~ '^[A-Z]{2}$'),
  iso3 text not null unique check (iso3 ~ '^[A-Z]{3}$'),
  region text not null check (region in ('asia', 'europe', 'middle_east', 'oceania', 'americas', 'africa')),
  status text not null default 'planned' check (status in ('live', 'beta', 'planned')),
  name_en text not null,
  name_local text not null,
  -- BCP 47 tags. English is always available; the rest are the country's
  -- own languages in display order.
  languages text[] not null default '{en}',
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  currency_decimals smallint not null check (currency_decimals between 0 and 3),
  -- Cefflo's own subscription price book: MYR in Malaysia, USD elsewhere.
  subscription_currency text not null default 'USD' check (subscription_currency ~ '^[A-Z]{3}$'),
  phone_code text not null check (phone_code ~ '^\+[0-9]{1,4}$'),
  timezones text[] not null check (cardinality(timezones) >= 1),
  -- Case-insensitive; null = the country has no postcodes.
  postcode_regex text,
  maps_provider text not null default 'google' check (maps_provider in ('google', 'naver', 'kakao')),
  sort_order smallint not null default 100
);

alter table public.countries enable row level security;
drop policy if exists countries_public_read on public.countries;
-- Public reference data: the first-launch picker reads it before sign-in.
create policy countries_public_read on public.countries for select to anon, authenticated using (true);
revoke all on public.countries from public, anon, authenticated;
grant select on public.countries to anon, authenticated;

insert into public.countries
  (iso2, iso3, region, status, name_en, name_local, languages, currency, currency_decimals, subscription_currency, phone_code, timezones, postcode_regex, maps_provider, sort_order)
values
  -- ASEAN
  ('MY','MYS','asia','live','Malaysia','Malaysia','{en,ms,zh-Hans,ta}','MYR',2,'MYR','+60','{Asia/Kuala_Lumpur}','^\d{5}$','google',1),
  ('BN','BRN','asia','planned','Brunei','Brunei','{en,ms}','BND',2,'USD','+673','{Asia/Brunei}','^[A-Z]{2}\d{4}$','google',10),
  ('SG','SGP','asia','planned','Singapore','Singapore','{en,zh-Hans,ms,ta}','SGD',2,'USD','+65','{Asia/Singapore}','^\d{6}$','google',11),
  ('ID','IDN','asia','planned','Indonesia','Indonesia','{en,id}','IDR',0,'USD','+62','{Asia/Jakarta,Asia/Makassar,Asia/Jayapura}','^\d{5}$','google',12),
  ('TH','THA','asia','planned','Thailand','ประเทศไทย','{en,th}','THB',2,'USD','+66','{Asia/Bangkok}','^\d{5}$','google',13),
  ('PH','PHL','asia','planned','Philippines','Pilipinas','{en,fil}','PHP',2,'USD','+63','{Asia/Manila}','^\d{4}$','google',14),
  ('VN','VNM','asia','planned','Vietnam','Việt Nam','{en,vi}','VND',0,'USD','+84','{Asia/Ho_Chi_Minh}','^\d{6}$','google',15),
  ('KH','KHM','asia','planned','Cambodia','កម្ពុជា','{en,km}','KHR',0,'USD','+855','{Asia/Phnom_Penh}','^\d{5,6}$','google',16),
  ('LA','LAO','asia','planned','Laos','ລາວ','{en,lo}','LAK',0,'USD','+856','{Asia/Vientiane}','^\d{5}$','google',17),
  ('MM','MMR','asia','planned','Myanmar','မြန်မာ','{en,my}','MMK',0,'USD','+95','{Asia/Yangon}','^\d{5}$','google',18),
  ('TL','TLS','asia','planned','Timor-Leste','Timor-Leste','{en,tet,pt}','USD',2,'USD','+670','{Asia/Dili}',null,'google',19),
  -- East & South Asia
  ('HK','HKG','asia','planned','Hong Kong','香港','{en,zh-Hant-HK}','HKD',2,'USD','+852','{Asia/Hong_Kong}',null,'google',30),
  ('TW','TWN','asia','planned','Taiwan','臺灣','{en,zh-Hant}','TWD',0,'USD','+886','{Asia/Taipei}','^\d{3}(\d{2,3})?$','google',31),
  ('JP','JPN','asia','planned','Japan','日本','{en,ja}','JPY',0,'USD','+81','{Asia/Tokyo}','^\d{3}-?\d{4}$','google',32),
  ('KR','KOR','asia','planned','South Korea','대한민국','{en,ko}','KRW',0,'USD','+82','{Asia/Seoul}','^\d{5}$','naver',33),
  ('IN','IND','asia','planned','India','भारत','{en,hi,ta,te,bn,mr,kn,ml,gu,pa}','INR',2,'USD','+91','{Asia/Kolkata}','^\d{6}$','google',34),
  -- Europe
  ('GB','GBR','europe','planned','United Kingdom','United Kingdom','{en}','GBP',2,'USD','+44','{Europe/London}','^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$','google',50),
  ('IE','IRL','europe','planned','Ireland','Éire','{en,ga}','EUR',2,'USD','+353','{Europe/Dublin}','^[A-Z]\d[\dW] ?[A-Z\d]{4}$','google',51),
  ('DE','DEU','europe','planned','Germany','Deutschland','{en,de}','EUR',2,'USD','+49','{Europe/Berlin}','^\d{5}$','google',52),
  ('FR','FRA','europe','planned','France','France','{en,fr}','EUR',2,'USD','+33','{Europe/Paris}','^\d{5}$','google',53),
  ('NL','NLD','europe','planned','Netherlands','Nederland','{en,nl}','EUR',2,'USD','+31','{Europe/Amsterdam}','^\d{4} ?[A-Z]{2}$','google',54),
  ('BE','BEL','europe','planned','Belgium','België / Belgique','{en,nl,fr,de}','EUR',2,'USD','+32','{Europe/Brussels}','^\d{4}$','google',55),
  ('ES','ESP','europe','planned','Spain','España','{en,es,ca}','EUR',2,'USD','+34','{Europe/Madrid}','^\d{5}$','google',56),
  ('PT','PRT','europe','planned','Portugal','Portugal','{en,pt}','EUR',2,'USD','+351','{Europe/Lisbon}','^\d{4}-\d{3}$','google',57),
  ('IT','ITA','europe','planned','Italy','Italia','{en,it}','EUR',2,'USD','+39','{Europe/Rome}','^\d{5}$','google',58),
  ('PL','POL','europe','planned','Poland','Polska','{en,pl}','PLN',2,'USD','+48','{Europe/Warsaw}','^\d{2}-\d{3}$','google',59),
  ('SE','SWE','europe','planned','Sweden','Sverige','{en,sv}','SEK',2,'USD','+46','{Europe/Stockholm}','^\d{3} ?\d{2}$','google',60),
  ('DK','DNK','europe','planned','Denmark','Danmark','{en,da}','DKK',2,'USD','+45','{Europe/Copenhagen}','^\d{4}$','google',61),
  ('NO','NOR','europe','planned','Norway','Norge','{en,nb}','NOK',2,'USD','+47','{Europe/Oslo}','^\d{4}$','google',62),
  ('FI','FIN','europe','planned','Finland','Suomi','{en,fi,sv}','EUR',2,'USD','+358','{Europe/Helsinki}','^\d{5}$','google',63)
on conflict (iso2) do nothing;

-- Country on the business (drives currency, timezone, phone prefix, postcode
-- rule, admin areas, payments) and on the profile (drivers).
alter table public.businesses
  add column if not exists country_iso2 text not null default 'MY' references public.countries(iso2);
alter table public.profiles
  add column if not exists country_iso2 text references public.countries(iso2);

-- Owner sets the business country while the business has no orders yet;
-- afterwards a change goes through Cefflo support (FOUNDR).
create or replace function public.set_business_country(p_business_id uuid, p_iso2 text)
returns public.businesses
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.businesses;
  c public.countries;
begin
  if not is_business_owner(p_business_id) then
    raise exception 'forbidden';
  end if;
  select * into c from public.countries where iso2 = upper(btrim(coalesce(p_iso2, '')));
  if c.iso2 is null or c.status = 'planned' then
    raise exception 'country not available';
  end if;
  select * into b from public.businesses where id = p_business_id for update;
  if b.country_iso2 = c.iso2 then
    return b;
  end if;
  if exists (select 1 from public.orders o where o.business_id = p_business_id) then
    raise exception 'country locked: contact Cefflo support';
  end if;
  update public.businesses
     set country_iso2 = c.iso2, currency = c.currency, timezone = c.timezones[1], updated_at = now()
   where id = p_business_id
  returning * into b;
  insert into public.business_profile_audit(business_id, actor_user_id, changed_fields, request_id)
  values (p_business_id, auth.uid(), array['country_iso2', 'currency', 'timezone'], null);
  return b;
end;
$$;

revoke all on function public.set_business_country(uuid, text) from public, anon;
grant execute on function public.set_business_country(uuid, text) to authenticated;

-- Profile country (drivers and users). Only selectable countries.
create or replace function public.set_my_country(p_iso2 text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  c public.countries;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  select * into c from public.countries where iso2 = upper(btrim(coalesce(p_iso2, '')));
  if c.iso2 is null or c.status = 'planned' then
    raise exception 'country not available';
  end if;
  insert into public.profiles(id, country_iso2) values (auth.uid(), c.iso2)
  on conflict (id) do update set country_iso2 = excluded.country_iso2, updated_at = now();
  return c.iso2;
end;
$$;

revoke all on function public.set_my_country(text) from public, anon;
grant execute on function public.set_my_country(text) to authenticated;

-- Storefront payload carries the business currency so customer prices are
-- formatted correctly outside Malaysia (body unchanged otherwise).
create or replace function public._storefront_payload(page public_order_pages)
 returns jsonb
 language sql
 stable security definer
 set search_path to 'public', 'extensions'
as $function$
  select jsonb_build_object(
    'slug', page.slug,
    'template_key', page.template_key,
    'theme', page.theme - 'hero_path' - 'logo_path',
    'hero_url', case when page.theme ? 'hero_path'
      then '/storage/v1/object/public/cefflo-storefront-assets/' || (page.theme->>'hero_path') end,
    'logo_url', case when page.theme ? 'logo_path'
      then '/storage/v1/object/public/cefflo-storefront-assets/' || (page.theme->>'logo_path') end,
    'business', jsonb_build_object('name', b.name, 'area', nullif(trim(b.operating_area), ''),
      'currency', b.currency, 'country', b.country_iso2),
    'hours', (select jsonb_agg(jsonb_build_object('weekday', h.weekday, 'is_open', h.is_open,
        'opens_at', to_char(h.opens_at, 'HH24:MI'), 'closes_at', to_char(h.closes_at, 'HH24:MI')) order by h.weekday)
      from business_hours h where h.business_id = page.business_id),
    'open_now', case when exists (select 1 from business_hours h where h.business_id = page.business_id)
      then business_open_now(page.business_id) end,
    'next_open', _business_next_open(page.business_id),
    'categories', coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'name', c.name) order by c.sort_order, c.id)
        from product_categories c where c.business_id = page.business_id and c.archived_at is null), '[]'::jsonb),
    'products', coalesce((select jsonb_agg(jsonb_build_object(
        'id', p.id, 'category_id', p.category_id, 'name', p.name,
        'description', p.description, 'display_price', p.display_price,
        'images', coalesce((select jsonb_agg('/storage/v1/object/public/cefflo-product-display/' || pm.prepared_storage_path
            order by pm.position nulls last, pm.approved_at)
          from product_media pm
          where pm.product_id = p.id and pm.status = 'approved' and pm.archived_at is null), '[]'::jsonb)
      ) order by p.sort_order, p.id)
      from products p where p.business_id = page.business_id and p.status = 'active' and p.archived_at is null), '[]'::jsonb)
  ) from businesses b where b.id = page.business_id
$function$;

-- ===== supabase/migrations/20261014160000_country_rules.sql
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
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  -- Founder 2026-10-14 (job_opening_profile_gate): a hiring post needs a
  -- complete Business profile (address and pickup location).
  if not exists (select 1 from businesses b where b.id = p_business_id
                  and nullif(btrim(b.address), '') is not null
                  and b.service_origin_latitude is not null
                  and b.service_origin_longitude is not null) then
    raise exception 'business profile incomplete';
  end if;
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

-- ===== supabase/migrations/20261014170000_auto_zone_assignment.sql
-- Auto zone assignment + hexagon zone cells (Auto Zone master guideline
-- Part A §3.1, Founder decisions D1/D4, 2026-10-14).
--
-- * An order with a trustworthy point (location_status = 'resolved') and no
--   zone gets the active zone of its business whose boundary holds the
--   point. Several zones holding it (should not happen once zones are cell
--   groups) -> nearest zone centre, then lowest id: deterministic.
-- * A zone the vendor sets by hand always wins (zone_source = 'manual').
-- * Only orders not yet in a run (no delivery session, no rider) are ever
--   (re)zoned; a planned or active run is never touched.
-- * Outside the coverage radius + 20 % tolerance: no zone ("Outside
--   coverage"), never guessed into the nearest zone.
-- * zone_cells: the H3 hexagon grid (resolution 9) of each business's
--   coverage, one zone per cell, written by the zone-cells Edge Function.

alter table public.orders add column if not exists zone_source text;
alter table public.orders drop constraint if exists orders_zone_source_check;
alter table public.orders add constraint orders_zone_source_check
  check (zone_source is null or zone_source in ('manual', 'auto'));
update public.orders set zone_source = 'manual' where zone_id is not null and zone_source is null;

-- Point in a GeoJSON Polygon / MultiPolygon ([lng, lat]); holes excluded.
create or replace function public.geojson_contains(p_geom jsonb, p_lng double precision, p_lat double precision)
returns boolean
language plpgsql
immutable
set search_path = public
as $$
declare
  polys jsonb;
  poly jsonb;
  ring jsonb;
  ring_no int;
  inside boolean;
  n int; i int; j int;
  xi double precision; yi double precision; xj double precision; yj double precision;
  in_poly boolean;
begin
  if p_geom is null or p_lng is null or p_lat is null then return false; end if;
  if p_geom->>'type' = 'Polygon' then
    polys := jsonb_build_array(p_geom->'coordinates');
  elsif p_geom->>'type' = 'MultiPolygon' then
    polys := p_geom->'coordinates';
  else
    return false;
  end if;
  for poly in select value from jsonb_array_elements(polys) loop
    in_poly := false;
    ring_no := 0;
    for ring in select value from jsonb_array_elements(poly) loop
      inside := false;
      n := jsonb_array_length(ring);
      j := n - 1;
      for i in 0 .. n - 1 loop
        xi := (ring->i->>0)::double precision; yi := (ring->i->>1)::double precision;
        xj := (ring->j->>0)::double precision; yj := (ring->j->>1)::double precision;
        if ((yi > p_lat) <> (yj > p_lat)) and (p_lng < (xj - xi) * (p_lat - yi) / (yj - yi) + xi) then
          inside := not inside;
        end if;
        j := i;
      end loop;
      if ring_no = 0 then
        in_poly := inside;
        exit when not in_poly;
      elsif inside then
        in_poly := false; -- inside a hole
        exit;
      end if;
      ring_no := ring_no + 1;
    end loop;
    if in_poly then return true; end if;
  end loop;
  return false;
end;
$$;

-- Centre of a GeoJSON geometry's bounding box: [lng, lat].
create or replace function public.geojson_bbox_centre(p_geom jsonb)
returns double precision[]
language sql
immutable
set search_path = public
as $$
  with pts as (
    select (pt->>0)::double precision as x, (pt->>1)::double precision as y
    from jsonb_path_query(p_geom, 'strict $.coordinates.**') pt
    where jsonb_typeof(pt) = 'array' and jsonb_array_length(pt) = 2
      and jsonb_typeof(pt->0) = 'number'
  )
  select array[(min(x) + max(x)) / 2, (min(y) + max(y)) / 2] from pts
$$;

-- Internal (no caller check; used by triggers and the re-zone job).
create or replace function public._auto_zone_for_point(p_business_id uuid, p_lat double precision, p_lng double precision)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  b businesses;
  hit uuid;
begin
  if p_lat is null or p_lng is null then return null; end if;
  select * into b from businesses where id = p_business_id;
  if b.service_coverage_radius_km is not null and b.service_origin_latitude is not null
     and haversine_km(b.service_origin_latitude, b.service_origin_longitude, p_lat, p_lng)
         > b.service_coverage_radius_km * 1.2 then
    return null; -- outside coverage + 20 %
  end if;
  select z.id into hit
  from zones z
  where z.business_id = p_business_id and z.status = 'active' and z.boundary is not null
    and geojson_contains(z.boundary, p_lng, p_lat)
  order by haversine_km(p_lat, p_lng,
             (geojson_bbox_centre(z.boundary))[2], (geojson_bbox_centre(z.boundary))[1]),
           z.id
  limit 1;
  return hit;
end;
$$;

revoke all on function public._auto_zone_for_point(uuid, double precision, double precision) from public, anon, authenticated;

-- Before insert / update on orders: manual zone wins, auto zone otherwise.
create or replace function public._orders_auto_zone()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  system_change boolean := coalesce(current_setting('cefflo.auto_zone', true), '') = 'on';
  in_run boolean := new.delivery_session_id is not null or new.assigned_rider_id is not null;
  moved boolean := tg_op = 'INSERT'
    or new.latitude is distinct from old.latitude
    or new.longitude is distinct from old.longitude
    or new.location_status is distinct from old.location_status;
begin
  -- A zone set or cleared by a person is a manual choice.
  if not system_change and (
       (tg_op = 'INSERT' and new.zone_id is not null and new.zone_source is distinct from 'auto')
       or (tg_op = 'UPDATE' and new.zone_id is distinct from old.zone_id)) then
    new.zone_source := case when new.zone_id is null then null else 'manual' end;
    return new;
  end if;
  if system_change or in_run or new.zone_source = 'manual' or not moved then
    return new;
  end if;
  if new.location_status = 'resolved' then
    new.zone_id := _auto_zone_for_point(new.business_id, new.latitude, new.longitude);
    new.zone_source := case when new.zone_id is null then null else 'auto' end;
  elsif new.zone_source = 'auto' then
    new.zone_id := null; -- the point is no longer trustworthy
    new.zone_source := null;
  end if;
  return new;
end;
$$;

drop trigger if exists orders_auto_zone on public.orders;
create trigger orders_auto_zone
  before insert or update of latitude, longitude, location_status, zone_id, delivery_session_id, assigned_rider_id
  on public.orders
  for each row execute function public._orders_auto_zone();

-- Re-zone a business's open orders after its zones change (boundary,
-- status, new or deleted zone). Manual zones and orders in a run are kept.
create or replace function public._rezone_open_orders(p_business_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  perform set_config('cefflo.auto_zone', 'on', true);
  with next as (
    select o.id, _auto_zone_for_point(o.business_id, o.latitude, o.longitude) as zone_id
    from orders o
    where o.business_id = p_business_id
      and o.location_status = 'resolved'
      and o.delivery_session_id is null and o.assigned_rider_id is null
      and o.delivery_status in ('created', 'ready_for_pickup')
      and coalesce(o.zone_source, 'auto') = 'auto'
  )
  update orders o
     set zone_id = next.zone_id,
         zone_source = case when next.zone_id is null then null else 'auto' end,
         updated_at = now()
    from next
   where o.id = next.id and o.zone_id is distinct from next.zone_id;
  get diagnostics changed = row_count;
  perform set_config('cefflo.auto_zone', 'off', true);
  return changed;
end;
$$;

revoke all on function public._rezone_open_orders(uuid) from public, anon, authenticated;

create or replace function public._zones_rezone_orders()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform _rezone_open_orders(coalesce(new.business_id, old.business_id));
  return null;
end;
$$;

drop trigger if exists zones_rezone_orders on public.zones;
create trigger zones_rezone_orders
  after insert or delete or update of boundary, status on public.zones
  for each row execute function public._zones_rezone_orders();

-- Hexagon cells (H3 resolution 9) of a business's coverage. One zone per
-- cell (primary key), so zones built from cells can never overlap.
create table if not exists public.zone_cells (
  business_id uuid not null references public.businesses on delete cascade,
  cell text not null check (cell ~ '^[0-9a-f]{15}$'),
  zone_id uuid references public.zones on delete set null,
  area_id text references public.admin_areas(id) on delete set null,
  centre_lat double precision not null,
  centre_lng double precision not null,
  updated_at timestamptz not null default now(),
  primary key (business_id, cell)
);
create index if not exists zone_cells_zone_idx on public.zone_cells (zone_id);

alter table public.zone_cells enable row level security;
drop policy if exists zone_cells_read on public.zone_cells;
create policy zone_cells_read on public.zone_cells for select to authenticated
  using (is_business_member(business_id));
revoke all on public.zone_cells from public, anon, authenticated;
grant select on public.zone_cells to authenticated;

-- Explicit re-run for the vendor (e.g. after loading new areas).
create or replace function public.rezone_open_orders(p_business_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  return _rezone_open_orders(p_business_id);
end;
$$;

revoke all on function public.rezone_open_orders(uuid) from public, anon;
grant execute on function public.rezone_open_orders(uuid) to authenticated;

-- ===== supabase/migrations/20261014180000_run_size_merge_split.sql
-- Target run size, merge and split (Auto Zone master guideline Part A
-- §3.2, Founder decisions D2/D3/D5, 2026-10-14).
--
-- * businesses.run_size_min / run_size_max: default 10 / 15, editable per
--   business (Owner / Operator) with set_business_run_size.
-- * propose_delivery_plan keeps its signature and response; it now merges
--   nearby under-minimum zones lying in the same direction (D3), splits
--   clusters above the maximum into compact patches that follow where the
--   orders are (D5), and flags each proposed run (zone_ids, merged,
--   below_target_size). Rider capacity still caps every run, as before.
--   Proposal only: the vendor reviews and dispatches as today.

alter table public.businesses add column if not exists run_size_min integer not null default 10;
alter table public.businesses add column if not exists run_size_max integer not null default 15;
alter table public.businesses drop constraint if exists businesses_run_size_check;
alter table public.businesses add constraint businesses_run_size_check
  check (run_size_min between 1 and 50 and run_size_max between 1 and 50 and run_size_min <= run_size_max);

create or replace function public.set_business_run_size(p_business_id uuid, p_min integer, p_max integer)
returns public.businesses
language plpgsql
security definer
set search_path = public
as $$
declare b public.businesses;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if p_min is null or p_max is null or p_min < 1 or p_max > 50 or p_min > p_max then
    raise exception 'run size must be 1-50 with minimum <= maximum';
  end if;
  update public.businesses set run_size_min = p_min, run_size_max = p_max, updated_at = now()
   where id = p_business_id returning * into b;
  insert into public.business_profile_audit(business_id, actor_user_id, changed_fields, request_id)
  values (p_business_id, auth.uid(), array['run_size_min', 'run_size_max'], null);
  return b;
end;
$$;
revoke all on function public.set_business_run_size(uuid, integer, integer) from public, anon;
grant execute on function public.set_business_run_size(uuid, integer, integer) to authenticated;

-- Initial bearing from point 1 to point 2, 0-360 degrees.
create or replace function public._bearing_deg(lat1 double precision, lng1 double precision, lat2 double precision, lng2 double precision)
returns double precision
language sql
immutable
set search_path = public
as $$
  select mod((degrees(atan2(
    sin(radians(lng2 - lng1)) * cos(radians(lat2)),
    cos(radians(lat1)) * sin(radians(lat2)) - sin(radians(lat1)) * cos(radians(lat2)) * cos(radians(lng2 - lng1))
  )) + 360)::numeric, 360)::double precision
$$;

-- Smallest angle between two bearings, 0-180.
create or replace function public._bearing_gap(a double precision, b double precision)
returns double precision
language sql
immutable
set search_path = public
as $$ select least(abs(a - b), 360 - abs(a - b)) $$;

create or replace function public.propose_delivery_plan(
  p_business_id uuid,
  p_rider_ids uuid[] default null,
  p_policy text default 'balance'
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  b businesses;
  groups jsonb := '[]'::jsonb;
  unplannable jsonb := '[]'::jsonb;
  excluded jsonb := '[]'::jsonb;
  u record;
  rd record;
  path_ids uuid[];
  chunk uuid[];
  seq_result jsonb;
  unit_requirement public.vehicle_requirement;
  unit_key text;
  left_n int;
  pos int;
  j int;
  k int;
  i int;
  cum int;
  take int;
  later_cap int;
  leftover_reason text;
  picks uuid[];
  takes int[];
  pick_caps int[];
  run_min int;
  run_max int;
  zu record;
  cand record;
  own text;
  total int;
  cu record;
  parts int;
  base_n int;
  rem_n int;
  p int;
  part_n int;
  cy double precision;
  cx double precision;
  sy double precision;
  sx double precision;
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_policy is null or p_policy not in ('balance','fill') then
    raise exception 'invalid policy';
  end if;
  if p_rider_ids is not null and cardinality(p_rider_ids) = 0 then
    raise exception 'no drivers selected';
  end if;
  select * into b from businesses where id = p_business_id;

  -- Orders in scope. Defensive drop: ON COMMIT DROP only fires at commit, so
  -- two calls in one transaction would otherwise collide (as in 202609030004).
  drop table if exists tmp_plan_scope;
  create temporary table tmp_plan_scope on commit drop as
    select o.id as order_id, o.zone_id, z.name as zone_name, o.vehicle_requirement,
           o.latitude as lat, o.longitude as lng, null::text as cluster,
           o.location_status::text as location_status, ds.preparation_status::text as preparation_status,
           o.approved_at,
           (o.delivery_session_id is not null and run_plan_locked(o.delivery_session_id)) as plan_locked,
           case o.vehicle_requirement when 'van_required' then 1 when 'car_or_larger' then 2 else 3 end as tier_rank
    from orders o
    join delivery_stops ds on ds.order_id = o.id
    left join zones z on z.id = o.zone_id
    where o.business_id = p_business_id
      and o.delivery_status = 'created'
      and o.approved_at is not null
      and o.assigned_rider_id is null;

  select coalesce(jsonb_agg(jsonb_build_object(
      'order_id', order_id,
      'reason', case
        when location_status <> 'resolved' then 'location_' || location_status
        when plan_locked then 'in_locked_run'
        when preparation_status in ('sorted','ready') then 'sorted_before_run'
        else 'in_preparation'
      end,
      'zone_id', zone_id,
      'required_vehicle', vehicle_requirement,
      'approved_at', approved_at
    ) order by order_id), '[]'::jsonb)
    into unplannable
    from tmp_plan_scope
    where location_status <> 'resolved' or preparation_status in ('preparing','sorted','ready') or plan_locked;
  delete from tmp_plan_scope where location_status <> 'resolved' or preparation_status in ('preparing','sorted','ready') or plan_locked;

  -- Riders.
  drop table if exists tmp_plan_riders;
  create temporary table tmp_plan_riders on commit drop as
    select r.id as rider_id, r.name, r.vehicle_type,
           case r.vehicle_type when 'motorcycle' then 1 when 'car' then 2 else 3 end as vehicle_rank,
           rider_effective_capacity(r.id) - rider_active_stop_count(r.id) as remaining,
           exists(select 1 from rider_assignments a
                  where a.rider_id = r.id and a.status in ('assigned','accepted','picking_up','delivering')) as has_open_run,
           false as used
    from riders r
    where r.business_id = p_business_id
      and r.status = 'active'
      and (p_rider_ids is null or r.id = any(p_rider_ids));

  if p_rider_ids is not null then
    select coalesce(jsonb_agg(jsonb_build_object('rider_id', x, 'reason', 'not_eligible') order by x), '[]'::jsonb)
      into excluded
      from (select distinct unnest(p_rider_ids) as x) s
      where not exists (select 1 from tmp_plan_riders t where t.rider_id = s.x);
  end if;
  select excluded || coalesce(jsonb_agg(jsonb_build_object(
      'rider_id', rider_id, 'rider_name', name,
      'reason', case when has_open_run then 'rider_has_open_run' else 'no_capacity' end
    ) order by rider_id), '[]'::jsonb)
    into excluded
    from tmp_plan_riders
    where has_open_run or remaining <= 0;
  delete from tmp_plan_riders where has_open_run or remaining <= 0;

  -- Target run size (Founder D2: default 10-15, editable per business).
  run_min := coalesce(b.run_size_min, 10);
  run_max := greatest(coalesce(b.run_size_max, 15), run_min);

  -- One cluster per (vehicle tier, zone) to start.
  drop table if exists tmp_plan_units;
  create temporary table tmp_plan_units on commit drop as
    select tier_rank, zone_id, count(*)::int as n, avg(lat) as clat, avg(lng) as clng,
           coalesce(zone_id::text, 'unzoned') || ':' || tier_rank as own_key,
           coalesce(zone_id::text, 'unzoned') || ':' || tier_rank as cluster
    from tmp_plan_scope group by tier_rank, zone_id;

  -- D3: a zone under the minimum is merged with nearby under-minimum zones
  -- lying in the same direction from the business (bearing within 45
  -- degrees, centres within 8 km) while the run stays within the maximum.
  for zu in
    select * from tmp_plan_units
    where zone_id is not null and n < run_min
    order by tier_rank,
             case when b.service_origin_latitude is null then 0
                  else _bearing_deg(b.service_origin_latitude, b.service_origin_longitude, clat, clng) end,
             own_key
  loop
    select cluster into own from tmp_plan_units where own_key = zu.own_key;
    continue when own <> zu.own_key; -- already merged into another run
    select sum(n) into total from tmp_plan_units where cluster = own;
    while total < run_min loop
      select c.* into cand from tmp_plan_units c
      where c.tier_rank = zu.tier_rank and c.zone_id is not null and c.own_key <> zu.own_key
        and c.cluster = c.own_key and c.n < run_min and total + c.n <= run_max
        and not exists (select 1 from tmp_plan_units x where x.cluster = c.own_key and x.own_key <> c.own_key)
        and haversine_km(zu.clat, zu.clng, c.clat, c.clng) <= 8
        and (b.service_origin_latitude is null or _bearing_gap(
              _bearing_deg(b.service_origin_latitude, b.service_origin_longitude, zu.clat, zu.clng),
              _bearing_deg(b.service_origin_latitude, b.service_origin_longitude, c.clat, c.clng)) <= 45)
      order by haversine_km(zu.clat, zu.clng, c.clat, c.clng), c.own_key
      limit 1;
      exit when not found;
      update tmp_plan_units set cluster = own where own_key = cand.own_key;
      total := total + cand.n;
    end loop;
  end loop;
  update tmp_plan_scope s set cluster = pu.cluster
    from tmp_plan_units pu
   where pu.tier_rank = s.tier_rank and pu.zone_id is not distinct from s.zone_id;

  -- D5: a cluster above the maximum is split into balanced, compact patches
  -- that follow where its orders actually are (never a fixed slice): seed
  -- with the order farthest from the remaining orders' centre, take its
  -- nearest orders, repeat.
  for cu in
    select cluster, count(*)::int as n from tmp_plan_scope
    group by cluster having count(*) > run_max order by cluster
  loop
    parts := ceil(cu.n::numeric / run_max)::int;
    base_n := cu.n / parts;
    rem_n := cu.n % parts;
    for p in 1 .. parts - 1 loop
      part_n := base_n + case when p <= rem_n then 1 else 0 end;
      select avg(lat), avg(lng) into cy, cx from tmp_plan_scope where cluster = cu.cluster;
      select lat, lng into sy, sx from tmp_plan_scope where cluster = cu.cluster
        order by haversine_km(cy, cx, lat, lng) desc, order_id limit 1;
      update tmp_plan_scope set cluster = cu.cluster || '/' || p
       where order_id in (select order_id from tmp_plan_scope where cluster = cu.cluster
                          order by haversine_km(sy, sx, lat, lng), order_id limit part_n);
    end loop;
    update tmp_plan_scope set cluster = cu.cluster || '/' || parts where cluster = cu.cluster;
  end loop;

  -- Units, deterministic order.
  for u in
    select tier_rank, cluster,
           (array_agg(zone_id order by zone_name, zone_id) filter (where zone_id is not null))[1] as zone_id,
           coalesce(jsonb_agg(distinct zone_id) filter (where zone_id is not null), '[]'::jsonb) as zone_ids,
           min(zone_name) as zone_name, count(*) as n
    from tmp_plan_scope
    group by tier_rank, cluster
    order by tier_rank, bool_and(zone_id is null), count(*) desc, min(zone_name), cluster
  loop
    unit_requirement := case u.tier_rank when 1 then 'van_required' when 2 then 'car_or_larger' else 'any' end;
    unit_key := u.cluster || ':' || unit_requirement::text;

    select array_agg(order_id order by order_id) into path_ids
      from tmp_plan_scope where cluster = u.cluster;
    seq_result := sequence_group_nearest_neighbor(path_ids, b.service_origin_latitude, b.service_origin_longitude);
    select array_agg((s->>'order_id')::uuid order by (s->>'sequence')::int) into path_ids
      from jsonb_array_elements(seq_result->'stops') s;
    left_n := cardinality(path_ids);

    -- Candidate riders for this unit, in allocation order.
    select array_agg(rider_id order by vehicle_rank, remaining desc, rider_id),
           array_agg(remaining order by vehicle_rank, remaining desc, rider_id)
      into picks, pick_caps
      from tmp_plan_riders
      where not used and is_vehicle_compatible(vehicle_type, unit_requirement);

    takes := '{}';
    if picks is not null then
      if p_policy = 'fill' then
        k := cardinality(picks);
      else
        -- Fewest riders whose remaining capacity covers the unit.
        k := 0; cum := 0;
        while k < cardinality(picks) and cum < left_n loop
          k := k + 1; cum := cum + pick_caps[k];
        end loop;
      end if;
      i := 1;
      while i <= k and left_n > 0 loop
        if p_policy = 'fill' then
          take := least(pick_caps[i], left_n);
        else
          later_cap := 0;
          for j in i + 1 .. k loop later_cap := later_cap + pick_caps[j]; end loop;
          take := least(pick_caps[i], greatest(ceil(left_n::numeric / (k - i + 1))::int, left_n - later_cap));
        end if;
        takes := takes || take;
        left_n := left_n - take;
        i := i + 1;
      end loop;
    end if;

    pos := 1;
    for i in 1 .. coalesce(cardinality(takes), 0) loop
      chunk := path_ids[pos : pos + takes[i] - 1];
      pos := pos + takes[i];
      select * into rd from tmp_plan_riders where rider_id = picks[i];
      update tmp_plan_riders set used = true where rider_id = picks[i];
      seq_result := sequence_group_nearest_neighbor(chunk, b.service_origin_latitude, b.service_origin_longitude);
      groups := groups || jsonb_build_array(jsonb_build_object(
        'group_key', unit_key || ':' || i,
        'zone_id', u.zone_id,
        'candidate_rider_id', rd.rider_id,
        'candidate_rider_name', rd.name,
        'candidate_rider_vehicle_type', rd.vehicle_type,
        'required_vehicle', unit_requirement,
        'stops', seq_result->'stops',
        'total_distance_km', seq_result->'total_distance_km',
        'tier', unit_requirement,
        'part', i,
        'parts', cardinality(takes),
        'rider_remaining_after', rd.remaining - takes[i],
        'zone_ids', u.zone_ids,
        'merged', jsonb_array_length(u.zone_ids) > 1,
        'below_target_size', u.n < run_min,
        'run_size_min', run_min,
        'run_size_max', run_max
      ));
    end loop;

    if pos <= cardinality(path_ids) then
      leftover_reason := case
        when exists(select 1 from riders r where r.business_id = p_business_id and r.status = 'active'
                      and (p_rider_ids is null or r.id = any(p_rider_ids))
                      and is_vehicle_compatible(r.vehicle_type, unit_requirement))
        then 'insufficient_capacity' else 'vehicle_incompatible' end;
      select unplannable || coalesce(jsonb_agg(jsonb_build_object(
          'order_id', t.order_id, 'reason', leftover_reason, 'zone_id', t.zone_id,
          'required_vehicle', t.vehicle_requirement, 'approved_at', t.approved_at
        ) order by x.ord), '[]'::jsonb)
        into unplannable
        from unnest(path_ids[pos : cardinality(path_ids)]) with ordinality as x(order_id, ord)
        join tmp_plan_scope t on t.order_id = x.order_id;
    end if;
  end loop;

  -- Orders still held by a declined run: visible, never planned here.
  select unplannable || coalesce(jsonb_agg(jsonb_build_object(
      'order_id', o.id, 'reason', 'declined_awaiting_recovery', 'zone_id', o.zone_id,
      'required_vehicle', o.vehicle_requirement, 'approved_at', o.approved_at
    ) order by o.id), '[]'::jsonb)
    into unplannable
    from orders o
    join delivery_stops ds on ds.order_id = o.id
    join rider_assignments a on a.id = ds.assignment_id
    where o.business_id = p_business_id
      and o.delivery_status = 'created'
      and o.approved_at is not null
      and o.assigned_rider_id is not null
      and a.status = 'declined';

  return jsonb_build_object(
    'business_id', p_business_id,
    'generated_at', now(),
    'plan_date', (now() at time zone b.timezone)::date,
    'policy', p_policy,
    'run_size_min', run_min,
    'run_size_max', run_max,
    'groups', groups,
    'unplannable_orders', unplannable,
    'excluded_riders', excluded
  );
end;
$$;



-- ===== supabase/migrations/20261014190000_google_geocoding.sql
-- Google geocoding storage rules (Auto Zone + Google Maps master guideline
-- Part B §B3, Phase 1, 2026-10-14).
--
-- * place_id is stored permanently (Google allows it).
-- * Google-derived coordinates (location_provider = 'google') are kept at
--   most 30 days. A daily job clears them:
--     - finished orders (delivered / cancelled): coordinates cleared; the
--       address text, place_id, POD and rider GPS stay as history;
--     - open orders not yet in a run: back to 'unresolved', so the next
--       geocode-order pending call resolves them again.
--   Orders inside a planned or active run are never touched.
-- * Our own points (customer_pin, vendor_pin, manual_correction) are never
--   expired.

alter table public.orders add column if not exists place_id text;
alter table public.businesses add column if not exists place_id text;

-- set_order_location gains p_place_id. Same rules as before; the place_id
-- is kept for ambiguous results too (Google's best candidate), never a
-- coordinate.
drop function if exists public.set_order_location(uuid, public.order_location_status, double precision, double precision, text, text);
create function public.set_order_location(
  p_order_id uuid,
  p_status public.order_location_status,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_provider text default null,
  p_error text default null,
  p_place_id text default null
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
    place_id = coalesce(nullif(btrim(p_place_id), ''), place_id),
    updated_at = now()
  where id = p_order_id
  returning * into o;

  insert into delivery_events(business_id, order_id, event_type, actor_role, metadata)
    values (o.business_id, o.id, 'order.location_resolved', 'system',
            jsonb_build_object('status', p_status, 'provider', p_provider, 'error', p_error));

  return o;
end;
$$;

revoke all on function public.set_order_location(uuid, public.order_location_status, double precision, double precision, text, text, text) from public, anon, authenticated;
grant execute on function public.set_order_location(uuid, public.order_location_status, double precision, double precision, text, text, text) to service_role;

-- Daily 30-day expiry of Google coordinates. Returns rows changed.
create or replace function public._expire_google_coordinates()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  finished integer;
  reopened integer;
begin
  update orders set
    latitude = null, longitude = null,
    location_error = 'google_cache_expired',
    updated_at = now()
  where location_provider = 'google'
    and latitude is not null
    and location_resolved_at < now() - interval '30 days'
    and delivery_status in ('delivered', 'cancelled');
  get diagnostics finished = row_count;

  update orders set
    latitude = null, longitude = null,
    location_status = 'unresolved',
    location_provider = null,
    location_error = 'google_cache_expired',
    updated_at = now()
  where location_provider = 'google'
    and location_resolved_at < now() - interval '30 days'
    and delivery_status in ('created', 'ready_for_pickup')
    and delivery_session_id is null and assigned_rider_id is null;
  get diagnostics reopened = row_count;

  return finished + reopened;
end;
$$;

revoke all on function public._expire_google_coordinates() from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('cefflo_google_geocode_expiry', '17 3 * * *',
                          'select public._expire_google_coordinates()');
  end if;
end;
$$;

commit;
