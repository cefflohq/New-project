// Helper PWA staging security tests (Security & Access Master §21). Staging only.
// A Helper must not reach Owner/Operator administration, unrelated business
// data, private storage or protected Vendor RPCs; it may use its own
// fulfilment workspace.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 140) : ''}`); if (!c) fails++; };
async function signIn(email, password = PW) {
  const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) });
  const j = await r.json(); if (!j.access_token) throw new Error('signin ' + email); return j.access_token;
}
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function sel(tok, path) { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);

const helper = await signIn(mail('helper')), owner = await signIn(mail('owner'));
const vendorB = await signIn(process.env.STAGING_VENDOR_B_EMAIL, process.env.STAGING_VENDOR_B_PASSWORD);
const hb = (await rpc(helper, 'get_my_businesses')).body;
const B = hb?.[0]?.business_id;
ok('helper resolves to its business with role helper', hb?.[0]?.member_role === 'helper', JSON.stringify(hb));
const otherBiz = (await rpc(vendorB, 'get_my_businesses')).body?.[0]?.business_id;

// own workspace works
const board = await rpc(helper, 'my_fulfilment_tasks', { p_business_id: B });
ok('helper can load its own fulfilment board', board.status === 200, msg(board));
const imgs = board.body?.item_images ? Object.values(board.body.item_images) : [];
ok('board images are public display paths only', imgs.every(p => !/original/i.test(p)), imgs.slice(0, 2).join(','));
const otherBoard = await rpc(helper, 'my_fulfilment_tasks', { p_business_id: otherBiz });
ok("helper cannot load another business's board", otherBoard.status >= 400, msg(otherBoard));
const adv = await rpc(helper, 'advance_preparation', { p_order_id: '00000000-0000-0000-0000-000000000000', p_next: 'ready' });
ok('advance_preparation on an unknown order is refused', adv.status >= 400, msg(adv));

// no direct table reads (customer PII, riders, admin data)
for (const t of ['orders', 'riders', 'businesses', 'business_members', 'products', 'product_media', 'rider_locations', 'delivery_events', 'rider_job_openings', 'rider_job_requests', 'business_hours']) {
  const r = await sel(helper, `${t}?select=*&limit=5`);
  ok(`helper reads no rows from ${t}`, r.status >= 400 || (Array.isArray(r.body) && r.body.length === 0), `${r.status} ${Array.isArray(r.body) ? r.body.length + ' rows' : msg(r)}`);
}

const me = JSON.parse(Buffer.from(helper.split('.')[1], 'base64url').toString()).sub;
const tjr = await sel(helper, 'team_join_requests?select=user_id&limit=50');
ok('helper sees only its own join requests', Array.isArray(tjr.body) && tjr.body.every(r => r.user_id === me), `${tjr.body?.length} rows, all own`);

// protected Vendor RPCs refused
const Z = '00000000-0000-0000-0000-000000000000';
const calls = [
  ['update_business_profile', { p_business_id: B, p_name: 'x' }],
  ['set_business_hours', { p_business_id: B, p_days: [] }],
  ['decide_team_join_request', { p_request_id: Z, p_approve: true }],
  ['update_team_member', { p_business_id: B, p_user_id: Z, p_role: 'operator' }],
  ['approve_pending_rider', { p_rider_id: Z }],
  ['deactivate_rider', { p_rider_id: Z }],
  ['get_invite_link', { p_business_id: B, p_kind: 'operator' }],
  ['get_invite_link', { p_business_id: B, p_kind: 'helper' }],
  ['get_invite_link', { p_business_id: B, p_kind: 'rider' }],
  ['create_zone', { p_business_id: B, p_name: 'x' }],
  ['approve_order', { p_order_id: Z }],
  ['get_storefront', { p_business_id: B }],
  ['set_storefront_published', { p_business_id: B, p_published: false }],
  ['save_job_opening', { p_business_id: B, p_area_label: 'x', p_pickup_time: '07:00', p_days: [1], p_vehicle_type: 'car', p_pay_per_drop: 3, p_drivers_needed: 1 }],
  ['set_business_service_area', { p_business_id: B, p_origin_latitude: 3, p_origin_longitude: 101, p_radius_km: 5 }],
];
for (const [name, body] of calls) {
  const r = await rpc(helper, name, body);
  ok(`helper cannot call ${name}${body.p_kind ? ` (${body.p_kind})` : ''}`, r.status >= 400, msg(r));
}

// storage: private originals denied, public display allowed
const path = '8b643f0b-4034-47c3-bbbf-1eb8bea72532/bccddb94-5bfe-443d-afe5-71e7c7bfdb48/24baab2b-969e-4158-9239-f9c2b0fa5a41';
const orig = await fetch(`${URL_}/storage/v1/object/authenticated/cefflo-product-originals/${path}/original.jpg`, { headers: { apikey: KEY, authorization: `Bearer ${helper}` } });
ok('helper cannot download private original product photos', orig.status >= 400, orig.status);
const ownerOrig = await fetch(`${URL_}/storage/v1/object/authenticated/cefflo-product-originals/${path}/original.jpg`, { headers: { apikey: KEY, authorization: `Bearer ${owner}` } });
ok('owner still can (regression check)', ownerOrig.status === 200, ownerOrig.status);
const disp = await fetch(`${URL_}/storage/v1/object/public/cefflo-product-display/${path}/display.jpg`);
ok('public display photo stays public', disp.status === 200, disp.status);
const list = await fetch(`${URL_}/storage/v1/object/list/cefflo-product-originals`, { method: 'POST', headers: H(helper), body: JSON.stringify({ prefix: '8b643f0b-4034-47c3-bbbf-1eb8bea72532/', limit: 10 }) });
const lj = await list.json().catch(() => []);
ok('helper cannot list private originals', list.status >= 400 || (Array.isArray(lj) && lj.length === 0), `${list.status} ${Array.isArray(lj) ? lj.length : ''}`);

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
