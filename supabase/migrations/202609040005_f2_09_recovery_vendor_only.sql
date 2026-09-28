-- CEFFLO Flow 2 Canonical Backend Completion Master -- Founder closure
-- decision: "reassignment/recovery ownership changes are Vendor-authorized
-- only; Rider may report an issue/request assistance but must not
-- independently release/reassign the order."
--
-- Supersedes 202609030011_s4_11_batch_11_recovery_created_state_fix.sql's
-- initiate_delivery_recovery, which (from the earlier, now-superseded A6
-- session phase) let the currently-assigned Rider themselves trigger
-- recovery via a Rider-supplied p_rider_id. That branch is removed
-- entirely, not merely gated further -- only is_business_operational(...)
-- (Owner/Operator, matching every other dispatch-authority RPC:
-- assign_rider, reassign_rider, build_rider_run, approve_order -- Helper
-- deliberately excluded per the S4-11 Batch 10 permission audit) can
-- authorize a call now. p_rider_id is dropped from the signature (no
-- longer meaningful input, not merely ignored) -- a plain CREATE OR
-- REPLACE is used since removing a parameter still changes the argument
-- list, so the old 5-arg overload is dropped first.
--
-- The Rider's legitimate channel is unchanged and untouched:
-- rider_report_delivery_issue ("report an issue / request assistance") --
-- this migration narrows initiate_delivery_recovery only, nothing else in
-- Recovery V1 is broadened or altered (idempotency-ledger replay,
-- rider_assignments cancellation, delivery_stops reset, and the
-- delivery.recovery_initiated audit event all keep their exact prior
-- behavior for the Vendor path).

drop function if exists public.initiate_delivery_recovery(uuid, public.delivery_issue_reason, uuid, text, uuid);

create function public.initiate_delivery_recovery(
  p_order_id uuid,
  p_reason public.delivery_issue_reason,
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
      if not is_business_operational(o.business_id) then
        raise exception 'forbidden';
      end if;
      return o;
    end if;
  end if;

  select * into o from orders where id = p_order_id for update;
  if o.id is null then
    raise exception 'order not found';
  end if;

  if not is_business_operational(o.business_id) then
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
    values (o.business_id, o.id, st.id, old_assignment_id, 'delivery.recovery_initiated', old_status, 'created', auth.uid(), 'vendor',
            jsonb_build_object(
              'reason', p_reason, 'note', p_note, 'idempotency_key', p_idempotency_key,
              'previous_rider_id', old_rider_id, 'previous_assignment_id', old_assignment_id
            ));

  return o;
end;
$$;

revoke all on function public.initiate_delivery_recovery(uuid, public.delivery_issue_reason, text, uuid) from public, anon;
grant execute on function public.initiate_delivery_recovery(uuid, public.delivery_issue_reason, text, uuid) to authenticated;
