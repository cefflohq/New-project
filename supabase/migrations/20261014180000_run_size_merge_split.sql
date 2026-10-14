-- Target run size, merge and split (Auto Zone master guideline Part A
-- §3.2, Founder decisions D2/D3/D5, 2026-10-14).
--
-- * businesses.run_size_min / run_size_max: default 10 / 15, editable per
--   business (Owner / Operator) with set_business_run_size.
-- * propose_delivery_plan keeps its signature and response; it now merges
--   nearby under-minimum zones lying in the same direction (D3), splits
--   clusters above the maximum into compact patches that follow where the
--   orders are (D5), and flags each proposed run (zone_ids, merged,
--   below_target_size). Rider capacity still caps every run, as before.
--   Proposal only: the vendor reviews and dispatches as today.

alter table public.businesses add column if not exists run_size_min integer not null default 10;
alter table public.businesses add column if not exists run_size_max integer not null default 15;
alter table public.businesses drop constraint if exists businesses_run_size_check;
alter table public.businesses add constraint businesses_run_size_check
  check (run_size_min between 1 and 50 and run_size_max between 1 and 50 and run_size_min <= run_size_max);

create or replace function public.set_business_run_size(p_business_id uuid, p_min integer, p_max integer)
returns public.businesses
language plpgsql
security definer
set search_path = public
as $$
declare b public.businesses;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if p_min is null or p_max is null or p_min < 1 or p_max > 50 or p_min > p_max then
    raise exception 'run size must be 1-50 with minimum <= maximum';
  end if;
  update public.businesses set run_size_min = p_min, run_size_max = p_max, updated_at = now()
   where id = p_business_id returning * into b;
  insert into public.business_profile_audit(business_id, actor_user_id, changed_fields, request_id)
  values (p_business_id, auth.uid(), array['run_size_min', 'run_size_max'], null);
  return b;
end;
$$;
revoke all on function public.set_business_run_size(uuid, integer, integer) from public, anon;
grant execute on function public.set_business_run_size(uuid, integer, integer) to authenticated;

-- Initial bearing from point 1 to point 2, 0-360 degrees.
create or replace function public._bearing_deg(lat1 double precision, lng1 double precision, lat2 double precision, lng2 double precision)
returns double precision
language sql
immutable
set search_path = public
as $$
  select mod((degrees(atan2(
    sin(radians(lng2 - lng1)) * cos(radians(lat2)),
    cos(radians(lat1)) * sin(radians(lat2)) - sin(radians(lat1)) * cos(radians(lat2)) * cos(radians(lng2 - lng1))
  )) + 360)::numeric, 360)::double precision
$$;

