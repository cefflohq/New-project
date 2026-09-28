-- Workforce reconciliation (Founder-locked Operating Model Master, D-74,
-- 2026-09-28). Supersedes the accountless Helper of 202609280003 (D-73).
--
--   OWNER     auth user + business_members(owner)     full authority
--   OPERATOR  auth user + business_members(operator)  daily operations
--   HELPER    auth user + business_members(helper)    fulfilment only
--   RIDER     auth user + riders                      Driver app (unchanged)
--
-- The Helper is again an authenticated business member (the 'helper'
-- member_role value exists since 202609030006). Returning Helpers to
-- business_members would, on its own, hand them every Vendor table and RPC
-- guarded by is_business_member(). So that predicate is narrowed here to
-- the two full Vendor roles, and fulfilment gets its own predicates:
--
--   is_business_owner        owner                         (unchanged)
--   is_business_operational  owner, operator               (unchanged)
--   is_business_member       owner, operator               (narrowed: no helper)
--   is_business_helper       helper                        (new)
--   is_business_fulfilment   owner, operator, helper       (new)
--
-- A Helper therefore reads no Vendor table through RLS and passes no
-- Vendor RPC. Helper data comes only from my_fulfilment_tasks(), which
-- returns the minimised fulfilment contract, and Helper writes only
-- through advance_preparation().
--
-- The token model of 202609280003 is retired: its RPCs are dropped, every
-- live invite/access secret is invalidated, and helper_workers is kept
-- read-locked (no grants) only as history for
-- delivery_stops.preparation_updated_by_helper attribution. No row there
-- can become a member: an accountless Helper has no auth identity to map.

-- ---- membership predicates ----------------------------------------------

create or replace function public.is_business_member(p_business uuid) returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from business_members
    where business_id = p_business and user_id = auth.uid()
      and role in ('owner', 'operator') and status = 'active'
  )
$$;

create function public.is_business_helper(p_business uuid) returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from business_members
    where business_id = p_business and user_id = auth.uid()
      and role = 'helper' and status = 'active'
  )
$$;

create function public.is_business_fulfilment(p_business uuid) returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from business_members
    where business_id = p_business and user_id = auth.uid()
      and role in ('owner', 'operator', 'helper') and status = 'active'
  )
$$;

revoke all on function public.is_business_helper(uuid) from public, anon;
revoke all on function public.is_business_fulfilment(uuid) from public, anon;
grant execute on function public.is_business_helper(uuid) to authenticated;
grant execute on function public.is_business_fulfilment(uuid) to authenticated;

-- ---- team invitations: Operator or Helper, never Owner --------------------

