(function () {
  // Invitation PWA (D-72 rider, D-73 team + helper). The page records the
  // invitee's single decision and never asks them to log in:
  //   rider  Accept -> consent_rider_invitation  -> Driver app claims it
  //   team   Accept -> consent_team_invitation   -> Vendor app/Web claims it (Operator)
  //   helper Accept -> accept_helper_invitation  -> Helper workspace access (no account)
  const api = window.CEFFLO;
  const $ = id => document.getElementById(id);
  const params = new URLSearchParams(location.search);
  const token = params.get('token');
  const type = ['rider', 'team', 'helper'].includes(params.get('type')) ? params.get('type') : 'rider';

  const ICON = {
    people: '<circle cx="9" cy="8" r="3"/><path d="M3 20a6 6 0 0 1 12 0M16 5a3 3 0 0 1 0 6M21 20a6 6 0 0 0-4-5.7"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    shield: '<path d="M12 3l7 3v5c0 4.5-3 8.4-7 10-4-1.6-7-5.5-7-10V6l7-3z"/>',
    box: '<path d="M3 7l9-4 9 4-9 4-9-4z"/><path d="M3 7v10l9 4 9-4V7M12 11v10"/>',
  };
  const KIND = {
    rider: {
      product: 'Driver',
      invitedLine: 'Be part of their delivery team and start making deliveries.',
      features: [
        ['people', 'Work with a trusted local business', 'Make deliveries within their service area.'],
        ['clock', 'Start delivering today', 'Get access once your account is approved.'],
        ['shield', 'All in one app', 'Orders, navigation and support.'],
      ],
      resolve: 'resolve_rider_invitation', accept: 'consent_rider_invitation', decline: 'decline_rider_invitation',
      pending: 'pending', acceptedStatuses: ['consented', 'accepted'], acceptedResult: 'consented',
      stores: 'driverStoreUrls',
      next: 'Download Cefflo Driver to create your account and complete your driver profile. Sign up with the email address this invitation was sent to.',
      revoked: 'Contact the business if you still want to join their delivery team.',
    },
    team: {
      product: 'Vendor',
      invitedLine: 'Help manage their daily delivery operations as an Operator.',
      features: [
        ['people', 'Run daily operations', 'Orders, zones, delivery planning and riders.'],
        ['clock', 'Vendor app or Vendor Web', 'Sign in with the email address this invitation was sent to.'],
        ['shield', 'Access set by the owner', 'Billing and ownership stay with the business owner.'],
      ],
      resolve: 'resolve_team_invitation', accept: 'consent_team_invitation', decline: 'decline_team_invitation',
      pending: 'pending', acceptedStatuses: ['consented', 'accepted'], acceptedResult: 'consented',
      stores: 'vendorStoreUrls',
      next: 'Download Cefflo Vendor to create your account, or sign in with the email address this invitation was sent to.',
      revoked: 'Contact the business owner if you still want to join their team.',
    },
    helper: {
      product: 'Helper',
      invitedLine: 'Help them prepare and pack orders. No account needed.',
      features: [
        ['box', 'Prepare and pack orders', 'See what to prepare and mark it Ready.'],
        ['clock', 'No account needed', 'Your Helper workspace opens on this device.'],
        ['shield', 'Only what you need', 'Order items for preparation. No customer contact details.'],
      ],
      resolve: 'resolve_helper_invitation', accept: 'accept_helper_invitation', decline: 'decline_helper_invitation',
      pending: 'invited', acceptedStatuses: ['accepted'], acceptedResult: 'accepted',
      stores: null,
      next: 'Your Helper workspace is ready on this device.',
      revoked: 'Contact the business owner if you still want to help their team.',
    },
  }[type];

  $('inviteApp').hidden = false;
  const screens = ['scrValidating', 'scrInvited', 'scrAccepted', 'scrUnavailable'];
  let businessName = '';

  function show(id) {
    screens.forEach(s => { $(s).hidden = s !== id; });
    // The inviting business once known; otherwise the centred wordmark.
    const header = $('headerName');
    header.textContent = '';
    if (businessName) header.textContent = businessName;
    else {
      const b = document.createElement('b'); b.textContent = 'Cefflo';
      const span = document.createElement('span'); span.textContent = ` ${KIND.product}`;
      header.append(b, span);
    }
    window.scrollTo(0, 0);
  }
  function setHero(title, body) {
    const hero = $('inviteHero');
    hero.textContent = '';
    if (!title) return;
    const h = document.createElement('h2'); h.textContent = title; hero.appendChild(h);
    if (body) { const p = document.createElement('p'); p.append(...body); hero.appendChild(p); }
  }
  function markChecks(count) {
    [...document.querySelectorAll('#checks li')].forEach((li, i) => li.classList.toggle('done', i < count));
  }
  function renderFeatures() {
    const list = $('features');
    list.textContent = '';
    for (const [icon, title, body] of KIND.features) {
      const li = document.createElement('li');
      li.innerHTML = `<svg viewBox="0 0 24 24" aria-hidden="true">${ICON[icon]}</svg><div><b></b><span></span></div>`;
      li.querySelector('b').textContent = title;
      li.querySelector('span').textContent = body;
      list.appendChild(li);
    }
  }

  const UNAVAILABLE = {
    invalid: ['This invitation link is not valid.', 'Check that you opened the full link, or ask the business to send you a new invitation.'],
    expired: ['This invitation has expired.', 'Ask the business to send you a new invitation.'],
    revoked: ['This invitation was withdrawn by the business.', KIND.revoked],
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

  // Screen 3. For a helper the workspace link carries the access secret in
  // the URL fragment (never sent to a server); it exists only right after
  // this device accepted. A reopened, already-accepted link gets no secret.
  function accepted(accessToken) {
    setHero('');
    $('acceptedBody').textContent = businessName
      ? `You’ve accepted the invitation from ${businessName}.`
      : 'You’ve accepted the invitation.';
    const workspace = $('openWorkspace');
    workspace.hidden = true;
    $('stores').hidden = true;
    if (type === 'helper') {
      if (accessToken) {
        $('acceptedNext').textContent = KIND.next;
        workspace.href = `../helper/#${accessToken}`;
        workspace.hidden = false;
      } else {
        $('acceptedNext').textContent = 'This invitation was already accepted. Ask the business owner to share your Helper workspace link.';
      }
    } else {
      $('acceptedNext').textContent = KIND.next;
      configureStores();
      $('stores').hidden = false;
    }
    show('scrAccepted');
  }

  // Store destinations are configuration, never guessed. Until real listing
  // URLs exist the badges keep their look but are inert.
  function configureStores() {
    const stores = (window.CEFFLO_CONFIG && window.CEFFLO_CONFIG[KIND.stores]) || {};
    for (const [id, url] of [['storeAndroid', stores.android], ['storeIos', stores.ios]]) {
      const a = $(id);
      if (url) { a.href = url; a.target = '_blank'; a.removeAttribute('aria-disabled'); }
      else { a.removeAttribute('href'); a.setAttribute('aria-disabled', 'true'); }
    }
  }

  function invited(result) {
    const nameEl = document.createElement('strong'); nameEl.textContent = businessName;
    setHero('You’re Invited!', ['Join ', nameEl, ` on Cefflo. ${KIND.invitedLine}`]);
    $('bizName').textContent = businessName;
    if (result.location) {
      $('bizLocation').querySelector('em').textContent = result.location;
      $('bizLocation').hidden = false;
    }
    renderFeatures();
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
    const acceptBtn = $('acceptBtn'); const declineBtn = $('declineBtn'); const status = $('decisionStatus');
    acceptBtn.disabled = declineBtn.disabled = true; status.hidden = true;
    if (kind === 'accept') acceptBtn.textContent = 'Accepting…';
    try {
      const result = await api.rpc(kind === 'accept' ? KIND.accept : KIND.decline, { p_token: token }, { token: null });
      if (kind === 'accept' && result?.status === KIND.acceptedResult) return accepted(result.access_token);
      if (kind === 'decline' && result?.status === 'declined') return unavailable('declined');
      throw new Error('unexpected');
    } catch (error) {
      const reason = mapError(error);
      if (reason === 'unusable') return resolve();   // state changed meanwhile: re-read it
      if (reason !== 'error') return unavailable(reason);
      status.textContent = 'We could not save your answer. Check your connection and try again.';
      status.hidden = false;
    } finally {
      acceptBtn.disabled = declineBtn.disabled = false;
      acceptBtn.textContent = 'Accept Invitation';
    }
  }
  $('acceptBtn').addEventListener('click', () => decide('accept'));
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
      result = await api.rpc(KIND.resolve, { p_token: token }, { token: null });
    } catch (_) {
      return unavailable('error');
    }
    if (!result) { businessName = ''; return unavailable('invalid'); }
    markChecks(3);
    businessName = result.business_name || '';
    // Reopening or refreshing an already-decided link never repeats it.
    if (result.status === KIND.pending) return invited(result);
    if (KIND.acceptedStatuses.includes(result.status)) return accepted(null);
    if (['declined', 'revoked', 'expired'].includes(result.status)) return unavailable(result.status);
    return unavailable('invalid');
  }
  resolve();
})();
