// View live map (Founder 2026-10-04): Mapbox, loaded only when the customer
// taps "View live map", never on page load. The map lives in its own overlay
// (outside the re-rendered sheet), shows only the latest authorised rider
// point from public_tracking, and is fully removed on close so nothing keeps
// rendering in the background. Needs CEFFLO_CONFIG.mapboxPublicToken (a
// public, URL-restricted pk.* token); without it the action is not offered.

const GL_VERSION = '3.7.0';
const GL_JS = `https://api.mapbox.com/mapbox-gl-js/v${GL_VERSION}/mapbox-gl.js`;
const GL_CSS = `https://api.mapbox.com/mapbox-gl-js/v${GL_VERSION}/mapbox-gl.css`;

let root = null, map = null, marker = null, glReady = null;

export const liveMapAvailable = () => /^pk\./.test(window.CEFFLO_CONFIG?.mapboxPublicToken || '');
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

export async function openLiveMap(location, { title = 'Live map', closeLabel = 'Close map' } = {}) {
  if (root || !location || !liveMapAvailable()) return;
  root = document.createElement('div');
  root.className = 'live-map';
  root.setAttribute('role', 'dialog');
  root.setAttribute('aria-label', title);
  root.innerHTML = `<div class="live-map__canvas" data-live-map></div>
    <button class="live-map__close" type="button" data-live-map-close aria-label="${closeLabel}">✕</button>`;
  root.style.cssText = 'position:fixed;inset:0;z-index:50;background:#e9edf2';
  root.querySelector('[data-live-map]').style.cssText = 'position:absolute;inset:0';
  root.querySelector('[data-live-map-close]').style.cssText = 'position:absolute;top:calc(12px + env(safe-area-inset-top));right:12px;width:44px;height:44px;border-radius:22px;border:0;background:#fff;box-shadow:0 2px 10px #0003;font-size:18px';
  root.querySelector('[data-live-map-close]').addEventListener('click', closeLiveMap);
  document.body.append(root);
  try {
    const gl = await loadGl();
    if (!root) return; // closed while loading
    gl.accessToken = window.CEFFLO_CONFIG.mapboxPublicToken;
    map = new gl.Map({
      container: root.querySelector('[data-live-map]'),
      style: 'mapbox://styles/mapbox/streets-v12',
      center: [location.lng, location.lat],
      zoom: 14,
    });
    map.addControl(new gl.NavigationControl({ showCompass: false }), 'bottom-right');
    marker = new gl.Marker().setLngLat([location.lng, location.lat]).addTo(map);
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
