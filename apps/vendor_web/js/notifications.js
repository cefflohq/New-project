// Notification centre for the Vendor Web App (contract:
// docs/cefflo/NOTIFICATION_EVENT_MATRIX.md). Rows come only from
// public.notifications (written by the server from delivery_events and FOUNDR
// broadcasts); RLS limits every read to the signed-in user's own rows.
//   event -> foreground banner -> sound (if on) -> persists in the centre.
// Background delivery (Web Push) is deferred: no provider exists, so nothing
// here pretends to deliver while the tab is closed. While the tab is open but
// hidden, the browser Notification API is used only if the user granted it.
import { api } from './api.js';
import { isDemo, readOnly } from './demo.js';
import { ctx, selectBusiness } from './store.js';
import { t, ago, fmtDate } from './i18n.js';
import { esc, icon, toast, modal, busy } from './ui.js';
import { subscribe } from './realtime.js';

const SELECT = 'id,app,business_id,event_key,category,priority,title,body,target,params,created_at,read_at';
// Events whose sound column is "yes" in the matrix.
const SOUND = new Set(['order.new_customer', 'delivery.issue', 'run.declined', 'rider.joined', 'platform.announcement']);
const FRESH_MS = 2 * 60_000;
const listeners = new Set();

export const notif = {
  items: [],
  unread: 0,
  prefs: { enabled: true, sound: true },
  loaded: false,
  error: null,
};

let sub = null, userId = null, prefsRow = false, tokenTimer = null, seen = new Set(), subscribedOnce = false;

const emit = () => listeners.forEach(fn => { try { fn(notif); } catch { /* listener error */ } });
export const onNotifications = fn => { listeners.add(fn); return () => listeners.delete(fn); };

// Localised copy for known event keys; server copy is the fallback and is
// always used for broadcasts and for the rider's own issue note.
export function copy(n) {
  const p = n.params || {};
  const known = ['order.new_customer', 'delivery.issue', 'run.declined', 'rider.joined', 'run.completed'];
  if (!known.includes(n.event_key)) return { title: n.title, body: n.body };
  const title = t(`nt.${n.event_key}.t`, { ref: p.ref || '' }).trim();
  const body = n.event_key === 'delivery.issue' ? n.body : t(`nt.${n.event_key}.b`, p);
  return { title, body };
}

const when = iso => (Date.now() - new Date(iso).getTime() < 24 * 3600_000 ? ago(iso) : fmtDate(iso));

async function loadList() {
  const [rows, unread] = await Promise.all([
    api.get(`/rest/v1/notifications?app=eq.vendor&select=${SELECT}&order=created_at.desc&limit=50`),
    api.get('/rest/v1/notifications?app=eq.vendor&read_at=is.null&select=id&limit=100'),
  ]);
  notif.items = Array.isArray(rows) ? rows : [];
  notif.unread = Array.isArray(unread) ? unread.length : 0;
  notif.items.forEach(n => seen.add(n.id));
  notif.loaded = true; notif.error = null;
  emit();
}

async function loadPrefs() {
  const rows = await api.get(`/rest/v1/notification_preferences?user_id=eq.${userId}&select=enabled,sound`);
  prefsRow = Array.isArray(rows) && !!rows[0];
  if (prefsRow) notif.prefs = { enabled: rows[0].enabled !== false, sound: rows[0].sound !== false };
}

export async function startNotifications() {
  stopNotifications();
  if (isDemo()) { notif.items = []; notif.unread = 0; notif.loaded = true; emit(); return; }
  userId = ctx.user?.id;
  if (!userId) return;
  try { await Promise.all([loadList(), loadPrefs()]); } catch (e) { notif.error = e; notif.loaded = true; emit(); }
  const session = api.session();
  if (!session?.access_token || !window.WebSocket) return;
  sub = subscribe({
    table: 'notifications',
    filter: `recipient_user_id=eq.${userId}`,
    token: session.access_token,
    onChange: handleChange,
    onStatus: s => {
      // Rejoin after a drop: re-read history; banners are never replayed.
      if (s === 'subscribed') { if (subscribedOnce) loadList().catch(() => {}); subscribedOnce = true; }
    },
  });
  // Keep the realtime token current (the REST client refreshes on demand).
  let last = session.access_token;
  tokenTimer = setInterval(async () => {
    const s = api.session();
    if (s?.expires_at && s.expires_at * 1000 - Date.now() < 120_000) await api.refreshSession().catch(() => {});
    const now = api.session()?.access_token;
    if (now && now !== last) { last = now; sub?.setToken(now); }
  }, 60_000);
}

