// Vendor Web auth suite (Supabase Auth), mirroring Vendor Mobile: Sign In
// (Vendor or Operator presentation), Email Sign In, Create Account, Verify
// your email, Verification link expired, Forgot Password, Check your email,
// Set New Password, and the Operator no-access state. Every action is a real
// GoTrue call; nothing here decides a role -- the server does, after sign-in.
import { t } from '../i18n.js';
import { api } from '../api.js';
import { esc, busy, icon, setChromeColor } from '../ui.js';
import { prefs, savePrefs } from '../prefs.js';
import { operatorEntry } from '../access.js';

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

// Branded frame shared by every auth screen. The full logo belongs to the
// Splash only (Founder, 2026-09-30): after it, every screen carries the
// Cefflo wordmark alone so its card or actions stay the focus. Top row: the
// back chevron (icon only) at the left, the language control at the right.
function frame(root, bottom, rerender, { hero = '', product = false, back = null } = {}) {
  setChromeColor('#061F5C');
  root.innerHTML = `<div class="auth${product ? ' choose' : ''}">
    <div class="auth-top">
      ${back ? `<button type="button" class="auth-back" data-topback aria-label="${esc(t('c.back'))}">${icon('chevl')}</button>` : ''}
      ${product ? '' : '<img class="auth-top-word" src="img/cefflo-wordmark-white.png" alt="Cefflo" width="555" height="142">'}
      <div class="auth-lang">
        <button type="button" class="auth-lang-btn" data-langmenu aria-haspopup="menu" aria-expanded="false" aria-label="${prefs.lang === 'ms' ? 'Bahasa Melayu' : 'English'}">${icon('globe')}<span>${prefs.lang === 'ms' ? 'BM' : 'EN'}</span></button>
        <div class="auth-lang-menu" role="menu" hidden>
          <button type="button" role="menuitemradio" aria-checked="${prefs.lang === 'en'}" data-lang="en">English</button>
          <button type="button" role="menuitemradio" aria-checked="${prefs.lang === 'ms'}" data-lang="ms">Bahasa Melayu</button>
        </div>
      </div>
    </div>
    <div class="auth-hero${hero ? ' op' : ''}">
      ${product
        ? '<img class="auth-logo" src="img/cefflo-logo.png" alt="Cefflo" width="150" height="234"><span class="auth-product">VENDOR</span>'
        : ''}
      ${hero}
    </div>
    <div class="auth-bottom">${bottom}</div>
  </div>`;
  if (back) root.querySelector('[data-topback]').addEventListener('click', back);
  const btn = root.querySelector('[data-langmenu]'), menu = root.querySelector('.auth-lang-menu');
  btn.addEventListener('click', () => { menu.hidden = !menu.hidden; btn.setAttribute('aria-expanded', String(!menu.hidden)); });
  root.querySelectorAll('[data-lang]').forEach(b => b.addEventListener('click', () => {
    menu.hidden = true;
    if (prefs.lang !== b.dataset.lang) { savePrefs({ lang: b.dataset.lang }); rerender(); }
  }));
}

// Splash, every time the Web App opens: the full logo, centred, and which
// entry this is (VENDOR or OPERATOR ACCESS). Brief; the session check runs
// behind it.
export function renderSplash(root) {
  setChromeColor('#061F5C');
  const label = operatorEntry() ? t('auth.opAccess') : 'Vendor';
  // Every surface's splash: the same artwork at 156px and the surface name.
  root.innerHTML = `<div class="auth splash" role="status" aria-label="Cefflo">
    <div class="splash-lockup"><img src="img/cefflo-logo-splash.png" alt="Cefflo" width="156" height="225"><span>${esc(label)}</span></div>
  </div>`;
}

// Google's multicolour "G" (brand mark, drawn from its official outline).
const GOOGLE_G = '<svg viewBox="0 0 48 48" aria-hidden="true"><path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.4-.4-3.5z"/><path fill="#FF3D00" d="m6.3 14.7 6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/><path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-8l-6.5 5C9.5 39.6 16.2 44 24 44z"/><path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C37 39.2 44 34 44 24c0-1.3-.1-2.4-.4-3.5z"/></svg>';

