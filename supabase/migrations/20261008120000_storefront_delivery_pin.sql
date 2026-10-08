-- Storefront delivery pin (Founder 2026-10-08, docs/cefflo/security/DELIVERY_PIN_AND_PLACE_PHOTOS_PROPOSAL.md).
-- The customer pins the exact drop point on an OpenStreetMap map (GPS + drag);
-- coordinates go to the existing orders.latitude/longitude. Photos were dropped
-- by the Founder: the delivery note carries the clues. Riders already read
-- orders.* for their assigned orders (RLS unchanged).
alter table public.orders
  add column if not exists location_accuracy_m numeric,
  add column if not exists location_source text;
alter table public.orders drop constraint if exists orders_location_source_check;
alter table public.orders add constraint orders_location_source_check
  check (location_source is null or location_source in ('gps', 'pin_adjusted', 'map', 'vendor'));

drop function if exists public.submit_storefront_order(text, jsonb, text, text, text, text, uuid);

CREATE OR REPLACE FUNCTION public.submit_storefront_order(p_slug text, p_items jsonb, p_customer_name text, p_customer_phone text, p_delivery_address text, p_delivery_notes text DEFAULT ''::text, p_idempotency_key uuid DEFAULT NULL::uuid, p_latitude double precision DEFAULT NULL, p_longitude double precision DEFAULT NULL, p_location_accuracy_m numeric DEFAULT NULL, p_location_source text DEFAULT NULL)
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
           location_source = coalesce(p_location_source, 'map')
     where business_id = page.business_id and submission_idempotency_key = p_idempotency_key;
  end if;
  return res;
end $function$;

revoke all on function public.submit_storefront_order(text, jsonb, text, text, text, text, uuid, double precision, double precision, numeric, text) from public;
grant execute on function public.submit_storefront_order(text, jsonb, text, text, text, text, uuid, double precision, double precision, numeric, text) to anon, authenticated, service_role;
