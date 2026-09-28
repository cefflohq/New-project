-- D-74 plan lock + execution recovery (Founder decision, 2026-09-28).
--
--   SORTING STARTED  -> DELIVERY PLAN STRUCTURE LOCKED
--   SORTING STARTED  -> RIDER EXECUTION RECOVERY STILL ALLOWED
--
-- Lock point: the first order of a Run (delivery_session) becomes 'sorted'.
-- delivery_sessions.sorting_started_at/by records it (event run.plan_locked).
-- An order already sorted/ready without a Run is locked to its Zone group.
--
-- Enforced by one BEFORE UPDATE guard on orders, so every path is covered
-- (attach_order_to_session, build_rider_run, update_order_details,
-- assign_rider, reassign_rider and any future RPC): on a locked, not yet
-- picked-up order it refuses a Run change, a Zone change, being added to a
-- locked Run, and any per-order change to a different Rider. Clearing the
-- Rider (existing delivery recovery) stays allowed. Only the two recovery
-- actions below may change the Run's pickup party:
--   replace_run_rider   same Run, same orders, same staging; new Rider
--   outsource_run       same Run, same orders, same staging; External Provider
-- Neither touches preparation: Sorting stays valid.
--
-- Custody: an internal Rider cannot pick up before Ready for Pickup where
-- the Helper workflow applies (rider_transition). An outsourced Run is
-- handed over with confirm_external_handover, recorded as an external
-- handover -- never as a Driver-app pickup checklist.
-- Cefflo records accountability evidence only (no HR/payroll action).

alter table public.delivery_sessions
  add column sorting_started_at timestamptz,
  add column sorting_started_by uuid references auth.users on delete set null;

create function public.run_plan_locked(p_session uuid) returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(select 1 from delivery_sessions where id = p_session and sorting_started_at is not null)
$$;
revoke all on function public.run_plan_locked(uuid) from public, anon;
grant execute on function public.run_plan_locked(uuid) to authenticated;

-- Runs whose Sorting already started before this migration are locked from
-- the first recorded per-order sort (202609280008 stamps sorted_at/by).
update public.delivery_sessions ds set
  sorting_started_at = f.first_at,
  sorting_started_by = f.first_by
from (
  select distinct on (o.delivery_session_id) o.delivery_session_id, st.sorted_at as first_at, st.sorted_by as first_by
  from public.orders o join public.delivery_stops st on st.order_id = o.id
  where o.delivery_session_id is not null and st.sorted_at is not null
  order by o.delivery_session_id, st.sorted_at
) f
where ds.id = f.delivery_session_id and ds.sorting_started_at is null;

-- Lock point.
create function public.stops_mark_sorting_started() returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_session uuid;
  v_business uuid;
begin
  if new.preparation_status = 'sorted' and old.preparation_status is distinct from 'sorted' then
    select delivery_session_id, business_id into v_session, v_business from orders where id = new.order_id;
    if v_session is not null then
      update delivery_sessions set sorting_started_at = now(), sorting_started_by = auth.uid(), updated_at = now()
        where id = v_session and sorting_started_at is null;
      if found then
        insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role, metadata)
          values (v_business, new.order_id, 'run.plan_locked', auth.uid(),
                  case when is_business_operational(v_business) then 'vendor' else 'helper' end,
                  jsonb_build_object('delivery_session_id', v_session, 'reason', 'sorting_started'));
      end if;
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.stops_mark_sorting_started() from public, anon, authenticated;
create trigger delivery_stops_sorting_started
  after update of preparation_status on public.delivery_stops
  for each row execute function public.stops_mark_sorting_started();

-- The plan lock.
create function public.orders_plan_lock_guard() returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_locked boolean;
  v_staged boolean;
