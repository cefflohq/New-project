// Integrations Phase 2 (staging only; migration 20261010090000 + Edge Function
// integrations-inbound). Wix posts to a private per-connection token URL;
// Google Sheets / Drive Apps Scripts post to /api/orders with a key bound to
// their own connection. Owner/Operator only; tokens and keys shown once and
// never readable later; reconnect/disconnect revoke the old secret.
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
const post = async (path, body, headers = {}) => { const r = await fetch(`${FN}${path}`, { method: 'POST', headers: { 'content-type': 'application/json', ...headers }, body: JSON.stringify(body) }); return { status: r.status, body: await r.json().catch(() => null) }; };
const stamp = String(Date.now()).slice(-6), created = [], businesses = [];
async function fresh(tag) {
  const email = `zelix.co00+int2${tag}${stamp}@gmail.com`, password = 'Cf-int-Test!7';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: SH, body: JSON.stringify({ email, password, email_confirm: true }) });
  const u = await r.json(); if (!r.ok) throw new Error(JSON.stringify(u)); created.push(u.id);
  const tok = (await (await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) })).json()).access_token;
  return { id: u.id, tok };
}
const member = (b, u, role) => fetch(`${URL_}/rest/v1/business_members`, { method: 'POST', headers: SH, body: JSON.stringify({ business_id: b, user_id: u, role, status: 'active' }) });
const orderCount = async b => (await sql(`orders?select=id&business_id=eq.${b}&origin=eq.integration`)).length;
const wixOrder = id => ({ data: { id, buyerNote: 'Pagar biru', billingInfo: { address: { addressLine1: '[TEST] 5 Jalan Wix', city: 'Shah Alam', postalCode: '40000', country: 'MY' }, contactDetails: { firstName: 'Nur', lastName: 'Test', phone: '+60123334444' } }, lineItems: [{ productName: { original: 'Brownies' }, quantity: 3, price: { amount: '12.50' } }] } });
const sheetRow = (ext, extra = {}) => ({ external_id: ext, customer_name: '[TEST] Sheet', customer_phone: '0123456789', delivery_address: '[TEST] 6 Jalan Sheet', notes: '', items: [{ name: 'Kek', quantity: 2, price: 30 }], ...extra });

