// Delivery pin maps -- Mapbox GL when the build carries a public pk. token
// (Founder 2026-10-12); MapLibre over OpenFreeMap otherwise (the 2026-10-08
// fallback). A fixed centre pin, the map moves under it. Loaded on demand so
// other pages pay nothing.
import { t } from './i18n.js';
import { esc, icon } from './ui.js';

const MAPBOX_TOKEN = /^pk\./.test(window.CEFFLO_CONFIG?.mapboxPublicToken || '') ? window.CEFFLO_CONFIG.mapboxPublicToken : null;

// Each zone keeps one colour on every map and in the list (same palette and
// hash as the Vendor App's zoneColor).
const ZONE_PALETTE = ['#1E5EFF', '#E8590C', '#2B8A3E', '#9C36B5', '#C2255C', '#0B7285', '#B08900', '#5C3D2E'];
export const zoneColor = z => ZONE_PALETTE[[...String(z.id)].reduce((a, ch) => (a * 31 + ch.charCodeAt(0)) & 0xFFFFFF, 0) % ZONE_PALETTE.length];

// Map credit behind a small ⓘ (Founder 2026-10-13): the licences need the
// credit reachable on the map, not spelled out across it.
function compactCredit(gl, map) {
  map.addControl(new gl.AttributionControl({ compact: true }), 'bottom-left');
  const close = () => map.getContainer().querySelectorAll('.mapboxgl-compact-show, .maplibregl-compact-show')
    .forEach(el => el.classList.remove('mapboxgl-compact-show', 'maplibregl-compact-show'));
  map.once('load', close); close();
  // Redraw when the box changes size (a map created while its card was still
  // laying out drew only part of the canvas).
  const box = map.getContainer();
  if ('ResizeObserver' in window) new ResizeObserver(() => map.resize()).observe(box);
  map.once('load', () => map.resize());
}

const GL = MAPBOX_TOKEN
  ? 'https://api.mapbox.com/mapbox-gl-js/v3.7.0/mapbox-gl'
  : 'https://cdn.jsdelivr.net/npm/maplibre-gl@4.7.1/dist/maplibre-gl';
const STYLE = MAPBOX_TOKEN ? 'mapbox://styles/mapbox/streets-v12' : 'https://tiles.openfreemap.org/styles/positron';
const MY_CENTER = [101.9, 4.2];
const PIN_SVG = '<svg viewBox="0 0 40 52" aria-hidden="true"><path d="M20 51C20 51 3 32.6 3 19.5a17 17 0 0 1 34 0C37 32.6 20 51 20 51z"/><circle cx="20" cy="19.5" r="6.5"/></svg>';

let loading = null;
function loadMapLibre() {
  const ready = () => (MAPBOX_TOKEN ? window.mapboxgl : window.maplibregl);
  if (ready()) return Promise.resolve(ready());
  loading ||= new Promise((ok, bad) => {
    const css = document.createElement('link'); css.rel = 'stylesheet'; css.href = `${GL}.css`; document.head.append(css);
    const s = document.createElement('script'); s.src = `${GL}.js`;
    s.onload = () => { const gl = ready(); if (MAPBOX_TOKEN) gl.accessToken = MAPBOX_TOKEN; ok(gl); };
    s.onerror = () => { loading = null; bad(new Error('map')); };
    document.head.append(s);
  });
  return loading;
}

export const hasPin = o => o && o.latitude != null && o.longitude != null;
export const mapsLink = query => `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}`;

// Mapbox draws its own logo + attribution; the fallback needs ours.
const attr = MAPBOX_TOKEN ? '' : '<span class="pm-attr">© OpenStreetMap · OpenFreeMap</span>';

