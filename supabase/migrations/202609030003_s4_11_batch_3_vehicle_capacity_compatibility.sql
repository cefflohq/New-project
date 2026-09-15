-- S4-11 Batch 3 (Grow V1 Flow 2, A3): Rider vehicle type, capacity, and
-- order/delivery vehicle-compatibility -- the central Vehicle & Capacity
-- Scope Addendum requirement, now made canonical.
--
-- Flow 1 finding (audit report §3a): riders had exactly one vehicle-related
-- column (vehicle_plate) and onboarding was hardcoded motorcycle-only;
-- zero occurrences of "driver" anywhere in the repo, so canonical role
-- stays Rider throughout -- this migration never introduces a Driver
-- identity/workspace.

create type public.rider_vehicle_type as enum ('motorcycle','car','van');

-- Order/delivery-level minimum vehicle-compatibility requirement (Founder-
-- decided REQUIRED V1 at scope freeze, CEFFLO_GROW_V1_SCOPE_LOCK.md §11a).
-- Deterministic hierarchy, illustrative naming per the addendum -- not a
-- weight/volume/dimension model; no evidence supports that complexity.
create type public.vehicle_requirement as enum ('any','motorcycle_ok','car_or_larger','van_required');

alter table public.riders
  add column vehicle_type public.rider_vehicle_type,
  add column capacity_override integer check (capacity_override is null or capacity_override > 0);

-- Backfill: Flow 1 confirmed onboarding was 100% hardcoded motorcycle-only
-- (rider/index.html Signup Step 3/4) -- every existing Rider was, in
-- practice, onboarded as a motorcycle rider. This is a documented factual
-- inference from verified product behavior, not an invented default.
update public.riders set vehicle_type = 'motorcycle' where vehicle_type is null;
alter table public.riders alter column vehicle_type set not null;
alter table public.riders alter column vehicle_type set default 'motorcycle';

alter table public.orders
  add column vehicle_requirement public.vehicle_requirement not null default 'any';

-- Deterministic vehicle-capability hierarchy: motorcycle < car < van. A
-- requirement is satisfied by that vehicle class or anything "larger."
create function public.is_vehicle_compatible(
  p_vehicle public.rider_vehicle_type,
  p_requirement public.vehicle_requirement
) returns boolean
language sql immutable
as $$
select case p_requirement
  when 'any' then true
  when 'motorcycle_ok' then true
  when 'car_or_larger' then p_vehicle in ('car','van')
  when 'van_required' then p_vehicle = 'van'
end
$$;

-- V1 default capacity per vehicle class (max concurrent active stops).
-- Bounded, launch-reliable values chosen per the addendum's own instruction
-- to recommend a simple model rather than invent weight/volume math; these
-- specific numbers are a tunable operational default, not derived from
-- hard usage evidence -- documented here for Founder/ops review post-launch,
-- overridable per-Rider via capacity_override below.
create function public.default_capacity_for_vehicle(p_vehicle public.rider_vehicle_type) returns integer
language sql immutable
as $$
select case p_vehicle
  when 'motorcycle' then 6
  when 'car' then 12
  when 'van' then 20
end
$$;

create function public.rider_effective_capacity(p_rider_id uuid) returns integer
language sql stable
security definer
set search_path = public
as $$
select coalesce(r.capacity_override, default_capacity_for_vehicle(r.vehicle_type))
from riders r where r.id = p_rider_id
$$;

-- Active workload = stops assigned to this Rider not yet in a terminal
-- state. 'issue' counts as active (unresolved workload); 'delivered' and
-- 'cancelled' do not.
create function public.rider_active_stop_count(p_rider_id uuid) returns integer
language sql stable
security definer
set search_path = public
as $$
select count(*)::integer
from delivery_stops s
where s.rider_id = p_rider_id
  and s.status not in ('delivered','cancelled')
$$;

-- Read-only pre-check the Vendor UI calls BEFORE build_rider_run, so a
-- conflict can be shown and confirmed rather than discovered only as a
-- raised exception. Returns the full violation set even when
-- compatible=false is already knowable from the first violation, so the
-- Vendor sees every problem in one call, not one at a time.
create function public.check_run_vehicle_capacity(p_rider_id uuid, p_order_ids uuid[]) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  r riders;
  violations jsonb;
  current_load integer;
  requested_count integer;
