// Rider Hub (D-75) staging security tests. Staging only; refuses any other project.
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (name, cond, extra = '') => { results.push(`${cond ? 'PASS' : 'FAIL'}  ${name}${extra ? '  -> ' + extra : ''}`); if (!cond) fails++; };
async function signIn(email, password = PW) {
  const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) });
  const j = await r.json(); if (!j.access_token) throw new Error('signin ' + email + ' ' + JSON.stringify(j)); return j.access_token;
}
async function rpc(tok, name, body = {}) {
  const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' }, body: JSON.stringify(body) });
  const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j };
}
async function sel(tok, path) {
  const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: { apikey: KEY, authorization: `Bearer ${tok}` } }); return { status: r.status, body: await r.json().catch(() => null) };
}
async function ins(tok, table, row) {
  const r = await fetch(`${URL_}/rest/v1/${table}`, { method: 'POST', headers: { apikey: KEY, authorization: `Bearer ${tok}`, 'content-type': 'application/json', prefer: 'return=representation' }, body: JSON.stringify(row) }); return r.status;
}
const err = res => (res.body && (res.body.message || res.body.hint)) || JSON.stringify(res.body);

// fresh applicant (admin API, staging)
const appEmail = `zelix.co00+v1005jobs${Date.now() % 100000}@gmail.com`, appPw = 'Cf-v1005-Jobs!7';
const cu = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' },
  body: JSON.stringify({ email: appEmail, password: appPw, email_confirm: true, user_metadata: { full_name: '[TEST] Jobs Applicant', driver_registration: { full_name: '[TEST] Jobs Applicant', phone: '+60 11-' + String(Date.now()).slice(-7), vehicle_type: 'motorcycle', vehicle_plate: 'KDH 1005' } } }) });
ok('setup: create applicant (staging admin)', cu.ok, cu.ok ? appEmail : await cu.text());

const owner = await signIn(mail('owner')), operator = await signIn(mail('operator')), helper = await signIn(mail('helper')), outsider = await signIn(mail('outsider'));
const applicant = await signIn(appEmail, appPw);
const vendorB = await signIn(process.env.STAGING_VENDOR_B_EMAIL, process.env.STAGING_VENDOR_B_PASSWORD);
const biz = (await rpc(owner, 'get_my_businesses')).body.find(b => b.member_role === 'owner');
ok('setup: owner business', !!biz, biz && biz.business_name);
const B = biz.business_id;
// M1 Driver Hiring contract: pickup time (no end), pay per drop (min RM3.00),
// drivers needed, driver reach 1-15 km.
const opening = (extra = {}) => ({ p_business_id: B, p_area_label: 'Taman Uda', p_pickup_time: '07:00', p_days: [1, 2, 3, 4, 5], p_vehicle_type: 'motorcycle', p_pay_per_drop: 3.5, p_drivers_needed: 2, p_reach_km: 10, ...extra });

// --- vendor side
const o1 = await rpc(owner, 'save_job_opening', opening());
ok('owner can post an opening', o1.status === 200 && o1.body.id, err(o1));
ok('stored per the contract: per drop, pickup time only, reach 10', o1.body?.pay_unit === 'drop' && Number(o1.body?.pay_amount) === 3.5 && o1.body?.shift_end === null && Number(o1.body?.radius_km) === 10, JSON.stringify({ u: o1.body?.pay_unit, a: o1.body?.pay_amount, e: o1.body?.shift_end, r: o1.body?.radius_km }));
const o2 = await rpc(owner, 'save_job_opening', opening({ p_pickup_time: '10:00', p_days: [2] }));
ok('owner can post a 2nd opening (same Tue)', o2.status === 200, err(o2));
const o3 = await rpc(owner, 'save_job_opening', opening({ p_pickup_time: '18:00', p_days: [5, 6, 7], p_reach_km: 15 }));
ok('owner can post a night opening, reach 15 km (max)', o3.status === 200, err(o3));
for (const [who, tok] of [['operator', operator], ['helper', helper], ['outsider', outsider], ['other vendor', vendorB]]) {
  const r = await rpc(tok, 'save_job_opening', opening());
  ok(`${who} cannot post an opening`, r.status >= 400, err(r));
  const c = await rpc(tok, 'close_job_opening', { p_opening_id: o3.body.id });
  ok(`${who} cannot close an opening`, c.status >= 400, err(c));
}
for (const [bad, extra] of [['reach 0 km', { p_reach_km: 0 }], ['reach 16 km', { p_reach_km: 16 }], ['RM2.99 per drop (min RM3.00)', { p_pay_per_drop: 2.99 }], ['no pickup time', { p_pickup_time: null }], ['day 8', { p_days: [8] }], ['old shift/pay-unit parameters', { p_pay_unit: 'shift' }]]) {
  const r = await rpc(owner, 'save_job_opening', opening(extra));
  ok(`invalid opening refused: ${bad}`, r.status >= 400, err(r));
}

