-- Integrations Phase 1 (Founder-approved 2026-10-08, staging first).
-- See docs/cefflo/security/INTEGRATIONS_PHASE1_PROPOSAL.md.
--
-- API keys, WooCommerce and Shopify (custom-app) webhooks create normal
-- Cefflo orders (origin 'integration'). Secrets live in Supabase Vault; API
-- keys are stored as SHA-256 hashes only. Vendor actions are Owner/Operator
-- RPCs; the inbound Edge Function calls service-role-only internals.

alter table public.orders drop constraint if exists orders_origin_check;
alter table public.orders add constraint orders_origin_check
  check (origin = any (array['vendor'::text, 'public'::text, 'integration'::text]));

create table public.integration_connections (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  provider text not null check (provider in ('api', 'woocommerce', 'shopify')),
  status text not null default 'active' check (status in ('active', 'revoked')),
  shop_domain text,
  secret_id uuid,                       -- vault.secrets.id; never exposed
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  revoked_by uuid references auth.users(id) on delete set null,
  revoked_at timestamptz,
  last_event_at timestamptz
);
create unique index integration_connections_one_active
  on public.integration_connections(business_id, provider) where status = 'active';

create table public.integration_api_keys (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.integration_connections(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  key_prefix text not null,
  key_hash text not null unique,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  last_used_at timestamptz
);

create table public.integration_events (
  id bigserial primary key,
  connection_id uuid not null references public.integration_connections(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  external_id text,
  outcome text not null check (outcome in ('created', 'duplicate', 'rejected')),
  reason text,
  order_id uuid references public.orders(id) on delete set null,
  received_at timestamptz not null default now()
);
create unique index integration_events_dedup
  on public.integration_events(connection_id, external_id) where outcome = 'created';

alter table public.integration_connections enable row level security;
alter table public.integration_api_keys enable row level security;
alter table public.integration_events enable row level security;
revoke all on public.integration_connections, public.integration_api_keys, public.integration_events from anon, authenticated;

-- Read models for Owner/Operator: no secret ids, no key hashes.
create or replace function public.integration_list(p_business uuid)
returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
begin
  if not is_business_member(p_business) then raise exception 'forbidden'; end if;
  return jsonb_build_object(
    'connections', coalesce((select jsonb_agg(jsonb_build_object(
        'id', c.id, 'provider', c.provider, 'status', c.status, 'shop_domain', c.shop_domain,
        'created_at', c.created_at, 'last_event_at', c.last_event_at) order by c.created_at desc)
      from integration_connections c where c.business_id = p_business and c.status = 'active'), '[]'::jsonb),
    'api_keys', coalesce((select jsonb_agg(jsonb_build_object(
        'id', k.id, 'prefix', k.key_prefix, 'created_at', k.created_at, 'last_used_at', k.last_used_at) order by k.created_at desc)
      from integration_api_keys k where k.business_id = p_business and k.revoked_at is null), '[]'::jsonb),
    'events', coalesce((select jsonb_agg(e order by e.received_at desc) from (
        select jsonb_build_object('provider', c.provider, 'outcome', ev.outcome, 'reason', ev.reason,
          'external_id', ev.external_id, 'received_at', ev.received_at) as e, ev.received_at
        from integration_events ev join integration_connections c on c.id = ev.connection_id
        where ev.business_id = p_business order by ev.received_at desc limit 20) x), '[]'::jsonb));
end $$;

create or replace function public._integration_connection(p_business uuid, p_provider text, p_domain text, p_secret text)
returns uuid language plpgsql security definer set search_path to 'public', 'vault' as $$
declare cid uuid; sid uuid;
begin
  update integration_connections set status = 'revoked', revoked_at = now(), revoked_by = auth.uid()
    where business_id = p_business and provider = p_provider and status = 'active'
    returning secret_id into sid;
  if sid is not null then delete from vault.secrets where id = sid; end if;
  if p_secret is not null then
    sid := vault.create_secret(p_secret, 'integration:' || p_provider || ':' || p_business::text || ':' || gen_random_uuid()::text);
  else sid := null; end if;
  insert into integration_connections(business_id, provider, shop_domain, secret_id, created_by)
    values (p_business, p_provider, p_domain, sid, auth.uid()) returning id into cid;
  return cid;
end $$;

create or replace function public.integration_create_api_key(p_business uuid)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare cid uuid; k text; kid uuid;
begin
  if not is_business_member(p_business) then raise exception 'forbidden'; end if;
  select id into cid from integration_connections where business_id = p_business and provider = 'api' and status = 'active';
  if cid is null then
    insert into integration_connections(business_id, provider, created_by) values (p_business, 'api', auth.uid()) returning id into cid;
  end if;
  if (select count(*) from integration_api_keys where business_id = p_business and revoked_at is null) >= 5 then
    raise exception 'too many active keys';
  end if;
  k := 'cfk_live_' || encode(gen_random_bytes(24), 'hex');
  insert into integration_api_keys(connection_id, business_id, key_prefix, key_hash, created_by)
    values (cid, p_business, left(k, 17), encode(digest(k, 'sha256'), 'hex'), auth.uid()) returning id into kid;
  return jsonb_build_object('id', kid, 'key', k, 'prefix', left(k, 17));
end $$;

create or replace function public.integration_revoke_api_key(p_key uuid)
returns void language plpgsql security definer set search_path to 'public' as $$
declare b uuid;
begin
  select business_id into b from integration_api_keys where id = p_key;
  if b is null or not is_business_member(b) then raise exception 'forbidden'; end if;
  update integration_api_keys set revoked_at = now() where id = p_key and revoked_at is null;
end $$;

create or replace function public.integration_connect_woocommerce(p_business uuid, p_store_url text, p_webhook_secret text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare u text := lower(btrim(coalesce(p_store_url, ''))); cid uuid;
begin
  if not is_business_member(p_business) then raise exception 'forbidden'; end if;
  if u !~ '^https://[a-z0-9.-]+\.[a-z]{2,}(/.*)?$' then raise exception 'invalid store url'; end if;
  if char_length(coalesce(p_webhook_secret, '')) not between 8 and 200 then raise exception 'invalid webhook secret'; end if;
  cid := _integration_connection(p_business, 'woocommerce', regexp_replace(u, '/+$', ''), p_webhook_secret);
  return jsonb_build_object('id', cid);
end $$;

create or replace function public.integration_connect_shopify(p_business uuid, p_shop_domain text, p_webhook_secret text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare d text := lower(btrim(coalesce(p_shop_domain, ''))); cid uuid;
begin
  if not is_business_member(p_business) then raise exception 'forbidden'; end if;
  d := regexp_replace(regexp_replace(d, '^https?://', ''), '/.*$', '');
  if d !~ '^[a-z0-9][a-z0-9-]*\.myshopify\.com$' then raise exception 'invalid shop domain'; end if;
  if char_length(coalesce(p_webhook_secret, '')) not between 8 and 200 then raise exception 'invalid webhook secret'; end if;
  cid := _integration_connection(p_business, 'shopify', d, p_webhook_secret);
  return jsonb_build_object('id', cid);
end $$;

create or replace function public.integration_disconnect(p_connection uuid)
returns void language plpgsql security definer set search_path to 'public', 'vault' as $$
declare c integration_connections;
begin
  select * into c from integration_connections where id = p_connection;
  if c.id is null or not is_business_member(c.business_id) then raise exception 'forbidden'; end if;
  update integration_connections set status = 'revoked', revoked_at = now(), revoked_by = auth.uid(), secret_id = null where id = c.id;
  if c.secret_id is not null then delete from vault.secrets where id = c.secret_id; end if;
  update integration_api_keys set revoked_at = now() where connection_id = c.id and revoked_at is null;
end $$;

-- ---------- service-role internals for the integrations-inbound Edge Function ----------

-- Resolve an API key (hash) → connection; null when unknown/revoked.
create or replace function public._integration_resolve_key(p_key_hash text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare k integration_api_keys; c integration_connections;
begin
  select * into k from integration_api_keys where key_hash = p_key_hash and revoked_at is null;
  if k.id is null then return null; end if;
  select * into c from integration_connections where id = k.connection_id and status = 'active';
  if c.id is null then return null; end if;
  update integration_api_keys set last_used_at = now() where id = k.id;
  return jsonb_build_object('connection_id', c.id, 'business_id', c.business_id, 'key_id', k.id);
end $$;

-- Webhook connection + its decrypted secret (service role only).
create or replace function public._integration_webhook_target(p_connection uuid, p_provider text)
returns jsonb language plpgsql security definer set search_path to 'public', 'vault' as $$
declare c integration_connections; s text;
begin
  select * into c from integration_connections where id = p_connection and provider = p_provider and status = 'active';
  if c.id is null or c.secret_id is null then return null; end if;
  select decrypted_secret into s from vault.decrypted_secrets where id = c.secret_id;
  return jsonb_build_object('connection_id', c.id, 'business_id', c.business_id, 'shop_domain', c.shop_domain, 'secret', s);
end $$;

create or replace function public._integration_reject(p_connection uuid, p_external text, p_reason text)
returns void language sql security definer set search_path to 'public' as $$
  insert into integration_events(connection_id, business_id, external_id, outcome, reason)
  select id, business_id, left(p_external, 120), 'rejected', left(p_reason, 200) from integration_connections where id = p_connection
$$;

-- Normalised order → Cefflo order. Business comes ONLY from the connection.
-- p_order: {customer_name, customer_phone, delivery_address, notes,
--           items:[{name, quantity, price}]}
create or replace function public._integration_ingest_order(p_connection uuid, p_external_id text, p_order jsonb)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare
  c integration_connections; ext text := left(btrim(coalesce(p_external_id, '')), 120);
  prev integration_events; item jsonb; items jsonb := '[]'::jsonb; n int := 0;
  nm text; ph text; addr text; nt text; q int; pr numeric; o orders; t text;
begin
  select * into c from integration_connections where id = p_connection and status = 'active';
  if c.id is null then return jsonb_build_object('error', 'unknown connection'); end if;
  if ext = '' then return jsonb_build_object('error', 'missing external id'); end if;

  select * into prev from integration_events where connection_id = c.id and external_id = ext and outcome = 'created';
  if prev.id is not null then
    insert into integration_events(connection_id, business_id, external_id, outcome, order_id) values (c.id, c.business_id, ext, 'duplicate', prev.order_id);
    return jsonb_build_object('duplicate', true, 'order_id', prev.order_id);
  end if;

  nm := btrim(coalesce(p_order->>'customer_name', ''));
  ph := regexp_replace(coalesce(p_order->>'customer_phone', ''), '[\s().-]', '', 'g');
  addr := btrim(coalesce(p_order->>'delivery_address', ''));
  nt := left(btrim(coalesce(p_order->>'notes', '')), 500);
  if char_length(nm) not between 1 and 120 then perform _integration_reject(c.id, ext, 'invalid customer name'); return jsonb_build_object('error', 'invalid customer name'); end if;
  if ph !~ '^\+?[0-9]{7,15}$' then perform _integration_reject(c.id, ext, 'invalid customer phone'); return jsonb_build_object('error', 'invalid customer phone'); end if;
  if char_length(addr) not between 1 and 500 then perform _integration_reject(c.id, ext, 'invalid delivery address'); return jsonb_build_object('error', 'invalid delivery address'); end if;
  if jsonb_typeof(p_order->'items') <> 'array' or jsonb_array_length(p_order->'items') not between 1 and 50 then
    perform _integration_reject(c.id, ext, 'invalid item list'); return jsonb_build_object('error', 'invalid item list');
  end if;
  for item in select * from jsonb_array_elements(p_order->'items') loop
    n := n + 1;
    begin
      q := (item->>'quantity')::int; pr := coalesce((item->>'price')::numeric, 0);
    exception when others then
      perform _integration_reject(c.id, ext, 'malformed item'); return jsonb_build_object('error', 'malformed item');
    end;
    if q is null or q < 1 or q > 999 or pr < 0 or pr > 1000000 or char_length(btrim(coalesce(item->>'name', ''))) not between 1 and 200 then
      perform _integration_reject(c.id, ext, 'malformed item'); return jsonb_build_object('error', 'malformed item');
    end if;
    items := items || jsonb_build_array(jsonb_build_object(
      'name', btrim(item->>'name'), 'qty', q,
      'product_id', null, 'product_name_snapshot', btrim(item->>'name'),
      'display_price_snapshot', round(pr, 2), 'quantity', q, 'line_subtotal_snapshot', round(pr * q, 2)));
  end loop;

  insert into orders(business_id, customer_name, customer_phone, delivery_address, notes, items, origin)
    values (c.business_id, nm, ph, addr, nt, items, 'integration') returning * into o;
  insert into delivery_stops(business_id, order_id) values (c.business_id, o.id);
  t := encode(gen_random_bytes(32), 'hex');
  insert into tracking_tokens(order_id, token_hash) values (o.id, encode(digest(t, 'sha256'), 'hex'));
  insert into delivery_events(business_id, order_id, event_type, to_status, actor_role)
    values (c.business_id, o.id, 'delivery.created', 'created', 'integration');
  insert into integration_events(connection_id, business_id, external_id, outcome, order_id) values (c.id, c.business_id, ext, 'created', o.id);
  update integration_connections set last_event_at = now() where id = c.id;
  return jsonb_build_object('order_id', o.id, 'order_reference', o.public_ref);
exception when unique_violation then
  return jsonb_build_object('duplicate', true);
end $$;

revoke all on function public._integration_connection(uuid, text, text, text) from public, anon, authenticated;
revoke all on function public._integration_resolve_key(text) from public, anon, authenticated;
revoke all on function public._integration_webhook_target(uuid, text) from public, anon, authenticated;
revoke all on function public._integration_reject(uuid, text, text) from public, anon, authenticated;
revoke all on function public._integration_ingest_order(uuid, text, jsonb) from public, anon, authenticated;
grant execute on function public._integration_resolve_key(text) to service_role;
grant execute on function public._integration_webhook_target(uuid, text) to service_role;
grant execute on function public._integration_reject(uuid, text, text) to service_role;
grant execute on function public._integration_ingest_order(uuid, text, jsonb) to service_role;
revoke all on function public.integration_list(uuid), public.integration_create_api_key(uuid), public.integration_revoke_api_key(uuid),
  public.integration_connect_woocommerce(uuid, text, text), public.integration_connect_shopify(uuid, text, text),
  public.integration_disconnect(uuid) from public, anon;
grant execute on function public.integration_list(uuid), public.integration_create_api_key(uuid), public.integration_revoke_api_key(uuid),
  public.integration_connect_woocommerce(uuid, text, text), public.integration_connect_shopify(uuid, text, text),
  public.integration_disconnect(uuid) to authenticated;
