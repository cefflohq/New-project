// Helper PWA lifecycle + security (staging only): invite -> join -> pending
// -> Owner approval -> workspace -> removal; role from the server token
// only; cross-business and Owner/Operator denial; fulfilment transitions,
// idempotency, concurrency, stale actions; business-local "today".
// Uses unapproved storefront orders (on the board by Founder decision) so
// cleanup can decline them; test zone set inactive; test users deleted.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 160) : ''}`); if (!c) fails++; };
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function signIn(email, password = PW) { const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) }); return (await r.json()).access_token; }
const H = tok => String(tok).startsWith('sb_secret') ? { apikey: tok, 'content-type': 'application/json' } : { apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' };
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function sel(tok, path) { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const uid = t => JSON.parse(Buffer.from(t.split('.')[1], 'base64url').toString()).sub;
const stamp = String(Date.now()).slice(-6);
const Z = '00000000-0000-0000-0000-000000000000';

const owner = await signIn(mail('owner')), operator = await signIn(mail('operator')), helper = await signIn(mail('helper'));
const vendorB = await signIn(process.env.STAGING_VENDOR_B_EMAIL, process.env.STAGING_VENDOR_B_PASSWORD);
const B = (await rpc(owner, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;
const BB = (await rpc(vendorB, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;

// ---------------------------------------------------------------- access
const email = `zelix.co00+v1005hlp${stamp}@gmail.com`;
await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: { apikey: SVC, 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'Cf-v1005-Hlp!1', email_confirm: true }) });
const h = await signIn(email, 'Cf-v1005-Hlp!1');
ok('1 unauthenticated: board refused', (await rpc(null, 'my_fulfilment_tasks', { p_business_id: B })).status >= 400);
ok('  unauthenticated: advance_preparation refused', (await rpc(null, 'advance_preparation', { p_order_id: Z, p_next: 'preparing' })).status >= 400);
ok('  signed-in stranger (no membership): board refused', (await rpc(h, 'my_fulfilment_tasks', { p_business_id: B })).status >= 400);

const helperLink = (await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: 'helper' })).body.token;
const operatorLink = (await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: 'operator' })).body.token;
const tamper = await rpc(h, 'join_via_invite_link', { p_token: helperLink, p_name: '[TEST] Helper L', p_phone: `+60 11-5${stamp}`, p_role: 'owner' });
ok('8 extra "role" parameter is not accepted (role comes only from the token)', tamper.status >= 400, msg(tamper));
const j = await rpc(h, 'join_via_invite_link', { p_token: helperLink, p_name: '[TEST] Helper L', p_phone: `+60 11-5${stamp}` });
ok('  join with the Helper link -> pending', j.status === 200 && j.body?.status === 'pending', msg(j));
const req = (await sel(h, 'team_join_requests?select=id,role,status,business_id')).body;
ok('  the server recorded role = helper for this business (from the token)', req?.length === 1 && req[0].role === 'helper' && req[0].business_id === B, JSON.stringify(req));
ok('2 pending Helper: no workspace (no business, board refused)', (await rpc(h, 'get_my_businesses')).body?.length === 0 && (await rpc(h, 'my_fulfilment_tasks', { p_business_id: B })).status >= 400);
ok('  pending Helper cannot mutate', (await rpc(h, 'confirm_packing', { p_business_id: B, p_zone_id: null, p_order_date: '2026-01-01' })).status >= 400);
ok('  pending Helper cannot approve itself', (await rpc(h, 'decide_team_join_request', { p_request_id: req[0].id, p_approve: true })).status >= 400);

// reset link: old token unusable
const reset = await rpc(owner, 'reset_invite_link', { p_business_id: B, p_kind: 'helper' });
const newHelperLink = reset.body?.token;
const e2 = `zelix.co00+v1005hlq${stamp}@gmail.com`;
await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: { apikey: SVC, 'content-type': 'application/json' }, body: JSON.stringify({ email: e2, password: 'Cf-v1005-Hlp!1', email_confirm: true }) });
const h2 = await signIn(e2, 'Cf-v1005-Hlp!1');
const old = await rpc(h2, 'join_via_invite_link', { p_token: helperLink, p_name: '[TEST] Helper Q', p_phone: `+60 11-6${stamp}` });
ok('10 reset invite: the old Helper token cannot create a membership', reset.status === 200 && old.status >= 400 && (await sel(h2, 'team_join_requests?select=id')).body?.length === 0, msg(old));
ok('  invalid token refused', (await rpc(h2, 'join_via_invite_link', { p_token: 'f'.repeat(48), p_name: 'x', p_phone: '+60 11-1111111' })).status >= 400);

