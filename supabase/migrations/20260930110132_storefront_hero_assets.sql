-- CEFFLO Storefront hero image (Founder approval 2026-10-01, STAGING only).
--
-- A dedicated public bucket for storefront appearance assets. The only
-- write is INSERT of a new object at exactly '{business_id}/hero-{uuid}.{ext}'
-- by an Owner or Operator of THAT business (the path's first segment is
-- checked against the caller, never trusted on its own). No UPDATE or
-- DELETE policy: a replacement is a new object; the storefront switches to
-- it only when save_storefront_appearance stores the new hero_path, which
-- must name an existing object in this bucket inside the caller's business.
--
-- Deferred technical debt (Founder, 2026-10-01): replaced / removed hero
-- files are not physically deleted in V1. They are never referenced by any
-- storefront once hero_path changes, but remain reachable at their random
-- (uuid) address until a future service-role cleanup job removes orphans.
-- Existing product-media storage policies are unchanged.

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
  values ('cefflo-storefront-assets', 'cefflo-storefront-assets', true, 5242880,
          array['image/jpeg', 'image/png', 'image/webp'])
  on conflict (id) do update
    set public = true,
        file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

-- Path shape first, then the role check -- the uuid cast only ever runs on
-- a name that already matched the exact pattern.
create or replace function public._storefront_asset_upload_allowed(p_name text)
returns boolean language plpgsql stable security definer set search_path to 'public' as $$
begin
  if p_name is null or p_name !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/hero-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$' then
    return false;
  end if;
  return public.is_business_operational(split_part(p_name, '/', 1)::uuid);
end $$;
revoke all on function public._storefront_asset_upload_allowed(text) from public, anon;
grant execute on function public._storefront_asset_upload_allowed(text) to authenticated;

drop policy if exists storefront_assets_operational_insert on storage.objects;
create policy storefront_assets_operational_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'cefflo-storefront-assets'
    and public._storefront_asset_upload_allowed(storage.objects.name)
  );

-- hero_path must be an uploaded hero of this business (upload first, then
-- save). Everything else is the approved 20260930091016 body.
create or replace function public.save_storefront_appearance(p_business_id uuid, p_template_key text, p_theme jsonb)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare k text; page public_order_pages;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if p_theme is null or jsonb_typeof(p_theme) <> 'object' then raise exception 'invalid theme'; end if;
  for k in select jsonb_object_keys(p_theme) loop
    if k not in ('accent', 'secondary', 'background_color', 'style', 'font', 'background', 'tagline', 'logo_path', 'hero_path') then
      raise exception 'invalid theme key %', k;
    end if;
    if jsonb_typeof(p_theme->k) <> 'string' then raise exception 'invalid theme value %', k; end if;
  end loop;
  if (p_theme ? 'accent' and (p_theme->>'accent') !~ '^#[0-9a-fA-F]{6}$')
     or (p_theme ? 'secondary' and (p_theme->>'secondary') !~ '^#[0-9a-fA-F]{6}$')
     or (p_theme ? 'background_color' and (p_theme->>'background_color') !~ '^#[0-9a-fA-F]{6}$') then
    raise exception 'invalid colour';
  end if;
  if p_theme ? 'style' and (p_theme->>'style') not in ('plain', 'gradient') then raise exception 'invalid style'; end if;
  if p_theme ? 'font' and (p_theme->>'font') not in ('modern', 'bold', 'elegant', 'classic') then raise exception 'invalid font'; end if;
  if p_theme ? 'background' and (p_theme->>'background') !~ '^[a-z0-9_-]{1,40}$' then raise exception 'invalid background'; end if;
  if p_theme ? 'tagline' and char_length(p_theme->>'tagline') > 120 then raise exception 'invalid tagline'; end if;
  if p_theme ? 'logo_path' and (p_theme->>'logo_path') not like p_business_id::text || '/%' then
    raise exception 'invalid asset path';
  end if;
  if p_theme ? 'hero_path' and (
       (p_theme->>'hero_path') !~ ('^' || p_business_id::text || '/hero-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$')
       or not exists (select 1 from storage.objects
                       where bucket_id = 'cefflo-storefront-assets' and name = p_theme->>'hero_path')) then
    raise exception 'invalid hero image';
  end if;
  update public_order_pages
     set template_key = p_template_key, theme = p_theme, updated_at = now(), updated_by = auth.uid()
   where business_id = p_business_id returning * into page;
  if page.id is null then raise exception 'storefront not found'; end if;
  return jsonb_build_object('template_key', page.template_key, 'theme', page.theme);
end $$;

-- public_storefront: + hero_url for the CURRENT hero_path only; storage
-- paths are not exposed in `theme`. Everything else is the
-- 20260930090723 body.
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
    'theme', page.theme - 'hero_path' - 'logo_path',
    'hero_url', case when page.theme ? 'hero_path'
      then '/storage/v1/object/public/cefflo-storefront-assets/' || (page.theme->>'hero_path') end,
    'business', jsonb_build_object('name', b.name, 'area', nullif(trim(b.operating_area), '')),
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
