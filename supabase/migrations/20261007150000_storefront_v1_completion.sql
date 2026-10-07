-- Public Storefront V1 completion (Founder-approved 2026-10-07, staging first).
--
-- 1. Trusted caller identity for the public rate limits. Verified on staging
--    (2026-10-07) against the real Supabase proxy chain:
--      x-forwarded-for  -> a client value is PREPENDED ("spoof, real"): untrusted;
--      cf-connecting-ip -> a client-sent value is rejected by Cloudflare (403);
--      sb-forwarded-for -> always rewritten by Supabase to the connecting IP.
--    The caller key now uses sb-forwarded-for, then cf-connecting-ip; with
--    neither (not reachable through the public API) every caller shares one
--    'unknown' bucket, which can only be stricter.
-- 2. Rate-limit infrastructure failure now FAILS CLOSED (it used to allow).
-- 3. submit_storefront_order: every refusal after the per-caller limit is
--    returned as {"error": ...} instead of raising, so the transaction commits
--    and failed / malformed attempts COUNT toward the limit (a raise rolled the
--    counter back, leaving an unlimited abuse path). Order creation itself
--    still runs in a sub-transaction: a failure leaves no partial rows.
-- 4. Ordering while closed is refused server-side (canonical
--    business_open_now(), business timezone). No configured hours keeps the
--    existing semantics: open_now unknown (null) -> ordering allowed.
-- 5. Customer phone: international format, 7-15 digits after removing spaces,
--    dashes, dots and brackets; an optional leading +.
-- 6. Idempotent replay (same key, same store, within 24 h) returns the same
--    order reference and that order's tracking token, rotated (one token per
--    order), so a customer whose first response was lost still reaches
--    tracking. No other order data is returned.
-- 7. Public payload: next_open (weekday / time / days ahead) when closed, from
--    the business's own hours and timezone.
-- _create_public_order is unchanged (also used by submit_public_order).

create or replace function public._public_caller_key(p_action text)
 returns text
 language sql
 stable
 set search_path to 'public', 'extensions'
as $function$
  select encode(digest(p_action || ':' || coalesce(
    nullif(btrim(current_setting('request.headers', true)::json->>'sb-forwarded-for'), ''),
    nullif(btrim(current_setting('request.headers', true)::json->>'cf-connecting-ip'), ''),
    'unknown'), 'sha256'), 'hex')
$function$;

-- Next opening (business-local) when the store is closed now; null when it is
-- open, has no hours, or never opens.
create or replace function public._business_next_open(p_business_id uuid)
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to 'public'
as $function$
declare
  ts timestamp; d int; dow int; h business_hours;
begin
  if not exists (select 1 from business_hours where business_id = p_business_id) then return null; end if;
  if business_open_now(p_business_id) then return null; end if;
  select (now() at time zone coalesce(b.timezone, 'Asia/Kuala_Lumpur')) into ts from businesses b where b.id = p_business_id;
  for d in 0..7 loop
    dow := extract(isodow from (ts + make_interval(days => d)))::int;
    select * into h from business_hours where business_id = p_business_id and weekday = dow and is_open;
    if h.business_id is not null and (d > 0 or h.opens_at > ts::time) then
      return jsonb_build_object('weekday', dow, 'time', to_char(h.opens_at, 'HH24:MI'), 'in_days', d);
    end if;
  end loop;
  return null;
end $function$;

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
    'business', jsonb_build_object('name', b.name, 'area', nullif(trim(b.operating_area), '')),
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

create or replace function public.public_storefront(p_slug text)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public', 'extensions'
as $function$
declare page public_order_pages; allowed boolean;
begin
  begin
    allowed := check_rate_limit(_public_caller_key('public_storefront'), 'public_storefront', 60, 60);
  exception when others then allowed := false;  -- fail closed
  end;
  if not allowed then raise exception 'rate limited'; end if;
  page := _resolve_storefront(lower(btrim(coalesce(p_slug, ''))));
  if page.id is null then
    perform record_invalid_lookup_telemetry('public_storefront');
    return null;
  end if;
  return _storefront_payload(page);
end $function$;

create or replace function public.submit_storefront_order(p_slug text, p_items jsonb, p_customer_name text, p_customer_phone text, p_delivery_address text, p_delivery_notes text default ''::text, p_idempotency_key uuid default null::uuid)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public', 'extensions'
as $function$
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

  begin
    res := _create_public_order(page, p_items, p_customer_name, p_customer_phone,
                                p_delivery_address, p_delivery_notes, p_idempotency_key);
  exception when others then
    return jsonb_build_object('error', sqlerrm);
  end;
  return res;
end $function$;

revoke all on function public._business_next_open(uuid) from public, anon, authenticated;