// Read-only map with the pin at the centre.
export async function mountViewMap(box, lat, lng) {
  box.classList.add('pm', 'pm-view');
  box.innerHTML = `<div class="pm-canvas"></div><div class="pm-pin has">${PIN_SVG}<i></i></div>${attr}`;
  try {
    const gl = await loadMapLibre();
    if (!box.isConnected) return null;
    const map = new gl.Map({ container: box.querySelector('.pm-canvas'), style: STYLE, center: [lng, lat], zoom: 16.5,
      attributionControl: false, dragRotate: false, pitchWithRotate: false, touchPitch: false, scrollZoom: false });
      compactCredit(gl, map);
    map.touchZoomRotate.disableRotation();
    return map;
  } catch { box.innerHTML = ''; box.hidden = true; return null; }
}

// Picker: returns { get(), destroy() }. get() is null until the vendor either
// locates or deliberately moves the map at zoom >= 14 (same rule as Storefront).
export function mountPicker(box, initial, onChange) {
  box.classList.add('pm');
  box.innerHTML = `<div class="pm-canvas"></div><div class="pm-pin${initial ? ' has' : ''}">${PIN_SVG}<i></i></div>
    <div class="pm-zoom"><button type="button" data-z="1" aria-label="${esc(t('pin.zoomIn'))}">${icon('plus')}</button><button type="button" data-z="-1" aria-label="${esc(t('pin.zoomOut'))}">${icon('minus')}</button></div>
    <button type="button" class="pm-locate" data-locate aria-label="${esc(t('pin.locate'))}">${icon('crosshair')}</button>${attr}`;
  let pin = initial ? { lat: initial.lat, lng: initial.lng } : null, changed = false, map = null;
  const show = () => { box.querySelector('.pm-pin').classList.toggle('has', !!pin); onChange?.(pin); };
  loadMapLibre().then(gl => {
    if (!box.isConnected) return;
    map = new gl.Map({ container: box.querySelector('.pm-canvas'), style: STYLE, center: pin ? [pin.lng, pin.lat] : MY_CENTER,
      zoom: pin ? 17 : 5, attributionControl: false, dragRotate: false, pitchWithRotate: false, touchPitch: false });
      compactCredit(gl, map);
    map.touchZoomRotate.disableRotation();
    map.on('movestart', e => { if (e.originalEvent) box.classList.add('is-moving'); });
    map.on('moveend', e => {
      box.classList.remove('is-moving');
      if (!e.originalEvent) return;                       // programmatic moves set the pin themselves
      if (map.getZoom() < 14) return;                      // too far out to be a doorstep
      const c = map.getCenter();
      pin = { lat: +c.lat.toFixed(6), lng: +c.lng.toFixed(6) }; changed = true; show();
    });
  }).catch(() => { box.innerHTML = `<p class="hint" style="padding:16px">${esc(t('pin.mapFail'))}</p>`; });
  box.addEventListener('click', e => {
    const z = e.target.closest('[data-z]');
    if (z) { map?.easeTo({ zoom: map.getZoom() + Number(z.dataset.z), duration: 250 }); return; }
    if (!e.target.closest('[data-locate]') || !navigator.geolocation) return;
    box.classList.add('is-locating');
    navigator.geolocation.getCurrentPosition(p => {
      box.classList.remove('is-locating');
      pin = { lat: +p.coords.latitude.toFixed(6), lng: +p.coords.longitude.toFixed(6) }; changed = true; show();
      map?.flyTo({ center: [pin.lng, pin.lat], zoom: 17, duration: 900 });
    }, () => box.classList.remove('is-locating'), { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 });
  });
  return { get: () => pin, changed: () => changed, map: () => map, destroy: () => { map?.remove(); map = null; } };
}

