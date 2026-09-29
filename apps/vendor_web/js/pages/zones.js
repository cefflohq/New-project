// Zones — list + detail (Founder reference 3). Counts come from real
// orders; zone management uses create/rename/set_zone_status.
import { t, fmtTime } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { fetchZones, fetchOrders, todayLocal, orderNo } from '../data.js';
import { esc, icon, chip, loadingRows, emptyState, errorState, gatedNote, toast, busy, modal } from '../ui.js';

const ONGOING = ['created', 'ready_for_pickup', 'picked_up', 'out_for_delivery', 'arrived'];

export default function zones({ el, params, setHeader }) {
  setHeader(t('zones.title'));
  const selected = params[0] || null;
  let query = '', sortAsc = true, zs = [], orders = [];
  el.innerHTML = `<div class="split ${selected ? '' : 'no-detail'}">
    <div class="card">
      <div class="bar pad">
        <button class="btn sm" data-add>${icon('plus')}${esc(t('zones.add'))}</button>
        <div class="search" style="margin-left:auto">${icon('search')}<input data-q placeholder="${esc(t('zones.search'))}" aria-label="${esc(t('c.search'))}"></div>
      </div>
      <div data-list>${loadingRows(8)}</div>
    </div>
    ${selected ? `<div class="card panel" data-detail>${loadingRows(6)}</div>` : ''}
  </div>`;
  const $ = s => el.querySelector(s);

  async function load() {
    try {
      const [z, o] = await Promise.all([fetchZones(), fetchOrders(`&order_date=eq.${todayLocal()}`)]);
      zs = z || []; orders = o || [];
      paint();
      if (selected) paintDetail();
    } catch (e) { $('[data-list]').innerHTML = errorState(e, 'zones'); }
  }
  const counts = id => {
    const mine = orders.filter(o => o.zone_id === id);
    return { mine, total: mine.length, completed: mine.filter(o => o.delivery_status === 'delivered').length, ongoing: mine.filter(o => ONGOING.includes(o.delivery_status)).length, issues: mine.filter(o => o.delivery_status === 'issue').length };
  };

  function paint() {
    const rows = zs.filter(z => !query || z.name.toLowerCase().includes(query)).sort((a, b) => (sortAsc ? 1 : -1) * a.name.localeCompare(b.name));
    $('[data-list]').innerHTML = rows.length ? `<div class="table-wrap"><table class="t">
      <thead><tr><th><button class="link-btn" data-sort style="text-decoration:none">${esc(t('zones.zone'))} ${sortAsc ? '▲' : '▼'}</button></th><th>${esc(t('zones.total'))}</th><th>${esc(t('zones.completed'))}</th><th>${esc(t('zones.ongoing'))}</th><th>${esc(t('zones.issues'))}</th><th>${esc(t('zones.status'))}</th><th></th></tr></thead>
      <tbody>${rows.map(z => { const c = counts(z.id); return `<tr class="row ${z.id === selected ? 'sel' : ''}" data-id="${esc(z.id)}">
        <td><b>${esc(z.name)}</b></td><td class="num">${c.total}</td><td class="num">${c.completed}</td><td class="num">${c.ongoing}</td>
        <td class="num" style="color:${c.issues ? 'var(--danger)' : 'inherit'}">${c.issues}</td><td>${chip(z.status === 'active' ? 'active' : 'inactive')}</td><td>${icon('right', 'i chev')}</td></tr>`; }).join('')}</tbody></table></div>`
      : emptyState(t('zones.none'), t('zones.noneBody'));
  }

  function paintDetail() {
    const box = $('[data-detail]');
    const z = zs.find(x => x.id === selected);
    if (!z) { box.innerHTML = emptyState(t('zones.none')); return; }
    const c = counts(z.id);
    const ongoing = c.mine.filter(o => ONGOING.includes(o.delivery_status));
    const done = c.mine.filter(o => o.delivery_status === 'delivered');
    const issues = c.mine.filter(o => o.delivery_status === 'issue');
    const row = o => `<a class="list-row" href="#/orders/${esc(o.id)}" style="color:inherit;text-decoration:none">${icon('pin')}<div class="grow"><b>${esc(orderNo(o))}</b><small>${esc(o.customer_name)}</small></div><small style="color:var(--muted)">${esc(fmtTime(o.updated_at))}</small>${icon('right', 'i chev')}</a>`;
    box.innerHTML = `
      <div class="panel-h"><h2>${esc(z.name)}</h2>${chip(z.status === 'active' ? 'active' : 'inactive')}
        <div style="margin-left:auto;position:relative"><button class="icon-btn" data-zmenu aria-haspopup="menu" aria-label="…">${icon('dots')}</button></div></div>
      <div class="boxed stats" style="margin:12px 0"><div class="stat"><b>${c.total}</b><span>${esc(t('zones.total'))}</span></div>
        <div class="stat"><b class="c-green">${c.completed}</b><span>${esc(t('zones.completed'))}</span></div>
        <div class="stat"><b class="c-blue">${c.ongoing}</b><span>${esc(t('zones.ongoing'))}</span></div>
        <div class="stat"><b class="c-red">${c.issues}</b><span>${esc(t('zones.issues'))}</span></div></div>
      <div class="sec"><h3>${esc(t('orders.rider'))}</h3>${gatedNote(t('zones.riderGated'))}</div>
      <div class="sec"><h3>${esc(t('zones.ongoingOrders', { n: ongoing.length }))}</h3>${ongoing.slice(0, 6).map(row).join('') || `<div class="hint">${esc(t('c.none'))}</div>`}</div>
      <div class="sec"><h3>${esc(t('zones.completedOrders', { n: done.length }))}</h3>${done.slice(0, 6).map(row).join('') || `<div class="hint">${esc(t('c.none'))}</div>`}</div>
      <div class="sec"><h3>${esc(t('zones.issuesOrders', { n: issues.length }))}</h3>${issues.slice(0, 6).map(row).join('') || `<div class="hint">${esc(t('c.none'))}</div>`}</div>
      <a class="btn" style="width:100%" href="#/orders">${esc(t('zones.viewAllOrders', { z: z.name }))} ${icon('right')}</a>`;
  }

  function zoneMenu(anchor) {
    document.querySelectorAll('.menu').forEach(m => m.remove());
    const z = zs.find(x => x.id === selected);
    const m = document.createElement('div');
    m.className = 'menu';
    m.innerHTML = `<button data-rename>${esc(t('zones.rename'))}</button><button data-toggle>${esc(t(z.status === 'active' ? 'zones.deactivate' : 'zones.activate'))}</button>`;
    m.addEventListener('click', async e => {
      e.stopPropagation(); m.remove();
      if (e.target.closest('[data-rename]')) nameDialog(t('zones.rename'), z.name, name => api.rpc('rename_zone', { p_zone_id: z.id, p_name: name }).then(() => toast(t('zones.renamed'))));
      if (e.target.closest('[data-toggle]')) { try { await api.rpc('set_zone_status', { p_zone_id: z.id, p_status: z.status === 'active' ? 'inactive' : 'active' }); load(); } catch (ex) { toast(ex.message, 'error'); } }
    });
    anchor.parentElement.append(m);
  }

  function nameDialog(title, value, action) {
    const m = modal({ title, body: `<div class="field"><label>${esc(t('zones.name'))}</label><input class="input" name="n" maxlength="80" value="${esc(value)}"></div><div class="err" data-err hidden></div>`,
      footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit>${esc(t('c.save'))}</button>` });
    m.el.querySelector('[data-submit]').addEventListener('click', async e => {
      const n = m.el.querySelector('[name=n]').value.trim(), err = m.el.querySelector('[data-err]');
      if (!n) { err.textContent = t('c.required'); err.hidden = false; return; }
      try { await busy(e.currentTarget, () => action(n)); m.close(); load(); } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    });
  }

  el.addEventListener('click', e => {
    if (e.target.closest('[data-sort]')) { sortAsc = !sortAsc; paint(); return; }
    const row = e.target.closest('tr[data-id]'); if (row) { location.hash = `#/zones/${row.dataset.id}`; return; }
    if (e.target.closest('[data-add]')) { nameDialog(t('zones.add'), '', name => api.rpc('create_zone', { p_business_id: ctx.bid, p_name: name }).then(() => toast(t('zones.created')))); return; }
    if (e.target.closest('[data-zmenu]')) { e.stopPropagation(); zoneMenu(e.target.closest('[data-zmenu]')); return; }
    if (e.target.closest('[data-retry]')) load();
  });
  $('[data-q]').addEventListener('input', e => { query = e.target.value.trim().toLowerCase(); paint(); });
  load();
}
