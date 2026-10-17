-- Prosedur Aduan, remaining pieces (Founder 2026-10-17):
--  1. Account actions are enforced: suspend / ban set auth.users.banned_until
--     (sign-in and token refresh refused) and end the person's sessions.
--  2. Stage 6: a complaint about a driver escalates to a document incident
--     (sealed IC/licence open for 72 h), in one step from FOUNDR.
--  3. Vendor verification: SSM number, SSM certificate and the owner's IC,
--     stored sealed like driver documents and reviewed in FOUNDR.

-- 1. Enforcement ---------------------------------------------------------
create table if not exists public.account_restrictions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('suspend','ban')),
  until timestamptz,
  complaint_id uuid references public.complaints(id) on delete set null,
  reason text not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  lifted_at timestamptz,
  lifted_by uuid references auth.users(id)
);
alter table public.account_restrictions enable row level security;
create policy account_restrictions_admin_read on public.account_restrictions for select using (is_platform_admin());

create or replace function public._restrict_account(p_user uuid, p_kind text, p_days int, p_complaint uuid, p_reason text)
returns void language plpgsql security definer set search_path = public, auth as $$
declare v_until timestamptz := case when p_kind = 'ban' then 'infinity'::timestamptz
                                    else now() + make_interval(days => greatest(coalesce(p_days, 7), 1)) end;
begin
  if exists (select 1 from platform_admins where user_id = p_user) then raise exception 'cannot restrict a platform admin'; end if;
  insert into account_restrictions (user_id, kind, until, complaint_id, reason, created_by)
  values (p_user, p_kind, v_until, p_complaint, p_reason, auth.uid());
  update auth.users set banned_until = v_until where id = p_user;
  delete from auth.sessions where user_id = p_user;
end $$;
revoke all on function public._restrict_account(uuid, text, int, uuid, text) from public, anon, authenticated;

-- The decision now names who an account action applies to.
drop function if exists public.admin_decide_complaint(uuid, text, text, text);
create or replace function public.admin_decide_complaint(
  p_id uuid, p_decision text, p_action text, p_note text,
  p_target text default null, p_suspend_days int default 7)
returns void language plpgsql security definer set search_path = public as $$
declare c complaints; v_user uuid;
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if coalesce(length(trim(p_note)), 0) < 10 then raise exception 'explain the decision'; end if;
  p_action := coalesce(p_action, 'none');
  update complaints set status = 'resolved', decision = p_decision, account_action = p_action,
         decision_note = trim(p_note), decided_by = auth.uid(), decided_at = now()
   where id = p_id and status <> 'resolved' returning * into c;
  if c.id is null then raise exception 'not found or already decided'; end if;
  if p_action in ('suspend', 'ban') then
    if p_target = 'driver' then
      select auth_user_id into v_user from riders where id = c.rider_id;
    elsif p_target = 'business' then
      select user_id into v_user from business_members
       where business_id = c.business_id and role = 'owner' and status = 'active' limit 1;
    elsif p_target = 'complainant' then
      v_user := c.complainant_user_id;
    end if;
    if v_user is null then raise exception 'no account to restrict'; end if;
    perform _restrict_account(v_user, p_action, p_suspend_days, c.id, c.ref || ': ' || trim(p_note));
  end if;
  insert into admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
  values (auth.uid(), 'complaint_decided', 'complaint', c.id::text, trim(p_note),
          jsonb_build_object('ref', c.ref, 'decision', p_decision, 'account_action', p_action,
                             'target', p_target, 'restricted_user', v_user));
end $$;

create or replace function public.admin_list_restrictions()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id', r.id, 'kind', r.kind, 'until', r.until,
            'reason', r.reason, 'created_at', r.created_at, 'lifted_at', r.lifted_at,
            'email', u.email, 'complaint_ref', c.ref,
            'active', r.lifted_at is null and (r.until is null or r.until > now()))
          order by r.created_at desc), '[]'::jsonb)
    from account_restrictions r
    join auth.users u on u.id = r.user_id
    left join complaints c on c.id = r.complaint_id);
end $$;

