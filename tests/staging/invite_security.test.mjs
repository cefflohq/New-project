// Invite PWA security / negative suite (staging only): token tampering,
// reset, duplicates, rejection, self-approval, cross-business, direct table
// writes, role tampering. Complements invite_regression (happy paths).
const URL_ = process.env.SUPABASE_URL, KEY = process.env.SUPABASE_PUBLISHABLE_KEY, SVC = process.env.SUPABASE_SECRET_KEY;
if (!URL_.includes('tomvvmwktehexwhktenw')) throw new Error('not staging');
const PW = 'Cf-v1004-Verify!9', mail = r => `zelix.co00+v1004${r}@gmail.com`;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 150) : ''}`); if (!c) fails++; };
async function signIn(email, password = PW) {
  const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { apikey: KEY, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) });
  const j = await r.json(); if (!j.access_token) throw new Error('signin ' + email); return j.access_token;
}
const H = tok => ({ apikey: KEY, authorization: `Bearer ${tok || KEY}`, 'content-type': 'application/json' });
async function rpc(tok, name, body = {}) { const r = await fetch(`${URL_}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(tok), body: JSON.stringify(body) }); const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; } return { status: r.status, body: j }; }
async function rest(tok, method, path, body) { const r = await fetch(`${URL_}/rest/v1/${path}`, { method, headers: { ...H(tok), prefer: 'return=representation' }, body: body ? JSON.stringify(body) : undefined }); return { status: r.status, body: await r.json().catch(() => null) }; }
const sel = (tok, path) => rest(tok, 'GET', path);
const msg = r => (r.body && (r.body.message || r.body.hint)) || JSON.stringify(r.body);
const denied = r => r.status >= 400 || (Array.isArray(r.body) && r.body.length === 0);
const uid = tok => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;
const stamp = String(Date.now()).slice(-6);
async function freshUser(tag) {
  const email = `zelix.co00+v1005sec${tag}${stamp}@gmail.com`, password = 'Cf-v1005-Invite!5';
  const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: { apikey: SVC, authorization: `Bearer ${SVC}`, 'content-type': 'application/json' }, body: JSON.stringify({ email, password, email_confirm: true }) });
  if (!r.ok) throw new Error('create ' + await r.text());
  return signIn(email, password);
}
const tok = b => (typeof b === 'string' ? b : b?.token);

const owner = await signIn(mail('owner')), operator = await signIn(mail('operator')), helper = await signIn(mail('helper'));
const ownerX = await signIn('zelix.co00+v1005p0x388121@gmail.com', 'Cf-v1005-P0!X');
const B = (await rpc(owner, 'get_my_businesses')).body.find(b => b.member_role === 'owner').business_id;

// 1. who may obtain a link
ok('1 anon cannot obtain a link', (await rpc(null, 'get_invite_link', { p_business_id: B, p_kind: 'operator' })).status >= 400);
ok('  helper cannot obtain any link', (await rpc(helper, 'get_invite_link', { p_business_id: B, p_kind: 'rider' })).status >= 400);
ok('  operator cannot obtain an Operator link', (await rpc(operator, 'get_invite_link', { p_business_id: B, p_kind: 'operator' })).status >= 400);
ok('  operator cannot obtain a Helper link (current authority)', (await rpc(operator, 'get_invite_link', { p_business_id: B, p_kind: 'helper' })).status >= 400);
ok('  another business\'s owner cannot obtain this business\'s link', (await rpc(ownerX, 'get_invite_link', { p_business_id: B, p_kind: 'operator' })).status >= 400);
ok('  an unknown kind is refused', (await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: 'owner' })).status >= 400);
const links = {};
for (const k of ['rider', 'operator', 'helper']) links[k] = tok((await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: k })).body);
ok('  three distinct permanent links (one per role)', new Set(Object.values(links)).size === 3 && Object.values(links).every(t => /^[0-9a-f]{48}$/.test(t)));
const again = tok((await rpc(owner, 'get_invite_link', { p_business_id: B, p_kind: 'helper' })).body);
ok('  link is permanent (same token on repeat)', again === links.helper);

