// Google Maps for Vendor Web (Auto Zone + Google Maps master guideline
// Phase 5, 2026-10-14). Same exports and return shapes as map.js; map.js
// hands over to this module when the build carries a browser key
// (window.CEFFLO_CONFIG.googleMapsBrowserKey, restricted by HTTP referrer).
import { t } from './i18n.js';
import { esc, icon } from './ui.js';

const KEY = window.CEFFLO_CONFIG?.googleMapsBrowserKey || '';
const MY_CENTER = { lat: 4.2, lng: 101.9 };
const PIN_SVG = '<svg viewBox="0 0 40 52" aria-hidden="true"><path d="M20 51C20 51 3 32.6 3 19.5a17 17 0 0 1 34 0C37 32.6 20 51 20 51z"/><circle cx="20" cy="19.5" r="6.5"/></svg>';
// Quiet basemap: no points of interest or transit labels competing with pins.
const STYLES = [
  { featureType: 'poi', stylers: [{ visibility: 'off' }] },
  { featureType: 'transit', stylers: [{ visibility: 'off' }] },
];
const BASE = { disableDefaultUI: true, zoomControl: true, clickableIcons: false, styles: STYLES, gestureHandling: 'greedy' };

let loading = null;
export function loadGoogle() {
  if (window.google?.maps?.Map) return Promise.resolve(window.google.maps);
  loading ||= new Promise((ok, bad) => {
    const cb = `__cfGmaps${Date.now()}`;
    window[cb] = () => { delete window[cb]; ok(window.google.maps); };
    const s = document.createElement('script');
    s.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(KEY)}&v=weekly&callback=${cb}`;
    s.async = true;
    s.onerror = () => { loading = null; bad(new Error('map')); };
    document.head.append(s);
  });
  return loading;
}

const fail = box => { box.innerHTML = `<p class="hint" style="padding:16px">${esc(t('pin.mapFail'))}</p>`; };
const ll = p => ({ lat: p.lat, lng: p.lng });

// HTML marker (keeps the app's own pin / dot / rider styles).
function htmlMarker(g, map, pos, el) {
  const o = new g.OverlayView();
  o.onAdd = () => { el.style.position = 'absolute'; o.getPanes().overlayMouseTarget.append(el); };
  o.draw = () => {
    const p = o.getProjection()?.fromLatLngToDivPixel(new g.LatLng(pos.lat, pos.lng));
    if (p) { el.style.left = `${p.x}px`; el.style.top = `${p.y}px`; el.style.transform = 'translate(-50%,-50%)'; }
  };
  o.onRemove = () => el.remove();
  o.setMap(map);
  return o;
}

function fit(g, map, points, maxZoom = 16) {
  if (!points.length) return;
  if (points.length === 1) { map.setCenter(points[0]); map.setZoom(Math.min(15, maxZoom)); return; }
  const b = new g.LatLngBounds();
  points.forEach(p => b.extend(p));
  map.fitBounds(b, 40);
  g.event.addListenerOnce(map, 'idle', () => { if (map.getZoom() > maxZoom) map.setZoom(maxZoom); });
}

const geoPoints = geom => (geom?.type === 'MultiPolygon' ? geom.coordinates.flat(2) : geom?.type === 'Polygon' ? geom.coordinates.flat(1) : [])
  .map(([lng, lat]) => ({ lat, lng }));

// Read-only map with the pin at the centre.
export async function mountViewMap(box, lat, lng) {
  box.classList.add('pm', 'pm-view');
  box.innerHTML = `<div class="pm-canvas"></div><div class="pm-pin has">${PIN_SVG}<i></i></div>`;
  try {
    const g = await loadGoogle();
    if (!box.isConnected) return null;
    return new g.Map(box.querySelector('.pm-canvas'), { ...BASE, center: { lat, lng }, zoom: 17, gestureHandling: 'cooperative' });
  } catch { box.innerHTML = ''; box.hidden = true; return null; }
}

// Picker: fixed centre pin, the map moves under it. Same rule as map.js:
// the pin counts once the vendor locates or moves the map at zoom >= 14.
export function mountPicker(box, initial, onChange) {
  box.classList.add('pm');
  box.innerHTML = `<div class="pm-canvas"></div><div class="pm-pin${initial ? ' has' : ''}">${PIN_SVG}<i></i></div>
    <button type="button" class="pm-locate" data-locate aria-label="${esc(t('pin.locate'))}">${icon('crosshair')}</button>`;
  let pin = initial ? ll(initial) : null, changed = false, map = null, userMove = false;
  const listeners = [];
  const show = () => { box.querySelector('.pm-pin').classList.toggle('has', !!pin); onChange?.(pin); listeners.forEach(f => f(pin)); };
  const ready = loadGoogle().then(g => {
    if (!box.isConnected) return null;
    map = new g.Map(box.querySelector('.pm-canvas'), { ...BASE, center: pin || MY_CENTER, zoom: pin ? 17 : 6 });
    map.addListener('dragstart', () => { userMove = true; box.classList.add('is-moving'); });
    map.addListener('zoom_changed', () => { if (pin) userMove = true; });
    map.addListener('idle', () => {
      box.classList.remove('is-moving');
      if (!userMove) return;
      userMove = false;
      if (map.getZoom() < 14) return;
      const c = map.getCenter();
      pin = { lat: +c.lat().toFixed(6), lng: +c.lng().toFixed(6) }; changed = true; show();
    });
    return map;
  }).catch(() => { fail(box); return null; });
  const setPin = (p, zoom = 17) => {
    pin = { lat: +Number(p.lat).toFixed(6), lng: +Number(p.lng).toFixed(6) }; changed = true; show();
    ready.then(m => { if (m) { userMove = false; m.panTo(pin); m.setZoom(zoom); } });
  };
  box.addEventListener('click', e => {
    if (!e.target.closest('[data-locate]') || !navigator.geolocation) return;
    box.classList.add('is-locating');
    navigator.geolocation.getCurrentPosition(p => {
      box.classList.remove('is-locating');
      setPin({ lat: p.coords.latitude, lng: p.coords.longitude });
    }, () => box.classList.remove('is-locating'), { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 });
  });
  return {
    get: () => pin, changed: () => changed, map: () => map, setPin, ready,
    onPin: f => listeners.push(f),
    destroy: () => { map = null; },
  };
}

// Several pins (run stops, zone orders), zones as soft shapes, live riders.
export async function mountPinsMap(box, drops, riders = [], zones = []) {
  box.classList.add('pm', 'pm-multi');
  box.innerHTML = `<div class="pm-canvas"></div>${drops.length ? '' : `<div class="pm-empty">${esc(t('pin.noPinned'))}</div>`}`;
  try {
    const g = await loadGoogle();
    if (!box.isConnected) return null;
    const map = new g.Map(box.querySelector('.pm-canvas'), { ...BASE, center: MY_CENTER, zoom: 6, gestureHandling: 'cooperative' });
    const { zoneColor } = await import('./map.js');
    const shapes = zones.filter(z => z.boundary?.coordinates?.length);
    shapes.forEach(z => map.data.addGeoJson({ type: 'Feature', geometry: z.boundary, properties: { color: zoneColor(z) } }));
    map.data.setStyle(f => ({ fillColor: f.getProperty('color'), fillOpacity: 0.12, strokeColor: f.getProperty('color'), strokeOpacity: 0.55, strokeWeight: 1.5, clickable: false }));
    const overlays = [];
    [...drops.filter(d => !d.next), ...drops.filter(d => d.next)].forEach(d => {
      const el = document.createElement('div');
      el.className = `pm-dot${d.done ? ' done' : d.next ? ' next' : ''}`;
      el.innerHTML = d.done ? icon('check') : esc(d.label ?? '');
      overlays.push(htmlMarker(g, map, d, el));
    });
    riders.forEach(r => {
      const el = document.createElement('div');
      el.className = 'pm-rider'; el.title = r.name || '';
      el.innerHTML = icon('moto');
      overlays.push(htmlMarker(g, map, r, el));
    });
    fit(g, map, [...drops, ...riders, ...shapes.flatMap(z => geoPoints(z.boundary))]);
    // map.js callers call remove() before re-mounting (Today live map).
    map.remove = () => { overlays.forEach(o => o.setMap(null)); };
    return map;
  } catch { fail(box); return null; }
}

// Coverage map: picker + the real coverage circle.
export function mountCoverageMap(box, initial, radiusKm, onChange) {
  let km = Number(radiusKm) || 0, circle = null;
  const picker = mountPicker(box, initial, onChange);
  const draw = () => {
    const map = picker.map(), pin = picker.get(), g = window.google?.maps;
    if (!map || !g) return;
    if (!pin || !(km > 0)) { circle?.setMap(null); circle = null; return; }
    circle ||= new g.Circle({ map, strokeColor: '#0060FE', strokeWeight: 2, fillColor: '#0060FE', fillOpacity: 0.12, clickable: false });
    circle.setCenter(pin); circle.setRadius(km * 1000);
  };
  const fitCircle = () => { const m = picker.map(); if (m && circle) m.fitBounds(circle.getBounds(), 24); };
  picker.onPin(draw);
  picker.ready.then(() => { draw(); fitCircle(); });
  return {
    ...picker,
    setRadius: v => { km = Number(v) || 0; draw(); fitCircle(); },
    setPin: (p, zoom) => { picker.setPin(p, zoom); draw(); },
    destroy: () => { circle?.setMap(null); picker.destroy(); },
  };
}

// Zone boundary drawer: tap to add corners; Undo / Clear.
export function mountZoneDrawer(box, initial, others = []) {
  box.classList.add('pm', 'pm-picker');
  box.innerHTML = `<div class="pm-canvas"></div>
    <div class="pm-draw"><button type="button" class="btn sm" data-undo>${esc(t('zones.drawUndo'))}</button><button type="button" class="btn sm" data-clear>${esc(t('zones.drawClear'))}</button></div>`;
  let pts = initial?.coordinates?.[0]?.slice(0, -1).map(([lng, lat]) => ({ lat, lng })) || [], map = null, poly = null, dots = [];
  const draw = () => {
    const g = window.google?.maps;
    if (!map || !g) return;
    poly?.setMap(null); dots.forEach(d => d.setMap(null)); dots = [];
    poly = pts.length >= 3
      ? new g.Polygon({ map, paths: pts, strokeColor: '#0060FE', strokeWeight: 2.5, fillColor: '#0060FE', fillOpacity: 0.15, clickable: false })
      : new g.Polyline({ map, path: pts, strokeColor: '#0060FE', strokeWeight: 2.5, clickable: false });
    dots = pts.map(p => new g.Marker({ map, position: p, clickable: false,
      icon: { path: g.SymbolPath.CIRCLE, scale: 6, fillColor: '#fff', fillOpacity: 1, strokeColor: '#0060FE', strokeWeight: 2.5 } }));
  };
  new Promise(r => setTimeout(r, 250)).then(loadGoogle).then(g => {
    if (!box.isConnected) return;
    map = new g.Map(box.querySelector('.pm-canvas'), { ...BASE, center: pts[0] || MY_CENTER, zoom: pts.length ? 12 : 6, draggableCursor: 'crosshair' });
    others.filter(z => z.boundary).forEach(z => map.data.addGeoJson({ type: 'Feature', geometry: z.boundary, properties: {} }));
    map.data.setStyle({ fillOpacity: 0, strokeColor: '#9AA3B2', strokeWeight: 1.5, clickable: false });
    fit(g, map, [...pts, ...others.flatMap(z => geoPoints(z.boundary))], 15);
    map.addListener('click', e => { if (pts.length < 200) { pts.push({ lat: +e.latLng.lat().toFixed(6), lng: +e.latLng.lng().toFixed(6) }); draw(); } });
    draw();
  }).catch(() => fail(box));
  box.addEventListener('click', e => {
    if (e.target.closest('[data-undo]')) { pts.pop(); draw(); }
    if (e.target.closest('[data-clear]')) { pts = []; draw(); }
  });
  const ring = () => (pts.length >= 3 ? [...pts, pts[0]].map(p => [p.lng, p.lat]) : null);
  return { get: () => { const r = ring(); return r ? { type: 'Polygon', coordinates: [r] } : null; }, count: () => pts.length, destroy: () => { map = null; } };
}

// Hexagon zone map: cells tinted by zone; tap or drag-paint (see map.js).
export async function mountHexMap(box, cells, zones, { onCell, orders = [] } = {}, { loadH3, zoneColor }) {
  box.classList.add('pm', 'pm-hex');
  box.innerHTML = '<div class="pm-canvas"></div><div class="pm-paint" hidden></div>';
  try {
    const [g, h3] = await Promise.all([loadGoogle(), loadH3()]);
    if (!box.isConnected) return null;
    const colour = new Map(zones.map(z => [z.id, zoneColor(z)]));
    const assign = new Map(cells.map(c => [c.cell, c.zone_id || null]));
    let pending = new Map(), dragMode = false;
    const map = new g.Map(box.querySelector('.pm-canvas'), { ...BASE, center: MY_CENTER, zoom: 6 });
    map.data.addGeoJson({ type: 'FeatureCollection', features: cells.map(c => ({ type: 'Feature', id: c.cell,
      geometry: { type: 'Polygon', coordinates: [h3.cellToBoundary(c.cell, true)] }, properties: { cell: c.cell } })) });
    const style = f => {
      const cell = f.getProperty('cell'), isPending = pending.has(cell);
      const zid = isPending ? pending.get(cell) : assign.get(cell);
      const color = (zid && colour.get(zid)) || '#9AA3B2';
      return { fillColor: color, fillOpacity: isPending ? 0.55 : zid ? 0.32 : 0.08,
        strokeColor: isPending ? '#111' : color, strokeWeight: isPending ? 1.6 : 0.4, strokeOpacity: 0.6, cursor: 'pointer' };
    };
    map.data.setStyle(style);
    orders.forEach(o => {
      const el = document.createElement('div');
      el.style.cssText = 'width:10px;height:10px;border-radius:50%;background:#111;border:2px solid #fff;pointer-events:none';
      htmlMarker(g, map, o, el);
    });
    map.data.addListener('click', e => { if (!dragMode) onCell?.(e.feature.getProperty('cell'), { drag: false }); });
    fit(g, map, cells.map(c => ({ lat: c.centre_lat, lng: c.centre_lng })), 17);

    // Drag-painting: a transparent layer over the map takes the pointer, so
    // panning stops and every cell under the stroke is painted once.
    const known = new Set(assign.keys());
    const layer = box.querySelector('.pm-paint');
    layer.style.cssText = 'position:absolute;inset:0;z-index:4;touch-action:none;cursor:crosshair';
    const proj = new g.OverlayView(); proj.onAdd = () => {}; proj.draw = () => {}; proj.onRemove = () => {}; proj.setMap(map);
    let stroke = null;
    const cellAt = e => {
      const r = layer.getBoundingClientRect();
      const p = proj.getProjection()?.fromContainerPixelToLatLng(new g.Point(e.clientX - r.left, e.clientY - r.top));
      const c = p && h3.latLngToCell(p.lat(), p.lng(), 9);
      return c && known.has(c) ? c : null;
    };
    const paint = e => { const c = cellAt(e); if (c && !stroke.has(c)) { stroke.add(c); onCell?.(c, { drag: true }); } };
    layer.addEventListener('pointerdown', e => { stroke = new Set(); layer.setPointerCapture(e.pointerId); paint(e); });
    layer.addEventListener('pointermove', e => { if (stroke) paint(e); });
    ['pointerup', 'pointercancel'].forEach(n => layer.addEventListener(n, () => { stroke = null; }));

    return {
      map,
      setDragMode(on) { dragMode = !!on; layer.hidden = !dragMode; },
      setPending(p) { pending = new Map(p); map.data.setStyle(style); },
      commit(p) { p.forEach((z, c) => assign.set(c, z)); pending = new Map(); map.data.setStyle(style); },
    };
  } catch { fail(box); return null; }
}
