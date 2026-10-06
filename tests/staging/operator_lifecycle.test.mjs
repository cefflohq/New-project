// Operator + Invite lifecycle E2E (staging only). A fresh [TEST] business
// runs the full path end to end and is deleted afterwards:
// Owner Operator link -> join -> Pending -> Owner approves -> workspace ->
// operational action persists -> delegated Helper / Driver invites and
// approvals -> Owner-only boundaries -> cross-business isolation -> reset
// scope -> Owner removes the Operator (live session loses every privilege)
// -> rejoin needs approval again. Every check is a direct RPC/REST call.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 150) : ''}`); if (!c) fails++; };
async function auth(path, body) {
  const r = await fetch(`${URL_}/auth/v1/${path}`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify(body) });
  return r.json();
}
async function signIn(email, password = PW) {
  const j = await auth('token?grant_type=password', { email, password });
  if (!j.access_token) throw new Error('signin ' + email); return j;
}
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
const SH = { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' };
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function rest(tok, method, path, body) { const r = await fetch(`${URL_}/rest/v1/${path}`, { method, headers: { ...H(tok), prefer: 'return=representation' }, body: body ? JSON.stringify(body) : undefined }); return { status: r.status, body: await r.json().catch(() => null) }; }
const sel = (tok, path) => rest(tok, 'GET', path);
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const refused = r => r.status >= 400;
const empty = r => r.status >= 400 || (Array.isArray(r.body) && r.body.length === 0);
const uid = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;
const stamp = String(Date.now()).slice(-6);
const created = [];
async function fresh(tag, meta = {}) {
  const email = `zelix.co00+v1006opl${tag}${stamp}@gmail.com`, password = 'Cf-v1006-OpLife!7';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: SH, body: JSON.stringify({ email, password, email_confirm: true, user_metadata: meta }) });
  if (!r.ok) throw new Error('create ' + await r.text());
  const s = await signIn(email, password); created.push(uid(s.access_token)); return s;
}
const phone = n => `+60 12-${n}${stamp}`;
const roleIn = async (tok, biz) => ((await rpc(tok, 'get_my_businesses')).body || []).find(x => x.business_id === biz)?.member_role;
const pendingReq = async (ownerTok, biz, user) => (await sel(ownerTok, `team_join_requests?select=id,role,status&business_id=eq.${biz}&user_id=eq.${user}&status=eq.pending`)).body || [];

