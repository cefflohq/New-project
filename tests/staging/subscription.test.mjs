// Subscription (pre-payment) backend + security suite (staging only).
// Fresh [TEST] businesses, deleted afterwards. No payment provider, no
// checkout, no charge: request_plan_change must stop at the boundary.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 150) : ''}`); if (!c) fails++; };
async function auth(path, body) { const r = await fetch(`${URL_}/auth/v1/${path}`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify(body) }); return r.json(); }
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
const SH = { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' };
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function rest(tok, method, path, body, extra = {}) { const r = await fetch(`${URL_}/rest/v1/${path}`, { method, headers: { ...H(tok), prefer: 'return=representation', ...extra }, body: body ? JSON.stringify(body) : undefined }); return { status: r.status, body: await r.json().catch(() => null) }; }
async function svc(method, path, body) { const r = await fetch(`${URL_}/rest/v1/${path}`, { method, headers: { ...SH, prefer: 'return=representation' }, body: body ? JSON.stringify(body) : undefined }); return { status: r.status, body: await r.json().catch(() => null) }; }
const sel = (tok, path) => rest(tok, 'GET', path);
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const refused = r => r.status >= 400;
const empty = r => r.status >= 400 || (Array.isArray(r.body) && r.body.length === 0);
const uid = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;
const stamp = String(Date.now()).slice(-6);
const created = [], businesses = [];
async function fresh(tag, meta = {}) {
  const email = `zelix.co00+v1007sub${tag}${stamp}@gmail.com`, password = 'Cf-v1007-Sub!7';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: SH, body: JSON.stringify({ email, password, email_confirm: true, user_metadata: meta }) });
  if (!r.ok) throw new Error('create ' + await r.text());
  const s = await auth('token?grant_type=password', { email, password }); created.push(uid(s.access_token)); return s.access_token;
}
async function join(owner, B, kind, tok) {
  const link = (await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: kind })).body?.token;
  await rpc(tok, 'join_via_invite_link', { p_token: link, p_name: `[TEST] Sub ${kind}`, p_phone: `+60 15-${stamp}${kind.length}` });
  if (kind === 'rider') { const r = (await sel(owner, `riders?select=id&business_id=eq.${B}&auth_user_id=eq.${uid(tok)}`)).body?.[0]; await rpc(owner, 'approve_pending_rider', { p_rider_id: r?.id }); return; }
  const q = (await sel(owner, `team_join_requests?select=id&business_id=eq.${B}&user_id=eq.${uid(tok)}&status=eq.pending`)).body?.[0];
  await rpc(owner, 'decide_team_join_request', { p_request_id: q?.id, p_approve: true });
}

