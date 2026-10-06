-- M2 Operator hiring authority (Founder-approved 2026-10-06; staging first).
-- Operator may manage Hiring and Invite for Driver and Helper, and approve
-- Drivers. Changes (owner-only -> Owner + Operator = is_business_operational):
--   _may_manage_invite_link: Helper link (Driver link already operational;
--     Operator link stays Owner-only -- an Operator never invites Operators)
--   approve_pending_rider, save_job_opening, close_job_opening
--   deactivate_rider: Operator may reject a PENDING applicant only;
--     removing an active driver stays Owner-only.
-- Unchanged (not part of M2): decide_team_join_request (Operator/Helper
-- join approval) stays Owner-only; business/billing stay Owner-only.
-- CREATE OR REPLACE keeps every grant. Rollback: re-apply the previous
-- definitions (20260930072634, 20260930160616, 20261005100000,
-- 20261005140000).

CREATE OR REPLACE FUNCTION public._may_manage_invite_link(p_business uuid, p_kind text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case p_kind
    when 'rider' then is_business_operational(p_business)
    when 'operator' then is_business_owner(p_business)
    when 'helper' then is_business_operational(p_business)
    else false end
$function$;

CREATE OR REPLACE FUNCTION public.approve_pending_rider(p_rider_id uuid)
 RETURNS riders
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  r riders;
begin
  select * into r from riders where id = p_rider_id for update;
  if r.id is null or not is_business_operational(r.business_id) then
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

CREATE OR REPLACE FUNCTION public.close_job_opening(p_opening_id uuid)
 RETURNS rider_job_openings
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v rider_job_openings;
begin
  select * into v from rider_job_openings where id = p_opening_id for update;
  if v.id is null or not is_business_operational(v.business_id) then raise exception 'forbidden'; end if;
  update rider_job_openings set status = 'closed', updated_at = now() where id = v.id returning * into v;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v.business_id, 'rider_job.closed', auth.uid(), 'vendor', jsonb_build_object('opening_id', v.id));
  return v;
end $function$;

CREATE OR REPLACE FUNCTION public.save_job_opening(p_business_id uuid, p_area_label text, p_pickup_time time without time zone, p_days smallint[], p_vehicle_type rider_vehicle_type, p_pay_per_drop numeric, p_drivers_needed integer, p_reach_km numeric DEFAULT 10, p_opening_id uuid DEFAULT NULL::uuid)
 RETURNS rider_job_openings
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v rider_job_openings;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if p_pickup_time is null then raise exception 'pickup time is required'; end if;
  if p_pay_per_drop is null or p_pay_per_drop < 3.00 then raise exception 'minimum RM3.00 per drop'; end if;
  if coalesce(p_reach_km, 10) not between 1 and 15 then raise exception 'driver reach must be 1-15 km'; end if;
  if p_opening_id is null then
    insert into rider_job_openings(business_id, area_label, shift_start, shift_end, days, vehicle_type,
                                   pay_amount, pay_unit, riders_needed, radius_km, created_by)
      values (p_business_id, btrim(p_area_label), p_pickup_time, null,
              (select array_agg(distinct d order by d) from unnest(p_days) d), p_vehicle_type,
              round(p_pay_per_drop, 2), 'drop', p_drivers_needed, coalesce(p_reach_km, 10), auth.uid())
      returning * into v;
  else
    update rider_job_openings set
      area_label = btrim(p_area_label), shift_start = p_pickup_time, shift_end = null,
      days = (select array_agg(distinct d order by d) from unnest(p_days) d),
      vehicle_type = p_vehicle_type, pay_amount = round(p_pay_per_drop, 2), pay_unit = 'drop',
      riders_needed = p_drivers_needed, radius_km = coalesce(p_reach_km, 10),
      status = 'open', updated_at = now()
    where id = p_opening_id and business_id = p_business_id
    returning * into v;
    if v.id is null then raise exception 'opening not found'; end if;
  end if;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'rider_job.saved', auth.uid(), 'vendor', jsonb_build_object('opening_id', v.id));
  return v;
end $function$;
