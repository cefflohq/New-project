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