// --- browsing (nearby-first; business origin is in KL 3.1579,101.7123)
const NEAR = { p_lat: 3.16, p_lng: 101.71 }, ours = x => [o1.body.id, o2.body.id, o3.body.id].includes(x.opening_id);
const anon = await rpc(null, 'find_job_openings', { ...NEAR, p_radius_km: 20 });
ok('anonymous cannot browse openings', anon.status >= 400, err(anon));
const noLoc = await rpc(applicant, 'find_job_openings', { p_lat: null, p_lng: null, p_radius_km: 20 });
ok('no nationwide feed: a location is required', noLoc.status >= 400, err(noLoc));
const badR = await rpc(applicant, 'find_job_openings', { ...NEAR, p_radius_km: 25 });
ok('radius must be 5/10/20/30/50', badR.status >= 400, err(badR));
const bigR = await rpc(applicant, 'find_job_openings', { ...NEAR, p_radius_km: 100 });
ok('radius above 50 km refused', bigR.status >= 400, err(bigR));
const f = await rpc(applicant, 'find_job_openings', { ...NEAR, p_radius_km: 20 });
const mine = Array.isArray(f.body) ? f.body.filter(ours) : [];
ok('nearby rider (default 20 km) sees the openings', f.status === 200 && mine.length === 3, `${Array.isArray(f.body) ? f.body.length : err(f)} rows`);
const keys = mine[0] ? Object.keys(mine[0]) : [];
ok('results carry no address/phone/coordinates', !keys.some(k => /address|phone|email|latitude|longitude|owner|customer/i.test(k)), keys.join(','));
ok('distance is rounded to 0.5 km from the pickup origin', mine.every(x => Number(x.distance_km) * 2 % 1 === 0 && Number(x.distance_km) < 2), mine.map(x => x.distance_km).join(','));
const shahAlam = { p_lat: 3.0733, p_lng: 101.5185 };
const sa20 = await rpc(applicant, 'find_job_openings', { ...shahAlam, p_radius_km: 20 });
ok('Change location to Shah Alam, 20 km: KL openings not shown', Array.isArray(sa20.body) && !sa20.body.some(ours), `${sa20.body?.length} rows`);
const sa30 = await rpc(applicant, 'find_job_openings', { ...shahAlam, p_radius_km: 30 });
ok('Shah Alam 30 km search: KL posts beyond their driver reach stay hidden', Array.isArray(sa30.body) && !sa30.body.some(ours), `${sa30.body?.filter(ours).length} shown`);
const north12 = await rpc(applicant, 'find_job_openings', { p_lat: 3.2679, p_lng: 101.71, p_radius_km: 20 });
const n12 = Array.isArray(north12.body) ? north12.body.filter(ours).map(x => x.opening_id) : [];
ok('driver ~12 km away: sees the 15 km-reach post only, not the 10 km ones', n12.length === 1 && n12[0] === o3.body.id, JSON.stringify(n12));
const kedah = await rpc(applicant, 'find_job_openings', { p_lat: 6.12, p_lng: 100.37, p_radius_km: 50 });
ok('rider in Kedah (50 km max) does not see KL openings', Array.isArray(kedah.body) && !kedah.body.some(ours));
const direct = await sel(applicant, `rider_job_openings?select=id&business_id=eq.${B}`);
ok('rider cannot read openings table directly', direct.status === 200 && direct.body.length === 0, JSON.stringify(direct.body));
ok('rider cannot insert an opening directly', (await ins(applicant, 'rider_job_openings', { business_id: B, area_label: 'x', shift_start: '07:00', days: [1], vehicle_type: 'car', pay_amount: 3, pay_unit: 'drop', riders_needed: 1 })) >= 400);
const bRead = await sel(vendorB, `rider_job_openings?select=id&business_id=eq.${B}`);
ok("other vendor cannot read this business's openings", bRead.status === 200 && bRead.body.length === 0);