const status = ic => `<div class="auth-status">${icon(ic)}</div>`;
const showErr = (el, text) => { el.textContent = text; el.hidden = false; };
const notConfirmed = e => /not confirmed/i.test(e?.message || '') || e?.code === 'email_not_confirmed';
const expired = e => /expired|invalid/i.test(`${e?.message || ''} ${e?.code || ''}`);

// GoTrue failure on a 6-digit code -> the code screen's state. GoTrue answers
// an expired and a mistyped code alike (otp_expired), so both read as
// 'incorrect'; a refused resend carries the backend's own wait time.
export function otpFailure(ex) {
  const m = `${ex?.message || ''}`.toLowerCase();
  const wait = /after (\d+) seconds?/.exec(m);
  const retryAfter = wait ? Number(wait[1]) : undefined;
  if (ex?.code === 'otp_expired' || ex?.code === 'otp_disabled') return { kind: 'incorrect' };
  if (/rate_limit/.test(ex?.code || '') || ex?.status === 429 || retryAfter) return { kind: 'rate', retryAfter };
  if (ex instanceof TypeError) return { kind: 'network' };
  if (/expired|invalid/.test(m)) return { kind: 'incorrect' };
  return { kind: 'other', message: ex?.message };
}
const viaOtp = call => async (...a) => { try { return await call(...a); } catch (ex) { throw otpFailure(ex); } };

// Sign-up code: verify -> session -> the app (Business Setup for a new Owner).
function renderSignUpCode(root, opts, email) {
  renderVerifyCode(root, opts, {
    email, purpose: 'signup',
    onVerify: viaOtp(code => api.verifyOtp('signup', email, code)),
    onResend: viaOtp(() => api.resendSignUp(email)),
    onContinue: () => opts.onSignedIn(),
    onBack: () => renderSignUp(root, opts),
  });
}

// Recovery code: verify -> recovery session -> Set New Password -> sign out
// -> Sign In with the new password.
function renderRecoveryCode(root, opts, email) {
  renderVerifyCode(root, opts, {
    email, purpose: 'recovery',
    onVerify: viaOtp(code => api.verifyOtp('recovery', email, code)),
    onResend: viaOtp(() => api.recover(email)),
    onContinue: () => renderSetPassword(root, { onDone: async () => {
      await api.signOut();
      renderSignIn(root, { ...opts, message: t('otp.pwUpdated') });
    } }),
    onBack: () => renderForgot(root, opts),
  });
}

