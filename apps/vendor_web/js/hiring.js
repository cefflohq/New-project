// D-75 "Looking for riders" (Owner only), as in Vendor App: the business's
// openings shown to Drivers in Find Jobs. A rider who requests one lands in
// Riders > Pending and the Owner approves as today. Server:
// save_job_opening / close_job_opening (Owner only, enforced server-side);
// rider_job_openings is readable by business members.
import { t, fmtDate } from './i18n.js';
import { api } from './api.js';
import { ctx } from './store.js';
import { esc, icon, toast, busy, modal, avatar } from './ui.js';

const hhmm = v => {
  const [h, m] = v.split(':').map(Number);
  return `${h % 12 || 12}:${String(m).padStart(2, '0')} ${h < 12 ? 'AM' : 'PM'}`;
};
const num = v => (Number(v) % 1 ? Number(v).toFixed(1) : String(Number(v)));

// "RM3.50 / drop" for per-drop posts (M1); legacy units keep their label.
const payLabel = o => (o.pay_unit === 'drop'
  ? t('hr.perDrop', { a: Number(o.pay_amount).toFixed(2) })
  : `RM ${num(o.pay_amount)} / ${t(`hire.${o.pay_unit}`)}`);
const timeLabel = o => (o.shift_end ? `${hhmm(o.shift_start)} – ${hhmm(o.shift_end)}` : t('hr.pickupAt', { t: hhmm(o.shift_start) }));
export const pendingApplicants = o => (o.rider_job_requests || []).filter(r => r.status === 'pending').length;

