-- Rider invitation: PWA consent + Driver-app claim (Founder-approved
-- Option 1, 2026-09-28).
--
-- One invitation, one acceptance decision:
--   Invitation PWA (no account)   consent_rider_invitation / decline_rider_invitation
--   Driver app (authenticated)    claim_my_rider_invitations()
--
-- The invited EMAIL is the server-side binding between the anonymous
-- consent and the account created later. Nothing is trusted from the
-- client except the raw token (PWA) and the caller's own session (claim).
--
-- State machine (rider_invitations.status):
--   pending   -> consented  (PWA Accept, anonymous, token-bound)
--   pending   -> declined   (PWA Decline)
--   consented -> declined   (PWA Decline, before any claim)
--   consented -> accepted   (claim_my_rider_invitations by the invited email,
--                            or accept_rider_invitation from the Driver app)
--   pending   -> accepted   (accept_rider_invitation, existing D17 path)
--   pending|consented -> revoked (Vendor), -> expired (clock)
-- accepted / declined / revoked / expired are terminal.
--
-- Rider membership is still created at status 'pending'; Owner approval
-- (approve_pending_rider) is unchanged and still required.

alter table public.rider_invitations drop constraint rider_invitations_status_check;
alter table public.rider_invitations
  add constraint rider_invitations_status_check
  check (status in ('pending', 'consented', 'accepted', 'declined', 'revoked', 'expired'));
alter table public.rider_invitations
  add column consented_at timestamptz,
  add column declined_at timestamptz;

-- Effective status: a pending/consented invitation past its expiry is
-- reported (and treated) as expired.
create function public.rider_invitation_effective_status(i public.rider_invitations)
returns text language sql stable as $$
  select case when i.status in ('pending', 'consented') and i.expires_at <= now()
              then 'expired' else i.status end
$$;
revoke all on function public.rider_invitation_effective_status(public.rider_invitations) from public, anon, authenticated;

-- Limited public invitation metadata for the PWA (Founder-approved):
-- business name, general location (the business's own operating area) and
-- the invitation status. Never the address, phone, email, owner, internal
-- ids or the invited rider's details. There is no business category column,
-- so no category is returned (not invented).
create or replace function public.resolve_rider_invitation(p_token text) returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'business_name', b.name,
    'location', nullif(trim(b.operating_area), ''),
    'status', rider_invitation_effective_status(i)
  )
  from rider_invitations i
  join businesses b on b.id = i.business_id
  where i.token_hash = encode(digest(p_token, 'sha256'), 'hex')
$$;
revoke all on function public.resolve_rider_invitation(text) from public, authenticated;
grant execute on function public.resolve_rider_invitation(text) to anon, authenticated;

-- PWA Accept. Anonymous-safe: possession of the 256-bit token is the only
-- authority, exactly as for resolve. Records consent only -- no riders row,
-- no auth.uid(). Idempotent for an already-consented invitation.
create function public.consent_rider_invitation(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invitation rider_invitations;
  v_business_name text;
begin
  select * into v_invitation from rider_invitations
    where token_hash = encode(digest(p_token, 'sha256'), 'hex')
    for update;
  if v_invitation.id is null then
    raise exception 'invalid invitation';
  end if;
  if rider_invitation_effective_status(v_invitation) = 'expired' and v_invitation.status <> 'expired' then
    update rider_invitations set status = 'expired', updated_at = now() where id = v_invitation.id;
    raise exception 'invitation expired';
  end if;
  select name into v_business_name from businesses where id = v_invitation.business_id;
  if v_invitation.status = 'consented' then
    return jsonb_build_object('status', 'consented', 'business_name', v_business_name);
  end if;
  if v_invitation.status <> 'pending' then
    raise exception 'invitation not available';
  end if;

  update rider_invitations set status = 'consented', consented_at = now(), updated_at = now()
    where id = v_invitation.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, 'rider.invite_consented', null, 'rider',
            jsonb_build_object('invitation_id', v_invitation.id));
  return jsonb_build_object('status', 'consented', 'business_name', v_business_name);
