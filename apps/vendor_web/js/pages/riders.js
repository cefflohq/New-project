// Riders — list + detail (Founder reference 7). Invites, approval and
// deactivation use the canonical rider RPCs (Owner or Operator, enforced
// server-side).
import { t, fmtDate, fmtTime } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { fetchRiders, fetchOrders, fetchRatings, fetchLocations, orderNo } from '../data.js';
import { esc, icon, chip, avatar, loadingRows, emptyState, errorState, toast, busy, modal, confirmDialog, copyText, phoneDigits, orderStatus, gatedNote } from '../ui.js';

export default function riders({ el, params, setHeader }) {
  setHeader(t('riders.title'));
  const selected = params[0] || null;
  let tab = 'all', query = '', all = [], orders = [], ratings = [], locs = new Map();
  el.innerHTML = `<div class="split no-detail">
    <div class="card">
      <div class="bar">
        <div class="tabs" data-tabs></div>
        <div class="search">${icon('search')}<input data-q placeholder="${esc(t('riders.search'))}" aria-label="${esc(t('c.search'))}"></div>
        <button class="btn cta sm" data-add>${icon('plus')}${esc(t('riders.add'))}</button>
      </div>
      <div data-list>${loadingRows(8)}</div>
    </div>
  </div>`;
  const $ = s => el.querySelector(s);

  async function load() {
    try {
      const [r, o, rt, l] = await Promise.all([fetchRiders(), fetchOrders(), fetchRatings(), fetchLocations()]);
      all = (r || []).filter(x => x.status !== 'inactive');
      orders = o || []; ratings = rt || []; locs = new Map((l || []).map(x => [x.rider_id, x]));
      paint();
      if (selected) openDetail();
    } catch (e) { $('[data-list]').innerHTML = errorState(e, 'riders'); }
  }
  const stats = id => {
    const mine = orders.filter(o => o.assigned_rider_id === id);
    const rs = ratings.filter(r => r.rider_id === id);
    return {
      total: mine.length,
      completed: mine.filter(o => o.delivery_status === 'delivered').length,
      ongoing: mine.filter(o => ['picked_up', 'out_for_delivery', 'arrived', 'created', 'ready_for_pickup'].includes(o.delivery_status)).length,
      issues: mine.filter(o => o.delivery_status === 'issue').length,
      rating: rs.length ? (rs.reduce((s, r) => s + r.rating, 0) / rs.length).toFixed(1) : null,
      mine,
    };
  };
  const vehicle = r => (r.vehicle_type ? t(`veh.${r.vehicle_type}`) : '');

  function paint() {
    const n = { all: all.length, active: all.filter(r => r.status === 'active').length, pending: all.filter(r => r.status === 'pending').length };
    $('[data-tabs]').innerHTML = [['all', 'riders.all'], ['active', 'riders.active'], ['pending', 'riders.pending']]
      .map(([id, key]) => `<button class="${tab === id ? 'on' : ''}" data-tab="${id}">${esc(t(key))} (${n[id]})</button>`).join('');
    const rows = all.filter(r => (tab === 'all' || r.status === tab)
      && (!query || `${r.name} ${r.phone} ${r.vehicle_plate}`.toLowerCase().includes(query)));
    $('[data-list]').innerHTML = rows.length ? `<div class="table-wrap"><table class="t">
      <thead><tr><th>${esc(t('orders.rider'))}</th><th>${esc(t('riders.vehicle'))}</th><th>${esc(t('orders.status'))}</th><th>${esc(t('riders.totalOrders'))}</th><th>${esc(t('riders.rating'))}</th><th>${esc(t('riders.joined'))}</th><th></th></tr></thead>
      <tbody>${rows.map(r => {
        const s = stats(r.id);
        return `<tr class="row ${r.id === selected ? 'sel' : ''}" data-id="${esc(r.id)}">
          <td><span class="person">${avatar(r.name, 'sm')}<span><b>${esc(r.name)}</b><span class="sub">${esc(r.phone)}</span></span></span></td>
          <td><span class="person">${icon('bike')}<span>${esc(r.vehicle_plate || t('c.none'))}<span class="sub">${esc(vehicle(r))}</span></span></span></td>
          <td>${chip(r.status === 'active' ? 'active' : 'pending', true)}</td><td class="num">${s.total}</td>
          <td class="num">${s.rating ? `<span style="color:#e0a800">${icon('star')}</span> ${s.rating}` : '-'}</td>
          <td style="color:var(--muted)">${esc(fmtDate(r.created_at))}</td><td>${icon('right', 'i chev')}</td></tr>`;
      }).join('')}</tbody></table></div>` : emptyState(t('riders.none'), t('riders.noneBody'));
  }

  // Rider detail as a popup over the list (Founder reference: Riders). The
  // route keeps the rider id, so the popup can be linked and Back closes it.
  function openDetail() {
    const r = all.find(x => x.id === selected);
    if (!r) { location.hash = '#/riders'; return; }
    const s = stats(r.id), digits = phoneDigits(r.phone);
    const loc = locs.get(r.id);
    const live = loc && Date.now() - new Date(loc.recorded_at).getTime() < 5 * 60000;
    const wa = digits ? `https://wa.me/${esc(digits.replace(/^0/, '60'))}` : '';
    const head = `<div class="rd-head">${avatar(r.name, 'lg')}
        <div class="rd-id"><div class="rd-name"><h2>${esc(r.name)}</h2>${chip(r.status === 'active' ? 'active' : 'pending')}</div>
          <div class="hint">${esc(r.phone)}</div><div class="hint">${esc([r.vehicle_plate, vehicle(r)].filter(Boolean).join(' · '))}</div></div>
        ${digits ? `<a class="round-btn" href="tel:${esc(r.phone)}" aria-label="${esc(t('c.call'))}">${icon('phone')}</a><a class="round-btn wa" href="${wa}" target="_blank" rel="noopener" aria-label="WhatsApp">${icon('wa')}</a>` : ''}
      </div>`;
    const overview = `
      <div class="boxed stats"><div class="stat"><b class="c-blue">${s.total}</b><span>${esc(t('riders.totalOrders'))}</span></div>
        <div class="stat"><b class="c-green">${s.completed}</b><span>${esc(t('riders.completed'))}</span></div>
        <div class="stat"><b class="c-amber">${s.ongoing}</b><span>${esc(t('riders.ongoing'))}</span></div>
        <div class="stat"><b class="c-red">${s.issues}</b><span>${esc(t('riders.issues'))}</span></div></div>
      <div>
        <div class="kv">${icon('user')}<div><small>${esc(t('riders.name'))}</small><b>${esc(r.name)}</b></div></div>
        <div class="kv">${icon('phone')}<div><small>${esc(t('riders.phone'))}</small><b>${esc(r.phone)}</b></div></div>
        <div class="kv">${icon('bike')}<div><small>${esc(t('riders.vehicleNumber'))}</small><b>${esc(r.vehicle_plate || t('c.none'))}</b></div></div>
        <div class="kv">${icon('bike')}<div><small>${esc(t('riders.vehicleType'))}</small><b>${esc(vehicle(r) || t('c.none'))}</b></div></div>
        <div class="kv">${icon('clock')}<div><small>${esc(t('riders.joined'))}</small><b>${esc(fmtDate(r.created_at))}</b></div></div>
        <div class="kv">${icon('star')}<div><small>${esc(t('riders.rating'))}</small><b>${s.rating ? esc(s.rating) : '-'}</b></div></div>
        <div class="kv">${icon('route')}<div style="flex:1"><small>${esc(t('riders.availability'))}</small><b><span class="live" style="color:${live ? 'var(--success)' : 'var(--faint)'}"><i class="dot"></i>${esc(t(live ? 'st.online' : 'st.offline'))}</span></b></div></div>
      </div>`;
    const history = s.mine.length ? `<div>${s.mine.slice(0, 30).map(o => `<a class="list-row" href="#/orders/${esc(o.id)}" style="color:inherit;text-decoration:none"><div class="grow"><b>${esc(orderNo(o))}</b><small>${esc(o.customer_name)} · ${esc(fmtDate(o.created_at))} ${esc(fmtTime(o.created_at))}</small></div>${chip(orderStatus(o))}</a>`).join('')}</div>` : emptyState(t('riders.noHistory'));
    const TABS = { ov: overview, docs: gatedNote(t('riders.docsGated')), earn: gatedNote(t('riders.earningsGated')), hist: history };
    // Approve / reject / deactivate are Owner-only (enforced server-side by
    // approve_pending_rider and deactivate_rider); Operators see none.
    const owner = ctx.isOwner;
    const footer = r.status === 'pending'
      ? (owner ? `<button class="btn" data-reject>${esc(t('riders.reject'))}</button><button class="btn primary" data-approve>${esc(t('riders.approve'))}</button>` : '')
      : `${owner ? `<button class="link-btn rd-deactivate" data-deactivate>${esc(t('riders.deactivate'))}</button>` : ''}${digits ? `<a class="btn" href="tel:${esc(r.phone)}">${icon('phone')}${esc(t('c.call'))}</a><a class="btn" href="${wa}" target="_blank" rel="noopener">${icon('wa')}WhatsApp</a>` : ''}`;
    const m = modal({
      title: r.name, head, cls: 'rider-modal', footer,
      body: `<div class="tabs rd-tabs" role="tablist">${[['ov', 'riders.overview'], ['docs', 'riders.documents'], ['earn', 'riders.earnings'], ['hist', 'riders.history']]
        .map(([id, key], i) => `<button class="${i ? '' : 'on'}" role="tab" data-dt="${id}">${esc(t(key))}</button>`).join('')}</div>
        <div class="rd-body" data-dbody>${overview}</div>`,
      onClose: () => { if (location.hash.startsWith(`#/riders/${selected}`)) location.hash = '#/riders'; },
    });
    m.el.addEventListener('click', async e => {
      const tb = e.target.closest('[data-dt]');
      if (tb) { m.el.querySelectorAll('[data-dt]').forEach(x => x.classList.toggle('on', x === tb)); m.el.querySelector('[data-dbody]').innerHTML = TABS[tb.dataset.dt]; return; }
      const hl = e.target.closest('a.list-row');
      if (hl) { e.preventDefault(); const to = hl.getAttribute('href'); m.close(); location.hash = to; return; }
      const ap = e.target.closest('[data-approve]');
      if (ap) { try { await busy(ap, () => api.rpc('approve_pending_rider', { p_rider_id: r.id })); toast(t('riders.approved')); m.close(); load(); } catch (ex) { toast(ex.message, 'error'); } return; }
      const rj = e.target.closest('[data-reject],[data-deactivate]');
      if (rj) {
        const reject = rj.hasAttribute('data-reject');
        if (!await confirmDialog({ title: reject ? t('riders.reject') : t('riders.deactivate'), body: r.name, confirmLabel: reject ? t('riders.reject') : t('riders.deactivate'), danger: true })) return;
        try { await api.rpc('deactivate_rider', { p_rider_id: r.id }); toast(reject ? t('riders.rejected') : t('riders.deactivated')); m.close(); } catch (ex) { toast(ex.message === 'rider has active work' ? t('riders.activeWork') : ex.message, 'error'); }
      }
    });
  }

  el.addEventListener('click', async e => {
    const tb = e.target.closest('[data-tab]'); if (tb) { tab = tb.dataset.tab; paint(); return; }
    const row = e.target.closest('tr[data-id]'); if (row) { location.hash = `#/riders/${row.dataset.id}`; return; }
    if (e.target.closest('[data-add]')) { openAddRider(load); return; }
    if (e.target.closest('[data-retry]')) { load(); return; }
  });
  $('[data-q]').addEventListener('input', e => { query = e.target.value.trim().toLowerCase(); paint(); });
  load();
}

