// Order intake + planning actions (Today quick actions). Each uses the
// existing canonical RPC; success is only reported after the server
// confirms, and every submit is idempotent / duplicate-guarded.
import { t, fmtTime } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { fetchZones, fetchRiders, todayLocal } from '../data.js';
import { esc, icon, modal, toast, busy, copyText } from '../ui.js';

const uuid = () => crypto.randomUUID();

// With `existing`, the same form edits a not-yet-dispatched order through
// update_order_details (V-15, D-61): the server accepts only created orders.
// Customer Tracking link (D-04: the shared tokenized link is the normal
// entry). create_delivery returns the token once; only its hash is stored,
// so the link is offered here, at creation, to copy or share with the
// customer. Base: CEFFLO_CONFIG.trackingBaseUrl, else this host's /customer/.
export const trackingUrl = token => `${window.CEFFLO_CONFIG?.trackingBaseUrl || new URL('../customer/', location.href).href}?token=${encodeURIComponent(token)}`;
function showTrackingLink(token) {
  const link = trackingUrl(token);
  const m = modal({
    title: t('trk.title'), lead: t('trk.lead'),
    body: `<div class="field"><label>${esc(t('trk.label'))}</label><input class="input" readonly data-trk value="${esc(link)}"></div>
      <p class="hint">${esc(t('trk.once'))}</p>`,
    footer: `<button class="btn" data-close>${esc(t('c.close'))}</button>
      ${navigator.share ? `<button class="btn" data-share>${esc(t('invite.share'))}</button>` : ''}
      <button class="btn primary" data-copy>${esc(t('riders.copy'))}</button>`,
  });
  m.el.addEventListener('click', async e => {
    if (e.target.closest('[data-copy]')) { const ok = await copyText(link); if (!ok) m.el.querySelector('[data-trk]').select(); toast(ok ? t('riders.copied') : link); }
    if (e.target.closest('[data-share]')) { try { await navigator.share({ title: t('trk.title'), url: link }); } catch { /* dismissed */ } }
  });
}

