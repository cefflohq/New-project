// CEFFLO Vendor Web App — bootstrap. Auth -> server role resolution ->
// shell. The frontend is untrusted: the server enforces everything.
import './prefs.js';
import { t } from './i18n.js';
import { api, consumeAuthFragment } from './api.js';
import { loadContext, clearContext, HelperOnlyError, NoBusinessError } from './store.js';
import { mountShell } from './shell.js';
import { errorState } from './ui.js';
import { renderSignIn, renderSetPassword } from './pages/auth.js';
import today from './pages/today.js';
import orders from './pages/orders.js';
import zones from './pages/zones.js';
import runs from './pages/runs.js';
import riders from './pages/riders.js';
import settings from './pages/settings.js';

const root = document.getElementById('app');
const PAGES = { today, orders, zones, runs, riders, settings };

async function signOut() {
  await api.signOut();
  clearContext();
  start();
}

async function start(message = '') {
  const linkType = consumeAuthFragment();
  if (!api.session()?.access_token) {
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
    if (e instanceof HelperOnlyError || e instanceof NoBusinessError) {
      await api.signOut();
      renderSignIn(root, { onSignedIn: () => start(), message: e instanceof HelperOnlyError ? t('auth.helper') : t('c.noBusiness') });
      return;
    }
    if (e.status === 401 || /JWT|session/i.test(e.message)) { await api.signOut(); renderSignIn(root, { onSignedIn: () => start() }); return; }
    root.innerHTML = `<div class="auth"><div class="auth-card">${errorState(e, 'boot')}</div></div>`;
    root.querySelector('[data-retry]')?.addEventListener('click', () => start());
  }
}

start();
