-- S4-07.3a: Rider multi-business identity + explicit active-context
-- authorization, plus the paired POD active-context correction.
--
-- Founder-locked model: one auth.users identity may legitimately hold more
-- than one Vendor-owned Rider relationship (D-03). The relationship the
-- client is CURRENTLY operating under must be an explicit, independently
-- verified input to every Rider mutation -- never inferred from whichever
-- relationship a target happens to belong to (that proves identity
-- ownership, not selected context). RLS remains an identity-wide ownership
-- CEILING only; it is not, and is not treated as, active-context workflow
-- scoping.
--
-- Sequence (each step leaves the system internally consistent -- no window
-- where old and new coexist inconsistently):
--   1. is_current_rider(p_rider_id) -- the one canonical ownership helper.
--   2. Uniqueness: drop UNIQUE(auth_user_id), add UNIQUE(business_id,
--      auth_user_id) -- strictly weaker, no existing row can violate it.
--   3. Seven RLS/storage policies + is_session_rider updated to the new
--      ceiling-only helper.
--   4. Nine Rider RPCs: DROP the old context-free signature, CREATE the new
--      p_rider_id-first signature (CREATE OR REPLACE cannot be used --
--      adding a parameter is a different signature; this exact drop-then-
--      create pattern already has precedent in this codebase for
--      create_delivery/update_order_details).
--   5. complete_delivery additionally: structural POD-path validation
--      against p_rider_id/p_order_id, plus a live storage.objects existence
--      check, before ever persisting the path as delivery proof.
--   6. Only now, with nothing left referencing it, drop the old bare
--      current_rider_id() -- a deliberate exception to this project's
--      "bypass, don't delete" convention, since an ambiguous global-identity
--      helper left lying around is a live authorization footgun, not inert
--      UI code.

-- =====================================================================
-- 1. Canonical ownership helper.
-- =====================================================================
-- Proves relationship ownership + active status only -- never "this is the
-- currently selected relationship" (Founder-locked distinction). Same
-- security-definer/broad-grant shape as is_session_rider's own established
-- reasoning: invoked implicitly while Postgres evaluates another table's
-- RLS policy for ANY querying role, including anon.
create function public.is_current_rider(p_rider_id uuid) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1 from riders where id = p_rider_id and auth_user_id = auth.uid() and status = 'active'
  )
$$;
grant execute on function public.is_current_rider(uuid) to public, anon, authenticated;

-- =====================================================================
-- 2. Multi-business uniqueness. Strictly weaker than the constraint it
-- replaces -- no existing row can possibly violate it, so no data rewrite
-- is needed. No FK anywhere targets riders.auth_user_id specifically
-- (every "references riders" elsewhere targets the primary key id), so
-- this has zero cascade impact.
-- =====================================================================
alter table public.riders drop constraint riders_auth_user_id_key;
alter table public.riders add constraint riders_business_auth_user_id_key unique (business_id, auth_user_id);

-- =====================================================================
-- 3. RLS/storage ceiling updates + is_session_rider.
-- =====================================================================
drop policy orders_rider on public.orders;
create policy orders_rider on public.orders for select using (is_current_rider(assigned_rider_id));

drop policy assignments_rider on public.rider_assignments;
create policy assignments_rider on public.rider_assignments for select using (is_current_rider(rider_id));

drop policy stops_rider on public.delivery_stops;
create policy stops_rider on public.delivery_stops for select using (is_current_rider(rider_id));

drop policy events_rider on public.delivery_events;
create policy events_rider on public.delivery_events for select using (order_id in (select id from orders where is_current_rider(assigned_rider_id)));

drop policy locations_rider on public.rider_locations;
create policy locations_rider on public.rider_locations for insert with check (is_current_rider(rider_id));