export function stopNotifications() {
  sub?.close(); sub = null; clearInterval(tokenTimer); tokenTimer = null;
  subscribedOnce = false; seen = new Set();
  notif.items = []; notif.unread = 0; notif.loaded = false;
  document.querySelector('.nbanners')?.remove();
}

function handleChange({ type, record, old_record: old }) {
  if (type === 'INSERT' && record?.app === 'vendor') {
    if (notif.items.some(n => n.id === record.id)) return;
    notif.items = [record, ...notif.items].slice(0, 50);
    if (!record.read_at) notif.unread += 1;
    emit();
    if (!seen.has(record.id)) { seen.add(record.id); present(record); }
  } else if (type === 'UPDATE' && record) {
    const i = notif.items.findIndex(n => n.id === record.id);
    if (i >= 0) {
      const was = notif.items[i].read_at;
      notif.items[i] = { ...notif.items[i], ...record };
      if (!was && record.read_at) notif.unread = Math.max(0, notif.unread - 1);
      if (was && !record.read_at) notif.unread += 1;
      emit();
    }
  } else if (type === 'DELETE' && old?.id) {
    const n = notif.items.find(x => x.id === old.id);
    notif.items = notif.items.filter(x => x.id !== old.id);
    if (n && !n.read_at) notif.unread = Math.max(0, notif.unread - 1);
    emit();
  }
}

// ---------------------------------------------------------------- foreground
function present(n) {
  if (!notif.prefs.enabled) return;
  if (Date.now() - new Date(n.created_at).getTime() > FRESH_MS) return;
  const c = copy(n);
  if (document.hidden && 'Notification' in window && Notification.permission === 'granted') {
    try {
      const sys = new Notification(c.title, { body: c.body, tag: n.id, requireInteraction: n.priority === 'urgent' });
      sys.onclick = () => { window.focus(); openTarget(n); sys.close(); };
    } catch { /* not allowed in this context */ }
  } else {
    banner(n, c);
  }
  if (notif.prefs.sound && SOUND.has(n.event_key)) window.CEFFLO_SOUND?.play();
}

function banner(n, c) {
  let root = document.querySelector('.nbanners');
  if (!root) { root = document.createElement('div'); root.className = 'nbanners'; root.setAttribute('aria-live', 'polite'); document.body.append(root); }
  if (root.querySelector(`[data-nid="${n.id}"]`)) return;
  const el = document.createElement('div');
  const urgent = n.priority === 'urgent';
  el.className = `nbanner${urgent ? ' urgent' : ''}`;
  el.dataset.nid = n.id;
  el.setAttribute('role', urgent ? 'alert' : 'status');
  el.innerHTML = `<span class="nb-ico">${icon(urgent ? 'alert' : 'bell')}</span>
    <button class="nb-main" data-open><b>${esc(c.title)}</b><span>${esc(c.body)}</span></button>
    <button class="icon-btn nb-x" data-x aria-label="${esc(t('c.close'))}">${icon('x')}</button>`;
  const close = () => el.remove();
  el.addEventListener('click', e => {
    if (e.target.closest('[data-x]')) close();
    else if (e.target.closest('[data-open]')) { close(); openTarget(n); }
  });
  root.prepend(el);
  if (!urgent) setTimeout(close, 6000);
}

// ---------------------------------------------------------------- actions
export async function markRead(ids = null) {
  if (isDemo()) return;
  const before = notif.items.map(n => ({ ...n }));
  const stamp = new Date().toISOString();
  notif.items = notif.items.map(n => (!ids || ids.includes(n.id)) && !n.read_at ? { ...n, read_at: stamp } : n);
  notif.unread = ids ? Math.max(0, notif.unread - before.filter(n => ids.includes(n.id) && !n.read_at).length) : 0;
  emit();
  try {
    await api.rpc('mark_notifications_read', ids ? { p_ids: ids, p_app: 'vendor' } : { p_app: 'vendor' });
  } catch (e) {
    await loadList().catch(() => { notif.items = before; emit(); });
    toast(e.message || t('c.errorBody'), 'error');
  }
}

