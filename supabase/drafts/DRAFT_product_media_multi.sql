-- DRAFT — NOT APPLIED. Founder approval required before staging apply.
-- Product photos: up to 5 active photos per product, ordered, 5 MB each
-- (Founder, 2026-10-01). Verified gap on staging 2026-10-01:
--   * product_media_current_approved_idx: UNIQUE(product_id) where
--     approved -> only ONE approved photo per product;
--   * product_media_active_pending_idx: UNIQUE(product_id) where queued/
--     processing/prepared -> only ONE photo in the pipeline;
--   * create_product_media archives every other pending photo, and
--     approve_product_media archives every other approved photo;
--   * no position column; buckets allow 10 MB (not 5 MB);
--   * create/approve check is_business_member (includes Helper).
-- product_media has 0 rows on staging, so no data needs migrating.

-- 1. Order within a product.
alter table public.product_media add column if not exists position smallint;
alter table public.product_media
  add constraint product_media_position_range check (position is null or position between 1 and 5);

-- 2. Replace the one-photo indexes with "one photo per position".
drop index if exists public.product_media_current_approved_idx;
drop index if exists public.product_media_active_pending_idx;
create unique index product_media_active_position_idx
  on public.product_media(product_id, position)
  where archived_at is null and status in ('queued','processing','prepared','approved');

-- 3. Max 5 active photos per product, enforced server-side.
create or replace function public._product_media_limit()
returns trigger language plpgsql as $$
begin
  if new.archived_at is null and (
    select count(*) from public.product_media
     where product_id = new.product_id and archived_at is null and id <> new.id
       and status in ('queued','processing','prepared','approved')) >= 5 then
    raise exception 'a product can have at most 5 photos';
  end if;
  return new;
end $$;
create trigger product_media_limit before insert or update of archived_at on public.product_media
  for each row execute function public._product_media_limit();

-- 4. create_product_media(p_product_id, p_media_id, p_content_type, p_position)
--    * authorization: is_business_operational (Owner/Operator), not member;
--    * p_position 1..5 (default: first free position);
--    * archives ONLY the photo currently at that position (a replace),
--      never every other photo;
--    * rest of the body unchanged (path, idempotent replay, storage check).
-- 5. approve_product_media(p_media_id)
--    * authorization: is_business_operational;
--    * archives ONLY a previously approved photo at the SAME position.
-- 6. New: archive_product_photo(p_media_id) (Owner/Operator) = remove;
--         reorder_product_photos(p_product_id, p_media_ids uuid[]) sets
--         position 1..n in one statement (deferred unique check).
--    (Function bodies written in full in the apply-ready version.)

-- 7. 5 MB per image, both buckets.
update storage.buckets set file_size_limit = 5242880
 where id in ('cefflo-product-originals', 'cefflo-product-display');

-- Impact:
--   * public_order_catalog returns `limit 1` image today -> keeps working
--     (first approved photo); public_storefront (storefront draft) returns
--     all approved photos ordered by position.
--   * The media processing worker (queued -> processing -> prepared) is
--     unchanged: it works per media row, not per product.
--   * Mobile: picker for up to 5, client-side JPG/PNG/WebP + 5 MB checks
--     (server enforces the same), reorder by drag, remove.
