// CEFFLO Vendor Web App — bootstrap. Auth -> server role resolution ->
// shell. The frontend is untrusted: the server enforces everything.
import './prefs.js';
import { t } from './i18n.js';
import { operatorEntry } from './access.js';
import { api, consumeAuthFragment, consumeAuthError } from './api.js';
import { loadContext, clearContext, HelperOnlyError, NoBusinessError } from './store.js';
import { mountShell } from './shell.js';
import { stopNotifications } from './notifications.js';
import { errorState } from './ui.js';
import { renderSignIn, renderSetPassword, renderExpired, renderNoOperatorAccess, renderSplash, ephemeralSessionEnded } from './pages/auth.js';
import { renderBusinessSetup } from './pages/setup.js';
import { openAddOrder } from './pages/order_actions.js';
import { openAddRider } from './pages/riders.js';
import today from './pages/today.js';
import orders from './pages/orders.js';
import zones from './pages/zones.js';
import runs from './pages/runs.js';
import riders from './pages/riders.js';
import settings from './pages/settings.js';
import products from './pages/products.js';
import storefront from './pages/storefront.js';

const root = document.getElementById('app');
const PAGES = { today, orders, zones, runs, riders, products, storefront, settings };

async function signOut() {
  stopNotifications();
  await api.signOut();
  clearContext();
  start();
}

async function start(message = '') {
  if (ephemeralSessionEnded() && api.session()?.access_token) { try { await api.signOut(); } catch { /* already gone */ } }
  const linkError = consumeAuthError();
  const linkType = consumeAuthFragment();
  if (!api.session()?.access_token) {
    // An expired or already-used emailed link: offer a fresh one.
    if (linkError) {
      if (/expired|invalid|denied/i.test(`${linkError.code} ${linkError.description}`)) renderExpired(root, { onSignedIn: () => start() });
      else renderSignIn(root, { onSignedIn: () => start(), message: linkError.description });
      return;
    }
    renderSignIn(root, { onSignedIn: () => start(), message });
    return;
  }
  if (linkType === 'recovery') {
    renderSetPassword(root, { onDone: () => start() });
    return;
  }
  root.innerHTML = '<div class="auth"><div class="auth-card"><div class="skel" style="height:24px"></div><div class="skel" style="height:24px"></div></div></div>';
  try {
    await loadContext();
    mountShell(root, PAGES, { signOut });
  } catch (e) {
    // D-74: signed in through the Operator Sign-In with no membership after
    // claiming invitations. Show the Operator no-access state; the Web App
    // has no business creation, and this account must never become an Owner
    // by falling through.
    if (e instanceof NoBusinessError && operatorEntry()) {
      renderNoOperatorAccess(root, { onRetry: () => start(), onSignOut: () => signOut() });
      return;
    }
    // Owner onboarding: a signed-in account with no business (and not
    // entering as an Operator) sets up its business with the existing
    // bootstrap_business. The server decides everything; this only guides.
    if (e instanceof NoBusinessError) {
      renderBusinessSetup(root, {
        reload: () => loadContext(),
        onSignOut: () => signOut(),
        onExpired: async () => { await api.signOut(); clearContext(); start(t('setup.expired')); },
        onReady: action => {
          location.hash = action === 'area' ? '#/settings/business' : '#/today';
          mountShell(root, PAGES, { signOut });
          if (action === 'rider') openAddRider();
          if (action === 'order') openAddOrder();
        },
      });
      return;
    }
    if (e instanceof HelperOnlyError) {
      await api.signOut();
      renderSignIn(root, { onSignedIn: () => start(), message: e instanceof HelperOnlyError ? t('auth.helper') : t('c.noBusiness') });
      return;
    }
    if (e.status === 401 || /JWT|session/i.test(e.message)) { await api.signOut(); renderSignIn(root, { onSignedIn: () => start() }); return; }
    root.innerHTML = `<div class="auth"><div class="auth-card">${errorState(e, 'boot')}</div></div>`;
    root.querySelector('[data-retry]')?.addEventListener('click', () => start());
  }
}

// Splash each time the Web App opens (Founder, 2026-09-30): a brief brand
// moment, then the normal start.
renderSplash(root);
setTimeout(() => start(), 1100);
