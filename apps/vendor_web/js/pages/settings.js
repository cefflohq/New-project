// Settings — side settings navigation (Founder references 4–8, 11). Page
// destinations render beside the navigation; Language, Appearance and
// Notifications open as focused modals over the blurred current page.
import { t, fmtDate } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { prefs, savePrefs } from '../prefs.js';
import { fetchBusiness, fetchZones, fetchMembers, fetchJoinRequests } from '../data.js';
import { esc, icon, avatar, chip, loadingRows, emptyState, errorState, gatedNote, toast, busy, modal, typedConfirmDialog } from '../ui.js';
import { showInviteLink } from '../invite_link.js';
import { rerenderShell, signOutHandler } from '../shell.js';
import { otpBoxesHtml, wireOtpBoxes, otpFailure } from './auth.js';
import { openNotificationPrefs } from '../notifications.js';

const PAGES = ['profile', 'security', 'business', 'team', 'integrations', 'help', 'privacy', 'about'];
// D-74, as Vendor Mobile: business details, Team and billing are Owner-only.
// Integrations stays open to Operators (Founder, 2026-09-29).
const OWNER_ONLY = new Set(['business', 'team', 'subscription']);

export default function settings({ el, params, setHeader }) {
  setHeader(t('set.title'), false);
  let sub = PAGES.includes(params[0]) ? params[0] : 'profile';
  if (OWNER_ONLY.has(sub) && !ctx.isOwner) sub = 'profile';
  const item = (id, ic, key, tail = '') => `<button data-s="${id}" class="${sub === id ? 'on' : ''}"${sub === id ? ' aria-current="page"' : ''}>${icon(ic)}<span>${esc(t(key))}</span>${tail ? `<span class="tail">${tail}</span>` : ''}</button>`;
  el.innerHTML = `<div class="settings">
    <nav class="settings-nav" aria-label="${esc(t('set.title'))}">
      <h4>${esc(t('set.account'))}</h4>
      ${item('profile', 'user', 'set.profile')}${item('security', 'lock', 'set.security')}
      ${item('m:notifications', 'bell', 'set.notifications')}
      ${item('m:language', 'globe', 'set.language', esc(prefs.lang === 'ms' ? 'BM' : 'EN'))}
      ${item('m:appearance', 'palette', 'set.appearance')}
      <h4>${esc(t('set.business'))}</h4>${ctx.isOwner ? item('business', 'building', 'set.businessProfile') + item('team', 'users', 'set.team') : ''}${item('integrations', 'link', 'set.integrations')}
      <h4>${esc(t('set.support'))}</h4>${item('help', 'help', 'set.help')}
      <h4>${esc(t('set.legal'))}</h4>${item('privacy', 'shield', 'set.privacy')}${item('about', 'info', 'set.about')}
      <button class="signout" data-signout>${icon('logout')}<span>${esc(t('set.signOut'))}</span></button>
    </nav>
    <div class="settings-page" data-page>${loadingRows(4)}</div></div>`;
  const page = el.querySelector('[data-page]');
  el.querySelector('.settings-nav').addEventListener('click', e => {
    if (e.target.closest('[data-signout]')) { signOutHandler()(); return; }
    const s = e.target.closest('[data-s]')?.dataset.s;
    if (!s) return;
    if (s === 'm:language') return openLanguage();
    if (s === 'm:appearance') return openAppearance();
    if (s === 'm:notifications') return openNotificationPrefs();
    location.hash = `#/settings/${s}`;
  });
  ({ profile, security, business, team, integrations, help: staticPage('help'), privacy: staticPage('privacy'), about: staticPage('about') })[sub](page);
}

// ---------------------------------------------------------------- modals
function openLanguage() {
  let pick = prefs.lang;
  const opt = (v, label) => `<button class="opt ${pick === v ? 'on' : ''}" data-v="${v}"><div><b>${label}</b></div><span class="radio"></span></button>`;
  const m = modal({ title: t('lang.title'), lead: t('lang.lead'), body: opt('en', 'English') + opt('ms', 'Bahasa Melayu'), center: true,
    footer: `<button class="btn primary" data-msave style="min-width:240px">${esc(t('lang.save'))}</button>` });
  m.el.addEventListener('click', e => {
    const o = e.target.closest('[data-v]');
    if (o) { pick = o.dataset.v; m.el.querySelectorAll('[data-v]').forEach(b => b.classList.toggle('on', b === o)); }
    if (e.target.closest("[data-msave]")) { savePrefs({ lang: pick }); m.close(); rerenderShell(); }
  });
}

function openAppearance() {
  let pick = prefs.theme === 'dark' ? 'dark' : 'light';
  const opt = (v, key, subKey) => `<button class="opt ${pick === v ? 'on' : ''}" data-v="${v}"><div><b>${esc(t(key))}</b><small>${esc(t(subKey))}</small></div><span class="radio"></span></button>`;
  const m = modal({ title: t('app.title'), lead: t('app.lead'), center: true,
    body: opt('light', 'app.light', 'app.lightSub') + opt('dark', 'app.dark', 'app.darkSub'),
    footer: `<button class="btn primary" data-msave style="min-width:240px">${esc(t('app.save'))}</button>` });
  m.el.addEventListener('click', e => {
    const o = e.target.closest('[data-v]');
    if (o) { pick = o.dataset.v; m.el.querySelectorAll('[data-v]').forEach(b => b.classList.toggle('on', b === o)); }
    if (e.target.closest("[data-msave]")) { savePrefs({ theme: pick }); m.close(); }
  });
}

