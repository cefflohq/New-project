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

  // Customer language: English only (Founder 2026-10-17). Vendor content is
  // never translated.
  let lang = 'en';
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
  // Cefflo icon set: Lucide (lucide-static 1.48.0), the same family as the
  // Vendor and Driver apps (lucide_icons_flutter).
  const P = {
    back: '<path d="m15 18-6-6 6-6" />',
    arrowLeft: '<path d="m12 19-7-7 7-7" /> <path d="M19 12H5" />',
    locate: '<line x1="2" x2="5" y1="12" y2="12" /> <line x1="19" x2="22" y1="12" y2="12" /> <line x1="12" x2="12" y1="2" y2="5" /> <line x1="12" x2="12" y1="19" y2="22" /> <circle cx="12" cy="12" r="7" /> <circle cx="12" cy="12" r="3" />',
    mapPin: '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0" /> <circle cx="12" cy="10" r="3" />',
    arrowRight: '<path d="M5 12h14" /> <path d="m12 5 7 7-7 7" />',
    arrowDown: '<path d="M12 5v14" /> <path d="m19 12-7 7-7-7" />',
    bag: '<path d="M16 10a4 4 0 0 1-8 0" /> <path d="M3.103 6.034h17.794" /> <path d="M3.4 5.467a2 2 0 0 0-.4 1.2V20a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6.667a2 2 0 0 0-.4-1.2l-2-2.667A2 2 0 0 0 17 2H7a2 2 0 0 0-1.6.8z" />',
    cart: '<path d="m2.05 2.05 1.099-.028a1 1 0 0 1 1.008.815l2.69 14.347A1 1 0 0 0 7.83 18H18" /> <path d="M4.563 5h16.435a1 1 0 0 1 .981 1.204l-1.026 6.226A2 2 0 0 1 18.962 14H6.25" /> <circle cx="18" cy="20" r="2" /> <circle cx="8" cy="20" r="2" />',
    basket: '<path d="m15 11-1 9" /> <path d="m19 11-4-7" /> <path d="M2 11h20" /> <path d="m3.5 11 1.6 7.4a2 2 0 0 0 2 1.6h9.8a2 2 0 0 0 2-1.6l1.7-7.4" /> <path d="M4.5 15.5h15" /> <path d="m5 11 4-7" /> <path d="m9 11 1 9" />',
    search: '<path d="m21 21-4.34-4.34" /> <circle cx="11" cy="11" r="8" />',
    heart: '<path d="M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5" />',
    plus: '<path d="M5 12h14" /> <path d="M12 5v14" />',
    minus: '<path d="M5 12h14" />',
    menu: '<path d="M4 5h16" /> <path d="M4 12h16" /> <path d="M4 19h16" />',
    grid: '<rect width="7" height="7" x="3" y="3" rx="1" /> <rect width="7" height="7" x="14" y="3" rx="1" /> <rect width="7" height="7" x="14" y="14" rx="1" /> <rect width="7" height="7" x="3" y="14" rx="1" />',
    dots: '<circle cx="12" cy="12" r="1" /> <circle cx="12" cy="5" r="1" /> <circle cx="12" cy="19" r="1" />',
    bell: '<path d="M10.268 21a2 2 0 0 0 3.464 0" /> <path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326" />',
    user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" /> <circle cx="12" cy="7" r="4" />',
    home: '<path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8" /> <path d="M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />',
    pin: '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0" /> <circle cx="12" cy="10" r="3" />',
    filter: '<path d="M10 5H3" /> <path d="M12 19H3" /> <path d="M14 3v4" /> <path d="M16 17v4" /> <path d="M21 12h-9" /> <path d="M21 19h-5" /> <path d="M21 5h-7" /> <path d="M8 10v4" /> <path d="M8 12H3" />',
    share: '<path d="M12 2v13" /> <path d="m16 6-4-4-4 4" /> <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" />',
    check: '<path d="M20 6 9 17l-5-5" />',
    clock: '<circle cx="12" cy="12" r="10" /> <path d="M12 6v6l4 2" />',
    orders: '<path d="M12 17V7" /> <path d="M16 8h-6a2 2 0 0 0 0 4h4a2 2 0 0 1 0 4H8" /> <path d="M4 3a1 1 0 0 1 1-1 1.3 1.3 0 0 1 .7.2l.933.6a1.3 1.3 0 0 0 1.4 0l.934-.6a1.3 1.3 0 0 1 1.4 0l.933.6a1.3 1.3 0 0 0 1.4 0l.933-.6a1.3 1.3 0 0 1 1.4 0l.934.6a1.3 1.3 0 0 0 1.4 0l.933-.6A1.3 1.3 0 0 1 19 2a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1 1.3 1.3 0 0 1-.7-.2l-.933-.6a1.3 1.3 0 0 0-1.4 0l-.934.6a1.3 1.3 0 0 1-1.4 0l-.933-.6a1.3 1.3 0 0 0-1.4 0l-.933.6a1.3 1.3 0 0 1-1.4 0l-.934-.6a1.3 1.3 0 0 0-1.4 0l-.933.6a1.3 1.3 0 0 1-.7.2 1 1 0 0 1-1-1z" />',
    tag: '<path d="M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2 2 0 0 0 .586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0l6.58-6.58a2.426 2.426 0 0 0 0-3.42z" /> <circle cx="7.5" cy="7.5" r=".5" fill="currentColor" />',
    star: '<path d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z" />',
    box: '<path d="M11 21.73a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73z" /> <path d="M12 22V12" /> <polyline points="3.29 7 12 12 20.71 7" /> <path d="m7.5 4.27 9 5.15" />',
    shield: '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z" /> <path d="m9 12 2 2 4-4" />',
    phone: '<path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384" />',
    chat: '<path d="M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719" />',
    chevronDown: '<path d="m6 9 6 6 6-6" />',
    chevronRight: '<path d="m9 18 6-6-6-6" />',
    sparkle: '<path d="M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z" /> <path d="M20 2v4" /> <path d="M22 4h-4" /> <circle cx="4" cy="20" r="2" />',
    percent: '<line x1="19" x2="5" y1="5" y2="19" /> <circle cx="6.5" cy="6.5" r="2.5" /> <circle cx="17.5" cy="17.5" r="2.5" />',
    apps: '<rect width="7" height="7" x="3" y="3" rx="1" /> <rect width="7" height="7" x="14" y="3" rx="1" /> <rect width="7" height="7" x="14" y="14" rx="1" /> <rect width="7" height="7" x="3" y="14" rx="1" />',
    info: '<circle cx="12" cy="12" r="10" /> <path d="M12 16v-4" /> <path d="M12 8h.01" />',
    flame: '<path d="M12 3q1 4 4 6.5t3 5.5a1 1 0 0 1-14 0 5 5 0 0 1 1-3 1 1 0 0 0 5 0c0-2-1.5-3-1.5-5q0-2 2.5-4" />',
  };

  const icon = (n, cls = '') => `<svg class="ic ${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${P[n] || ''}</svg>`;

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
  const ui = { cat: null, q: '', sel: 1, img: 0, intro: false, size: null };
  let idempotencyKey = crypto.randomUUID();
  let lastOrder = null;
  let lastRouteKey = '', lastCount = 0;

  function normalise(raw) {
    const theme = raw.theme || {};
    const products = (raw.products || []).map(p => ({
      id: p.id, categoryId: p.category_id, name: p.name || '', description: p.description || '',
      price: Number(p.display_price || 0), images: (p.images || []).map(abs).filter(Boolean),
      // Background-removed main photo (transparent PNG), when the vendor has one.
      cutout: abs(p.cutout_url) || null,
      // One cut-out per photo when the vendor has them (colour variants).
      cutouts: (Array.isArray(p.cutout_urls) ? p.cutout_urls : [p.cutout_url]).map(u => abs(u) || null),
      // Size choices (e.g. S–XXL) when the vendor lists them.
      sizes: Array.isArray(p.sizes) ? p.sizes.filter(z => typeof z === 'string' && z.trim()).slice(0, 8) : [],
    }));
    return {
      slug: raw.slug, name: raw.business?.name || '', area: raw.business?.area || '',
      tagline: theme.tagline || '', theme, heroUrl: abs(raw.hero_url), logoUrl: abs(raw.logo_url), openNow: raw.open_now, nextOpen: raw.next_open || null,
      hours: Array.isArray(raw.hours) ? raw.hours : [], products,
      categories: (raw.categories || []).filter(c => products.some(p => p.categoryId === c.id)),
      templateKey: raw.template_key,
      // Delivery plan set by the vendor: fee per drop (= the driver's pay, never
      // free), delivery weekdays (1 = Mon), shifts (fixed batches) and package
      // lengths in weeks. No fee set = the store confirms delivery itself.
      delivery: {
        fee: raw.delivery?.fee == null ? null : Number(raw.delivery.fee),
        days: Array.isArray(raw.delivery?.days) && raw.delivery.days.length ? raw.delivery.days.map(Number) : [1, 2, 3, 4, 5],
        shifts: Array.isArray(raw.delivery?.shifts) ? raw.delivery.shifts : [],
        weeks: Array.isArray(raw.delivery?.weeks) && raw.delivery.weeks.length ? raw.delivery.weeks.map(Number) : [1, 2, 4],
        coverage: !!raw.delivery?.coverage,
      },
      // Online payment needs the vendor's own CHIP account; COD is allowed when
      // the vendor turns it on, and is the only way to pay without CHIP.
      payOnline: !!raw.payments?.online, payCod: raw.payments ? raw.payments.cod !== false || !raw.payments.online : true,
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
  const initials = s => (s || '').replace(/[^\p{L}\p{N}\s]/gu, '').split(/\s+/).filter(Boolean).slice(0, 2).map(w => w[0]).join('').toUpperCase() || '·';
  function img(p, cls = '', i = 0) {
    // Cut-out templates float the product on their colour (as the references
    // do) when a cut-out exists; otherwise the photo fills its frame.
    const cut = tpl?.cutout && (p?.cutouts?.[i] || (i === 0 && p?.cutout));
    const src = cut || p?.images?.[i];
    if (cut) cls = `${cls} sf-cut`;
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
      // The vendor's logo, or their initials when none is uploaded.
      logo: (cls = '') => store.logoUrl
        ? `<img class="${cls} is-img" src="${esc(store.logoUrl)}" alt="${esc(store.name)}">`
        : `<span class="${cls}" aria-hidden="true">${esc(initials(store.name))}</span>`,
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
  function cartView() {
    const lines = [...cart].filter(([id]) => product(id));
    return `<div class="sf-flow">
      <header class="sf-flow-top"><button type="button" class="sf-round" data-act="back" aria-label="${esc(t('Back'))}">${icon('arrowLeft')}</button><h1>${esc(t('Your order'))}</h1>${lines.length ? `<button type="button" class="sf-link sf-clear" data-act="clear">${esc(t('Empty cart'))}</button>` : '<span></span>'}</header>
      ${isClosed() ? closedNote() : ''}
      ${lines.length ? `<ul class="sf-lines">${lines.map(([id]) => { const p = product(id); return `<li>${img(p, 'sf-line-img')}<div><b>${esc(p.name)}</b><small>${money(p.price)}</small></div>${ctx().stepper(id)}</li>`; }).join('')}</ul>
      <div class="sf-sum"><span>${esc(t('Total'))}</span><b>${money(total())}</b></div>
      <p class="sf-note">${esc(t('Final prices are confirmed by {store} when your order is received.', { store: store.name }))}</p>
      <button type="button" class="sf-cta" data-act="checkout" ${isClosed() ? 'disabled' : ''}>${esc(t(isClosed() ? 'Closed' : 'Checkout'))}</button>`
      : `<div class="sf-empty">${esc(t('Your cart is empty.'))}</div><button type="button" class="sf-cta" data-act="home">${esc(t('Browse products'))}</button>`}
    </div>`;
  }
  // Delivery plan. 'once' = one delivery; otherwise the chosen weekdays every
  // week for the chosen number of weeks. Goods and delivery repeat per drop.
  const DAYN = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  function plan() {
    const d = store.delivery;
    if (!form.weeks || (form.weeks !== 'once' && !d.weeks.includes(Number(form.weeks)))) form.weeks = 'once';
    if (!Array.isArray(form.days)) form.days = [...d.days];
    form.days = form.days.filter(x => d.days.includes(x));
    if (d.shifts.length && !d.shifts.some(x => x.name === form.shift)) form.shift = d.shifts[0].name;
    const once = form.weeks === 'once';
    const drops = once ? 1 : form.days.length * Number(form.weeks);
    const goods = total() * drops, fee = d.fee == null ? null : d.fee * drops;
    return { once, drops, goods, fee, grand: goods + (fee || 0) };
  }
  function planText(pl) {
    const sh = store.delivery.shifts.find(x => x.name === form.shift);
    return [pl.once ? 'One delivery' : `${form.days.map(x => DAYN[x - 1]).join(', ')} × ${form.weeks} week${form.weeks == 1 ? '' : 's'} (${pl.drops} deliveries)`,
      sh ? `${sh.name} ${sh.from}–${sh.to}` : '', store.delivery.fee != null ? `Delivery RM ${store.delivery.fee.toFixed(2)} × ${pl.drops}` : ''].filter(Boolean).join(' · ');
  }
  // One-page checkout (Founder: as easy as TikTok / Shopee): address, items,
  // payment, total + Place order. Details are remembered on this device.
  function checkoutView(err) {
    const lines = [...cart].filter(([id]) => product(id));
    const methods = [
      ...(store.payOnline ? [['duitnow', 'DuitNow QR', 'Any bank or e-wallet app'], ['fpx', 'Online banking (FPX)', 'Maybank2u, CIMB Clicks and more']] : []),
      ...(store.payCod ? [['cod', 'Cash on delivery', 'Pay the rider when it arrives']] : []),
    ];
    if (!methods.some(m => m[0] === form.pay)) form.pay = methods[0]?.[0] || 'cod';
    const d = store.delivery, pl = plan();
    return `<div class="sf-flow sf-co">
      <header class="sf-flow-top"><button type="button" class="sf-round" data-act="back" aria-label="${esc(t('Back'))}">${icon('arrowLeft')}</button><h1>${esc(t('Checkout'))}</h1><span></span></header>
      ${isClosed() ? closedNote() : ''}
      <form class="sf-form" id="sfForm" novalidate>
        <section class="co-box"><h2>${icon('mapPin')} ${esc(t('Delivery address'))}</h2>
          <div class="co-two"><label>${esc(t('Name'))}<input name="name" autocomplete="name" maxlength="120" required></label>
          <label>${esc(t('Phone'))}<input name="phone" autocomplete="tel" inputmode="tel" maxlength="30" required placeholder="+60 12-345 6789"></label></div>
          <label>${esc(t('Address'))}<textarea name="address" rows="2" maxlength="500" required></textarea></label>
          <div class="sf-pin">
            <div class="sf-pin-map" id="sfPinMap">
              <div class="sf-map-canvas"></div>
              <div class="sf-map-pin" aria-hidden="true"><svg viewBox="0 0 40 52"><path d="M20 51C20 51 37 31.6 37 19.5A17 17 0 0 0 3 19.5C3 31.6 20 51 20 51Z"/><circle cx="20" cy="19.5" r="6.5"/></svg><i></i></div>
              <span class="sf-map-acc" hidden></span>
              <div class="sf-map-zoom"><button type="button" data-act="zoomin" aria-label="${esc(t('Zoom in'))}">${icon('plus')}</button><button type="button" data-act="zoomout" aria-label="${esc(t('Zoom out'))}">${icon('minus')}</button></div>
              <button type="button" class="sf-map-locate" data-act="pin" aria-label="${esc(t('Use my current location'))}">${icon('locate')}</button>
              <div class="sf-map-start"><button type="button" data-act="pin">${icon('locate')} ${esc(t('Use my current location'))}</button></div>
              ${mapboxToken() ? '' : '<small class="sf-map-attr">© OpenStreetMap · OpenFreeMap</small>'}
            </div>
            <p class="sf-pin-hint" id="sfPinHint">${esc(t('Pin your exact location so the rider finds you without calling.'))}</p>
          </div>
          <label>${esc(t('Note for the rider (optional)'))}<input name="notes" maxlength="500" placeholder="${esc(t('e.g. blue gate, leave at the guardhouse'))}"></label>
        </section>
        <section class="co-box"><h2>${icon('bag')} ${esc(store.name)}</h2>
          <ul class="co-items">${lines.map(([id, q]) => { const p = product(id); return `<li>${img(p, 'co-img')}<div><b>${esc(p.name)}</b><small>× ${q}</small></div><span>${money(p.price * q)}</span></li>`; }).join('')}</ul>
        </section>
        <section class="co-box"><h2>${icon('clock')} ${esc(t('Delivery schedule'))}</h2>
          <div class="co-seg" role="radiogroup" aria-label="${esc(t('How often'))}">${[['once', t('Once')], ...d.weeks.map(w => [String(w), t(w === 1 ? '1 week' : '{n} weeks', { n: w })])].map(([k, l]) => `<button type="button" role="radio" aria-checked="${String(form.weeks) === k}" class="${String(form.weeks) === k ? 'on' : ''}" data-act="weeks" data-id="${k}">${esc(l)}</button>`).join('')}</div>
          ${pl.once ? '' : `<div class="co-days" role="group" aria-label="${esc(t('Delivery days'))}">${[1, 2, 3, 4, 5, 6, 7].map(x => { const ok = d.days.includes(x), on = form.days.includes(x); return `<button type="button" aria-pressed="${on}" class="${on ? 'on' : ''}" data-act="day" data-id="${x}" ${ok ? '' : 'disabled'}>${esc(t(DAYN[x - 1]))}</button>`; }).join('')}</div>`}
          ${d.shifts.length ? `<div class="co-pay" role="radiogroup" aria-label="${esc(t('Delivery time'))}">${d.shifts.map(x => `<button type="button" role="radio" aria-checked="${form.shift === x.name}" class="${form.shift === x.name ? 'on' : ''}" data-act="shift" data-id="${esc(x.name)}"><span class="co-dot"></span><span><b>${esc(x.name)}</b><small>${esc(t('Arrives {from}–{to}', { from: x.from, to: x.to }))}</small></span></button>`).join('')}</div>` : ''}
          ${pl.once ? '' : `<p class="co-hint">${esc(t('{n} deliveries. Your items are sent on each day.', { n: pl.drops }))}</p>`}
        </section>
        <section class="co-box"><h2>${icon('shield')} ${esc(t('Payment method'))}</h2>
          <div class="co-pay" role="radiogroup">${methods.map(([k, label, sub]) => `<button type="button" role="radio" aria-checked="${form.pay === k}" class="${form.pay === k ? 'on' : ''}" data-act="pay" data-id="${k}"><span class="co-dot"></span><span><b>${esc(t(label))}</b><small>${esc(t(sub))}</small></span></button>`).join('')}</div>
        </section>
        <section class="co-box co-sum"><div><span>${esc(pl.once ? t('Subtotal') : t('Items × {n} deliveries', { n: pl.drops }))}</span><span>${money(pl.goods)}</span></div><div><span>${esc(pl.once ? t('Delivery fee') : t('Delivery {fee} × {n}', { fee: money(d.fee || 0), n: pl.drops }))}</span><span>${pl.fee == null ? esc(t('Confirmed by the store')) : money(pl.fee)}</span></div></section>
        ${err ? `<p class="sf-error" role="alert">${esc(err)}</p>` : ''}
        <div class="co-bar"><div><small>${esc(t('Total'))}</small><b>${money(pl.grand)}</b></div><button type="submit" class="sf-cta" id="sfPlace" ${isClosed() ? 'disabled' : ''}>${esc(t(isClosed() ? 'Closed' : 'Place order'))}</button></div>
      </form>
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
    </div>`;
  }

  // ------------------------------------------------------------- delivery pin
  // Map: Mapbox GL (or the OpenFreeMap/MapLibre fallback, see loadMapLibre).
  // CEFFLO's own UI sits on top:
  // a fixed centre pin (move the map under it), locate + zoom buttons, an
  // accuracy chip. A pin only counts after GPS or a deliberate map move.
  let pin = null, pinMap = null;
  const MY_CENTER = [101.9, 4.2];
  const pinHint = () => !pin ? t('Move the map so the pin sits on your house.')
    : pin.source === 'gps' && pin.acc > 60 ? t('Approximate (±{m} m). Move the map so the pin sits on your house.', { m: Math.round(pin.acc) })
    : t('Pinned. Move the map if the pin is not exactly at your place.');
  // Mapbox GL when the build carries a public pk. token (Founder 2026-10-12);
  // MapLibre over OpenFreeMap otherwise.
  function mapboxToken() {
    const tok = window.CEFFLO_CONFIG?.mapboxPublicToken || '';
    return /^pk\./.test(tok) ? tok : null;
  }
  const MAPBOX_TOKEN = mapboxToken();

  // Map credit behind a small ⓘ (Founder 2026-10-13): the licences need the
  // credit reachable on the map, not spelled out across it.
  function compactCredit(gl, map) {
    map.addControl(new gl.AttributionControl({ compact: true }), 'bottom-left');
    const close = () => map.getContainer().querySelectorAll('.mapboxgl-compact-show, .maplibregl-compact-show')
      .forEach(el => el.classList.remove('mapboxgl-compact-show', 'maplibregl-compact-show'));
    map.once('load', close); close();
  }
  const GL_BASE = MAPBOX_TOKEN ? 'https://api.mapbox.com/mapbox-gl-js/v3.7.0/mapbox-gl' : 'https://cdn.jsdelivr.net/npm/maplibre-gl@4.7.1/dist/maplibre-gl';
  const MAP_STYLE = MAPBOX_TOKEN ? 'mapbox://styles/mapbox/streets-v12' : 'https://tiles.openfreemap.org/styles/positron';
  function loadMapLibre() {
    const ready = () => (MAPBOX_TOKEN ? window.mapboxgl : window.maplibregl);
    if (ready()) return Promise.resolve(ready());
    return new Promise((ok, bad) => {
      const css = document.createElement('link'); css.rel = 'stylesheet';
      css.href = `${GL_BASE}.css`; document.head.append(css);
      const s = document.createElement('script'); s.src = `${GL_BASE}.js`;
      s.onload = () => { const gl = ready(); if (MAPBOX_TOKEN) gl.accessToken = MAPBOX_TOKEN; ok(gl); };
      s.onerror = bad; document.head.append(s);
    });
  }
  function pinUi() {
    const box = document.getElementById('sfPinMap'); if (!box) return;
    box.classList.toggle('has-pin', !!pin);
    const hint = document.getElementById('sfPinHint'); if (hint) hint.textContent = pinHint();
    const acc = box.querySelector('.sf-map-acc');
    if (acc) { acc.hidden = !(pin && pin.source === 'gps' && pin.acc); acc.textContent = pin?.acc ? `±${Math.round(pin.acc)} m` : ''; }
  }
  async function mountPinMap() {
    const box = document.getElementById('sfPinMap'); if (!box) return;
    const gl = await loadMapLibre();
    const canvas = box.querySelector('.sf-map-canvas');
    pinMap?.remove();
    pinMap = new gl.Map({ container: canvas, style: MAP_STYLE,
      center: pin ? [pin.lng, pin.lat] : MY_CENTER, zoom: pin ? 17.5 : 5, attributionControl: false,
      dragRotate: false, pitchWithRotate: false, touchPitch: false });
      compactCredit(gl, pinMap);
    pinMap.touchZoomRotate.disableRotation();
    pinMap.on('movestart', e => { if (e.originalEvent) box.classList.add('is-moving'); });
    pinMap.on('moveend', e => {
      box.classList.remove('is-moving');
      if (!e.originalEvent && !e.byUser) return;               // programmatic moves set the pin themselves
      if (pinMap.getZoom() < 14) { pinUi(); return; }           // too far out to be a house
      const c = pinMap.getCenter();
      pin = { lat: +c.lat.toFixed(6), lng: +c.lng.toFixed(6), source: pin ? 'pin_adjusted' : 'map', acc: null };
      pinUi();
    });
    pinUi();
  }
  function locate() {
    const box = document.getElementById('sfPinMap'); const hint = document.getElementById('sfPinHint');
    box?.classList.add('is-locating');
    if (!navigator.geolocation) { box?.classList.remove('is-locating'); if (hint) hint.textContent = t('Move the map so the pin sits on your house.'); return; }
    if (hint) hint.textContent = t('Finding your location…');
    navigator.geolocation.getCurrentPosition(p => {
      box?.classList.remove('is-locating');
      pin = { lat: +p.coords.latitude.toFixed(6), lng: +p.coords.longitude.toFixed(6), source: 'gps', acc: p.coords.accuracy };
      pinMap?.flyTo({ center: [pin.lng, pin.lat], zoom: 17.5, duration: 900 });
      pinUi();
    }, () => { box?.classList.remove('is-locating'); if (hint) hint.textContent = t('Location is off. Move the map so the pin sits on your house.'); },
    { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 });
  }
  const zoom = d => pinMap?.easeTo({ zoom: pinMap.getZoom() + d, duration: 250 });

  // ------------------------------------------------------------- render
  let form = {};
  // Returning shoppers: name, phone and address are pre-filled from this device.
  try { const me = JSON.parse(localStorage.getItem('cefflo.sf.me') || 'null'); if (me) form = { ...me, ...form }; } catch { /* private mode */ }
  const CARD_SEL = '.wr-row, .tl-card, .ca-row, .ca-card, .ca-cats > *, .sv-offer, .sv-cats > *, .sv-card, .sp5-card, .sp5-chip, .tl-chip, .wr-chip, .sv-card2, .sp5-sizes button, .tl-sizes button';
  // Loading state: a shimmer laid out like the template the store last used
  // (remembered per store), so the page does not jump when data arrives.
  function skeleton(key) {
    const b = (w, h, r = 12, extra = '') => `<i class="sk" style="width:${w};height:${h}px;border-radius:${r}px;${extra}"></i>`;
    const rows = (n, f) => Array.from({ length: n }, f).join('');
    const head = `<div class="sk-row" style="justify-content:space-between">${b('34px', 34, 999)}${b('55%', 34, 999)}${b('34px', 34, 999)}</div>`;
    const v = {
      warung: `${head}${b('70%', 22, 8, 'margin-top:28px')}${b('40%', 14, 6)}<div class="sk-row" style="margin-top:18px">${rows(4, () => b('78px', 30, 999))}</div>${rows(3, () => `<div class="sk-row" style="margin-top:34px">${b('150px', 150, 999)}${b('100%', 120, 24, 'margin-left:-80px')}</div>`)}`,
      tailor: `${head}${b('100%', 172, 18, 'margin-top:16px')}<div class="sk-grid">${rows(4, () => b('100%', 186, 18))}</div>`,
      care: `${head}${b('100%', 44, 12, 'margin-top:14px')}${b('100%', 170, 18, 'margin-top:14px')}<div class="sk-row" style="margin-top:18px">${rows(4, () => b('56px', 56, 14))}</div><div class="sk-grid">${rows(2, () => b('100%', 200, 14))}</div>`,
      service: `${b('calc(100% + 40px)', 160, 26, 'margin:-20px -20px 0')}<div class="sk-row" style="margin-top:20px">${b('80%', 150, 16)}${b('20%', 150, 16)}</div><div class="sk-row" style="margin-top:20px">${rows(4, () => b('56px', 56, 999))}</div><div class="sk-row" style="margin-top:20px">${rows(2, () => b('50%', 120, 14))}</div>`,
      pour: `${head}${b('60%', 34, 8, 'margin-top:22px')}${b('100%', 50, 999, 'margin-top:16px')}<div class="sk-row" style="margin-top:20px">${rows(3, () => b('84px', 38, 999))}</div>${rows(2, () => b('100%', 280, 22, 'margin-top:14px'))}`,
    };
    return `<div class="sf sf-skel t-${key}" aria-busy="true" aria-label="${esc(t('Loading store'))}"><div class="sk-wrap">${v[key] || v.care}</div></div>`;
  }
  window.CEFFLO_STORE_SKELETON = key => { app.className = ''; app.innerHTML = skeleton(key); };
  document.addEventListener('load', e => { if (e.target.tagName === 'IMG') e.target.classList.add('is-in'); }, true);

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
    app.innerHTML = `<div class="sf-page">${browse && isClosed() ? closedNote() : ''}${html}</div>${bar}`;
    dock(r);
    // Motion only marks a change: a new screen enters, and the cart badge
    // bumps when an item is added. Re-renders from a tap on the same screen
    // (quantity, size) do not replay the entrance.
    const routeKey = `${r.name}:${r.id || ''}`, n = count();
    if (routeKey !== lastRouteKey) app.classList.add('sf-enter');
    if (n > lastCount) app.classList.add('sf-grew');
    lastRouteKey = routeKey; lastCount = n;
    // Cards carry their order so each template staggers its own entrance.
    if (app.classList.contains('sf-enter')) app.querySelectorAll(CARD_SEL).forEach((el, i) => el.style.setProperty('--i', Math.min(i, 8)));
    app.querySelectorAll('img').forEach(im => { if (im.complete && im.naturalWidth) im.classList.add('is-in'); });
    if (r.name === 'checkout' && cart.size) {
      const f = document.getElementById('sfForm');
      for (const [k, v] of Object.entries(form)) if (f.elements[k]) f.elements[k].value = v;
      f.addEventListener('input', e => { form[e.target.name] = e.target.value; });
      if (err) { const bad = f.querySelector('[aria-invalid="true"]'); bad?.focus(); }
      mountPinMap();
      f.addEventListener('submit', submit);
    }
  }

  // Thumb-reach rule (Founder 2026-10-11): on every template the main action
  // of a product page, the cart and checkout sits in one dock pinned to the
  // bottom of the screen, never mid-page or at the top. Templates keep their
  // look; their own in-page buy button / quantity stepper is replaced here.
  function dock(r) {
    let inner = '';
    if (r.name === 'product' || app.querySelector('[data-act="addsel"]')) {
      const act = r.name === 'product' ? 'buy' : 'addsel';
      const p = r.name === 'product' ? product(r.id) : (list()[0] || store.products[0]);
      if (!p) return;
      app.querySelectorAll('[data-act="buy"],[data-act="addsel"]').forEach(b => b.remove());
      // A template may draw its own bottom bar (as its reference does); it is
      // still pinned to the bottom and keeps its in-page quantity control.
      if (r.name === 'product' && tpl.dock) {
        app.insertAdjacentHTML('beforeend', `<div class="sf-dock sf-dock-${tplKey}">${tpl.dock(ctx(), p)}</div>`);
        app.classList.add('has-dock');
        return;
      }
      app.querySelectorAll('.sf-stepper').forEach(st => { if (st.querySelector('[data-id="__sel"]')) st.remove(); });
      inner = `${ctx().stepper('__sel', 'sf-dock-step')}<button type="button" class="sf-dock-cta" data-act="${act}" ${isClosed() ? 'disabled' : ''}>${esc(t(isClosed() ? 'Closed' : 'Add to cart'))}<b>${money(p.price * ui.sel)}</b></button>`;
    } else if (r.name === 'cart' || r.name === 'checkout' || r.name === 'done') {
      const cta = app.querySelector('.sf-page .co-bar') || app.querySelector('.sf-page .sf-cta');
      if (!cta) return;
      const place = cta.id === 'sfPlace' ? cta : cta.querySelector('#sfPlace');
      if (place) place.setAttribute('form', 'sfForm');
      cta.remove();
      const d = document.createElement('div');
      d.className = 'sf-dock';
      d.append(cta);
      app.append(d);
      app.classList.add('has-dock');
      return;
    } else return;
    app.insertAdjacentHTML('beforeend', `<div class="sf-dock">${inner}</div>`);
    app.classList.add('has-dock');
  }

  // A server refusal comes back as {error} (so failed attempts stay counted
  // by the rate limit); transport problems throw.
  const errorText = m => (/rate limited/.test(m) ? t('Too many attempts. Please wait a minute and try again.')
    : /business not verified/.test(m) ? t('This store is not taking orders yet. Please check back soon.')
    : /store closed/.test(m) ? `${t('This store is closed right now.')} ${nextOpenText()}`.trim()
    : /outside coverage/.test(m) ? t('Sorry, {store} does not deliver to this location yet.', { store: store.name })
    : /delivery pin/.test(m) ? t('Please pin your delivery location on the map.')
    : /phone/.test(m) ? t('Enter a valid phone number, for example +60 12-345 6789.')
    : /available|product|item|quantity/i.test(m) ? t('Some items are no longer available. Please review your order.')
    : t('We could not place your order. Please try again.'));
  async function submit(e) {
    e.preventDefault();
    const name = (form.name || '').trim(), phone = (form.phone || '').trim(), address = (form.address || '').trim();
    if (!name || !phone || !address) return render(t('Please fill in your name, phone and delivery address.'));
    if (!pin && !EMBED) return render(t('Please pin your delivery location on the map.'));
    if (!phoneOk(phone)) return render(t('Enter a valid phone number, for example +60 12-345 6789.'));
    if (EMBED) return render(t('This is a preview. Orders are placed from your live storefront.'));
    if (isClosed()) return render(`${t('This store is closed right now.')} ${nextOpenText()}`.trim());
    const btn = document.getElementById('sfPlace');
    btn.disabled = true; btn.textContent = t('Placing order…');
    window.showPageLoader(t('Placing order…'));
    try {
      if (pin && store.delivery.coverage) {
        const cov = await rpc('storefront_coverage_check', { p_slug: store.slug, p_latitude: pin.lat, p_longitude: pin.lng }).catch(() => null);
        if (cov?.covered === false) return render(errorText('outside coverage'));
      }
      const res = await rpc('submit_storefront_order', {
        p_slug: store.slug, p_items: [...cart].map(([product_id, quantity]) => ({ product_id, quantity })),
        p_customer_name: name, p_customer_phone: phone, p_delivery_address: address,
        p_delivery_notes: [planText(plan()), (form.notes || '').trim()].filter(Boolean).join('\n'), p_idempotency_key: idempotencyKey,
        ...(plan().once ? {} : { p_plan: { weeks: Number(form.weeks), days: form.days, shift: form.shift || null } }),
        ...(pin ? { p_latitude: pin.lat, p_longitude: pin.lng, p_location_accuracy_m: pin.acc ?? null, p_location_source: pin.source } : {}),
      });
      if (res?.error) {
        if (/store closed/.test(res.error)) { store.openNow = false; store.nextOpen = res.next_open || store.nextOpen; }
        return render(errorText(res.error));
      }
      lastOrder = { ref: res.order_reference, token: res.tracking_token };
      try { localStorage.setItem('cefflo.sf.me', JSON.stringify({ name, phone, address })); } catch { /* private mode */ }
      cart.clear(); saveCart(); form = {}; pin = null; idempotencyKey = crypto.randomUUID();
      go('done');
    } catch (ex) {
      // The same key is kept, so a retry never creates a second order (a
      // replay returns the same order and its tracking link).
      render(ex.status ? errorText(String(ex.message || '')) : t('No connection. Please check your internet and try again.'));
    } finally { window.hidePageLoader(); }
  }

  // ------------------------------------------------------------- events
  app.addEventListener('click', e => {
    const t = e.target.closest('[data-act]');
    if (!t || t.tagName === 'INPUT') return;
    const act = t.dataset.act, id = t.dataset.id;
    const bump = (pid, d) => { const n = Math.max(0, Math.min(50, qty(pid) + d)); if (n) cart.set(pid, n); else cart.delete(pid); saveCart(); };
    switch (act) {
      case 'open': ui.sel = 1; ui.img = 0; ui.size = null; go(`p/${id}`); break;
      case 'size': ui.size = id; render(); break;
      case 'add': bump(id, 1); render(); break;
      case 'q+': bump(id, 1); render(); break;
      case 'q-': bump(id, -1); render(); break;
      case 'sel+': ui.sel = Math.min(50, ui.sel + 1); render(); break;
      case 'sel-': ui.sel = Math.max(1, ui.sel - 1); render(); break;
      case 'pay': form.pay = id; render(); break;
      case 'weeks': form.weeks = id === 'once' ? 'once' : Number(id); render(); break;
      case 'shift': form.shift = id; render(); break;
      case 'day': { const x = Number(id); form.days = form.days.includes(x) ? (form.days.length > 1 ? form.days.filter(y => y !== x) : form.days) : [...form.days, x].sort(); render(); break; }
      case 'buy': { const r = route(); if (r.name === 'product') { bump(r.id, ui.sel); ui.sel = 1; } go('checkout'); break; }
      case 'addsel': { const r = route(); if (r.name === 'product') { bump(r.id, ui.sel); ui.sel = 1; } render(); break; }
      case 'img': ui.img = Number(id) || 0; render(); break;
      case 'pin': locate(); break;
      case 'zoomin': zoom(1); break;
      case 'zoomout': zoom(-1); break;
      case 'cat': ui.cat = id || null; render(); break;
      case 'catpage': ui.cat = id || null; go(id ? `c/${id}` : 'all'); break;
      case 'tocart': go('cart'); break;
      case 'checkout': go('checkout'); break;
      case 'home': ui.cat = null; ui.intro = true; go(''); break;
      case 'intro': ui.intro = true; render(); break;
      case 'back': history.length > 1 ? history.back() : go(''); break;
      case 'clear': cart.clear(); saveCart(); render(); break;
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
        // Cloudflare Pages branch aliases (<branch>.<project>.pages.dev) are the same app.
        const ok = allowed.has(ev.origin) || [...allowed].some(a => {
          const h = new URL(a).hostname;
          return h.endsWith('.pages.dev') && new URL(ev.origin).hostname.endsWith('.' + h) && ev.origin.startsWith('https://');
        });
        if (!ok || ev.source !== window.parent) return;
        if (ev.data?.type === 'cefflo-storefront-preview' && ev.data.store) start(ev.data.store);
      });
      window.parent.postMessage({ type: 'cefflo-storefront-ready', frame: params.get('frame') || '' }, '*');
      return;
    }
    if (!/^[a-z0-9]([a-z0-9-]{1,28}[a-z0-9])$/.test(slug)) { state('This storefront does not exist.'); return; }
    let lastTpl = null; try { lastTpl = localStorage.getItem(`cefflo.sf.tpl.${slug}`); } catch { /* private mode */ }
    app.innerHTML = skeleton(params.get('template') || lastTpl || 'care');
    let raw;
    try { raw = await rpc('public_storefront', { p_slug: slug }); }
    catch (e) { state(/rate limited/.test(e.message) ? 'Too many visits right now. Please try again in a minute.' : 'We could not load this storefront. Please try again.'); return; }
    if (!raw) { state('This storefront is not available.'); return; }
    if (raw.slug !== slug) history.replaceState(null, '', `/${raw.slug}${location.search}${location.hash}`);
    try { localStorage.setItem(`cefflo.sf.tpl.${slug}`, raw.template_key || ''); } catch { /* private mode */ }
    start(raw);
  }
  window.CEFFLO_STORE_PREVIEW = start; // tests / tooling
  load();
})();
