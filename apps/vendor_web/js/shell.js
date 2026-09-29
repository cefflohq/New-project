// The single application shell: sidebar (collapsed by default, expands
// quickly on interaction, collapses when interaction ends), top bar and the
// hash router. Pages only render into the content area.
import { t, longToday } from './i18n.js';
import { isDemo } from './demo.js';
import { ctx, selectBusiness } from './store.js';
import { esc, icon, initials } from './ui.js';

const NAV = [
  ['today', 'home', 'nav.today'],
  ['orders', 'file', 'nav.orders'],
  ['zones', 'pin', 'nav.zones'],
  ['runs', 'route', 'nav.runs'],
  ['riders', 'users', 'nav.riders'],
];

let root, content, pages, cleanup = null, onSignOut;

export function mountShell(el, pageMap, { signOut }) {
  root = el; pages = pageMap; onSignOut = signOut;
  renderFrame();
  window.addEventListener('hashchange', route);
  route();
}

export function rerenderShell() {
  renderFrame();
  route();
}

function renderFrame() {
  const b = ctx.business;
  root.innerHTML = `
  <div class="shell">
    <aside class="sidebar" aria-label="Main navigation">
      <div class="brand"><img class="mark" src="img/cefflo-mark-white.png" alt="Cefflo" width="26" height="32"><img class="full" src="img/cefflo-wordmark-white.png" alt="Cefflo" width="118" height="56"></div>
      <nav class="nav">
        ${NAV.map(([id, ic, key]) => `<a href="#/${id}" data-nav="${id}">${icon(ic)}<span class="lbl">${esc(t(key))}</span></a>`).join('')}
        <hr>
        <a href="#/settings" data-nav="settings">${icon('gear')}<span class="lbl">${esc(t('nav.settings'))}</span></a>
      </nav>
      <div class="sidebar-foot">
        <button class="biz-chip" data-bizmenu aria-label="${esc(t('shell.switchBusiness'))}">
          <span class="ico">${icon('store')}</span>
          <span class="txt"><b>${esc(b?.business_name)}</b><small>${esc(t(`shell.role.${b?.member_role}`))}</small></span><span class="chev">${icon('down')}</span>
        </button>
      </div>
    </aside>
    <main class="main">
      ${isDemo() ? `<div class="demo-bar" role="status"><b>${esc(t('demo.bar'))}</b><span>${esc(t('demo.barBody'))}</span></div>` : ''}
      <header class="topbar">
        <h1 data-title></h1><div class="date" data-date></div>
        <div class="spacer"></div>
        <div class="biz-switch" data-bizmenu role="button" tabindex="0" aria-haspopup="menu" aria-label="${esc(t('shell.switchBusiness'))}">
          ${icon('store')}<div><b>${esc(b?.business_name)}</b><small>${esc(t(`shell.role.${b?.member_role}`))}</small></div>
          <span style="margin-left:auto">${icon('down')}</span>
        </div>
        <button class="icon-btn" disabled title="${esc(t('shell.notificationsNotConnected'))}" aria-label="${esc(t('shell.notificationsNotConnected'))}">${icon('bell')}</button>
        <div style="position:relative">
          <button class="user-btn" data-usermenu aria-haspopup="menu">${`<span class="avatar">${esc(initials(ctx.user?.user_metadata?.full_name || ctx.user?.email))}</span>`}${icon('down')}</button>
        </div>
      </header>
      <section data-content></section>
    </main>
  </div>`;
  content = root.querySelector('[data-content]');
  wireSidebar(root.querySelector('.sidebar'));
  root.querySelectorAll('[data-bizmenu]').forEach(el => el.addEventListener('click', e => openBizMenu(e.currentTarget)));
  root.querySelector('[data-usermenu]').addEventListener('click', e => openUserMenu(e.currentTarget));
}

function wireSidebar(sb) {
  let timer;
  const open = () => { clearTimeout(timer); sb.classList.add('expanded'); };
  const close = () => { timer = setTimeout(() => sb.classList.remove('expanded'), 120); };
  sb.addEventListener('mouseenter', open);
  sb.addEventListener('mouseleave', close);
  sb.addEventListener('focusin', open);
  sb.addEventListener('focusout', e => { if (!sb.contains(e.relatedTarget)) close(); });
  sb.addEventListener('click', e => { if (e.target.closest('a')) sb.classList.remove('expanded'); });
}

function closeMenus() { document.querySelectorAll('.menu').forEach(m => m.remove()); }
document.addEventListener('click', e => { if (!e.target.closest('.menu,[data-bizmenu],[data-usermenu]')) closeMenus(); });

function openBizMenu(anchor) {
  closeMenus();
  const m = document.createElement('div');
  m.className = 'menu';
  m.setAttribute('role', 'menu');
  if (anchor.classList.contains('biz-chip')) Object.assign(m.style, { top: 'auto', bottom: 'calc(100% + 6px)', left: '0', right: 'auto' });
  m.innerHTML = ctx.businesses.map(b => `<button role="menuitem" data-bid="${esc(b.business_id)}">${icon('store')}<span><b>${esc(b.business_name)}</b><small>${esc(t(`shell.role.${b.member_role}`))}</small></span>${b.business_id === ctx.bid ? icon('check') : ''}</button>`).join('');
  m.addEventListener('click', e => {
    const id = e.target.closest('[data-bid]')?.dataset.bid;
    if (!id) return;
    closeMenus();
    if (id !== ctx.bid) { selectBusiness(id); rerenderShell(); }
  });
  (anchor.classList.contains('biz-chip') ? anchor.parentElement : anchor).append(m);
}

function openUserMenu(anchor) {
  closeMenus();
  const m = document.createElement('div');
  m.className = 'menu';
  m.setAttribute('role', 'menu');
  m.innerHTML = `<div style="padding:10px 12px"><b>${esc(ctx.user?.user_metadata?.full_name || '')}</b><small>${esc(ctx.user?.email)}</small></div>
    <button role="menuitem" data-go="#/settings/profile">${icon('user')}${esc(t('shell.profile'))}</button>
    <button role="menuitem" class="danger" data-signout>${icon('logout')}${esc(t('shell.signOut'))}</button>`;
  m.addEventListener('click', e => {
    if (e.target.closest('[data-go]')) { closeMenus(); location.hash = e.target.closest('[data-go]').dataset.go; }
    if (e.target.closest('[data-signout]')) { closeMenus(); onSignOut(); }
  });
  anchor.parentElement.append(m);
}

export function setHeader(title, withDate = true) {
  root.querySelector('[data-title]').textContent = title;
  root.querySelector('[data-date]').textContent = withDate ? longToday() : '';
  document.title = `${title} · Cefflo Vendor`;
}

function route() {
  const [name = 'today', ...rest] = location.hash.replace(/^#\/?/, '').split('/');
  const page = pages[name] ? name : 'today';
  root.querySelectorAll('[data-nav]').forEach(a => {
    const on = a.dataset.nav === page;
    a.classList.toggle('active', on);
    if (on) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current');
  });
  try { cleanup?.(); } catch { /* ignore */ }
  cleanup = null;
  content.innerHTML = '';
  const res = pages[page]({ el: content, params: rest.map(decodeURIComponent), setHeader });
  if (typeof res === 'function') cleanup = res;
}

export function signOutHandler() { return onSignOut; }
