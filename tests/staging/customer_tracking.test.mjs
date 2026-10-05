// Customer Tracking production-readiness suite (staging only): real
// storefront orders -> one multi-drop run -> real Driver actions, with the
// anonymous tracking contract checked at every step plus negative security
// tests (token tampering, cross-customer, anonymous reads/mutations,
// delivered location cutoff, rate limit).
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 170) : ''}`); if (!c) fails++; };
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function signIn(email) { const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password: PW }) }); return (await r.json()).access_token; }
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function sel(tok, path) { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const step = async (label, res) => { ok(label, res.status < 300, msg(res)); if (res.status >= 300) { console.log(results.join('\n')); process.exit(1); } return res; };
// Customer-safe keys only: anything else in the anonymous response is a leak.
const ALLOWED = new Set(['order_id', 'order_number', 'store_name', 'status', 'eta', 'rider_name', 'completed_at', 'picked_up_at', 'pod_available', 'rating_submitted', 'rider_location', 'live', 'items', 'pickup_address', 'business_phone', 'rider_vehicle', 'rider_plate']);
// Must never reach the browser (raw payload text is checked, not the UI).
const NOTE = 'CTNOTE-' + Date.now(), PODNOTE = 'CTPOD-' + Date.now();
const noPII = (s, extra = []) => { const j = JSON.stringify(s); return ![NOTE, PODNOTE, '000 3101', '0003101', '000 3102', '0003102', 'Jalan A 1', 'Jalan B 2', 'display_price', 'product_id', 'price', ...extra].some(x => x && j.includes(x)); };
const track = async tok => (await rpc(null, 'public_tracking', { p_token: tok })).body;

const owner = await signIn(mail('owner')), rider = await signIn(mail('rider2'));
const B = (await rpc(owner, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;
const R = (await sel(rider, `riders?select=id&business_id=eq.${B}&status=eq.active`)).body?.[0]?.id;
ok('setup: driver relationship', !!R);
const slug = (await rpc(owner, 'get_storefront', { p_business_id: B })).body.slug;
const prod = (await rpc(null, 'public_storefront', { p_slug: slug })).body.products.find(p => Number(p.display_price) > 0);

async function place(name, phone, address) {
  for (let i = 0; i < 3; i++) {
    const o = await rpc(null, 'submit_storefront_order', { p_slug: slug, p_items: [{ product_id: prod.id, quantity: 1 }], p_customer_name: name, p_customer_phone: phone, p_delivery_address: address, p_delivery_notes: NOTE, p_idempotency_key: crypto.randomUUID() });
    if (!/rate limited/.test(msg(o))) return o;
    await sleep(61000);
  }
}
// 1. two customers order (they will share one multi-drop run)
const a = await step('1 customer A orders (storefront)', await place('[TEST] CT Customer A', '+60 12-000 3101', '[TEST] Jalan A 1, KL'));
const b = await step('  customer B orders (storefront)', await place('[TEST] CT Customer B', '+60 12-000 3102', '[TEST] Jalan B 2, KL'));
const tA = a.body.tracking_token, tB = b.body.tracking_token;
const OA = (await sel(owner, `orders?select=id&public_ref=eq.${a.body.order_reference}`)).body[0].id;
const OB = (await sel(owner, `orders?select=id&public_ref=eq.${b.body.order_reference}`)).body[0].id;

let s = await track(tA);
ok('  A: anonymous link opens A\'s order', s && s.order_id === a.body.order_reference && s.status === 'created', JSON.stringify(s).slice(0, 120));
ok('  A: response holds customer-safe keys only', s && Object.keys(s).every(k => ALLOWED.has(k)), Object.keys(s || {}).join(','));
ok('  A: no live location before pickup', s && !('rider_location' in s) && !('live' in s));
const biz = (await sel(owner, `businesses?select=address,phone&id=eq.${B}`)).body[0];
const drv = (await sel(owner, `riders?select=phone,vehicle_type,vehicle_plate&id=eq.${R}`)).body[0];
ok('  items: name + quantity only', Array.isArray(s.items) && s.items.length >= 1 && s.items.every(i => Object.keys(i).sort().join() === 'name,qty' && i.qty === 1), JSON.stringify(s.items));
ok('  pickup_address is this business\'s address', s.pickup_address === biz.address, s.pickup_address);
ok('  business_phone is this business\'s phone', s.business_phone === biz.phone, s.business_phone);
ok('  no vehicle/plate before pickup', !('rider_vehicle' in s) && !('rider_plate' in s));
ok('  excluded PII absent from raw payload (note, customer phone/address, prices)', noPII(s), JSON.stringify(s).slice(0, 120));

// 2. negative: tampering / unknown / cross-customer
const fake = await rpc(null, 'public_tracking', { p_token: 'f'.repeat(64) });
ok('2 unknown token reveals nothing', fake.body === null || fake.status >= 400, JSON.stringify(fake.body).slice(0, 60));
const flipped = tA.slice(0, -1) + (tA.slice(-1) === 'a' ? 'b' : 'a');
const mod = await rpc(null, 'public_tracking', { p_token: flipped });
ok('  modified token (1 char) reveals nothing', mod.body === null || mod.status >= 400, JSON.stringify(mod.body).slice(0, 60));
const empty = await rpc(null, 'public_tracking', { p_token: '' });
ok('  empty token reveals nothing', empty.body === null || empty.status >= 400);
const refAsToken = await rpc(null, 'public_tracking', { p_token: a.body.order_reference });
ok('  order reference is not a credential', refAsToken.body === null || refAsToken.status >= 400);
s = await track(tB);
ok('  B\'s link returns B only (no A data)', s && s.order_id === b.body.order_reference && !JSON.stringify(s).includes(a.body.order_reference) && !/Customer A|Jalan A 1/.test(JSON.stringify(s)));

// 3. anonymous direct table access and mutations are refused
for (const t of ['orders', 'tracking_tokens', 'rider_locations', 'delivery_stops', 'riders', 'rider_assignments', 'delivery_events', 'ratings']) {
  const r = await sel(null, `${t}?select=*&limit=5`);
  ok(`3 anon cannot read ${t}`, r.status >= 400 || (Array.isArray(r.body) && r.body.length === 0), `${r.status} ${JSON.stringify(r.body).slice(0, 60)}`);
}
const patch = await fetch(`${URL_}/rest/v1/orders?id=eq.${OA}`, { method: 'PATCH', headers: { ...H(null), prefer: 'return=representation' }, body: JSON.stringify({ delivery_status: 'delivered' }) });
const patchBody = await patch.json().catch(() => null);
ok('  anon cannot update an order', patch.status >= 400 || (Array.isArray(patchBody) && patchBody.length === 0), patch.status);
for (const [fn, args] of [
  ['rider_transition', { p_rider_id: R, p_order_id: OA, p_next: 'picked_up', p_idempotency_key: crypto.randomUUID() }],
  ['complete_delivery', { p_rider_id: R, p_order_id: OA, p_pod_path: 'x/y.jpg' }],
  ['record_rider_location', { p_rider_id: R, p_latitude: 3.1, p_longitude: 101.6, p_accuracy: 5, p_heading: null, p_speed: null }],
  ['approve_order', { p_order_id: OA }],
  ['rotate_tracking_token', { p_order_id: OA }],
]) { const r = await rpc(null, fn, args); ok(`  anon cannot call ${fn}`, r.status >= 400, `${r.status} ${msg(r)}`); }

// 4. real operational flow: approve, one run with both orders
for (const O of [OA, OB]) await step('4 owner approves an order', await rpc(owner, 'approve_order', { p_order_id: O }));
const zone = (await sel(owner, `zones?select=id&business_id=eq.${B}&status=eq.active&limit=1`)).body?.[0]?.id;
for (const O of [OA, OB]) await rpc(owner, 'update_order_details', { p_order_id: O, p_zone_id: zone });
const sess = await step('  owner opens a delivery session', await rpc(owner, 'create_delivery_session', { p_business_id: B, p_name: '[TEST] CT run ' + new Date().toISOString().slice(11, 16) }));
const S = (Array.isArray(sess.body) ? sess.body[0] : sess.body).id;
await step('  owner builds ONE run with A and B (multi-drop)', await rpc(owner, 'build_rider_run', { p_delivery_session_id: S, p_rider_id: R, p_order_ids: [OA, OB], p_idempotency_key: crypto.randomUUID(), p_override_capacity: true }));
await step('  driver accepts the run', await rpc(rider, 'accept_run', { p_rider_id: R, p_delivery_session_id: S }));
await step('  driver starts pickup', await rpc(rider, 'start_pickup_run', { p_rider_id: R, p_delivery_session_id: S }));
for (const O of [OA, OB]) {
  const st = (await sel(owner, `orders?select=delivery_status&id=eq.${O}`)).body[0].delivery_status;
  if (st === 'created') await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: O, p_next: 'ready_for_pickup', p_idempotency_key: crypto.randomUUID() });
  await step('5 driver picks up an order', await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: O, p_next: 'picked_up', p_idempotency_key: crypto.randomUUID() }));
}
s = await track(tA);
const ev = (await sel(owner, `delivery_events?select=created_at&order_id=eq.${OA}&to_status=eq.picked_up&order=created_at.asc&limit=1`)).body?.[0]?.created_at;
ok('  A shows Pickup (picked_up)', s?.status === 'picked_up', s?.status);
ok('  vehicle + plate of the assigned driver while in progress', s.rider_vehicle === drv.vehicle_type && s.rider_plate === drv.vehicle_plate && !!drv.vehicle_plate, `${s.rider_vehicle} ${s.rider_plate}`);
ok('  in progress: excluded PII absent from raw payload', noPII(s), JSON.stringify(s).slice(0, 120));
ok('  driver personal phone absent from raw payload', !JSON.stringify(s).includes(drv.phone) && !JSON.stringify(s).includes(drv.phone.replace(/\D/g, '')), drv.phone ? 'checked' : 'no phone');
ok('  picked_up_at is the real pickup event time', !!ev && s?.picked_up_at && Math.abs(new Date(s.picked_up_at) - new Date(ev)) < 1000, `${s?.picked_up_at} vs ${ev}`);

// 6. live location: driver reports a point through the real RPC
await sleep(1500);
const loc = await rpc(rider, 'record_rider_location', { p_rider_id: R, p_latitude: 3.1478123, p_longitude: 101.6953456, p_accuracy: 8, p_heading: null, p_speed: null });
ok('6 driver records a live location', loc.status < 300, msg(loc));
s = await track(tA);
ok('  A gets the driver\'s latest point (rounded to 4 dp)', s?.rider_location && s.rider_location.lat === 3.1478 && s.rider_location.lng === 101.6953, JSON.stringify(s?.rider_location));
ok('  A gets a live hint channel only (no coordinates in it)', s?.live && /^trk:/.test(s.live.topic) && !('lat' in s.live));
ok('  multi-drop: A sees no other stop/customer/count', !('stops_ahead' in s) && !JSON.stringify(s).includes(b.body.order_reference) && !/Customer B|Jalan B 2|stops/.test(JSON.stringify(s)) && !JSON.stringify(s.eta || {}).includes('stops_ahead'));
ok('  multi-drop: still customer-safe keys only', Object.keys(s).every(k => ALLOWED.has(k)), Object.keys(s).join(','));

// 7. on the way, then A delivered while B continues
await step('7 driver confirms the stop order', await rpc(rider, 'save_run_sequence', { p_rider_id: R, p_delivery_session_id: S, p_ordered_order_ids: [OA, OB] }));
await step('  driver starts delivering', await rpc(rider, 'start_run_delivery', { p_rider_id: R, p_delivery_session_id: S }));
for (const O of [OA, OB]) {
  const st = (await sel(owner, `orders?select=delivery_status&id=eq.${O}`)).body[0].delivery_status;
  if (st !== 'out_for_delivery') await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: O, p_next: 'out_for_delivery', p_idempotency_key: crypto.randomUUID() });
}
s = await track(tA);
ok('  A shows On the way (out_for_delivery)', s?.status === 'out_for_delivery', s?.status);
await step('  driver arrives at A', await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: OA, p_next: 'arrived', p_idempotency_key: crypto.randomUUID() }));
const jpg = Buffer.from('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAAA//EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AN//Z', 'base64');
const podPath = `${R}/${OA}/${Date.now()}.jpg`;
await fetch(`${URL_}/storage/v1/object/cefflo-pod/${podPath}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${rider}`, 'content-type': 'image/jpeg' }, body: jpg });
await step('8 driver completes A with POD', await rpc(rider, 'complete_delivery', { p_rider_id: R, p_order_id: OA, p_pod_path: podPath, p_note: PODNOTE, p_idempotency_key: crypto.randomUUID() }));
await sleep(11000); // the 10 s location write floor
const loc2 = await rpc(rider, 'record_rider_location', { p_rider_id: R, p_latitude: 3.15, p_longitude: 101.7, p_accuracy: 8, p_heading: null, p_speed: null });
ok('  driver keeps reporting location for B', loc2.status < 300, msg(loc2));
s = await track(tA);
const done = (await sel(owner, `orders?select=completed_at&id=eq.${OA}`)).body[0].completed_at;
ok('  A shows Delivered', s?.status === 'delivered', s?.status);
ok('  delivered time is the real completion time', s?.completed_at && done && new Date(s.completed_at).getTime() === new Date(done).getTime(), `${s?.completed_at} vs ${done}`);
ok('  delivered: NO driver location and NO live channel for A', s && !('rider_location' in s) && !('live' in s), Object.keys(s || {}).join(','));
ok('  delivered: vehicle + plate no longer returned', !('rider_vehicle' in s) && !('rider_plate' in s));
ok('  delivered: POD note and delivery address absent from raw payload', noPII(s), JSON.stringify(s).slice(0, 120));
const sB = await track(tB);
ok('  B (still in progress) keeps its live location', ['picked_up', 'out_for_delivery', 'arrived'].includes(sB?.status) && !!sB.rider_location, JSON.stringify(sB).slice(0, 170));
await sleep(1000);
s = await track(tA);
ok('  reopening A: Delivered persists, still no location', s?.status === 'delivered' && !('rider_location' in s) && !('live' in s));

// 9. rate limit: 10 requests / 60 s per link
let limited = false, n = 0;
for (let i = 0; i < 12 && !limited; i++) { const r = await rpc(null, 'public_tracking', { p_token: tB }); n++; limited = r.status >= 400 && /rate limited/.test(msg(r)); }
ok('9 rate limit stops repeated refreshes (<=12 calls)', limited, `limited after ${n} calls`);
const rl = await rpc(null, 'public_tracking', { p_token: tB });
ok('  rate-limited reply exposes no data', rl.status >= 400 && !JSON.stringify(rl.body).includes(b.body.order_reference), JSON.stringify(rl.body).slice(0, 80));

// finish B so the run closes cleanly (not part of A's checks)
await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: OB, p_next: 'arrived', p_idempotency_key: crypto.randomUUID() });
const podB = `${R}/${OB}/${Date.now()}.jpg`;
await fetch(`${URL_}/storage/v1/object/cefflo-pod/${podB}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${rider}`, 'content-type': 'image/jpeg' }, body: jpg });
await rpc(rider, 'complete_delivery', { p_rider_id: R, p_order_id: OB, p_pod_path: podB, p_note: PODNOTE, p_idempotency_key: crypto.randomUUID() });

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
console.log('CT orders', a.body.order_reference, b.body.order_reference, 'tokenA', tA);
process.exit(fails ? 1 : 0);