export function openAddRider(onDone) {
  const m = modal({
    title: t('riders.add'), lead: t('riders.inviteLead'),
    body: `<div class="field"><label>${esc(t('riders.name'))}</label><input class="input" name="name" maxlength="80"></div>
      <div class="field"><label>${esc(t('riders.phone'))}</label><input class="input" name="phone" inputmode="tel" placeholder="+60 12-345 6789"></div>
      <div class="field"><label>${esc(t('prof.email'))}</label><input class="input" name="email" type="email" placeholder="name@example.com"></div>
      <div class="err" data-err hidden></div>`,
    footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit>${esc(t('riders.invite'))}</button>`,
  });
  m.el.querySelector('[data-submit]').addEventListener('click', async e => {
    const f = n => m.el.querySelector(`[name=${n}]`).value.trim();
    const err = m.el.querySelector('[data-err]');
    const name = f('name'), phone = f('phone'), email = f('email');
    if (!name || !phone || !email) { err.textContent = t('c.required'); err.hidden = false; return; }
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { err.textContent = t('c.invalidEmail'); err.hidden = false; return; }
    try {
      const res = await busy(e.currentTarget, () => api.rpc('create_rider_invitation', { p_business_id: ctx.bid, p_invited_email: email, p_invited_name: name, p_invited_phone: phone }));
      m.close();
      showLink(t('riders.linkReady'), new URL(`../invite/?type=rider&token=${encodeURIComponent(res.token)}`, location.href).href);
      onDone?.();
    } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
}

export function showLink(title, link) {
  const m = modal({
    title, lead: t('riders.linkLead'),
    body: `<input class="input" readonly value="${esc(link)}" data-link>`,
    footer: `<button class="btn" data-close>${esc(t('c.close'))}</button><button class="btn primary" data-copy>${esc(t('riders.copy'))}</button>`,
  });
  m.el.querySelector('[data-copy]').addEventListener('click', async () => {
    const ok = await copyText(link);
    if (!ok) m.el.querySelector('[data-link]').select();
    toast(ok ? t('riders.copied') : link);
  });
}
