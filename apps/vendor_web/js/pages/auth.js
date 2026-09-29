// Vendor Web auth suite (Supabase Auth), mirroring Vendor Mobile: Sign In
// (Vendor or Operator presentation), Email Sign In, Create Account, Verify
// your email, Verification link expired, Forgot Password, Check your email,
// Set New Password, and the Operator no-access state. Every action is a real
// GoTrue call; nothing here decides a role -- the server does, after sign-in.
import { t } from '../i18n.js';
import { api } from '../api.js';
import { esc, busy, icon } from '../ui.js';
import { demoAllowed, enterDemo } from '../demo.js';
import { prefs, savePrefs } from '../prefs.js';
import { operatorEntry } from '../access.js';

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

// Branded frame shared by every auth screen, matching Cefflo Vendor mobile
// sign-in: the brand backdrop, the Cefflo lockup, the spaced VENDOR label,
// a language menu at the top and the actions below the hero.
function frame(root, bottom, rerender, { hero = '', langRight = false } = {}) {
  root.innerHTML = `<div class="auth">
    <div class="auth-top${langRight ? ' right' : ''}">
      <div class="auth-lang">
        <button type="button" class="auth-lang-btn" data-langmenu aria-haspopup="menu" aria-expanded="false">${icon('globe')}<span>${prefs.lang === 'ms' ? 'Bahasa Melayu' : 'English'}</span>${icon('down')}</button>
        <div class="auth-lang-menu" role="menu" hidden>
          <button type="button" role="menuitemradio" aria-checked="${prefs.lang === 'en'}" data-lang="en">English</button>
          <button type="button" role="menuitemradio" aria-checked="${prefs.lang === 'ms'}" data-lang="ms">Bahasa Melayu</button>
        </div>
      </div>
    </div>
    <div class="auth-hero${hero ? ' op' : ''}">
      <img class="auth-logo" src="img/cefflo-logo.png" alt="Cefflo" width="150" height="234">
      <span class="auth-product">VENDOR</span>
      ${hero}
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

const status = ic => `<div class="auth-status">${icon(ic)}</div>`;
const showErr = (el, text) => { el.textContent = text; el.hidden = false; };
const notConfirmed = e => /not confirmed/i.test(e?.message || '') || e?.code === 'email_not_confirmed';
const expired = e => /expired|invalid/i.test(`${e?.message || ''} ${e?.code || ''}`);

export function renderSignIn(root, opts, mode = 'choose') {
  const { onSignedIn, message = '' } = opts;
  const again = next => renderSignIn(root, opts, next);
  if (mode === 'choose') {
    const op = operatorEntry();
    // Operator Sign-In (D-74): the same providers and flow with the Operator
    // Access context. Presentation only -- it never sets the role.
    const hero = op ? `<span class="auth-chip">${icon('users')}${esc(t('auth.opAccess'))}</span>
      <h1 class="auth-title">${esc(t('auth.opWelcome'))}</h1><p class="auth-lead">${esc(t('auth.opLead'))}</p>` : '';
    frame(root, `
      ${message ? `<div class="auth-note" role="status">${esc(message)}</div>` : ''}
      <button class="auth-pill" type="button" data-email>${icon('mail')}<span>${esc(t('auth.withEmail'))}</span></button>
      ${demoAllowed() ? `<button class="auth-pill ghost" type="button" data-demo>${icon('store')}<span>${esc(t('demo.enter'))}</span></button>
      <small class="auth-hint">${esc(t('demo.entryHint'))}</small>` : ''}
      <p class="auth-invite">${esc(t('auth.haveInvite'))} <button type="button" class="auth-link" data-invite>${esc(t('auth.getStarted'))}</button></p>`,
    () => again('choose'), { hero, langRight: op });
    root.querySelector('[data-email]').addEventListener('click', () => again('email'));
    root.querySelector('[data-demo]')?.addEventListener('click', () => { enterDemo(); onSignedIn(); });
    root.querySelector('[data-invite]').addEventListener('click', () => renderSignUp(root, opts));
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
    <p class="auth-foot">${esc(t('auth.noAccount'))} <button class="link-btn" type="button" data-signup>${esc(t('auth.signUp'))}</button></p>
  </form>`, () => again('email'));
  const form = root.querySelector('[data-form]'), err = root.querySelector('[data-err]');
  root.querySelector('#em').focus();
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const email = root.querySelector('#em').value.trim(), pw = root.querySelector('#pw').value;
    if (!EMAIL.test(email)) return showErr(err, t('c.invalidEmail'));
    if (!pw) return showErr(err, t('c.required'));
    err.hidden = true;
    try {
      await busy(form.querySelector('[type=submit]'), () => api.signIn(email, pw), t('c.loading'));
      onSignedIn();
    } catch (ex) {
      // An account that never confirmed its email goes to Verify your email.
      if (notConfirmed(ex)) return renderVerify(root, opts, email);
      showErr(err, /invalid/i.test(ex.message) ? t('auth.bad') : ex.message);
    }
  });
  root.querySelector('[data-back]').addEventListener('click', () => again('choose'));
  root.querySelector('[data-forgot]').addEventListener('click', () => renderForgot(root, opts));
  root.querySelector('[data-signup]').addEventListener('click', () => renderSignUp(root, opts));
}

