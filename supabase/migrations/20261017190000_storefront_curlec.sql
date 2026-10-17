-- Storefront payments move from CHIP to Curlec (Founder 2026-10-17), still on
-- the VENDOR's own account. Curlec (Razorpay API, api.razorpay.com/v1, Basic
-- auth key_id:key_secret) hosted Payment Links; Curlec's minimum link expiry
-- is 15 min, so Cefflo cancels the link itself after 5 minutes.
-- Tracking (Founder 2026-10-17): the customer gets the tracking link only once
-- the driver starts the delivery (storefront_order_status).
-- Rollback: restore 20261017180000 objects (CHIP columns / RPCs).
delete from public.vendor_payment_accounts;           -- staging only: no CHIP accounts kept
alter table public.vendor_payment_accounts drop constraint if exists vendor_payment_accounts_provider_check;
alter table public.vendor_payment_accounts drop constraint if exists vendor_payment_accounts_brand_id_check;
alter table public.vendor_payment_accounts drop constraint if exists vendor_payment_accounts_secret_key_check;
alter table public.vendor_payment_accounts rename column brand_id to key_id;
alter table public.vendor_payment_accounts rename column secret_key to key_secret;
alter table public.vendor_payment_accounts alter column provider set default 'curlec';
alter table public.vendor_payment_accounts add constraint vendor_payment_accounts_provider_check check (provider = 'curlec');
alter table public.vendor_payment_accounts add constraint vendor_payment_accounts_key_id_check check (key_id ~ '^rzp_(test|live)_[A-Za-z0-9]{8,32}$');
alter table public.vendor_payment_accounts add constraint vendor_payment_accounts_key_secret_check check (length(key_secret) between 16 and 128);
alter table public.storefront_payments rename column chip_purchase_id to provider_ref;

drop function if exists public.save_chip_account(uuid, text, text);
drop function if exists public.disconnect_chip_account(uuid);

create or replace function public.save_curlec_account(p_business_id uuid, p_key_id text, p_key_secret text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if btrim(coalesce(p_key_id, '')) !~ '^rzp_(test|live)_[A-Za-z0-9]{8,32}$' then raise exception 'invalid key id'; end if;
  if length(btrim(coalesce(p_key_secret, ''))) not between 16 and 128 then raise exception 'invalid key secret'; end if;
  insert into vendor_payment_accounts(business_id, provider, key_id, key_secret, connected_by)
    values (p_business_id, 'curlec', btrim(p_key_id), btrim(p_key_secret), auth.uid())
    on conflict (business_id) do update set key_id = excluded.key_id, key_secret = excluded.key_secret,
      connected_at = now(), connected_by = auth.uid();
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role) values (p_business_id, 'payments.curlec_connected', auth.uid(), 'vendor');
  return jsonb_build_object('connected', true);
end $$;
grant execute on function public.save_curlec_account(uuid, text, text) to authenticated;

create or replace function public.disconnect_curlec_account(p_business_id uuid) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  delete from vendor_payment_accounts where business_id = p_business_id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role) values (p_business_id, 'payments.curlec_disconnected', auth.uid(), 'vendor');
  return jsonb_build_object('connected', false);
end $$;
grant execute on function public.disconnect_curlec_account(uuid) to authenticated;

create or replace function public.payment_settings(p_business_id uuid) returns jsonb
language sql stable security definer set search_path to 'public' as $$
  select case when not is_business_member(p_business_id) then null else jsonb_build_object(
    'provider', 'curlec',
    'connected', a.business_id is not null,
    'key_hint', case when a.key_id is not null then left(a.key_id, 9) || '…' || right(a.key_id, 4) end,
    'test_mode', a.key_id like 'rzp_test_%',
    'connected_at', a.connected_at,
    'accept_cod', coalesce(p.accept_cod, true)) end
  from (select p_business_id id) x
  left join vendor_payment_accounts a on a.business_id = x.id
  left join public_order_pages p on p.business_id = x.id
$$;

-- Paid late (after Cefflo cancelled the window) but before the link died:
-- the money is real, so the order is reinstated rather than lost.
create or replace function public._storefront_mark_paid(p_payment_id uuid) returns void
language plpgsql security definer set search_path to 'public' as $$
declare r storefront_payments;
begin
  select * into r from storefront_payments where id = p_payment_id for update;
  if r.id is null or r.status = 'paid' then return; end if;
  update storefront_payments set status = 'paid', paid_at = now() where id = r.id;
  update orders set payment_status = 'paid',
         delivery_status = case when delivery_status = 'cancelled' and payment_status = 'expired' then 'created' else delivery_status end
   where id = r.order_id;
  update storefront_subscriptions set status = 'active' where first_order_id = r.order_id and status = 'cancelled';
  update storefront_subscription_days d set status = 'scheduled' from storefront_subscriptions s
   where d.subscription_id = s.id and s.first_order_id = r.order_id and d.status = 'skipped' and d.delivery_on > _my_today();
  insert into delivery_events(business_id, order_id, event_type, actor_role, metadata)
    values (r.business_id, r.order_id, 'payment.paid', 'system', jsonb_build_object('provider', 'curlec', 'ref', r.provider_ref, 'amount_cents', r.amount_cents));
end $$;
revoke all on function public._storefront_mark_paid(uuid) from public, anon, authenticated;
grant execute on function public._storefront_mark_paid(uuid) to service_role;

-- Customer order status. The tracking link is revealed only once the driver
-- has started the delivery; a fresh token is issued then, once per order.
alter table public.orders add column if not exists tracking_shared_at timestamptz;
create or replace function public.storefront_order_status(p_slug text, p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
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
      'tracking_shared', rec.tracking_shared_at is not null or tok is not null));
  end loop;
  return jsonb_build_object('orders', out,
    'upcoming', (select coalesce(jsonb_agg(jsonb_build_object('date', d.delivery_on, 'status', d.status) order by d.delivery_on), '[]')
                   from storefront_subscription_days d where d.subscription_id = sub and d.status = 'scheduled'));
end $$;
revoke all on function public.storefront_order_status(text, uuid) from public;
grant execute on function public.storefront_order_status(text, uuid) to anon, authenticated;

-- Every minute: curlec-sync (needs Vault secrets 'cefflo_functions_url' and
-- 'cefflo_cron_secret', the latter also set as the CEFFLO_CRON_SECRET function
-- secret). Skips quietly until both exist.
create or replace function public.storefront_curlec_sync_call() returns void
language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare url text; sec text;
begin
  select decrypted_secret into url from vault.decrypted_secrets where name = 'cefflo_functions_url';
  select decrypted_secret into sec from vault.decrypted_secrets where name = 'cefflo_cron_secret';
  if url is null or sec is null then return; end if;
  perform net.http_post(url || '/curlec-sync', '{}'::jsonb, '{}'::jsonb, jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', sec), 20000);
end $$;
revoke all on function public.storefront_curlec_sync_call() from public, anon, authenticated;
do $$ begin
  perform cron.unschedule('storefront-curlec-sync') where exists (select 1 from cron.job where jobname = 'storefront-curlec-sync');
  perform cron.schedule('storefront-curlec-sync', '* * * * *', 'select public.storefront_curlec_sync_call()');
end $$;
