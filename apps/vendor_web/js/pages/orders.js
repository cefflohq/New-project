// Orders — list + detail panel (Founder reference 2).
import { t, fmtTime, ago } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { fetchOrders, fetchStops, fetchRiders, fetchZones, fetchOrder, fetchOrderEvents, fetchLocations, orderNo } from '../data.js';
import { esc, icon, chip, orderStatus, itemsText, itemsLines, avatar, loadingRows, emptyState, errorState, gatedNote, toast, busy, modal, phoneDigits } from '../ui.js';
import { openAddOrder } from './order_actions.js';

const PAGE = 12;
const COV_KEYS = ['unconfigured', 'pending_location', 'covered', 'out_of_coverage'];
const COV_ATTN = ['pending_location', 'out_of_coverage'];
// vendor_report_delivery_issue (Web SOT §10, S4-08): any operational member,
// from these statuses only; reasons are the delivery_issue_reason enum.
const ISSUE_FROM = ['created', 'ready_for_pickup', 'picked_up', 'out_for_delivery', 'arrived'];
const ISSUE_REASONS = ['customer_unreachable', 'address_problem', 'access_problem', 'vendor_not_ready', 'rider_unable_to_proceed'];

// initiate_delivery_recovery (Web SOT §2/§10, F2-09): Owner/Operator only;
// releases the order from its rider back to unassigned for re-planning.
const recoverable = o => !!o.assigned_rider_id && [...ISSUE_FROM, 'issue'].includes(o.delivery_status) && ctx.role !== 'helper';

