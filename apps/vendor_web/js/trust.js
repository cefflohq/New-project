// Business verification and Complaints (Founder 2026-10-17), as in the
// Vendor app. Verification: the owner sends the SSM number, the SSM
// certificate and their IC; orders stay blocked until Cefflo verifies it.
// Complaints: reports the business made and reports about it, answered
// within 48 h; Cefflo decides with both sides and the order's records.
import { t, fmtDate } from './i18n.js';
import { api } from './api.js';
import { ctx } from './store.js';
import { isDemo } from './demo.js';
import { esc, icon, loadingRows, emptyState, errorState, toast, busy } from './ui.js';
import { readOnly } from './demo.js';

// A status pill in the page's own chip styles (active / pending / warning / danger).
const chip = (label, tone) => `<span class="chip ${tone}"><i class="dot"></i>${esc(label)}</span>`;

const newId = () => (crypto.randomUUID ? crypto.randomUUID() : String(Date.now()) + Math.random().toString(16).slice(2));
const ext = f => (f.type === 'application/pdf' ? 'pdf' : f.type === 'image/png' ? 'png' : 'jpg');

// ------------------------------------------------------------ verification
export async function verification(page) {
  page.innerHTML = `<h2>${esc(t('bv.title'))}</h2><p class="lead">${esc(t('bv.lead'))}</p><div data-body class="bv-card">${loadingRows(3)}</div>`;
  const body = page.querySelector('[data-body]');
  const bid = ctx.business?.business_id;
  let v = null;
  try { v = isDemo() ? null : await api.rpc('my_business_verification', { p_business_id: bid }); }
  catch (e) { body.innerHTML = errorState(e); return; }
  const status = v?.status || null;
  const STATUS = {
    pending: [t('bv.pending'), 'delivery', t('bv.pendingBody')],
    verified: [t('bv.verified'), 'active', t('bv.verifiedBody')],
    rejected: [t('bv.rejected'), 'issue', t('bv.rejectedBecause').replace('{reason}', v?.reject_reason || '')],
  }[status] || [t('bv.none'), 'pending', t('bv.noneBody')];
  const canSubmit = !status || status === 'rejected';
  // IC: camera only (capture) so the photo is taken now; SSM optional.
  const fileRow = (name, label, accept, cam) => `<label class="field"><span>${esc(label)}</span><input type="file" name="${name}" accept="${accept}"${cam ? ' capture="environment"' : ''}></label>`;
  body.innerHTML = `<div style="margin-bottom:16px">
      <div class="bv-status">${chip(STATUS[0], STATUS[1])}</div>
      <p class="lead" style="margin:6px 0 0">${esc(STATUS[2])}</p>
      ${v?.owner_name && v?.owner_ic_last4 ? `<p class="lead" style="margin:4px 0 0">${esc(t('bv.readResult').replace('{name}', v.owner_name).replace('{last4}', v.owner_ic_last4))}</p>` : ''}
    </div>
    ${canSubmit ? `<form class="form" data-bv novalidate style="display:grid;gap:12px;max-width:560px">
      <p class="lead" style="margin:0">${esc(t('bv.autoRead'))}</p>
      ${camRow('icFront', t('bv.icFront'))}
      ${camRow('icBack', t('bv.icBack'))}
      ${fileRow('ssmDoc', t('bv.ssmOptional'), 'application/pdf,image/jpeg,image/png', false)}
      <p class="err" data-err hidden></p>
      <div><button class="btn primary" type="submit">${esc(t('bv.submit'))}</button></div>
    </form>` : ''}`;
  const form = body.querySelector('[data-bv]');
  if (!form) return;
  // IC photos come only from the card camera (no gallery).
  const shots = {};
  form.addEventListener('click', async e => {
    const b = e.target.closest('[data-cam]');
    if (!b) return;
    e.preventDefault();
    const blob = await captureIdCard(b.dataset.label);
    if (!blob) return;
    shots[b.dataset.cam] = new File([blob], `${b.dataset.cam}.jpg`, { type: 'image/jpeg' });
    const thumb = form.querySelector(`[data-thumb="${b.dataset.cam}"]`);
    thumb.src = URL.createObjectURL(blob); thumb.hidden = false;
    b.textContent = t('bv.retake');
  });
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const err = form.querySelector('[data-err]');
    const f = new FormData(form);
    const front = shots.icFront || null, back = shots.icBack || null;
    const ssm = (x => (x && x.size ? x : null))(f.get('ssmDoc'));
    const fail = m => { err.textContent = m; err.hidden = false; };
    err.hidden = true;
    if (!front || !back) return fail(t('bv.icMissing'));
    if ([front, back, ssm].some(x => x && x.size > 10 * 1024 * 1024)) return fail(t('bv.tooBig'));
    if (isDemo()) return fail(readOnly().message);
    const btn = form.querySelector('[type=submit]');
    try { await busy(btn, async () => {
      const up = async (x, name) => { const path = `${bid}/${newId()}-${name}.${ext(x)}`; await api.upload('cefflo-business-documents', path, x); return path; };
      const r = await api.fn('business-verification', {
        business_id: bid, ic_front_path: await up(front, 'ic-front'), ic_back_path: await up(back, 'ic-back'), ssm_path: ssm ? await up(ssm, 'ssm') : null,
      });
      toast(r?.read ? t('bv.readResult').replace('{name}', r.owner_name).replace('{last4}', r.owner_ic_last4) : t('bv.sent'));
      verification(page);
    }); } catch (ex) { fail(ex.message === 'business already verified' ? t('bv.verifiedBody') : ex.message); }
  });
}