try {
  // ---------- price book
  const plans = await sel(null, 'subscription_plans?select=key,monthly_price_myr,delivery_allowance,driver_cap,zone_cap,team_user_cap,most_popular,self_serve&order=sort');
  const byKey = Object.fromEntries((plans.body || []).map(p => [p.key, p]));
  ok('1 price book is public (anon read) and matches the locked/published values',
    plans.status === 200 && plans.body?.length === 5
    && Number(byKey.free?.monthly_price_myr) === 0 && byKey.free?.delivery_allowance === 150 && byKey.free?.driver_cap === 3 && byKey.free?.zone_cap === 2 && byKey.free?.team_user_cap === 1
    && Number(byKey.grow?.monthly_price_myr) === 99 && byKey.grow?.delivery_allowance === 500
    && Number(byKey.operate?.monthly_price_myr) === 199 && byKey.operate?.delivery_allowance === 1500 && byKey.operate?.most_popular === true && byKey.operate?.driver_cap === null
    && Number(byKey.scale?.monthly_price_myr) === 499 && byKey.scale?.delivery_allowance === 5000
    && byKey.enterprise?.monthly_price_myr === null && byKey.enterprise?.self_serve === false, JSON.stringify(plans.body).slice(0, 140));

  const owner = await fresh('own');
  const B = (await rpc(owner, 'bootstrap_business', { p_name: `[TEST] Sub ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(B);
  const ownerX = await fresh('ownx');
  const BX = (await rpc(ownerX, 'bootstrap_business', { p_name: `[TEST] Sub X ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(BX);
  const op = await fresh('op'); await join(owner, B, 'operator', op);
  const hel = await fresh('hel'); await join(owner, B, 'helper', hel);
  const drv = await fresh('drv', { driver_registration: { full_name: '[TEST] Sub Driver', phone: `+60 15-${stamp}9`, vehicle_type: 'car', vehicle_plate: `SUB ${stamp}` } }); await join(owner, B, 'rider', drv);
  ok('  nobody can write the price book (anon / Owner)', empty(await rest(null, 'PATCH', 'subscription_plans?key=eq.free', { monthly_price_myr: 1 })) && empty(await rest(owner, 'PATCH', 'subscription_plans?key=eq.operate', { monthly_price_myr: 1 })) && empty(await rest(owner, 'POST', 'subscription_plans', { key: 'free', name: 'x', sort: 9 })) && Number((await svc('GET', 'subscription_plans?select=monthly_price_myr&key=eq.operate')).body?.[0]?.monthly_price_myr) === 199);

  // ---------- default Free
  const row = (await sel(owner, `business_subscriptions?select=plan_key,status&business_id=eq.${B}`)).body?.[0];
  ok('2 a new business starts on FREE / active (no payment details)', row?.plan_key === 'free' && row?.status === 'active', JSON.stringify(row));

  // ---------- my_subscription + usage
  const ms0 = await rpc(owner, 'my_subscription', { p_business_id: B });
  ok('3 Owner reads plan, status and usage', ms0.status === 200 && ms0.body?.plan_key === 'free' && ms0.body?.deliveries_used === 0 && ms0.body?.delivery_allowance === 150 && ms0.body?.payment_enabled === false && ms0.body?.drivers_active === 1 && ms0.body?.team_users === 3, JSON.stringify(ms0.body).slice(0, 160));
  const zone = (await rpc(owner, 'create_zone', { p_business_id: B, p_name: 'Zone S' })).body; const ZID = (Array.isArray(zone) ? zone[0] : zone)?.id;
  const mk = async () => (await rpc(owner, 'create_delivery', { p_business_id: B, p_customer_name: '[TEST] Sub Cust', p_customer_phone: '+60 12-600 0001', p_delivery_address: '[TEST] 1 Jalan, KL', p_notes: '', p_latitude: null, p_longitude: null, p_items: [{ name: 'x', quantity: 1 }], p_zone_id: ZID, p_vehicle_requirement: 'any' })).body?.order?.id;
  const [d1, d2, open] = [await mk(), await mk(), await mk()];
  // fixture: two completed deliveries this cycle, one last month (not counted), one still open
  await svc('PATCH', `orders?id=eq.${d1}`, { delivery_status: 'delivered', completed_at: new Date().toISOString() });
  await svc('PATCH', `orders?id=eq.${d2}`, { delivery_status: 'delivered', completed_at: new Date(Date.now() - 40 * 86400000).toISOString() });
  const ms1 = await rpc(owner, 'my_subscription', { p_business_id: B });
  ok('  only completed deliveries in this cycle count (open / last month excluded)', ms1.body?.deliveries_used === 1 && ms1.body?.over_allowance === false, JSON.stringify(ms1.body).slice(0, 120));
  for (const [n, t] of [['Operator', op], ['Helper', hel], ['Driver', drv], ['other-business Owner', ownerX], ['anon', null]]) {
    ok(`  ${n} refused: my_subscription`, refused(await rpc(t, 'my_subscription', { p_business_id: B })));
  }
  ok('  Operator / Helper / Driver / X read no subscription row', [await sel(op, `business_subscriptions?select=plan_key&business_id=eq.${B}`), await sel(hel, `business_subscriptions?select=plan_key&business_id=eq.${B}`), await sel(drv, `business_subscriptions?select=plan_key&business_id=eq.${B}`), await sel(ownerX, `business_subscriptions?select=plan_key&business_id=eq.${B}`)].every(empty));

  // ---------- plan change stops at the payment boundary
  const before = JSON.stringify((await svc('GET', `business_subscriptions?select=*&business_id=eq.${B}`)).body);
  const up = await rpc(owner, 'request_plan_change', { p_business_id: B, p_plan_key: 'operate' });
  ok('4 Owner upgrade -> payment_required (payment not enabled), amount from the price book', up.status === 200 && up.body?.status === 'payment_required' && up.body?.payment_enabled === false && Number(up.body?.amount_myr) === 199, JSON.stringify(up.body));
  ok('  nothing activated, nothing written', JSON.stringify((await svc('GET', `business_subscriptions?select=*&business_id=eq.${B}`)).body) === before);
  ok('  current plan -> current_plan; Enterprise -> contact_sales', (await rpc(owner, 'request_plan_change', { p_business_id: B, p_plan_key: 'free' })).body?.status === 'current_plan' && (await rpc(owner, 'request_plan_change', { p_business_id: B, p_plan_key: 'enterprise' })).body?.status === 'contact_sales');
  ok('  invalid plan refused', refused(await rpc(owner, 'request_plan_change', { p_business_id: B, p_plan_key: 'platinum' })));
  for (const [n, t] of [['Operator', op], ['Helper', hel], ['Driver', drv], ['other-business Owner', ownerX], ['anon', null]]) {
    ok(`  ${n} refused: request_plan_change`, refused(await rpc(t, 'request_plan_change', { p_business_id: B, p_plan_key: 'operate' })));
  }

  // ---------- forged activation / direct writes
  ok('5 Owner cannot self-activate a paid plan (PATCH / POST / upsert)', empty(await rest(owner, 'PATCH', `business_subscriptions?business_id=eq.${B}`, { plan_key: 'scale', status: 'active' })) && empty(await rest(owner, 'POST', 'business_subscriptions', { business_id: B, plan_key: 'scale', status: 'active' }, { prefer: 'resolution=merge-duplicates,return=representation' })));
  ok('  Owner / Operator cannot call the FOUNDR plan setter', refused(await rpc(owner, 'admin_set_subscription', { p_business_id: B, p_plan_key: 'scale', p_status: 'active', p_mrr_cents: 49900, p_trial_ends_at: null })) && refused(await rpc(op, 'admin_set_subscription', { p_business_id: B, p_plan_key: 'scale', p_status: 'active', p_mrr_cents: 49900, p_trial_ends_at: null })));
  ok('  no client can forge a payment: no payment / checkout RPC exists for clients', [await rpc(owner, 'confirm_payment', {}), await rpc(owner, 'activate_subscription', {})].every(refused));
  ok('  even the service role cannot store an unknown plan or status', refused(await svc('PATCH', `business_subscriptions?business_id=eq.${B}`, { plan_key: 'platinum' })) && refused(await svc('PATCH', `business_subscriptions?business_id=eq.${B}`, { status: 'paid' })));
  ok('  subscription still FREE / active after every attempt', JSON.stringify((await svc('GET', `business_subscriptions?select=*&business_id=eq.${B}`)).body) === before);
  ok('  other business also starts FREE and stays isolated', (await sel(ownerX, `business_subscriptions?select=plan_key&business_id=eq.${BX}`)).body?.[0]?.plan_key === 'free' && empty(await sel(ownerX, `business_subscriptions?select=plan_key&business_id=eq.${B}`)));
  void open;
} catch (e) {
  ok('suite ran without an exception', false, e.stack || String(e));
} finally {
  for (const b of businesses) if (b) await fetch(`${URL_}/rest/v1/businesses?id=eq.${b}`, { method: 'DELETE', headers: SH });
  let left = 0;
  for (const id of created) { const r = await fetch(`${URL_}/auth/v1/admin/users/${id}`, { method: 'DELETE', headers: SH }); if (!r.ok) left++; }
  const bl = businesses.filter(Boolean).length ? (await svc('GET', `businesses?select=id&id=in.(${businesses.filter(Boolean).join(',')})`)).body : [];
  ok('cleanup: [TEST] businesses and accounts deleted (subscriptions cascade)', bl.length === 0 && left === 0, `${bl.length} businesses, ${left} accounts left`);
}
console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