function openReportIssue(orderId, onDone, recover = false) {
  let reason = '';
  const key = crypto.randomUUID();
  const m = modal({
    title: t(recover ? 'recover.title' : 'issue.title'), lead: t(recover ? 'recover.lead' : 'issue.lead'),
    body: `${ISSUE_REASONS.map(r => `<button class="opt" data-reason="${r}"><div><b>${esc(t(`issue.${r}`))}</b></div><span class="radio"></span></button>`).join('')}
      <div class="field"><label>${esc(t('issue.note'))}</label><textarea class="input" data-note rows="3" maxlength="500"></textarea></div>
      <div class="err" data-err hidden></div>`,
    footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit disabled>${esc(t(recover ? 'recover.submit' : 'issue.submit'))}</button>`,
  });
  const submit = m.el.querySelector('[data-submit]'), err = m.el.querySelector('[data-err]');
  m.el.addEventListener('click', async e => {
    const o = e.target.closest('[data-reason]');
    if (o) { reason = o.dataset.reason; m.el.querySelectorAll('[data-reason]').forEach(b => b.classList.toggle('on', b === o)); submit.disabled = false; return; }
    if (e.target.closest('[data-submit]') && reason) {
      err.hidden = true;
      const note = m.el.querySelector('[data-note]').value.trim();
      try {
        await busy(submit, () => recover
          ? api.rpc('initiate_delivery_recovery', { p_order_id: orderId, p_reason: reason, p_note: note, p_idempotency_key: key })
          : api.rpc('vendor_report_delivery_issue', { p_order_id: orderId, p_reason_type: reason, ...(note ? { p_note: note } : {}) }));
        m.close(); toast(t(recover ? 'recover.done' : 'issue.done')); onDone?.();
      } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    }
  });
}

export default function orders({ el, params, setHeader }) {
  setHeader(t('orders.title'));
  const selected = params[0] || null;
  let tab = 'ongoing', query = '', page = 1, zoneFilter = '', riderFilter = '';
  let list = [], prep = new Map(), riders = new Map(), zones = new Map(), locs = new Map();
  el.innerHTML = `<div class="split ${selected ? '' : 'no-detail'}">
    <div class="card">
      <div class="bar">
        <div class="tabs" data-tabs></div>
        <button class="btn sm" data-add aria-label="${esc(t('today.addOrder'))}" title="${esc(t('today.addOrder'))}">${icon('plus')}</button>
        <div class="search">${icon('search')}<input data-q placeholder="${esc(t('today.searchOrders'))}" aria-label="${esc(t('c.search'))}"></div>
        <div style="position:relative"><button class="btn sm" data-filter aria-haspopup="true" title="${esc(t('orders.filter'))}">${icon('filter')}</button></div>
      </div>
      <div data-list>${loadingRows(8)}</div>
    </div>
    ${selected ? '<div class="card panel" data-detail>' + loadingRows(6) + '</div>' : ''}
  </div>`;
  const $ = s => el.querySelector(s);

  async function load() {
    if (!el.isConnected) return; // page was left while a modal was saving
    try {
      const [o, s, r, z, l] = await Promise.all([fetchOrders(), fetchStops(), fetchRiders(), fetchZones(), fetchLocations()]);
      list = o || [];
      prep = new Map((s || []).map(x => [x.order_id, x.preparation_status]));
      riders = new Map((r || []).map(x => [x.id, x]));
      zones = new Map((z || []).map(x => [x.id, x]));
      locs = new Map((l || []).map(x => [x.rider_id, x]));
      if (el.isConnected) paint();
    } catch (e) { if (el.isConnected) $('[data-list]').innerHTML = errorState(e, 'orders'); }
  }
  const st = o => orderStatus(o, prep.get(o.id));
  const inTab = (o, tb) => {
    const s = st(o);
    if (tb === 'ongoing') return ['ready', 'preparing', 'delivery', 'pending', 'unassigned'].includes(s);
    if (tb === 'issue') return s === 'issue';
    return s === 'delivered';
  };
  const liveRider = id => { const l = locs.get(id); return l && Date.now() - new Date(l.recorded_at).getTime() < 5 * 60000; };

  function paint() {
    const counts = { ongoing: 0, issue: 0, delivered: 0 };
    list.forEach(o => Object.keys(counts).forEach(k => { if (inTab(o, k)) counts[k]++; }));
    $('[data-tabs]').innerHTML = [['ongoing', 'today.ongoing'], ['issue', 'today.issues'], ['delivered', 'st.delivered']]
      .map(([id, key]) => `<button class="${tab === id ? 'on' : ''}" data-tab="${id}">${esc(t(key))}<span class="count">${counts[id]}</span></button>`).join('');
    const rows = list.filter(o => inTab(o, tab)
      && (!zoneFilter || o.zone_id === zoneFilter) && (!riderFilter || o.assigned_rider_id === riderFilter)
      && (!query || `${orderNo(o)} ${o.customer_name} ${o.customer_phone}`.toLowerCase().includes(query)));
    const pages = Math.max(1, Math.ceil(rows.length / PAGE));
    page = Math.min(page, pages);
    const slice = rows.slice((page - 1) * PAGE, page * PAGE);
    $('[data-list]').innerHTML = rows.length ? `<div class="table-wrap"><table class="t">
      <thead><tr><th>${esc(t('orders.id'))}</th><th>${esc(t('orders.customer'))}</th><th>${esc(t('orders.items'))}</th><th>${esc(t('orders.status'))}</th><th>${esc(t('orders.rider'))}</th><th>${esc(t('orders.updated'))}</th><th></th></tr></thead>
      <tbody>${slice.map(o => {
        const r = riders.get(o.assigned_rider_id);
        return `<tr class="row ${o.id === selected ? 'sel' : ''}" data-id="${esc(o.id)}"><td><b>${esc(orderNo(o))}</b></td>
          <td>${esc(o.customer_name)}<span class="sub">${esc(o.customer_phone)}</span></td><td style="color:var(--muted)">${esc(itemsText(o.items))}</td>
          <td>${chip(st(o))}</td>
          <td>${r ? `<span class="person">${avatar(r.name, 'sm')}<span>${esc(r.name)}${liveRider(r.id) ? `<span class="sub live"><i class="dot"></i>${esc(t('st.live'))}</span>` : ''}</span></span>` : esc(t('c.none'))}</td>
          <td class="num" style="color:var(--muted)">${esc(fmtTime(o.updated_at))}</td><td>${icon('right', 'i chev')}</td></tr>`;
      }).join('')}</tbody></table></div>
      <div class="pager"><span>${esc(t('c.showing', { n: slice.length }))}</span><div class="pages">
        <button data-page="${page - 1}" ${page === 1 ? 'disabled' : ''} aria-label="prev">${icon('left')}</button>
        ${Array.from({ length: pages }, (_, i) => `<button data-page="${i + 1}" class="${i + 1 === page ? 'on' : ''}">${i + 1}</button>`).join('')}
        <button data-page="${page + 1}" ${page === pages ? 'disabled' : ''} aria-label="next">${icon('right')}</button></div></div>`
      : emptyState(t('orders.none'), t('orders.noneBody'));
  }

  function openFilter(anchor) {
    document.querySelectorAll('.menu').forEach(m => m.remove());
    const m = document.createElement('div');
    m.className = 'menu';
    m.style.padding = '12px';
    m.innerHTML = `<div class="field"><label>${esc(t('add.zone'))}</label><select class="select" data-fz><option value="">—</option>${[...zones.values()].map(z => `<option value="${esc(z.id)}" ${z.id === zoneFilter ? 'selected' : ''}>${esc(z.name)}</option>`).join('')}</select></div>
      <div class="field" style="margin-top:10px"><label>${esc(t('orders.rider'))}</label><select class="select" data-fr><option value="">—</option>${[...riders.values()].map(r => `<option value="${esc(r.id)}" ${r.id === riderFilter ? 'selected' : ''}>${esc(r.name)}</option>`).join('')}</select></div>`;
    m.addEventListener('change', () => { zoneFilter = m.querySelector('[data-fz]').value; riderFilter = m.querySelector('[data-fr]').value; page = 1; paint(); });
    m.addEventListener('click', e => e.stopPropagation());
    anchor.parentElement.append(m);
  }

  el.addEventListener('click', e => {
    const tb = e.target.closest('[data-tab]'); if (tb) { tab = tb.dataset.tab; page = 1; paint(); return; }
    const pg = e.target.closest('[data-page]'); if (pg && !pg.disabled) { page = Number(pg.dataset.page); paint(); return; }
    const row = e.target.closest('tr[data-id]'); if (row) { location.hash = `#/orders/${row.dataset.id}`; return; }
    if (e.target.closest('[data-add]')) { openAddOrder(load); return; }
    if (e.target.closest('[data-filter]')) { e.stopPropagation(); openFilter(e.target.closest('[data-filter]')); return; }
    if (e.target.closest('[data-retry]')) load();
  });
  $('[data-q]').addEventListener('input', e => { query = e.target.value.trim().toLowerCase(); page = 1; paint(); });

  load();
  if (selected) renderDetail(el.querySelector('[data-detail]'), selected, () => { load(); });
  const timer = setInterval(() => { if (document.visibilityState === 'visible') load(); }, 30000);
  return () => clearInterval(timer);
}