// Read-only map with several pins (run stops, zone orders). drops:
// [{ lat, lng, label?, done?, next? }]. Fits all pins; Malaysia when none.
// riders (Today live map only): [{ lat, lng, name }] -- latest authorised
// point of this business's own drivers.
// zones: [{ name, boundary }] -- vendor-drawn GeoJSON polygons, drawn under the pins.
export async function mountPinsMap(box, drops, riders = [], zones = []) {
  box.classList.add('pm', 'pm-multi');
  box.innerHTML = `<div class="pm-canvas"></div>${drops.length ? '' : `<div class="pm-empty">${esc(t('pin.noPinned'))}</div>`}${attr}`;
  try {
    const gl = await loadMapLibre();
    if (!box.isConnected) return null;
    const map = new gl.Map({ container: box.querySelector('.pm-canvas'), style: STYLE,
      center: drops.length ? [drops[0].lng, drops[0].lat] : MY_CENTER, zoom: drops.length || riders.length ? 15 : 5,
      attributionControl: false, dragRotate: false, pitchWithRotate: false, touchPitch: false, scrollZoom: false });
      compactCredit(gl, map);
    map.touchZoomRotate.disableRotation();
    // Next stop last so it draws on top.
    [...drops.filter(d => !d.next), ...drops.filter(d => d.next)].forEach(d => {
      const m = document.createElement('div');
      m.className = `pm-dot${d.done ? ' done' : d.next ? ' next' : ''}`;
      m.innerHTML = d.done ? icon('check') : esc(d.label ?? '');
      new gl.Marker({ element: m }).setLngLat([d.lng, d.lat]).addTo(map);
    });
    const shapes = zones.filter(z => z.boundary?.coordinates?.[0]?.length > 3);
    if (shapes.length) {
      const addZones = () => {
        map.addSource('zones', { type: 'geojson', attribution: '© geoBoundaries', data: { type: 'FeatureCollection', features: shapes.map(z => ({ type: 'Feature', geometry: z.boundary, properties: { name: z.name, color: zoneColor(z) } })) } });
        // Soft zones (Founder 2026-10-13): light tint, thin edge, no label on
        // top of the map's own place names; the colour matches the list.
        map.addLayer({ id: 'zones-fill', type: 'fill', source: 'zones', paint: { 'fill-color': ['get', 'color'], 'fill-opacity': 0.12 } });
        map.addLayer({ id: 'zones-line', type: 'line', source: 'zones', paint: { 'line-color': ['get', 'color'], 'line-width': 1.5, 'line-opacity': 0.55 } });
      };
      map.isStyleLoaded() ? addZones() : map.once('load', addZones);
    }
    riders.forEach(r => {
      const m = document.createElement('div');
      m.className = 'pm-rider'; m.title = r.name || '';
      m.innerHTML = icon('moto');
      new gl.Marker({ element: m }).setLngLat([r.lng, r.lat]).addTo(map);
    });
    const all = [...drops, ...riders, ...shapes.flatMap(z => z.boundary.coordinates[0].map(([lng, lat]) => ({ lat, lng })))];
    if (all.length === 1) map.setCenter([all[0].lng, all[0].lat]);
    if (all.length > 1) {
      const b = new gl.LngLatBounds();
      all.forEach(d => b.extend([d.lng, d.lat]));
      map.fitBounds(b, { padding: 40, maxZoom: 16, duration: 0 });
    }
    return map;
  } catch { box.innerHTML = `<p class="hint" style="padding:16px">${esc(t('pin.mapFail'))}</p>`; return null; }
}

// Coverage map (Business profile, Founder 2026-10-12): the pickup origin as
// a picker pin plus the real coverage radius drawn as a circle. Moving the
// map moves the origin (same rule as mountPicker); setRadius redraws.
const circle = (lat, lng, km, n = 64) => {
  const ring = [];
  for (let i = 0; i <= n; i++) {
    const a = (i / n) * 2 * Math.PI;
    ring.push([lng + (km / (111.32 * Math.cos(lat * Math.PI / 180))) * Math.cos(a), lat + (km / 110.57) * Math.sin(a)]);
  }
  return { type: 'Feature', geometry: { type: 'Polygon', coordinates: [ring] }, properties: {} };
};