create or replace function public.create_team_invitation(
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
  if p_role is null or p_role not in ('operator', 'helper') then
    raise exception 'only operators and helpers are invited as team members';
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

create or replace function public.consent_team_invitation(p_token text) returns jsonb
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
  if v_invitation.role = 'owner' then
    raise exception 'invitation not available';
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

-- Grants a membership from an invitation. An invitation never changes an
-- existing Owner (no demotion, no last-owner loss through a link).
create or replace function public.team_membership_from_invitation(v_invitation team_invitations)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing business_members;
begin
  select * into v_existing from business_members
    where business_id = v_invitation.business_id and user_id = auth.uid()
    for update;
  if v_existing.user_id is not null and v_existing.role = 'owner' and v_existing.status = 'active' then
    return 'owner_unchanged';
  end if;
  insert into business_members(business_id, user_id, role, status)
    values (v_invitation.business_id, auth.uid(), v_invitation.role, 'active')
    on conflict (business_id, user_id) do update set role = excluded.role, status = 'active';
  return case when v_existing.user_id is null then 'membership.created' else 'membership.role_changed' end;
end;
$$;
revoke all on function public.team_membership_from_invitation(team_invitations) from public, anon, authenticated;

create or replace function public.accept_team_invitation(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invitation team_invitations;
  v_auth_email text;
  v_change text;
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
  if v_invitation.role = 'owner' then
    raise exception 'invitation not available';
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

  v_change := team_membership_from_invitation(v_invitation);

  update team_invitations set status = 'accepted', accepted_at = now(), accepted_by = auth.uid(), updated_at = now()
    where id = v_invitation.id;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, 'team.invite_accepted', auth.uid(), 'vendor',
            jsonb_build_object('invitation_id', v_invitation.id, 'role', v_invitation.role));
  if v_change <> 'owner_unchanged' then
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (v_invitation.business_id, v_change, auth.uid(), 'vendor', jsonb_build_object('role', v_invitation.role));
  end if;

  return jsonb_build_object('business_id', v_invitation.business_id,
    'role', case when v_change = 'owner_unchanged' then 'owner'::public.member_role else v_invitation.role end,
    'status', 'active');
end;
$$;

create or replace function public.claim_my_team_invitations() returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_email text;
  v_invitation team_invitations;
  v_change text;
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
        and role in ('operator', 'helper')
      order by consented_at
      for update
  loop
    v_change := team_membership_from_invitation(v_invitation);

    update team_invitations set status = 'accepted', accepted_at = now(), accepted_by = auth.uid(), updated_at = now()
      where id = v_invitation.id;

    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (v_invitation.business_id, 'team.invite_accepted', auth.uid(), 'vendor',
              jsonb_build_object('invitation_id', v_invitation.id, 'role', v_invitation.role, 'via', 'claim'));
    if v_change <> 'owner_unchanged' then
      insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
        values (v_invitation.business_id, v_change, auth.uid(), 'vendor', jsonb_build_object('role', v_invitation.role));
    end if;

    v_claimed := v_claimed || jsonb_build_object(
      'business_id', v_invitation.business_id,
      'role', case when v_change = 'owner_unchanged' then 'owner' else v_invitation.role::text end,
      'status', 'active');
  end loop;
  return v_claimed;
end;
$$;

-- Last-owner protection covers any change away from owner (operator or helper).
create or replace function public.update_team_member(
  p_business_id uuid, p_user_id uuid,
  p_role public.member_role default null, p_status text default null
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
     and ((p_role is not null and p_role <> 'owner') or p_status = 'inactive') then
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

-- ---- fulfilment ------------------------------------------------------------

-- Owner, Operator or Helper progress preparation. The audit row records the
-- real role of the authenticated actor.
create or replace function public.advance_preparation(p_order_id uuid, p_next public.preparation_status)
returns public.delivery_stops
language plpgsql
security definer
set search_path = public
as $$
declare
  st delivery_stops;
  o orders;
  old public.preparation_status;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_fulfilment(o.business_id) then
    raise exception 'forbidden';
  end if;
  if is_business_helper(o.business_id) and not is_business_operational(o.business_id)
     and o.delivery_status not in ('created', 'ready_for_pickup') then
    raise exception 'task not available';
  end if;
  select * into st from delivery_stops where order_id = p_order_id for update;
  if st.id is null then
    raise exception 'delivery stop not found';
  end if;

  old := st.preparation_status;
  if old = p_next then
    return st;
  end if;
  if not preparation_transition_allowed(old, p_next) then
    raise exception 'invalid preparation transition % -> %', old, p_next;
  end if;

  update delivery_stops set
    preparation_status = p_next,
    preparation_updated_at = now(),
    preparation_updated_by = auth.uid(),
    preparation_updated_by_helper = null,
    updated_at = now()
  where id = st.id
  returning * into st;

  insert into delivery_events(business_id, order_id, delivery_stop_id, event_type, from_status, to_status, actor_user_id, actor_role)
    values (o.business_id, o.id, st.id, 'preparation.status_changed', old::text, p_next::text, auth.uid(),
            case when is_business_operational(o.business_id) then 'vendor' else 'helper' end);

  return st;
end;
$$;

-- The only Helper read path. Minimised fulfilment contract: identification,
-- items, notes, preparation state/time, run + stop order for sorting, and
-- the assigned rider's name only once the order is Ready (handover). Never
-- phone, address, coordinates, payment, tracking, or unrelated orders.
create function public.my_fulfilment_tasks(p_business_id uuid) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not is_business_fulfilment(p_business_id) then
    raise exception 'forbidden';
  end if;
  return jsonb_build_object(
    'business_name', (select name from businesses where id = p_business_id),
    'tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
        'order_id', o.id,
        'order_number', o.order_number,
        'customer_name', o.customer_name,
        'items', o.items,
        'notes', nullif(o.notes, ''),
        'order_date', o.order_date,
        'preparation_status', s.preparation_status,
        'preparation_updated_at', s.preparation_updated_at,
        'run_name', ds.name,
        'run_date', ds.delivery_date,
        'stop_sequence', s.sequence,
        'handover_rider_name', case when s.preparation_status = 'ready' then r.name end,
        'created_at', o.created_at
      ) order by o.order_date nulls last, ds.name nulls last, s.sequence nulls last, o.created_at)
      from orders o
      join delivery_stops s on s.order_id = o.id
      left join delivery_sessions ds on ds.id = o.delivery_session_id
      left join riders r on r.id = o.assigned_rider_id
      where o.business_id = p_business_id
        and o.delivery_status in ('created', 'ready_for_pickup')
    ), '[]'::jsonb)
  );
end;
$$;
revoke all on function public.my_fulfilment_tasks(uuid) from public, anon;
grant execute on function public.my_fulfilment_tasks(uuid) to authenticated;

-- ---- retire the accountless token model (202609280003) --------------------

drop function public.helper_advance_preparation(text, uuid, public.preparation_status);
drop function public.helper_tasks(text);
drop function public.accept_helper_invitation(text);
drop function public.decline_helper_invitation(text);
drop function public.resolve_helper_invitation(text);
drop function public.create_helper_invitation(uuid, text, text);
drop function public.list_helper_workers(uuid);
drop function public.rotate_helper_access(uuid);
drop function public.revoke_helper_worker(uuid);
drop function public.helper_from_access_token(text);

-- Invalidate every outstanding invite/access secret. Rows stay as history.
update public.helper_workers set
  status = 'revoked',
  revoked_at = coalesce(revoked_at, now()),
  invite_token_hash = null,
  access_token_hash = null,
  updated_at = now()
where status in ('invited', 'active') or invite_token_hash is not null or access_token_hash is not null;

comment on table public.helper_workers is
  'DEPRECATED (D-74): accountless Helper model retired. Read-locked history for delivery_stops.preparation_updated_by_helper. Helpers are business_members(role=helper).';
comment on column public.delivery_stops.preparation_updated_by_helper is
  'DEPRECATED (D-74): historical accountless-Helper attribution. New writes use preparation_updated_by (auth user).';
