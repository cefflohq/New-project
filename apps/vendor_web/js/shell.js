// The single application shell: a persistent neutral sidebar (workspace
// switcher, primary navigation, Settings / Help and the account menu), a
// compact top bar and the hash router. Pages only render into the content
// area. Below 1024px the sidebar becomes an icon rail, below 768px an
// off-canvas drawer; both open from the top-bar toggle.
import { t, longToday } from './i18n.js';
import { isDemo } from './demo.js';
import { ctx, selectBusiness } from './store.js';
import { esc, icon, initials, avatar, confirmDialog, setChromeColor } from './ui.js';
import { notif, onNotifications, startNotifications, renderPanel, wirePanel, openNotificationPrefs } from './notifications.js';

// Feature parity with the Vendor App, navigation fitted to desktop (Founder,
// 2026-10-05): the app's tabs plus Products and Storefront as direct
// shortcuts. Active Runs is a secondary overview opened from Zones.
const NAV = [
  ['today', 'home', 'nav.today'],
  ['orders', 'file', 'nav.orders'],
  ['zones', 'pin', 'nav.zones'],
  ['riders', 'users', 'nav.riders'],
  ['products', 'pkg', 'nav.products'],
  ['storefront', 'store', 'nav.storefront'],
];
const NAV_PARENT = { runs: 'zones' };

let root, content, pages, cleanup = null, onSignOut;

export function mountShell(el, pageMap, { signOut }) {
  root = el; pages = pageMap; onSignOut = signOut;
  renderFrame();
  // One listener per page lifetime: a remount after sign-out / sign-in must
  // not stack a second router or route against the old, removed shell.
  window.removeEventListener('hashchange', route);
  window.addEventListener('hashchange', route);
  route();
  startNotifications();
}

// A notification deep-link into another of the user's businesses.
window.addEventListener('cefflo:business-switched', () => { if (root?.isConnected) rerenderShell(); });

export function rerenderShell() {
  renderFrame();
  route();
}

function renderFrame() {
  setChromeColor(getComputedStyle(document.documentElement).getPropertyValue('--bg').trim() || '#fbfbfc');
  const b = ctx.business;
  const name = ctx.user?.user_metadata?.full_name || ctx.user?.email || '';
  const link = (id, ic, key, href = `#/${id}`) => `<a href="${href}" data-nav="${id}" title="${esc(t(key))}">${icon(ic)}<span class="lbl">${esc(t(key))}</span></a>`;
  root.innerHTML = `
  <div class="shell">
    <aside class="sidebar" aria-label="Main navigation">
      <a class="brand" href="#/today"><img src="img/cefflo-icon-navy.png" alt="" width="22" height="22"><b>Cefflo</b><small>Vendor</small></a>
      <div class="ws">
        <button class="ws-btn" data-bizmenu aria-haspopup="menu" aria-label="${esc(t('shell.switchBusiness'))}" title="${esc(b?.business_name)}">
          <span class="ws-tile">${esc(initials(b?.business_name).slice(0, 1))}</span>
          <span class="ws-txt"><b>${esc(b?.business_name)}</b><small>${esc(t(`shell.role.${b?.member_role}`))}</small></span>${icon('updown', 'i updown')}
        </button>
      </div>
      <nav class="nav">${NAV.map(([id, ic, key]) => link(id, ic, key)).join('')}</nav>
      <div class="sidebar-foot nav">
        ${link('settings', 'menu', 'nav.settings')}
        <div class="acct">
          <button class="acct-btn" data-usermenu aria-haspopup="menu" title="${esc(name)}">${avatar(name, 'xs')}<span class="acct-txt"><b>${esc(name)}</b><small>${esc(ctx.user?.email)}</small></span>${icon('updown', 'i updown')}</button>
        </div>
      </div>
    </aside>
    <div class="scrim" data-scrim></div>
    <main class="main">
      <header class="topbar">
        <button class="icon-btn nav-toggle" data-navtoggle aria-label="${esc(t('shell.menu'))}" aria-expanded="false">${icon('menu')}</button>
        <h1 data-title></h1><div class="date" data-date></div>
        <div class="spacer"></div>
        <div style="position:relative">
          <button class="icon-btn" data-bell aria-haspopup="dialog" aria-label="${esc(t('shell.notifications'))}">${icon('bell')}<span class="nbadge" data-nbadge hidden></span></button>
        </div>
      </header>
      ${isDemo() ? `<div class="demo-bar" role="status"><b>${esc(t('demo.bar'))}</b><span>${esc(t('demo.barBody'))}</span></div>` : ''}
      <section class="content" data-content></section>
    </main>
  </div>`;
  content = root.querySelector('[data-content]');
  wireSidebar(root.querySelector('.sidebar'));
  root.querySelector('[data-bizmenu]').addEventListener('click', e => openBizMenu(e.currentTarget));
  root.querySelector('[data-usermenu]').addEventListener('click', e => openUserMenu(e.currentTarget));
  root.querySelector('[data-bell]').addEventListener('click', e => openBell(e.currentTarget));
  paintBadge();
}

function paintBadge() {
  const b = root?.querySelector('[data-nbadge]');
  if (!b) return;
  b.hidden = !notif.unread;
  b.textContent = notif.unread > 99 ? '99+' : String(notif.unread);
  root.querySelector('[data-bell]').setAttribute('aria-label', notif.unread ? `${t('shell.notifications')} (${notif.unread})` : t('shell.notifications'));
}

