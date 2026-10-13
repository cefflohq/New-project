-- Official area outlines for auto zone boundaries (Founder 2026-10-13: all
-- of Malaysia, not only the Klang Valley). Mukim / bandar / pekan (ADM3) for
-- Peninsular Malaysia, Sarawak and Labuan; daerah (ADM2) for Sabah, which has
-- no mukim. Source: geoBoundaries gbOpen MYS, CC BY 4.0 / CC BY 3.0; maps that
-- draw these shapes credit geoBoundaries.
--
-- Rows are loaded by scripts/load-admin-areas.mjs (data is too large for a
-- migration). Public reference data: read-only for signed-in users, written
-- only by the loader (service role).

create table if not exists public.admin_areas (
  id text primary key,
  name text not null,
  -- What the vendor sees and picks: "Seremban", kind "Bandar", state.
  label text not null,
  kind text not null,
  state text,
  level text not null check (level in ('ADM2', 'ADM3')),
  area_km2 numeric not null,
  min_lng double precision not null,
  min_lat double precision not null,
  max_lng double precision not null,
  max_lat double precision not null,
  -- GeoJSON Polygon or MultiPolygon, [lng, lat].
  geom jsonb not null
);

create index if not exists admin_areas_name_idx on public.admin_areas (lower(name));
create index if not exists admin_areas_label_idx on public.admin_areas (lower(label) text_pattern_ops);
create index if not exists admin_areas_bbox_idx on public.admin_areas (min_lng, max_lng, min_lat, max_lat);

alter table public.admin_areas enable row level security;
drop policy if exists admin_areas_read on public.admin_areas;
create policy admin_areas_read on public.admin_areas for select to authenticated using (true);
revoke all on public.admin_areas from anon;
grant select on public.admin_areas to authenticated;

-- Zone name suggestions (Founder 2026-10-13): typing "se" offers
-- "Seremban · Negeri Sembilan". One row per place name and state: when the
-- same name is a bandar, a pekan and a mukim, the vendor sees it once and
-- the area used is picked here (bandar, then pekan, then mukim). Prefix
-- matches first, then word-start matches; slivers under 1 km2 are left out.
create or replace function public.search_admin_areas(p_query text)
returns table (id text, label text, kind text, state text)
language sql
stable
security invoker
set search_path to 'public'
as $function$
  with q as (select lower(btrim(coalesce(p_query, ''))) as t),
  hits as (
    select distinct on (lower(a.label), a.state)
      a.id, a.label, a.kind, a.state, (lower(a.label) like q.t || '%') as prefix
    from admin_areas a, q
    where length(q.t) >= 2
      and a.area_km2 >= 1
      and (lower(a.label) like q.t || '%' or lower(a.label) like '% ' || q.t || '%')
    order by lower(a.label), a.state,
             array_position(array['Bandar', 'Daerah', 'Pekan', 'Mukim', 'Kawasan'], a.kind)
  )
  select id, label, kind, state from hits
  order by prefix desc, label, state
  limit 8;
$function$;

revoke all on function public.search_admin_areas(text) from public, anon;
grant execute on function public.search_admin_areas(text) to authenticated;
