-- CEFFLO open invite links (Founder approval 2026-10-01, STAGING FIRST,
-- review before apply). One reusable link per business per kind:
-- rider, operator, helper. Anyone who opens a link must sign in, and every
-- join lands as PENDING: nobody gains access until the business approves.
--
--   rider           -> riders row, status 'pending' (existing approval:
--                      approve_pending_rider, Riders > Pending tab)
--   operator/helper -> team_join_requests row, status 'pending'; the Owner
--                      approves (membership created) or rejects.
--
-- Additive only: two new tables, new RPCs. No existing table, column,
-- policy or function is changed; the per-person invitations keep working.

-- ---------------------------------------------------------------- links
create table public.business_invite_links (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  kind text not null check (kind in ('rider', 'operator', 'helper')),
  -- The link is meant to be shared, so the owner must be able to show it
  -- again: the token is kept, but the table has RLS on and NO policies --
  -- it is readable only through the SECURITY DEFINER functions below.
  token text not null unique,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  revoked_at timestamptz
);
create unique index business_invite_links_one_live_idx
  on public.business_invite_links(business_id, kind) where revoked_at is null;
alter table public.business_invite_links enable row level security;

-- ------------------------------------------------------- team requests
create table public.team_join_requests (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.member_role not null check (role in ('operator', 'helper')),
  name text not null,
  phone text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  link_id uuid references public.business_invite_links(id) on delete set null,
  decided_by uuid references auth.users(id),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
create unique index team_join_requests_one_pending_idx
  on public.team_join_requests(business_id, user_id) where status = 'pending';
alter table public.team_join_requests enable row level security;

-- The requester sees their own requests; the Owner sees the business's.
create policy team_join_requests_read on public.team_join_requests
  for select to authenticated
  using (user_id = auth.uid() or is_business_owner(business_id));

-- Who may hand out which link: riders -> owner or operator (same rule as
-- create_rider_invitation); operator / helper -> owner only (same rule as
-- create_team_invitation).
create or replace function public._may_manage_invite_link(p_business uuid, p_kind text)
returns boolean language sql stable security definer set search_path to 'public' as $$
  select case p_kind
    when 'rider' then is_business_operational(p_business)
    when 'operator' then is_business_owner(p_business)
    when 'helper' then is_business_owner(p_business)
    else false end
$$;
revoke all on function public._may_manage_invite_link(uuid, text) from public, anon;

-- The live link for (business, kind), created on first use. Opening the
-- invite screen shows the same link every time.
create or replace function public.get_invite_link(p_business_id uuid, p_kind text)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare v business_invite_links;
begin
  if not _may_manage_invite_link(p_business_id, p_kind) then
    raise exception 'forbidden';
  end if;
  select * into v from business_invite_links
    where business_id = p_business_id and kind = p_kind and revoked_at is null;
  if v.id is null then
    insert into business_invite_links(business_id, kind, token, created_by)
      values (p_business_id, p_kind, encode(gen_random_bytes(24), 'hex'), auth.uid())
      on conflict do nothing
      returning * into v;
    if v.id is null then -- lost a race: read the winner
      select * into v from business_invite_links
        where business_id = p_business_id and kind = p_kind and revoked_at is null;
    else
      insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
        values (p_business_id, 'invite_link.created', auth.uid(), 'vendor', jsonb_build_object('kind', p_kind));
    end if;
  end if;
  return jsonb_build_object('kind', v.kind, 'token', v.token, 'created_at', v.created_at);
end $$;

-- Reset: the old link stops working at once, a new one replaces it.
create or replace function public.reset_invite_link(p_business_id uuid, p_kind text)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
begin
  if not _may_manage_invite_link(p_business_id, p_kind) then
    raise exception 'forbidden';
  end if;
  update business_invite_links set revoked_at = now()
    where business_id = p_business_id and kind = p_kind and revoked_at is null;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'invite_link.reset', auth.uid(), 'vendor', jsonb_build_object('kind', p_kind));
  return get_invite_link(p_business_id, p_kind);
end $$;

-- Landing page (Invitation PWA): what this link is, before sign-in.
create or replace function public.resolve_invite_link(p_token text)
returns jsonb language sql stable security definer set search_path to 'public' as $$
  select jsonb_build_object(
    'business_name', b.name,
    'location', nullif(trim(b.operating_area), ''),
    'kind', l.kind,
    'status', case when l.revoked_at is null then 'open' else 'revoked' end)
  from business_invite_links l join businesses b on b.id = l.business_id
  where l.token = p_token
