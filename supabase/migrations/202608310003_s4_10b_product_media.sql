-- S4-10B: durable Product Media + Storage foundation.
--
-- Provides the media/version/approval contract that S4-10C's future
-- preparation pipeline will drive. Does NOT perform any image processing --
-- there is no background-removal/normalization logic here, only the
-- storage layout and state machine an external worker will later transition
-- through. Original photos are never overwritten; every upload is a new,
-- immutable row referencing its own storage object.
--
-- State machine (5 values, deliberately not larger): 'queued' covers both
-- "upload received" and "waiting/ready for processing" from the S4-10B
-- brief -- nothing meaningful happens between those two moments (the row
-- becomes pickable by a worker the instant it exists), so collapsing them
-- avoids state explosion while still satisfying both named requirements.
-- 'processing' -> 'prepared' | 'failed' -> (retry) 'queued'. A 'prepared'
-- row becomes 'approved' only through an explicit Vendor action.
--
-- Two independent partial-unique invariants give a deterministic answer to
-- "what does the customer see" and "what is currently under review" without
-- any boolean is_current flag:
--   - at most one 'approved' + not-archived row per product (the current
--     display image)
--   - at most one active in-flight row per product (queued/processing/
--     prepared, not-archived) -- uploading a replacement supersedes
--     (soft-archives) whatever was previously pending, it never deletes it.
create type public.product_media_status as enum ('queued','processing','prepared','failed','approved');

-- Extends S4-10A's own composite-FK pattern (products already reused this
-- exact technique against product_categories) one level deeper: media can
-- only ever attach to a product in its own business.
alter table public.products add constraint products_business_id_id_key unique (business_id, id);

create table public.product_media (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  product_id uuid not null,
  original_storage_path text not null,
  original_content_type text not null check (original_content_type in ('image/jpeg','image/png','image/webp')),
  prepared_storage_path text,
  prepared_content_type text check (prepared_content_type is null or prepared_content_type in ('image/jpeg','image/png','image/webp')),
  status public.product_media_status not null default 'queued',
  processing_version integer,
  failure_reason text check (failure_reason is null or char_length(failure_reason) <= 500),
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  constraint product_media_product_same_business_fk
    foreign key (business_id, product_id)
    references public.products(business_id, id)
    on delete restrict,
  constraint product_media_prepared_requires_processed_status
    check (prepared_storage_path is null or status in ('prepared','approved')),
  constraint product_media_approved_has_timestamp
    check ((status = 'approved') = (approved_at is not null)),
  constraint product_media_failure_only_on_failed
    check (failure_reason is null or status = 'failed')
);

create index product_media_product_history_idx
  on public.product_media (product_id, created_at desc);
create unique index product_media_current_approved_idx
  on public.product_media (product_id)
  where status = 'approved' and archived_at is null;
create unique index product_media_active_pending_idx
  on public.product_media (product_id)
  where status in ('queued','processing','prepared') and archived_at is null;

alter table public.product_media enable row level security;

create policy product_media_vendor_read on public.product_media
  for select to authenticated
  using (public.is_business_member(business_id));

revoke all on table public.product_media from public, anon, authenticated;
grant select on table public.product_media to authenticated;

-- ===================== STORAGE =====================
-- Originals are never public. Path convention:
--   {business_id}/{product_id}/{media_id}/original.{ext}
--   {business_id}/{product_id}/{media_id}/prepared.{ext}
-- Both original and prepared derivatives live here while a media row is
-- under review -- the prepared derivative only ever reaches the public
-- bucket at Vendor-approval time (see approve_product_media), never before,
-- so an unapproved image can never become customer-reachable.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
  values('cefflo-product-originals','cefflo-product-originals',false,10485760,array['image/jpeg','image/png','image/webp'])
  on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

-- Display is public-read (the eventual public Order Page needs direct,
-- unauthenticated access to approved assets) but still ownership-gated on
-- write -- only the Vendor who owns the product (proven by
-- is_business_member + the same-business product check) may ever place an
-- object here, and only ever the exact object they were the one to approve.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
  values('cefflo-product-display','cefflo-product-display',true,10485760,array['image/jpeg','image/png','image/webp'])
  on conflict(id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

create policy product_originals_vendor_write on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'cefflo-product-originals'
    and exists (
      select 1 from public.products p
      where p.id = (storage.foldername(name))[2]::uuid
        and p.business_id = (storage.foldername(name))[1]::uuid
        and p.archived_at is null
        and public.is_business_member(p.business_id)
    )
  );