export function mountCoverageMap(box, initial, radiusKm, onChange) {
  let km = Number(radiusKm) || 0, map = null;
  const picker = mountPicker(box, initial, pin => { onChange?.(pin); draw(); });
  const draw = () => {
    map ||= picker.map?.();
    const pin = picker.get();
    if (!map || (!map.getSource('cov') && !map.isStyleLoaded())) return;
    const data = pin && km > 0 ? circle(pin.lat, pin.lng, km) : { type: 'FeatureCollection', features: [] };
    if (map.getSource('cov')) { map.getSource('cov').setData(data); return; }
    map.addSource('cov', { type: 'geojson', data });
    map.addLayer({ id: 'cov-fill', type: 'fill', source: 'cov', paint: { 'fill-color': '#0060FE', 'fill-opacity': 0.12 } });
    map.addLayer({ id: 'cov-line', type: 'line', source: 'cov', paint: { 'line-color': '#0060FE', 'line-width': 2 } });
  };
  const wait = setInterval(() => { const m = picker.map?.(); if (m) { clearInterval(wait); map = m; m.on('load', () => { draw(); fit(); }); if (m.isStyleLoaded()) { draw(); fit(); } } }, 100);
  const fit = () => {
    const pin = picker.get();
    if (!map || !pin || !(km > 0)) return;
    const c = circle(pin.lat, pin.lng, km).geometry.coordinates[0];
    const b = c.reduce((acc, p) => acc.extend(p), new (MAPBOX_TOKEN ? window.mapboxgl : window.maplibregl).LngLatBounds(c[0], c[0]));
    map.fitBounds(b, { padding: 24, duration: 0 });
  };
  return { ...picker, setRadius: v => { km = Number(v) || 0; draw(); fit(); }, destroy: () => { clearInterval(wait); picker.destroy(); } };
}

// Zone boundary drawer (Founder 2026-10-12, option B): tap the map to add a
// corner, Undo removes the last, Clear starts over. get() returns a closed
// GeoJSON Polygon, or null with fewer than 3 corners. Other zones are drawn
// faintly for reference.
export function mountZoneDrawer(box, initial, others = []) {
  box.classList.add('pm', 'pm-picker');
  box.innerHTML = `<div class="pm-canvas"></div>
    <div class="pm-draw"><button type="button" class="btn sm" data-undo>${esc(t('zones.drawUndo'))}</button><button type="button" class="btn sm" data-clear>${esc(t('zones.drawClear'))}</button></div>${attr}`;
  let pts = initial?.coordinates?.[0]?.slice(0, -1).map(([lng, lat]) => [lng, lat]) || [], map = null;
  const closed = () => (pts.length >= 3 ? [...pts, pts[0]] : null);
  const draw = () => {
    if (!map?.getSource('draw')) return;
    const ring = closed();
    const data = { type: 'FeatureCollection', features: [
      ...(ring ? [{ type: 'Feature', geometry: { type: 'Polygon', coordinates: [ring] }, properties: {} }] : []),
      ...(pts.length >= 2 && !ring ? [{ type: 'Feature', geometry: { type: 'LineString', coordinates: pts }, properties: {} }] : []),
      ...pts.map(p => ({ type: 'Feature', geometry: { type: 'Point', coordinates: p }, properties: {} })),
    ] };
    map.getSource('draw').setData(data);
  };
  // Built a moment after the modal opens, once it has its final size.
  new Promise(r => setTimeout(r, 250)).then(loadMapLibre).then(gl => {
    if (!box.isConnected) return;
    const all = [...pts, ...others.flatMap(z => z.boundary?.coordinates?.[0] || [])];
    map = new gl.Map({ container: box.querySelector('.pm-canvas'), style: STYLE, center: all[0] || MY_CENTER, zoom: all.length ? 12 : 5,
      attributionControl: false, dragRotate: false, pitchWithRotate: false, touchPitch: false });
      compactCredit(gl, map);
    map.touchZoomRotate.disableRotation();
    // Opened inside a modal that is still laying out: size again once shown.
    [50, 300, 800].forEach(ms => setTimeout(() => map?.resize(), ms));
    map.on('load', () => {
      map.resize();
      map.addSource('others', { type: 'geojson', data: { type: 'FeatureCollection', features: others.filter(z => z.boundary).map(z => ({ type: 'Feature', geometry: z.boundary, properties: {} })) } });
      map.addLayer({ id: 'others-line', type: 'line', source: 'others', paint: { 'line-color': '#9AA3B2', 'line-width': 1.5, 'line-dasharray': [2, 2] } });
      map.addSource('draw', { type: 'geojson', data: { type: 'FeatureCollection', features: [] } });
      map.addLayer({ id: 'draw-fill', type: 'fill', source: 'draw', filter: ['==', '$type', 'Polygon'], paint: { 'fill-color': '#0060FE', 'fill-opacity': 0.15 } });
      map.addLayer({ id: 'draw-line', type: 'line', source: 'draw', filter: ['!=', '$type', 'Point'], paint: { 'line-color': '#0060FE', 'line-width': 2.5 } });
      map.addLayer({ id: 'draw-pts', type: 'circle', source: 'draw', filter: ['==', '$type', 'Point'], paint: { 'circle-radius': 6, 'circle-color': '#fff', 'circle-stroke-color': '#0060FE', 'circle-stroke-width': 2.5 } });
      if (all.length > 1) {
        const b = new gl.LngLatBounds(); all.forEach(p => b.extend(p));
        map.fitBounds(b, { padding: 40, maxZoom: 15, duration: 0 });
      }
      draw();
    });
    map.on('click', e => { if (pts.length < 200) { pts.push([+e.lngLat.lng.toFixed(6), +e.lngLat.lat.toFixed(6)]); draw(); } });
  }).catch(() => { box.innerHTML = `<p class="hint" style="padding:16px">${esc(t('pin.mapFail'))}</p>`; });
  box.addEventListener('click', e => {
    if (e.target.closest('[data-undo]')) { pts.pop(); draw(); }
    if (e.target.closest('[data-clear]')) { pts = []; draw(); }
  });
  return { get: () => { const r = closed(); return r ? { type: 'Polygon', coordinates: [r] } : null; }, count: () => pts.length, destroy: () => { map?.remove(); map = null; } };
}

