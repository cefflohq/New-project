-- S4-11 Batch 11 (Grow V1 Flow 2 continuation): fix a real gap in
-- initiate_delivery_recovery's valid FROM-states, caught by browser
-- validation (Puppeteer), not by inspection.
--
-- The Batch 9 migration comment stated the intent clearly: "Valid FROM
-- states: assigned-but-not-yet-executing through mid-run through already-
-- flagged-issue." But build_rider_run/assign_rider never change
-- delivery_status -- an order sits at 'created' WITH a Rider assigned
-- until the Rider's own first rider_transition call moves it to
-- 'ready_for_pickup'. That exact "assigned but not yet executing" window
-- is 'created' + assigned_rider_id set, which the Batch 9 code's checked-
-- state list omitted (it started at 'ready_for_pickup'), contradicting
-- its own stated intent. A real, common recovery scenario -- a Rider
-- becomes unavailable after being assigned but before starting the run --
-- was silently unrecoverable. Fixed by adding 'created' to the list; the
-- separate assigned_rider_id is-null check just above already guarantees
-- this only matches a genuinely assigned order, not a fresh, never-
-- planned one.

create or replace function public.initiate_delivery_recovery(
  p_order_id uuid,
  p_reason public.delivery_issue_reason,
  p_rider_id uuid default null,
  p_note text default '',
  p_idempotency_key uuid default null
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  st delivery_stops;
  actor_role text;
  old_status public.delivery_status;
  old_assignment_id uuid;
  old_rider_id uuid;
  existing_event delivery_events;
begin
  if p_idempotency_key is not null then
    select * into existing_event
      from delivery_events
      where event_type = 'delivery.recovery_initiated' and (metadata->>'idempotency_key')::uuid = p_idempotency_key
      limit 1;
    if existing_event.id is not null then
      if existing_event.order_id <> p_order_id then
        raise exception 'idempotency key conflict';
      end if;
      select * into o from orders where id = p_order_id;
      if not (is_business_member(o.business_id) or (p_rider_id is not null and is_current_rider(p_rider_id))) then
        raise exception 'forbidden';
      end if;
      return o;
    end if;
  end if;

  select * into o from orders where id = p_order_id for update;
  if o.id is null then
    raise exception 'order not found';
  end if;

  if is_business_member(o.business_id) then
    actor_role := 'vendor';
  elsif p_rider_id is not null and is_current_rider(p_rider_id) and o.assigned_rider_id = p_rider_id then
    actor_role := 'rider';
  else
    raise exception 'forbidden';
  end if;

  if o.assigned_rider_id is null then
    raise exception 'no active assignment to recover from';
  end if;
  if o.delivery_status not in ('created','ready_for_pickup','picked_up','out_for_delivery','arrived','issue') then
    raise exception 'delivery not in a recoverable state (%)', o.delivery_status;
  end if;

  select * into st from delivery_stops where order_id = o.id for update;
  old_status := o.delivery_status;
  old_assignment_id := st.assignment_id;
  old_rider_id := o.assigned_rider_id;

  if old_assignment_id is not null then
    update rider_assignments set status = 'cancelled', updated_at = now() where id = old_assignment_id;
  end if;

  update orders set
    delivery_status = 'created',
    assigned_rider_id = null,
    completed_at = null,
    updated_at = now()
  where id = o.id
  returning * into o;

  update delivery_stops set
    assignment_id = null,
    rider_id = null,
    sequence = null,
    sequence_locked_at = null,
    status = 'created',
    arrived_at = null,
    updated_at = now()
  where id = st.id;

  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    values (o.business_id, o.id, st.id, old_assignment_id, 'delivery.recovery_initiated', old_status, 'created', auth.uid(), actor_role,
            jsonb_build_object(
              'reason', p_reason, 'note', p_note, 'idempotency_key', p_idempotency_key,
              'previous_rider_id', old_rider_id, 'previous_assignment_id', old_assignment_id
            ));

  return o;
end;
$$;