// "Keep me logged in" (same rule as FOUNDR): off means the session ends with
// this browser session; the next visit starts signed out.
const KEEP_KEY = 'cefflo_vendorweb_ephemeral', ALIVE_KEY = 'cefflo_vendorweb_alive';
function rememberChoice(keep) {
  try { if (keep) localStorage.removeItem(KEEP_KEY); else { localStorage.setItem(KEEP_KEY, '1'); sessionStorage.setItem(ALIVE_KEY, '1'); } } catch { /* storage blocked */ }
}
export function ephemeralSessionEnded() {
  try { return localStorage.getItem(KEEP_KEY) === '1' && sessionStorage.getItem(ALIVE_KEY) !== '1'; } catch { return false; }
}

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
      <button class="auth-pill" type="button" data-google>${GOOGLE_G}<span>${esc(t('auth.withGoogle'))}</span></button>
      <button class="auth-pill" type="button" data-email>${icon('mail')}<span>${esc(t('auth.withEmail'))}</span></button>
      <p class="auth-invite">${esc(t('auth.haveInvite'))} <button type="button" class="auth-link" data-invite>${esc(t('auth.getStarted'))}</button></p>`,
    () => again('choose'), { hero, product: true });
    root.querySelector('[data-google]').addEventListener('click', () => { location.assign(api.googleSignInUrl()); });
    root.querySelector('[data-email]').addEventListener('click', () => again('email'));
    root.querySelector('[data-invite]').addEventListener('click', () => renderSignUp(root, opts));
    return;
  }
  frame(root, `<form class="auth-card" data-form novalidate>
    <h1>${esc(t('auth.welcome'))}</h1><p>${esc(t('auth.lead'))}</p>
    ${message ? `<div class="gated">${esc(message)}</div>` : ''}
    <div class="field"><label for="em">${esc(t('auth.email'))}</label><input class="input" id="em" type="email" autocomplete="username" required></div>
    <div class="field"><label for="pw">${esc(t('auth.password'))}</label><input class="input" id="pw" type="password" autocomplete="current-password" required></div>
    <div class="auth-card-links split"><label class="keep"><input type="checkbox" id="keep" checked><span class="keep-dot" aria-hidden="true"></span>${esc(t('auth.keep'))}</label>
      <button class="link-btn" type="button" data-forgot>${esc(t('auth.forgot'))}</button></div>
    <div class="err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">${esc(t('auth.signIn'))}</button>
    <p class="auth-foot">${esc(t('auth.noAccount'))} <button class="link-btn" type="button" data-signup>${esc(t('auth.signUp'))}</button></p>
  </form>`, () => again('email'), { back: () => again('choose') });
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
      rememberChoice(root.querySelector('#keep').checked);
      onSignedIn();
    } catch (ex) {
      // An account that never confirmed its email goes to Verify your email.
      if (notConfirmed(ex)) {
        // The sign-in attempt sends no code; send one, then ask for it.
        try { await api.resendSignUp(email); } catch { /* the code screen's resend covers it */ }
        return renderSignUpCode(root, opts, email);
      }
      showErr(err, /invalid/i.test(ex.message) ? t('auth.bad') : ex.message);
    }
  });
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
    <p class="auth-foot">${esc(t('auth.haveAccount'))} <button class="link-btn" type="button" data-signin>${esc(t('auth.signIn'))}</button></p>
  </form>`, () => renderSignUp(root, opts), { back: () => renderSignIn(root, opts, 'choose') });
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
      if (needsVerification) renderSignUpCode(root, opts, email);
      else opts.onSignedIn();
    } catch (ex) { showErr(err, ex.message); }
  });
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
    <button class="btn primary" type="submit" style="width:100%">${esc(t('auth.sendReset'))}</button></form>`, () => renderForgot(root, opts), { back: () => renderSignIn(root, opts, 'email') });
  const form = root.querySelector('[data-form]'), err = root.querySelector('[data-err]');
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const email = root.querySelector('#em').value.trim();
    if (!EMAIL.test(email)) return showErr(err, t('c.invalidEmail'));
    err.hidden = true;
    try {
      await busy(form.querySelector('[type=submit]'), () => api.recover(email), t('auth.sending'));
      renderRecoveryCode(root, opts, email);
    } catch (ex) { showErr(err, ex.message); }
  });
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
  </div>`, () => renderNoOperatorAccess(root, { onRetry, onSignOut }));
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

// ---------------------------------------------------------------- 6-digit code
// Verify with the 6-digit code from the email (sign-up, password recovery or
// an email change). Presentation and interaction only: `onVerify(code)` and
// `onResend()` belong to the auth flow that owns the GoTrue calls. A
// rejection carries `{ kind: 'incorrect' | 'expired' | 'rate' | 'network',
// retryAfter?, message? }`; GoTrue answers an expired and a mistyped code
// with the same `otp_expired`, so 'incorrect' is the default and 'expired'
// is used only when the backend says so unambiguously. Success is shown only
// after `onVerify` resolves. The code is read from the inputs when needed
// and never logged or stored.
const OTP_LEN = 6;

