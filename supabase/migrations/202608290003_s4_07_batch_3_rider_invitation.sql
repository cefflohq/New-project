-- S4-07 Batch 3: Rider invitation + pending-approval backend.
-- Founder-locked decisions this migration implements exactly:
--  - Structurally separate from team_invitations/business_members --
--    Rider identity is never merged into the Staff/Owner model. Shares only
--    the same secure-token engineering (gen_random_bytes(32)/sha256),
--    matching Section 7's explicit instruction.
--  - Option B approval model for Riders: accept creates/binds a riders row
--    at status='pending' (the enum value already existed for exactly this
--    purpose, unused until now); an Owner must explicitly approve before
--    the Rider becomes 'active'. No immediate activation.
--  - Rider-invitation CREATION reuses the existing, already-Founder-locked
--    "Rider create/onboard: ALLOW for Owner AND Operator/Staff" authority
--    (S4-02 design doc row 8, `riders_vendor` policy) -- this is the modern
--    replacement for that same action, not a new permission grant.
--  - Rider APPROVAL is a new, more sensitive gate and is Owner-only, per
--    explicit Founder instruction (Section 8) -- Operator approval is not
--    assumed.
--  - "Reject a pending Rider" reuses the existing deactivate_rider RPC
--    unchanged (it already sets any rider to 'inactive', Owner-only, with
--    no precondition on the current status) -- no separate reject RPC is
--    added, since one already does exactly this.
--  - Discovered schema conflict, NOT silently resolved here (see the
--    migration-turn report): riders.auth_user_id carries a bare `unique`
--    constraint, which structurally forbids the same auth identity from
--    ever holding more than one riders row across ANY business -- this
--    directly contradicts D-03 ("one Rider Auth identity may belong to
--    multiple Vendor teams"). accept_rider_invitation below does not
--    attempt to work around this constraint; it surfaces the resulting
--    conflict as a clean, honest error instead of a raw constraint
--    violation. Loosening or removing that constraint is a distinct
--    architectural decision, out of scope for this migration.
--    RESOLVED in a later S4-07.3a migration
--    (202608290004_s4_07_batch_3a_rider_multi_business_context.sql), which
--    replaces this constraint with UNIQUE(business_id, auth_user_id) after
--    a full dependency reconciliation -- accept_rider_invitation needed no
--    code change at all once that landed, since it already checked for an
--    existing same-business relationship before ever attempting the insert.

create table public.rider_invitations(
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses on delete cascade,
  invited_email text not null,
  invited_name text not null,
  invited_phone text not null,
  invited_by uuid not null references auth.users on delete restrict,
  token_hash text not null,
  status text not null default 'pending' check (status in ('pending','accepted','revoked','expired')),
  expires_at timestamptz not null,
  accepted_at timestamptz,
  accepted_by uuid references auth.users on delete set null,
  rider_id uuid references public.riders on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index rider_invitations_token_hash_idx on public.rider_invitations(token_hash);
create index rider_invitations_business_idx on public.rider_invitations(business_id, status);

alter table public.rider_invitations enable row level security;
-- Any business member -- matching riders_vendor's own existing "any
-- member" visibility precedent for the Rider roster itself.
create policy rider_invitations_vendor on public.rider_invitations
  for select using (public.is_business_member(business_id));
-- No insert/update/delete policy -- RPC only, same deny-by-default
-- discipline as team_invitations/business_members.

-- Any active business member (Owner or Operator/Staff) -- reuses the
-- existing "Rider create/onboard: ALLOW" authority; name/phone are
-- collected here (not at accept time) because riders.name/phone are
-- NOT NULL and business-scoped-unique -- the Owner/Staff member already
-- knows this real-world detail before formalizing it as a secure invite.
create function public.create_rider_invitation(
  p_business_id uuid,
  p_invited_email text,
  p_invited_name text,
  p_invited_phone text
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invitation rider_invitations;
  v_email text;
  v_name text;
  v_phone text;
  v_token text;
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  v_email := lower(trim(p_invited_email));
  if v_email = '' or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'invalid email';
  end if;
  v_name := nullif(trim(p_invited_name), '');
  v_phone := nullif(trim(p_invited_phone), '');
  if v_name is null or v_phone is null then
    raise exception 'name and phone are required';
  end if;
  if exists (select 1 from riders where business_id = p_business_id and phone = v_phone) then
    raise exception 'phone already on file for this business';
  end if;

  v_token := encode(gen_random_bytes(32), 'hex');
  insert into rider_invitations(business_id, invited_email, invited_name, invited_phone, invited_by, token_hash, expires_at)
    values (p_business_id, v_email, v_name, v_phone, auth.uid(), encode(digest(v_token, 'sha256'), 'hex'), now() + interval '7 days')
    returning * into v_invitation;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'rider.invite_created', auth.uid(), 'vendor',
            jsonb_build_object('invitation_id', v_invitation.id));

  return jsonb_build_object(
    'invitation_id', v_invitation.id, 'business_id', p_business_id,
    'invited_email', v_email, 'expires_at', v_invitation.expires_at, 'token', v_token
  );
end;
$$;
revoke all on function public.create_rider_invitation(uuid, text, text, text) from public, anon, authenticated;
grant execute on function public.create_rider_invitation(uuid, text, text, text) to authenticated;

-- Any business member may revoke -- matching create's own authority level.
create function public.revoke_rider_invitation(p_invitation_id uuid) returns public.rider_invitations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invitation rider_invitations;
begin
  select * into v_invitation from rider_invitations where id = p_invitation_id for update;
  if v_invitation.id is null or not is_business_member(v_invitation.business_id) then
    raise exception 'forbidden';
  end if;
  if v_invitation.status <> 'pending' then
    return v_invitation;
  end if;
  update rider_invitations set status = 'revoked', updated_at = now()
    where id = v_invitation.id
    returning * into v_invitation;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, 'rider.invite_revoked', auth.uid(), 'vendor',
            jsonb_build_object('invitation_id', v_invitation.id));
  return v_invitation;
end;
$$;
revoke all on function public.revoke_rider_invitation(uuid) from public, anon, authenticated;
grant execute on function public.revoke_rider_invitation(uuid) to authenticated;

-- Anonymous-safe. Never returns invited_email/name/phone/token_hash.
create function public.resolve_rider_invitation(p_token text) returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'business_name', b.name,
    'status', case when i.status = 'pending' and i.expires_at <= now() then 'expired' else i.status end
  )
  from rider_invitations i
  join businesses b on b.id = i.business_id
  where i.token_hash = encode(digest(p_token, 'sha256'), 'hex')
