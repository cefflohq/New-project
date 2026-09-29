// Shared UI primitives: escaping, icons, status chips, states, modal,
// toast and busy buttons. Every page builds from these.
import { t } from './i18n.js';

export const esc = v => String(v ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const P = {
  home: '<path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
  file: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5M9 13h6M9 17h6"/>',
  pin: '<path d="M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>',
  route: '<circle cx="6" cy="6" r="2.5"/><circle cx="18" cy="12" r="2.5"/><circle cx="6" cy="18" r="2.5"/><path d="M8.3 7.2l7.4 3.6M8.3 16.8l7.4-3.6"/>',
  users: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M21.5 20a6.5 6.5 0 0 0-4-6"/>',
  gear: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  bell: '<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/><path d="M10 20a2 2 0 0 0 4 0"/>',
  down: '<path d="M6 9l6 6 6-6"/>', right: '<path d="M9 6l6 6-6 6"/>', left: '<path d="M19 12H5M11 6l-6 6 6 6"/>',
  search: '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>', plus: '<path d="M12 5v14M5 12h14"/>',
  upload: '<path d="M12 16V4M7 9l5-5 5 5M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2"/>',
  plan: '<circle cx="6" cy="18" r="2.5"/><circle cx="18" cy="6" r="2.5"/><path d="M8 16c4-1 3-9 8-9"/>',
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>', code: '<path d="M8 8l-4 4 4 4M16 8l4 4-4 4M13.5 5l-3 14"/>', check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>', eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>', x: '<path d="M6 6l12 12M18 6L6 18"/>',
  phone: '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>',
  wa: '<path d="M4 20l1.3-4A8 8 0 1 1 8 18.7z"/><path d="M9 9.5c.2 2 2.6 4.5 5 5l1.3-1.3-2-1-1 .8a4 4 0 0 1-1.8-1.8l.8-1-1-2z"/>',
  lock: '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
  palette: '<path d="M12 3a9 9 0 1 0 0 18c1.1 0 1.7-.9 1.4-1.9-.4-1.2.4-2.1 1.6-2.1H17a4 4 0 0 0 4-4c0-5.5-4-10-9-10z"/><circle cx="7.5" cy="11" r="1.2"/><circle cx="10" cy="7" r="1.2"/><circle cx="15" cy="7.5" r="1.2"/>',
  building: '<path d="M4 21V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v16M16 9h2a2 2 0 0 1 2 2v10M3 21h18M8 7h4M8 11h4M8 15h4"/>',
  store: '<path d="M4 9l1.5-5h13L20 9M4 9v11h16V9M4 9a2.7 2.7 0 0 0 5.3 0 2.7 2.7 0 0 0 5.4 0 2.7 2.7 0 0 0 5.3 0M10 20v-5h4v5"/>',
  box: '<path d="M21 8l-9-5-9 5 9 5z"/><path d="M3 8v8l9 5 9-5V8M12 13v8"/>',
  card: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 10h18"/>',
  link: '<path d="M10 14a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1M14 10a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1"/>',
  help: '<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.6V14M12 17.5v.01"/>',
  shield: '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M9 12l2 2 4-4"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7.5v.01"/>',
  logout: '<path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3M10 16l-4-4 4-4M6 12h10"/>',
  alert: '<path d="M12 4l9 16H3z"/><path d="M12 10v4M12 17v.01"/>', clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  map: '<path d="M9 4L3 6v14l6-2 6 2 6-2V4l-6 2z"/><path d="M9 4v14M15 6v14"/>', check: '<path d="M5 12.5l4.5 4.5L19 7"/>',
  star: '<path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.8l-5.2 2.8 1-5.8-4.3-4.1 5.9-.8z"/>',
  bike: '<circle cx="6" cy="16" r="3"/><circle cx="18" cy="16" r="3"/><path d="M6 16l4-7h5l3 7M9 9h4M14 5h2l1 4"/>',
  dots: '<circle cx="5" cy="12" r="1.3"/><circle cx="12" cy="12" r="1.3"/><circle cx="19" cy="12" r="1.3"/>',
  filter: '<path d="M4 6h16M7 12h10M10 18h4"/>', camera: '<path d="M4 8h3l2-3h6l2 3h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>',
  mail: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/>', invite: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0M19 8v6M16 11h6"/>',
  csv: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5M9 13h1M9 17h6"/>',
  pkg: '<path d="M12 3l8 4.5v9L12 21l-8-4.5v-9z"/><path d="M12 12l8-4.5M12 12v9M12 12L4 7.5"/>',
  moon: '<path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z"/>',
};
export const icon = (name, cls = 'i') => `<svg class="${cls}" viewBox="0 0 24 24" aria-hidden="true">${P[name] || ''}</svg>`;

export const initials = name => {
  if (String(name || '').includes('@') && !/\s/.test(String(name).trim())) return String(name).replace(/[^\p{L}]/gu, '').slice(0, 2).toUpperCase() || '?';
  const parts = String(name || '').replace(/\[[^\]]*\]/g, ' ').replace(/[^\p{L}\p{N}@.\s]/gu, ' ').trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return '?';
  return (parts.length > 1 ? parts[0][0] + parts[parts.length - 1][0] : parts[0].slice(0, 2)).toUpperCase();
};
export const avatar = (name, cls = '') => `<span class="avatar ${cls}">${esc(initials(name))}</span>`;