create policy product_originals_vendor_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'cefflo-product-originals'
    and public.is_business_member((storage.foldername(name))[1]::uuid)
  );

create policy product_display_vendor_write on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'cefflo-product-display'
    and exists (
      select 1 from public.products p
      where p.id = (storage.foldername(name))[2]::uuid
        and p.business_id = (storage.foldername(name))[1]::uuid
        and public.is_business_member(p.business_id)
    )
  );
-- No authenticated/anon SELECT policy needed on cefflo-product-display:
-- public=true buckets serve reads directly, bypassing storage.objects RLS.

-- ===================== RPCs (Vendor-facing) =====================
-- Registers an original photo the Vendor's own client has already uploaded
-- to the exact deterministic path this function recomputes and verifies --
-- the client-supplied path is never trusted, only the (business_id,
-- product_id, media_id, content_type) identity is, matching the existing
-- POD-completion precedent (verify live storage.objects existence rather
-- than trusting a client string).
create function public.create_product_media(p_product_id uuid, p_media_id uuid, p_content_type text)
returns public.product_media
language plpgsql security definer set search_path = public
as $$
declare
  biz uuid; ext text; path text; existing public.product_media;
begin
  select business_id into biz from public.products where id = p_product_id and archived_at is null;
  if biz is null or not public.is_business_member(biz) then raise exception 'forbidden'; end if;
  if p_media_id is null then raise exception 'invalid media id'; end if;
  if p_content_type not in ('image/jpeg','image/png','image/webp') then raise exception 'invalid content type'; end if;
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
  update public.product_media
    set archived_at = now(), updated_at = now()
    where product_id = p_product_id and archived_at is null
      and status in ('queued','processing','prepared');

  insert into public.product_media(id,business_id,product_id,original_storage_path,original_content_type,status)
  values (p_media_id, biz, p_product_id, path, p_content_type, 'queued')
  returning * into existing;
  return existing;
end;
$$;

create function public.retry_product_media_processing(p_media_id uuid)
returns public.product_media
language plpgsql security definer set search_path = public
as $$
declare v public.product_media;
begin
  select * into v from public.product_media where id = p_media_id and archived_at is null for update;
  if v.id is null or not public.is_business_member(v.business_id) then raise exception 'forbidden'; end if;
  if v.status is distinct from 'failed' then raise exception 'media is not in a failed state'; end if;
  update public.product_media set status = 'queued', failure_reason = null, updated_at = now() where id = v.id returning * into v;
  return v;
end;
$$;

-- Approval is the ONLY path by which an image becomes customer-reachable.
-- Demotes any prior approved row for the same product (archived, not
-- deleted -- full history preserved) and approves this one, atomically.
create function public.approve_product_media(p_media_id uuid)
returns public.product_media
language plpgsql security definer set search_path = public
as $$
declare v public.product_media;
begin
  select * into v from public.product_media where id = p_media_id and archived_at is null for update;
  if v.id is null or not public.is_business_member(v.business_id) then raise exception 'forbidden'; end if;
  if v.status is distinct from 'prepared' then raise exception 'media is not ready for approval'; end if;
  if v.prepared_storage_path is null then raise exception 'no prepared asset to approve'; end if;

  update public.product_media set archived_at = now(), updated_at = now()
    where product_id = v.product_id and status = 'approved' and archived_at is null;

  update public.product_media set status = 'approved', approved_at = now(), updated_at = now()
    where id = v.id returning * into v;
  return v;
end;
$$;

create function public.archive_product_media(p_media_id uuid)
returns public.product_media
language plpgsql security definer set search_path = public
as $$
declare v public.product_media;
begin
  select * into v from public.product_media where id = p_media_id for update;
  if v.id is null or not public.is_business_member(v.business_id) then raise exception 'forbidden'; end if;
  if v.archived_at is not null then return v; end if; -- idempotent
  update public.product_media set archived_at = now(), updated_at = now() where id = v.id returning * into v;
  return v;