end;
$$;
revoke all on function public.consent_rider_invitation(text) from public;
grant execute on function public.consent_rider_invitation(text) to anon, authenticated;

-- PWA Decline. Anonymous-safe, token-bound. Idempotent once declined.
create function public.decline_rider_invitation(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invitation rider_invitations;
begin
  select * into v_invitation from rider_invitations
    where token_hash = encode(digest(p_token, 'sha256'), 'hex')
    for update;
  if v_invitation.id is null then
    raise exception 'invalid invitation';
  end if;
  if v_invitation.status = 'declined' then
    return jsonb_build_object('status', 'declined');
  end if;
  if rider_invitation_effective_status(v_invitation) not in ('pending', 'consented') then
    raise exception 'invitation not available';
  end if;

  update rider_invitations set status = 'declined', declined_at = now(), updated_at = now()
    where id = v_invitation.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, 'rider.invite_declined', null, 'rider',
            jsonb_build_object('invitation_id', v_invitation.id));
  return jsonb_build_object('status', 'declined');
end;
$$;
revoke all on function public.decline_rider_invitation(text) from public;
grant execute on function public.decline_rider_invitation(text) to anon, authenticated;

-- Driver app, after sign-up / sign-in. Claims every consented, unexpired
-- invitation addressed to the caller's own CONFIRMED account email (read
-- from auth.users, never from the client). Creates or links the riders
-- row at status 'pending'. Idempotent: a second call finds nothing left
-- to claim and returns the caller's already-claimed memberships unchanged.
create function public.claim_my_rider_invitations() returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_email text;
  v_invitation rider_invitations;
  v_rider riders;
  v_claimed jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  select lower(trim(email)) into v_email from auth.users
    where id = auth.uid() and email_confirmed_at is not null;
  if v_email is null then
    -- Unconfirmed email: nothing can be claimed until the address is proven.
    return v_claimed;
  end if;

  for v_invitation in
    select * from rider_invitations
      where invited_email = v_email and status = 'consented' and expires_at > now()
      order by consented_at
      for update
  loop
    select * into v_rider from riders
      where business_id = v_invitation.business_id and auth_user_id = auth.uid();
    if v_rider.id is null then
      insert into riders(business_id, auth_user_id, name, phone, status)
        values (v_invitation.business_id, auth.uid(), v_invitation.invited_name, v_invitation.invited_phone, 'pending')
        returning * into v_rider;
    end if;

    update rider_invitations
      set status = 'accepted', accepted_at = now(), accepted_by = auth.uid(), rider_id = v_rider.id, updated_at = now()
      where id = v_invitation.id;
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (v_invitation.business_id, 'rider.invite_accepted', auth.uid(), 'rider',
              jsonb_build_object('invitation_id', v_invitation.id, 'rider_id', v_rider.id, 'via', 'claim'));
    v_claimed := v_claimed || jsonb_build_object(
      'business_id', v_invitation.business_id, 'rider_id', v_rider.id, 'status', v_rider.status);
  end loop;
  return v_claimed;
end;
$$;
revoke all on function public.claim_my_rider_invitations() from public, anon;
grant execute on function public.claim_my_rider_invitations() to authenticated;

-- Existing Driver-app token path (D17 Join Business) also accepts a
-- consented invitation, so a rider who consented in the PWA and then pastes
-- the same link is linked once, not refused. Body otherwise unchanged.
create or replace function public.accept_rider_invitation(p_token text) returns jsonb
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
  if v_invitation.status not in ('pending', 'consented') then
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

-- Vendor revoke also covers a consented (not yet claimed) invitation.
create or replace function public.revoke_rider_invitation(p_invitation_id uuid) returns public.rider_invitations
language plpgsql security definer set search_path = public
as $$
declare
  v_invitation rider_invitations;
begin
  select * into v_invitation from rider_invitations where id = p_invitation_id for update;
  if v_invitation.id is null or not is_business_operational(v_invitation.business_id) then
    raise exception 'forbidden';
  end if;
  if v_invitation.status not in ('pending', 'consented') then
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
