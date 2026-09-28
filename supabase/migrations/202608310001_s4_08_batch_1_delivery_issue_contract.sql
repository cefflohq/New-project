-- S4-08 Batch 1: minimum authoritative delivery-issue contract.
--
-- Audit-confirmed root cause (S4-08-CANONICAL-ACCEPTANCE-AUDIT-01): both
-- delivery_status and assignment_status have carried an 'issue' value since
-- the foundation migration, but no RPC anywhere in this schema's history has
-- ever produced it. Current Vendor/Rider "Report Issue" UI therefore mutates
-- local client-only state and shows a false success toast -- a canonical
-- S4-08 acceptance blocker (exceptions must be authoritative/audited; no
-- reachable false operational success). This migration closes only that
-- backend gap -- frontend rewiring is a separate, later task.
--
-- Deliberately out of scope here (not guessed at from a UI mockup): a
-- cancellation workflow, redelivery, real phone/WhatsApp contact tracking,
-- address editing, and a Rider breakdown/pause workflow all reuse or extend
-- this same 'issue' foundation later; inventing them now would be
-- speculative. Only the single 'issue' transition itself is closed here.

-- Real machine-readable typing, not an arbitrary client-supplied string --
-- matches this schema's existing convention (member_role, rider_status,
-- delivery_status and assignment_status are all real enums, never a
-- text+check substitute). Exactly the five launch-critical categories the
-- audit identified from the current Vendor/Rider "Report Issue" reason
-- lists; no speculative categories added.
create type public.delivery_issue_reason as enum (
  'customer_unreachable',
  'address_problem',
  'access_problem',
  'vendor_not_ready',
  'rider_unable_to_proceed'
);

-- Vendor-side report. Any active business member (Owner or Operator/Staff)
-- -- matching create_delivery/assign_rider's own existing "any member"
-- authority precedent, not Owner-only; reporting an operational problem is
-- not the more sensitive Team/Rider-invitation class of action.
--
-- Transition matrix (deliberately explicit, not inferred): created,
-- ready_for_pickup, picked_up, out_for_delivery and arrived may all report
-- an issue -- these are exactly the active pre-completion states. Already
-- 'issue' is a safe idempotent no-op (matching rider_transition's own
-- old = p_next precedent), never a duplicate audit event. 'delivered' and
-- 'cancelled' are terminal and must never regress into 'issue'.
create function public.vendor_report_delivery_issue(
  p_order_id uuid,
  p_reason_type public.delivery_issue_reason,
  p_note text default null
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  old delivery_status;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;

  old := o.delivery_status;
  if old = 'issue' then
    return o;
  end if;
  if old not in ('created','ready_for_pickup','picked_up','out_for_delivery','arrived') then
    raise exception 'invalid transition % -> issue', old;
  end if;

  update orders set delivery_status = 'issue', updated_at = now() where id = o.id returning * into o;
  update delivery_stops set status = 'issue', updated_at = now() where order_id = o.id;

  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    select o.business_id, o.id, s.id, s.assignment_id, 'delivery.issue_reported', old, 'issue', auth.uid(), 'vendor',
           jsonb_build_object('reason_type', p_reason_type::text, 'note', nullif(trim(coalesce(p_note, '')), ''))
    from delivery_stops s where s.order_id = o.id;

  return o;
end;
$$;
revoke all on function public.vendor_report_delivery_issue(uuid, public.delivery_issue_reason, text) from public, anon, authenticated;
grant execute on function public.vendor_report_delivery_issue(uuid, public.delivery_issue_reason, text) to authenticated;

-- Rider-side report. Reuses the exact same identity/tenancy/accepted-
-- assignment invariant rider_transition (S4-07.3a) already established --
-- not weakened, not duplicated with different logic. Same transition
-- matrix and idempotency rule as the Vendor-side function above.
create function public.rider_report_delivery_issue(
  p_rider_id uuid,
  p_order_id uuid,
  p_reason_type public.delivery_issue_reason,
  p_note text default null
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  old delivery_status;
  a_status assignment_status;
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

  old := o.delivery_status;
  if old = 'issue' then
    return o;
  end if;
  if old not in ('created','ready_for_pickup','picked_up','out_for_delivery','arrived') then
    raise exception 'invalid transition % -> issue', old;
  end if;

  update orders set delivery_status = 'issue', updated_at = now() where id = o.id returning * into o;
  update delivery_stops set status = 'issue', updated_at = now() where order_id = o.id;

  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    select o.business_id, o.id, s.id, s.assignment_id, 'delivery.issue_reported', old, 'issue', auth.uid(), 'rider',
           jsonb_build_object('reason_type', p_reason_type::text, 'note', nullif(trim(coalesce(p_note, '')), ''))
    from delivery_stops s where s.order_id = o.id;

  return o;
end;
$$;
revoke all on function public.rider_report_delivery_issue(uuid, uuid, public.delivery_issue_reason, text) from public, anon, authenticated;
grant execute on function public.rider_report_delivery_issue(uuid, uuid, public.delivery_issue_reason, text) to authenticated;
