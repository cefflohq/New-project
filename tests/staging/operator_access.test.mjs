// Operator PWA authorization tests (Security & Access Master §20, §28).
// A real staging Operator session calls every Owner-only function directly
// with REAL targets. All must be refused. Staging only.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 140) : ''}`); if (!c) fails++; };
async function signIn(email, password = PW) {
  const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) });
  const j = await r.json(); if (!j.access_token) throw new Error('signin ' + email + JSON.stringify(j)); return j.access_token;
}
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function sel(tok, path) { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; }
async function patch(tok, path, body) { const r = await fetch(`${URL_}/rest/v1/${path}`, { method: 'PATCH', headers: { ...H(tok), prefer: 'return=representation' }, body: JSON.stringify(body) }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const refused = r => r.status >= 400;

const owner = await signIn(mail('owner')), operator = await signIn(mail('operator'));
const opBiz = (await rpc(operator, 'get_my_businesses')).body;
const B = opBiz?.[0]?.business_id;
ok('operator session resolves to role operator', opBiz?.[0]?.member_role === 'operator', JSON.stringify(opBiz));
const meOp = JSON.parse(Buffer.from(operator.split('.')[1], 'base64url').toString()).sub;

// real targets
const riders = (await sel(owner, `riders?select=id,name,status&business_id=eq.${B}&status=eq.active&limit=1`)).body;
const realRider = riders?.[0];
ok('setup: a real active rider exists', !!realRider, realRider?.name);
const biz = (await sel(owner, `businesses?select=id,name,phone,email,address&id=eq.${B}`)).body?.[0];
const opening = (await rpc(owner, 'save_job_opening', { p_business_id: B, p_area_label: '[TEST] op-auth', p_pickup_time: '07:00', p_days: [1], p_vehicle_type: 'car', p_pay_per_drop: 3, p_drivers_needed: 1 })).body;
ok('setup: owner posts a real opening', !!opening?.id);
// a real pending join request from a fresh account through the helper link
const link = (await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: 'helper' })).body;
const token = typeof link === 'string' ? link : (link?.token || link?.link_token);
const email = `zelix.co00+v1005opauth${Date.now() % 100000}@gmail.com`;
await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'Cf-v1005-OpAuth!3', email_confirm: true }) });
const joiner = await signIn(email, 'Cf-v1005-OpAuth!3');
const jr = await rpc(joiner, 'join_via_invite_link', { p_token: token, p_name: '[TEST] OpAuth Joiner', p_phone: '+60 11-' + String(Date.now()).slice(-7) });
const pendingReq = (await sel(owner, `team_join_requests?select=id&business_id=eq.${B}&status=eq.pending&name=eq.%5BTEST%5D%20OpAuth%20Joiner`)).body?.[0];
ok('setup: a real pending Helper join request exists', jr.status === 200 && !!pendingReq, msg(jr));