const camRow = (name, label) => `<div class="field"><span>${esc(label)}</span>
  <div style="display:flex;gap:12px;align-items:center"><img data-thumb="${name}" alt="" hidden style="width:76px;height:48px;object-fit:cover;border-radius:6px">
  <button type="button" class="btn" data-cam="${name}" data-label="${esc(label)}">${esc(t('bv.snap'))}</button></div></div>`;

// ID card camera (Founder 2026-10-17), as in the apps: a card-shaped frame
// over the live camera and three tips; only the inside of the frame is
// kept. The browser has no live card detection, so there is a shutter.
const CARD = 85.6 / 54, FRAME_W = 0.88;
function captureIdCard(title) {
  return new Promise(async resolve => {
    let stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: { ideal: 'environment' }, width: { ideal: 1920 } }, audio: false });
    } catch { toast(t('bv.camUnavailable')); return resolve(null); }
    const root = document.createElement('div');
    root.style.cssText = 'position:fixed;inset:0;z-index:200;background:#000;color:#fff;display:flex;flex-direction:column';
    root.innerHTML = `<div style="display:flex;align-items:center;gap:10px;padding:14px 16px"><button data-x class="icon-btn" style="color:#fff" aria-label="${esc(t('c.close'))}">${icon('x')}</button><b>${esc(title)}</b></div>
      <div data-stage style="flex:1;display:flex;align-items:center;justify-content:center;min-height:0">
        <div style="position:relative;max-width:100%;max-height:100%"><video data-v playsinline muted autoplay style="display:block;max-width:100%;max-height:70vh"></video>
          <div data-f style="position:absolute;left:50%;top:50%;width:${FRAME_W * 100}%;aspect-ratio:${CARD};transform:translate(-50%,-50%);border:3px solid #FFC93C;border-radius:14px;box-shadow:0 0 0 9999px rgba(0,0,0,.6)"></div></div>
        <img data-shot alt="" hidden style="max-width:92%;max-height:70vh;border-radius:12px"></div>
      <div style="padding:12px 16px 24px;display:grid;gap:8px">
        <div data-tips style="display:grid;gap:4px;font-size:13px;opacity:.9"><div>▢ ${esc(t('bv.tipFrame'))}</div><div>☀ ${esc(t('bv.tipLight'))}</div><div>✦ ${esc(t('bv.tipGlare'))}</div></div>
        <button class="btn primary" data-snap style="width:100%">${esc(t('bv.snap'))}</button>
        <button class="btn primary" data-use hidden style="width:100%">${esc(t('bv.use'))}</button>
        <button class="btn" data-again hidden style="width:100%">${esc(t('bv.retake'))}</button></div>`;
    document.body.appendChild(root);
    const video = root.querySelector('[data-v]'), shotImg = root.querySelector('[data-shot]');
    video.srcObject = stream;
    let blob = null;
    const done = v => { stream.getTracks().forEach(tr => tr.stop()); root.remove(); resolve(v); };
    const show = shot => {
      root.querySelector('[data-v]').parentElement.hidden = shot; shotImg.hidden = !shot;
      root.querySelector('[data-tips]').hidden = shot; root.querySelector('[data-snap]').hidden = shot;
      root.querySelector('[data-use]').hidden = !shot; root.querySelector('[data-again]').hidden = !shot;
    };
    root.addEventListener('click', e => {
      if (e.target.closest('[data-x]')) return done(null);
      if (e.target.closest('[data-again]')) { blob = null; return show(false); }
      if (e.target.closest('[data-use]')) return done(blob);
      if (e.target.closest('[data-snap]')) {
        const w = video.videoWidth, h = video.videoHeight;
        if (!w) return;
        const cw = Math.round(w * FRAME_W), ch = Math.round(cw / CARD);
        const c = document.createElement('canvas'); c.width = cw; c.height = ch;
        c.getContext('2d').drawImage(video, (w - cw) / 2, (h - ch) / 2, cw, ch, 0, 0, cw, ch);
        c.toBlob(b => { blob = b; shotImg.src = URL.createObjectURL(b); show(true); }, 'image/jpeg', 0.88);
      }
    });
  });
}

