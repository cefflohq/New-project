// Team Invite routing (production domain map, Founder 2026-10-05). Pure and
// side-effect free so it can be unit-tested. It only decides WHERE to send a
// link holder; the server-resolved token alone decides business and role.
(function (root) {
  const TOKEN = /^[0-9a-f]{48}$/;

  // invite.cefflo.com/<token> (canonical) or ?link=<token> (existing links).
  function inviteTokenFrom(loc) {
    const fromQuery = new URLSearchParams(loc.search || '').get('link');
    if (fromQuery !== null) return fromQuery;
    const segment = String(loc.pathname || '').split('/').filter(Boolean).pop() || '';
    return TOKEN.test(segment) ? segment : null;
  }

  // kind comes from resolve_invite_link (server). Driver -> Driver app;
  // Operator / Helper -> their dedicated host, else the shared Vendor App
  // build with ?access=<kind> (staging). Null = no web destination
  // configured (the page then shows its store-badge screen).
  function inviteDestination(kind, apps, token) {
    apps = apps || {};
    let base;
    if (kind === 'rider') base = apps.driver;
    else if (kind === 'operator' || kind === 'helper') base = apps[kind] || apps.vendor;
    if (!base || !TOKEN.test(token || '')) return null;
    const url = new URL(base);
    if (kind !== 'rider') url.searchParams.set('access', kind);
    url.searchParams.set('join', token);
    return url.href;
  }

  const api = { inviteTokenFrom, inviteDestination };
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.CEFFLOInvite = api;
})(typeof window !== 'undefined' ? window : globalThis);
