/* CEFFLO push service worker — closed-app alerts (Web Push).
   Its own scope (this folder), so it never touches an app's own worker.
   docs/cefflo/security/PUSH_NOTIFICATIONS.md */
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));

self.addEventListener('push', e => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch (_) { d = { title: 'Cefflo', body: e.data ? e.data.text() : '' }; }
  const base = self.registration.scope;
  e.waitUntil(self.registration.showNotification(d.title || 'Cefflo', {
    body: d.body || '',
    badge: base + 'badge-96.png',
    tag: d.tag || undefined,
    renotify: !!d.tag,
    requireInteraction: !!d.urgent,
    data: { url: d.url || '/' },
  }));
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  const url = new URL(e.notification.data && e.notification.data.url || '/', self.location.origin).href;
  e.waitUntil((async () => {
    const wins = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    const target = new URL(url);
    for (const w of wins) {
      const u = new URL(w.url);
      if (u.origin === target.origin && u.pathname === target.pathname && 'focus' in w) {
        if (u.href !== target.href && 'navigate' in w) { try { await w.navigate(url); } catch (_) { /* cross-scope */ } }
        return w.focus();
      }
    }
    return self.clients.openWindow(url);
  })());
});
