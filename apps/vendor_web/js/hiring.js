// D-75 "Looking for riders" (Owner only), as in Vendor App: the business's
// openings shown to Drivers in Find Jobs. A rider who requests one lands in
// Riders > Pending and the Owner approves as today. Server:
// save_job_opening / close_job_opening (Owner only, enforced server-side);
// rider_job_openings is readable by business members.
import { t } from './i18n.js';
import { api } from './api.js';
import { ctx } from './store.js';
import { esc, icon, toast, busy, modal, confirmDialog } from './ui.js';

const hhmm = v => {
  const [h, m] = v.split(':').map(Number);
  return `${h % 12 || 12}:${String(m).padStart(2, '0')} ${h < 12 ? 'AM' : 'PM'}`;
};
const num = v => (Number(v) % 1 ? Number(v).toFixed(1) : String(Number(v)));

export function mountHiring(host, { onChange } = {}) {
  let openings = null, working = false;

  async function load() {
    try {
      openings = (await api.get(`/rest/v1/rider_job_openings?business_id=eq.${encodeURIComponent(ctx.bid)}&status=eq.open&select=*&order=shift_start`)) || [];
    } catch (e) { openings = []; toast(e.message, 'error'); }
    paint();
  }

  function paint() {
    const on = (openings || []).length > 0;
    host.innerHTML = `<div class="hire">
      <div class="hire-h"><div><b>${esc(t('hire.title'))}</b><small>${esc(t(on ? 'hire.on' : 'hire.off'))}</small></div>
        <button class="switch ${on ? 'on' : ''}" role="switch" aria-checked="${on}" aria-label="${esc(t('hire.title'))}" data-toggle ${openings === null || working ? 'disabled' : ''}></button></div>
      ${on ? `<div class="hire-list">${openings.map(o => `<div class="hire-row">
          <div><b>${esc(hhmm(o.shift_start))} – ${esc(hhmm(o.shift_end))}</b>
          <small>${esc([[...o.days].sort().map(d => t(`hire.d${d}`)).join(', '), t(`veh.${o.vehicle_type}`), `RM ${num(o.pay_amount)} / ${t(`hire.${o.pay_unit}`)}`, `× ${o.riders_needed}`, t('hire.radius', { km: num(o.radius_km) })].join(' · '))}</small>
          <small>${esc(o.area_label)}</small></div>
          <button class="btn sm" data-close-id="${esc(o.id)}" ${working ? 'disabled' : ''}>${esc(t('hire.close'))}</button></div>`).join('')}
        <button class="btn sm" data-add ${working ? 'disabled' : ''}>${icon('plus')}${esc(t('hire.add'))}</button></div>` : ''}
    </div>`;
  }

  host.addEventListener('click', async e => {
    if (e.target.closest('[data-add]')) { openForm(); return; }
    const c = e.target.closest('[data-close-id]');
    if (c) {
      try { await busy(c, () => api.rpc('close_job_opening', { p_opening_id: c.dataset.closeId })); toast(t('hire.closed')); onChange?.(); } catch (ex) { toast(ex.message, 'error'); }
      return load();
    }
    if (e.target.closest('[data-toggle]')) {
      if (!(openings || []).length) { openForm(); return; }
      const ok = await confirmDialog({ title: t('hire.offTitle'), body: t('hire.offBody'), confirmLabel: t('hire.turnOff'), danger: true });
      if (!ok) return;
      working = true; paint();
      try { for (const o of openings) await api.rpc('close_job_opening', { p_opening_id: o.id }); } catch (ex) { toast(ex.message, 'error'); }
      working = false; load();
    }
  });

  function openForm() {
    let days = new Set([1, 2, 3, 4, 5]), vehicle = 'motorcycle', unit = 'shift';
    const chips = (name, items, isOn) => items.map(([v, label]) => `<button type="button" class="chip-btn ${isOn(v) ? 'on' : ''}" data-${name}="${v}">${esc(label)}</button>`).join('');
    const m = modal({
      title: t('hire.new'),
      body: `<form data-form novalidate class="hire-form">
        <div class="field"><label for="h-area">${esc(t('hire.area'))}</label><input class="input" id="h-area" placeholder="${esc(t('hire.areaHint'))}" maxlength="60"></div>
        <div class="field"><label>${esc(t('hire.days'))}</label><div class="chips" data-days></div></div>
        <div class="row2"><div class="field"><label for="h-start">${esc(t('hire.start'))}</label><input class="input" id="h-start" type="time" value="07:00"></div>
          <div class="field"><label for="h-end">${esc(t('hire.end'))}</label><input class="input" id="h-end" type="time" value="11:00"></div></div>
        <div class="field"><label>${esc(t('hire.vehicle'))}</label><div class="chips" data-vehicles></div></div>
        <div class="row2"><div class="field"><label for="h-pay">${esc(t('hire.pay'))}</label><input class="input" id="h-pay" inputmode="decimal" value="45"></div>
          <div class="field"><label>${esc(t('hire.per'))}</label><div class="chips" data-units></div></div></div>
        <div class="row2"><div class="field"><label for="h-need">${esc(t('hire.needed'))}</label><input class="input" id="h-need" type="number" min="1" max="50" value="1"></div>
          <div class="field"><label for="h-radius" data-radius-label>${esc(t('hire.radius', { km: 10 }))}</label><input id="h-radius" type="range" min="5" max="20" step="1" value="10"></div></div>
        <div class="err" data-err hidden role="alert"></div></form>`,
      footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-save>${esc(t('hire.post'))}</button>`,
    });
    const q = s => m.el.querySelector(s);
    const repaint = () => {
      q('[data-days]').innerHTML = chips('day', [1, 2, 3, 4, 5, 6, 7].map(d => [d, t(`hire.d${d}`)]), v => days.has(Number(v)));
      q('[data-vehicles]').innerHTML = chips('veh', ['motorcycle', 'car', 'van'].map(v => [v, t(`veh.${v}`)]), v => v === vehicle);
      q('[data-units]').innerHTML = chips('unit', ['shift', 'drop', 'hour'].map(v => [v, t(`hire.${v}`)]), v => v === unit);
    };
    repaint();
    m.el.addEventListener('click', e => {
      const d = e.target.closest('[data-day]'), v = e.target.closest('[data-veh]'), u = e.target.closest('[data-unit]');
      if (d) { const n = Number(d.dataset.day); days.has(n) ? days.delete(n) : days.add(n); repaint(); }
      if (v) { vehicle = v.dataset.veh; repaint(); }
      if (u) { unit = u.dataset.unit; repaint(); }
    });
    q('#h-radius').addEventListener('input', e => { q('[data-radius-label]').textContent = t('hire.radius', { km: e.target.value }); });
    q('[data-save]').addEventListener('click', async e => {
      const err = q('[data-err]'); err.hidden = true;
      const area = q('#h-area').value.trim(), start = q('#h-start').value, end = q('#h-end').value;
      const pay = Number(q('#h-pay').value.replace(',', '.')), need = Number(q('#h-need').value), radius = Number(q('#h-radius').value);
      if (area.length < 2 || !days.size || !start || !end || end <= start || !(pay > 0) || !(need >= 1 && need <= 50)) { err.textContent = t('hire.fix'); err.hidden = false; return; }
      try {
        await busy(e.target, () => api.rpc('save_job_opening', {
          p_business_id: ctx.bid, p_area_label: area, p_shift_start: start, p_shift_end: end, p_days: [...days].sort(),
          p_vehicle_type: vehicle, p_pay_amount: pay, p_pay_unit: unit, p_riders_needed: need, p_radius_km: radius,
        }));
        m.close(); toast(t('hire.posted')); onChange?.(); load();
      } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    });
  }

  paint();
  load();
}
