// Loads official Malaysian area outlines into public.admin_areas (see
// supabase/migrations/20261013100000_admin_areas.sql).
//
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node scripts/load-admin-areas.mjs
//   node scripts/load-admin-areas.mjs --ndjson > areas.ndjson   (then \copy)
//
// Source: geoBoundaries gbOpen MYS, pinned to one release. ADM3 (mukim /
// bandar / pekan) everywhere it exists; Sabah has no ADM3, so its ADM2
// districts are used there. Idempotent: rows are upserted by id.

const RELEASE = 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/MYS';
const url = (level) => `${RELEASE}/${level}/geoBoundaries-MYS-${level}_simplified.geojson`;

const rings = (g) => (g.type === 'MultiPolygon' ? g.coordinates : [g.coordinates]).map((p) => p[0]);

function inside([x, y], ring) {
  let c = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i], [xj, yj] = ring[j];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) c = !c;
  }
  return c;
}

function areaKm2(g) {
  let a = 0;
  for (const r of rings(g)) {
    let s = 0;
    for (let i = 0; i < r.length - 1; i++) s += r[i][0] * r[i + 1][1] - r[i + 1][0] * r[i][1];
    const lat = r[0][1] * Math.PI / 180;
    a += (Math.abs(s) / 2) * 111.32 * 111.32 * Math.cos(lat);
  }
  return a;
}

// "BANDAR SEREMBAN" -> { label: "Seremban", kind: "Bandar" }.
const KINDS = { MUKIM: 'Mukim', BANDAR: 'Bandar', PEKAN: 'Pekan' };
const STATE_NAMES = { Malacca: 'Melaka', Penang: 'Pulau Pinang', 'Kuala Lumpur': 'Kuala Lumpur' };
const titleCase = (s) => s.toLowerCase().replace(/(^|[\s(\/-])(\p{L})/gu, (m, a, b) => a + b.toUpperCase());
function labelOf(name, level) {
  if (level === 'ADM2') return { label: name, kind: 'Daerah' };
  const [first, ...rest] = name.split(' ');
  if (KINDS[first] && rest.length) return { label: titleCase(rest.join(' ')), kind: KINDS[first] };
  return { label: titleCase(name.replace(/ LAND DISTRICT$/, '')), kind: 'Kawasan' };
}

let STATES = [];
const stateOf = (g) => {
  const r = rings(g).sort((a, b) => b.length - a.length)[0];
  const c = [r.reduce((s, p) => s + p[0], 0) / r.length, r.reduce((s, p) => s + p[1], 0) / r.length];
  const hit = STATES.find((st) => rings(st.geometry).some((ring) => inside(c, ring)));
  return hit ? STATE_NAMES[hit.properties.shapeName] || hit.properties.shapeName : null;
};

function row(f, level) {
  const pts = rings(f.geometry).flat();
  const lngs = pts.map((p) => p[0]), lats = pts.map((p) => p[1]);
  return {
    id: f.properties.shapeID,
    name: f.properties.shapeName,
    ...labelOf(f.properties.shapeName, level),
    state: stateOf(f.geometry),
    level,
    area_km2: +areaKm2(f.geometry).toFixed(2),
    min_lng: Math.min(...lngs), min_lat: Math.min(...lats),
    max_lng: Math.max(...lngs), max_lat: Math.max(...lats),
    geom: f.geometry,
  };
}

const get = async (level) => (await (await fetch(url(level))).json()).features;
const [adm1, adm2, adm3] = await Promise.all([get('ADM1'), get('ADM2'), get('ADM3')]);
STATES = adm1;
const sabah = adm1.find((f) => f.properties.shapeName === 'Sabah');
const inSabah = (f) => {
  const r = rings(f.geometry).sort((a, b) => b.length - a.length)[0];
  const c = [r.reduce((s, p) => s + p[0], 0) / r.length, r.reduce((s, p) => s + p[1], 0) / r.length];
  return rings(sabah.geometry).some((ring) => inside(c, ring));
};
const rows = [...adm3.map((f) => row(f, 'ADM3')), ...adm2.filter(inSabah).map((f) => row(f, 'ADM2'))];

// --ndjson: print one row per line instead (for psql \copy without an API key).
if (process.argv.includes('--ndjson')) {
  for (const r of rows) process.stdout.write(`${JSON.stringify(r)}\n`);
  process.exit(0);
}

const base = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!base || !key) throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
for (let i = 0; i < rows.length; i += 200) {
  const res = await fetch(`${base}/rest/v1/admin_areas`, {
    method: 'POST',
    headers: { apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json', Prefer: 'resolution=merge-duplicates' },
    body: JSON.stringify(rows.slice(i, i + 200)),
  });
  if (!res.ok) throw new Error(`Load failed at ${i}: ${res.status} ${await res.text()}`);
}
console.log(`Loaded ${rows.length} areas (${rows.filter((r) => r.level === 'ADM2').length} Sabah districts).`);