// approve
const ap = await rpc(owner, 'decide_team_join_request', { p_request_id: req[0].id, p_approve: true });
const mine = (await rpc(h, 'get_my_businesses')).body;
ok('3 Owner approves -> Helper of exactly this business', ap.status === 200 && mine?.length === 1 && mine[0].business_id === B && mine[0].member_role === 'helper', JSON.stringify(mine));
const board0 = await rpc(h, 'my_fulfilment_tasks', { p_business_id: B });
ok('  approved Helper loads its board', board0.status === 200 && Array.isArray(board0.body?.tasks), msg(board0));
ok('  Helper link token never grants Operator: role stays helper', mine[0].member_role === 'helper' && (await rpc(h, 'get_invite_link', { p_business_id: B, p_kind: 'operator' })).status >= 400);

// 15. business-local today
const kl = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kuala_Lumpur' }).format(new Date());
const tz = (await sel(SVC, `businesses?select=timezone&id=eq.${B}`)).body?.[0]?.timezone;
const expectedToday = new Intl.DateTimeFormat('en-CA', { timeZone: tz || 'Asia/Kuala_Lumpur' }).format(new Date());
ok('15 board.business_today = today in the business timezone (not UTC / device)', board0.body?.business_today === expectedToday, `${board0.body?.business_today} vs ${expectedToday} (${tz}); KL ${kl}`);

// --------------------------------------------------------- isolation (4-7)
ok('4 Helper A cannot read Business B board', (await rpc(h, 'my_fulfilment_tasks', { p_business_id: BB })).status >= 400);
const orderB = (await sel(SVC, `orders?select=id&business_id=eq.${BB}&delivery_status=eq.created&limit=1`)).body?.[0]?.id;
ok('5 Helper A cannot mutate a Business B order', !orderB || (await rpc(h, 'advance_preparation', { p_order_id: orderB, p_next: 'preparing' })).status >= 400, orderB ? '' : 'no B order to try');
ok('  Helper A cannot confirm packing/sorting for Business B', (await rpc(h, 'confirm_packing', { p_business_id: BB, p_zone_id: null, p_order_date: kl })).status >= 400 && (await rpc(h, 'confirm_sorting', { p_business_id: BB, p_zone_id: null, p_delivery_session_id: null, p_order_date: kl })).status >= 400);
for (const t of ['orders', 'customers', 'riders', 'delivery_sessions', 'products', 'business_members', 'team_join_requests', 'zones']) {
  const r = await sel(h, `${t}?select=*&limit=5`);
  const rows = Array.isArray(r.body) ? r.body : [];
  ok(`  Helper reads no business rows from ${t}`, r.status >= 400 || rows.length === 0 || (t === 'team_join_requests' && rows.every(x => x.user_id === uid(h))), `${r.status} ${rows.length}`);
}
for (const [name, body] of [
  ['update_business_profile', { p_business_id: B, p_name: 'x' }],
  ['update_team_member', { p_business_id: B, p_user_id: uid(helper), p_status: 'inactive' }],
  ['reset_invite_link', { p_business_id: B, p_kind: 'helper' }],
  ['get_invite_link', { p_business_id: B, p_kind: 'helper' }],
  ['decide_team_join_request', { p_request_id: Z, p_approve: true }],
  ['set_business_hours', { p_business_id: B, p_days: [] }],
]) ok(`6 Owner-only refused: ${name}`, (await rpc(h, name, body)).status >= 400);
for (const [name, body] of [
  ['approve_order', { p_order_id: Z }],
  ['update_order_details', { p_order_id: Z, p_zone_id: null }],
  ['create_delivery_session', { p_business_id: B, p_name: 'x' }],
  ['build_rider_run', { p_delivery_session_id: Z, p_rider_id: Z, p_order_ids: [Z], p_idempotency_key: crypto.randomUUID() }],
  ['create_zone', { p_business_id: B, p_name: 'x' }],
  ['approve_pending_rider', { p_rider_id: Z }],
  ['get_storefront', { p_business_id: B }],
]) ok(`7 Operator-only refused: ${name}`, (await rpc(h, name, body)).status >= 400);

