import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import * as turf from 'https://esm.sh/@turf/turf@7.1.0';

// Auto zone boundary (Founder 2026-10-13): the vendor picks a town from the
// suggestions ("Cheras", "Wangsa Maju", "Seremban") or types a name; this
// gives the zone its area on the map, so nobody has to draw. Display only,
// like a drawn boundary.
//
// { suggest: "che" } -> town suggestions (city / town / suburb level only,
//   from OpenStreetMap via Photon; no villages or housing estates).
// { zone_id, center? } -> lays the zone, right after create_zone / rename_zone
//   (center = the picked suggestion).
//
//   1. The place centre: the picked suggestion, else the typed name looked up
//      (Photon, Mapbox, then Nominatim).
//   2. The official area (public.admin_areas: mukim / bandar / pekan, Sabah
//      daerah; geoBoundaries) holding the centre, preferring a town-sized one
//      (TOWN_MIN_KM2..TOWN_MAX_KM2), else the typed name's own area.
//   3. The zone takes that official outline. When several of the business's
//      zones fall in the same area they split it along the half-way lines
//      between their centres; a very large area (forest, plantation) is also
//      trimmed to CAP_KM around the centre.
//   4. Official areas nest (a bandar sits inside its mukim), so smaller zones
//      are laid first and each larger zone gives up what they already cover
//      (it may get a hole). Zones never overlap.
// Auto boundaries carry {"auto": true, "center": [lng, lat], "area_id"}; every
// save re-lays all of the business's active auto zones. A boundary drawn by
// hand is never touched (auto zones avoid it). A name that is not a place
// ("Zone A") leaves the zone without a boundary.

const PHOTON_URL = 'https://photon.komoot.io/api/';
const MAPBOX_URL = 'https://api.mapbox.com/search/geocode/v6/forward';
const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search';
const USER_AGENT = 'Cefflo/1.0 (zone areas; https://cefflo.com)';
const NEAR_KM = 60;          // a same-name place further than this is another town
const NAME_MATCH_KM = 25;    // official area must lie this close to the centre
const MIN_AREA_KM2 = 1;      // skip slivers (tiny pekan)
const LARGE_KM2 = 40;        // above this, trim around the centre
const CAP_KM = 5;
const FALLBACK_KM = 3;       // no official area at all
const MAX_POINTS = 400;
const TOWN_MIN_KM2 = 3;      // smaller official areas are slivers of a town
const TOWN_MAX_KM2 = 60;
const TOWN_KM2 = 20;         // the size a delivery zone should roughly be
const MALAYSIA_BBOX = '99.6,0.8,119.3,7.4';
// Town level only (Founder: "bandar sahaja").
const TOWN_TAGS = ['place:city', 'place:town', 'place:suburb', 'place:quarter'];
const STEPS = 48;

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}
const json = (body, status = 200) => Response.json(body, { status, headers: corsHeaders() });

function km(a, b) {
  const r = Math.PI / 180;
  const dLat = (b[1] - a[1]) * r;
  const dLng = (b[0] - a[0]) * r;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(a[1] * r) * Math.cos(b[1] * r) * Math.sin(dLng / 2) ** 2;
  return 12742 * Math.asin(Math.sqrt(h));
}

const sameName = (a, b) => String(a || '').toLowerCase().includes(String(b || '').toLowerCase());
const clean = (s) => String(s || '').replace(/[^\p{L}\p{N} ]+/gu, ' ').replace(/\s+/g, ' ').trim();

// ---------------------------------------------------------------- centre

