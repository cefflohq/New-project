-- S4-07 Batch 1: trusted-team (Owner/Operator-Staff) invitation backend.
-- Founder-locked decisions this migration implements exactly:
--  - Option A approval model: valid invite + successful auth + email match
--    -> business_members becomes active immediately. No second approval step.
--  - Invitation creation is OWNER ONLY for every role, including Owner-role
--    invitations themselves -- matching update_team_member's existing
--    Owner-only precedent for all "Team" management (S4-02 design doc row 6),
--    since invitation creation is at least as sensitive as an existing
--    member's role change and the Founder's decision only carves out an
--    explicit Owner-role restriction, not a broader Operator-may-invite
--    allowance -- treated here as reinforcing, not loosening, the existing
--    Owner-only Team boundary.
--  - Role comes ONLY from the invitation row, never from the accepting
--    client -- accept_team_invitation takes no role parameter at all.
--  - Identity binding by email is mandatory (no "whoever holds the link").
--  - Token model: gen_random_bytes(32)/sha256, exactly matching the existing
--    tracking_tokens precedent -- raw value returned exactly once, by
--    create_team_invitation only; never stored, never logged, never
--    returned by resolve.
--  - Fixed 7-day expiry (Founder decision; no configurable-expiry UI).
--  - No new membership state: business_members remains active/inactive.

create table public.team_invitations(
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses on delete cascade,
  role public.member_role not null,
  invited_email text not null,
  invited_by uuid not null references auth.users on delete restrict,
  token_hash text not null,
  status text not null default 'pending' check (status in ('pending','accepted','revoked','expired')),
  expires_at timestamptz not null,
  accepted_at timestamptz,
  accepted_by uuid references auth.users on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index team_invitations_token_hash_idx on public.team_invitations(token_hash);
create index team_invitations_business_idx on public.team_invitations(business_id, status);

alter table public.team_invitations enable row level security;
-- Owner-only visibility -- matching Owner-only creation/revocation; an
-- Operator has no need to see who else has been invited or at what email,
-- and this table's own row carries invited_email (PII-adjacent) that
-- Section 4's "no unnecessary email exposure" spirit extends to internal
-- roster visibility too, not just anonymous resolution.
create policy team_invitations_owner on public.team_invitations
  for select using (public.is_business_owner(business_id));
-- No insert/update/delete policy -- every mutation is RPC-mediated only,
-- matching business_members' own deny-by-default precedent exactly.

-- Owner-only, every role including 'owner' itself. Generates the raw token,
-- returns it exactly once; only the sha256 hash is ever persisted.
create function public.create_team_invitation(
  p_business_id uuid,
  p_role public.member_role,
  p_invited_email text
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invitation team_invitations;
  v_email text;
  v_token text;
begin
  if not is_business_owner(p_business_id) then
    raise exception 'forbidden';
  end if;
  v_email := lower(trim(p_invited_email));
  if v_email = '' or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'invalid email';
  end if;

  v_token := encode(gen_random_bytes(32), 'hex');
  insert into team_invitations(business_id, role, invited_email, invited_by, token_hash, expires_at)
    values (p_business_id, p_role, v_email, auth.uid(), encode(digest(v_token, 'sha256'), 'hex'), now() + interval '7 days')
    returning * into v_invitation;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'team.invite_created', auth.uid(), 'vendor',
            jsonb_build_object('invitation_id', v_invitation.id, 'role', p_role));

  return jsonb_build_object(
    'invitation_id', v_invitation.id, 'business_id', p_business_id, 'role', p_role,
    'invited_email', v_email, 'expires_at', v_invitation.expires_at, 'token', v_token
  );
end;
$$;
revoke all on function public.create_team_invitation(uuid, public.member_role, text) from public, anon, authenticated;
grant execute on function public.create_team_invitation(uuid, public.member_role, text) to authenticated;

-- Owner-only. Revokes a still-pending invitation; a no-op on an
-- already-terminal one (idempotent, matching this project's established
-- style) rather than an error, since re-clicking Revoke twice is a
-- harmless, expected UI race.
create function public.revoke_team_invitation(p_invitation_id uuid) returns public.team_invitations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invitation team_invitations;
begin
  select * into v_invitation from team_invitations where id = p_invitation_id for update;
  if v_invitation.id is null or not is_business_owner(v_invitation.business_id) then
    raise exception 'forbidden';
  end if;
  if v_invitation.status <> 'pending' then
    return v_invitation;
  end if;
  update team_invitations set status = 'revoked', updated_at = now()
    where id = v_invitation.id
    returning * into v_invitation;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, 'team.invite_revoked', auth.uid(), 'vendor',
            jsonb_build_object('invitation_id', v_invitation.id));
  return v_invitation;
end;
$$;
revoke all on function public.revoke_team_invitation(uuid) from public, anon, authenticated;
grant execute on function public.revoke_team_invitation(uuid) to authenticated;

