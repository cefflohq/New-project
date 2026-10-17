-- Storefront online payment through the vendor's own CHIP account
-- (Founder 2026-10-17). Cefflo never holds the money: CHIP pays the vendor.
-- Secrets live in vendor_payment_accounts, readable only by service_role
-- (edge functions). 5-minute payment window; unpaid orders are cancelled.
-- Rollback: unschedule 'storefront-payment-expiry'; drop storefront_payments,
-- vendor_payment_accounts, the RPCs below and accept_cod; restore payload and
-- submit_storefront_order without p_payment.
alter table public.public_order_pages add column if not exists accept_cod boolean not null default true;

create table if not exists public.vendor_payment_accounts (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  provider text not null default 'chip' check (provider = 'chip'),
  brand_id text not null check (brand_id ~ '^[0-9a-fA-F-]{36}$'),
  secret_key text not null check (length(secret_key) between 20 and 512),
  connected_at timestamptz not null default now(),
  connected_by uuid
);
alter table public.vendor_payment_accounts enable row level security;
revoke all on public.vendor_payment_accounts from anon, authenticated;

create table if not exists public.storefront_payments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  chip_purchase_id text unique,
  amount_cents bigint not null check (amount_cents > 0),
  status text not null default 'pending' check (status in ('pending', 'paid', 'expired', 'failed')),
  expires_at timestamptz not null default now() + interval '5 minutes',
  paid_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists storefront_payments_pending on public.storefront_payments (expires_at) where status = 'pending';
alter table public.storefront_payments enable row level security;
drop policy if exists storefront_payments_member_read on public.storefront_payments;
create policy storefront_payments_member_read on public.storefront_payments for select to authenticated using (is_business_member(business_id));
revoke all on public.storefront_payments from anon;
grant select on public.storefront_payments to authenticated;

-- Owner / Operator connects CHIP. The secret is never returned.
create or replace function public.save_chip_account(p_business_id uuid, p_brand_id text, p_secret_key text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if p_brand_id !~ '^[0-9a-fA-F-]{36}$' then raise exception 'invalid brand id'; end if;
  if length(coalesce(p_secret_key, '')) not between 20 and 512 then raise exception 'invalid secret key'; end if;
  insert into vendor_payment_accounts(business_id, brand_id, secret_key, connected_by)
    values (p_business_id, p_brand_id, btrim(p_secret_key), auth.uid())
    on conflict (business_id) do update set brand_id = excluded.brand_id, secret_key = excluded.secret_key,
      connected_at = now(), connected_by = auth.uid();
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role) values (p_business_id, 'payments.chip_connected', auth.uid(), 'vendor');
  return jsonb_build_object('connected', true);
end $$;
grant execute on function public.save_chip_account(uuid, text, text) to authenticated;

create or replace function public.disconnect_chip_account(p_business_id uuid) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  delete from vendor_payment_accounts where business_id = p_business_id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role) values (p_business_id, 'payments.chip_disconnected', auth.uid(), 'vendor');
  return jsonb_build_object('connected', false);
end $$;
grant execute on function public.disconnect_chip_account(uuid) to authenticated;

create or replace function public.payment_settings(p_business_id uuid) returns jsonb
language sql stable security definer set search_path to 'public' as $$
  select case when not is_business_member(p_business_id) then null else jsonb_build_object(
    'connected', a.business_id is not null,
    'brand_id_hint', case when a.brand_id is not null then '…' || right(a.brand_id, 4) end,
    'connected_at', a.connected_at,
    'accept_cod', coalesce(p.accept_cod, true)) end
  from (select p_business_id id) x
  left join vendor_payment_accounts a on a.business_id = x.id
  left join public_order_pages p on p.business_id = x.id
$$;
grant execute on function public.payment_settings(uuid) to authenticated;

create or replace function public.set_storefront_cod(p_business_id uuid, p_accept boolean) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  update public_order_pages set accept_cod = coalesce(p_accept, true), updated_at = now() where business_id = p_business_id;
  return jsonb_build_object('accept_cod', coalesce(p_accept, true));
end $$;
grant execute on function public.set_storefront_cod(uuid, boolean) to authenticated;

-- Unpaid after the 5-minute window: cancel the order (and its package).
create or replace function public.storefront_payment_expiry() returns int
language plpgsql security definer set search_path to 'public' as $$
declare n int := 0; r record;
begin
  for r in select * from storefront_payments where status = 'pending' and expires_at < now() - interval '2 minutes' for update skip locked loop
    update storefront_payments set status = 'expired' where id = r.id;
    update orders set payment_status = 'expired', delivery_status = 'cancelled' where id = r.order_id and payment_status = 'awaiting_payment';
    update storefront_subscriptions set status = 'cancelled' where first_order_id = r.order_id;
    update storefront_subscription_days d set status = 'skipped' from storefront_subscriptions s
     where d.subscription_id = s.id and s.first_order_id = r.order_id and d.status = 'scheduled';
    n := n + 1;
  end loop;
  return n;
end $$;
revoke all on function public.storefront_payment_expiry() from public, anon, authenticated;
do $$ begin
  perform cron.unschedule('storefront-payment-expiry') where exists (select 1 from cron.job where jobname = 'storefront-payment-expiry');
  perform cron.schedule('storefront-payment-expiry', '* * * * *', 'select public.storefront_payment_expiry()');
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
    'payments', jsonb_build_object(
      'online', exists (select 1 from vendor_payment_accounts a where a.business_id = page.business_id),
      'cod', page.accept_cod or not exists (select 1 from vendor_payment_accounts a where a.business_id = page.business_id)),
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
drop function if exists public.submit_storefront_order(text, jsonb, text, text, text, text, uuid, double precision, double precision, numeric, text, jsonb);
CREATE OR REPLACE FUNCTION public.submit_storefront_order(p_slug text, p_items jsonb, p_customer_name text, p_customer_phone text, p_delivery_address text, p_delivery_notes text DEFAULT ''::text, p_idempotency_key uuid DEFAULT NULL::uuid, p_latitude double precision DEFAULT NULL::double precision, p_longitude double precision DEFAULT NULL::double precision, p_location_accuracy_m numeric DEFAULT NULL::numeric, p_location_source text DEFAULT NULL::text, p_plan jsonb DEFAULT NULL::jsonb, p_payment text DEFAULT 'cod'::text)
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
  if res ? 'order_reference' and coalesce((res->>'replay')::boolean, false) is false then
    update public.orders set payment_status = case when p_payment = 'online' then 'awaiting_payment' else 'cod' end
     where business_id = page.business_id and submission_idempotency_key = p_idempotency_key;
  end if;
  return res;
end $function$;
grant execute on function public.submit_storefront_order(text, jsonb, text, text, text, text, uuid, double precision, double precision, numeric, text, jsonb, text) to anon, authenticated;
