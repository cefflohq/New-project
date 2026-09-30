-- CEFFLO profile photos (Founder approval 2026-09-30, staging first).
--
-- Reusable capability on the canonical identity: every signed-in person
-- (Vendor Owner / Operator / Helper, Driver, FOUNDR admin) has exactly one
-- `profiles` row keyed by auth.users.id, and may keep one photo.
--
-- Ownership is derived from the authenticated identity only:
--   * the object path is fixed per user: '<auth.uid()>/avatar' — one object,
--     replaced in place, never a client-chosen name;
--   * storage policies allow read / upload / replace / delete of that one
--     path for its owner and nothing else;
--   * profiles.avatar_url may only name the owner's own path (check
--     constraint), and the row itself stays under profiles_self.
-- The bucket is private (read through short-lived signed URLs), limited to
-- 2 MB and to JPEG / PNG / WebP. No other table, bucket, RPC or policy is
-- touched.

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
  values ('cefflo-avatars', 'cefflo-avatars', false, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
  on conflict (id) do update
    set public = false,
        file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles drop constraint if exists profiles_avatar_url_own_path;
alter table public.profiles add constraint profiles_avatar_url_own_path
  check (avatar_url is null or avatar_url = id::text || '/avatar');

create policy avatars_owner_read on storage.objects
  for select to authenticated
  using (bucket_id = 'cefflo-avatars' and name = auth.uid()::text || '/avatar');

create policy avatars_owner_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'cefflo-avatars' and name = auth.uid()::text || '/avatar');

create policy avatars_owner_update on storage.objects
  for update to authenticated
  using (bucket_id = 'cefflo-avatars' and name = auth.uid()::text || '/avatar')
  with check (bucket_id = 'cefflo-avatars' and name = auth.uid()::text || '/avatar');

create policy avatars_owner_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'cefflo-avatars' and name = auth.uid()::text || '/avatar');