begin
  select * into r from riders where id = p_rider_id;
  if r.id is null or not is_business_member(r.business_id) then
    raise exception 'forbidden';
  end if;
  requested_count := coalesce(array_length(p_order_ids, 1), 0);

  select coalesce(jsonb_agg(jsonb_build_object(
      'order_id', o.id,
      'reason', 'vehicle_incompatible',
      'vehicle_requirement', o.vehicle_requirement,
      'rider_vehicle_type', r.vehicle_type
    )), '[]'::jsonb)
  into violations
  from orders o
  where o.id = any(p_order_ids)
    and not is_vehicle_compatible(r.vehicle_type, o.vehicle_requirement);

  current_load := rider_active_stop_count(p_rider_id);
  if current_load + requested_count > rider_effective_capacity(p_rider_id) then
    violations := violations || jsonb_build_array(jsonb_build_object(
      'reason', 'capacity_exceeded',
      'current_load', current_load,
      'requested', requested_count,
      'effective_capacity', rider_effective_capacity(p_rider_id)
    ));
  end if;

  return jsonb_build_object('compatible', jsonb_array_length(violations) = 0, 'violations', violations);
end;
$$;

revoke all on function public.check_run_vehicle_capacity(uuid, uuid[]) from public, anon;
grant execute on function public.check_run_vehicle_capacity(uuid, uuid[]) to authenticated;

-- update_rider_details: add vehicle_type / capacity_override. Byte-identical
-- to the existing S4-03 version otherwise (same forbidden check, same
-- coalesce-on-null "only touch what's provided" pattern). Must drop the old
-- 4-type signature first -- a new trailing param changes the type list, so
-- CREATE OR REPLACE would otherwise leave both overloads live (the same
-- pitfall the S4-06 zones migration already documented for create_delivery).
drop function if exists public.update_rider_details(uuid,text,text,text);

create function public.update_rider_details(
  p_rider_id uuid,
  p_name text default null,
  p_phone text default null,
  p_vehicle_plate text default null,
  p_vehicle_type public.rider_vehicle_type default null,
  p_capacity_override integer default null
) returns public.riders
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.riders;
begin
  select * into r from public.riders where id = p_rider_id for update;
  if r.id is null or not public.is_business_member(r.business_id) then
    raise exception 'forbidden';
  end if;
  if p_capacity_override is not null and p_capacity_override <= 0 then
    raise exception 'capacity override must be positive';
  end if;

  update public.riders set
    name = coalesce(p_name, name),
    phone = coalesce(p_phone, phone),
    vehicle_plate = coalesce(p_vehicle_plate, vehicle_plate),
    vehicle_type = coalesce(p_vehicle_type, vehicle_type),
    capacity_override = case when p_capacity_override is not null then p_capacity_override else capacity_override end,
    updated_at = now()
  where id = p_rider_id
  returning * into r;
  return r;
end;
$$;

revoke all on function public.update_rider_details(uuid,text,text,text,public.rider_vehicle_type,integer) from public, anon, authenticated;
grant execute on function public.update_rider_details(uuid,text,text,text,public.rider_vehicle_type,integer) to authenticated;

-- create_delivery: add p_vehicle_requirement as a new trailing default
-- param on top of the S4-06 zones version (p_zone_id). Must drop that
-- 9-type signature first (same overload pitfall as above) -- the zones
-- migration's own comment already documents why CREATE OR REPLACE alone
-- is not enough when the parameter list's type shape changes.
drop function if exists public.create_delivery(uuid,text,text,text,text,double precision,double precision,jsonb,uuid);

