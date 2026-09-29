// Data access for the Vendor Web App. Everything goes through the canonical
// Supabase REST/RPC contracts with the signed-in user's JWT; RLS and RPC
// authorisation remain the security boundary. No mock data, no fallbacks.
import { isDemo, exitDemo, demoGet, demoRpc, demoUser, readOnly, DEMO_SESSION } from './demo.js';

const base = window.CEFFLO;
const cfg = window.CEFFLO_CONFIG;

async function authFetch(path, { method = 'POST', body, token } = {}) {
  const res = await fetch(`${cfg.supabaseUrl}${path}`, {
    method,
    headers: {
      apikey: cfg.supabaseAnonKey,
      Authorization: `Bearer ${token || cfg.supabaseAnonKey}`,
      'Content-Type': 'application/json',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) {
    const err = new Error(data?.msg || data?.message || data?.error_description || `Request failed (${res.status})`);
    err.status = res.status;
    throw err;
  }
  return data;
}

let refreshing = null;
async function refreshSession() {
  const s = base.session();
  if (!s?.refresh_token) throw Object.assign(new Error('Session expired'), { status: 401 });
  refreshing ??= authFetch('/auth/v1/token?grant_type=refresh_token', { body: { refresh_token: s.refresh_token } })
    .then(next => base.setSession(next))
    .finally(() => { refreshing = null; });
  return refreshing;
}

function expiresSoon() {
  const s = base.session();
  return s?.expires_at && s.expires_at * 1000 - Date.now() < 60_000;
}

async function call(fn) {
  if (expiresSoon()) await refreshSession().catch(() => {});
  try {
    return await fn();
  } catch (e) {
    if (/JWT expired|invalid JWT|401/.test(String(e.message))) {
      await refreshSession();
      return fn();
    }
    throw e;
  }
}

export const api = {
  session: () => (isDemo() ? DEMO_SESSION : base.session()),
  get: path => (isDemo() ? demoGet(path) : call(() => base.request(path))),
  write: (path, method, body) => (isDemo() ? Promise.reject(readOnly()) : call(() => base.request(path, { method, body }))),
  rpc: (name, body = {}) => (isDemo() ? demoRpc(name, body) : call(() => base.rpc(name, body))),
  async signIn(email, password) {
    return base.login(email.trim(), password);
  },
  async signOut() {
    if (isDemo()) { exitDemo(); return; }
    await base.logout();
  },
  async recover(email) {
    const redirect = new URL('./', location.href).href;
    return authFetch(`/auth/v1/recover?redirect_to=${encodeURIComponent(redirect)}`, { body: { email: email.trim() } });
  },
  async user() {
    if (isDemo()) return demoUser();
    return call(() => authFetch('/auth/v1/user', { method: 'GET', token: base.session()?.access_token }));
  },
  async updateUser(attrs) {
    if (isDemo()) throw readOnly();
    return call(() => authFetch('/auth/v1/user', { method: 'PUT', body: attrs, token: base.session()?.access_token }));
  },
  refreshSession,
};

// Recovery / magic links land with #access_token=... in the URL.
export function consumeAuthFragment() {
  const h = new URLSearchParams(location.hash.replace(/^#/, ''));
  if (!h.get('access_token')) return null;
  const s = {
    access_token: h.get('access_token'),
    refresh_token: h.get('refresh_token'),
    expires_at: Number(h.get('expires_at')) || undefined,
    token_type: 'bearer',
  };
  base.setSession(s);
  history.replaceState(null, '', location.pathname + location.search);
  return h.get('type');
}
