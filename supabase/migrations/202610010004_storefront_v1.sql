-- CEFFLO Storefront V1 (Founder approval 2026-10-01, STAGING first).
-- A permanent, slug-based public storefront per business on the EXISTING
-- public ordering backend: public_order_pages is the storefront record
-- (enabled = published), products are the catalogue, submit_public_order's
-- order path creates the orders. Nothing is duplicated.
--
-- * The token-based functions (create_order_page, public_order_catalog,
--   submit_public_order, rotate_order_page_token, set_order_page_enabled)
--   stay available until the slug flow is fully verified.
-- * Management: Owner + Operator (is_business_operational). The existing
--   order-page functions are tightened from any member (incl. Helper).
-- * Customers reach two SECURITY DEFINER functions only; no RLS loosened.

-- 1. Storefront configuration on the existing page row ------------------
alter table public.public_order_pages
  add column if not exists template_key text not null default 'arena',
  add column if not exists theme jsonb not null default '{}'::jsonb,
  add column if not exists published_at timestamptz,
  add column if not exists updated_by uuid references auth.users(id);

alter table public.public_order_pages
  add constraint public_order_pages_slug_format
    check (slug ~ '^[a-z0-9]([a-z0-9-]{1,28}[a-z0-9])$'),
  add constraint public_order_pages_template_key
    check (template_key in ('arena', 'market', 'ritual', 'feast', 'stride')),
  add constraint public_order_pages_theme_object
    check (jsonb_typeof(theme) = 'object');

-- 2. Reserved slugs --------------------------------------------------------
create table public.reserved_storefront_slugs (slug text primary key);
insert into public.reserved_storefront_slugs(slug) values
  ('about'),('admin'),('api'),('app'),('apps'),('assets'),('auth'),('billing'),
  ('blog'),('careers'),('cefflo'),('contact'),('customer'),('dashboard'),
  ('docs'),('driver'),('foundr'),('help'),('invite'),('kim'),('legal'),
  ('login'),('logout'),('order'),('orders'),('pricing'),('privacy'),
  ('retired'),('rider'),('server'),('settings'),('shared'),('shop'),
  ('signin'),('signup'),('static'),('status'),('store'),('support'),
  ('terms'),('track'),('tracking'),('vendor'),('web'),('www')
on conflict do nothing;
alter table public.reserved_storefront_slugs enable row level security;

-- 3. Retired slugs keep redirecting and stay owned ------------------------
create table public.storefront_slug_history (
  slug text primary key,
  business_id uuid not null references public.businesses(id) on delete cascade,
  retired_at timestamptz not null default now()
);
alter table public.storefront_slug_history enable row level security;

create or replace function public._normalize_storefront_slug(p text)
returns text language sql immutable as $$
  select left(regexp_replace(regexp_replace(lower(coalesce(p, '')),
    '[^a-z0-9]+', '-', 'g'), '(^-+|-+$)', '', 'g'), 30)
$$;

create or replace function public._storefront_slug_available(p_slug text, p_business uuid)
returns boolean language sql stable security definer set search_path to 'public' as $$
  select p_slug ~ '^[a-z0-9]([a-z0-9-]{1,28}[a-z0-9])$'
     and not exists (select 1 from reserved_storefront_slugs where slug = p_slug)
     and not exists (select 1 from public_order_pages where slug = p_slug and business_id <> p_business)
     and not exists (select 1 from storefront_slug_history where slug = p_slug and business_id <> p_business)
$$;
revoke all on function public._storefront_slug_available(text, uuid) from public, anon, authenticated;

-- 4. Vendor management (Owner + Operator) ------------------------------
create or replace function public.get_storefront(p_business_id uuid)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare page public_order_pages; base text; candidate text; n int := 0;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  select * into page from public_order_pages where business_id = p_business_id;
  if page.id is null then
    select _normalize_storefront_slug(name) into base from businesses where id = p_business_id;
    if base is null or length(base) < 3 then base := 'store'; end if;
    base := regexp_replace(base, '-+$', '');
    candidate := base;
    while not _storefront_slug_available(candidate, p_business_id) loop
      n := n + 1;
      candidate := regexp_replace(left(base, 30 - length(n::text) - 1), '-+$', '') || '-' || n;
    end loop;
    -- The table requires an access-token hash: a random value that is
    -- never returned (storefronts are reached by slug, not token).
    insert into public_order_pages(business_id, slug, access_token_hash, enabled, updated_by)
      values (p_business_id, candidate, encode(digest(gen_random_bytes(32), 'sha256'), 'hex'), false, auth.uid())
      on conflict (business_id) do nothing
      returning * into page;
    if page.id is null then
      select * into page from public_order_pages where business_id = p_business_id;
    else
      insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
        values (p_business_id, 'storefront.created', auth.uid(), 'vendor', jsonb_build_object('slug', page.slug));
    end if;
  end if;
  return jsonb_build_object('slug', page.slug, 'published', page.enabled,
    'published_at', page.published_at, 'template_key', page.template_key, 'theme', page.theme);
