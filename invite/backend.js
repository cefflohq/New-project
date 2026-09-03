(function () {
  const api = window.CEFFLO;
  const PENDING_KEY = 'cefflo_pending_invite';

  const params = new URLSearchParams(location.search);
  const urlToken = params.get('token');
  const urlType = params.get('type') === 'rider' ? 'rider' : 'team'; // default: team

  function readPending() {
    try { return JSON.parse(localStorage.getItem(PENDING_KEY) || 'null'); } catch { return null; }
  }
  function savePending(token, type) {
    // The raw token exists here only transiently, client-side, exactly long
    // enough to survive a signup -> email-confirmation -> first-authenticated-
    // load round trip -- it is never sent anywhere but the resolve/accept
    // RPCs, and never persisted server-side in raw form.
    localStorage.setItem(PENDING_KEY, JSON.stringify({ token, type }));
  }
  function clearPending() { localStorage.removeItem(PENDING_KEY); }

  // A token in the URL always wins; otherwise fall back to a pending token
  // saved before a signup's email-confirmation redirect.
  const pending = readPending();
  const token = urlToken || pending?.token || null;
  const type = urlToken ? urlType : (pending?.type || urlType);

  const el = {
    loading: document.getElementById('loadingState'),
    invalid: document.getElementById('invalidState'),
    invalidReason: document.getElementById('invalidReason'),
    main: document.getElementById('mainState'),
    headline: document.getElementById('headline'),
    subheadline: document.getElementById('subheadline'),
    summaryBusiness: document.getElementById('summaryBusiness'),
    summaryRole: document.getElementById('summaryRole'),
    ownerWarning: document.getElementById('ownerWarning'),
    formStatus: document.getElementById('formStatus'),
    tabs: document.getElementById('authTabs'),
    loginForm: document.getElementById('loginForm'),
    signupForm: document.getElementById('signupForm'),
    success: document.getElementById('successState'),
    successHeadline: document.getElementById('successHeadline'),
    successBody: document.getElementById('successBody'),
    pendingScreen: document.getElementById('pendingState'),
  };

  function show(section) {
    [el.loading, el.invalid, el.main, el.success, el.pendingScreen].forEach(s => s.classList.add('hidden'));
    section.classList.remove('hidden');
  }
  function setStatus(message, kind) {
    el.formStatus.innerHTML = message ? `<div class="status ${kind || 'error'}">${message}</div>` : '';
  }
  function setBusy(busy) {
    document.getElementById('loginBtn').disabled = busy;
    document.getElementById('signupBtn').disabled = busy;
  }
  function friendlyError(error) {
    const raw = String(error?.message || error || 'Something went wrong.');
    const map = {
      'Invalid login credentials': 'Email or password is incorrect.',
      'invitation expired': 'This invitation has expired. Ask for a new one.',
      'invitation not available': 'This invitation is no longer available.',
      'invalid invitation': 'This invitation link is not valid.',
      'email mismatch': 'This invitation was sent to a different email address. Log in or sign up using that exact email.',
      'User already registered': 'An account already exists for this email — use Log In instead.',
    };
    return map[raw] || raw.replace(/^Backend \d+:\s*/, '');
  }

  if (!token) {
    show(el.invalid);
    el.invalidReason.textContent = 'This invitation link is missing its token.';
    return;
  }

  async function resolveInvite() {
    try {
      const fn = type === 'rider' ? 'resolve_rider_invitation' : 'resolve_team_invitation';
      const result = await api.rpc(fn, { p_token: token });
      if (!result || result.status !== 'pending') {
        show(el.invalid);
        el.invalidReason.textContent = !result
          ? 'This invitation link is not valid.'
          : result.status === 'expired' ? 'This invitation has expired. Ask for a new one.'
          : result.status === 'revoked' ? 'This invitation has been revoked.'
          : 'This invitation has already been used.';
        clearPending();
        return;
      }
      el.summaryBusiness.textContent = result.business_name;
      if (type === 'rider') {
        el.headline.textContent = 'Rider invitation';
        el.subheadline.textContent = 'Join as a delivery Rider for this business.';
        el.summaryRole.textContent = 'Invited as: Rider';
      } else {
        el.headline.textContent = "You're invited";
        el.subheadline.textContent = 'Join the trusted team for this business.';
        el.summaryRole.textContent = `Invited role: ${result.role === 'owner' ? 'Owner' : 'Operator / Staff'}`;
        if (result.role === 'owner') el.ownerWarning.classList.remove('hidden');
      }
      show(el.main);
      // Already authenticated (e.g. returning after email confirmation, or
      // simply already logged in) -- skip the forms and accept directly.
      if (api.session()?.access_token) {
        await accept();
      }
    } catch (error) {
      show(el.invalid);
      el.invalidReason.textContent = friendlyError(error);
      clearPending();
    }
  }

  async function accept() {
    try {
      const fn = type === 'rider' ? 'accept_rider_invitation' : 'accept_team_invitation';
      const result = await api.rpc(fn, { p_token: token });
      clearPending();
      if (type === 'rider') {
        show(el.pendingScreen);
      } else {
        el.successBody.textContent = `You've joined as ${result.role === 'owner' ? 'Owner' : 'Operator / Staff'}.`;
        show(el.success);
      }
    } catch (error) {
      setStatus(friendlyError(error), 'error');
      show(el.main);
    }
  }

  el.tabs.addEventListener('click', (event) => {
    const btn = event.target.closest('[data-tab]');
    if (!btn) return;
    [...el.tabs.children].forEach(b => b.classList.toggle('active', b === btn));
    el.loginForm.classList.toggle('hidden', btn.dataset.tab !== 'login');
    el.signupForm.classList.toggle('hidden', btn.dataset.tab !== 'signup');
    setStatus('');
  });

  document.getElementById('loginBtn').addEventListener('click', async () => {
    const email = document.getElementById('li-email').value.trim();
    const password = document.getElementById('li-pass').value;
    if (!email || !password) return setStatus('Enter your email and password.', 'error');
    setBusy(true); setStatus('');
    try {
      await api.login(email, password);
      await accept();
    } catch (error) {
      setStatus(friendlyError(error), 'error');
    } finally {
      setBusy(false);
    }
  });

  document.getElementById('signupBtn').addEventListener('click', async () => {
    const email = document.getElementById('su-email').value.trim();
    const password = document.getElementById('su-pass').value;
    if (!email || password.length < 8) return setStatus('Enter a valid email and a password of at least 8 characters.', 'error');
    setBusy(true); setStatus('');
    try {
      // Real Supabase Auth signup only -- no mock OTP anywhere in this path.
      const result = await api.request('/auth/v1/signup', { method: 'POST', token: null, body: { email, password } });
      if (result?.access_token) {
        api.setSession(result);
        await accept();
      } else {
        // Email confirmation required: the raw token must survive that
        // round trip -- stashed transiently, cleared the moment acceptance
        // finally succeeds or fails, never sent anywhere but this page's
        // own resolve/accept calls.
        savePending(token, type);
        setStatus('Account created. Check your email to confirm, then reopen this exact invitation link to finish joining.', 'success');
      }
    } catch (error) {
      setStatus(friendlyError(error), 'error');
    } finally {
      setBusy(false);
    }
  });

  resolveInvite();
})();
