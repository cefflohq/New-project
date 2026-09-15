-- S4-11 Batch 4 (Grow V1 Flow 2, A4): Deterministic Optimization Engine V1.
--
-- Flow 1's central finding (audit report §3/§8): "No optimizer exists. What
-- exists is deterministic, 100% human-driven grouping and sequencing" via
-- build_rider_run (manual order/rider selection) and save_run_sequence
-- (manual drag-and-drop). This migration adds the missing PROPOSAL step
-- upstream of those two -- it never bypasses them. The Vendor still calls
-- the existing build_rider_run/save_run_sequence to actually commit a run;
-- propose_delivery_plan only produces a reviewable recommendation.
--
-- Architecture (Founder-locked, scope-lock §12): deterministic foundation,
-- authoritative. Geocoding -> deterministic vehicle/capacity-aware grouping
-- -> deterministic sequencing -> proposal -> (optional AI explanation, not
-- built here) -> Vendor review -> dispatch via the existing RPCs. No LLM
-- is used or required to compute the plan; distance is straight-line
-- haversine (A2's haversine_km) -- deliberately not an external
-- routing/distance provider, per the Master MD's "choose the smallest
-- launch-reliable design" and "no specific provider is locked at Flow 1/2."
--
-- Deliberate V1 scope limit (documented, not silently dropped): a group
-- that exceeds every compatible Rider's remaining capacity is reported
-- unplannable as a whole, with a factual reason, rather than auto-split
-- into capacity-sized chunks. Auto-splitting is a reasonable Flow 3
-- enhancement; it is not implemented here so the shipped algorithm stays
-- small enough to fully reason about and test in one pass.

-- Not marked STABLE: it creates a session-local temporary table as a
-- working set for the multi-pass grouping/sequencing logic below, and
-- Postgres does not permit CREATE TABLE AS inside a STABLE function. It
-- performs no INSERT/UPDATE/DELETE on any real application table -- purely
-- read-then-compute -- so it remains safe to call freely and repeatedly;
-- only the strict "same snapshot in, byte-identical plan out" volatility
-- label doesn't apply at the Postgres function-metadata level.
create function public.propose_delivery_plan(p_business_id uuid) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  b businesses;
  groups jsonb := '[]'::jsonb;
  unplannable jsonb := '[]'::jsonb;
  grp_key text;
  grp_rec record;
  grp_zone_id uuid;
  grp_order_ids uuid[];
  grp_size int;
  grp_worst_requirement public.vehicle_requirement;
  candidate riders;
  seq_result jsonb;
  origin_lat double precision;
  origin_lng double precision;
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  select * into b from businesses where id = p_business_id;
  origin_lat := b.service_origin_latitude;
  origin_lng := b.service_origin_longitude;

  -- Scope: same base eligibility as list_plannable_orders (approved,
  -- unassigned, created), narrowed further to location_status = 'resolved'
  -- -- an unresolved/ambiguous/failed order is explicitly excluded from
  -- automatic planning per A1's own requirement, and surfaced honestly as
  -- unplannable rather than silently skipped.
  -- Defensive drop: ON COMMIT DROP only fires at actual transaction commit,
  -- so two calls to this function inside one caller transaction would
  -- otherwise collide on the same temp table name. Explicit drop-then-create
  -- makes repeated calls safe regardless of caller transaction shape.
  drop table if exists tmp_plan_scope;
  create temporary table tmp_plan_scope on commit drop as
    select o.id as order_id, o.zone_id, o.latitude, o.longitude, o.vehicle_requirement, o.location_status
    from orders o
    where o.business_id = p_business_id
      and o.delivery_status = 'created'
      and o.approved_at is not null
      and o.assigned_rider_id is null;

  select coalesce(jsonb_agg(jsonb_build_object('order_id', order_id, 'reason', 'location_' || location_status)), '[]'::jsonb)
    into unplannable
    from tmp_plan_scope where location_status <> 'resolved';

  delete from tmp_plan_scope where location_status <> 'resolved';

  -- Group by zone (Founder-confirmed manual label, reused as-is for
  -- grouping -- not reinterpreted as geospatial truth); ungrouped orders
  -- (no zone assigned) share one deterministic 'unzoned' bucket rather than
  -- each becoming a singleton group, which would defeat multi-drop planning
  -- entirely for vendors who haven't adopted Zones yet.
  for grp_rec in
    select coalesce(zone_id::text, 'unzoned') as key, zone_id
    from tmp_plan_scope
    group by zone_id
    order by coalesce(zone_id::text, 'unzoned')
  loop
    grp_key := grp_rec.key;
    grp_zone_id := grp_rec.zone_id;
    select array_agg(order_id order by order_id) into grp_order_ids
      from tmp_plan_scope where zone_id is not distinct from grp_zone_id;
    grp_size := array_length(grp_order_ids, 1);

    -- Most restrictive requirement present in the group -- a candidate
    -- rider must satisfy the hardest constraint in the set, since one
    -- rider executes the whole proposed group.
    select case
      when bool_or(vehicle_requirement = 'van_required') then 'van_required'
      when bool_or(vehicle_requirement = 'car_or_larger') then 'car_or_larger'
      else 'any'
    end::public.vehicle_requirement
    into grp_worst_requirement
    from tmp_plan_scope where zone_id is not distinct from grp_zone_id;

    select r.* into candidate
      from riders r
      where r.business_id = p_business_id
        and r.status = 'active'
        and is_vehicle_compatible(r.vehicle_type, grp_worst_requirement)
        and rider_effective_capacity(r.id) - rider_active_stop_count(r.id) >= grp_size
      order by (rider_effective_capacity(r.id) - rider_active_stop_count(r.id)) desc, r.id asc
      limit 1;

    if candidate.id is null then
      unplannable := unplannable || jsonb_build_array(jsonb_build_object(
        'group_key', grp_key,
        'order_ids', to_jsonb(grp_order_ids),
        'reason', 'no_compatible_capacity_sufficient_rider',
        'required_vehicle', grp_worst_requirement,
        'group_size', grp_size
      ));
      continue;
    end if;

    seq_result := sequence_group_nearest_neighbor(grp_order_ids, origin_lat, origin_lng);

    groups := groups || jsonb_build_array(jsonb_build_object(
      'group_key', grp_key,
      'zone_id', grp_zone_id,
      'candidate_rider_id', candidate.id,
      'candidate_rider_name', candidate.name,
      'candidate_rider_vehicle_type', candidate.vehicle_type,
      'required_vehicle', grp_worst_requirement,
      'stops', seq_result->'stops',
      'total_distance_km', seq_result->'total_distance_km'
    ));
  end loop;

  return jsonb_build_object(
    'business_id', p_business_id,
    'generated_at', now(),
    'groups', groups,
    'unplannable_orders', unplannable
  );
end;
$$;

-- Deterministic nearest-neighbor sequencer, factored out so it can be
-- unit-exercised on its own and reused unchanged if a future group-splitting
-- pass (Flow 3) needs to re-sequence a sub-chunk. Greedy nearest-unvisited
-- from a fixed start point; ties broken by order id ascending, so the same
-- input snapshot always produces the same sequence (required determinism).
create function public.sequence_group_nearest_neighbor(
  p_order_ids uuid[],
  p_start_lat double precision,
  p_start_lng double precision
) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  remaining uuid[] := p_order_ids;
  cur_lat double precision := p_start_lat;
  cur_lng double precision := p_start_lng;
  stops jsonb := '[]'::jsonb;
  total_km double precision := 0;
  seq int := 1;
  next_id uuid;
  next_lat double precision;
  next_lng double precision;
  best_dist double precision;
  d double precision;
  oid uuid;
  olat double precision;
  olng double precision;
  have_start boolean := (p_start_lat is not null and p_start_lng is not null);
begin
  -- No configured business origin: deterministically seed from the lowest
  -- order id's own coordinates rather than treating distance-from-nowhere
  -- as zero (which would silently bias the first pick). This only affects
  -- which order is picked FIRST; every subsequent pick is still genuine
  -- nearest-neighbor.
  if not have_start then
    select o.id, o.latitude, o.longitude into next_id, cur_lat, cur_lng
      from orders o where o.id = any(remaining) order by o.id asc limit 1;
  end if;

  while array_length(remaining, 1) > 0 loop
    best_dist := null;
    next_id := null;
    foreach oid in array remaining loop
      select o.latitude, o.longitude into olat, olng from orders o where o.id = oid;
      d := haversine_km(cur_lat, cur_lng, olat, olng);
      if best_dist is null or d < best_dist or (d = best_dist and oid < next_id) then
        best_dist := d;
        next_id := oid;
        next_lat := olat;
        next_lng := olng;
      end if;
    end loop;

    stops := stops || jsonb_build_array(jsonb_build_object(
      'order_id', next_id,
      'sequence', seq,
      'distance_from_previous_km', round(best_dist::numeric, 3)
    ));
    total_km := total_km + best_dist;
    cur_lat := next_lat;
    cur_lng := next_lng;
    seq := seq + 1;
    remaining := array_remove(remaining, next_id);
  end loop;

  return jsonb_build_object('stops', stops, 'total_distance_km', round(total_km::numeric, 3));
end;
$$;

revoke all on function public.propose_delivery_plan(uuid) from public, anon;
grant execute on function public.propose_delivery_plan(uuid) to authenticated;
revoke all on function public.sequence_group_nearest_neighbor(uuid[], double precision, double precision) from public, anon;
grant execute on function public.sequence_group_nearest_neighbor(uuid[], double precision, double precision) to authenticated;