// 2. tampering
const flip = t => t.slice(0, -1) + (t.endsWith('a') ? 'b' : 'a');
ok('2 modified token: preview reveals nothing', (await rpc(null, 'resolve_invite_link', { p_token: flip(links.operator) })).body === null);
ok('  random token: preview reveals nothing', (await rpc(null, 'resolve_invite_link', { p_token: 'f'.repeat(48) })).body === null);
const u1 = await freshUser('a');
const jm = await rpc(u1, 'join_via_invite_link', { p_token: flip(links.operator), p_name: '[TEST] Sec', p_phone: '+60 13-1' + stamp });
ok('  modified token cannot be joined', jm.status >= 400 && /not available/.test(msg(jm)), msg(jm));
ok('  anon cannot join', (await rpc(null, 'join_via_invite_link', { p_token: links.operator, p_name: 'x', p_phone: 'y' })).status >= 400);
const roleParam = await rpc(u1, 'join_via_invite_link', { p_token: links.helper, p_name: '[TEST] Sec', p_phone: '+60 13-1' + stamp, p_role: 'operator' });
ok('  extra role parameter is not accepted by the server', roleParam.status >= 400, msg(roleParam));
const bizParam = await rpc(u1, 'join_via_invite_link', { p_token: links.helper, p_name: '[TEST] Sec', p_phone: '+60 13-1' + stamp, p_business_id: B });
ok('  extra business parameter is not accepted by the server', bizParam.status >= 400, msg(bizParam));

// 3. role comes from the link; duplicates are safe
const j1 = await rpc(u1, 'join_via_invite_link', { p_token: links.helper, p_name: '[TEST] Sec Helper', p_phone: '+60 13-1' + stamp });
ok('3 helper link -> pending', j1.status === 200 && j1.body?.status === 'pending' && j1.body?.kind === 'helper', msg(j1));
await rpc(u1, 'join_via_invite_link', { p_token: links.helper, p_name: '[TEST] Sec Helper', p_phone: '+60 13-1' + stamp });
const j3 = await rpc(u1, 'join_via_invite_link', { p_token: links.operator, p_name: '[TEST] Sec Helper', p_phone: '+60 13-1' + stamp });
const reqs = (await sel(owner, `team_join_requests?select=id,role,status&business_id=eq.${B}&user_id=eq.${uid(u1)}`)).body;
ok('  re-joining (and then opening the Operator link) keeps ONE pending Helper request', reqs?.length === 1 && reqs[0].role === 'helper' && reqs[0].status === 'pending', JSON.stringify(reqs) + ' ' + msg(j3));
ok('  pending grants no workspace', ((await rpc(u1, 'get_my_businesses')).body || []).length === 0);

// 4. no self-service escalation
ok('4 user cannot approve their own request', (await rpc(u1, 'decide_team_join_request', { p_request_id: reqs[0].id, p_approve: true })).status >= 400);
ok('  operator cannot approve a team request', (await rpc(operator, 'decide_team_join_request', { p_request_id: reqs[0].id, p_approve: true })).status >= 400);
ok('  another business\'s owner cannot approve it', (await rpc(ownerX, 'decide_team_join_request', { p_request_id: reqs[0].id, p_approve: true })).status >= 400);
ok('  user cannot insert their own membership', denied(await rest(u1, 'POST', 'business_members', { business_id: B, user_id: uid(u1), role: 'operator', status: 'active' })));
ok('  user cannot rewrite their request (role/status)', denied(await rest(u1, 'PATCH', `team_join_requests?id=eq.${reqs[0].id}`, { role: 'operator', status: 'approved' })));
ok('  user cannot create an invite link row', denied(await rest(u1, 'POST', 'business_invite_links', { business_id: B, kind: 'operator', token: 'a'.repeat(48) })));
ok('  user cannot read the business\'s invite links', denied(await sel(u1, `business_invite_links?select=token&business_id=eq.${B}`)));
const still = (await sel(owner, `team_join_requests?select=role,status&id=eq.${reqs[0].id}`)).body[0];
ok('  request unchanged after all attempts (helper, pending)', still.role === 'helper' && still.status === 'pending', JSON.stringify(still));

