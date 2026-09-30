-- CEFFLO product photos: up to 5 active photos per product, ordered, 5 MB
-- each (Founder approval 2026-10-01, STAGING first). Replaces the S4-10B
-- one-photo invariants. product_media had 0 rows on staging at apply time.
--
-- Also tightens management to Owner + Operator (is_business_operational):
-- the S4-10B functions and storage write policies allowed any member,
-- including Helpers. And fixes product_display_vendor_write, whose
-- subquery resolved `name` to products.name instead of the object path.

-- 1. Position within a product (1..5).
alter table public.product_media add column if not exists position smallint;
alter table public.product_media drop constraint if exists product_media_position_range;
alter table public.product_media
  add constraint product_media_position_range check (position is null or position between 1 and 5);

-- 2. One active photo per position instead of one per product.
drop index if exists public.product_media_current_approved_idx;
drop index if exists public.product_media_active_pending_idx;
create unique index product_media_active_position_idx
  on public.product_media(product_id, position)
  where archived_at is null and status in ('queued','processing','prepared','approved');

-- 3. At most 5 active photos per product (server-enforced).
create or replace function public._product_media_limit()
returns trigger language plpgsql set search_path to 'public' as $$
begin
  if new.archived_at is null and new.status in ('queued','processing','prepared','approved') and (
    select count(*) from public.product_media
     where product_id = new.product_id and archived_at is null and id <> new.id
       and status in ('queued','processing','prepared','approved')) >= 5 then
    raise exception 'a product can have at most 5 photos';
  end if;
  return new;
end $$;
drop trigger if exists product_media_limit on public.product_media;
create trigger product_media_limit before insert or update of archived_at, status on public.product_media
  for each row execute function public._product_media_limit();

-- 4. Register an uploaded original at a position. Replacing a position
--    archives only the photo at that position.
drop function if exists public.create_product_media(uuid, uuid, text);
create function public.create_product_media(p_product_id uuid, p_media_id uuid, p_content_type text, p_position smallint default null)
returns public.product_media
language plpgsql security definer set search_path to 'public' as $$
declare
  biz uuid; ext text; path text; existing public.product_media; pos smallint := p_position;
begin
  select business_id into biz from public.products where id = p_product_id and archived_at is null;
  if biz is null or not public.is_business_operational(biz) then raise exception 'forbidden'; end if;
  if p_media_id is null then raise exception 'invalid media id'; end if;
  if p_content_type not in ('image/jpeg','image/png','image/webp') then raise exception 'invalid content type'; end if;
  if pos is not null and pos not between 1 and 5 then raise exception 'invalid position'; end if;
  ext := case p_content_type when 'image/jpeg' then 'jpg' when 'image/png' then 'png' else 'webp' end;
  path := biz::text || '/' || p_product_id::text || '/' || p_media_id::text || '/original.' || ext;

  select * into existing from public.product_media where id = p_media_id;
  if existing.id is not null then
    if existing.product_id is distinct from p_product_id then raise exception 'media id already used'; end if;
    return existing; -- idempotent replay of the same upload call
  end if;

  if not exists (select 1 from storage.objects where bucket_id = 'cefflo-product-originals' and name = path) then
    raise exception 'original upload not found';
  end if;

  perform 1 from public.products where id = p_product_id for update;
  if pos is null then
    select min(s) into pos from generate_series(1, 5) s
     where not exists (select 1 from public.product_media m
       where m.product_id = p_product_id and m.position = s and m.archived_at is null
         and m.status in ('queued','processing','prepared','approved'));
    if pos is null then raise exception 'a product can have at most 5 photos'; end if;
  else
    -- Replace: only the photo currently at this position.
    update public.product_media set archived_at = now(), updated_at = now()
     where product_id = p_product_id and position = pos and archived_at is null;
  end if;

  insert into public.product_media(id, business_id, product_id, original_storage_path, original_content_type, status, position)
  values (p_media_id, biz, p_product_id, path, p_content_type, 'queued', pos)
  returning * into existing;
  return existing;
end $$;

create or replace function public.retry_product_media_processing(p_media_id uuid)
returns public.product_media
language plpgsql security definer set search_path to 'public' as $$
declare v public.product_media;
begin
  select * into v from public.product_media where id = p_media_id and archived_at is null for update;
  if v.id is null or not public.is_business_operational(v.business_id) then raise exception 'forbidden'; end if;
  if v.status is distinct from 'failed' then raise exception 'media is not failed'; end if;
  update public.product_media set status = 'queued', failure_reason = null, updated_at = now() where id = v.id returning * into v;
  return v;
