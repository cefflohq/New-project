-- S4-10E: Public Order Page identity, public catalog read, and public order
-- submission. No payment, no marketplace discovery, no rider assignment or
-- delivery-lifecycle start here -- a public submission only ever produces
-- the same "Needs Review" state (delivery_status='created', approved_at is
-- null) a Vendor-entered order already starts at (S4-05's own locked
-- decision: approval is a readiness gate, not a delivery_status value).
--
-- Scope discipline: this migration adds ONLY what public read/submission
-- requires -- business_id/slug/token/enabled. It deliberately does NOT add
-- theme_key/logo/accent columns; those remain S4-10D's own future
-- persistence work, not silently absorbed here.

-- ===================== ORDERS: minimal additive columns =====================
-- 'origin' lets the Vendor's eventual Needs Review UI distinguish
-- publicly-submitted orders from its own manually-entered ones without any
-- new delivery_status value or duplicate lifecycle.
alter table public.orders
  add column origin text not null default 'vendor' check (origin in ('vendor','public')),
  add column submission_idempotency_key uuid;

create unique index orders_submission_idempotency_key_idx
  on public.orders (submission_idempotency_key)
  where submission_idempotency_key is not null;

-- ===================== PUBLIC ORDER PAGE IDENTITY =====================
-- One page per business (Cefflo is not a marketplace -- a page always
-- belongs to exactly one Vendor). slug is a friendly, non-authoritative
-- routing label; access_token_hash is the actual security boundary,
-- hashed at rest exactly like tracking_tokens.token_hash. A guessed or
-- brute-forced slug alone yields nothing without the paired raw token.
create table public.public_order_pages (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null unique references public.businesses(id) on delete cascade,
  slug text not null unique check (slug ~ '^[a-z0-9]([a-z0-9-]{1,38}[a-z0-9])?$'),
  access_token_hash text not null unique,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  rotated_at timestamptz
);

alter table public.public_order_pages enable row level security;
create policy public_order_pages_vendor_read on public.public_order_pages
  for select to authenticated
  using (public.is_business_member(business_id));

revoke all on table public.public_order_pages from public, anon, authenticated;
grant select on table public.public_order_pages to authenticated;

