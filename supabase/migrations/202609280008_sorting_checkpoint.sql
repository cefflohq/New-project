-- D-74 Sorting model (Founder decision, 2026-09-28).
--
-- Truth is PER ORDER (delivery_stops); the workflow is aggregated by group.
--
--   per order   not_started -> preparing -> packed -> sorted -> ready
--   per order   packed_at/by, packing_confirmed_at/by, sorted_at/by, ready_at/by
--
--   PACKING group   business + Zone + order date (the Zone workload; packing
--                   may start before any Run exists)
--   SORTING group   business + Zone + Run (delivery_session); before a Run
--                   exists: business + Zone + order date with no Run
--
--   confirm_packing(group)  every eligible order in the group is packed (or
--                           later) -> stamps packing confirmation per order
--   packed -> sorted        per order, only after its packing is confirmed
--                           (packing an order never marks it sorted)
--   confirm_sorting(group)  every eligible order in the group is sorted ->
--                           each becomes Ready for Pickup, attributed per order
--   ready                   ONLY through confirm_sorting; never per order
--
-- No order-count limit exists anywhere. Helpers never create, restructure,
-- assign or reassign Runs or Riders; the Rider's own pickup verification in
-- the Driver app (unchanged) is what moves custody. Eligible = the order's
-- delivery_status is 'created' or 'ready_for_pickup' (not yet picked up).

alter table public.delivery_stops
  add column packed_at timestamptz,
  add column packed_by uuid references auth.users on delete set null,
  add column packing_confirmed_at timestamptz,
  add column packing_confirmed_by uuid references auth.users on delete set null,
  add column sorted_at timestamptz,
  add column sorted_by uuid references auth.users on delete set null,
  add column ready_at timestamptz,
  add column ready_by uuid references auth.users on delete set null;

create or replace function public.preparation_transition_allowed(
  p_from public.preparation_status, p_to public.preparation_status
) returns boolean
language sql immutable
as $$
  select (p_from = 'not_started' and p_to = 'preparing')
      or (p_from = 'preparing' and p_to = 'packed')
      or (p_from = 'packed' and p_to = 'sorted')
      or (p_from = 'sorted' and p_to = 'ready')
$$;
revoke all on function public.preparation_transition_allowed(public.preparation_status, public.preparation_status) from public, anon, authenticated;

-- Per-order checkpoint. Ready is refused here: it is a group decision.
create or replace function public.advance_preparation(p_order_id uuid, p_next public.preparation_status)
returns public.delivery_stops
language plpgsql
security definer
set search_path = public
as $$
declare
  st delivery_stops;
  o orders;
  old public.preparation_status;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_fulfilment(o.business_id) then
    raise exception 'forbidden';
  end if;
  if o.delivery_status not in ('created', 'ready_for_pickup') then
    raise exception 'task not available';
  end if;
  select * into st from delivery_stops where order_id = p_order_id for update;
  if st.id is null then
    raise exception 'delivery stop not found';
  end if;

  old := st.preparation_status;
  if old = p_next then
    return st;
  end if;
  if p_next = 'ready' then
    raise exception 'ready requires sorting confirmation';
  end if;
  if not preparation_transition_allowed(old, p_next) then
    raise exception 'invalid preparation transition % -> %', old, p_next;
  end if;
  if p_next = 'sorted' and st.packing_confirmed_at is null then
    raise exception 'packing not confirmed';
  end if;

  update delivery_stops set
    preparation_status = p_next,
    preparation_updated_at = now(),
    preparation_updated_by = auth.uid(),
    preparation_updated_by_helper = null,
    packed_at = case when p_next = 'packed' then now() else packed_at end,
    packed_by = case when p_next = 'packed' then auth.uid() else packed_by end,
    sorted_at = case when p_next = 'sorted' then now() else sorted_at end,
    sorted_by = case when p_next = 'sorted' then auth.uid() else sorted_by end,
    updated_at = now()
  where id = st.id
  returning * into st;

  insert into delivery_events(business_id, order_id, delivery_stop_id, event_type, from_status, to_status, actor_user_id, actor_role)
    values (o.business_id, o.id, st.id, 'preparation.status_changed', old::text, p_next::text, auth.uid(),
            case when is_business_operational(o.business_id) then 'vendor' else 'helper' end);

  return st;
end;
$$;

-- Slide to Confirm Packing: Zone + order date.
create function public.confirm_packing(p_business_id uuid, p_zone_id uuid, p_order_date date)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total int;
  v_packed int;
  v_ids uuid[];
  v_role text;
