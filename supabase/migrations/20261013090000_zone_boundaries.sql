-- Zone boundaries (Founder 2026-10-12, option B; auto areas 2026-10-13): a
-- zone may carry a polygon so it shows on the maps, drawn by the vendor or
-- set by the zone-boundary Edge Function. Stored as a GeoJSON Polygon
-- geometry ({"type":"Polygon","coordinates":[[[lng,lat],...]]}), one outer
-- ring, closed. Display only for now: it does not change zone assignment,
-- the planner or any order rule.

alter table public.zones add column if not exists boundary jsonb;

create or replace function public.set_zone_boundary(p_zone_id uuid, p_boundary jsonb)
returns public.zones
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  z zones;
  ring jsonb;
  pt jsonb;
  n int;
begin
  select * into z from zones where id = p_zone_id for update;
  if z.id is null or not is_business_operational(z.business_id) then
    raise exception 'forbidden';
  end if;

  if p_boundary is not null and p_boundary <> 'null'::jsonb then
    -- Outer ring first, then up to 49 holes (an auto zone gives up a smaller
    -- zone nested inside it). Each ring closed, 4..1001 points.
    if p_boundary ->> 'type' is distinct from 'Polygon'
       or jsonb_typeof(p_boundary -> 'coordinates') <> 'array'
       or jsonb_array_length(p_boundary -> 'coordinates') not between 1 and 50 then
      raise exception 'invalid zone boundary';
    end if;
    for ring in select value from jsonb_array_elements(p_boundary -> 'coordinates') loop
      if jsonb_typeof(ring) <> 'array' then
        raise exception 'invalid zone boundary';
      end if;
      n := jsonb_array_length(ring);
      if n < 4 or n > 1001 or ring -> 0 <> ring -> (n - 1) then
        raise exception 'invalid zone boundary';
      end if;
      for pt in select value from jsonb_array_elements(ring) loop
        if jsonb_typeof(pt) <> 'array' or jsonb_array_length(pt) <> 2
           or jsonb_typeof(pt -> 0) <> 'number' or jsonb_typeof(pt -> 1) <> 'number'
           or (pt ->> 0)::numeric not between -180 and 180
           or (pt ->> 1)::numeric not between -90 and 90 then
          raise exception 'invalid zone boundary';
        end if;
      end loop;
    end loop;
  else
    p_boundary := null;
  end if;

  update zones set boundary = p_boundary, updated_at = now() where id = z.id returning * into z;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (z.business_id, 'zone.boundary_set', auth.uid(), 'vendor',
            jsonb_build_object('zone_id', z.id, 'cleared', p_boundary is null));
  return z;
end;
$function$;

revoke all on function public.set_zone_boundary(uuid, jsonb) from public, anon;
grant execute on function public.set_zone_boundary(uuid, jsonb) to authenticated;