begin
  if coalesce(current_setting('cefflo.plan_recovery', true), '') = 'on' then
    return new;
  end if;
  if old.delivery_status not in ('created', 'ready_for_pickup') then
    return new;
  end if;
  v_locked := old.delivery_session_id is not null and run_plan_locked(old.delivery_session_id);
  v_staged := exists(select 1 from delivery_stops where order_id = old.id and preparation_status in ('sorted', 'ready'));

  if new.delivery_session_id is distinct from old.delivery_session_id
     and (v_locked or v_staged or (new.delivery_session_id is not null and run_plan_locked(new.delivery_session_id))) then
    raise exception 'delivery plan locked: sorting has started';
  end if;
  if new.zone_id is distinct from old.zone_id and (v_locked or v_staged) then
    raise exception 'delivery plan locked: sorting has started';
  end if;
  if new.assigned_rider_id is distinct from old.assigned_rider_id and new.assigned_rider_id is not null and v_locked then
    raise exception 'delivery plan locked: use Replace Rider for the whole Run';
  end if;
  return new;
end;
$$;
revoke all on function public.orders_plan_lock_guard() from public, anon, authenticated;
create trigger orders_plan_lock
  before update of delivery_session_id, zone_id, assigned_rider_id on public.orders
  for each row execute function public.orders_plan_lock_guard();