create or replace function public.admin_lift_restriction(p_id uuid, p_note text)
returns void language plpgsql security definer set search_path = public, auth as $$
declare r account_restrictions;
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if coalesce(length(trim(p_note)), 0) < 3 then raise exception 'note required'; end if;
  update account_restrictions set lifted_at = now(), lifted_by = auth.uid()
   where id = p_id and lifted_at is null returning * into r;
  if r.id is null then raise exception 'not found or already lifted'; end if;
  -- Unban only when no other restriction on this person is still live.
  if not exists (select 1 from account_restrictions where user_id = r.user_id and lifted_at is null
                 and (until is null or until > now())) then
    update auth.users set banned_until = null where id = r.user_id;
  end if;
  insert into admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
  values (auth.uid(), 'restriction_lifted', 'account_restriction', r.id::text, trim(p_note), '{}'::jsonb);
end $$;

-- 2. Escalation ----------------------------------------------------------
alter table public.driver_incident_cases add column if not exists complaint_id uuid references public.complaints(id) on delete set null;

create or replace function public.admin_escalate_complaint(p_id uuid, p_reason text)
returns uuid language plpgsql security definer set search_path = public as $$
declare c complaints; r riders; v_case uuid;
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  select * into c from complaints where id = p_id;
  if c.id is null then raise exception 'not found'; end if;
  select * into r from riders where id = c.rider_id;
  if r.auth_user_id is null then raise exception 'no driver on this complaint'; end if;
  select id into v_case from driver_incident_cases where complaint_id = c.id;
  if v_case is null then
    insert into driver_incident_cases (rider_user_id, rider_id, business_id, reported_by, report, complaint_id)
    values (r.auth_user_id, r.id, c.business_id, coalesce(c.complainant_user_id, auth.uid()),
            c.ref || ' (' || c.category || '): ' || left(c.description, 1900), c.id)
    returning id into v_case;
  end if;
  perform open_driver_incident(v_case, p_reason);
  insert into complaint_entries (complaint_id, kind, author_role, author_user_id, body)
  values (c.id, 'note', 'cefflo', auth.uid(), 'Escalated: driver documents opened for 72 h. ' || trim(p_reason));
  return v_case;
end $$;