// Six digit inputs: one-time-code autofill, numeric keyboard, auto-advance,
// paste of the whole code, backspace to the previous box, arrow keys. Shared
// by the auth code screen and the Change Email dialog. The code is read from
// the inputs when needed and never logged or stored.
export const otpBoxesHtml = () => `<div class="otp" role="group" aria-label="${esc(t('otp.label'))}">
  ${Array.from({ length: OTP_LEN }, (_, i) => `<input class="otp-box" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="${i ? 'off' : 'one-time-code'}" aria-label="${esc(t('otp.digit', { n: i + 1 }))}" data-i="${i}">`).join('')}
</div>`;
export function wireOtpBoxes(group, onChange) {
  const boxes = [...group.querySelectorAll('.otp-box')];
  const fill = (from, digits) => {
    digits.split('').slice(0, OTP_LEN - from).forEach((d, k) => { boxes[from + k].value = d; });
    boxes[Math.min(from + digits.length, OTP_LEN - 1)].focus();
  };
  boxes.forEach((b, i) => {
    b.addEventListener('input', () => {
      const digits = b.value.replace(/\D/g, '');
      b.value = '';
      if (digits) fill(i, digits);
      onChange();
    });
    b.addEventListener('paste', e => {
      e.preventDefault();
      const digits = (e.clipboardData?.getData('text') || '').replace(/\D/g, '').slice(0, OTP_LEN);
      if (!digits) return;
      boxes.forEach(x => { x.value = ''; });
      fill(0, digits);
      onChange();
    });
    b.addEventListener('keydown', e => {
      if (e.key === 'Backspace' && !b.value && i > 0) { e.preventDefault(); boxes[i - 1].value = ''; boxes[i - 1].focus(); onChange(); }
      else if (e.key === 'ArrowLeft' && i > 0) { e.preventDefault(); boxes[i - 1].focus(); }
      else if (e.key === 'ArrowRight' && i < OTP_LEN - 1) { e.preventDefault(); boxes[i + 1].focus(); }
    });
    b.addEventListener('focus', () => b.select());
  });
  return {
    code: () => boxes.map(b => b.value).join(''),
    complete: () => boxes.every(b => b.value),
    clear: () => boxes.forEach(b => { b.value = ''; }),
    disable: on => boxes.forEach(b => { b.disabled = on; }),
    bad: on => group.classList.toggle('bad', on),
    focus: () => (boxes.find(b => !b.value) || boxes[OTP_LEN - 1]).focus(),
  };
}

