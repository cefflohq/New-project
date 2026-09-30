-- CEFFLO product photos, V1 "original as-is" (Founder, 2026-10-01, STAGING
-- first). The S4-10C processing worker does not exist yet, so an uploaded
-- photo stayed 'queued' forever and never reached the storefront.
--
-- V1 flow, no second media system:
--   1. the Vendor client uploads the validated original (JPG/PNG/WebP,
--      <= 5 MB, compressed on the device) to cefflo-product-originals and
--      registers it (create_product_media -> 'queued', at a position);
--   2. it uploads the SAME bytes to the public cefflo-product-display bucket
--      at {business}/{product}/{media}/display.{ext} (existing write policy:
--      Owner/Operator, same-business product path);
--   3. mark_product_media_displayable verifies that exact object exists and
--      moves the row queued -> prepared -> approved through the existing
--      approval path. processing_version = 0 records "original, not
--      processed", so a future worker can find and reprocess these rows
--      (and bump processing_version) without any schema change.
-- Only approved, non-archived rows are ever listed publicly; replacing a
-- position archives the previous photo, which drops out of every catalogue.

create or replace function public.mark_product_media_displayable(p_media_id uuid)
returns public.product_media
language plpgsql security definer set search_path to 'public' as $$
declare v public.product_media; ext text; display_path text;
begin
  select * into v from public.product_media where id = p_media_id and archived_at is null for update;
  if v.id is null or not public.is_business_operational(v.business_id) then raise exception 'forbidden'; end if;
  if v.status = 'approved' then return v; end if; -- idempotent replay
  if v.status is distinct from 'queued' then raise exception 'media is not awaiting display'; end if;

  ext := case v.original_content_type when 'image/jpeg' then 'jpg' when 'image/png' then 'png' else 'webp' end;
  display_path := v.business_id::text || '/' || v.product_id::text || '/' || v.id::text || '/display.' || ext;
  if not exists (select 1 from storage.objects where bucket_id = 'cefflo-product-display' and name = display_path) then
    raise exception 'display upload not found';
  end if;

  update public.product_media
     set status = 'prepared', prepared_storage_path = display_path,
         prepared_content_type = v.original_content_type, processing_version = 0,
         updated_at = now()
   where id = v.id;
  return public.approve_product_media(v.id);
end $$;

revoke all on function public.mark_product_media_displayable(uuid) from public, anon;
grant execute on function public.mark_product_media_displayable(uuid) to authenticated;