end;
$$;

revoke all on function public.create_product_media(uuid,uuid,text) from public, anon, authenticated;
revoke all on function public.retry_product_media_processing(uuid) from public, anon, authenticated;
revoke all on function public.approve_product_media(uuid) from public, anon, authenticated;
revoke all on function public.archive_product_media(uuid) from public, anon, authenticated;
grant execute on function public.create_product_media(uuid,uuid,text) to authenticated;
grant execute on function public.retry_product_media_processing(uuid) to authenticated;
grant execute on function public.approve_product_media(uuid) to authenticated;
grant execute on function public.archive_product_media(uuid) to authenticated;

-- ===================== RPCs (future S4-10C worker only) =====================
-- Deliberately NOT granted to authenticated: a Vendor's own client must
-- never be able to self-report "processing" or fabricate a "prepared"
-- state without a real worker having actually produced the asset. Only a
-- trusted service_role-driven process (S4-10C, not built in this package)
-- may drive these transitions -- this is the concrete enforcement of the
-- image-truthfulness guardrail at the contract layer: no code path lets a
-- Vendor session put its own image into 'prepared'/'approved'-eligible
-- state without going through this gate.
create function public.mark_product_media_processing(p_media_id uuid)
returns public.product_media
language plpgsql security definer set search_path = public
as $$
declare v public.product_media;
begin
  select * into v from public.product_media where id = p_media_id and archived_at is null for update;
  if v.id is null then raise exception 'media not found'; end if;
  if v.status is distinct from 'queued' then raise exception 'media is not queued'; end if;
  update public.product_media set status = 'processing', updated_at = now() where id = v.id returning * into v;
  return v;
end;
$$;

create function public.mark_product_media_prepared(p_media_id uuid, p_content_type text, p_processing_version integer)
returns public.product_media
language plpgsql security definer set search_path = public
as $$
declare v public.product_media; ext text; path text;
begin
  select * into v from public.product_media where id = p_media_id and archived_at is null for update;
  if v.id is null then raise exception 'media not found'; end if;
  if v.status is distinct from 'processing' then raise exception 'media is not processing'; end if;
  if p_content_type not in ('image/jpeg','image/png','image/webp') then raise exception 'invalid content type'; end if;
  ext := case p_content_type when 'image/jpeg' then 'jpg' when 'image/png' then 'png' else 'webp' end;
  path := v.business_id::text || '/' || v.product_id::text || '/' || v.id::text || '/prepared.' || ext;
  if not exists (select 1 from storage.objects where bucket_id = 'cefflo-product-originals' and name = path) then
    raise exception 'prepared asset not found';
  end if;
  update public.product_media
    set status = 'prepared', prepared_storage_path = path, prepared_content_type = p_content_type,
        processing_version = p_processing_version, updated_at = now()
    where id = v.id returning * into v;
  return v;
end;
$$;

create function public.mark_product_media_failed(p_media_id uuid, p_failure_reason text)
returns public.product_media
language plpgsql security definer set search_path = public
as $$
declare v public.product_media;
begin
  select * into v from public.product_media where id = p_media_id and archived_at is null for update;
  if v.id is null then raise exception 'media not found'; end if;
  if v.status is distinct from 'processing' then raise exception 'media is not processing'; end if;
  update public.product_media
    set status = 'failed', failure_reason = nullif(btrim(coalesce(p_failure_reason,'')),''), updated_at = now()
    where id = v.id returning * into v;
  return v;
end;
$$;

revoke all on function public.mark_product_media_processing(uuid) from public, anon, authenticated;
revoke all on function public.mark_product_media_prepared(uuid,text,integer) from public, anon, authenticated;
revoke all on function public.mark_product_media_failed(uuid,text) from public, anon, authenticated;
grant execute on function public.mark_product_media_processing(uuid) to service_role;
grant execute on function public.mark_product_media_prepared(uuid,text,integer) to service_role;
grant execute on function public.mark_product_media_failed(uuid,text) to service_role;
