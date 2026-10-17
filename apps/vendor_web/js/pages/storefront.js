// Storefront (V-31-V-33, D-55, Storefront V1 Founder 2026-10-01). Same
// contracts as Vendor App: get_storefront (created unpublished on first
// open), set_storefront_published, save_storefront_appearance (template +
// theme), hero image as a new object in cefflo-storefront-assets. The public
// link is {storefront base}{slug}; Owner + Operator on the server.
import { t } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { esc, icon, chip, loadingRows, errorState, toast, busy, copyText } from '../ui.js';
import qrcode from '../lib/qrcode.js';

// The Template Library: five templates (Menu, Showcase, Basket, Service,
// Spotlight), in library order. Ids,
// names, categories and default colours match store/templates.js
// (CEFFLO_TEMPLATE_ORDER) and the Vendor App registry.
const TEMPLATES = [
  { id: 'warung', name: 'Menu', cat: 'food', primary: '#169A49', secondary: '#E11D2E', hero: false },
  { id: 'tailor', name: 'Showcase', cat: 'retail', primary: '#111111', secondary: '#F59E6B' },
  { id: 'care', name: 'Basket', cat: 'retail', primary: '#1677D8', secondary: '#E8F2FD' },
  { id: 'service', name: 'Service', cat: 'services', primary: '#5B7CF6', secondary: '#FACC15' },
  { id: 'pour', name: 'Spotlight', cat: 'gifts', primary: '#F8BB5E', secondary: '#111111', hero: false },
];
const CATS = ['food', 'retail', 'gifts', 'services'];
// Earlier templates (CEFFLO_TEMPLATE_LEGACY): not offered any more, but a
// storefront saved on one still shows it as the active template.
const LEGACY = [
  { id: 'homefood', name: 'Dapur', primary: '#C2410C', secondary: '#FFF7ED' },
  { id: 'bakery', name: 'Patisserie', primary: '#9D174D', secondary: '#FDF2F8' },
  { id: 'eatery', name: 'Kedai Makan', primary: '#B91C1C', secondary: '#FEF2F2' },
  { id: 'cafe', name: 'Kafe', primary: '#1F2937', secondary: '#F3F4F6' },
  { id: 'catering', name: 'Katering', primary: '#0F766E', secondary: '#F0FDFA' },
  { id: 'frozen', name: 'Sejuk Beku', primary: '#1D4ED8', secondary: '#EFF6FF' },
  { id: 'florist', name: 'Florist', primary: '#3F3F46', secondary: '#FAF7F2' },
  { id: 'laundry', name: 'Dobi', primary: '#0369A1', secondary: '#F0F9FF' },
  { id: 'retail', name: 'Jenama', primary: '#111827', secondary: '#F59E0B' },
  { id: 'outlets', name: 'Rangkaian', primary: '#4338CA', secondary: '#EEF2FF' },
  { id: 'capsule', name: 'Capsule', primary: '#C8234F', secondary: '#F7C531' },
  { id: 'kit', name: 'Kit', primary: '#253D6B', secondary: '#E1293F' },
  { id: 'brew', name: 'Brew', primary: '#4B2A15', secondary: '#D3A06A' },
  { id: 'crimson', name: 'Crimson', primary: '#B82838', secondary: '#2A2A2A' },
  { id: 'lift', name: 'Lift', primary: '#111111', secondary: '#E5332A' },
  { id: 'harvest', name: 'Harvest', primary: '#111111', secondary: '#3BAA4A' },
  { id: 'botanic', name: 'Botanic', primary: '#86A98F', secondary: '#2F4A3A' },
  { id: 'combo', name: 'Combo', primary: '#F26B2C', secondary: '#8E9BF5', hero: false },
  { id: 'discover', name: 'Discover', primary: '#22C55E', secondary: '#16A34A' },
  { id: 'atelier', name: 'Atelier', primary: '#111111', secondary: '#E35B2C' },
  { id: 'sprint', name: 'Sprint', primary: '#6B3BE0', secondary: '#FF7A1A' },
  { id: 'splash', name: 'Splash', primary: '#2563EB', secondary: '#FACC15' },
  { id: 'collector', name: 'Collector', primary: '#111111', secondary: '#F2F2F4', hero: false },
];
const PREVIEW_SCREENS = [['', 'sf.pvHome'], ['p/first', 'sf.pvProduct'], ['cart', 'sf.pvCart']];
const LOGO_TYPES = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const HERO_TYPES = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const base = () => window.CEFFLO_CONFIG?.storefrontBaseUrl || 'https://order.cefflo.com/';

