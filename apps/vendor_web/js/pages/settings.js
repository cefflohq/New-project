// Settings — side settings navigation (Founder references 4–8, 11). Page
// destinations render beside the navigation; Language, Appearance and
// Notifications open as focused modals over the blurred current page.
import { t, fmtDate } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { prefs, savePrefs } from '../prefs.js';
import { fetchBusiness, fetchZones, fetchMembers, fetchTeamInvites } from '../data.js';
import { esc, icon, avatar, chip, loadingRows, emptyState, errorState, gatedNote, toast, busy, modal, confirmDialog } from '../ui.js';
import { showLink } from './riders.js';
import { rerenderShell, signOutHandler } from '../shell.js';

const PAGES = ['profile', 'security', 'business', 'team', 'integrations', 'help', 'privacy', 'about'];
const OWNER_ONLY = new Set(['business', 'team', 'integrations', 'subscription']);

export default function settings({ el, params, setHeader }) {
  setHeader(t('set.title'), false);
  let sub = PAGES.includes(params[0]) ? params[0] : 'profile';
  if (OWNER_ONLY.has(sub) && !ctx.isOwner) sub = 'profile';
  const item = (id, ic, key, tail = '') => `<button data-s="${id}" class="${sub === id ? 'on' : ''}">${icon(ic)}<span>${esc(t(key))}</span><span class="tail">${tail}${icon('right')}</span></button>`;
  el.innerHTML = `<div class="settings">
    <div class="card settings-page" data-page>${loadingRows(4)}</div>
    <nav class="card settings-nav" aria-label="${esc(t('set.title'))}">
      <h4>${esc(t('set.account'))}</h4>
      ${item('profile', 'user', 'set.profile')}${item('security', 'lock', 'set.security')}
      ${item('m:notifications', 'bell', 'set.notifications')}
      ${item('m:language', 'globe', 'set.language', esc(prefs.lang === 'ms' ? 'Bahasa Melayu' : 'English'))}
      ${item('m:appearance', 'palette', 'set.appearance')}
      ${ctx.isOwner ? `<h4>${esc(t('set.business'))}</h4>${item('business', 'building', 'set.businessProfile')}${item('team', 'users', 'set.team')}${item('integrations', 'link', 'set.integrations')}` : ''}
      <h4>${esc(t('set.support'))}</h4>${item('help', 'help', 'set.help')}
      <h4>${esc(t('set.legal'))}</h4>${item('privacy', 'shield', 'set.privacy')}${item('about', 'info', 'set.about')}
      <button class="signout" data-signout>${icon('logout')}<span>${esc(t('set.signOut'))}</span></button>
    </nav></div>`;
  const page = el.querySelector('[data-page]');
  el.querySelector('.settings-nav').addEventListener('click', e => {
    if (e.target.closest('[data-signout]')) { signOutHandler()(); return; }
    const s = e.target.closest('[data-s]')?.dataset.s;
    if (!s) return;
    if (s === 'm:language') return openLanguage();
    if (s === 'm:appearance') return openAppearance();
    if (s === 'm:notifications') return openNotifications();
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
  let pick = prefs.theme;
  const opt = (v, key, subKey) => `<button class="opt ${pick === v ? 'on' : ''}" data-v="${v}"><div><b>${esc(t(key))}</b><small>${esc(t(subKey))}</small></div><span class="radio"></span></button>`;
  const m = modal({ title: t('app.title'), lead: t('app.lead'), center: true,
    body: opt('light', 'app.light', 'app.lightSub') + opt('dark', 'app.dark', 'app.darkSub') + opt('system', 'app.system', 'app.systemSub'),
    footer: `<button class="btn primary" data-msave style="min-width:240px">${esc(t('app.save'))}</button>` });
  m.el.addEventListener('click', e => {
    const o = e.target.closest('[data-v]');
    if (o) { pick = o.dataset.v; m.el.querySelectorAll('[data-v]').forEach(b => b.classList.toggle('on', b === o)); }
    if (e.target.closest("[data-msave]")) { savePrefs({ theme: pick }); m.close(); }
  });
}

function openNotifications() {
  modal({ title: t('notif.title'), lead: t('notif.lead'), body: gatedNote(t('notif.gated')),
    footer: `<button class="btn" data-close>${esc(t('c.close'))}</button>` });
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
    const rows = await api.get(`/rest/v1/profiles?id=eq.${u.id}&select=display_name,phone`);
    const p = rows?.[0] || {};
    const name = p.display_name || u.user_metadata?.full_name || '';
    body.innerHTML = `
      <div class="sub-card" style="display:flex;gap:24px;align-items:center">${avatar(name || u.email, 'lg')}
        <div style="flex:1"><h3 style="font-size:24px">${esc(name || u.email)}</h3>${gatedNote(t('prof.photoGated'))}</div></div>
      <div class="sub-card"><h3>${esc(t('prof.personal'))}</h3>
        <div class="form-row"><label>${esc(t('prof.fullName'))}</label><input class="input" name="name" maxlength="80" value="${esc(name)}"></div>
        <div class="form-row"><label>${esc(t('prof.email'))}</label><div style="display:flex;gap:10px"><input class="input" name="email" type="email" value="${esc(u.email)}"><button class="btn soft" data-email>${esc(t('c.change'))}</button></div></div>
        <div class="form-row"><label>${esc(t('prof.phone'))}</label><input class="input" name="phone" inputmode="tel" value="${esc(p.phone || '')}"></div>
        <div class="err" data-err hidden></div>
        <div style="display:flex;justify-content:flex-end"><button class="btn primary" data-save>${esc(t('c.save'))}</button></div></div>
      <div class="sub-card" style="display:flex;align-items:center;gap:16px"><div style="flex:1"><h3>${esc(t('prof.password'))}</h3><p class="desc" style="margin:0">${esc(t('prof.passwordLead'))}</p></div>
        <a class="btn soft" href="#/settings/security">${esc(t('prof.changePassword'))}</a></div>`;
    const err = body.querySelector('[data-err]');
    body.querySelector('[data-save]').addEventListener('click', async e => {
      const display_name = body.querySelector('[name=name]').value.trim();
      const phone = body.querySelector('[name=phone]').value.trim();
      if (!display_name) { err.textContent = t('c.required'); err.hidden = false; return; }
      err.hidden = true;
      try {
        await busy(e.currentTarget, async () => {
          if (rows?.length) await api.write(`/rest/v1/profiles?id=eq.${u.id}`, 'PATCH', { display_name, phone: phone || null, updated_at: new Date().toISOString() });
          else await api.write('/rest/v1/profiles', 'POST', { id: u.id, display_name, phone: phone || null });
          ctx.user = await api.updateUser({ data: { full_name: display_name } });
        });
        toast(t('c.saved'));
      } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    });
    body.querySelector('[data-email]').addEventListener('click', async e => {
      const email = body.querySelector('[name=email]').value.trim();
      if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { err.textContent = t('c.invalidEmail'); err.hidden = false; return; }
      if (email === u.email) return;
      try { await busy(e.currentTarget, () => api.updateUser({ email })); toast(t('prof.emailSent')); } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    });
  } catch (e) { body.innerHTML = errorState(e); }
}

function security(page) {
  const body = header(page, 'set.security', 'sec.lead');
  body.innerHTML = `
    <div class="sub-card"><h3>${esc(t('prof.changePassword'))}</h3>
      <div class="form-row"><label>${esc(t('sec.new'))}</label><input class="input" type="password" name="p1" autocomplete="new-password"></div>
      <div class="form-row"><label>${esc(t('sec.confirm'))}</label><input class="input" type="password" name="p2" autocomplete="new-password"></div>
      <div class="err" data-err hidden></div>
      <div style="display:flex;justify-content:flex-end"><button class="btn primary" data-save>${esc(t('prof.changePassword'))}</button></div></div>
    <div class="sub-card"><h3>${esc(t('sec.2fa'))}</h3><p class="desc">${esc(t('sec.2faLead'))}</p>${gatedNote(t('c.awaitingApproval'))}</div>`;
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
    const [b, zs] = await Promise.all([fetchBusiness(), fetchZones()]);
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
        <div class="err" data-aerr hidden></div>
        <div style="margin-top:12px">${gatedNote(t('bp.mapGated'))}</div></div>
      <div class="sub-card"><h3>${esc(t('bp.schedule'))} · ${esc(t('bp.description'))} · ${esc(t('bp.social'))}</h3>${gatedNote(t('bp.gatedFields'))}</div>`;
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
    body.querySelector('[data-area]').addEventListener('click', async e => {
      const aerr = body.querySelector('[data-aerr]');
      const lat = Number(body.querySelector('[name=lat]').value), lng = Number(body.querySelector('[name=lng]').value), r = Number(body.querySelector('[name=radius]').value);
      if (!Number.isFinite(lat) || !Number.isFinite(lng) || !(r > 0)) { aerr.textContent = t('c.required'); aerr.hidden = false; return; }
      aerr.hidden = true;
      try { await busy(e.currentTarget, () => api.rpc('set_business_service_area', { p_business_id: ctx.bid, p_origin_latitude: lat, p_origin_longitude: lng, p_radius_km: r })); toast(t('c.saved')); } catch (ex) { aerr.textContent = ex.message; aerr.hidden = false; }
    });
  } catch (e) { body.innerHTML = errorState(e); }
}

async function team(page) {
  const body = header(page, 'set.team', 'team.lead');
  const paint = async () => {
    try {
      const [members, invites] = await Promise.all([fetchMembers(), fetchTeamInvites()]);
      const pending = (invites || []).filter(i => ['pending', 'consented'].includes(i.status));
      body.innerHTML = `
        <div style="display:flex;justify-content:flex-end;margin-bottom:12px"><button class="btn cta" data-invite>${icon('plus')}${esc(t('team.invite'))}</button></div>
        <div class="sub-card">${(members || []).map(m => `<div class="list-row" style="cursor:default">${avatar(m.user_id === ctx.user.id ? (ctx.user.user_metadata?.full_name || ctx.user.email) : m.role)}
            <div class="grow"><b>${esc(m.user_id === ctx.user.id ? `${ctx.user.user_metadata?.full_name || ctx.user.email} (${t('team.you')})` : t('team.member'))}</b><small>${esc(t(`team.${m.role}`))}</small></div>${chip(m.status === 'active' ? 'active' : 'inactive', true)}</div>`).join('')}
          <div style="margin-top:10px">${gatedNote(t('team.memberNameGated'))}</div></div>
        <div class="sub-card"><div style="display:flex;align-items:center;gap:12px"><div style="flex:1"><h3>${esc(t('team.invitations'))}</h3><p class="desc" style="margin:0">${esc(t('team.invitationsLead'))}</p></div></div>
          ${pending.length ? pending.map(i => {
            const days = Math.max(0, Math.ceil((new Date(i.expires_at) - Date.now()) / 86400000));
            return `<div class="list-row" style="cursor:default">${avatar(i.invited_email)}<div class="grow"><b>${esc(i.invited_email)}</b></div>
              <span class="chip ${i.role === 'helper' ? 'neutral' : 'delivery'}">${esc(t(`team.${i.role}`))}</span>${chip('pending', true)}
              <div style="min-width:90px"><small>${esc(t('team.expiresIn'))}</small><b style="font-size:14px">${esc(t('team.days', { n: days }))}</b></div>
              <button class="btn sm" data-revoke="${esc(i.id)}">${esc(t('team.revoke'))}</button></div>`;
          }).join('') : `<div class="hint" style="padding:10px 0">${esc(t('c.none'))}</div>`}</div>`;
    } catch (e) { body.innerHTML = errorState(e); }
  };
  body.addEventListener('click', async e => {
    if (e.target.closest('[data-invite]')) return inviteMember(paint);
    const rv = e.target.closest('[data-revoke]');
    if (rv) {
      if (!await confirmDialog({ title: t('team.revoke'), confirmLabel: t('team.revoke'), danger: true })) return;
      try { await api.rpc('revoke_team_invitation', { p_invitation_id: rv.dataset.revoke }); toast(t('team.revoked')); paint(); } catch (ex) { toast(ex.message, 'error'); }
    }
  });
  paint();
}

function inviteMember(onDone) {
  let role = 'operator';
  const opt = (v, key, subKey) => `<button class="opt ${role === v ? 'on' : ''}" data-v="${v}"><div><b>${esc(t(key))}</b><small>${esc(t(subKey))}</small></div><span class="radio"></span></button>`;
  const m = modal({ title: t('team.invite'),
    body: `${opt('operator', 'team.operator', 'team.operatorSub')}${opt('helper', 'team.helper', 'team.helperSub')}
      <div class="field"><label>${esc(t('prof.email'))}</label><input class="input" name="email" type="email" placeholder="name@example.com"></div><div class="err" data-err hidden></div>`,
    footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit>${esc(t('riders.invite'))}</button>` });
  m.el.addEventListener('click', async e => {
    const o = e.target.closest('[data-v]');
    if (o) { role = o.dataset.v; m.el.querySelectorAll('[data-v]').forEach(b => b.classList.toggle('on', b === o)); return; }
    const sb = e.target.closest('[data-submit]');
    if (!sb) return;
    const email = m.el.querySelector('[name=email]').value.trim(), err = m.el.querySelector('[data-err]');
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { err.textContent = t('c.invalidEmail'); err.hidden = false; return; }
    try {
      const res = await busy(sb, () => api.rpc('create_team_invitation', { p_business_id: ctx.bid, p_role: role, p_invited_email: email }));
      m.close();
      showLink(t('team.linkReady'), new URL(`../invite/?type=team&token=${encodeURIComponent(res.token)}`, location.href).href);
      onDone();
    } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
}

function integrations(page) {
  const body = header(page, 'set.integrations', 'int.lead');
  body.innerHTML = `
    <div class="sub-card" style="display:flex;align-items:center;gap:16px">${`<span class="avatar">${icon('csv')}</span>`}
      <div style="flex:1"><h3>${esc(t('int.csv'))}</h3><p class="desc" style="margin:0">${esc(t('int.csvSub'))}</p></div>
      ${chip('active', true).replace(esc(t('st.active')), esc(t('int.available')))}
      <a class="btn soft" href="#/today">${esc(t('today.importOrders'))}</a></div>
    ${gatedNote(t('int.gated'))}`;
}

function staticPage(kind) {
  return page => {
    const map = { help: ['set.help', 'help.lead'], privacy: ['set.privacy', 'about.lead'], about: ['set.about', 'about.lead'] };
    const body = header(page, ...map[kind]);
    body.innerHTML = kind === 'help'
      ? gatedNote(t('help.gated'))
      : kind === 'privacy'
        ? `<div class="sub-card"><p class="desc" style="line-height:1.7">${esc(t('legal.privacy'))}</p></div>`
        : `<div class="sub-card"><h3>Cefflo Vendor</h3><p class="desc">${esc(t('about.lead'))}</p></div>
           <div class="sub-card"><h3>${esc(t('legal.termsTitle'))}</h3><p class="desc" style="line-height:1.7">${esc(t('legal.terms'))}</p></div>`;
  };
}