-- ===================== VENDOR-FACING MANAGEMENT (backend primitives only) =====================
-- These are the minimal RPCs a future S4-10F Vendor UI will call -- no UI
-- is implemented here. Deliberately three small functions rather than one
-- combined "upsert" so a raw token is never silently re-issued or hidden:
-- create_order_page fails loudly if a page already exists (use
-- rotate_order_page_token instead), and only creation/rotation ever return
-- the raw secret -- it is never re-derivable from the stored hash.
create function public.create_order_page(p_business_id uuid, p_slug text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions
as $$
declare
  biz_name text;
  base_slug text;
  candidate text;
  suffix int := 0;
  raw_token text;
  page public.public_order_pages;
begin
  select name into biz_name from public.businesses where id = p_business_id;
  if biz_name is null or not public.is_business_member(p_business_id) then raise exception 'forbidden'; end if;
  if exists (select 1 from public.public_order_pages where business_id = p_business_id) then
    raise exception 'order page already exists';
  end if;

  -- Normalize: lowercase, non [a-z0-9] collapsed to '-', trimmed, bounded.
  base_slug := lower(regexp_replace(coalesce(nullif(btrim(p_slug), ''), biz_name), '[^a-z0-9]+', '-', 'gi'));
  base_slug := regexp_replace(base_slug, '(^-+|-+$)', '', 'g');
  base_slug := left(coalesce(nullif(base_slug, ''), 'vendor'), 30);
  candidate := base_slug;
  while exists (select 1 from public.public_order_pages where slug = candidate) loop
    suffix := suffix + 1;
    candidate := left(base_slug, 30 - length(suffix::text) - 1) || '-' || suffix::text;
  end loop;

  raw_token := encode(gen_random_bytes(32), 'hex');
  insert into public.public_order_pages(business_id, slug, access_token_hash)
  values (p_business_id, candidate, encode(digest(raw_token, 'sha256'), 'hex'))
  returning * into page;

  return jsonb_build_object('page', to_jsonb(page), 'access_token', raw_token);
end;
$$;

create function public.rotate_order_page_token(p_business_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions
as $$
declare
  raw_token text;
  page public.public_order_pages;
begin
  select * into page from public.public_order_pages where business_id = p_business_id for update;
  if page.id is null or not public.is_business_member(p_business_id) then raise exception 'forbidden'; end if;
  raw_token := encode(gen_random_bytes(32), 'hex');
  update public.public_order_pages
    set access_token_hash = encode(digest(raw_token, 'sha256'), 'hex'), rotated_at = now(), updated_at = now()
    where id = page.id
    returning * into page;
  return jsonb_build_object('page', to_jsonb(page), 'access_token', raw_token);
end;
$$;

create function public.set_order_page_enabled(p_business_id uuid, p_enabled boolean)
returns public.public_order_pages
language plpgsql security definer set search_path = public
as $$
declare page public.public_order_pages;
begin
  select * into page from public.public_order_pages where business_id = p_business_id for update;
  if page.id is null or not public.is_business_member(p_business_id) then raise exception 'forbidden'; end if;
  update public.public_order_pages set enabled = p_enabled, updated_at = now() where id = page.id returning * into page;
  return page;
end;
$$;

revoke all on function public.create_order_page(uuid,text) from public, anon, authenticated;
revoke all on function public.rotate_order_page_token(uuid) from public, anon, authenticated;
revoke all on function public.set_order_page_enabled(uuid,boolean) from public, anon, authenticated;
grant execute on function public.create_order_page(uuid,text) to authenticated;
grant execute on function public.rotate_order_page_token(uuid) to authenticated;
grant execute on function public.set_order_page_enabled(uuid,boolean) to authenticated;

-- ===================== PUBLIC CATALOG READ =====================
-- Anon-safe, rate-limited exactly like public_tracking: token hashed
-- before lookup, limiter failures fail open, a genuine over-limit result
-- fails closed. Exposes ONLY what an Order Page genuinely needs: business
-- display name, live (non-archived) categories, active (non-archived)
-- products, and -- per the closed S4-10B contract -- the single current
-- approved-and-not-archived display image if one exists. Never the
-- original/private image, never processing state, never Vendor-only
-- fields, never business contact/ownership details.
create function public.public_order_catalog(p_token text)
returns jsonb
language plpgsql security definer set search_path = public, extensions
as $$
declare
  key text;
  allowed boolean;
  page public.public_order_pages;
  result jsonb;
  display_bucket_url text := '/storage/v1/object/public/cefflo-product-display/';
begin
  key := encode(digest(coalesce(p_token, ''), 'sha256'), 'hex');

  begin
    allowed := public.check_rate_limit(key, 'public_order_catalog', 60, 10);
  exception when others then
    allowed := true;
  end;
  if not allowed then raise exception 'rate limited'; end if;

  select pop.* into page
    from public.public_order_pages pop
    where pop.access_token_hash = key and pop.enabled = true;

  if page.id is null then
    perform public.record_invalid_lookup_telemetry('public_order_catalog');
    return null;
  end if;

  select jsonb_build_object(
    'business', jsonb_build_object('name', b.name),
    'categories', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'name', c.name) order by c.sort_order, c.id)
      from public.product_categories c
      where c.business_id = page.business_id and c.archived_at is null
    ), '[]'::jsonb),
    'products', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'category_id', p.category_id,
        'name', p.name,
        'description', p.description,
        'display_price', p.display_price,
        'image_url', (
          select display_bucket_url || pm.prepared_storage_path
          from public.product_media pm
          where pm.product_id = p.id and pm.status = 'approved' and pm.archived_at is null
          limit 1
        )
      ) order by p.sort_order, p.id)
      from public.products p
      where p.business_id = page.business_id and p.status = 'active' and p.archived_at is null
    ), '[]'::jsonb)
  ) into result
  from public.businesses b
  where b.id = page.business_id;

  return result;