// ------------------------------------------------------------------ detail
export async function renderDetail(box, id, onChange) {
  const paint = async () => {
    try {
      const [o, events, rs, stops, ls, cov] = await Promise.all([fetchOrder(id), fetchOrderEvents(id), fetchRiders(), fetchStops(), fetchLocations(),
        // Server verdict (order_coverage_status); a failed lookup shows unknown, never a guess.
        api.rpc('order_coverage_status', { p_order_id: id }).catch(() => 'unknown')]);
      if (!o) { box.innerHTML = emptyState(t('orders.none')); return; }
      const rider = (rs || []).find(r => r.id === o.assigned_rider_id);
      const prepSt = (stops || []).find(s => s.order_id === o.id)?.preparation_status;
      const s = orderStatus(o, prepSt);
      const at = st2 => (events || []).filter(e => e.to_status === st2).pop()?.created_at;
      const steps = [['picked_up', t('orders.pickedUp')], ['out_for_delivery', t('orders.onTheWay')], ['arrived', t('orders.arrived')], ['delivered', t('orders.deliveredStep')]];
      const order = ['created', 'ready_for_pickup', 'picked_up', 'out_for_delivery', 'arrived', 'delivered'];
      const cur = order.indexOf(o.delivery_status);
      const loc = rider && (ls || []).find(l => l.rider_id === rider.id);
      const lines = itemsLines(o.items);
      const digits = phoneDigits(o.customer_phone);
      box.innerHTML = `
        <div class="panel-h"><h2>${esc(orderNo(o))}</h2>${chip(s)}<button class="icon-btn" style="margin-left:auto" data-close-detail aria-label="${esc(t('c.close'))}">${icon('x')}</button></div>
        <div class="sec" style="display:flex;align-items:center;gap:10px">
          <div style="flex:1"><b style="font-size:15px">${esc(o.customer_name)}</b><div class="hint">${esc(o.customer_phone)}</div></div>
          ${digits ? `<a class="round-btn" href="tel:${esc(o.customer_phone)}" aria-label="${esc(t('c.call'))}">${icon('phone')}</a><a class="round-btn wa" href="https://wa.me/${esc(digits.replace(/^0/, '60'))}" target="_blank" rel="noopener" aria-label="WhatsApp">${icon('wa')}</a>` : ''}
        </div>
        <a class="sec kv" href="https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(o.latitude != null ? `${o.latitude},${o.longitude}` : o.delivery_address)}" target="_blank" rel="noopener" style="color:inherit;text-decoration:none;border-bottom:0">
          <span style="color:var(--primary)">${icon('pin')}</span><div style="flex:1"><b style="margin:0">${esc(o.delivery_address)}</b></div>${icon('right', 'i chev')}</a>
        <div class="sec kv" style="border-bottom:0"><span style="color:var(--primary)">${icon('map')}</span><div style="flex:1"><b style="margin:0">${esc(t('cov.title'))}</b></div><span class="chip ${COV_ATTN.includes(cov) ? 'issue' : cov === 'covered' ? 'active' : 'neutral'}">${esc(t(`cov.${COV_KEYS.includes(cov) ? cov : 'unknown'}`))}</span></div>
        ${o.delivery_status === 'created' && !o.assigned_rider_id ? `<div class="sec" style="display:flex;gap:10px"><button class="btn sm" data-edit>${esc(t('edit.action'))}</button>${!o.approved_at ? `<button class="btn primary sm" data-approve>${esc(t('orders.approve'))}</button>` : ''}</div>` : ''}
        ${ISSUE_FROM.includes(o.delivery_status) || recoverable(o) ? `<div class="sec" style="display:flex;gap:10px;flex-wrap:wrap">
          ${ISSUE_FROM.includes(o.delivery_status) ? `<button class="btn sm" data-report-issue>${icon('alert')}${esc(t('issue.report'))}</button>` : ''}
          ${recoverable(o) ? `<button class="btn sm" data-recover>${esc(t('recover.action'))}</button>` : ''}</div>` : ''}
        <div class="sec"><h3>${esc(t('orders.liveStatus'))}</h3><div class="timeline">
          ${steps.map(([k, label], i) => {
            const idx = order.indexOf(k);
            const done = cur > idx || (k === 'delivered' && cur === idx);
            const now = cur === idx && k !== 'delivered';
            return `<div class="tl ${done ? 'done' : ''} ${now ? 'now' : ''}"><span class="mk"></span><div><b style="font-weight:500">${esc(label)}</b>
              ${now && k === 'out_for_delivery' && rider ? `<small>${esc(t('orders.enRoute', { r: rider.name }))}</small>` : ''}
              ${now && loc && i < 3 ? `<div class="sub-card" style="margin:8px 0 0;padding:10px 12px;background:var(--primary-tint);border:0"><small>${esc(t('orders.currentLocation'))}</small><b style="font-weight:600">${esc(t('orders.lastSeen', { t: ago(loc.recorded_at) }))}</b>${o.estimated_arrival_at ? `<small>${esc(t('orders.eta', { t: fmtTime(o.estimated_arrival_at) }))}</small>` : ''}</div>` : ''}
              </div><time>${esc(fmtTime(at(k)) || '-')}</time></div>`;
          }).join('')}
          ${!rider ? `<div class="hint">${esc(t('orders.noRiderYet'))}</div>` : ''}
        </div></div>
        <div class="sec"><h3>${esc(t('orders.itemsCount', { n: lines.length }))}</h3>
          ${lines.map(l => `<div class="kv"><span class="avatar sm" style="border-radius:10px">${icon('pkg')}</span><div style="flex:1"><b style="margin:0">${esc(l.name)}</b><small>${l.qty} ×</small></div></div>`).join('') || `<div class="hint">${esc(t('c.none'))}</div>`}
          <div style="margin-top:12px">${gatedNote(t('orders.priceGated'))}</div></div>`;
    } catch (e) { box.innerHTML = errorState(e); }
  };
  box.addEventListener('click', async e => {
    if (e.target.closest('[data-close-detail]')) { location.hash = '#/orders'; return; }
    const ap = e.target.closest('[data-approve]');
    if (ap) {
      try { await busy(ap, () => api.rpc('approve_order', { p_order_id: id })); toast(t('orders.approved')); onChange?.(); paint(); } catch (ex) { toast(ex.message, 'error'); }
    }
    if (e.target.closest('[data-edit]')) { fetchOrder(id).then(o => o && openAddOrder(() => { onChange?.(); paint(); }, o)); return; }
    if (e.target.closest('[data-recover]')) { openReportIssue(id, () => { onChange?.(); paint(); }, true); return; }
    if (e.target.closest('[data-report-issue]')) { openReportIssue(id, () => { onChange?.(); paint(); }); return; }
  });
  void ctx; void modal;
  await paint();
}
