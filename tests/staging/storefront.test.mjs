// Storefront V1 staging tests: anonymous customer contract, price integrity,
// abuse limits (spaced to stay under the limiter, which is itself verified below), publish gate, idempotency, order lands in the vendor's Orders.
// Staging only.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 150) : ''}`); if (!c) fails++; };
async function signIn(email, password = PW) { const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) }); return (await r.json()).access_token; }
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function sel(tok, path) { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);

const owner = await signIn(mail('owner'));
const B = (await rpc(owner, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;
const sf = (await rpc(owner, 'get_storefront', { p_business_id: B })).body;
const slug = sf.slug;
ok('setup: storefront slug', !!slug, slug);
const wasPublished = sf.published;
if (!wasPublished) await rpc(owner, 'set_storefront_published', { p_business_id: B, p_published: true });

// anonymous view
const pub = await rpc(null, 'public_storefront', { p_slug: slug });
ok('anonymous customer can open the published storefront', pub.status === 200 && Array.isArray(pub.body?.products), msg(pub));
const keys = JSON.stringify(Object.keys(pub.body || {})) + JSON.stringify(Object.keys(pub.body?.business || {}));
ok('storefront exposes no owner phone/email/address/ids of staff', !/phone|email|address|owner|user_id/i.test(keys), keys);
ok('product images are public display files only', JSON.stringify(pub.body?.products || []).indexOf('original') < 0);
const prod = pub.body.products.find(p => Number(p.display_price) > 0);
ok('setup: a priced product is listed', !!prod, prod && `${prod.name} RM${prod.display_price}`);
const bad = await rpc(null, 'public_storefront', { p_slug: 'no-such-store-' + Date.now() });
ok('unknown slug shows nothing', bad.status >= 400 || bad.body === null, msg(bad));

const base = { p_slug: slug, p_customer_name: '[TEST] Storefront Buyer', p_customer_phone: '+60 12-000 1005', p_delivery_address: '[TEST] Jalan Test 1, Kuala Lumpur', p_delivery_notes: 'staging test' };
// price integrity: client-supplied price is ignored
const key = crypto.randomUUID();
const order = await rpc(null, 'submit_storefront_order', { ...base, p_items: [{ product_id: prod.id, quantity: 2, display_price: 0.01, price: 0.01 }], p_idempotency_key: key });
ok('anonymous customer can place an order', order.status === 200, msg(order));
const again = await rpc(null, 'submit_storefront_order', { ...base, p_items: [{ product_id: prod.id, quantity: 2 }], p_idempotency_key: key });
const ref = order.body?.order_reference;
ok('same idempotency key replays the same order', again.status === 200 && again.body?.order_reference === ref && again.body?.replay === true, JSON.stringify(again.body).slice(0, 100));
const row = (await sel(owner, `orders?select=id,items,origin,customer_name,delivery_status&public_ref=eq.${ref}`)).body?.[0];
const oid = row?.id;
ok('order lands in the vendor\'s Orders', !!row, JSON.stringify(row || null).slice(0, 120));
const line = row?.items?.[0];
ok('server priced it from Products (client price ignored)', Number(line?.display_price_snapshot) === Number(prod.display_price) && Number(line?.line_subtotal_snapshot) === Math.round(prod.display_price * 2 * 100) / 100, JSON.stringify(line));
ok('origin marked as a public (storefront) order', ['public', 'storefront'].includes(row?.origin), row?.origin);
const trackingKeys = Object.keys(order.body || {});
ok('customer gets a tracking link/token', trackingKeys.some(k => /track/i.test(k)), trackingKeys.join(','));

// abuse limits (spaced to stay under the limiter, which is itself verified below)
const cases = [
  ['quantity 0', [{ product_id: prod.id, quantity: 0 }]],
  ['quantity 51', [{ product_id: prod.id, quantity: 51 }]],
  ['negative quantity', [{ product_id: prod.id, quantity: -2 }]],
  ['fractional quantity', [{ product_id: prod.id, quantity: 1.5 }]],
  ['unknown product', [{ product_id: '00000000-0000-0000-0000-000000000000', quantity: 1 }]],
  ['21 lines', Array.from({ length: 21 }, () => ({ product_id: prod.id, quantity: 1 }))],
  ['empty cart', []],
];
const pause = () => new Promise(r => setTimeout(r, 13000)); // limiter: 5 orders / 60 s per caller
for (const [label, items] of cases) { await pause(); const r = await rpc(null, 'submit_storefront_order', { ...base, p_items: items, p_idempotency_key: crypto.randomUUID() }); ok(`refused by validation: ${label}`, r.status >= 400 && !/rate limited/.test(msg(r)), msg(r)); }
await pause(); const noName = await rpc(null, 'submit_storefront_order', { ...base, p_customer_name: '', p_items: [{ product_id: prod.id, quantity: 1 }], p_idempotency_key: crypto.randomUUID() });
ok('refused by validation: missing customer name', noName.status >= 400 && !/rate limited/.test(msg(noName)), msg(noName));
// another business's product through this store
const vb = await signIn(process.env.STAGING_VENDOR_B_EMAIL, process.env.STAGING_VENDOR_B_PASSWORD);
const bBiz = (await rpc(vb, 'get_my_businesses')).body?.[0]?.business_id;
const bProd = (await sel(vb, `products?select=id&business_id=eq.${bBiz}&limit=1`)).body?.[0];
if (bProd) { const r = await rpc(null, 'submit_storefront_order', { ...base, p_items: [{ product_id: bProd.id, quantity: 1 }] }); ok("refused: another business's product", r.status >= 400, msg(r)); }
else ok("skipped: other business has no product to test with", true);

// the limiter itself: valid orders beyond 5 a minute are refused. (A refused
// order rolls back its own counter, so only real orders count - by design.)
await new Promise(r => setTimeout(r, 61000 - (Date.now() % 60000) + 500)); // start of a fresh window
let limited = false, placed = 0;
for (let i = 0; i < 7 && !limited; i++) { const r = await rpc(null, 'submit_storefront_order', { ...base, p_items: [{ product_id: prod.id, quantity: 1 }], p_idempotency_key: crypto.randomUUID() }); if (r.status === 200) placed++; limited = /rate limited/.test(msg(r)); }
ok('more than 5 orders a minute from one customer are rate limited', limited && placed <= 5, `${placed} placed before the limit`);
await new Promise(r => setTimeout(r, 61000));

// publish gate
await rpc(owner, 'set_storefront_published', { p_business_id: B, p_published: false });
const hidden = await rpc(null, 'public_storefront', { p_slug: slug });
ok('unpublished storefront is not shown', hidden.status >= 400 || hidden.body === null, msg(hidden));
await pause(); const blocked = await rpc(null, 'submit_storefront_order', { ...base, p_items: [{ product_id: prod.id, quantity: 1 }], p_idempotency_key: crypto.randomUUID() });
ok('unpublished storefront takes no orders', blocked.status >= 400 && !/rate limited/.test(msg(blocked)), msg(blocked));
await rpc(owner, 'set_storefront_published', { p_business_id: B, p_published: wasPublished !== false });
// anonymous cannot read orders
const anonOrders = await sel(null, `orders?select=id&limit=1`);
ok('anonymous cannot read orders', anonOrders.status >= 400 || (Array.isArray(anonOrders.body) && anonOrders.body.length === 0), anonOrders.status);

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
console.log('TEST_ORDER_ID=' + oid);
process.exit(fails ? 1 : 0);
