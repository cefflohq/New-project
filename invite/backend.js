(function () {
  const api = window.CEFFLO;
  const params = new URLSearchParams(location.search);
  const token = params.get('token');
  const type = params.get('type') === 'team' ? 'team' : 'rider';
  const $ = id => document.getElementById(id);

  if (type === 'rider') riderFlow(); else teamFlow();

  // ==========================================================================
  // Rider invitation (Founder-approved 2026-09-28, Option 1).
  // The PWA records the rider's decision only:
  //   Accept  -> consent_rider_invitation (no account, no rider row)
  //   Decline -> decline_rider_invitation
  // The Driver app later claims the consent for the same invited email
  // (claim_my_rider_invitations), so there is exactly one acceptance.
  // ==========================================================================
  function riderFlow() {
    $('riderApp').hidden = false;
    const screens = ['scrValidating', 'scrInvited', 'scrAccepted', 'scrUnavailable'];
    const hero = $('riderHero');
    let businessName = '';

    function show(id) {
      screens.forEach(s => { $(s).hidden = s !== id; });
      $('headerName').textContent = businessName;
      window.scrollTo(0, 0);
    }
    function setHero(title, body) {
      hero.textContent = '';
      if (!title) return;
      const h = document.createElement('h2'); h.textContent = title; hero.appendChild(h);
      if (body) { const p = document.createElement('p'); p.append(...body); hero.appendChild(p); }
    }
    function markChecks(count) {
      [...document.querySelectorAll('#checks li')].forEach((li, i) => li.classList.toggle('done', i < count));
    }

    const UNAVAILABLE = {
      invalid: ['This invitation link is not valid.', 'Check that you opened the full link, or ask the business to send you a new invitation.'],
      expired: ['This invitation has expired.', 'Ask the business to send you a new invitation.'],
      revoked: ['This invitation was withdrawn by the business.', 'Contact the business if you still want to join their delivery team.'],
      declined: ['You declined this invitation.', 'If you change your mind, ask the business to send you a new invitation.'],
      error: ['We could not check this invitation right now.', 'Check your connection and open the link again.'],
    };
    function unavailable(kind) {
      const [body, next] = UNAVAILABLE[kind] || UNAVAILABLE.invalid;
      setHero('');
      $('unavailableBody').textContent = body;
      $('unavailableNext').textContent = next;
      show('scrUnavailable');
    }

    function accepted() {
      setHero('');
      $('acceptedBody').textContent = businessName
        ? `You’ve accepted the invitation from ${businessName}.`
        : 'You’ve accepted the invitation.';
      configureStores();
      show('scrAccepted');
    }

    // Store destinations are configuration, never guessed. Until the Founder
    // supplies real listing URLs the rows stay visible but disabled -- the
    // acceptance itself is already saved server-side.
    function configureStores() {
      const stores = (window.CEFFLO_CONFIG && window.CEFFLO_CONFIG.driverStoreUrls) || {};
      const rows = [['storeAndroid', stores.android], ['storeIos', stores.ios]];
      for (const [id, url] of rows) {
        const a = $(id);
        if (url) { a.href = url; a.target = '_blank'; a.removeAttribute('aria-disabled'); }
        else { a.removeAttribute('href'); a.setAttribute('aria-disabled', 'true'); }
      }
      // The rider's own platform first; the other stays available.
      if (/iphone|ipad|ipod/i.test(navigator.userAgent)) {
        $('storeIos').parentNode.insertBefore($('storeIos'), $('storeAndroid'));
      }
    }

    function invited(result) {
      businessName = result.business_name || '';
      const nameEl = document.createElement('strong'); nameEl.textContent = businessName;
      setHero('You’re Invited!', ['Join ', nameEl, ' on Cefflo. Be part of their delivery team and start making deliveries.']);
      $('bizName').textContent = businessName;
      if (result.location) {
        $('bizLocation').querySelector('em').textContent = result.location;
        $('bizLocation').hidden = false;
      }
      show('scrInvited');
    }

    function mapError(error) {
      const raw = String(error?.message || error || '');
      if (/expired/.test(raw)) return 'expired';
      if (/not available/.test(raw)) return 'unusable';
      if (/invalid invitation/.test(raw)) return 'invalid';
      return 'error';
    }

    async function decide(kind) {
      const accept = $('acceptBtn'); const decline = $('declineBtn'); const status = $('decisionStatus');
      accept.disabled = decline.disabled = true; status.hidden = true;
      accept.textContent = kind === 'consent' ? 'Accepting…' : accept.textContent;
      try {
        const result = await api.rpc(kind === 'consent' ? 'consent_rider_invitation' : 'decline_rider_invitation', { p_token: token }, { token: null });
        if (kind === 'consent' && result?.status === 'consented') return accepted();
        if (kind === 'decline' && result?.status === 'declined') return unavailable('declined');
        throw new Error('unexpected');
      } catch (error) {
        const reason = mapError(error);
        if (reason === 'unusable') return resolve();   // state changed meanwhile: re-read it
        if (reason !== 'error') return unavailable(reason);
        status.textContent = 'We could not save your answer. Check your connection and try again.';
        status.hidden = false;
      } finally {
        accept.disabled = decline.disabled = false;
        accept.textContent = 'Accept Invitation';
      }
    }
    $('acceptBtn').addEventListener('click', () => decide('consent'));
    $('declineBtn').addEventListener('click', () => decide('decline'));

    // Screen 1: validation runs while this state is visible; the checklist
    // completes when the real answer arrives (no invented progress).
    async function resolve() {
      setHero('');
      markChecks(0);
      show('scrValidating');
      if (!token || !/^[0-9a-f]{64}$/i.test(token)) return unavailable('invalid');
      let result;
      try {
        result = await api.rpc('resolve_rider_invitation', { p_token: token }, { token: null });
      } catch (_) {
        return unavailable('error');
      }
      if (!result) { businessName = ''; return unavailable('invalid'); }
      markChecks(3);
      businessName = result.business_name || '';
      switch (result.status) {
        case 'pending': return invited(result);
        // Already decided in this PWA (or already claimed in the app):
        // reopening or refreshing never repeats the acceptance.
        case 'consented':
        case 'accepted': return accepted();
        case 'declined': return unavailable('declined');
        case 'revoked': return unavailable('revoked');
        case 'expired': return unavailable('expired');
        default: return unavailable('invalid');
      }
    }
    resolve();
  }

  // ==========================================================================
  // Team (Owner / Operator) invitation -- staff join through Vendor surfaces;
  // behaviour unchanged: log in or sign up, then accept_team_invitation.
  // ==========================================================================
  function teamFlow() {
    $('teamApp').hidden = false;
    const PENDING_KEY = 'cefflo_pending_invite';
    const sections = ['loadingState', 'invalidState', 'mainState', 'successState'];
    const show = id => sections.forEach(s => { $(s).hidden = s !== id; });
    const setStatus = (message, kind) => {
      $('formStatus').innerHTML = '';
      if (!message) return;
      const div = document.createElement('div');
      div.className = `status-msg ${kind || 'error'}`; div.textContent = message;
      $('formStatus').appendChild(div);
    };
    const setBusy = busy => { $('loginBtn').disabled = busy; $('signupBtn').disabled = busy; };
    let pending = null;
    try { pending = JSON.parse(localStorage.getItem(PENDING_KEY) || 'null'); } catch (_) {}
    const teamToken = token || pending?.token || null;
    const clearPending = () => { try { localStorage.removeItem(PENDING_KEY); } catch (_) {} };
    const friendly = error => {
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
    };
    if (!teamToken) { show('invalidState'); $('invalidReason').textContent = 'This invitation link is missing its token.'; return; }

    async function accept() {
      try {
        const result = await api.rpc('accept_team_invitation', { p_token: teamToken });
        clearPending();
        $('successBody').textContent = `You've joined as ${result.role === 'owner' ? 'Owner' : 'Operator / Staff'}.`;
        show('successState');
      } catch (error) { setStatus(friendly(error)); show('mainState'); }
    }
    (async () => {
      try {
        const result = await api.rpc('resolve_team_invitation', { p_token: teamToken });
        if (!result || result.status !== 'pending') {
          show('invalidState');
          $('invalidReason').textContent = !result ? 'This invitation link is not valid.'
            : result.status === 'expired' ? 'This invitation has expired. Ask for a new one.'
            : result.status === 'revoked' ? 'This invitation has been revoked.'
            : 'This invitation has already been used.';
          clearPending(); return;
        }
        $('summaryBusiness').textContent = result.business_name;
        $('summaryRole').textContent = `Invited role: ${result.role === 'owner' ? 'Owner' : 'Operator / Staff'}`;
        $('ownerWarning').hidden = result.role !== 'owner';
        show('mainState');
        if (api.session()?.access_token) await accept();
      } catch (error) { show('invalidState'); $('invalidReason').textContent = friendly(error); clearPending(); }
    })();
    $('authTabs').addEventListener('click', event => {
      const btn = event.target.closest('[data-tab]'); if (!btn) return;
      [...$('authTabs').children].forEach(b => b.classList.toggle('active', b === btn));
      $('loginForm').hidden = btn.dataset.tab !== 'login';
      $('signupForm').hidden = btn.dataset.tab !== 'signup';
      setStatus('');
    });
    $('loginBtn').addEventListener('click', async () => {
      const email = $('li-email').value.trim(); const password = $('li-pass').value;
      if (!email || !password) return setStatus('Enter your email and password.');
      setBusy(true); setStatus('');
      try { await api.login(email, password); await accept(); } catch (error) { setStatus(friendly(error)); } finally { setBusy(false); }
    });
    $('signupBtn').addEventListener('click', async () => {
      const email = $('su-email').value.trim(); const password = $('su-pass').value;
      if (!email || password.length < 8) return setStatus('Enter a valid email and a password of at least 8 characters.');
      setBusy(true); setStatus('');
      try {
        const result = await api.request('/auth/v1/signup', { method: 'POST', token: null, body: { email, password } });
        if (result?.access_token) { api.setSession(result); await accept(); }
        else {
          try { localStorage.setItem(PENDING_KEY, JSON.stringify({ token: teamToken, type: 'team' })); } catch (_) {}
          setStatus('Account created. Check your email to confirm, then reopen this exact invitation link to finish joining.', 'success');
        }
      } catch (error) { setStatus(friendly(error)); } finally { setBusy(false); }
    });
  }
})();
