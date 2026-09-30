// FOUNDR MFA contract (security batch 2A; node:test, no dependencies).
// The client only relays: GoTrue owns enrollment/challenge/verify and the
// AAL of the session; platform_admin_status() is the caller's own state.
// A 403 is a permission answer and must never sign the admin out.
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInThisContext } from 'node:vm';

const SUPABASE = 'https://example-ref.supabase.co';
const calls = [];
const rpcCalls = [];
let session = null;
let next = {};

const jwt = claims => `h.${Buffer.from(JSON.stringify(claims)).toString('base64url')}.s`;

globalThis.window = globalThis;
globalThis.location = { href: 'https://foundr.example/', pathname: '/', search: '', hash: '' };
globalThis.history = { replaceState: () => {} };
globalThis.atob = s => Buffer.from(s, 'base64').toString('binary');
globalThis.CEFFLO_CONFIG = { environment: 'staging', supabaseUrl: SUPABASE, supabaseAnonKey: 'anon-key', schema: 'public' };
globalThis.CEFFLO = {
  session: () => session,
  setSession: s => { session = s; return s; },
  request: async () => [],
  rpc: async (name, body) => { rpcCalls.push({ name, body }); return next.rpc?.[name] ?? null; },
  logout: async () => { session = null; },
};
globalThis.fetch = async (url, init = {}) => {
  const path = new URL(url).pathname;
  calls.push({ path, method: init.method || 'GET', headers: init.headers, body: init.body ? JSON.parse(init.body) : undefined });
  const hit = next.fetch?.[`${init.method || 'GET'} ${path}`];
  const [status, data] = hit || [200, {}];
  return { ok: status < 400, status, text: async () => JSON.stringify(data), json: async () => data };
};

const BACKEND = new URL('../foundr/backend.js', import.meta.url);
runInThisContext(readFileSync(BACKEND, 'utf8'), { filename: BACKEND.pathname });
const F = globalThis.CEFFLO_FOUNDR;
const APP = readFileSync(new URL('../foundr/app.js', import.meta.url), 'utf8');

beforeEach(() => {
  calls.length = 0; rpcCalls.length = 0; next = {};
  session = { access_token: jwt({ sub: 'u1', aal: 'aal1' }), refresh_token: 'r', expires_at: Math.floor(Date.now() / 1000) + 3600 };
});

test('platform_admin_status is read through the authenticated RPC', async () => {
  next.rpc = { platform_admin_status: { admin: true, aal: 'aal1', verified_factors: 1 } };
  assert.deepEqual(await F.platformAdminStatus(), { admin: true, aal: 'aal1', verified_factors: 1 });
  assert.deepEqual(rpcCalls, [{ name: 'platform_admin_status', body: {} }]);
});

test('sessionAal reads the stored token claim (aal1 / aal2)', () => {
  assert.equal(F.sessionAal(), 'aal1');
  session = { access_token: jwt({ sub: 'u1', aal: 'aal2' }) };
  assert.equal(F.sessionAal(), 'aal2');
  session = null;
  assert.equal(F.sessionAal(), null);
});

test('enroll posts a TOTP factor with the user token', async () => {
  next.fetch = { 'POST /auth/v1/factors': [200, { id: 'f1', type: 'totp', totp: { qr_code: 'data:image/svg+xml;utf-8,<svg/>', secret: 'ABC' } }] };
  const f = await F.enrollTotp('FOUNDR test');
  assert.equal(f.id, 'f1');
  const c = calls.find(x => x.path === '/auth/v1/factors');
  assert.equal(c.method, 'POST');
  assert.equal(c.body.factor_type, 'totp');
  assert.match(c.headers.Authorization, /^Bearer h\./);
});

test('challenge + verify replaces the session with the aal2 one GoTrue returns', async () => {
  const aal2 = jwt({ sub: 'u1', aal: 'aal2' });
  next.fetch = {
    'POST /auth/v1/factors/f1/challenge': [200, { id: 'ch1' }],
    'POST /auth/v1/factors/f1/verify': [200, { access_token: aal2, refresh_token: 'r2', expires_in: 3600 }],
  };
  const ch = await F.challengeFactor('f1');
  await F.verifyFactor('f1', ch.id, ' 123456 ');
  const v = calls.find(x => x.path === '/auth/v1/factors/f1/verify');
  assert.deepEqual(v.body, { challenge_id: 'ch1', code: '123456' });
  assert.equal(session.access_token, aal2);
  assert.equal(session.refresh_token, 'r2');
  assert.ok(session.expires_at > Date.now() / 1000);
  assert.equal(F.sessionAal(), 'aal2');
});

test('a wrong code keeps the aal1 session and surfaces the error', async () => {
  const before = session;
  next.fetch = { 'POST /auth/v1/factors/f1/verify': [422, { error_code: 'mfa_verification_failed', msg: 'Invalid TOTP code entered' }] };
  await assert.rejects(F.verifyFactor('f1', 'ch1', '000000'), e => e.code === 'mfa_verification_failed' && e.status === 422);
  assert.equal(session, before);
});

test('unenroll uses DELETE on the factor', async () => {
  await F.unenrollFactor('f1');
  assert.deepEqual(calls.map(c => `${c.method} ${c.path}`), ['DELETE /auth/v1/factors/f1']);
});

test('listFactors returns only TOTP factors from the user', async () => {
  next.fetch = { 'GET /auth/v1/user': [200, { id: 'u1', factors: [{ id: 'a', factor_type: 'totp', status: 'verified' }, { id: 'b', factor_type: 'phone', status: 'verified' }] }] };
  assert.deepEqual((await F.listFactors()).map(f => f.id), ['a']);
});

test('403 is never a sign-out: the in-app handler re-checks access', () => {
  const handler = APP.slice(APP.indexOf('function handleAuthError'), APP.indexOf('function reset()'));
  assert.match(handler, /e\?\.status === 403 \|\| \/forbidden\/i\.test\(msg\)\) \{[\s\S]*recheckAccess\(\);/);
  assert.doesNotMatch(handler.slice(handler.indexOf('status === 403')), /signOut/);
  // Only a dead session (401 / invalid JWT codes) ends it.
  assert.match(APP, /const deadSession = e => e\?\.status === 401 \|\| \/\^\(bad_jwt\|session_not_found\|session_expired\|refresh_token_not_found\)\$\//);
  assert.doesNotMatch(APP, /e\?\.status === 401 \|\| e\?\.status === 403\) \{ await F\.signOut/);
});

test('routing: not admin → denied; no factor → set up; aal1 with factor → verify', () => {
  const route = APP.slice(APP.indexOf('async function routeAccess'), APP.indexOf('let rechecking'));
  assert.match(route, /if \(!st\?\.admin\) return renderDenied/);
  assert.match(route, /st\.verified_factors > 0 && st\.aal !== 'aal2'\) return renderMfaVerify\(next\)/);
  assert.match(route, /st\.verified_factors === 0\) return renderMfaSetup\(next, \{ optional: true \}\)/);
});

test('entering FOUNDR still requires the canonical allowlist check', () => {
  assert.match(APP, /async function enterApp\(\) \{\n[^\n]*\n  if \(await F\.isPlatformAdmin\(\) !== true\) return renderDenied/);
});

test('removing an authenticator requires typed CONFIRM', () => {
  const rm = APP.slice(APP.indexOf('function renderRemoveFactor'), APP.indexOf('function toastSoon'));
  assert.match(rm, /btn\.disabled = e\.target\.value !== 'CONFIRM'/);
  assert.match(rm, /if \(form\.querySelector\('#confirm'\)\.value !== 'CONFIRM'\) return;/);
});