-- POD upload: the object PATH is now the explicit, independently-verified
-- context selector (Storage RLS cannot accept an out-of-band "active
-- context" parameter the way an RPC call can -- the path is the only
-- client-supplied datum available to check against). Both the path's
-- claimed rider id AND the target order's actual assigned rider must match
-- exactly -- ownership across some other relationship of the same identity
-- is not sufficient. This is evaluated at INSERT time, before the object is
-- accepted.
drop policy pod_rider_upload on storage.objects;
create policy pod_rider_upload on storage.objects for insert to authenticated with check(
  bucket_id = 'cefflo-pod'
  and is_current_rider((storage.foldername(name))[1]::uuid)
  and exists(
    select 1 from orders o
    where o.id = (storage.foldername(name))[2]::uuid
      and o.assigned_rider_id = (storage.foldername(name))[1]::uuid
  )
);

-- POD read: unchanged in shape and unchanged in path-index (the order id
-- was, and remains, foldername()[2] under the new <rider_id>/<order_id>/...
-- layout -- the literal 'orders' label is simply replaced 1:1 by rider_id,
-- so no re-indexing is needed, only the helper call). Left ceiling-only
-- (ownership across every relationship, not path-claimed-context matching)
-- deliberately: this policy is not exercised by any live read path today
-- (Vendor/Rider both read POD exclusively through the tracking-pod signed-
-- URL Edge Function's service_role client, which bypasses RLS entirely) --
-- reading a photo the same identity is legitimately entitled to creates
-- none of the upload-side harms (orphan objects, tenant contamination,
-- audit ambiguity) that justify the stricter upload check above.
drop policy pod_authorized_read on storage.objects;
create policy pod_authorized_read on storage.objects for select to authenticated using(
  bucket_id = 'cefflo-pod'
  and exists(
    select 1 from orders o
    where o.id = (storage.foldername(name))[2]::uuid
      and (is_business_member(o.business_id) or is_current_rider(o.assigned_rider_id))
  )
);

-- Delivery-session visibility: RLS structurally cannot take a client-
-- supplied "active rider" parameter, so this remains a ceiling (does ANY
-- of my active relationships have an assignment in this session) -- the
-- Rider frontend's own explicit business_id filter (Section 9) is what
-- prevents Business A/B Wave mixing in the UI; this policy's job is only
-- to guarantee no OTHER identity's session is ever visible.
create or replace function public.is_session_rider(p_delivery_session_id uuid) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1 from rider_assignments
    where delivery_session_id = p_delivery_session_id
      and is_current_rider(rider_id)
  )
$$;

-- Small, mechanically-required addition: the Team-selection screen (Section
-- 7/8 of the frontend design) needs to show which BUSINESS each
-- relationship belongs to -- a Rider has no other read path to a business's
-- name today (businesses_read requires is_business_member, which a Rider
-- never is). Scoped to exactly "a business I hold any documented riders
-- relationship with" -- matching this project's established precedent of
-- adding the smallest new read a genuine new screen requires (e.g.
-- is_session_rider for S4-06.6a). Read-only; no write capability implied.
create policy businesses_rider on public.businesses for select using (
  exists(select 1 from riders where riders.business_id = businesses.id and riders.auth_user_id = auth.uid())
);

-- =====================================================================
-- 4. Nine Rider RPCs: explicit p_rider_id, first parameter. Every existing
-- check/statement otherwise preserved byte-for-byte; only the identity
-- derivation and every place that referenced the old ambiguous `rid`
-- changes -- to the caller-supplied, independently-verified p_rider_id.
-- =====================================================================