let panelOff = null;
function openBell(anchor) {
  const wasOpen = !!document.querySelector('.npanel');
  closeMenus();
  if (wasOpen) return;
  const m = document.createElement('div');
  m.className = 'menu npanel';
  m.setAttribute('role', 'dialog');
  m.setAttribute('aria-label', t('shell.notifications'));
  const paint = () => { m.innerHTML = renderPanel(); };
  paint();
  wirePanel(m, { onPrefs: openNotificationPrefs, close: closeMenus });
  panelOff = onNotifications(() => { if (m.isConnected) paint(); else { panelOff?.(); panelOff = null; } });
  anchor.parentElement.append(m);
}
onNotifications(paintBadge);

// Rail / drawer: the top-bar toggle opens the full sidebar over the page;
// choosing a destination, the scrim or Escape closes it.
function wireSidebar(sb) {
  const toggle = root.querySelector('[data-navtoggle]');
  const set = open => { sb.classList.toggle('open', open); toggle.setAttribute('aria-expanded', String(open)); };
  toggle.addEventListener('click', () => set(!sb.classList.contains('open')));
  root.querySelector('[data-scrim]').addEventListener('click', () => set(false));
  sb.addEventListener('click', e => { if (e.target.closest('a')) set(false); });
  document.addEventListener('keydown', e => { if (e.key === 'Escape' && sb.classList.contains('open')) set(false); });
}

function closeMenus() { document.querySelectorAll('.menu').forEach(m => m.remove()); }
document.addEventListener('click', e => { if (!e.target.closest('.menu,[data-bizmenu],[data-usermenu],[data-bell]')) closeMenus(); });


function openBizMenu(anchor) {
  const wasOpen = !!anchor.parentElement.querySelector('.menu');
  closeMenus();
  if (wasOpen) return;
  const m = document.createElement('div');
  m.className = 'menu down-left';
  m.setAttribute('role', 'menu');
  m.innerHTML = `<div class="menu-label">${esc(t('shell.switchBusiness'))}</div>` + ctx.businesses.map(b => `<button role="menuitem" data-bid="${esc(b.business_id)}"><span class="ws-tile">${esc(initials(b.business_name).slice(0, 1))}</span><span><b>${esc(b.business_name)}</b><small>${esc(t(`shell.role.${b.member_role}`))}</small></span>${b.business_id === ctx.bid ? icon('check') : ''}</button>`).join('');
  m.addEventListener('click', e => {
    const id = e.target.closest('[data-bid]')?.dataset.bid;
    if (!id) return;
    closeMenus();
    if (id !== ctx.bid) { selectBusiness(id); rerenderShell(); }
  });
  anchor.parentElement.append(m);
}

function openUserMenu(anchor) {
  const wasOpen = !!anchor.parentElement.querySelector('.menu');
  closeMenus();
  if (wasOpen) return;
  const m = document.createElement('div');
  m.className = 'menu up';
  m.setAttribute('role', 'menu');
  m.innerHTML = `<div class="menu-head"><b>${esc(ctx.user?.user_metadata?.full_name || '')}</b><small>${esc(ctx.user?.email)}</small></div>
    <button role="menuitem" data-go="#/settings/profile">${icon('user')}<span>${esc(t('shell.profile'))}</span></button>
    <button role="menuitem" class="danger" data-signout>${icon('logout')}<span>${esc(t('shell.signOut'))}</span></button>`;
  m.addEventListener('click', e => {
    if (e.target.closest('[data-go]')) { closeMenus(); location.hash = e.target.closest('[data-go]').dataset.go; }
    if (e.target.closest('[data-signout]')) { closeMenus(); confirmSignOut(); }
  });
  anchor.parentElement.append(m);
}

export function setHeader(title, withDate = true) {
  root.querySelector('[data-title]').textContent = title;
  root.querySelector('[data-date]').textContent = withDate ? longToday() : '';
  document.title = `${title} · Cefflo Vendor`;
}

function route() {
  // Signed out (shell no longer on screen): nothing to route.
  if (!root?.isConnected || !root.querySelector('[data-title]')) return;
  const [name = 'today', ...rest] = location.hash.replace(/^#\/?/, '').split('/');
  const page = pages[name] ? name : 'today';
  const navKey = NAV_PARENT[page] || page;
  root.querySelectorAll('[data-nav]').forEach(a => {
    const on = a.dataset.nav === navKey;
    a.classList.toggle('active', on);
    if (on) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current');
  });
  try { cleanup?.(); } catch { /* ignore */ }
  cleanup = null;
  // A page's dialog (e.g. Driver detail) never stays over the next page.
  document.querySelectorAll('.modal-root [data-close]').forEach(x => x.click());
  // A fresh element per route, so listeners a page attached (and late async
  // renders) never leak into the next page.
  const fresh = content.cloneNode(false);
  content.replaceWith(fresh);
  content = fresh;
  const res = pages[page]({ el: content, params: rest.map(decodeURIComponent), setHeader });
  if (typeof res === 'function') cleanup = res;
}

// Sign out always asks first (short yes/no popup).
async function confirmSignOut() {
  const ok = await confirmDialog({ title: t('out.title'), body: t('out.body'), confirmLabel: t('shell.signOut'), danger: true });
  if (ok) onSignOut();
}
export function signOutHandler() { return confirmSignOut; }