// ---------------------------------------------------------------- pages
function header(page, titleKey, leadKey) {
  page.innerHTML = `<h2>${esc(t(titleKey))}</h2><p class="lead">${esc(t(leadKey))}</p><div data-body>${loadingRows(3)}</div>`;
  return page.querySelector('[data-body]');
}

async function profile(page) {
  const body = header(page, 'set.profile', 'prof.lead');
  try {
    const u = ctx.user;
    const rows = await api.get(`/rest/v1/profiles?id=eq.${u.id}&select=display_name,phone,avatar_url`);
    const p = rows?.[0] || {};
    const name = p.display_name || u.user_metadata?.full_name || '';
    body.innerHTML = `
      <div class="photo">
        <button type="button" class="photo-btn" data-photo aria-label="${esc(t('prof.photoChange'))}">${avatar(name || u.email, 'xl')}<i class="spin" data-photo-spin hidden></i></button>
        <input type="file" accept="image/jpeg,image/png,image/webp" data-photo-input hidden>
        <div class="photo-actions">
          <button class="icon-btn" type="button" data-photo-pick title="${esc(t('prof.photoChange'))}" aria-label="${esc(t('prof.photoChange'))}">${icon('camera')}</button>
          <button class="icon-btn danger" type="button" data-photo-remove title="${esc(t('prof.photoRemove'))}" aria-label="${esc(t('prof.photoRemove'))}" ${p.avatar_url ? '' : 'hidden'}>${icon('trash')}</button>
        </div>
        <div class="err" data-photo-err hidden role="alert"></div>
      </div>
      <div class="sub-card"><h3>${esc(t('prof.personal'))}</h3>
        <div class="form-row"><label>${esc(t('prof.fullName'))}</label><input class="input" name="name" maxlength="80" value="${esc(name)}"></div>
        <div class="form-row"><label>${esc(t('prof.email'))}</label><div class="inline-field"><input class="input" name="email" type="email" value="${esc(u.email)}"><button class="btn soft" data-email>${esc(t('c.change'))}</button></div></div>
        <div class="form-row"><label>${esc(t('prof.phone'))}</label><input class="input" name="phone" inputmode="tel" value="${esc(p.phone || '')}"></div>
        <div class="err" data-err hidden></div>
        <div class="row-end"><button class="btn primary" data-save>${esc(t('c.save'))}</button></div></div>
      <div class="sub-card row-card"><div class="grow"><h3>${esc(t('prof.password'))}</h3><p class="desc" style="margin:0">${esc(t('prof.passwordLead'))}</p></div>
        <a class="btn soft" href="#/settings/security">${esc(t('prof.changePassword'))}</a></div>`;
    // One shared answer to "does this user's profiles row exist yet?" for
    // Save and the photo control, so neither inserts it twice.
    const row = { exists: !!rows?.length };
    wirePhoto(body, u, row, name, p.avatar_url);
    const err = body.querySelector('[data-err]');
    body.querySelector('[data-save]').addEventListener('click', async e => {
      const display_name = body.querySelector('[name=name]').value.trim();
      const phone = body.querySelector('[name=phone]').value.trim();
      if (!display_name) { err.textContent = t('c.required'); err.hidden = false; return; }
      err.hidden = true;
      try {
        await busy(e.currentTarget, async () => {
          if (row.exists) await api.write(`/rest/v1/profiles?id=eq.${u.id}`, 'PATCH', { display_name, phone: phone || null, updated_at: new Date().toISOString() });
          else { await api.write('/rest/v1/profiles', 'POST', { id: u.id, display_name, phone: phone || null }); row.exists = true; }
          ctx.user = await api.updateUser({ data: { full_name: display_name } });
        });
        toast(t('c.saved'));
      } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    });
    body.querySelector('[data-email]').addEventListener('click', async e => {
      const email = body.querySelector('[name=email]').value.trim();
      if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { err.textContent = t('c.invalidEmail'); err.hidden = false; return; }
      if (email === u.email) return;
      // Secure Email Change (kept, Founder 2026-09-30): GoTrue sends a code to
      // BOTH addresses and changes the email only after both are confirmed.
      try {
        await busy(e.currentTarget, () => api.updateUser({ email }));
        // Done only when the account's email really is the new one.
        openEmailChangeCodes(u.email, email, async () => {
          ctx.user = await api.user();
          body.querySelector('[name=email]').value = ctx.user.email;
          if (ctx.user.email !== email) return false;
          toast(t('otp.changeDone', { email: ctx.user.email }));
          return true;
        });
      } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    });
  } catch (e) { body.innerHTML = errorState(e); }
}