drop function if exists public.accept_assignment(uuid);
create function public.accept_assignment(p_rider_id uuid, p_order_id uuid) returns public.rider_assignments
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  a rider_assignments;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'invalid rider context';
  end if;
  select * into o from orders where id = p_order_id for update;
  if o.id is null or o.assigned_rider_id is distinct from p_rider_id then
    raise exception 'forbidden';
  end if;
  select ra.* into a from rider_assignments ra
    join delivery_stops s on s.assignment_id = ra.id
    where s.order_id = o.id
    for update;
  if a.id is null or a.rider_id is distinct from p_rider_id then
    raise exception 'forbidden';
  end if;
  if a.status = 'accepted' then
    return a;
  end if;
  if a.status <> 'assigned' then
    raise exception 'assignment not pending';
  end if;
  update rider_assignments set status = 'accepted', accepted_at = now(), updated_at = now()
    where id = a.id
    returning * into a;
  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role)
    select o.business_id, o.id, s.id, a.id, 'assignment.accepted', auth.uid(), 'rider'
    from delivery_stops s where s.order_id = o.id;
  return a;
end;
$$;
revoke all on function public.accept_assignment(uuid, uuid) from public, anon, authenticated;
grant execute on function public.accept_assignment(uuid, uuid) to authenticated;

drop function if exists public.decline_assignment(uuid);
create function public.decline_assignment(p_rider_id uuid, p_order_id uuid) returns public.rider_assignments
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  a rider_assignments;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'invalid rider context';
  end if;
  select * into o from orders where id = p_order_id for update;
  if o.id is null or o.assigned_rider_id is distinct from p_rider_id then
    raise exception 'forbidden';
  end if;
  select ra.* into a from rider_assignments ra
    join delivery_stops s on s.assignment_id = ra.id
    where s.order_id = o.id
    for update;
  if a.id is null or a.rider_id is distinct from p_rider_id then
    raise exception 'forbidden';
  end if;
  if a.status = 'declined' then
    return a;
  end if;
  if a.status <> 'assigned' then
    raise exception 'assignment not pending';
  end if;
  update rider_assignments set status = 'declined', updated_at = now()
    where id = a.id
    returning * into a;
  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role)
    select o.business_id, o.id, s.id, a.id, 'assignment.declined', auth.uid(), 'rider'
    from delivery_stops s where s.order_id = o.id;
  return a;
end;
$$;
revoke all on function public.decline_assignment(uuid, uuid) from public, anon, authenticated;
grant execute on function public.decline_assignment(uuid, uuid) to authenticated;

drop function if exists public.accept_run(uuid);
create function public.accept_run(p_rider_id uuid, p_delivery_session_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  newly_accepted_count int;
  already_accepted_count int;
  skipped_count int;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'invalid rider context';
  end if;

  if not exists (
    select 1 from rider_assignments where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id
  ) then
    raise exception 'no assignments in this run';
  end if;

  select count(*) into already_accepted_count
    from rider_assignments
    where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id and status = 'accepted';

  select count(*) into skipped_count
    from rider_assignments
    where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id
      and status not in ('assigned','accepted');

  with newly_accepted as (
    update rider_assignments a
    set status = 'accepted', accepted_at = now(), updated_at = now()
    where a.rider_id = p_rider_id and a.delivery_session_id = p_delivery_session_id and a.status = 'assigned'
    returning a.id
  ),
  events as (
    insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role, metadata)
    select s.business_id, s.order_id, s.id, na.id, 'assignment.accepted', auth.uid(), 'rider', jsonb_build_object('via', 'accept_run')
    from newly_accepted na join delivery_stops s on s.assignment_id = na.id
    returning 1
  )
  select count(*) into newly_accepted_count from newly_accepted;

  return jsonb_build_object(
    'delivery_session_id', p_delivery_session_id,
    'newly_accepted', newly_accepted_count,
    'already_accepted', already_accepted_count,
    'skipped', skipped_count
  );
end;
$$;
revoke all on function public.accept_run(uuid, uuid) from public, anon, authenticated;
grant execute on function public.accept_run(uuid, uuid) to authenticated;

