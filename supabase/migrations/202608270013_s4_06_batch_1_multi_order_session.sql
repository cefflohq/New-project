-- S4-06 Batch 1: multi-order session foundation.
--
-- Reconciliation (this batch made NO other backend change): the existing
-- S4-05.3 schema already fully supports multiple same-business orders
-- belonging to one session -- orders.delivery_session_id carries no unique
-- constraint, and attach_order_to_session already independently verifies
-- both the order and the session belong to the same business before
-- attaching. Repeated single-order attach_order_to_session calls are
-- therefore sufficient: session membership is an independent per-order fact
-- with no cross-order invariant that would require a new atomic bulk RPC --
-- "the smallest robust contract" is the one that already exists, used
-- repeatedly. No bulk/multi-order RPC is added.
--
-- The one real gap found: attach_order_to_session was not idempotent --
-- calling it again with the SAME target session_id (or NULL, if already
-- detached) re-recorded a duplicate session.order_attached/detached event
-- every time, unlike every other mutation in this project (approve_order,
-- accept_assignment, reassign_rider's same-rider case). Fixed with a single
-- no-op guard, matching that established idiom exactly. No schema change.
create or replace function public.attach_order_to_session(
  p_order_id uuid,
  p_delivery_session_id uuid
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  s delivery_sessions;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;
  if p_delivery_session_id is not null then
    select * into s from delivery_sessions where id = p_delivery_session_id;
    if s.id is null or s.business_id is distinct from o.business_id then
      raise exception 'invalid session';
    end if;
  end if;
  if o.delivery_session_id is not distinct from p_delivery_session_id then
    return o;
  end if;
  update orders set delivery_session_id = p_delivery_session_id, updated_at = now()
    where id = o.id
    returning * into o;
  insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role, metadata)
    values (
      o.business_id, o.id,
      case when p_delivery_session_id is null then 'session.order_detached' else 'session.order_attached' end,
      auth.uid(), 'vendor',
      jsonb_build_object('delivery_session_id', p_delivery_session_id)
    );
  return o;
end;
$$;
