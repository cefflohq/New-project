-- Driver support tickets, finished (Founder 2026-10-17): drivers add up to 3
-- photos, see their own tickets with Cefflo's reply in the app, and FOUNDR
-- sees the photos.
alter table public.support_tickets add column if not exists photo_paths text[] not null default '{}';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('cefflo-support-photos', 'cefflo-support-photos', false, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;
create policy support_photos_own_write on storage.objects for insert to authenticated
  with check (bucket_id = 'cefflo-support-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy support_photos_read on storage.objects for select using (
  bucket_id = 'cefflo-support-photos' and ((storage.foldername(name))[1] = auth.uid()::text or is_platform_admin()));

drop function if exists public.submit_support_ticket(text, text, uuid);
create or replace function public.submit_support_ticket(p_category text, p_description text, p_rider_id uuid default null, p_photos text[] default '{}')
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_rider riders;
  v_audience text := case when p_category in ('delivery_run','vendor_business') then 'vendor' else 'cefflo' end;
  m record; p text;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if coalesce(array_length(p_photos, 1), 0) > 3 then raise exception 'up to 3 photos'; end if;
  foreach p in array coalesce(p_photos, '{}') loop
    if split_part(p, '/', 1) <> auth.uid()::text then raise exception 'invalid photo'; end if;
  end loop;
  if p_rider_id is not null then
    select * into v_rider from riders where id = p_rider_id and auth_user_id = auth.uid();
    if v_rider.id is null then raise exception 'forbidden'; end if;
  end if;
  if v_audience = 'vendor' and v_rider.id is null then v_audience := 'cefflo'; end if;
  insert into support_tickets (auth_user_id, rider_id, business_id, category, audience, description, photo_paths)
  values (auth.uid(), v_rider.id, v_rider.business_id, p_category, v_audience, trim(p_description), coalesce(p_photos, '{}'))
  returning id into v_id;
  if v_audience = 'vendor' then
    for m in select user_id from business_members
              where business_id = v_rider.business_id and coalesce(status,'active') = 'active' loop
      perform notify_user(m.user_id, 'vendor', v_rider.business_id, 'support.ticket', 'operational',
        'normal', 'Driver support: ' || v_rider.name, left(trim(p_description), 200),
        jsonb_build_object('screen','rider','id', v_rider.id), jsonb_build_object('ticket_id', v_id, 'name', v_rider.name),
        'support:' || v_id);
    end loop;
  end if;
  return v_id;
end $$;
revoke all on function public.submit_support_ticket(text, text, uuid, text[]) from public, anon;
grant execute on function public.submit_support_ticket(text, text, uuid, text[]) to authenticated;

-- The caller's own tickets, newest first, with Cefflo's reply.
create or replace function public.my_support_tickets()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', t.id, 'category', t.category, 'audience', t.audience,
           'description', t.description, 'status', t.status, 'created_at', t.created_at,
           'reply', t.resolution_note, 'resolved_at', t.resolved_at, 'business_name', b.name)
         order by t.created_at desc), '[]'::jsonb)
  from support_tickets t left join businesses b on b.id = t.business_id
  where t.auth_user_id = auth.uid()
$$;
revoke all on function public.my_support_tickets() from public, anon;
grant execute on function public.my_support_tickets() to authenticated;

-- FOUNDR lists the photos too.
create or replace function public.admin_list_support_tickets()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  return (select coalesce(jsonb_agg(x), '[]'::jsonb) from (
    select jsonb_build_object('id', t.id, 'category', t.category, 'audience', t.audience,
      'description', t.description, 'status', t.status, 'created_at', t.created_at,
      'resolved_at', t.resolved_at, 'resolution_note', t.resolution_note, 'photo_paths', t.photo_paths,
      'email', u.email, 'phone', r.phone,
      'name', coalesce(r.name, u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name'),
      'business_name', b.name) as x
    from support_tickets t
    left join auth.users u on u.id = t.auth_user_id
    left join riders r on r.id = t.rider_id
    left join businesses b on b.id = t.business_id
    where t.audience = 'cefflo'
    order by (t.status = 'resolved'), t.created_at desc limit 500) s);
end $$;

-- The reply reaches the driver as an in-app notice too.
create or replace function public.admin_resolve_support_ticket(p_id uuid, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare t support_tickets;
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if coalesce(length(trim(p_note)), 0) < 3 then raise exception 'note required'; end if;
  update support_tickets set status = 'resolved', resolved_at = now(), resolution_note = trim(p_note)
   where id = p_id and audience = 'cefflo' and status = 'open' returning * into t;
  if t.id is null then raise exception 'not found or already resolved'; end if;
  perform notify_user(t.auth_user_id, 'rider', t.business_id, 'support.reply', 'account', 'normal',
    'Cefflo replied to your support request', left(trim(p_note), 200),
    '{"screen":"none"}'::jsonb, jsonb_build_object('ticket_id', t.id), 'support-reply:' || t.id);
  insert into admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
  values (auth.uid(), 'support_ticket_resolved', 'support_ticket', p_id::text, trim(p_note), '{}'::jsonb);
end $$;
