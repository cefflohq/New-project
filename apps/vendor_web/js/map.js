// Delivery pin maps — MapLibre GL over OpenFreeMap tiles (temporary until
// Mapbox, Founder 2026-10-08). Mirrors the Storefront pin UI: a fixed centre
// pin, the map moves under it. Loaded on demand so other pages pay nothing.
import { t } from './i18n.js';
import { esc, icon } from './ui.js';

const GL = 'https://cdn.jsdelivr.net/npm/maplibre-gl@4.7.1/dist/maplibre-gl';
const STYLE = 'https://tiles.openfreemap.org/styles/positron';
const MY_CENTER = [101.9, 4.2];
const PIN_SVG = '<svg viewBox="0 0 40 52" aria-hidden="true"><path d="M20 51C20 51 3 32.6 3 19.5a17 17 0 0 1 34 0C37 32.6 20 51 20 51z"/><circle cx="20" cy="19.5" r="6.5"/></svg>';

let loading = null;
function loadMapLibre() {
  if (window.maplibregl) return Promise.resolve(window.maplibregl);
  loading ||= new Promise((ok, bad) => {
    const css = document.createElement('link'); css.rel = 'stylesheet'; css.href = `${GL}.css`; document.head.append(css);
    const s = document.createElement('script'); s.src = `${GL}.js`;
    s.onload = () => ok(window.maplibregl); s.onerror = () => { loading = null; bad(new Error('map')); };
    document.head.append(s);
  });
  return loading;
}

export const hasPin = o => o && o.latitude != null && o.longitude != null;
export const mapsLink = query => `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}`;

const attr = '<span class="pm-attr">© OpenStreetMap · OpenFreeMap</span>';

// Read-only map with the pin at the centre.
export async function mountViewMap(box, lat, lng) {
  box.classList.add('pm', 'pm-view');
  box.innerHTML = `<div class="pm-canvas"></div><div class="pm-pin has">${PIN_SVG}<i></i></div>${attr}`;
  try {
    const gl = await loadMapLibre();
    if (!box.isConnected) return null;
    const map = new gl.Map({ container: box.querySelector('.pm-canvas'), style: STYLE, center: [lng, lat], zoom: 16.5,
      attributionControl: false, dragRotate: false, pitchWithRotate: false, touchPitch: false, scrollZoom: false });
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
  return { get: () => pin, changed: () => changed, destroy: () => { map?.remove(); map = null; } };
}
