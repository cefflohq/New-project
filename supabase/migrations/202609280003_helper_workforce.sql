-- Workforce model (Founder-locked, D-73, 2026-09-28).
--
--   OWNER     auth user + business_members(owner)      Vendor Web + Mobile (full)
--   OPERATOR  auth user + business_members(operator)   Vendor Web + Mobile (daily ops)
--   HELPER    NO auth user; helper_workers row         Helper PWA only (Prepare/Pack/Ready)
--   RIDER     auth user + riders                       Driver app (unchanged)
--
-- business_members stays the table of AUTHENTICATED Vendor users. Helpers
-- are a separate, accountless identity: a helper_workers row whose access
-- is a server-issued secret (only its sha256 is stored) accepted by a
-- small set of narrowly scoped RPCs. Helpers never read tables directly
-- and never pass is_business_member / is_business_operational, so they
-- inherit no Vendor authority. The member_role enum keeps 'helper' for
-- compatibility, but no new helper team membership can be created.
--
-- Helper access lifecycle (persistent staff access, chosen for long-term
-- kitchen/packing staff):
--   invite token   single use, 7 days, consumed by accept (hash kept only
--                  so a reopened link reports "accepted", never reissues)
--   access token   issued once on accept; no idle or calendar expiry while
--                  the helper is active -- revocation and rotation are the
--                  controls. Owner rotation replaces the hash (old token
--                  dies immediately; lost/shared device recovery); Owner
--                  revocation clears it. Every use is rate-limited and
--                  stamps access_last_used_at so an Owner can see stale access.

