// FOUNDR admin authorization (staging only). Every admin RPC FOUNDR uses is
// called by: anonymous, a normal signed-in user, a business Owner, a platform
// admin WITHOUT MFA (aal1) and a platform admin WITH MFA (aal2, real GoTrue
// TOTP). Only the aal2 admin may use admin RPCs and admin RLS reads
// (migration 20261007140000); every admin mutation writes admin_audit_log,
// including Marketplace verification decisions. [TEST] fixtures are removed.
import crypto from 'node:crypto';

const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_ || !URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${c ? '' : '  -> ' + String(typeof x === 'string' ? x : JSON.stringify(x)).slice(0, 180)}`); if (!c) fails++; };
const SH = { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' };
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
const sel = async (tok, path) => { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; };
const svc = async (method, path, body) => { const r = await fetch(`${URL_}/rest/v1/${path}`, { method, headers: { ...SH, prefer: 'return=representation' }, body: body ? JSON.stringify(body) : undefined }); return r.json().catch(() => null); };
const uid = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;
const aal = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).aal;
const refused = r => r.status >= 400 || r.body === null || r.body === false || (Array.isArray(r.body) && r.body.length === 0);
const auth = async (path, body, tok) => { const r = await fetch(`${URL_}/auth/v1/${path}`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json', ...(tok ? { authorization: `Bearer ${tok}` } : {}) }, body: JSON.stringify(body) }); return { status: r.status, body: await r.json().catch(() => null) }; };

// RFC 6238 TOTP (SHA-1, 30 s, 6 digits) from a base32 secret.
function totp(secret, at = Date.now()) {
  const alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'; let bits = '';
  for (const c of secret.replace(/=+$/, '').toUpperCase()) bits += alpha.indexOf(c).toString(2).padStart(5, '0');
  const key = Buffer.from(bits.match(/.{8}/g).map(b => parseInt(b, 2)));
  const msg = Buffer.alloc(8); msg.writeBigUInt64BE(BigInt(Math.floor(at / 30000)));
  const h = crypto.createHmac('sha1', key).update(msg).digest(); const o = h[h.length - 1] & 15;
  return String(((h.readUInt32BE(o) & 0x7fffffff) % 1e6)).padStart(6, '0');
}

const stamp = String(Date.now()).slice(-6), created = [], businesses = [];
async function fresh(tag, meta = {}) {
  const email = `zelix.co00+fdadm${tag}${stamp}@gmail.com`, password = 'Cf-fdadm-Test!7';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: SH, body: JSON.stringify({ email, password, email_confirm: true, user_metadata: meta }) });
  const u = await r.json(); if (!r.ok) throw new Error('create ' + JSON.stringify(u)); created.push(u.id);
  const s = await auth('token?grant_type=password', { email, password }); return s.body.access_token;
}

try {
  // ---------- fixtures
  const user = await fresh('user');
  const owner = await fresh('owner');
  const B = (await rpc(owner, 'bootstrap_business', { p_name: `[TEST] FOUNDR admin ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(B);
  const admin1 = await fresh('adminaal1');            // platform admin, password only
  const adminT = await fresh('adminmfa');             // platform admin with TOTP
  for (const t of [admin1, adminT]) await svc('POST', 'platform_admins', { user_id: uid(t), role: 'ops' });
  const enroll = await auth('factors', { factor_type: 'totp', friendly_name: `[TEST] ${stamp}` }, adminT);
  const ch = await auth(`factors/${enroll.body.id}/challenge`, {}, adminT);
  const ver = await auth(`factors/${enroll.body.id}/verify`, { challenge_id: ch.body.id, code: totp(enroll.body.totp.secret) }, adminT);
  const admin2 = ver.body?.access_token;
  ok('fixture: MFA admin reaches aal2 through real GoTrue TOTP', aal(admin2) === 'aal2', ver.body);
  ok('fixture: password-only admin stays aal1', aal(admin1) === 'aal1');
  // a [TEST] driver verification awaiting review
  const drv = await fresh('driver', { driver_registration: { full_name: '[TEST] FD Driver', phone: `+60 13-9${stamp}`, vehicle_type: 'motorcycle', vehicle_plate: `FD ${stamp}` } });
  const D = uid(drv);
  await svc('POST', 'driver_marketplace_verifications', { user_id: D, status: 'needs_review', reasons: ['low_confidence'], vehicle_type: 'motorcycle', vehicle_plate: `FD ${stamp}`, licence_result: { ic: '990101015555', name: '[TEST] FD DRIVER', expiry: '2030-01-01', classes: ['B2'], confidence: 0.7, text_found: true }, submitted_at: new Date().toISOString() });
  const D2 = uid(await fresh('driver2'));
  await svc('POST', 'driver_marketplace_verifications', { user_id: D2, status: 'pending', vehicle_type: 'car', vehicle_plate: `FE ${stamp}` });

  // ---------- 1. gate functions (self-context, callable by any signed-in user)
  ok('is_platform_admin: anon false/refused', refused(await rpc(null, 'is_platform_admin')));
  ok('is_platform_admin: user false', (await rpc(user, 'is_platform_admin')).body === false);
  ok('is_platform_admin: owner false', (await rpc(owner, 'is_platform_admin')).body === false);
  ok('is_platform_admin: admin aal1 FALSE (MFA enforced server-side)', (await rpc(admin1, 'is_platform_admin')).body === false);
  ok('is_platform_admin: admin aal2 true', (await rpc(admin2, 'is_platform_admin')).body === true);
  const st1 = (await rpc(admin1, 'platform_admin_status')).body, st2 = (await rpc(admin2, 'platform_admin_status')).body, stu = (await rpc(user, 'platform_admin_status')).body;
  ok('platform_admin_status: aal1 admin sees admin=true, aal1, 0 factors (routes to MFA setup)', st1?.admin === true && st1?.aal === 'aal1' && st1?.verified_factors === 0, st1);
  ok('platform_admin_status: aal2 admin sees aal2 + 1 factor', st2?.admin === true && st2?.aal === 'aal2' && st2?.verified_factors === 1, st2);
  ok('platform_admin_status: user sees admin=false', stu?.admin === false, stu);
  ok('get_active_announcements: public read works (all surfaces)', (await rpc(user, 'get_active_announcements')).status === 200);
  ok('get_active_maintenance: public read works (all surfaces)', (await rpc(user, 'get_active_maintenance')).status === 200);

  // ---------- 2. admin read RPCs + admin RLS reads
  const READS = [
    ['admin_list_vendors', {}], ['admin_get_vendor', { p_business_id: B }], ['admin_list_riders', {}], ['admin_stuck_riders', { p_stale_minutes: 45 }],
    ['admin_delivery_operations', {}], ['admin_list_audit_log', { p_limit: 5 }], ['admin_list_subscriptions', {}], ['admin_list_app_versions', {}],
    ['admin_list_broadcasts', { p_limit: 5 }], ['admin_broadcast_audience_size', { p_audience: 'business', p_business_id: B }],
  ];
  const callers = [['anon', null], ['user', user], ['owner', owner], ['admin aal1', admin1]];
  for (const [name, body] of READS) {
    for (const [who, tok] of callers) ok(`${name}: ${who} refused`, refused(await rpc(tok, name, body)));
    const r = await rpc(admin2, name, body);
    ok(`${name}: admin aal2 allowed`, r.status === 200, r.body);
  }
  const TABLES = ['platform_admins', 'admin_audit_log', 'feature_flags', 'maintenance_windows', 'business_subscriptions', 'app_versions', 'platform_announcements', 'notification_broadcasts', 'driver_marketplace_verifications', 'driver_licences'];
  for (const t of TABLES) {
    for (const [who, tok] of [['user', user], ['owner', owner], ['admin aal1', admin1]]) {
      const r = await sel(tok, `${t}?select=*&limit=5`);
      const leaked = Array.isArray(r.body) && r.body.some(x => !(t === 'business_subscriptions' && who === 'owner' && x.business_id === B));
      ok(`${t}: ${who} reads nothing admin-only`, !leaked, r.body);
    }
  }
  ok('admin aal2 reads platform_admins', ((await sel(admin2, 'platform_admins?select=user_id')).body || []).length >= 2);
  ok('admin aal2 reads verifications', ((await sel(admin2, `driver_marketplace_verifications?select=user_id&user_id=eq.${D}`)).body || []).length === 1);
  ok('admin aal2 selected screening fields exclude the full IC', !JSON.stringify((await sel(admin2, `driver_marketplace_verifications?select=user_id,lic_name:licence_result->>name&user_id=eq.${D}`)).body).includes('990101015555'));

  // ---------- 3. admin mutations: refused for non-aal2, allowed + audited for aal2
  const flagKey = `test_fdadm_${stamp}`;
  const MUT = [
    ['admin_set_feature_flag', { p_key: flagKey, p_enabled: false, p_description: '[TEST] FOUNDR admin suite' }, 'set_feature_flag'],
    ['admin_record_app_version', { p_app: 'foundr', p_version: `0.0.0-test.${stamp}`, p_notes: '[TEST]' }, 'record_app_version'],
    ['admin_create_announcement', { p_title: `[TEST] FD ${stamp}`, p_body: '[TEST]', p_severity: 'info', p_starts_at: new Date(Date.now() + 864e5 * 365).toISOString(), p_ends_at: new Date(Date.now() + 864e5 * 366).toISOString() }, 'create_announcement'],
    ['admin_set_subscription', { p_business_id: B, p_plan_key: 'grow', p_status: 'active', p_mrr_cents: 9900, p_trial_ends_at: null }, 'set_subscription'],
    ['admin_broadcast_notification', { p_title: '[TEST] FD broadcast', p_body: '[TEST]', p_audience: 'business', p_business_id: B, p_reason: '[TEST] suite' }, 'broadcast_notification'],
  ];
  const auditCount = async action => ((await svc('GET', `admin_audit_log?select=id&admin_user_id=eq.${uid(admin2)}&action=eq.${action}`)) || []).length;
  let annId = null;
  for (const [name, body, action] of MUT) {
    for (const [who, tok] of callers) ok(`${name}: ${who} refused`, refused(await rpc(tok, name, body)));
    const before = await auditCount(action);
    const r = await rpc(admin2, name, body);
    ok(`${name}: admin aal2 allowed`, r.status === 200, r.body);
    ok(`${name}: audit row '${action}' written`, (await auditCount(action)) === before + 1);
    if (name === 'admin_create_announcement') annId = (Array.isArray(r.body) ? r.body[0] : r.body)?.id;
  }
  ok('subscription: set_subscription rejects a plan outside the price book (trial)', (await rpc(admin2, 'admin_set_subscription', { p_business_id: B, p_plan_key: 'trial', p_status: 'active', p_mrr_cents: null, p_trial_ends_at: null })).status >= 400);
  for (const p of ['free', 'grow', 'operate', 'scale', 'enterprise']) ok(`subscription: plan '${p}' accepted`, (await rpc(admin2, 'admin_set_subscription', { p_business_id: B, p_plan_key: p, p_status: 'active', p_mrr_cents: null, p_trial_ends_at: null })).status === 200);
  if (annId) {
    for (const [who, tok] of callers) ok(`admin_set_announcement_active: ${who} refused`, refused(await rpc(tok, 'admin_set_announcement_active', { p_id: annId, p_active: false })));
    const b0 = await auditCount('set_announcement_active');
    ok('admin_set_announcement_active: admin aal2 allowed', (await rpc(admin2, 'admin_set_announcement_active', { p_id: annId, p_active: false })).status === 200);
    ok("admin_set_announcement_active: audit row written", (await auditCount('set_announcement_active')) === b0 + 1);
  }
  // Maintenance: scope foundr only, ended immediately.
  for (const [who, tok] of callers) ok(`admin_start_maintenance: ${who} refused`, refused(await rpc(tok, 'admin_start_maintenance', { p_scope: 'foundr', p_reason: '[TEST]', p_rollback_condition: '[TEST]' })));
  const m0 = await auditCount('start_maintenance');
  const mw = await rpc(admin2, 'admin_start_maintenance', { p_scope: 'foundr', p_reason: '[TEST] FOUNDR admin suite', p_expected_duration_minutes: 1, p_rollback_condition: '[TEST] ends immediately' });
  const mwId = (Array.isArray(mw.body) ? mw.body[0] : mw.body)?.id;
  ok('admin_start_maintenance: admin aal2 allowed (scope foundr)', mw.status === 200 && !!mwId, mw.body);
  ok('admin_start_maintenance: audit row written', (await auditCount('start_maintenance')) === m0 + 1);
  for (const [who, tok] of callers) ok(`admin_end_maintenance: ${who} refused`, refused(await rpc(tok, 'admin_end_maintenance', { p_id: mwId })));
  const e0 = await auditCount('end_maintenance');
  ok('admin_end_maintenance: admin aal2 allowed', (await rpc(admin2, 'admin_end_maintenance', { p_id: mwId })).status === 200);
  ok('admin_end_maintenance: audit row written', (await auditCount('end_maintenance')) === e0 + 1);

  // ---------- 4. Marketplace verification decisions
  for (const [who, tok] of callers) ok(`decide_marketplace_verification: ${who} refused`, refused(await rpc(tok, 'decide_marketplace_verification', { p_user_id: D, p_decision: 'verified', p_reason: null })));
  ok('decide: driver unchanged after refused attempts', (await svc('GET', `driver_marketplace_verifications?select=status&user_id=eq.${D}`))?.[0]?.status === 'needs_review');
  ok('decide: invalid decision refused', (await rpc(admin2, 'decide_marketplace_verification', { p_user_id: D, p_decision: 'paid', p_reason: 'x' })).status >= 400);
  const d0 = await auditCount('marketplace_decision');
  const rt = await rpc(admin2, 'decide_marketplace_verification', { p_user_id: D, p_decision: 'retake_licence', p_reason: '[TEST] blurry' });
  ok('decide retake_licence: status not_started, retake licence', rt.body?.status === 'not_started' && rt.body?.retake === 'licence', rt.body);
  const rw = (await svc('GET', `driver_marketplace_verifications?select=reasons,reviewed_by&user_id=eq.${D}`))?.[0];
  ok('decide: reviewer and reason recorded on the verification', rw?.reviewed_by === uid(admin2) && (rw?.reasons || []).includes('foundr:[TEST] blurry'), rw);
  ok('decide: audit row marketplace_decision written', (await auditCount('marketplace_decision')) === d0 + 1);
  const au = (await svc('GET', `admin_audit_log?select=action,target_type,target_id,reason,metadata&admin_user_id=eq.${uid(admin2)}&action=eq.marketplace_decision&order=id.desc&limit=1`))?.[0];
  ok('decide: audit row has driver target, reason and decision', au?.target_type === 'driver' && au?.target_id === D && au?.reason === '[TEST] blurry' && au?.metadata?.decision === 'retake_licence', au);
  const vv = await rpc(admin2, 'decide_marketplace_verification', { p_user_id: D2, p_decision: 'verified', p_reason: null });
  ok('decide verified (pending driver): status verified', vv.body?.status === 'verified', vv.body);
  const rj = await rpc(admin2, 'decide_marketplace_verification', { p_user_id: D2, p_decision: 'rejected', p_reason: '[TEST] reject' });
  ok('decide rejected: status rejected', rj.body?.status === 'rejected', rj.body);
  ok('decide: unknown driver -> not found', (await rpc(admin2, 'decide_marketplace_verification', { p_user_id: crypto.randomUUID(), p_decision: 'verified' })).status >= 400);
  // Storage: private licence documents
  const docPath = `${D}/licence-front-${stamp}.png`;
  await fetch(`${URL_}/storage/v1/object/cefflo-driver-documents/${docPath}`, { method: 'POST', headers: { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'image/png' }, body: Buffer.from('89504e470d0a1a0a', 'hex') });
  const sign = async tok => (await fetch(`${URL_}/storage/v1/object/sign/cefflo-driver-documents/${docPath}`, { method: 'POST', headers: { ...H(tok) }, body: JSON.stringify({ expiresIn: 60 }) })).status;
  ok('documents: admin aal2 can sign a licence image', (await sign(admin2)) === 200);
  for (const [who, tok] of [['user', user], ['owner', owner], ['admin aal1', admin1]]) ok(`documents: ${who} cannot sign`, (await sign(tok)) >= 400);
  ok('documents: no public URL', (await fetch(`${URL_}/storage/v1/object/public/cefflo-driver-documents/${docPath}`)).status >= 400);
  await fetch(`${URL_}/storage/v1/object/cefflo-driver-documents`, { method: 'DELETE', headers: SH, body: JSON.stringify({ prefixes: [docPath] }) });

  // cleanup of global rows this suite created
  await svc('DELETE', `feature_flags?key=eq.${flagKey}`);
  await svc('DELETE', `app_versions?version=eq.0.0.0-test.${stamp}`);
  if (annId) await svc('DELETE', `platform_announcements?id=eq.${annId}`);
  if (mwId) await svc('DELETE', `maintenance_windows?id=eq.${mwId}`);
  await svc('DELETE', `notification_broadcasts?business_id=eq.${B}`);
} catch (e) {
  ok('suite ran without exception', false, e.stack || e.message);
} finally {
  for (const id of created) await svc('DELETE', `admin_audit_log?admin_user_id=eq.${id}`);
  // reviewed_by (NO ACTION FK) points at the reviewing admin: remove the
  // [TEST] verification rows before deleting any account.
  for (const id of created) await svc('DELETE', `driver_marketplace_verifications?user_id=eq.${id}`);
  for (const b of businesses) if (b) await fetch(`${URL_}/rest/v1/businesses?id=eq.${b}`, { method: 'DELETE', headers: SH });
  let left = 0;
  for (const id of created) {
    await fetch(`${URL_}/rest/v1/platform_admins?user_id=eq.${id}`, { method: 'DELETE', headers: SH });
    await fetch(`${URL_}/rest/v1/profiles?id=eq.${id}`, { method: 'DELETE', headers: SH });
    const r = await fetch(`${URL_}/auth/v1/admin/users/${id}`, { method: 'DELETE', headers: SH }); if (!r.ok) left++;
  }
  const flags = await svc('GET', 'feature_flags?select=key&key=like.test_fdadm_*');
  ok('cleanup: [TEST] accounts, admins, business, flags removed', left === 0 && (flags || []).length === 0, `${left} accounts, ${(flags || []).length} flags left`);
  console.log(results.join('\n'));
  const total = results.length;
  console.log(`\n${total - fails}/${total} passed`);
  process.exitCode = fails ? 1 : 0;
}
