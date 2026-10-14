// View live map (Founder 2026-10-04): Mapbox, loaded only when the customer
// taps "View live map", never on page load. The map lives in its own overlay
// (outside the re-rendered sheet), shows only the latest authorised rider
// point from public_tracking, and is fully removed on close so nothing keeps
// rendering in the background. Google Maps when the build carries
// CEFFLO_CONFIG.googleMapsBrowserKey (referrer-restricted; Auto Zone + Google
// Maps guideline Phase 5), else Mapbox with a public pk.* token; with
// neither the action is not offered.

const GL_VERSION = '3.7.0';
const GL_JS = `https://api.mapbox.com/mapbox-gl-js/v${GL_VERSION}/mapbox-gl.js`;
const GL_CSS = `https://api.mapbox.com/mapbox-gl-js/v${GL_VERSION}/mapbox-gl.css`;

let root = null, map = null, marker = null, glReady = null;

const GOOGLE_KEY = window.CEFFLO_CONFIG?.googleMapsBrowserKey || '';
export const liveMapAvailable = () => Boolean(GOOGLE_KEY) || /^pk\./.test(window.CEFFLO_CONFIG?.mapboxPublicToken || '');

let googleReady = null;
function loadGoogle() {
  if (window.google?.maps?.Map) return Promise.resolve(window.google.maps);
  googleReady ||= new Promise((resolve, reject) => {
    const cb = `__cfTrackMaps${Date.now()}`;
    window[cb] = () => { delete window[cb]; resolve(window.google.maps); };
    // Key refused by Google (e.g. referrer): say so instead of a broken map.
    window.gm_authFailure = () => {
      const box = root?.querySelector('[data-live-map-loading]') || root?.querySelector('[data-live-map]');
      if (box) box.innerHTML = '<span>Map unavailable right now</span>';
    };
    const js = document.createElement('script');
    js.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(GOOGLE_KEY)}&v=weekly&callback=${cb}`;
    js.async = true;
    js.onerror = () => { googleReady = null; reject(new Error('Map unavailable')); };
    document.head.append(js);
  });
  return googleReady;
}

// The rider pin as an HTML overlay on a Google map; move(latlng) re-places it.
function googleRiderPin(g, gmap, location) {
  const el = document.createElement('div');
  el.className = 'cf-rider-pin';
  el.innerHTML = RIDER_SVG;
  el.style.position = 'absolute';
  let pos = new g.LatLng(location.lat, location.lng);
  const o = new g.OverlayView();
  o.onAdd = () => o.getPanes().overlayMouseTarget.append(el);
  o.draw = () => {
    const p = o.getProjection()?.fromLatLngToDivPixel(pos);
    if (p) { el.style.left = `${p.x}px`; el.style.top = `${p.y}px`; el.style.transform = 'translate(-50%,-50%)'; }
  };
  o.onRemove = () => el.remove();
  o.setMap(gmap);
  return { setLngLat: ([lng, lat]) => { pos = new g.LatLng(lat, lng); o.draw(); gmap.panTo(pos); }, remove: () => o.setMap(null) };
}
export const isLiveMapOpen = () => Boolean(root);

function loadGl() {
  if (window.mapboxgl) return Promise.resolve(window.mapboxgl);
  if (glReady) return glReady;
  glReady = new Promise((resolve, reject) => {
    const css = document.createElement('link');
    css.rel = 'stylesheet'; css.href = GL_CSS;
    document.head.append(css);
    const js = document.createElement('script');
    js.src = GL_JS; js.async = true;
    js.onload = () => resolve(window.mapboxgl);
    js.onerror = () => { glReady = null; reject(new Error('Map unavailable')); };
    document.head.append(js);
  });
  return glReady;
}

/** Centred pop-up (Founder 2026-10-12): large rounded card, round X below it. */
function openDialog(title, closeLabel) {
  root = document.createElement('div');
  root.className = 'live-map';
  root.setAttribute('role', 'dialog');
  root.setAttribute('aria-label', title);
  root.innerHTML = `<div class="live-map__card"><div class="live-map__canvas" data-live-map></div>
    <div class="live-map__loading" data-live-map-loading>${window.cfLoader?.markup('Loading map') || '<span class="live-map__spinner"></span><span>Loading map…</span>'}</div></div>
    <button class="live-map__close" type="button" data-live-map-close aria-label="${closeLabel}">✕</button>`;
  root.style.cssText = 'position:fixed;inset:0;z-index:50;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;padding:16px;background:rgba(11,21,48,.55);-webkit-backdrop-filter:blur(4px);backdrop-filter:blur(4px)';
  root.querySelector('.live-map__card').style.cssText = 'position:relative;width:100%;max-width:520px;height:min(72vh,640px);border-radius:20px;overflow:hidden;background:#e9edf2;box-shadow:0 24px 60px rgba(0,0,0,.35)';
  root.querySelector('[data-live-map]').style.cssText = 'position:absolute;inset:0';
  root.querySelector('[data-live-map-close]').style.cssText = 'flex:0 0 auto;width:56px;height:56px;border-radius:50%;border:0;background:#fff;color:#1F2937;box-shadow:0 8px 20px rgba(0,0,0,.25);font-size:22px;line-height:1';
  root.querySelector('[data-live-map-close]').addEventListener('click', closeLiveMap);
  root.addEventListener('click', (e) => { if (e.target === root) closeLiveMap(); });
  document.body.append(root);
  return root.querySelector('[data-live-map]');
}

function hideLoading() {
  root?.querySelector('[data-live-map-loading]')?.remove();
}

const RIDER_SVG = '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="5.5" cy="17" r="3.5"/><circle cx="18.5" cy="17" r="3.5"/><path d="M5.5 17L9 9h4l2 4H9M15 6h3l2.5 11"/></svg>';

/** Demo only: the same pop-up around static (illustrative) map markup. */
export function openStaticMap(html, { title = 'Map', closeLabel = 'Close map' } = {}) {
  if (root) return;
  openDialog(title, closeLabel).innerHTML = html;
  hideLoading();
}

export async function openLiveMap(location, { title = 'Live map', closeLabel = 'Close map' } = {}) {
  if (root || !location || !liveMapAvailable()) return;
  openDialog(title, closeLabel);
  if (GOOGLE_KEY) {
    try {
      const g = await loadGoogle();
      if (!root) return; // closed while loading
      const gmap = new g.Map(root.querySelector('[data-live-map]'), {
        center: { lat: location.lat, lng: location.lng }, zoom: 15,
        disableDefaultUI: true, zoomControl: true, clickableIcons: false, gestureHandling: 'greedy',
        styles: [{ featureType: 'poi', stylers: [{ visibility: 'off' }] }, { featureType: 'transit', stylers: [{ visibility: 'off' }] }],
      });
      marker = googleRiderPin(g, gmap, location);
      map = { remove: () => marker?.remove() };
      g.event.addListenerOnce(gmap, 'tilesloaded', hideLoading);
    } catch {
      closeLiveMap();
    }
    return;
  }
  try {
    const gl = await loadGl();
    if (!root) return; // closed while loading
    gl.accessToken = window.CEFFLO_CONFIG.mapboxPublicToken;
    map = new gl.Map({
      container: root.querySelector('[data-live-map]'),
      style: 'mapbox://styles/mapbox/streets-v12',
      center: [location.lng, location.lat],
      zoom: 14,
      attributionControl: false,
    });
    // Map credit behind a small (i), as on every Cefflo map.
    map.addControl(new gl.AttributionControl({ compact: true }), 'bottom-left');
    map.once('load', () => root?.querySelectorAll('.mapboxgl-compact-show')
      .forEach((el) => el.classList.remove('mapboxgl-compact-show')));
    map.addControl(new gl.NavigationControl({ showCompass: false }), 'bottom-right');
    // The driver: the same yellow motorbike pin as the Vendor live map.
    const pin = document.createElement('div');
    pin.className = 'cf-rider-pin';
    pin.innerHTML = RIDER_SVG;
    marker = new gl.Marker({ element: pin }).setLngLat([location.lng, location.lat]).addTo(map);
    map.once('load', hideLoading);
    // Style/token failure before the first load: say so instead of spinning forever.
    map.once('error', () => {
      const box = root?.querySelector('[data-live-map-loading]');
      if (box && !map?.loaded()) box.innerHTML = '<span>Map unavailable right now</span>';
    });
  } catch {
    closeLiveMap();
  }
}

/** Moves the rider marker to the latest authorised point (no history). */
export function updateLiveMap(location) {
  if (!marker || !location) return;
  marker.setLngLat([location.lng, location.lat]);
}

export function closeLiveMap() {
  if (map) map.remove();
  map = null; marker = null;
  if (root) root.remove();
  root = null;
}
