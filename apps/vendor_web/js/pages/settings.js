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
  const pick = { ...prefs.notif };
  const row = (k, ic) => `<div class="toggle-row">${icon(ic)}<div class="grow"><b>${esc(t(`notif.${k}`))}</b><small>${esc(t(`notif.${k}Sub`))}</small></div>
    <button type="button" class="switch ${pick[k] ? 'on' : ''}" role="switch" aria-checked="${pick[k]}" aria-label="${esc(t(`notif.${k}`))}" data-k="${k}"></button></div>`;
  const m = modal({ title: t('notif.title'), lead: t('notif.lead'), center: true,
    body: `<div class="toggle-list">${row('orders', 'file')}${row('issues', 'alert')}${row('riders', 'users')}${row('runs', 'route')}</div>
      <div class="gated">${icon('info')}<div>${esc(t('notif.device'))}</div></div>`,
    footer: `<button class="btn primary" data-msave style="min-width:240px">${esc(t('c.save'))}</button>` });
  m.el.addEventListener('click', e => {
    const sw = e.target.closest('[data-k]');
    if (sw) { const k = sw.dataset.k; pick[k] = !pick[k]; sw.classList.toggle('on', pick[k]); sw.setAttribute('aria-checked', String(pick[k])); }
    if (e.target.closest('[data-msave]')) { savePrefs({ notif: pick }); m.close(); toast(t('c.saved')); }
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
  const row = (ic, name, sub, live, action = '') => `<div class="int-row"><span class="int-ico">${ic}</span>
    <div class="grow"><b>${esc(name)}</b><small>${esc(sub)}</small></div>
    ${live ? chip('active', true).replace(esc(t('st.active')), esc(t('int.available'))) : `<span class="chip neutral"><i class="dot"></i>${esc(t('int.planned'))}</span>`}${action}</div>`;
  body.innerHTML = `<div class="sub-card int-list">
      ${row(icon('csv'), t('int.csv'), t('int.csvSub'), true, `<a class="btn soft sm" href="#/today">${esc(t('today.importOrders'))}</a>`)}
      ${row(icon('file'), t('int.manual'), t('int.manualSub'), true, `<a class="btn soft sm" href="#/orders">${esc(t('today.addOrder'))}</a>`)}
      ${row(icon('store'), 'Shopify', t('int.shopSub'), false)}
      ${row(icon('store'), 'WooCommerce', t('int.shopSub'), false)}
      ${row(icon('store'), 'Wix eCommerce', t('int.shopSub'), false)}
      ${row(icon('csv'), 'Google Sheets', t('int.sheetsSub'), false)}
      ${row(icon('link'), 'API / Webhooks', t('int.apiSub'), false)}
    </div>
    <div class="sub-card"><h3>${esc(t('int.how'))}</h3>
      <div class="steps4">${['int.s1', 'int.s2', 'int.s3', 'int.s4'].map((k, i) => `<div><span class="n">${i + 1}</span><b>${esc(t(k))}</b><small>${esc(t(`${k}Sub`))}</small></div>`).join('')}</div></div>`;
}

function staticPage(kind) {
  return page => {
    const map = { help: ['set.help', 'help.lead'], privacy: ['set.privacy', 'priv.lead'], about: ['set.about', 'about.lead'] };
    const body = header(page, ...map[kind]);
    if (kind === 'help') {
      body.innerHTML = `<div class="sub-card"><h3>${esc(t('help.faq'))}</h3><div class="faq">
          ${[1, 2, 3, 4, 5, 6].map(n => `<details><summary>${esc(t(`help.q${n}`))}${icon('down')}</summary><p>${esc(t(`help.a${n}`))}</p></details>`).join('')}</div></div>
        <div class="sub-card row-card">${`<span class="int-ico">${icon('mail')}</span>`}<div class="grow"><h3>${esc(t('help.contact'))}</h3>
          <p class="desc" style="margin:0">${esc(t('help.contactLead'))} <b class="sel">support@cefflo.com</b></p></div>
          <a class="btn soft" href="mailto:support@cefflo.com">${icon('mail')}${esc(t('help.email'))}</a></div>`;
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
