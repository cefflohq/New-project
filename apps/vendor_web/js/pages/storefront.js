// Storefront (V-31-V-33, D-55, Storefront V1 Founder 2026-10-01). Same
// contracts as Vendor App: get_storefront (created unpublished on first
// open), set_storefront_published, save_storefront_appearance (template +
// theme), hero image as a new object in cefflo-storefront-assets. The public
// link is {storefront base}{slug}; Owner + Operator on the server.
import { t } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { esc, icon, chip, loadingRows, errorState, toast, busy, copyText, modal } from '../ui.js';
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
// Preview devices (Founder 2026-10-18): the iframe renders at the device's
// CSS width and is scaled to fit its frame.
const DEVICES = [['phone', 'Phone'], ['tablet', 'Tablet'], ['desktop', 'Desktop']];
const DEV_W = { phone: 390, tablet: 820, desktop: 1280 };
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
  let dlv = {}, subs = [], pay = {}, cou = {};
  let sf = null, tpl = 'warung', theme = {}, heroFile = null, heroData = null, logoFile = null, logoData = null, pv = null, screen = '', cat = '';
  let frame = null, frameReady = false, tab = 'look', device = 'phone';
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

  // Each settings group is a section: a heading row (icon, title, one-line
  // lead) over one quiet panel. Layout classes live in app.css (.sfx-*).
  const sec = (id, ic, title, lead, body) => `<section class="sfx-sec" id="sfx-${id}" ${tab === id ? '' : 'hidden'}>
      <p class="sfx-lead">${esc(lead)}</p>${body}</section>`;
  const fld = (label, control, cls = '') => `<label class="sfx-f ${cls}"><span>${esc(label)}</span>${control}</label>`;
  const foot = (btn, note = '') => `<div class="sfx-foot">${note ? `<small>${esc(note)}</small>` : ''}${btn}</div>`;

  // Delivery & packages (Founder 2026-10-17): fee per drop = the driver's pay,
  // never free; weekdays; shifts (batches); package lengths.
  const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const deliveryCard = () => {
    const days = dlv.days || [1, 2, 3, 4, 5], weeks = dlv.weeks || [1, 2, 4], shifts = dlv.shifts || [];
    return sec('delivery', 'route', t('sf.delivery'), t('sf.deliveryLead'), `
      <div class="sfx-row">${fld(t('sf.fee'), `<span class="sfx-money"><i>RM</i><input class="sfx-in" type="number" min="0" max="1000" step="0.5" data-fee value="${esc(dlv.fee ?? '')}" placeholder="5.00"></span>`, 'sfx-narrow')}</div>
      <div class="sfx-f"><span>${esc(t('sf.days'))}</span><div class="sfx-pills">${DAYS.map((d, i) => `<button type="button" class="sfx-pill ${days.includes(i + 1) ? 'on' : ''}" aria-pressed="${days.includes(i + 1)}" data-dday="${i + 1}">${esc(t(`sf.d${i + 1}`))}</button>`).join('')}</div></div>
      <div class="sfx-f"><span>${esc(t('sf.weeks'))}</span><div class="sfx-pills">${[1, 2, 3, 4].map(w => `<button type="button" class="sfx-pill ${weeks.includes(w) ? 'on' : ''}" aria-pressed="${weeks.includes(w)}" data-dweek="${w}">${esc(t(w === 1 ? 'sf.week1' : 'sf.weekN', { n: w }))}</button>`).join('')}</div><small>${esc(t('sf.weeksHint'))}</small></div>
      <div class="sfx-f"><span>${esc(t('sf.shifts'))}</span><div class="sfx-shifts" data-shifts>${shifts.map((x, i) => `<div class="sfx-shift"><input class="sfx-in" data-sname="${i}" value="${esc(x.name)}" placeholder="${esc(t('sf.shiftName'))}"><input class="sfx-in sfx-time" type="time" data-sfrom="${i}" value="${esc(x.from)}"><span class="sfx-to">to</span><input class="sfx-in sfx-time" type="time" data-sto="${i}" value="${esc(x.to)}"><button type="button" class="sfx-x" data-sdel="${i}" aria-label="${esc(t('sf.shiftRemove'))}">${icon('trash')}</button></div>`).join('')}
        ${shifts.length < 4 ? `<button type="button" class="sfx-add" data-sadd>${esc(t('sf.shiftAdd'))}</button>` : ''}</div><small>${esc(t('sf.shiftsHint'))}</small></div>
      <div class="err" data-derr hidden></div>
      ${foot(`<button class="sfx-btn primary" data-dsave>${esc(t('c.save'))}</button>`)}`);
  };
  // Payments (Founder 2026-10-17): the vendor's own Curlec account; Cefflo never
  // holds the money. Cash on delivery is a vendor switch (always on without Curlec).
  const payCard = () => sec('pay', 'card', t('sf.pay'), t('sf.payLead'), `
    ${pay.connected ? `<div class="sfx-conn"><span class="sfx-dot"></span><div><b>${esc(t('sf.chipOn', { id: pay.key_hint || '' }))}</b>${pay.test_mode ? `<small>${esc(t('sf.testMode'))}</small>` : ''}</div><button class="sfx-btn" data-chipoff>${esc(t('sf.chipOff'))}</button></div>`
      : `<div class="sfx-row">${fld(t('sf.brandId'), `<input class="sfx-in" data-brand placeholder="rzp_live_…" autocomplete="off">`)}${fld(t('sf.secret'), `<input class="sfx-in" type="password" data-secret autocomplete="new-password">`)}</div>
        <small class="sfx-note">${esc(t('sf.chipHint'))}</small>
        <div class="err" data-perr hidden></div>
        ${foot(`<button class="sfx-btn primary" data-chipon>${esc(t('sf.chipConnect'))}</button>`)}`}
    <label class="sfx-switch"><span><b>${esc(t('sf.cod'))}</b><small>${esc(t(pay.connected ? 'sf.codHint' : 'sf.codOnly'))}</small></span><input type="checkbox" role="switch" data-cod ${pay.accept_cod !== false || !pay.connected ? 'checked' : ''} ${pay.connected ? '' : 'disabled'}><i></i></label>`);

  // Courier (Founder 2026-10-17): the vendor's own EasyParcel account ships
  // storefront orders outside the rider area; booking is automatic after payment.
  const EP_STATES = [['jhr', 'Johor'], ['kdh', 'Kedah'], ['ktn', 'Kelantan'], ['mlk', 'Melaka'], ['nsn', 'Negeri Sembilan'], ['phg', 'Pahang'], ['prk', 'Perak'], ['pls', 'Perlis'], ['png', 'Pulau Pinang'], ['sgr', 'Selangor'], ['trg', 'Terengganu'], ['kul', 'Kuala Lumpur'], ['pjy', 'Putrajaya'], ['srw', 'Sarawak'], ['sbh', 'Sabah'], ['lbn', 'Labuan']];
  const courierCard = () => {
    const pk = cou.pickup || {};
    return sec('courier', 'pkg', t('sf.courier'), t('sf.courierLead'), `
    ${cou.connected ? `<div class="sfx-conn"><span class="sfx-dot"></span><div><b>${esc(t('sf.epOn', { id: cou.key_hint || '' }))}</b>${cou.demo ? `<small>${esc(t('sf.testMode'))}</small>` : ''}</div><button class="sfx-btn" data-epoff>${esc(t('sf.chipOff'))}</button></div>` : ''}
    <div class="sfx-row">${fld(t('sf.epKey'), `<input class="sfx-in" type="password" data-epkey autocomplete="new-password" placeholder="${esc(cou.connected ? t('sf.epKeyKeep') : '')}">`)}
      <label class="sfx-check"><input type="checkbox" data-epdemo ${cou.demo ? 'checked' : ''}><span>${esc(t('sf.epDemo'))}</span></label></div>
    <h3 class="sfx-sub">${esc(t('sf.pickAddr'))}</h3>
    <div class="sfx-row">${fld(t('sf.pickName'), `<input class="sfx-in" data-pk="name" value="${esc(pk.name || '')}">`)}${fld(t('sf.pickPhone'), `<input class="sfx-in" data-pk="phone" inputmode="tel" value="${esc(pk.phone || '')}">`)}</div>
    ${fld(t('sf.pickAddr'), `<input class="sfx-in" data-pk="address" value="${esc(pk.address || '')}">`)}
    <div class="sfx-row sfx-r3">${fld(t('sf.pickCity'), `<input class="sfx-in" data-pk="city" value="${esc(pk.city || '')}">`)}${fld(t('sf.pickPost'), `<input class="sfx-in" data-pk="postcode" inputmode="numeric" maxlength="5" value="${esc(pk.postcode || '')}">`)}${fld(t('sf.pickState'), `<select class="sfx-in" data-pk="state">${EP_STATES.map(([k, n]) => `<option value="${k}" ${pk.state === k ? 'selected' : ''}>${esc(n)}</option>`).join('')}</select>`)}</div>
    <small class="sfx-note">${esc(t('sf.courierHint'))}</small>
    <div class="err" data-eperr hidden></div>
    ${foot(`<button class="sfx-btn primary" data-epsave>${esc(t(cou.connected ? 'c.save' : 'sf.epConnect'))}</button>`)}`);
  };
  const subsCard = () => {
    if (!subs.length) return '';
    return sec('subs', 'plan', t('sf.subs'), t('sf.subsLead'), `<div class="sfx-subs">${subs.map(x => `<div class="sfx-subi">
        <div class="sfx-subh"><b>${esc(x.customer_name)}</b><small>${esc(x.customer_phone)}</small>${chip(x.status === 'active' ? 'active' : 'pending')}
          ${x.status === 'active' ? `<button class="sfx-btn sm" data-scancel="${x.id}">${esc(t('sf.subCancel'))}</button>` : ''}</div>
        <small>${esc((x.days || []).map(d => DAYS[d - 1]).join(', '))} × ${x.weeks} · ${esc(x.shift?.name || '')}</small>
        <div class="sfx-pills">${(x.deliveries || []).map(d => `<span class="sfx-day ${d.status === 'skipped' ? 'off' : ''}" title="${esc(d.status)}">${esc(new Date(d.date + 'T00:00').toLocaleDateString(undefined, { weekday: 'short', day: 'numeric', month: 'short' }))}${d.multiplier > 1 ? ` ×${d.multiplier}` : ''}
          ${d.status === 'scheduled' ? `<button class="link" data-dskip="${d.id}" title="${esc(t('sf.skip'))}">✕</button><button class="link" data-dmove="${d.id}" data-month="${d.date.slice(0, 7)}" title="${esc(t('sf.move'))}">↻</button>` : ''}</span>`).join('')}</div></div>`).join('')}</div>`);
  };
  const readDelivery = () => {
    const shifts = [...el.querySelectorAll('[data-sname]')].map(n => { const i = n.dataset.sname; return { name: n.value.trim(), from: el.querySelector(`[data-sfrom="${i}"]`).value, to: el.querySelector(`[data-sto="${i}"]`).value }; });
    const fee = el.querySelector('[data-fee]').value;
    return { ...dlv, fee: fee === '' ? null : Number(fee), shifts };
  };

  const paint = () => {
    const link = base() + sf.slug;
    const cur = def();
    const nav = [['look', t('sf.template')], ['pay', t('sf.pay')], ['delivery', t('sf.delivery')], ['courier', t('sf.courier')], ...(subs.length ? [['subs', t('sf.subs')]] : [])];
    el.innerHTML = `<div class="sfx">
      <div class="sfx-top">
        <div class="sfx-link">${chip(sf.published ? 'active' : 'pending')}<input class="sfx-url" readonly data-link value="${esc(link)}" aria-label="${esc(t('sf.link'))}"></div>
        <div class="sfx-acts">
          <button class="sfx-btn" data-copy>${esc(t('riders.copy'))}</button>
          <button class="sfx-btn" data-qr>QR code</button>
          <a class="sfx-btn" href="${esc(link)}" target="_blank" rel="noopener">${esc(t('sf.open'))}</a>
          <button class="sfx-btn ${sf.published ? '' : 'primary'}" data-publish>${esc(t(sf.published ? 'sf.unpublish' : 'sf.publish'))}</button></div></div>
      <nav class="sfx-nav" role="tablist">${nav.map(([k, n]) => `<button type="button" role="tab" aria-selected="${tab === k}" class="${tab === k ? 'on' : ''}" data-jump="${k}">${esc(n)}</button>`).join('')}</nav>
      <div class="sfx-split sf-split sfx-split-${device}">
        <div class="sfx-main">
          ${sec('look', 'palette', t('sf.template'), t('sf.templateLead'), `
            <div class="sfx-pills">${['', ...CATS].map(k => `<button type="button" class="sfx-pill ${cat === k ? 'on' : ''}" data-cat="${k}">${esc(t(k ? `sf.cat.${k}` : 'sf.cat.all'))}</button>`).join('')}</div>
            <div class="sfx-tpls">${[...(LEGACY.some(x => x.id === sf.template_key) && !cat ? LEGACY.filter(x => x.id === sf.template_key) : []), ...TEMPLATES.filter(x => !cat || x.cat === cat)].map(x => `<button type="button" class="sfx-tpl ${x.id === tpl ? 'on' : ''}" data-tpl="${x.id}" aria-pressed="${x.id === tpl}">
              <span class="sfx-shot">${TEMPLATES.some(y => y.id === x.id) ? `<img src="img/templates/${x.id}.jpg" alt="" loading="lazy">` : `<i style="background:linear-gradient(${x.primary},${x.secondary})"></i>`}</span>
              <span class="sfx-tn"><b>${esc(x.name)}</b>${x.id === sf.template_key ? `<em>${esc(t(LEGACY.some(l => l.id === x.id) ? 'sf.activeEarlier' : 'sf.active'))}</em>` : ''}</span><small>${esc(t(`tpl.${x.id}`))}</small></button>`).join('')}</div>
            <h3 class="sfx-sub">${esc(t('sf.appearance'))}</h3><p class="sfx-lead">${esc(t('sf.appearanceLead'))}</p>
            <div class="sfx-row">
              ${fld(t('sf.accent'), `<span class="sfx-color"><input type="color" data-accent value="${esc(theme.accent || cur.primary)}"><i>${esc((theme.accent || cur.primary).toUpperCase())}</i></span>`)}
              ${fld(t('sf.secondary'), `<span class="sfx-color"><input type="color" data-secondary value="${esc(theme.secondary || cur.secondary)}"><i>${esc((theme.secondary || cur.secondary).toUpperCase())}</i></span>`)}</div>
            ${fld(t('sf.tagline'), `<input class="sfx-in" data-tagline maxlength="120" value="${esc(theme.tagline || '')}">`)}
            <div class="sfx-row sfx-start">
              <div class="sfx-f"><span>${esc(t('sf.logo'))}</span>
                <div class="sfx-media">${theme.logo_path || logoFile ? `<img data-logoimg src="${esc(logoData || api.publicUrl('cefflo-storefront-assets', theme.logo_path))}" alt="" class="sfx-logo">` : `<span class="sfx-ph sfx-logo">${icon('upload')}</span>`}
                  <button type="button" class="sfx-btn sm" data-logo>${esc(t(theme.logo_path || logoFile ? 'sf.logoChange' : 'sf.logoAdd'))}</button>
                  <input type="file" accept="image/jpeg,image/png,image/webp" hidden data-logofile></div>
                <small>${esc(t('sf.logoHint'))}</small></div>
              ${cur.hero === false ? '' : `<div class="sfx-f"><span>${esc(t('sf.hero'))}</span>
                <div class="sfx-media">${theme.hero_path || heroFile ? `<img data-heroimg src="${esc(heroData || api.publicUrl('cefflo-storefront-assets', theme.hero_path))}" alt="" class="sfx-heroimg">` : `<span class="sfx-ph sfx-heroimg">${icon('upload')}</span>`}
                  <button type="button" class="sfx-btn sm" data-hero>${esc(t(theme.hero_path || heroFile ? 'sf.heroChange' : 'sf.heroAdd'))}</button>
                  <input type="file" accept="image/jpeg,image/png,image/webp" hidden data-herofile></div>
                <small>${esc(t('sf.heroHint'))}</small></div>`}</div>
            <div class="err" data-err hidden></div>
            ${foot(`<button class="sfx-btn primary" data-save>${esc(t('sf.apply'))}</button>`, sf.published ? t('sf.applyLive') : '')}`)}
          ${payCard()}
          ${deliveryCard()}
          ${courierCard()}
          ${subsCard()}</div>
        <aside class="sfx-pv sfx-pv-${device}">
          <div class="sfx-pills sfx-pvtabs">${DEVICES.map(([k, n]) => `<button type="button" class="sfx-pill ${device === k ? 'on' : ''}" data-device="${k}">${n}</button>`).join('')}</div>
          <div class="sfx-dev sfx-${device}" data-dev>${device === 'phone' ? '<i class="sfx-island"></i>' : device === 'desktop' ? '<div class="sfx-chrome"><i></i><i></i><i></i></div>' : ''}<div class="sfx-scr" data-scr><iframe data-frame title="${esc(t('sf.preview'))}" src="${esc(src())}"></iframe></div></div>
          <small>${esc(t('sf.previewLead'))}</small></aside></div></div>`;
    frame = el.querySelector('[data-frame]'); frameReady = false;
    fitDevice();
  };
  const fitDevice = () => {
    const scr = el.querySelector('[data-scr]'); if (!scr || !frame) return;
    const w = DEV_W[device], k = scr.clientWidth / w;
    frame.style.width = `${w}px`; frame.style.height = `${scr.clientHeight / k}px`; frame.style.transform = `scale(${k})`;
  };
  const ro = new ResizeObserver(() => fitDevice()); ro.observe(el);

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
      pay = await api.rpc('payment_settings', { p_business_id: ctx.bid }).catch(() => ({})) || {};
      cou = await api.rpc('courier_settings', { p_business_id: ctx.bid }).catch(() => ({})) || {};
      paint();
    } catch (e) { el.innerHTML = errorState(e, 'storefront'); }
  };

  el.addEventListener('input', e => {
    if (e.target.matches('[data-accent],[data-secondary]')) { const tag = e.target.nextElementSibling; if (tag) tag.textContent = e.target.value.toUpperCase(); }
    if (e.target.closest('[data-accent],[data-secondary],[data-tagline]')) post();
  });
  el.addEventListener('click', async e => {
    if (e.target.closest('[data-retry]')) { load(); return; }
    const jp = e.target.closest('[data-jump]');
    if (jp) { tab = jp.dataset.jump; el.querySelectorAll('[data-jump]').forEach(b => { const on = b === jp; b.classList.toggle('on', on); b.setAttribute('aria-selected', String(on)); }); el.querySelectorAll('.sfx-sec').forEach(x => { x.hidden = x.id !== `sfx-${tab}`; }); return; }
    if (e.target.closest('[data-qr]')) { const link = base() + sf.slug; modal({ title: 'QR code', lead: t('sf.link'), cls: 'sfx-qrm', body: `<div class="sfx-qrbox">${qrSvg(link)}</div><p class="sfx-qrlink">${esc(link)}</p>` }); return; }
    const eps = e.target.closest('[data-epsave]');
    if (eps) {
      const err = el.querySelector('[data-eperr]'); err.hidden = true;
      const pickup = Object.fromEntries([...el.querySelectorAll('[data-pk]')].map(i => [i.dataset.pk, i.value.trim()]));
      const key = el.querySelector('[data-epkey]').value.trim();
      if (!key && !cou.connected) { err.textContent = t('sf.epKeyNeeded'); err.hidden = false; return; }
      if (!/^[0-9]{5}$/.test(pickup.postcode) || !pickup.name || !pickup.phone || !pickup.address || !pickup.city) { err.textContent = t('c.required'); err.hidden = false; return; }
      if (!key) { err.textContent = t('sf.epKeyNeeded'); err.hidden = false; return; }
      try { await busy(eps, () => api.rpc('save_courier_account', { p_business_id: ctx.bid, p_api_key: key, p_demo: el.querySelector('[data-epdemo]').checked, p_pickup: pickup })); cou = await api.rpc('courier_settings', { p_business_id: ctx.bid }); toast(t('c.saved')); paint(); }
      catch (ex) { err.textContent = ex.message; err.hidden = false; }
      return;
    }
    if (e.target.closest('[data-epoff]')) { try { await api.rpc('disconnect_courier_account', { p_business_id: ctx.bid }); cou = await api.rpc('courier_settings', { p_business_id: ctx.bid }); paint(); } catch (ex) { toast(ex.message, 'error'); } return; }
    const con = e.target.closest('[data-chipon]');
    if (con) {
      const err = el.querySelector('[data-perr]'); err.hidden = true;
      const brand = el.querySelector('[data-brand]').value.trim(), secret = el.querySelector('[data-secret]').value.trim();
      try { await busy(con, () => api.rpc('save_curlec_account', { p_business_id: ctx.bid, p_key_id: brand, p_key_secret: secret })); pay = await api.rpc('payment_settings', { p_business_id: ctx.bid }); toast(t('c.saved')); paint(); }
      catch (ex) { err.textContent = ex.message; err.hidden = false; }
      return;
    }
    if (e.target.closest('[data-chipoff]')) {
      try { await api.rpc('disconnect_curlec_account', { p_business_id: ctx.bid }); pay = await api.rpc('payment_settings', { p_business_id: ctx.bid }); paint(); } catch (ex) { toast(ex.message, 'error'); }
      return;
    }
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
    const dv = e.target.closest('[data-device]');
    if (dv) { theme = { ...theme, ...readForm() }; device = dv.dataset.device; paint(); return; }
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
  el.addEventListener('change', async e => {
    const cod = e.target.closest('[data-cod]');
    if (cod) { try { await api.rpc('set_storefront_cod', { p_business_id: ctx.bid, p_accept: cod.checked }); pay.accept_cod = cod.checked; toast(t('c.saved')); } catch (ex) { cod.checked = !cod.checked; toast(ex.message, 'error'); } return; }
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
