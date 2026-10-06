// Helper fulfilment E2E (staging only): a real storefront order -> Owner
// approval -> run for a Driver -> Helper board -> Preparation -> Packing ->
// Sorting -> Ready -> Driver pickup, plus Helper authority / privacy negatives.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 160) : ''}`); if (!c) fails++; };
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function signIn(email, password = PW) { const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) }); return (await r.json()).access_token; }
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function sel(tok, path) { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const step = async (label, res) => { ok(label, res.status < 300, msg(res)); if (res.status >= 300) { console.log(results.join('\n')); process.exit(1); } return res; };

const owner = await signIn(mail('owner')), helper = await signIn(mail('helper')), rider = await signIn(mail('rider2')), operator = await signIn(mail('operator')), outsider = await signIn(mail('outsider'));
const helperY = await signIn('zelix.co00+v1005p0y388121@gmail.com', 'Cf-v1005-P0!Y'); // Helper of this business + Owner elsewhere
const B = (await rpc(owner, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;
const R = (await sel(rider, `riders?select=id&business_id=eq.${B}&status=eq.active`)).body?.[0]?.id;
ok('setup: helper role, driver relationship', (await rpc(helper, 'get_my_businesses')).body?.[0]?.member_role === 'helper' && !!R);
const slug = (await rpc(owner, 'get_storefront', { p_business_id: B })).body.slug;
const prod = (await rpc(null, 'public_storefront', { p_slug: slug })).body.products.find(p => Number(p.display_price) > 0);
const PHONE = '+60 12-000 4' + String(Date.now()).slice(-3), ADDR = '[TEST] Jalan Helper ' + String(Date.now()).slice(-4);
let o;
for (let i = 0; i < 3; i++) { o = await rpc(null, 'submit_storefront_order', { p_slug: slug, p_items: [{ product_id: prod.id, quantity: 2 }], p_customer_name: '[TEST] Helper E2E', p_customer_phone: PHONE, p_delivery_address: ADDR, p_delivery_notes: 'Ring bell', p_idempotency_key: crypto.randomUUID() }); if (!/rate limited/.test(msg(o))) break; await sleep(61000); }
await step('1 customer orders on the storefront', o);
const O = (await sel(owner, `orders?select=id,order_date&public_ref=eq.${o.body.order_reference}`)).body[0];

// before approval: not on the Helper board
let board = (await rpc(helper, 'my_fulfilment_tasks', { p_business_id: B })).body;
const unapprovedOnBoard = (board.tasks || []).some(t => t.order_id === O.id);
results.push(`${unapprovedOnBoard ? 'FINDING' : 'PASS   '}  unapproved storefront order ${unapprovedOnBoard ? 'IS' : 'is not'} on the Helper board (my_fulfilment_tasks has no approved_at filter)`);
const hApprove = await rpc(helper, 'approve_order', { p_order_id: O.id });
ok('  Helper cannot approve orders', hApprove.status >= 400, msg(hApprove));
await step('2 owner approves', await rpc(owner, 'approve_order', { p_order_id: O.id }));
const zone = (await sel(owner, `zones?select=id&business_id=eq.${B}&status=eq.active&limit=1`)).body[0].id;
await rpc(owner, 'update_order_details', { p_order_id: O.id, p_zone_id: zone });
const S = (x => Array.isArray(x) ? x[0] : x)((await step('  owner opens a run', await rpc(owner, 'create_delivery_session', { p_business_id: B, p_name: '[TEST] Helper run ' + new Date().toISOString().slice(11, 16) }))).body).id;
await step('  owner builds the run for the driver', await rpc(owner, 'build_rider_run', { p_delivery_session_id: S, p_rider_id: R, p_order_ids: [O.id], p_idempotency_key: crypto.randomUUID(), p_override_capacity: true }));

// 3. Helper board
board = (await rpc(helper, 'my_fulfilment_tasks', { p_business_id: B })).body;
let task = (board.tasks || []).find(t => t.order_id === O.id);
ok('3 order appears on the Helper board (not started)', task && task.preparation_status === 'not_started' && task.zone_id === zone && task.run_id === S, JSON.stringify(task).slice(0, 160));
ok('  board carries items + name for the label, no customer phone/address', task && Array.isArray(task.items) && !JSON.stringify(board).includes(PHONE) && !JSON.stringify(board).includes(PHONE.replace(/\D/g, '')) && !JSON.stringify(board).includes(ADDR), Object.keys(task || {}).join(','));
ok('  another business\'s helper/owner sees nothing of it', !JSON.stringify((await rpc(outsider, 'my_fulfilment_tasks', { p_business_id: B })).body || '').includes(O.id));

// 4. Preparation -> Packing -> Sorting
await step('4 helper starts preparing', await rpc(helper, 'advance_preparation', { p_order_id: O.id, p_next: 'preparing' }));
await step('  helper marks packed', await rpc(helper, 'advance_preparation', { p_order_id: O.id, p_next: 'packed' }));
// leftovers from earlier staging runs in the same zone/day must be packed too
for (const t of (board.tasks || []).filter(t => t.order_id !== O.id && t.zone_id === zone && ['not_started', 'preparing'].includes(t.preparation_status))) {
  if (t.preparation_status === 'not_started') await rpc(helper, 'advance_preparation', { p_order_id: t.order_id, p_next: 'preparing' });
  await rpc(helper, 'advance_preparation', { p_order_id: t.order_id, p_next: 'packed' });
}
await step('  helper confirms Packing for the zone', await rpc(helper, 'confirm_packing', { p_business_id: B, p_zone_id: zone, p_order_date: O.order_date }));
await step('  helper sorts the order', await rpc(helper, 'advance_preparation', { p_order_id: O.id, p_next: 'sorted' }));
await step('  helper confirms Sorting for the zone + run', await rpc(helper, 'confirm_sorting', { p_business_id: B, p_zone_id: zone, p_delivery_session_id: S, p_order_date: O.order_date }));
board = (await rpc(helper, 'my_fulfilment_tasks', { p_business_id: B })).body;
task = (board.tasks || []).find(t => t.order_id === O.id);
ok('  board: Ready for pickup with the driver handover', task && ['ready', 'sorted'].includes(task.preparation_status) && task.packing_confirmed && task.handover_rider_name, JSON.stringify({ s: task?.preparation_status, p: task?.packing_confirmed, d: task?.handover_rider_name, v: task?.handover_rider_vehicle_plate }));
const ownerSees = (await sel(owner, `delivery_stops?select=preparation_status&order_id=eq.${O.id}`)).body?.[0]?.preparation_status;
ok('  owner sees the same preparation status (one source of truth)', ownerSees === task?.preparation_status, ownerSees);

// 5. Helper must not do Owner / Operator / Driver work
for (const [fn, args] of [
  ['rider_transition', { p_rider_id: R, p_order_id: O.id, p_next: 'picked_up', p_idempotency_key: crypto.randomUUID() }],
  ['build_rider_run', { p_delivery_session_id: S, p_rider_id: R, p_order_ids: [O.id], p_idempotency_key: crypto.randomUUID() }],
  ['update_order_details', { p_order_id: O.id, p_zone_id: zone }],
  ['get_storefront', { p_business_id: B }],
  ['get_invite_link', { p_business_id: B, p_kind: 'helper' }],
  ['approve_pending_rider', { p_rider_id: R }],
]) { const r = await rpc(helper, fn, args); ok(`5 Helper refused: ${fn}`, r.status >= 400, `${r.status} ${msg(r)}`); }
const hOrders = await sel(helper, `orders?select=id,customer_phone,delivery_address&business_id=eq.${B}&limit=5`);
ok('  Helper cannot read orders (phone/address) directly', hOrders.status >= 400 || (Array.isArray(hOrders.body) && hOrders.body.length === 0), JSON.stringify(hOrders.body).slice(0, 80));
const hRiders = await sel(helper, `riders?select=id,phone&business_id=eq.${B}&limit=5`);
ok('  Helper cannot read drivers directly', hRiders.status >= 400 || (Array.isArray(hRiders.body) && hRiders.body.length === 0));
const outAdv = await rpc(outsider, 'advance_preparation', { p_order_id: O.id, p_next: 'ready' });
ok('  outsider cannot advance this order', outAdv.status >= 400, msg(outAdv));
const opAdv = await rpc(operator, 'my_fulfilment_tasks', { p_business_id: B });
ok('  Operator can still use the board (Owner/Operator/Helper)', opAdv.status === 200);
const yBoard = await rpc(helperY, 'my_fulfilment_tasks', { p_business_id: B });
ok('  a Helper who owns another shop still only gets Helper scope here', yBoard.status === 200 && (await rpc(helperY, 'get_storefront', { p_business_id: B })).status >= 400);

// 6. Driver picks up; board shows the handover done
await step('6 driver accepts the run', await rpc(rider, 'accept_run', { p_rider_id: R, p_delivery_session_id: S }));
await step('  driver starts pickup', await rpc(rider, 'start_pickup_run', { p_rider_id: R, p_delivery_session_id: S }));
const st = (await sel(owner, `orders?select=delivery_status&id=eq.${O.id}`)).body[0].delivery_status;
if (st === 'created') await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: O.id, p_next: 'ready_for_pickup', p_idempotency_key: crypto.randomUUID() });
await step('  driver picks up', await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: O.id, p_next: 'picked_up', p_idempotency_key: crypto.randomUUID() }));
board = (await rpc(helper, 'my_fulfilment_tasks', { p_business_id: B })).body;
task = (board.tasks || []).find(t => t.order_id === O.id);
ok('  Helper board shows it picked up (handover done)', task?.picked_up_at || !task, JSON.stringify(task && { p: task.picked_up_at }));
const late = await rpc(helper, 'advance_preparation', { p_order_id: O.id, p_next: 'preparing' });
ok('  preparation cannot be reopened after pickup', late.status >= 400, msg(late));

// cleanup: finish the delivery so the run closes
await rpc(rider, 'save_run_sequence', { p_rider_id: R, p_delivery_session_id: S, p_ordered_order_ids: [O.id] });
await rpc(rider, 'start_run_delivery', { p_rider_id: R, p_delivery_session_id: S });
for (const n of ['out_for_delivery', 'arrived']) await rpc(rider, 'rider_transition', { p_rider_id: R, p_order_id: O.id, p_next: n, p_idempotency_key: crypto.randomUUID() });
const jpg = Buffer.from('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAAA//EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AN//Z', 'base64');
const pod = `${R}/${O.id}/${Date.now()}.jpg`;
await fetch(`${URL_}/storage/v1/object/cefflo-pod/${pod}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${rider}`, 'content-type': 'image/jpeg' }, body: jpg });
await rpc(rider, 'complete_delivery', { p_rider_id: R, p_order_id: O.id, p_pod_path: pod, p_note: 'helper e2e', p_idempotency_key: crypto.randomUUID() });

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
