-- S4-05 Batch 4: Rider assignment Accept/Decline backend lifecycle.
-- Founder-locked rule: creating an assignment does NOT mean the Rider
-- accepted it. assign_rider already creates a rider_assignments row with
-- status defaulting to 'assigned' (pending) -- untouched by this batch.
--
-- Reconciliation finding: assignment_status has no value representing a
-- Rider decline. Reusing 'cancelled' would collide with S4-08's future
-- typed-exception/cancel workflow (a different actor/reason, deliberately
-- reserved). The smallest correct fix is one new, dedicated enum value.
alter type public.assignment_status add value 'declined';

-- Reconciliation note: reassign_rider (S4-03 Batch 1) UPDATEs the existing
-- rider_assignments row in place (found via delivery_stops.assignment_id)
-- rather than creating a new one -- so "the current assignment for this
-- order" is always resolved the same way here. reassign_rider does not
-- reset status/accepted_at when moving to a new rider (pre-existing
-- behavior, unmodified) -- a session/reassignment-recovery concern
-- explicitly out of this batch's scope, not fixed here.

-- ACCEPT: only the actually assigned, active, authenticated Rider. Reuses
-- the exact same current_rider_id() + `is distinct from` invariant already
-- established by rider_transition/complete_delivery (S4-03) -- not
-- weakened, not duplicated with different logic. Idempotent: accepting an
-- already-accepted assignment is a no-op return, matching the existing
-- approve_order/complete_delivery style. Accepting after a decline (or from
-- any state other than the pending 'assigned') is rejected.
create function public.accept_assignment(p_order_id uuid) returns public.rider_assignments
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  a rider_assignments;
  rid uuid;
begin
  rid := current_rider_id();
  select * into o from orders where id = p_order_id for update;
  if o.id is null or rid is null or o.assigned_rider_id is distinct from rid then
    raise exception 'forbidden';
  end if;
  select ra.* into a from rider_assignments ra
    join delivery_stops s on s.assignment_id = ra.id
    where s.order_id = o.id
    for update;
  if a.id is null or a.rider_id is distinct from rid then
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

-- DECLINE: same authorization invariant as ACCEPT. Records the decline
-- authoritatively (status + event) but does not touch orders.assigned_rider_id
-- or delivery_stops -- no automatic reassignment, no session-recovery
-- semantics; the Vendor must separately act (e.g. via the existing
-- reassign_rider) on a declined assignment, exactly as instructed. Declining
-- after an accept (or from any state other than 'assigned') is rejected.
-- Declining twice is a safe idempotent no-op, matching ACCEPT's style.
create function public.decline_assignment(p_order_id uuid) returns public.rider_assignments
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  a rider_assignments;
  rid uuid;
begin
  rid := current_rider_id();
  select * into o from orders where id = p_order_id for update;
  if o.id is null or rid is null or o.assigned_rider_id is distinct from rid then
    raise exception 'forbidden';
  end if;
  select ra.* into a from rider_assignments ra
    join delivery_stops s on s.assignment_id = ra.id
    where s.order_id = o.id
    for update;
  if a.id is null or a.rider_id is distinct from rid then
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

revoke all on function public.accept_assignment(uuid) from public, anon, authenticated;
grant execute on function public.accept_assignment(uuid) to authenticated;
revoke all on function public.decline_assignment(uuid) from public, anon, authenticated;
grant execute on function public.decline_assignment(uuid) to authenticated;

-- Gate: a Rider who has not accepted the assignment must not be able to
-- begin (or continue) the delivery lifecycle. Exactly one new check added
-- right after the existing, untouched authorization check -- the S4-03
-- exact-rider invariant (`is distinct from`) is preserved byte-for-byte,
-- not weakened. complete_delivery is not modified: an order can only ever
-- reach 'arrived' via this function, so it is already transitively gated --
-- adding the same check there would be redundant, not a new safeguard.
create or replace function public.rider_transition(p_order_id uuid,p_next public.delivery_status,p_idempotency_key text default null) returns public.orders language plpgsql security definer set search_path=public as $$declare o orders;old delivery_status;ok boolean;rid uuid;a_status assignment_status;begin rid=current_rider_id();select * into o from orders where id=p_order_id for update;if o.id is null or rid is null or o.assigned_rider_id is distinct from rid then raise exception 'forbidden';end if;select a.status into a_status from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=o.id;if a_status is distinct from 'accepted' then raise exception 'assignment not accepted';end if;old=o.delivery_status;if old=p_next then return o;end if;ok=(old='created' and p_next='ready_for_pickup')or(old='ready_for_pickup' and p_next='picked_up')or(old='picked_up' and p_next='out_for_delivery')or(old='out_for_delivery' and p_next='arrived');if not ok then raise exception 'invalid transition % -> %',old,p_next;end if;update orders set delivery_status=p_next,updated_at=now() where id=o.id returning * into o;update delivery_stops set status=p_next,arrived_at=case when p_next='arrived' then now() else arrived_at end,updated_at=now() where order_id=o.id;insert into delivery_events(business_id,order_id,delivery_stop_id,assignment_id,event_type,from_status,to_status,actor_user_id,actor_role,metadata)select o.business_id,o.id,s.id,s.assignment_id,'delivery.status_changed',old,p_next,auth.uid(),'rider',jsonb_build_object('idempotency_key',p_idempotency_key) from delivery_stops s where s.order_id=o.id;return o;end$$;