// --- requests
const r1 = await rpc(applicant, 'request_job_opening', { p_opening_id: o1.body.id });
ok('rider can request an opening (pending)', r1.status === 200 && r1.body.status === 'pending', err(r1));
const dup = await rpc(applicant, 'request_job_opening', { p_opening_id: o1.body.id });
ok('duplicate request refused', dup.status >= 400, err(dup));
const opReq = await rpc(operator, 'request_job_opening', { p_opening_id: o1.body.id });
ok('team member cannot apply to own business', opReq.status >= 400, err(opReq));
const pend = await sel(owner, `riders?select=id,status,name&business_id=eq.${B}&auth_user_id=eq.${JSON.parse(Buffer.from(applicant.split('.')[1], 'base64url').toString()).sub}`);
ok('request shows in Riders > Pending for the owner', pend.body?.[0]?.status === 'pending', JSON.stringify(pend.body));
const riderId = pend.body?.[0]?.id;
const selfApprove = await rpc(applicant, 'approve_pending_rider', { p_rider_id: riderId });
ok('rider cannot approve themselves', selfApprove.status >= 400, err(selfApprove));
const opApprove = await rpc(operator, 'approve_pending_rider', { p_rider_id: riderId });
ok('operator cannot approve the rider', opApprove.status >= 400, err(opApprove));
const bReq = await sel(vendorB, `rider_job_requests?select=id&business_id=eq.${B}`);
ok("other vendor cannot read this business's requests", bReq.status === 200 && bReq.body.length === 0);
const ownerApprove = await rpc(owner, 'approve_pending_rider', { p_rider_id: riderId });
ok('owner approves the rider', ownerApprove.status === 200, err(ownerApprove));
const sched = await rpc(applicant, 'my_job_schedule');
ok('approval also approves the job request (My Schedule)', Array.isArray(sched.body) && sched.body.some(x => x.opening_id === o1.body.id && x.status === 'approved'), JSON.stringify(sched.body).slice(0, 200));
const sameDay = await rpc(applicant, 'request_job_opening', { p_opening_id: o2.body.id });
ok('no artificial clash rule: a 2nd Tue post can be taken (approved, already active)', sameDay.status === 200 && sameDay.body.status === 'approved', err(sameDay));
const o4 = await rpc(owner, 'save_job_opening', opening({ p_pickup_time: '14:00', p_days: [3], p_vehicle_type: 'car' }));
ok('owner posts a car opening (rider rides a motorbike)', o4.status === 200, err(o4));
const f2 = await rpc(applicant, 'find_job_openings', { ...NEAR, p_radius_km: 20 });
const order = f2.body.filter(x => [o2.body.id, o3.body.id, o4.body.id].includes(x.opening_id)).map(x => x.opening_id);
ok('ranking: same vehicle before other vehicle',
  order.indexOf(o4.body.id) > order.indexOf(o2.body.id) && order.indexOf(o4.body.id) > order.indexOf(o3.body.id), order.map(id => ({ [o2.body.id]: 'tue', [o3.body.id]: 'night', [o4.body.id]: 'car' })[id]).join(' > '));
const row2 = f2.body.find(x => x.opening_id === o2.body.id), row1 = f2.body.find(x => x.opening_id === o1.body.id);
ok('browse marks my bookings and never a clash', !row2?.clash && row1?.my_status === 'approved' && row2?.my_status === 'approved', `${row2?.clash} / ${row1?.my_status} / ${row2?.my_status}`);
const night = await rpc(applicant, 'request_job_opening', { p_opening_id: o3.body.id });
ok('night post, already an active rider -> approved directly', night.status === 200 && night.body.status === 'approved', err(night));
const otherSched = await rpc(outsider, 'my_job_schedule');
ok("another user's schedule is not visible", Array.isArray(otherSched.body) && !otherSched.body.some(x => x.opening_id === o1.body.id));
const reqId = sched.body.find(x => x.opening_id === o1.body.id)?.request_id;
const wOther = await rpc(outsider, 'withdraw_job_request', { p_request_id: reqId });
ok("cannot withdraw someone else's request", wOther.status >= 400, err(wOther));
const wOwn = await rpc(applicant, 'withdraw_job_request', { p_request_id: reqId });
ok('rider can withdraw own booking', wOwn.status === 204 || wOwn.status === 200, err(wOwn));

// --- removal rejects live requests
const remove = await rpc(owner, 'deactivate_rider', { p_rider_id: riderId });
ok('owner removes the rider', remove.status === 200, err(remove));
const after = await rpc(applicant, 'my_job_schedule');
ok('removal clears the rider\'s bookings', Array.isArray(after.body) && after.body.length === 0, JSON.stringify(after.body).slice(0, 160));

// --- cleanup: close test openings
for (const o of [o1, o2, o3, o4]) { const c = await rpc(owner, 'close_job_opening', { p_opening_id: o.body.id }); ok('cleanup: owner closes opening', c.status === 200, err(c)); }

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
