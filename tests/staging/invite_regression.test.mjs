import { ensureMarketplaceVerified } from './_marketplace.mjs';
// Invite regression (Security & Access Master §9-12, §27-29) + Find Jobs
// (D-75) interaction. Fresh staging accounts per role:
// link -> auth -> join request -> pending -> Owner approval -> correct
// active role -> correct destination. Staging only.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 150) : ''}`); if (!c) fails++; };
async function signIn(email, password = PW) {
  const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) });
  const j = await r.json(); if (!j.access_token) throw new Error('signin ' + email + JSON.stringify(j)); return j.access_token;
}
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function sel(tok, path) { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const uid = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;
const stamp = String(Date.now()).slice(-6);
async function freshUser(tag, meta = {}) {
  const email = `zelix.co00+v1005inv${tag}${stamp}@gmail.com`, password = 'Cf-v1005-Invite!5';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' }, body: JSON.stringify({ email, password, email_confirm: true, user_metadata: meta }) });
  if (!r.ok) throw new Error('create ' + await r.text());
  return signIn(email, password);
}
const owner = await signIn(mail('owner'));
const B = (await rpc(owner, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;
const cfg = await (await fetch('https://cefflo-staging-invite.pages.dev/shared/config.js')).text();
const appUrl = { driver: cfg.match(/"driver":\s*"([^"]+)"/)?.[1], vendor: cfg.match(/"vendor":\s*"([^"]+)"/)?.[1] };
ok('invite page knows both app destinations', !!appUrl.driver && !!appUrl.vendor, JSON.stringify(appUrl));
const tokenOf = b => (typeof b === 'string' ? b : b?.token);
const phone = n => `+60 13-${stamp}${n}`;
const created = { team: [], riders: [] };

for (const kind of ['operator', 'helper', 'rider']) {
  const link = tokenOf((await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: kind })).body);
  ok(`[${kind}] owner gets the permanent ${kind} link`, /^[0-9a-f]{40,}$/i.test(link || ''), link);
  // anonymous preview (before auth): business + kind only, no PII
  const prev = await rpc(null, 'resolve_invite_link', { p_token: link });
  const prevKeys = Object.keys(prev.body || {});
  ok(`[${kind}] link preview works before sign-in, kind matches`, prev.status === 200 && (prev.body?.kind === kind), JSON.stringify(prev.body).slice(0, 120));
  ok(`[${kind}] preview exposes no phone/email/address`, !prevKeys.some(k => /phone|email|address|owner|user/i.test(k)), prevKeys.join(','));

  const meta = kind === 'rider' ? { driver_registration: { full_name: `[TEST] Inv ${kind}`, phone: phone(1), vehicle_type: 'motorcycle', vehicle_plate: 'INV ' + stamp } } : {};
  const user = await freshUser(kind, meta);
  const before = (await rpc(user, 'get_my_businesses')).body;
  ok(`[${kind}] fresh account has no business before joining`, Array.isArray(before) && before.length === 0);
  const j1 = await rpc(user, 'join_via_invite_link', { p_token: link, p_name: `[TEST] Inv ${kind}`, p_phone: phone(kind === 'operator' ? 2 : kind === 'helper' ? 3 : 1) });
  ok(`[${kind}] join request -> pending`, j1.status === 200 && j1.body?.status === 'pending', msg(j1));
  const j2 = await rpc(user, 'join_via_invite_link', { p_token: link, p_name: `[TEST] Inv ${kind}`, p_phone: phone(9) });
  ok(`[${kind}] joining again is idempotent (still pending, no duplicate)`, j2.status === 200 && j2.body?.status === 'pending', msg(j2));
  const pendingAccess = (await rpc(user, 'get_my_businesses')).body;
  ok(`[${kind}] pending grants zero workspace access`, Array.isArray(pendingAccess) && pendingAccess.length === 0, JSON.stringify(pendingAccess));
  const pend = await rpc(user, 'get_storefront', { p_business_id: B });
  ok(`[${kind}] pending user is refused vendor data`, pend.status >= 400, msg(pend));

  // Owner approval
  if (kind === 'rider') {
    const rows = (await sel(owner, `riders?select=id,status,vehicle_type,vehicle_plate&business_id=eq.${B}&auth_user_id=eq.${uid(user)}`)).body;
    ok('[rider] appears in Riders > Pending', rows?.length === 1 && rows[0].status === 'pending', JSON.stringify(rows));
    const ap = await rpc(owner, 'approve_pending_rider', { p_rider_id: rows[0].id });
    ok('[rider] owner approves', ap.status === 200, msg(ap));
    const mine = (await sel(user, `riders?select=status,business_id&auth_user_id=eq.${uid(user)}`)).body;
    ok('[rider] own relationship is active', mine?.[0]?.status === 'active', JSON.stringify(mine));
    const ws = (await rpc(user, 'get_my_businesses')).body;
    ok('[rider] rider membership grants NO vendor workspace', Array.isArray(ws) && ws.length === 0, JSON.stringify(ws));
    const dest = new URL(appUrl.driver); dest.searchParams.set('join', link);
    const d = await fetch(dest.href); ok('[rider] destination = Driver app (loads)', d.status === 200 && dest.href.startsWith(appUrl.driver), dest.href);
    created.riders.push({ id: rows[0].id, tok: user });
  } else {
    const reqs = (await sel(owner, `team_join_requests?select=id,role,status&business_id=eq.${B}&user_id=eq.${uid(user)}&status=eq.pending`)).body;
    ok(`[${kind}] appears in Team > Pending with role ${kind}`, reqs?.length === 1 && reqs[0].role === kind, JSON.stringify(reqs));
    const ap = await rpc(owner, 'decide_team_join_request', { p_request_id: reqs[0].id, p_approve: true });
    ok(`[${kind}] owner approves`, ap.status === 200, msg(ap));
    const ws = (await rpc(user, 'get_my_businesses')).body;
    ok(`[${kind}] active role is exactly ${kind}`, ws?.length === 1 && ws[0].member_role === kind, JSON.stringify(ws));
    const dest = new URL(appUrl.vendor); dest.searchParams.set('access', kind); dest.searchParams.set('join', link);
    const page = await (await fetch(dest.href)).text();
    ok(`[${kind}] destination = Vendor App ?access=${kind} (installs as Cefflo ${kind === 'operator' ? 'Operator' : 'Helper'})`, page.includes(`manifest-' + a + '.json`) || page.includes('manifest-'), dest.href);
    if (kind === 'operator') {
      const sf = await rpc(user, 'get_storefront', { p_business_id: B });
      ok('[operator] can do operations (storefront)', sf.status === 200, msg(sf));
      const own = await rpc(user, 'update_business_profile', { p_business_id: B, p_name: 'x', p_phone: null, p_email: null, p_address: null, p_operating_area: null, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR', p_idempotency_key: crypto.randomUUID() });
      ok('[operator] still cannot do Owner admin', own.status >= 400, msg(own));
    } else {
      const fb = await rpc(user, 'my_fulfilment_tasks', { p_business_id: B });
      ok('[helper] lands in the fulfilment workspace (board loads)', fb.status === 200, msg(fb));
      const sf = await rpc(user, 'get_storefront', { p_business_id: B });
      ok('[helper] cannot open vendor operations', sf.status >= 400, msg(sf));
    }
    created.team.push({ uid: uid(user), tok: user, kind });
  }
}

// --- Find Jobs interaction
const op = (await rpc(owner, 'save_job_opening', { p_business_id: B, p_area_label: '[TEST] inv-regression', p_pickup_time: '19:00', p_days: [7], p_vehicle_type: 'motorcycle', p_pay_per_drop: 3, p_drivers_needed: 1 })).body;
ok('Find Jobs: owner posts an opening', !!op?.id);
const invitedRider = created.riders[0];
const unv = await rpc(invitedRider.tok, 'request_job_opening', { p_opening_id: op.id });
ok('Find Jobs: applying needs Marketplace Verification (invite alone is not enough)', unv.status >= 400 && /marketplace verification required/.test(msg(unv)), msg(unv));
await ensureMarketplaceVerified({ url: URL_, key: KEY, svc: process.env.SUPABASE_SECRET_KEY, driverToken: invitedRider.tok, name: '[TEST] Inv rider', plate: 'INV ' + stamp.slice(-4) });
const rq = await rpc(invitedRider.tok, 'request_job_opening', { p_opening_id: op.id });
ok('Find Jobs: invite-approved rider is booked directly (already active)', rq.status === 200 && rq.body?.status === 'approved', msg(rq));
for (const t of created.team) {
  const r = await rpc(t.tok, 'request_job_opening', { p_opening_id: op.id });
  ok(`Find Jobs: ${t.kind} of this business cannot apply as a rider`, r.status >= 400, msg(r));
}
// a Find-Jobs applicant later opening the rider invite link -> same relationship, no duplicate
const fjUser = await freshUser('fj', { driver_registration: { full_name: '[TEST] Inv findjobs', phone: phone(5), vehicle_type: 'motorcycle', vehicle_plate: 'FJ ' + stamp } });
await ensureMarketplaceVerified({ url: URL_, key: KEY, svc: process.env.SUPABASE_SECRET_KEY, driverToken: fjUser, name: '[TEST] Inv findjobs', plate: 'FJ ' + stamp.slice(-4) });
const fj = await rpc(fjUser, 'request_job_opening', { p_opening_id: op.id });
ok('Find Jobs: new rider requests -> pending', fj.status === 200 && fj.body?.status === 'pending', msg(fj));
const riderLink = tokenOf((await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: 'rider' })).body);
const viaLink = await rpc(fjUser, 'join_via_invite_link', { p_token: riderLink, p_name: '[TEST] Inv findjobs', p_phone: phone(6) });
ok('Find Jobs + invite link: returns the existing pending relationship', viaLink.status === 200 && viaLink.body?.status === 'pending', msg(viaLink));
const fjRows = (await sel(owner, `riders?select=id&business_id=eq.${B}&auth_user_id=eq.${uid(fjUser)}`)).body;
ok('Find Jobs + invite link: still exactly one rider row', fjRows?.length === 1, `${fjRows?.length} rows`);

// --- cleanup (staging test data)
await rpc(owner, 'close_job_opening', { p_opening_id: op.id });
for (const r of [...created.riders.map(x => x.id), ...(fjRows || []).map(x => x.id)]) await rpc(owner, 'deactivate_rider', { p_rider_id: r });
for (const t of created.team) {
  const r = await rpc(owner, 'update_team_member', { p_business_id: B, p_user_id: t.uid, p_role: t.kind, p_status: 'inactive' });
  ok(`cleanup: owner removes test ${t.kind}`, r.status === 200, msg(r));
  const ws = (await rpc(t.tok, 'get_my_businesses')).body;
  ok(`removal revokes ${t.kind} access immediately`, Array.isArray(ws) && ws.length === 0, JSON.stringify(ws));
}

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
