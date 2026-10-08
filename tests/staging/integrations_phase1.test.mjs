// Integrations Phase 1 (staging only; migration 20261008090000 + Edge Function
// integrations-inbound). Owner/Operator manage keys and connections; Helper,
// outsiders and anon are denied; secrets and key hashes are never readable by
// clients; API / WooCommerce / Shopify inbound create one normal order each,
// with signatures enforced, duplicates collapsed and payload tenant ids ignored.
import crypto from 'node:crypto';

const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_ || !URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const FN = `${URL_}/functions/v1/integrations-inbound`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${c ? '' : '  -> ' + String(typeof x === 'string' ? x : JSON.stringify(x)).slice(0, 220)}`); if (!c) fails++; };
const SH = { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' };
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
const sql = async q => (await fetch(`${URL_}/rest/v1/${q}`, { headers: SH })).json();
const restAs = async (tok, q) => { const r = await fetch(`${URL_}/rest/v1/${q}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; };
const post = async (path, body, headers = {}) => { const raw = typeof body === 'string' ? body : JSON.stringify(body); const r = await fetch(`${FN}${path}`, { method: 'POST', headers: { 'content-type': 'application/json', ...headers }, body: raw }); return { status: r.status, body: await r.json().catch(() => null) }; };
const hmac = (secret, raw) => crypto.createHmac('sha256', secret).update(raw).digest('base64');
const stamp = String(Date.now()).slice(-6), created = [], businesses = [];
async function fresh(tag) {
  const email = `zelix.co00+int${tag}${stamp}@gmail.com`, password = 'Cf-int-Test!7';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: SH, body: JSON.stringify({ email, password, email_confirm: true }) });
  const u = await r.json(); if (!r.ok) throw new Error(JSON.stringify(u)); created.push(u.id);
  const tok = (await (await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) })).json()).access_token;
  return { id: u.id, tok };
}
const member = (b, u, role) => fetch(`${URL_}/rest/v1/business_members`, { method: 'POST', headers: SH, body: JSON.stringify({ business_id: b, user_id: u, role, status: 'active' }) });
const orderCount = async b => (await sql(`orders?select=id&business_id=eq.${b}&origin=eq.integration`)).length;
const apiOrder = (ext, extra = {}) => ({ external_id: ext, customer_name: '[TEST] Int', customer_phone: '+60 12-345 6789', delivery_address: '[TEST] 1 Jalan Int', notes: 'n', items: [{ name: 'Kopi', quantity: 2, price: 6.5 }], ...extra });