drop function if exists public.decline_run(uuid);
create function public.decline_run(p_rider_id uuid, p_delivery_session_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  newly_declined_count int;
  already_declined_count int;
  skipped_count int;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'invalid rider context';
  end if;

  if not exists (
    select 1 from rider_assignments where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id
  ) then
    raise exception 'no assignments in this run';
  end if;

  select count(*) into already_declined_count
    from rider_assignments
    where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id and status = 'declined';

  select count(*) into skipped_count
    from rider_assignments
    where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id
      and status not in ('assigned','declined');

  with newly_declined as (
    update rider_assignments a
    set status = 'declined', updated_at = now()
    where a.rider_id = p_rider_id and a.delivery_session_id = p_delivery_session_id and a.status = 'assigned'
    returning a.id
  ),
  events as (
    insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role, metadata)
    select s.business_id, s.order_id, s.id, nd.id, 'assignment.declined', auth.uid(), 'rider', jsonb_build_object('via', 'decline_run')
    from newly_declined nd join delivery_stops s on s.assignment_id = nd.id
    returning 1
  )
  select count(*) into newly_declined_count from newly_declined;

  return jsonb_build_object(
    'delivery_session_id', p_delivery_session_id,
    'newly_declined', newly_declined_count,
    'already_declined', already_declined_count,
    'skipped', skipped_count
  );
end;
$$;
revoke all on function public.decline_run(uuid, uuid) from public, anon, authenticated;
grant execute on function public.decline_run(uuid, uuid) to authenticated;

drop function if exists public.save_run_sequence(uuid, uuid[]);
create function public.save_run_sequence(p_rider_id uuid, p_delivery_session_id uuid, p_ordered_order_ids uuid[]) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  locked_count int;
  eligible_count int;
  provided_count int;
  distinct_provided_count int;
  mismatch_count int;
  unchanged_count int;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'invalid rider context';
  end if;

  select count(*) into locked_count
    from delivery_stops s
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = p_rider_id
      and a.delivery_session_id = p_delivery_session_id
      and a.status not in ('declined','cancelled','completed','issue')
      and s.sequence_locked_at is not null;
  if locked_count > 0 then
    raise exception 'sequence locked';
  end if;

  select count(*) into eligible_count
    from delivery_stops s
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = p_rider_id
      and a.delivery_session_id = p_delivery_session_id
      and a.status not in ('declined','cancelled','completed','issue');

  provided_count := coalesce(array_length(p_ordered_order_ids, 1), 0);
  select count(*) into distinct_provided_count from (select distinct unnest(p_ordered_order_ids)) x;

  if provided_count = 0 or distinct_provided_count <> provided_count or provided_count <> eligible_count then
    raise exception 'invalid sequence set';
  end if;

  select count(*) into mismatch_count
    from unnest(p_ordered_order_ids) as provided(order_id)
    where not exists (
      select 1 from delivery_stops s
      join rider_assignments a on a.id = s.assignment_id
      where a.rider_id = p_rider_id
        and a.delivery_session_id = p_delivery_session_id
        and a.status not in ('declined','cancelled','completed','issue')
        and s.order_id = provided.order_id
    );
  if mismatch_count > 0 then
    raise exception 'invalid sequence set';
  end if;

  select count(*) into unchanged_count
    from delivery_stops s
    join unnest(p_ordered_order_ids) with ordinality as idx(order_id, pos) on s.order_id = idx.order_id
    where s.sequence is distinct from idx.pos::int;
  if unchanged_count = 0 then
    return;
  end if;

  update delivery_stops s
    set sequence = idx.pos, updated_at = now()
    from unnest(p_ordered_order_ids) with ordinality as idx(order_id, pos)
    where s.order_id = idx.order_id;

  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role, metadata)
  select a.business_id, s.order_id, s.id, s.assignment_id, 'run.sequence_saved', auth.uid(), 'rider',
         jsonb_build_object('delivery_session_id', p_delivery_session_id, 'sequence', s.sequence)
  from delivery_stops s
  join rider_assignments a on a.id = s.assignment_id
  where a.rider_id = p_rider_id
    and a.delivery_session_id = p_delivery_session_id
    and s.order_id = any(p_ordered_order_ids);
