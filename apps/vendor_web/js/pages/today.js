// Today — operational overview (Founder reference 1).
import { t, fmtTime, ago } from '../i18n.js';
import { fetchOrders, fetchStops, fetchRiders, businessToday, orderNo } from '../data.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { mountPinsMap, hasPin } from '../map.js';
import { esc, icon, chip, orderStatus, itemsText, avatar, loadingRows, emptyState, errorState, gatedNote } from '../ui.js';
import { openAddOrder, openImport, openPlanDelivery } from './order_actions.js';
import { openAddRider } from './riders.js';
import { verificationBanner } from '../trust.js';
import { lineChart, wireCharts, barList, donut } from '../charts.js';

export default function today({ el, setHeader }) {
  setHeader(t('today.title'));
  let tab = 'all', query = '';
  // Dashboard (Founder 2026-10-17): a performance summary against yesterday,
  // a 14-day orders trend, today's status breakdown, drivers, what needs
  // attention and the live map, then recent orders. Charts are plain SVG.
  const card = (ic, tone, title, lead, body, extra = '') => `<section class="dc"><header class="dc-h"><span class="dc-ic ${tone}">${icon(ic)}</span><div><h2>${esc(title)}</h2>${lead ? `<p>${esc(lead)}</p>` : ''}</div>${extra}</header>${body}</section>`;
  el.innerHTML = `<div data-verify></div>
  <div class="dash">
    <div class="dash-bar">
      <div class="seg" role="tablist"><button class="on" role="tab" aria-selected="true">Overview</button><a href="#/orders" role="tab">Orders</a><a href="#/riders" role="tab">Drivers</a></div>
      <div class="dash-acts"><span class="dash-date" data-dashdate></span>
        <button class="btn" data-a="import">${esc(t('today.importOrders'))}</button>
        <button class="btn" data-a="plan">${esc(t('today.planDelivery'))}</button>
        <button class="btn" data-a="rider">${esc(t('today.addRider'))}</button>
        <button class="btn primary" data-a="add">${esc(t('today.addOrder'))}</button></div></div>
    ${card('route', 'blue', 'Performance summary', 'Today against yesterday.', '<div class="kpis2" data-overview>' + loadingRows(1) + '</div>')}
    <div class="dash-2">
      ${card('file', 'violet', 'Orders trend', 'Orders and deliveries over the last 14 days.', '<div data-trend>' + loadingRows(3) + '</div>')}
      ${card('box', 'amber', 'Order status', 'Where today\'s orders are now.', '<div data-status>' + loadingRows(3) + '</div>')}
    </div>
    <div class="dash-3">
      ${card('alert', 'red', t('today.attention'), 'Orders that need you now.', '<div data-attn>' + loadingRows(3) + '</div>', '<span data-attn-count></span><a class="link" href="#/orders">' + esc(t('c.viewAll')) + '</a>')}
      ${card('users', 'green', t('today.delivery'), 'Delivered against assigned, per driver.', '<div data-delivery>' + loadingRows(3) + '</div>', '<a class="link" href="#/riders">' + esc(t('c.viewAll')) + '</a>')}
      ${card('map', 'blue', 'Live map', '', '<div class="dc-map map-slot is-live"><div data-livemap></div></div><div class="map-legend" data-legend></div>')}
    </div>
    ${card('file', 'violet', t('today.recent'), '', '<div class="dc-tools"><div class="tabs" data-tabs></div><div class="search">' + icon('search') + '<input data-q placeholder="' + esc(t('today.searchOrders')) + '" aria-label="' + esc(t('c.search')) + '"></div></div><div data-recent>' + loadingRows(5) + '</div>', '<a class="link" href="#/orders">' + esc(t('c.viewAll')) + '</a>')}
  </div>`;
  // The dashboard bar replaces the page title block (Founder 2026-10-17).
  const mainEl = el.closest('.main'); mainEl?.classList.add('no-title');
  businessToday().then(d => { const n = $('[data-dashdate]'); if (n) n.textContent = new Date(`${d}T12:00:00Z`).toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short' }); });
  verificationBanner().then(h => { const v = el.querySelector('[data-verify]'); if (v) v.innerHTML = h; });

  let orders = [], hist = [], today = '', prep = new Map(), riders = new Map();
  const $ = s => el.querySelector(s);

  async function load() {
    try {
      const day = await businessToday();
      const from = new Date(new Date(`${day}T12:00:00Z`).getTime() - 13 * 86400000).toISOString().slice(0, 10);
      const [all, stops, rs] = await Promise.all([fetchOrders(`&order_date=gte.${from}`), fetchStops(), fetchRiders()]);
      hist = all || []; today = day;
      orders = hist.filter(o => o.order_date === day);
      prep = new Map((stops || []).map(s => [s.order_id, s.preparation_status]));
      riders = new Map((rs || []).map(r => [r.id, r]));
      paint();
      liveMap();
    } catch (e) {
      ['[data-recent]', '[data-overview]', '[data-delivery]', '[data-attn]', '[data-trend]', '[data-status]'].forEach(s => { $(s).innerHTML = errorState(e, 'today'); });
    }
  }
  // Live map (Founder 2026-10-12): today's pinned orders + the latest point
  // (<= 15 min old) of this business's drivers who have an order in
  // progress. latest_rider_locations is member-checked server-side.
  let liveMapObj = null, liveTimer = null;
  async function liveMap() {
    const box = $('[data-livemap]'); if (!box) return;
    const LIVE = ['picked_up', 'out_for_delivery', 'arrived'];
    const busy = new Set(orders.filter(o => LIVE.includes(o.delivery_status)).map(o => o.assigned_rider_id).filter(Boolean));
    let locs = [];
    try { locs = await api.rpc('latest_rider_locations', { p_business_id: ctx.bid }) || []; } catch { locs = []; }
    const fresh = locs.filter(l => busy.has(l.rider_id) && Date.now() - new Date(l.recorded_at).getTime() < 15 * 60000)
      .map(l => ({ lat: l.latitude, lng: l.longitude, name: riders.get(l.rider_id)?.name }));
    const drops = orders.filter(hasPin).map(o => ({ lat: Number(o.latitude), lng: Number(o.longitude),
      label: '', done: o.delivery_status === 'delivered' }));
    liveMapObj?.remove?.();
    box.innerHTML = '';
    liveMapObj = await mountPinsMap(box, drops, fresh);
    $('[data-legend]').textContent = t('today.mapLegend', { orders: drops.length, drivers: fresh.length });
    clearTimeout(liveTimer);
    liveTimer = setTimeout(() => { if (box.isConnected) liveMap(); }, 60000);
  }

  const st = o => orderStatus(o, prep.get(o.id));

  function paint() {
    const counts = { all: orders.length, ready: 0, ongoing: 0, issue: 0, delivered: 0 };
    orders.forEach(o => {
      const s = st(o);
      if (s === 'ready') counts.ready++;
      if (['ready', 'preparing', 'delivery', 'pending', 'unassigned'].includes(s)) counts.ongoing++;
      if (s === 'issue') counts.issue++;
      if (s === 'delivered') counts.delivered++;
    });
    // Performance summary: today against yesterday (same business day logic).
    const yday = new Date(new Date(`${today}T12:00:00Z`).getTime() - 86400000).toISOString().slice(0, 10);
    const yo = hist.filter(o => o.order_date === yday);
    const rate = list => list.length ? Math.round((list.filter(o => o.delivery_status === 'delivered').length / list.length) * 100) : 0;
    const kpi = (label, tone, now, before, unit = '', goodUp = true) => {
      const diff = before ? Math.round(((now - before) / before) * 100) : null;
      const good = diff === null ? null : (diff >= 0) === goodUp;
      return `<div class="kpi2 ${tone}"><span>${esc(label)}</span><small>Today</small><div><b>${now}${unit}</b>${diff === null ? '' : `<em class="${good ? 'up' : 'down'}">${diff >= 0 ? '↗' : '↘'} ${Math.abs(diff)}%</em>`}</div></div>`;
    };
    $('[data-overview]').innerHTML = kpi(t('today.total'), 'blue', counts.all, yo.length)
      + kpi(t('st.delivered'), 'green', counts.delivered, yo.filter(o => o.delivery_status === 'delivered').length)
      + kpi('Success rate', 'violet', rate(orders), rate(yo), '%')
      + kpi(t('today.issues'), 'red', counts.issue, yo.filter(o => o.delivery_status === 'issue').length, '', false);

    // Orders trend: last 14 business days.
    const days = [...Array(14)].map((_, i) => new Date(new Date(`${today}T12:00:00Z`).getTime() - (13 - i) * 86400000).toISOString().slice(0, 10));
    const per = d => hist.filter(o => o.order_date === d);
    $('[data-trend]').innerHTML = lineChart({ width: $('[data-trend]').clientWidth || 640, labels: days.map(d => new Date(`${d}T12:00:00Z`).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })),
      series: [{ key: 'o', name: 'Orders', color: '#3D63F5', fill: true, values: days.map(d => per(d).length) },
        { key: 'd', name: 'Delivered', color: '#22B07D', dashed: true, values: days.map(d => per(d).filter(o => o.delivery_status === 'delivered').length) }] })
      + '<div class="legend"><span><i style="background:#3D63F5"></i>Orders</span><span><i style="background:#22B07D"></i>Delivered</span></div>';
    wireCharts($('[data-trend]'));

    // Order status now.
    const by = k => orders.filter(o => st(o) === k).length;
    $('[data-status]').innerHTML = barList([
      { label: t('st.pending'), value: by('pending') + by('unassigned'), color: '#F5A524' },
      { label: t('st.preparing'), value: by('preparing'), color: '#8B6CF6' },
      { label: t('st.ready'), value: by('ready'), color: '#3D63F5' },
      { label: t('st.onDelivery'), value: by('delivery'), color: '#2BB5D8' },
      { label: t('st.delivered'), value: counts.delivered, color: '#22B07D' },
      { label: t('today.issues'), value: counts.issue, color: '#EF5A5A' }]);

    // Today's Delivery: every active rider, delivered / assigned today.
    const active = [...riders.values()].filter(r => r.status === 'active');
    const COLORS = ['#3D63F5', '#2BB5D8', '#22B07D', '#C46CF0', '#F5A524', '#EF5A5A'];
    const assigned = orders.filter(o => o.assigned_rider_id).length;
    $('[data-delivery]').innerHTML = active.length ? donut(active.map((r, i) => {
      const mine = orders.filter(o => o.assigned_rider_id === r.id);
      return { label: `${r.name}  ${mine.filter(o => o.delivery_status === 'delivered').length}/${mine.length}`, value: mine.length, color: COLORS[i % COLORS.length] };
    }), String(assigned), 'Assigned') : emptyState(t('today.noRiders'), t('today.noRidersBody'));

    // Need Attention: backend truth only (issues, failed geocode,
    // unapproved, approved-but-unassigned).
    const attn = [];
    orders.forEach(o => {
      if (o.delivery_status === 'issue') attn.push([o, 'red', 'alert', t('att.issue')]);
      else if (o.location_status === 'failed') attn.push([o, 'red', 'pin', t('att.locationFailed')]);
      else if (!o.approved_at && o.delivery_status === 'created') attn.push([o, 'amber', 'clock', t('att.notApproved')]);
      else if (o.approved_at && !o.assigned_rider_id && ['created', 'ready_for_pickup'].includes(o.delivery_status)) attn.push([o, 'amber', 'box', t('att.unassigned')]);
    });
    $('[data-attn-count]').innerHTML = attn.length ? `<span class="badge">${attn.length}</span>` : '';
    $('[data-attn]').innerHTML = attn.length ? attn.slice(0, 5).map(([o, tone, ic, why]) => `
      <a class="list-row" href="#/orders/${esc(o.id)}" style="color:inherit;text-decoration:none">
        <span class="att-ico ${tone}">${icon(ic)}</span><div class="grow"><b>${esc(orderNo(o))}</b><small>${esc(why)}</small></div>
        <small style="color:var(--muted)">${esc(ago(o.updated_at || o.created_at))}</small>${icon('right', 'i chev')}</a>`).join('')
      : emptyState(t('today.noAttention'));

    const tabs = [['all', 'today.all', counts.all], ['ready', 'st.ready', counts.ready], ['ongoing', 'today.ongoing', counts.ongoing], ['issue', 'today.issues', counts.issue], ['delivered', 'st.delivered', counts.delivered]];
    $('[data-tabs]').innerHTML = tabs.map(([id, key, n]) => `<button class="${tab === id ? 'on' : ''}" data-tab="${id}">${esc(t(key))} (${n})</button>`).join('');
    paintRecent();
  }

  function paintRecent() {
    const rows = orders.filter(o => {
      const s = st(o);
      if (tab === 'ready' && s !== 'ready') return false;
      if (tab === 'ongoing' && !['ready', 'preparing', 'delivery', 'pending', 'unassigned'].includes(s)) return false;
      if (tab === 'issue' && s !== 'issue') return false;
      if (tab === 'delivered' && s !== 'delivered') return false;
      if (query) {
        const hay = `${orderNo(o)} ${o.customer_name} ${o.delivery_address}`.toLowerCase();
        if (!hay.includes(query)) return false;
      }
      return true;
    }).slice(0, 8);
    $('[data-recent]').innerHTML = rows.length ? `<div class="table-wrap"><table class="t">
      <thead><tr><th>${esc(t('orders.id'))}</th><th>${esc(t('orders.customer'))}</th><th>${esc(t('orders.address'))}</th><th>${esc(t('orders.items'))}</th><th>${esc(t('orders.status'))}</th><th>${esc(t('orders.rider'))}</th><th>${esc(t('orders.time'))}</th><th></th></tr></thead>
      <tbody>${rows.map(o => {
        const r = riders.get(o.assigned_rider_id);
        return `<tr class="row" data-href="#/orders/${esc(o.id)}"><td><b>${esc(orderNo(o))}</b></td><td>${esc(o.customer_name)}</td>
        <td style="color:var(--muted)">${esc(o.delivery_address)}</td><td style="color:var(--muted)">${esc(itemsText(o.items))}</td><td>${chip(st(o))}</td>
        <td>${r ? `<span class="person">${avatar(r.name, 'sm')}${esc(r.name)}</span>` : esc(t('c.none'))}</td>
        <td class="num" style="color:var(--muted)">${esc(fmtTime(o.created_at))}</td><td>${icon('right', 'i chev')}</td></tr>`;
      }).join('')}</tbody></table></div>` : emptyState(t('orders.none'), t('orders.noneBody'));
  }

  el.addEventListener('click', e => {
    const tb = e.target.closest('[data-tab]');
    if (tb) { tab = tb.dataset.tab; paint(); return; }
    const row = e.target.closest('tr[data-href]');
    if (row) { location.hash = row.dataset.href; return; }
    if (e.target.closest('[data-retry]')) { load(); return; }
    const a = e.target.closest('[data-a]')?.dataset.a;
    if (a === 'add') openAddOrder(load);
    if (a === 'import') openImport(load);
    if (a === 'plan') openPlanDelivery(load);
    if (a === 'rider') openAddRider();
  });
  el.querySelector('[data-q]').addEventListener('input', e => { query = e.target.value.trim().toLowerCase(); paintRecent(); });
  load();
  const timer = setInterval(() => { if (document.visibilityState === 'visible') load(); }, 30000);
  return () => { clearInterval(timer); mainEl?.classList.remove('no-title'); };
}
