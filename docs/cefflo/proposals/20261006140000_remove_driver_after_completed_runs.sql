-- PROPOSAL (not applied): the Owner can remove a driver whose runs are all
-- delivered. P1 found in the Driver audit (2026-10-06): rider_assignments are
-- never set to 'completed' (0 rows on staging), so deactivate_rider counted
-- every accepted run forever and refused to remove any driver who had ever
-- done a run ('rider has active work'). Now an assignment counts only while
-- it still has an open stop; open orders / stops are still counted as before,
-- so a driver with real active work still cannot be removed.
-- Authority unchanged (Owner; Operator only for pending applicants).
-- Rollback: re-apply 20261006100000's deactivate_rider definition.

CREATE OR REPLACE FUNCTION public.deactivate_rider(p_rider_id uuid)
 RETURNS riders
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  r public.riders;
  v_previous_status public.rider_status;
  v_runs int;
  v_orders int;
  v_stops int;
begin
  select * into r from public.riders where id = p_rider_id for update;
  -- Owner: any driver. Operator: only reject a pending applicant (M2);
  -- removing an active driver stays Owner-only.
  if r.id is null or not (public.is_business_owner(r.business_id)
       or (r.status = 'pending' and public.is_business_operational(r.business_id))) then
    raise exception 'forbidden';
  end if;

  -- An assignment counts only while it still has an open stop: assignments
  -- are never marked 'completed', so a fully delivered run is not work.
  select count(*) into v_runs from public.rider_assignments a
   where a.rider_id = r.id
     and a.status not in ('completed', 'cancelled', 'declined')
     and exists (select 1 from public.delivery_stops s
                 where s.assignment_id = a.id and s.status not in ('delivered', 'cancelled'));
  select count(*) into v_orders from public.orders o
   where o.assigned_rider_id = r.id
     and o.delivery_status not in ('delivered', 'cancelled');
  select count(*) into v_stops from public.delivery_stops s
   where s.rider_id = r.id
     and s.status not in ('delivered', 'cancelled');

  if v_runs + v_orders + v_stops > 0 then
    raise exception using
      errcode = 'P0001',
      message = 'rider has active work',
      detail = jsonb_build_object(
        'active_runs', v_runs, 'open_orders', v_orders, 'open_stops', v_stops)::text,
      hint = 'Reassign or finish the rider''s active runs, orders and stops, then remove the rider.';
  end if;

  v_previous_status := r.status;

  update public.riders
  set status = 'inactive', updated_at = now()
  where id = p_rider_id
  returning * into r;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (r.business_id, 'rider.deactivated', auth.uid(), 'vendor',
            jsonb_build_object('rider_id', r.id, 'previous_status', v_previous_status));

  return r;
end;
$function$;