create table public.helper_workers(
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses on delete cascade,
  display_name text not null check (length(trim(display_name)) between 1 and 80),
  contact text check (contact is null or length(contact) <= 120),
  status text not null default 'invited' check (status in ('invited', 'active', 'declined', 'revoked')),
  invite_token_hash text,
  invite_expires_at timestamptz,
  access_token_hash text,
  access_issued_at timestamptz,
  access_last_used_at timestamptz,
  invited_by uuid not null references auth.users on delete restrict,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index helper_workers_invite_token_idx on public.helper_workers(invite_token_hash) where invite_token_hash is not null;
create unique index helper_workers_access_token_idx on public.helper_workers(access_token_hash) where access_token_hash is not null;
create index helper_workers_business_idx on public.helper_workers(business_id, status);
alter table public.helper_workers enable row level security;
-- No policies and no grants: every read and write is RPC-mediated.
revoke all on table public.helper_workers from public, anon, authenticated;

alter table public.delivery_stops
  add column preparation_updated_by_helper uuid references public.helper_workers on delete set null;

-- ---------------------------------------------------------------------
-- Canonical preparation transition, shared by Vendor and Helper paths.
-- ---------------------------------------------------------------------
create function public.preparation_transition_allowed(
  p_from public.preparation_status, p_to public.preparation_status
) returns boolean language sql immutable as $$
  select (p_from = 'not_started' and p_to = 'preparing')
      or (p_from = 'preparing' and p_to = 'packed')
      or (p_from = 'packed' and p_to = 'ready')
$$;

-- Vendor path (Owner/Operator). Body unchanged except the shared rule.
create or replace function public.advance_preparation(
  p_order_id uuid,
  p_next public.preparation_status
) returns public.delivery_stops
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
  if o.id is null or not is_business_member(o.business_id) then
    raise exception 'forbidden';
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

-- ---------------------------------------------------------------------
-- Internal: resolve an ACTIVE helper from a raw access token (+ rate limit).
-- ---------------------------------------------------------------------
create function public.helper_from_access_token(p_token text) returns public.helper_workers
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_hash text;
  h helper_workers;
begin
  if p_token is null or p_token !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid access';
  end if;
  v_hash := encode(digest(p_token, 'sha256'), 'hex');
  if check_rate_limit(v_hash, 'helper_access', 60, 60) is false then
    raise exception 'rate limited';
  end if;
  select * into h from helper_workers where access_token_hash = v_hash;
  if h.id is null or h.status <> 'active' then
    raise exception 'invalid access';
  end if;
  update helper_workers set access_last_used_at = now() where id = h.id;
  return h;
end;
$$;
revoke all on function public.helper_from_access_token(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Owner: invite, list, rotate, revoke.
-- ---------------------------------------------------------------------
create function public.create_helper_invitation(
  p_business_id uuid, p_display_name text, p_contact text default null
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_token text;
  h helper_workers;
begin
  if not is_business_owner(p_business_id) then
    raise exception 'forbidden';
  end if;
  if nullif(trim(p_display_name), '') is null then
    raise exception 'name is required';
  end if;
  v_token := encode(gen_random_bytes(32), 'hex');
  insert into helper_workers(business_id, display_name, contact, invite_token_hash, invite_expires_at, invited_by)
    values (p_business_id, trim(p_display_name), nullif(trim(p_contact), ''),
            encode(digest(v_token, 'sha256'), 'hex'), now() + interval '7 days', auth.uid())
    returning * into h;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'helper.invite_created', auth.uid(), 'vendor', jsonb_build_object('helper_id', h.id));
  return jsonb_build_object('helper_id', h.id, 'status', h.status, 'kind', 'invitation',
                            'token', v_token, 'expires_at', h.invite_expires_at);
end;
$$;

create function public.list_helper_workers(p_business_id uuid) returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case when not is_business_owner(p_business_id) then null else coalesce(jsonb_agg(jsonb_build_object(
    'helper_id', h.id, 'display_name', h.display_name, 'contact', h.contact,
    'status', case when h.status = 'invited' and h.invite_expires_at <= now() then 'expired' else h.status end,
    'created_at', h.created_at, 'accepted_at', h.accepted_at,
    'access_last_used_at', h.access_last_used_at, 'revoked_at', h.revoked_at
  ) order by h.created_at), '[]'::jsonb) end
  from helper_workers h
  where h.business_id = p_business_id and h.status <> 'declined'
$$;

-- Owner: regenerate the helper's link. Invited -> new invitation link;
-- active -> new access link. The previous secret stops working at once.
create function public.rotate_helper_access(p_helper_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  h helper_workers;
  v_token text;
begin
  select * into h from helper_workers where id = p_helper_id for update;
  if h.id is null or not is_business_owner(h.business_id) then
    raise exception 'forbidden';
  end if;
  v_token := encode(gen_random_bytes(32), 'hex');
  if h.status = 'active' then
    update helper_workers set access_token_hash = encode(digest(v_token, 'sha256'), 'hex'),
      access_issued_at = now(), updated_at = now() where id = h.id;
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (h.business_id, 'helper.access_rotated', auth.uid(), 'vendor', jsonb_build_object('helper_id', h.id));
    return jsonb_build_object('helper_id', h.id, 'status', 'active', 'kind', 'access', 'token', v_token);
  elsif h.status = 'invited' then
    update helper_workers set invite_token_hash = encode(digest(v_token, 'sha256'), 'hex'),
      invite_expires_at = now() + interval '7 days', updated_at = now() where id = h.id;
    return jsonb_build_object('helper_id', h.id, 'status', 'invited', 'kind', 'invitation', 'token', v_token);
  end if;
  raise exception 'helper not available';
end;
$$;

create function public.revoke_helper_worker(p_helper_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  h helper_workers;
begin
  select * into h from helper_workers where id = p_helper_id for update;
  if h.id is null or not is_business_owner(h.business_id) then
    raise exception 'forbidden';
  end if;
  if h.status in ('revoked', 'declined') then
    return jsonb_build_object('helper_id', h.id, 'status', h.status);
  end if;
  update helper_workers set status = 'revoked', access_token_hash = null, invite_token_hash = null,
    revoked_at = now(), updated_at = now() where id = h.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (h.business_id, 'helper.revoked', auth.uid(), 'vendor', jsonb_build_object('helper_id', h.id));
  return jsonb_build_object('helper_id', h.id, 'status', 'revoked');
end;
$$;

-- ---------------------------------------------------------------------
-- Invitation PWA (anonymous, invite-token bound).
-- ---------------------------------------------------------------------
create function public.resolve_helper_invitation(p_token text) returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'business_name', b.name,
    'location', nullif(trim(b.operating_area), ''),
    'helper_name', h.display_name,
    'status', case
      when h.status = 'invited' and h.invite_expires_at <= now() then 'expired'
      when h.status = 'active' then 'accepted'
      else h.status end
  )
  from helper_workers h
  join businesses b on b.id = h.business_id
  where h.invite_token_hash = encode(digest(p_token, 'sha256'), 'hex')
$$;

-- Accept once: activates the helper and returns the access token ONCE.
-- A reopened invitation never issues another token (the Owner rotates).
create function public.accept_helper_invitation(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  h helper_workers;
  v_access text;
begin
  select * into h from helper_workers
    where invite_token_hash = encode(digest(p_token, 'sha256'), 'hex')
    for update;
  if h.id is null then
    raise exception 'invalid invitation';
  end if;
  if h.status <> 'invited' then
    raise exception 'invitation not available';
  end if;
  if h.invite_expires_at <= now() then
    raise exception 'invitation expired';
  end if;
  v_access := encode(gen_random_bytes(32), 'hex');
  update helper_workers set status = 'active', accepted_at = now(),
    access_token_hash = encode(digest(v_access, 'sha256'), 'hex'), access_issued_at = now(),
    updated_at = now() where id = h.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (h.business_id, 'helper.invite_accepted', null, 'helper', jsonb_build_object('helper_id', h.id));
  return jsonb_build_object('status', 'accepted', 'access_token', v_access,
    'business_name', (select name from businesses where id = h.business_id));
end;
$$;

create function public.decline_helper_invitation(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  h helper_workers;
begin
  select * into h from helper_workers
    where invite_token_hash = encode(digest(p_token, 'sha256'), 'hex')
    for update;
  if h.id is null then
    raise exception 'invalid invitation';
  end if;
  if h.status = 'declined' then
    return jsonb_build_object('status', 'declined');
  end if;
  if h.status <> 'invited' or h.invite_expires_at <= now() then
    raise exception 'invitation not available';
  end if;
  update helper_workers set status = 'declined', updated_at = now() where id = h.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (h.business_id, 'helper.invite_declined', null, 'helper', jsonb_build_object('helper_id', h.id));
  return jsonb_build_object('status', 'declined');
end;
$$;

-- ---------------------------------------------------------------------
-- Helper PWA (anonymous, access-token bound). Minimised by construction:
-- only the fields needed to prepare and pack.
-- ---------------------------------------------------------------------
create function public.helper_tasks(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  h helper_workers;
begin
  h := helper_from_access_token(p_token);
  return jsonb_build_object(
    'business_name', (select name from businesses where id = h.business_id),
    'helper_name', h.display_name,
    'tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
        'order_id', o.id,
        'order_number', o.order_number,
        'customer_name', o.customer_name,
        'items', o.items,
        'notes', nullif(o.notes, ''),
        'preparation_status', s.preparation_status,
        'preparation_updated_at', s.preparation_updated_at,
        'created_at', o.created_at
      ) order by o.created_at)
      from orders o
      join delivery_stops s on s.order_id = o.id
      where o.business_id = h.business_id
        and o.delivery_status in ('created', 'ready_for_pickup')
    ), '[]'::jsonb)
  );
end;
$$;

create function public.helper_advance_preparation(
  p_token text, p_order_id uuid, p_next public.preparation_status
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  h helper_workers;
  o orders;
  st delivery_stops;
  old public.preparation_status;
begin
  h := helper_from_access_token(p_token);
  select * into o from orders where id = p_order_id for update;
  -- An order id alone grants nothing: it must belong to this helper's
  -- business and still be before pickup.
  if o.id is null or o.business_id <> h.business_id
     or o.delivery_status not in ('created', 'ready_for_pickup') then
    raise exception 'task not available';
  end if;
  select * into st from delivery_stops where order_id = o.id for update;
  if st.id is null then
    raise exception 'task not available';
  end if;
  old := st.preparation_status;
  if old <> p_next then
    if not preparation_transition_allowed(old, p_next) then
      raise exception 'invalid preparation transition % -> %', old, p_next;
    end if;
    update delivery_stops set
      preparation_status = p_next,
      preparation_updated_at = now(),
      preparation_updated_by = null,
      preparation_updated_by_helper = h.id,
      updated_at = now()
    where id = st.id
    returning * into st;
    insert into delivery_events(business_id, order_id, delivery_stop_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
      values (o.business_id, o.id, st.id, 'preparation.status_changed', old::text, p_next::text, null, 'helper',
              jsonb_build_object('helper_id', h.id));
  end if;
  return jsonb_build_object('order_id', o.id, 'order_number', o.order_number,
    'preparation_status', st.preparation_status, 'preparation_updated_at', st.preparation_updated_at);
end;
$$;

-- ---------------------------------------------------------------------
-- Team invitations: Operator only. Helpers use helper_workers; owners are
-- never invited through the normal team flow (no co-owner / transfer).
-- ---------------------------------------------------------------------
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
  if p_role is distinct from 'operator' then
    raise exception 'only operators are invited as team members';
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

-- Existing helper-role team invitations (none on staging) can no longer be
-- consented or claimed into business_members.
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
  if v_invitation.role = 'helper' then
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

create or replace function public.claim_my_team_invitations() returns jsonb
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
        and role <> 'helper'
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
  if v_invitation.role = 'helper' then
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

-- ---------------------------------------------------------------------
-- Operator manages riders (Founder, D-73): approve / deactivate move from
-- Owner-only to Owner or Operator, still strictly business-scoped.
-- ---------------------------------------------------------------------
create or replace function public.approve_pending_rider(p_rider_id uuid) returns public.riders
language plpgsql
security definer
set search_path = public
as $$
declare
  r riders;
begin
  select * into r from riders where id = p_rider_id for update;
  if r.id is null or not is_business_operational(r.business_id) then
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
  if r.id is null or not public.is_business_operational(r.business_id) then
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

-- ---------------------------------------------------------------------
-- Grants.
-- ---------------------------------------------------------------------
revoke all on function public.preparation_transition_allowed(public.preparation_status, public.preparation_status) from public, anon, authenticated;
revoke all on function public.create_helper_invitation(uuid, text, text) from public, anon;
revoke all on function public.list_helper_workers(uuid) from public, anon;
revoke all on function public.rotate_helper_access(uuid) from public, anon;
revoke all on function public.revoke_helper_worker(uuid) from public, anon;
grant execute on function public.create_helper_invitation(uuid, text, text) to authenticated;
grant execute on function public.list_helper_workers(uuid) to authenticated;
grant execute on function public.rotate_helper_access(uuid) to authenticated;
grant execute on function public.revoke_helper_worker(uuid) to authenticated;
revoke all on function public.resolve_helper_invitation(text) from public;
revoke all on function public.accept_helper_invitation(text) from public;
revoke all on function public.decline_helper_invitation(text) from public;
revoke all on function public.helper_tasks(text) from public;
revoke all on function public.helper_advance_preparation(text, uuid, public.preparation_status) from public;
grant execute on function public.resolve_helper_invitation(text) to anon, authenticated;
grant execute on function public.accept_helper_invitation(text) to anon, authenticated;
grant execute on function public.decline_helper_invitation(text) to anon, authenticated;
grant execute on function public.helper_tasks(text) to anon, authenticated;
grant execute on function public.helper_advance_preparation(text, uuid, public.preparation_status) to anon, authenticated;
