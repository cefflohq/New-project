// Vendor Web Business Setup — OWNER onboarding only (Founder approval,
// 2026-09-29). Two steps, then the existing canonical `bootstrap_business`
// (no new RPC, no direct inserts, no backend change).
//
//   Step 1  Your Business    name (required, <=120), contact phone (required),
//                            account email (read-only)
//   Step 2  Pickup Location  street (required), postcode (optional, MY 5
//                            digits), city (optional)
//   Create  bootstrap_business(name, phone, email, "street, postcode city")
//           -- the same address shape Vendor Mobile sends; timezone/currency
//           use the backend defaults. Then the session/business state is
//           reloaded. Business Ready appears only after both succeeded.
//
// Never retries bootstrap_business: if creation succeeded but the reload
// failed, recovery only reloads. The unfinished draft lives on this device
// (keyed by user) and is cleared the moment the server has created the
// business, so it can never create a second one. Service Area is optional,
// offered after setup.
import { t } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { esc, icon } from '../ui.js';

const PHONE = /^\+?[0-9][0-9\s-]{5,19}$/;
const draftKey = () => `cefflo.vendorweb.setupDraft.${ctx.user?.id || 'anon'}`;
function readDraft() {
  try { return JSON.parse(localStorage.getItem(draftKey()) || 'null') || {}; } catch { return {}; }
}
function writeDraft(d) {
  try { localStorage.setItem(draftKey(), JSON.stringify(d)); } catch { /* private mode */ }
}
export function clearSetupDraft() {
  try { localStorage.removeItem(draftKey()); } catch { /* ignore */ }
}

const digits = s => String(s || '').replace(/\D/g, '');
export function validateStep1(d) {
  const e = {};
  const name = String(d.name || '').trim();
  if (!name) e.name = t('c.required');
  else if (name.length > 120) e.name = t('setup.nameTooLong');
  const phone = String(d.phone || '').trim();
  if (!phone) e.phone = t('c.required');
  else if (!PHONE.test(phone) || digits(phone).length < 7 || digits(phone).length > 15) e.phone = t('c.invalidPhone');
  return e;
}
export function validateStep2(d) {
  const e = {};
  if (!String(d.street || '').trim()) e.street = t('c.required');
  const pc = String(d.postcode || '').trim();
  if (pc && !/^\d{5}$/.test(pc)) e.postcode = t('setup.postcodeInvalid');
  return e;
}
export const composeAddress = d => [String(d.street || '').trim(),
  [String(d.postcode || '').trim(), String(d.city || '').trim()].filter(Boolean).join(' ')].filter(Boolean).join(', ');

/**
 * @param root     container
 * @param opts.reload   () => Promise  reloads the session/business context
 * @param opts.onReady  (action) => void  enter the app (today|area|rider|order)
 * @param opts.onSignOut () => void
 * @param opts.onExpired () => void   session expired: sign in again (draft kept)
 */
