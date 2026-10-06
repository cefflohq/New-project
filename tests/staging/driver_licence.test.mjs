// Driver licence document store (staging only): IC number = one account;
// the photo is the driving licence. Malaysia (MyKad) only.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 160) : ''}`); if (!c) fails++; };
async function signIn(email, password) { const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) }); return (await r.json()).access_token; }
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function sel(tok, path) { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; }
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const uid = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;
const stamp = String(Date.now()).slice(-6);
async function fresh(tag) {
  const email = `zelix.co00+v1005lic${tag}${stamp}@gmail.com`;
  await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'Cf-v1005-Lic!1', email_confirm: true }) });
  return signIn(email, 'Cf-v1005-Lic!1');
}
const jpg = Buffer.from('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAAA//EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AN//Z', 'base64');
const upload = (tok, path) => fetch(`${URL_}/storage/v1/object/cefflo-driver-documents/${path}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${tok}`, 'content-type': 'image/jpeg' }, body: jpg });
const IC = `9001011${stamp.slice(-5)}`, IC2 = `9102022${stamp.slice(-5)}`;
const dashed = ic => `${ic.slice(0, 6)}-${ic.slice(6, 8)}-${ic.slice(8)}`;

const a = await fresh('a'), b = await fresh('b'), owner = await signIn('zelix.co00+v1004owner@gmail.com', 'Cf-v1004-Verify!9');
const pa = `${uid(a)}/licence-${stamp}.jpg`;
ok('1 driver uploads a licence photo to their own folder', (await upload(a, pa)).ok);
const intoOther = await upload(b, `${uid(a)}/evil-${stamp}.jpg`);
ok('  cannot upload into another driver\'s folder', !intoOther.ok, intoOther.status);
const s1 = await rpc(a, 'submit_driver_licence', { p_ic_number: dashed(IC), p_photo_path: pa });
ok('  submit IC + licence photo -> submitted, last 4 only, no IC in clear', s1.status === 200 && s1.body?.status === 'submitted' && s1.body?.ic_last4 === IC.slice(-4) && !JSON.stringify(s1.body).includes(IC), JSON.stringify(s1.body).slice(0, 120));

// 2. one IC = one account (formatting does not matter)
const pb = `${uid(b)}/licence-${stamp}.jpg`; await upload(b, pb);
const dup = await rpc(b, 'submit_driver_licence', { p_ic_number: ` ${IC} `, p_photo_path: pb });
ok('2 a second account with the same IC is refused (e.g. a new account, or a relative)', dup.status >= 400 && /already registered/.test(msg(dup)), msg(dup));
const okB = await rpc(b, 'submit_driver_licence', { p_ic_number: IC2, p_photo_path: pb });
ok('  the second account can submit its own (different) IC', okB.status === 200, msg(okB));

// 3. validation
ok('3 not 12 digits refused', (await rpc(a, 'submit_driver_licence', { p_ic_number: '12345', p_photo_path: pa })).status >= 400);
ok('  impossible birth month refused', (await rpc(a, 'submit_driver_licence', { p_ic_number: '901301145678', p_photo_path: pa })).status >= 400);
ok('  photo in someone else\'s folder refused', (await rpc(a, 'submit_driver_licence', { p_ic_number: IC, p_photo_path: pb })).status >= 400);
ok('  photo that was never uploaded refused', (await rpc(a, 'submit_driver_licence', { p_ic_number: IC, p_photo_path: `${uid(a)}/missing.jpg` })).status >= 400);
ok('  anonymous refused', (await rpc(null, 'submit_driver_licence', { p_ic_number: IC, p_photo_path: pa })).status >= 400);

// 4. privacy
const readOwnRow = await sel(a, `driver_licences?select=status,ic_last4`);
ok('4 driver reads only their own row', readOwnRow.body?.length === 1, JSON.stringify(readOwnRow.body));
const otherPhoto = await fetch(`${URL_}/storage/v1/object/authenticated/cefflo-driver-documents/${pa}`, { headers: { apikey: KEY, authorization: `Bearer ${b}` } });
ok('  another driver cannot open the photo', !otherPhoto.ok, otherPhoto.status);
const ownerRows = await sel(owner, `driver_licences?select=user_id`);
ok('  a business owner reads no licences', Array.isArray(ownerRows.body) && ownerRows.body.length === 0);
const ownerPhoto = await fetch(`${URL_}/storage/v1/object/authenticated/cefflo-driver-documents/${pa}`, { headers: { apikey: KEY, authorization: `Bearer ${owner}` } });
ok('  a business owner cannot open the photo', !ownerPhoto.ok, ownerPhoto.status);
ok('  direct writes are refused', (await fetch(`${URL_}/rest/v1/driver_licences?user_id=eq.${uid(a)}`, { method: 'PATCH', headers: { ...H(a), prefer: 'return=representation' }, body: JSON.stringify({ status: 'verified' }) }).then(r => r.json())).length !== 1);
ok('  status still submitted', (await sel(a, 'driver_licences?select=status')).body?.[0]?.status === 'submitted');

// 5. review is Cefflo-only
const rv = await rpc(owner, 'review_driver_licence', { p_user_id: uid(a), p_approve: true });
ok('5 a non-admin cannot verify a licence', rv.status >= 400 && /forbidden/.test(msg(rv)), msg(rv));
ok('  the driver cannot verify themselves', (await rpc(a, 'review_driver_licence', { p_user_id: uid(a), p_approve: true })).status >= 400);

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
