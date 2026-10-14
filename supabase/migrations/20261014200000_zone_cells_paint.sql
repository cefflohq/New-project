-- Hexagon zone painting (Auto Zone master guideline D1/D4, 2026-10-14).
--
-- * The vendor paints H3 cells onto a zone (or clears them) on the Zones
--   map. Painted cells are marked manual, so a later zone-cells rebuild
--   keeps them.
-- * Auto zone assignment uses the cells first: the order's point takes the
--   zone of the nearest cell centre within 0.25 km (a resolution-9 cell is
--   ~0.17 km edge to centre). Without cells it falls back to the zone
--   boundaries, as before.

alter table public.zone_cells add column if not exists manual boolean not null default false;
create index if not exists zone_cells_business_lat_idx on public.zone_cells (business_id, centre_lat, centre_lng);

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
  has_cells boolean;
begin
  if p_lat is null or p_lng is null then return null; end if;
  select * into b from businesses where id = p_business_id;
  if b.service_coverage_radius_km is not null and b.service_origin_latitude is not null
     and haversine_km(b.service_origin_latitude, b.service_origin_longitude, p_lat, p_lng)
         > b.service_coverage_radius_km * 1.2 then
    return null; -- outside coverage + 20 %
  end if;

  -- Hexagon cells, when the business has them.
  select exists (select 1 from zone_cells where business_id = p_business_id) into has_cells;
  if has_cells then
    select c.zone_id into hit
    from zone_cells c
    left join zones z on z.id = c.zone_id
    where c.business_id = p_business_id
      and c.centre_lat between p_lat - 0.003 and p_lat + 0.003
      and c.centre_lng between p_lng - 0.003 and p_lng + 0.003
      and haversine_km(p_lat, p_lng, c.centre_lat, c.centre_lng) <= 0.25
    order by haversine_km(p_lat, p_lng, c.centre_lat, c.centre_lng), c.cell
    limit 1;
    if found then
      -- The cell decides; an inactive or deleted zone means no zone.
      return (select z.id from zones z where z.id = hit and z.status = 'active');
    end if;
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

-- Paint cells onto a zone (p_zone_id) or clear them (null). Only cells that
-- already exist in the business's grid; returns the number changed. Open
-- auto-zoned orders follow at once.
create or replace function public.paint_zone_cells(p_business_id uuid, p_cells text[], p_zone_id uuid default null)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  if p_cells is null or cardinality(p_cells) = 0 then return 0; end if;
  if cardinality(p_cells) > 5000 then raise exception 'too many cells'; end if;
  if p_zone_id is not null and not exists (
       select 1 from zones where id = p_zone_id and business_id = p_business_id and deleted_at is null) then
    raise exception 'zone not found';
  end if;
  update zone_cells set zone_id = p_zone_id, manual = true, updated_at = now()
   where business_id = p_business_id and cell = any(p_cells)
     and (zone_id is distinct from p_zone_id or not manual);
  get diagnostics changed = row_count;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'zone.cells_painted', auth.uid(), 'vendor',
            jsonb_build_object('zone_id', p_zone_id, 'cells', changed));
  perform _rezone_open_orders(p_business_id);
  return changed;
end;
$$;

revoke all on function public.paint_zone_cells(uuid, text[], uuid) from public, anon;
grant execute on function public.paint_zone_cells(uuid, text[], uuid) to authenticated;

-- zone-cells (service role) re-zones open orders after a rebuild.
grant execute on function public._rezone_open_orders(uuid) to service_role;
