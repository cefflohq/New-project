-- CEFFLO business templates (Founder brief 2026-10-11).
-- Problem: the Template Library now offers ten business templates
-- (homefood, bakery, eatery, cafe, catering, frozen, florist, laundry,
-- retail, outlets) that public_order_pages.template_key does not allow, and
-- vendors cannot use a logo: theme.logo_path was accepted unvalidated, could
-- not be uploaded (storage policy only allows hero-*) and never reached the
-- storefront payload.
-- New:
--   * template_key allows the ten business keys plus the 18 earlier V1 keys
--     (pages saved on those keep rendering; nothing is migrated).
--   * New storefronts start on 'homefood'.
--   * Uploads may be {business}/logo-<uuid>.(jpg|png|webp) as well as hero-*.
--   * save_storefront_appearance validates logo_path like hero_path (this
--     business, logo-<uuid>, object exists).
--   * _storefront_payload returns logo_url (public bucket path), as hero_url.
-- Grants / RLS unchanged. Rollback: restore the 20261007130000 constraint
-- and default 'care', the hero-only upload check, the previous
-- save_storefront_appearance and _storefront_payload bodies.

alter table public.public_order_pages drop constraint if exists public_order_pages_template_key;
alter table public.public_order_pages add constraint public_order_pages_template_key check (template_key in (
  'homefood', 'bakery', 'eatery', 'cafe', 'catering', 'frozen', 'florist', 'laundry', 'retail', 'outlets',
  'care', 'capsule', 'kit', 'brew', 'crimson', 'lift', 'harvest', 'botanic', 'combo',
  'discover', 'atelier', 'pour', 'tailor', 'sprint', 'splash', 'service', 'warung', 'collector'));
alter table public.public_order_pages alter column template_key set default 'homefood';

create or replace function public._storefront_asset_upload_allowed(p_name text)
returns boolean language plpgsql stable security definer set search_path to 'public' as $$
begin
  if p_name is null or p_name !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/(hero|logo)-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$' then
    return false;
  end if;
  return public.is_business_operational(split_part(p_name, '/', 1)::uuid);
end $$;

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
  if p_theme ? 'logo_path' and (
       (p_theme->>'logo_path') !~ ('^' || p_business_id::text || '/logo-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$')
       or not exists (select 1 from storage.objects
                       where bucket_id = 'cefflo-storefront-assets' and name = p_theme->>'logo_path')) then
    raise exception 'invalid logo image';
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