export function renderVerifyCode(root, opts, args) {
  const { email, purpose = 'signup', onVerify, onResend, onContinue, onBack, cooldown = 60 } = args;
  let left = 0, timer = null, verifying = false, failed = null;
  const title = t(`otp.title.${purpose}`);
  const draw = () => frame(root, `<form class="auth-card auth-center" data-form novalidate>
    ${status(purpose === 'recovery' ? 'lock' : 'mail')}
    <h1>${esc(title)}</h1><p>${esc(t('otp.lead'))}</p>
    <p class="auth-email">${esc(email)}</p>
    ${otpBoxesHtml()}
    <div class="err" data-err hidden role="alert"></div><div class="gated" data-ok hidden role="status"></div>
    <button class="btn primary" type="submit" data-verify style="width:100%" disabled>${esc(t('otp.verify'))}</button>
    <p class="otp-resend" data-resendline></p>
    <button class="link-btn" type="button" data-back>${esc(t(purpose === 'signup' ? 'auth.differentEmail' : 'auth.backToSignIn'))}</button>
    <p class="auth-muted">${esc(t('auth.spam'))}</p>
  </form>`, () => renderVerifyCode(root, opts, args), { back: () => { clearInterval(timer); onBack(); } });
  draw();
  const $ = s => root.querySelector(s);
  const err = $('[data-err]'), ok = $('[data-ok]'), verifyBtn = $('[data-verify]'), line = $('[data-resendline]');
  const otp = wireOtpBoxes(root.querySelector('.otp'), () => changed());
  const code = () => otp.code();
  const clearMsgs = () => { err.hidden = true; ok.hidden = true; };
  const setFailed = kind => { failed = kind; otp.bad(!!kind && kind !== 'expired'); };
  const sync = () => {
    verifyBtn.disabled = failed === 'expired' ? left > 0 : verifying || !!failed || code().length !== OTP_LEN;
  };
  const paintLine = () => {
    if (failed === 'expired') { line.innerHTML = left > 0 ? esc(t('otp.resendIn', { s: left })) : ''; sync(); return; }
    line.innerHTML = left > 0 ? esc(t('otp.resendIn', { s: left }))
      : `${esc(t('otp.noCode'))} <button class="link-btn" type="button" data-resend>${esc(t('otp.resend'))}</button>`;
    line.querySelector('[data-resend]')?.addEventListener('click', resend);
  };
  const countdown = s => {
    clearInterval(timer); left = s; paintLine();
    if (s > 0) timer = setInterval(() => { left -= 1; if (!root.contains(line)) return clearInterval(timer); if (left <= 0) clearInterval(timer); paintLine(); }, 1000);
  };
  const failText = f => ({ incorrect: t('otp.incorrect'), expired: t('otp.expired'), rate: t('otp.rate'), network: t('otp.network') })[f?.kind] || f?.message || t('otp.incorrect');
  function changed() {
    if (failed && failed !== 'expired') { setFailed(null); clearMsgs(); }
    sync();
    if (code().length === OTP_LEN && !verifying && !failed) verify();
  }
  async function verify() {
    if (code().length !== OTP_LEN || verifying) return;
    verifying = true; clearMsgs();
    const value = code();
    otp.disable(true);
    let ran = false;
    try {
      // busy() skips a disabled button, so enable it for the call and only
      // treat the code as verified when onVerify actually ran and resolved.
      verifyBtn.disabled = false;
      await busy(verifyBtn, () => { ran = true; return onVerify(value); }, t('otp.verifying'));
      if (!ran) throw { kind: 'network' };
      clearInterval(timer);
      if (purpose === 'recovery') return onContinue();
      renderVerified();
    } catch (f) {
      verifying = false;
      otp.disable(false);
      setFailed(f?.kind || 'incorrect');
      showErr(err, failText(f));
      if (failed === 'expired') {
        otp.clear(); otp.disable(true);
        verifyBtn.textContent = t('otp.sendNew');
      } else otp.focus();
      paintLine(); sync();
    }
  }
  async function resend() {
    if (left > 0) return;
    clearMsgs();
    const target = failed === 'expired' ? verifyBtn : line.querySelector('[data-resend]');
    let ran = false;
    try {
      target.disabled = false;
      await busy(target, () => { ran = true; return onResend(); }, t('auth.sending'));
      if (!ran) return;
      setFailed(null);
      otp.clear(); otp.disable(false);
      verifyBtn.textContent = t('otp.verify');
      ok.textContent = t('otp.resent', { email }); ok.hidden = false;
      countdown(cooldown); otp.focus();
    } catch (f) {
      showErr(err, failText(f));
      if (f?.retryAfter) countdown(f.retryAfter); else paintLine();
    }
    sync();
  }
  function renderVerified() {
    frame(root, `<div class="auth-card auth-center" data-verified>
      ${status('check')}
      <h1>${esc(t('otp.verifiedTitle'))}</h1><p>${esc(t('otp.verifiedLead'))}</p>
      <button class="btn primary" type="button" data-continue style="width:100%">${esc(t('otp.continue'))}</button>
    </div>`, renderVerified);
    root.querySelector('[data-continue]').addEventListener('click', () => onContinue());
  }
  $('[data-form]').addEventListener('submit', e => { e.preventDefault(); if (failed === 'expired') resend(); else verify(); });
  $('[data-back]').addEventListener('click', () => { clearInterval(timer); onBack(); });
  countdown(cooldown);
  sync();
  otp.focus();
  return { close: () => clearInterval(timer) };
}