begin
  if not is_business_fulfilment(p_business_id) then
    raise exception 'forbidden';
  end if;
  v_role := case when is_business_operational(p_business_id) then 'vendor' else 'helper' end;

  perform 1 from delivery_stops s join orders o on o.id = s.order_id
    where o.business_id = p_business_id
      and o.zone_id is not distinct from p_zone_id
      and o.order_date is not distinct from p_order_date
      and o.delivery_status in ('created', 'ready_for_pickup')
    for update of s;

  select count(*), count(*) filter (where s.preparation_status in ('packed', 'sorted', 'ready')),
         array_agg(o.id) filter (where s.preparation_status = 'packed' and s.packing_confirmed_at is null)
    into v_total, v_packed, v_ids
    from delivery_stops s join orders o on o.id = s.order_id
    where o.business_id = p_business_id
      and o.zone_id is not distinct from p_zone_id
      and o.order_date is not distinct from p_order_date
      and o.delivery_status in ('created', 'ready_for_pickup');

  if v_total = 0 then
    raise exception 'no orders in this group';
  end if;
  if v_packed < v_total then
    raise exception 'packing incomplete: % / % packed', v_packed, v_total;
  end if;

  update delivery_stops set packing_confirmed_at = now(), packing_confirmed_by = auth.uid(), updated_at = now()
    where order_id = any(coalesce(v_ids, '{}'));
  insert into delivery_events(business_id, order_id, delivery_stop_id, event_type, actor_user_id, actor_role, metadata)
    select p_business_id, s.order_id, s.id, 'preparation.packing_confirmed', auth.uid(), v_role,
           jsonb_build_object('zone_id', p_zone_id, 'order_date', p_order_date)
    from delivery_stops s where s.order_id = any(coalesce(v_ids, '{}'));
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'fulfilment.packing_confirmed', auth.uid(), v_role,
            jsonb_build_object('zone_id', p_zone_id, 'order_date', p_order_date,
                               'orders', v_total, 'newly_confirmed', coalesce(array_length(v_ids, 1), 0)));

  return jsonb_build_object('orders', v_total, 'packed', v_packed,
                            'newly_confirmed', coalesce(array_length(v_ids, 1), 0));
end;
$$;

