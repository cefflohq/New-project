-- S4-11 Batch 9 (Grow V1 Flow 2, A6): Recovery / Reschedule V1.
--
-- Flow 1 finding (audit report §11): zero matches for "reschedule" across
-- every migration; docs/cefflo/DECISION_REPORT_ISSUE_RESCHEDULE.md
-- documents this as a real open gap. Founder Gate decision, locked at
-- scope freeze (scope-lock §4/§16): narrow operational recovery only, not
-- a calendar/scheduling system. Required behavior, verbatim:
--   - trigger when delivery cannot be completed as planned (or enters a
--     qualifying delivery exception);
--   - preserve original delivery/run history, never silently overwrite;
--   - create an auditable recovery/reschedule event;
--   - safely return the affected work to planning for a replacement/
--     future attempt;
--   - reuse delivery_events/issue-reason architecture where appropriate.
--
-- History preservation model: the OLD rider_assignments row is never
-- deleted or repurposed -- its status moves to 'cancelled' (an existing,
-- valid assignment_status value), so it permanently remains a truthful
-- record of "this Rider was assigned, this is what happened to that
-- assignment." delivery_stops is reset the same way every other lifecycle
-- transition in this schema already mutates it in place (rider_transition
-- does the same) -- the permanent, append-only historical record has
-- always been delivery_events, not delivery_stops itself.
--
-- Rider identity: p_rider_id + is_current_rider(), not the removed
-- single-tenant current_rider_id() -- matching rider_report_delivery_issue
-- and every other Rider-facing RPC since S4-07 Batch 3a's multi-business
-- Rider identity change (a Rider's auth account can hold a distinct riders
-- row per business, so the caller must say which one it's acting as).

create unique index recovery_idempotency_key_idx
  on public.delivery_events ((metadata->>'idempotency_key'))
  where event_type = 'delivery.recovery_initiated';

-- Callable by a business member (Owner/Operator -- matches
-- vendor_report_delivery_issue's own "any active member" precedent, this
-- is at least as sensitive but not more) OR the currently assigned Rider,
-- identified explicitly via p_rider_id (matches
-- rider_report_delivery_issue's precedent exactly). p_rider_id is null for
-- a Vendor-initiated call. Valid FROM states: assigned-but-not-yet-
-- executing through mid-run through already-flagged-issue; NOT valid from
-- 'created' (nothing assigned to recover from) nor from the terminal
-- 'delivered'/'cancelled'.
create function public.initiate_delivery_recovery(
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
  if o.delivery_status not in ('ready_for_pickup','picked_up','out_for_delivery','arrived','issue') then
    raise exception 'delivery not in a recoverable state (%)', o.delivery_status;
  end if;

  select * into st from delivery_stops where order_id = o.id for update;
  old_status := o.delivery_status;
  old_assignment_id := st.assignment_id;
  old_rider_id := o.assigned_rider_id;

  -- Preserve history: the assignment row itself is never deleted or
  -- reused -- only its status moves to 'cancelled', permanently recording
  -- that this Rider was assigned and what became of it.
  if old_assignment_id is not null then
    update rider_assignments set status = 'cancelled', updated_at = now() where id = old_assignment_id;
  end if;

  -- Return the order to planning: same eligibility shape build_rider_run
  -- already requires (delivery_status = 'created', assigned_rider_id null)
  -- -- approval and preparation truth are untouched, since neither needs
  -- to be redone for a re-plan.
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

revoke all on function public.initiate_delivery_recovery(uuid, public.delivery_issue_reason, uuid, text, uuid) from public, anon;
grant execute on function public.initiate_delivery_recovery(uuid, public.delivery_issue_reason, uuid, text, uuid) to authenticated;
