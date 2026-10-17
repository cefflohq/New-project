-- Product sets and vendor promos (Founder 2026-10-17). All vendor-owned:
-- Cefflo only provides the settings.
-- * compare_at_price: the normal price shown struck through ("Save RM…").
-- * set_items: what a set contains (e.g. the dishes in a 7-day frozen set).
-- * portion_note: e.g. "Each pack feeds 2-3".
-- * delivery_fee: per-product delivery fee; null = the store fee; 0 = the
--   vendor gives free delivery (the vendor still pays its driver).
-- * weight_kg: for courier rates.
-- Order delivery fee = the highest fee among its items (free only when every
-- item is free).
-- Rollback: drop set_product_extras, _storefront_order_fee; drop the columns;
-- restore _storefront_payload.
alter table public.products
  add column if not exists compare_at_price numeric(10,2) check (compare_at_price is null or compare_at_price > 0),
  add column if not exists set_items text[] check (set_items is null or cardinality(set_items) <= 30),
  add column if not exists portion_note text check (portion_note is null or char_length(portion_note) <= 80),
  add column if not exists delivery_fee numeric(10,2) check (delivery_fee is null or delivery_fee between 0 and 1000),
  add column if not exists weight_kg numeric(6,3) check (weight_kg is null or weight_kg > 0 and weight_kg <= 70);

create or replace function public.set_product_extras(p_product_id uuid, p_compare_at_price numeric, p_set_items text[],
  p_portion_note text, p_delivery_fee numeric, p_weight_kg numeric)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare pr products; items text[];
begin
  select * into pr from products where id = p_product_id;
  if pr.id is null or not is_business_operational(pr.business_id) then raise exception 'forbidden'; end if;
  if p_compare_at_price is not null and p_compare_at_price <= pr.display_price then
    raise exception 'normal price must be higher than the selling price';
  end if;
  select array_agg(btrim(x)) into items from unnest(coalesce(p_set_items, '{}')) x where btrim(x) <> '' and char_length(btrim(x)) <= 80;
  update products set compare_at_price = p_compare_at_price, set_items = items,
         portion_note = nullif(btrim(coalesce(p_portion_note, '')), ''),
         delivery_fee = p_delivery_fee, weight_kg = p_weight_kg, updated_at = now()
   where id = p_product_id;
  return jsonb_build_object('ok', true);
end $$;
grant execute on function public.set_product_extras(uuid, numeric, text[], text, numeric, numeric) to authenticated;

-- Per-drop fee for an order: highest item fee (item override or store fee).
create or replace function public._storefront_order_fee(p_order_id uuid) returns numeric
language sql stable security definer set search_path to 'public' as $$
  select max(coalesce(p.delivery_fee, pg.delivery_fee, 0))
    from orders o
    join public_order_pages pg on pg.business_id = o.business_id
    cross join lateral jsonb_array_elements(o.items) i
    join products p on p.id = (i->>'product_id')::uuid
   where o.id = p_order_id
$$;
revoke all on function public._storefront_order_fee(uuid) from public, anon, authenticated;
grant execute on function public._storefront_order_fee(uuid) to service_role;
CREATE OR REPLACE FUNCTION public._storefront_payload(page public_order_pages)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
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
    'delivery', jsonb_build_object('fee', page.delivery_fee, 'days', to_jsonb(page.delivery_days),
      'shifts', page.delivery_shifts, 'weeks', to_jsonb(page.package_weeks),
      'coverage', b.service_coverage_radius_km is not null),
    'payments', jsonb_build_object(
      'online', exists (select 1 from vendor_payment_accounts a where a.business_id = page.business_id),
      'cod', page.accept_cod or not exists (select 1 from vendor_payment_accounts a where a.business_id = page.business_id)),
    'categories', coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'name', c.name) order by c.sort_order, c.id)
        from product_categories c where c.business_id = page.business_id and c.archived_at is null), '[]'::jsonb),
    'products', coalesce((select jsonb_agg(jsonb_build_object(
        'id', p.id, 'category_id', p.category_id, 'name', p.name,
        'description', p.description, 'display_price', p.display_price,
        'compare_at_price', p.compare_at_price, 'set_items', to_jsonb(p.set_items), 'portion_note', p.portion_note,
        'delivery_fee', p.delivery_fee, 'weight_kg', p.weight_kg,
        'images', coalesce((select jsonb_agg('/storage/v1/object/public/cefflo-product-display/' || pm.prepared_storage_path
            order by pm.position nulls last, pm.approved_at)
          from product_media pm
          where pm.product_id = p.id and pm.status = 'approved' and pm.archived_at is null), '[]'::jsonb)
      ) order by p.sort_order, p.id)
      from products p where p.business_id = page.business_id and p.status = 'active' and p.archived_at is null), '[]'::jsonb)
  ) from businesses b where b.id = page.business_id
$function$;

-- Packages charge the order's per-drop fee (product fees respected).
CREATE OR REPLACE FUNCTION public._start_storefront_subscription(page public_order_pages, p_plan jsonb, p_items jsonb, p_name text, p_phone text, p_address text, p_notes text, p_lat double precision, p_lng double precision, p_key uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare sub_id uuid; w int; d smallint[]; dt date; first_order uuid; open_days int[]; n int := 0;
begin
  w := (p_plan->>'weeks')::int;
  if w not in (select unnest(page.package_weeks)) then raise exception 'invalid package'; end if;
  select array_agg(x::smallint order by x) into d from jsonb_array_elements_text(p_plan->'days') x
   where x::int = any(page.delivery_days);
  if d is null or cardinality(d) = 0 then raise exception 'invalid delivery days'; end if;
  select array_agg(h.weekday) into open_days from business_hours h where h.business_id = page.business_id and h.is_open;
  select id into first_order from orders where business_id = page.business_id and submission_idempotency_key = p_key;
  insert into storefront_subscriptions(business_id, first_order_id, customer_name, customer_phone, delivery_address,
      delivery_notes, latitude, longitude, items, days, weeks, shift, delivery_fee)
    values (page.business_id, first_order, btrim(p_name), btrim(p_phone), btrim(p_address), coalesce(btrim(p_notes), ''),
      p_lat, p_lng, p_items, d, w,
      (select s from jsonb_array_elements(page.delivery_shifts) s where s->>'name' = p_plan->>'shift' limit 1),
      coalesce(_storefront_order_fee(first_order), page.delivery_fee))
    returning id into sub_id;
  -- Deliveries over the next w weeks on the chosen weekdays the store is open.
  for dt in select g::date from generate_series(_my_today(), _my_today() + (w * 7 - 1), interval '1 day') g loop
    if extract(isodow from dt)::smallint = any(d) and (open_days is null or extract(isodow from dt)::int = any(open_days)) then
      n := n + 1;
      insert into storefront_subscription_days(subscription_id, business_id, delivery_on, status, order_id)
        values (sub_id, page.business_id, dt, case when n = 1 then 'ordered' else 'scheduled' end, case when n = 1 then first_order end);
    end if;
  end loop;
  return sub_id;
end $function$;
