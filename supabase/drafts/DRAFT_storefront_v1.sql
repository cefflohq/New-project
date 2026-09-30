-- DRAFT — NOT APPLIED. Founder approval required before staging apply.
-- CEFFLO Storefront V1 (Founder, 2026-10-01): a permanent, shareable public
-- storefront per business, on the EXISTING public ordering backend.
--
-- Reuse, not rebuild (verified on staging 2026-10-01):
--   * public_order_pages already holds one page per business with a
--     unique, normalized `slug` and an `enabled` flag -> it becomes the
--     storefront record (enabled = published). No second table.
--   * products / product_categories / product_media stay the catalogue
--     source of truth; nothing is copied.
--   * submit_public_order already creates real `orders` (origin 'public'),
--     delivery_stops, tracking tokens and delivery_events, idempotently,
--     with server-side price snapshots and rate limits. Storefront orders
--     reuse that exact path through one shared internal function.
--
-- What changes:
--   1. The public identifier becomes the SLUG (permanent URL), not a secret
--      token. The token functions stay untouched for now (no callers,
--      0 rows on staging) -- Founder decision whether to retire them.
--   2. Storefront appearance persists (template + theme) on the page row.
--   3. Slug rules: format, reserved words, owner-only change, old slugs
--      keep redirecting and can never be claimed by another business.
--   4. Management is Owner + Operator (is_business_operational); the
--      existing order-page functions allow ANY member incl. Helper -- the
--      new functions do not, and section 7 tightens the old ones.
--   5. Anonymous customers call only two SECURITY DEFINER functions; no
--      table gains an anon policy and no RLS is loosened.

-- 1. Storefront configuration on the existing page row -----------------
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

-- 2. Reserved slugs: paths the Cefflo host already uses or will need ----
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

-- 3. Old slugs keep working (redirect) and stay owned ------------------
create table public.storefront_slug_history (
  slug text primary key,
  business_id uuid not null references public.businesses(id) on delete cascade,
  retired_at timestamptz not null default now()
);
alter table public.storefront_slug_history enable row level security;
-- No policies: reached only through the functions below.

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
revoke all on function public._storefront_slug_available(text, uuid) from public, anon;

-- 4. Vendor management (Owner + Operator) ------------------------------
-- The business's storefront, created on first open with a slug from the
-- business name (unpublished until the vendor publishes it).
create or replace function public.get_storefront(p_business_id uuid)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare page public_order_pages; base text; candidate text; n int := 0;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  select * into page from public_order_pages where business_id = p_business_id;
  if page.id is null then
    select _normalize_storefront_slug(name) into base from businesses where id = p_business_id;
    if base is null or length(base) < 3 then base := 'store'; end if;
    candidate := base;
    while not _storefront_slug_available(candidate, p_business_id) loop
      n := n + 1;
      candidate := left(base, 30 - length(n::text) - 1) || '-' || n;
    end loop;
    -- access_token_hash is required by the existing table: a random,
    -- never-returned value (the token path is not used by storefronts).
    insert into public_order_pages(business_id, slug, access_token_hash, enabled, updated_by)
      values (p_business_id, candidate, encode(digest(gen_random_bytes(32), 'sha256'), 'hex'), false, auth.uid())
      returning * into page;
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (p_business_id, 'storefront.created', auth.uid(), 'vendor', jsonb_build_object('slug', page.slug));
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

