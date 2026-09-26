-- S4-06.7 Batch 1: two Founder-approved local corrections.
--
-- (P2) Backend sequence-lock invariant: for an order that belongs to a
-- session-scoped Run, picked_up -> out_for_delivery (and -> arrived) must
-- not be permitted until this Rider's Run sequence has genuinely been
-- locked via start_run_delivery. Previously this was only a UI convention
-- (start_pickup_run/Start Delivery always called in order by the sanctioned
-- Rider UI) -- rider_transition itself never required it. A standalone
-- order (delivery_session_id is null -- the pre-S4-06 legacy/single-order
-- path) is entirely unaffected: the new check is a no-op whenever the stop
-- has no session.
--
-- (P4) Wave/session lifecycle auto-transitions: delivery_sessions.status
-- previously only ever changed via the Vendor's manual update_session_status
-- call, so a Wave stayed "planned" forever unless a Vendor remembered to
-- touch it. Two small, purely additive, idempotent helpers are added:
-- planned->active the moment any Rider genuinely begins executing the Wave
-- (start_pickup_run), and active/planned->completed only once every order
-- still genuinely relevant to the Wave (attached, and not declined/
-- cancelled) has reached delivered. A Wave with multiple Riders is
-- unaffected by any one Rider finishing early -- the completion check
-- aggregates every relevant order in the whole session, not just the
-- calling Rider's own stops. Both helpers reuse the existing
-- session.status_changed event type (no new event type invented), adding
-- only a metadata.trigger:'auto' field to distinguish them from a Vendor's
-- manual update_session_status call. No new Run/session table.

-- Internal-only: never callable directly by a client. Idempotent (only
-- fires the transition, and its one event, the first time it applies).
create function public.mark_session_active_if_planned(p_delivery_session_id uuid) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_id uuid;
begin
  update delivery_sessions
    set status = 'active', started_at = coalesce(started_at, now()), updated_at = now()
    where id = p_delivery_session_id and status = 'planned'
    returning id into updated_id;

  if updated_id is not null then
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    select business_id, 'session.status_changed', auth.uid(), 'rider',
           jsonb_build_object('delivery_session_id', id, 'status', 'active', 'trigger', 'auto')
    from delivery_sessions where id = updated_id;
  end if;
end;
$$;
revoke all on function public.mark_session_active_if_planned(uuid) from public, anon, authenticated;

-- Internal-only, same style. Locks the session row first (FOR UPDATE) so
-- two Riders finishing their very last stop at the same instant can never
-- both independently conclude "all delivered" and race to mark/complete
-- twice -- the second call's own lock wait resolves against the first
-- call's already-committed 'completed' status and its guard clause below
-- exits as a safe no-op. "Relevant" order = still attached to this session
-- and not declined/cancelled (a LEFT JOIN so an order attached but never
-- yet assigned to any Rider still correctly blocks completion, rather than
-- being silently invisible to the count). A session already 'cancelled' by
-- the Vendor is a terminal Vendor override this never fights.
create function public.complete_session_if_all_delivered(p_delivery_session_id uuid) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  s delivery_sessions;
  relevant_total int;
  relevant_delivered int;
begin
  select * into s from delivery_sessions where id = p_delivery_session_id for update;
  if s.id is null or s.status not in ('planned','active') then
    return;
  end if;

  select count(*), count(*) filter (where o.delivery_status = 'delivered')
    into relevant_total, relevant_delivered
    from orders o
    left join delivery_stops st on st.order_id = o.id
    left join rider_assignments a on a.id = st.assignment_id
    where o.delivery_session_id = s.id
      and (a.status is null or a.status not in ('declined','cancelled'));

  if relevant_total = 0 or relevant_delivered <> relevant_total then
    return;
  end if;

  update delivery_sessions
    set status = 'completed', completed_at = coalesce(completed_at, now()), updated_at = now()
    where id = s.id;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (s.business_id, 'session.status_changed', auth.uid(), 'rider',
            jsonb_build_object('delivery_session_id', s.id, 'status', 'completed', 'trigger', 'auto'));
end;
$$;
revoke all on function public.complete_session_if_all_delivered(uuid) from public, anon, authenticated;

-- start_pickup_run: unchanged in every existing respect, one new line
-- calling the 'active' helper right before returning success. Safe to call
-- on every invocation (including a second/third Rider's own Start Pickup in
-- the same Wave, or a duplicate call) -- the helper's own guard makes this
-- a no-op once the Wave is already active.
create or replace function public.start_pickup_run(p_delivery_session_id uuid) returns jsonb
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

  perform mark_session_active_if_planned(p_delivery_session_id);

  return jsonb_build_object('delivery_session_id', p_delivery_session_id, 'pickup_started', true);
end;
$$;

-- rider_transition: one new additive check, inserted into the existing
-- p_next in ('out_for_delivery','arrived') block, reusing the same
-- my_session/my_locked variables that block already fetches. Every other
-- existing check (exact-rider authorization, accepted-assignment gate, the
-- linear transition graph, the post-lock "complete earlier stop first"
-- ordering check, the update/event statements) is preserved byte-for-byte.
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

    -- P2: a session-scoped Run's stops must already be locked (i.e. this
    -- Rider must already have called start_run_delivery for this Wave)
    -- before any of them can move past picked_up. A standalone order
    -- (my_session is null) never had a session to lock -- no-op for it,
    -- preserving single-order/legacy compatibility exactly as before.
    if my_session is not null and my_locked is null then
      raise exception 'sequence not locked';
    end if;

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

-- complete_delivery: unchanged in every existing respect, two new lines
-- (session lookup + the completion helper call) inserted right before the
-- final return. A standalone order (delivery_session_id is null) never
-- calls the helper at all.
create or replace function public.complete_delivery(p_order_id uuid, p_pod_path text, p_note text default '', p_idempotency_key text default null) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  rid uuid;
begin
  rid = current_rider_id();
  select * into o from orders where id = p_order_id for update;
  if o.id is null or rid is null or o.assigned_rider_id is distinct from rid then
    raise exception 'forbidden';
  end if;
  if o.delivery_status = 'delivered' then
    return o;
  end if;
  if o.delivery_status <> 'arrived' or nullif(trim(p_pod_path), '') is null then
    raise exception 'arrival and POD required';
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