$$;
revoke all on function public.resolve_rider_invitation(text) from public, authenticated;
grant execute on function public.resolve_rider_invitation(text) to anon, authenticated;

-- Authenticated only. Email-bound, fail-closed. Creates the riders row at
-- status='pending' -- never active on acceptance. Idempotent for the exact
-- same accepting identity re-linking the same business; a genuinely
-- different auth identity already holding ANY riders row anywhere (the
-- pre-existing unique(auth_user_id) constraint -- see the migration header
-- note) is surfaced as a clean, honest error rather than a raw constraint
-- violation, not worked around.
create function public.accept_rider_invitation(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invitation rider_invitations;
  v_auth_email text;
  v_rider riders;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  select * into v_invitation
    from rider_invitations
    where token_hash = encode(digest(p_token, 'sha256'), 'hex')
    for update;
  if v_invitation.id is null then
    raise exception 'invalid invitation';
  end if;

  if v_invitation.status = 'accepted' and v_invitation.accepted_by = auth.uid() then
    select * into v_rider from riders where id = v_invitation.rider_id;
    return jsonb_build_object('business_id', v_invitation.business_id, 'rider_id', v_rider.id, 'status', v_rider.status);
  end if;
  if v_invitation.status <> 'pending' then
    raise exception 'invitation not available';
  end if;
  if v_invitation.expires_at <= now() then
    update rider_invitations set status = 'expired', updated_at = now() where id = v_invitation.id;
    raise exception 'invitation expired';
  end if;

  select lower(trim(email)) into v_auth_email from auth.users where id = auth.uid();
  if v_auth_email is distinct from v_invitation.invited_email then
    raise exception 'email mismatch';
  end if;

  -- Already attached to THIS business: idempotent, no duplicate row.
  select * into v_rider from riders where business_id = v_invitation.business_id and auth_user_id = auth.uid();
  if v_rider.id is null then
    begin
      insert into riders(business_id, auth_user_id, name, phone, status)
        values (v_invitation.business_id, auth.uid(), v_invitation.invited_name, v_invitation.invited_phone, 'pending')
        returning * into v_rider;
    exception
      when unique_violation then
        raise exception 'this identity is already linked to a different Rider profile';
    end;
  end if;

  update rider_invitations set status = 'accepted', accepted_at = now(), accepted_by = auth.uid(), rider_id = v_rider.id, updated_at = now()
    where id = v_invitation.id;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, 'rider.invite_accepted', auth.uid(), 'rider',
            jsonb_build_object('invitation_id', v_invitation.id, 'rider_id', v_rider.id));

  return jsonb_build_object('business_id', v_invitation.business_id, 'rider_id', v_rider.id, 'status', v_rider.status);