export async function markUnread(id) {
  if (isDemo()) return;
  try {
    await api.rpc('mark_notification_unread', { p_id: id });
    const n = notif.items.find(x => x.id === id);
    if (n?.read_at) { n.read_at = null; notif.unread += 1; emit(); }
  } catch (e) { toast(e.message || t('c.errorBody'), 'error'); }
}

export function openTarget(n) {
  if (!n.read_at) markRead([n.id]);
  const tg = n.target || {};
  const hash = { order: tg.id ? `#/orders/${tg.id}` : '#/orders', runs: '#/runs', riders: '#/riders', rider: tg.id ? `#/riders/${tg.id}` : '#/riders' }[tg.screen];
  if (!hash) return;
  // A notification from another of the user's businesses switches to it first.
  if (n.business_id && n.business_id !== ctx.bid && ctx.businesses.some(b => b.business_id === n.business_id)) {
    selectBusiness(n.business_id);
    location.hash = hash;
    window.dispatchEvent(new CustomEvent('cefflo:business-switched'));
    return;
  }
  location.hash = hash;
}

export async function savePreferences(next) {
  if (isDemo()) throw readOnly();
  const body = { enabled: !!next.enabled, sound: !!next.sound, updated_at: new Date().toISOString() };
  // The shared REST client sends no Prefer header, so no upsert: insert the
  // first time (absent row = defaults), update afterwards.
  const patch = () => api.write(`/rest/v1/notification_preferences?user_id=eq.${userId}`, 'PATCH', body);
  if (prefsRow) await patch();
  else {
    try { await api.write('/rest/v1/notification_preferences', 'POST', { user_id: userId, ...body }); } catch (e) {
      if (!/duplicate|23505|conflict/i.test(e.message)) throw e;
      await patch();
    }
    prefsRow = true;
  }
  notif.prefs = { enabled: body.enabled, sound: body.sound };
  emit();
}

// Browser permission for alerts while this tab is open but hidden. Reported
// truthfully: unsupported / default / granted / denied.
export const browserPermission = () => ('Notification' in window ? Notification.permission : 'unsupported');
export async function requestBrowserPermission() {
  if (!('Notification' in window)) return 'unsupported';
  try { return await Notification.requestPermission(); } catch { return Notification.permission; }
}

// ---------------------------------------------------------------- panel
export function renderPanel() {
  const multi = ctx.businesses.length > 1;
  const bizName = id => ctx.businesses.find(b => b.business_id === id)?.business_name || '';
  const list = notif.error
    ? `<div class="np-empty">${icon('alert')}<b>${esc(t('c.errorTitle'))}</b><span>${esc(notif.error.message || '')}</span><button class="btn sm" data-nretry>${esc(t('c.retry'))}</button></div>`
    : !notif.loaded ? '<div class="skel" style="height:42px;margin:12px"></div>'.repeat(3)
    : !notif.items.length ? `<div class="np-empty">${icon('bell')}<b>${esc(t('nt.empty'))}</b><span>${esc(t(isDemo() ? 'nt.emptyDemo' : 'nt.emptySub'))}</span></div>`
    : notif.items.map(n => {
      const c = copy(n);
      return `<div class="np-item${n.read_at ? '' : ' unread'}${n.priority === 'urgent' ? ' urgent' : ''}" data-nid="${esc(n.id)}">
        <button class="np-open" data-nopen><span class="np-ico">${icon(n.priority === 'urgent' ? 'alert' : n.category === 'announcement' ? 'info' : 'bell')}</span>
          <span class="np-txt"><b>${esc(c.title)}</b><span>${esc(c.body)}</span><small>${esc(when(n.created_at))}${multi && n.business_id ? ` · ${esc(bizName(n.business_id))}` : ''}</small></span></button>
        <button class="np-dot" data-ntoggle aria-label="${esc(t(n.read_at ? 'nt.markUnread' : 'nt.markRead'))}" title="${esc(t(n.read_at ? 'nt.markUnread' : 'nt.markRead'))}"><i></i></button>
      </div>`;
    }).join('');
  return `<div class="np-head"><b>${esc(t('shell.notifications'))}</b>
      <button class="btn sm" data-nall ${notif.unread && !isDemo() ? '' : 'disabled'}>${esc(t('nt.markAll'))}</button></div>
    <div class="np-list">${list}</div>
    <div class="np-foot"><button class="btn sm" data-nprefs>${icon('gear')}${esc(t('nt.preferences'))}</button></div>`;
}

