// Helper active workload = business TODAY + UNFINISHED work from the previous
// 7 business calendar days (Founder 2026-10-06). Staging only. Fixtures are
// isolated test orders inserted with past created_at (the order_date trigger
// stamps the business-local date) in a dedicated test zone, and deleted at
// the end. No product data is touched.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 160) : ''}`); if (!c) fails++; };
async function signIn(email, password = PW) { const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) }); return (await r.json()).access_token; }
const H = tok => String(tok).startsWith('sb_secret') ? { apikey: tok, 'content-type': 'application/json' } : { apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' };
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function rest(method, path, body) { const r = await fetch(`${URL_}/rest/v1/${path}`, { method, headers: { ...H(SVC), prefer: 'return=representation' }, body: body ? JSON.stringify(body) : undefined }); return { status: r.status, body: await r.json().catch(() => null) }; }
const stamp = String(Date.now()).slice(-6);

const owner = await signIn(mail('owner')), helper = await signIn(mail('helper'));
const vendorB = await signIn(process.env.STAGING_VENDOR_B_EMAIL, process.env.STAGING_VENDOR_B_PASSWORD);
const B = (await rpc(owner, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;
const BB = (await rpc(vendorB, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;
const tz = (await rest('GET', `businesses?select=timezone&id=eq.${B}`)).body[0].timezone;
const fmt = (d, zone) => new Intl.DateTimeFormat('en-CA', { timeZone: zone }).format(d);
const today = fmt(new Date(), tz);
const board0 = (await rpc(helper, 'my_fulfilment_tasks', { p_business_id: B })).body;
ok('business_today from businesses.timezone', board0.business_today === today, `${board0.business_today} vs ${today} (${tz})`);
const addDays = (iso, n) => { const d = new Date(iso + 'T00:00:00Z'); d.setUTCDate(d.getUTCDate() + n); return d.toISOString().slice(0, 10); };
ok('backlog_from = business_today - 7 calendar days', board0.backlog_from === addDays(today, -7), board0.backlog_from);

// fixtures: a test zone + orders at local noon of chosen business days
const zone = (x => Array.isArray(x) ? x[0] : x)((await rpc(owner, 'create_zone', { p_business_id: B, p_name: `[TEST] Backlog ${stamp}` })).body).id;
const noonUtc = iso => { // local noon of `iso` in tz, as a UTC instant
  const guess = new Date(iso + 'T12:00:00Z');
  const local = new Date(guess.toLocaleString('en-US', { timeZone: tz }));
  return new Date(guess.getTime() - (local.getTime() - guess.getTime())).toISOString();
};
const made = [];
async function fixture(label, daysAgo, prep, extra = {}) {
  const day = addDays(today, -daysAgo);
  const o = (await rest('POST', 'orders', { business_id: B, customer_name: `[TEST] Backlog ${label}`, customer_phone: '+60 12-000 0000', delivery_address: '[TEST] Backlog', zone_id: zone, created_at: noonUtc(day), delivery_status: 'created' })).body?.[0];
  if (!o) throw new Error('fixture order ' + label);
  const st = (await rest('POST', 'delivery_stops', { business_id: B, order_id: o.id, preparation_status: prep, ...extra })).body?.[0];
  made.push(o.id);
  return { id: o.id, day: o.order_date, expectedDay: day, stop: st };
}
const A = await fixture('A today', 0, 'not_started');
const Bk = await fixture('B 1day', 1, 'preparing');
const C = await fixture('C 7day', 7, 'packed', { packing_confirmed_at: new Date().toISOString() });
const D = await fixture('D 8day', 8, 'not_started');
const E = await fixture('E ready 1day', 1, 'ready');
const T2 = await fixture('today ready', 0, 'ready');
ok('fixtures carry the intended business-local order_date', [A, Bk, C, D, E].every(f => f.day === f.expectedDay), [A, Bk, C, D, E].map(f => `${f.day}/${f.expectedDay}`).join(' '));

const tasks = (await rpc(helper, 'my_fulfilment_tasks', { p_business_id: B })).body.tasks;
const seen = id => tasks.find(t => t.order_id === id);
ok(`A today (${A.day}) unfinished -> visible`, !!seen(A.id));
ok(`B 1-day backlog (${Bk.day}) unfinished -> visible`, !!seen(Bk.id));
ok(`C 7-day backlog (${C.day}) unfinished -> visible`, !!seen(C.id));
ok(`D 8-day backlog (${D.day}) -> NOT in the Helper workload`, !seen(D.id));
ok(`E completed (ready) on ${E.day} -> NOT carried as backlog`, !seen(E.id));
ok('today Ready work stays on today\'s board', !!seen(T2.id));
ok('F carried order keeps its exact state (packed, packing confirmed)', seen(C.id)?.preparation_status === 'packed' && seen(C.id)?.packing_confirmed === true, JSON.stringify(seen(C.id)).slice(0, 120));
ok('  1-day backlog keeps preparing', seen(Bk.id)?.preparation_status === 'preparing');
const dRow = (await rest('GET', `delivery_stops?select=preparation_status&order_id=eq.${D.id}`)).body?.[0];
const dOrder = (await rest('GET', `orders?select=delivery_status,order_date&id=eq.${D.id}`)).body?.[0];
ok('>7 days: record preserved, state untouched (not deleted / cancelled / reset)', dRow?.preparation_status === 'not_started' && dOrder?.delivery_status === 'created' && dOrder?.order_date === D.day);

// carried work can be finished today (per order-date group)
ok('carried work progresses: 1-day backlog preparing -> packed', (await rpc(helper, 'advance_preparation', { p_order_id: Bk.id, p_next: 'packed' })).status === 200);
const cpOld = await rpc(helper, 'confirm_packing', { p_business_id: B, p_zone_id: zone, p_order_date: Bk.day });
ok('  packing confirmed for the backlog day group', cpOld.status === 200 && cpOld.body?.newly_confirmed >= 1, JSON.stringify(cpOld.body));

// G: the window is the server's; the client cannot pass a date
const tamper = await rpc(helper, 'my_fulfilment_tasks', { p_business_id: B, p_business_today: '2026-01-01' });
ok('J client cannot supply its own "today" (no such parameter)', tamper.status >= 400);
ok('J/K Helper cannot open another business window', (await rpc(helper, 'my_fulfilment_tasks', { p_business_id: BB })).status >= 400);
ok('K Business B never sees these fixtures', !JSON.stringify((await rpc(vendorB, 'my_fulfilment_tasks', { p_business_id: BB })).body).includes(A.id));

// H / I: another business timezone computes its own day; the boundary follows it
const origB = (await rest('GET', `businesses?select=timezone&id=eq.${BB}`)).body[0].timezone;
const now = new Date();
for (const zoneName of ['Pacific/Kiritimati', 'Pacific/Pago_Pago']) {
  await rest('PATCH', `businesses?id=eq.${BB}`, { timezone: zoneName });
  const bt = (await rpc(vendorB, 'my_fulfilment_tasks', { p_business_id: BB })).body?.business_today;
  ok(`H business in ${zoneName} gets its own business_today (${fmt(now, zoneName)})`, bt === fmt(new Date(), zoneName), bt);
}
ok('I same instant, different timezones -> different business days (midnight follows businesses.timezone)', fmt(now, 'Pacific/Kiritimati') !== fmt(now, 'Pacific/Pago_Pago'));
await rest('PATCH', `businesses?id=eq.${BB}`, { timezone: origB });
ok('  Business B timezone restored', (await rest('GET', `businesses?select=timezone&id=eq.${BB}`)).body[0].timezone === origB);

// cleanup (test fixtures only)
const ids = made.join(',');
await rest('DELETE', `delivery_events?order_id=in.(${ids})`);
await rest('DELETE', `delivery_stops?order_id=in.(${ids})`);
const del = await rest('DELETE', `orders?id=in.(${ids})`);
await rpc(owner, 'set_zone_status', { p_zone_id: zone, p_status: 'inactive' });
ok('cleanup: fixture orders deleted, test zone inactive', del.status === 200 && (await rest('GET', `orders?select=id&id=in.(${ids})`)).body?.length === 0);

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
