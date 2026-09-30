(function () {
  // Cefflo Storefront V1 (staging proof). Anonymous customers call exactly
  // two SECURITY DEFINER functions: public_storefront and
  // submit_storefront_order. Prices shown here are display only; the server
  // snapshots the real prices from the business's Products.
  const cfg = window.CEFFLO_CONFIG;
  const $ = id => document.getElementById(id);
  const slug = decodeURIComponent(location.pathname.replace(/^\/+|\/+$/g, '').split('/')[0] || '').toLowerCase();
  const cart = new Map(); // product_id -> quantity
  let products = [];
  let idempotencyKey = crypto.randomUUID();

  async function rpc(name, body) {
    const res = await fetch(`${cfg.supabaseUrl}/rest/v1/rpc/${name}`, {
      method: 'POST',
      headers: { apikey: cfg.supabaseAnonKey, Authorization: `Bearer ${cfg.supabaseAnonKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const text = await res.text();
    const data = text ? JSON.parse(text) : null;
    if (!res.ok) throw new Error(data?.message || `Request failed (${res.status})`);
    return data;
  }

  const money = n => `RM ${Number(n || 0).toFixed(2)}`;
  const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  function el(tag, attrs = {}, ...kids) {
    const e = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs)) {
      if (k === 'class') e.className = v; else if (k.startsWith('on')) e.addEventListener(k.slice(2), v); else e.setAttribute(k, v);
    }
    for (const k of kids) e.append(k);
    return e;
  }

  function renderBar() {
    const count = [...cart.values()].reduce((a, b) => a + b, 0);
    $('bar').hidden = count === 0 || !$('done').hidden;
    $('barCount').textContent = `${count} item${count === 1 ? '' : 's'}`;
  }

  function renderCatalogue() {
    const root = $('catalogue');
    root.textContent = '';
    if (!products.length) { root.append(el('p', { class: 'state' }, 'No products yet.')); return; }
    for (const p of products) {
      const qty = cart.get(p.id) || 0;
      const img = p.images && p.images[0]
        ? el('img', { src: `${cfg.supabaseUrl}${p.images[0]}`, alt: '' })
        : el('div', { class: 'ph' });
      const count = el('span', {}, String(qty));
      const change = d => () => {
        const next = Math.max(0, Math.min(50, (cart.get(p.id) || 0) + d));
        if (next) cart.set(p.id, next); else cart.delete(p.id);
        renderCatalogue(); renderBar();
      };
      root.append(el('div', { class: 'product' }, img,
        el('div', { class: 'info' },
          el('b', {}, p.name),
          el('small', {}, `${money(p.display_price)}${p.description ? ' · ' + p.description : ''}`),
          el('div', { class: 'qty' },
            el('button', { type: 'button', 'aria-label': 'Remove one', onclick: change(-1) }, '−'), count,
            el('button', { type: 'button', 'aria-label': 'Add one', onclick: change(1) }, '+')))));
    }
  }

  function renderCheckout() {
    const lines = $('cartLines');
    lines.textContent = '';
    let total = 0;
    for (const [id, qty] of cart) {
      const p = products.find(x => x.id === id);
      if (!p) continue;
      total += p.display_price * qty;
      lines.append(el('li', {}, el('span', {}, `${qty} × ${p.name}`), el('span', {}, money(p.display_price * qty))));
    }
    $('cartTotal').textContent = money(total);
  }

  $('toCheckout').addEventListener('click', () => {
    renderCheckout();
    $('checkout').hidden = false;
    $('checkout').scrollIntoView({ behavior: 'smooth' });
  });

  $('placeOrder').addEventListener('click', async () => {
    const err = $('formError');
    err.hidden = true;
    const name = $('cName').value.trim(), phone = $('cPhone').value.trim(), address = $('cAddress').value.trim();
    if (!name || !phone || !address || !cart.size) {
      err.textContent = 'Please add items and fill in your name, phone and address.';
      err.hidden = false;
      return;
    }
    const btn = $('placeOrder');
    btn.disabled = true; btn.textContent = 'Placing order…';
    try {
      const res = await rpc('submit_storefront_order', {
        p_slug: slug,
        p_items: [...cart].map(([product_id, quantity]) => ({ product_id, quantity })),
        p_customer_name: name,
        p_customer_phone: phone,
        p_delivery_address: address,
        p_delivery_notes: $('cNotes').value.trim(),
        p_idempotency_key: idempotencyKey,
      });
      $('orderRef').textContent = res.order_reference;
      $('checkout').hidden = true; $('catalogue').hidden = true;
      $('done').hidden = false;
      cart.clear(); renderBar();
      idempotencyKey = crypto.randomUUID();
    } catch (e) {
      // The same key is kept, so retrying never creates a second order.
      err.textContent = /rate limited/.test(e.message) ? 'Too many attempts. Please wait a minute and try again.' : e.message;
      err.hidden = false;
    } finally {
      btn.disabled = false; btn.textContent = 'Place order';
    }
  });

  async function load() {
    if (!/^[a-z0-9]([a-z0-9-]{1,28}[a-z0-9])$/.test(slug)) { $('state').textContent = 'This storefront does not exist.'; return; }
    let store;
    try { store = await rpc('public_storefront', { p_slug: slug }); }
    catch (_) { $('state').textContent = 'We could not load this storefront. Please try again.'; return; }
    if (!store) { $('state').textContent = 'This storefront is not available.'; return; }
    // An old link lands on the canonical address.
    if (store.slug !== slug) history.replaceState(null, '', `/${store.slug}`);
    const theme = store.theme || {};
    if (theme.accent) document.documentElement.style.setProperty('--accent', theme.accent);
    if (theme.style === 'gradient') $('top').classList.add('gradient');
    document.title = store.business.name;
    $('bizName').textContent = store.business.name;
    const meta = [];
    if (store.business.area) meta.push(store.business.area);
    if (store.open_now === true) meta.push('Open now');
    if (store.open_now === false) meta.push('Closed now');
    if (theme.tagline) meta.unshift(theme.tagline);
    $('bizMeta').textContent = meta.join(' · ');
    if (Array.isArray(store.hours)) {
      $('bizMeta').title = store.hours.map(h => `${DAYS[h.weekday - 1]} ${h.is_open ? `${h.opens_at}–${h.closes_at}` : 'closed'}`).join('\n');
    }
    products = store.products || [];
    $('state').hidden = true;
    $('catalogue').hidden = false;
    renderCatalogue(); renderBar();
  }
  load();
})();
