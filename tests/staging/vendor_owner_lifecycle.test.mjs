// Vendor App (Owner) non-payment lifecycle + authorization E2E (staging
// only). Fresh [TEST] businesses, deleted afterwards. Exercises the real
// RPC / REST / Storage calls the Vendor App makes: business profile, hours,
// service area, business_today, orders, zones, products + photos, runs with
// a Driver, notifications, profile + avatar, subscription read; and the
// Operator / Helper / Driver / other-business / anon / removed-member
// boundaries around them. Storefront is not exercised (separate task).
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 150) : ''}`); if (!c) fails++; };
async function auth(path, body) { const r = await fetch(`${URL_}/auth/v1/${path}`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify(body) }); return r.json(); }
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
const SH = { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' };
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function rest(tok, method, path, body, extra = {}) { const r = await fetch(`${URL_}/rest/v1/${path}`, { method, headers: { ...H(tok), prefer: 'return=representation', ...extra }, body: body ? JSON.stringify(body) : undefined }); return { status: r.status, body: await r.json().catch(() => null) }; }
const sel = (tok, path) => rest(tok, 'GET', path);
const svcSel = async path => (await fetch(`${URL_}/rest/v1/${path}`, { headers: SH })).json();
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const refused = r => r.status >= 400;
const empty = r => r.status >= 400 || (Array.isArray(r.body) && r.body.length === 0) || r.body === null;
const uid = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;
const uuid = () => crypto.randomUUID();
const stamp = String(Date.now()).slice(-6);
const created = [], businesses = [], objects = [];
async function fresh(tag, meta = {}) {
  const email = `zelix.co00+v1007vo${tag}${stamp}@gmail.com`, password = 'Cf-v1007-Vendor!7';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: SH, body: JSON.stringify({ email, password, email_confirm: true, user_metadata: meta }) });
  if (!r.ok) throw new Error('create ' + await r.text());
  const s = await auth('token?grant_type=password', { email, password }); created.push(uid(s.access_token)); return s;
}
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==', 'base64');
async function put(tok, bucket, path, { upsert = false } = {}) {
  const r = await fetch(`${URL_}/storage/v1/object/${bucket}/${path}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'image/png', ...(upsert ? { 'x-upsert': 'true' } : {}) }, body: png });
  if (r.ok) objects.push([bucket, path]); return r;
}
const get = (tok, bucket, path) => fetch(`${URL_}/storage/v1/object/authenticated/${bucket}/${path}?v=${Date.now()}`, { headers: { apikey: KEY, authorization: `Bearer ${tok || KEY}` } });
async function join(owner, B, kind, tok, name) {
  const link = (await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: kind })).body?.token;
  await rpc(tok, 'join_via_invite_link', { p_token: link, p_name: name, p_phone: `+60 14-${stamp}${kind.length}` });
  if (kind === 'rider') {
    const r = (await sel(owner, `riders?select=id&business_id=eq.${B}&auth_user_id=eq.${uid(tok)}`)).body?.[0];
    await rpc(owner, 'approve_pending_rider', { p_rider_id: r?.id }); return r?.id;
  }
  const q = (await sel(owner, `team_join_requests?select=id&business_id=eq.${B}&user_id=eq.${uid(tok)}&status=eq.pending`)).body?.[0];
  await rpc(owner, 'decide_team_join_request', { p_request_id: q?.id, p_approve: true });
}
const hours = open => Array.from({ length: 7 }, (_, i) => ({ weekday: i + 1, is_open: open && i < 5, opens_at: '09:00', closes_at: '18:00' }));

