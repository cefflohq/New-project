// Permanent invite link + QR (Security & Access Master Part III §9-11):
// Link/QR → Sign in → Join request → Pending → Owner approval → Active.
// One link per business and role from get_invite_link; the server decides who
// may manage it. Opening a link never grants access by itself.
import { t } from './i18n.js';
import { api } from './api.js';
import { ctx } from './store.js';
import { esc, modal, toast, copyText } from './ui.js';
import qrcode from './lib/qrcode.js';

function qrSvg(text) {
  const code = qrcode(0, 'M');
  code.addData(text);
  code.make();
  return code.createSvgTag({ cellSize: 5, margin: 2, scalable: true });
}

// The Team Invite gateway from runtime config (production
// https://invite.cefflo.com/); staging/local fall back to the bundled /invite/.
const linkFor = token => {
  const base = (window.CEFFLO_CONFIG || {}).inviteBaseUrl;
  return new URL(`?link=${encodeURIComponent(token)}`, base || new URL('../invite/', location.href)).href;
};

// kind: 'rider' | 'team' (team lets the Owner choose Operator or Helper).
export function showInviteLink(kind, initialRole = 'operator') {
  // M2: an Operator invites Helpers only (Operator links are Owner-only).
  let role = kind === 'rider' ? 'rider' : (ctx.isOwner ? initialRole : 'helper');
  const roleOpt = (v, key, subKey) => `<button class="opt ${role === v ? 'on' : ''}" data-v="${v}"><div><b>${esc(t(key))}</b><small>${esc(t(subKey))}</small></div><span class="radio"></span></button>`;
  const m = modal({
    title: t(kind === 'rider' ? 'invite.riderTitle' : 'invite.teamTitle'),
    lead: t('invite.lead'),
    body: `${kind === 'rider' ? '' : (ctx.isOwner ? roleOpt('operator', 'team.operator', 'team.operatorSub') : '') + roleOpt('helper', 'team.helper', 'team.helperSub')}
      <div class="invite-qr" data-qr style="display:grid;place-items:center;min-height:200px"><i class="spin"></i></div>
      <div class="field"><label>${esc(t('invite.linkLabel'))}</label><input class="input" readonly data-link></div>
      <p class="desc" style="margin:4px 0 0">${esc(t('invite.pendingNote'))}</p>
      <div class="err" data-err hidden></div>`,
    footer: `<button class="btn" data-close>${esc(t('c.close'))}</button>
      ${navigator.share ? `<button class="btn" data-share disabled>${esc(t('invite.share'))}</button>` : ''}
      <button class="btn primary" data-copy disabled>${esc(t('riders.copy'))}</button>`,
  });
  let current = '';
  const load = async () => {
    const qr = m.el.querySelector('[data-qr]'), input = m.el.querySelector('[data-link]'), err = m.el.querySelector('[data-err]');
    m.el.querySelectorAll('[data-copy],[data-share]').forEach(b => { b.disabled = true; });
    qr.innerHTML = '<i class="spin"></i>'; input.value = ''; err.hidden = true;
    try {
      const res = await api.rpc('get_invite_link', { p_business_id: ctx.bid, p_kind: role });
      const token = (Array.isArray(res) ? res[0] : res)?.token;
      if (!token) throw new Error(t('invite.unavailable'));
      current = linkFor(token);
      input.value = current;
      qr.innerHTML = `<div style="width:200px;height:200px">${qrSvg(current)}</div>`;
      m.el.querySelectorAll('[data-copy],[data-share]').forEach(b => { b.disabled = false; });
    } catch (ex) {
      qr.innerHTML = '';
      err.textContent = ex.message; err.hidden = false;
    }
  };
  m.el.addEventListener('click', async e => {
    const o = e.target.closest('[data-v]');
    if (o && o.dataset.v !== role) {
      role = o.dataset.v;
      m.el.querySelectorAll('[data-v]').forEach(b => b.classList.toggle('on', b === o));
      load();
      return;
    }
    if (e.target.closest('[data-copy]') && current) {
      const ok = await copyText(current);
      if (!ok) m.el.querySelector('[data-link]').select();
      toast(ok ? t('riders.copied') : current);
      return;
    }
    if (e.target.closest('[data-share]') && current) {
      try { await navigator.share({ title: t('invite.shareTitle'), url: current }); } catch { /* dismissed */ }
    }
  });
  load();
}
