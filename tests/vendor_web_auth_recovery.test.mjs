// Vendor Web password recovery contract (node:test, no dependencies).
// The recovery link must return to the CURRENT deployed Vendor Web (derived
// from location, never a hard-coded host), the recovery session must be
// recognised, and the new password must go to GoTrue with that session.
// GoTrue itself only honours redirect_to values on the project's Auth
// Redirect URL allowlist; otherwise it falls back to the Site URL.
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SUPABASE = 'https://example-ref.supabase.co';
const calls = [];
let session = null;
let loc;

function setLocation(href) {
  loc = new URL(href);
  globalThis.location = {
    get href() { return loc.href; }, get pathname() { return loc.pathname; },
    get search() { return loc.search; }, get hash() { return loc.hash; },
  };
}

globalThis.window = globalThis;
globalThis.CEFFLO_CONFIG = { environment: 'staging', supabaseUrl: SUPABASE, supabaseAnonKey: 'anon-key', schema: 'public' };
globalThis.CEFFLO = {
  session: () => session,
  setSession: s => { session = s; return s; },
  request: async () => [], rpc: async () => null, logout: async () => { session = null; },
};
globalThis.history = { replaceState: (_s, _t, url) => { loc = new URL(url, loc.href); } };
globalThis.document = { documentElement: { lang: 'en' } };
globalThis.localStorage = { getItem: () => null, setItem() {}, removeItem() {} };
globalThis.sessionStorage = globalThis.localStorage;
globalThis.fetch = async (url, init = {}) => {
  calls.push({ url, method: init.method || 'GET', headers: init.headers, body: init.body ? JSON.parse(init.body) : undefined });
  const path = new URL(url).pathname;
  let data = {};
  if (path === '/auth/v1/token') data = { access_token: 'signed-in-token', refresh_token: 'r', expires_at: Math.floor(Date.now() / 1000) + 3600 };
  if (path === '/auth/v1/user') data = { id: 'u1', email: 'owner@example.test' };
  return { ok: true, status: 200, text: async () => JSON.stringify(data) };
};

setLocation('https://any-preview.example.app/web/');
const { api, consumeAuthFragment } = await import('../apps/vendor_web/js/api.js');

beforeEach(() => { calls.length = 0; session = null; });

const recoverRedirect = () => new URL(calls.find(c => new URL(c.url).pathname === '/auth/v1/recover').url).searchParams.get('redirect_to');

test('Forgot Password sends redirect_to = current Vendor Web root (preview)', async () => {
  setLocation('https://new-branch-preview.vercel.app/web/?_vercel_share=abc#/settings');
  await api.recover(' owner@example.test ');
  assert.equal(recoverRedirect(), 'https://new-branch-preview.vercel.app/web/');
  const c = calls[0];
  assert.equal(c.method, 'POST');
  assert.deepEqual(c.body, { email: 'owner@example.test' });
});

test('redirect_to follows every deployment: local, staging host, production', async () => {
  for (const [page, expected] of [
    ['http://localhost:8080/apps/vendor_web/index.html', 'http://localhost:8080/apps/vendor_web/'],
    ['https://vendor-staging.example.com/', 'https://vendor-staging.example.com/'],
    ['https://vendor.cefflo.com/#/today', 'https://vendor.cefflo.com/'],
  ]) {
    calls.length = 0;
    setLocation(page);
    await api.recover('a@b.c');
    assert.equal(recoverRedirect(), expected, page);
  }
});

test('a deployed page never falls back to localhost', async () => {
  setLocation('https://vendor.cefflo.com/web/');
  await api.recover('a@b.c');
  assert.ok(!/localhost|127\.0\.0\.1/.test(recoverRedirect()));
});

test('sign-up and resend verification use the same derived redirect', async () => {
  setLocation('https://pr-42.example.app/web/');
  await api.signUp('new@example.test', 'longpassword');
  await api.resendSignUp('new@example.test');
  for (const c of calls) assert.equal(new URL(c.url).searchParams.get('redirect_to'), 'https://pr-42.example.app/web/');
});

test('recovery callback is recognised, stored as the session and cleared from the URL', () => {
  setLocation('https://pr-42.example.app/web/#access_token=recovery-token&refresh_token=rt&expires_at=9999999999&type=recovery');
  assert.equal(consumeAuthFragment(), 'recovery');
  assert.equal(session.access_token, 'recovery-token');
  assert.equal(loc.hash, '', 'tokens must not stay in the address bar');
});

test('no fragment: nothing is consumed (normal visits unaffected)', () => {
  setLocation('https://pr-42.example.app/web/#/today');
  assert.equal(consumeAuthFragment(), null);
  assert.equal(session, null);
});

test('Set New Password updates the password with the recovery session', async () => {
  session = { access_token: 'recovery-token', refresh_token: 'rt', expires_at: Math.floor(Date.now() / 1000) + 3600 };
  await api.updateUser({ password: 'n3w-password' });
  const c = calls.find(x => new URL(x.url).pathname === '/auth/v1/user');
  assert.equal(c.method, 'PUT');
  assert.equal(c.headers.Authorization, 'Bearer recovery-token');
  assert.deepEqual(c.body, { password: 'n3w-password' });
});

test('normal password sign-in is unchanged', async () => {
  await api.signIn(' owner@example.test ', 'secret');
  const c = calls[0];
  assert.equal(new URL(c.url).pathname, '/auth/v1/token');
  assert.equal(new URL(c.url).searchParams.get('grant_type'), 'password');
  assert.deepEqual(c.body, { email: 'owner@example.test', password: 'secret' });
  assert.equal(session.access_token, 'signed-in-token');
});

test('no deployment hostname or localhost fallback is hard-coded in Vendor Web', () => {
  const dir = new URL('../apps/vendor_web/js/', import.meta.url).pathname;
  const files = [];
  const walk = d => readdirSync(d, { withFileTypes: true }).forEach(e => (e.isDirectory() ? walk(join(d, e.name)) : e.name.endsWith('.js') && files.push(join(d, e.name))));
  walk(dir);
  for (const f of files) {
    const src = readFileSync(f, 'utf8');
    assert.ok(!/vercel\.app/.test(src), `${f} hard-codes a Vercel host`);
    assert.ok(!/redirect_to=[^`'"]*localhost/.test(src) && !/https?:\/\/localhost/.test(src), `${f} hard-codes localhost`);
  }
});

test('Continue with Google goes to GoTrue authorize and returns to this Vendor Web', () => {
  setLocation('https://new-branch-preview.vercel.app/web/?access=operator#/today');
  const url = new URL(api.googleSignInUrl());
  assert.equal(url.origin + url.pathname, `${SUPABASE}/auth/v1/authorize`);
  assert.equal(url.searchParams.get('provider'), 'google');
  assert.equal(url.searchParams.get('redirect_to'), 'https://new-branch-preview.vercel.app/web/');
});