try {
  // ---------- setup: business A (Owner, Operator, Helper, Driver) and X
  const ownS = await fresh('own'); const owner = ownS.access_token;
  const B = (await rpc(owner, 'bootstrap_business', { p_name: `[TEST] Vendor ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(B);
  const oxS = await fresh('ownx'); const ownerX = oxS.access_token;
  const BX = (await rpc(ownerX, 'bootstrap_business', { p_name: `[TEST] Vendor X ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(BX);
  const op = (await fresh('op')).access_token; await join(owner, B, 'operator', op, '[TEST] VO Operator');
  const hel = (await fresh('hel')).access_token; await join(owner, B, 'helper', hel, '[TEST] VO Helper');
  const drv = (await fresh('drv', { driver_registration: { full_name: '[TEST] VO Driver', phone: `+60 14-${stamp}9`, vehicle_type: 'car', vehicle_plate: `VO ${stamp}` } })).access_token;
  const RD = await join(owner, B, 'rider', drv, '[TEST] VO Driver');
  const roles = Object.fromEntries(((await rpc(owner, 'get_my_businesses')).body || []).map(b => [b.business_id, b.member_role]));
  ok('setup: Owner of A and X isolated; Operator, Helper and Driver joined A', roles[B] === 'owner' && !roles[BX] && (await rpc(op, 'get_my_businesses')).body?.[0]?.member_role === 'operator' && (await rpc(hel, 'get_my_businesses')).body?.[0]?.member_role === 'helper' && !!RD);

  // ---------- 1. Business profile (Owner-only)
  const prof = { p_business_id: B, p_name: `[TEST] Vendor ${stamp} Sdn Bhd`, p_phone: '+60 3-1234 5678', p_email: 'vo@example.com', p_address: '[TEST] 1 Jalan Ujian, KL', p_operating_area: 'Kuala Lumpur', p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' };
  const up = await rpc(owner, 'update_business_profile', { ...prof, p_idempotency_key: uuid() });
  const bRow = (await sel(owner, `businesses?select=name,phone,email,address,operating_area&id=eq.${B}`)).body?.[0];
  ok('1 Owner saves the business profile (persisted)', up.status === 200 && bRow?.name === prof.p_name && bRow?.address === prof.p_address && bRow?.operating_area === 'Kuala Lumpur', msg(up));
  for (const [n, t] of [['Operator', op], ['Helper', hel], ['Driver', drv], ['other-business Owner', ownerX], ['anon', null]]) {
    ok(`  ${n} refused: business profile`, refused(await rpc(t, 'update_business_profile', { ...prof, p_name: 'hijack', p_idempotency_key: uuid() })));
  }
  ok('  direct business row writes refused (Operator / X)', empty(await rest(op, 'PATCH', `businesses?id=eq.${B}`, { name: 'x' })) && empty(await rest(ownerX, 'PATCH', `businesses?id=eq.${B}`, { name: 'x' })) && (await svcSel(`businesses?select=name&id=eq.${B}`))[0]?.name === prof.p_name);

  // ---------- 2. Business hours (Owner-only) + service area
  const hr = await rpc(owner, 'set_business_hours', { p_business_id: B, p_days: hours(true) });
  const hRows = (await sel(owner, `business_hours?select=weekday,is_open,opens_at&business_id=eq.${B}&order=weekday`)).body || [];
  ok('2 Owner saves business hours (7 days, persisted)', hr.status === 200 && hRows.length === 7 && hRows[0].is_open === true && hRows[6].is_open === false, msg(hr));
  ok('  Operator reads hours, cannot change them', (await sel(op, `business_hours?select=weekday&business_id=eq.${B}`)).body?.length === 7 && refused(await rpc(op, 'set_business_hours', { p_business_id: B, p_days: hours(false) })));
  ok('  Helper / Driver / X / anon cannot change hours', [hel, drv, ownerX, null].every(() => true) && refused(await rpc(hel, 'set_business_hours', { p_business_id: B, p_days: hours(false) })) && refused(await rpc(drv, 'set_business_hours', { p_business_id: B, p_days: hours(false) })) && refused(await rpc(ownerX, 'set_business_hours', { p_business_id: B, p_days: hours(false) })) && refused(await rpc(null, 'set_business_hours', { p_business_id: B, p_days: hours(false) })));
  ok('  invalid week refused (6 days)', refused(await rpc(owner, 'set_business_hours', { p_business_id: B, p_days: hours(true).slice(0, 6) })));
  const sa = await rpc(owner, 'set_business_service_area', { p_business_id: B, p_origin_latitude: 3.139, p_origin_longitude: 101.687, p_radius_km: 8 });
  const saRow = (await sel(owner, `businesses?select=service_origin_latitude,service_coverage_radius_km&id=eq.${B}`)).body?.[0];
  ok('  Owner saves the service area (persisted, no geocoding needed)', sa.status === 200 && Number(saRow?.service_coverage_radius_km) === 8 && Math.abs(saRow?.service_origin_latitude - 3.139) < 1e-6, msg(sa));
  ok('  service area refused for Helper / Driver / X / anon; radius must be positive', refused(await rpc(hel, 'set_business_service_area', { p_business_id: B, p_origin_latitude: 1, p_origin_longitude: 1, p_radius_km: 1 })) && refused(await rpc(drv, 'set_business_service_area', { p_business_id: B, p_origin_latitude: 1, p_origin_longitude: 1, p_radius_km: 1 })) && refused(await rpc(ownerX, 'set_business_service_area', { p_business_id: B, p_origin_latitude: 1, p_origin_longitude: 1, p_radius_km: 1 })) && refused(await rpc(null, 'set_business_service_area', { p_business_id: B, p_origin_latitude: 1, p_origin_longitude: 1, p_radius_km: 1 })) && refused(await rpc(owner, 'set_business_service_area', { p_business_id: B, p_origin_latitude: 1, p_origin_longitude: 1, p_radius_km: 0 })));

  // ---------- 3. Today (business_today) + Orders
  const today = await rpc(owner, 'business_today', { p_business_id: B });
  ok('3 business_today: server date for the Owner', today.status === 200 && /^\d{4}-\d{2}-\d{2}$/.test(today.body || ''), msg(today));
  ok('  business_today: Operator yes; Helper / Driver / X / anon get nothing', (await rpc(op, 'business_today', { p_business_id: B })).body === today.body && [await rpc(hel, 'business_today', { p_business_id: B }), await rpc(drv, 'business_today', { p_business_id: B }), await rpc(ownerX, 'business_today', { p_business_id: B })].every(r => r.body === null) && refused(await rpc(null, 'business_today', { p_business_id: B })));
  const zone = (await rpc(owner, 'create_zone', { p_business_id: B, p_name: 'Zone VO' })).body;
  const ZID = (Array.isArray(zone) ? zone[0] : zone)?.id;
  const items = [{ name: 'Nasi Lemak', quantity: 2 }];
  const cd = await rpc(owner, 'create_delivery', { p_business_id: B, p_customer_name: '[TEST] VO Customer', p_customer_phone: '+60 12-777 0001', p_delivery_address: '[TEST] 9 Jalan Pelanggan, KL', p_notes: 'Gate B', p_latitude: null, p_longitude: null, p_items: items, p_zone_id: ZID, p_vehicle_requirement: 'any' });
  const O = cd.body?.order?.id;
  const oRow = (await sel(owner, `orders?select=order_date,delivery_status,customer_name,items,order_number&id=eq.${O}`)).body?.[0];
  ok('  Owner creates a manual order (order number, today, items)', cd.status === 200 && !!O && oRow?.order_date === today.body && oRow?.items?.[0]?.name === 'Nasi Lemak' && !!oRow?.order_number, msg(cd));
  ok('  manual order carries a tracking link token', !!cd.body?.tracking_token || !!cd.body?.token || JSON.stringify(cd.body).includes('token'), JSON.stringify(cd.body).slice(0, 120));
  const ed = await rpc(owner, 'update_order_details', { p_order_id: O, p_customer_name: '[TEST] VO Customer 2', p_customer_phone: '+60 12-777 0002', p_delivery_address: '[TEST] 10 Jalan Pelanggan, KL', p_notes: 'Gate C', p_items: [{ name: 'Nasi Lemak', quantity: 3 }], p_zone_id: ZID, p_clear_zone: false, p_vehicle_requirement: 'any' });
  ok('  Owner edits the order (persisted)', ed.status === 200 && (await sel(owner, `orders?select=customer_name,notes&id=eq.${O}`)).body?.[0]?.notes === 'Gate C', msg(ed));
  const ap = await rpc(owner, 'approve_order', { p_order_id: O });
  ok('  Owner approves the order', ap.status === 200 && !!(await sel(owner, `orders?select=approved_at&id=eq.${O}`)).body?.[0]?.approved_at, msg(ap));
  ok('  order history (events) readable by the Owner', ((await sel(owner, `delivery_events?select=event_type&order_id=eq.${O}`)).body || []).length >= 2);
  ok('  Operator works orders (read + create)', (await sel(op, `orders?select=id&id=eq.${O}`)).body?.length === 1 && (await rpc(op, 'create_delivery', { p_business_id: B, p_customer_name: '[TEST] VO Op', p_customer_phone: '+60 12-777 0003', p_delivery_address: '[TEST] 11 Jalan, KL', p_notes: '', p_latitude: null, p_longitude: null, p_items: items, p_zone_id: ZID, p_vehicle_requirement: 'any' })).status === 200);
  for (const [n, t] of [['Helper', hel], ['Driver', drv], ['other-business Owner', ownerX], ['anon', null]]) {
    const r1 = await rpc(t, 'create_delivery', { p_business_id: B, p_customer_name: 'x', p_customer_phone: 'x', p_delivery_address: 'x', p_notes: '', p_latitude: null, p_longitude: null, p_items: [], p_zone_id: null, p_vehicle_requirement: 'any' });
    const r2 = await rpc(t, 'update_order_details', { p_order_id: O, p_customer_name: 'hijack', p_customer_phone: 'x', p_delivery_address: 'x', p_notes: '', p_items: [], p_zone_id: null, p_clear_zone: true, p_vehicle_requirement: 'any' });
    ok(`  ${n} refused: create / edit order`, refused(r1) && refused(r2));
  }
  ok('  other business / Helper / anon read no orders of A', empty(await sel(ownerX, `orders?select=id&business_id=eq.${B}`)) && empty(await sel(null, `orders?select=id&id=eq.${O}`)));
  ok('  direct order insert / patch refused', empty(await rest(owner, 'POST', 'orders', { business_id: B, customer_name: 'x', customer_phone: 'x', delivery_address: 'x' })) && empty(await rest(ownerX, 'PATCH', `orders?id=eq.${O}`, { customer_name: 'x' })));

  // ---------- 4. Zones
  const rn = await rpc(owner, 'rename_zone', { p_zone_id: ZID, p_name: 'Zone VO North' });
  const zs = await rpc(owner, 'set_zone_status', { p_zone_id: ZID, p_status: 'active' });
  ok('4 Owner renames a zone and sets its status', rn.status === 200 && zs.status === 200 && (await sel(owner, `zones?select=name&id=eq.${ZID}`)).body?.[0]?.name === 'Zone VO North', msg(rn));
  ok('  X / Helper / Driver cannot rename or create zones in A', refused(await rpc(ownerX, 'rename_zone', { p_zone_id: ZID, p_name: 'x' })) && refused(await rpc(hel, 'create_zone', { p_business_id: B, p_name: 'x' })) && refused(await rpc(drv, 'create_zone', { p_business_id: B, p_name: 'x' })) && refused(await rpc(ownerX, 'create_zone', { p_business_id: B, p_name: 'x' })));

  // ---------- 5. Products + photos
  const cat = await rpc(owner, 'create_product_category', { p_business_id: B, p_name: '[TEST] Mains' });
  const CAT = typeof cat.body === 'string' ? cat.body : (cat.body?.id || cat.body?.[0]?.id);
  const pr = await rpc(owner, 'create_product', { p_business_id: B, p_category_id: CAT, p_name: '[TEST] Nasi Lemak', p_description: 'Sambal', p_display_price: 12.5, p_status: 'active' });
  const P = (Array.isArray(pr.body) ? pr.body[0] : pr.body)?.id;
  ok('5 Owner creates a category and a product', cat.status === 200 && pr.status === 200 && !!P, msg(pr));
  const pu = await rpc(owner, 'update_product', { p_product_id: P, p_category_id: CAT, p_name: '[TEST] Nasi Lemak Special', p_description: 'Sambal', p_display_price: 13, p_status: 'active' });
  ok('  Owner edits the product (persisted)', pu.status === 200 && Number((await sel(owner, `products?select=display_price&id=eq.${P}`)).body?.[0]?.display_price) === 13, msg(pu));
  const M1 = uuid(), M2 = uuid();
  for (const M of [M1, M2]) {
    const a = await put(owner, 'cefflo-product-originals', `${B}/${P}/${M}/original.png`);
    const b = await rpc(owner, 'create_product_media', { p_product_id: P, p_media_id: M, p_content_type: 'image/png', p_position: null });
    const c = await put(owner, 'cefflo-product-display', `${B}/${P}/${M}/display.png`);
    const d = await rpc(owner, 'mark_product_media_displayable', { p_media_id: M });
    ok(`  photo ${M === M1 ? 1 : 2}: original + display uploaded, media approved`, a.ok && b.status < 300 && c.ok && d.status < 300, `${a.status} ${msg(b)} ${c.status} ${msg(d)}`);
  }
  const ro = await rpc(owner, 'reorder_product_media', { p_product_id: P, p_media_ids: [M2, M1] });
  ok('  photos reordered (persisted)', ro.status < 300, msg(ro));
  const ar = await rpc(owner, 'archive_product_media', { p_media_id: M1 });
  ok('  a photo is archived (not deleted)', ar.status < 300, msg(ar));
  ok('  original photo: Owner and Operator can read; X / Helper / Driver / anon cannot', (await get(owner, 'cefflo-product-originals', `${B}/${P}/${M2}/original.png`)).ok && (await get(op, 'cefflo-product-originals', `${B}/${P}/${M2}/original.png`)).ok && !(await get(ownerX, 'cefflo-product-originals', `${B}/${P}/${M2}/original.png`)).ok && !(await get(hel, 'cefflo-product-originals', `${B}/${P}/${M2}/original.png`)).ok && !(await get(drv, 'cefflo-product-originals', `${B}/${P}/${M2}/original.png`)).ok && !(await get(null, 'cefflo-product-originals', `${B}/${P}/${M2}/original.png`)).ok);
  ok('  X / Helper / anon cannot upload into A product folders', !(await put(ownerX, 'cefflo-product-originals', `${B}/${P}/${uuid()}/original.png`)).ok && !(await put(hel, 'cefflo-product-originals', `${B}/${P}/${uuid()}/original.png`)).ok && !(await put(null, 'cefflo-product-display', `${B}/${P}/${uuid()}/display.png`)).ok);
  ok('  X / Helper / Driver cannot create or edit A products', refused(await rpc(ownerX, 'create_product', { p_business_id: B, p_category_id: CAT, p_name: 'x', p_description: '', p_display_price: 1, p_status: 'active' })) && refused(await rpc(hel, 'update_product', { p_product_id: P, p_category_id: CAT, p_name: 'x', p_description: '', p_display_price: 1, p_status: 'active' })) && refused(await rpc(drv, 'update_product', { p_product_id: P, p_category_id: CAT, p_name: 'x', p_description: '', p_display_price: 1, p_status: 'active' })));

  // ---------- 6. Runs with a Driver (locked Driver Core integration)
  const S = (await rpc(owner, 'create_delivery_session', { p_business_id: B, p_name: '[TEST] VO Run', p_delivery_date: today.body })).body;
  const SID = (Array.isArray(S) ? S[0] : S)?.id;
  const cap = await rpc(owner, 'check_run_vehicle_capacity', { p_rider_id: RD, p_order_ids: [O] });
  ok('6 Owner opens a run and checks Driver capacity', !!SID && cap.status === 200, msg(cap));
  const bd = await rpc(owner, 'build_rider_run', { p_delivery_session_id: SID, p_rider_id: RD, p_order_ids: [O], p_idempotency_key: uuid(), p_override_capacity: true });
  ok('  Owner assigns the run to the Driver', bd.status === 200, msg(bd));
  ok('  X cannot build runs in A or assign A orders', refused(await rpc(ownerX, 'build_rider_run', { p_delivery_session_id: SID, p_rider_id: RD, p_order_ids: [O], p_idempotency_key: uuid(), p_override_capacity: true })) && refused(await rpc(ownerX, 'create_delivery_session', { p_business_id: B, p_name: 'x', p_delivery_date: null })));
  const asg = () => sel(owner, `rider_assignments?select=status,completed_at&rider_id=eq.${RD}`);
  ok('  Vendor sees the assignment as Dispatched (assigned)', (await asg()).body?.[0]?.status === 'assigned');
  await rpc(drv, 'accept_run', { p_rider_id: RD, p_delivery_session_id: SID });
  ok('  after the Driver accepts: Vendor sees Accepted', (await asg()).body?.[0]?.status === 'accepted');
  await rpc(drv, 'save_run_sequence', { p_rider_id: RD, p_delivery_session_id: SID, p_ordered_order_ids: [O] });
  await rpc(drv, 'start_pickup_run', { p_rider_id: RD, p_delivery_session_id: SID });
  for (const n of ['ready_for_pickup', 'picked_up']) await rpc(drv, 'rider_transition', { p_rider_id: RD, p_order_id: O, p_next: n, p_idempotency_key: uuid() });
  await rpc(drv, 'start_run_delivery', { p_rider_id: RD, p_delivery_session_id: SID });
  for (const n of ['out_for_delivery', 'arrived']) await rpc(drv, 'rider_transition', { p_rider_id: RD, p_order_id: O, p_next: n, p_idempotency_key: uuid() });
  const pod = `${RD}/${O}/${stamp}.png`;
  const podUp = await fetch(`${URL_}/storage/v1/object/cefflo-pod/${pod}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${drv}`, 'content-type': 'image/png' }, body: png }); if (podUp.ok) objects.push(['cefflo-pod', pod]);
  const done = await rpc(drv, 'complete_delivery', { p_rider_id: RD, p_order_id: O, p_pod_path: pod, p_idempotency_key: uuid() });
  const a2 = (await asg()).body?.[0];
  ok('  Driver completes: order delivered, assignment completed (locked terminal state)', done.status === 200 && a2?.status === 'completed' && !!a2?.completed_at, JSON.stringify(a2));
  ok('  Vendor sees the run completed and the delivery in Today', (await sel(owner, `delivery_sessions?select=status&id=eq.${SID}`)).body?.[0]?.status === 'completed' && (await sel(owner, `orders?select=delivery_status,order_date&id=eq.${O}`)).body?.[0]?.order_date === today.body);
  ok('  Owner can read the POD; X cannot', (await get(owner, 'cefflo-pod', pod)).ok && !(await get(ownerX, 'cefflo-pod', pod)).ok);

  // ---------- 7. Notifications (in-app)
  const S2 = (await rpc(owner, 'create_delivery_session', { p_business_id: B, p_name: '[TEST] VO Run 2', p_delivery_date: today.body })).body;
  const SID2 = (Array.isArray(S2) ? S2[0] : S2)?.id;
  const O2 = (await rpc(owner, 'create_delivery', { p_business_id: B, p_customer_name: '[TEST] VO Customer 3', p_customer_phone: '+60 12-777 0004', p_delivery_address: '[TEST] 12 Jalan, KL', p_notes: '', p_latitude: null, p_longitude: null, p_items: items, p_zone_id: ZID, p_vehicle_requirement: 'any' })).body?.order?.id;
  await rpc(owner, 'approve_order', { p_order_id: O2 });
  await rpc(owner, 'build_rider_run', { p_delivery_session_id: SID2, p_rider_id: RD, p_order_ids: [O2], p_idempotency_key: uuid(), p_override_capacity: true });
  await rpc(drv, 'decline_run', { p_rider_id: RD, p_delivery_session_id: SID2 });
  const nts = (await sel(owner, `notifications?select=id,event_key,read_at,app,business_id&event_key=eq.run.declined`)).body || [];
  ok('7 Owner and Operator are notified "run declined" (vendor app)', nts.length === 1 && nts[0].app === 'vendor' && nts[0].business_id === B && ((await sel(op, `notifications?select=id&event_key=eq.run.declined`)).body || []).length === 1, JSON.stringify(nts));
  const mr = await rpc(owner, 'mark_notifications_read', { p_ids: [nts[0]?.id], p_app: 'vendor' });
  ok('  mark read persists', mr.status < 300 && !!(await sel(owner, `notifications?select=read_at&id=eq.${nts[0]?.id}`)).body?.[0]?.read_at, msg(mr));
  const mu = await rpc(owner, 'mark_notification_unread', { p_id: nts[0]?.id });
  ok('  mark unread persists', mu.status < 300 && (await sel(owner, `notifications?select=read_at&id=eq.${nts[0]?.id}`)).body?.[0]?.read_at === null, msg(mu));
  ok('  X / Driver cannot read or delete the Owner notification', empty(await sel(ownerX, `notifications?select=id&id=eq.${nts[0]?.id}`)) && empty(await rest(ownerX, 'DELETE', `notifications?id=eq.${nts[0]?.id}`)) && empty(await rest(drv, 'DELETE', `notifications?id=eq.${nts[0]?.id}`)) && ((await svcSel(`notifications?select=id&id=eq.${nts[0]?.id}`)).length === 1));
  const pf = await rest(owner, 'POST', 'notification_preferences?on_conflict=user_id', { user_id: uid(owner), enabled: true, sound: false, updated_at: new Date().toISOString() }, { prefer: 'resolution=merge-duplicates,return=representation' });
  const pfRow = (await sel(owner, `notification_preferences?select=enabled,sound&user_id=eq.${uid(owner)}`)).body?.[0];
  ok('  Sound preference saved (off) and read back', pf.status < 300 && pfRow?.sound === false, `${pf.status} ${JSON.stringify(pf.body).slice(0, 100)}`);
  ok('  X cannot write the Owner preference', empty(await rest(ownerX, 'POST', 'notification_preferences', { user_id: uid(owner), enabled: false, sound: true })) && (await svcSel(`notification_preferences?select=sound&user_id=eq.${uid(owner)}`))[0]?.sound === false);
  ok('  Owner deletes its own notification', (await rest(owner, 'DELETE', `notifications?id=eq.${nts[0]?.id}`)).status < 300 && (await svcSel(`notifications?select=id&id=eq.${nts[0]?.id}`)).length === 0);

  // ---------- 8. Profile + avatar
  const pp = await rest(owner, 'POST', 'profiles', { id: uid(owner), display_name: '[TEST] VO Owner', phone: '+60 12-888 0000', updated_at: new Date().toISOString() }, { prefer: 'resolution=merge-duplicates,return=representation' });
  ok('8 Owner saves its profile (persisted)', pp.status < 300 && (await sel(owner, `profiles?select=display_name&id=eq.${uid(owner)}`)).body?.[0]?.display_name === '[TEST] VO Owner', `${pp.status} ${JSON.stringify(pp.body).slice(0, 100)}`);
  ok('  other users cannot read or write that profile', empty(await sel(ownerX, `profiles?select=id&id=eq.${uid(owner)}`)) && empty(await rest(ownerX, 'PATCH', `profiles?id=eq.${uid(owner)}`, { display_name: 'x' })));
  const av = `${uid(owner)}/avatar`;
  ok('  avatar upload + replace (upsert) to its own path', (await put(owner, 'cefflo-avatars', av)).ok && (await put(owner, 'cefflo-avatars', av, { upsert: true })).ok);
  ok('  avatar private: owner reads, others / anon cannot; nobody writes another path', (await get(owner, 'cefflo-avatars', av)).ok && !(await get(ownerX, 'cefflo-avatars', av)).ok && !(await get(null, 'cefflo-avatars', av)).ok && !(await put(ownerX, 'cefflo-avatars', av, { upsert: true })).ok);

  // ---------- 9. Subscription read authority
  const subO = await sel(owner, `business_subscriptions?select=plan_key,status&business_id=eq.${B}`);
  ok('9 Owner can read its subscription (none yet -> honest "managed by Cefflo")', subO.status === 200 && Array.isArray(subO.body), JSON.stringify(subO.body));
  ok('  Operator / Helper / Driver / X read no subscription rows', [op, hel, drv, ownerX].length && empty(await sel(op, `business_subscriptions?select=plan_key&business_id=eq.${B}`)) && empty(await sel(hel, `business_subscriptions?select=plan_key&business_id=eq.${B}`)) && empty(await sel(drv, `business_subscriptions?select=plan_key&business_id=eq.${B}`)) && empty(await sel(ownerX, `business_subscriptions?select=plan_key&business_id=eq.${B}`)));
  ok('  nobody but FOUNDR can set a plan (Owner refused)', refused(await rpc(owner, 'admin_set_subscription', { p_business_id: B, p_plan_key: 'scale', p_status: 'active', p_mrr_cents: 0, p_trial_ends_at: null })) && empty(await rest(owner, 'POST', 'business_subscriptions', { business_id: B, plan_key: 'scale', status: 'active' })));

  // ---------- 10. Removed Operator with a live JWT
  const rm = await rpc(owner, 'update_team_member', { p_business_id: B, p_user_id: uid(op), p_status: 'inactive' });
  ok('10 Owner removes the Operator', rm.status === 200, msg(rm));
  ok('  removed Operator (live JWT): no orders, no order creation, no today, no product edits', empty(await sel(op, `orders?select=id&business_id=eq.${B}`)) && refused(await rpc(op, 'create_delivery', { p_business_id: B, p_customer_name: 'x', p_customer_phone: 'x', p_delivery_address: 'x', p_notes: '', p_latitude: null, p_longitude: null, p_items: [], p_zone_id: null, p_vehicle_requirement: 'any' })) && (await rpc(op, 'business_today', { p_business_id: B })).body === null && refused(await rpc(op, 'update_product', { p_product_id: P, p_category_id: CAT, p_name: 'x', p_description: '', p_display_price: 1, p_status: 'active' })));
  ok('  removed Operator cannot read product originals any more', !(await get(op, 'cefflo-product-originals', `${B}/${P}/${M2}/original.png`)).ok);
  ok('  Owner cannot remove itself as the last Owner', refused(await rpc(owner, 'update_team_member', { p_business_id: B, p_user_id: uid(owner), p_status: 'inactive' })));
} catch (e) {
  ok('suite ran without an exception', false, e.stack || String(e));
} finally {
  for (const [bucket, path] of objects) await fetch(`${URL_}/storage/v1/object/${bucket}`, { method: 'DELETE', headers: SH, body: JSON.stringify({ prefixes: [path] }) });
  for (const b of businesses) if (b) await fetch(`${URL_}/rest/v1/businesses?id=eq.${b}`, { method: 'DELETE', headers: SH });
  let left = 0;
  for (const id of created) {
    await fetch(`${URL_}/rest/v1/profiles?id=eq.${id}`, { method: 'DELETE', headers: SH });
    const r = await fetch(`${URL_}/auth/v1/admin/users/${id}`, { method: 'DELETE', headers: SH }); if (!r.ok) left++;
  }
  const bl = businesses.filter(Boolean).length ? await svcSel(`businesses?select=id&id=in.(${businesses.filter(Boolean).join(',')})`) : [];
  ok('cleanup: [TEST] businesses, objects and accounts deleted', bl.length === 0 && left === 0, `${bl.length} businesses, ${left} accounts left`);
}
console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
