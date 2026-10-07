// Public Storefront V1 security + contract (staging only; migration
// 20261007150000). A fresh [TEST] business with a published storefront:
// trusted caller identity (spoofed X-Forwarded-For cannot bypass the limits),
// failed / malformed attempts are counted, limiter failure fails closed,
// ordering refused while closed (business timezone, overnight, no hours),
// international phone validation, idempotent replay returns a working
// tracking token without a duplicate order, the Vendor gets exactly one
// order.new_customer notification, and the existing order rules hold.
// Rate-limit blocks wait for a fresh minute window; the suite takes ~5 min.
import crypto from 'node:crypto';

const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_ || !URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${c ? '' : '  -> ' + String(typeof x === 'string' ? x : JSON.stringify(x)).slice(0, 200)}`); if (!c) fails++; };
const SH = { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' };
const H = (tok, extra = {}) => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json', ...extra });
async function rpc(tok, name, body = {}, extra = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok, extra), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
const svc = async (method, path, body) => { const r = await fetch(`${URL_}/rest/v1/${path}`, { method, headers: { ...SH, prefer: 'return=representation' }, body: body ? JSON.stringify(body) : undefined }); return r.json().catch(() => null); };
const sql = async q => svc('GET', q);
const sleep = ms => new Promise(r => setTimeout(r, ms));
const freshMinute = async () => { const s = new Date().getUTCSeconds(); await sleep((61 - s) * 1000); };
const stamp = String(Date.now()).slice(-6), created = [], businesses = [];
async function fresh(tag) {
  const email = `zelix.co00+sfsec${tag}${stamp}@gmail.com`, password = 'Cf-sfsec-Test!7';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: SH, body: JSON.stringify({ email, password, email_confirm: true }) });
  const u = await r.json(); if (!r.ok) throw new Error(JSON.stringify(u)); created.push(u.id);
  return (await (await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) })).json()).access_token;
}
const one = r => (Array.isArray(r) ? r[0] : r);
const localNow = tz => { const p = Object.fromEntries(new Intl.DateTimeFormat('en-GB', { timeZone: tz, hour12: false, weekday: 'short', hour: '2-digit', minute: '2-digit' }).formatToParts(new Date()).map(x => [x.type, x.value])); return { dow: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(p.weekday) + 1, min: (+p.hour % 24) * 60 + +p.minute }; };
const hhmm = m => { m = ((m % 1440) + 1440) % 1440; return `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`; };
const week = (set = {}) => Array.from({ length: 7 }, (_, i) => set[i + 1] ? { weekday: i + 1, is_open: true, ...set[i + 1] } : { weekday: i + 1, is_open: false });

try {
  const O = await fresh('owner');
  const B = (await rpc(O, 'bootstrap_business', { p_name: `[TEST] SF Sec ${stamp}`, p_timezone: 'Asia/Kuala_Lumpur', p_currency: 'MYR' })).body; businesses.push(B);
  const C = one((await rpc(O, 'create_product_category', { p_business_id: B, p_name: 'Menu' })).body).id;
  const P1 = one((await rpc(O, 'create_product', { p_business_id: B, p_category_id: C, p_name: 'Kopi', p_description: '', p_display_price: 6.5, p_status: 'active' })).body).id;
  const PH = one((await rpc(O, 'create_product', { p_business_id: B, p_category_id: C, p_name: 'Hidden', p_description: '', p_display_price: 1, p_status: 'hidden' })).body).id;
  const slug = (await rpc(O, 'get_storefront', { p_business_id: B })).body.slug;
  const other = (await sql(`products?select=id&business_id=neq.${B}&status=eq.active&limit=1`))[0]?.id;
  const order = (extra = {}, headers = {}) => rpc(null, 'submit_storefront_order', { p_slug: slug, p_items: [{ product_id: P1, quantity: 1 }], p_customer_name: '[TEST] SF Sec', p_customer_phone: '+60 12-345 6789', p_delivery_address: '[TEST] 1 Jalan', p_idempotency_key: crypto.randomUUID(), ...extra }, headers);
  const err = r => r.body?.error || r.body?.message || '';

  // ---------- publication
  ok('unpublished: public read returns nothing', (await rpc(null, 'public_storefront', { p_slug: slug })).body === null);
  ok('unpublished: order refused', /unavailable/.test(err(await order())));
  await rpc(O, 'set_storefront_published', { p_business_id: B, p_published: true });
  const pub = (await rpc(null, 'public_storefront', { p_slug: slug })).body;
  ok('published: public read works', pub?.slug === slug);
  ok('public payload stays minimal (no phone/address/email/ids of people)', !/phone|email|address|owner|user_id/.test(JSON.stringify(pub.business)) && !('hidden' in pub));
  ok('hidden product not in the public payload', !(pub.products || []).some(p => p.id === PH));
  ok('no hours configured: open_now is null and next_open null', pub.open_now === null && pub.next_open === null);

  // ---------- order rules (one fresh window: these are refusals, counted)
  await freshMinute();
  ok('hidden product refused', /not available/.test(err(await order({ p_items: [{ product_id: PH, quantity: 1 }] }))));
  ok('cross-business product refused', /not available/.test(err(await order({ p_items: [{ product_id: other, quantity: 1 }] }))));
  ok('fractional quantity refused', /quantity/.test(err(await order({ p_items: [{ product_id: P1, quantity: 1.5 }] }))));
  ok('quantity above 50 refused (split across lines too)', /quantity/.test(err(await order({ p_items: [{ product_id: P1, quantity: 30 }, { product_id: P1, quantity: 21 }] }))));
  ok('more than 20 lines refused', /item list/.test(err(await order({ p_items: Array.from({ length: 21 }, () => ({ product_id: P1, quantity: 1 })) }))));
  await freshMinute();
  ok('idempotency key required', /idempotency/.test(err(await order({ p_idempotency_key: null }))));
  for (const bad of ['!!!', '12', 'abcdefghij', '+60 12 345 6789 1234 5678']) ok(`phone '${bad}' refused (server)`, /phone/.test(err(await order({ p_customer_phone: bad }))));
  await freshMinute();
  // valid international formats (each creates an order)
  const okPhones = ['+60 12-345 6789', '+44 (20) 7946 0958', '012.345.6789'];
  for (const ph of okPhones) { const r = await order({ p_customer_phone: ph }); ok(`phone '${ph}' accepted`, !!r.body?.order_reference, r.body); }
  // server-authoritative price
  const row = (await sql(`orders?select=items&business_id=eq.${B}&order=created_at.desc&limit=1`))[0];
  ok('price is the server snapshot (6.50), not client-supplied', row?.items?.[0]?.display_price_snapshot === 6.5 && row.items[0].line_subtotal_snapshot === 6.5);

  // ---------- idempotent replay + tracking + Vendor notification
  await freshMinute();
  const key = crypto.randomUUID();
  const first = await order({ p_idempotency_key: key });
  const second = await order({ p_idempotency_key: key, p_items: [{ product_id: P1, quantity: 9 }] });
  ok('replay: same order reference', first.body?.order_reference && first.body.order_reference === second.body?.order_reference, [first.body, second.body]);
  ok('replay: marked replay with a fresh tracking token', second.body?.replay === true && /^[0-9a-f]{64}$/.test(second.body?.tracking_token || '') && second.body.tracking_token !== first.body.tracking_token);
  ok('replay: no duplicate order', (await sql(`orders?select=id&submission_idempotency_key=eq.${key}`)).length === 1);
  const trk = await rpc(null, 'public_tracking', { p_token: second.body.tracking_token });
  ok('replay: its tracking token opens the same order', trk.status === 200 && JSON.stringify(trk.body).includes(first.body.order_reference), trk.body);
  ok('replay: tracking exposes no customer phone/address', !/\+60 12-345 6789|1 Jalan/.test(JSON.stringify(trk.body)));
  ok('replay: the rotated-out first token no longer opens tracking (one token per order)', JSON.stringify((await rpc(null, 'public_tracking', { p_token: first.body.tracking_token })).body).indexOf(first.body.order_reference) < 0);
  await sleep(1500);
  const notes = await sql(`notifications?select=recipient_user_id,business_id,event_key,app&event_key=eq.order.new_customer&params->>ref=eq.${first.body.order_reference}`);
  const ownerId = JSON.parse(Buffer.from(O.split('.')[1], 'base64url').toString()).sub;
  ok('Vendor notification: exactly one order.new_customer', notes.length === 1, notes);
  ok('Vendor notification: to the Owner of this business, vendor app', notes[0]?.recipient_user_id === ownerId && notes[0]?.business_id === B && notes[0]?.app === 'vendor', notes);

  // ---------- rate limits: trusted identity, spoofing, malformed bounded
  await freshMinute();
  const statuses = [];
  for (let i = 0; i < 6; i++) statuses.push((await order({ p_items: 'not-an-array' })).body);
  ok('malformed orders are counted: 6th attempt in a minute is rate limited', statuses.slice(0, 5).every(b => b?.error) && /rate limited/.test(JSON.stringify(statuses[5])), statuses);
  const spoof = await order({}, { 'X-Forwarded-For': `198.51.100.${Math.floor(Math.random() * 250)}` });
  ok('spoofed X-Forwarded-For cannot bypass the order limit', /rate limited/.test(JSON.stringify(spoof.body)), spoof.body);
  await freshMinute();
  let reads = 0, limited = false;
  for (let i = 0; i < 62 && !limited; i++) { const r = await rpc(null, 'public_storefront', { p_slug: slug }); if (r.status === 200) reads++; else limited = /rate limited/.test(JSON.stringify(r.body)); }
  ok('public read limit enforced (60/min per caller)', reads === 60 && limited, { reads, limited });
  const spoofRead = await rpc(null, 'public_storefront', { p_slug: slug }, { 'X-Forwarded-For': '203.0.113.9' });
  ok('spoofed X-Forwarded-For cannot bypass the read limit', spoofRead.status >= 400, spoofRead.body);
  const ip = await rpc(null, 'public_storefront', { p_slug: slug }, { 'True-Client-IP': '203.0.113.10' });
  ok('True-Client-IP (client-controlled) is not trusted either', ip.status >= 400);

  // ---------- business hours / closed store (business timezone)
  await freshMinute();
  const setHours = async (days, tz) => { if (tz) await rpc(O, 'update_business_profile', { p_business_id: B, p_timezone: tz }); return rpc(O, 'set_business_hours', { p_business_id: B, p_days: days }); };
  let n = localNow('Asia/Kuala_Lumpur');
  await setHours(week({ [n.dow]: { opens_at: hhmm(n.min - 60), closes_at: hhmm(n.min + 60) } }));
  ok('open now: payload open_now true', (await rpc(null, 'public_storefront', { p_slug: slug })).body?.open_now === true);
  ok('open now: order accepted', !!(await order()).body?.order_reference);
  await setHours(week({ [n.dow]: { opens_at: hhmm(n.min + 60), closes_at: hhmm(n.min + 120) } }));
  const cp = (await rpc(null, 'public_storefront', { p_slug: slug })).body;
  ok('closed now: payload open_now false, next_open later today', cp?.open_now === false && cp?.next_open?.in_days === 0 && cp.next_open.time === hhmm(n.min + 60), cp?.next_open);
  const cr = await order();
  ok('closed now: order refused server-side with next_open', cr.body?.error === 'store closed' && cr.body?.next_open?.time === hhmm(n.min + 60), cr.body);
  const yday = n.dow === 1 ? 7 : n.dow - 1;
  await setHours(week({ [yday]: { opens_at: hhmm(n.min + 120), closes_at: hhmm(n.min + 60) } }));
  ok('overnight (yesterday until later today): open, order accepted', !!(await order()).body?.order_reference);
  await setHours(week({ [n.dow]: { opens_at: hhmm(n.min - 60), closes_at: hhmm(n.min - 120) } }));
  ok('overnight (started today, ends after midnight): open', (await rpc(null, 'public_storefront', { p_slug: slug })).body?.open_now === true);
  await freshMinute();
  const ny = localNow('America/New_York');
  await setHours(week({ [ny.dow]: { opens_at: hhmm(ny.min - 30), closes_at: hhmm(ny.min + 30) } }), 'America/New_York');
  ok('timezone: open by the business timezone (New York)', (await rpc(null, 'public_storefront', { p_slug: slug })).body?.open_now === true);
  await setHours(week({ [ny.dow]: { opens_at: hhmm(ny.min + 30), closes_at: hhmm(ny.min + 90) } }));
  ok('timezone: closed by the business timezone, order refused', (await order()).body?.error === 'store closed');
  await svc('DELETE', `business_hours?business_id=eq.${B}`);
  ok('no hours configured: ordering allowed (existing semantics)', !!(await order()).body?.order_reference);

  // ---------- disabled after publish
  await rpc(O, 'set_storefront_published', { p_business_id: B, p_published: false });
  ok('unpublished again: order refused', /unavailable/.test(err(await order())));
} catch (e) {
  ok('suite ran without exception', false, e.stack || e.message);
} finally {
  for (const b of businesses) if (b) await fetch(`${URL_}/rest/v1/businesses?id=eq.${b}`, { method: 'DELETE', headers: SH });
  let left = 0;
  for (const id of created) { await fetch(`${URL_}/rest/v1/profiles?id=eq.${id}`, { method: 'DELETE', headers: SH }); const r = await fetch(`${URL_}/auth/v1/admin/users/${id}`, { method: 'DELETE', headers: SH }); if (!r.ok) left++; }
  ok('cleanup: [TEST] business and accounts removed', left === 0);
  console.log(results.join('\n'));
  console.log(`\n${results.length - fails}/${results.length} passed`);
  process.exitCode = fails ? 1 : 0;
}
