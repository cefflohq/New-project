-- S4-06 Batch 4: Run-level Accept/Decline + safe Rider reassignment
-- correction. Purely additive on top of S4-05.4 (per-order accept/decline,
-- unchanged) and S4-06.1/.2/.3 (sessions, sequencing, zones -- all
-- structurally uninvolved here except the one already-approved sequence
-- reset). No new schema, no new table.

-- ACCEPT RUN: exact-Rider, session-scoped, atomic, partial-tolerant across
-- mixed assignment states. Reuses the exact 'assignment.accepted' event
-- type accept_assignment already uses -- provenance distinguished only via
-- metadata.via, so any query by event_type sees one consistent picture.
create function public.accept_run(p_delivery_session_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  rid uuid;
  newly_accepted_count int;
  already_accepted_count int;
  skipped_count int;
begin
  rid := current_rider_id();
  if rid is null then
    raise exception 'forbidden';
  end if;

  if not exists (
    select 1 from rider_assignments where rider_id = rid and delivery_session_id = p_delivery_session_id
  ) then
    raise exception 'no assignments in this run';
  end if;

  select count(*) into already_accepted_count
    from rider_assignments
    where rider_id = rid and delivery_session_id = p_delivery_session_id and status = 'accepted';

  select count(*) into skipped_count
    from rider_assignments
    where rider_id = rid and delivery_session_id = p_delivery_session_id
      and status not in ('assigned','accepted');

  with newly_accepted as (
    update rider_assignments a
    set status = 'accepted', accepted_at = now(), updated_at = now()
    where a.rider_id = rid and a.delivery_session_id = p_delivery_session_id and a.status = 'assigned'
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

-- DECLINE RUN: symmetric. No decline reason (Founder decision: keep
-- symmetrical with decline_assignment's existing no-reason contract).
create function public.decline_run(p_delivery_session_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  rid uuid;
  newly_declined_count int;
  already_declined_count int;
  skipped_count int;
begin
  rid := current_rider_id();
  if rid is null then
    raise exception 'forbidden';
  end if;

  if not exists (
    select 1 from rider_assignments where rider_id = rid and delivery_session_id = p_delivery_session_id
  ) then
    raise exception 'no assignments in this run';
  end if;

  select count(*) into already_declined_count
    from rider_assignments
    where rider_id = rid and delivery_session_id = p_delivery_session_id and status = 'declined';

  select count(*) into skipped_count
    from rider_assignments
    where rider_id = rid and delivery_session_id = p_delivery_session_id
      and status not in ('assigned','declined');

  with newly_declined as (
    update rider_assignments a
    set status = 'declined', updated_at = now()
    where a.rider_id = rid and a.delivery_session_id = p_delivery_session_id and a.status = 'assigned'
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

revoke all on function public.accept_run(uuid) from public, anon, authenticated;
grant execute on function public.accept_run(uuid) to authenticated;
revoke all on function public.decline_run(uuid) from public, anon, authenticated;
grant execute on function public.decline_run(uuid) to authenticated;

-- REASSIGN_RIDER correction: same signature as the S4-03 original (no
-- DROP+CREATE needed -- the parameter list is unchanged, only the body).
-- Acceptance belongs to the Rider who gave it -- a genuine reassignment
-- must never let the new Rider inherit it. Allowed only strictly
-- pre-pickup; denied from picked_up onward (the goods are already in a
-- specific Rider's physical possession) and for cancelled; issue-state
-- handling remains S4-08. The sequence_locked_at check is explicit
-- defense-in-depth -- the existing delivery_status gate already makes a
-- locked stop transitively unreachable here (locking requires all-picked-up
-- first, which is already past this function's allowed window), but the
-- check is added anyway per Founder decision, matching this project's
-- established style of explicit, layered guards.
create or replace function public.reassign_rider(p_order_id uuid, p_new_rider_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
  old_rider_id uuid;
begin
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not public.is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;

  if o.delivery_status not in ('created', 'ready_for_pickup') then
    raise exception 'reassignment not allowed after pickup';
  end if;

  if exists (
    select 1 from public.delivery_stops where order_id = o.id and sequence_locked_at is not null
  ) then
    raise exception 'reassignment not allowed after pickup';
  end if;

  if not exists (
    select 1 from public.riders
    where id = p_new_rider_id
      and business_id = o.business_id
      and status = 'active'
  ) then
    raise exception 'invalid rider';
  end if;

  old_rider_id := o.assigned_rider_id;

  -- Same-Rider reassignment: true no-op. No reset, no event.
  if old_rider_id = p_new_rider_id then
    return o;
  end if;

  update public.orders
  set assigned_rider_id = p_new_rider_id, updated_at = now()
  where id = o.id
  returning * into o;

  -- Acceptance reset: status back to 'assigned', accepted_at cleared --
  -- the new Rider must explicitly accept (individually or via accept_run).
  -- Reassigning back to a previously assigned Rider goes through this exact
  -- same path -- no historical acceptance is ever restored.
  update public.rider_assignments
  set rider_id = p_new_rider_id, status = 'assigned', accepted_at = null, updated_at = now()
  where business_id = o.business_id
    and rider_id = old_rider_id
    and status not in ('completed', 'cancelled')
    and id in (
      select assignment_id from public.delivery_stops where order_id = o.id
    );

  -- Sequence reset for the reassigned stop only. Any other, unaffected
  -- stops in the old or new Rider's own run keep their existing sequence
  -- values unchanged -- gaps this creates (e.g. 1,3 after removing 2) are
  -- valid and do not need renumbering (S4-06.2's sequencing logic only
  -- requires non-null, mutually distinct values, not a contiguous range).
  update public.delivery_stops
  set rider_id = p_new_rider_id, sequence = null, updated_at = now()
  where order_id = o.id;

  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role, metadata)
  select o.business_id, o.id, s.id, s.assignment_id, 'rider.reassigned', auth.uid(), 'vendor',
         jsonb_build_object('from_rider_id', old_rider_id, 'to_rider_id', p_new_rider_id)
  from public.delivery_stops s where s.order_id = o.id;

  return o;
end;
$$;
