-- Driver Core lifecycle fix (Founder-approved 2026-10-06; staging first).
-- Problem: complete_delivery never moved the rider assignment to its
-- terminal state, so a delivered stop's assignment stayed 'accepted' (the
-- in-progress state for Vendor Riders "on a run", FOUNDR admin_list_riders /
-- admin_stuck_riders, record_rider_location). Old: assignment stays
-- 'accepted' forever. New: completing a delivery sets ITS assignment to
-- 'completed' + completed_at; the run/session still completes only when
-- every stop is delivered (complete_session_if_all_delivered, unchanged).
-- Idempotent: an already-delivered order returns before any update.
-- Grants unchanged (CREATE OR REPLACE keeps them); no RLS change.
-- Backfill: assignments still active whose order is authoritatively
-- delivered (delivery_status = 'delivered' with completed_at) take
-- completed_at from the order. Nothing is inferred from age.
-- Rollback: re-apply complete_delivery from 202608290001 /
-- 202609030007 (function only); the backfilled rows are correct data.

CREATE OR REPLACE FUNCTION public.complete_delivery(p_rider_id uuid, p_order_id uuid, p_pod_path text, p_note text DEFAULT ''::text, p_idempotency_key text DEFAULT NULL::text)
 RETURNS orders
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  -- Terminal assignment state: this stop's own assignment (one stop per
  -- assignment, held by this rider) is completed; other stops of the run
  -- keep their state, and the run completes only via the check below.
  update rider_assignments a set status = 'completed', completed_at = now(), updated_at = now()
    from delivery_stops s
    where s.order_id = o.id and a.id = s.assignment_id and a.rider_id = p_rider_id
      and a.status in ('accepted', 'picking_up', 'delivering');
  update tracking_tokens set expires_at = now() + interval '48 hours' where order_id = o.id;
  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    select o.business_id, o.id, s.id, s.assignment_id, 'delivery.completed', 'arrived', 'delivered', auth.uid(), 'rider', jsonb_build_object('idempotency_key', p_idempotency_key)
    from delivery_stops s where s.order_id = o.id;

  if o.delivery_session_id is not null then
    perform complete_session_if_all_delivered(o.delivery_session_id);
  end if;

  return o;
end;
$function$;

update public.rider_assignments a
   set status = 'completed', completed_at = o.completed_at, updated_at = now()
  from public.delivery_stops s
  join public.orders o on o.id = s.order_id
 where s.assignment_id = a.id
   and a.status in ('accepted', 'picking_up', 'delivering')
   and o.delivery_status = 'delivered'
   and o.completed_at is not null;