create function public.create_delivery(
  p_business_id uuid,
  p_customer_name text,
  p_customer_phone text,
  p_delivery_address text,
  p_notes text default '',
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_items jsonb default '[]',
  p_zone_id uuid default null,
  p_vehicle_requirement public.vehicle_requirement default 'any'
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  o orders;
  t text;
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_zone_id is not null and not exists(select 1 from zones where id = p_zone_id and business_id = p_business_id and status = 'active') then
    raise exception 'invalid zone';
  end if;
  insert into orders(business_id, customer_name, customer_phone, delivery_address, notes, latitude, longitude, items, zone_id, vehicle_requirement)
    values (p_business_id, p_customer_name, p_customer_phone, p_delivery_address, p_notes, p_latitude, p_longitude, coalesce(p_items,'[]'), p_zone_id, p_vehicle_requirement)
    returning * into o;
  insert into delivery_stops(business_id, order_id) values (p_business_id, o.id);
  t = encode(gen_random_bytes(32), 'hex');
  insert into tracking_tokens(order_id, token_hash) values (o.id, encode(digest(t,'sha256'),'hex'));
  insert into delivery_events(business_id, order_id, event_type, to_status, actor_user_id, actor_role)
    values (p_business_id, o.id, 'delivery.created', 'created', auth.uid(), 'vendor');
  return jsonb_build_object('order', to_jsonb(o), 'tracking_token', t);
end;
$$;

revoke all on function public.create_delivery(uuid,text,text,text,text,double precision,double precision,jsonb,uuid,public.vehicle_requirement) from public, anon, authenticated;
grant execute on function public.create_delivery(uuid,text,text,text,text,double precision,double precision,jsonb,uuid,public.vehicle_requirement) to authenticated;

-- update_order_details: add p_vehicle_requirement on top of the CURRENT
-- S4-06-zones version (p_zone_id/p_clear_zone + zone_changed audit event)
-- -- not the older pre-zones foundation version. Must drop that 8-type
-- signature first, same overload reasoning as above.
drop function if exists public.update_order_details(uuid,text,text,text,text,jsonb,uuid,boolean);

create function public.update_order_details(
  p_order_id uuid,
  p_customer_name text default null,
  p_customer_phone text default null,
  p_delivery_address text default null,
  p_notes text default null,
  p_items jsonb default null,
  p_zone_id uuid default null,
  p_clear_zone boolean default false,
  p_vehicle_requirement public.vehicle_requirement default null
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
  new_zone_id uuid;
  zone_changed boolean;
begin
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not public.is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;
  if o.delivery_status <> 'created' then
    raise exception 'order already dispatched';
  end if;

  if p_zone_id is not null then
    if not exists (select 1 from public.zones where id = p_zone_id and business_id = o.business_id and status = 'active') then
      raise exception 'invalid zone';
    end if;
    new_zone_id := p_zone_id;
  elsif p_clear_zone then
    new_zone_id := null;
  else
    new_zone_id := o.zone_id;
  end if;
  zone_changed := new_zone_id is distinct from o.zone_id;

  update public.orders set
    customer_name = coalesce(p_customer_name, customer_name),
    customer_phone = coalesce(p_customer_phone, customer_phone),
    delivery_address = coalesce(p_delivery_address, delivery_address),
    notes = coalesce(p_notes, notes),
    items = coalesce(p_items, items),
    zone_id = new_zone_id,
    vehicle_requirement = coalesce(p_vehicle_requirement, vehicle_requirement),
    updated_at = now()
  where id = p_order_id
  returning * into o;

  if zone_changed then
    insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role, metadata)
      values (o.business_id, o.id, 'order.zone_changed', auth.uid(), 'vendor', jsonb_build_object('zone_id', o.zone_id));
  end if;

  return o;
end;
$$;

revoke all on function public.update_order_details(uuid,text,text,text,text,jsonb,uuid,boolean,public.vehicle_requirement) from public, anon, authenticated;
grant execute on function public.update_order_details(uuid,text,text,text,text,jsonb,uuid,boolean,public.vehicle_requirement) to authenticated;

-- build_rider_run: add the vehicle/capacity eligibility layer as a
-- SEPARATE exception class from the existing session/approval/assignment
-- eligibility check above it (which stays byte-identical and remains a
-- hard, non-overridable block). Vehicle/capacity conflicts are Founder-
-- locked to "block by default, explicit audited override" (scope-lock
-- §11a/§16) -- p_override_capacity is a new trailing default param, so
-- every existing 4-arg call site keeps working unchanged (no override).
create function public.build_rider_run(
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
  if s.id is null or not is_business_member(s.business_id) then
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
    select business_id, approved_at, assigned_rider_id, delivery_status
    from orders
    where id = any(requested_ids)
    for update
  )
  select
    count(*),
    count(*) filter (
      where business_id = s.business_id
        and approved_at is not null
        and assigned_rider_id is null
        and delivery_status = 'created'
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
          'order_count', array_length(existing_order_ids,1)
        );
      else
        raise exception 'idempotency key conflict';
      end if;
    end if;

    raise exception 'orders no longer eligible';
  end if;

  -- Vehicle/capacity eligibility -- a distinct exception class from the
  -- basic eligibility check above. Blocked by default; the Vendor must
  -- have already called check_run_vehicle_capacity and explicitly chosen
  -- to override for this to proceed with violations present.
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

revoke all on function public.build_rider_run(uuid,uuid,uuid[],uuid,boolean) from public, anon, authenticated;
grant execute on function public.build_rider_run(uuid,uuid,uuid[],uuid,boolean) to authenticated;

-- Drop the old 4-arg signature: CREATE OR REPLACE cannot change a function's
-- parameter list shape in place when a new required-shape overload is
-- intended to fully supersede it (here it's additive-compatible, but the
-- OLD 4-arg entry in pg_proc is now a separate, redundant overload after
-- the 5-arg CREATE above -- Postgres treats different arg counts as
-- distinct functions, not a replacement). Drop it explicitly so there is
-- exactly one build_rider_run again, matching this project's "one
-- authoritative RPC per action" convention.
drop function if exists public.build_rider_run(uuid,uuid,uuid[],uuid);