-- Smallest angle between two bearings, 0-180.
create or replace function public._bearing_gap(a double precision, b double precision)
returns double precision
language sql
immutable
set search_path = public
as $$ select least(abs(a - b), 360 - abs(a - b)) $$;

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
  run_min int;
  run_max int;
  zu record;
  cand record;
  own text;
  total int;
  cu record;
  parts int;
  base_n int;
  rem_n int;
  p int;
  part_n int;
  cy double precision;
  cx double precision;
  sy double precision;
  sx double precision;
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
           o.latitude as lat, o.longitude as lng, null::text as cluster,
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

  -- Target run size (Founder D2: default 10-15, editable per business).
  run_min := coalesce(b.run_size_min, 10);
  run_max := greatest(coalesce(b.run_size_max, 15), run_min);

  -- One cluster per (vehicle tier, zone) to start.
  drop table if exists tmp_plan_units;
  create temporary table tmp_plan_units on commit drop as
    select tier_rank, zone_id, count(*)::int as n, avg(lat) as clat, avg(lng) as clng,
           coalesce(zone_id::text, 'unzoned') || ':' || tier_rank as own_key,
           coalesce(zone_id::text, 'unzoned') || ':' || tier_rank as cluster
    from tmp_plan_scope group by tier_rank, zone_id;

  -- D3: a zone under the minimum is merged with nearby under-minimum zones
  -- lying in the same direction from the business (bearing within 45
  -- degrees, centres within 8 km) while the run stays within the maximum.
  for zu in
    select * from tmp_plan_units
    where zone_id is not null and n < run_min
    order by tier_rank,
             case when b.service_origin_latitude is null then 0
                  else _bearing_deg(b.service_origin_latitude, b.service_origin_longitude, clat, clng) end,
             own_key
  loop
    select cluster into own from tmp_plan_units where own_key = zu.own_key;
    continue when own <> zu.own_key; -- already merged into another run
    select sum(n) into total from tmp_plan_units where cluster = own;
    while total < run_min loop
      select c.* into cand from tmp_plan_units c
      where c.tier_rank = zu.tier_rank and c.zone_id is not null and c.own_key <> zu.own_key
        and c.cluster = c.own_key and c.n < run_min and total + c.n <= run_max
        and not exists (select 1 from tmp_plan_units x where x.cluster = c.own_key and x.own_key <> c.own_key)
        and haversine_km(zu.clat, zu.clng, c.clat, c.clng) <= 8
        and (b.service_origin_latitude is null or _bearing_gap(
              _bearing_deg(b.service_origin_latitude, b.service_origin_longitude, zu.clat, zu.clng),
              _bearing_deg(b.service_origin_latitude, b.service_origin_longitude, c.clat, c.clng)) <= 45)
      order by haversine_km(zu.clat, zu.clng, c.clat, c.clng), c.own_key
      limit 1;
      exit when not found;
      update tmp_plan_units set cluster = own where own_key = cand.own_key;
      total := total + cand.n;
    end loop;
  end loop;
  update tmp_plan_scope s set cluster = pu.cluster
    from tmp_plan_units pu
   where pu.tier_rank = s.tier_rank and pu.zone_id is not distinct from s.zone_id;

  -- D5: a cluster above the maximum is split into balanced, compact patches
  -- that follow where its orders actually are (never a fixed slice): seed
  -- with the order farthest from the remaining orders' centre, take its
  -- nearest orders, repeat.
  for cu in
    select cluster, count(*)::int as n from tmp_plan_scope
    group by cluster having count(*) > run_max order by cluster
  loop
    parts := ceil(cu.n::numeric / run_max)::int;
    base_n := cu.n / parts;
    rem_n := cu.n % parts;
    for p in 1 .. parts - 1 loop
      part_n := base_n + case when p <= rem_n then 1 else 0 end;
      select avg(lat), avg(lng) into cy, cx from tmp_plan_scope where cluster = cu.cluster;
      select lat, lng into sy, sx from tmp_plan_scope where cluster = cu.cluster
        order by haversine_km(cy, cx, lat, lng) desc, order_id limit 1;
      update tmp_plan_scope set cluster = cu.cluster || '/' || p
       where order_id in (select order_id from tmp_plan_scope where cluster = cu.cluster
                          order by haversine_km(sy, sx, lat, lng), order_id limit part_n);
    end loop;
    update tmp_plan_scope set cluster = cu.cluster || '/' || parts where cluster = cu.cluster;
  end loop;

  -- Units, deterministic order.
  for u in
    select tier_rank, cluster,
           (array_agg(zone_id order by zone_name, zone_id) filter (where zone_id is not null))[1] as zone_id,
           coalesce(jsonb_agg(distinct zone_id) filter (where zone_id is not null), '[]'::jsonb) as zone_ids,
           min(zone_name) as zone_name, count(*) as n
    from tmp_plan_scope
    group by tier_rank, cluster
    order by tier_rank, bool_and(zone_id is null), count(*) desc, min(zone_name), cluster
  loop
    unit_requirement := case u.tier_rank when 1 then 'van_required' when 2 then 'car_or_larger' else 'any' end;
    unit_key := u.cluster || ':' || unit_requirement::text;

    select array_agg(order_id order by order_id) into path_ids
      from tmp_plan_scope where cluster = u.cluster;
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
        'rider_remaining_after', rd.remaining - takes[i],
        'zone_ids', u.zone_ids,
        'merged', jsonb_array_length(u.zone_ids) > 1,
        'below_target_size', u.n < run_min,
        'run_size_min', run_min,
        'run_size_max', run_max
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
    'run_size_min', run_min,
    'run_size_max', run_max,
    'groups', groups,
    'unplannable_orders', unplannable,
    'excluded_riders', excluded
  );
end;
$$;