/** The Today banner: orders are refused until the business is verified. */
export async function verificationBanner() {
  if (isDemo() || !ctx.business) return '';
  try {
    const v = await api.rpc('my_business_verification', { p_business_id: ctx.business.business_id });
    if (v?.status === 'verified') return '';
    const msg = v?.status === 'pending' ? t('bv.bannerPending') : ctx.isOwner ? t('bv.bannerBody') : t('bv.bannerStaff');
    return `<a class="card" href="${ctx.isOwner ? '#/settings/verification' : '#/today'}" style="display:flex;gap:12px;align-items:center;padding:14px 16px;margin-bottom:14px;text-decoration:none;color:inherit;border-color:var(--danger)">
      ${icon('info')}<span style="flex:1"><b>${esc(t('bv.bannerTitle'))}</b><br><small>${esc(msg)}</small></span>${ctx.isOwner ? icon('right') : ''}</a>`;
  } catch { return ''; }
}

// ------------------------------------------------------------- complaints
const CAT = () => ({ damaged_lost: t('cmp.catDamaged'), conduct: t('cmp.catConduct'), safety: t('cmp.catSafety'), unpaid: t('cmp.catUnpaid'), fraud: t('cmp.catFraud'), other: t('cmp.catOther') });
const DEC = () => ({ settled: t('cmp.decSettled'), no_fault: t('cmp.decNoFault'), warning: t('cmp.decWarning'), driver_at_fault: t('cmp.decDriver'), vendor_at_fault: t('cmp.decVendor'), customer_at_fault: t('cmp.decCustomer'), false_report: t('cmp.decFalse') });
const PARTY = r => ({ customer: t('cmp.customer'), driver: t('cmp.driver') }[r] || t('cmp.business'));
const statusChip = c => (c.status === 'awaiting_reply' ? chip(t('cmp.awaiting'), 'pending') : c.status === 'in_review' ? chip(t('cmp.review'), 'delivery') : chip(t('cmp.resolved'), 'active'));
const when = iso => (iso ? new Date(iso).toLocaleString(undefined, { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' }) : '');

async function loadComplaints() {
  if (isDemo()) return [];
  const list = await api.rpc('my_complaints');
  for (const c of list || []) for (const e of c.entries || []) {
    if (e.file_path) e.url = await api.signedUrl('cefflo-complaint-evidence', e.file_path).catch(() => '');
  }
  return list || [];
}

export async function complaints(page, openId) {
  page.innerHTML = `<h2>${esc(t('cmp.title'))}</h2><p class="lead">${esc(t('cmp.lead'))}</p><div data-body class="cmp-card">${loadingRows(3)}</div>`;
  const body = page.querySelector('[data-body]');
  let all;
  try { all = await loadComplaints(); } catch (e) { body.innerHTML = errorState(e); return; }
  if (openId) return detail(page, all.find(c => c.id === openId), all);
  let tab = 'open';
  const paint = () => {
    const list = all.filter(c => (c.status === 'resolved') === (tab === 'resolved'));
    body.innerHTML = `<div class="tabs" role="tablist" style="margin-bottom:12px">
        <button class="tab ${tab === 'open' ? 'on' : ''}" data-tab="open">${esc(t('cmp.tabOpen'))}</button>
        <button class="tab ${tab === 'resolved' ? 'on' : ''}" data-tab="resolved">${esc(t('cmp.tabResolved'))}</button></div>
      ${list.length ? `<div style="display:grid;gap:10px">${list.map(c => {
        const mine = c.side === 'complainant';
        const due = !mine && c.status === 'awaiting_reply' && !c.replied;
        return `<button class="card" data-open="${esc(c.id)}" style="text-align:left;padding:14px 16px;cursor:pointer">
          <div style="display:flex;gap:10px;justify-content:space-between;align-items:center"><b>${esc(c.ref)} · ${esc(CAT()[c.category])}</b>${statusChip(c)}</div>
          <small class="muted">${esc(mine ? `${t('cmp.youReported')} · ${c.rider_name || ''}` : `${t('cmp.aboutYou')} · ${PARTY(c.complainant_role)}`)}</small>
          ${due ? `<div style="color:var(--danger);font-size:13px;margin-top:4px">${esc(t('cmp.replyBy').replace('{date}', when(c.reply_due_at)))}</div>` : ''}
        </button>`; }).join('')}</div>` : emptyState(t('cmp.empty'))}`;
  };
  paint();
  body.addEventListener('click', e => {
    const tb = e.target.closest('[data-tab]');
    if (tb) { tab = tb.dataset.tab; return paint(); }
    const o = e.target.closest('[data-open]');
    if (o) location.hash = `#/settings/complaints/${o.dataset.open}`;
  });
}

function detail(page, c, all) {
  const body = page.querySelector('[data-body]');
  if (!c) { body.innerHTML = emptyState(t('cmp.empty')); return; }
  const mine = c.side === 'complainant';
  const canReply = !mine && c.status !== 'resolved';
  const who = r => (r === 'complainant' ? (mine ? t('cmp.yourSide') : t('cmp.theirSide')) : r === 'respondent' ? (mine ? t('cmp.theirSide') : t('cmp.yourSide')) : 'Cefflo');
  page.querySelector('h2').textContent = c.ref;
  body.innerHTML = `<p><a href="#/settings/complaints">← ${esc(t('cmp.title'))}</a></p>
    <div class="card" style="padding:16px;margin-bottom:12px">
      <div style="display:flex;justify-content:space-between;align-items:center"><b>${esc(CAT()[c.category])}</b>${statusChip(c)}</div>
      ${c.order_ref ? `<small class="muted">${esc(t('cmp.order'))} ${esc(c.order_ref)}</small><br>` : ''}
      ${c.status === 'awaiting_reply' ? `<small class="muted">${esc(t('cmp.replyBy').replace('{date}', when(c.reply_due_at)))}</small>` : ''}
    </div>
    ${c.status === 'resolved' ? `<div class="card" style="padding:16px;margin-bottom:12px"><b>${esc(t('cmp.outcome'))}</b><p style="margin:6px 0 0">${esc(DEC()[c.decision] || t('cmp.resolved'))}</p>${c.decision_note ? `<small class="muted">${esc(c.decision_note)}</small>` : ''}</div>` : ''}
    <div style="display:grid;gap:10px">${(c.entries || []).map(e => `<div class="card" style="padding:14px 16px">
      <small class="muted">${esc(who(e.author_role))} · ${esc(when(e.created_at))}</small>
      ${e.body ? `<p style="margin:6px 0 0;white-space:pre-wrap">${esc(e.body)}</p>` : ''}
      ${e.url ? `<a href="${esc(e.url)}" target="_blank" rel="noopener"><img src="${esc(e.url)}" alt="" style="margin-top:8px;max-width:100%;max-height:240px;border-radius:12px"></a>` : ''}
    </div>`).join('')}</div>
    ${canReply ? `<form data-reply novalidate style="display:grid;gap:12px;margin-top:16px;max-width:620px">
      <h3 style="margin:0">${esc(t('cmp.giveSide'))}</h3>
      <textarea name="body" rows="5" placeholder="${esc(t('cmp.replyHint'))}" maxlength="3000"></textarea>
      <label class="field"><span>${esc(t('cmp.photos'))}</span><input type="file" name="photos" accept="image/jpeg,image/png" multiple></label>
      <p class="err" data-err hidden></p>
      <div><button class="btn primary" type="submit">${esc(t('cmp.sendReply'))}</button></div>
    </form>` : ''}`;
  const form = body.querySelector('[data-reply]');
  if (!form) return;
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const err = form.querySelector('[data-err]');
    const text = form.body.value.trim();
    const photos = [...form.photos.files].slice(0, 5);
    if (text.length < 5) { err.textContent = t('cmp.tooShort'); err.hidden = false; return; }
    if (isDemo()) { err.textContent = readOnly().message; err.hidden = false; return; }
    const btn = form.querySelector('[type=submit]');
    try { await busy(btn, async () => {
      const uid = ctx.user?.id;
      const paths = [];
      for (const p of photos) {
        const path = `${uid}/complaints/${newId()}.${ext(p)}`;
        await api.upload('cefflo-complaint-evidence', path, p);
        paths.push(path);
      }
      await api.rpc('reply_complaint', { p_id: c.id, p_body: text, p_photos: paths });
      toast(t('cmp.replySent'));
      complaints(page, c.id);
    }); } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
}
