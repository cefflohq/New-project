-- Security remediation batch 1 (Founder-approved 2026-09-30, staging first).
-- CEFFLO_SECURITY_AND_ACCESS_MASTER_SPEC: P0-1, P1-1, P1-2.

-- ---------------------------------------------------------------------
-- P0-1: internal planning/storefront helpers are not client APIs.
-- sequence_group_nearest_neighbor read any order's coordinates without a
-- tenant check (distance oracle on another business's customer address);
-- the others disclosed per-rider / per-session / per-business state for
-- any id. Every legitimate caller is a SECURITY DEFINER function owned by
-- postgres (propose_delivery_plan, build_rider_run,
-- check_run_vehicle_capacity, public_storefront, orders_plan_lock_guard),
-- so revoking client EXECUTE leaves them working.
revoke execute on function public.sequence_group_nearest_neighbor(uuid[], double precision, double precision) from public, anon, authenticated;
revoke execute on function public.rider_active_stop_count(uuid) from public, anon, authenticated;
revoke execute on function public.rider_effective_capacity(uuid) from public, anon, authenticated;
revoke execute on function public.run_plan_locked(uuid) from public, anon, authenticated;
revoke execute on function public.business_open_now(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- P1-1: rider approval is Owner-only (locked decision #15, spec s10/s22).
create or replace function public.approve_pending_rider(p_rider_id uuid)
 returns riders
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  r riders;
begin
  select * into r from riders where id = p_rider_id for update;
  if r.id is null or not is_business_owner(r.business_id) then
    raise exception 'forbidden';
  end if;
  if r.status <> 'pending' then
    raise exception 'rider not pending';
  end if;
  update riders set status = 'active', updated_at = now() where id = r.id returning * into r;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (r.business_id, 'rider.approved', auth.uid(), 'vendor', jsonb_build_object('rider_id', r.id));
  return r;
end;
$function$;

-- ---------------------------------------------------------------------
-- P1-1 + P1-2: rider removal is Owner-only and never orphans active work.
-- Active work is read from the real non-terminal states only:
--   rider_assignments.status  not in (completed, cancelled, declined)
--   orders.delivery_status    not in (delivered, cancelled)  (assigned to rider)
--   delivery_stops.status     not in (delivered, cancelled)
-- The row is scoped to one business: other businesses' rider rows for the
-- same person are untouched.
create or replace function public.deactivate_rider(p_rider_id uuid)
 returns riders
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  r public.riders;
  v_previous_status public.rider_status;
  v_runs int;
  v_orders int;
  v_stops int;
begin
  select * into r from public.riders where id = p_rider_id for update;
  if r.id is null or not public.is_business_owner(r.business_id) then
    raise exception 'forbidden';
  end if;

  select count(*) into v_runs from public.rider_assignments a
   where a.rider_id = r.id
     and a.status not in ('completed', 'cancelled', 'declined');
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
