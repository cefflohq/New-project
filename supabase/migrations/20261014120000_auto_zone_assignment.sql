-- Auto zone assignment + hexagon zone cells (Auto Zone master guideline
-- Part A §3.1, Founder decisions D1/D4, 2026-10-14).
--
-- * An order with a trustworthy point (location_status = 'resolved') and no
--   zone gets the active zone of its business whose boundary holds the
--   point. Several zones holding it (should not happen once zones are cell
--   groups) -> nearest zone centre, then lowest id: deterministic.
-- * A zone the vendor sets by hand always wins (zone_source = 'manual').
-- * Only orders not yet in a run (no delivery session, no rider) are ever
--   (re)zoned; a planned or active run is never touched.
-- * Outside the coverage radius + 20 % tolerance: no zone ("Outside
--   coverage"), never guessed into the nearest zone.
-- * zone_cells: the H3 hexagon grid (resolution 9) of each business's
--   coverage, one zone per cell, written by the zone-cells Edge Function.

alter table public.orders add column if not exists zone_source text;
alter table public.orders drop constraint if exists orders_zone_source_check;
alter table public.orders add constraint orders_zone_source_check
  check (zone_source is null or zone_source in ('manual', 'auto'));
update public.orders set zone_source = 'manual' where zone_id is not null and zone_source is null;

-- Point in a GeoJSON Polygon / MultiPolygon ([lng, lat]); holes excluded.
create or replace function public.geojson_contains(p_geom jsonb, p_lng double precision, p_lat double precision)
returns boolean
language plpgsql
immutable
set search_path = public
as $$
declare
  polys jsonb;
  poly jsonb;
  ring jsonb;
  ring_no int;
  inside boolean;
  n int; i int; j int;
  xi double precision; yi double precision; xj double precision; yj double precision;
  in_poly boolean;
begin
  if p_geom is null or p_lng is null or p_lat is null then return false; end if;
  if p_geom->>'type' = 'Polygon' then
    polys := jsonb_build_array(p_geom->'coordinates');
  elsif p_geom->>'type' = 'MultiPolygon' then
    polys := p_geom->'coordinates';
  else
    return false;
  end if;
  for poly in select value from jsonb_array_elements(polys) loop
    in_poly := false;
    ring_no := 0;
    for ring in select value from jsonb_array_elements(poly) loop
      inside := false;
      n := jsonb_array_length(ring);
      j := n - 1;
      for i in 0 .. n - 1 loop
        xi := (ring->i->>0)::double precision; yi := (ring->i->>1)::double precision;
        xj := (ring->j->>0)::double precision; yj := (ring->j->>1)::double precision;
        if ((yi > p_lat) <> (yj > p_lat)) and (p_lng < (xj - xi) * (p_lat - yi) / (yj - yi) + xi) then
          inside := not inside;
        end if;
        j := i;
      end loop;
      if ring_no = 0 then
        in_poly := inside;
        exit when not in_poly;
      elsif inside then
        in_poly := false; -- inside a hole
        exit;
      end if;
      ring_no := ring_no + 1;
    end loop;
    if in_poly then return true; end if;
  end loop;
  return false;
end;
$$;

-- Centre of a GeoJSON geometry's bounding box: [lng, lat].
create or replace function public.geojson_bbox_centre(p_geom jsonb)
returns double precision[]
language sql
immutable
set search_path = public
as $$
  with pts as (
    select (pt->>0)::double precision as x, (pt->>1)::double precision as y
    from jsonb_path_query(p_geom, 'strict $.coordinates.**') pt
    where jsonb_typeof(pt) = 'array' and jsonb_array_length(pt) = 2
      and jsonb_typeof(pt->0) = 'number'
  )
  select array[(min(x) + max(x)) / 2, (min(y) + max(y)) / 2] from pts
$$;

-- Internal (no caller check; used by triggers and the re-zone job).
create or replace function public._auto_zone_for_point(p_business_id uuid, p_lat double precision, p_lng double precision)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  b businesses;
  hit uuid;
begin
  if p_lat is null or p_lng is null then return null; end if;
  select * into b from businesses where id = p_business_id;
  if b.service_coverage_radius_km is not null and b.service_origin_latitude is not null
     and haversine_km(b.service_origin_latitude, b.service_origin_longitude, p_lat, p_lng)
         > b.service_coverage_radius_km * 1.2 then
    return null; -- outside coverage + 20 %
  end if;
  select z.id into hit
  from zones z
  where z.business_id = p_business_id and z.status = 'active' and z.boundary is not null
    and geojson_contains(z.boundary, p_lng, p_lat)
  order by haversine_km(p_lat, p_lng,
             (geojson_bbox_centre(z.boundary))[2], (geojson_bbox_centre(z.boundary))[1]),
           z.id
  limit 1;
  return hit;
end;
$$;

revoke all on function public._auto_zone_for_point(uuid, double precision, double precision) from public, anon, authenticated;

-- Before insert / update on orders: manual zone wins, auto zone otherwise.
create or replace function public._orders_auto_zone()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  system_change boolean := coalesce(current_setting('cefflo.auto_zone', true), '') = 'on';
  in_run boolean := new.delivery_session_id is not null or new.assigned_rider_id is not null;
  moved boolean := tg_op = 'INSERT'
    or new.latitude is distinct from old.latitude
    or new.longitude is distinct from old.longitude
    or new.location_status is distinct from old.location_status;
begin
  -- A zone set or cleared by a person is a manual choice.
  if not system_change and (
       (tg_op = 'INSERT' and new.zone_id is not null and new.zone_source is distinct from 'auto')
       or (tg_op = 'UPDATE' and new.zone_id is distinct from old.zone_id)) then
    new.zone_source := case when new.zone_id is null then null else 'manual' end;
    return new;
  end if;
  if system_change or in_run or new.zone_source = 'manual' or not moved then
    return new;
  end if;
  if new.location_status = 'resolved' then
    new.zone_id := _auto_zone_for_point(new.business_id, new.latitude, new.longitude);
    new.zone_source := case when new.zone_id is null then null else 'auto' end;
  elsif new.zone_source = 'auto' then
    new.zone_id := null; -- the point is no longer trustworthy
    new.zone_source := null;
  end if;
  return new;
end;
$$;

drop trigger if exists orders_auto_zone on public.orders;
create trigger orders_auto_zone
  before insert or update of latitude, longitude, location_status, zone_id, delivery_session_id, assigned_rider_id
  on public.orders
  for each row execute function public._orders_auto_zone();

-- Re-zone a business's open orders after its zones change (boundary,
-- status, new or deleted zone). Manual zones and orders in a run are kept.
create or replace function public._rezone_open_orders(p_business_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  perform set_config('cefflo.auto_zone', 'on', true);
  with next as (
    select o.id, _auto_zone_for_point(o.business_id, o.latitude, o.longitude) as zone_id
    from orders o
    where o.business_id = p_business_id
      and o.location_status = 'resolved'
      and o.delivery_session_id is null and o.assigned_rider_id is null
      and o.delivery_status in ('created', 'ready_for_pickup')
      and coalesce(o.zone_source, 'auto') = 'auto'
  )
  update orders o
     set zone_id = next.zone_id,
         zone_source = case when next.zone_id is null then null else 'auto' end,
         updated_at = now()
    from next
   where o.id = next.id and o.zone_id is distinct from next.zone_id;
  get diagnostics changed = row_count;
  perform set_config('cefflo.auto_zone', 'off', true);
  return changed;
end;
$$;

revoke all on function public._rezone_open_orders(uuid) from public, anon, authenticated;

create or replace function public._zones_rezone_orders()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform _rezone_open_orders(coalesce(new.business_id, old.business_id));
  return null;
end;
$$;

drop trigger if exists zones_rezone_orders on public.zones;
create trigger zones_rezone_orders
  after insert or delete or update of boundary, status on public.zones
  for each row execute function public._zones_rezone_orders();

-- Hexagon cells (H3 resolution 9) of a business's coverage. One zone per
-- cell (primary key), so zones built from cells can never overlap.
create table if not exists public.zone_cells (
  business_id uuid not null references public.businesses on delete cascade,
  cell text not null check (cell ~ '^[0-9a-f]{15}$'),
  zone_id uuid references public.zones on delete set null,
  area_id text references public.admin_areas(id) on delete set null,
  centre_lat double precision not null,
  centre_lng double precision not null,
  updated_at timestamptz not null default now(),
  primary key (business_id, cell)
);
create index if not exists zone_cells_zone_idx on public.zone_cells (zone_id);

alter table public.zone_cells enable row level security;
drop policy if exists zone_cells_read on public.zone_cells;
create policy zone_cells_read on public.zone_cells for select to authenticated
  using (is_business_member(business_id));
revoke all on public.zone_cells from public, anon, authenticated;
grant select on public.zone_cells to authenticated;

-- Explicit re-run for the vendor (e.g. after loading new areas).
create or replace function public.rezone_open_orders(p_business_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  return _rezone_open_orders(p_business_id);
end;
$$;

revoke all on function public.rezone_open_orders(uuid) from public, anon;
grant execute on function public.rezone_open_orders(uuid) to authenticated;
