-- Complaints and disputes (Founder 2026-10-16, "Prosedur Aduan" draft 1).
-- Vendors, drivers and customers file complaints; the other side has 48 h
-- to reply; Cefflo mediates in FOUNDR with the order's own records as
-- neutral evidence, then decides. Driver documents stay sealed
-- (driver_incident_cases); this table is the everyday path.

create sequence if not exists public.complaint_ref_seq;

create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  ref text not null unique default 'CF-' || lpad(nextval('public.complaint_ref_seq')::text, 5, '0'),
  category text not null check (category in ('damaged_lost','conduct','safety','unpaid','fraud','other')),
  status text not null default 'awaiting_reply' check (status in ('awaiting_reply','in_review','resolved')),
  complainant_role text not null check (complainant_role in ('vendor','driver','customer')),
  complainant_user_id uuid references auth.users(id) on delete set null,
  complainant_name text,
  complainant_contact text,
  respondent_role text not null check (respondent_role in ('vendor','driver')),
  respondent_user_id uuid references auth.users(id) on delete set null,
  business_id uuid not null references public.businesses(id) on delete cascade,
  rider_id uuid references public.riders(id) on delete set null,
  order_id uuid references public.orders(id) on delete set null,
  description text not null check (length(trim(description)) between 10 and 3000),
  reply_due_at timestamptz not null default now() + interval '48 hours',
  decision text check (decision in ('settled','no_fault','warning','driver_at_fault','vendor_at_fault','customer_at_fault','false_report')),
  account_action text check (account_action in ('none','written_warning','suspend','ban')),
  decision_note text,
  decided_by uuid references auth.users(id),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists complaints_business_idx on public.complaints (business_id, created_at desc);
create index if not exists complaints_respondent_idx on public.complaints (respondent_user_id);
create index if not exists complaints_complainant_idx on public.complaints (complainant_user_id);

-- The thread: each side's statement and photos, and Cefflo's internal notes.
create table if not exists public.complaint_entries (
  id bigint generated always as identity primary key,
  complaint_id uuid not null references public.complaints(id) on delete cascade,
  kind text not null check (kind in ('statement','reply','photo','note')),
  author_role text not null check (author_role in ('complainant','respondent','cefflo')),
  author_user_id uuid references auth.users(id) on delete set null,
  body text,
  file_path text,
  created_at timestamptz not null default now()
);
create index if not exists complaint_entries_idx on public.complaint_entries (complaint_id, id);

alter table public.complaints enable row level security;
alter table public.complaint_entries enable row level security;
-- Reads go through the RPCs below; only the platform admin reads directly.
create policy complaints_admin_read on public.complaints for select using (is_platform_admin());
create policy complaint_entries_admin_read on public.complaint_entries for select using (is_platform_admin());

-- Photos: a private bucket. People upload into their own folder; the
-- complaint RPCs only accept paths in the caller's folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('cefflo-complaint-evidence', 'cefflo-complaint-evidence', false, 10485760, array['image/jpeg','image/png','image/webp','image/heic'])
on conflict (id) do nothing;
create policy complaint_evidence_own_write on storage.objects for insert to authenticated
  with check (bucket_id = 'cefflo-complaint-evidence' and (storage.foldername(name))[1] = auth.uid()::text);
create policy complaint_evidence_read on storage.objects for select using (
  bucket_id = 'cefflo-complaint-evidence' and (
    (storage.foldername(name))[1] = auth.uid()::text
    or is_platform_admin()
    or exists (select 1 from complaint_entries e join complaints c on c.id = e.complaint_id
                where e.file_path = name
                  and (c.complainant_user_id = auth.uid() or c.respondent_user_id = auth.uid()
                       or is_business_member(c.business_id)))));
-- Cefflo reviews the proof-of-delivery photo of an order under complaint.
create policy pod_admin_complaint_read on storage.objects for select using (
  bucket_id = 'cefflo-pod' and is_platform_admin() and exists (
    select 1 from complaints c where c.order_id = ((storage.foldername(name))[2])::uuid));

create or replace function public._complaint_add_photos(p_id uuid, p_role text, p_paths text[])
returns void language plpgsql security definer set search_path = public as $$
declare p text;
begin
  if coalesce(array_length(p_paths, 1), 0) > 5 then raise exception 'up to 5 photos'; end if;
  foreach p in array coalesce(p_paths, '{}') loop
    if auth.uid() is null or split_part(p, '/', 1) <> auth.uid()::text then raise exception 'invalid photo'; end if;
    insert into complaint_entries (complaint_id, kind, author_role, author_user_id, file_path)
    values (p_id, 'photo', p_role, auth.uid(), p);
  end loop;
end $$;
revoke all on function public._complaint_add_photos(uuid, text, text[]) from public, anon, authenticated;