// Create Account. Whether GoTrue returns a session (confirmation off) or
// not (confirmation required) is backend truth that picks the next step.
function renderSignUp(root, opts) {
  frame(root, `<form class="auth-card" data-form novalidate>
    <h1>${esc(t('auth.createTitle'))}</h1><p>${esc(t('auth.createLead'))}</p>
    <div class="field"><label for="em">${esc(t('auth.email'))}</label><input class="input" id="em" type="email" autocomplete="email"></div>
    <div class="field"><label for="p1">${esc(t('auth.password'))}</label><input class="input" id="p1" type="password" autocomplete="new-password"><small class="hint">${esc(t('auth.pwRule'))}</small></div>
    <div class="field"><label for="p2">${esc(t('auth.confirmPw'))}</label><input class="input" id="p2" type="password" autocomplete="new-password"></div>
    <div class="err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">${esc(t('auth.create'))}</button>
    <div class="auth-card-links"><button class="link-btn" type="button" data-back>${esc(t('c.back'))}</button></div>
    <p class="auth-foot">${esc(t('auth.haveAccount'))} <button class="link-btn" type="button" data-signin>${esc(t('auth.signIn'))}</button></p>
  </form>`, () => renderSignUp(root, opts));
  const form = root.querySelector('[data-form]'), err = root.querySelector('[data-err]');
  root.querySelector('#em').focus();
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const email = root.querySelector('#em').value.trim(), p1 = root.querySelector('#p1').value, p2 = root.querySelector('#p2').value;
    if (!EMAIL.test(email)) return showErr(err, t('c.invalidEmail'));
    if (p1.length < 8) return showErr(err, t('sec.short'));
    if (p1 !== p2) return showErr(err, t('sec.mismatch'));
    err.hidden = true;
    try {
      const needsVerification = await busy(form.querySelector('[type=submit]'), () => api.signUp(email, p1), t('c.loading'));
      if (needsVerification) renderVerify(root, opts, email);
      else opts.onSignedIn();
    } catch (ex) { showErr(err, ex.message); }
  });
  root.querySelector('[data-back]').addEventListener('click', () => renderSignIn(root, opts, 'choose'));
  root.querySelector('[data-signin]').addEventListener('click', () => renderSignIn(root, opts, 'email'));
}

// Resend a sign-up verification email, shared by Verify and Link expired.
async function resend(btn, email, notice, err, onExpired) {
  err.hidden = true; notice.hidden = true;
  try {
    await busy(btn, () => api.resendSignUp(email), t('auth.sending'));
    notice.textContent = t('auth.resent', { email }); notice.hidden = false;
  } catch (ex) {
    if (onExpired && expired(ex)) return onExpired();
    showErr(err, ex.message);
  }
}

// Verify your email: the account exists but its address is unconfirmed.
function renderVerify(root, opts, email) {
  frame(root, `<div class="auth-card auth-center">
    ${status('mail')}
    <h1>${esc(t('auth.verifyTitle'))}</h1><p>${esc(t('auth.verifyBody'))}</p>
    <p class="auth-email">${esc(email)}</p>
    <p class="auth-muted">${esc(t('auth.spam'))}</p>
    <div class="gated" data-ok hidden role="status"></div><div class="err" data-err hidden role="alert"></div>
    <button class="btn primary" type="button" data-resend style="width:100%">${esc(t('auth.resend'))}</button>
    <button class="btn" type="button" data-other style="width:100%">${esc(t('auth.differentEmail'))}</button>
    <button class="link-btn" type="button" data-signin>${esc(t('auth.backToSignIn'))}</button>
  </div>`, () => renderVerify(root, opts, email));
  const ok = root.querySelector('[data-ok]'), err = root.querySelector('[data-err]');
  root.querySelector('[data-resend]').addEventListener('click', e => resend(e.currentTarget, email, ok, err, () => renderExpired(root, opts, email)));
  root.querySelector('[data-other]').addEventListener('click', () => renderSignUp(root, opts));
  root.querySelector('[data-signin]').addEventListener('click', () => renderSignIn(root, opts, 'email'));
}