function qrSvg(text) {
  const code = qrcode(0, 'M');
  code.addData(text);
  code.make();
  return code.createSvgTag({ cellSize: 5, margin: 2, scalable: true });
}

export default function storefront({ el, setHeader }) {
  setHeader(t('sf.title'));
  el.innerHTML = loadingRows(4);
  let dlv = {}, subs = [];
  let sf = null, tpl = 'warung', theme = {}, heroFile = null, heroData = null, logoFile = null, logoData = null, pv = null, screen = '', cat = '';
  let frame = null, frameReady = false;
  const def = () => TEMPLATES.find(x => x.id === tpl) || LEGACY.find(x => x.id === tpl) || TEMPLATES[0];
  const sfOrigin = () => new URL(base(), location.href).origin;

  // The live preview is the real storefront renderer (store/?embed=1), fed
  // this business's storefront_preview payload plus the unsaved edits, as
  // in the Vendor App. Ordering is disabled inside the preview.
  const payload = () => {
    const d = def(), cur = readForm();
    const store = { ...(pv || { slug: sf?.slug || 'preview', business: { name: ctx.business?.business_name || '' }, categories: [], products: [] }) };
    store.theme = { ...(store.theme || {}), accent: cur.accent || d.primary, secondary: cur.secondary || d.secondary, ...(cur.tagline ? { tagline: cur.tagline } : {}) };
    store.template_key = tpl;
    if (heroData) store.hero_url = heroData;
    if (logoData) store.logo_url = logoData;
    else if (theme.logo_path) store.logo_url = api.publicUrl('cefflo-storefront-assets', theme.logo_path);
    return store;
  };
  const post = () => { if (frame?.contentWindow && frameReady) frame.contentWindow.postMessage({ type: 'cefflo-storefront-preview', store: payload() }, sfOrigin()); };
  const route = () => {
    if (screen !== 'p/first') return screen;
    const first = pv?.products?.[0]?.id; return first ? `p/${first}` : '';
  };
  const src = () => `${new URL('preview', base()).href}?embed=1&template=${encodeURIComponent(tpl)}${route() ? `#/${route()}` : ''}`;
  const onMessage = e => {
    if (!el.isConnected) { window.removeEventListener('message', onMessage); return; }
    if (e.origin !== sfOrigin() || !frame || e.source !== frame.contentWindow) return;
    if (e.data?.type === 'cefflo-storefront-ready') { frameReady = true; post(); }
  };
  window.addEventListener('message', onMessage);

  const readForm = () => {
    const v = s => el.querySelector(s);
    return v('[data-accent]') ? { accent: v('[data-accent]').value.toUpperCase(), secondary: v('[data-secondary]').value.toUpperCase(), tagline: v('[data-tagline]').value.trim() }
      : { accent: theme.accent, secondary: theme.secondary, tagline: theme.tagline || '' };
  };

  // Delivery & packages (Founder 2026-10-17): fee per drop = the driver's pay,
  // never free; weekdays; shifts (batches); package lengths.
  const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const deliveryCard = () => {
    const days = dlv.days || [1, 2, 3, 4, 5], weeks = dlv.weeks || [1, 2, 4], shifts = dlv.shifts || [];
    return `<div class="card" style="padding:20px"><h3 style="margin:0 0 4px">${esc(t('sf.delivery'))}</h3><p class="desc">${esc(t('sf.deliveryLead'))}</p>
      <div class="g4" style="align-items:end"><div class="field"><label>${esc(t('sf.fee'))}</label><input class="input" type="number" min="0" max="1000" step="0.5" data-fee value="${esc(dlv.fee ?? '')}" placeholder="5.00"></div></div>
      <div class="field"><label>${esc(t('sf.days'))}</label><div style="display:flex;gap:6px;flex-wrap:wrap">${DAYS.map((d, i) => `<button class="opt ${days.includes(i + 1) ? 'on' : ''}" data-dday="${i + 1}" style="min-width:52px">${esc(t(`sf.d${i + 1}`))}</button>`).join('')}</div></div>
      <div class="field"><label>${esc(t('sf.weeks'))}</label><div style="display:flex;gap:6px;flex-wrap:wrap">${[1, 2, 3, 4].map(w => `<button class="opt ${weeks.includes(w) ? 'on' : ''}" data-dweek="${w}">${esc(t(w === 1 ? 'sf.week1' : 'sf.weekN', { n: w }))}</button>`).join('')}</div><small class="hint">${esc(t('sf.weeksHint'))}</small></div>
      <div class="field"><label>${esc(t('sf.shifts'))}</label><div style="display:grid;gap:8px" data-shifts>${shifts.map((x, i) => `<div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap"><input class="input" data-sname="${i}" value="${esc(x.name)}" placeholder="${esc(t('sf.shiftName'))}" style="flex:1;min-width:140px"><input class="input" type="time" data-sfrom="${i}" value="${esc(x.from)}" style="width:120px"><span>–</span><input class="input" type="time" data-sto="${i}" value="${esc(x.to)}" style="width:120px"><button class="btn sm" data-sdel="${i}">${esc(t('sf.shiftRemove'))}</button></div>`).join('')}</div>
        ${shifts.length < 4 ? `<button class="btn sm" data-sadd style="margin-top:8px">${esc(t('sf.shiftAdd'))}</button>` : ''}<small class="hint">${esc(t('sf.shiftsHint'))}</small></div>
      <div class="err" data-derr hidden></div>
      <div style="display:flex;justify-content:flex-end"><button class="btn primary" data-dsave>${esc(t('c.save'))}</button></div></div>`;
  };
  const subsCard = () => {
    if (!subs.length) return '';
    return `<div class="card" style="padding:20px"><h3 style="margin:0 0 4px">${esc(t('sf.subs'))}</h3><p class="desc">${esc(t('sf.subsLead'))}</p>
      <div style="display:grid;gap:14px">${subs.map(x => `<div style="border:1px solid var(--line);border-radius:12px;padding:12px">
        <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap"><b>${esc(x.customer_name)}</b><small class="hint">${esc(x.customer_phone)}</small>${chip(x.status === 'active' ? 'active' : 'pending')}
          ${x.status === 'active' ? `<button class="btn sm" data-scancel="${x.id}" style="margin-left:auto">${esc(t('sf.subCancel'))}</button>` : ''}</div>
        <small class="hint">${esc((x.days || []).map(d => DAYS[d - 1]).join(', '))} × ${x.weeks} · ${esc(x.shift?.name || '')}</small>
        <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:8px">${(x.deliveries || []).map(d => `<span class="chip" title="${esc(d.status)}" style="${d.status === 'skipped' ? 'text-decoration:line-through;opacity:.5' : ''}">${esc(new Date(d.date + 'T00:00').toLocaleDateString(undefined, { weekday: 'short', day: 'numeric', month: 'short' }))}${d.multiplier > 1 ? ` ×${d.multiplier}` : ''}
          ${d.status === 'scheduled' ? `<button class="link" data-dskip="${d.id}" title="${esc(t('sf.skip'))}">✕</button><button class="link" data-dmove="${d.id}" data-month="${d.date.slice(0, 7)}" title="${esc(t('sf.move'))}">↻</button>` : ''}</span>`).join('')}</div></div>`).join('')}</div></div>`;
  };
  const readDelivery = () => {
    const shifts = [...el.querySelectorAll('[data-sname]')].map(n => { const i = n.dataset.sname; return { name: n.value.trim(), from: el.querySelector(`[data-sfrom="${i}"]`).value, to: el.querySelector(`[data-sto="${i}"]`).value }; });
    const fee = el.querySelector('[data-fee]').value;
    return { ...dlv, fee: fee === '' ? null : Number(fee), shifts };
  };

  const paint = () => {
    const link = base() + sf.slug;
    const cur = def();
    el.innerHTML = `<div style="display:grid;gap:16px;max-width:1180px">
      <div class="card" style="padding:20px"><div style="display:flex;align-items:center;gap:12px"><h3 style="margin:0">${esc(t('sf.yours'))}</h3>${chip(sf.published ? 'active' : 'pending')}
          <button class="btn ${sf.published ? '' : 'primary'} sm" data-publish style="margin-left:auto">${esc(t(sf.published ? 'sf.unpublish' : 'sf.publish'))}</button></div>
        <p class="desc">${esc(t(sf.published ? 'sf.liveLead' : 'sf.draftLead'))}</p>
        <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px;align-items:center">
          <div style="width:200px;height:200px">${qrSvg(link)}</div>
          <div><div class="field"><label>${esc(t('sf.link'))}</label><input class="input" readonly data-link value="${esc(link)}"></div>
            <div style="display:flex;gap:8px;flex-wrap:wrap">
              <button class="btn primary sm" data-copy>${esc(t('riders.copy'))}</button>
              ${navigator.share ? `<button class="btn sm" data-share>${esc(t('invite.share'))}</button>` : ''}
              <a class="btn sm" href="${esc(link)}" target="_blank" rel="noopener">${esc(t('sf.open'))}</a></div></div></div></div>
      <div style="display:grid;grid-template-columns:minmax(0,1fr) 340px;gap:16px;align-items:start" class="sf-split">
        <div style="display:grid;gap:16px;min-width:0">
          <div class="card" style="padding:20px"><h3 style="margin:0 0 4px">${esc(t('sf.template'))}</h3><p class="desc">${esc(t('sf.templateLead'))}</p>
            <div class="tabs" style="margin-bottom:12px;flex-wrap:wrap">${['', ...CATS].map(k => `<button class="tab ${cat === k ? 'on' : ''}" data-cat="${k}">${esc(t(k ? `sf.cat.${k}` : 'sf.cat.all'))}</button>`).join('')}</div>
            <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:10px">${[...(LEGACY.some(x => x.id === sf.template_key) && !cat ? LEGACY.filter(x => x.id === sf.template_key) : []), ...TEMPLATES.filter(x => !cat || x.cat === cat)].map(x => `<button class="opt ${x.id === tpl ? 'on' : ''}" data-tpl="${x.id}" style="display:flex;flex-direction:column;align-items:flex-start;gap:6px;text-align:left">
              <span style="display:flex;gap:4px"><i style="width:18px;height:18px;border-radius:50%;background:${x.primary};border:1px solid var(--line)"></i><i style="width:18px;height:18px;border-radius:50%;background:${x.secondary};border:1px solid var(--line)"></i></span>
              <b>${esc(x.name)}</b><small>${esc(t(`tpl.${x.id}`))}</small>
              ${x.id === sf.template_key ? `<small style="color:var(--ok,#047857);font-weight:600">● ${esc(t(LEGACY.some(l => l.id === x.id) ? 'sf.activeEarlier' : 'sf.active'))}</small>` : x.id === tpl ? `<small style="color:var(--primary);font-weight:600">${esc(t('sf.previewing'))}</small>` : ''}</button>`).join('')}</div></div>
          <div class="card" style="padding:20px"><h3 style="margin:0 0 4px">${esc(t('sf.appearance'))}</h3><p class="desc">${esc(t('sf.appearanceLead'))}</p>
            <div class="g4" style="align-items:end">
              <div class="field"><label>${esc(t('sf.accent'))}</label><input class="input" type="color" data-accent value="${esc(theme.accent || cur.primary)}"></div>
              <div class="field"><label>${esc(t('sf.secondary'))}</label><input class="input" type="color" data-secondary value="${esc(theme.secondary || cur.secondary)}"></div></div>
            <div class="field"><label>${esc(t('sf.tagline'))}</label><input class="input" data-tagline maxlength="120" value="${esc(theme.tagline || '')}"></div>
            <div class="field"><label>${esc(t('sf.logo'))}</label>
              <div style="display:flex;gap:12px;align-items:center">${theme.logo_path || logoFile ? `<img data-logoimg src="${esc(logoData || api.publicUrl('cefflo-storefront-assets', theme.logo_path))}" alt="" style="width:56px;height:56px;object-fit:cover;border-radius:12px;border:1px solid var(--line)">` : ''}
                <button class="btn sm" data-logo>${esc(t(theme.logo_path || logoFile ? 'sf.logoChange' : 'sf.logoAdd'))}</button>
                <input type="file" accept="image/jpeg,image/png,image/webp" hidden data-logofile></div>
              <small class="hint">${esc(t('sf.logoHint'))}</small></div>
            ${cur.hero === false ? '' : `<div class="field"><label>${esc(t('sf.hero'))}</label>
              <div style="display:flex;gap:12px;align-items:center">${theme.hero_path || heroFile ? `<img data-heroimg src="${esc(heroData || api.publicUrl('cefflo-storefront-assets', theme.hero_path))}" alt="" style="width:160px;height:90px;object-fit:cover;border-radius:8px">` : ''}
                <button class="btn sm" data-hero>${esc(t(theme.hero_path || heroFile ? 'sf.heroChange' : 'sf.heroAdd'))}</button>
                <input type="file" accept="image/jpeg,image/png,image/webp" hidden data-herofile></div>
              <small class="hint">${esc(t('sf.heroHint'))}</small></div>`}
            <div class="err" data-err hidden></div>
            <div style="display:flex;justify-content:flex-end;align-items:center;gap:12px;flex-wrap:wrap">${sf.published ? `<small class="hint">${esc(t('sf.applyLive'))}</small>` : ''}<button class="btn primary" data-save>${esc(t('sf.apply'))}</button></div></div>
          ${deliveryCard()}
          ${subsCard()}</div>
        <div class="card" style="padding:16px;position:sticky;top:16px"><h3 style="margin:0 0 4px">${esc(t('sf.preview'))}</h3><p class="desc" style="margin-bottom:10px">${esc(t('sf.previewLead'))}</p>
          <div class="tabs" style="margin-bottom:12px">${PREVIEW_SCREENS.map(([r, k]) => `<button class="tab ${screen === r ? 'on' : ''}" data-screen="${r}">${esc(t(k))}</button>`).join('')}</div>
          <div style="width:308px;height:667px;margin:0 auto;border-radius:28px;overflow:hidden;border:6px solid #111;background:#fff">
            <iframe data-frame title="${esc(t('sf.preview'))}" style="width:390px;height:844px;border:0;transform:scale(.7744);transform-origin:0 0" src="${esc(src())}"></iframe></div></div></div></div>`;
    frame = el.querySelector('[data-frame]'); frameReady = false;
  };

  const load = async () => {
    try {
      const [res, p] = await Promise.all([
        api.rpc('get_storefront', { p_business_id: ctx.bid }),
        api.rpc('storefront_preview', { p_business_id: ctx.bid }).catch(() => null),
      ]);
      sf = Array.isArray(res) ? res[0] : res;
      pv = p && typeof p === 'object' ? p : null;
      tpl = [...TEMPLATES, ...LEGACY].some(x => x.id === sf.template_key) ? sf.template_key : 'warung';
      theme = { ...(sf.theme || {}) };
      dlv = { fee: sf.delivery_fee, days: sf.delivery_days, weeks: sf.package_weeks, shifts: sf.delivery_shifts || [] };
      subs = await api.rpc('list_storefront_subscriptions', { p_business_id: ctx.bid }).catch(() => []) || [];
      paint();
    } catch (e) { el.innerHTML = errorState(e, 'storefront'); }
  };

  el.addEventListener('input', e => { if (e.target.closest('[data-accent],[data-secondary],[data-tagline]')) post(); });
  el.addEventListener('click', async e => {
    if (e.target.closest('[data-retry]')) { load(); return; }
    const dd = e.target.closest('[data-dday]');
    if (dd) { dlv = readDelivery(); const n = Number(dd.dataset.dday); const set = new Set(dlv.days || []); set.has(n) ? set.size > 1 && set.delete(n) : set.add(n); dlv.days = [...set].sort(); paint(); return; }
    const dw = e.target.closest('[data-dweek]');
    if (dw) { dlv = readDelivery(); const n = Number(dw.dataset.dweek); const set = new Set(dlv.weeks || []); set.has(n) ? set.size > 1 && set.delete(n) : set.add(n); dlv.weeks = [...set].sort(); paint(); return; }
    if (e.target.closest('[data-sadd]')) { dlv = readDelivery(); dlv.shifts = [...dlv.shifts, { name: '', from: '18:00', to: '20:00' }]; paint(); return; }
    const sdel = e.target.closest('[data-sdel]');
    if (sdel) { dlv = readDelivery(); dlv.shifts.splice(Number(sdel.dataset.sdel), 1); paint(); return; }
    const dsave = e.target.closest('[data-dsave]');
    if (dsave) {
      const err = el.querySelector('[data-derr]'); err.hidden = true; dlv = readDelivery();
      if (dlv.fee == null || !(dlv.fee >= 0)) { err.textContent = t('sf.feeNeeded'); err.hidden = false; return; }
      try { await busy(dsave, () => api.rpc('save_storefront_delivery', { p_business_id: ctx.bid, p_fee: dlv.fee, p_days: dlv.days, p_shifts: dlv.shifts, p_weeks: dlv.weeks })); toast(t('c.saved')); }
      catch (ex) { err.textContent = ex.message; err.hidden = false; }
      return;
    }
    const sk = e.target.closest('[data-dskip]');
    const mv = e.target.closest('[data-dmove]');
    const sc2 = e.target.closest('[data-scancel]');
    if (sk || mv || sc2) {
      try {
        if (sk) await api.rpc('change_subscription_day', { p_day_id: sk.dataset.dskip, p_action: 'skip' });
        if (mv) {
          const input = document.createElement('input'); input.type = 'date'; input.min = new Date(Date.now() + 864e5).toISOString().slice(0, 10);
          const [y, m] = mv.dataset.month.split('-').map(Number); input.max = new Date(Date.UTC(y, m, 0)).toISOString().slice(0, 10);
          const picked = await new Promise(res => { input.onchange = () => res(input.value); input.style.position = 'fixed'; input.style.opacity = '0'; document.body.append(input); input.showPicker ? input.showPicker() : input.click(); });
          input.remove();
          if (picked) await api.rpc('change_subscription_day', { p_day_id: mv.dataset.dmove, p_action: 'move', p_new_date: picked });
        }
        if (sc2) await api.rpc('cancel_storefront_subscription', { p_id: sc2.dataset.scancel });
        subs = await api.rpc('list_storefront_subscriptions', { p_business_id: ctx.bid }) || []; toast(t('c.saved')); paint();
      } catch (ex) { toast(ex.message, 'error'); }
      return;
    }
    const link = () => el.querySelector('[data-link]').value;
    if (e.target.closest('[data-copy]')) { const ok = await copyText(link()); toast(ok ? t('riders.copied') : link()); return; }
    if (e.target.closest('[data-share]')) { try { await navigator.share({ title: ctx.business?.business_name, url: link() }); } catch { /* dismissed */ } return; }
    const pub = e.target.closest('[data-publish]');
    if (pub) {
      try {
        const res = await busy(pub, () => api.rpc('set_storefront_published', { p_business_id: ctx.bid, p_published: !sf.published }));
        sf.published = (Array.isArray(res) ? res[0] : res)?.published ?? !sf.published;
        toast(t(sf.published ? 'sf.published' : 'sf.unpublished')); paint();
      } catch (ex) { toast(ex.message, 'error'); }
      return;
    }
    const sc = e.target.closest('[data-screen]');
    if (sc) { theme = { ...theme, ...readForm() }; screen = sc.dataset.screen; paint(); return; }
    const x = e.target.closest('[data-tpl]');
    if (x && x.dataset.tpl !== tpl) {
      // A new template starts from its own colours, as in the App.
      tpl = x.dataset.tpl; const d = def();
      theme = { ...theme, tagline: readForm().tagline, accent: d.primary, secondary: d.secondary };
      paint(); return;
    }
    const cf = e.target.closest('[data-cat]');
    if (cf) { theme = { ...theme, ...readForm() }; cat = cf.dataset.cat; paint(); return; }
    if (e.target.closest('[data-hero]')) { el.querySelector('[data-herofile]').click(); return; }
    if (e.target.closest('[data-logo]')) { el.querySelector('[data-logofile]').click(); return; }
    const save = e.target.closest('[data-save]');
    if (save) {
      const err = el.querySelector('[data-err]'); err.hidden = true;
      const f = readForm();
      const next = { ...theme, accent: f.accent, secondary: f.secondary };
      delete next.style; delete next.font;
      if (f.tagline) next.tagline = f.tagline; else delete next.tagline;
      try {
        await busy(save, async () => {
          if (heroFile) {
            const path = `${ctx.bid}/hero-${crypto.randomUUID()}.${HERO_TYPES[heroFile.type]}`;
            await api.upload('cefflo-storefront-assets', path, heroFile);
            next.hero_path = path;
          }
          if (logoFile) {
            const path = `${ctx.bid}/logo-${crypto.randomUUID()}.${LOGO_TYPES[logoFile.type]}`;
            await api.upload('cefflo-storefront-assets', path, logoFile);
            next.logo_path = path;
          }
          await api.rpc('save_storefront_appearance', { p_business_id: ctx.bid, p_template_key: tpl, p_theme: next });
        });
        theme = next; sf.template_key = tpl; heroFile = null; logoFile = null; toast(t('c.saved')); paint();
      } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    }
  });
  el.addEventListener('change', e => {
    const lf = e.target.closest('[data-logofile]');
    if (lf && lf.files[0]) {
      const file = lf.files[0];
      if (!LOGO_TYPES[file.type]) { toast(t('prod.badType'), 'error'); return; }
      if (file.size > 2 * 1024 * 1024) { toast(t('prod.tooBig'), 'error'); return; }
      theme = { ...theme, ...readForm() };
      logoFile = file;
      const r = new FileReader(); r.onload = () => { logoData = String(r.result); paint(); post(); }; r.readAsDataURL(file);
      return;
    }
    const f = e.target.closest('[data-herofile]');
    if (!f || !f.files[0]) return;
    const file = f.files[0];
    if (!HERO_TYPES[file.type]) { toast(t('prod.badType'), 'error'); return; }
    if (file.size > 5 * 1024 * 1024) { toast(t('prod.tooBig'), 'error'); return; }
    // Keep typed colours/tagline while showing the new hero.
    theme = { ...theme, ...readForm() };
    heroFile = file;
    const r = new FileReader(); r.onload = () => { heroData = String(r.result); paint(); }; r.readAsDataURL(file);
  });
  load();
}
