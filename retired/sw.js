// Retirement worker for CEFFLO web surfaces that are no longer products
// : the legacy purple Vendor, Rider and Customer PWAs. A browser that still has
// the old worker installed fetches this file on its next update check; it
// takes control, deletes every cache the old app left behind, unregisters
// itself and reloads open tabs so no cached obsolete UI can be served again.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map(key => caches.delete(key)));
    await self.registration.unregister();
    const windows = await self.clients.matchAll({ type: 'window' });
    windows.forEach(client => client.navigate(client.url));
  })());
});