-- Slide to Confirm Sorting: Zone + Run (or Zone + order date before a Run).
-- Every order must be sorted; then each becomes Ready for Pickup.
create function public.confirm_sorting(
  p_business_id uuid, p_zone_id uuid, p_delivery_session_id uuid, p_order_date date
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total int;
  v_sorted int;
  v_ids uuid[];
  v_role text;
begin
  if not is_business_fulfilment(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_delivery_session_id is not null and not exists(
    select 1 from delivery_sessions where id = p_delivery_session_id and business_id = p_business_id
  ) then
    raise exception 'forbidden';
  end if;
  v_role := case when is_business_operational(p_business_id) then 'vendor' else 'helper' end;

  perform 1 from delivery_stops s join orders o on o.id = s.order_id
    where o.business_id = p_business_id
      and o.zone_id is not distinct from p_zone_id
      and o.delivery_session_id is not distinct from p_delivery_session_id
      and (p_delivery_session_id is not null or o.order_date is not distinct from p_order_date)
      and o.delivery_status in ('created', 'ready_for_pickup')
    for update of s;

  select count(*), count(*) filter (where s.preparation_status in ('sorted', 'ready')),
         array_agg(o.id) filter (where s.preparation_status = 'sorted')
    into v_total, v_sorted, v_ids
    from delivery_stops s join orders o on o.id = s.order_id
    where o.business_id = p_business_id
      and o.zone_id is not distinct from p_zone_id
      and o.delivery_session_id is not distinct from p_delivery_session_id
      and (p_delivery_session_id is not null or o.order_date is not distinct from p_order_date)
      and o.delivery_status in ('created', 'ready_for_pickup');

  if v_total = 0 then
    raise exception 'no orders in this group';
  end if;
  if v_sorted < v_total then
    raise exception 'sorting incomplete: % / % sorted', v_sorted, v_total;
  end if;

  update delivery_stops set
    preparation_status = 'ready',
    preparation_updated_at = now(),
    preparation_updated_by = auth.uid(),
    preparation_updated_by_helper = null,
    ready_at = now(),
    ready_by = auth.uid(),
    updated_at = now()
  where order_id = any(coalesce(v_ids, '{}'));
  insert into delivery_events(business_id, order_id, delivery_stop_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    select p_business_id, s.order_id, s.id, 'preparation.status_changed', 'sorted', 'ready', auth.uid(), v_role,
           jsonb_build_object('via', 'confirm_sorting', 'zone_id', p_zone_id, 'delivery_session_id', p_delivery_session_id)
    from delivery_stops s where s.order_id = any(coalesce(v_ids, '{}'));
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'fulfilment.sorting_confirmed', auth.uid(), v_role,
            jsonb_build_object('zone_id', p_zone_id, 'delivery_session_id', p_delivery_session_id,
                               'order_date', p_order_date, 'orders', v_total,
                               'newly_ready', coalesce(array_length(v_ids, 1), 0)));

  return jsonb_build_object('orders', v_total, 'sorted', v_sorted,
                            'newly_ready', coalesce(array_length(v_ids, 1), 0));
end;
$$;

revoke all on function public.confirm_packing(uuid, uuid, date) from public, anon;
revoke all on function public.confirm_sorting(uuid, uuid, uuid, date) from public, anon;
grant execute on function public.confirm_packing(uuid, uuid, date) to authenticated;
grant execute on function public.confirm_sorting(uuid, uuid, uuid, date) to authenticated;

-- Minimised Helper contract, now with the grouping keys and checkpoint
-- flags, plus read-only "Picked up • Rider • time" for 24 h after the
-- Rider's own pickup verification.
create or replace function public.my_fulfilment_tasks(p_business_id uuid) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not is_business_fulfilment(p_business_id) then
    raise exception 'forbidden';
  end if;
  return jsonb_build_object(
    'business_name', (select name from businesses where id = p_business_id),
    'tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
        'order_id', o.id,
        'order_number', o.order_number,
        'customer_name', o.customer_name,
        'items', o.items,
        'notes', nullif(o.notes, ''),
        'order_date', o.order_date,
        'preparation_status', s.preparation_status,
        'preparation_updated_at', s.preparation_updated_at,
        'packing_confirmed', s.packing_confirmed_at is not null,
        'zone_id', o.zone_id,
        'zone_name', z.name,
        'run_id', o.delivery_session_id,
        'run_name', ds.name,
        'run_date', ds.delivery_date,
        'stop_sequence', s.sequence,
        'handover_rider_name', case when s.preparation_status = 'ready' or o.delivery_status = 'picked_up' then r.name end,
        'picked_up_at', pu.at,
        'created_at', o.created_at
      ) order by o.order_date nulls last, z.name nulls last, ds.name nulls last, s.sequence nulls last, o.created_at)
      from orders o
      join delivery_stops s on s.order_id = o.id
      left join delivery_sessions ds on ds.id = o.delivery_session_id
      left join zones z on z.id = o.zone_id
      left join riders r on r.id = o.assigned_rider_id
      left join lateral (
        select max(e.created_at) as at from delivery_events e
        where e.order_id = o.id and e.to_status = 'picked_up'
      ) pu on o.delivery_status = 'picked_up'
      where o.business_id = p_business_id
        and (o.delivery_status in ('created', 'ready_for_pickup')
             or (o.delivery_status = 'picked_up' and pu.at > now() - interval '24 hours'))
    ), '[]'::jsonb)
  );
end;
$$;

