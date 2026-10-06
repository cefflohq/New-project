// Driver self-edit profile/vehicle + rejoin via invite (staging only).
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 160) : ''}`); if (!c) fails++; };
async function signIn(email, password = PW) { const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) }); return (await r.json()).access_token; }
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function sel(tok, path) { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const uid = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;
const stamp = String(Date.now()).slice(-6);

const owner = await signIn(mail('owner')), operator = await signIn(mail('operator')), rider2 = await signIn(mail('rider2'));
const B = (await rpc(owner, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;
const link = (await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: 'rider' })).body.token;
const email = `zelix.co00+v1005dp${stamp}@gmail.com`;
await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'Cf-v1005-Dp!1', email_confirm: true, user_metadata: { driver_registration: { full_name: '[TEST] DP Driver', phone: `+60 13-6${stamp}`, vehicle_type: 'motorcycle', vehicle_plate: 'DP ' + stamp } } }) });
const drv = await signIn(email, 'Cf-v1005-Dp!1');
await rpc(drv, 'join_via_invite_link', { p_token: link, p_name: '[TEST] DP Driver', p_phone: `+60 13-6${stamp}` });
const row = () => sel(owner, `riders?select=id,name,phone,vehicle_type,vehicle_plate,status&business_id=eq.${B}&auth_user_id=eq.${uid(drv)}`).then(r => r.body?.[0]);
let r = await row();
await rpc(operator, 'approve_pending_rider', { p_rider_id: r.id });
ok('setup: driver joined + approved', (await row())?.status === 'active');

// 1. edit own details
// Founder 2026-10-06: vehicle / plate changes are PAID (RM50) -> refused on
// the free path; name and phone stay self-service.
const paidVeh = await rpc(drv, 'update_my_driver_profile', { p_full_name: '[TEST] DP Driver', p_phone: `+60 13-6${stamp}`, p_vehicle_type: 'car', p_vehicle_plate: 'DP ' + stamp });
ok('1 vehicle-type change without payment is refused', paidVeh.status >= 400 && /requires payment/.test(msg(paidVeh)), msg(paidVeh));
const paidPlate = await rpc(drv, 'update_my_driver_profile', { p_full_name: '[TEST] DP Driver', p_phone: `+60 13-6${stamp}`, p_vehicle_type: 'motorcycle', p_vehicle_plate: 'NEW ' + stamp });
ok('  plate change without payment is refused', paidPlate.status >= 400 && /requires payment/.test(msg(paidPlate)), msg(paidPlate));
ok('  vehicle and plate unchanged', (await row()).vehicle_type === 'motorcycle' && (await row()).vehicle_plate === 'DP ' + stamp);
const up = await rpc(drv, 'update_my_driver_profile', { p_full_name: '[TEST] DP Driver Edited', p_phone: `+60 13-7${stamp}`, p_vehicle_type: 'motorcycle', p_vehicle_plate: 'DP ' + stamp });
r = await row();
ok('  driver updates own name + phone (free)', up.status === 200 && r.name === '[TEST] DP Driver Edited' && r.phone === `+60 13-7${stamp}`, JSON.stringify(r));
const ev = (await sel(owner, `delivery_events?select=event_type&business_id=eq.${B}&event_type=eq.rider.profile_updated&order=created_at.desc&limit=1`)).body;
ok('  the business sees a profile_updated event', ev?.length === 1);
const r2before = (await sel(owner, `riders?select=name,phone,vehicle_type&business_id=eq.${B}&auth_user_id=eq.${uid(rider2)}`)).body?.[0];
ok('  another driver\'s row is untouched', r2before && r2before.name !== '[TEST] DP Driver Edited');

// 2. validation / authority
for (const [label, body] of [['empty name', { p_full_name: ' ', p_phone: `+60 13-7${stamp}`, p_vehicle_type: 'motorcycle', p_vehicle_plate: 'DP ' + stamp }], ['short phone', { p_full_name: 'Ok Name', p_phone: '123', p_vehicle_type: 'motorcycle', p_vehicle_plate: 'DP ' + stamp }], ['long plate', { p_full_name: 'Ok Name', p_phone: `+60 13-7${stamp}`, p_vehicle_type: 'motorcycle', p_vehicle_plate: 'DP ' + stamp.repeat(25) }], ['no vehicle', { p_full_name: 'Ok Name', p_phone: `+60 13-7${stamp}`, p_vehicle_type: null, p_vehicle_plate: 'X' }]]) {
  const x = await rpc(drv, 'update_my_driver_profile', body); ok(`2 refused: ${label}`, x.status >= 400, msg(x));
}
ok('  anonymous refused', (await rpc(null, 'update_my_driver_profile', { p_full_name: 'A B', p_phone: '+60 12 345 6789', p_vehicle_type: 'car', p_vehicle_plate: null })).status >= 400);
const r2phone = (await sel(owner, `riders?select=phone&business_id=eq.${B}&auth_user_id=eq.${uid(rider2)}`)).body?.[0]?.phone;
const clash = await rpc(drv, 'update_my_driver_profile', { p_full_name: '[TEST] DP Driver Edited', p_phone: r2phone, p_vehicle_type: 'motorcycle', p_vehicle_plate: 'DP ' + stamp });
ok('  phone already used by another driver of the business -> refused', clash.status >= 400, msg(clash));

// 3. vehicle change blocked during active work
const slug = (await rpc(owner, 'get_storefront', { p_business_id: B })).body.slug;
const prod = (await rpc(null, 'public_storefront', { p_slug: slug })).body.products.find(p => Number(p.display_price) > 0);
const o = (await rpc(null, 'submit_storefront_order', { p_slug: slug, p_items: [{ product_id: prod.id, quantity: 1 }], p_customer_name: '[TEST] DP', p_customer_phone: '+60 12-000 5' + stamp.slice(-3), p_delivery_address: '[TEST] DP', p_delivery_notes: '', p_idempotency_key: crypto.randomUUID() })).body;
const O = (await sel(owner, `orders?select=id&public_ref=eq.${o.order_reference}`)).body[0].id;
await rpc(owner, 'approve_order', { p_order_id: O });
const zone = (await sel(owner, `zones?select=id&business_id=eq.${B}&status=eq.active&limit=1`)).body[0].id;
await rpc(owner, 'update_order_details', { p_order_id: O, p_zone_id: zone });
const S = (x => Array.isArray(x) ? x[0] : x)((await rpc(owner, 'create_delivery_session', { p_business_id: B, p_name: '[TEST] DP run' })).body).id;
const built = await rpc(owner, 'build_rider_run', { p_delivery_session_id: S, p_rider_id: r.id, p_order_ids: [O], p_idempotency_key: crypto.randomUUID(), p_override_capacity: true });
ok('setup: the driver has an active run', built.status === 200, msg(built));
const busyVeh = await rpc(drv, 'update_my_driver_profile', { p_full_name: '[TEST] DP Driver Edited', p_phone: `+60 13-7${stamp}`, p_vehicle_type: 'van', p_vehicle_plate: 'DPC ' + stamp });
ok('3 vehicle change refused during active work', busyVeh.status >= 400, msg(busyVeh));
const busyName = await rpc(drv, 'update_my_driver_profile', { p_full_name: '[TEST] DP Busy Rename', p_phone: `+60 13-7${stamp}`, p_vehicle_type: 'motorcycle', p_vehicle_plate: 'DP ' + stamp });
ok('  name / plate still editable during work (same vehicle)', busyName.status === 200 && (await row()).name === '[TEST] DP Busy Rename', msg(busyName));
// finish that run through the real Driver flow (keeps staging clean)
await rpc(drv, 'accept_run', { p_rider_id: r.id, p_delivery_session_id: S });
await rpc(drv, 'start_pickup_run', { p_rider_id: r.id, p_delivery_session_id: S });
if ((await sel(owner, `orders?select=delivery_status&id=eq.${O}`)).body[0].delivery_status === 'created') await rpc(drv, 'rider_transition', { p_rider_id: r.id, p_order_id: O, p_next: 'ready_for_pickup', p_idempotency_key: crypto.randomUUID() });
await rpc(drv, 'rider_transition', { p_rider_id: r.id, p_order_id: O, p_next: 'picked_up', p_idempotency_key: crypto.randomUUID() });
await rpc(drv, 'save_run_sequence', { p_rider_id: r.id, p_delivery_session_id: S, p_ordered_order_ids: [O] });
await rpc(drv, 'start_run_delivery', { p_rider_id: r.id, p_delivery_session_id: S });
for (const n of ['out_for_delivery', 'arrived']) await rpc(drv, 'rider_transition', { p_rider_id: r.id, p_order_id: O, p_next: n, p_idempotency_key: crypto.randomUUID() });
const jpg = Buffer.from('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAAA//EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AN//Z', 'base64');
const pod = `${r.id}/${O}/${Date.now()}.jpg`;
await fetch(`${URL_}/storage/v1/object/cefflo-pod/${pod}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${drv}`, 'content-type': 'image/jpeg' }, body: jpg });
const done = await rpc(drv, 'complete_delivery', { p_rider_id: r.id, p_order_id: O, p_pod_path: pod, p_note: 'dp', p_idempotency_key: crypto.randomUUID() });
ok('  the driver finishes the run', done.status === 200, msg(done));
const freeVeh = await rpc(drv, 'update_my_driver_profile', { p_full_name: '[TEST] DP Busy Rename', p_phone: `+60 13-7${stamp}`, p_vehicle_type: 'van', p_vehicle_plate: 'DPV ' + stamp });
ok('  after the run, a vehicle change still needs payment', freeVeh.status >= 400 && /requires payment/.test(msg(freeVeh)), msg(freeVeh));

// 4. rejoin via invite after removal (a separate driver that never ran)
const email2 = `zelix.co00+v1005dq${stamp}@gmail.com`;
await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' }, body: JSON.stringify({ email: email2, password: 'Cf-v1005-Dp!1', email_confirm: true, user_metadata: { driver_registration: { full_name: '[TEST] DQ Driver', phone: `+60 13-8${stamp}`, vehicle_type: 'van', vehicle_plate: 'DQ ' + stamp } } }) });
const d2 = await signIn(email2, 'Cf-v1005-Dp!1');
await rpc(d2, 'join_via_invite_link', { p_token: link, p_name: '[TEST] DQ Driver', p_phone: `+60 13-8${stamp}` });
const row2 = () => sel(owner, `riders?select=id,status,vehicle_type&business_id=eq.${B}&auth_user_id=eq.${uid(d2)}`).then(q => q.body?.[0]);
let q = await row2();
await rpc(operator, 'approve_pending_rider', { p_rider_id: q.id });
const rm = await rpc(owner, 'deactivate_rider', { p_rider_id: q.id });
ok('setup: owner removes a driver with no runs', rm.status === 200 && (await row2()).status === 'inactive', msg(rm));
const rj = await rpc(d2, 'join_via_invite_link', { p_token: link, p_name: '[TEST] DQ Driver Back', p_phone: `+60 13-8${stamp}` });
q = await row2();
ok('4 removed driver rejoins via the invite -> pending (no access yet)', rj.status === 200 && rj.body?.status === 'pending' && q.status === 'pending', JSON.stringify(rj.body));
ok('  rejoin keeps the registered vehicle (van)', q.vehicle_type === 'van', q.vehicle_type);
ok('  still exactly one driver row', (await sel(owner, `riders?select=id&business_id=eq.${B}&auth_user_id=eq.${uid(d2)}`)).body.length === 1);
const again = await rpc(operator, 'approve_pending_rider', { p_rider_id: q.id });
ok('  approval again makes it active', again.status === 200 && (await row2()).status === 'active', msg(again));
await rpc(owner, 'deactivate_rider', { p_rider_id: q.id });
const findingRm = await rpc(owner, 'deactivate_rider', { p_rider_id: r.id });
results.push(`${findingRm.status === 200 ? 'PASS   ' : 'FINDING'}  owner ${findingRm.status === 200 ? 'can' : 'CANNOT'} remove a driver whose runs are all delivered (${msg(findingRm)})`);

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
