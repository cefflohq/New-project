// Today — operational overview (Founder reference 1).
import { t, fmtTime, ago } from '../i18n.js';
import { fetchOrders, fetchStops, fetchRiders, todayLocal, orderNo } from '../data.js';
import { esc, icon, chip, orderStatus, itemsText, avatar, loadingRows, emptyState, errorState, gatedNote } from '../ui.js';
import { openAddOrder, openImport, openPlanDelivery } from './order_actions.js';
import { openAddRider } from './riders.js';

export default function today({ el, setHeader }) {
  setHeader(t('today.title'));
  let tab = 'all', query = '';
  el.innerHTML = `
  <div class="grid-today">
    <div class="stack">
      <div class="card map-slot">
        <div>
          <div class="state" style="padding:0"><div class="ico">${icon('map')}</div><h3>${esc(t('today.mapTitle'))}</h3></div>
          ${gatedNote(t('today.mapGated'))}
        </div>
      </div>
      <div class="actions">
        <button class="btn cta" data-a="add">${icon('plus')}${esc(t('today.addOrder'))}</button>
        <button class="btn" data-a="import">${icon('upload')}${esc(t('today.importOrders'))}</button>
        <button class="btn" data-a="plan">${icon('plan')}${esc(t('today.planDelivery'))}</button>
        <button class="btn" data-a="rider">${icon('user')}${esc(t('today.addRider'))}</button>
      </div>
      <div class="card">
        <div class="card-h"><h2>${esc(t('today.recent'))}</h2>
          <div class="search" style="margin-left:auto">${icon('search')}<input data-q placeholder="${esc(t('today.searchOrders'))}" aria-label="${esc(t('c.search'))}"></div>
          <a class="link" href="#/orders">${esc(t('c.viewAll'))}</a></div>
        <div class="tabs" data-tabs></div>
        <div data-recent>${loadingRows(5)}</div>
      </div>
    </div>
    <div class="stack">
      <div class="card"><div class="card-h"><h2>${esc(t('today.overview'))}</h2><a class="link" href="#/orders">${esc(t('c.viewAll'))}</a></div><div class="card-b" data-overview>${loadingRows(1)}</div></div>
      <div class="card"><div class="card-h"><h2>${esc(t('today.delivery'))}</h2><a class="link" href="#/riders">${esc(t('c.viewAll'))}</a></div><div class="card-b" data-delivery>${loadingRows(3)}</div></div>
      <div class="card"><div class="card-h"><h2>${esc(t('today.attention'))}</h2><span data-attn-count></span><a class="link" href="#/orders">${esc(t('c.viewAll'))}</a></div><div class="card-b" data-attn>${loadingRows(3)}</div></div>
    </div>
  </div>`;

  let orders = [], prep = new Map(), riders = new Map();
  const $ = s => el.querySelector(s);

  async function load() {
    try {
      const [o, stops, rs] = await Promise.all([fetchOrders(`&order_date=eq.${todayLocal()}`), fetchStops(), fetchRiders()]);
      orders = o || [];
      prep = new Map((stops || []).map(s => [s.order_id, s.preparation_status]));
      riders = new Map((rs || []).map(r => [r.id, r]));
      paint();
    } catch (e) {
      ['[data-recent]', '[data-overview]', '[data-delivery]', '[data-attn]'].forEach(s => { $(s).innerHTML = errorState(e, 'today'); });
    }
  }
  const st = o => orderStatus(o, prep.get(o.id));

  function paint() {
    const counts = { all: orders.length, ready: 0, ongoing: 0, issue: 0, delivered: 0 };
    orders.forEach(o => {
      const s = st(o);
      if (s === 'ready') counts.ready++;
      if (['ready', 'preparing', 'delivery'].includes(s)) counts.ongoing++;
      if (s === 'issue') counts.issue++;
      if (s === 'delivered') counts.delivered++;
    });
    $('[data-overview]').innerHTML = `<div class="stats">
      <div class="stat"><b class="c-blue">${counts.all}</b><span>${esc(t('today.total'))}</span></div>
      <div class="stat"><b class="c-amber">${counts.ready}</b><span>${esc(t('st.ready'))}</span></div>
      <div class="stat"><b class="c-red">${counts.issue}</b><span>${esc(t('today.issues'))}</span></div>
      <div class="stat"><b class="c-green">${counts.delivered}</b><span>${esc(t('st.delivered'))}</span></div></div>`;

    // Today's Delivery: every active rider, delivered / assigned today.
    const active = [...riders.values()].filter(r => r.status === 'active');
    $('[data-delivery]').innerHTML = active.length ? active.map(r => {
      const mine = orders.filter(o => o.assigned_rider_id === r.id);
      const done = mine.filter(o => o.delivery_status === 'delivered').length;
      const onRoad = mine.some(o => st(o) === 'delivery');
      const pct = mine.length ? Math.round((done / mine.length) * 100) : 0;
      return `<a class="list-row" href="#/riders/${esc(r.id)}" style="color:inherit;text-decoration:none">
        ${avatar(r.name)}<div style="min-width:130px"><b>${esc(r.name)}</b><small><span class="live" style="color:${onRoad ? 'var(--success)' : 'var(--faint)'}"><i class="dot"></i>${esc(onRoad ? t('st.onDelivery') : t(r.availability_status === 'online' ? 'st.online' : 'st.offline'))}</span></small></div>
        <div class="grow"><div class="progress"><i style="width:${pct}%"></i></div></div>
        <span class="num" style="min-width:44px;text-align:right">${done} / ${mine.length}</span>${icon('right', 'i chev')}</a>`;
    }).join('') : emptyState(t('today.noRiders'), t('today.noRidersBody'));

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
      if (tab === 'ongoing' && !['ready', 'preparing', 'delivery'].includes(s)) return false;
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
  return () => clearInterval(timer);
}