end $$;

-- Approval archives only a previously approved photo at the SAME position.
create or replace function public.approve_product_media(p_media_id uuid)
returns public.product_media
language plpgsql security definer set search_path to 'public' as $$
declare v public.product_media;
begin
  select * into v from public.product_media where id = p_media_id and archived_at is null for update;
  if v.id is null or not public.is_business_operational(v.business_id) then raise exception 'forbidden'; end if;
  if v.status is distinct from 'prepared' then raise exception 'media is not ready for approval'; end if;
  if v.prepared_storage_path is null then raise exception 'no prepared asset to approve'; end if;

  update public.product_media set archived_at = now(), updated_at = now()
    where product_id = v.product_id and position is not distinct from v.position
      and status = 'approved' and archived_at is null and id <> v.id;

  update public.product_media set status = 'approved', approved_at = now(), updated_at = now()
    where id = v.id returning * into v;
  return v;
end $$;

create or replace function public.archive_product_media(p_media_id uuid)
returns public.product_media
language plpgsql security definer set search_path to 'public' as $$
declare v public.product_media;
begin
  select * into v from public.product_media where id = p_media_id for update;
  if v.id is null or not public.is_business_operational(v.business_id) then raise exception 'forbidden'; end if;
  if v.archived_at is not null then return v; end if; -- idempotent
  update public.product_media set archived_at = now(), updated_at = now() where id = v.id returning * into v;
  return v;
end $$;

-- 5. Reorder: p_media_ids in the new order become positions 1..n. Moves go
--    through a temporary negative-free offset so the unique index holds.
create or replace function public.reorder_product_media(p_product_id uuid, p_media_ids uuid[])
returns setof public.product_media
language plpgsql security definer set search_path to 'public' as $$
declare biz uuid; n int := coalesce(array_length(p_media_ids, 1), 0); active int;
begin
  select business_id into biz from public.products where id = p_product_id and archived_at is null;
  if biz is null or not public.is_business_operational(biz) then raise exception 'forbidden'; end if;
  select count(*) into active from public.product_media
   where product_id = p_product_id and archived_at is null and status in ('queued','processing','prepared','approved');
  if n <> active or n > 5 or (select count(distinct x) from unnest(p_media_ids) x) <> n
     or exists (select 1 from unnest(p_media_ids) x where not exists (
       select 1 from public.product_media m where m.id = x and m.product_id = p_product_id
         and m.archived_at is null and m.status in ('queued','processing','prepared','approved'))) then
    raise exception 'reorder must list every active photo of the product once';
  end if;
  perform 1 from public.products where id = p_product_id for update;
  update public.product_media set position = null
   where product_id = p_product_id and archived_at is null;
  update public.product_media m set position = o.ord, updated_at = now()
    from unnest(p_media_ids) with ordinality as o(id, ord)
   where m.id = o.id;
  return query select * from public.product_media
    where product_id = p_product_id and archived_at is null order by position;
end $$;

revoke all on function public.create_product_media(uuid, uuid, text, smallint) from public, anon;
revoke all on function public.reorder_product_media(uuid, uuid[]) from public, anon;
grant execute on function public.create_product_media(uuid, uuid, text, smallint) to authenticated;
grant execute on function public.reorder_product_media(uuid, uuid[]) to authenticated;

-- 6. Storage: Owner + Operator only; fix the display policy's path bug.
drop policy if exists product_originals_vendor_write on storage.objects;
create policy product_originals_vendor_write on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'cefflo-product-originals'
    and exists (
      select 1 from public.products p
      where p.id = (storage.foldername(storage.objects.name))[2]::uuid
        and p.business_id = (storage.foldername(storage.objects.name))[1]::uuid
        and p.archived_at is null
        and public.is_business_operational(p.business_id)
    )
  );
drop policy if exists product_display_vendor_write on storage.objects;
create policy product_display_vendor_write on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'cefflo-product-display'
    and exists (
      select 1 from public.products p
      where p.id = (storage.foldername(storage.objects.name))[2]::uuid
        and p.business_id = (storage.foldername(storage.objects.name))[1]::uuid
        and public.is_business_operational(p.business_id)
    )
  );

-- 7. 5 MB per image in both buckets.
update storage.buckets set file_size_limit = 5242880
 where id in ('cefflo-product-originals', 'cefflo-product-display');