-- Theme: only known keys, bounded values (accent hex, style plain/gradient,
-- optional logo/hero storage paths inside the business's own folder).
create or replace function public.save_storefront_appearance(p_business_id uuid, p_template_key text, p_theme jsonb)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare k text; page public_order_pages;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if jsonb_typeof(p_theme) <> 'object' then raise exception 'invalid theme'; end if;
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

-- Slug change is part of the public identity: Owner only, validated, and
-- the old slug keeps redirecting to this business forever.
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

-- 5. Public (anonymous) storefront -------------------------------------
-- Rate-limit key per caller: the client address from the PostgREST request
-- headers (x-forwarded-for, first hop) + the action; a per-slug ceiling
-- protects one busy store from others' abuse without throttling its real
-- customers together.
create or replace function public._public_caller_key()
returns text language sql stable as $$
  select encode(digest(coalesce(split_part(
    (current_setting('request.headers', true)::json->>'x-forwarded-for'), ',', 1), 'unknown'), 'sha256'), 'hex')
$$;

create or replace function public._resolve_storefront(p_slug text)
returns public_order_pages language sql stable security definer set search_path to 'public' as $$
  select p.* from public_order_pages p
   where p.enabled and (p.slug = p_slug or p.business_id = (
     select h.business_id from storefront_slug_history h where h.slug = p_slug))
   limit 1
$$;
revoke all on function public._resolve_storefront(text) from public, anon;

-- The public catalogue for cefflo.com/{slug}. Returns null for an unknown
-- or unpublished store (no enumeration detail). `slug` is the canonical
-- slug: a client that asked with an old slug redirects to it.
create or replace function public.public_storefront(p_slug text)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare page public_order_pages; result jsonb; hours_known boolean;
begin
  if not check_rate_limit(_public_caller_key(), 'public_storefront', 60, 60) then
    raise exception 'rate limited';
  end if;
  page := _resolve_storefront(lower(coalesce(p_slug, '')));
  if page.id is null then
    perform record_invalid_lookup_telemetry('public_storefront');
    return null;
  end if;
  select jsonb_build_object(
    'slug', page.slug,
    'template_key', page.template_key,
    'theme', page.theme,
    'business', jsonb_build_object('name', b.name, 'area', nullif(trim(b.operating_area), '')),
    'categories', coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'name', c.name) order by c.sort_order, c.id)
        from product_categories c where c.business_id = page.business_id and c.archived_at is null), '[]'::jsonb),
    'products', coalesce((select jsonb_agg(jsonb_build_object(
        'id', p.id, 'category_id', p.category_id, 'name', p.name,
        'description', p.description, 'display_price', p.display_price,
        -- Approved display images; one today, up to 5 once the product
        -- multi-photo migration lands (ordered by position then).
        'images', coalesce((select jsonb_agg('/storage/v1/object/public/cefflo-product-display/' || pm.prepared_storage_path
            order by pm.approved_at)
          from product_media pm
          where pm.product_id = p.id and pm.status = 'approved' and pm.archived_at is null), '[]'::jsonb)
      ) order by p.sort_order, p.id)
      from products p where p.business_id = page.business_id and p.status = 'active' and p.archived_at is null), '[]'::jsonb)
  ) into result from businesses b where b.id = page.business_id;
  return result;
end $$;

-- 6. Public order entry: the SAME order path as submit_public_order ----
-- The body of submit_public_order (validation, merge, price snapshot,
-- orders insert with origin 'public', delivery_stops, tracking token,
-- delivery_events, idempotent replay) moves unchanged into
-- _create_public_order(page, ...). submit_public_order keeps its exact
-- signature and behaviour by calling it; submit_storefront_order resolves
-- the page by slug and calls the same function.
--
--   create function public._create_public_order(page public_order_pages,
--     p_items jsonb, p_customer_name text, p_customer_phone text,
--     p_delivery_address text, p_delivery_notes text, p_idempotency_key uuid)
--   returns jsonb ... -- body = submit_public_order lines after the page
--                     -- lookup, verbatim (staging definition, 2026-10-01)
--
-- (Kept as a pointer here: the verbatim move is mechanical and is written
-- out in full in the apply-ready version once the Founder approves the
-- design, so the reviewed text is the design, not 150 copied lines.)

create or replace function public.submit_storefront_order(
  p_slug text, p_items jsonb, p_customer_name text, p_customer_phone text,
  p_delivery_address text, p_delivery_notes text default '', p_idempotency_key uuid default null)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare page public_order_pages;
begin
  if not check_rate_limit(_public_caller_key(), 'submit_storefront_order', 60, 5) then
    raise exception 'rate limited';
  end if;
  page := _resolve_storefront(lower(coalesce(p_slug, '')));
  if page.id is null then
    perform record_invalid_lookup_telemetry('submit_storefront_order');
    raise exception 'invalid or unavailable storefront';
  end if;
  if not check_rate_limit(encode(digest(page.id::text, 'sha256'), 'hex'), 'submit_storefront_order_store', 60, 120) then
    raise exception 'rate limited';
  end if;
  return _create_public_order(page, p_items, p_customer_name, p_customer_phone,
                              p_delivery_address, p_delivery_notes, p_idempotency_key);
end $$;

-- 7. Tighten the existing order-page functions (security) -------------
-- create_order_page / set_order_page_enabled / rotate_order_page_token
-- currently allow ANY business member, including Helpers. Replace
-- is_business_member with is_business_operational in each (bodies
-- otherwise unchanged). Listed, not rewritten, in this design draft.

-- 8. Grants --------------------------------------------------------------
revoke all on function public.get_storefront(uuid) from public, anon;
revoke all on function public.set_storefront_published(uuid, boolean) from public, anon;
revoke all on function public.save_storefront_appearance(uuid, text, jsonb) from public, anon;
revoke all on function public.change_storefront_slug(uuid, text) from public, anon;
grant execute on function public.get_storefront(uuid) to authenticated;
grant execute on function public.set_storefront_published(uuid, boolean) to authenticated;
grant execute on function public.save_storefront_appearance(uuid, text, jsonb) to authenticated;
grant execute on function public.change_storefront_slug(uuid, text) to authenticated;
grant execute on function public.public_storefront(text) to anon, authenticated;
grant execute on function public.submit_storefront_order(text, jsonb, text, text, text, text, uuid) to anon, authenticated;