-- External provider record (not a Rider, not a Driver-app user).
create table public.delivery_outsourcing(
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses on delete cascade,
  delivery_session_id uuid not null references public.delivery_sessions on delete cascade,
  status text not null default 'active' check (status in ('active', 'handed_over', 'cancelled')),
  provider_name text not null check (length(trim(provider_name)) between 1 and 80),
  external_reference text check (external_reference is null or length(external_reference) <= 120),
  driver_name text check (driver_name is null or length(driver_name) <= 80),
  vehicle text check (vehicle is null or length(vehicle) <= 80),
  contact text check (contact is null or length(contact) <= 120),
  notes text check (notes is null or length(notes) <= 500),
  reason text not null,
  previous_rider_ids uuid[] not null default '{}',
  outsourced_by uuid references auth.users on delete set null,
  outsourced_at timestamptz not null default now(),
  handed_over_by uuid references auth.users on delete set null,
  handed_over_at timestamptz,
  ended_by uuid references auth.users on delete set null,
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index delivery_outsourcing_one_live on public.delivery_outsourcing(delivery_session_id)
  where status in ('active', 'handed_over');
alter table public.delivery_outsourcing enable row level security;
create policy delivery_outsourcing_vendor_read on public.delivery_outsourcing
  for select using (is_business_member(business_id));
revoke all on table public.delivery_outsourcing from anon;
revoke insert, update, delete on table public.delivery_outsourcing from authenticated;
grant select on table public.delivery_outsourcing to authenticated;

create function public.recovery_reason_valid(p_reason text, p_note text) returns boolean
language sql immutable
as $$
  select p_reason in ('rider_unavailable', 'no_show', 'sick', 'vehicle_issue', 'emergency', 'other')
     and (p_reason <> 'other' or nullif(trim(coalesce(p_note, '')), '') is not null)
$$;

-- Shared pre-check: the Run is this business's and nothing has left the store.
create function public.recovery_run_check(p_session uuid) returns delivery_sessions
language plpgsql security definer set search_path = public
as $$
declare
  s delivery_sessions;
begin
  select * into s from delivery_sessions where id = p_session for update;
  if s.id is null or not is_business_operational(s.business_id) then
    raise exception 'forbidden';
  end if;
  if exists(
    select 1 from orders o join delivery_stops st on st.order_id = o.id
    where o.delivery_session_id = s.id
      and (o.delivery_status in ('picked_up', 'out_for_delivery', 'arrived') or st.sequence_locked_at is not null)
  ) then
    raise exception 'pickup already started: use delivery recovery';
  end if;
  if not exists(select 1 from orders where delivery_session_id = s.id and delivery_status in ('created', 'ready_for_pickup')) then
    raise exception 'no orders to recover in this run';
  end if;
  return s;
end;
$$;
revoke all on function public.recovery_run_check(uuid) from public, anon, authenticated;

-- Replace Rider: same Run, same orders, same staging.
create function public.replace_run_rider(
  p_delivery_session_id uuid, p_new_rider_id uuid, p_reason text, p_note text default null
) returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  s delivery_sessions;
  v_prev uuid[];
  v_count int := 0;
  r record;
  v_assignment uuid;
begin
  s := recovery_run_check(p_delivery_session_id);
  if not recovery_reason_valid(p_reason, p_note) then
    raise exception 'recovery reason required';
  end if;
  if not exists(select 1 from riders where id = p_new_rider_id and business_id = s.business_id and status = 'active') then
    raise exception 'invalid rider';
  end if;

  select coalesce(array_agg(distinct assigned_rider_id) filter (where assigned_rider_id is not null), '{}')
    into v_prev from orders where delivery_session_id = s.id and delivery_status in ('created', 'ready_for_pickup');
  if v_prev = array[p_new_rider_id] then
    return jsonb_build_object('delivery_session_id', s.id, 'orders', 0, 'unchanged', true);
  end if;

  perform set_config('cefflo.plan_recovery', 'on', true);
  update delivery_outsourcing set status = 'cancelled', ended_at = now(), ended_by = auth.uid(), updated_at = now()
    where delivery_session_id = s.id and status = 'active';

  for r in
    select o.id as order_id, o.assigned_rider_id, st.id as stop_id, st.assignment_id, a.status as a_status
      from orders o join delivery_stops st on st.order_id = o.id
      left join rider_assignments a on a.id = st.assignment_id
      where o.delivery_session_id = s.id and o.delivery_status in ('created', 'ready_for_pickup')
      for update of o, st
  loop
    if r.assignment_id is not null and r.a_status not in ('completed', 'cancelled') then
      update rider_assignments set rider_id = p_new_rider_id, status = 'assigned', accepted_at = null, updated_at = now()
        where id = r.assignment_id;
      v_assignment := r.assignment_id;
    else
      insert into rider_assignments(business_id, delivery_session_id, rider_id)
        values (s.business_id, s.id, p_new_rider_id) returning id into v_assignment;
    end if;
    update orders set assigned_rider_id = p_new_rider_id, updated_at = now() where id = r.order_id;
    update delivery_stops set rider_id = p_new_rider_id, assignment_id = v_assignment, sequence = null, updated_at = now()
      where id = r.stop_id;
    insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role, metadata)
      values (s.business_id, r.order_id, r.stop_id, v_assignment, 'rider.reassigned', auth.uid(), 'vendor',
              jsonb_build_object('via', 'replace_run_rider', 'from_rider_id', r.assigned_rider_id,
                                 'to_rider_id', p_new_rider_id, 'reason', p_reason));
    v_count := v_count + 1;
  end loop;
  perform set_config('cefflo.plan_recovery', '', true);

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (s.business_id, 'run.rider_replaced', auth.uid(), 'vendor',
            jsonb_build_object('delivery_session_id', s.id, 'previous_rider_ids', v_prev,
                               'new_rider_id', p_new_rider_id, 'reason', p_reason, 'note', p_note,
                               'orders', v_count, 'plan_locked', s.sorting_started_at is not null));
  return jsonb_build_object('delivery_session_id', s.id, 'orders', v_count,
                            'previous_rider_ids', v_prev, 'new_rider_id', p_new_rider_id);
end;
$$;

-- Outsource Run: same Run, same orders, same staging; External Provider.
create function public.outsource_run(
  p_delivery_session_id uuid, p_provider_name text, p_reason text, p_note text default null,
  p_external_reference text default null, p_driver_name text default null,
  p_vehicle text default null, p_contact text default null
) returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  s delivery_sessions;
  v_prev uuid[];
  ob delivery_outsourcing;
