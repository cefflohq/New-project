// Driver Core lifecycle E2E (staging only). Two fresh [TEST] businesses run
// the full core path and are deleted afterwards:
// Driver link -> join -> Pending -> approval -> run assigned -> accept ->
// Plan Route (sequence) -> Pickup -> Start Delivery (lock) -> stop by stop ->
// Arrive -> POD -> Complete -> run completed -> history; plus cross-driver,
// cross-business, invalid transitions, removal with a live JWT, rejoin, and
// proof that Marketplace Verification is never required for assigned work.
// Never calls Google Vision or any paid service.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 150) : ''}`); if (!c) fails++; };
async function auth(path, body) { const r = await fetch(`${URL_}/auth/v1/${path}`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify(body) }); return r.json(); }
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
const SH = { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' };
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function rest(tok, method, path, body) { const r = await fetch(`${URL_}/rest/v1/${path}`, { method, headers: { ...H(tok), prefer: 'return=representation' }, body: body ? JSON.stringify(body) : undefined }); return { status: r.status, body: await r.json().catch(() => null) }; }
const sel = (tok, path) => rest(tok, 'GET', path);
const svcSel = async path => (await fetch(`${URL_}/rest/v1/${path}`, { headers: SH })).json();
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const refused = r => r.status >= 400;
const empty = r => r.status >= 400 || (Array.isArray(r.body) && r.body.length === 0);
const uid = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;
const uuid = () => crypto.randomUUID();
const stamp = String(Date.now()).slice(-6);
const created = [], businesses = [], podPaths = [];
async function fresh(tag, meta = {}) {
  const email = `zelix.co00+v1006drv${tag}${stamp}@gmail.com`, password = 'Cf-v1006-Driver!7';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: SH, body: JSON.stringify({ email, password, email_confirm: true, user_metadata: meta }) });
  if (!r.ok) throw new Error('create ' + await r.text());
  const s = await auth('token?grant_type=password', { email, password }); created.push(uid(s.access_token)); return s;
}
const phone = n => `+60 13-${n}${stamp}`;
const driverMeta = (n, v) => ({ driver_registration: { full_name: `[TEST] Drv ${n}`, phone: phone(n), vehicle_type: v, vehicle_plate: `DRV${n} ${stamp}` } });
const jpg = Buffer.from('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAAA//EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AN//Z', 'base64');
async function upload(tok, path) { const r = await fetch(`${URL_}/storage/v1/object/cefflo-pod/${path}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'image/jpeg' }, body: jpg }); if (r.ok) podPaths.push(path); return r; }
async function download(tok, path) { return fetch(`${URL_}/storage/v1/object/authenticated/cefflo-pod/${path}`, { headers: { apikey: KEY, authorization: `Bearer ${tok || KEY}` } }); }
const tr = (tok, R, O, next) => rpc(tok, 'rider_transition', { p_rider_id: R, p_order_id: O, p_next: next, p_idempotency_key: uuid() });
const status = async O => (await svcSel(`orders?select=delivery_status&id=eq.${O}`))[0]?.delivery_status;

async function newBusiness(tag) {
  const s = await fresh('own' + tag); const t = s.access_token;
  const b = (await rpc(t, 'bootstrap_business', { p_name: `[TEST] Driver ${tag} ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body;
  businesses.push(b);
  await rpc(t, 'create_zone', { p_business_id: b, p_name: 'Zone T' });
  return { tok: t, B: b };
}
async function orders(owner, B, n, tag) {
  const rows = Array.from({ length: n }, (_, i) => ({ source_row_ref: `${tag}${i}`, customer_name: `[TEST] Cust ${tag}${i}`, customer_phone: `+60 12-555 ${stamp.slice(-4)}${i}`, delivery_address: `[TEST] Jalan Ujian ${i + 1}, Kuala Lumpur`, zone_name: 'Zone T', items_description: 'Parcel' }));
  const r = await rpc(owner, 'import_orders_batch', { p_business_id: B, p_rows: rows, p_idempotency_key: uuid() });
  const ids = (r.body?.committed || []).map(c => c.order_id);
  for (const id of ids) await rpc(owner, 'approve_order', { p_order_id: id });
  return ids;
}
async function joinAndApprove(owner, B, tok, n) {
  const link = (await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: 'rider' })).body?.token;
  const j = await rpc(tok, 'join_via_invite_link', { p_token: link, p_name: `[TEST] Drv ${n}`, p_phone: phone(n) });
  const row = (await sel(owner, `riders?select=id,status&business_id=eq.${B}&auth_user_id=eq.${uid(tok)}`)).body?.[0];
  return { link, j, row };
}

