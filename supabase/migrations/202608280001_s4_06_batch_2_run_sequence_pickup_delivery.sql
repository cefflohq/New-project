-- S4-06 Batch 2: Rider multi-stop Plan Route / Pickup Checklist / Delivery
-- Run backend contract. Builds strictly on S4-05 (approval/acceptance) and
-- S4-06.1 (session/order attachment). No Vendor/Rider UI change, no
-- reassign_rider change (that correction remains S4-06.4), no notification
-- sending/provider integration (run.delivery_started is only the future
-- trigger fact -- nothing consumes it yet).
--
-- "Eligible" stops, used consistently by every function below, means: this
-- rider's own delivery_stops for the given session, whose assignment has
-- NOT reached a terminal/excluded state (declined, cancelled, completed,
-- issue). Declined assignments are never part of an active run, matching
-- the exclusion already established in Rider UI (S4-05.5).

-- delivery_stops.sequence becomes the sole authoritative sequence source.
-- orders.delivery_sequence is left untouched and unused -- no migration or
-- drop of it in this batch.
alter table public.delivery_stops
  add column sequence_locked_at timestamptz;

-- Rider-editable pre-run drag/drop ordering. Requires the complete, exact
-- eligible-stop set (no missing/extra/duplicate order ids) -- this is the
-- one place in S4-06 where a bulk RPC is genuinely justified, since
-- renumbering a whole ordering is not decomposable into independent
-- per-order calls the way session attachment was (S4-06.1). Idempotent:
-- resubmitting the exact same order leaves everything untouched and
-- records no event.
create function public.save_run_sequence(
  p_delivery_session_id uuid,
  p_ordered_order_ids uuid[]
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  rid uuid;
  locked_count int;
  eligible_count int;
  provided_count int;
  distinct_provided_count int;
  mismatch_count int;
  unchanged_count int;
begin
  rid := current_rider_id();
  if rid is null then
    raise exception 'forbidden';
  end if;

  select count(*) into locked_count
    from delivery_stops s
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = rid
      and a.delivery_session_id = p_delivery_session_id
      and a.status not in ('declined','cancelled','completed','issue')
      and s.sequence_locked_at is not null;
  if locked_count > 0 then
    raise exception 'sequence locked';
  end if;

  select count(*) into eligible_count
    from delivery_stops s
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = rid
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
      where a.rider_id = rid
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
  where a.rider_id = rid
    and a.delivery_session_id = p_delivery_session_id
    and s.order_id = any(p_ordered_order_ids);
end;
$$;

-- Slide to Start Pickup: a factual marker only. Never touches orders/
-- delivery_stops -- cannot fabricate a pickup confirmation. Idempotency
-- achieved by locking this rider's own assignment rows (already needed to
-- inspect them) before checking/recording the event, serializing any
-- concurrent duplicate calls -- no new persistent status column needed.
create function public.start_pickup_run(p_delivery_session_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  rid uuid;
  biz_id uuid;
  pending_count int;
  existing_event_id bigint;
begin
  rid := current_rider_id();
  if rid is null then
    raise exception 'forbidden';
  end if;

  perform 1 from rider_assignments a
    where a.rider_id = rid and a.delivery_session_id = p_delivery_session_id
    for update;

  select business_id into biz_id from rider_assignments
    where rider_id = rid and delivery_session_id = p_delivery_session_id
    limit 1;
  if biz_id is null then
    raise exception 'no assignments in this run';
  end if;

  select count(*) into pending_count
    from rider_assignments a
    where a.rider_id = rid and a.delivery_session_id = p_delivery_session_id
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
            jsonb_build_object('delivery_session_id', p_delivery_session_id, 'rider_id', rid));
  end if;

  return jsonb_build_object('delivery_session_id', p_delivery_session_id, 'pickup_started', true);
end;
$$;

-- Slide to Start Delivery: requires every eligible order already physically
-- picked up (delivery_status past created/ready_for_pickup) AND a complete,
-- valid saved sequence (every eligible stop sequenced, no gaps/duplicates).
-- On success, atomically locks this rider's sequence for this session and
-- records both the per-stop lock history and the single canonical
-- run.delivery_started trigger event. Idempotent: calling again once
-- already locked is a no-op success, not an error.
create function public.start_run_delivery(p_delivery_session_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  rid uuid;
  biz_id uuid;
  not_picked_up_count int;
  eligible_count int;
  sequenced_count int;
  distinct_sequence_count int;
begin
  rid := current_rider_id();
  if rid is null then
    raise exception 'forbidden';
  end if;

  perform 1 from rider_assignments a
    where a.rider_id = rid and a.delivery_session_id = p_delivery_session_id
    for update;

  select business_id into biz_id from rider_assignments
    where rider_id = rid and delivery_session_id = p_delivery_session_id
    limit 1;
  if biz_id is null then
    raise exception 'no assignments in this run';
  end if;

  if exists (
    select 1 from delivery_stops s
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = rid
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
    where a.rider_id = rid
      and a.delivery_session_id = p_delivery_session_id
      and a.status not in ('declined','cancelled','completed','issue')
      and o.delivery_status in ('created','ready_for_pickup');
  if not_picked_up_count > 0 then
    raise exception 'pickup incomplete';
  end if;

  select count(*) into eligible_count
    from delivery_stops s
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = rid
      and a.delivery_session_id = p_delivery_session_id
      and a.status not in ('declined','cancelled','completed','issue');

  select count(*), count(distinct sequence) into sequenced_count, distinct_sequence_count
    from delivery_stops s
    join rider_assignments a on a.id = s.assignment_id
    where a.rider_id = rid
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
      and a.rider_id = rid
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
         jsonb_build_object('delivery_session_id', p_delivery_session_id, 'rider_id', rid)
  where exists (select 1 from locked);

  return jsonb_build_object('delivery_session_id', p_delivery_session_id, 'sequence_locked', true, 'already_locked', false);
end;
$$;

revoke all on function public.save_run_sequence(uuid,uuid[]) from public, anon, authenticated;
grant execute on function public.save_run_sequence(uuid,uuid[]) to authenticated;
revoke all on function public.start_pickup_run(uuid) from public, anon, authenticated;
grant execute on function public.start_pickup_run(uuid) to authenticated;
revoke all on function public.start_run_delivery(uuid) from public, anon, authenticated;
grant execute on function public.start_run_delivery(uuid) to authenticated;

-- rider_transition: one additive block. Every existing check (exact-rider
-- authorization, S4-05.4 assignment-accepted gate, the linear transition
-- graph, the update/event statements) is preserved in full effect --
-- reformatted to multi-line for readability given the size of the addition,
-- not redesigned. The new check applies only to the delivery-execution
-- transitions (out_for_delivery/arrived), only when this specific stop has
-- been locked -- inert for every unlocked stop, including every
-- single-order delivery today. Pickup-phase transitions remain unordered.
create or replace function public.rider_transition(p_order_id uuid, p_next public.delivery_status, p_idempotency_key text default null)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  old delivery_status;
  ok boolean;
  rid uuid;
  a_status assignment_status;
  my_seq int;
  my_locked timestamptz;
  my_session uuid;
  incomplete_earlier int;
begin
  rid = current_rider_id();
  select * into o from orders where id = p_order_id for update;
  if o.id is null or rid is null or o.assigned_rider_id is distinct from rid then
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
    if my_locked is not null then
      select count(*) into incomplete_earlier
        from delivery_stops s2
        join rider_assignments a2 on a2.id = s2.assignment_id
        join orders o2 on o2.id = s2.order_id
        where a2.rider_id = rid
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