// ------------------------------------------------------- fulfilment (11-14)
const slug = (await rpc(owner, 'get_storefront', { p_business_id: B })).body.slug;
const prod = (await rpc(null, 'public_storefront', { p_slug: slug })).body.products.find(p => Number(p.display_price) > 0);
async function order() {
  let o;
  for (let i = 0; i < 3; i++) { o = await rpc(null, 'submit_storefront_order', { p_slug: slug, p_items: [{ product_id: prod.id, quantity: 1 }], p_customer_name: '[TEST] Helper L', p_customer_phone: '+60 12-000 7' + String(Date.now()).slice(-3), p_delivery_address: '[TEST] Jalan Lifecycle', p_idempotency_key: crypto.randomUUID() }); if (!/rate limited/.test(msg(o))) break; await sleep(61000); }
  return (await sel(owner, `orders?select=id,order_date,zone_id&public_ref=eq.${o.body.order_reference}`)).body[0];
}
const O1 = await order();
ok('15 a new order is stamped with the business-local date = business_today', O1.order_date === expectedToday, `${O1.order_date} vs ${expectedToday}`);
// its own zone so packing/sorting groups contain only test orders
const zn = await rpc(owner, 'create_zone', { p_business_id: B, p_name: `[TEST] Helper L ${stamp}` });
const ZID = (x => Array.isArray(x) ? x[0] : x)(zn.body)?.id;
await rpc(owner, 'update_order_details', { p_order_id: O1.id, p_zone_id: ZID });
const tb = (await rpc(h, 'my_fulfilment_tasks', { p_business_id: B })).body.tasks.find(t => t.order_id === O1.id);
ok('16 order appears on the Helper board under today, in its zone', tb?.order_date === expectedToday && tb?.zone_id === ZID && tb?.preparation_status === 'not_started', JSON.stringify(tb).slice(0, 120));

