// Zones — list + detail (Founder reference 3). Counts come from real
// orders; zone management uses create/rename/set_zone_status.
import { t, fmtTime } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { country } from '../country.js';
import { fetchZones, fetchOrders, fetchZoneCells, businessToday, orderNo } from '../data.js';
import { mountPinsMap, mountZoneDrawer, mountHexMap, hasPin, zoneColor } from '../map.js';
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
        <a class="btn sm" href="#/runs">${icon('route')}${esc(t('nav.runs'))}</a>
        <button class="btn sm" data-hex>${icon('map')}${esc(t('zones.hexMap'))}</button>
        <div class="search" style="margin-left:auto">${icon('search')}<input data-q placeholder="${esc(t('zones.search'))}" aria-label="${esc(t('c.search'))}"></div>
      </div>
      <div style="padding:0 16px 12px"><div data-zmap></div></div>
      <div data-list>${loadingRows(8, t('ld.zones'))}</div>
    </div>
    ${selected ? `<div class="card panel" data-detail>${loadingRows(6, t('ld.zones'))}</div>` : ''}
  </div>`;
  const $ = s => el.querySelector(s);

  async function load() {
    try {
      const [z, o] = await Promise.all([fetchZones(), businessToday().then(d => fetchOrders(`&order_date=eq.${d}`))]);
      zs = z || []; orders = o || [];
      paint();
      mountPinsMap($('[data-zmap]'), drops(orders), [], zs.filter(z => z.status === 'active'));
      if (selected) paintDetail();
    } catch (e) { $('[data-list]').innerHTML = errorState(e, 'zones'); }
  }
  const counts = id => {
    const mine = orders.filter(o => o.zone_id === id);
    return { mine, total: mine.length, completed: mine.filter(o => o.delivery_status === 'delivered').length, ongoing: mine.filter(o => ONGOING.includes(o.delivery_status)).length, issues: mine.filter(o => o.delivery_status === 'issue').length };
  };

  // Pinned orders as map drops; zones with a drawn boundary show as shapes.
  const drops = list => list.filter(o => hasPin(o) && o.delivery_status !== 'cancelled')
    .map(o => ({ lat: +o.latitude, lng: +o.longitude, done: o.delivery_status === 'delivered' }));

  function paint() {
    const rows = zs.filter(z => !query || z.name.toLowerCase().includes(query)).sort((a, b) => (sortAsc ? 1 : -1) * a.name.localeCompare(b.name));
    $('[data-list]').innerHTML = rows.length ? `<div class="table-wrap"><table class="t">
      <thead><tr><th><button class="link-btn" data-sort style="text-decoration:none">${esc(t('zones.zone'))} ${sortAsc ? '▲' : '▼'}</button></th><th>${esc(t('zones.total'))}</th><th>${esc(t('zones.completed'))}</th><th>${esc(t('zones.ongoing'))}</th><th>${esc(t('zones.issues'))}</th><th>${esc(t('zones.status'))}</th><th></th></tr></thead>
      <tbody>${rows.map(z => { const c = counts(z.id); return `<tr class="row ${z.id === selected ? 'sel' : ''}" data-id="${esc(z.id)}">
        <td style="white-space:nowrap">${z.boundary && z.status === 'active' ? `<span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${zoneColor(z)};margin-right:8px"></span>` : ''}<b>${esc(z.name)}</b></td><td class="num">${c.total}</td><td class="num">${c.completed}</td><td class="num">${c.ongoing}</td>
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
      <div data-dmap style="margin-bottom:12px"></div>
      <div class="sec"><h3>${esc(t('orders.rider'))}</h3>${gatedNote(t('zones.riderGated'))}</div>
      <div class="sec"><h3>${esc(t('zones.ongoingOrders', { n: ongoing.length }))}</h3>${ongoing.slice(0, 6).map(row).join('') || `<div class="hint">${esc(t('c.none'))}</div>`}</div>
      <div class="sec"><h3>${esc(t('zones.completedOrders', { n: done.length }))}</h3>${done.slice(0, 6).map(row).join('') || `<div class="hint">${esc(t('c.none'))}</div>`}</div>
      <div class="sec"><h3>${esc(t('zones.issuesOrders', { n: issues.length }))}</h3>${issues.slice(0, 6).map(row).join('') || `<div class="hint">${esc(t('c.none'))}</div>`}</div>
      <a class="btn" style="width:100%" href="#/orders">${esc(t('zones.viewAllOrders', { z: z.name }))} ${icon('right')}</a>`;
    mountPinsMap(box.querySelector('[data-dmap]'), drops(c.mine), [], [z]);
  }

  function zoneMenu(anchor) {
    document.querySelectorAll('.menu').forEach(m => m.remove());
    const z = zs.find(x => x.id === selected);
    const m = document.createElement('div');
    m.className = 'menu';
    m.innerHTML = `<button data-rename>${esc(t('zones.rename'))}</button><button data-draw>${esc(t(z.boundary ? 'zones.editBoundary' : 'zones.drawBoundary'))}</button><button data-toggle>${esc(t(z.status === 'active' ? 'zones.deactivate' : 'zones.activate'))}</button><button data-delete style="color:var(--danger)">${esc(t('zones.delete'))}</button>`;
    m.addEventListener('click', async e => {
      e.stopPropagation(); m.remove();
      if (e.target.closest('[data-draw]')) boundaryDialog(z);
      if (e.target.closest('[data-delete]')) deleteDialog(z);
      if (e.target.closest('[data-rename]')) nameDialog(t('zones.rename'), z.name, (name, place) => api.rpc('rename_zone', { p_zone_id: z.id, p_name: name }).then(r => outline(r, place)).then(() => toast(t('zones.renamed'))));
      if (e.target.closest('[data-toggle]')) { try { await api.rpc('set_zone_status', { p_zone_id: z.id, p_status: z.status === 'active' ? 'inactive' : 'active' }); load(); } catch (ex) { toast(ex.message, 'error'); } }
    });
    anchor.parentElement.append(m);
  }

  // Auto outline: the zone name is looked up on the map (zone-boundary Edge
  // Function) so the vendor never has to draw. Best effort; a name that is not
  // a place simply stays without a boundary.
  const outline = (row, place) => {
    const id = Array.isArray(row) ? row[0]?.id : row?.id;
    if (!id) return null;
    // Then the hexagon cells of the coverage are re-laid (zone-cells).
    return api.fn('zone-boundary', { zone_id: id, ...(place ? { center: place.center } : {}) }).catch(() => null)
      .then(res => { api.fn('zone-cells', { business_id: ctx.bid }).catch(() => null); return res; });
  };

  // Hexagon map (Auto Zone D1/D4): paint cells onto a zone. Changes are kept
  // locally until Save, then sent per target zone (paint_zone_cells).
  async function hexDialog() {
    const active = zs.filter(z => z.status === 'active');
    const m = modal({ title: t('zones.hexMap'), lead: t('zones.hexLead'), cls: 'hex-modal',
      body: `<div class="hex-brush" data-brush></div><div data-hexmap>${loadingRows(4, t('ld.zones'))}</div><div class="hint" data-pending></div><div class="err" data-err hidden></div>`,
      footer: `<button class="btn" data-build style="margin-right:auto">${esc(t('zones.hexRebuild'))}</button><button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit disabled>${esc(t('c.save'))}</button>` });
    const q = s => m.el.querySelector(s), err = q('[data-err]');
    let brush = active[0]?.id || null, hex = null;
    const pending = new Map(), current = new Map();
    const showErr = ex => { err.textContent = ex.message; err.hidden = false; };
    const paintBrush = () => {
      q('[data-brush]').innerHTML = [...active.map(z => ({ id: z.id, name: z.name, color: zoneColor(z) })), { id: null, name: t('zones.hexNoZone'), color: '#9AA3B2' }]
        .map(b => `<button type="button" data-b="${esc(b.id || '')}" class="${b.id === brush ? 'on' : ''}"><i style="background:${b.color}"></i>${esc(b.name)}</button>`).join('');
    };
    const paintPending = () => {
      q('[data-pending]').textContent = pending.size ? t('zones.hexPending', { n: pending.size }) : '';
      q('[data-submit]').disabled = !pending.size;
      hex?.setPending(pending);
    };
    const open = async () => {
      const cells = await fetchZoneCells();
      if (!cells.length) {
        q('[data-hexmap]').innerHTML = emptyState(t('zones.hexNone'));
        q('[data-build]').textContent = t('zones.hexBuild');
        return;
      }
      current.clear(); cells.forEach(c => current.set(c.cell, c.zone_id || null));
      hex = await mountHexMap(q('[data-hexmap]'), cells, active, {
        onCell: cell => {
          if (current.get(cell) === brush) pending.delete(cell); else pending.set(cell, brush);
          paintPending();
        },
      });
    };
    paintBrush();
    q('[data-brush]').addEventListener('click', e => {
      const b = e.target.closest('[data-b]'); if (!b) return;
      brush = b.dataset.b || null; paintBrush();
    });
    q('[data-build]').addEventListener('click', async e => {
      err.hidden = true;
      try {
        const res = await busy(e.currentTarget, () => api.fn('zone-cells', { business_id: ctx.bid }));
        if (res?.status === 'no_service_area') return;
        toast(t('zones.hexBuilt', { n: res?.cells ?? 0 }));
        pending.clear(); paintPending(); await open();
      } catch (ex) { showErr(ex); }
    });
    q('[data-submit]').addEventListener('click', async e => {
      err.hidden = true;
      const byZone = new Map();
      pending.forEach((z, c) => { const k = z || ''; byZone.set(k, [...(byZone.get(k) || []), c]); });
      try {
        await busy(e.currentTarget, async () => {
          for (const [z, list] of byZone) await api.rpc('paint_zone_cells', { p_business_id: ctx.bid, p_cells: list, p_zone_id: z || null });
        });
        pending.forEach((z, c) => current.set(c, z));
        hex?.commit(pending); pending.clear(); paintPending();
        toast(t('zones.hexSaved')); load();
      } catch (ex) { showErr(ex); }
    });
    try { await open(); } catch (ex) { q('[data-hexmap]').innerHTML = ''; showErr(ex); }
  }

  // Delete zone (Founder 2026-10-13): leaves the list, row kept for history.
  function deleteDialog(z) {
    const m = modal({ title: t('zones.delete'), body: `<p>${esc(t('zones.deleteBody'))}</p><div class="err" data-err hidden></div>`,
      footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn danger-soft" data-submit>${esc(t('zones.delete'))}</button>` });
    m.el.querySelector('[data-submit]').addEventListener('click', async e => {
      const err = m.el.querySelector('[data-err]');
      try { await busy(e.currentTarget, () => api.rpc('delete_zone', { p_zone_id: z.id })); m.close(); toast(t('zones.deleted')); location.hash = '#/zones'; load(); }
      catch (ex) { err.textContent = ex.message; err.hidden = false; }
    });
  }

  function boundaryDialog(z) {
    const m = modal({ title: t(z.boundary ? 'zones.editBoundary' : 'zones.drawBoundary'),
      body: `<p class="hint" style="margin-bottom:10px">${esc(t('zones.drawHint'))}</p><div data-draw-map></div><div class="err" data-err hidden></div>`,
      footer: `${z.boundary ? `<button class="btn" data-remove style="margin-right:auto">${esc(t('zones.removeBoundary'))}</button>` : ''}<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit>${esc(t('c.save'))}</button>` });
    const drawer = mountZoneDrawer(m.el.querySelector('[data-draw-map]'), z.boundary, zs.filter(x => x.id !== z.id && x.boundary));
    const save = async (btn, boundary) => {
      const err = m.el.querySelector('[data-err]');
      try { await busy(btn, () => api.rpc('set_zone_boundary', { p_zone_id: z.id, p_boundary: boundary })); drawer.destroy(); m.close(); toast(t('c.saved')); load(); }
      catch (ex) { err.textContent = ex.message; err.hidden = false; }
    };
    m.el.querySelector('[data-submit]').addEventListener('click', e => {
      const b = drawer.get(), err = m.el.querySelector('[data-err]');
      if (!b) { err.textContent = t('zones.drawMin'); err.hidden = false; return; }
      save(e.currentTarget, b);
    });
    m.el.querySelector('[data-remove]')?.addEventListener('click', e => save(e.currentTarget, null));
  }

  // Zone name with town suggestions (Founder 2026-10-13: "che" -> Cheras,
  // Kuala Lumpur; town level only). A picked town is passed on as place.
  function nameDialog(title, value, action) {
    const m = modal({ title, body: `<div class="field"><label>${esc(t('zones.name'))}</label><input class="input" name="n" maxlength="80" autocomplete="off" value="${esc(value)}"><div class="area-suggest" data-sug hidden></div></div><div class="err" data-err hidden></div>`,
      footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit>${esc(t('c.save'))}</button>` });
    const input = m.el.querySelector('[name=n]'), sug = m.el.querySelector('[data-sug]');
    let picked = null, timer = null, seq = 0, options = [];
    input.addEventListener('input', () => {
      if (picked && input.value !== picked.name) picked = null;
      clearTimeout(timer);
      const q = input.value.trim(), mine = ++seq;
      if (picked || q.length < 2) { sug.hidden = true; return; }
      timer = setTimeout(async () => {
        options = (await api.fn('zone-boundary', { suggest: q, country: country().iso2 }).catch(() => null))?.suggestions || [];
        if (mine !== seq) return;
        sug.innerHTML = (options || []).map((a, i) => `<button type="button" data-i="${i}">${icon('pin')}<span><b>${esc(a.name)}</b>${a.state ? `<small>${esc(a.state)}</small>` : ''}</span></button>`).join('');
        sug.hidden = !options?.length;
      }, 250);
    });
    sug.addEventListener('click', e => {
      const b = e.target.closest('[data-i]'); if (!b) return;
      picked = options[+b.dataset.i]; input.value = picked.name; sug.hidden = true; input.focus();
    });
    m.el.querySelector('[data-submit]').addEventListener('click', async e => {
      const n = input.value.trim(), err = m.el.querySelector('[data-err]');
      if (!n) { err.textContent = t('c.required'); err.hidden = false; return; }
      try { await busy(e.currentTarget, () => action(n, picked || null)); m.close(); load(); } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    });
  }

  el.addEventListener('click', e => {
    if (e.target.closest('[data-sort]')) { sortAsc = !sortAsc; paint(); return; }
    const row = e.target.closest('tr[data-id]'); if (row) { location.hash = `#/zones/${row.dataset.id}`; return; }
    if (e.target.closest('[data-add]')) { nameDialog(t('zones.add'), '', (name, place) => api.rpc('create_zone', { p_business_id: ctx.bid, p_name: name }).then(r => outline(r, place)).then(() => toast(t('zones.created')))); return; }
    if (e.target.closest('[data-hex]')) { hexDialog(); return; }
    if (e.target.closest('[data-zmenu]')) { e.stopPropagation(); zoneMenu(e.target.closest('[data-zmenu]')); return; }
    if (e.target.closest('[data-retry]')) load();
  });
  $('[data-q]').addEventListener('input', e => { query = e.target.value.trim().toLowerCase(); paint(); });
  load();
}