-- Anonymous-safe: the ONLY invitation surface reachable before auth. Never
-- returns invited_email, token_hash, or any other business/member data --
-- just enough for an invitee to see who invited them and as what, honestly
-- reflecting expiry without needing a cron (lazily computed, never
-- mutated here -- mutation only happens inside accept, which is the sole
-- place a "pending but actually expired" row is ever written back).
create function public.resolve_team_invitation(p_token text) returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'business_name', b.name,
    'role', i.role,
    'status', case when i.status = 'pending' and i.expires_at <= now() then 'expired' else i.status end
  )
  from team_invitations i
  join businesses b on b.id = i.business_id
  where i.token_hash = encode(digest(p_token, 'sha256'), 'hex')
$$;
revoke all on function public.resolve_team_invitation(text) from public, authenticated;
grant execute on function public.resolve_team_invitation(text) to anon, authenticated;

-- Authenticated only. Role and business come exclusively from the
-- server-side invitation row -- never a client parameter, closing role
-- escalation and cross-business use by construction. Email-bound,
-- fail-closed on mismatch. Idempotent for the exact same accepting
-- identity (safe retry); a different identity attempting to reuse an
-- already-accepted token is rejected, not silently joined.
create function public.accept_team_invitation(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invitation team_invitations;
  v_auth_email text;
  v_existing_role public.member_role;
  v_was_member boolean;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  select * into v_invitation
    from team_invitations
    where token_hash = encode(digest(p_token, 'sha256'), 'hex')
    for update;
  if v_invitation.id is null then
    raise exception 'invalid invitation';
  end if;

  if v_invitation.status = 'accepted' and v_invitation.accepted_by = auth.uid() then
    return jsonb_build_object('business_id', v_invitation.business_id, 'role', v_invitation.role, 'status', 'active');
  end if;
  if v_invitation.status <> 'pending' then
    raise exception 'invitation not available';
  end if;
  if v_invitation.expires_at <= now() then
    update team_invitations set status = 'expired', updated_at = now() where id = v_invitation.id;
    raise exception 'invitation expired';
  end if;

  select lower(trim(email)) into v_auth_email from auth.users where id = auth.uid();
  if v_auth_email is distinct from v_invitation.invited_email then
    raise exception 'email mismatch';
  end if;

  select exists(
    select 1 from business_members where business_id = v_invitation.business_id and user_id = auth.uid()
  ) into v_was_member;

  insert into business_members(business_id, user_id, role, status)
    values (v_invitation.business_id, auth.uid(), v_invitation.role, 'active')
    on conflict (business_id, user_id) do update set role = excluded.role, status = 'active';

  update team_invitations set status = 'accepted', accepted_at = now(), accepted_by = auth.uid(), updated_at = now()
    where id = v_invitation.id;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, 'team.invite_accepted', auth.uid(), 'vendor',
            jsonb_build_object('invitation_id', v_invitation.id, 'role', v_invitation.role));
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, case when v_was_member then 'membership.role_changed' else 'membership.created' end,
            auth.uid(), 'vendor', jsonb_build_object('role', v_invitation.role));

  return jsonb_build_object('business_id', v_invitation.business_id, 'role', v_invitation.role, 'status', 'active');
end;
$$;
revoke all on function public.accept_team_invitation(text) from public, anon;
grant execute on function public.accept_team_invitation(text) to authenticated;

-- Fold the pre-existing update_team_member audit gap into S4-07: it never
-- wrote any event. Same signature (CREATE OR REPLACE, no drop needed) --
-- every existing check (Owner-only, status validation, last-owner
-- protection, the coalesce-update) preserved byte-for-byte; only the event
-- insert is new.
create or replace function public.update_team_member(
  p_business_id uuid,
  p_user_id uuid,
  p_role public.member_role default null,
  p_status text default null
) returns public.business_members
language plpgsql
security definer
set search_path = public
as $$
declare
  m public.business_members;
  remaining_owners integer;
begin
  if not public.is_business_owner(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_status is not null and p_status not in ('active', 'inactive') then
    raise exception 'invalid status';
  end if;

  select * into m
  from public.business_members
  where business_id = p_business_id and user_id = p_user_id
  for update;
  if m.business_id is null then
    raise exception 'not a team member';
  end if;

  if m.role = 'owner' and m.status = 'active'
     and (p_role = 'operator' or p_status = 'inactive') then
    select count(*) into remaining_owners
    from public.business_members
    where business_id = p_business_id
      and role = 'owner'
      and status = 'active'
      and user_id <> p_user_id;
    if remaining_owners = 0 then
      raise exception 'business must retain at least one active owner';
    end if;
  end if;

  update public.business_members set
    role = coalesce(p_role, role),
    status = coalesce(p_status, status)
  where business_id = p_business_id and user_id = p_user_id
  returning * into m;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (
      p_business_id,
      case when p_status is not null and p_role is null then 'membership.status_changed' else 'membership.role_changed' end,
      auth.uid(), 'vendor',
      jsonb_build_object('member_user_id', p_user_id, 'role', m.role, 'status', m.status)
    );

  return m;
end;
$$;
