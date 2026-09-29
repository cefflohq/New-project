// Sign in / forgot password (Supabase Auth). No Founder web reference for
// these screens yet, so they use the shared components only.
import { t } from '../i18n.js';
import { api } from '../api.js';
import { esc, busy, icon } from '../ui.js';
import { demoAllowed, enterDemo } from '../demo.js';
import { prefs, savePrefs } from '../prefs.js';

// Branded frame shared by every auth screen, matching Cefflo Vendor mobile
// sign-in: the sky-to-navy brand backdrop, the Cefflo lockup, the spaced
// VENDOR label, a language menu top left and the actions at the bottom.
function frame(root, bottom, rerender) {
  root.innerHTML = `<div class="auth">
    <div class="auth-top">
      <div class="auth-lang">
        <button type="button" class="auth-lang-btn" data-langmenu aria-haspopup="menu" aria-expanded="false">${icon('globe')}<span>${prefs.lang === 'ms' ? 'Bahasa Melayu' : 'English'}</span>${icon('down')}</button>
        <div class="auth-lang-menu" role="menu" hidden>
          <button type="button" role="menuitemradio" aria-checked="${prefs.lang === 'en'}" data-lang="en">English</button>
          <button type="button" role="menuitemradio" aria-checked="${prefs.lang === 'ms'}" data-lang="ms">Bahasa Melayu</button>
        </div>
      </div>
    </div>
    <div class="auth-hero">
      <img class="auth-logo" src="img/cefflo-logo.png" alt="Cefflo" width="150" height="234">
      <span class="auth-product">VENDOR</span>
    </div>
    <div class="auth-bottom">${bottom}</div>
  </div>`;
  const btn = root.querySelector('[data-langmenu]'), menu = root.querySelector('.auth-lang-menu');
  btn.addEventListener('click', () => { menu.hidden = !menu.hidden; btn.setAttribute('aria-expanded', String(!menu.hidden)); });
  root.querySelectorAll('[data-lang]').forEach(b => b.addEventListener('click', () => {
    menu.hidden = true;
    if (prefs.lang !== b.dataset.lang) { savePrefs({ lang: b.dataset.lang }); rerender(); }
  }));
}

export function renderSignIn(root, { onSignedIn, message = '' }, mode = 'choose') {
  const again = next => renderSignIn(root, { onSignedIn, message }, next);
  if (mode === 'choose') {
    frame(root, `
      ${message ? `<div class="auth-note" role="status">${esc(message)}</div>` : ''}
      <button class="auth-pill" type="button" data-email>${icon('mail')}<span>${esc(t('auth.withEmail'))}</span></button>
      ${demoAllowed() ? `<button class="auth-pill ghost" type="button" data-demo>${icon('store')}<span>${esc(t('demo.enter'))}</span></button>
      <small class="auth-hint">${esc(t('demo.entryHint'))}</small>` : ''}
      <p class="auth-invite">${esc(t('auth.haveInvite'))} <button type="button" class="auth-link" data-invite>${esc(t('auth.getStarted'))}</button></p>
      <p class="auth-invite-note" data-invite-note hidden>${esc(t('auth.inviteNote'))}</p>`, () => again('choose'));
    root.querySelector('[data-email]').addEventListener('click', () => again('email'));
    root.querySelector('[data-demo]')?.addEventListener('click', () => { enterDemo(); onSignedIn(); });
    root.querySelector('[data-invite]').addEventListener('click', () => { root.querySelector('[data-invite-note]').hidden = false; });
    return;
  }
  frame(root, `<form class="auth-card" data-form novalidate>
    <h1>${esc(t('auth.welcome'))}</h1><p>${esc(t('auth.lead'))}</p>
    ${message ? `<div class="gated">${esc(message)}</div>` : ''}
    <div class="field"><label for="em">${esc(t('auth.email'))}</label><input class="input" id="em" type="email" autocomplete="username" required></div>
    <div class="field"><label for="pw">${esc(t('auth.password'))}</label><input class="input" id="pw" type="password" autocomplete="current-password" required></div>
    <div class="err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">${esc(t('auth.signIn'))}</button>
    <div class="auth-card-links"><button class="link-btn" type="button" data-back>${esc(t('c.back'))}</button><button class="link-btn" type="button" data-forgot>${esc(t('auth.forgot'))}</button></div>
  </form>`, () => again('email'));
  const form = root.querySelector('[data-form]'), err = root.querySelector('[data-err]');
  root.querySelector('#em').focus();
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const email = root.querySelector('#em').value.trim(), pw = root.querySelector('#pw').value;
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { err.textContent = t('c.invalidEmail'); err.hidden = false; return; }
    if (!pw) { err.textContent = t('c.required'); err.hidden = false; return; }
    err.hidden = true;
    try {
      await busy(form.querySelector('[type=submit]'), () => api.signIn(email, pw));
      onSignedIn();
    } catch (ex) {
      err.textContent = /invalid/i.test(ex.message) ? t('auth.bad') : ex.message;
      err.hidden = false;
    }
  });
  root.querySelector('[data-back]').addEventListener('click', () => again('choose'));
  root.querySelector('[data-forgot]').addEventListener('click', () => renderForgot(root, { onSignedIn }));
}

function renderForgot(root, opts) {
  frame(root, `<form class="auth-card" data-form novalidate>
    <h1>${esc(t('auth.forgot'))}</h1><p>${esc(t('auth.resetLead'))}</p>
    <div class="field"><label for="em">${esc(t('auth.email'))}</label><input class="input" id="em" type="email" autocomplete="username"></div>
    <div class="err" data-err hidden role="alert"></div><div class="gated" data-ok hidden></div>
    <button class="btn primary" type="submit" style="width:100%">${esc(t('auth.sendReset'))}</button>
    <button class="link-btn" type="button" data-back style="justify-self:center">${esc(t('auth.backToSignIn'))}</button></form>`, () => renderForgot(root, opts));
  const form = root.querySelector('[data-form]'), err = root.querySelector('[data-err]');
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const email = root.querySelector('#em').value.trim();
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { err.textContent = t('c.invalidEmail'); err.hidden = false; return; }
    err.hidden = true;
    try {
      await busy(form.querySelector('[type=submit]'), () => api.recover(email));
      const ok = root.querySelector('[data-ok]'); ok.textContent = t('auth.resetSent'); ok.hidden = false;
    } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
  root.querySelector('[data-back]').addEventListener('click', () => renderSignIn(root, opts, 'email'));
}

// After a recovery link: set a new password before entering the app.
export function renderSetPassword(root, { onDone }) {
  frame(root, `<form class="auth-card" data-form novalidate>
    <h1>${esc(t('prof.changePassword'))}</h1>
    <div class="field"><label for="p1">${esc(t('sec.new'))}</label><input class="input" id="p1" type="password" autocomplete="new-password"></div>
    <div class="field"><label for="p2">${esc(t('sec.confirm'))}</label><input class="input" id="p2" type="password" autocomplete="new-password"></div>
    <div class="err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">${esc(t('c.save'))}</button></form>`, () => renderSetPassword(root, { onDone }));
  const form = root.querySelector('[data-form]'), err = root.querySelector('[data-err]');
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const p1 = root.querySelector('#p1').value, p2 = root.querySelector('#p2').value;
    if (p1.length < 8) { err.textContent = t('sec.short'); err.hidden = false; return; }
    if (p1 !== p2) { err.textContent = t('sec.mismatch'); err.hidden = false; return; }
    try { await busy(form.querySelector('[type=submit]'), () => api.updateUser({ password: p1 })); onDone(); } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
}