-- A vendor complains about a driver, or a driver about the business.
create or replace function public.file_complaint(
  p_category text, p_description text, p_rider_id uuid default null,
  p_order_id uuid default null, p_photos text[] default '{}')
returns jsonb language plpgsql security definer set search_path = public as $$
declare r riders; o orders; v_id uuid; v_ref text; v_owner uuid; v_name text;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if p_order_id is not null then
    select * into o from orders where id = p_order_id;
    if o.id is null then raise exception 'order not found'; end if;
    p_rider_id := coalesce(p_rider_id, o.assigned_rider_id);
  end if;
  select * into r from riders where id = p_rider_id;
  if r.id is null then raise exception 'driver not found'; end if;
  if o.id is not null and o.business_id <> r.business_id then raise exception 'forbidden'; end if;
  select coalesce(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', email) into v_name from auth.users where id = auth.uid();

  if is_business_member(r.business_id) then
    if p_category = 'unpaid' then raise exception 'invalid category'; end if;
    insert into complaints (category, complainant_role, complainant_user_id, complainant_name,
                            respondent_role, respondent_user_id, business_id, rider_id, order_id, description)
    values (p_category, 'vendor', auth.uid(), v_name, 'driver', r.auth_user_id, r.business_id, r.id, o.id, trim(p_description))
    returning id, ref into v_id, v_ref;
  elsif r.auth_user_id = auth.uid() then
    select user_id into v_owner from business_members
     where business_id = r.business_id and role = 'owner' and status = 'active' limit 1;
    insert into complaints (category, complainant_role, complainant_user_id, complainant_name,
                            respondent_role, respondent_user_id, business_id, rider_id, order_id, description)
    values (p_category, 'driver', auth.uid(), coalesce(r.name, v_name), 'vendor', v_owner, r.business_id, r.id, o.id, trim(p_description))
    returning id, ref into v_id, v_ref;
  else
    raise exception 'forbidden';
  end if;
  insert into complaint_entries (complaint_id, kind, author_role, author_user_id, body)
  values (v_id, 'statement', 'complainant', auth.uid(), trim(p_description));
  perform _complaint_add_photos(v_id, 'complainant', p_photos);
  return jsonb_build_object('id', v_id, 'ref', v_ref);
end $$;

-- A customer complains from the tracking page (no account). Delivery
-- problems go to the driver; fraud goes to the business.
create or replace function public.file_complaint_by_tracking(
  p_token text, p_category text, p_description text, p_name text, p_contact text)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare t tracking_tokens; o orders; r riders; v_id uuid; v_ref text; v_owner uuid;
begin
  if p_category not in ('damaged_lost','conduct','safety','fraud','other') then raise exception 'invalid category'; end if;
  if coalesce(length(trim(p_contact)), 0) < 6 then raise exception 'contact required'; end if;
  select * into t from tracking_tokens where token_hash = encode(digest(p_token, 'sha256'), 'hex')
     and revoked_at is null and (expires_at is null or expires_at > now());
  select * into o from orders where id = t.order_id;
  if o.id is null then raise exception 'invalid tracking token'; end if;
  if (select count(*) from complaints where order_id = o.id and complainant_role = 'customer') >= 3 then
    raise exception 'too many complaints for this order';
  end if;
  select * into r from riders where id = o.assigned_rider_id;
  select user_id into v_owner from business_members
   where business_id = o.business_id and role = 'owner' and status = 'active' limit 1;
  if p_category = 'fraud' or r.id is null then
    insert into complaints (category, complainant_role, complainant_name, complainant_contact,
                            respondent_role, respondent_user_id, business_id, rider_id, order_id, description)
    values (p_category, 'customer', left(trim(p_name), 120), left(trim(p_contact), 120), 'vendor', v_owner, o.business_id, r.id, o.id, trim(p_description))
    returning id, ref into v_id, v_ref;
  else
    insert into complaints (category, complainant_role, complainant_name, complainant_contact,
                            respondent_role, respondent_user_id, business_id, rider_id, order_id, description)
    values (p_category, 'customer', left(trim(p_name), 120), left(trim(p_contact), 120), 'driver', r.auth_user_id, o.business_id, r.id, o.id, trim(p_description))
    returning id, ref into v_id, v_ref;
  end if;
  insert into complaint_entries (complaint_id, kind, author_role, body)
  values (v_id, 'statement', 'complainant', trim(p_description));
  return jsonb_build_object('id', v_id, 'ref', v_ref);
end $$;

-- Complaints the caller is part of: filed, against them, or (for owners and
-- operators) about their business.
create or replace function public.my_complaints()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(x order by x->>'created_at' desc), '[]'::jsonb) from (
    select jsonb_build_object(
      'id', c.id, 'ref', c.ref, 'category', c.category, 'status', c.status,
      'side', case when c.complainant_user_id = auth.uid()
                     or (c.complainant_role = 'vendor' and is_business_member(c.business_id)) then 'complainant'
                   else 'respondent' end,
      'complainant_role', c.complainant_role, 'respondent_role', c.respondent_role,
      'rider_id', c.rider_id, 'rider_name', r.name, 'business_name', b.name,
      'order_ref', o.public_ref, 'description', c.description,
      'reply_due_at', c.reply_due_at, 'decision', c.decision, 'decision_note', c.decision_note,
      'decided_at', c.decided_at, 'created_at', c.created_at,
      'replied', exists (select 1 from complaint_entries e where e.complaint_id = c.id and e.kind = 'reply'),
      'entries', (select coalesce(jsonb_agg(jsonb_build_object('kind', e.kind, 'author_role', e.author_role,
                    'body', e.body, 'file_path', e.file_path, 'created_at', e.created_at) order by e.id), '[]'::jsonb)
                  from complaint_entries e where e.complaint_id = c.id and e.kind <> 'note')) as x
    from complaints c
    left join riders r on r.id = c.rider_id
    left join businesses b on b.id = c.business_id
    left join orders o on o.id = c.order_id
    where auth.uid() is not null and (
      c.complainant_user_id = auth.uid() or c.respondent_user_id = auth.uid()
      or is_business_member(c.business_id))
  ) s
