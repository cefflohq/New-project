import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { latLngToCell, gridDisk, cellToLatLng } from 'https://esm.sh/h3-js@4.1.0';

// Hexagon zone cells (Auto Zone master guideline D1/D4, 2026-10-14).
//
// { business_id } -> rebuilds public.zone_cells for that business: the H3
// resolution-9 cells (~0.1 km² each) whose centre lies within the coverage
// radius + 20 % of the service origin. Each cell is given to the official
// area (admin_areas, the business's country) holding its centre, and to the
// active zone whose boundary holds it — the nearest zone centre when two
// do, so one cell always belongs to one zone. Returns counts.
//
// Caller: an operational member of the business (checked server-side with
// is_business_operational); the rows are written with the service role.

const RES = 9;
const TOLERANCE = 1.2;          // coverage + 20 % (Founder D1)
const DEFAULT_RADIUS_KM = 10;
const CELL_SPACING_KM = 0.3;    // centre-to-centre distance at resolution 9
const MAX_CELLS = 20000;

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}
const json = (body, status = 200) => Response.json(body, { status, headers: corsHeaders() });

export function km(a, b) {
  const r = Math.PI / 180;
  const dLat = (b[1] - a[1]) * r;
  const dLng = (b[0] - a[0]) * r;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(a[1] * r) * Math.cos(b[1] * r) * Math.sin(dLng / 2) ** 2;
  return 12742 * Math.asin(Math.sqrt(h));
}
const polygonsOf = (g) => (g?.type === 'MultiPolygon' ? g.coordinates : g?.type === 'Polygon' ? [g.coordinates] : []);
function inside([x, y], ring) {
  let c = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i], [xj, yj] = ring[j];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) c = !c;
  }
  return c;
}
// Holes excluded, as geojson_contains in SQL.
export const contains = (g, pt) => polygonsOf(g).some((p) => inside(pt, p[0]) && !p.slice(1).some((h) => inside(pt, h)));
export function bboxCentre(g) {
  const pts = polygonsOf(g).flat(1).flat(1);
  const xs = pts.map((p) => p[0]), ys = pts.map((p) => p[1]);
  return [(Math.min(...xs) + Math.max(...xs)) / 2, (Math.min(...ys) + Math.max(...ys)) / 2];
}

// Pure: the cells of a coverage disc with their zone and area.
export function buildCells({ origin, radiusKm, zones, areas }) {
  const r = (radiusKm || DEFAULT_RADIUS_KM) * TOLERANCE;
  const k = Math.ceil(r / CELL_SPACING_KM) + 1;
  const centres = zones.map((z) => ({ id: z.id, boundary: z.boundary, mid: bboxCentre(z.boundary) }));
  const out = [];
  for (const cell of gridDisk(latLngToCell(origin[1], origin[0], RES), k)) {
    const [lat, lng] = cellToLatLng(cell);
    const pt = [lng, lat];
    if (km(origin, pt) > r) continue;
    const zone = centres.filter((z) => contains(z.boundary, pt))
      .sort((a, b) => km(pt, a.mid) - km(pt, b.mid) || (a.id < b.id ? -1 : 1))[0];
    const area = areas.find((a) => pt[0] >= a.min_lng && pt[0] <= a.max_lng && pt[1] >= a.min_lat && pt[1] <= a.max_lat
      && contains(a.geom, pt));
    out.push({ cell, zone_id: zone?.id || null, area_id: area?.id || null, centre_lat: lat, centre_lng: lng });
    if (out.length >= MAX_CELLS) break;
  }
  return out;
}

if (typeof Deno !== 'undefined') Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders() });
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const body = await request.json().catch(() => null);
  const businessId = typeof body?.business_id === 'string' ? body.business_id : null;
  if (!businessId) return json({ error: 'business_id is required' }, 400);

  const url = Deno.env.get('SUPABASE_URL');
  const caller = createClient(url, Deno.env.get('SUPABASE_ANON_KEY') || '', {
    global: { headers: { Authorization: request.headers.get('authorization') || '' } },
    auth: { persistSession: false },
  });
  const { data: allowed } = await caller.rpc('is_business_operational', { p_business: businessId });
  if (allowed !== true) return json({ error: 'forbidden' }, 403);

  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'), { auth: { persistSession: false } });
  const { data: biz } = await admin.from('businesses')
    .select('service_origin_latitude, service_origin_longitude, service_coverage_radius_km, country_iso2')
    .eq('id', businessId).maybeSingle();
  if (biz?.service_origin_latitude == null || biz?.service_origin_longitude == null) {
    return json({ business_id: businessId, status: 'no_service_area', cells: 0 });
  }
  const origin = [Number(biz.service_origin_longitude), Number(biz.service_origin_latitude)];
  const radiusKm = Number(biz.service_coverage_radius_km) || DEFAULT_RADIUS_KM;
  const r = radiusKm * TOLERANCE, dLat = r / 111, dLng = r / (111 * Math.cos(origin[1] * Math.PI / 180));

  const [{ data: zones }, { data: areas }] = await Promise.all([
    admin.from('zones').select('id, boundary').eq('business_id', businessId).eq('status', 'active').not('boundary', 'is', null),
    admin.from('admin_areas').select('id, min_lng, min_lat, max_lng, max_lat, geom')
      .eq('country_iso2', biz.country_iso2 || 'MY')
      .lte('min_lng', origin[0] + dLng).gte('max_lng', origin[0] - dLng)
      .lte('min_lat', origin[1] + dLat).gte('max_lat', origin[1] - dLat),
  ]);
  const cells = buildCells({ origin, radiusKm, zones: zones || [], areas: areas || [] });

  const now = new Date().toISOString();
  for (let i = 0; i < cells.length; i += 500) {
    const { error } = await admin.from('zone_cells')
      .upsert(cells.slice(i, i + 500).map((c) => ({ ...c, business_id: businessId, updated_at: now })), { onConflict: 'business_id,cell' });
    if (error) return json({ error: 'Could not save cells' }, 500);
  }
  // Cells no longer inside the coverage are removed.
  await admin.from('zone_cells').delete().eq('business_id', businessId).lt('updated_at', now);

  return json({
    business_id: businessId,
    status: 'ok',
    cells: cells.length,
    zoned: cells.filter((c) => c.zone_id).length,
    with_area: cells.filter((c) => c.area_id).length,
  });
});