begin
  s := recovery_run_check(p_delivery_session_id);
  if not recovery_reason_valid(p_reason, p_note) then
    raise exception 'recovery reason required';
  end if;
  if nullif(trim(coalesce(p_provider_name, '')), '') is null then
    raise exception 'provider required';
  end if;

  select coalesce(array_agg(distinct assigned_rider_id) filter (where assigned_rider_id is not null), '{}')
    into v_prev from orders where delivery_session_id = s.id and delivery_status in ('created', 'ready_for_pickup');

  select * into ob from delivery_outsourcing where delivery_session_id = s.id and status in ('active', 'handed_over') for update;
  if ob.status = 'handed_over' then
    raise exception 'already handed over';
  end if;
  if ob.id is not null then
    update delivery_outsourcing set provider_name = trim(p_provider_name), external_reference = p_external_reference,
      driver_name = p_driver_name, vehicle = p_vehicle, contact = p_contact, notes = p_note,
      reason = p_reason, updated_at = now()
      where id = ob.id returning * into ob;
  else
    insert into delivery_outsourcing(business_id, delivery_session_id, provider_name, external_reference, driver_name,
                                     vehicle, contact, notes, reason, previous_rider_ids, outsourced_by)
      values (s.business_id, s.id, trim(p_provider_name), p_external_reference, p_driver_name,
              p_vehicle, p_contact, p_note, p_reason, v_prev, auth.uid())
      returning * into ob;
  end if;

  -- Internal custody ends; Run membership and preparation are untouched.
  perform set_config('cefflo.plan_recovery', 'on', true);
  update rider_assignments a set status = 'cancelled', updated_at = now()
    from delivery_stops st join orders o on o.id = st.order_id
    where a.id = st.assignment_id and o.delivery_session_id = s.id
      and o.delivery_status in ('created', 'ready_for_pickup') and a.status not in ('completed', 'cancelled');
  update orders set assigned_rider_id = null, updated_at = now()
    where delivery_session_id = s.id and delivery_status in ('created', 'ready_for_pickup') and assigned_rider_id is not null;
  update delivery_stops st set rider_id = null, assignment_id = null, sequence = null, updated_at = now()
    from orders o where o.id = st.order_id and o.delivery_session_id = s.id and o.delivery_status in ('created', 'ready_for_pickup');
  perform set_config('cefflo.plan_recovery', '', true);

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (s.business_id, 'run.outsourced', auth.uid(), 'vendor',
            jsonb_build_object('delivery_session_id', s.id, 'outsourcing_id', ob.id, 'provider_name', ob.provider_name,
                               'external_reference', ob.external_reference, 'previous_rider_ids', v_prev,
                               'reason', p_reason, 'note', p_note, 'plan_locked', s.sorting_started_at is not null));
  return jsonb_build_object('delivery_session_id', s.id, 'outsourcing_id', ob.id, 'provider_name', ob.provider_name,
                            'previous_rider_ids', v_prev);
end;
$$;

-- Copy Delivery Data / Export CSV contract: only what an external provider
-- needs to deliver this Run. Operator/Owner only; every export is audited.
create function public.outsource_run_export(p_delivery_session_id uuid) returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  s delivery_sessions;
  b businesses;
  v jsonb;
begin
  select * into s from delivery_sessions where id = p_delivery_session_id;
  if s.id is null or not is_business_operational(s.business_id) then
    raise exception 'forbidden';
  end if;
  select * into b from businesses where id = s.business_id;
  select jsonb_build_object(
    'run', jsonb_build_object('id', s.id, 'name', s.name, 'delivery_date', s.delivery_date),
    'pickup', jsonb_build_object('business_name', b.name, 'address', b.address, 'phone', b.phone),
    'orders', coalesce(jsonb_agg(jsonb_build_object(
      'order_number', o.order_number,
      'customer_name', o.customer_name,
      'customer_phone', o.customer_phone,
      'delivery_address', o.delivery_address,
      'latitude', o.latitude,
      'longitude', o.longitude,
      'items', o.items,
      'notes', nullif(o.notes, '')
    ) order by st.sequence nulls last, o.created_at), '[]'::jsonb)
  ) into v
  from orders o join delivery_stops st on st.order_id = o.id
  where o.delivery_session_id = s.id and o.delivery_status in ('created', 'ready_for_pickup');
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (s.business_id, 'run.outsource_exported', auth.uid(), 'vendor',
            jsonb_build_object('delivery_session_id', s.id, 'orders', jsonb_array_length(v->'orders')));
  return v;
