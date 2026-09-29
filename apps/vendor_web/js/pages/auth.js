// Sign in / forgot password (Supabase Auth). No Founder web reference for
// these screens yet, so they use the shared components only.
import { t } from '../i18n.js';
import { api } from '../api.js';
import { esc, busy } from '../ui.js';
import { demoAllowed, enterDemo } from '../demo.js';

export function renderSignIn(root, { onSignedIn, message = '' }) {
  root.innerHTML = `<div class="auth"><form class="auth-card" data-form novalidate>
    <div class="auth-brand">Cefflo <span style="color:var(--muted);font-weight:600;font-size:15px;letter-spacing:3px">VENDOR</span></div>
    <h1>${esc(t('auth.welcome'))}</h1><p>${esc(t('auth.lead'))}</p>
    ${message ? `<div class="gated">${esc(message)}</div>` : ''}
    <div class="field"><label for="em">${esc(t('auth.email'))}</label><input class="input" id="em" type="email" autocomplete="username" required></div>
    <div class="field"><label for="pw">${esc(t('auth.password'))}</label><input class="input" id="pw" type="password" autocomplete="current-password" required></div>
    <div class="err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">${esc(t('auth.signIn'))}</button>
    <button class="link-btn" type="button" data-forgot style="justify-self:center">${esc(t('auth.forgot'))}</button>
    ${demoAllowed() ? `<div class="demo-entry"><span>${esc(t('demo.or'))}</span><button class="btn" type="button" data-demo style="width:100%">${esc(t('demo.enter'))}</button><small>${esc(t('demo.entryHint'))}</small></div>` : ''}
  </form></div>`;
  const form = root.querySelector('[data-form]'), err = root.querySelector('[data-err]');
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
  root.querySelector('[data-forgot]').addEventListener('click', () => renderForgot(root, { onSignedIn }));
  root.querySelector('[data-demo]')?.addEventListener('click', () => { enterDemo(); onSignedIn(); });
}

function renderForgot(root, opts) {
  root.innerHTML = `<div class="auth"><form class="auth-card" data-form novalidate>
    <div class="auth-brand">Cefflo</div><h1>${esc(t('auth.forgot'))}</h1><p>${esc(t('auth.resetLead'))}</p>
    <div class="field"><label for="em">${esc(t('auth.email'))}</label><input class="input" id="em" type="email" autocomplete="username"></div>
    <div class="err" data-err hidden role="alert"></div><div class="gated" data-ok hidden></div>
    <button class="btn primary" type="submit" style="width:100%">${esc(t('auth.sendReset'))}</button>
    <button class="link-btn" type="button" data-back style="justify-self:center">${esc(t('auth.backToSignIn'))}</button></form></div>`;
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
  root.querySelector('[data-back]').addEventListener('click', () => renderSignIn(root, opts));
}

// After a recovery link: set a new password before entering the app.
export function renderSetPassword(root, { onDone }) {
  root.innerHTML = `<div class="auth"><form class="auth-card" data-form novalidate>
    <div class="auth-brand">Cefflo</div><h1>${esc(t('prof.changePassword'))}</h1>
    <div class="field"><label for="p1">${esc(t('sec.new'))}</label><input class="input" id="p1" type="password" autocomplete="new-password"></div>
    <div class="field"><label for="p2">${esc(t('sec.confirm'))}</label><input class="input" id="p2" type="password" autocomplete="new-password"></div>
    <div class="err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">${esc(t('c.save'))}</button></form></div>`;
  const form = root.querySelector('[data-form]'), err = root.querySelector('[data-err]');
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const p1 = root.querySelector('#p1').value, p2 = root.querySelector('#p2').value;
    if (p1.length < 8) { err.textContent = t('sec.short'); err.hidden = false; return; }
    if (p1 !== p2) { err.textContent = t('sec.mismatch'); err.hidden = false; return; }
    try { await busy(form.querySelector('[type=submit]'), () => api.updateUser({ password: p1 })); onDone(); } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
}