// Town suggestions: one per name and state, inside the business country
// (ISO 3166-1 alpha-2; Malaysia unless the caller's business says otherwise).
async function photonTowns(q, near, limit = 8, cc = 'MY') {
  const url = new URL(PHOTON_URL);
  url.searchParams.set('q', q);
  url.searchParams.set('limit', String(limit * 2));
  if (cc === 'MY') url.searchParams.set('bbox', MALAYSIA_BBOX);
  for (const t of TOWN_TAGS) url.searchParams.append('osm_tag', t);
  if (near) { url.searchParams.set('lon', String(near[0])); url.searchParams.set('lat', String(near[1])); }
  const res = await fetch(url, { headers: { 'User-Agent': USER_AGENT } });
  if (!res.ok) return [];
  const body = await res.json().catch(() => null);
  const seen = new Set();
  const out = [];
  for (const f of body?.features || []) {
    const p = f.properties || {};
    const c = f.geometry?.coordinates;
    if (p.countrycode !== cc || !p.name || !Array.isArray(c)) continue;
    // Kuala Lumpur carries no state in OSM; it is its own territory.
    const state = p.state || p.city || (cc === 'MY' ? 'Kuala Lumpur' : '');
    const key = `${p.name.toLowerCase()}|${state}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push({ name: p.name, state, center: c.map(Number) });
    if (out.length >= limit) break;
  }
  return out;
}

async function centreFromMapbox(name, origin, token, cc = 'MY') {
  if (!token) return null;
  const url = new URL(MAPBOX_URL);
  url.searchParams.set('q', name);
  url.searchParams.set('country', cc.toLowerCase());
  url.searchParams.set('types', 'neighborhood,locality,place,district');
  url.searchParams.set('limit', '5');
  url.searchParams.set('access_token', token);
  if (origin) url.searchParams.set('proximity', `${origin[0]},${origin[1]}`);
  const res = await fetch(url);
  if (!res.ok) return null;
  const body = await res.json().catch(() => null);
  const f = (body?.features || []).find((x) => {
    const c = x?.geometry?.coordinates;
    return sameName(x?.properties?.name, name) && Array.isArray(c) && (!origin || km(origin, c) <= NEAR_KM);
  });
  return f ? f.geometry.coordinates.map(Number) : null;
}

async function centreFromOsm(name, origin, cc = 'MY') {
  const url = new URL(NOMINATIM_URL);
  url.searchParams.set('q', name);
  url.searchParams.set('countrycodes', cc.toLowerCase());
  url.searchParams.set('format', 'jsonv2');
  url.searchParams.set('limit', '8');
  const res = await fetch(url, { headers: { 'User-Agent': USER_AGENT } });
  if (!res.ok) return null;
  const rows = await res.json().catch(() => []);
  // Places only: never a railway station or mall that shares the name.
  const r = (Array.isArray(rows) ? rows : []).find((x) => {
    const c = [Number(x.lon), Number(x.lat)];
    return (x.category === 'place' || x.category === 'boundary') && sameName(x.name, name)
      && (!origin || km(origin, c) <= NEAR_KM);
  });
  return r ? [Number(r.lon), Number(r.lat)] : null;
}

// ---------------------------------------------------------------- geometry

const polygonsOf = (g) => (g?.type === 'MultiPolygon' ? g.coordinates : g?.type === 'Polygon' ? [g.coordinates] : []);

function inside([x, y], ring) {
  let c = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i], [xj, yj] = ring[j];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) c = !c;
  }
  return c;
}
const contains = (g, pt) => polygonsOf(g).some((p) => inside(pt, p[0]));

function centroid(ring) {
  const pts = ring.slice(0, -1);
  return [pts.reduce((s, p) => s + p[0], 0) / pts.length, pts.reduce((s, p) => s + p[1], 0) / pts.length];
}

// The outer ring holding the centre (islands aside), else the largest one.
function mainRing(g, center) {
  const outers = polygonsOf(g).map((p) => p[0]);
  return (center && outers.find((r) => inside(center, r))) || outers.sort((a, b) => b.length - a.length)[0];
}

// Flat km grid around a reference latitude; fine at zone scale.
const toXY = (p, lat0) => [p[0] * 111.32 * Math.cos(lat0 * Math.PI / 180), p[1] * 110.574];
const toLngLat = (q, lat0) => [+(q[0] / (111.32 * Math.cos(lat0 * Math.PI / 180))).toFixed(6), +(q[1] / 110.574).toFixed(6)];

// Keep the part of `poly` where (p - m) . n <= 0.
function halfPlane(poly, m, n) {
  const side = (p) => (p[0] - m[0]) * n[0] + (p[1] - m[1]) * n[1];
  const out = [];
  for (let i = 0; i < poly.length; i++) {
    const p = poly[i], q = poly[(i + 1) % poly.length];
    const sp = side(p), sq = side(q);
    if (sp <= 0) out.push(p);
    if ((sp < 0 && sq > 0) || (sp > 0 && sq < 0)) {
      const t = sp / (sp - sq);
      out.push([p[0] + t * (q[0] - p[0]), p[1] + t * (q[1] - p[1])]);
    }
  }
  return out;
}
// Side nearer to `a` of the half-way line between a and b.
const nearerTo = (poly, a, b) => halfPlane(poly, [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2], [b[0] - a[0], b[1] - a[1]]);

function circleXY(c, r) {
  return Array.from({ length: STEPS }, (_, i) => {
    const a = (i / STEPS) * 2 * Math.PI;
    return [c[0] + r * Math.cos(a), c[1] + r * Math.sin(a)];
  });
}
function withinCircle(poly, c, r) {
  let out = poly;
  const circle = circleXY(c, r);
  for (let i = 0; i < circle.length && out.length >= 3; i++) {
    const p = circle[i], q = circle[(i + 1) % circle.length];
    const m = [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2];
    out = halfPlane(out, m, [m[0] - c[0], m[1] - c[1]]);
  }
  return out;
}

function thin(ring) {
  if (ring.length <= MAX_POINTS) return ring;
  const step = ring.length / MAX_POINTS;
  return Array.from({ length: MAX_POINTS }, (_, i) => ring[Math.floor(i * step)]);
}

// The zone's share of its official area (or of a plain circle when it has
// none), cut against the other zone centres in the same area.
function cell(center, area, others) {
  const lat0 = center[1];
  const c = toXY(center, lat0);
  let poly = area
    ? mainRing(area.geom, center).slice(0, -1).map((p) => toXY(p, lat0))
    : circleXY(c, FALLBACK_KM);
  for (const o of others) {
    const d = toXY(o, lat0);
    if (Math.hypot(d[0] - c[0], d[1] - c[1]) < 0.05) continue;
    poly = nearerTo(poly, c, d);
    if (poly.length < 3) return null;
  }
  if (area && Number(area.area_km2) > LARGE_KM2) poly = withinCircle(poly, c, CAP_KM);
  if (poly.length < 3) return null;
  const ring = thin(poly.map((q) => toLngLat(q, lat0)));
  return [...ring, ring[0]];
}

// ---------------------------------------------------------------- areas

const AREA_COLS = 'id, name, level, area_km2, min_lng, min_lat, max_lng, max_lat, geom';
const midOf = (a) => [(Number(a.min_lng) + Number(a.max_lng)) / 2, (Number(a.min_lat) + Number(a.max_lat)) / 2];

async function areaByName(db, name, near, cc = 'MY') {
  const n = clean(name);
  if (!n) return null;
  const { data } = await db.from('admin_areas').select(AREA_COLS).eq('country_iso2', cc)
    .or(['', 'MUKIM ', 'BANDAR ', 'PEKAN '].map((p) => `name.ilike.${p}${n}`).join(','))
    .gte('area_km2', MIN_AREA_KM2);
  const rows = (data || []).filter((a) => !near || km(near, midOf(a)) <= NAME_MATCH_KM);
  // Nearest to the centre; on a tie the smaller (more local) area.
  return rows.sort((a, b) => (near ? km(near, midOf(a)) - km(near, midOf(b)) : 0)
    || Number(a.area_km2) - Number(b.area_km2))[0] || null;
}

async function areaAt(db, pt, cc = 'MY') {
  const { data } = await db.from('admin_areas').select(AREA_COLS).eq('country_iso2', cc)
    .lte('min_lng', pt[0]).gte('max_lng', pt[0]).lte('min_lat', pt[1]).gte('max_lat', pt[1])
    .gte('area_km2', MIN_AREA_KM2);
  const holding = (data || []).filter((a) => contains(a.geom, pt));
  // A town-sized area first (closest to TOWN_KM2), else the smallest larger
  // one (trimmed around the centre later), else whatever holds the point.
  const town = holding.filter((a) => Number(a.area_km2) >= TOWN_MIN_KM2 && Number(a.area_km2) <= TOWN_MAX_KM2)
    .sort((a, b) => Math.abs(Number(a.area_km2) - TOWN_KM2) - Math.abs(Number(b.area_km2) - TOWN_KM2))[0];
  if (town) return town;
  const bigger = holding.filter((a) => Number(a.area_km2) > TOWN_MAX_KM2)
    .sort((a, b) => Number(a.area_km2) - Number(b.area_km2))[0];
  return bigger || holding.sort((a, b) => Number(b.area_km2) - Number(a.area_km2))[0] || null;
}

const middle = (b) => {
  if (Array.isArray(b?.center)) return b.center.map(Number);
  const r = b?.coordinates?.[0];
  return Array.isArray(r) && r.length >= 4 ? centroid(r) : null;
};

// Lays the business's zones without overlap. `autos`: [{id, mid, area}],
// `fixed`: hand-drawn GeoJSON Polygons. Returns Map id -> GeoJSON Polygon
// (outer ring + holes) for every auto zone that keeps some area.
function layout(autos, fixed) {
  const bases = autos.map((z) => {
    const peers = autos.filter((o) => o.id !== z.id && (z.area ? o.area?.id === z.area.id : !o.area))
      .map((o) => o.mid).filter((p) => z.area || km(p, z.mid) < FALLBACK_KM * 2);
    const ring = cell(z.mid, z.area, peers);
    return ring ? { z, poly: turf.polygon([ring]) } : null;
  }).filter(Boolean).sort((a, b) => turf.area(a.poly) - turf.area(b.poly));

  let taken = fixed.length ? fixed.map((g) => turf.polygon(g.coordinates)) : [];
  const out = new Map();
  for (const { z, poly } of bases) {
    let shape = poly;
    if (taken.length) {
      const cover = taken.length === 1 ? taken[0] : turf.union(turf.featureCollection(taken));
      shape = cover ? turf.difference(turf.featureCollection([poly, cover])) : poly;
    }
    if (!shape) continue;
    // Keep the largest piece; slivers left by a neighbour are dropped.
    const parts = shape.geometry.type === 'MultiPolygon'
      ? shape.geometry.coordinates.map((c) => turf.polygon(c)) : [shape];
    const best = parts.sort((a, b) => turf.area(b) - turf.area(a))[0];
    const rings = best.geometry.coordinates
      .map((r) => r.map(([x, y]) => [+x.toFixed(6), +y.toFixed(6)]))
      .filter((r, i) => i === 0 || r.length >= 4);
    out.set(z.id, { type: 'Polygon', coordinates: rings });
    taken = [...taken, best];
  }
  return out;
}

// ---------------------------------------------------------------- handler

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders() });
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const body = await request.json().catch(() => null);

  if (body && typeof body.suggest === 'string') {
    // Signed-in callers only (the platform checks the JWT before this runs).
    const q = clean(body.suggest).slice(0, 60);
    if (q.length < 2) return json({ suggestions: [] });
    const near = Array.isArray(body.near) && body.near.length === 2 ? body.near.map(Number) : null;
    const cc = typeof body.country === 'string' && /^[A-Z]{2}$/.test(body.country) ? body.country : 'MY';
    try { return json({ suggestions: await photonTowns(q, near, 8, cc) }); } catch { return json({ suggestions: [] }); }
  }

  const zoneId = body && typeof body.zone_id === 'string' ? body.zone_id : null;
  // Set when the vendor picked a suggestion (search_admin_areas).
  const pickedAreaId = body && typeof body.area_id === 'string' ? body.area_id : null;
  const picked = Array.isArray(body?.center) && body.center.length === 2
    && body.center.every((n) => Number.isFinite(Number(n))) ? body.center.map(Number) : null;
  if (!zoneId) return json({ error: 'zone_id is required' }, 400);

  // Caller-scoped client: RLS decides what the caller may see, and
  // set_zone_boundary re-checks is_business_operational on every write.
  const db = createClient(Deno.env.get('SUPABASE_URL'), Deno.env.get('SUPABASE_ANON_KEY') || '', {
    global: { headers: { Authorization: request.headers.get('authorization') || '' } },
    auth: { persistSession: false },
  });
  const { data: zone } = await db.from('zones').select('id, name, business_id, boundary').eq('id', zoneId).maybeSingle();
  if (!zone) return json({ error: 'Zone not found or not accessible' }, 403);

  // A hand-drawn boundary is the vendor's choice; leave it.
  if (zone.boundary && !zone.boundary.auto) return json({ zone_id: zoneId, status: 'kept' });

  const [{ data: biz }, { data: all }] = await Promise.all([
    db.from('businesses').select('service_origin_latitude, service_origin_longitude, country_iso2').eq('id', zone.business_id).maybeSingle(),
    db.from('zones').select('id, status, boundary').eq('business_id', zone.business_id),
  ]);
  const origin = biz?.service_origin_latitude != null && biz?.service_origin_longitude != null
    ? [Number(biz.service_origin_longitude), Number(biz.service_origin_latitude)] : null;
  const cc = /^[A-Z]{2}$/.test(biz?.country_iso2 || '') ? biz.country_iso2 : 'MY';

  const name = clean(zone.name);
  let center = picked;
  if (!center) {
    try {
      const hit = (await photonTowns(name, origin, 3, cc)).find((t) => sameName(t.name, name)
        && (!origin || km(origin, t.center) <= NEAR_KM));
      center = hit?.center || null;
    } catch { /* next */ }
  }
  if (!center) { try { center = await centreFromMapbox(name, origin, Deno.env.get('CEFFLO_MAPBOX_ACCESS_TOKEN'), cc); } catch { /* next */ } }
  if (!center) { try { center = await centreFromOsm(name, origin, cc); } catch { /* none */ } }

  let area = null;
  if (pickedAreaId) {
    const { data } = await db.from('admin_areas').select(AREA_COLS).eq('id', pickedAreaId).maybeSingle();
    area = data || null;
    // The geocoded centre only counts when it lies in the picked area.
    if (area && center && !contains(area.geom, center)) center = null;
  }
  if (!area && center) area = await areaAt(db, center, cc);
  if (!area) area = await areaByName(db, name, center || origin, cc);
  if (!center && area) center = centroid(mainRing(area.geom, null));

  if (!center) {
    if (zone.boundary) await db.rpc('set_zone_boundary', { p_zone_id: zoneId, p_boundary: null });
    return json({ zone_id: zoneId, status: 'not_found' });
  }

  // Every active auto zone of the business is re-laid; hand-drawn ones stay.
  const target = { auto: true, center, area_id: area?.id || null };
  const zones = (all || []).map((z) => (z.id === zoneId ? { ...z, status: 'active', boundary: target } : z))
    .filter((z) => z.status === 'active' && z.boundary);
  const areas = new Map(area ? [[area.id, area]] : []);
  const ids = [...new Set(zones.map((z) => z.boundary.auto && z.boundary.area_id).filter((id) => id && !areas.has(id)))];
  if (ids.length) {
    const { data } = await db.from('admin_areas').select(AREA_COLS).in('id', ids);
    for (const a of data || []) areas.set(a.id, a);
  }
  const autos = zones.filter((z) => z.boundary.auto)
    .map((z) => ({ id: z.id, mid: middle(z.boundary), area: areas.get(z.boundary.area_id) || null }))
    .filter((z) => z.mid);
  const fixed = zones.filter((z) => !z.boundary.auto && z.boundary.type === 'Polygon').map((z) => z.boundary);
  const shapes = layout(autos, fixed);

  const writes = autos.map((z) => {
    const g = shapes.get(z.id);
    const boundary = g ? { ...g, auto: true, center: z.mid, area_id: z.area?.id || null } : null;
    return db.rpc('set_zone_boundary', { p_zone_id: z.id, p_boundary: boundary });
  });
  const results = await Promise.all(writes);
  if (results.some((r) => r.error)) return json({ error: 'Could not save the zone boundary' }, 403);
  return json({ zone_id: zoneId, status: shapes.has(zoneId) ? 'set' : 'covered', area: area?.name || null, updated: writes.length });
});
