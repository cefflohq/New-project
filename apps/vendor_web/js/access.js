// Which Sign-In variant the Vendor Web App shows (D-74), matching Vendor
// Mobile's `?access=operator`. Presentation only: it never grants a role.
// After sign-in the role always comes from the server
// (claim_my_team_invitations, then get_my_businesses).
//
// The variant survives an emailed auth link (verification, recovery),
// which returns to the app without the query string, by remembering the
// last explicit choice. Opening the app normally (no ?access, no auth
// link) resets it to the standard Vendor Sign-In.
const KEY = 'cefflo.vendorweb.access';

function resolve() {
  const q = new URLSearchParams(location.search).get('access');
  const fromAuthLink = /(^|[#&])(access_token|error)=/.test(location.hash)
    || new URLSearchParams(location.search).has('error');
  const explicit = q === 'operator' ? 'operator' : q ? 'vendor' : null;
  try {
    if (explicit) { localStorage.setItem(KEY, explicit); return explicit; }
    if (fromAuthLink) return localStorage.getItem(KEY) === 'operator' ? 'operator' : 'vendor';
    localStorage.removeItem(KEY);
  } catch { /* storage unavailable: fall back to the query string */ }
  return explicit || 'vendor';
}

const access = resolve();

/** True when the Operator Sign-In presentation was requested. */
export const operatorEntry = () => access === 'operator';