end;
$$;
revoke all on function public.accept_rider_invitation(text) from public, anon;
grant execute on function public.accept_rider_invitation(text) to authenticated;

-- Owner-only. The new, more sensitive gate the Founder is explicitly
-- adding (Section 8) -- Operator approval is not assumed. Requires the
-- rider to genuinely be 'pending'; "reject" reuses the existing
-- deactivate_rider RPC unchanged (already sets any rider to 'inactive',
-- Owner-only, no precondition on current status).
create function public.approve_pending_rider(p_rider_id uuid) returns public.riders
language plpgsql
security definer
set search_path = public
as $$
declare
  r riders;
begin
  select * into r from riders where id = p_rider_id for update;
  if r.id is null or not is_business_owner(r.business_id) then
    raise exception 'forbidden';
  end if;
  if r.status <> 'pending' then
    raise exception 'rider not pending';
  end if;
  update riders set status = 'active', updated_at = now() where id = r.id returning * into r;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (r.business_id, 'rider.approved', auth.uid(), 'vendor', jsonb_build_object('rider_id', r.id));
  return r;
end;
$$;
revoke all on function public.approve_pending_rider(uuid) from public, anon, authenticated;
grant execute on function public.approve_pending_rider(uuid) to authenticated;

-- deactivate_rider: folds in the same pre-existing audit gap as
-- update_team_member (Section 15, Founder-explicit) -- it never logged any
-- event. Same signature (CREATE OR REPLACE, no drop needed); every
-- existing check/statement preserved byte-for-byte; only the event insert
-- is new. One event type covers both "reject a still-pending Rider" and
-- "deactivate an already-active one" -- metadata.previous_status
-- distinguishes them factually rather than inventing a second event type.
create or replace function public.deactivate_rider(p_rider_id uuid)
returns public.riders
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.riders;
  v_previous_status public.rider_status;
begin
  select * into r from public.riders where id = p_rider_id for update;
  if r.id is null or not public.is_business_owner(r.business_id) then
    raise exception 'forbidden';
  end if;
  v_previous_status := r.status;

  update public.riders
  set status = 'inactive', updated_at = now()
  where id = p_rider_id
  returning * into r;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (r.business_id, 'rider.deactivated', auth.uid(), 'vendor',
            jsonb_build_object('rider_id', r.id, 'previous_status', v_previous_status));

  return r;
end;
$$;