let B3;
try {
  // shared staging business (cross-business target) + a fresh [TEST] business
  const sharedOwner = (await signIn(mail('owner'))).access_token;
  const BS = (await rpc(sharedOwner, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;
  const ownerS = await fresh('owner'); const owner = ownerS.access_token;
  const b = await rpc(owner, 'bootstrap_business', { p_name: `[TEST] OpLife ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' });
  B3 = b.body;
  ok('setup: fresh [TEST] business with its Owner', b.status === 200 && (await roleIn(owner, B3)) === 'owner', msg(b));

  // ---------- 1. Owner -> Operator invite -> join -> Pending
  const opLink = (await rpc(owner, 'get_invite_link', { p_business_id: B3, p_kind: 'operator' })).body?.token;
  ok('1 Owner obtains the permanent Operator link', /^[0-9a-f]{48}$/.test(opLink || ''));
  const pre = (await rpc(null, 'resolve_invite_link', { p_token: opLink })).body;
  ok('  link preview: kind from the server = operator, open', pre?.kind === 'operator' && pre?.status === 'open', JSON.stringify(pre));
  const opS = await fresh('op'); let op = opS.access_token; const opId = uid(op);
  const j1 = await rpc(op, 'join_via_invite_link', { p_token: opLink, p_name: '[TEST] OpLife Operator', p_phone: phone(1) });
  ok('  join -> pending operator', j1.status === 200 && j1.body?.status === 'pending' && j1.body?.kind === 'operator', msg(j1));
  const j1b = await rpc(op, 'join_via_invite_link', { p_token: opLink, p_name: '[TEST] OpLife Operator', p_phone: phone(1) });
  ok('  joining twice keeps ONE pending request', j1b.body?.status === 'pending' && (await pendingReq(owner, B3, opId)).length === 1);
  ok('  pending Operator has no workspace', (await roleIn(op, B3)) === undefined);
  ok('  pending Operator cannot obtain any invite link', refused(await rpc(op, 'get_invite_link', { p_business_id: B3, p_kind: 'helper' })) && refused(await rpc(op, 'get_invite_link', { p_business_id: B3, p_kind: 'rider' })));
  ok('  pending Operator cannot post a hiring opening', refused(await rpc(op, 'save_job_opening', { p_business_id: B3, p_area_label: '[TEST] x', p_pickup_time: '07:00', p_days: [1], p_vehicle_type: 'car', p_pay_per_drop: 3, p_drivers_needed: 1 })));
  ok('  pending Operator reads no orders / storefront', empty(await sel(op, `orders?select=id&business_id=eq.${B3}`)) && refused(await rpc(op, 'get_storefront', { p_business_id: B3 })));
  const opReq = (await pendingReq(owner, B3, opId))[0];
  ok('  pending Operator cannot approve itself', refused(await rpc(op, 'decide_team_join_request', { p_request_id: opReq?.id, p_approve: true })));

  // ---------- 2. Owner approves -> Operator workspace
  const ap = await rpc(owner, 'decide_team_join_request', { p_request_id: opReq.id, p_approve: true });
  ok('2 Owner approves the Operator request', ap.status === 200 && ap.body?.status === 'approved', msg(ap));
  ok('  role resolved server-side = operator (same session)', (await roleIn(op, B3)) === 'operator');
  ok('  Operator opens the storefront / orders', (await rpc(op, 'get_storefront', { p_business_id: B3 })).status === 200 && (await sel(op, `orders?select=id&business_id=eq.${B3}`)).status === 200);

  // ---------- 3. operational action persists across a fresh session
  const post = await rpc(op, 'save_job_opening', { p_business_id: B3, p_area_label: '[TEST] OpLife', p_pickup_time: '09:00', p_days: [1, 3], p_vehicle_type: 'motorcycle', p_pay_per_drop: 3.5, p_drivers_needed: 2 });
  ok('3 Operator publishes a Driver hiring post', post.status === 200 && post.body?.status === 'open', msg(post));
  const re = await auth('token?grant_type=refresh_token', { refresh_token: opS.refresh_token });
  op = re.access_token || op;
  const after = (await sel(op, `rider_job_openings?select=id,pay_amount,status&id=eq.${post.body?.id}`)).body?.[0];
  ok('  persisted: visible after session refresh (Operator)', after?.status === 'open' && Number(after?.pay_amount) === 3.5, JSON.stringify(after));
  ok('  persisted: visible to the Owner', (await sel(owner, `rider_job_openings?select=id&id=eq.${post.body?.id}`)).body?.length === 1);

  // ---------- 4. Owner-only boundaries (direct RPC)
  const ownerId = uid(owner);
  const ownerOnly = [
    ['get Operator link', 'get_invite_link', { p_business_id: B3, p_kind: 'operator' }],
    ['reset Operator link', 'reset_invite_link', { p_business_id: B3, p_kind: 'operator' }],
    ['owner kind link', 'get_invite_link', { p_business_id: B3, p_kind: 'owner' }],
    ['promote self to owner', 'update_team_member', { p_business_id: B3, p_user_id: opId, p_role: 'owner' }],
    ['demote / remove the Owner', 'update_team_member', { p_business_id: B3, p_user_id: ownerId, p_status: 'inactive' }],
    ['business profile', 'update_business_profile', { p_business_id: B3, p_name: 'x', p_phone: null, p_email: null, p_address: null, p_operating_area: null, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR', p_idempotency_key: crypto.randomUUID() }],
    ['business hours', 'set_business_hours', { p_business_id: B3, p_days: [] }],
    ['storefront slug', 'change_storefront_slug', { p_business_id: B3, p_slug: 'oplife-' + stamp }],
  ];
  for (const [l, fn, body] of ownerOnly) { const r = await rpc(op, fn, body); ok(`4 Operator refused: ${l}`, refused(r), msg(r)); }
  ok('  Operator cannot write its own membership row', empty(await rest(op, 'PATCH', `business_members?business_id=eq.${B3}&user_id=eq.${opId}`, { role: 'owner' })));
  ok('  Operator still operator', (await roleIn(op, B3)) === 'operator');

  // ---------- 5. delegated Helper invite + approval
  const hTok = (await rpc(op, 'get_invite_link', { p_business_id: B3, p_kind: 'helper' })).body?.token;
  ok('5 Operator obtains the Helper link (same permanent token as the Owner sees)', !!hTok && hTok === (await rpc(owner, 'get_invite_link', { p_business_id: B3, p_kind: 'helper' })).body?.token);
  const hS = await fresh('helper'); const hel = hS.access_token; const helId = uid(hel);
  const hj = await rpc(hel, 'join_via_invite_link', { p_token: hTok, p_name: '[TEST] OpLife Helper', p_phone: phone(2) });
  ok('  Helper join -> pending helper', hj.body?.status === 'pending' && hj.body?.kind === 'helper', msg(hj));
  const hReq = (await pendingReq(owner, B3, helId))[0];
  const hd = await rpc(op, 'decide_team_join_request', { p_request_id: hReq?.id, p_approve: true });
  ok('  Operator approves the Helper', hd.status === 200, msg(hd));
  ok('  resulting role = helper', (await roleIn(hel, B3)) === 'helper');
  for (const [l, fn, body] of [['get Helper link', 'get_invite_link', { p_business_id: B3, p_kind: 'helper' }], ['get Driver link', 'get_invite_link', { p_business_id: B3, p_kind: 'rider' }], ['post hiring', 'save_job_opening', { p_business_id: B3, p_area_label: 'x', p_pickup_time: '07:00', p_days: [1], p_vehicle_type: 'car', p_pay_per_drop: 3, p_drivers_needed: 1 }], ['decide request', 'decide_team_join_request', { p_request_id: hReq?.id, p_approve: true }]]) {
    ok(`  Helper refused: ${l}`, refused(await rpc(hel, fn, body)));
  }

  // ---------- 6. delegated Driver invite + approval
  const rTok = (await rpc(op, 'get_invite_link', { p_business_id: B3, p_kind: 'rider' })).body?.token;
  ok('6 Operator obtains the Driver link', /^[0-9a-f]{48}$/.test(rTok || ''));
  const dS = await fresh('driver', { driver_registration: { full_name: '[TEST] OpLife Driver', phone: phone(3), vehicle_type: 'car', vehicle_plate: 'OPL ' + stamp } });
  const drv = dS.access_token;
  const dj = await rpc(drv, 'join_via_invite_link', { p_token: rTok, p_name: '[TEST] OpLife Driver', p_phone: phone(3) });
  const dRow = (await sel(owner, `riders?select=id,status&business_id=eq.${B3}&auth_user_id=eq.${uid(drv)}`)).body?.[0];
  ok('  Driver join -> one pending rider row', dj.body?.kind === 'rider' && dRow?.status === 'pending', msg(dj));
  ok('  Driver gets no team membership', (await roleIn(drv, B3)) === undefined);
  const da = await rpc(op, 'approve_pending_rider', { p_rider_id: dRow?.id });
  ok('  Operator approves the Driver', da.status === 200 && da.body?.status === 'active', msg(da));
  for (const k of ['rider', 'helper', 'operator']) ok(`  Driver refused: get ${k} link`, refused(await rpc(drv, 'get_invite_link', { p_business_id: B3, p_kind: k })));
  ok('  Driver refused: decide / approve', refused(await rpc(drv, 'decide_team_join_request', { p_request_id: hReq?.id, p_approve: true })) && refused(await rpc(drv, 'approve_pending_rider', { p_rider_id: dRow?.id })));
  ok('  Operator cannot REMOVE the active Driver (Owner-only)', refused(await rpc(op, 'deactivate_rider', { p_rider_id: dRow?.id })));

  // ---------- 7. Operator never admits an Operator
  const o2S = await fresh('op2'); const o2 = o2S.access_token;
  await rpc(o2, 'join_via_invite_link', { p_token: opLink, p_name: '[TEST] OpLife Operator2', p_phone: phone(4) });
  const o2Req = (await pendingReq(owner, B3, uid(o2)))[0];
  ok('7 Operator cannot see an Operator request', empty(await sel(op, `team_join_requests?select=id&id=eq.${o2Req?.id}`)));
  ok('  Operator cannot approve / reject an Operator request', refused(await rpc(op, 'decide_team_join_request', { p_request_id: o2Req?.id, p_approve: true })) && refused(await rpc(op, 'decide_team_join_request', { p_request_id: o2Req?.id, p_approve: false })));
  await rpc(owner, 'decide_team_join_request', { p_request_id: o2Req?.id, p_approve: false });

  // ---------- 8. cross-business isolation (Operator of B3 vs shared business)
  const sHelper = (await rpc(sharedOwner, 'get_invite_link', { p_business_id: BS, p_kind: 'helper' })).body?.token;
  const xS = await fresh('xh'); const xh = xS.access_token;
  await rpc(xh, 'join_via_invite_link', { p_token: sHelper, p_name: '[TEST] OpLife CrossHelper', p_phone: phone(5) });
  const xReq = (await pendingReq(sharedOwner, BS, uid(xh)))[0];
  ok('8 setup: pending Helper request in ANOTHER business', !!xReq);
  ok('  B3 Operator cannot see it', empty(await sel(op, `team_join_requests?select=id&id=eq.${xReq?.id}`)));
  ok('  B3 Operator cannot approve it', refused(await rpc(op, 'decide_team_join_request', { p_request_id: xReq?.id, p_approve: true })));
  for (const k of ['rider', 'helper', 'operator']) ok(`  B3 Operator refused: other business ${k} link`, refused(await rpc(op, 'get_invite_link', { p_business_id: BS, p_kind: k })));
  ok('  B3 Operator refused: other business hiring post', refused(await rpc(op, 'save_job_opening', { p_business_id: BS, p_area_label: 'x', p_pickup_time: '07:00', p_days: [1], p_vehicle_type: 'car', p_pay_per_drop: 3, p_drivers_needed: 1 })));
  ok('  B3 Operator reads no orders / riders of the other business', empty(await sel(op, `orders?select=id&business_id=eq.${BS}`)) && empty(await sel(op, `riders?select=id&business_id=eq.${BS}`)));
  ok('  B3 Operator refused: other business storefront', refused(await rpc(op, 'get_storefront', { p_business_id: BS })));
  await rpc(sharedOwner, 'decide_team_join_request', { p_request_id: xReq?.id, p_approve: false });
  ok('  anon refused: link / decide / hiring', refused(await rpc(null, 'get_invite_link', { p_business_id: B3, p_kind: 'rider' })) && refused(await rpc(null, 'decide_team_join_request', { p_request_id: hReq?.id, p_approve: true })) && refused(await rpc(null, 'save_job_opening', { p_business_id: B3, p_area_label: 'x', p_pickup_time: '07:00', p_days: [1], p_vehicle_type: 'car', p_pay_per_drop: 3, p_drivers_needed: 1 })));

  // ---------- 9. reset scope: only that role's token changes
  const before = {}; for (const k of ['rider', 'helper', 'operator']) before[k] = (await rpc(owner, 'get_invite_link', { p_business_id: B3, p_kind: k })).body?.token;
  const rs = await rpc(op, 'reset_invite_link', { p_business_id: B3, p_kind: 'helper' });
  const now = {}; for (const k of ['rider', 'helper', 'operator']) now[k] = (await rpc(owner, 'get_invite_link', { p_business_id: B3, p_kind: k })).body?.token;
  ok('9 Operator resets the Helper link -> new Helper token', rs.status === 200 && now.helper !== before.helper && now.helper === rs.body?.token);
  ok('  Driver and Operator tokens unchanged', now.rider === before.rider && now.operator === before.operator);
  const lateS = await fresh('late'); const late = lateS.access_token;
  const oj = await rpc(late, 'join_via_invite_link', { p_token: before.helper, p_name: '[TEST] OpLife Late', p_phone: phone(6) });
  ok('  old Helper token cannot be joined', refused(oj) && /not available/.test(msg(oj)), msg(oj));
  ok('  old token preview = revoked', (await rpc(null, 'resolve_invite_link', { p_token: before.helper })).body?.status === 'revoked');

  // ---------- 10. Owner removes the Operator: the LIVE session loses everything
  const hS2 = await fresh('helper2'); const h2 = hS2.access_token;
  await rpc(h2, 'join_via_invite_link', { p_token: now.helper, p_name: '[TEST] OpLife Helper2', p_phone: phone(7) });
  const h2Req = (await pendingReq(owner, B3, uid(h2)))[0];
  const dS2 = await fresh('driver2', { driver_registration: { full_name: '[TEST] OpLife Driver2', phone: phone(8), vehicle_type: 'van', vehicle_plate: 'OPL2 ' + stamp } });
  await rpc(dS2.access_token, 'join_via_invite_link', { p_token: now.rider, p_name: '[TEST] OpLife Driver2', p_phone: phone(8) });
  const d2Row = (await sel(owner, `riders?select=id,status&business_id=eq.${B3}&auth_user_id=eq.${uid(dS2.access_token)}`)).body?.[0];
  const rm = await rpc(owner, 'update_team_member', { p_business_id: B3, p_user_id: opId, p_status: 'inactive' });
  ok('10 Owner removes the Operator', rm.status === 200 && rm.body?.status === 'inactive', msg(rm));
  ok('  existing session: no workspace', (await roleIn(op, B3)) === undefined);
  const removedCalls = [
    ['get Helper link', 'get_invite_link', { p_business_id: B3, p_kind: 'helper' }],
    ['get Driver link', 'get_invite_link', { p_business_id: B3, p_kind: 'rider' }],
    ['reset Helper link', 'reset_invite_link', { p_business_id: B3, p_kind: 'helper' }],
    ['approve Helper request', 'decide_team_join_request', { p_request_id: h2Req?.id, p_approve: true }],
    ['approve Driver', 'approve_pending_rider', { p_rider_id: d2Row?.id }],
    ['reject Driver applicant', 'deactivate_rider', { p_rider_id: d2Row?.id }],
    ['post hiring', 'save_job_opening', { p_business_id: B3, p_area_label: 'x', p_pickup_time: '07:00', p_days: [1], p_vehicle_type: 'car', p_pay_per_drop: 3, p_drivers_needed: 1 }],
    ['close hiring', 'close_job_opening', { p_opening_id: post.body?.id }],
    ['storefront', 'get_storefront', { p_business_id: B3 }],
  ];
  for (const [l, fn, body] of removedCalls) { const r = await rpc(op, fn, body); ok(`  removed Operator (live JWT) refused: ${l}`, refused(r), msg(r)); }
  ok('  removed Operator reads no orders / requests / riders', empty(await sel(op, `orders?select=id&business_id=eq.${B3}`)) && empty(await sel(op, `team_join_requests?select=id&business_id=eq.${B3}&role=eq.helper`)) && empty(await sel(op, `riders?select=id&business_id=eq.${B3}`)));
  const re2 = await auth('token?grant_type=refresh_token', { refresh_token: re.refresh_token || opS.refresh_token });
  ok('  refreshed session after removal: still no workspace', !!re2.access_token && (await roleIn(re2.access_token, B3)) === undefined);
  ok('  Helper request + Driver applicant untouched by the attempts', (await pendingReq(owner, B3, uid(h2))).length === 1 && (await sel(owner, `riders?select=status&id=eq.${d2Row?.id}`)).body?.[0]?.status === 'pending');

  // ---------- 11. rejoin requires the valid link + approval again
  const rj = await rpc(op, 'join_via_invite_link', { p_token: now.operator, p_name: '[TEST] OpLife Operator', p_phone: phone(1) });
  ok('11 removed Operator rejoins via the Operator link -> pending (no access)', rj.body?.status === 'pending' && (await roleIn(op, B3)) === undefined, msg(rj));
  await rpc(op, 'join_via_invite_link', { p_token: now.operator, p_name: '[TEST] OpLife Operator', p_phone: phone(1) });
  ok('  duplicate rejoin keeps ONE pending request', (await pendingReq(owner, B3, opId)).length === 1);
  const rjH = await rpc(op, 'join_via_invite_link', { p_token: now.helper, p_name: '[TEST] OpLife Operator', p_phone: phone(1) });
  ok('  then opening the Helper link does not add a second request or a role', (await pendingReq(owner, B3, opId)).length === 1 && (await pendingReq(owner, B3, opId))[0].role === 'operator', msg(rjH));
  await rpc(owner, 'decide_team_join_request', { p_request_id: (await pendingReq(owner, B3, opId))[0]?.id, p_approve: false });
  ok('  rejected rejoin: still no workspace', (await roleIn(op, B3)) === undefined);

  const rmH = await rpc(owner, 'update_team_member', { p_business_id: B3, p_user_id: helId, p_status: 'inactive' });
  ok('  Owner removes the Helper', rmH.status === 200 && (await roleIn(hel, B3)) === undefined, msg(rmH));
  ok('  removed Helper: old (reset) token refused', refused(await rpc(hel, 'join_via_invite_link', { p_token: before.helper, p_name: '[TEST] OpLife Helper', p_phone: phone(2) })));
  const hrj = await rpc(hel, 'join_via_invite_link', { p_token: now.helper, p_name: '[TEST] OpLife Helper', p_phone: phone(2) });
  ok('  removed Helper rejoins via the current link -> pending, no workspace', hrj.body?.status === 'pending' && (await roleIn(hel, B3)) === undefined, msg(hrj));
  await rpc(owner, 'decide_team_join_request', { p_request_id: (await pendingReq(owner, B3, helId))[0]?.id, p_approve: false });

  const rmD = await rpc(owner, 'deactivate_rider', { p_rider_id: dRow?.id });
  ok('  Owner removes the Driver', rmD.status === 200 && rmD.body?.status === 'inactive', msg(rmD));
  const drj = await rpc(drv, 'join_via_invite_link', { p_token: now.rider, p_name: '[TEST] OpLife Driver', p_phone: phone(3) });
  const dRows = (await sel(owner, `riders?select=id,status&business_id=eq.${B3}&auth_user_id=eq.${uid(drv)}`)).body || [];
  ok('  removed Driver rejoins -> the SAME row back to pending (no duplicate)', drj.body?.status === 'pending' && dRows.length === 1 && dRows[0].status === 'pending', JSON.stringify(dRows));

  // ---------- 12. a removed Owner must not regain Owner through a Helper / Operator approval
  const o3S = await fresh('op3'); const o3 = o3S.access_token;
  await rpc(o3, 'join_via_invite_link', { p_token: now.operator, p_name: '[TEST] OpLife Operator3', p_phone: phone(9) });
  await rpc(owner, 'decide_team_join_request', { p_request_id: (await pendingReq(owner, B3, uid(o3)))[0]?.id, p_approve: true });
  const coS = await fresh('coowner'); const co = coS.access_token; const coId = uid(co);
  await rpc(co, 'join_via_invite_link', { p_token: now.operator, p_name: '[TEST] OpLife CoOwner', p_phone: phone(0) });
  await rpc(owner, 'decide_team_join_request', { p_request_id: (await pendingReq(owner, B3, coId))[0]?.id, p_approve: true });
  await rpc(owner, 'update_team_member', { p_business_id: B3, p_user_id: coId, p_role: 'owner' });
  const coRm = await rpc(owner, 'update_team_member', { p_business_id: B3, p_user_id: coId, p_status: 'inactive' });
  ok('12 setup: a second Owner was removed by the Owner', coRm.status === 200 && (await roleIn(co, B3)) === undefined, msg(coRm));
  await rpc(co, 'join_via_invite_link', { p_token: now.helper, p_name: '[TEST] OpLife CoOwner', p_phone: phone(0) });
  const coReq = (await pendingReq(owner, B3, coId))[0];
  ok('  removed Owner via the Helper link -> a pending HELPER request', coReq?.role === 'helper', JSON.stringify(coReq));
  const coAp = await rpc(o3, 'decide_team_join_request', { p_request_id: coReq?.id, p_approve: true });
  const coRole = await roleIn(co, B3);
  ok('  an Operator approving that Helper request never restores Owner', coRole !== 'owner', `approve ${coAp.status}, role now ${coRole}`);
  ok('  the account is exactly a Helper (the role of the request)', coRole === 'helper' || refused(coAp), `role ${coRole}`);

  // ---------- 13. session: logout revokes the refresh token
  const lo = await fetch(`${URL_}/auth/v1/logout`, { method: 'POST', headers: H(o3) });
  const after13 = await auth('token?grant_type=refresh_token', { refresh_token: o3S.refresh_token });
  ok('13 logout revokes the refresh token', lo.status < 300 && !after13.access_token, `${lo.status} ${after13.error_code || ''}`);
  ok('  invalid / expired bearer is refused', (await rpc('eyJhbGciOiJIUzI1NiJ9.e30.x', 'get_my_businesses')).status === 401);
} finally {
  // cleanup: the [TEST] business (cascade) and every account this suite created
  if (B3) await fetch(`${URL_}/rest/v1/businesses?id=eq.${B3}`, { method: 'DELETE', headers: SH });
  let left = 0;
  for (const id of created) { const r = await fetch(`${URL_}/auth/v1/admin/users/${id}`, { method: 'DELETE', headers: SH }); if (!r.ok) left++; }
  ok('cleanup: [TEST] business and accounts deleted', !B3 || (await (await fetch(`${URL_}/rest/v1/businesses?select=id&id=eq.${B3}`, { headers: SH })).json()).length === 0 && left === 0, `${left} accounts left`);
}
console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