end $$;

create or replace function public.set_storefront_published(p_business_id uuid, p_published boolean)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare page public_order_pages;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  update public_order_pages
     set enabled = p_published,
         published_at = case when p_published then coalesce(published_at, now()) else published_at end,
         updated_at = now(), updated_by = auth.uid()
   where business_id = p_business_id returning * into page;
  if page.id is null then raise exception 'storefront not found'; end if;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, case when p_published then 'storefront.published' else 'storefront.unpublished' end,
            auth.uid(), 'vendor', '{}'::jsonb);
  return jsonb_build_object('slug', page.slug, 'published', page.enabled);
end $$;

create or replace function public.save_storefront_appearance(p_business_id uuid, p_template_key text, p_theme jsonb)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare k text; page public_order_pages;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if p_theme is null or jsonb_typeof(p_theme) <> 'object' then raise exception 'invalid theme'; end if;
  for k in select jsonb_object_keys(p_theme) loop
    if k not in ('accent', 'style', 'logo_path', 'hero_path') then raise exception 'invalid theme key %', k; end if;
  end loop;
  if p_theme ? 'accent' and (p_theme->>'accent') !~ '^#[0-9a-fA-F]{6}$' then raise exception 'invalid accent'; end if;
  if p_theme ? 'style' and (p_theme->>'style') not in ('plain', 'gradient') then raise exception 'invalid style'; end if;
  if (p_theme ? 'logo_path' and (p_theme->>'logo_path') not like p_business_id::text || '/%')
     or (p_theme ? 'hero_path' and (p_theme->>'hero_path') not like p_business_id::text || '/%') then
    raise exception 'invalid asset path';
  end if;
  update public_order_pages
     set template_key = p_template_key, theme = p_theme, updated_at = now(), updated_by = auth.uid()
   where business_id = p_business_id returning * into page;
  if page.id is null then raise exception 'storefront not found'; end if;
  return jsonb_build_object('template_key', page.template_key, 'theme', page.theme);
end $$;

-- Public identity: Owner only; the old slug keeps redirecting forever.
create or replace function public.change_storefront_slug(p_business_id uuid, p_slug text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare page public_order_pages; next text := _normalize_storefront_slug(p_slug);
begin
  if not is_business_owner(p_business_id) then raise exception 'forbidden'; end if;
  select * into page from public_order_pages where business_id = p_business_id for update;
  if page.id is null then raise exception 'storefront not found'; end if;
  if next = page.slug then return jsonb_build_object('slug', page.slug); end if;
  if not _storefront_slug_available(next, p_business_id) then raise exception 'slug not available'; end if;
  insert into storefront_slug_history(slug, business_id) values (page.slug, p_business_id)
    on conflict (slug) do nothing;
  delete from storefront_slug_history where slug = next and business_id = p_business_id;
  update public_order_pages set slug = next, updated_at = now(), updated_by = auth.uid() where id = page.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'storefront.slug_changed', auth.uid(), 'vendor',
            jsonb_build_object('from', page.slug, 'to', next));
  return jsonb_build_object('slug', next);
end $$;

-- 5. Public storefront -----------------------------------------------------
create or replace function public._public_caller_key(p_action text)
returns text language sql stable set search_path to 'public', 'extensions' as $$
  select encode(digest(p_action || ':' || coalesce(nullif(btrim(split_part(
    (current_setting('request.headers', true)::json->>'x-forwarded-for'), ',', 1)), ''), 'unknown'), 'sha256'), 'hex')
$$;
revoke all on function public._public_caller_key(text) from public, anon, authenticated;