$$;

-- The other side answers (any time before the decision).
create or replace function public.reply_complaint(p_id uuid, p_body text, p_photos text[] default '{}')
returns void language plpgsql security definer set search_path = public as $$
declare c complaints;
begin
  select * into c from complaints where id = p_id for update;
  if c.id is null or c.status = 'resolved' then raise exception 'complaint closed'; end if;
  if not (c.respondent_user_id = auth.uid()
          or (c.respondent_role = 'vendor' and is_business_member(c.business_id))) then
    raise exception 'forbidden';
  end if;
  if coalesce(length(trim(p_body)), 0) < 5 then raise exception 'reply required'; end if;
  insert into complaint_entries (complaint_id, kind, author_role, author_user_id, body)
  values (c.id, 'reply', 'respondent', auth.uid(), trim(p_body));
  perform _complaint_add_photos(c.id, 'respondent', p_photos);
  update complaints set status = 'in_review' where id = c.id and status = 'awaiting_reply';
end $$;

-- FOUNDR -----------------------------------------------------------------
create or replace function public.admin_list_complaints()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  return (select coalesce(jsonb_agg(x), '[]'::jsonb) from (
    select jsonb_build_object('id', c.id, 'ref', c.ref, 'category', c.category, 'status', c.status,
      'complainant_role', c.complainant_role, 'complainant_name', c.complainant_name,
      'respondent_role', c.respondent_role, 'business_name', b.name, 'rider_name', r.name,
      'order_ref', o.public_ref, 'reply_due_at', c.reply_due_at, 'created_at', c.created_at,
      'decision', c.decision,
      'replied', exists (select 1 from complaint_entries e where e.complaint_id = c.id and e.kind = 'reply')) as x
    from complaints c
    left join businesses b on b.id = c.business_id
    left join riders r on r.id = c.rider_id
    left join orders o on o.id = c.order_id
    order by (c.status = 'resolved'), c.created_at desc limit 500) s);
end $$;