end;
$$;

revoke all on function public.public_order_catalog(text) from public, anon, authenticated;
grant execute on function public.public_order_catalog(text) to anon, authenticated;

-- ===================== PUBLIC ORDER SUBMISSION =====================
-- The sole public write boundary. Client supplies only {product_id,
-- quantity} pairs plus delivery/customer text fields -- price, product
-- name and business ownership are always resolved server-side, never
-- trusted from the client. A cross-business or inactive/archived
-- product_id rejects the WHOLE submission (never partially accepted).
-- Idempotency key: client-generated, unique per genuine new submission --
-- a retry with the same key returns the original order rather than
-- creating a second one.
create function public.submit_public_order(
  p_token text,
  p_items jsonb,
  p_customer_name text,
  p_customer_phone text,
  p_delivery_address text,
  p_delivery_notes text default '',
  p_idempotency_key uuid default null
) returns jsonb
language plpgsql security definer set search_path = public, extensions
as $$
declare
  rl_key text;
  allowed boolean;
  page public.public_order_pages;
  existing public.orders;
  item jsonb;
  item_count int := 0;
  merged jsonb := '{}'::jsonb; -- product_id::text -> quantity, dedupes+sums client duplicate lines
  pid uuid; qty int;
  snapshot jsonb := '[]'::jsonb;
  prod record;
  o public.orders;
  t text;