// Verification link expired (or already used): request a fresh one.
export function renderExpired(root, opts, email = '') {
  frame(root, `<form class="auth-card auth-center" data-form novalidate>
    ${status('alert')}
    <h1>${esc(t('auth.expiredTitle'))}</h1><p>${esc(t('auth.expiredBody'))}</p>
    <div class="field" style="text-align:left"><label for="em">${esc(t('auth.email'))}</label><input class="input" id="em" type="email" autocomplete="email" value="${esc(email)}"></div>
    <div class="gated" data-ok hidden role="status"></div><div class="err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">${esc(t('auth.resend'))}</button>
    <button class="link-btn" type="button" data-signin>${esc(t('auth.backToSignIn'))}</button>
  </form>`, () => renderExpired(root, opts, root.querySelector('#em')?.value || email));
  const form = root.querySelector('[data-form]'), ok = root.querySelector('[data-ok]'), err = root.querySelector('[data-err]');
  form.addEventListener('submit', e => {
    e.preventDefault();
    const value = root.querySelector('#em').value.trim();
    if (!EMAIL.test(value)) return showErr(err, t('c.invalidEmail'));
    resend(form.querySelector('[type=submit]'), value, ok, err);
  });
  root.querySelector('[data-signin]').addEventListener('click', () => renderSignIn(root, opts, 'email'));
}

function renderForgot(root, opts) {
  frame(root, `<form class="auth-card" data-form novalidate>
    <h1>${esc(t('auth.forgot'))}</h1><p>${esc(t('auth.resetLead'))}</p>
    <div class="field"><label for="em">${esc(t('auth.email'))}</label><input class="input" id="em" type="email" autocomplete="username"></div>
    <div class="err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">${esc(t('auth.sendReset'))}</button>
    <button class="link-btn" type="button" data-back style="justify-self:center">${esc(t('auth.backToSignIn'))}</button></form>`, () => renderForgot(root, opts));
  const form = root.querySelector('[data-form]'), err = root.querySelector('[data-err]');
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const email = root.querySelector('#em').value.trim();
    if (!EMAIL.test(email)) return showErr(err, t('c.invalidEmail'));
    err.hidden = true;
    try {
      await busy(form.querySelector('[type=submit]'), () => api.recover(email), t('auth.sending'));
      renderCheckEmail(root, opts);
    } catch (ex) { showErr(err, ex.message); }
  });
  root.querySelector('[data-back]').addEventListener('click', () => renderSignIn(root, opts, 'email'));
}

// Check your email (after Forgot Password). GoTrue never reveals whether
// the address exists, and neither does this copy.
function renderCheckEmail(root, opts) {
  frame(root, `<div class="auth-card auth-center">
    ${status('mail')}
    <h1>${esc(t('auth.checkTitle'))}</h1><p>${esc(t('auth.checkBody'))}</p>
    <p class="auth-muted">${esc(t('auth.spam'))}</p>
    <button class="btn primary" type="button" data-signin style="width:100%">${esc(t('auth.backToSignIn'))}</button>
    <button class="btn" type="button" data-other style="width:100%">${esc(t('auth.tryAnother'))}</button>
  </div>`, () => renderCheckEmail(root, opts));
  root.querySelector('[data-signin]').addEventListener('click', () => renderSignIn(root, opts, 'email'));
  root.querySelector('[data-other]').addEventListener('click', () => renderForgot(root, opts));
}

// Signed in through the Operator Sign-In, but the server returned no
// membership after claiming invitations. Never falls through to business
// creation; the account can retry (e.g. after accepting the invite) or
// switch account -- as Vendor Mobile.
export function renderNoOperatorAccess(root, { onRetry, onSignOut }) {
  frame(root, `<div class="auth-card auth-center" role="alert">
    ${status('users')}
    <h1>${esc(t('auth.noOpTitle'))}</h1><p>${esc(t('auth.noOpBody'))}</p>
    <button class="btn primary" type="button" data-retry style="width:100%">${esc(t('c.retry'))}</button>
    <button class="btn" type="button" data-signout style="width:100%">${esc(t('shell.signOut'))}</button>
  </div>`, () => renderNoOperatorAccess(root, { onRetry, onSignOut }), { langRight: true });
  root.querySelector('[data-retry]').addEventListener('click', onRetry);
  root.querySelector('[data-signout]').addEventListener('click', onSignOut);
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
