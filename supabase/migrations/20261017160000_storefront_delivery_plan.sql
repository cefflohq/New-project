-- Storefront delivery plan (Founder 2026-10-17).
-- * Vendor sets a delivery fee per drop (= the driver's pay; never free), the
--   weekdays it delivers, its delivery shifts (batches with fixed windows) and
--   the package lengths customers may choose (weeks).
-- * The storefront shows these, lets the customer choose days, weeks and a
--   shift, and blocks orders outside the business's coverage radius.
-- Rollback: drop function save_storefront_delivery, storefront_coverage_check;
-- restore the previous _storefront_payload and submit_storefront_order bodies;
-- alter table public_order_pages drop column delivery_fee, delivery_days,
-- delivery_shifts, package_weeks.

alter table public.public_order_pages
  add column if not exists delivery_fee numeric(10,2) check (delivery_fee is null or delivery_fee between 0 and 1000),
  add column if not exists delivery_days smallint[] not null default '{1,2,3,4,5}'
    check (delivery_days <@ '{1,2,3,4,5,6,7}'::smallint[] and cardinality(delivery_days) between 1 and 7),
  add column if not exists delivery_shifts jsonb not null default '[]'::jsonb check (jsonb_typeof(delivery_shifts) = 'array'),
  add column if not exists package_weeks smallint[] not null default '{1,2,4}'
    check (package_weeks <@ '{1,2,3,4}'::smallint[] and cardinality(package_weeks) between 1 and 4);

-- Vendor setting (Owner / Operator). Shifts: [{"name":"Evening","from":"18:00","to":"20:00"}], max 4.
create or replace function public.save_storefront_delivery(p_business_id uuid, p_fee numeric, p_days smallint[],
  p_shifts jsonb, p_weeks smallint[])
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare s jsonb;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if p_fee is null or p_fee < 0 or p_fee > 1000 then raise exception 'invalid delivery fee'; end if;
  if jsonb_typeof(coalesce(p_shifts, '[]')) <> 'array' or jsonb_array_length(coalesce(p_shifts, '[]')) > 4 then
    raise exception 'invalid delivery shifts';
  end if;
  for s in select * from jsonb_array_elements(coalesce(p_shifts, '[]')) loop
    if coalesce(btrim(s->>'name'), '') = '' or length(s->>'name') > 40
       or (s->>'from') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' or (s->>'to') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
       or (s->>'to') <= (s->>'from') then
      raise exception 'invalid delivery shifts';
    end if;
  end loop;
  update public.public_order_pages
     set delivery_fee = round(p_fee, 2), delivery_days = p_days, package_weeks = p_weeks,
         delivery_shifts = (select coalesce(jsonb_agg(jsonb_build_object('name', btrim(x->>'name'), 'from', x->>'from', 'to', x->>'to')
                              order by x->>'from'), '[]') from jsonb_array_elements(coalesce(p_shifts, '[]')) x),
         updated_at = now()
   where business_id = p_business_id;
  if not found then raise exception 'storefront not found'; end if;
  return jsonb_build_object('ok', true);
end $$;
revoke all on function public.save_storefront_delivery(uuid, numeric, smallint[], jsonb, smallint[]) from public, anon;
grant execute on function public.save_storefront_delivery(uuid, numeric, smallint[], jsonb, smallint[]) to authenticated;

-- Public: is this pin inside the store's coverage? null = the store has no radius set.
create or replace function public._storefront_covers(page public_order_pages, p_lat double precision, p_lng double precision)
returns boolean language sql stable security definer set search_path to 'public' as $$
  select case when b.service_coverage_radius_km is null or b.service_origin_latitude is null or p_lat is null or p_lng is null then null
              else haversine_km(b.service_origin_latitude, b.service_origin_longitude, p_lat, p_lng) <= b.service_coverage_radius_km end
    from businesses b where b.id = page.business_id
$$;
revoke all on function public._storefront_covers(public_order_pages, double precision, double precision) from public, anon, authenticated;

create or replace function public.storefront_coverage_check(p_slug text, p_latitude double precision, p_longitude double precision)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare page public_order_pages; allowed boolean;
begin
  begin
    allowed := check_rate_limit(_public_caller_key('storefront_coverage_check'), 'storefront_coverage_check', 60, 30);
  exception when others then allowed := false;
  end;
  if not allowed then return jsonb_build_object('error', 'rate limited'); end if;
  page := _resolve_storefront(lower(btrim(coalesce(p_slug, ''))));
  if page.id is null then return null; end if;
  return jsonb_build_object('covered', _storefront_covers(page, p_latitude, p_longitude));
end $$;
revoke all on function public.storefront_coverage_check(text, double precision, double precision) from public;
grant execute on function public.storefront_coverage_check(text, double precision, double precision) to anon, authenticated;

-- Payload: the delivery plan.
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

-- Submit: refuse pins outside coverage.
CREATE OR REPLACE FUNCTION public.submit_storefront_order(p_slug text, p_items jsonb, p_customer_name text, p_customer_phone text, p_delivery_address text, p_delivery_notes text DEFAULT ''::text, p_idempotency_key uuid DEFAULT NULL::uuid, p_latitude double precision DEFAULT NULL::double precision, p_longitude double precision DEFAULT NULL::double precision, p_location_accuracy_m numeric DEFAULT NULL::numeric, p_location_source text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  page public.public_order_pages; allowed boolean; existing public.orders; digits text; t text; res jsonb;
begin
  begin
    allowed := check_rate_limit(_public_caller_key('submit_storefront_order'), 'submit_storefront_order', 60, 5);
  exception when others then allowed := false;  -- fail closed
  end;
  if not allowed then raise exception 'rate limited'; end if;
  -- From here every refusal is RETURNED (not raised) so the attempt stays counted.
  page := _resolve_storefront(lower(btrim(coalesce(p_slug, ''))));
  if page.id is null then
    perform record_invalid_lookup_telemetry('submit_storefront_order');
    return jsonb_build_object('error', 'invalid or unavailable storefront');
  end if;
  begin
    allowed := check_rate_limit(encode(digest('store:' || page.id::text, 'sha256'), 'hex'), 'submit_storefront_order_store', 60, 120);
  exception when others then allowed := false;
  end;
  if not allowed then return jsonb_build_object('error', 'rate limited'); end if;
  if p_idempotency_key is null then return jsonb_build_object('error', 'invalid idempotency key'); end if;

  -- Replay of an order already created with this key (same store, last 24 h):
  -- the same reference plus a fresh tracking token for that order only.
  select * into existing from public.orders
   where submission_idempotency_key = p_idempotency_key and business_id = page.business_id;
  if existing.id is not null then
    if existing.created_at < now() - interval '24 hours' then
      return jsonb_build_object('order_reference', existing.public_ref, 'tracking_token', null, 'replay', true);
    end if;
    -- One token per order (unique): rotate it like rotate_tracking_token, so
    -- the token the customer now holds is the working one.
    t := encode(gen_random_bytes(32), 'hex');
    update public.tracking_tokens
       set token_hash = encode(digest(t, 'sha256'), 'hex'),
           expires_at = case when existing.delivery_status = 'delivered' then now() + interval '48 hours' else null end,
           revoked_at = null
     where order_id = existing.id;
    if not found then
      insert into public.tracking_tokens(order_id, token_hash) values (existing.id, encode(digest(t, 'sha256'), 'hex'));
    end if;
    return jsonb_build_object('order_reference', existing.public_ref, 'tracking_token', t, 'replay', true);
  end if;

  if exists (select 1 from business_hours h where h.business_id = page.business_id)
     and not business_open_now(page.business_id) then
    return jsonb_build_object('error', 'store closed', 'next_open', _business_next_open(page.business_id));
  end if;

  digits := regexp_replace(coalesce(p_customer_phone, ''), '[\s().-]', '', 'g');
  if digits !~ '^\+?[0-9]{7,15}$' then
    return jsonb_build_object('error', 'invalid customer phone');
  end if;

  -- Delivery pin (Founder 2026-10-08): both or neither; Malaysia bounds only.
  if (p_latitude is null) <> (p_longitude is null)
     or (p_latitude is not null and not (p_latitude between 0.5 and 7.6 and p_longitude between 99.5 and 119.5)) then
    return jsonb_build_object('error', 'invalid delivery pin');
  end if;
  if p_location_source is not null and p_location_source not in ('gps', 'pin_adjusted', 'map') then
    return jsonb_build_object('error', 'invalid delivery pin');
  end if;

  -- Coverage (Founder 2026-10-17): a store with a radius does not take orders
  -- pinned outside it; its drivers cannot reach there.
  if _storefront_covers(page, p_latitude, p_longitude) is false then
    return jsonb_build_object('error', 'outside coverage');
  end if;
  if p_latitude is null and exists (select 1 from businesses b where b.id = page.business_id and b.service_coverage_radius_km is not null) then
    return jsonb_build_object('error', 'invalid delivery pin');
  end if;

  begin
    res := _create_public_order(page, p_items, p_customer_name, p_customer_phone,
                                p_delivery_address, p_delivery_notes, p_idempotency_key);
  exception when others then
    return jsonb_build_object('error', sqlerrm);
  end;

  if p_latitude is not null and res ? 'order_reference' and p_idempotency_key is not null then
    update public.orders
       set latitude = round(p_latitude::numeric, 6), longitude = round(p_longitude::numeric, 6),
           location_accuracy_m = case when p_location_accuracy_m between 0 and 100000 then round(p_location_accuracy_m) end,
           location_source = coalesce(p_location_source, 'map'),
           location_status = 'resolved', location_provider = 'customer_pin',
           location_resolved_at = now(), location_error = null
     where business_id = page.business_id and submission_idempotency_key = p_idempotency_key;
  end if;
  return res;
end $function$;