// Hexagon zone map (Auto Zone D1/D4, 2026-10-14): the business's H3 cells
// (public.zone_cells) tinted by zone, grey when no zone. paint(cell) is
// called on a click; setPending redraws with pending changes outlined.
const H3_URL = 'https://cdn.jsdelivr.net/npm/h3-js@4.1.0/dist/h3-js.umd.js';
let h3Loading = null;
function loadH3() {
  if (window.h3) return Promise.resolve(window.h3);
  h3Loading ||= new Promise((ok, bad) => {
    const s = document.createElement('script'); s.src = H3_URL;
    s.onload = () => ok(window.h3);
    s.onerror = () => { h3Loading = null; bad(new Error('h3')); };
    document.head.append(s);
  });
  return h3Loading;
}

// orders: [{ lat, lng }] drawn as dots on top. onCell(cell, { drag }) is
// called on a tap, and for every cell crossed while drag-painting is on.
export async function mountHexMap(box, cells, zones, { onCell, orders = [] } = {}) {
  box.classList.add('pm', 'pm-hex');
  box.innerHTML = `<div class="pm-canvas"></div>${attr}`;
  try {
    const [gl, h3] = await Promise.all([loadMapLibre(), loadH3()]);
    if (!box.isConnected) return null;
    const colour = new Map(zones.map(z => [z.id, zoneColor(z)]));
    const shape = new Map(cells.map(c => [c.cell, h3.cellToBoundary(c.cell, true)]));
    const data = (assign, pending) => ({ type: 'FeatureCollection', features: cells.map(c => {
      const zid = pending.has(c.cell) ? pending.get(c.cell) : assign.get(c.cell);
      return { type: 'Feature', id: c.cell, geometry: { type: 'Polygon', coordinates: [shape.get(c.cell)] },
        properties: { cell: c.cell, color: (zid && colour.get(zid)) || '#9AA3B2', zoned: zid ? 1 : 0, pending: pending.has(c.cell) ? 1 : 0 } };
    }) });
    const assign = new Map(cells.map(c => [c.cell, c.zone_id || null]));
    let dragMode = false;
    const map = new gl.Map({ container: box.querySelector('.pm-canvas'), style: STYLE, center: MY_CENTER, zoom: 5,
      attributionControl: false, dragRotate: false, pitchWithRotate: false, touchPitch: false });
    compactCredit(gl, map);
    map.touchZoomRotate.disableRotation();
    map.on('load', () => {
      map.addSource('hex', { type: 'geojson', attribution: 'H3 · Uber', data: data(assign, new Map()) });
      map.addLayer({ id: 'hex-fill', type: 'fill', source: 'hex',
        paint: { 'fill-color': ['get', 'color'], 'fill-opacity': ['case', ['==', ['get', 'pending'], 1], 0.55, ['==', ['get', 'zoned'], 1], 0.32, 0.08] } });
      map.addLayer({ id: 'hex-line', type: 'line', source: 'hex',
        paint: { 'line-color': ['case', ['==', ['get', 'pending'], 1], '#111', ['get', 'color']], 'line-width': ['case', ['==', ['get', 'pending'], 1], 1.6, 0.4], 'line-opacity': 0.6 } });
      map.addSource('orders', { type: 'geojson', data: { type: 'FeatureCollection', features: orders.map(o => ({ type: 'Feature', geometry: { type: 'Point', coordinates: [o.lng, o.lat] }, properties: {} })) } });
      map.addLayer({ id: 'orders-dot', type: 'circle', source: 'orders',
        paint: { 'circle-radius': 5, 'circle-color': '#111', 'circle-stroke-color': '#fff', 'circle-stroke-width': 2 } });
      map.on('click', 'hex-fill', e => { if (dragMode) return; const f = e.features?.[0]; if (f) onCell?.(f.properties.cell, { drag: false }); });
      // Drag-painting: the map stops panning and every cell under the
      // finger / pointer is painted once per stroke.
      const cellAt = pt => map.queryRenderedFeatures(pt, { layers: ['hex-fill'] })[0]?.properties.cell;
      let stroke = null;
      const start = pt => { if (!dragMode) return; stroke = new Set(); move(pt); };
      const move = pt => {
        if (!stroke) return;
        const c = cellAt(pt);
        if (c && !stroke.has(c)) { stroke.add(c); onCell?.(c, { drag: true }); }
      };
      const end = () => { stroke = null; };
      map.on('mousedown', e => start(e.point));
      map.on('mousemove', e => move(e.point));
      map.on('mouseup', end);
      map.on('touchstart', e => { if (dragMode) e.preventDefault(); start(e.point); });
      map.on('touchmove', e => { if (dragMode) e.preventDefault(); move(e.point); });
      map.on('touchend', end);
      map.on('mouseenter', 'hex-fill', () => { if (!dragMode) map.getCanvas().style.cursor = 'pointer'; });
      map.on('mouseleave', 'hex-fill', () => { if (!dragMode) map.getCanvas().style.cursor = ''; });
      if (cells.length) {
        const b = new gl.LngLatBounds();
        cells.forEach(c => b.extend([c.centre_lng, c.centre_lat]));
        map.fitBounds(b, { padding: 24, duration: 0 });
      }
    });
    return {
      map,
      setDragMode(on) {
        dragMode = !!on;
        if (dragMode) { map.dragPan.disable(); map.touchZoomRotate.disable(); } else { map.dragPan.enable(); map.touchZoomRotate.enable(); map.touchZoomRotate.disableRotation(); }
        map.getCanvas().style.cursor = dragMode ? 'crosshair' : '';
      },
      setPending(pending) { map.getSource('hex')?.setData(data(assign, pending)); },
      commit(pending) { pending.forEach((z, c) => assign.set(c, z)); map.getSource('hex')?.setData(data(assign, new Map())); },
    };
  } catch { box.innerHTML = `<p class="hint" style="padding:16px">${esc(t('pin.mapFail'))}</p>`; return null; }
}
