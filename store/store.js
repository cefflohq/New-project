(function () {
  'use strict';
  // Cefflo Storefront V1 engine. Anonymous customers call exactly two
  // SECURITY DEFINER functions: public_storefront and submit_storefront_order.
  // Prices shown are display only: the server snapshots the real prices from
  // the business's Products when the order is created. Templates
  // (store/templates.js) only lay out data; they never ship sample content.
  const cfg = window.CEFFLO_CONFIG || {};
  const T = window.CEFFLO_TEMPLATES || {};
  const params = new URLSearchParams(location.search);
  const EMBED = params.get('embed') === '1';
  const slug = decodeURIComponent(location.pathname.replace(/^\/+|\/+$/g, '').split('/')[0] || '').toLowerCase();
  const app = document.getElementById('app');

  // ------------------------------------------------------------- helpers
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  // Customer-facing amounts always show two decimals (RM 8.00); the server
  // price contract is unchanged.
  const money = n => `RM ${Number(n || 0).toFixed(2)}`;
  const moneyShort = money;

  // Customer language: English by default, Bahasa Melayu when chosen; kept on
  // this device only, never auto-detected. Vendor content is never translated.
  const LANG_KEY = 'cefflo.store.lang';
  let lang = 'en';
  try { lang = localStorage.getItem(LANG_KEY) === 'ms' ? 'ms' : 'en'; } catch { /* private mode */ }
  const MS = window.CEFFLO_STORE_MS || {};
  const t = (s, vars) => { let out = lang === 'ms' && MS[s] ? MS[s] : s; if (vars) out = out.replace(/\{(\w+)\}/g, (_, k) => vars[k] ?? ''); return out; };
  window.CEFFLO_I18N = s => (lang === 'ms' && MS[s] ? MS[s] : s);
  const DAYS_EN = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'], DAYS_MS = ['Isn', 'Sel', 'Rab', 'Kha', 'Jum', 'Sab', 'Ahd'];
  let DAYS = lang === 'ms' ? DAYS_MS : DAYS_EN;

  // A usable international phone: optional +, then 7-15 digits once spaces,
  // dashes, dots and brackets are removed (the server applies the same rule).
  const phoneOk = v => /^\+?[0-9]{7,15}$/.test(String(v || '').replace(/[\s().-]/g, ''));
  const abs = u => (!u ? null : /^(https?:|data:image\/)/.test(u) ? u : `${cfg.supabaseUrl || ''}${u}`);

  async function rpc(name, body) {
    const res = await fetch(`${cfg.supabaseUrl}/rest/v1/rpc/${name}`, {
      method: 'POST',
      headers: { apikey: cfg.supabaseAnonKey, Authorization: `Bearer ${cfg.supabaseAnonKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const text = await res.text();
    let data = null; try { data = text ? JSON.parse(text) : null; } catch { data = null; }
    if (!res.ok) { const e = new Error(data?.message || `status ${res.status}`); e.status = res.status; throw e; }
    return data;
  }

  // Line icons (stroke = currentColor), drawn for Cefflo; no icon font.
  const P = {
    back: '<path d="M15 18l-6-6 6-6"/>', arrowLeft: '<path d="M19 12H5M12 19l-7-7 7-7"/>', arrowRight: '<path d="M5 12h14M12 5l7 7-7 7"/>',
    arrowDown: '<path d="M12 5v14M19 12l-7 7-7-7"/>', bag: '<path d="M6 7h12l1 13H5L6 7z"/><path d="M9 7a3 3 0 016 0"/>',
    cart: '<circle cx="9" cy="20" r="1.4"/><circle cx="18" cy="20" r="1.4"/><path d="M2 3h3l2.6 11.2a1 1 0 001 .8h9.7a1 1 0 001-.8L21 7H6"/>',
    basket: '<path d="M4 10h16l-1.5 9a1 1 0 01-1 .8H6.5a1 1 0 01-1-.8L4 10z"/><path d="M8 10l4-6 4 6M9 14v3M15 14v3"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>', heart: '<path d="M12 20s-7-4.4-9.2-8.6C1.2 8.3 3 4.5 6.6 4.5c2.1 0 3.4 1.2 4.4 2.6 1-1.4 2.3-2.6 4.4-2.6 3.6 0 5.4 3.8 3.8 6.9C19 15.6 12 20 12 20z"/>',
    plus: '<path d="M12 5v14M5 12h14"/>', minus: '<path d="M5 12h14"/>', menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
    menu2: '<path d="M4 8h16M4 16h10"/>', grid: '<circle cx="7" cy="7" r="2.6"/><circle cx="17" cy="7" r="2.6"/><circle cx="7" cy="17" r="2.6"/><circle cx="17" cy="17" r="2.6"/>',
    dots: '<circle cx="8" cy="8" r="1.4"/><circle cx="16" cy="8" r="1.4"/><circle cx="8" cy="16" r="1.4"/><circle cx="16" cy="16" r="1.4"/>',
    bell: '<path d="M6 16V11a6 6 0 0112 0v5l2 2H4l2-2z"/><path d="M10 20a2 2 0 004 0"/>', user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0116 0"/>',
    home: '<path d="M3 11l9-7 9 7v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1v-9z"/>', pin: '<path d="M12 21s-7-6.2-7-11.5A7 7 0 0119 9.5C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>',
    filter: '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/>',
    share: '<path d="M12 3v13M7 8l5-5 5 5"/><path d="M5 13v6a2 2 0 002 2h10a2 2 0 002-2v-6"/>', check: '<path d="M5 12l5 5 9-10"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>', orders: '<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 8h6M9 12h6M9 16h4"/>',
    tag: '<path d="M3 12V4h8l10 10-8 8L3 12z"/><circle cx="7.5" cy="7.5" r="1.5"/>', star: '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9L12 3z"/>',
    box: '<path d="M3 7l9-4 9 4v10l-9 4-9-4V7z"/><path d="M3 7l9 4 9-4M12 11v10"/>', shield: '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3z"/>',
    phone: '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 005 5L15 13l5 2v4a2 2 0 01-2 2A16 16 0 013 6a2 2 0 012-2z"/>', chat: '<path d="M4 5h16v11H8l-4 4V5z"/>',
    chevronDown: '<path d="M6 9l6 6 6-6"/>', chevronRight: '<path d="M9 6l6 6-6 6"/>', sparkle: '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3z"/>',
    percent: '<path d="M19 5L5 19"/><circle cx="7" cy="7" r="2.5"/><circle cx="17" cy="17" r="2.5"/>', apps: '<rect x="4" y="4" width="7" height="7" rx="2"/><rect x="13" y="4" width="7" height="7" rx="2"/><rect x="4" y="13" width="7" height="7" rx="2"/><rect x="13" y="13" width="7" height="7" rx="2"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7.5v.5"/>', flame: '<path d="M12 3c1 4 5 5.5 5 10a5 5 0 01-10 0c0-2.5 1.5-4 2.5-5 .5 2 1.5 2.5 2.5 2.5C12 8 11 6 12 3z"/>',
  };
  const icon = (n, cls = '') => `<svg class="ic ${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${P[n] || ''}</svg>`;

  // ------------------------------------------------------------- state
  let store = null; // normalised data
  let tpl = null, tplKey = null;
  const cart = new Map(); // product_id -> quantity (display only; the server prices it)
  // The cart is kept on this device per storefront (never customer details) and
  // reconciled with the live catalogue on load; the server still prices and
  // validates every order.
  const cartKey = () => `cefflo.store.cart.${store?.slug || slug}`;
  function saveCart() { if (EMBED || !store) return; try { localStorage.setItem(cartKey(), JSON.stringify([...cart])); } catch { /* storage unavailable */ } }
  function restoreCart() {
    if (EMBED) return;
    let rows = [];
    try { rows = JSON.parse(localStorage.getItem(cartKey()) || '[]'); } catch { rows = []; }
    cart.clear();
    for (const [id, q] of Array.isArray(rows) ? rows : []) {
      const n = Math.floor(Number(q));
      if (product(id) && n >= 1) cart.set(id, Math.min(50, n));
    }
    saveCart();
  }
  const ui = { cat: null, q: '', sel: 1, img: 0, intro: false };
  let idempotencyKey = crypto.randomUUID();
  let lastOrder = null;

  function normalise(raw) {
    const theme = raw.theme || {};
    const products = (raw.products || []).map(p => ({
      id: p.id, categoryId: p.category_id, name: p.name || '', description: p.description || '',
      price: Number(p.display_price || 0), images: (p.images || []).map(abs).filter(Boolean),
    }));
    return {
      slug: raw.slug, name: raw.business?.name || '', area: raw.business?.area || '',
      tagline: theme.tagline || '', theme, heroUrl: abs(raw.hero_url), openNow: raw.open_now, nextOpen: raw.next_open || null,
      hours: Array.isArray(raw.hours) ? raw.hours : [], products,
      categories: (raw.categories || []).filter(c => products.some(p => p.categoryId === c.id)),
      templateKey: raw.template_key,
    };
  }

  const product = id => store.products.find(p => p.id === id);
  const qty = id => cart.get(id) || 0;
  const count = () => [...cart.values()].reduce((a, b) => a + b, 0);
  const total = () => [...cart].reduce((s, [id, q]) => s + (product(id)?.price || 0) * q, 0);
  function list(catId = ui.cat, q = ui.q) {
    const term = (q || '').trim().toLowerCase();
    return store.products.filter(p => (!catId || p.categoryId === catId) && (!term || p.name.toLowerCase().includes(term) || p.description.toLowerCase().includes(term)));
  }
  const catName = id => store.categories.find(c => c.id === id)?.name || '';
  const initials = s => (s || '').split(/\s+/).filter(Boolean).slice(0, 2).map(w => w[0]).join('').toUpperCase() || '·';
  function img(p, cls = '', i = 0) {
    const src = p?.images?.[i];
    return src
      ? `<img class="${cls}" src="${esc(src)}" alt="${esc(p.name)}" loading="lazy" onerror="this.replaceWith(Object.assign(document.createElement('div'),{className:'sf-ph ${cls}',textContent:'${esc(initials(p.name)).replace(/'/g, '')}'}))">`
      : `<div class="sf-ph ${cls}" aria-hidden="true">${esc(initials(p?.name))}</div>`;
  }
  function hoursText() {
    if (!store.hours.length) return '';
    const today = (new Date().getDay() + 6) % 7 + 1;
    const h = store.hours.find(x => x.weekday === today);
    return h ? (h.is_open ? `${t('Today')} ${h.opens_at}–${h.closes_at}` : t('Closed today')) : '';
  }
  const openLabel = () => (store.openNow === true ? t('Open now') : store.openNow === false ? t('Closed now') : '');
  function greeting() { const h = new Date().getHours(); return t(h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening'); }
  const isClosed = () => store?.openNow === false;
  function nextOpenText() {
    const n = store?.nextOpen;
    if (!n) return '';
    if (n.in_days === 0) return t('Opens today at {time}', { time: n.time });
    if (n.in_days === 1) return t('Opens tomorrow at {time}', { time: n.time });
    return t('Opens {day} at {time}', { day: DAYS[(n.weekday || 1) - 1], time: n.time });
  }
  const closedNote = () => `<div class="sf-closed" role="status">${icon('clock')}<div><b>${esc(t('This store is closed right now.'))}</b><small>${esc(nextOpenText() || t('You can browse the menu; ordering opens when the store is open.'))}</small></div></div>`;

  // ------------------------------------------------------------- routing
  function route() {
    const h = location.hash.replace(/^#\/?/, '');
    const [a, b] = h.split('/');
    if (a === 'p' && b && product(b)) return { name: 'product', id: b };
    if (a === 'c' && b) return { name: 'category', id: b };
    if (a === 'cart') return { name: 'cart' };
    if (a === 'checkout') return { name: 'checkout' };
    if (a === 'done' && lastOrder) return { name: 'done' };
    if (a === 'all') return { name: 'all' };
    return { name: 'home' };
  }
  const go = path => { if (location.hash !== `#/${path}`) location.hash = `#/${path}`; else render(); };

  // ------------------------------------------------------------- ctx for templates
  function ctx() {
    return {
      s: store, ui, esc, money, moneyShort, icon, img, list, qty, count, total, product, catName, initials,
      hoursText, openLabel, greeting, DAYS, t, isClosed,
      // An image that always fills its box (cover) for banners/heroes.
      hero: (fallbackProduct, cls = '') => store.heroUrl
        ? `<img class="${cls}" src="${esc(store.heroUrl)}" alt="" loading="lazy">`
        : (fallbackProduct ? img(fallbackProduct, cls) : `<div class="sf-ph ${cls}"></div>`),
      headline: fb => store.tagline || fb,
      // Standard action attributes (the engine handles them).
      open: id => `data-act="open" data-id="${esc(id)}"`,
      add: id => `data-act="add" data-id="${esc(id)}"`,
      cat: id => `data-act="cat" data-id="${esc(id || '')}"`,
      catPage: id => `data-act="catpage" data-id="${esc(id || '')}"`,
      empty: msg => `<div class="sf-empty">${esc(msg ? t(msg) : t(ui.q ? 'No products match your search.' : 'No products yet.'))}</div>`,
      searchInput: (ph, cls = '') => `<input class="sf-search ${cls}" type="search" data-act="search" placeholder="${esc(t(ph || 'Search'))}" value="${esc(ui.q)}" aria-label="${esc(t('Search products'))}">`,
      stepper: (id, cls = '') => {
        const q = id === '__sel' ? ui.sel : qty(id);
        const act = id === '__sel' ? 'sel' : 'q';
        return `<div class="sf-stepper ${cls}"><button type="button" data-act="${act}-" data-id="${esc(id)}" aria-label="${esc(t('Remove one'))}">${icon('minus')}</button><span>${q}</span><button type="button" data-act="${act}+" data-id="${esc(id)}" aria-label="${esc(t('Add one'))}">${icon('plus')}</button></div>`;
      },
      buy: (label, cls = '') => `<button type="button" class="${cls}" data-act="buy">${label}</button>`,
      toCart: (cls = '', inner) => `<button type="button" class="${cls}" data-act="tocart" aria-label="${esc(t('Cart'))}">${inner || icon('bag')}${count() ? `<i class="sf-badge">${count()}</i>` : ''}</button>`,
      home: cls => `data-act="home"${cls ? ` class="${cls}"` : ''}`,
      selImg: i => `data-act="img" data-id="${i}"`,
    };
  }

  // ------------------------------------------------------------- shared views
  const langSwitch = () => `<div class="sf-lang" role="group" aria-label="Language / Bahasa"><button type="button" data-act="lang" data-id="en" class="${lang === 'en' ? 'on' : ''}" aria-pressed="${lang === 'en'}">English</button><button type="button" data-act="lang" data-id="ms" class="${lang === 'ms' ? 'on' : ''}" aria-pressed="${lang === 'ms'}">Bahasa Melayu</button></div>`;
  function cartView() {
    const lines = [...cart].filter(([id]) => product(id));
    return `<div class="sf-flow">
      <header class="sf-flow-top"><button type="button" class="sf-round" data-act="back" aria-label="${esc(t('Back'))}">${icon('arrowLeft')}</button><h1>${esc(t('Your order'))}</h1>${lines.length ? `<button type="button" class="sf-link sf-clear" data-act="clear">${esc(t('Empty cart'))}</button>` : '<span></span>'}</header>
      ${isClosed() ? closedNote() : ''}
      ${lines.length ? `<ul class="sf-lines">${lines.map(([id]) => { const p = product(id); return `<li>${img(p, 'sf-line-img')}<div><b>${esc(p.name)}</b><small>${money(p.price)}</small></div>${ctx().stepper(id)}</li>`; }).join('')}</ul>
      <div class="sf-sum"><span>${esc(t('Total'))}</span><b>${money(total())}</b></div>
      <p class="sf-note">${esc(t('Final prices are confirmed by {store} when your order is received.', { store: store.name }))}</p>
      <button type="button" class="sf-cta" data-act="checkout" ${isClosed() ? 'disabled' : ''}>${esc(t(isClosed() ? 'Closed' : 'Continue'))}</button>`
      : `<div class="sf-empty">${esc(t('Your cart is empty.'))}</div><button type="button" class="sf-cta" data-act="home">${esc(t('Browse products'))}</button>`}
      ${langSwitch()}
    </div>`;
  }
  function checkoutView(err) {
    const n = count();
    return `<div class="sf-flow">
      <header class="sf-flow-top"><button type="button" class="sf-round" data-act="back" aria-label="${esc(t('Back'))}">${icon('arrowLeft')}</button><h1>${esc(t('Delivery details'))}</h1><span></span></header>
      ${isClosed() ? closedNote() : ''}
      <form class="sf-form" id="sfForm" novalidate>
        <label>${esc(t('Name'))}<input name="name" autocomplete="name" maxlength="120" required></label>
        <label>${esc(t('Phone'))}<input name="phone" autocomplete="tel" inputmode="tel" maxlength="30" required placeholder="+60 12-345 6789"></label>
        <label>${esc(t('Delivery address'))}<textarea name="address" rows="3" maxlength="500" required></textarea></label>
        <label>${esc(t('Notes (optional)'))}<textarea name="notes" rows="2" maxlength="500"></textarea></label>
        <div class="sf-sum"><span>${esc(t(n === 1 ? '{n} item' : '{n} items', { n }))}</span><b>${money(total())}</b></div>
        <p class="sf-note">${esc(t('Payment is arranged directly with {store}. Cefflo does not take payment for this order.', { store: store.name }))}</p>
        ${err ? `<p class="sf-error" role="alert">${esc(err)}</p>` : ''}
        <button type="submit" class="sf-cta" id="sfPlace" ${isClosed() ? 'disabled' : ''}>${esc(t(isClosed() ? 'Closed' : 'Place order'))}</button>
      </form>
      ${langSwitch()}
    </div>`;
  }
  function doneView() {
    const link = lastOrder?.token && cfg.trackingBaseUrl ? `${cfg.trackingBaseUrl}?token=${encodeURIComponent(lastOrder.token)}` : null;
    return `<div class="sf-flow sf-done">
      <div class="sf-done-mark">${icon('check')}</div>
      <h1>${esc(t('Order received'))}</h1>
      <p>${esc(t('Your order number is'))} <b>${esc(lastOrder?.ref || '')}</b>.</p>
      <p class="sf-note">${esc(t('{store} will confirm your order.', { store: store.name }))}</p>
      ${link ? `<a class="sf-cta" href="${esc(link)}">${esc(t('Track your order'))}</a>` : ''}
      <button type="button" class="sf-link" data-act="home">${esc(t('Back to the store'))}</button>
      ${langSwitch()}
    </div>`;
  }

  // ------------------------------------------------------------- render
  let form = {};
  function render(err) {
    const r = route();
    const c = ctx();
    let html;
    if (r.name === 'cart') html = cartView();
    else if (r.name === 'checkout') html = cart.size ? checkoutView(err) : cartView();
    else if (r.name === 'done') html = doneView();
    else if (r.name === 'product') html = tpl.product(c, product(r.id));
    else if (r.name === 'category') html = (tpl.category || tpl.home).call(tpl, c, r.id);
    else if (r.name === 'all') html = (tpl.all || tpl.category || tpl.home).call(tpl, c, null);
    else if (tpl.intro && !ui.intro) html = tpl.intro(c);
    else html = tpl.home(c);
    const bar = ['home', 'category', 'all'].includes(r.name) && count() && tpl.bar !== false
      ? (tpl.bar ? tpl.bar(c) : `<button type="button" class="sf-bar" data-act="tocart"><span>${esc(t(count() === 1 ? '{n} item' : '{n} items', { n: count() }))}</span><b>${money(total())}</b><span>${esc(t('View cart'))} ${icon('arrowRight')}</span></button>`)
      : '';
    app.className = `sf t-${tplKey} r-${r.name}${isClosed() ? ' is-closed' : ''}`;
    const browse = !['cart', 'checkout', 'done'].includes(r.name);
    app.innerHTML = `<div class="sf-page">${browse && isClosed() ? closedNote() : ''}${html}${browse && !EMBED ? `<footer class="sf-foot">${langSwitch()}</footer>` : ''}</div>${bar}`;
    if (r.name === 'checkout' && cart.size) {
      const f = document.getElementById('sfForm');
      for (const [k, v] of Object.entries(form)) if (f.elements[k]) f.elements[k].value = v;
      f.addEventListener('input', e => { form[e.target.name] = e.target.value; });
      if (err) { const bad = f.querySelector('[aria-invalid="true"]'); bad?.focus(); }
      f.addEventListener('submit', submit);
    }
  }

  // A server refusal comes back as {error} (so failed attempts stay counted
  // by the rate limit); transport problems throw.
  const errorText = m => (/rate limited/.test(m) ? t('Too many attempts. Please wait a minute and try again.')
    : /store closed/.test(m) ? `${t('This store is closed right now.')} ${nextOpenText()}`.trim()
    : /phone/.test(m) ? t('Enter a valid phone number, for example +60 12-345 6789.')
    : /available|product|item|quantity/i.test(m) ? t('Some items are no longer available. Please review your order.')
    : t('We could not place your order. Please try again.'));
  async function submit(e) {
    e.preventDefault();
    const name = (form.name || '').trim(), phone = (form.phone || '').trim(), address = (form.address || '').trim();
    if (!name || !phone || !address) return render(t('Please fill in your name, phone and delivery address.'));
    if (!phoneOk(phone)) return render(t('Enter a valid phone number, for example +60 12-345 6789.'));
    if (EMBED) return render(t('This is a preview. Orders are placed from your live storefront.'));
    if (isClosed()) return render(`${t('This store is closed right now.')} ${nextOpenText()}`.trim());
    const btn = document.getElementById('sfPlace');
    btn.disabled = true; btn.textContent = t('Placing order…');
    try {
      const res = await rpc('submit_storefront_order', {
        p_slug: store.slug, p_items: [...cart].map(([product_id, quantity]) => ({ product_id, quantity })),
        p_customer_name: name, p_customer_phone: phone, p_delivery_address: address,
        p_delivery_notes: (form.notes || '').trim(), p_idempotency_key: idempotencyKey,
      });
      if (res?.error) {
        if (/store closed/.test(res.error)) { store.openNow = false; store.nextOpen = res.next_open || store.nextOpen; }
        return render(errorText(res.error));
      }
      lastOrder = { ref: res.order_reference, token: res.tracking_token };
      cart.clear(); saveCart(); form = {}; idempotencyKey = crypto.randomUUID();
      go('done');
    } catch (ex) {
      // The same key is kept, so a retry never creates a second order (a
      // replay returns the same order and its tracking link).
      render(ex.status ? errorText(String(ex.message || '')) : t('No connection. Please check your internet and try again.'));
    }
  }

  // ------------------------------------------------------------- events
  app.addEventListener('click', e => {
    const t = e.target.closest('[data-act]');
    if (!t || t.tagName === 'INPUT') return;
    const act = t.dataset.act, id = t.dataset.id;
    const bump = (pid, d) => { const n = Math.max(0, Math.min(50, qty(pid) + d)); if (n) cart.set(pid, n); else cart.delete(pid); saveCart(); };
    switch (act) {
      case 'open': ui.sel = 1; ui.img = 0; go(`p/${id}`); break;
      case 'add': bump(id, 1); render(); break;
      case 'q+': bump(id, 1); render(); break;
      case 'q-': bump(id, -1); render(); break;
      case 'sel+': ui.sel = Math.min(50, ui.sel + 1); render(); break;
      case 'sel-': ui.sel = Math.max(1, ui.sel - 1); render(); break;
      case 'buy': { const r = route(); if (r.name === 'product') { bump(r.id, ui.sel); ui.sel = 1; } go('cart'); break; }
      case 'addsel': { const r = route(); if (r.name === 'product') { bump(r.id, ui.sel); ui.sel = 1; } render(); break; }
      case 'img': ui.img = Number(id) || 0; render(); break;
      case 'cat': ui.cat = id || null; render(); break;
      case 'catpage': ui.cat = id || null; go(id ? `c/${id}` : 'all'); break;
      case 'tocart': go('cart'); break;
      case 'checkout': go('checkout'); break;
      case 'home': ui.cat = null; ui.intro = true; go(''); break;
      case 'intro': ui.intro = true; render(); break;
      case 'back': history.length > 1 ? history.back() : go(''); break;
      case 'clear': cart.clear(); saveCart(); render(); break;
      case 'lang': lang = id === 'ms' ? 'ms' : 'en'; DAYS = lang === 'ms' ? DAYS_MS : DAYS_EN; try { localStorage.setItem(LANG_KEY, lang); } catch { /* private mode */ } document.documentElement.lang = lang; render(); break;
      default: break;
    }
  });
  app.addEventListener('input', e => {
    if (e.target.dataset?.act !== 'search') return;
    ui.q = e.target.value;
    const pos = e.target.selectionStart;
    render();
    const s = app.querySelector('[data-act="search"]');
    if (s) { s.focus(); try { s.setSelectionRange(pos, pos); } catch { /* ignore */ } }
  });
  window.addEventListener('hashchange', () => { render(); window.scrollTo(0, 0); });

  // ------------------------------------------------------------- boot
  function useTemplate(key) {
    // Unknown / retired keys (e.g. the pre-V1 default 'arena') use Care.
    tplKey = T[key] ? key : 'care';
    tpl = T[tplKey];
    const th = store.theme || {}, d = tpl.defaults || {};
    const root = document.documentElement.style;
    root.setProperty('--accent', /^#[0-9a-f]{6}$/i.test(th.accent || '') ? th.accent : d.accent);
    root.setProperty('--accent2', /^#[0-9a-f]{6}$/i.test(th.secondary || '') ? th.secondary : d.accent2 || d.accent);
    root.setProperty('--bg', /^#[0-9a-f]{6}$/i.test(th.background_color || '') ? th.background_color : d.bg || '#ffffff');
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', d.bar || '#ffffff');
  }
  // Robots: a live, published storefront is indexable; previews and missing /
  // unpublished storefronts are not.
  function setRobots(index) {
    let m = document.querySelector('meta[name="robots"]');
    if (!index) { if (!m) { m = document.createElement('meta'); m.name = 'robots'; document.head.append(m); } m.content = 'noindex'; }
    else m?.remove();
  }
  function setMeta(name, content, prop = false) {
    const sel = prop ? `meta[property="${name}"]` : `meta[name="${name}"]`;
    let m = document.querySelector(sel);
    if (!m) { m = document.createElement('meta'); m.setAttribute(prop ? 'property' : 'name', name); document.head.append(m); }
    m.content = content;
  }
  function state(msg) { setRobots(false); app.innerHTML = `<p class="sf-state">${esc(t(msg))}</p>`; }
  function start(raw) {
    store = normalise(raw);
    document.title = store.name || 'Storefront';
    document.documentElement.lang = lang;
    useTemplate(params.get('template') || store.templateKey);
    if (EMBED) setRobots(false);
    else {
      setRobots(true);
      const desc = [store.tagline, store.area].filter(Boolean).join(' · ') || store.name;
      setMeta('description', desc); setMeta('og:title', store.name, true); setMeta('og:description', desc, true); setMeta('og:type', 'website', true);
      restoreCart();
    }
    render();
  }
  async function load() {
    if (EMBED) {
      // Vendor App / Vendor Web live preview: the app posts its own
      // storefront_preview payload; no backend call, ordering disabled. Only
      // the configured Vendor / Operator app and Vendor Web origins may feed it (a foreign site framing
      // ?embed=1 cannot paint content on this domain).
      const allowed = new Set([...Object.values(cfg.appWebUrls || {}), cfg.vendorConsoleUrl].filter(Boolean).map(u => { try { return new URL(u).origin; } catch { return null; } }).filter(Boolean));
      setRobots(false);
      if (window.parent === window) { state('Preview is shown inside the Cefflo app.'); return; }
      window.addEventListener('message', ev => {
        if (!allowed.has(ev.origin) || ev.source !== window.parent) return;
        if (ev.data?.type === 'cefflo-storefront-preview' && ev.data.store) start(ev.data.store);
      });
      window.parent.postMessage({ type: 'cefflo-storefront-ready' }, '*');
      return;
    }
    if (!/^[a-z0-9]([a-z0-9-]{1,28}[a-z0-9])$/.test(slug)) { state('This storefront does not exist.'); return; }
    let raw;
    try { raw = await rpc('public_storefront', { p_slug: slug }); }
    catch (e) { state(/rate limited/.test(e.message) ? 'Too many visits right now. Please try again in a minute.' : 'We could not load this storefront. Please try again.'); return; }
    if (!raw) { state('This storefront is not available.'); return; }
    if (raw.slug !== slug) history.replaceState(null, '', `/${raw.slug}${location.search}${location.hash}`);
    start(raw);
  }
  window.CEFFLO_STORE_PREVIEW = start; // tests / tooling
  load();
})();