begin
  rl_key := encode(digest(coalesce(p_token, ''), 'sha256'), 'hex');

  begin
    allowed := public.check_rate_limit(rl_key, 'submit_public_order', 60, 5);
  exception when others then
    allowed := true;
  end;
  if not allowed then raise exception 'rate limited'; end if;

  select pop.* into page
    from public.public_order_pages pop
    where pop.access_token_hash = rl_key and pop.enabled = true;
  if page.id is null then
    perform public.record_invalid_lookup_telemetry('submit_public_order');
    raise exception 'invalid or unavailable order page';
  end if;

  -- Idempotent replay: same key, same page's prior order, returned as-is.
  -- The raw tracking token was only ever available at original creation
  -- time (only its hash is stored), so a replay cannot re-reveal it.
  if p_idempotency_key is not null then
    select * into existing from public.orders
      where submission_idempotency_key = p_idempotency_key and business_id = page.business_id;
    if existing.id is not null then
      return jsonb_build_object('order_reference', existing.public_ref, 'tracking_token', null, 'replay', true);
    end if;
  end if;

  if p_customer_name is null or char_length(btrim(p_customer_name)) not between 1 and 120 then
    raise exception 'invalid customer name';
  end if;
  if p_customer_phone is null or char_length(btrim(p_customer_phone)) not between 1 and 30 then
    raise exception 'invalid customer phone';
  end if;
  if p_delivery_address is null or char_length(btrim(p_delivery_address)) not between 1 and 500 then
    raise exception 'invalid delivery address';
  end if;
  if p_delivery_notes is not null and char_length(p_delivery_notes) > 500 then
    raise exception 'invalid delivery notes';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) < 1 or jsonb_array_length(p_items) > 20 then
    raise exception 'invalid item list';
  end if;

  for item in select * from jsonb_array_elements(p_items) loop
    item_count := item_count + 1;
    if jsonb_typeof(item) <> 'object' or not (item ? 'product_id') or not (item ? 'quantity') then
      raise exception 'malformed order item';
    end if;
    begin
      pid := (item->>'product_id')::uuid;
    exception when others then
      raise exception 'malformed order item';
    end;
    if jsonb_typeof(item->'quantity') <> 'number' or (item->>'quantity') !~ '^[0-9]+$' then
      raise exception 'invalid quantity';
    end if;
    qty := (item->>'quantity')::int;
    if qty < 1 or qty > 50 then raise exception 'invalid quantity'; end if;
    merged := jsonb_set(merged, array[pid::text], to_jsonb(coalesce((merged->>(pid::text))::int, 0) + qty));
  end loop;

  for pid, qty in select key::uuid, value::int from jsonb_each_text(merged) loop
    select p.id, p.name, p.display_price into prod
      from public.products p
      where p.id = pid and p.business_id = page.business_id and p.status = 'active' and p.archived_at is null;
    if prod.id is null then
      raise exception 'product not available';
    end if;
    snapshot := snapshot || jsonb_build_array(jsonb_build_object(
      'product_id', prod.id,
      'product_name_snapshot', prod.name,
      'display_price_snapshot', prod.display_price,
      'quantity', qty,
      'line_subtotal_snapshot', round(prod.display_price * qty, 2)
    ));
  end loop;

  begin
    insert into public.orders(
      business_id, customer_name, customer_phone, delivery_address, notes,
      items, origin, submission_idempotency_key
    ) values (
      page.business_id, btrim(p_customer_name), btrim(p_customer_phone), btrim(p_delivery_address),
      coalesce(btrim(p_delivery_notes), ''), snapshot, 'public', p_idempotency_key
    ) returning * into o;
  exception when unique_violation then
    -- Genuine concurrent retry raced past the earlier check-first lookup.
    select * into o from public.orders
      where submission_idempotency_key = p_idempotency_key and business_id = page.business_id;
    return jsonb_build_object('order_reference', o.public_ref, 'tracking_token', null, 'replay', true);
  end;

  insert into public.delivery_stops(business_id, order_id) values (page.business_id, o.id);
  t := encode(gen_random_bytes(32), 'hex');
  insert into public.tracking_tokens(order_id, token_hash) values (o.id, encode(digest(t, 'sha256'), 'hex'));
  insert into public.delivery_events(business_id, order_id, event_type, to_status, actor_role)
    values (page.business_id, o.id, 'delivery.created', 'created', 'customer');

  return jsonb_build_object('order_reference', o.public_ref, 'tracking_token', t, 'replay', false);
end;
$$;

revoke all on function public.submit_public_order(text,jsonb,text,text,text,text,uuid) from public, anon, authenticated;
grant execute on function public.submit_public_order(text,jsonb,text,text,text,text,uuid) to anon, authenticated;

-- ===================== DECLINE (the missing half of the existing Approve gate) =====================
-- Mirrors approve_order's exact authorization precedent (any active
-- business member). Only reachable while an order is still genuinely in
-- Needs Review (delivery_status='created', not yet approved) -- declining
-- an order already approved/in progress is a different, unimplemented
-- concept (a real cancellation), deliberately not conflated here.
create function public.decline_order(p_order_id uuid, p_reason text default null)
returns public.orders
language plpgsql security definer set search_path = public
as $$
declare o public.orders;
begin
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not public.is_business_member(o.business_id) then raise exception 'forbidden'; end if;
  if o.approved_at is not null then raise exception 'order already approved'; end if;
  if o.delivery_status <> 'created' then raise exception 'order not in needs review state'; end if;
  update public.orders set delivery_status = 'cancelled', updated_at = now() where id = o.id returning * into o;
  insert into public.delivery_events(business_id, order_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    values (o.business_id, o.id, 'order.declined', 'created', 'cancelled', auth.uid(), 'vendor',
            jsonb_build_object('reason', nullif(btrim(coalesce(p_reason, '')), '')));
  return o;
end;
$$;

revoke all on function public.decline_order(uuid,text) from public, anon, authenticated;
grant execute on function public.decline_order(uuid,text) to authenticated;