// --- every Owner-only function, called by the Operator with real targets
const cases = [
  ['approve_pending_rider (real pending? uses active rider)', 'approve_pending_rider', { p_rider_id: realRider.id }],
  ['deactivate_rider (real active rider)', 'deactivate_rider', { p_rider_id: realRider.id }],
  ['decide_team_join_request approve (real pending)', 'decide_team_join_request', { p_request_id: pendingReq?.id, p_approve: true }],
  ['decide_team_join_request reject (real pending)', 'decide_team_join_request', { p_request_id: pendingReq?.id, p_approve: false }],
  ['update_team_member: promote self to owner', 'update_team_member', { p_business_id: B, p_user_id: meOp, p_role: 'owner', p_status: 'active' }],
  ['update_team_member: change another member', 'update_team_member', { p_business_id: B, p_user_id: JSON.parse(Buffer.from(owner.split('.')[1], 'base64url').toString()).sub, p_role: 'operator', p_status: 'inactive' }],
  ['update_business_profile', 'update_business_profile', { p_business_id: B, p_name: biz.name, p_phone: biz.phone, p_email: biz.email, p_address: biz.address, p_operating_area: null, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR', p_idempotency_key: crypto.randomUUID() }],
  ['set_business_hours', 'set_business_hours', { p_business_id: B, p_days: [] }],
  ['change_storefront_slug', 'change_storefront_slug', { p_business_id: B, p_slug: 'op-auth-test-' + Date.now() }],
  ['create_team_invitation (email invites)', 'create_team_invitation', { p_business_id: B, p_role: 'operator', p_invited_email: 'x@example.com' }],
  ['revoke_team_invitation', 'revoke_team_invitation', { p_invitation_id: '00000000-0000-0000-0000-000000000000' }],
  ['get_invite_link (operator)', 'get_invite_link', { p_business_id: B, p_kind: 'operator' }],
  ['get_invite_link (helper)', 'get_invite_link', { p_business_id: B, p_kind: 'helper' }],
  ['reset_invite_link (operator)', 'reset_invite_link', { p_business_id: B, p_kind: 'operator' }],
  ['reset_invite_link (helper)', 'reset_invite_link', { p_business_id: B, p_kind: 'helper' }],
  ['save_job_opening', 'save_job_opening', { p_business_id: B, p_area_label: 'x', p_pickup_time: '07:00', p_days: [1], p_vehicle_type: 'car', p_pay_per_drop: 3, p_drivers_needed: 1 }],
  ['close_job_opening (real opening)', 'close_job_opening', { p_opening_id: opening.id }],
  ['admin_broadcast_notification (platform admin)', 'admin_broadcast_notification', { p_title: 'x', p_body: 'x', p_audience: 'business', p_business_id: B, p_reason: 'test' }],
  ['admin_set_subscription (platform admin)', 'admin_set_subscription', { p_business_id: B, p_plan_key: 'scale', p_status: 'active', p_mrr_cents: 0, p_trial_ends_at: null }],
];
for (const [label, fn, body] of cases) { const r = await rpc(operator, fn, body); ok(`operator refused: ${label}`, refused(r), msg(r)); }

// --- direct table writes / owner-only reads
const pw = await patch(operator, `businesses?id=eq.${B}`, { name: biz.name + ' X' });
ok('operator cannot update the business row directly', pw.status >= 400 || (Array.isArray(pw.body) && pw.body.length === 0), `${pw.status} ${JSON.stringify(pw.body).slice(0, 80)}`);
for (const t of ['business_subscriptions', 'team_invitations']) {
  const r = await sel(operator, `${t}?select=*&business_id=eq.${B}`);
  ok(`operator reads no rows from ${t}`, r.status >= 400 || (Array.isArray(r.body) && r.body.length === 0), `${r.status} ${r.body?.length}`);
}
const tj = await sel(operator, `team_join_requests?select=user_id&business_id=eq.${B}`);
ok("operator cannot read others' team join requests", Array.isArray(tj.body) && tj.body.every(x => x.user_id === meOp), `${tj.body?.length} rows`);

// --- state unchanged after the attempts
const r2 = (await sel(owner, `riders?select=status&id=eq.${realRider.id}`)).body?.[0];
ok('rider still active after operator attempts', r2?.status === 'active', r2?.status);
const op2 = (await rpc(operator, 'get_my_businesses')).body?.[0];
ok('operator still operator (no escalation)', op2?.member_role === 'operator', op2?.member_role);
const req2 = (await sel(owner, `team_join_requests?select=status&id=eq.${pendingReq?.id}`)).body?.[0];
ok('join request still pending', req2?.status === 'pending', req2?.status);
const op3 = (await sel(owner, `rider_job_openings?select=status&id=eq.${opening.id}`)).body?.[0];
ok('opening still open', op3?.status === 'open', op3?.status);

// --- positive controls: operational work still allowed
const rl = await rpc(operator, 'get_invite_link', { p_business_id: B, p_kind: 'rider' });
ok('operator CAN get the rider invite link', rl.status === 200, msg(rl));
const sf = await rpc(operator, 'get_storefront', { p_business_id: B });
ok('operator CAN open the storefront', sf.status === 200, msg(sf));
const ord = await sel(operator, `orders?select=id&business_id=eq.${B}&limit=1`);
ok('operator CAN read business orders', ord.status === 200 && Array.isArray(ord.body), ord.status);

// cleanup
await rpc(owner, 'close_job_opening', { p_opening_id: opening.id });
const rej = await rpc(owner, 'decide_team_join_request', { p_request_id: pendingReq?.id, p_approve: false });
ok('cleanup: owner rejects the test join request', rej.status === 200, msg(rej));

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
