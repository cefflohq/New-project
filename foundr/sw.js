const CACHE_NAME = 'cefflo-foundr-prototype-v11';
const ROOT = new URL('./', self.registration.scope).pathname;
const SHELL = [ROOT, `${ROOT}app.css`, `${ROOT}mock-data.js`, `${ROOT}app.js`, `${ROOT}icons/icon-192.png`, `${ROOT}icons/icon-512.png`, `${ROOT}assets/product/vendor-web.jpg`, `${ROOT}assets/product/vendor-mobile.jpg`, `${ROOT}assets/product/driver-app.jpg`, `${ROOT}assets/product/customer-tracking.jpg`, `${ROOT}assets/product/website.jpg`];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(SHELL)));
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key)))).then(() => self.clients.claim()));
});

self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;
  if (request.mode === 'navigate') {
    event.respondWith(fetch(request).catch(() => caches.match(ROOT)));
    return;
  }
  if (!SHELL.includes(url.pathname)) return;
  event.respondWith(fetch(request).then(response => {
    if (response.ok) caches.open(CACHE_NAME).then(cache => cache.put(request, response.clone()));
    return response;
  }).catch(() => caches.match(request)));
});