try {
  const O = await fresh('owner'), OP = await fresh('op'), HE = await fresh('helper'), X = await fresh('outsider');
  const B = (await rpc(O.tok, 'bootstrap_business', { p_name: `[TEST] Int2 ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(B);
  const B2 = (await rpc(X.tok, 'bootstrap_business', { p_name: `[TEST] Int2 other ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(B2);
  await member(B, OP.id, 'operator'); await member(B, HE.id, 'helper');

  // ---------- Wix
  ok('Wix: invalid site url refused', /invalid site url/.test(JSON.stringify((await rpc(O.tok, 'integration_connect_wix', { p_business: B, p_site_url: 'http://x' })).body)));
  ok('Wix: Helper cannot connect', /forbidden/.test(JSON.stringify((await rpc(HE.tok, 'integration_connect_wix', { p_business: B, p_site_url: 'https://a.example.com' })).body)));
  ok('Wix: outsider cannot connect', /forbidden/.test(JSON.stringify((await rpc(X.tok, 'integration_connect_wix', { p_business: B, p_site_url: 'https://a.example.com' })).body)));
  ok('Wix: anon cannot connect', (await rpc(null, 'integration_connect_wix', { p_business: B, p_site_url: 'https://a.example.com' })).status >= 400);
  const w = (await rpc(O.tok, 'integration_connect_wix', { p_business: B, p_site_url: 'https://www.cefflo-test.com/' })).body;
  ok('Wix: Owner connects, token (48 hex) returned once', !!w?.id && /^[0-9a-f]{48}$/.test(w?.token || ''), w);
  const list1 = (await rpc(O.tok, 'integration_list', { p_business: B })).body;
  ok('Wix: list shows connection without the token', list1?.connections?.some(c => c.provider === 'wix') && !JSON.stringify(list1).includes(w.token));
  const w1 = await post(`/wix/${w.id}/${w.token}`, wixOrder('wix-1'));
  ok('Wix: valid token creates an order', w1.status === 201 && !!w1.body?.order_reference, w1);
  const row = (await sql(`orders?select=business_id,customer_name,delivery_address,items,notes&id=eq.${w1.body?.order_id}`))[0];
  ok('Wix: order mapped (name, address, items, note)', row?.business_id === B && row.customer_name === 'Nur Test' && /Jalan Wix, Shah Alam/.test(row.delivery_address) && row.items?.[0]?.name === 'Brownies' && row.items[0].qty === 3 && row.notes === 'Pagar biru', row);
  ok('Wix: replay = duplicate, no second order', (await post(`/wix/${w.id}/${w.token}`, wixOrder('wix-1'))).body?.duplicate === true);
  ok('Wix: wrong token 401', (await post(`/wix/${w.id}/${'0'.repeat(48)}`, wixOrder('wix-2'))).status === 401);
  ok('Wix: missing token 401', (await post(`/wix/${w.id}`, wixOrder('wix-2'))).status === 401);
  ok('Wix: unknown connection 404', (await post(`/wix/${crypto.randomUUID()}/${w.token}`, wixOrder('wix-2'))).status === 404);
  ok('Wix: flat customised body accepted', (await post(`/wix/${w.id}/${w.token}`, { external_id: 'wix-flat', customer_name: '[TEST] Flat', customer_phone: '0129998888', delivery_address: '[TEST] 7 Jalan Flat', items: 'Kek x2, Roti x1' })).status === 201);
  const w2 = (await rpc(OP.tok, 'integration_connect_wix', { p_business: B, p_site_url: 'https://www.cefflo-test.com' })).body;
  ok('Wix: Operator reconnects; old URL stops working (404)', !!w2?.token && (await post(`/wix/${w.id}/${w.token}`, wixOrder('wix-3'))).status === 404);
  ok('Wix: new URL works', (await post(`/wix/${w2.id}/${w2.token}`, wixOrder('wix-3'))).status === 201);

  // ---------- Google Sheets / Drive
  ok('Google: invalid provider refused', /invalid provider/.test(JSON.stringify((await rpc(O.tok, 'integration_connect_google', { p_business: B, p_provider: 'shopify' })).body)));
  ok('Google: Helper cannot connect', /forbidden/.test(JSON.stringify((await rpc(HE.tok, 'integration_connect_google', { p_business: B, p_provider: 'google_sheets' })).body)));
  const gs = (await rpc(O.tok, 'integration_connect_google', { p_business: B, p_provider: 'google_sheets' })).body;
  ok('Sheets: Owner gets a connection key (shown once)', /^cfk_live_[0-9a-f]{48}$/.test(gs?.key || ''), gs);
  const s1 = await post('/api/orders', sheetRow('SHEET:0:2'), { authorization: `Bearer ${gs.key}` });
  ok('Sheets: row creates an order', s1.status === 201, s1);
  ok('Sheets: "Nasi lemak x2, Kopi x1" item text parsed', (await post('/api/orders', sheetRow('SHEET:0:3', { items: 'Nasi lemak x2, Kopi x1' }), { authorization: `Bearer ${gs.key}` })).status === 201
    && (await sql(`orders?select=items&business_id=eq.${B}&order=created_at.desc&limit=1`))[0]?.items?.map(i => `${i.name}:${i.qty}`).join(',') === 'Nasi lemak:2,Kopi:1');
  const ev = (await rpc(O.tok, 'integration_list', { p_business: B })).body;
  ok('Sheets: events labelled google_sheets', ev?.events?.some(e => e.provider === 'google_sheets' && e.outcome === 'created'));
  ok('Sheets: key not listed among general API keys', (ev?.api_keys || []).length === 0, ev?.api_keys);
  const gs2 = (await rpc(OP.tok, 'integration_connect_google', { p_business: B, p_provider: 'google_sheets' })).body;
  ok('Sheets: new script revokes the old key (401)', !!gs2?.key && (await post('/api/orders', sheetRow('SHEET:0:4'), { authorization: `Bearer ${gs.key}` })).status === 401);
  const gd = (await rpc(O.tok, 'integration_connect_google', { p_business: B, p_provider: 'google_drive' })).body;
  ok('Drive: own key creates an order', (await post('/api/orders', sheetRow('FILE1:2'), { authorization: `Bearer ${gd.key}` })).status === 201);
  const gdConn = ((await rpc(O.tok, 'integration_list', { p_business: B })).body?.connections || []).find(c => c.provider === 'google_drive');
  await rpc(O.tok, 'integration_disconnect', { p_connection: gdConn?.id });
  ok('Drive: after disconnect the key is refused (401)', (await post('/api/orders', sheetRow('FILE1:3'), { authorization: `Bearer ${gd.key}` })).status === 401);
  const ak = (await rpc(O.tok, 'integration_create_api_key', { p_business: B })).body;
  ok('general API keys still work and list alone', !!ak?.key && ((await rpc(O.tok, 'integration_list', { p_business: B })).body?.api_keys || []).length === 1);

  // ---------- script templates
  for (const k of ['sheets', 'drive']) {
    const r = await fetch(`${FN}/script/${k}`); const txt = await r.text();
    ok(`script/${k}: served as text with placeholders, no key`, r.status === 200 && txt.includes('__CEFFLO_KEY__') && txt.includes('function cefflo_setup') && !/cfk_live_[0-9a-f]{48}/.test(txt));
  }
  ok('script: unknown template 405/404', (await fetch(`${FN}/script/other`)).status >= 400);

  ok('payloads never land in another business', (await sql(`orders?select=id&business_id=eq.${B2}`)).length === 0);
  ok('exactly 6 integration orders created', (await orderCount(B)) === 6, await orderCount(B));
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