export function renderBusinessSetup(root, opts) {
  const d = { name: '', phone: '', street: '', postcode: '', city: '', ...readDraft() };
  let step = d.step === 2 ? 2 : 1;
  let created = false; // bootstrap_business already succeeded in this visit

  function frame(inner) {
    root.innerHTML = `<div class="onb">
      <aside class="onb-side">
        <img class="onb-logo" src="img/cefflo-logo.png" alt="Cefflo" width="72" height="112">
        <div><span class="onb-kicker">VENDOR</span><h1>${esc(t('setup.sideTitle'))}</h1><p>${esc(t('setup.sideLead'))}</p></div>
        <ol class="onb-steps">
          ${[[1, 'setup.step1'], [2, 'setup.step2']].map(([n, key]) => `<li class="${step === n && !created ? 'on' : ''} ${step > n || created ? 'done' : ''}">
            <span class="onb-num">${step > n || created ? icon('check') : n}</span><span>${esc(t(key))}</span></li>`).join('')}
        </ol>
        <button class="onb-signout" type="button" data-signout>${icon('logout')}${esc(t('shell.signOut'))}</button>
      </aside>
      <main class="onb-main"><div class="onb-card card">${inner}</div></main>
    </div>`;
    root.querySelector('[data-signout]').addEventListener('click', () => opts.onSignOut());
  }
  const field = (name, label, attrs = '', hint = '') => `<div class="field"><label for="f-${name}">${esc(label)}</label>
    <input class="input" id="f-${name}" name="${name}" value="${esc(d[name] || '')}" ${attrs}>${hint ? `<span class="hint">${esc(hint)}</span>` : ''}<span class="err" data-err="${name}" hidden></span></div>`;
  const showErrors = errs => {
    root.querySelectorAll('[data-err]').forEach(el => {
      const m = errs[el.dataset.err];
      el.hidden = !m; el.textContent = m || '';
      root.querySelector(`[name=${el.dataset.err}]`)?.classList.toggle('invalid', !!m);
    });
    const first = Object.keys(errs)[0];
    if (first) root.querySelector(`[name=${first}]`)?.focus();
  };
  const bind = () => root.querySelectorAll('input[name]').forEach(i => i.addEventListener('input', () => {
    d[i.name] = i.value; writeDraft({ ...d, step });
  }));

  function step1() {
    step = 1; writeDraft({ ...d, step });
    frame(`<form data-form novalidate>
      <span class="onb-count">${esc(t('setup.stepOf', { n: 1 }))}</span>
      <h2>${esc(t('setup.step1'))}</h2><p class="onb-lead">${esc(t('setup.step1Lead'))}</p>
      ${field('name', t('bp.name'), 'maxlength="120" autocomplete="organization" required')}
      ${field('phone', t('setup.contactPhone'), 'inputmode="tel" autocomplete="tel" placeholder="+60 12-345 6789" required')}
      <div class="field"><label for="f-email">${esc(t('prof.email'))}</label><input class="input" id="f-email" value="${esc(ctx.user?.email || '')}" readonly disabled>
        <span class="hint">${esc(t('setup.emailHint'))}</span></div>
      <div class="onb-actions"><button class="btn primary" type="submit">${esc(t('setup.continue'))}${icon('right')}</button></div>
    </form>`);
    bind();
    root.querySelector('[data-form]').addEventListener('submit', e => {
      e.preventDefault();
      const errs = validateStep1(d);
      showErrors(errs);
      if (Object.keys(errs).length) return;
      d.name = d.name.trim(); d.phone = d.phone.trim();
      step2();
    });
    root.querySelector('[name=name]').focus();
  }

  function step2() {
    step = 2; writeDraft({ ...d, step });
    frame(`<form data-form novalidate>
      <span class="onb-count">${esc(t('setup.stepOf', { n: 2 }))}</span>
      <h2>${esc(t('setup.step2'))}</h2><p class="onb-lead">${esc(t('setup.step2Lead'))}</p>
      ${field('street', t('setup.street'), 'autocomplete="street-address" required')}
      <div class="onb-row">${field('postcode', t('setup.postcode'), 'inputmode="numeric" maxlength="5" autocomplete="postal-code"', t('c.optional'))}
        ${field('city', t('setup.city'), 'autocomplete="address-level2"', t('c.optional'))}</div>
      <div class="err" data-submit-err hidden role="alert"></div>
      <div class="onb-actions"><button class="btn" type="button" data-back>${icon('left')}${esc(t('c.back'))}</button>
        <button class="btn primary" type="submit" data-create>${esc(t('setup.create'))}</button></div>
    </form>`);
    bind();
    root.querySelector('[data-back]').addEventListener('click', () => step1());
    root.querySelector('[data-form]').addEventListener('submit', e => { e.preventDefault(); create(); });
    root.querySelector('[name=street]').focus();
  }

  let inFlight = false;
  async function create() {
    if (inFlight || created) return; // no duplicate submission
    const errs = validateStep2(d);
    showErrors(errs);
    if (Object.keys(errs).length) return;
    const e1 = validateStep1(d);
    if (Object.keys(e1).length) { step1(); showErrors(e1); return; }
    const btn = root.querySelector('[data-create]'), back = root.querySelector('[data-back]');
    const errBox = root.querySelector('[data-submit-err]');
    inFlight = true;
    btn.disabled = true; back.disabled = true;
    btn.innerHTML = `<i class="spin"></i>${esc(t('setup.creating'))}`;
    errBox.hidden = true;
    try {
      await api.rpc('bootstrap_business', {
        p_name: d.name.trim(), p_phone: d.phone.trim(), p_email: ctx.user?.email || null, p_address: composeAddress(d),
      });
    } catch (ex) {
      inFlight = false;
      btn.disabled = false; back.disabled = false;
      btn.textContent = t('setup.create');
      if (ex.status === 401 || /JWT|session expired/i.test(ex.message)) { opts.onExpired(); return; }
      errBox.textContent = ex.message || t('c.errorBody');
      errBox.hidden = false;
      return;
    }
    // The server created the business: from here on we never call
    // bootstrap_business again, and the draft must not survive.
    created = true;
    clearSetupDraft();
    await reloadAfterCreate();
  }

  async function reloadAfterCreate() {
    frame(`<div class="onb-center" aria-busy="true"><div class="onb-status">${icon('check')}</div>
      <h2>${esc(t('setup.finishing'))}</h2><p class="onb-lead">${esc(t('setup.finishingLead'))}</p>
      <div class="skel" style="height:10px;width:60%"></div></div>`);
    try {
      await opts.reload();
      ready();
    } catch (ex) {
      frame(`<div class="onb-center" role="alert"><div class="onb-status warn">${icon('alert')}</div>
        <h2>${esc(t('setup.reloadFailed'))}</h2><p class="onb-lead">${esc(t('setup.reloadFailedLead'))}</p>
        <div class="hint">${esc(ex.message || '')}</div>
        <div class="onb-actions center"><button class="btn primary" type="button" data-reload>${esc(t('c.retry'))}</button></div></div>`);
      root.querySelector('[data-reload]').addEventListener('click', () => reloadAfterCreate());
    }
  }

  function ready() {
    const name = ctx.business?.business_name || d.name;
    frame(`<div class="onb-center">
      <div class="onb-status ok">${icon('check')}</div>
      <span class="onb-count">${esc(t('setup.readyKicker'))}</span>
      <h2>${esc(t('setup.readyTitle'))}</h2><p class="onb-lead">${esc(t('setup.readyLead', { name }))}</p>
      <button class="btn primary onb-go" type="button" data-go="today">${esc(t('setup.goToday'))}${icon('right')}</button>
      <div class="onb-next"><span>${esc(t('setup.nextSteps'))}</span>
        <button type="button" data-go="area">${icon('pin')}<span><b>${esc(t('setup.setArea'))}</b><small>${esc(t('setup.setAreaSub'))}</small></span>${icon('right')}</button>
        <button type="button" data-go="rider">${icon('users')}<span><b>${esc(t('today.addRider'))}</b><small>${esc(t('setup.addRiderSub'))}</small></span>${icon('right')}</button>
        <button type="button" data-go="order">${icon('plus')}<span><b>${esc(t('setup.firstOrder'))}</b><small>${esc(t('setup.firstOrderSub'))}</small></span>${icon('right')}</button>
      </div></div>`);
    root.querySelectorAll('[data-go]').forEach(b => b.addEventListener('click', () => opts.onReady(b.dataset.go)));
    root.querySelector('[data-go="today"]').focus();
  }

  if (step === 2) step2(); else step1();
}
