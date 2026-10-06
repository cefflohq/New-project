-- Driver licence document store (Founder 2026-10-06: Documents are ACTIVE).
-- Malaysia only (no foreign drivers yet). The Driver types their MyKad IC
-- number and photographs their DRIVING LICENCE (which carries the IC number,
-- name and address). One person = one account: an IC number already
-- registered to another account cannot be used again, so a second account
-- (or a relative's) cannot dodge the RM50 vehicle-change fee. Reviewed by
-- Cefflo (FOUNDR) only; businesses never see it (PDPA). Kept while the
-- account exists (deleted with the account).
--
-- * Private bucket cefflo-driver-documents: a Driver uploads only under
--   their own folder ({auth.uid()}/...) and reads only their own files;
--   Cefflo platform admins read for review. Businesses never see the photo.
-- * driver_licences: one row per account. The IC number is stored as a
--   salted SHA-256 (unique) plus the last 4 digits for display; never in
--   clear text.
-- * submit_driver_licence: the Driver submits IC number + licence photo ->
--   'submitted'; an IC held by another account is refused. A verified
--   identity cannot be swapped by the Driver.
-- * review_driver_licence: platform admin (FOUNDR) verifies or rejects.
-- Rollback: drop the two functions, the table, the storage policies and the
-- bucket (after exporting any rows).

insert into storage.buckets (id, name, public)
values ('cefflo-driver-documents', 'cefflo-driver-documents', false)
on conflict (id) do nothing;

create table if not exists public.driver_licences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  ic_hash text not null unique,
  ic_last4 text not null,
  photo_path text not null,
  status text not null default 'submitted' check (status in ('submitted', 'verified', 'rejected')),
  reject_reason text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id)
);

alter table public.driver_licences enable row level security;
revoke all on public.driver_licences from anon;
revoke insert, update, delete on public.driver_licences from authenticated;

create policy driver_licences_read on public.driver_licences
  for select to authenticated
  using (user_id = auth.uid() or public.is_platform_admin());

-- storage: own folder only; platform admins read for review
create policy driver_documents_own_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'cefflo-driver-documents'
              and (storage.foldername(name))[1] = auth.uid()::text);
create policy driver_documents_own_read on storage.objects
  for select to authenticated
  using (bucket_id = 'cefflo-driver-documents'
         and ((storage.foldername(name))[1] = auth.uid()::text or public.is_platform_admin()));

create or replace function public._ic_hash(p_ic text)
returns text language sql immutable set search_path = public, extensions as $$
  select encode(digest('cefflo-driver-ic:v1:' || p_ic, 'sha256'), 'hex')
$$;
revoke all on function public._ic_hash(text) from public, anon, authenticated;

create or replace function public.submit_driver_licence(p_ic_number text, p_photo_path text)
returns public.driver_licences
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_norm text := regexp_replace(coalesce(p_ic_number, ''), '\D', '', 'g');
  v_hash text;
  v_mine driver_licences;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  -- MyKad: 12 digits YYMMDD-PB-###G with a real birth date.
  if v_norm !~ '^[0-9]{12}$'
     or substr(v_norm, 3, 2)::int not between 1 and 12
     or substr(v_norm, 5, 2)::int not between 1 and 31 then
    raise exception 'invalid IC number';
  end if;
  if p_photo_path is null or split_part(p_photo_path, '/', 1) <> auth.uid()::text then
    raise exception 'invalid licence photo';
  end if;
  if not exists (select 1 from storage.objects o where o.bucket_id = 'cefflo-driver-documents' and o.name = p_photo_path) then
    raise exception 'licence photo not uploaded';
  end if;
  v_hash := _ic_hash(v_norm);
  if exists (select 1 from driver_licences l where l.ic_hash = v_hash and l.user_id <> auth.uid()) then
    raise exception 'IC already registered to another account';
  end if;
  select * into v_mine from driver_licences where user_id = auth.uid() for update;
  if v_mine.user_id is not null and v_mine.status = 'verified' and v_mine.ic_hash <> v_hash then
    raise exception 'a verified identity cannot be replaced; contact Cefflo support';
  end if;
  insert into driver_licences(user_id, ic_hash, ic_last4, photo_path, status, submitted_at)
    values (auth.uid(), v_hash, right(v_norm, 4), p_photo_path, 'submitted', now())
  on conflict (user_id) do update
    set ic_hash = excluded.ic_hash, ic_last4 = excluded.ic_last4,
        photo_path = excluded.photo_path,
        status = case when driver_licences.status = 'verified' then 'verified' else 'submitted' end,
        reject_reason = null, submitted_at = now()
  returning * into v_mine;
  return v_mine;
end $$;

create or replace function public.review_driver_licence(p_user_id uuid, p_approve boolean, p_reason text default null)
returns public.driver_licences
language plpgsql security definer set search_path = public as $$
declare v driver_licences;
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  update driver_licences
     set status = case when p_approve then 'verified' else 'rejected' end,
         reject_reason = case when p_approve then null else nullif(btrim(p_reason), '') end,
         reviewed_at = now(), reviewed_by = auth.uid()
   where user_id = p_user_id
   returning * into v;
  if v.user_id is null then raise exception 'licence not found'; end if;
  return v;
end $$;

revoke all on function public.submit_driver_licence(text, text) from public, anon;
revoke all on function public.review_driver_licence(uuid, boolean, text) from public, anon;
grant execute on function public.submit_driver_licence(text, text) to authenticated;
grant execute on function public.review_driver_licence(uuid, boolean, text) to authenticated;
