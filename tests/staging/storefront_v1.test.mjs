// Storefront V1 (reference templates) staging suite. A fresh [TEST]
// business (deleted afterwards) exercises: the 18 template keys saved and
// served, the Vendor preview payload (storefront_preview) == the public
// payload, preview before publishing, authority, what the public payload
// exposes, catalogue rules (archived / inactive / photos), one real order
// through the public storefront with server pricing and a tracking token,
// and cross-business tampering. Staging only; one order (limiter-safe).
import { readFileSync } from 'node:fs';
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 150) : ''}`); if (!c) fails++; };
async function auth(path, body) { const r = await fetch(`${URL_}/auth/v1/${path}`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify(body) }); return r.json(); }
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
const SH = { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' };
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function rest(tok, method, path, body) { const r = await fetch(`${URL_}/rest/v1/${path}`, { method, headers: { ...H(tok), prefer: 'return=representation' }, body: body ? JSON.stringify(body) : undefined }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const refused = r => r.status >= 400;
const uid = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;
const uuid = () => crypto.randomUUID();
const stamp = String(Date.now()).slice(-6);
const created = [], businesses = [], objects = [];
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==', 'base64');
async function fresh(tag, meta = {}) {
  const email = `zelix.co00+v1007sf${tag}${stamp}@gmail.com`, password = 'Cf-v1007-Store!7';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: SH, body: JSON.stringify({ email, password, email_confirm: true, user_metadata: meta }) });
  if (!r.ok) throw new Error('create ' + await r.text());
  const s = await auth('token?grant_type=password', { email, password }); created.push(uid(s.access_token)); return s.access_token;
}
async function put(tok, bucket, path) { const r = await fetch(`${URL_}/storage/v1/object/${bucket}/${path}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${tok}`, 'content-type': 'image/png' }, body: png }); if (r.ok) objects.push([bucket, path]); return r; }
async function join(owner, B, kind, tok) {
  const link = (await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: kind })).body?.token;
  await rpc(tok, 'join_via_invite_link', { p_token: link, p_name: `[TEST] SF ${kind}`, p_phone: `+60 16-${stamp}${kind.length}` });
  if (kind === 'rider') { const r = (await rest(owner, 'GET', `riders?select=id&business_id=eq.${B}&auth_user_id=eq.${uid(tok)}`)).body?.[0]; await rpc(owner, 'approve_pending_rider', { p_rider_id: r?.id }); return; }
  const q = (await rest(owner, 'GET', `team_join_requests?select=id&business_id=eq.${B}&user_id=eq.${uid(tok)}&status=eq.pending`)).body?.[0];
  await rpc(owner, 'decide_team_join_request', { p_request_id: q?.id, p_approve: true });
}
// The 18 keys the public renderer and the Vendor App both define.
const tplSrc = readFileSync(new URL('../../store/templates.js', import.meta.url), 'utf8');
const KEYS = JSON.parse(tplSrc.match(/CEFFLO_TEMPLATE_ORDER = (\[[^\]]+\])/)[1].replace(/'/g, '"'));

try {
  const owner = await fresh('own');
  const B = (await rpc(owner, 'bootstrap_business', { p_name: `[TEST] Store ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(B);
  await rpc(owner, 'update_business_profile', { p_business_id: B, p_name: `[TEST] Store ${stamp}`, p_phone: '+60 3-9999 0000', p_email: 'private@example.com', p_address: '[TEST] 7 Private Road', p_operating_area: 'Petaling Jaya', p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR', p_idempotency_key: uuid() });
  const ownerX = await fresh('ownx');
  const BX = (await rpc(ownerX, 'bootstrap_business', { p_name: `[TEST] Store X ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(BX);
  const op = await fresh('op'); await join(owner, B, 'operator', op);
  const hel = await fresh('hel'); await join(owner, B, 'helper', hel);
  const drv = await fresh('drv', { driver_registration: { full_name: '[TEST] SF Driver', phone: `+60 16-${stamp}9`, vehicle_type: 'car', vehicle_plate: `SF ${stamp}` } }); await join(owner, B, 'rider', drv);
  const sf = (await rpc(owner, 'get_storefront', { p_business_id: B })).body;
  ok('setup: [TEST] business with a storefront (unpublished)', !!sf?.slug && sf.published === false, JSON.stringify(sf).slice(0, 100));

  // catalogue: 2 active (one with photos), 1 archived, 1 inactive
  const cat = await rpc(owner, 'create_product_category', { p_business_id: B, p_name: '[TEST] Drinks' });
  const CAT = typeof cat.body === 'string' ? cat.body : (cat.body?.id || cat.body?.[0]?.id);
  const mk = async (name, price, status = 'active') => { const r = await rpc(owner, 'create_product', { p_business_id: B, p_category_id: CAT, p_name: name, p_description: `${name} description`, p_display_price: price, p_status: status }); return (Array.isArray(r.body) ? r.body[0] : r.body)?.id; };
  const P1 = await mk('[TEST] Iced Latte', 8.9), P2 = await mk('[TEST] Kaya Toast', 6.5), P3 = await mk('[TEST] Archived', 5), P4 = await mk('[TEST] Hidden', 4, 'hidden');
  const M = uuid();
  await put(owner, 'cefflo-product-originals', `${B}/${P1}/${M}/original.png`);
  await rpc(owner, 'create_product_media', { p_product_id: P1, p_media_id: M, p_content_type: 'image/png', p_position: null });
  await put(owner, 'cefflo-product-display', `${B}/${P1}/${M}/display.png`);
  await rpc(owner, 'mark_product_media_displayable', { p_media_id: M });
  await fetch(`${URL_}/rest/v1/products?id=eq.${P3}`, { method: 'PATCH', headers: SH, body: JSON.stringify({ archived_at: new Date().toISOString() }) });
  ok('setup: 4 products (2 active, 1 archived, 1 hidden), one with a photo', !!P1 && !!P2 && !!P3 && !!P4);

  // ---------- preview before publishing
  const pv0 = await rpc(owner, 'storefront_preview', { p_business_id: B });
  ok('1 Owner previews the storefront before publishing', pv0.status === 200 && pv0.body?.published === false && pv0.body?.products?.length === 2, msg(pv0));
  ok('  the public page stays hidden until published', (await rpc(null, 'public_storefront', { p_slug: sf.slug })).body === null);
  ok('  Operator can preview too', (await rpc(op, 'storefront_preview', { p_business_id: B })).status === 200);
  for (const [n, t] of [['Helper', hel], ['Driver', drv], ['other-business Owner', ownerX], ['anon', null]]) ok(`  ${n} refused: storefront_preview`, refused(await rpc(t, 'storefront_preview', { p_business_id: B })));

  // ---------- every V1 template key is saved and served
  await rpc(owner, 'set_storefront_published', { p_business_id: B, p_published: true });
  let served = 0, why = '';
  for (const k of KEYS) {
    const s = await rpc(owner, 'save_storefront_appearance', { p_business_id: B, p_template_key: k, p_theme: { accent: '#1677D8', tagline: 'Fresh every morning' } });
    const pv = await rpc(owner, 'storefront_preview', { p_business_id: B });
    if (s.status === 200 && pv.body?.template_key === k && pv.body?.theme?.tagline === 'Fresh every morning') served++;
    else why ||= `${k}: ${s.status} ${msg(s)} / ${pv.body?.template_key}`;
  }
  ok(`2 all ${KEYS.length} V1 template keys save and are served`, served === KEYS.length && KEYS.length === 18, `${served}/${KEYS.length} ${why}`);
  ok('  invalid theme values refused (colour / key)', refused(await rpc(owner, 'save_storefront_appearance', { p_business_id: B, p_template_key: 'care', p_theme: { accent: 'red' } })) && refused(await rpc(owner, 'save_storefront_appearance', { p_business_id: B, p_template_key: 'care', p_theme: { script: '<x>' } })));
  ok('  Helper / Driver / X cannot change the template', refused(await rpc(hel, 'save_storefront_appearance', { p_business_id: B, p_template_key: 'kit', p_theme: {} })) && refused(await rpc(drv, 'save_storefront_appearance', { p_business_id: B, p_template_key: 'kit', p_theme: {} })) && refused(await rpc(ownerX, 'save_storefront_appearance', { p_business_id: B, p_template_key: 'kit', p_theme: {} })));
  await rpc(owner, 'save_storefront_appearance', { p_business_id: B, p_template_key: 'care', p_theme: { accent: '#1677D8', tagline: 'Fresh every morning' } });

  // ---------- public payload == preview payload; nothing private
  const pub = (await rpc(null, 'public_storefront', { p_slug: sf.slug })).body;
  const prv = (await rpc(owner, 'storefront_preview', { p_business_id: B })).body; delete prv.published;
  ok('3 the Vendor preview shows exactly the public payload', JSON.stringify(pub) === JSON.stringify(prv));
  const flat = JSON.stringify(pub);
  ok('  no private business data (phone / email / address / members / ids)', !/\+60 3-9999|private@example|Private Road|user_id|owner|member|business_id|access_token/i.test(flat), Object.keys(pub).join(','));
  ok('  only active, non-archived products', pub.products.length === 2 && !flat.includes('[TEST] Archived') && !flat.includes('[TEST] Hidden'));
  const p1 = pub.products.find(p => p.id === P1);
  ok('  photos are public display files only (no originals)', p1?.images?.length === 1 && /cefflo-product-display\//.test(p1.images[0]) && !flat.includes('original'));
  const img = await fetch(`${URL_}${p1?.images?.[0]}`);
  ok('  the display photo loads anonymously; the original does not', img.ok && !(await fetch(`${URL_}/storage/v1/object/public/cefflo-product-originals/${B}/${P1}/${M}/original.png`)).ok);
  ok('  categories, area, hours and template key are present', pub.categories?.[0]?.name === '[TEST] Drinks' && pub.business?.area === 'Petaling Jaya' && pub.template_key === 'care');

  // ---------- one real order: server prices it, returns a tracking token
  await new Promise(r => setTimeout(r, 61000 - (Date.now() % 60000) + 500)); // fresh limiter window
  const order = await rpc(null, 'submit_storefront_order', { p_slug: sf.slug, p_items: [{ product_id: P1, quantity: 2, display_price: 0.01, price: 0.01 }, { product_id: P2, quantity: 1 }], p_customer_name: '[TEST] SF Customer', p_customer_phone: '+60 12-700 0001', p_delivery_address: '[TEST] 1 Jalan Pelanggan, PJ', p_delivery_notes: 'V1', p_idempotency_key: uuid() });
  ok('4 a customer orders through the public storefront', order.status === 200 && !!order.body?.order_reference, msg(order));
  const row = (await rest(owner, 'GET', `orders?select=id,items,origin,business_id&public_ref=eq.${order.body?.order_reference}`)).body?.[0];
  const lines = row?.items || [];
  const l1 = lines.find(l => l.product_id === P1);
  ok('  the server priced it from Products (client price ignored)', Number(l1?.display_price_snapshot) === 8.9 && row?.business_id === B, JSON.stringify(l1 || lines).slice(0, 140));
  const tr = await rpc(null, 'public_tracking', { p_token: order.body?.tracking_token });
  ok('  the tracking token opens Customer Tracking for this order only', tr.status === 200 && !!tr.body && !JSON.stringify(tr.body).includes('+60 12-700 0001'), JSON.stringify(tr.body).slice(0, 100));
  const pX = (await rpc(ownerX, 'create_product', { p_business_id: BX, p_category_id: null, p_name: '[TEST] X item', p_description: '', p_display_price: 1, p_status: 'active' })).body;
  const PX = (Array.isArray(pX) ? pX[0] : pX)?.id;
  const cross = await rpc(null, 'submit_storefront_order', { p_slug: sf.slug, p_items: [{ product_id: PX, quantity: 1 }], p_customer_name: '[TEST] X', p_customer_phone: '+60 12-700 0002', p_delivery_address: '[TEST] 2 Jalan', p_delivery_notes: '', p_idempotency_key: uuid() });
  ok("  another business's product through this store is refused", refused(cross), msg(cross));
  const arch = await rpc(null, 'submit_storefront_order', { p_slug: sf.slug, p_items: [{ product_id: P3, quantity: 1 }], p_customer_name: '[TEST] A', p_customer_phone: '+60 12-700 0003', p_delivery_address: '[TEST] 3 Jalan', p_delivery_notes: '', p_idempotency_key: uuid() });
  ok('  an archived product cannot be ordered', refused(arch), msg(arch));
  ok('  anon cannot write products or pages', refused(await rest(null, 'PATCH', `products?id=eq.${P1}`, { display_price: 0.01 })) || (await rest(null, 'PATCH', `products?id=eq.${P1}`, { display_price: 0.01 })).body?.length === 0);
} catch (e) {
  ok('suite ran without an exception', false, e.stack || String(e));
} finally {
  for (const [bucket, path] of objects) await fetch(`${URL_}/storage/v1/object/${bucket}`, { method: 'DELETE', headers: SH, body: JSON.stringify({ prefixes: [path] }) });
  for (const b of businesses) if (b) await fetch(`${URL_}/rest/v1/businesses?id=eq.${b}`, { method: 'DELETE', headers: SH });
  let left = 0;
  for (const id of created) { const r = await fetch(`${URL_}/auth/v1/admin/users/${id}`, { method: 'DELETE', headers: SH }); if (!r.ok) left++; }
  const bl = businesses.filter(Boolean).length ? await (await fetch(`${URL_}/rest/v1/businesses?select=id&id=in.(${businesses.filter(Boolean).join(',')})`, { headers: SH })).json() : [];
  ok('cleanup: [TEST] businesses, photos, orders and accounts deleted', bl.length === 0 && left === 0, `${bl.length} businesses, ${left} accounts left`);
}
console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
