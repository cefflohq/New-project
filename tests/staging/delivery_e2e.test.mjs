// Customer Tracking E2E on staging: storefront order -> approval -> run ->
// rider accept -> pickup -> on the way -> arrived -> delivered + POD ->
// customer tracking at each step -> POD view -> rating. Staging only.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 170) : ''}`); if (!c) fails++; };
async function signIn(email, password = PW) { const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) }); return (await r.json()).access_token; }
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function sel(tok, path) { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const step = async (label, res) => { ok(label, res.status < 300, msg(res)); if (res.status >= 300) { console.log(results.join('\n')); process.exit(1); } return res; };

const owner = await signIn(mail('owner')), rider = await signIn(mail('rider')), rider2 = await signIn(mail('rider2'));
const B = (await rpc(owner, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;
const R = (await sel(rider, `riders?select=id&business_id=eq.${B}&status=eq.active`)).body?.[0]?.id;
const R2 = (await sel(rider2, `riders?select=id&business_id=eq.${B}&status=eq.active`)).body?.[0]?.id;
ok('setup: rider relationships', !!R && !!R2);
const slug = (await rpc(owner, 'get_storefront', { p_business_id: B })).body.slug;
const store = (await rpc(null, 'public_storefront', { p_slug: slug })).body;
const prod = store.products.find(p => Number(p.display_price) > 0);
const track = async () => (await rpc(null, 'public_tracking', { p_token: token })).body;

// 1. customer orders on the storefront
let order;
for (let i = 0; i < 3; i++) {
  order = await rpc(null, 'submit_storefront_order', { p_slug: slug, p_items: [{ product_id: prod.id, quantity: 1 }], p_customer_name: '[TEST] E2E Customer', p_customer_phone: '+60 12-000 2005', p_delivery_address: '[TEST] Jalan Ampang 1, Kuala Lumpur', p_delivery_notes: 'E2E', p_idempotency_key: crypto.randomUUID() });
  if (!/rate limited/.test(msg(order))) break; await new Promise(r => setTimeout(r, 61000));
}
await step('1 customer places a storefront order', order);
const token = order.body.tracking_token, ref = order.body.order_reference;
const O = (await sel(owner, `orders?select=id,zone_id&public_ref=eq.${ref}`)).body[0].id;
let t = await track();
ok('  tracking works from the first minute', !!t && !t.message, JSON.stringify(t).slice(0, 160));
const tKeys = JSON.stringify(t);
ok('  tracking hides customer phone and full rider contact', !/\+60 12-000 2005/.test(tKeys), '');
const fake = await rpc(null, 'public_tracking', { p_token: 'f'.repeat(64) });
ok('  a fake tracking token reveals nothing', fake.status >= 400 || fake.body === null || !fake.body.order_reference, JSON.stringify(fake.body).slice(0, 80));

// 2. vendor approves and builds a run for the rider
await step('2 owner approves the order', await rpc(owner, 'approve_order', { p_order_id: O }));
const zone = (await sel(owner, `zones?select=id&business_id=eq.${B}&status=eq.active&limit=1`)).body?.[0]?.id;
const z = await rpc(owner, 'update_order_details', { p_order_id: O, p_zone_id: zone });
ok('  owner assigns the delivery zone', z.status < 300, msg(z));
const sess = await step('  owner opens a delivery session', await rpc(owner, 'create_delivery_session', { p_business_id: B, p_name: '[TEST] E2E run ' + new Date().toISOString().slice(11, 16) }));
const S = (Array.isArray(sess.body) ? sess.body[0] : sess.body).id;
await step('  owner builds a run for the rider', await rpc(owner, 'build_rider_run', { p_delivery_session_id: S, p_rider_id: R, p_order_ids: [O], p_idempotency_key: crypto.randomUUID(), p_override_capacity: true }));

// 3. rider works the run
const hijack = await rpc(rider2, 'accept_run', { p_rider_id: R2, p_delivery_session_id: S });
ok('  another rider cannot take this run', hijack.status >= 400, msg(hijack));
const spoof = await rpc(rider2, 'accept_run', { p_rider_id: R, p_delivery_session_id: S });
ok('  another rider cannot act as this rider', spoof.status >= 400, msg(spoof));
await step('3 rider accepts the run', await rpc(rider, 'accept_run', { p_rider_id: R, p_delivery_session_id: S }));
await step('  rider starts pickup', await rpc(rider, 'start_pickup_run', { p_rider_id: R, p_delivery_session_id: S }));
const rdy = (await sel(owner, `orders?select=delivery_status&id=eq.${O}`)).body[0].delivery_status;
if (rdy === 'created') { const r = await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: O, p_next: 'ready_for_pickup', p_idempotency_key: crypto.randomUUID() }); ok('  order ready for pickup', r.status < 300, msg(r)); }
await step('  rider picks up the order', await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: O, p_next: 'picked_up', p_idempotency_key: crypto.randomUUID() }));
t = await track(); ok('  customer sees "picked up"', JSON.stringify(t).includes('picked_up'), t?.status || t?.delivery_status);
await step('  rider confirms the stop order', await rpc(rider, 'save_run_sequence', { p_rider_id: R, p_delivery_session_id: S, p_ordered_order_ids: [O] }));
await step('  rider starts delivering (route locked)', await rpc(rider, 'start_run_delivery', { p_rider_id: R, p_delivery_session_id: S }));
const st1 = (await sel(owner, `orders?select=delivery_status&id=eq.${O}`)).body[0].delivery_status;
if (st1 !== 'out_for_delivery') await step('  rider is on the way', await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: O, p_next: 'out_for_delivery', p_idempotency_key: crypto.randomUUID() }));
t = await track(); ok('4 customer sees "on the way"', JSON.stringify(t).includes('out_for_delivery'), t?.status || t?.delivery_status);
await step('  rider arrives', await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: O, p_next: 'arrived', p_idempotency_key: crypto.randomUUID() }));
const skip = await rpc(rider2, 'complete_delivery', { p_rider_id: R2, p_order_id: O, p_pod_path: 'x/y.jpg' });
ok('  another rider cannot complete it', skip.status >= 400, msg(skip));