// 5. rejection grants nothing
const rj = await rpc(owner, 'decide_team_join_request', { p_request_id: reqs[0].id, p_approve: false });
ok('5 owner rejects', rj.status === 200, msg(rj));
ok('  rejected user has no workspace', ((await rpc(u1, 'get_my_businesses')).body || []).length === 0);
ok('  rejected user is refused vendor data', (await rpc(u1, 'get_storefront', { p_business_id: B })).status >= 400);
ok('  a decided request cannot be decided again', (await rpc(owner, 'decide_team_join_request', { p_request_id: reqs[0].id, p_approve: true })).status >= 400);

// 6. driver: duplicate, self-activation, cross-business, rejection
const d1 = await freshUser('d');
const dj = await rpc(d1, 'join_via_invite_link', { p_token: links.rider, p_name: '[TEST] Sec Driver', p_phone: '+60 13-2' + stamp });
await rpc(d1, 'join_via_invite_link', { p_token: links.rider, p_name: '[TEST] Sec Driver', p_phone: '+60 13-9' + stamp });
const drows = (await sel(owner, `riders?select=id,status&business_id=eq.${B}&auth_user_id=eq.${uid(d1)}`)).body;
ok('6 driver link -> ONE pending driver row', dj.body?.kind === 'rider' && drows?.length === 1 && drows[0].status === 'pending', JSON.stringify(drows));
ok('  driver cannot activate themselves', denied(await rest(d1, 'PATCH', `riders?id=eq.${drows[0].id}`, { status: 'active' })) && (await rpc(d1, 'approve_pending_rider', { p_rider_id: drows[0].id })).status >= 400);
ok('  another business\'s owner cannot approve this driver', (await rpc(ownerX, 'approve_pending_rider', { p_rider_id: drows[0].id })).status >= 400);
ok('  driver membership never creates a team membership', ((await rpc(d1, 'get_my_businesses')).body || []).length === 0);
const dr = await rpc(owner, 'deactivate_rider', { p_rider_id: drows[0].id });
const dAfter = (await sel(owner, `riders?select=status&id=eq.${drows[0].id}`)).body[0];
ok('  owner rejects the driver -> inactive, no access', dr.status < 300 && dAfter.status === 'inactive', msg(dr));

// 7. reset invalidates the old link
const oldHelper = links.helper;
const reset = await rpc(owner, 'reset_invite_link', { p_business_id: B, p_kind: 'helper' });
const newHelper = tok(reset.body);
ok('7 owner resets the Helper link -> new token', reset.status === 200 && newHelper && newHelper !== oldHelper, msg(reset));
ok('  old link preview reports revoked', (await rpc(null, 'resolve_invite_link', { p_token: oldHelper })).body?.status === 'revoked');
const u2 = await freshUser('r');
const oldJoin = await rpc(u2, 'join_via_invite_link', { p_token: oldHelper, p_name: '[TEST] Sec Old', p_phone: '+60 13-3' + stamp });
ok('  old link can no longer be joined', oldJoin.status >= 400 && /not available/.test(msg(oldJoin)), msg(oldJoin));
const newJoin = await rpc(u2, 'join_via_invite_link', { p_token: newHelper, p_name: '[TEST] Sec New', p_phone: '+60 13-3' + stamp });
ok('  new link works (pending helper)', newJoin.body?.status === 'pending' && newJoin.body?.kind === 'helper', msg(newJoin));
ok('  operator cannot reset links', (await rpc(operator, 'reset_invite_link', { p_business_id: B, p_kind: 'helper' })).status >= 400);
// tidy: reject the pending request created by this suite
const p2 = (await sel(owner, `team_join_requests?select=id&business_id=eq.${B}&user_id=eq.${uid(u2)}&status=eq.pending`)).body?.[0];
if (p2) await rpc(owner, 'decide_team_join_request', { p_request_id: p2.id, p_approve: false });

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
console.log('NEW helper link token (after reset):', newHelper);
process.exit(fails ? 1 : 0);
