-- Courier shipping for storefront orders (Founder 2026-10-17): outside the
-- rider radius, the vendor's own EasyParcel account ships the parcel. Rates
-- are quoted live at checkout (courier-rates); after payment (or at once for
-- COD) courier-book submits and pays the EasyParcel order automatically and
-- stores the AWB, label and tracking link. The vendor presses nothing.
-- Courier orders are not planned into rider runs.
-- Rollback: drop the courier objects below; restore payload / submit /
-- storefront_order_status bodies from 20261017200000 / 20261017190000.
create table if not exists public.vendor_courier_accounts (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  provider text not null default 'easyparcel' check (provider = 'easyparcel'),
  api_key text not null check (length(api_key) between 10 and 100),
  demo boolean not null default false,
  pickup_name text not null, pickup_phone text not null, pickup_address text not null,
  pickup_city text not null, pickup_postcode text not null check (pickup_postcode ~ '^[0-9]{5}$'),
  pickup_state text not null check (pickup_state in ('jhr','kdh','ktn','mlk','nsn','phg','prk','pls','png','sgr','trg','kul','pjy','srw','sbh','lbn')),
  connected_at timestamptz not null default now(), connected_by uuid
);
alter table public.vendor_courier_accounts enable row level security;
revoke all on public.vendor_courier_accounts from anon, authenticated;

create table if not exists public.storefront_shipments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_id uuid not null unique references public.orders(id) on delete cascade,
  service_id text not null, courier_name text, price numeric(10,2),
  send_city text not null, send_postcode text not null, send_state text not null,
  weight_kg numeric(6,3),
  status text not null default 'waiting' check (status in ('waiting', 'booked', 'failed', 'cancelled')),
  ep_order_no text, awb text, label_url text, tracking_url text, last_status text,
  error text, attempts int not null default 0, updated_at timestamptz not null default now(), created_at timestamptz not null default now()
);
alter table public.storefront_shipments enable row level security;
drop policy if exists storefront_shipments_member_read on public.storefront_shipments;
create policy storefront_shipments_member_read on public.storefront_shipments for select to authenticated using (is_business_member(business_id));
revoke all on public.storefront_shipments from anon;
grant select on public.storefront_shipments to authenticated;

create or replace function public._queue_storefront_shipment(page public_order_pages, p_key uuid, p_courier jsonb)
returns void language plpgsql security definer set search_path to 'public' as $$
declare o orders;
begin
  select * into o from orders where business_id = page.business_id and submission_idempotency_key = p_key;
  if o.id is null then return; end if;
  insert into storefront_shipments(business_id, order_id, service_id, courier_name, price, send_city, send_postcode, send_state)
    values (page.business_id, o.id, p_courier->>'service_id', left(p_courier->>'courier_name', 80), (p_courier->>'price')::numeric,
            left(btrim(p_courier->>'city'), 80), p_courier->>'postcode', p_courier->>'state')
    on conflict (order_id) do nothing;
  -- Not a rider drop: keep it out of run planning.
  delete from delivery_stops where order_id = o.id and assignment_id is null;
  update orders set notes = left(coalesce(notes, '') || E'\nCourier: ' || coalesce(p_courier->>'courier_name', 'courier') || ' (booked automatically after payment)', 500)
   where id = o.id;
end $$;
revoke all on function public._queue_storefront_shipment(public_order_pages, uuid, jsonb) from public, anon, authenticated;

create or replace function public.save_courier_account(p_business_id uuid, p_api_key text, p_demo boolean, p_pickup jsonb)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if length(btrim(coalesce(p_api_key, ''))) not between 10 and 100 then raise exception 'invalid api key'; end if;
  insert into vendor_courier_accounts(business_id, api_key, demo, pickup_name, pickup_phone, pickup_address, pickup_city, pickup_postcode, pickup_state, connected_by)
    values (p_business_id, btrim(p_api_key), coalesce(p_demo, false), btrim(p_pickup->>'name'), btrim(p_pickup->>'phone'), btrim(p_pickup->>'address'),
            btrim(p_pickup->>'city'), btrim(p_pickup->>'postcode'), btrim(p_pickup->>'state'), auth.uid())
    on conflict (business_id) do update set api_key = excluded.api_key, demo = excluded.demo, pickup_name = excluded.pickup_name,
      pickup_phone = excluded.pickup_phone, pickup_address = excluded.pickup_address, pickup_city = excluded.pickup_city,
      pickup_postcode = excluded.pickup_postcode, pickup_state = excluded.pickup_state, connected_at = now(), connected_by = auth.uid();
  return jsonb_build_object('connected', true);
end $$;
grant execute on function public.save_courier_account(uuid, text, boolean, jsonb) to authenticated;

create or replace function public.disconnect_courier_account(p_business_id uuid) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  delete from vendor_courier_accounts where business_id = p_business_id;
  return jsonb_build_object('connected', false);
end $$;
grant execute on function public.disconnect_courier_account(uuid) to authenticated;

