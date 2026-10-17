// CEFFLO Customer Tracking — "Report a problem" (Prosedur Aduan, stage 1).
// The customer has no account: the tracking token in the URL identifies the
// order. Delivery problems go to the driver, fraud to the business; Cefflo
// reviews both sides. Photos go through the complaint-photos function.
(function () {
  const token = new URLSearchParams(location.search).get('token');
  const link = document.querySelector('[data-report-problem]');
  if (!token || !link) { if (link) link.hidden = true; return; }
  const cfg = window.CEFFLO_CONFIG || {};
  const CATS = [
    ['damaged_lost', 'Item damaged or missing'],
    ['conduct', 'Driver behaviour'],
    ['safety', 'Safety concern'],
    ['fraud', 'Paid but never received / scam'],
    ['other', 'Something else'],
  ];
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => `&#${c.charCodeAt(0)};`);

  // Reports this customer already made for the order, with Cefflo's outcome
  // (shown here because a phone-only customer gets no email).
  const STATUS = { awaiting_reply: 'Waiting for the other side', in_review: 'Cefflo is reviewing', resolved: 'Resolved' };
  const OUTCOME = { settled: 'Settled between both sides', no_fault: 'No fault found', warning: 'A warning was given', driver_at_fault: 'The driver was at fault', vendor_at_fault: 'The business was at fault', customer_at_fault: 'The report was not upheld', false_report: 'The report was not upheld' };
  const box = document.createElement('section');
  box.className = 'cmp-status';
  box.hidden = true;
  link.closest('footer')?.before(box);
  async function showStatus() {
    try {
      const res = await fetch(`${cfg.supabaseUrl}/rest/v1/rpc/complaints_by_tracking`, { method: 'POST', headers: { apikey: cfg.supabaseAnonKey, 'Content-Type': 'application/json' }, body: JSON.stringify({ p_token: token }) });
      const list = res.ok ? await res.json() : [];
      if (!list.length) return;
      box.innerHTML = `<h3>Your reports</h3>${list.map(c => `<div class="cmp-status__row"><b>${esc(c.ref)}</b> · ${esc(STATUS[c.status] || c.status)}${c.status === 'resolved' ? `<p>${esc(OUTCOME[c.decision] || 'Resolved')}${c.decision_note ? `: ${esc(c.decision_note)}` : ''}</p>` : ''}</div>`).join('')}`;
      box.hidden = false;
    } catch { /* offline: nothing to show */ }
  }
  let photos = [];

  showStatus();

  const sheet = document.createElement('div');
  sheet.className = 'cmp-backdrop';
  sheet.hidden = true;
  sheet.innerHTML = `<form class="cmp-sheet" role="dialog" aria-modal="true" aria-labelledby="cmp-title" novalidate>
    <div class="cmp-grip"></div>
    <h2 id="cmp-title">Report a problem</h2>
    <p class="cmp-sub">Cefflo reviews your report with the delivery records and hears the other side before deciding.</p>
    <fieldset class="cmp-cats"><legend>What happened?</legend>${CATS.map(([k, l], i) => `<label><input type="radio" name="category" value="${k}" ${i ? '' : 'checked'}> ${esc(l)}</label>`).join('')}</fieldset>
    <label class="cmp-field">Describe what happened<textarea id="cmp-desc" name="description" rows="4" maxlength="3000" required></textarea></label>
    <label class="cmp-field">Your name<input id="cmp-name" name="name" autocomplete="name"></label>
    <label class="cmp-field">Email or phone, so we can reply<input id="cmp-contact" name="contact" autocomplete="email" required></label>
    <div class="cmp-field">Photos (up to 5)<input id="cmp-photos" type="file" accept="image/jpeg,image/png,image/webp" multiple><div class="cmp-thumbs"></div></div>
    <p class="cmp-err" role="alert" hidden></p>
    <div class="cmp-actions"><button type="button" class="cmp-cancel">Cancel</button><button type="submit" class="cmp-send">Send report</button></div>
  </form>`;
  document.body.appendChild(sheet);
  const form = sheet.querySelector('form'), err = sheet.querySelector('.cmp-err'), send = sheet.querySelector('.cmp-send');

  const open = () => { sheet.hidden = false; requestAnimationFrame(() => sheet.classList.add('is-open')); sheet.querySelector('#cmp-desc').focus(); };
  const close = () => { sheet.classList.remove('is-open'); setTimeout(() => { sheet.hidden = true; }, 240); };
  link.addEventListener('click', e => { e.preventDefault(); open(); });
  sheet.addEventListener('click', e => { if (e.target === sheet || e.target.closest('.cmp-cancel')) close(); });
  document.addEventListener('keydown', e => { if (e.key === 'Escape' && !sheet.hidden) close(); });

  sheet.querySelector('#cmp-photos').addEventListener('change', async e => {
    const files = [...e.target.files].slice(0, 5 - photos.length);
    for (const f of files) photos.push({ type: f.type, data: await shrink(f), name: f.name });
    e.target.value = '';
    sheet.querySelector('.cmp-thumbs').innerHTML = photos.map((p, i) => `<span>${esc(p.name)} <button type="button" data-rm="${i}" aria-label="Remove photo">×</button></span>`).join('');
  });
  sheet.querySelector('.cmp-thumbs').addEventListener('click', e => {
    const b = e.target.closest('[data-rm]'); if (!b) return;
    photos.splice(Number(b.dataset.rm), 1); b.parentElement.remove();
  });

  // Phone photos are large: scale to 1600px JPEG before sending.
  function shrink(file) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => {
        const k = Math.min(1, 1600 / Math.max(img.width, img.height));
        const c = document.createElement('canvas'); c.width = img.width * k; c.height = img.height * k;
        c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
        resolve(c.toDataURL('image/jpeg', 0.82).split(',')[1]);
        URL.revokeObjectURL(img.src);
      };
      img.onerror = reject;
      img.src = URL.createObjectURL(file);
    }).then(data => data);
  }

  async function rpc(name, body) {
    const res = await fetch(`${cfg.supabaseUrl}/rest/v1/rpc/${name}`, { method: 'POST', headers: { apikey: cfg.supabaseAnonKey, 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    const data = await res.json().catch(() => null);
    if (!res.ok) throw new Error(data?.message || 'Could not send your report.');
    return data;
  }

  form.addEventListener('submit', async e => {
    e.preventDefault();
    const v = Object.fromEntries(new FormData(form));
    err.hidden = true;
    if (String(v.description || '').trim().length < 10) { err.textContent = 'Tell us a little more (at least 10 characters).'; err.hidden = false; return; }
    if (String(v.contact || '').trim().length < 6) { err.textContent = 'Add an email or phone number so we can reply.'; err.hidden = false; return; }
    send.disabled = true; send.textContent = 'Sending…';
    try {
      const r = await rpc('file_complaint_by_tracking', { p_token: token, p_category: v.category, p_description: v.description.trim(), p_name: String(v.name || '').trim(), p_contact: v.contact.trim() });
      if (photos.length) {
        await fetch(`${cfg.supabaseUrl}/functions/v1/complaint-photos`, { method: 'POST', headers: { apikey: cfg.supabaseAnonKey, 'Content-Type': 'application/json' }, body: JSON.stringify({ token, complaint_id: r.id, photos: photos.map(p => ({ type: 'image/jpeg', data: p.data })) }) }).catch(() => {});
      }
      showStatus();
      form.innerHTML = `<div class="cmp-grip"></div><h2>Report sent</h2><p class="cmp-sub">Your case number is <b>${esc(r.ref)}</b>. The other side has 48 hours to respond, then Cefflo reviews and contacts you.</p><div class="cmp-actions"><button type="button" class="cmp-cancel cmp-send">Done</button></div>`;
    } catch (x) {
      err.textContent = x.message === 'too many complaints for this order' ? 'You already reported this order. Cefflo is reviewing it.' : 'Could not send your report. Check your connection and try again.';
      err.hidden = false; send.disabled = false; send.textContent = 'Send report';
    }
  });
})();
