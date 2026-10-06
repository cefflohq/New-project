-- Storefront V1 templates (Founder references 2026-10-06; staging first).
-- The Vendor App previews its storefront in the real public renderer
-- (store/ templates) inside a device frame. That preview needs exactly the
-- public payload -- including approved product photos and the hero -- even
-- before the storefront is published (public_storefront only resolves an
-- enabled page). This extracts the payload into _storefront_payload(page),
-- keeps public_storefront byte-identical in output, and adds
-- storefront_preview(business) for the business's Owner / Operator only.
-- No new data is exposed: the payload is what the public page shows.
-- Grants: _storefront_payload not executable by clients; storefront_preview
-- authenticated only. RLS unchanged.
-- Rollback: drop storefront_preview + _storefront_payload and re-apply
-- public_storefront from 20261001-era definition (inline payload).

create or replace function public._storefront_payload(page public.public_order_pages)
returns jsonb
language sql
stable
security definer
set search_path to 'public', 'extensions'
as $$
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
  ) from businesses b where b.id = page.business_id
$$;
revoke all on function public._storefront_payload(public.public_order_pages) from public, anon, authenticated;

create or replace function public.public_storefront(p_slug text)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare page public_order_pages; allowed boolean;
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
  return _storefront_payload(page);
end $function$;

create or replace function public.storefront_preview(p_business_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare page public_order_pages;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  select * into page from public_order_pages where business_id = p_business_id;
  if page.id is null then return null; end if;
  return _storefront_payload(page) || jsonb_build_object('published', page.enabled);
end $$;
revoke all on function public.storefront_preview(uuid) from public, anon;
grant execute on function public.storefront_preview(uuid) to authenticated;