end;
$$;
revoke all on function public.save_run_sequence(uuid, uuid, uuid[]) from public, anon, authenticated;
grant execute on function public.save_run_sequence(uuid, uuid, uuid[]) to authenticated;

drop function if exists public.start_pickup_run(uuid);
create function public.start_pickup_run(p_rider_id uuid, p_delivery_session_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  biz_id uuid;
  pending_count int;
  existing_event_id bigint;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'invalid rider context';
  end if;

  perform 1 from rider_assignments a
    where a.rider_id = p_rider_id and a.delivery_session_id = p_delivery_session_id
    for update;

  select business_id into biz_id from rider_assignments
    where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id
    limit 1;
  if biz_id is null then
    raise exception 'no assignments in this run';
  end if;

  select count(*) into pending_count
    from rider_assignments a
    where a.rider_id = p_rider_id and a.delivery_session_id = p_delivery_session_id
      and a.status = 'assigned';
  if pending_count > 0 then
    raise exception 'unsettled assignments remain';
  end if;

  select id into existing_event_id
    from delivery_events
    where event_type = 'run.pickup_started'
      and actor_user_id = auth.uid()
      and metadata->>'delivery_session_id' = p_delivery_session_id::text
    limit 1;

  if existing_event_id is null then
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (biz_id, 'run.pickup_started', auth.uid(), 'rider',
            jsonb_build_object('delivery_session_id', p_delivery_session_id, 'rider_id', p_rider_id));
  end if;

  perform mark_session_active_if_planned(p_delivery_session_id);

  return jsonb_build_object('delivery_session_id', p_delivery_session_id, 'pickup_started', true);
end;
$$;
revoke all on function public.start_pickup_run(uuid, uuid) from public, anon, authenticated;
grant execute on function public.start_pickup_run(uuid, uuid) to authenticated;

drop function if exists public.start_run_delivery(uuid);
create function public.start_run_delivery(p_rider_id uuid, p_delivery_session_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  biz_id uuid;
  not_picked_up_count int;
  eligible_count int;
  sequenced_count int;
  distinct_sequence_count int;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'invalid rider context';
  end if;

  perform 1 from rider_assignments a
    where a.rider_id = p_rider_id and a.delivery_session_id = p_delivery_session_id
    for update;

  select business_id into biz_id from rider_assignments
    where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id
    limit 1;
  if biz_id is null then
    raise exception 'no assignments in this run';
  end if;

  if exists (
    select 1 from delivery_stops s
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = p_rider_id
      and a.delivery_session_id = p_delivery_session_id
      and a.status not in ('declined','cancelled','completed','issue')
      and s.sequence_locked_at is not null
  ) then
    return jsonb_build_object('delivery_session_id', p_delivery_session_id, 'sequence_locked', true, 'already_locked', true);
  end if;

  select count(*) into not_picked_up_count
    from orders o
    join delivery_stops s on s.order_id = o.id
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = p_rider_id
      and a.delivery_session_id = p_delivery_session_id
      and a.status not in ('declined','cancelled','completed','issue')
      and o.delivery_status in ('created','ready_for_pickup');
  if not_picked_up_count > 0 then
    raise exception 'pickup incomplete';
  end if;

  select count(*) into eligible_count
    from delivery_stops s
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = p_rider_id
      and a.delivery_session_id = p_delivery_session_id
      and a.status not in ('declined','cancelled','completed','issue');

  select count(*), count(distinct sequence) into sequenced_count, distinct_sequence_count
    from delivery_stops s
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = p_rider_id
      and a.delivery_session_id = p_delivery_session_id
      and a.status not in ('declined','cancelled','completed','issue')
      and s.sequence is not null;

  if eligible_count = 0 or sequenced_count <> eligible_count or distinct_sequence_count <> eligible_count then
    raise exception 'sequence not ready';
  end if;

  with locked as (
    update delivery_stops s
    set sequence_locked_at = now(), updated_at = now()
    from rider_assignments a
    where s.assignment_id = a.id
      and a.rider_id = p_rider_id
      and a.delivery_session_id = p_delivery_session_id
      and a.status not in ('declined','cancelled','completed','issue')
    returning s.id, s.order_id, s.business_id, s.assignment_id, s.sequence
  ),
  lock_events as (
    insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role, metadata)
    select l.business_id, l.order_id, l.id, l.assignment_id, 'run.sequence_locked', auth.uid(), 'rider',
           jsonb_build_object('delivery_session_id', p_delivery_session_id, 'sequence', l.sequence)
    from locked l
    returning 1
  )
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
  select biz_id, 'run.delivery_started', auth.uid(), 'rider',
         jsonb_build_object('delivery_session_id', p_delivery_session_id, 'rider_id', p_rider_id)
  where exists (select 1 from locked);

  return jsonb_build_object('delivery_session_id', p_delivery_session_id, 'sequence_locked', true, 'already_locked', false);
end;
$$;
revoke all on function public.start_run_delivery(uuid, uuid) from public, anon, authenticated;
grant execute on function public.start_run_delivery(uuid, uuid) to authenticated;

drop function if exists public.rider_transition(uuid, public.delivery_status, text);
create function public.rider_transition(p_rider_id uuid, p_order_id uuid, p_next public.delivery_status, p_idempotency_key text default null)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  old delivery_status;
  ok boolean;
  a_status assignment_status;
  my_seq int;
  my_locked timestamptz;
  my_session uuid;
  incomplete_earlier int;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'invalid rider context';
  end if;
  select * into o from orders where id = p_order_id for update;
  if o.id is null or o.assigned_rider_id is distinct from p_rider_id then
    raise exception 'forbidden';
  end if;

  select a.status into a_status
    from rider_assignments a join delivery_stops s on s.assignment_id = a.id
    where s.order_id = o.id;
  if a_status is distinct from 'accepted' then
    raise exception 'assignment not accepted';
  end if;

  old = o.delivery_status;
  if old = p_next then
    return o;
  end if;

  ok = (old = 'created' and p_next = 'ready_for_pickup')
    or (old = 'ready_for_pickup' and p_next = 'picked_up')
    or (old = 'picked_up' and p_next = 'out_for_delivery')
    or (old = 'out_for_delivery' and p_next = 'arrived');
  if not ok then
    raise exception 'invalid transition % -> %', old, p_next;
  end if;

  if p_next in ('out_for_delivery', 'arrived') then
    select s.sequence, s.sequence_locked_at, a.delivery_session_id
      into my_seq, my_locked, my_session
      from delivery_stops s join rider_assignments a on a.id = s.assignment_id
      where s.order_id = o.id;

    if my_session is not null and my_locked is null then
      raise exception 'sequence not locked';
    end if;

    if my_locked is not null then
      select count(*) into incomplete_earlier
        from delivery_stops s2
        join rider_assignments a2 on a2.id = s2.assignment_id
        join orders o2 on o2.id = s2.order_id
        where a2.rider_id = p_rider_id
          and a2.delivery_session_id = my_session
          and a2.status not in ('declined','cancelled','completed','issue')
          and s2.sequence < my_seq
          and o2.delivery_status <> 'delivered';
      if incomplete_earlier > 0 then
        raise exception 'complete earlier stop first';
      end if;
    end if;
  end if;

  update orders set delivery_status = p_next, updated_at = now() where id = o.id returning * into o;
  update delivery_stops set status = p_next, arrived_at = case when p_next = 'arrived' then now() else arrived_at end, updated_at = now() where order_id = o.id;
  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    select o.business_id, o.id, s.id, s.assignment_id, 'delivery.status_changed', old, p_next, auth.uid(), 'rider', jsonb_build_object('idempotency_key', p_idempotency_key)
    from delivery_stops s where s.order_id = o.id;
  return o;
end;
$$;
revoke all on function public.rider_transition(uuid, uuid, public.delivery_status, text) from public, anon, authenticated;
grant execute on function public.rider_transition(uuid, uuid, public.delivery_status, text) to authenticated;

-- =====================================================================
-- 5. complete_delivery: explicit context + POD structural/existence
-- defense-in-depth (Founder-mandated, Section 13). Every existing rule
-- about WHEN a POD is required/optional is preserved exactly -- the new
-- checks run strictly after that existing gate, so they only ever see a
-- genuinely non-empty p_pod_path. Already-'delivered' orders return early,
-- before reaching the new checks -- historical (pre-S4-07.3a) stored paths,
-- of any shape, are never re-validated or reinterpreted.
-- =====================================================================
drop function if exists public.complete_delivery(uuid, text, text, text);
create function public.complete_delivery(p_rider_id uuid, p_order_id uuid, p_pod_path text, p_note text default '', p_idempotency_key text default null) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  path_rider_id uuid;
  path_order_id uuid;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'invalid rider context';
  end if;
  select * into o from orders where id = p_order_id for update;
  if o.id is null or o.assigned_rider_id is distinct from p_rider_id then
    raise exception 'forbidden';
  end if;
  if o.delivery_status = 'delivered' then
    return o;
  end if;
  if o.delivery_status <> 'arrived' or nullif(trim(p_pod_path), '') is null then
    raise exception 'arrival and POD required';
  end if;

  -- Structural check: the submitted path must be shaped exactly
  -- <p_rider_id>/<p_order_id>/<object>, matching THIS call's own explicit
  -- rider/order pair -- not merely "a well-formed-looking path". A path
  -- that fails to parse as two leading UUID segments is rejected the same
  -- as a structural mismatch, not treated as a different (e.g. legacy)
  -- valid shape.
  begin
    path_rider_id := split_part(p_pod_path, '/', 1)::uuid;
    path_order_id := split_part(p_pod_path, '/', 2)::uuid;
  exception when others then
    raise exception 'invalid POD path';
  end;
  if path_rider_id is distinct from p_rider_id or path_order_id is distinct from p_order_id then
    raise exception 'POD path does not match this delivery';
  end if;

  -- Existence check: the referenced object must genuinely exist in the
  -- private bucket before its path is ever persisted as delivery proof --
  -- a structurally-valid-looking but nonexistent/fabricated path is
  -- rejected here, not trusted on shape alone.
  if not exists (select 1 from storage.objects where bucket_id = 'cefflo-pod' and name = p_pod_path) then
    raise exception 'POD object not found';
  end if;

  update orders set delivery_status = 'delivered', completed_at = now(), updated_at = now() where id = o.id returning * into o;
  update delivery_stops set status = 'delivered', pod_storage_path = p_pod_path, pod_note = p_note, pod_captured_at = now(), pod_submitted_by = auth.uid(), completed_at = now(), updated_at = now() where order_id = o.id;
  update tracking_tokens set expires_at = now() + interval '48 hours' where order_id = o.id;
  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    select o.business_id, o.id, s.id, s.assignment_id, 'delivery.completed', 'arrived', 'delivered', auth.uid(), 'rider', jsonb_build_object('idempotency_key', p_idempotency_key)
    from delivery_stops s where s.order_id = o.id;

  if o.delivery_session_id is not null then
    perform complete_session_if_all_delivered(o.delivery_session_id);
  end if;

  return o;
end;
$$;
revoke all on function public.complete_delivery(uuid, uuid, text, text, text) from public, anon, authenticated;
grant execute on function public.complete_delivery(uuid, uuid, text, text, text) to authenticated;

-- =====================================================================
-- 6. Retire the old ambiguous zero-argument helper. Nothing above still
-- references it -- this is the final step, not a cleanup done in passing.
-- =====================================================================
drop function public.current_rider_id();
