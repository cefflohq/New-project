// FOUNDR password recovery contract (node:test, no dependencies).
// Same contract as Vendor Web: the recovery link returns to the CURRENT
// deployed FOUNDR folder (never a hard-coded host), the recovery session is
// recognised and cleared from the address bar, and the new password goes to
// GoTrue with that session. The admin gate still runs after the reset.
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInThisContext } from 'node:vm';

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
globalThis.fetch = async (url, init = {}) => {
  calls.push({ url, method: init.method || 'GET', headers: init.headers, body: init.body ? JSON.parse(init.body) : undefined });
  const path = new URL(url).pathname;
  let data = {};
  if (path === '/auth/v1/token') data = { access_token: 'signed-in-token', refresh_token: 'r', expires_at: Math.floor(Date.now() / 1000) + 3600 };
  if (path === '/auth/v1/user') data = { id: 'u1', email: 'admin@example.test' };
  return { ok: true, status: 200, text: async () => JSON.stringify(data) };
};

setLocation('https://any-preview.example.app/foundr/');
const BACKEND = new URL('../foundr/backend.js', import.meta.url);
runInThisContext(readFileSync(BACKEND, 'utf8'), { filename: BACKEND.pathname });
const F = globalThis.CEFFLO_FOUNDR;

beforeEach(() => { calls.length = 0; session = null; });

const recoverRedirect = () => new URL(calls.find(c => new URL(c.url).pathname === '/auth/v1/recover').url).searchParams.get('redirect_to');

test('Forgot Password sends redirect_to = current FOUNDR folder (preview)', async () => {
  setLocation('https://new-branch-preview.vercel.app/foundr/?_vercel_share=abc');
  await F.recover(' admin@example.test ');
  assert.equal(recoverRedirect(), 'https://new-branch-preview.vercel.app/foundr/');
  assert.equal(calls[0].method, 'POST');
  assert.deepEqual(calls[0].body, { email: 'admin@example.test' });
});

test('redirect_to follows local, staging and production hosts', async () => {
  for (const [href, want] of [
    ['http://127.0.0.1:4173/foundr/index.html', 'http://127.0.0.1:4173/foundr/'],
    ['https://staging.cefflo.com/foundr/', 'https://staging.cefflo.com/foundr/'],
    ['https://foundr.cefflo.com/', 'https://foundr.cefflo.com/'],
  ]) {
    calls.length = 0;
    setLocation(href);
    await F.recover('admin@example.test');
    assert.equal(recoverRedirect(), want);
  }
});

test('a deployed host never asks for localhost', async () => {
  setLocation('https://foundr.cefflo.com/');
  await F.recover('admin@example.test');
  assert.doesNotMatch(recoverRedirect(), /localhost|127\.0\.0\.1/);
});

test('recovery callback stores the session, clears tokens, returns "recovery"', () => {
  setLocation('https://foundr.cefflo.com/?x=1#access_token=rec-token&refresh_token=rec-refresh&expires_at=2000000000&type=recovery');
  assert.equal(F.consumeAuthFragment(), 'recovery');
  assert.equal(session.access_token, 'rec-token');
  assert.equal(session.refresh_token, 'rec-refresh');
  assert.equal(location.hash, '');
  assert.equal(location.search, '?x=1');
});

test('a normal visit is not a recovery', () => {
  setLocation('https://foundr.cefflo.com/');
  assert.equal(F.consumeAuthFragment(), null);
  assert.equal(session, null);
});

test('expired link error is reported once and cleared', () => {
  setLocation('https://foundr.cefflo.com/#error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid');
  assert.equal(F.consumeAuthError().code, 'otp_expired');
  assert.equal(location.hash, '');
  assert.equal(F.consumeAuthError(), null);
});

test('new password is sent to GoTrue with the recovery session', async () => {
  setLocation('https://foundr.cefflo.com/#access_token=rec-token&refresh_token=r&expires_at=2000000000&type=recovery');
  F.consumeAuthFragment();
  await F.updatePassword('new-secret-1');
  const put = calls.find(c => c.method === 'PUT');
  assert.equal(new URL(put.url).pathname, '/auth/v1/user');
  assert.equal(put.headers.Authorization, 'Bearer rec-token');
  assert.deepEqual(put.body, { password: 'new-secret-1' });
});

test('normal sign-in is unchanged', async () => {
  await F.signIn(' admin@example.test ', 'pw');
  assert.equal(new URL(calls[0].url).search, '?grant_type=password');
  assert.deepEqual(calls[0].body, { email: 'admin@example.test', password: 'pw' });
  assert.equal(session.access_token, 'signed-in-token');
});

test('FOUNDR hard-codes no host or localhost for auth links', () => {
  const src = readFileSync(BACKEND, 'utf8') + readFileSync(new URL('../foundr/app.js', import.meta.url), 'utf8');
  assert.doesNotMatch(src, /redirect_to=https?:|localhost:3000|vercel\.app/);
});

test('app opens Set New Password for a recovery link before the admin gate', () => {
  const app = readFileSync(new URL('../foundr/app.js', import.meta.url), 'utf8');
  assert.match(app, /consumeAuthFragment\(\) === 'recovery'\) return renderSetPassword\(\)/);
  assert.match(app, /await F\.updatePassword\(p1\); await boot\(\)/);
});