function security(page) {
  const body = header(page, 'set.security', 'sec.lead');
  body.innerHTML = `
    <div class="sub-card"><h3>${esc(t('prof.changePassword'))}</h3>
      <p class="desc">${esc(t('sec.pwLead'))}</p>
      <div class="form-row"><label for="p1">${esc(t('sec.new'))}</label><div class="pw"><input class="input" id="p1" type="password" name="p1" autocomplete="new-password"><button type="button" class="pw-eye" data-eye aria-label="${esc(t('sec.show'))}">${icon('eye')}</button></div></div>
      <div class="form-row"><label for="p2">${esc(t('sec.confirm'))}</label><div class="pw"><input class="input" id="p2" type="password" name="p2" autocomplete="new-password"><button type="button" class="pw-eye" data-eye aria-label="${esc(t('sec.show'))}">${icon('eye')}</button></div></div>
      <div class="err" data-err hidden></div>
      <div class="row-end"><span class="hint">${esc(t('sec.rule'))}</span><button class="btn primary" data-save>${esc(t('sec.update'))}</button></div></div>
    <div class="sub-card"><h3>${esc(t('sec.2fa'))}</h3><p class="desc">${esc(t('sec.2faLead'))}</p>${gatedNote(t('c.awaitingApproval'))}</div>
    <div class="sub-card row-card"><div class="grow"><h3>${esc(t('sec.actions'))}</h3><p class="desc" style="margin:0">${esc(t('sec.actionsLead'))}</p></div>
      <button class="btn danger-soft" data-out>${icon('logout')}${esc(t('shell.signOut'))}</button></div>`;
  body.addEventListener('click', e => {
    const eye = e.target.closest('[data-eye]');
    if (eye) { const i = eye.previousElementSibling; i.type = i.type === 'password' ? 'text' : 'password'; eye.classList.toggle('on', i.type === 'text'); }
    if (e.target.closest('[data-out]')) signOutHandler()();
  });
  body.querySelector('[data-save]').addEventListener('click', async e => {
    const p1 = body.querySelector('[name=p1]').value, p2 = body.querySelector('[name=p2]').value, err = body.querySelector('[data-err]');
    err.hidden = false;
    if (p1.length < 8) { err.textContent = t('sec.short'); return; }
    if (p1 !== p2) { err.textContent = t('sec.mismatch'); return; }
    err.hidden = true;
    try { await busy(e.currentTarget, () => api.updateUser({ password: p1 })); toast(t('sec.updated')); body.querySelectorAll('input').forEach(i => { i.value = ''; }); } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
}

async function business(page) {
  const body = header(page, 'set.businessProfile', 'bp.lead');
  try {
    const [b, zs, hours] = await Promise.all([fetchBusiness(), fetchZones(), api.get(`/rest/v1/business_hours?business_id=eq.${encodeURIComponent(ctx.bid)}&select=weekday,is_open,opens_at,closes_at&order=weekday`).then(r => r || [])]);
    const active = (zs || []).filter(z => z.status === 'active');
    body.innerHTML = `
      <div class="sub-card"><h3>${esc(t('bp.info'))}</h3><p class="desc">${esc(t('bp.infoLead'))}</p>
        <div class="g2">
          <div class="field"><label>${esc(t('bp.name'))}</label><input class="input" name="name" maxlength="120" value="${esc(b.name)}"></div>
          <div class="field"><label>${esc(t('bp.email'))}</label><input class="input" name="email" type="email" value="${esc(b.email || '')}"></div>
          <div class="field"><label>${esc(t('bp.phone'))}</label><input class="input" name="phone" inputmode="tel" value="${esc(b.phone || '')}"></div>
          <div class="field"><label>${esc(t('bp.address'))}</label><textarea class="textarea" name="address" rows="2">${esc(b.address || '')}</textarea></div></div>
        <div class="err" data-err hidden></div>
        <div style="display:flex;justify-content:flex-end;margin-top:12px"><button class="btn primary" data-save>${esc(t('c.save'))}</button></div></div>
      <div class="sub-card"><h3>${esc(t('bp.area'))}</h3><p class="desc">${esc(t('bp.areaLead'))}</p>
        <div class="boxed stats" style="margin-bottom:12px"><div class="stat"><b style="font-size:18px">${b.service_coverage_radius_km ? esc(t('bp.km', { n: Number(b.service_coverage_radius_km) })) : '—'}</b><span>${esc(t('bp.radius'))}</span></div>
          <div class="stat"><b style="font-size:18px">${esc(t('bp.zonesN', { n: active.length }))}</b><span>${esc(t('bp.activeZones'))}</span></div>
          <div class="stat"><b style="font-size:15px">${esc(active.slice(0, 3).map(z => z.name).join(', ') || '—')}</b><span>${esc(t('bp.areasCovered'))}</span></div></div>
        <div class="g4">
          <div class="field"><label>${esc(t('bp.origin'))}</label><input class="input" name="lat" inputmode="decimal" value="${esc(b.service_origin_latitude ?? '')}" placeholder="3.139"></div>
          <div class="field"><label>&nbsp;</label><input class="input" name="lng" inputmode="decimal" value="${esc(b.service_origin_longitude ?? '')}" placeholder="101.687"></div>
          <div class="field"><label>${esc(t('bp.radius'))} (km)</label><input class="input" name="radius" inputmode="decimal" value="${esc(b.service_coverage_radius_km ?? '')}"></div>
          <button class="btn soft" data-area>${esc(t('c.save'))}</button></div>
        <button class="link-btn" type="button" data-locate style="margin-top:10px">${esc(t('bp.locate'))}</button>
        <div class="err" data-aerr hidden></div>
        <div style="margin-top:12px">${gatedNote(t('bp.mapGated'))}</div></div>
      <div class="sub-card" data-hours><h3>${esc(t('hours.title'))}</h3><p class="desc">${esc(t('hours.lead'))}</p>
        ${[1, 2, 3, 4, 5, 6, 7].map(d => { const h = hours.find(x => x.weekday === d) || {}; return `<div class="g4" data-day="${d}" style="align-items:center;margin-bottom:6px">
          <b style="font-weight:500">${esc(t(`hours.d${d}`))}</b>
          <label style="display:flex;gap:8px;align-items:center"><input type="checkbox" data-open ${h.is_open ? 'checked' : ''}>${esc(t('hours.open'))}</label>
          <input class="input" type="time" data-from value="${esc((h.opens_at || '09:00').slice(0, 5))}" aria-label="${esc(t('hours.from'))}">
          <input class="input" type="time" data-to value="${esc((h.closes_at || '18:00').slice(0, 5))}" aria-label="${esc(t('hours.to'))}"></div>`; }).join('')}
        <div class="err" data-herr hidden></div>
        <div style="display:flex;justify-content:flex-end;margin-top:12px"><button class="btn primary" data-hsave>${esc(t('c.save'))}</button></div></div>
      <div class="sub-card"><h3>${esc(t('bp.description'))} · ${esc(t('bp.social'))}</h3>${gatedNote(t('bp.gatedFields'))}</div>`;
    // Business Hours V1 (V-40): ISO weekdays 1-7, one interval per day,
    // overnight allowed; the whole week is replaced atomically, Owner only.
    const syncDay = row => row.querySelectorAll('[data-from],[data-to]').forEach(i => { i.disabled = !row.querySelector('[data-open]').checked; });
    body.querySelectorAll('[data-day]').forEach(syncDay);
    body.querySelector('[data-hours]').addEventListener('change', e => { const row = e.target.closest('[data-day]'); if (row) syncDay(row); });
    body.querySelector('[data-hsave]').addEventListener('click', async e => {
      const herr = body.querySelector('[data-herr]');
      const days = [...body.querySelectorAll('[data-day]')].map(r => {
        const open = r.querySelector('[data-open]').checked;
        return { weekday: Number(r.dataset.day), is_open: open, opens_at: open ? r.querySelector('[data-from]').value : null, closes_at: open ? r.querySelector('[data-to]').value : null };
      });
      if (days.some(d => d.is_open && (!d.opens_at || !d.closes_at))) { herr.textContent = t('c.required'); herr.hidden = false; return; }
      herr.hidden = true;
      try { await busy(e.currentTarget, () => api.rpc('set_business_hours', { p_business_id: ctx.bid, p_days: days })); toast(t('c.saved')); } catch (ex) { herr.textContent = ex.message; herr.hidden = false; }
    });
    const err = body.querySelector('[data-err]');
    body.querySelector('[data-save]').addEventListener('click', async e => {
      const v = n => body.querySelector(`[name=${n}]`).value.trim();
      if (!v('name')) { err.textContent = t('c.required'); err.hidden = false; return; }
      if (v('email') && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v('email'))) { err.textContent = t('c.invalidEmail'); err.hidden = false; return; }
      err.hidden = true;
      try {
        await busy(e.currentTarget, () => api.rpc('update_business_profile', { p_business_id: ctx.bid, p_name: v('name'), p_phone: v('phone') || null, p_email: v('email') || null, p_address: v('address') || null, p_operating_area: b.operating_area, p_timezone: b.timezone, p_currency: b.currency, p_idempotency_key: crypto.randomUUID() }));
        toast(t('c.saved'));
      } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    });
    // Pickup origin from the saved business address: the existing
    // geocode-order business mode, then the owner saves with the existing
    // set_business_service_area. No polygons.
    body.querySelector('[data-locate]').addEventListener('click', async e => {
      const aerr = body.querySelector('[data-aerr]');
      aerr.hidden = true;
      try {
        const res = await busy(e.currentTarget, () => api.fn('geocode-order', { business_id: ctx.bid }));
        if (res?.status !== 'resolved') throw new Error(t('bp.locateFailed'));
        body.querySelector('[name=lat]').value = res.latitude;
        body.querySelector('[name=lng]').value = res.longitude;
        const r = body.querySelector('[name=radius]');
        if (!r.value) r.value = 5;
        toast(t('bp.located'));
      } catch (ex) { aerr.textContent = ex.message && ex.status !== 404 ? ex.message : t('bp.locateFailed'); aerr.hidden = false; }
    });
    body.querySelector('[data-area]').addEventListener('click', async e => {
      const aerr = body.querySelector('[data-aerr]');
      const lat = Number(body.querySelector('[name=lat]').value), lng = Number(body.querySelector('[name=lng]').value), r = Number(body.querySelector('[name=radius]').value);
      if (!Number.isFinite(lat) || !Number.isFinite(lng) || !(r > 0)) { aerr.textContent = t('c.required'); aerr.hidden = false; return; }
      aerr.hidden = true;
      try { await busy(e.currentTarget, () => api.rpc('set_business_service_area', { p_business_id: ctx.bid, p_origin_latitude: lat, p_origin_longitude: lng, p_radius_km: r })); toast(t('c.saved')); } catch (ex) { aerr.textContent = ex.message; aerr.hidden = false; }
    });
  } catch (e) { body.innerHTML = errorState(e); }
}

// Team (Owner-only page): active members with Owner-only Remove member
// (typed CONFIRM + fresh read-back) and invite-link join requests awaiting the
// Owner's decision. Invitations use the permanent link + QR only. Security & Access Master Part III
// §12, §17-24; the server authorises every action.
async function team(page) {
  const body = header(page, 'set.team', 'team.lead');
  let names = new Map();
  const memberName = m => m.user_id === ctx.user.id
    ? `${ctx.user.user_metadata?.full_name || ctx.user.email} (${t('team.you')})`
    : (names.get(m.user_id) || t('team.member'));
  const paint = async () => {
    try {
      const [members, requests, approved] = await Promise.all([
        fetchMembers(), fetchJoinRequests('pending'), fetchJoinRequests('approved').catch(() => []),
      ]);
      names = new Map((approved || []).filter(r => r.user_id && r.name).map(r => [r.user_id, r.name]));
      const unnamed = (members || []).some(m => m.user_id !== ctx.user.id && !names.has(m.user_id));
      body.innerHTML = `
        <div style="display:flex;justify-content:flex-end;margin-bottom:12px"><button class="btn cta" data-invite>${icon('plus')}${esc(t('team.invite'))}</button></div>
        <div class="sub-card"><h3>${esc(t('team.members'))}</h3>${(members || []).map(m => `<div class="list-row" style="cursor:default">${avatar(memberName(m))}
            <div class="grow"><b>${esc(memberName(m))}</b><small>${esc(t(`team.${m.role}`))}</small></div>${chip('active', true)}
            ${m.role !== 'owner' ? `<button class="btn sm danger-soft" data-remove="${esc(m.user_id)}">${esc(t('team.remove'))}</button>` : ''}</div>`).join('')}
          ${unnamed ? `<div style="margin-top:10px">${gatedNote(t('team.memberNameGated'))}</div>` : ''}</div>
        <div class="sub-card"><h3>${esc(t('team.pending'))}</h3><p class="desc" style="margin:0 0 6px">${esc(t('team.pendingLead'))}</p>
          ${(requests || []).length ? requests.map(r => `<div class="list-row" style="cursor:default">${avatar(r.name || r.role)}
              <div class="grow"><b>${esc(r.name || t('team.member'))}</b><small>${esc(t(`team.${r.role}`))} · ${esc(t('team.requested'))} ${esc(fmtDate(r.created_at))}</small></div>
              <button class="btn sm" data-decide="${esc(r.id)}" data-approve="0">${esc(t('team.reject'))}</button>
              <button class="btn sm primary" data-decide="${esc(r.id)}" data-approve="1">${esc(t('team.approve'))}</button></div>`).join('')
            : `<div class="hint" style="padding:10px 0">${esc(t('c.none'))}</div>`}</div>`;
    } catch (e) { body.innerHTML = errorState(e); }
  };
  body.addEventListener('click', async e => {
    if (e.target.closest('[data-invite]')) return showInviteLink('team');
    // Pending requests: Approve / Reject; rejecting never needs typed CONFIRM.
    const dc = e.target.closest('[data-decide]');
    if (dc) {
      const approve = dc.dataset.approve === '1';
      try {
        await busy(dc, () => api.rpc('decide_team_join_request', { p_request_id: dc.dataset.decide, p_approve: approve }));
        toast(t(approve ? 'team.approved' : 'team.rejected')); paint();
      } catch (ex) { toast(ex.message, 'error'); }
      return;
    }
    const rm = e.target.closest('[data-remove]');
    if (rm) {
      const userId = rm.dataset.remove, name = names.get(userId) || t('team.member');
      if (!await typedConfirmDialog({ title: t('team.removeTitle', { name }), body: t('team.removeBody', { name }), confirmLabel: t('team.remove') })) return;
      try {
        await api.rpc('update_team_member', { p_business_id: ctx.bid, p_user_id: userId, p_status: 'inactive' });
        const still = ((await fetchMembers()) || []).some(m => m.user_id === userId);
        if (still) { toast(t('c.removalNotConfirmed'), 'error'); return; }
        toast(t('team.removed')); paint();
      } catch (ex) { toast(ex.message, 'error'); }
    }
  });
  paint();
}

// Integrations: master list + detail panel (Founder reference). Only what the
// app can really do is Available; everything else is marked Planned and has no
// connect action.
const BRAND = {
  csv: `<span class="brand-ico file">${icon('csv')}</span>`,
  manual: `<span class="brand-ico file">${icon('file')}</span>`,
  shopify: '<span class="brand-ico"><svg viewBox="0 0 32 32" aria-hidden="true"><path fill="#95BF47" d="M22.6 6.3c0-.1-.1-.2-.2-.2l-2.1-.2-1.6-1.6c-.2-.2-.5-.1-.6-.1l-.8.3C16.8 3.1 16 2.2 14.6 2.2h-.1c-.4-.5-.9-.7-1.3-.7-3.2 0-4.8 4-5.2 6l-2.3.7c-.7.2-.7.2-.8.9L3 27.3l15.2 2.8 8.2-1.8L22.6 6.3z"/><path fill="#5E8E3E" d="M22.4 6.1l-2.1-.2-1.6-1.6-.4-.1L18.2 30l8.2-1.8L22.6 6.3c0-.1-.1-.2-.2-.2z"/><path fill="#fff" d="M14.6 11.2l-1 3s-.9-.5-2-.5c-1.6 0-1.7 1-1.7 1.3 0 1.4 3.6 1.9 3.6 5.1 0 2.5-1.6 4.2-3.8 4.2-2.6 0-4-1.6-4-1.6l.7-2.3s1.4 1.2 2.6 1.2c.8 0 1.1-.6 1.1-1.1 0-1.8-3-1.9-3-4.9 0-2.5 1.8-5 5.5-5 1.4 0 2 .4 2 .4z"/></svg></span>',
  woo: '<span class="brand-ico"><svg viewBox="0 0 32 32" aria-hidden="true"><rect x="1" y="7" width="30" height="16" rx="4" fill="#7F54B3"/><path fill="#7F54B3" d="M17 22l3 5 1-5z"/><text x="16" y="19" text-anchor="middle" font-family="Inter,Arial" font-weight="800" font-size="10" fill="#fff">Woo</text></svg></span>',
  wix: '<span class="brand-ico" style="color:var(--ink)"><svg viewBox="0 0 32 32" aria-hidden="true"><text x="16" y="21" text-anchor="middle" font-family="Inter,Arial" font-weight="800" font-size="12" fill="currentColor">WiX</text></svg></span>',
  sheets: '<span class="brand-ico"><img src="img/google-sheets-logo.png" alt="" width="26" height="26"></span>',
  excel: '<span class="brand-ico"><svg viewBox="0 0 32 32" aria-hidden="true"><rect x="9" y="4" width="20" height="24" rx="2" fill="#21A366"/><path fill="#33C481" d="M19 4h8a2 2 0 0 1 2 2v6H19z"/><path fill="#107C41" d="M9 16h10v12h-8a2 2 0 0 1-2-2z"/><rect x="3" y="9" width="14" height="14" rx="2" fill="#107C41"/><path fill="#fff" d="M6.4 12.5h2.3l1.3 2.4 1.3-2.4h2.2l-2.3 3.5 2.4 3.5h-2.3L10 17l-1.4 2.5H6.3l2.4-3.5z"/></svg></span>',
  drive: '<span class="brand-ico"><svg viewBox="0 0 32 32" aria-hidden="true"><path fill="#0066DA" d="M4.3 24.6l1.3 2.3c.3.5.7.9 1.1 1.1l4.6-8H2.1c0 .6.1 1.1.4 1.6z"/><path fill="#00AC47" d="M16 11.5 11.4 3.5c-.4.3-.8.6-1.1 1.1L2.5 18.4c-.3.5-.4 1-.4 1.6h9.2z"/><path fill="#EA4335" d="M25.3 28c.4-.3.8-.6 1.1-1.1l.5-.9 2.6-4.4c.3-.5.4-1 .4-1.6h-9.2l2 3.9z"/><path fill="#00832D" d="M16 11.5l4.6-8c-.4-.3-1-.4-1.5-.4h-6.2c-.5 0-1.1.2-1.5.4z"/><path fill="#2684FC" d="M20.7 20H11.3l-4.6 8c.4.3 1 .4 1.5.4h15.6c.5 0 1.1-.2 1.5-.4z"/><path fill="#FFBA00" d="M25.2 12.1l-4.3-7.4c-.3-.5-.7-.9-1.1-1.1L15.2 11.5 20.7 20h9.2c0-.6-.1-1.1-.4-1.6z"/></svg></span>',
  api: `<span class="brand-ico file">${icon('code')}</span>`,
};
const INTEGRATIONS = [
  { id: 'csv', name: () => t('int.csv'), sub: () => t('int.csvSub'), live: true, action: 'import' },
  { id: 'manual', name: () => t('int.manual'), sub: () => t('int.manualSub'), live: true, action: 'add' },
  { id: 'shopify', name: () => 'Shopify', sub: () => t('int.shopSub') },
  { id: 'woo', name: () => 'WooCommerce', sub: () => t('int.shopSub') },
  { id: 'wix', name: () => 'Wix eCommerce', sub: () => t('int.shopSub') },
  { id: 'excel', name: () => 'Microsoft Excel', sub: () => t('int.excelSub'), live: true, action: 'import' },
  { id: 'sheets', name: () => 'Google Sheets', sub: () => t('int.sheetsSub') },
  { id: 'drive', name: () => 'Google Drive', sub: () => t('int.driveSub') },
  { id: 'api', name: () => 'API / Webhooks', sub: () => t('int.apiSub') },
];
let intSelected = 'csv';

function integrations(page) {
  const body = header(page, 'set.integrations', 'int.lead');
  const status = x => (x.live
    ? `<span class="chip active"><i class="dot"></i>${esc(t('int.available'))}</span>`
    : `<span class="chip neutral"><i class="dot"></i>${esc(t('int.planned'))}</span>`);
  const paint = () => {
    const x = INTEGRATIONS.find(i => i.id === intSelected) || INTEGRATIONS[0];
    const points = x.live ? [`int.${x.id}P1`, `int.${x.id}P2`, `int.${x.id}P3`] : ['int.planP1', 'int.planP2', 'int.planP3'];
    body.innerHTML = `<div class="int-md">
      <div class="int-list" role="listbox" aria-label="${esc(t('set.integrations'))}">
        ${INTEGRATIONS.map(i => `<button type="button" class="int-row ${i.id === x.id ? 'on' : ''}" role="option" aria-selected="${i.id === x.id}" data-int="${i.id}">
          ${BRAND[i.id]}<span class="grow"><b>${esc(i.name())}</b><small>${esc(i.sub())}</small></span>${status(i)}${icon('right', 'i chev')}</button>`).join('')}
      </div>
      <aside class="int-detail card" aria-live="polite">
        <div class="int-d-head">${BRAND[x.id].replace('brand-ico', 'brand-ico lg')}<div><h3>${esc(x.name())}</h3>${status(x)}</div></div>
        <p class="int-d-sub">${esc(x.sub())}</p>
        <ul class="int-points">${points.map((k, n) => `<li>${icon(['upload', 'map', 'route'][n])}<span>${esc(t(k))}</span></li>`).join('')}</ul>
        <div class="gated">${icon('info')}<div><b>${esc(t(x.live ? 'int.needTitle' : 'int.planTitle'))}</b><br>${esc(t(x.live ? `int.${x.id}Need` : 'int.planNote'))}</div></div>
        ${x.live
          ? `<button class="btn primary int-cta" data-int-action="${x.action}">${icon(x.action === 'import' ? 'upload' : 'plus')}${esc(t(x.action === 'import' ? 'today.importOrders' : 'today.addOrder'))}</button>`
          : `<button class="btn int-cta" disabled>${esc(t('c.notAvailable'))}</button>`}
      </aside>
    </div>
    <div class="flow" aria-label="${esc(t('int.how'))}"><span class="flow-title">${esc(t('int.how'))}</span>
      ${['int.s1', 'int.s2', 'int.s3', 'int.s4'].map((k, n) => `${n ? `<span class="flow-arrow">${icon('right')}</span>` : ''}<span class="flow-step"><span class="n">${n + 1}</span><span><b>${esc(t(k))}</b><small>${esc(t(`${k}Sub`))}</small></span></span>`).join('')}</div>`;
  };
  body.addEventListener('click', async e => {
    const r = e.target.closest('[data-int]');
    if (r) { intSelected = r.dataset.int; paint(); body.querySelector(`[data-int="${intSelected}"]`)?.focus(); return; }
    const act = e.target.closest('[data-int-action]')?.dataset.intAction;
    if (act === 'import') { const { openImport } = await import('./order_actions.js'); openImport(); }
    if (act === 'add') { const { openAddOrder } = await import('./order_actions.js'); openAddOrder(); }
  });
  paint();
}

function staticPage(kind) {
  return page => {
    const map = { help: ['set.help', 'help.lead'], privacy: ['set.privacy', 'priv.lead'], about: ['set.about', 'about.lead'] };
    const body = header(page, ...map[kind]);
    if (kind === 'help') {
      body.innerHTML = `<div class="sub-card"><h3>${esc(t('help.faq'))}</h3><div class="faq">
          ${[1, 2, 3, 4, 5, 6].map(n => `<details><summary>${esc(t(`help.q${n}`))}${icon('down')}</summary><p>${esc(t(`help.a${n}`))}</p></details>`).join('')}</div></div>
        <div class="sub-card" data-support><h3>${esc(t('help.contact'))}</h3>
          <p class="desc">${esc(t('help.contactLead'))} <b class="sel">support@cefflo.com</b></p>
          <div class="field"><label>${esc(t('support.subject'))}</label><input class="input" data-subject maxlength="120" placeholder="${esc(t('support.subjectHint'))}"></div>
          <div class="field"><label>${esc(t('support.message'))}</label><textarea class="textarea" data-message rows="4" maxlength="500" placeholder="${esc(t('support.messageHint'))}"></textarea></div>
          <p class="hint">${esc(t('support.opensEmail'))}</p>
          <div class="err" data-serr hidden></div>
          <div style="display:flex;justify-content:flex-end;margin-top:12px"><button class="btn primary" data-send>${icon('mail')}${esc(t('support.send'))}</button></div></div>`;
      // V-57 Contact Support (FG-4), as Vendor App: the request goes to
      // support@cefflo.com from the user's own email app with business and
      // account context. No ticket backend, so nothing is reported as sent.
      body.querySelector('[data-send]').addEventListener('click', () => {
        const msg = body.querySelector('[data-message]').value.trim(), serr = body.querySelector('[data-serr]');
        if (!msg) { serr.textContent = t('support.writeFirst'); serr.hidden = false; return; }
        serr.hidden = true;
        const subject = body.querySelector('[data-subject]').value.trim() || 'Cefflo Vendor support';
        const lines = [msg, '', '--', ctx.business && `Business: ${ctx.business.business_name} (${ctx.bid})`, ctx.role && `Role: ${ctx.role}`, ctx.user?.email && `Account: ${ctx.user.email}`, 'App: Cefflo Vendor Web'].filter(Boolean);
        location.href = `mailto:support@cefflo.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(lines.join('\n'))}`;
      });
    } else if (kind === 'privacy') {
      body.innerHTML = `<div class="sub-card"><h3>${esc(t('set.privacy'))}</h3><p class="desc" style="line-height:1.7">${esc(t('legal.privacy'))}</p></div>
        <div class="sub-card"><h3>${esc(t('legal.termsTitle'))}</h3><p class="desc" style="line-height:1.7">${esc(t('legal.terms'))}</p></div>`;
    } else {
      body.innerHTML = `<div class="sub-card row-card"><img src="img/cefflo-mark-white.png" alt="" class="about-mark"><div class="grow"><h3>Cefflo Vendor</h3><p class="desc" style="margin:0">${esc(t('about.lead'))}</p></div></div>
        <div class="sub-card"><div class="kv">${icon('info')}<div><small>${esc(t('about.version'))}</small><b>${esc(t('about.versionVal'))}</b></div></div>
          <div class="kv">${icon('shield')}<div><small>${esc(t('set.privacy'))}</small><b><a href="#/settings/privacy">${esc(t('about.readPrivacy'))}</a></b></div></div>
          <div class="kv">${icon('mail')}<div><small>${esc(t('help.contact'))}</small><b class="sel">support@cefflo.com</b></div></div></div>`;
    }
  };
}

// Change Email with 6-digit codes, one step per address. The email changes
// only when GoTrue has accepted both codes (Secure Email Change); a step's
// success is shown only after GoTrue accepts that code.
function openEmailChangeCodes(current, next, onDone) {
  const steps = [{ email: current, key: 'otp.changeCurrent' }, { email: next, key: 'otp.changeNew' }];
  let i = 0, busyNow = false, left = 0, timer = null;
  const m = modal({
    title: t('otp.title.email_change'),
    body: `<p class="hint" data-step></p><p class="auth-email" data-addr style="margin:0;text-align:center"></p>
      ${otpBoxesHtml()}
      <div class="err" data-err hidden role="alert"></div><div class="gated" data-ok hidden role="status"></div>
      <p class="hint" data-line style="text-align:center;margin:0"></p>`,
    footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-verify disabled>${esc(t('otp.verify'))}</button>`,
    onClose: () => clearInterval(timer),
  });
  const $ = s => m.el.querySelector(s);
  const err = $('[data-err]'), ok = $('[data-ok]'), verifyBtn = $('[data-verify]'), line = $('[data-line]');
  const otp = wireOtpBoxes($('.otp'), () => {
    err.hidden = true; otp.bad(false);
    verifyBtn.disabled = busyNow || !otp.complete();
    if (otp.complete() && !busyNow) verify();
  });
  const paint = () => {
    $('[data-step]').textContent = t(steps[i].key);
    $('[data-addr]').textContent = steps[i].email;
    otp.clear(); otp.focus(); verifyBtn.disabled = true;
  };
  const paintLine = () => {
    line.innerHTML = left > 0 ? esc(t('otp.resendIn', { s: left })) : `${esc(t('otp.noCode'))} <button class="link-btn" type="button" data-resend>${esc(t('otp.resend'))}</button>`;
    line.querySelector('[data-resend]')?.addEventListener('click', resend);
  };
  const countdown = s => { clearInterval(timer); left = s; paintLine(); if (s > 0) timer = setInterval(() => { left -= 1; if (left <= 0) clearInterval(timer); if (m.el.isConnected) paintLine(); }, 1000); };
  const failText = f => ({ incorrect: t('otp.incorrect'), rate: t('otp.rate'), network: t('otp.network') })[f?.kind] || f?.message || t('otp.incorrect');
  async function verify() {
    busyNow = true; err.hidden = true; ok.hidden = true; otp.disable(true);
    let ran = false, res;
    try {
      verifyBtn.disabled = false;
      await busy(verifyBtn, async () => { ran = true; res = await api.verifyOtp('email_change', steps[i].email, otp.code()); }, t('otp.verifying'));
      if (!ran) throw { kind: 'network' };
      if (i < steps.length - 1 && !res.done) { i += 1; paint(); return; }
      if (await onDone()) { m.close(); return; }
      // GoTrue accepted the code but the change is not complete yet.
      err.textContent = res.message || t('otp.incorrect'); err.hidden = false;
    } catch (ex) {
      const f = ex?.kind ? ex : otpFailure(ex);
      err.textContent = failText(f); err.hidden = false; otp.bad(true);
    } finally { busyNow = false; otp.disable(false); if (m.el.isConnected) otp.focus(); }
  }
  async function resend() {
    if (left > 0) return;
    try { await api.resendEmailChange(next); ok.textContent = t('otp.resent', { email: steps[i].email }); ok.hidden = false; countdown(60); }
    catch (ex) { const f = otpFailure(ex); err.textContent = failText(f); err.hidden = false; if (f.retryAfter) countdown(f.retryAfter); }
  }
  verifyBtn.addEventListener('click', verify);
  paint(); countdown(60);
}

// Profile photo: pick -> validate -> upload to the user's own path -> save
// profiles.avatar_url -> re-read the profile -> show the stored image. The
// photo shown is always the one read back from storage, never the local file.
const PHOTO_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const PHOTO_MAX = 2 * 1024 * 1024;
function wirePhoto(body, u, row, name, savedPath) {
  const btn = body.querySelector('[data-photo]'), input = body.querySelector('[data-photo-input]');
  const spin = body.querySelector('[data-photo-spin]'), err = body.querySelector('[data-photo-err]');
  const removeBtn = body.querySelector('[data-photo-remove]');
  const holder = btn.querySelector('.avatar');
  const show = async path => {
    const url = await api.avatarUrl(path).catch(() => '');
    holder.innerHTML = url ? `<img src="${esc(url)}" alt="">` : esc(initialsOf(name || u.email));
    removeBtn.hidden = !url;
  };
  const initialsOf = n => holder.dataset.initials || (holder.dataset.initials = holder.textContent.trim());
  initialsOf();
  if (savedPath) show(savedPath);
  const setBusy = on => { btn.disabled = on; spin.hidden = !on; btn.classList.toggle('busy', on); };
  const fail = m => { err.textContent = m; err.hidden = false; };
  const saveRow = async avatar_url => {
    if (row.exists) await api.write(`/rest/v1/profiles?id=eq.${u.id}`, 'PATCH', { avatar_url, updated_at: new Date().toISOString() });
    else { await api.write('/rest/v1/profiles', 'POST', { id: u.id, avatar_url }); row.exists = true; }
    const back = await api.get(`/rest/v1/profiles?id=eq.${u.id}&select=avatar_url`);
    return back?.[0]?.avatar_url || null;
  };
  const pick = () => { if (!btn.disabled) input.click(); };
  btn.addEventListener('click', pick);
  body.querySelector('[data-photo-pick]').addEventListener('click', pick);
  input.addEventListener('change', async () => {
    const file = input.files?.[0]; input.value = '';
    if (!file) return;
    err.hidden = true;
    if (!PHOTO_TYPES.includes(file.type)) return fail(t('prof.photoType'));
    if (file.size > PHOTO_MAX) return fail(t('prof.photoSize'));
    setBusy(true);
    try {
      await api.uploadAvatar(u.id, file);
      const saved = await saveRow(api.avatarPath(u.id));
      if (saved !== api.avatarPath(u.id)) throw new Error(t('prof.photoFailed'));
      await show(saved);
      toast(t('prof.photoSaved'));
    } catch (ex) { fail(ex.message || t('prof.photoFailed')); } finally { setBusy(false); }
  });
  removeBtn.addEventListener('click', async () => {
    err.hidden = true; setBusy(true);
    try {
      await api.removeAvatar(u.id);
      const saved = await saveRow(null);
      if (saved !== null) throw new Error(t('prof.photoFailed'));
      await show(null);
      toast(t('prof.photoRemoved'));
    } catch (ex) { fail(ex.message || t('prof.photoFailed')); } finally { setBusy(false); }
  });
}