-- 3. Vendor verification -------------------------------------------------
create table if not exists public.business_verifications (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  ssm_number text not null check (length(trim(ssm_number)) between 5 and 40),
  owner_name text not null,
  owner_ic_last4 text not null check (owner_ic_last4 ~ '^[0-9]{4}$'),
  ssm_path text not null,
  ic_front_path text not null,
  ic_back_path text not null,
  status text not null default 'pending' check (status in ('pending','verified','rejected')),
  reject_reason text,
  submitted_by uuid not null references auth.users(id),
  submitted_at timestamptz not null default now(),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz
);
alter table public.business_verifications enable row level security;
-- Owners see their status; the admin sees the queue. Paths stay sealed in
-- storage either way.
create policy business_verif_owner_read on public.business_verifications for select
  using (is_business_owner(business_id) or is_platform_admin());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('cefflo-business-documents', 'cefflo-business-documents', false, 10485760,
        array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do nothing;
-- Folder = business id. Only the owner uploads; nobody reads except the
-- platform admin reviewing a pending verification or an open incident.
create policy business_docs_owner_write on storage.objects for insert to authenticated
  with check (bucket_id = 'cefflo-business-documents' and is_business_owner(((storage.foldername(name))[1])::uuid));
create policy business_docs_admin_read on storage.objects for select using (
  bucket_id = 'cefflo-business-documents' and is_platform_admin() and exists (
    select 1 from business_verifications v
     where v.business_id = ((storage.foldername(name))[1])::uuid and v.status = 'pending'));

create or replace function public.submit_business_verification(
  p_business_id uuid, p_ssm_number text, p_owner_name text, p_ic_last4 text,
  p_ssm_path text, p_ic_front_path text, p_ic_back_path text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_business_owner(p_business_id) then raise exception 'forbidden'; end if;
  if split_part(p_ssm_path, '/', 1) <> p_business_id::text or split_part(p_ic_front_path, '/', 1) <> p_business_id::text
     or split_part(p_ic_back_path, '/', 1) <> p_business_id::text then raise exception 'invalid document'; end if;
  if exists (select 1 from business_verifications where business_id = p_business_id and status = 'verified') then
    raise exception 'business already verified';
  end if;
  insert into business_verifications (business_id, ssm_number, owner_name, owner_ic_last4, ssm_path, ic_front_path, ic_back_path, submitted_by)
  values (p_business_id, upper(trim(p_ssm_number)), trim(p_owner_name), p_ic_last4, p_ssm_path, p_ic_front_path, p_ic_back_path, auth.uid())
  on conflict (business_id) do update set ssm_number = excluded.ssm_number, owner_name = excluded.owner_name,
    owner_ic_last4 = excluded.owner_ic_last4, ssm_path = excluded.ssm_path, ic_front_path = excluded.ic_front_path,
    ic_back_path = excluded.ic_back_path, status = 'pending', reject_reason = null,
    submitted_by = auth.uid(), submitted_at = now(), reviewed_by = null, reviewed_at = null;
end $$;

create or replace function public.my_business_verification(p_business_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select case when not is_business_member(p_business_id) then null else
    (select jsonb_build_object('status', v.status, 'ssm_number', v.ssm_number, 'reject_reason', v.reject_reason,
                               'submitted_at', v.submitted_at, 'reviewed_at', v.reviewed_at)
       from business_verifications v where v.business_id = p_business_id) end
$$;

create or replace function public.admin_list_business_verifications()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('business_id', v.business_id, 'business_name', b.name,
            'ssm_number', v.ssm_number, 'owner_name', v.owner_name, 'owner_ic_last4', v.owner_ic_last4,
            'ssm_path', v.ssm_path, 'ic_front_path', v.ic_front_path, 'ic_back_path', v.ic_back_path,
            'status', v.status, 'reject_reason', v.reject_reason, 'submitted_at', v.submitted_at,
            'reviewed_at', v.reviewed_at, 'owner_email', u.email)
          order by (v.status = 'pending') desc, v.submitted_at desc), '[]'::jsonb)
    from business_verifications v join businesses b on b.id = v.business_id
    left join auth.users u on u.id = v.submitted_by);
end $$;

create or replace function public.admin_decide_business_verification(p_business_id uuid, p_verified boolean, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if not p_verified and coalesce(length(trim(p_reason)), 0) < 5 then raise exception 'reason required'; end if;
  update business_verifications set status = case when p_verified then 'verified' else 'rejected' end,
         reject_reason = case when p_verified then null else trim(p_reason) end,
         reviewed_by = auth.uid(), reviewed_at = now()
   where business_id = p_business_id and status = 'pending';
  if not found then raise exception 'not pending'; end if;
  insert into admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
  values (auth.uid(), case when p_verified then 'business_verified' else 'business_verification_rejected' end,
          'business', p_business_id::text, nullif(trim(coalesce(p_reason, '')), ''), '{}'::jsonb);
end $$;

revoke all on function public.admin_decide_complaint(uuid, text, text, text, text, int) from public, anon;
revoke all on function public.admin_list_restrictions() from public, anon;
revoke all on function public.admin_lift_restriction(uuid, text) from public, anon;
revoke all on function public.admin_escalate_complaint(uuid, text) from public, anon;
revoke all on function public.submit_business_verification(uuid, text, text, text, text, text, text) from public, anon;
revoke all on function public.my_business_verification(uuid) from public, anon;
revoke all on function public.admin_list_business_verifications() from public, anon;
revoke all on function public.admin_decide_business_verification(uuid, boolean, text) from public, anon;
grant execute on function public.admin_decide_complaint(uuid, text, text, text, text, int) to authenticated;
grant execute on function public.admin_list_restrictions() to authenticated;
grant execute on function public.admin_lift_restriction(uuid, text) to authenticated;
grant execute on function public.admin_escalate_complaint(uuid, text) to authenticated;
grant execute on function public.submit_business_verification(uuid, text, text, text, text, text, text) to authenticated;
grant execute on function public.my_business_verification(uuid) to authenticated;
grant execute on function public.admin_list_business_verifications() to authenticated;
grant execute on function public.admin_decide_business_verification(uuid, boolean, text) to authenticated;