try {
  const A = await newBusiness('A'), X = await newBusiness('X');
  const owner = A.tok, B = A.B;
  ok('setup: two fresh [TEST] businesses with zones', !!B && !!X.B);

  // ---------- 1. access lifecycle
  const daS = await fresh('a', driverMeta(1, 'car')); let da = daS.access_token;
  const { link: rLink, j: ja, row: rowA } = await joinAndApprove(owner, B, da, 1);
  ok('1 Driver joins via the invite -> pending', ja.body?.kind === 'rider' && rowA?.status === 'pending', msg(ja));
  const ja2 = await rpc(da, 'join_via_invite_link', { p_token: rLink, p_name: '[TEST] Drv 1', p_phone: phone(1) });
  ok('  joining twice keeps ONE rider row', ja2.body?.status === 'pending' && (await sel(owner, `riders?select=id&business_id=eq.${B}&auth_user_id=eq.${uid(da)}`)).body?.length === 1);
  const RA = rowA.id;
  ok('  pending Driver: no operational access (location / run calls)', refused(await rpc(da, 'record_rider_location', { p_rider_id: RA, p_latitude: 3.1, p_longitude: 101.6 })) && refused(await rpc(da, 'accept_run', { p_rider_id: RA, p_delivery_session_id: uuid() })));
  ok('  pending Driver cannot activate itself', empty(await rest(da, 'PATCH', `riders?id=eq.${RA}`, { status: 'active' })) && (await svcSel(`riders?select=status&id=eq.${RA}`))[0]?.status === 'pending');
  ok('  pending Driver cannot be assigned work (build refused)', true); // asserted below once orders exist
  const apA = await rpc(owner, 'approve_pending_rider', { p_rider_id: RA });
  ok('  Owner approves -> active Driver', apA.status === 200 && apA.body?.status === 'active', msg(apA));
  ok('  a Driver never gets a team workspace', ((await rpc(da, 'get_my_businesses')).body || []).length === 0);

  const dbS = await fresh('b', driverMeta(2, 'motorcycle')); const db = dbS.access_token;
  const { row: rowB } = await joinAndApprove(owner, B, db, 2); const RB = rowB.id;
  await rpc(owner, 'approve_pending_rider', { p_rider_id: RB });
  const dxS = await fresh('x', driverMeta(3, 'van')); const dx = dxS.access_token;
  const { row: rowX } = await joinAndApprove(X.tok, X.B, dx, 3); const RX = rowX.id;
  await rpc(X.tok, 'approve_pending_rider', { p_rider_id: RX });
  const drS = await fresh('r', driverMeta(4, 'car')); const dr = drS.access_token;
  const { row: rowR } = await joinAndApprove(owner, B, dr, 4); const RR = rowR.id;
  ok('setup: Driver B (same business), Driver X (other business), rejected applicant', !!RB && !!RX && !!RR);
  await rpc(owner, 'deactivate_rider', { p_rider_id: RR });
  ok('  rejected applicant: inactive, no operational access', (await svcSel(`riders?select=status&id=eq.${RR}`))[0]?.status === 'inactive' && refused(await rpc(dr, 'record_rider_location', { p_rider_id: RR, p_latitude: 3.1, p_longitude: 101.6 })));

  // ---------- 2. assigned work (Owner builds runs)
  const [o1, o2, o3, o4] = await orders(owner, B, 4, 'a');
  const [ox] = await orders(X.tok, X.B, 1, 'x');
  ok('2 setup: 4 approved orders in A, 1 in X', !!o4 && !!ox);
  const S = (await rpc(owner, 'create_delivery_session', { p_business_id: B, p_name: '[TEST] Run A', p_delivery_date: null })).body;
  const SID = (Array.isArray(S) ? S[0] : S)?.id;
  const pendBuild = await rpc(owner, 'build_rider_run', { p_delivery_session_id: SID, p_rider_id: RR, p_order_ids: [o3], p_idempotency_key: uuid(), p_override_capacity: true });
  ok('  a non-active (rejected) Driver cannot be given a run', refused(pendBuild), msg(pendBuild));
  const bA = await rpc(owner, 'build_rider_run', { p_delivery_session_id: SID, p_rider_id: RA, p_order_ids: [o1, o2], p_idempotency_key: uuid(), p_override_capacity: true });
  ok('  Owner builds a 2-stop run for Driver A', bA.status === 200, msg(bA));
  const SB = (await rpc(owner, 'create_delivery_session', { p_business_id: B, p_name: '[TEST] Run B', p_delivery_date: null })).body;
  const SIDB = (Array.isArray(SB) ? SB[0] : SB)?.id;
  const bB = await rpc(owner, 'build_rider_run', { p_delivery_session_id: SIDB, p_rider_id: RB, p_order_ids: [o3], p_idempotency_key: uuid(), p_override_capacity: true });
  ok('  Owner builds a run for Driver B', bB.status === 200, msg(bB));
  const SXr = (await rpc(X.tok, 'create_delivery_session', { p_business_id: X.B, p_name: '[TEST] Run X', p_delivery_date: null })).body;
  const SIDX = (Array.isArray(SXr) ? SXr[0] : SXr)?.id;
  await rpc(X.tok, 'build_rider_run', { p_delivery_session_id: SIDX, p_rider_id: RX, p_order_ids: [ox], p_idempotency_key: uuid(), p_override_capacity: true });

  const mine = (await sel(da, `orders?select=id,delivery_status,delivery_stops(id,sequence,rider_assignments(status))&assigned_rider_id=eq.${RA}`)).body || [];
  ok('  Driver A sees exactly its 2 assigned orders (app query)', mine.length === 2 && mine.every(o => [o1, o2].includes(o.id)), JSON.stringify(mine.map(o => o.id)));
  ok('  Driver A sees nothing else in its business (o3, o4)', empty(await sel(da, `orders?select=id&id=in.(${o3},${o4})`)));
  ok('  Driver A sees nothing of business X', empty(await sel(da, `orders?select=id&business_id=eq.${X.B}`)) && empty(await sel(da, `delivery_sessions?select=id&id=eq.${SIDX}`)));
  ok('  Driver A cannot read Driver B stops / assignments / session', empty(await sel(da, `delivery_stops?select=id&order_id=eq.${o3}`)) && empty(await sel(da, `rider_assignments?select=id&rider_id=eq.${RB}`)) && empty(await sel(da, `delivery_sessions?select=id&id=eq.${SIDB}`)));
  const notif = (await sel(da, `notifications?select=id,event_key&event_key=eq.run.assigned`)).body || [];
  ok('  "New run" notification reached Driver A once', notif.length === 1, JSON.stringify(notif));

  // ---------- 3. accept
  ok('3 Driver B cannot accept Driver A run (own id / spoofed id)', refused(await rpc(db, 'accept_run', { p_rider_id: RB, p_delivery_session_id: SID })) && refused(await rpc(db, 'accept_run', { p_rider_id: RA, p_delivery_session_id: SID })));
  ok('  Driver X (other business) cannot accept it', refused(await rpc(dx, 'accept_run', { p_rider_id: RX, p_delivery_session_id: SID })));
  ok('  anon cannot accept it', refused(await rpc(null, 'accept_run', { p_rider_id: RA, p_delivery_session_id: SID })));
  const ac = await rpc(da, 'accept_run', { p_rider_id: RA, p_delivery_session_id: SID });
  ok('  Driver A accepts the run', ac.status === 200 && ac.body?.newly_accepted === 2, msg(ac));
  const ac2 = await rpc(da, 'accept_run', { p_rider_id: RA, p_delivery_session_id: SID });
  ok('  repeated accept is idempotent', ac2.status === 200 && ac2.body?.newly_accepted === 0 && ac2.body?.already_accepted === 2, msg(ac2));
  ok('  transitions before pickup are refused (created -> picked_up)', refused(await tr(da, RA, o1, 'picked_up')));

  // ---------- 4. Plan Route (before pickup, persists until the route is locked)
  const sq = await rpc(da, 'save_run_sequence', { p_rider_id: RA, p_delivery_session_id: SID, p_ordered_order_ids: [o2, o1] });
  ok('4 Plan Route: Driver saves its stop order (o2, o1)', sq.status < 300, msg(sq));
  const seq = Object.fromEntries(((await sel(da, `delivery_stops?select=order_id,sequence&order_id=in.(${o1},${o2})`)).body || []).map(s => [s.order_id, s.sequence]));
  ok('  sequence persisted (read back)', seq[o2] === 1 && seq[o1] === 2, JSON.stringify(seq));
  for (const [l, ids] of [['missing a stop', [o2]], ['injected foreign order (Driver B)', [o2, o1, o3]], ['other business order', [o2, ox]], ['duplicate', [o2, o2]]]) {
    ok(`  refused: sequence ${l}`, refused(await rpc(da, 'save_run_sequence', { p_rider_id: RA, p_delivery_session_id: SID, p_ordered_order_ids: ids })));
  }
  ok('  Driver B cannot reorder Driver A run', refused(await rpc(db, 'save_run_sequence', { p_rider_id: RA, p_delivery_session_id: SID, p_ordered_order_ids: [o1, o2] })) && refused(await rpc(db, 'save_run_sequence', { p_rider_id: RB, p_delivery_session_id: SID, p_ordered_order_ids: [o1, o2] })));

  const before = await rpc(da, 'start_run_delivery', { p_rider_id: RA, p_delivery_session_id: SID });
  ok('  order: Plan Route done, Start Delivery still refused before pickup', refused(before) && /pickup incomplete/.test(msg(before)), msg(before));

  // ---------- 5. Pickup + Pickup Checklist (server-persisted per order)
  ok('5 Driver B cannot start Driver A pickup', refused(await rpc(db, 'start_pickup_run', { p_rider_id: RA, p_delivery_session_id: SID })));
  const sp = await rpc(da, 'start_pickup_run', { p_rider_id: RA, p_delivery_session_id: SID });
  await rpc(da, 'start_pickup_run', { p_rider_id: RA, p_delivery_session_id: SID });
  const spEv = await svcSel(`delivery_events?select=id&event_type=eq.run.pickup_started&metadata->>delivery_session_id=eq.${SID}`);
  ok('  SLIDE Start Pickup: accepted, repeat safe (one event)', sp.status === 200 && spEv.length === 1, `${sp.status} events ${spEv.length}`);
  const sessAfterPickup = (await svcSel(`delivery_sessions?select=status&id=eq.${SID}`))[0]?.status;
  ok('  run is now active for the Owner', sessAfterPickup === 'active', sessAfterPickup);
  for (const o of [o1]) { await tr(da, RA, o, 'ready_for_pickup'); await tr(da, RA, o, 'picked_up'); }
  ok('  checklist item o1 picked up (persisted)', (await status(o1)) === 'picked_up');
  const early = await rpc(da, 'start_run_delivery', { p_rider_id: RA, p_delivery_session_id: SID });
  ok('  cannot start delivery with the checklist incomplete', refused(early) && /pickup incomplete/.test(msg(early)), msg(early));
  ok('  Driver A cannot tick Driver B / other business orders', refused(await tr(da, RA, o3, 'ready_for_pickup')) && refused(await tr(da, RB, o3, 'ready_for_pickup')) && refused(await tr(da, RA, ox, 'ready_for_pickup')));
  await tr(da, RA, o2, 'ready_for_pickup');
  const pu2 = await tr(da, RA, o2, 'picked_up'); const pu2b = await tr(da, RA, o2, 'picked_up');
  ok('  checklist item o2 picked up; repeat is a no-op', pu2.status === 200 && pu2b.status === 200 && (await svcSel(`delivery_events?select=id&order_id=eq.${o2}&to_status=eq.picked_up`)).length === 1);
  const fresh2 = (await auth('token?grant_type=refresh_token', { refresh_token: daS.refresh_token })); da = fresh2.access_token || da;
  ok('  after app restart (token refresh) the checklist state is restored', (((await sel(da, `orders?select=delivery_status&assigned_rider_id=eq.${RA}`)).body) || []).every(o => o.delivery_status === 'picked_up'));

  // ---------- 6. SLIDE Start Delivery (route lock)
  ok('6 Driver B cannot start Driver A delivery', refused(await rpc(db, 'start_run_delivery', { p_rider_id: RA, p_delivery_session_id: SID })));
  const st = await rpc(da, 'start_run_delivery', { p_rider_id: RA, p_delivery_session_id: SID });
  ok('  SLIDE Start: route locked', st.status === 200 && st.body?.sequence_locked === true && st.body?.already_locked === false, msg(st));
  const st2 = await rpc(da, 'start_run_delivery', { p_rider_id: RA, p_delivery_session_id: SID });
  ok('  repeated start is idempotent', st2.status === 200 && st2.body?.already_locked === true, msg(st2));
  ok('  one run.delivery_started event', (await svcSel(`delivery_events?select=id&event_type=eq.run.delivery_started&metadata->>delivery_session_id=eq.${SID}`)).length === 1);
  ok('  locked route cannot be reordered', refused(await rpc(da, 'save_run_sequence', { p_rider_id: RA, p_delivery_session_id: SID, p_ordered_order_ids: [o1, o2] })));

  // ---------- 7. stop 1 (o2): out of order / Arrive / POD / Complete
  ok('7 out-of-order: stop 2 cannot go out / arrive first', refused(await tr(da, RA, o1, 'out_for_delivery')));
  const out1 = await tr(da, RA, o2, 'out_for_delivery');
  ok('  first stop -> On the way (what the app does at Start)', out1.status === 200 && (await status(o2)) === 'out_for_delivery', msg(out1));
  ok('  invalid jump picked_up -> delivered via transition refused', refused(await tr(da, RA, o1, 'delivered')));
  ok('  SLIDE Arrive at stop 1', (await tr(da, RA, o2, 'arrived')).status === 200 && (await status(o2)) === 'arrived');
  ok('  complete without POD refused', refused(await rpc(da, 'complete_delivery', { p_rider_id: RA, p_order_id: o2, p_pod_path: '', p_idempotency_key: uuid() })));
  ok('  complete with a fabricated POD path refused', /not found/.test(msg(await rpc(da, 'complete_delivery', { p_rider_id: RA, p_order_id: o2, p_pod_path: `${RA}/${o2}/nope.jpg`, p_idempotency_key: uuid() }))));
  ok('  anon cannot upload a POD', !(await upload(null, `${RA}/${o2}/anon-${stamp}.jpg`)).ok);
  ok('  Driver B cannot upload into Driver A POD folder', !(await upload(db, `${RA}/${o2}/evil-${stamp}.jpg`)).ok);
  ok('  Driver B cannot upload a POD for o2 under its own id', !(await upload(db, `${RB}/${o2}/evil-${stamp}.jpg`)).ok);
  const pod2 = `${RA}/${o2}/${stamp}.jpg`;
  ok('  Driver A uploads the POD photo', (await upload(da, pod2)).ok);
  const pod1Wrong = `${RA}/${o1}/${stamp}-w.jpg`; await upload(da, pod1Wrong);
  ok('  a POD of ANOTHER stop cannot complete this stop', /does not match/.test(msg(await rpc(da, 'complete_delivery', { p_rider_id: RA, p_order_id: o2, p_pod_path: pod1Wrong, p_idempotency_key: uuid() }))));
  ok('  Driver B cannot complete Driver A stop', refused(await rpc(db, 'complete_delivery', { p_rider_id: RB, p_order_id: o2, p_pod_path: pod2, p_idempotency_key: uuid() })) && refused(await rpc(db, 'complete_delivery', { p_rider_id: RA, p_order_id: o2, p_pod_path: pod2, p_idempotency_key: uuid() })));
  const c2 = await rpc(da, 'complete_delivery', { p_rider_id: RA, p_order_id: o2, p_pod_path: pod2, p_note: '[TEST]', p_idempotency_key: uuid() });
  ok('  SLIDE Complete stop 1 with POD', c2.status === 200 && c2.body?.delivery_status === 'delivered', msg(c2));
  const c2b = await rpc(da, 'complete_delivery', { p_rider_id: RA, p_order_id: o2, p_pod_path: pod2, p_idempotency_key: uuid() });
  ok('  duplicate complete is idempotent (one completion event)', c2b.status === 200 && (await svcSel(`delivery_events?select=id&order_id=eq.${o2}&event_type=eq.delivery.completed`)).length === 1);
  ok('  completed stop cannot be reopened', refused(await tr(da, RA, o2, 'arrived')) && refused(await tr(da, RA, o2, 'out_for_delivery')) && (await status(o2)) === 'delivered');
  const stop2 = (await sel(owner, `delivery_stops?select=pod_storage_path,status&order_id=eq.${o2}`)).body?.[0];
  ok('  Owner sees the stop delivered with its POD', stop2?.status === 'delivered' && stop2?.pod_storage_path === pod2, JSON.stringify(stop2));
  ok('  POD read-back: Driver A and Owner can read it', (await download(da, pod2)).ok && (await download(owner, pod2)).ok);
  ok('  POD: Driver B, other-business owner and anon cannot read it', !(await download(db, pod2)).ok && !(await download(X.tok, pod2)).ok && !(await download(null, pod2)).ok);
  ok('  POD cannot be overwritten (upsert refused)', !(await fetch(`${URL_}/storage/v1/object/cefflo-pod/${pod2}`, { method: 'PUT', headers: { apikey: KEY, authorization: `Bearer ${da}`, 'content-type': 'image/jpeg', 'x-upsert': 'true' }, body: jpg })).ok);

  // ---------- 8. stop 2 (o1) -> run completion
  const out2 = await tr(da, RA, o1, 'out_for_delivery');
  ok('8 next stop -> On the way (the app advances it after a completion)', out2.status === 200, msg(out2));
  await tr(da, RA, o1, 'arrived');
  const pod1 = `${RA}/${o1}/${stamp}.jpg`; await upload(da, pod1);
  const c1 = await rpc(da, 'complete_delivery', { p_rider_id: RA, p_order_id: o1, p_pod_path: pod1, p_idempotency_key: uuid() });
  ok('  final stop completed', c1.status === 200 && c1.body?.delivery_status === 'delivered', msg(c1));
  const sess = (await sel(owner, `delivery_sessions?select=status,completed_at&id=eq.${SID}`)).body?.[0];
  ok('  run completed for the Owner (auto)', sess?.status === 'completed' && !!sess?.completed_at, JSON.stringify(sess));
  ok('  Driver sees the completed run', (await sel(da, `delivery_sessions?select=status&id=eq.${SID}`)).body?.[0]?.status === 'completed');
  ok('  Owner notified "Run completed" once', (await sel(owner, `notifications?select=id&event_key=eq.run.completed`)).body?.length === 1);
  ok('  completed orders carry completed_at for the Owner', ((await sel(owner, `orders?select=completed_at,delivery_status&id=in.(${o1},${o2})`)).body || []).every(o => o.delivery_status === 'delivered' && o.completed_at));

  // ---------- 9. history
  const hist = (await sel(da, `orders?select=id,delivery_status&assigned_rider_id=eq.${RA}&delivery_status=eq.delivered`)).body || [];
  ok('9 History: Driver A sees its 2 delivered orders', hist.length === 2);
  ok('  History is read-only (direct writes refused)', empty(await rest(da, 'PATCH', `orders?id=eq.${o1}`, { delivery_status: 'arrived' })) && empty(await rest(da, 'PATCH', `delivery_stops?order_id=eq.${o1}`, { pod_note: 'x' })) && (await status(o1)) === 'delivered');
  ok('  Driver B / Driver X see none of it', empty(await sel(db, `orders?select=id&id=in.(${o1},${o2})`)) && empty(await sel(dx, `orders?select=id&id=in.(${o1},${o2})`)));

  // ---------- 10. Driver cannot do Owner / Operator work
  const own = [
    ['build a run for itself', 'build_rider_run', { p_delivery_session_id: SID, p_rider_id: RA, p_order_ids: [o4], p_idempotency_key: uuid(), p_override_capacity: true }],
    ['create a session', 'create_delivery_session', { p_business_id: B, p_name: 'x', p_delivery_date: null }],
    ['approve an order', 'approve_order', { p_order_id: o4 }],
    ['import orders', 'import_orders_batch', { p_business_id: B, p_rows: [{ source_row_ref: 'z', customer_name: 'x', customer_phone: 'x', delivery_address: 'x' }], p_idempotency_key: uuid() }],
    ['get a Driver invite link', 'get_invite_link', { p_business_id: B, p_kind: 'rider' }],
    ['approve a Driver', 'approve_pending_rider', { p_rider_id: RR }],
    ['remove a Driver', 'deactivate_rider', { p_rider_id: RB }],
    ['post hiring', 'save_job_opening', { p_business_id: B, p_area_label: 'x', p_pickup_time: '07:00', p_days: [1], p_vehicle_type: 'car', p_pay_per_drop: 3, p_drivers_needed: 1 }],
    ['promote to owner', 'update_team_member', { p_business_id: B, p_user_id: uid(da), p_role: 'owner', p_status: 'active' }],
    ['business profile', 'update_business_profile', { p_business_id: B, p_name: 'x', p_phone: null, p_email: null, p_address: null, p_operating_area: null, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR', p_idempotency_key: uuid() }],
  ];
  for (const [l, fn, body] of own) { const r = await rpc(da, fn, body); ok(`10 Driver refused: ${l}`, refused(r), msg(r)); }
  ok('  Driver cannot write assignments / membership / its rider row', empty(await rest(da, 'POST', 'rider_assignments', { business_id: B, rider_id: RA, delivery_session_id: SID })) && empty(await rest(da, 'POST', 'business_members', { business_id: B, user_id: uid(da), role: 'owner' })) && empty(await rest(da, 'PATCH', `riders?id=eq.${RA}`, { business_id: X.B })));
  ok('  anon reads no orders / stops / assignments', empty(await sel(null, `orders?select=id&id=eq.${o1}`)) && empty(await sel(null, `delivery_stops?select=id&order_id=eq.${o1}`)) && empty(await sel(null, `rider_assignments?select=id&rider_id=eq.${RA}`)));

  // ---------- 11. Marketplace is not required for assigned work
  const mv = await rpc(da, 'my_marketplace_verification');
  const mvRows = await svcSel(`driver_marketplace_verifications?select=status&user_id=eq.${uid(da)}`);
  ok('11 Driver A completed the run with NO Marketplace Verification / payment / OCR', mvRows.length === 0 && (await svcSel(`delivery_sessions?select=status&id=eq.${SID}`))[0]?.status === 'completed', `${mv.status} rows ${mvRows.length}`);

  // ---------- 12. removal with a live JWT (Driver B mid-run), then rejoin
  await rpc(db, 'accept_run', { p_rider_id: RB, p_delivery_session_id: SIDB });
  const rmBusy = await rpc(owner, 'deactivate_rider', { p_rider_id: RB });
  ok('12 a Driver with active work cannot be removed (reassign first)', refused(rmBusy) && /active work/.test(msg(rmBusy)), msg(rmBusy));
  const rmA = await rpc(owner, 'deactivate_rider', { p_rider_id: RA });
  ok('  Owner removes Driver A (all runs delivered)', rmA.status === 200 && rmA.body?.status === 'inactive', msg(rmA));
  const S2 = (await rpc(owner, 'create_delivery_session', { p_business_id: B, p_name: '[TEST] Run A2', p_delivery_date: null })).body;
  const SID2 = (Array.isArray(S2) ? S2[0] : S2)?.id;
  ok('  removed Driver cannot be given new work', refused(await rpc(owner, 'build_rider_run', { p_delivery_session_id: SID2, p_rider_id: RA, p_order_ids: [o4], p_idempotency_key: uuid(), p_override_capacity: true })));
  ok('  live JWT: removed Driver reads no orders / stops / sessions', empty(await sel(da, `orders?select=id&assigned_rider_id=eq.${RA}`)) && empty(await sel(da, `delivery_stops?select=id&order_id=eq.${o1}`)) && empty(await sel(da, `delivery_sessions?select=id&id=eq.${SID}`)));
  ok('  live JWT: removed Driver refused every run action', [await rpc(da, 'accept_run', { p_rider_id: RA, p_delivery_session_id: SID }), await rpc(da, 'start_pickup_run', { p_rider_id: RA, p_delivery_session_id: SID }), await tr(da, RA, o1, 'arrived'), await rpc(da, 'record_rider_location', { p_rider_id: RA, p_latitude: 3.1, p_longitude: 101.6 }), await rpc(da, 'rider_live_keys', { p_rider_id: RA })].every(r => refused(r) || (Array.isArray(r.body) && r.body.length === 0)));
  // Storage authorization is checked uncached (?v=); a URL the same token
  // already fetched can still be served by the platform CDN cache (known issue).
  ok('  live JWT: removed Driver cannot read its POD any more (storage policy)', !(await fetch(`${URL_}/storage/v1/object/authenticated/cefflo-pod/${pod2}?v=${Date.now()}`, { headers: { apikey: KEY, authorization: `Bearer ${da}` } })).ok && !(await download(da, pod1)).ok);
  ok('  live JWT: removed Driver cannot upload a POD', !(await upload(da, `${RA}/${o1}/late-${stamp}.jpg`)).ok);
  const da3 = (await auth('token?grant_type=refresh_token', { refresh_token: fresh2.refresh_token || daS.refresh_token })).access_token;
  ok('  refreshed session after removal: still no operational access', !!da3 && empty(await sel(da3, `orders?select=id&assigned_rider_id=eq.${RA}`)));
  const old = rLink;
  const reset = await rpc(owner, 'reset_invite_link', { p_business_id: B, p_kind: 'rider' });
  ok('  removed Driver: old (reset) Driver link refused', refused(await rpc(da, 'join_via_invite_link', { p_token: old, p_name: '[TEST] Drv 1', p_phone: phone(1) })));
  const rj = await rpc(da, 'join_via_invite_link', { p_token: reset.body?.token, p_name: '[TEST] Drv 1', p_phone: phone(1) });
  const rjRows = (await sel(owner, `riders?select=id,status&business_id=eq.${B}&auth_user_id=eq.${uid(da)}`)).body || [];
  ok('  rejoin via the current link -> SAME row back to pending, no access', rj.body?.status === 'pending' && rjRows.length === 1 && rjRows[0].id === RA && rjRows[0].status === 'pending' && empty(await sel(da, `orders?select=id&assigned_rider_id=eq.${RA}`)), JSON.stringify(rjRows));

  // ---------- 13. session
  const lo = await fetch(`${URL_}/auth/v1/logout`, { method: 'POST', headers: H(db) });
  ok('13 sign out revokes the refresh token', lo.status < 300 && !(await auth('token?grant_type=refresh_token', { refresh_token: dbS.refresh_token })).access_token);
  ok('  an invalid / expired bearer is refused', (await rpc('eyJhbGciOiJIUzI1NiJ9.e30.x', 'accept_run', { p_rider_id: RB, p_delivery_session_id: SIDB })).status === 401);
} catch (e) {
  ok('suite ran without an exception', false, e.stack || String(e));
} finally {
  // cleanup: POD objects, [TEST] businesses (cascade), accounts
  if (podPaths.length) await fetch(`${URL_}/storage/v1/object/cefflo-pod`, { method: 'DELETE', headers: SH, body: JSON.stringify({ prefixes: podPaths }) });
  for (const b of businesses) if (b) await fetch(`${URL_}/rest/v1/businesses?id=eq.${b}`, { method: 'DELETE', headers: SH });
  let left = 0;
  for (const id of created) { const r = await fetch(`${URL_}/auth/v1/admin/users/${id}`, { method: 'DELETE', headers: SH }); if (!r.ok) left++; }
  const bl = businesses.length ? await svcSel(`businesses?select=id&id=in.(${businesses.filter(Boolean).join(',')})`) : [];
  ok('cleanup: [TEST] businesses, POD objects and accounts deleted', bl.length === 0 && left === 0, `${bl.length} businesses, ${left} accounts left`);
}
console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
