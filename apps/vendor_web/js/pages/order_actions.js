// Order intake + planning actions (Today quick actions). Each uses the
// existing canonical RPC; success is only reported after the server
// confirms, and every submit is idempotent / duplicate-guarded.
import { t, fmtTime } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { fetchZones, fetchRiders, todayLocal } from '../data.js';
import { esc, icon, modal, toast, busy } from '../ui.js';

const uuid = () => crypto.randomUUID();

export async function openAddOrder(onDone) {
  let zones = [];
  try { zones = (await fetchZones()).filter(z => z.status === 'active'); } catch { /* zone optional */ }
  const m = modal({
    title: t('add.title'), lead: t('add.lead'),
    body: `
      <div class="field"><label>${esc(t('add.name'))}</label><input class="input" name="name" maxlength="120" autocomplete="off"></div>
      <div class="field"><label>${esc(t('add.phone'))}</label><input class="input" name="phone" inputmode="tel" placeholder="+60 12-345 6789"></div>
      <div class="field"><label>${esc(t('add.address'))}</label><textarea class="textarea" name="address" rows="2"></textarea></div>
      <div class="field"><label>${esc(t('add.zone'))}</label><select class="select" name="zone"><option value="">${esc(t('add.noZone'))}</option>${zones.map(z => `<option value="${esc(z.id)}">${esc(z.name)}</option>`).join('')}</select></div>
      <div class="field"><label>${esc(t('orders.items'))}</label><div data-items style="display:grid;gap:8px"></div>
        <button type="button" class="link-btn" data-additem style="justify-self:start">+ ${esc(t('add.addItem'))}</button></div>
      <div class="field"><label>${esc(t('add.notes'))}</label><textarea class="textarea" name="notes" rows="2"></textarea></div>
      <div class="err" data-err hidden></div>`,
    footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit>${esc(t('add.create'))}</button>`,
  });
  const items = m.el.querySelector('[data-items]');
  const addItem = () => items.insertAdjacentHTML('beforeend', `<div style="display:grid;grid-template-columns:1fr 90px;gap:8px"><input class="input" data-iname placeholder="${esc(t('add.itemName'))}"><input class="input" data-iqty type="number" min="1" value="1" aria-label="${esc(t('add.qty'))}"></div>`);
  addItem();
  m.el.querySelector('[data-additem]').addEventListener('click', addItem);
  m.el.querySelector('[data-submit]').addEventListener('click', async e => {
    const f = n => m.el.querySelector(`[name=${n}]`);
    const err = m.el.querySelector('[data-err]');
    const name = f('name').value.trim(), phone = f('phone').value.trim(), address = f('address').value.trim();
    [['name', name], ['phone', phone], ['address', address]].forEach(([n, v]) => f(n).classList.toggle('invalid', !v));
    if (!name || !address || !phone) { err.textContent = t('c.required'); err.hidden = false; return; }
    if (phone.replace(/\D/g, '').length < 7) { f('phone').classList.add('invalid'); err.textContent = t('c.invalidPhone'); err.hidden = false; return; }
    err.hidden = true;
    const lines = [...items.children].map(r => ({ name: r.querySelector('[data-iname]').value.trim(), quantity: Math.max(1, Number(r.querySelector('[data-iqty]').value) || 1) })).filter(l => l.name);
    try {
      await busy(e.currentTarget, () => api.rpc('create_delivery', {
        p_business_id: ctx.bid, p_customer_name: name, p_customer_phone: phone, p_delivery_address: address,
        p_notes: f('notes').value.trim(), p_latitude: null, p_longitude: null, p_items: lines,
        p_zone_id: f('zone').value || null, p_vehicle_requirement: null,
      }));
      m.close();
      toast(t('add.created'));
      onDone?.();
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
      <select class="select" data-rider="${i}">${riders.map(r => `<option value="${esc(r.id)}" ${r.id === g.candidate_rider_id ? 'selected' : ''}>${esc(r.name)}</option>`).join('')}</select></div></div>`).join('');
  submit.disabled = false;
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
          const orderIds = (g.stops || []).map(s => s.order_id).filter(Boolean);
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
