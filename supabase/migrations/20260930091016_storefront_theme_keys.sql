-- CEFFLO Storefront V1 follow-up (Founder-approved storefront persistence,
-- 2026-10-01, STAGING first): persist every Customize setting the Vendor
-- app already offers, with bounded validation. Function body only; no
-- table, policy or grant changes.
--   accent / secondary / background_color: #RRGGBB
--   style: plain | gradient
--   font: modern | bold | elegant | classic
--   background: a template background id ([a-z0-9_-], <= 40)
--   tagline: <= 120 characters
--   logo_path / hero_path: inside the business's own storage folder
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
