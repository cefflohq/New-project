-- S4-11 Batch 7 (Grow V1 Flow 2, C1-C3 continued): Operations/Helper RPCs
-- and the narrower dispatch-authority permission boundary.
--
-- Separate migration from Batch 6 by necessity, not preference: Postgres
-- does not allow a newly added enum value (member_role 'helper', added in
-- Batch 6) to be referenced in the SAME transaction that added it in every
-- context: this migration runs as its own transaction, so 'helper' is
-- fully safe to compare against here.
--
-- Scoped permission boundary (Master MD §12 "tenant isolation and scoped
-- permissions"): is_business_member (existing, unchanged) stays the broad
-- "any active member, including Helper" check used for read access and for
-- this batch's own preparation RPC -- a Helper must be able to see and
-- progress prep work, and an Owner/Operator must be able to do prep work
-- too in a small operation. is_business_operational (new) narrows to
-- Owner/Operator only, and is applied to the specific dispatch-authority
-- actions where a Helper having access would defeat the point of a
-- distinct, narrower workspace: assigning a Rider, building/confirming a
-- run, and approving an order. Every other existing RPC is intentionally
-- left untouched in this pass -- documented in the Flow 2 completion
-- report as a residual, non-blocking scope item, not silently claimed as
-- fully re-scoped across the entire surface.

create function public.is_business_operational(p_business uuid) returns boolean
language sql stable security definer set search_path = public
as $$
select exists(
  select 1 from business_members
  where business_id = p_business and user_id = auth.uid()
    and role in ('owner','operator') and status = 'active'
)
$$;

-- Any active member (Owner/Operator/Helper) may view and progress
-- preparation work -- this is the "functional surface to view and progress
-- preparation work and exceptions" requirement itself, so it deliberately
-- stays on the broad is_business_member check, not the narrower
-- is_business_operational one.
--
-- Forward-only, one-step-at-a-time transitions (not_started -> preparing
-- -> packed -> ready), matching rider_transition's own precise transition-
-- matrix style; repeating the current state is an idempotent no-op
-- (complete_delivery/rider_transition/approve_order precedent), not an
-- error, since a re-tapped button is an expected UI race.
create function public.advance_preparation(
  p_order_id uuid,
  p_next public.preparation_status
) returns public.delivery_stops
language plpgsql
security definer
set search_path = public
as $$
declare
  st delivery_stops;
  o orders;
  old public.preparation_status;
  ok boolean;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;
  select * into st from delivery_stops where order_id = p_order_id for update;
  if st.id is null then
    raise exception 'delivery stop not found';
  end if;

  old := st.preparation_status;
  if old = p_next then
    return st;
  end if;
  ok := (old = 'not_started' and p_next = 'preparing')
     or (old = 'preparing' and p_next = 'packed')
     or (old = 'packed' and p_next = 'ready');
  if not ok then
    raise exception 'invalid preparation transition % -> %', old, p_next;
  end if;

  update delivery_stops set
    preparation_status = p_next,
    preparation_updated_at = now(),
    preparation_updated_by = auth.uid(),
    updated_at = now()
  where id = st.id
  returning * into st;

  insert into delivery_events(business_id, order_id, delivery_stop_id, event_type, from_status, to_status, actor_user_id, actor_role)
    values (o.business_id, o.id, st.id, 'preparation.status_changed', old::text, p_next::text, auth.uid(),
            case when is_business_operational(o.business_id) then 'vendor' else 'helper' end);

  return st;
end;
$$;

revoke all on function public.advance_preparation(uuid, public.preparation_status) from public, anon;
grant execute on function public.advance_preparation(uuid, public.preparation_status) to authenticated;

-- assign_rider: identical to the CURRENT version (202609010002 remediation
-- -- cancelled-order and not-yet-approved preconditions both included, not
-- the older foundation/S4-05 shapes), narrowed from is_business_member to
-- is_business_operational -- a Helper can prepare an order but must never
-- be able to assign it to a Rider.
create or replace function public.assign_rider(p_order_id uuid, p_rider_id uuid) returns public.orders
language plpgsql security definer set search_path = public as $$
declare o orders; a rider_assignments;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_operational(o.business_id) then raise exception 'forbidden'; end if;
  if o.delivery_status = 'cancelled' then raise exception 'order cancelled'; end if;
  if o.approved_at is null then raise exception 'order not approved'; end if;
  if not exists(select 1 from riders where id = p_rider_id and business_id = o.business_id and status = 'active') then
    raise exception 'invalid rider';
  end if;
  insert into rider_assignments(business_id, delivery_session_id, rider_id) values (o.business_id, o.delivery_session_id, p_rider_id) returning * into a;
  update orders set assigned_rider_id = p_rider_id, updated_at = now() where id = o.id returning * into o;
  update delivery_stops set assignment_id = a.id, rider_id = p_rider_id, updated_at = now() where order_id = o.id;
  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role)
    select o.business_id, o.id, s.id, a.id, 'rider.assigned', auth.uid(), 'vendor' from delivery_stops s where s.order_id = o.id;
  return o;
end;
$$;

-- approve_order: identical to the CURRENT version (202609010002
-- remediation -- rejects a cancelled/declined order, closing the terminal-
-- decline-must-be-terminal gap that migration fixed), narrowed the same way.
create or replace function public.approve_order(p_order_id uuid) returns public.orders
language plpgsql security definer set search_path = public as $$
declare o orders;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_operational(o.business_id) then raise exception 'forbidden'; end if;
  if o.delivery_status = 'cancelled' then raise exception 'order cancelled'; end if;
  if o.approved_at is not null then return o; end if;
  update orders set approved_at = now(), approved_by = auth.uid(), updated_at = now() where id = o.id returning * into o;
  insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role)
    values (o.business_id, o.id, 'order.approved', auth.uid(), 'vendor');
  return o;
end;
$$;

-- build_rider_run: identical to the current (S4-11 Batch 3) version, with
-- two changes: (1) is_business_member -> is_business_operational on the
-- session-forbidden check, matching the same Helper boundary; (2) the
-- eligibility CTE now also requires preparation_status not in
-- ('preparing','packed') -- "planning cannot treat work as ready when
-- preparation truth says otherwise" (Master MD §12), enforced only for
-- orders a Helper has actually started (default 'not_started' is
-- plannable, so a business that never uses the Helper workspace sees zero
-- behavior change -- this is not a retroactive regression).
create or replace function public.build_rider_run(
  p_delivery_session_id uuid,
  p_rider_id uuid,
  p_order_ids uuid[],
  p_idempotency_key uuid,
  p_override_capacity boolean default false
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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
        and preparation_status not in ('preparing','packed')
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
$$;