create or replace function public.courier_settings(p_business_id uuid) returns jsonb
language sql stable security definer set search_path to 'public' as $$
  select case when not is_business_member(p_business_id) then null else coalesce((select jsonb_build_object(
    'connected', true, 'provider', 'easyparcel', 'demo', c.demo, 'key_hint', '…' || right(c.api_key, 4),
    'pickup', jsonb_build_object('name', c.pickup_name, 'phone', c.pickup_phone, 'address', c.pickup_address,
      'city', c.pickup_city, 'postcode', c.pickup_postcode, 'state', c.pickup_state))
    from vendor_courier_accounts c where c.business_id = p_business_id), jsonb_build_object('connected', false)) end
$$;
grant execute on function public.courier_settings(uuid) to authenticated;

-- Every minute: courier-book (same Vault secrets as curlec-sync).
create or replace function public.storefront_courier_book_call() returns void
language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare url text; sec text;
begin
  if not exists (select 1 from storefront_shipments s join orders o on o.id = s.order_id
                  where s.status = 'waiting' and o.payment_status = 'paid' and s.attempts < 10)
     and not exists (select 1 from storefront_shipments where status = 'booked' and last_status is distinct from 'Successfully Delivered') then
    return;
  end if;
  select decrypted_secret into url from vault.decrypted_secrets where name = 'cefflo_functions_url';
  select decrypted_secret into sec from vault.decrypted_secrets where name = 'cefflo_cron_secret';
  if url is null or sec is null then return; end if;
  perform net.http_post(url || '/courier-book', '{}'::jsonb, '{}'::jsonb, jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', sec), 30000);
end $$;
revoke all on function public.storefront_courier_book_call() from public, anon, authenticated;
do $$ begin
  perform cron.unschedule('storefront-courier-book') where exists (select 1 from cron.job where jobname = 'storefront-courier-book');
  perform cron.schedule('storefront-courier-book', '* * * * *', 'select public.storefront_courier_book_call()');
end $$;
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
    'courier', jsonb_build_object('enabled', exists (select 1 from vendor_courier_accounts c where c.business_id = page.business_id)),
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
drop function if exists public.submit_storefront_order(text, jsonb, text, text, text, text, uuid, double precision, double precision, numeric, text, jsonb, text);
CREATE OR REPLACE FUNCTION public.submit_storefront_order(p_slug text, p_items jsonb, p_customer_name text, p_customer_phone text, p_delivery_address text, p_delivery_notes text DEFAULT ''::text, p_idempotency_key uuid DEFAULT NULL::uuid, p_latitude double precision DEFAULT NULL::double precision, p_longitude double precision DEFAULT NULL::double precision, p_location_accuracy_m numeric DEFAULT NULL::numeric, p_location_source text DEFAULT NULL::text, p_plan jsonb DEFAULT NULL::jsonb, p_payment text DEFAULT 'cod'::text, p_courier jsonb DEFAULT NULL::jsonb)
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
  -- Courier (Founder 2026-10-17): outside the rider radius the customer may
  -- ship by the vendor's EasyParcel courier; the shipment is booked after payment.
  if p_courier is not null then
    if not exists (select 1 from vendor_courier_accounts c where c.business_id = page.business_id) then
      return jsonb_build_object('error', 'courier unavailable');
    end if;
    if coalesce(p_courier->>'service_id', '') !~ '^[A-Za-z0-9-]{3,40}$' or coalesce(p_courier->>'postcode', '') !~ '^[0-9]{5}$'
       or coalesce(p_courier->>'state', '') not in ('jhr','kdh','ktn','mlk','nsn','phg','prk','pls','png','sgr','trg','kul','pjy','srw','sbh','lbn')
       or coalesce(p_courier->>'city', '') = '' or (p_courier->>'price')::numeric not between 0 and 2000 then
      return jsonb_build_object('error', 'invalid courier');
    end if;
    if p_plan is not null and coalesce(p_plan->>'weeks', 'once') <> 'once' then
      return jsonb_build_object('error', 'invalid courier');
    end if;
    if coalesce(p_payment, 'cod') <> 'online' then return jsonb_build_object('error', 'courier needs online payment'); end if;
  elsif _storefront_covers(page, p_latitude, p_longitude) is false then
    return jsonb_build_object('error', 'outside coverage');
  end if;
  if p_courier is null and p_latitude is null and exists (select 1 from businesses b where b.id = page.business_id and b.service_coverage_radius_km is not null) then
    return jsonb_build_object('error', 'invalid delivery pin');
  end if;

  -- Payment (Founder 2026-10-17): online needs the vendor's own CHIP account;
  -- cash on delivery only when the vendor allows it or has no CHIP account.
  if coalesce(p_payment, 'cod') not in ('cod', 'online') then return jsonb_build_object('error', 'invalid payment'); end if;
  if p_payment = 'online' and not exists (select 1 from vendor_payment_accounts a where a.business_id = page.business_id) then
    return jsonb_build_object('error', 'online payment unavailable');
  end if;
  if coalesce(p_payment, 'cod') = 'cod' and not page.accept_cod and exists (select 1 from vendor_payment_accounts a where a.business_id = page.business_id) then
    return jsonb_build_object('error', 'cash on delivery unavailable');
  end if;

  begin
    res := _create_public_order(page, p_items, p_customer_name, p_customer_phone,
                                p_delivery_address, p_delivery_notes, p_idempotency_key);
  exception when others then
    return jsonb_build_object('error', sqlerrm);
  end;

  -- Subscription package (Founder 2026-10-17): the first delivery is this
  -- order; the rest are created on their day by storefront_subscription_tick.
  if p_plan is not null and coalesce(p_plan->>'weeks', 'once') <> 'once' and coalesce((res->>'replay')::boolean, false) is false then
    perform _start_storefront_subscription(page, p_plan, p_items, p_customer_name, p_customer_phone,
      p_delivery_address, p_delivery_notes, p_latitude, p_longitude, p_idempotency_key);
  end if;

  if p_latitude is not null and res ? 'order_reference' and p_idempotency_key is not null then
    update public.orders
       set latitude = round(p_latitude::numeric, 6), longitude = round(p_longitude::numeric, 6),
           location_accuracy_m = case when p_location_accuracy_m between 0 and 100000 then round(p_location_accuracy_m) end,
           location_source = coalesce(p_location_source, 'map'),
           location_status = 'resolved', location_provider = 'customer_pin',
           location_resolved_at = now(), location_error = null
     where business_id = page.business_id and submission_idempotency_key = p_idempotency_key;
  end if;
  if p_courier is not null and res ? 'order_reference' and coalesce((res->>'replay')::boolean, false) is false then
    perform _queue_storefront_shipment(page, p_idempotency_key, p_courier);
  end if;
  if res ? 'order_reference' and coalesce((res->>'replay')::boolean, false) is false then
    update public.orders set payment_status = case when p_payment = 'online' then 'awaiting_payment' else 'cod' end
     where business_id = page.business_id and submission_idempotency_key = p_idempotency_key;
  end if;
  return res;
end $function$;
grant execute on function public.submit_storefront_order(text, jsonb, text, text, text, text, uuid, double precision, double precision, numeric, text, jsonb, text, jsonb) to anon, authenticated;
CREATE OR REPLACE FUNCTION public.storefront_order_status(p_slug text, p_idempotency_key uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare page public_order_pages; o orders; allowed boolean; tok text; out jsonb := '[]'::jsonb; sub uuid; rec record;
begin
  begin
    allowed := check_rate_limit(_public_caller_key('storefront_order_status'), 'storefront_order_status', 60, 30);
  exception when others then allowed := false;
  end;
  if not allowed then return jsonb_build_object('error', 'rate limited'); end if;
  page := _resolve_storefront(lower(btrim(coalesce(p_slug, ''))));
  if page.id is null then return null; end if;
  select * into o from orders where business_id = page.business_id and submission_idempotency_key = p_idempotency_key;
  if o.id is null then return null; end if;
  select id into sub from storefront_subscriptions where first_order_id = o.id;
  for rec in
    select x.* from orders x where x.id = o.id
    union all
    select x.* from storefront_subscription_days d join orders x on x.id = d.order_id
     where sub is not null and d.subscription_id = sub and x.id <> o.id
  loop
    tok := null;
    -- Started = the driver slid Start delivery (stop sequence locked) or later.
    if rec.tracking_shared_at is null and (rec.delivery_status in ('out_for_delivery', 'arrived', 'delivered')
        or exists (select 1 from delivery_stops st where st.order_id = rec.id and st.sequence_locked_at is not null)) then
      tok := encode(gen_random_bytes(32), 'hex');
      update tracking_tokens set token_hash = encode(digest(tok, 'sha256'), 'hex'), revoked_at = null where order_id = rec.id;
      if not found then insert into tracking_tokens(order_id, token_hash) values (rec.id, encode(digest(tok, 'sha256'), 'hex')); end if;
      update orders set tracking_shared_at = now() where id = rec.id;
    end if;
    out := out || jsonb_build_array(jsonb_build_object('ref', rec.public_ref, 'date', rec.order_date,
      'status', rec.delivery_status, 'payment', rec.payment_status, 'tracking_token', tok,
      'tracking_shared', rec.tracking_shared_at is not null or tok is not null,
      'courier', (select jsonb_build_object('name', sh.courier_name, 'status', sh.status, 'awb', sh.awb,
                   'tracking_url', sh.tracking_url, 'last_status', sh.last_status)
                    from storefront_shipments sh where sh.order_id = rec.id)));
  end loop;
  return jsonb_build_object('orders', out,
    'upcoming', (select coalesce(jsonb_agg(jsonb_build_object('date', d.delivery_on, 'status', d.status) order by d.delivery_on), '[]')
                   from storefront_subscription_days d where d.subscription_id = sub and d.status = 'scheduled'));
end $function$;
