// Active Runs — the business's open delivery runs, with a summary row
// (Founder reference: Active Runs).
import { t, fmtTime, fmtDate } from '../i18n.js';
import { fetchSessions, fetchOrders, fetchRiders, orderNo } from '../data.js';
import { esc, icon, avatar, chip, orderStatus, loadingRows, emptyState, errorState } from '../ui.js';

export default function runs({ el, setHeader }) {
  setHeader(t('runs.title'));
  el.innerHTML = `<div class="kpis" data-kpis>${['route', 'box', 'check', 'clock'].map(() => '<div class="kpi"><div class="skel" style="height:56px"></div></div>').join('')}</div>
    <div class="card"><div data-list>${loadingRows(6)}</div></div>`;
  const box = el.querySelector('[data-list]'), kpis = el.querySelector('[data-kpis]');
  // Summary of the open runs (Founder reference: Active Runs). A run is one
  // rider's share of an open delivery session.
  function paintKpis(open, os) {
    const ids = new Set(open.map(s => s.id));
    const mine = (os || []).filter(o => ids.has(o.delivery_session_id) && o.delivery_status !== 'cancelled');
    const runs = new Set(mine.filter(o => o.assigned_rider_id).map(o => `${o.delivery_session_id}:${o.assigned_rider_id}`)).size;
    const done = mine.filter(o => o.delivery_status === 'delivered').length;
    const tile = (n, key, ic, tone) => `<div class="kpi ${tone}"><div><b>${n}</b><span>${esc(t(key))}</span></div><span class="kpi-ico">${icon(ic)}</span></div>`;
    kpis.innerHTML = tile(runs, 'runs.kActive', 'route', 'blue') + tile(mine.length, 'runs.kTotal', 'box', 'amber')
      + tile(done, 'runs.kDone', 'check', 'green') + tile(mine.length - done, 'runs.kOngoing', 'clock', 'red');
  }
  async function load() {
    try {
      const [ss, os, rs] = await Promise.all([fetchSessions(), fetchOrders(), fetchRiders()]);
      const riders = new Map((rs || []).map(r => [r.id, r]));
      const open = (ss || []).filter(s => ['planned', 'active'].includes(s.status));
      paintKpis(open, os);
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
    } catch (e) { box.innerHTML = errorState(e, 'runs'); kpis.hidden = true; }
  }
  el.addEventListener('click', e => { if (e.target.closest('[data-retry]')) load(); });
  load();
}
