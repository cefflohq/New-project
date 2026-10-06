// Marketplace Verification V1 (staging only). IC (keyed HMAC, one IC = one
// account) + ONE licence image + vehicle type/plate + ONE live photo;
// screening rules server-side; businesses see nothing; Vendor-invited
// drivers are never affected. No biometrics.
import { createHash } from 'node:crypto';
import { client, uidOf } from './_marketplace.mjs';
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(typeof x === 'string' ? x : JSON.stringify(x)).slice(0, 180) : ''}`); if (!c) fails++; };
const { rpc, upload, H } = client(URL_, KEY);
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
async function signIn(email, password) { const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) }); return (await r.json()).access_token; }
const sel = async (tok, path) => { const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: H(tok) }); return { status: r.status, body: await r.json().catch(() => null) }; };
const fetchObj = (tok, path) => fetch(`${URL_}/storage/v1/object/authenticated/cefflo-driver-documents/${path}`, { headers: { apikey: KEY, authorization: `Bearer ${tok}` } });
const stamp = String(Date.now()).slice(-6);
let n = 0;
async function fresh(name) {
  const email = `zelix.co00+v1005mv${stamp}${++n}@gmail.com`;
  await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'Cf-v1005-Mv!1', email_confirm: true, user_metadata: { driver_registration: { full_name: name, phone: `+60 13-8${n}${stamp}`, vehicle_type: 'motorcycle', vehicle_plate: 'MV 1' } } }) });
  return signIn(email, 'Cf-v1005-Mv!1');
}
const icFor = i => `9${String(Number(stamp) % 10)}0${(i % 9) + 1}1${(i % 2) + 1}${stamp.slice(-4)}${String(i).padStart(2, '0')}`.slice(0, 12);
async function submitAll(tok, ic, plate = 'VAB 1234', vehicle = 'motorcycle') {
  const u = uidOf(tok), t = Date.now(), fp = `${u}/licence-front-${t}.jpg`, bp = `${u}/licence-back-${t}.jpg`, vp = `${u}/vehicle-${t}.jpg`;
  for (const p of [fp, bp, vp]) await upload(tok, p);
  const l = await rpc(tok, 'submit_driver_licence', { p_ic_number: ic, p_front_path: fp, p_back_path: bp });
  const v = await rpc(tok, 'submit_marketplace_vehicle', { p_vehicle_type: vehicle, p_vehicle_plate: plate, p_photo_path: vp });
  return { l, v, fp, bp, vp };
}
const good = (ic, name, extra = {}) => ({ text_found: true, confidence: 0.97, ic, name, classes: ['B2', 'D'], expiry: '2030-12-31', ...extra });
const plates = (text, confidence = 0.96) => ({ plates: [{ text, confidence }] });
const screen = (tok, lic, pl) => rpc(SVC, 'record_marketplace_screening', { p_user_id: uidOf(tok), p_licence: lic, p_plate: pl });
const status = async tok => (await rpc(tok, 'my_marketplace_verification')).body;

const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const owner = await signIn(mail('owner'), PW), operator = await signIn(mail('operator'), PW), helper = await signIn(mail('helper'), PW), rider = await signIn(mail('rider'), PW);
const vendorB = await signIn(process.env.STAGING_VENDOR_B_EMAIL, process.env.STAGING_VENDOR_B_PASSWORD);

// ---- H. high-confidence valid fixture -> verified
const NAME = '[TEST] Ahmad Faizal bin Ismail';
const a = await fresh(NAME), IC = icFor(1), DASHED = `${IC.slice(0, 6)}-${IC.slice(6, 8)}-${IC.slice(8)}`;
ok('initial status: not_started, no Find Jobs access', (await status(a)).status === 'not_started' && (await status(a)).marketplace_access === false);
const A = await submitAll(a, DASHED, 'vab-1234');
const ua = uidOf(a);
await upload(a, `${ua}/only-front-${stamp}.jpg`);
ok('licence with FRONT only (no back) is refused', (await rpc(a, 'submit_driver_licence', { p_ic_number: IC, p_front_path: `${ua}/only-front-${stamp}.jpg`, p_back_path: null })).status >= 400);
ok('  the same image as front and back is refused', (await rpc(a, 'submit_driver_licence', { p_ic_number: IC, p_front_path: `${ua}/only-front-${stamp}.jpg`, p_back_path: `${ua}/only-front-${stamp}.jpg` })).status >= 400);
ok('  a back image that was never uploaded is refused', (await rpc(a, 'submit_driver_licence', { p_ic_number: IC, p_front_path: `${ua}/only-front-${stamp}.jpg`, p_back_path: `${ua}/ghost.jpg` })).status >= 400);
ok('licence (IC + FRONT + BACK) + vehicle (type + plate + ONE photo) accepted', A.l.status === 200 && A.v.status === 200, msg(A.l) + msg(A.v));
const sa = await status(a);
ok('I. declared plate normalised: vab-1234 -> VAB1234', sa.vehicle_plate === 'VAB1234', sa);
ok('  before screening: pending (never verified without OCR)', sa.status === 'pending' && sa.marketplace_access === false, sa);
ok('  user-facing status exposes only IC last 4 (no hash, no paths, no evidence)', sa.ic_last4 === IC.slice(-4) && !JSON.stringify(sa).match(/hash|path|result|reason|confidence/i) && !JSON.stringify(sa).includes(IC), Object.keys(sa));
const ha = await screen(a, good(IC, 'AHMAD FAIZAL BIN ISMAIL'), plates('VAB 1234'));
ok('H. high-confidence match -> AUTO PASS verified', ha.body?.status === 'verified', ha.body);
ok('  marketplace access granted (verification only; payment later)', (await status(a)).marketplace_access === true);
ok('  verified state is locked (no vehicle swap after verification)', (await rpc(a, 'submit_marketplace_vehicle', { p_vehicle_type: 'car', p_vehicle_plate: 'WXY 1', p_photo_path: A.vp })).status >= 400);

// ---- D. IC identity + duplicates
const b = await fresh('[TEST] Dup Person');
const B1 = await submitAll(b, IC);
ok('D. same IC without dashes on another account -> rejected', B1.l.status >= 400 && /already registered/.test(msg(B1.l)), msg(B1.l));
const B2 = await submitAll(b, ` ${DASHED} `);
ok('  same IC with dashes/spaces -> rejected too (same identity)', B2.l.status >= 400 && /already registered/.test(msg(B2.l)), msg(B2.l));
const c = await fresh('[TEST] Same Self');
const C1 = await submitAll(c, icFor(3));
const C2 = await submitAll(c, `${icFor(3).slice(0, 6)}-${icFor(3).slice(6, 8)}-${icFor(3).slice(8)}`);
ok('  900101-14-5678 and 900101145678 = one identity (resubmit by the owner ok)', C1.l.status === 200 && C2.l.status === 200 && (await status(c)).ic_last4 === icFor(3).slice(-4), msg(C2.l));
ok('  invalid IC refused', (await rpc(c, 'submit_driver_licence', { p_ic_number: '901301145678', p_front_path: C1.fp, p_back_path: C1.bp })).status >= 400);

// ---- E. IC hash: keyed, unreadable
const row = (await sel(SVC, `driver_licences?select=ic_hash&user_id=eq.${uidOf(a)}`)).body?.[0];
const unkeyed = [createHash('sha256').update('cefflo-driver-ic:v1:' + IC).digest('hex'), createHash('sha256').update(IC).digest('hex')];
ok('IC hash is HMAC (not the old/plain unkeyed SHA-256)', row?.ic_hash?.length === 64 && !unkeyed.includes(row.ic_hash));
for (const [who, tok] of [['driver', a], ['owner', owner], ['operator', operator], ['helper', helper]]) {
  const r = await sel(tok, 'driver_licences?select=ic_hash');
  ok(`E. ${who} cannot read ic_hash`, r.status >= 400, `${r.status}`);
}
for (const [who, tok] of [['owner', owner], ['operator', operator], ['helper', helper], ['other business owner', vendorB], ['driver self', a]]) {
  const r1 = await sel(tok, 'driver_licences?select=user_id,ic_last4,front_path,back_path');
  const r2 = await sel(tok, 'driver_marketplace_verifications?select=user_id,status,licence_result,plate_result');
  ok(`F. ${who}: no licence rows and no verification evidence`, (r1.status >= 400 || r1.body?.length === 0) && (r2.status >= 400 || r2.body?.length === 0), `${r1.status}/${JSON.stringify(r1.body).slice(0, 60)} ${r2.status}/${JSON.stringify(r2.body).slice(0, 60)}`);
}

// ---- B/C/F. documents private
for (const [who, tok] of [['B. owner', owner], ['C. operator', operator], ['helper', helper], ['J. other business owner', vendorB], ['another driver', b]]) {
  const f = await fetchObj(tok, A.fp), bk = await fetchObj(tok, A.bp), v = await fetchObj(tok, A.vp);
  ok(`${who} cannot open licence FRONT, licence BACK or the vehicle photo`, !f.ok && !bk.ok && !v.ok, `${f.status}/${bk.status}/${v.status}`);
}
ok('  driver can open their own front + back', (await fetchObj(a, A.fp)).ok && (await fetchObj(a, A.bp)).ok);
ok('  cannot upload into another driver\'s folder', !(await upload(b, `${uidOf(a)}/evil-${stamp}.jpg`)));
ok('  cannot submit another driver\'s file as own licence', (await rpc(b, 'submit_driver_licence', { p_ic_number: icFor(4), p_front_path: A.fp, p_back_path: A.bp })).status >= 400);

// ---- J. only the server records screening; only platform admins decide
ok('J. a driver cannot record their own screening result', (await rpc(b, 'record_marketplace_screening', { p_user_id: uidOf(b), p_licence: good(icFor(4), 'X'), p_plate: plates('VAB1234') })).status >= 400);
ok('  owner cannot record screening', (await rpc(owner, 'record_marketplace_screening', { p_user_id: uidOf(b), p_licence: null, p_plate: null })).status >= 400);
ok('  driver / owner cannot decide (FOUNDR = platform admin only)', (await rpc(b, 'decide_marketplace_verification', { p_user_id: uidOf(b), p_decision: 'verified' })).status >= 400 && (await rpc(owner, 'decide_marketplace_verification', { p_user_id: uidOf(b), p_decision: 'verified' })).status >= 400);
ok('  has_marketplace_access is not callable by clients', (await rpc(b, 'has_marketplace_access', { p_user: uidOf(a) })).status >= 400);

// ---- G. OCR failure / uncertainty never verifies
const cases = [
  ['licence BACK unreadable -> RETAKE licence', { text_found: false, confidence: 0, unreadable: ['back'] }, plates('VAB1234'), 'not_started', 'licence'],
  ['no usable text -> RETAKE licence', { text_found: false, confidence: 0 }, plates('VAB1234'), 'not_started', 'licence'],
  ['IC not found -> RETAKE licence', { text_found: true, confidence: 0.9, ic: null }, plates('VAB1234'), 'not_started', 'licence'],
  ['required fields missing (no class / expiry) -> RETAKE licence', { text_found: true, confidence: 0.95, ic: '@IC', name: '@NAME', classes: [], expiry: null }, plates('VAB1234'), 'not_started', 'licence'],
  ['plate unreadable -> RETAKE vehicle', '@GOOD', { plates: [] }, 'not_started', 'vehicle'],
  ['IC mismatch -> NEEDS REVIEW', '@GOOD:ic=900101149999', plates('VAB1234'), 'needs_review'],
  ['name mismatch -> NEEDS REVIEW', '@GOOD:name=SOMEONE ELSE', plates('VAB1234'), 'needs_review'],
  ['low OCR confidence -> NEEDS REVIEW', '@GOOD:confidence=0.6', plates('VAB1234'), 'needs_review'],
  ['expired licence -> NEEDS REVIEW (not auto-rejected)', '@GOOD:expiry=2020-01-01', plates('VAB1234'), 'needs_review'],
  ['class incompatible (car class for motorcycle) -> NEEDS REVIEW', '@GOOD:classes=D', plates('VAB1234'), 'needs_review'],
  ['plate confusable (VA81234) -> NEEDS REVIEW', '@GOOD', plates('VA81234'), 'needs_review'],
  ['plate clearly different -> NEEDS REVIEW', '@GOOD', plates('WXY9876'), 'needs_review'],
  ['plate exact but low confidence -> NEEDS REVIEW', '@GOOD', plates('VAB1234', 0.5), 'needs_review'],
  ['nothing screened yet (OCR down) -> stays pending', null, null, 'pending'],
];
let i = 10;
for (const [label, lic0, pl, want, retake] of cases) {
  const nm = '[TEST] Case Person', t = await fresh(nm), ic = icFor(++i);
  await submitAll(t, ic);
  let lic = lic0;
  if (typeof lic0 === 'string') { const [, kv] = lic0.split(':'); lic = good(ic, 'CASE PERSON'); if (kv) { const [k, v] = kv.split('='); lic[k] = k === 'confidence' ? Number(v) : k === 'classes' ? [v] : v; } }
  else if (lic0 && lic0.ic === '@IC') lic = { ...lic0, ic, name: 'CASE PERSON' };
  const r = (lic || pl) ? (await screen(t, lic, pl)).body : await status(t);
  const s = await status(t);
  ok(`G. ${label}`, s.status === want && (!retake || s.retake === retake) && s.marketplace_access === false, { r, s: s.status, retake: s.retake });
}
// repeated failed attempts -> NEEDS REVIEW
const rp = await fresh('[TEST] Retry Person'); await submitAll(rp, icFor(40));
for (let k = 0; k < 4; k++) await screen(rp, { text_found: false, confidence: 0 }, null);
const rps = await status(rp);
ok('G. repeated failed attempts -> NEEDS REVIEW', rps.status === 'needs_review' && rps.marketplace_access === false, rps);

// ---- A. Vendor-invited drivers are not affected
const rv = (await sel(SVC, `driver_marketplace_verifications?select=status&user_id=eq.${uidOf(rider)}`)).body;
ok('A. Vendor-invited e2e driver has NO marketplace verification (delivery_e2e proves runs/POD work)', Array.isArray(rv) && rv.length === 0, rv);
const fn = await sel(SVC, `riders?select=id&limit=1`);
ok('  riders.licence_* columns removed', (await sel(SVC, 'riders?select=licence_verified_at&limit=1')).status >= 400 && fn.status === 200);
ok('  verify_rider_licence removed', (await rpc(owner, 'verify_rider_licence', { p_rider_id: '00000000-0000-0000-0000-000000000000', p_approve: true })).status === 404);

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