ok('12 invalid transition not_started -> packed refused', (await rpc(h, 'advance_preparation', { p_order_id: O1.id, p_next: 'packed' })).status >= 400);
ok('  invalid: ready only via sorting confirmation', (await rpc(h, 'advance_preparation', { p_order_id: O1.id, p_next: 'ready' })).status >= 400);
ok('  invalid: sorting before packing confirmed refused', (await rpc(h, 'advance_preparation', { p_order_id: O1.id, p_next: 'sorted' })).status >= 400);
// 14. concurrent: Helper + Operator both start preparing at once
const [c1, c2] = await Promise.all([rpc(h, 'advance_preparation', { p_order_id: O1.id, p_next: 'preparing' }), rpc(operator, 'advance_preparation', { p_order_id: O1.id, p_next: 'preparing' })]);
const evs = (await sel(SVC, `delivery_events?select=id&order_id=eq.${O1.id}&event_type=eq.preparation.status_changed&to_status=eq.preparing`)).body;
ok('14 concurrent identical actions: both succeed, ONE state change recorded', c1.status === 200 && c2.status === 200 && evs?.length === 1, `${c1.status}/${c2.status} events=${evs?.length}`);
ok('11 valid: preparing -> packed', (await rpc(h, 'advance_preparation', { p_order_id: O1.id, p_next: 'packed' })).status === 200);
const dup = await rpc(h, 'advance_preparation', { p_order_id: O1.id, p_next: 'packed' });
const packedEvents = (await sel(SVC, `delivery_events?select=id&order_id=eq.${O1.id}&to_status=eq.packed`)).body;
ok('13 duplicate "packed" is idempotent (no second state change)', dup.status === 200 && packedEvents?.length === 1, `events=${packedEvents?.length}`);
ok('  stale client sending an older step (preparing) cannot move it back', (await rpc(h, 'advance_preparation', { p_order_id: O1.id, p_next: 'preparing' })).status >= 400);
const cp = await rpc(h, 'confirm_packing', { p_business_id: B, p_zone_id: ZID, p_order_date: expectedToday });
ok('11 confirm packing for the zone/day', cp.status === 200 && cp.body?.orders === 1, msg(cp));
ok('  sorted after packing confirmed', (await rpc(h, 'advance_preparation', { p_order_id: O1.id, p_next: 'sorted' })).status === 200);
const cs = await rpc(h, 'confirm_sorting', { p_business_id: B, p_zone_id: ZID, p_delivery_session_id: null, p_order_date: expectedToday });
ok('  confirm sorting -> ready', cs.status === 200 && cs.body?.newly_ready === 1, msg(cs));
const cs2 = await rpc(h, 'confirm_sorting', { p_business_id: B, p_zone_id: ZID, p_delivery_session_id: null, p_order_date: expectedToday });
ok('13 repeating confirm sorting changes nothing', cs2.status === 200 && cs2.body?.newly_ready === 0, msg(cs2));
// incomplete group refused
const O2 = await order();
await rpc(owner, 'update_order_details', { p_order_id: O2.id, p_zone_id: ZID });
ok('12 confirm packing with an unpacked order in the group refused', (await rpc(h, 'confirm_packing', { p_business_id: B, p_zone_id: ZID, p_order_date: expectedToday })).status >= 400);
const reread = (await rpc(h, 'my_fulfilment_tasks', { p_business_id: B })).body.tasks;
ok('16 reload returns persisted server truth (ready + not_started)', reread.find(t => t.order_id === O1.id)?.preparation_status === 'ready' && reread.find(t => t.order_id === O2.id)?.preparation_status === 'not_started');
ok('  Owner sees the same state (one source of truth)', (await rpc(owner, 'my_fulfilment_tasks', { p_business_id: B })).body.tasks.find(t => t.order_id === O1.id)?.preparation_status === 'ready');

// ----------------------------------------------------------- removal (9)
const rm = await rpc(owner, 'update_team_member', { p_business_id: B, p_user_id: uid(h), p_status: 'inactive' });
ok('9 Owner removes the Helper', rm.status === 200, msg(rm));
ok('  removed Helper: no business, board refused, mutation refused', (await rpc(h, 'get_my_businesses')).body?.length === 0 && (await rpc(h, 'my_fulfilment_tasks', { p_business_id: B })).status >= 400 && (await rpc(h, 'advance_preparation', { p_order_id: O2.id, p_next: 'preparing' })).status >= 400);
const back = await rpc(h, 'join_via_invite_link', { p_token: newHelperLink, p_name: '[TEST] Helper L', p_phone: `+60 11-5${stamp}` });
ok('  rejoining needs a new request + approval (pending, no access)', (back.status >= 400 || back.body?.status === 'pending') && (await rpc(h, 'get_my_businesses')).body?.length === 0, msg(back));

// cleanup: cancel test orders, archive test zone, withdraw/reject pending
const cleanup = [];
for (const id of [O1.id, O2.id]) cleanup.push((await rpc(owner, 'decline_order', { p_order_id: id, p_reason: '[TEST] cleanup' })).status);
const pend = (await sel(owner, `team_join_requests?select=id&business_id=eq.${B}&user_id=in.(${uid(h)},${uid(h2)})&status=eq.pending`)).body || [];
for (const p of pend) await rpc(owner, 'decide_team_join_request', { p_request_id: p.id, p_approve: false });
if (ZID) cleanup.push((await rpc(owner, 'set_zone_status', { p_zone_id: ZID, p_status: 'inactive' })).status);
for (const t of [h, h2]) cleanup.push((await fetch(`${URL_}/auth/v1/admin/users/${uid(t)}`, { method: 'DELETE', headers: { apikey: SVC } })).status);
ok('cleanup: test orders declined, test zone inactive, test users deleted', cleanup.every(c => c === 200 || c === 204), cleanup.join(','));

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