// Order display status derived from backend truth (delivery_status +
// preparation_status). No invented states.
export function orderStatus(o, prep) {
  const d = o.delivery_status;
  if (d === 'delivered') return 'delivered';
  if (d === 'issue') return 'issue';
  if (d === 'cancelled') return 'cancelled';
  if (['picked_up', 'out_for_delivery', 'arrived'].includes(d)) return 'delivery';
  if (['preparing', 'packed', 'sorted'].includes(prep)) return 'preparing';
  return 'ready';
}
const CHIP = {
  ready: ['ready', 'st.ready'], delivery: ['delivery', 'st.onDelivery'], issue: ['issue', 'st.issue'],
  delivered: ['delivered', 'st.delivered'], preparing: ['preparing', 'st.preparing'], cancelled: ['neutral', 'st.cancelled'],
  active: ['active', 'st.active'], inactive: ['neutral', 'st.inactive'], pending: ['pending', 'st.pending'],
  unassigned: ['neutral', 'st.unassigned'],
};
export const chip = (s, dot = false) => {
  const [cls, key] = CHIP[s] || ['neutral', s];
  return `<span class="chip ${cls}">${dot ? '<i class="dot"></i>' : ''}${esc(t(key))}</span>`;
};

export const itemsText = items => {
  const n = (Array.isArray(items) ? items : []).reduce((s, i) => s + (Number(i?.quantity ?? i?.qty ?? 1) || 1), 0);
  return n === 1 ? t('c.item') : t('c.items', { n });
};
export const itemsLines = items => (Array.isArray(items) ? items : []).map(i => ({
  name: typeof i === 'string' ? i : (i?.name || i?.title || ''), qty: typeof i === 'string' ? 1 : Number(i?.quantity ?? i?.qty ?? 1) || 1,
})).filter(l => l.name);

// ---------------------------------------------------------------- states
export const loadingRows = (n = 5) => `<div class="card-b" aria-busy="true">${Array.from({ length: n }, () => '<div class="skel" style="height:42px;margin:10px 0"></div>').join('')}</div>`;
export const emptyState = (title, body = '', actionHtml = '') => `<div class="state"><div class="ico">${icon('box')}</div><h3>${esc(title)}</h3>${body ? `<div>${esc(body)}</div>` : ''}${actionHtml}</div>`;
export const errorState = (err, retryId) => `<div class="state error" role="alert"><div class="ico">${icon('alert')}</div><h3>${esc(t('c.errorTitle'))}</h3><div>${esc(err?.message || t('c.errorBody'))}</div>${retryId ? `<button class="btn sm" data-retry="${retryId}">${esc(t('c.retry'))}</button>` : ''}</div>`;
export const gatedNote = text => `<div class="gated">${icon('info')}<div><b>${esc(t('gate.title'))}.</b> ${esc(text)}</div></div>`;

// ---------------------------------------------------------------- toast
export function toast(message, kind = '') {
  let root = document.querySelector('.toasts');
  if (!root) { root = document.createElement('div'); root.className = 'toasts'; root.setAttribute('role', 'status'); document.body.append(root); }
  const el = document.createElement('div');
  el.className = `toast ${kind}`;
  el.textContent = message;
  root.append(el);
  setTimeout(() => el.remove(), 3500);
}

// ---------------------------------------------------------------- busy
// Runs an async action with the button disabled + spinner, preventing
// duplicate submissions. Returns the action result or throws.
export async function busy(btn, action, label = t('c.saving')) {
  if (!btn || btn.disabled) return undefined;
  const html = btn.innerHTML;
  btn.disabled = true;
  btn.innerHTML = `<i class="spin"></i>${esc(label)}`;
  try { return await action(); } finally { btn.disabled = false; btn.innerHTML = html; }
}

// ---------------------------------------------------------------- modal
// Focused popup over the current page; the page stays visible, softly
// blurred. Returns { el, close }.
export function modal({ title, lead = '', body = '', footer = '', center = false, onClose, cls = '', head = '' }) {
  const root = document.createElement('div');
  root.className = 'modal-root';
  root.innerHTML = `<div class="modal ${cls}" role="dialog" aria-modal="true" aria-label="${esc(title)}">
    <div class="modal-h">${head || `<div><h2>${esc(title)}</h2>${lead ? `<p>${esc(lead)}</p>` : ''}</div>`}
      <button class="icon-btn x" data-close aria-label="${esc(t('c.close'))}">${icon('x')}</button></div>
    <div class="modal-b">${body}</div>
    ${footer ? `<div class="modal-f ${center ? 'center' : ''}">${footer}</div>` : ''}</div>`;
  const prev = document.activeElement;
  const close = () => { root.remove(); document.removeEventListener('keydown', onKey); prev?.focus?.(); onClose?.(); };
  const onKey = e => { if (e.key === 'Escape') close(); };
  root.addEventListener('click', e => { if (e.target === root || e.target.closest('[data-close]')) close(); });
  document.addEventListener('keydown', onKey);
  document.body.append(root);
  root.querySelector('input,select,textarea,button:not([data-close])')?.focus();
  return { el: root, close };
}

export function confirmDialog({ title, body, confirmLabel, danger = false }) {
  return new Promise(resolve => {
    let done = false;
    const m = modal({
      title, lead: body,
      footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn ${danger ? 'danger-soft' : 'primary'}" data-ok>${esc(confirmLabel)}</button>`,
      onClose: () => { if (!done) resolve(false); },
    });
    m.el.querySelector('[data-ok]').addEventListener('click', () => { done = true; m.close(); resolve(true); });
  });
}

export function copyText(text) {
  return navigator.clipboard?.writeText(text).then(() => true, () => false) ?? Promise.resolve(false);
}

export const phoneDigits = p => String(p || '').replace(/[^\d]/g, '');