-- One case with everything Cefflo needs to decide: both sides, contacts
-- for mediation, and the order's own records.
create or replace function public.admin_complaint_detail(p_id uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c complaints; v jsonb;
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  select * into c from complaints where id = p_id;
  if c.id is null then raise exception 'not found'; end if;
  select jsonb_build_object(
    'complaint', to_jsonb(c),
    'business', (select jsonb_build_object('name', b.name, 'phone', b.phone, 'email', b.email,
                   'owner_email', (select u.email from business_members m join auth.users u on u.id = m.user_id
                                   where m.business_id = b.id and m.role = 'owner' limit 1))
                 from businesses b where b.id = c.business_id),
    'driver', (select jsonb_build_object('name', r.name, 'phone', r.phone,
                 'email', (select email from auth.users where id = r.auth_user_id))
               from riders r where r.id = c.rider_id),
    'entries', (select coalesce(jsonb_agg(to_jsonb(e) order by e.id), '[]'::jsonb) from complaint_entries e where e.complaint_id = c.id),
    'order', (select jsonb_build_object('ref', o.public_ref, 'status', o.delivery_status,
                'customer_name', o.customer_name, 'customer_phone', o.customer_phone, 'created_at', o.created_at)
              from orders o where o.id = c.order_id),
    'timeline', (select coalesce(jsonb_agg(jsonb_build_object('event', d.event_type, 'to', d.to_status,
                   'actor', d.actor_role, 'at', d.created_at) order by d.created_at), '[]'::jsonb)
                 from delivery_events d where c.order_id is not null and d.order_id = c.order_id),
    'pod_path', (select s.pod_storage_path from delivery_stops s where c.order_id is not null and s.order_id = c.order_id
                 and s.pod_storage_path is not null limit 1),
    'rating', (select jsonb_build_object('rating', g.rating, 'feedback', g.feedback, 'at', g.submitted_at)
               from ratings g where c.order_id is not null and g.order_id = c.order_id),
    'route', (select jsonb_build_object('points', count(*), 'first', min(l.recorded_at), 'last', max(l.recorded_at),
                'path', coalesce(jsonb_agg(jsonb_build_array(l.latitude, l.longitude) order by l.recorded_at), '[]'::jsonb))
              from rider_locations l join delivery_stops s on s.order_id = c.order_id
              where c.order_id is not null and l.rider_id = c.rider_id
                and l.recorded_at between (select min(created_at) from delivery_events where order_id = c.order_id)
                                      and coalesce((select max(created_at) from delivery_events where order_id = c.order_id), now()))
  ) into v;
  return v;
end $$;

create or replace function public.admin_add_complaint_note(p_id uuid, p_note text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if coalesce(length(trim(p_note)), 0) < 3 then raise exception 'note required'; end if;
  insert into complaint_entries (complaint_id, kind, author_role, author_user_id, body)
  values (p_id, 'note', 'cefflo', auth.uid(), trim(p_note));
  update complaints set status = 'in_review' where id = p_id and status = 'awaiting_reply';
end $$;

create or replace function public.admin_decide_complaint(p_id uuid, p_decision text, p_action text, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare c complaints;
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if coalesce(length(trim(p_note)), 0) < 10 then raise exception 'explain the decision'; end if;
  update complaints set status = 'resolved', decision = p_decision, account_action = coalesce(p_action, 'none'),
         decision_note = trim(p_note), decided_by = auth.uid(), decided_at = now()
   where id = p_id and status <> 'resolved' returning * into c;
  if c.id is null then raise exception 'not found or already decided'; end if;
  insert into admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
  values (auth.uid(), 'complaint_decided', 'complaint', c.id::text, trim(p_note),
          jsonb_build_object('ref', c.ref, 'decision', p_decision, 'account_action', coalesce(p_action, 'none')));
end $$;

revoke all on function public.file_complaint(text, text, uuid, uuid, text[]) from public, anon;
revoke all on function public.my_complaints() from public, anon;
revoke all on function public.reply_complaint(uuid, text, text[]) from public, anon;
revoke all on function public.admin_list_complaints() from public, anon;
revoke all on function public.admin_complaint_detail(uuid) from public, anon;
revoke all on function public.admin_add_complaint_note(uuid, text) from public, anon;
revoke all on function public.admin_decide_complaint(uuid, text, text, text) from public, anon;
grant execute on function public.file_complaint(text, text, uuid, uuid, text[]) to authenticated;
grant execute on function public.my_complaints() to authenticated;
grant execute on function public.reply_complaint(uuid, text, text[]) to authenticated;
grant execute on function public.admin_list_complaints() to authenticated;
grant execute on function public.admin_complaint_detail(uuid) to authenticated;
grant execute on function public.admin_add_complaint_note(uuid, text) to authenticated;
grant execute on function public.admin_decide_complaint(uuid, text, text, text) to authenticated;
grant execute on function public.file_complaint_by_tracking(text, text, text, text, text) to anon, authenticated;

-- Emails: filed (to both sides) and decided (to both sides).
create or replace function public.complaint_email_dispatch()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
declare v_url text; v_secret text; v_kind text;
begin
  if tg_op = 'INSERT' then v_kind := 'complaint_filed';
  elsif new.status = 'resolved' and old.status <> 'resolved' then v_kind := 'complaint_decided';
  else return null; end if;
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'push_function_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'push_webhook_secret';
  if v_url is null or v_secret is null then return null; end if;
  perform net.http_post(
    url := regexp_replace(v_url, '/push(/send)?/?$', '/approval-email'),
    body := jsonb_build_object('kind', v_kind, 'id', new.id),
    headers := jsonb_build_object('content-type', 'application/json', 'x-push-secret', v_secret),
    timeout_milliseconds := 5000);
  return null;
exception when others then
  raise warning 'complaint email skipped: %', sqlerrm;
  return null;
end $$;
revoke all on function public.complaint_email_dispatch() from public, anon, authenticated;
create trigger complaints_email after insert or update of status on public.complaints
  for each row execute function public.complaint_email_dispatch();
