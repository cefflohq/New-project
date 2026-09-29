// Active Runs — the business's open delivery runs (no Founder reference
// screen; uses the shared components only, no new design).
import { t, fmtTime, fmtDate } from '../i18n.js';
import { fetchSessions, fetchOrders, fetchRiders, orderNo } from '../data.js';
import { esc, icon, avatar, chip, orderStatus, loadingRows, emptyState, errorState } from '../ui.js';

export default function runs({ el, setHeader }) {
  setHeader(t('runs.title'));
  el.innerHTML = `<div class="card"><div data-list>${loadingRows(6)}</div></div>`;
  const box = el.querySelector('[data-list]');
  async function load() {
    try {
      const [ss, os, rs] = await Promise.all([fetchSessions(), fetchOrders(), fetchRiders()]);
      const riders = new Map((rs || []).map(r => [r.id, r]));
      const open = (ss || []).filter(s => ['planned', 'active'].includes(s.status));
      if (!open.length) { box.innerHTML = emptyState(t('runs.none'), t('runs.noneBody')); return; }
      box.innerHTML = open.map(s => {
        const mine = (os || []).filter(o => o.delivery_session_id === s.id);
        const byRider = new Map();
        mine.forEach(o => { const k = o.assigned_rider_id || ''; byRider.set(k, [...(byRider.get(k) || []), o]); });
        return `<div class="card-b" style="border-bottom:1px solid var(--border)">
          <div style="display:flex;align-items:center;gap:10px"><b style="font-size:17px">${esc(s.name)}</b>${chip(s.status === 'active' ? 'active' : 'pending')}
            <span class="hint" style="margin-left:auto">${esc(fmtDate(s.delivery_date))}${s.pickup_at ? ` · ${esc(t('runs.pickup', { t: fmtTime(s.pickup_at) }))}` : ''} · ${esc(t('runs.orders', { n: mine.length }))}</span></div>
          ${[...byRider.entries()].map(([rid, list]) => `<div style="margin-top:10px">
            <div class="person" style="margin-bottom:6px">${avatar(riders.get(rid)?.name || '?', 'sm')}<b>${esc(riders.get(rid)?.name || t('st.unassigned'))}</b></div>
            ${list.map(o => `<a class="list-row" href="#/orders/${esc(o.id)}" style="color:inherit;text-decoration:none;padding:8px 0"><div class="grow"><b style="font-size:14px">${esc(orderNo(o))}</b><small>${esc(o.customer_name)}</small></div>${chip(orderStatus(o))}${icon('right', 'i chev')}</a>`).join('')}</div>`).join('')}
        </div>`;
      }).join('');
    } catch (e) { box.innerHTML = errorState(e, 'runs'); }
  }
  el.addEventListener('click', e => { if (e.target.closest('[data-retry]')) load(); });
  load();
}