try {
  const O = await fresh('owner'), OP = await fresh('op'), HE = await fresh('helper'), X = await fresh('outsider');
  const B = (await rpc(O.tok, 'bootstrap_business', { p_name: `[TEST] Int ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(B);
  const B2 = (await rpc(X.tok, 'bootstrap_business', { p_name: `[TEST] Int other ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(B2);
  await member(B, OP.id, 'operator'); await member(B, HE.id, 'helper');

  // ---------- authority
  const k1 = await rpc(O.tok, 'integration_create_api_key', { p_business: B });
  ok('Owner creates an API key (shown once, cfk_live_ + 48 hex)', /^cfk_live_[0-9a-f]{48}$/.test(k1.body?.key || ''), k1.body);
  const k2 = await rpc(OP.tok, 'integration_create_api_key', { p_business: B });
  ok('Operator creates an API key', !!k2.body?.key, k2.body);
  ok('Helper cannot create a key', /forbidden/.test(JSON.stringify((await rpc(HE.tok, 'integration_create_api_key', { p_business: B })).body)));
  ok('outsider (other business owner) cannot create a key', /forbidden/.test(JSON.stringify((await rpc(X.tok, 'integration_create_api_key', { p_business: B })).body)));
  ok('anon cannot create a key', (await rpc(null, 'integration_create_api_key', { p_business: B })).status >= 400);
  ok('Helper cannot list integrations', /forbidden/.test(JSON.stringify((await rpc(HE.tok, 'integration_list', { p_business: B })).body)));
  const list = (await rpc(O.tok, 'integration_list', { p_business: B })).body;
  ok('list shows 2 keys by prefix only (no hash / full key)', list?.api_keys?.length === 2 && !/key_hash|cfk_live_[0-9a-f]{48}/.test(JSON.stringify(list)), list);
  for (const t of ['integration_connections', 'integration_api_keys', 'integration_events']) {
    const r = await restAs(O.tok, `${t}?select=*`);
    ok(`${t}: no direct client read`, r.status >= 400 || (Array.isArray(r.body) && r.body.length === 0), r);
  }
  ok('internal ingest not callable by a client', (await rpc(O.tok, '_integration_ingest_order', { p_connection: crypto.randomUUID(), p_external_id: 'x', p_order: {} })).status >= 400);
  ok('webhook secret target not callable by a client', (await rpc(O.tok, '_integration_webhook_target', { p_connection: crypto.randomUUID(), p_provider: 'shopify' })).status >= 400);

  // ---------- API inbound
  const KEY1 = k1.body.key;
  const a1 = await post('/api/orders', apiOrder('API-1'), { authorization: `Bearer ${KEY1}` });
  ok('API: valid key creates an order (201 + reference)', a1.status === 201 && !!a1.body?.order_reference, a1);
  const row = (await sql(`orders?select=business_id,origin,items,customer_phone&id=eq.${a1.body?.order_id}`))[0];
  ok('API order belongs to the key business, origin integration', row?.business_id === B && row?.origin === 'integration');
  ok('API order items: name/qty + price snapshot', row?.items?.[0]?.name === 'Kopi' && row.items[0].qty === 2 && row.items[0].line_subtotal_snapshot === 13);
  ok('API order: delivery stop + tracking token created', (await sql(`delivery_stops?select=id&order_id=eq.${a1.body?.order_id}`)).length === 1 && (await sql(`tracking_tokens?select=order_id&order_id=eq.${a1.body?.order_id}`)).length === 1);
  const dup = await post('/api/orders', apiOrder('API-1'), { authorization: `Bearer ${KEY1}` });
  ok('API: same external id → duplicate, no second order', dup.status === 200 && dup.body?.duplicate === true && (await orderCount(B)) === 1, dup);
  const cross = await post('/api/orders', apiOrder('API-2', { business_id: B2 }), { authorization: `Bearer ${KEY1}` });
  ok('API: payload business_id ignored (order lands in key business)', (await sql(`orders?select=business_id&id=eq.${cross.body?.order_id}`))[0]?.business_id === B && (await sql(`orders?select=id&business_id=eq.${B2}`)).length === 0);
  ok('API: unknown key 401', (await post('/api/orders', apiOrder('API-3'), { authorization: `Bearer cfk_live_${'0'.repeat(48)}` })).status === 401);
  ok('API: missing key 401', (await post('/api/orders', apiOrder('API-3'))).status === 401);
  ok('API: invalid phone 422 (no order)', (await post('/api/orders', apiOrder('API-4', { customer_phone: 'abc' }), { authorization: `Bearer ${KEY1}` })).status === 422);
  ok('API: empty items 422', (await post('/api/orders', apiOrder('API-5', { items: [] }), { authorization: `Bearer ${KEY1}` })).status === 422);
  ok('API: payload over 64 KB rejected (413)', (await post('/api/orders', apiOrder('API-6', { notes: 'x'.repeat(70000) }), { authorization: `Bearer ${KEY1}` })).status === 413);
  await rpc(O.tok, 'integration_revoke_api_key', { p_key: k1.body.id });
  ok('API: revoked key 401', (await post('/api/orders', apiOrder('API-7'), { authorization: `Bearer ${KEY1}` })).status === 401);
  ok('Helper cannot revoke a key', /forbidden/.test(JSON.stringify((await rpc(HE.tok, 'integration_revoke_api_key', { p_key: k2.body.id })).body)));

  // ---------- WooCommerce
  const wsec = 'wc-secret-' + stamp;
  ok('WooCommerce: invalid store url refused', /invalid store url/.test(JSON.stringify((await rpc(O.tok, 'integration_connect_woocommerce', { p_business: B, p_store_url: 'http://x', p_webhook_secret: wsec })).body)));
  const wc = (await rpc(O.tok, 'integration_connect_woocommerce', { p_business: B, p_store_url: 'https://shop.example.com/', p_webhook_secret: wsec })).body;
  ok('WooCommerce: Owner connects', !!wc?.id, wc);
  ok('Helper cannot connect WooCommerce', /forbidden/.test(JSON.stringify((await rpc(HE.tok, 'integration_connect_woocommerce', { p_business: B, p_store_url: 'https://a.example.com', p_webhook_secret: wsec })).body)));
  const woo = { id: 9001, customer_note: 'Pintu belakang', billing: { first_name: 'Aina', last_name: 'Test', phone: '+60123456789' }, shipping: { first_name: 'Aina', last_name: 'Test', address_1: '[TEST] 2 Jalan Woo', city: 'Shah Alam', postcode: '40000', country: 'MY' }, line_items: [{ name: 'Kek', quantity: 1, price: 30 }] };
  const wraw = JSON.stringify(woo);
  const w1 = await post(`/woocommerce/${wc.id}`, wraw, { 'x-wc-webhook-signature': hmac(wsec, wraw) });
  ok('WooCommerce: valid signature creates an order', w1.status === 201 && !!w1.body?.order_reference, w1);
  ok('WooCommerce: bad signature rejected (401)', (await post(`/woocommerce/${wc.id}`, JSON.stringify({ ...woo, id: 9002 }), { 'x-wc-webhook-signature': hmac('wrong-secret', wraw) })).status === 401);
  ok('WooCommerce: replay of same order id = duplicate', (await post(`/woocommerce/${wc.id}`, wraw, { 'x-wc-webhook-signature': hmac(wsec, wraw) })).body?.duplicate === true);
  ok('WooCommerce: ping without signature accepted, no order', (await post(`/woocommerce/${wc.id}`, { webhook_id: 5 })).status === 200);
  ok('WooCommerce: unknown connection 404', (await post(`/woocommerce/${crypto.randomUUID()}`, wraw, { 'x-wc-webhook-signature': hmac(wsec, wraw) })).status === 404);

  // ---------- Shopify
  const ssec = 'shp-secret-' + stamp;
  ok('Shopify: invalid domain refused', /invalid shop domain/.test(JSON.stringify((await rpc(O.tok, 'integration_connect_shopify', { p_business: B, p_shop_domain: 'evil.com', p_webhook_secret: ssec })).body)));
  const sc = (await rpc(OP.tok, 'integration_connect_shopify', { p_business: B, p_shop_domain: 'https://cefflo-test.myshopify.com/', p_webhook_secret: ssec })).body;
  ok('Shopify: Operator connects (domain normalised)', !!sc?.id, sc);
  const shp = { id: 7001, note: '', shipping_address: { name: 'Farid Test', phone: '+60198765432', address1: '[TEST] 3 Jalan Shop', city: 'KL', zip: '50000', country: 'Malaysia' }, line_items: [{ title: 'Bunga', quantity: 3, price: '12.00' }] };
  const sraw = JSON.stringify(shp);
  const s1 = await post(`/shopify/${sc.id}`, sraw, { 'x-shopify-hmac-sha256': hmac(ssec, sraw), 'x-shopify-shop-domain': 'cefflo-test.myshopify.com' });
  ok('Shopify: valid HMAC + shop creates an order', s1.status === 201, s1);
  ok('Shopify: wrong shop domain rejected', (await post(`/shopify/${sc.id}`, sraw, { 'x-shopify-hmac-sha256': hmac(ssec, sraw), 'x-shopify-shop-domain': 'other.myshopify.com' })).status === 401);
  ok('Shopify: bad HMAC rejected', (await post(`/shopify/${sc.id}`, sraw, { 'x-shopify-hmac-sha256': 'AAAA', 'x-shopify-shop-domain': 'cefflo-test.myshopify.com' })).status === 401);

  // ---------- disconnect + audit
  await rpc(O.tok, 'integration_disconnect', { p_connection: sc.id });
  ok('Shopify: after disconnect, webhook 404', (await post(`/shopify/${sc.id}`, sraw, { 'x-shopify-hmac-sha256': hmac(ssec, sraw), 'x-shopify-shop-domain': 'cefflo-test.myshopify.com' })).status === 404);
  ok('disconnect removes the Vault secret', (await sql(`integration_connections?select=secret_id&id=eq.${sc.id}`))[0]?.secret_id === null);
  const ev = (await rpc(O.tok, 'integration_list', { p_business: B })).body?.events || [];
  ok('event log shows created, duplicate and rejected outcomes', ['created', 'duplicate', 'rejected'].every(o => ev.some(e => e.outcome === o)), ev.map(e => e.outcome));
  ok('exactly 4 integration orders created in total', (await orderCount(B)) === 4, await orderCount(B));
} catch (e) {
  ok('suite ran without exception', false, e.stack || e.message);
} finally {
  for (const b of businesses) if (b) await fetch(`${URL_}/rest/v1/businesses?id=eq.${b}`, { method: 'DELETE', headers: SH });
  let left = 0;
  for (const id of created) { await fetch(`${URL_}/rest/v1/profiles?id=eq.${id}`, { method: 'DELETE', headers: SH }); const r = await fetch(`${URL_}/auth/v1/admin/users/${id}`, { method: 'DELETE', headers: SH }); if (!r.ok) left++; }
  ok('cleanup: [TEST] businesses and accounts removed', left === 0);
  console.log(results.join('\n'));
  console.log(`\n${results.length - fails}/${results.length} passed`);
  process.exitCode = fails ? 1 : 0;
}