export function mountHiring(host, { onChange } = {}) {
  let openings = null, working = false;

  async function load() {
    try {
      openings = (await api.get(`/rest/v1/rider_job_openings?business_id=eq.${encodeURIComponent(ctx.bid)}&status=eq.open&select=*,rider_job_requests(status)&order=shift_start`)) || [];
    } catch (e) { openings = []; toast(e.message, 'error'); }
    paint();
  }

  // Draft D (Founder 2026-10-05): the Openings view of Drivers - a list with
  // Close, one "+" action, and an empty state. A row opens its Driver Hiring
  // page (screen 10: applicants + details).
  function paint() {
    const list = openings || [];
    onChange?.(openings === null ? null : list.length, list.reduce((n, o) => n + pendingApplicants(o), 0));
    host.innerHTML = `<div class="hire">
      <div class="hire-h"><div><b>${esc(t('hire.openTitle'))}</b><small>${esc(t('hire.openLead'))}</small></div>
        <button class="btn cta sm" data-add ${working ? 'disabled' : ''}>${icon('plus')}${esc(t('hr.title'))}</button></div>
      ${openings === null ? window.cfLoader.markup(t('ld.default'))
        : list.length ? `<div class="hire-list">${list.map(o => `<div class="hire-row" data-open-id="${esc(o.id)}" role="button" tabindex="0" style="cursor:pointer">
          <div><b>${esc(timeLabel(o))}</b>
          <small>${esc([[...o.days].sort().map(d => t(`hire.d${d}`)).join(', '), t(`veh.${o.vehicle_type}`), payLabel(o), `× ${o.riders_needed}`].join(' · '))}</small>
          <small>${esc(o.area_label)} · ${esc(num(o.radius_km))} km${pendingApplicants(o) ? ` · <b>${esc(t('hr.applicantsN', { n: pendingApplicants(o) }))}</b>` : ''}</small></div>
          <button class="link-btn hire-close" data-close-id="${esc(o.id)}" ${working ? 'disabled' : ''}>${esc(t('hire.close'))}</button></div>`).join('')}</div>`
        : `<div class="hire-empty">${esc(t('hire.none'))}</div>`}
    </div>`;
  }

  host.addEventListener('click', async e => {
    if (e.target.closest('[data-add]')) { openForm(); return; }
    const c = e.target.closest('[data-close-id]');
    if (c) {
      try { await busy(c, () => api.rpc('close_job_opening', { p_opening_id: c.dataset.closeId })); toast(t('hire.closed')); } catch (ex) { toast(ex.message, 'error'); }
      return load();
    }
    const row = e.target.closest('[data-open-id]');
    if (row) openPost((openings || []).find(o => o.id === row.dataset.openId));
  });

  // Founder screen 10: "Active · N applicants", Applicants | Details.
  // Approve / Reject = the existing rider approval (Owner-only server-side).
  async function openPost(post) {
    if (!post) return;
    let tab = 'app', rows = [];
    const m = modal({ title: t('hr.postTitle'), body: '<div data-post></div>' });
    const box = m.el.querySelector('[data-post]');
    const kv = (k, v) => `<div class="kv"><div><small>${esc(k)}</small><b>${esc(v)}</b></div></div>`;
    const fmt = fmtDate;
    const paintPost = () => {
      const waiting = rows.filter(r => r.status === 'pending').length;
      const chipFor = r => r.status === 'approved' ? `<span class="chip ready">${esc(t('hr.approved'))}</span>`
        : r.status !== 'pending' ? `<span class="chip neutral">${esc(t('hr.rejected'))}</span>`
        : (Date.now() - new Date(r.created_at) < 864e5 ? `<span class="chip delivery">${esc(t('hr.new'))}</span>` : `<span class="chip pending">${esc(t('hr.pending'))}</span>`);
      box.innerHTML = `<p class="desc" style="margin:0 0 10px"><i class="dot" style="display:inline-block;width:8px;height:8px;border-radius:50%;background:var(--success,#16a34a);margin-right:6px"></i>${esc(t('hr.active', { n: waiting }))}</p>
        <div class="tabs"><button class="${tab === 'app' ? 'on' : ''}" data-ptab="app">${esc(t('hr.applicantsTab', { n: rows.length }))}</button><button class="${tab === 'det' ? 'on' : ''}" data-ptab="det">${esc(t('hr.details'))}</button></div>
        ${tab === 'det' ? `<div class="sub-card">${kv(t('hire.area'), post.area_label)}${kv(t('hire.days'), [...post.days].sort().map(d => t(`hire.d${d}`)).join(', '))}${kv(t('hr.pickupTime'), hhmm(post.shift_start))}${kv(t('hire.vehicle'), t(`veh.${post.vehicle_type}`))}${kv(t('hr.payPerDrop'), payLabel(post))}${kv(t('hire.needed'), String(post.riders_needed))}${kv(t('hr.reach'), `${num(post.radius_km)} km`)}</div>`
          : rows.length ? rows.map(r => { const d = r.riders || {}; const can = r.status === 'pending' && d.status === 'pending';
              return `<div class="list-row" style="cursor:default">${avatar(d.name || '?')}<div class="grow"><b>${esc(d.name || '')}</b><small>${esc([d.vehicle_type && t(`veh.${d.vehicle_type}`), d.vehicle_plate].filter(Boolean).join(' · '))}</small><small>${esc(t('hr.appliedVia', { d: fmt(r.created_at) }))}</small></div>${chipFor(r)}
              ${can ? `<button class="btn sm" data-dec="${esc(r.rider_id)}" data-ok="0">${esc(t('hr.reject'))}</button><button class="btn sm primary" data-dec="${esc(r.rider_id)}" data-ok="1">${esc(t('hr.approve'))}</button>` : ''}</div>`; }).join('')
          : `<div class="hint" style="padding:12px 0">${esc(t('hr.none'))}</div>`}`;
    };
    const loadPost = async () => {
      try { rows = (await api.get(`/rest/v1/rider_job_requests?opening_id=eq.${encodeURIComponent(post.id)}&select=id,status,created_at,rider_id,riders(name,vehicle_type,vehicle_plate,status)&order=created_at.desc`)) || []; }
      catch (e) { rows = []; toast(e.message, 'error'); }
      paintPost();
    };
    box.addEventListener('click', async e => {
      const tb = e.target.closest('[data-ptab]'); if (tb) { tab = tb.dataset.ptab; paintPost(); return; }
      const d = e.target.closest('[data-dec]'); if (!d) return;
      const approve = d.dataset.ok === '1';
      try {
        await busy(d, () => api.rpc(approve ? 'approve_pending_rider' : 'deactivate_rider', { p_rider_id: d.dataset.dec }));
        toast(t(approve ? 'hr.approvedToast' : 'hr.rejectedToast')); await loadPost(); load();
      } catch (ex) { toast(ex.message, 'error'); }
    });
    paintPost(); loadPost();
  }

  // Hiring Driver (M1 contract, Founder screen 3): area, days, pickup time
  // (no end time), vehicle, pay per drop (min RM3.00), drivers needed,
  // driver reach 1-15 km (default 10). The server validates everything again.
  function openForm() {
    let days = new Set([1, 2, 3, 4, 5]), vehicle = 'motorcycle';
    const chips = (name, items, isOn) => items.map(([v, label]) => `<button type="button" class="chip-btn ${isOn(v) ? 'on' : ''}" data-${name}="${v}">${esc(label)}</button>`).join('');
    const m = modal({
      title: t('hr.title'),
      lead: t('hiring.driverSub'),
      body: `<form data-form novalidate class="hire-form">
        <div class="field"><label for="h-area">${esc(t('hire.area'))}</label><input class="input" id="h-area" placeholder="${esc(t('hire.areaHint'))}" maxlength="60"></div>
        <div class="field"><label>${esc(t('hire.days'))}</label><div class="chips" data-days></div></div>
        <div class="field"><label for="h-start">${esc(t('hr.pickupTime'))}</label><input class="input" id="h-start" type="time" value="07:00" style="max-width:200px"><small class="hint">${esc(t('hr.pickupHint'))}</small></div>
        <div class="field"><label>${esc(t('hire.vehicle'))}</label><div class="chips" data-vehicles></div></div>
        <div class="field"><label for="h-pay">${esc(t('hr.payPerDrop'))}</label><input class="input" id="h-pay" inputmode="decimal" value="3.00" style="max-width:200px"><small class="hint" data-pay-hint>${esc(t('hr.payMin'))}</small></div>
        <div class="row2"><div class="field"><label for="h-need">${esc(t('hire.needed'))}</label><input class="input" id="h-need" type="number" min="1" max="50" value="1"></div>
          <div class="field"><label for="h-radius" data-radius-label>${esc(t('hr.reachKm', { km: 10 }))}</label><input id="h-radius" type="range" min="1" max="15" step="1" value="10"><small class="hint" data-reach-hint>${esc(t('hr.reachHint', { km: 10 }))}</small></div></div>
        <div class="err" data-err hidden role="alert"></div></form>`,
      footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-save>${esc(t('hr.publish'))}</button>`,
    });
    const q = s => m.el.querySelector(s);
    const repaint = () => {
      q('[data-days]').innerHTML = chips('day', [1, 2, 3, 4, 5, 6, 7].map(d => [d, t(`hire.d${d}`)]), v => days.has(Number(v)));
      q('[data-vehicles]').innerHTML = chips('veh', ['motorcycle', 'car', 'van'].map(v => [v, t(`veh.${v}`)]), v => v === vehicle);
    };
    repaint();
    m.el.addEventListener('click', e => {
      const d = e.target.closest('[data-day]'), v = e.target.closest('[data-veh]');
      if (d) { const n = Number(d.dataset.day); days.has(n) ? days.delete(n) : days.add(n); repaint(); }
      if (v) { vehicle = v.dataset.veh; repaint(); }
    });
    const payNum = () => Number(q('#h-pay').value.replace(',', '.'));
    q('#h-pay').addEventListener('input', () => { q('[data-pay-hint]').style.color = payNum() >= 3 ? '' : 'var(--danger, #dc2626)'; });
    q('#h-radius').addEventListener('input', e => {
      q('[data-radius-label]').textContent = t('hr.reachKm', { km: e.target.value });
      q('[data-reach-hint]').textContent = t('hr.reachHint', { km: e.target.value });
    });
    q('[data-save]').addEventListener('click', async e => {
      const err = q('[data-err]'); err.hidden = true;
      const area = q('#h-area').value.trim(), pickup = q('#h-start').value;
      const pay = payNum(), need = Number(q('#h-need').value), reach = Number(q('#h-radius').value);
      if (area.length < 2 || !days.size || !pickup || !(pay >= 3) || !(need >= 1 && need <= 50)) { err.textContent = t('hr.fix'); err.hidden = false; return; }
      try {
        await busy(e.target, () => api.rpc('save_job_opening', {
          p_business_id: ctx.bid, p_area_label: area, p_pickup_time: pickup, p_days: [...days].sort(),
          p_vehicle_type: vehicle, p_pay_per_drop: pay, p_drivers_needed: need, p_reach_km: reach,
        }));
        m.close(); toast(t('hire.posted')); load();
      } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    });
  }

  paint();
  load();
  return { openForm, reload: load };
}