end;
$$;

-- External handover: custody to the provider for the whole Run, only once
-- the Run is Ready for Pickup where the Helper workflow applies. Recorded as
-- an external handover by the Vendor/Helper user who performed it.
create function public.confirm_external_handover(p_delivery_session_id uuid) returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  s delivery_sessions;
  ob delivery_outsourcing;
  v_total int;
  v_ready int;
  v_role text;
begin
  select * into s from delivery_sessions where id = p_delivery_session_id for update;
  if s.id is null or not is_business_fulfilment(s.business_id) then
    raise exception 'forbidden';
  end if;
  select * into ob from delivery_outsourcing where delivery_session_id = s.id and status = 'active' for update;
  if ob.id is null then
    raise exception 'run is not outsourced';
  end if;
  v_role := case when is_business_operational(s.business_id) then 'vendor' else 'helper' end;

  select count(*), count(*) filter (where st.preparation_status in ('not_started', 'ready'))
    into v_total, v_ready
    from orders o join delivery_stops st on st.order_id = o.id
    where o.delivery_session_id = s.id and o.delivery_status in ('created', 'ready_for_pickup');
  if v_total = 0 then
    raise exception 'no orders to hand over';
  end if;
  if v_ready < v_total then
    raise exception 'not ready for pickup: % / % ready', v_ready, v_total;
  end if;

  insert into delivery_events(business_id, order_id, delivery_stop_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    select s.business_id, o.id, st.id, 'delivery.external_handover', o.delivery_status, 'picked_up', auth.uid(), v_role,
           jsonb_build_object('outsourcing_id', ob.id, 'provider_name', ob.provider_name, 'external_reference', ob.external_reference)
    from orders o join delivery_stops st on st.order_id = o.id
    where o.delivery_session_id = s.id and o.delivery_status in ('created', 'ready_for_pickup');
  update delivery_stops st set status = 'picked_up', updated_at = now()
    from orders o where o.id = st.order_id and o.delivery_session_id = s.id and o.delivery_status in ('created', 'ready_for_pickup');
  update orders set delivery_status = 'picked_up', updated_at = now()
    where delivery_session_id = s.id and delivery_status in ('created', 'ready_for_pickup');
  update delivery_outsourcing set status = 'handed_over', handed_over_at = now(), handed_over_by = auth.uid(), updated_at = now()
    where id = ob.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (s.business_id, 'run.external_handover', auth.uid(), v_role,
            jsonb_build_object('delivery_session_id', s.id, 'outsourcing_id', ob.id,
                               'provider_name', ob.provider_name, 'orders', v_total));
  return jsonb_build_object('delivery_session_id', s.id, 'orders', v_total, 'provider_name', ob.provider_name);
end;
$$;

revoke all on function public.replace_run_rider(uuid, uuid, text, text) from public, anon;
revoke all on function public.outsource_run(uuid, text, text, text, text, text, text, text) from public, anon;
revoke all on function public.outsource_run_export(uuid) from public, anon;
revoke all on function public.confirm_external_handover(uuid) from public, anon;
revoke all on function public.recovery_reason_valid(text, text) from public, anon, authenticated;
grant execute on function public.replace_run_rider(uuid, uuid, text, text) to authenticated;
grant execute on function public.outsource_run(uuid, text, text, text, text, text, text, text) to authenticated;
grant execute on function public.outsource_run_export(uuid) to authenticated;
grant execute on function public.confirm_external_handover(uuid) to authenticated;

-- Internal Rider pickup gate (otherwise identical to the current definition).
CREATE OR REPLACE FUNCTION public.rider_transition(p_rider_id uuid, p_order_id uuid, p_next delivery_status, p_idempotency_key text DEFAULT NULL::text)
 RETURNS orders
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  o orders;
  old delivery_status;
  ok boolean;
  a_status assignment_status;
  my_seq int;
  my_locked timestamptz;
  my_session uuid;
  incomplete_earlier int;
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

  old = o.delivery_status;
  if old = p_next then
    return o;
  end if;

  ok = (old = 'created' and p_next = 'ready_for_pickup')
    or (old = 'ready_for_pickup' and p_next = 'picked_up')
    or (old = 'picked_up' and p_next = 'out_for_delivery')
    or (old = 'out_for_delivery' and p_next = 'arrived');
  if not ok then
    raise exception 'invalid transition % -> %', old, p_next;
  end if;

  -- D-74: where the Helper fulfilment workflow applies to this order
  -- (preparation has started), an internal Rider cannot take custody
  -- before Ready for Pickup (packing + sorting confirmed).
  if p_next = 'picked_up' and exists (
    select 1 from delivery_stops where order_id = o.id and preparation_status in ('preparing', 'packed', 'sorted')
  ) then
    raise exception 'not ready for pickup';
  end if;

  if p_next in ('out_for_delivery', 'arrived') then
    select s.sequence, s.sequence_locked_at, a.delivery_session_id
      into my_seq, my_locked, my_session
      from delivery_stops s join rider_assignments a on a.id = s.assignment_id
      where s.order_id = o.id;

    if my_session is not null and my_locked is null then
      raise exception 'sequence not locked';
    end if;

    if my_locked is not null then
      select count(*) into incomplete_earlier
        from delivery_stops s2
        join rider_assignments a2 on a2.id = s2.assignment_id
        join orders o2 on o2.id = s2.order_id
        where a2.rider_id = p_rider_id
          and a2.delivery_session_id = my_session
          and a2.status not in ('declined','cancelled','completed','issue')
          and s2.sequence < my_seq
          and o2.delivery_status <> 'delivered';
      if incomplete_earlier > 0 then
        raise exception 'complete earlier stop first';
      end if;
    end if;
  end if;

  update orders set delivery_status = p_next, updated_at = now() where id = o.id returning * into o;
  update delivery_stops set status = p_next, arrived_at = case when p_next = 'arrived' then now() else arrived_at end, updated_at = now() where order_id = o.id;
  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    select o.business_id, o.id, s.id, s.assignment_id, 'delivery.status_changed', old, p_next, auth.uid(), 'rider', jsonb_build_object('idempotency_key', p_idempotency_key)
    from delivery_stops s where s.order_id = o.id;
  return o;
end;
$function$;

-- Helper contract: handover destination includes an External Provider (name, driver, vehicle only).
CREATE OR REPLACE FUNCTION public.my_fulfilment_tasks(p_business_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
        'handover_external', case when (s.preparation_status = 'ready' or o.delivery_status = 'picked_up') and ob.id is not null
          then jsonb_build_object('provider_name', ob.provider_name, 'driver_name', ob.driver_name, 'vehicle', ob.vehicle) end,
        'picked_up_at', pu.at,
        'created_at', o.created_at
      ) order by o.order_date nulls last, z.name nulls last, ds.name nulls last, s.sequence nulls last, o.created_at)
      from orders o
      join delivery_stops s on s.order_id = o.id
      left join delivery_sessions ds on ds.id = o.delivery_session_id
      left join zones z on z.id = o.zone_id
      left join riders r on r.id = o.assigned_rider_id
      left join delivery_outsourcing ob on ob.delivery_session_id = o.delivery_session_id and ob.status in ('active', 'handed_over')
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
$function$;