create or replace function public._resolve_storefront(p_slug text)
returns public_order_pages language sql stable security definer set search_path to 'public' as $$
  select p.* from public_order_pages p
   where p.enabled and (p.slug = p_slug or p.business_id = (
     select h.business_id from storefront_slug_history h where h.slug = p_slug))
   limit 1
$$;
revoke all on function public._resolve_storefront(text) from public, anon, authenticated;

create or replace function public.public_storefront(p_slug text)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare page public_order_pages; result jsonb; allowed boolean;
begin
  begin
    allowed := check_rate_limit(_public_caller_key('public_storefront'), 'public_storefront', 60, 60);
  exception when others then allowed := true;
  end;
  if not allowed then raise exception 'rate limited'; end if;
  page := _resolve_storefront(lower(btrim(coalesce(p_slug, ''))));
  if page.id is null then
    perform record_invalid_lookup_telemetry('public_storefront');
    return null;
  end if;
  select jsonb_build_object(
    'slug', page.slug,
    'template_key', page.template_key,
    'theme', page.theme,
    'business', jsonb_build_object('name', b.name, 'area', nullif(trim(b.operating_area), '')),
    -- Business Hours (202610010003): the week as set by the Owner, and
    -- open/closed now in the business's own timezone. Empty week = null.
    'hours', (select jsonb_agg(jsonb_build_object('weekday', h.weekday, 'is_open', h.is_open,
        'opens_at', to_char(h.opens_at, 'HH24:MI'), 'closes_at', to_char(h.closes_at, 'HH24:MI')) order by h.weekday)
      from business_hours h where h.business_id = page.business_id),
    'open_now', case when exists (select 1 from business_hours h where h.business_id = page.business_id)
      then business_open_now(page.business_id) end,
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
  ) into result from businesses b where b.id = page.business_id;
  return result;
end $$;