$$;

-- Join through a link. Signed in only; always PENDING.
create or replace function public.join_via_invite_link(p_token text, p_name text, p_phone text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v business_invite_links;
  v_name text := nullif(trim(p_name), '');
  v_phone text := nullif(trim(p_phone), '');
  v_rider riders;
  v_req team_join_requests;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  select * into v from business_invite_links where token = p_token;
  if v.id is null or v.revoked_at is not null then
    raise exception 'invitation not available';
  end if;
  if v_name is null then raise exception 'name is required'; end if;

  if v.kind = 'rider' then
    if v_phone is null then raise exception 'phone is required'; end if;
    select * into v_rider from riders where business_id = v.business_id and auth_user_id = auth.uid();
    if v_rider.id is not null then
      return jsonb_build_object('business_id', v.business_id, 'kind', 'rider', 'status', v_rider.status);
    end if;
    begin
      insert into riders(business_id, auth_user_id, name, phone, status)
        values (v.business_id, auth.uid(), v_name, v_phone, 'pending')
        returning * into v_rider;
    exception when unique_violation then
      raise exception 'phone already on file for this business';
    end;
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (v.business_id, 'rider.joined_via_link', auth.uid(), 'rider', jsonb_build_object('rider_id', v_rider.id));
    return jsonb_build_object('business_id', v.business_id, 'kind', 'rider', 'status', 'pending');
  end if;

  -- operator / helper
  if exists (select 1 from business_members
             where business_id = v.business_id and user_id = auth.uid() and status = 'active') then
    return jsonb_build_object('business_id', v.business_id, 'kind', v.kind, 'status', 'active');
  end if;
  select * into v_req from team_join_requests
    where business_id = v.business_id and user_id = auth.uid() and status = 'pending';
  if v_req.id is null then
    insert into team_join_requests(business_id, user_id, role, name, phone, link_id)
      values (v.business_id, auth.uid(), v.kind::member_role, v_name, v_phone, v.id)
      returning * into v_req;
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (v.business_id, 'team.join_requested', auth.uid(), 'vendor',
              jsonb_build_object('request_id', v_req.id, 'role', v.kind));
  end if;
  return jsonb_build_object('business_id', v.business_id, 'kind', v.kind, 'status', 'pending');
end $$;

-- Owner decision on a team request. Approve creates the membership; an
-- existing Owner is never downgraded.
create or replace function public.decide_team_join_request(p_request_id uuid, p_approve boolean)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v team_join_requests;
begin
  select * into v from team_join_requests where id = p_request_id for update;
  if v.id is null or not is_business_owner(v.business_id) then
    raise exception 'forbidden';
  end if;
  if v.status <> 'pending' then raise exception 'request already decided'; end if;
  if p_approve then
    insert into business_members(business_id, user_id, role, status)
      values (v.business_id, v.user_id, v.role, 'active')
      on conflict (business_id, user_id) do update
        set role = case when business_members.role = 'owner' then 'owner'::member_role else excluded.role end,
            status = 'active';
  end if;
  update team_join_requests
    set status = case when p_approve then 'approved' else 'rejected' end,
        decided_by = auth.uid(), decided_at = now()
    where id = v.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v.business_id, case when p_approve then 'team.join_approved' else 'team.join_rejected' end,
            auth.uid(), 'vendor', jsonb_build_object('request_id', v.id, 'role', v.role));
  return jsonb_build_object('request_id', v.id, 'status', case when p_approve then 'approved' else 'rejected' end);
end $$;

revoke all on function public.get_invite_link(uuid, text) from public, anon;
revoke all on function public.reset_invite_link(uuid, text) from public, anon;
revoke all on function public.join_via_invite_link(text, text, text) from public, anon;
revoke all on function public.decide_team_join_request(uuid, boolean) from public, anon;
grant execute on function public.get_invite_link(uuid, text) to authenticated;
grant execute on function public.reset_invite_link(uuid, text) to authenticated;
grant execute on function public.join_via_invite_link(text, text, text) to authenticated;
grant execute on function public.decide_team_join_request(uuid, boolean) to authenticated;
grant execute on function public.resolve_invite_link(text) to anon, authenticated;
