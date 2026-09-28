-- Team (Owner / Operator / Helper) invitation: PWA consent + Vendor-app
-- claim. Same model as the rider invitation (202609280001, D-72), applied
-- to staff (Founder, 2026-09-28).
--
--   Invitation PWA (no account)  consent_team_invitation / decline_team_invitation
--   Vendor app / Vendor Web      claim_my_team_invitations()
--
-- The invited EMAIL is the server-side binding. Role and business still
-- come only from the invitation row. A claim creates (or reactivates) the
-- business_members row with the invited role -- exactly what
-- accept_team_invitation already does; there is no approval step for
-- staff (unchanged).
--
-- State machine (team_invitations.status):
--   pending   -> consented | declined        (PWA, token-bound)
--   consented -> accepted                    (claim by the invited email, or accept)
--   consented -> declined                    (PWA, before any claim)
--   pending   -> accepted                    (accept_team_invitation)
--   pending|consented -> revoked (Owner), -> expired (clock)

alter table public.team_invitations drop constraint team_invitations_status_check;
alter table public.team_invitations
  add constraint team_invitations_status_check
  check (status in ('pending', 'consented', 'accepted', 'declined', 'revoked', 'expired'));
alter table public.team_invitations
  add column consented_at timestamptz,
  add column declined_at timestamptz;

create function public.team_invitation_effective_status(i public.team_invitations)
returns text language sql stable as $$
  select case when i.status in ('pending', 'consented') and i.expires_at <= now()
              then 'expired' else i.status end
$$;
revoke all on function public.team_invitation_effective_status(public.team_invitations) from public, anon, authenticated;

-- Limited public metadata: business name, operating area, invited role and
-- status. Never the address, phone, email, owner, ids or invited email.
create or replace function public.resolve_team_invitation(p_token text) returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'business_name', b.name,
    'location', nullif(trim(b.operating_area), ''),
    'role', i.role,
    'status', team_invitation_effective_status(i)
  )
  from team_invitations i
  join businesses b on b.id = i.business_id
  where i.token_hash = encode(digest(p_token, 'sha256'), 'hex')
$$;
revoke all on function public.resolve_team_invitation(text) from public, authenticated;
grant execute on function public.resolve_team_invitation(text) to anon, authenticated;

create function public.consent_team_invitation(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invitation team_invitations;
  v_business_name text;
begin
  select * into v_invitation from team_invitations
    where token_hash = encode(digest(p_token, 'sha256'), 'hex')
    for update;
  if v_invitation.id is null then
    raise exception 'invalid invitation';
  end if;
  if team_invitation_effective_status(v_invitation) = 'expired' and v_invitation.status <> 'expired' then
    update team_invitations set status = 'expired', updated_at = now() where id = v_invitation.id;
    raise exception 'invitation expired';
  end if;
  select name into v_business_name from businesses where id = v_invitation.business_id;
  if v_invitation.status = 'consented' then
    return jsonb_build_object('status', 'consented', 'business_name', v_business_name, 'role', v_invitation.role);
  end if;
  if v_invitation.status <> 'pending' then
    raise exception 'invitation not available';
  end if;

  update team_invitations set status = 'consented', consented_at = now(), updated_at = now()
    where id = v_invitation.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, 'team.invite_consented', null, 'vendor',
            jsonb_build_object('invitation_id', v_invitation.id, 'role', v_invitation.role));
  return jsonb_build_object('status', 'consented', 'business_name', v_business_name, 'role', v_invitation.role);
end;
$$;
revoke all on function public.consent_team_invitation(text) from public;
grant execute on function public.consent_team_invitation(text) to anon, authenticated;

create function public.decline_team_invitation(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invitation team_invitations;
begin
  select * into v_invitation from team_invitations
    where token_hash = encode(digest(p_token, 'sha256'), 'hex')
    for update;
  if v_invitation.id is null then
    raise exception 'invalid invitation';
  end if;
  if v_invitation.status = 'declined' then
    return jsonb_build_object('status', 'declined');
  end if;
  if team_invitation_effective_status(v_invitation) not in ('pending', 'consented') then
    raise exception 'invitation not available';
  end if;

  update team_invitations set status = 'declined', declined_at = now(), updated_at = now()
    where id = v_invitation.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, 'team.invite_declined', null, 'vendor',
            jsonb_build_object('invitation_id', v_invitation.id));
  return jsonb_build_object('status', 'declined');
end;
$$;
revoke all on function public.decline_team_invitation(text) from public;
grant execute on function public.decline_team_invitation(text) to anon, authenticated;

-- Vendor app / Vendor Web, after sign-up / sign-in. Claims every consented,
-- unexpired team invitation addressed to the caller's own CONFIRMED email
-- (read from auth.users). Membership + events exactly as
-- accept_team_invitation. Idempotent.
create function public.claim_my_team_invitations() returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_email text;
  v_invitation team_invitations;
  v_was_member boolean;
  v_claimed jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  select lower(trim(email)) into v_email from auth.users
    where id = auth.uid() and email_confirmed_at is not null;
  if v_email is null then
    return v_claimed;
  end if;

  for v_invitation in
    select * from team_invitations
      where invited_email = v_email and status = 'consented' and expires_at > now()
      order by consented_at
      for update
  loop
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
              jsonb_build_object('invitation_id', v_invitation.id, 'role', v_invitation.role, 'via', 'claim'));
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (v_invitation.business_id, case when v_was_member then 'membership.role_changed' else 'membership.created' end,
              auth.uid(), 'vendor', jsonb_build_object('role', v_invitation.role));

    v_claimed := v_claimed || jsonb_build_object(
      'business_id', v_invitation.business_id, 'role', v_invitation.role, 'status', 'active');
  end loop;
  return v_claimed;
end;
$$;
revoke all on function public.claim_my_team_invitations() from public, anon;
grant execute on function public.claim_my_team_invitations() to authenticated;

-- accept_team_invitation also accepts a consented invitation. Body
-- otherwise unchanged.
create or replace function public.accept_team_invitation(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invitation team_invitations;
  v_auth_email text;
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
  if v_invitation.status not in ('pending', 'consented') then
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

-- Owner revoke also covers a consented (not yet claimed) invitation.
create or replace function public.revoke_team_invitation(p_invitation_id uuid) returns public.team_invitations
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
  if v_invitation.status not in ('pending', 'consented') then
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