-- 6. One order path for token and slug entry -------------------------------
-- The body of submit_public_order after its page lookup, verbatim.
create or replace function public._create_public_order(
  page public.public_order_pages, p_items jsonb, p_customer_name text, p_customer_phone text,
  p_delivery_address text, p_delivery_notes text, p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare
  existing public.orders;
  item jsonb;
  item_count int := 0;
  merged jsonb := '{}'::jsonb;
  pid uuid; qty int;
  snapshot jsonb := '[]'::jsonb;
  prod record;
  o public.orders;
  t text;
begin
  if p_idempotency_key is null then
    raise exception 'invalid idempotency key';
  end if;

  select * into existing from public.orders
    where submission_idempotency_key = p_idempotency_key and business_id = page.business_id;
  if existing.id is not null then
    return jsonb_build_object('order_reference', existing.public_ref, 'tracking_token', null, 'replay', true);
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
    if qty < 1 or qty > 50 then raise exception 'invalid quantity'; end if;
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
    select * into o from public.orders
      where submission_idempotency_key = p_idempotency_key and business_id = page.business_id;
    if o.id is null then
      raise;
    end if;
    return jsonb_build_object('order_reference', o.public_ref, 'tracking_token', null, 'replay', true);
  end;

  insert into public.delivery_stops(business_id, order_id) values (page.business_id, o.id);
  t := encode(gen_random_bytes(32), 'hex');
  insert into public.tracking_tokens(order_id, token_hash) values (o.id, encode(digest(t, 'sha256'), 'hex'));
  insert into public.delivery_events(business_id, order_id, event_type, to_status, actor_role)
    values (page.business_id, o.id, 'delivery.created', 'created', 'customer');

  return jsonb_build_object('order_reference', o.public_ref, 'tracking_token', t, 'replay', false);
end $$;
revoke all on function public._create_public_order(public.public_order_pages, jsonb, text, text, text, text, uuid) from public, anon, authenticated;

-- submit_public_order keeps its signature and behaviour exactly.
create or replace function public.submit_public_order(p_token text, p_items jsonb, p_customer_name text, p_customer_phone text, p_delivery_address text, p_delivery_notes text default ''::text, p_idempotency_key uuid default null::uuid)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare rl_key text; allowed boolean; page public.public_order_pages;
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
  return public._create_public_order(page, p_items, p_customer_name, p_customer_phone,
                                     p_delivery_address, p_delivery_notes, p_idempotency_key);
end $$;

create or replace function public.submit_storefront_order(
  p_slug text, p_items jsonb, p_customer_name text, p_customer_phone text,
  p_delivery_address text, p_delivery_notes text default '', p_idempotency_key uuid default null)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare page public.public_order_pages; allowed boolean;
begin
  begin
    allowed := check_rate_limit(_public_caller_key('submit_storefront_order'), 'submit_storefront_order', 60, 5);
  exception when others then allowed := true;
  end;
  if not allowed then raise exception 'rate limited'; end if;
  page := _resolve_storefront(lower(btrim(coalesce(p_slug, ''))));
  if page.id is null then
    perform record_invalid_lookup_telemetry('submit_storefront_order');
    raise exception 'invalid or unavailable storefront';
  end if;
  begin
    allowed := check_rate_limit(encode(digest('store:' || page.id::text, 'sha256'), 'hex'), 'submit_storefront_order_store', 60, 120);
  exception when others then allowed := true;
  end;
  if not allowed then raise exception 'rate limited'; end if;
  return _create_public_order(page, p_items, p_customer_name, p_customer_phone,
                              p_delivery_address, p_delivery_notes, p_idempotency_key);
end $$;

-- 7. Tighten the token-era order-page management to Owner + Operator ------
create or replace function public.set_order_page_enabled(p_business_id uuid, p_enabled boolean)
returns public_order_pages language plpgsql security definer set search_path to 'public' as $$
declare page public.public_order_pages;
begin
  select * into page from public.public_order_pages where business_id = p_business_id for update;
  if page.id is null or not public.is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  update public.public_order_pages set enabled = p_enabled, updated_at = now() where id = page.id returning * into page;
  return page;
end $$;

create or replace function public.rotate_order_page_token(p_business_id uuid)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare raw_token text; page public.public_order_pages;
begin
  select * into page from public.public_order_pages where business_id = p_business_id for update;
  if page.id is null or not public.is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  raw_token := encode(gen_random_bytes(32), 'hex');
  update public.public_order_pages
    set access_token_hash = encode(digest(raw_token, 'sha256'), 'hex'), rotated_at = now(), updated_at = now()
    where id = page.id
    returning * into page;
  return jsonb_build_object('page', to_jsonb(page), 'access_token', raw_token);
end $$;

create or replace function public.create_order_page(p_business_id uuid, p_slug text default null::text)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare
  biz_name text; base_slug text; candidate text; suffix int := 0; raw_token text;
  page public.public_order_pages;
begin
  select name into biz_name from public.businesses where id = p_business_id;
  if biz_name is null or not public.is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if exists (select 1 from public.public_order_pages where business_id = p_business_id) then
    raise exception 'order page already exists';
  end if;
  base_slug := public._normalize_storefront_slug(coalesce(nullif(btrim(p_slug), ''), biz_name));
  if length(base_slug) < 3 then base_slug := 'store'; end if;
  candidate := base_slug;
  while not public._storefront_slug_available(candidate, p_business_id) loop
    suffix := suffix + 1;
    candidate := regexp_replace(left(base_slug, 30 - length(suffix::text) - 1), '-+$', '') || '-' || suffix::text;
  end loop;
  raw_token := encode(gen_random_bytes(32), 'hex');
  insert into public.public_order_pages(business_id, slug, access_token_hash)
  values (p_business_id, candidate, encode(digest(raw_token, 'sha256'), 'hex'))
  returning * into page;
  return jsonb_build_object('page', to_jsonb(page), 'access_token', raw_token);
end $$;

-- 8. Grants ------------------------------------------------------------------
revoke all on function public.get_storefront(uuid) from public, anon;
revoke all on function public.set_storefront_published(uuid, boolean) from public, anon;
revoke all on function public.save_storefront_appearance(uuid, text, jsonb) from public, anon;
revoke all on function public.change_storefront_slug(uuid, text) from public, anon;
grant execute on function public.get_storefront(uuid) to authenticated;
grant execute on function public.set_storefront_published(uuid, boolean) to authenticated;
grant execute on function public.save_storefront_appearance(uuid, text, jsonb) to authenticated;
grant execute on function public.change_storefront_slug(uuid, text) to authenticated;
revoke all on function public.public_storefront(text) from public;
revoke all on function public.submit_storefront_order(text, jsonb, text, text, text, text, uuid) from public;
grant execute on function public.public_storefront(text) to anon, authenticated;
grant execute on function public.submit_storefront_order(text, jsonb, text, text, text, text, uuid) to anon, authenticated;