-- Planning: a Run may be built from packed orders (Sorting then follows the
-- Run grouping). Orders still being prepared, or already sorted into a
-- staging group, stay out of new Runs. Otherwise identical to the current
-- definition.
CREATE OR REPLACE FUNCTION public.build_rider_run(p_delivery_session_id uuid, p_rider_id uuid, p_order_ids uuid[], p_idempotency_key uuid, p_override_capacity boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s delivery_sessions;
  r riders;
  requested_ids uuid[];
  requested_count int;
  distinct_count int;
  locked_count int;
  eligible_count int;
  existing_event delivery_events;
  existing_session_id uuid;
  existing_rider_id uuid;
  existing_order_ids uuid[];
  oid uuid;
  violations jsonb;
  current_load integer;
begin
  if p_idempotency_key is null then
    raise exception 'idempotency key required';
  end if;
  if p_order_ids is null or array_length(p_order_ids,1) is null or array_length(p_order_ids,1) = 0 then
    raise exception 'no orders selected';
  end if;

  requested_count := array_length(p_order_ids,1);
  select array_agg(x order by x) into requested_ids from (select distinct unnest(p_order_ids) as x) d;
  distinct_count := array_length(requested_ids,1);
  if requested_count <> distinct_count then
    raise exception 'duplicate order ids';
  end if;

  select * into existing_event
    from delivery_events
    where event_type = 'run.built' and (metadata->>'idempotency_key')::uuid = p_idempotency_key
    limit 1;

  if existing_event.id is not null then
    existing_session_id := (existing_event.metadata->>'delivery_session_id')::uuid;
    existing_rider_id := (existing_event.metadata->>'rider_id')::uuid;
    select array_agg((x)::uuid order by (x)::uuid) into existing_order_ids
      from jsonb_array_elements_text(existing_event.metadata->'order_ids') as x;

    if existing_session_id = p_delivery_session_id
       and existing_rider_id = p_rider_id
       and existing_order_ids = requested_ids then
      return jsonb_build_object(
        'delivery_session_id', existing_session_id,
        'rider_id', existing_rider_id,
        'order_count', array_length(existing_order_ids,1),
        'vehicle_capacity_override_used', coalesce((existing_event.metadata->>'vehicle_capacity_override')::boolean, false)
          and coalesce(jsonb_array_length(existing_event.metadata->'vehicle_capacity_violations'), 0) > 0
      );
    else
      raise exception 'idempotency key conflict';
    end if;
  end if;

  select * into s from delivery_sessions where id = p_delivery_session_id for update;
  if s.id is null or not is_business_operational(s.business_id) then
    raise exception 'forbidden';
  end if;
  if s.status not in ('planned','active') then
    raise exception 'session not open';
  end if;

  select * into r from riders where id = p_rider_id;
  if r.id is null or r.business_id is distinct from s.business_id or r.status <> 'active' then
    raise exception 'invalid rider';
  end if;

  with locked as (
    select o.business_id, o.approved_at, o.assigned_rider_id, o.delivery_status, ds.preparation_status
    from orders o
    join delivery_stops ds on ds.order_id = o.id
    where o.id = any(requested_ids)
    for update
  )
  select
    count(*),
    count(*) filter (
      where business_id = s.business_id
        and approved_at is not null
        and assigned_rider_id is null
        and delivery_status = 'created'
        and preparation_status not in ('preparing','sorted')
    )
  into locked_count, eligible_count
  from locked;

  if locked_count <> distinct_count or eligible_count <> distinct_count then
    select * into existing_event
      from delivery_events
      where event_type = 'run.built' and (metadata->>'idempotency_key')::uuid = p_idempotency_key
      limit 1;

    if existing_event.id is not null then
      existing_session_id := (existing_event.metadata->>'delivery_session_id')::uuid;
      existing_rider_id := (existing_event.metadata->>'rider_id')::uuid;
      select array_agg((x)::uuid order by (x)::uuid) into existing_order_ids
        from jsonb_array_elements_text(existing_event.metadata->'order_ids') as x;

      if existing_session_id = p_delivery_session_id
         and existing_rider_id = p_rider_id
         and existing_order_ids = requested_ids then
        return jsonb_build_object(
          'delivery_session_id', existing_session_id,
          'rider_id', existing_rider_id,
          'order_count', array_length(existing_order_ids,1),
          'vehicle_capacity_override_used', coalesce((existing_event.metadata->>'vehicle_capacity_override')::boolean, false)
            and coalesce(jsonb_array_length(existing_event.metadata->'vehicle_capacity_violations'), 0) > 0
        );
      else
        raise exception 'idempotency key conflict';
      end if;
    end if;

    raise exception 'orders no longer eligible';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
      'order_id', o.id,
      'reason', 'vehicle_incompatible',
      'vehicle_requirement', o.vehicle_requirement,
      'rider_vehicle_type', r.vehicle_type
    )), '[]'::jsonb)
  into violations
  from orders o
  where o.id = any(requested_ids)
    and not is_vehicle_compatible(r.vehicle_type, o.vehicle_requirement);

  current_load := rider_active_stop_count(p_rider_id);
  if current_load + distinct_count > rider_effective_capacity(p_rider_id) then
    violations := violations || jsonb_build_array(jsonb_build_object(
      'reason', 'capacity_exceeded',
      'current_load', current_load,
      'requested', distinct_count,
      'effective_capacity', rider_effective_capacity(p_rider_id)
    ));
  end if;

  if jsonb_array_length(violations) > 0 and not p_override_capacity then
    raise exception 'vehicle/capacity incompatible: call check_run_vehicle_capacity for details before overriding';
  end if;

  foreach oid in array requested_ids loop
    perform attach_order_to_session(oid, p_delivery_session_id);
    perform assign_rider(oid, p_rider_id);
  end loop;

  begin
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (
        s.business_id, 'run.built', auth.uid(), 'vendor',
        jsonb_build_object(
          'delivery_session_id', p_delivery_session_id,
          'rider_id', p_rider_id,
          'order_ids', to_jsonb(requested_ids),
          'idempotency_key', p_idempotency_key,
          'vehicle_capacity_override', p_override_capacity,
          'vehicle_capacity_violations', violations
        )
      );
  exception when unique_violation then
    raise exception 'idempotency key conflict';
  end;

  return jsonb_build_object(
    'delivery_session_id', p_delivery_session_id,
    'rider_id', p_rider_id,
    'order_count', distinct_count,
    'vehicle_capacity_override_used', (jsonb_array_length(violations) > 0 and p_override_capacity)
  );
end;
$function$;
