-- FOUNDR Phase 1: read-only cross-business admin RPCs, backed entirely by
-- tables that already exist. No plan/MRR/subscription fields anywhere here
-- -- that concept does not exist in this schema yet (see Phase 3 for the
-- honest, manually-admin-set version of it). Every function below is the
-- cross-business counterpart of an already-existing per-business read; the
-- only thing that changes is the authorization check (is_platform_admin()
-- instead of is_business_member()) and the removal of the business_id scope.

create function public.admin_stuck_riders(p_stale_minutes integer default 45)
returns table (
  rider_id uuid,
  business_id uuid,
  business_name text,
  rider_name text,
  rider_phone text,
  assignment_id uuid,
  assignment_status public.assignment_status,
  last_recorded_at timestamptz,
  minutes_since_last_location numeric
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;

  return query
    select
      r.id, r.business_id, b.name, r.name, r.phone,
      a.id, a.status,
      loc.last_seen,
      extract(epoch from (now() - loc.last_seen)) / 60.0
    from public.riders r
    join public.businesses b on b.id = r.business_id
    join public.rider_assignments a
      on a.rider_id = r.id
      and a.status in ('assigned', 'accepted', 'picking_up', 'delivering')
    left join lateral (
      select max(recorded_at) as last_seen
      from public.rider_locations rl
      where rl.rider_id = r.id
    ) loc on true
    where r.status = 'active'
      and (loc.last_seen is null or loc.last_seen < now() - make_interval(mins => p_stale_minutes));
end;
$$;

create function public.admin_list_vendors()
returns table (
  business_id uuid,
  name text,
  phone text,
  email text,
  operating_area text,
  member_count bigint,
  active_rider_count bigint,
  order_count_30d bigint,
  last_order_at timestamptz,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;

  return query
    select
      b.id, b.name, b.phone, b.email, b.operating_area,
      (select count(*) from public.business_members m where m.business_id = b.id and m.status = 'active'),
      (select count(*) from public.riders r where r.business_id = b.id and r.status = 'active'),
      (select count(*) from public.orders o where o.business_id = b.id and o.created_at > now() - interval '30 days'),
      (select max(o.created_at) from public.orders o where o.business_id = b.id),
      b.created_at
    from public.businesses b
    order by b.created_at desc;
end;
$$;

create function public.admin_get_vendor(p_business_id uuid)
returns table (
  business_id uuid,
  name text,
  phone text,
  email text,
  address text,
  operating_area text,
  member_count bigint,
  rider_count bigint,
  active_rider_count bigint,
  order_count_total bigint,
  order_count_30d bigint,
  delivered_count_30d bigint,
  issue_count_30d bigint,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;

  return query
    select
      b.id, b.name, b.phone, b.email, b.address, b.operating_area,
      (select count(*) from public.business_members m where m.business_id = b.id and m.status = 'active'),
      (select count(*) from public.riders r where r.business_id = b.id),
      (select count(*) from public.riders r where r.business_id = b.id and r.status = 'active'),
      (select count(*) from public.orders o where o.business_id = b.id),
      (select count(*) from public.orders o where o.business_id = b.id and o.created_at > now() - interval '30 days'),
      (select count(*) from public.orders o where o.business_id = b.id and o.delivery_status = 'delivered' and o.created_at > now() - interval '30 days'),
      (select count(*) from public.orders o where o.business_id = b.id and o.delivery_status = 'issue' and o.created_at > now() - interval '30 days'),
      b.created_at
    from public.businesses b
    where b.id = p_business_id;

  if not found then
    raise exception 'vendor not found';
  end if;
end;
$$;

create function public.admin_list_riders()
returns table (
  rider_id uuid,
  business_id uuid,
  business_name text,
  name text,
  phone text,
  vehicle_plate text,
  status public.rider_status,
  availability_status text,
  delivered_count_30d bigint,
  active_assignment_count bigint,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;

  return query
    select
      r.id, r.business_id, b.name, r.name, r.phone, r.vehicle_plate,
      r.status, r.availability_status,
      (select count(*) from public.orders o where o.assigned_rider_id = r.id and o.delivery_status = 'delivered' and o.created_at > now() - interval '30 days'),
      (select count(*) from public.rider_assignments a where a.rider_id = r.id and a.status in ('assigned', 'accepted', 'picking_up', 'delivering')),
      r.created_at
    from public.riders r
    join public.businesses b on b.id = r.business_id
    order by r.created_at desc;
end;
$$;

-- Cross-business live view: every order still in flight, its assigned
-- Rider's latest known position (if any), matching what a single business's
-- own dashboard already computes per-business -- this is the same shape,
-- just unscoped.
create function public.admin_delivery_operations()
returns table (
  order_id uuid,
  public_ref text,
  business_id uuid,
  business_name text,
  delivery_status public.delivery_status,
  assigned_rider_id uuid,
  rider_name text,
  rider_last_lat double precision,
  rider_last_lng double precision,
  rider_last_seen timestamptz,
  estimated_arrival_at timestamptz,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;

  return query
    select
      o.id, o.public_ref, o.business_id, b.name,
      o.delivery_status, o.assigned_rider_id, r.name,
      loc.lat, loc.lng, loc.last_seen,
      o.estimated_arrival_at, o.created_at
    from public.orders o
    join public.businesses b on b.id = o.business_id
    left join public.riders r on r.id = o.assigned_rider_id
    left join lateral (
      select latitude as lat, longitude as lng, recorded_at as last_seen
      from public.rider_locations rl
      where rl.rider_id = o.assigned_rider_id
      order by rl.recorded_at desc
      limit 1
    ) loc on o.assigned_rider_id is not null
    where o.delivery_status not in ('delivered', 'cancelled')
    order by o.created_at desc;
end;
$$;

grant execute on function public.admin_stuck_riders(integer) to authenticated;
grant execute on function public.admin_list_vendors() to authenticated;
grant execute on function public.admin_get_vendor(uuid) to authenticated;
grant execute on function public.admin_list_riders() to authenticated;
grant execute on function public.admin_delivery_operations() to authenticated;
