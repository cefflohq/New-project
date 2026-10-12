-- Planner reasons for orders that cannot join a new run (Founder-approved,
-- 2026-10-12). Reporting only: eligibility, the plan-lock guard and every
-- other part of propose_delivery_plan (20261012120000) are unchanged.
--
--   in_preparation     preparation 'preparing' (build_rider_run refuses it)
--   in_locked_run      the order sits in a plan-locked run; only whole-run
--                      recovery (replace_run_rider / outsource_run) moves it
--   sorted_before_run  'sorted'/'ready' with no plan-locked run: sorted
--                      before a run existed, locked to its zone group by
--                      orders_plan_lock_guard (202609280009)
--
-- Same signature, so CREATE OR REPLACE keeps the existing grants.

create or replace function public.propose_delivery_plan(
  p_business_id uuid,
  p_rider_ids uuid[] default null,
  p_policy text default 'balance'
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  b businesses;
  groups jsonb := '[]'::jsonb;
  unplannable jsonb := '[]'::jsonb;
  excluded jsonb := '[]'::jsonb;
  u record;
  rd record;
  path_ids uuid[];
  chunk uuid[];
  seq_result jsonb;
  unit_requirement public.vehicle_requirement;
  unit_key text;
  left_n int;
  pos int;
  j int;
  k int;
  i int;
  cum int;
  take int;
  later_cap int;
  leftover_reason text;
  picks uuid[];
  takes int[];
  pick_caps int[];
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_policy is null or p_policy not in ('balance','fill') then
    raise exception 'invalid policy';
  end if;
  if p_rider_ids is not null and cardinality(p_rider_ids) = 0 then
    raise exception 'no drivers selected';
  end if;
  select * into b from businesses where id = p_business_id;

  -- Orders in scope. Defensive drop: ON COMMIT DROP only fires at commit, so
  -- two calls in one transaction would otherwise collide (as in 202609030004).
  drop table if exists tmp_plan_scope;
  create temporary table tmp_plan_scope on commit drop as
    select o.id as order_id, o.zone_id, z.name as zone_name, o.vehicle_requirement,
           o.location_status::text as location_status, ds.preparation_status::text as preparation_status,
           o.approved_at,
           (o.delivery_session_id is not null and run_plan_locked(o.delivery_session_id)) as plan_locked,
           case o.vehicle_requirement when 'van_required' then 1 when 'car_or_larger' then 2 else 3 end as tier_rank
    from orders o
    join delivery_stops ds on ds.order_id = o.id
    left join zones z on z.id = o.zone_id
    where o.business_id = p_business_id
      and o.delivery_status = 'created'
      and o.approved_at is not null
      and o.assigned_rider_id is null;

  select coalesce(jsonb_agg(jsonb_build_object(
      'order_id', order_id,
      'reason', case
        when location_status <> 'resolved' then 'location_' || location_status
        when plan_locked then 'in_locked_run'
        when preparation_status in ('sorted','ready') then 'sorted_before_run'
        else 'in_preparation'
      end,
      'zone_id', zone_id,
      'required_vehicle', vehicle_requirement,
      'approved_at', approved_at
    ) order by order_id), '[]'::jsonb)
    into unplannable
    from tmp_plan_scope
    where location_status <> 'resolved' or preparation_status in ('preparing','sorted','ready') or plan_locked;
  delete from tmp_plan_scope where location_status <> 'resolved' or preparation_status in ('preparing','sorted','ready') or plan_locked;

  -- Riders.
  drop table if exists tmp_plan_riders;
  create temporary table tmp_plan_riders on commit drop as
    select r.id as rider_id, r.name, r.vehicle_type,
           case r.vehicle_type when 'motorcycle' then 1 when 'car' then 2 else 3 end as vehicle_rank,
           rider_effective_capacity(r.id) - rider_active_stop_count(r.id) as remaining,
           exists(select 1 from rider_assignments a
                  where a.rider_id = r.id and a.status in ('assigned','accepted','picking_up','delivering')) as has_open_run,
           false as used
    from riders r
    where r.business_id = p_business_id
      and r.status = 'active'
      and (p_rider_ids is null or r.id = any(p_rider_ids));

  if p_rider_ids is not null then
    select coalesce(jsonb_agg(jsonb_build_object('rider_id', x, 'reason', 'not_eligible') order by x), '[]'::jsonb)
      into excluded
      from (select distinct unnest(p_rider_ids) as x) s
      where not exists (select 1 from tmp_plan_riders t where t.rider_id = s.x);
  end if;
  select excluded || coalesce(jsonb_agg(jsonb_build_object(
      'rider_id', rider_id, 'rider_name', name,
      'reason', case when has_open_run then 'rider_has_open_run' else 'no_capacity' end
    ) order by rider_id), '[]'::jsonb)
    into excluded
    from tmp_plan_riders
    where has_open_run or remaining <= 0;
  delete from tmp_plan_riders where has_open_run or remaining <= 0;

  -- Units, deterministic order.
  for u in
    select tier_rank, zone_id, min(zone_name) as zone_name, count(*) as n
    from tmp_plan_scope
    group by tier_rank, zone_id
    order by tier_rank, (zone_id is null), count(*) desc, min(zone_name), zone_id
  loop
    unit_requirement := case u.tier_rank when 1 then 'van_required' when 2 then 'car_or_larger' else 'any' end;
    unit_key := coalesce(u.zone_id::text, 'unzoned') || ':' || unit_requirement::text;

    select array_agg(order_id order by order_id) into path_ids
      from tmp_plan_scope where tier_rank = u.tier_rank and zone_id is not distinct from u.zone_id;
    seq_result := sequence_group_nearest_neighbor(path_ids, b.service_origin_latitude, b.service_origin_longitude);
    select array_agg((s->>'order_id')::uuid order by (s->>'sequence')::int) into path_ids
      from jsonb_array_elements(seq_result->'stops') s;
    left_n := cardinality(path_ids);

    -- Candidate riders for this unit, in allocation order.
    select array_agg(rider_id order by vehicle_rank, remaining desc, rider_id),
           array_agg(remaining order by vehicle_rank, remaining desc, rider_id)
      into picks, pick_caps
      from tmp_plan_riders
      where not used and is_vehicle_compatible(vehicle_type, unit_requirement);

    takes := '{}';
    if picks is not null then
      if p_policy = 'fill' then
        k := cardinality(picks);
      else
        -- Fewest riders whose remaining capacity covers the unit.
        k := 0; cum := 0;
        while k < cardinality(picks) and cum < left_n loop
          k := k + 1; cum := cum + pick_caps[k];
        end loop;
      end if;
      i := 1;
      while i <= k and left_n > 0 loop
        if p_policy = 'fill' then
          take := least(pick_caps[i], left_n);
        else
          later_cap := 0;
          for j in i + 1 .. k loop later_cap := later_cap + pick_caps[j]; end loop;
          take := least(pick_caps[i], greatest(ceil(left_n::numeric / (k - i + 1))::int, left_n - later_cap));
        end if;
        takes := takes || take;
        left_n := left_n - take;
        i := i + 1;
      end loop;
    end if;

    pos := 1;
    for i in 1 .. coalesce(cardinality(takes), 0) loop
      chunk := path_ids[pos : pos + takes[i] - 1];
      pos := pos + takes[i];
      select * into rd from tmp_plan_riders where rider_id = picks[i];
      update tmp_plan_riders set used = true where rider_id = picks[i];
      seq_result := sequence_group_nearest_neighbor(chunk, b.service_origin_latitude, b.service_origin_longitude);
      groups := groups || jsonb_build_array(jsonb_build_object(
        'group_key', unit_key || ':' || i,
        'zone_id', u.zone_id,
        'candidate_rider_id', rd.rider_id,
        'candidate_rider_name', rd.name,
        'candidate_rider_vehicle_type', rd.vehicle_type,
        'required_vehicle', unit_requirement,
        'stops', seq_result->'stops',
        'total_distance_km', seq_result->'total_distance_km',
        'tier', unit_requirement,
        'part', i,
        'parts', cardinality(takes),
        'rider_remaining_after', rd.remaining - takes[i]
      ));
    end loop;

    if pos <= cardinality(path_ids) then
      leftover_reason := case
        when exists(select 1 from riders r where r.business_id = p_business_id and r.status = 'active'
                      and (p_rider_ids is null or r.id = any(p_rider_ids))
                      and is_vehicle_compatible(r.vehicle_type, unit_requirement))
        then 'insufficient_capacity' else 'vehicle_incompatible' end;
      select unplannable || coalesce(jsonb_agg(jsonb_build_object(
          'order_id', t.order_id, 'reason', leftover_reason, 'zone_id', t.zone_id,
          'required_vehicle', t.vehicle_requirement, 'approved_at', t.approved_at
        ) order by x.ord), '[]'::jsonb)
        into unplannable
        from unnest(path_ids[pos : cardinality(path_ids)]) with ordinality as x(order_id, ord)
        join tmp_plan_scope t on t.order_id = x.order_id;
    end if;
  end loop;

  -- Orders still held by a declined run: visible, never planned here.
  select unplannable || coalesce(jsonb_agg(jsonb_build_object(
      'order_id', o.id, 'reason', 'declined_awaiting_recovery', 'zone_id', o.zone_id,
      'required_vehicle', o.vehicle_requirement, 'approved_at', o.approved_at
    ) order by o.id), '[]'::jsonb)
    into unplannable
    from orders o
    join delivery_stops ds on ds.order_id = o.id
    join rider_assignments a on a.id = ds.assignment_id
    where o.business_id = p_business_id
      and o.delivery_status = 'created'
      and o.approved_at is not null
      and o.assigned_rider_id is not null
      and a.status = 'declined';

  return jsonb_build_object(
    'business_id', p_business_id,
    'generated_at', now(),
    'plan_date', (now() at time zone b.timezone)::date,
    'policy', p_policy,
    'groups', groups,
    'unplannable_orders', unplannable,
    'excluded_riders', excluded
  );
end;
$$;