export function wirePanel(panel, { onPrefs, close }) {
  panel.addEventListener('click', e => {
    const item = e.target.closest('[data-nid]');
    const n = item && notif.items.find(x => x.id === item.dataset.nid);
    if (e.target.closest('[data-nall]')) { markRead(null); return; }
    if (e.target.closest('[data-nretry]')) { loadList().catch(err => { notif.error = err; emit(); }); return; }
    if (e.target.closest('[data-nprefs]')) { close(); onPrefs(); return; }
    if (n && e.target.closest('[data-ntoggle]')) { if (n.read_at) markUnread(n.id); else markRead([n.id]); return; }
    if (n && e.target.closest('[data-nopen]')) { close(); openTarget(n); }
  });
}

// ---------------------------------------------------------------- preferences
// Two server-backed switches (Notifications, Sound) plus the truthful browser
// permission state. Shared by the bell panel and Settings.
export function openNotificationPrefs() {
  const pick = { ...notif.prefs };
  const row = (k, ic) => `<div class="toggle-row">${icon(ic)}<div class="grow"><b>${esc(t(`nt.pref.${k}`))}</b><small>${esc(t(`nt.pref.${k}Sub`))}</small></div>
    <button type="button" class="switch ${pick[k] ? 'on' : ''}" role="switch" aria-checked="${pick[k]}" aria-label="${esc(t(`nt.pref.${k}`))}" data-k="${k}" ${k === 'sound' && !pick.enabled ? 'disabled' : ''}></button></div>`;
  const permLine = () => {
    const p = browserPermission();
    return `<div class="gated" data-perm>${icon('info')}<div><b>${esc(t('nt.perm.title'))}:</b> ${esc(t(`nt.perm.${p}`))}${p === 'default' ? ` <button class="btn sm" data-askperm>${esc(t('nt.perm.allow'))}</button>` : ''}</div></div>`;
  };
  const m = modal({ title: t('notif.title'), lead: t('nt.pref.lead'), center: true,
    body: `<div class="toggle-list">${row('enabled', 'bell')}${row('sound', 'bell')}</div>${permLine()}
      <div class="gated">${icon('info')}<div>${esc(t('nt.pref.pushDeferred'))}</div></div>`,
    footer: `<button class="btn primary" data-msave style="min-width:240px" ${isDemo() ? 'disabled' : ''}>${esc(t('c.save'))}</button>` });
  m.el.addEventListener('click', async e => {
    const sw = e.target.closest('[data-k]');
    if (sw && !sw.disabled) {
      const k = sw.dataset.k; pick[k] = !pick[k];
      sw.classList.toggle('on', pick[k]); sw.setAttribute('aria-checked', String(pick[k]));
      const snd = m.el.querySelector('[data-k="sound"]');
      if (k === 'enabled') snd.disabled = !pick.enabled;
      // Sound preview uses the same player and rules as real alerts.
      if (k === 'sound' && pick.sound) window.CEFFLO_SOUND?.play();
    }
    if (e.target.closest('[data-askperm]')) {
      await requestBrowserPermission();
      m.el.querySelector('[data-perm]').outerHTML = permLine();
    }
    const save = e.target.closest('[data-msave]');
    if (save) {
      try { await busy(save, () => savePreferences(pick)); m.close(); toast(t('c.saved')); }
      catch (err) { toast(err.message || t('c.errorBody'), 'error'); }
    }
  });
}