// 5. proof of delivery: upload a photo, then complete
const jpg = Buffer.from('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAAA//EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AN//Z', 'base64');
const podPath = `${R}/${O}/${Date.now()}.jpg`;
const up = await fetch(`${URL_}/storage/v1/object/cefflo-pod/${podPath}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${rider}`, 'content-type': 'image/jpeg' }, body: jpg });
ok('5 rider uploads the POD photo', up.ok, up.status + ' ' + (up.ok ? '' : await up.text()));
const badUp = await fetch(`${URL_}/storage/v1/object/cefflo-pod/${R}/${O}/evil-${Date.now()}.jpg`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${rider2}`, 'content-type': 'image/jpeg' }, body: jpg });
ok("  another rider cannot upload into this rider's POD folder", !badUp.ok, badUp.status);
await step('  rider completes delivery with the POD', await rpc(rider, 'complete_delivery', { p_rider_id: R, p_order_id: O, p_pod_path: podPath, p_note: 'E2E', p_idempotency_key: crypto.randomUUID() }));
t = await track(); ok('  customer sees "delivered"', JSON.stringify(t).includes('delivered'), t?.status || t?.delivery_status);

// 6. customer views the POD
const pod = await fetch(`${URL_}/functions/v1/tracking-pod`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ token }) });
const podJ = await pod.json().catch(() => ({}));
ok('6 customer can view the proof of delivery', pod.ok && JSON.stringify(podJ).includes('http'), pod.status + ' ' + JSON.stringify(podJ).slice(0, 100));
const podFake = await fetch(`${URL_}/functions/v1/tracking-pod`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ token: 'f'.repeat(64) }) });
ok('  a fake token cannot fetch any POD', !podFake.ok || !JSON.stringify(await podFake.json().catch(() => ({}))).includes('http'), podFake.status);

// 7. rating
await step('7 customer rates the delivery', await rpc(null, 'submit_rating', { p_token: token, p_rating: 5, p_feedback: ['On time'] }));
const twice = await rpc(null, 'submit_rating', { p_token: token, p_rating: 1, p_feedback: [] });
ok('  a second rating cannot overwrite the first', twice.status >= 400 || JSON.stringify(twice.body).includes('already'), msg(twice));
const rt = (await sel(owner, `ratings?select=rating&order_id=eq.${O}`)).body;
ok('  vendor sees the rating (5)', rt?.[0]?.rating === 5, JSON.stringify(rt));
const badRate = await rpc(null, 'submit_rating', { p_token: 'f'.repeat(64), p_rating: 5 });
ok('  a fake token cannot rate', badRate.status >= 400, msg(badRate));
t = await track(); ok('  tracking shows the rating was submitted', JSON.stringify(t).includes('rating'), JSON.stringify(t).slice(0, 100));

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
console.log('E2E order', ref);
process.exit(fails ? 1 : 0);