export async function openAddOrder(onDone, existing = null) {
  const ed = existing || {};
  let zones = [];
  try { zones = (await fetchZones()).filter(z => z.status === 'active'); } catch { /* zone optional */ }
  const m = modal({
    title: t(existing ? 'edit.title' : 'add.title'), lead: t(existing ? 'edit.lead' : 'add.lead'),
    body: `
      <div class="field"><label>${esc(t('add.name'))}</label><input class="input" name="name" maxlength="120" autocomplete="off" value="${esc(ed.customer_name || '')}"></div>
      <div class="field"><label>${esc(t('add.phone'))}</label><input class="input" name="phone" inputmode="tel" placeholder="+60 12-345 6789" value="${esc(ed.customer_phone || '')}"></div>
      <div class="field"><label>${esc(t('add.address'))}</label><textarea class="textarea" name="address" rows="2">${esc(ed.delivery_address || '')}</textarea></div>
      <div class="field"><label>${esc(t('add.zone'))}</label><select class="select" name="zone"><option value="">${esc(t('add.noZone'))}</option>${zones.map(z => `<option value="${esc(z.id)}" ${z.id === ed.zone_id ? 'selected' : ''}>${esc(z.name)}</option>`).join('')}</select></div>
      <div class="field"><label>${esc(t('orders.items'))}</label><div data-items style="display:grid;gap:8px"></div>
        <button type="button" class="link-btn" data-additem style="justify-self:start">+ ${esc(t('add.addItem'))}</button></div>
      <div class="field"><label>${esc(t('add.notes'))}</label><textarea class="textarea" name="notes" rows="2">${esc(ed.notes || '')}</textarea></div>
      <div class="err" data-err hidden></div>`,
    footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit>${esc(t(existing ? 'edit.save' : 'add.create'))}</button>`,
  });
  const items = m.el.querySelector('[data-items]');
  const addItem = (l = {}) => items.insertAdjacentHTML('beforeend', `<div style="display:grid;grid-template-columns:1fr 90px;gap:8px"><input class="input" data-iname placeholder="${esc(t('add.itemName'))}" value="${esc(l.name || '')}"><input class="input" data-iqty type="number" min="1" value="${Number(l.quantity) || 1}" aria-label="${esc(t('add.qty'))}"></div>`);
  const prior = Array.isArray(ed.items) ? ed.items : [];
  if (prior.length) prior.forEach(addItem); else addItem();
  m.el.querySelector('[data-additem]').addEventListener('click', () => addItem());
  m.el.querySelector('[data-submit]').addEventListener('click', async e => {
    const f = n => m.el.querySelector(`[name=${n}]`);
    const err = m.el.querySelector('[data-err]');
    const name = f('name').value.trim(), phone = f('phone').value.trim(), address = f('address').value.trim();
    [['name', name], ['phone', phone], ['address', address]].forEach(([n, v]) => f(n).classList.toggle('invalid', !v));
    if (!name || !address || !phone) { err.textContent = t('c.required'); err.hidden = false; return; }
    if (phone.replace(/\D/g, '').length < 7) { f('phone').classList.add('invalid'); err.textContent = t('c.invalidPhone'); err.hidden = false; return; }
    err.hidden = true;
    const lines = [...items.children].map(r => ({ name: r.querySelector('[data-iname]').value.trim(), quantity: Math.max(1, Number(r.querySelector('[data-iqty]').value) || 1) })).filter(l => l.name);
    if (existing) {
      // Keep any other item fields (e.g. unit_price) for lines whose name is unchanged.
      const merged = lines.map(l => ({ ...(prior.find(p => p.name === l.name) || {}), ...l }));
      const zone = f('zone').value || null;
      try {
        await busy(e.currentTarget, () => api.rpc('update_order_details', {
          p_order_id: existing.id, p_customer_name: name, p_customer_phone: phone, p_delivery_address: address,
          p_notes: f('notes').value.trim(), p_items: merged, ...(zone ? { p_zone_id: zone } : { p_clear_zone: !!existing.zone_id }),
        }));
        // An address change resets the location server-side; resolve it again.
        if (address !== existing.delivery_address) api.fn('geocode-order', { order_id: existing.id }).catch(() => {});
        m.close(); toast(t('edit.saved')); onDone?.();
      } catch (ex) { err.textContent = ex.message; err.hidden = false; }
      return;
    }
    try {
      const created = await busy(e.currentTarget, () => api.rpc('create_delivery', {
        p_business_id: ctx.bid, p_customer_name: name, p_customer_phone: phone, p_delivery_address: address,
        p_notes: f('notes').value.trim(), p_latitude: null, p_longitude: null, p_items: lines,
        p_zone_id: f('zone').value || null, p_vehicle_requirement: 'any',
      }));
      // Same fire-and-forget step as Vendor App: resolve the location planning
      // needs. The order exists either way; a failure leaves it unresolved
      // and it surfaces under Need Attention.
      const orderId = created?.order?.id ?? created?.order_id ?? created?.id;
      if (orderId) api.fn('geocode-order', { order_id: orderId }).catch(() => {});
      m.close();
      toast(t('add.created'));
      onDone?.();
      if (created?.tracking_token) showTrackingLink(created.tracking_token);
    } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
}

// Minimal RFC-4180 CSV parser (quoted fields, commas, newlines).
function parseCsv(text) {
  const rows = []; let row = [], cell = '', q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) { if (c === '"') { if (text[i + 1] === '"') { cell += '"'; i++; } else q = false; } else cell += c; }
    else if (c === '"') q = true;
    else if (c === ',') { row.push(cell); cell = ''; }
    else if (c === '\n' || c === '\r') { if (c === '\r' && text[i + 1] === '\n') i++; row.push(cell); rows.push(row); row = []; cell = ''; }
    else cell += c;
  }
  if (cell || row.length) { row.push(cell); rows.push(row); }
  return rows.filter(r => r.some(v => v.trim()));
}

// Excel (.xlsx/.xls) is read in the browser (same library the legacy vendor
// web used) and turned into the same rows as a CSV, so both paths feed the
// one canonical import_orders_batch.
const XLSX_SRC = 'https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js';
function loadXlsx() {
  if (window.XLSX) return Promise.resolve(window.XLSX);
  return new Promise((ok, fail) => {
    const s = document.createElement('script');
    s.src = XLSX_SRC;
    s.onload = () => ok(window.XLSX);
    s.onerror = () => fail(new Error(t('imp.xlsxLoadFailed')));
    document.head.append(s);
  });
}
async function readRows(file) {
  if (!/\.xlsx?$/i.test(file.name)) return parseCsv(await file.text());
  const X = await loadXlsx();
  const wb = X.read(await file.arrayBuffer(), { type: 'array' });
  const rows = X.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]], { header: 1, defval: '', raw: false });
  return rows.map(r => r.map(v => String(v ?? ''))).filter(r => r.some(v => v.trim()));
}

export function openImport(onDone) {
  let valid = [];
  const m = modal({
    title: t('imp.title'), lead: t('imp.lead'),
    body: `<div class="hint">${esc(t('imp.columns'))}</div>
      <input type="file" accept=".csv,text/csv,.xlsx,.xls,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel" data-file class="input" style="padding-top:9px">
      <div data-summary class="hint"></div><div class="err" data-err hidden></div>`,
    footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit disabled>${esc(t('imp.import'))}</button>`,
  });
  const err = m.el.querySelector('[data-err]'), submit = m.el.querySelector('[data-submit]');
  m.el.querySelector('[data-file]').addEventListener('change', async e => {
    err.hidden = true; valid = [];
    const file = e.target.files?.[0];
    if (!file) return;
    let rows;
    try { rows = await readRows(file); } catch (ex) { err.textContent = ex.message; err.hidden = false; submit.disabled = true; return; }
    const head = (rows.shift() || []).map(h => h.trim().toLowerCase());
    const col = n => head.indexOf(n);
    const bad = [];
    rows.forEach((r, i) => {
      const get = n => (col(n) >= 0 ? (r[col(n)] || '').trim() : '');
      const rec = { source_row_ref: `row-${i + 2}`, customer_name: get('customer_name'), customer_phone: get('customer_phone'), delivery_address: get('delivery_address'), zone_name: get('zone') || null };
      if (!rec.customer_name || !rec.customer_phone || !rec.delivery_address) bad.push(t('imp.bad', { n: i + 2, why: t('c.required') }));
      else valid.push(rec);
    });
    m.el.querySelector('[data-summary]').textContent = t('imp.rows', { n: valid.length });
    if (bad.length) { err.textContent = bad.slice(0, 5).join(' · '); err.hidden = false; }
    submit.disabled = !valid.length;
  });
  const key = uuid();
  submit.addEventListener('click', async e => {
    try {
      const res = await busy(e.currentTarget, () => api.rpc('import_orders_batch', { p_business_id: ctx.bid, p_rows: valid, p_idempotency_key: key }));
      const n = (res?.committed || []).length;
      m.close();
      toast(t('imp.done', { n }));
      onDone?.();
    } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
}

export async function openPlanDelivery(onDone) {
  const m = modal({ title: t('plan.title'), lead: t('plan.lead'), body: `<div data-body><div class="skel" style="height:60px"></div></div><div class="err" data-err hidden></div>`,
    footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit disabled>${esc(t('plan.create'))}</button>` });
  const body = m.el.querySelector('[data-body]'), err = m.el.querySelector('[data-err]'), submit = m.el.querySelector('[data-submit]');
  let groups = [], riders = [], zones = new Map();
  try {
    const [plan, rs, zs] = await Promise.all([api.rpc('propose_delivery_plan', { p_business_id: ctx.bid }), fetchRiders(), fetchZones()]);
    groups = plan?.groups || [];
    riders = (rs || []).filter(r => r.status === 'active');
    zones = new Map((zs || []).map(z => [z.id, z.name]));
  } catch (ex) { body.innerHTML = ''; err.textContent = ex.message; err.hidden = false; return; }
  if (!groups.length) { body.innerHTML = `<div class="state"><h3>${esc(t('plan.none'))}</h3></div>`; return; }
  body.innerHTML = groups.map((g, i) => `<div class="sub-card" style="margin:0">
      <div style="display:flex;align-items:center;gap:10px"><b>${esc(t('plan.run', { n: i + 1 }))}</b><span class="chip neutral">${esc(zones.get(g.zone_id) || t('add.noZone'))}</span>
      <span class="hint" style="margin-left:auto">${esc(t('runs.orders', { n: (g.stops || []).length }))}${g.total_distance_km ? ` · ${Number(g.total_distance_km).toFixed(1)} km` : ''}</span></div>
      <div class="field" style="margin-top:10px"><label>${esc(t('plan.rider'))}</label>
      <select class="select" data-rider="${i}">${riders.map(r => `<option value="${esc(r.id)}" ${r.id === g.candidate_rider_id ? 'selected' : ''}>${esc(r.name)}</option>`).join('')}</select></div>
      <div class="hint" data-cap="${i}" style="margin-top:6px"></div></div>`).join('');
  // D-61: rider selection -> check_run_vehicle_capacity -> confirmation. A run
  // is dispatched only when every group is compatible (no override, as App).
  const ok = groups.map(() => false);
  const orderIdsOf = g => (g.stops || []).map(s => s.order_id).filter(Boolean);
  const refresh = () => { submit.disabled = !ok.every(Boolean); };
  async function check(i) {
    const out = m.el.querySelector(`[data-cap="${i}"]`), rider = m.el.querySelector(`[data-rider="${i}"]`).value;
    ok[i] = false; refresh();
    if (!rider) { out.textContent = t('plan.noRider'); return; }
    out.textContent = t('plan.checking');
    try {
      const res = await api.rpc('check_run_vehicle_capacity', { p_rider_id: rider, p_order_ids: orderIdsOf(groups[i]) });
      const r = Array.isArray(res) ? res[0] : res;
      if (m.el.querySelector(`[data-rider="${i}"]`).value !== rider) return;
      ok[i] = r?.compatible === true;
      out.innerHTML = ok[i] ? esc(t('plan.capOk')) : (r?.violations || []).map(v => `<div class="err" style="margin:2px 0">${esc(v.reason === 'capacity_exceeded'
        ? t('plan.capExceeded', { load: v.current_load, req: v.requested, cap: v.effective_capacity })
        : t('plan.vehicleBad', { need: v.vehicle_requirement, has: v.rider_vehicle_type }))}</div>`).join('');
    } catch (ex) { out.innerHTML = `<div class="err">${esc(ex.message)}</div>`; }
    refresh();
  }
  m.el.addEventListener('change', e => { const sel = e.target.closest('[data-rider]'); if (sel) check(Number(sel.dataset.rider)); });
  groups.forEach((_, i) => check(i));
  const keys = groups.map(() => uuid());
  let sessionId = null;
  submit.addEventListener('click', async e => {
    err.hidden = true;
    const picks = groups.map((_, i) => m.el.querySelector(`[data-rider="${i}"]`).value);
    if (picks.some(p => !p)) { err.textContent = t('plan.noRider'); err.hidden = false; return; }
    try {
      let made = 0;
      await busy(e.currentTarget, async () => {
        if (!sessionId) {
          const s = await api.rpc('create_delivery_session', { p_business_id: ctx.bid, p_name: `${t('plan.title')} ${fmtTime(new Date().toISOString())}`, p_delivery_date: todayLocal() });
          sessionId = s.id;
        }
        for (const [i, g] of groups.entries()) {
          const orderIds = orderIdsOf(g);
          if (!orderIds.length) continue;
          await api.rpc('build_rider_run', { p_delivery_session_id: sessionId, p_rider_id: picks[i], p_order_ids: orderIds, p_idempotency_key: keys[i], p_override_capacity: false });
          made++;
        }
      });
      m.close();
      toast(t('plan.done', { n: made }));
      onDone?.();
    } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
  void icon;
}
