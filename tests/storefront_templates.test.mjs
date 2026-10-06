// Storefront V1 templates (offline): every reference template renders the
// business's own data on every screen it defines, ships no sample content
// or reference brand names, and the public renderer and the Vendor App
// register exactly the same 18 template ids.
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import test from 'node:test';
import assert from 'node:assert/strict';

const src = readFileSync(new URL('../store/templates.js', import.meta.url), 'utf8');
const sandbox = { window: {} };
vm.runInNewContext(src, sandbox);
const T = sandbox.window.CEFFLO_TEMPLATES, ORDER = JSON.parse(JSON.stringify(sandbox.window.CEFFLO_TEMPLATE_ORDER));

const store = {
  name: 'Kedai Uji Seratus', area: 'Shah Alam', tagline: 'Tagline Uji', heroUrl: null, openNow: true,
  hours: [{ weekday: 1, is_open: true, opens_at: '09:00', closes_at: '18:00' }],
  categories: [{ id: 'c1', name: 'Kategori Satu' }, { id: 'c2', name: 'Kategori Dua' }],
  products: [
    { id: 'p1', categoryId: 'c1', name: 'Produk Alfa', description: 'Huraian alfa', price: 12.5, images: ['https://x/a.png', 'https://x/b.png'] },
    { id: 'p2', categoryId: 'c2', name: 'Produk Beta', description: '', price: 7, images: [] },
  ],
};
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = n => `RM ${Number(n || 0).toFixed(2)}`;
function ctx(s = store, cart = new Map()) {
  const ui = { cat: null, q: '', sel: 1, img: 0, intro: true };
  const list = (cat = ui.cat, q = ui.q) => s.products.filter(p => (!cat || p.categoryId === cat) && (!q || p.name.toLowerCase().includes(q)));
  const img = (p, cls = '', i = 0) => (p?.images?.[i] ? `<img class="${cls}" src="${esc(p.images[i])}" alt="${esc(p.name)}">` : `<div class="sf-ph ${cls}"></div>`);
  return {
    s, ui, esc, money, moneyShort: money, icon: n => `<svg data-i="${n}"></svg>`, img, list,
    qty: id => cart.get(id) || 0, count: () => [...cart.values()].reduce((a, b) => a + b, 0), total: () => 0,
    product: id => s.products.find(p => p.id === id), catName: id => s.categories.find(c => c.id === id)?.name || '',
    initials: x => (x || '').slice(0, 2).toUpperCase(), hoursText: () => 'Today 09:00–18:00', openLabel: () => 'Open now', greeting: () => 'Good morning', DAYS: [],
    hero: (p, cls) => img(p, cls), headline: fb => s.tagline || fb,
    open: id => `data-act="open" data-id="${id}"`, add: id => `data-act="add" data-id="${id}"`, cat: id => `data-act="cat" data-id="${id || ''}"`, catPage: id => `data-act="catpage" data-id="${id || ''}"`,
    empty: m => `<div class="sf-empty">${esc(m || 'No products yet.')}</div>`, searchInput: ph => `<input data-act="search" placeholder="${esc(ph || '')}">`,
    stepper: id => `<div class="sf-stepper" data-id="${id}"></div>`, buy: (l, c) => `<button class="${c}" data-act="buy">${l}</button>`,
    toCart: (c, i) => `<button class="${c}" data-act="tocart">${i || ''}</button>`, home: () => 'data-act="home"', selImg: i => `data-act="img" data-id="${i}"`,
  };
}
const screens = (k, c) => {
  const t = T[k], out = { home: t.home(c), product: t.product(c, store.products[0]), product2: t.product(c, store.products[1]) };
  if (t.category) out.category = t.category.call(t, c, 'c1');
  if (t.all) out.all = t.all.call(t, c, null);
  if (t.intro) out.intro = t.intro(c);
  return out;
};
// Words that appear in the Founder's reference screenshots: brand names and
// sample copy must never ship inside a template.
const FORBIDDEN = /xefag|nike|psg|barça|barca|syntha|endorush|bsn\b|jmd[af]|northen|arobix|pashaya|mediplus|panadol|strepsils|cetaphil|scott|ensure|omron|azuki|closesea|harbani|cappuccino|matcha latte|iced matcha|clearance sales|powerful boost|winter essentials|run better|buy 1 get 3|spotless attire|jenny wilson|mie ayam|delicious seafood|fried prawns|face recovery|ultra run pro|velocity boost|everyday healthcare|los vegas|new york|\$\s?\d|£|₽|rp\s?\d/i;

test('the public renderer defines 18 templates in gallery order, each with home + product', () => {
  assert.equal(ORDER.length, 18);
  assert.deepEqual([...ORDER].sort(), JSON.parse(JSON.stringify(Object.keys(T))).sort());
  for (const k of ORDER) {
    assert.equal(typeof T[k].home, 'function', k);
    assert.equal(typeof T[k].product, 'function', k);
    assert.ok(/^#[0-9a-f]{6}$/i.test(T[k].defaults.accent), `${k} accent`);
  }
});

test('the Vendor App registry lists exactly the same template ids, in the same order', () => {
  const dart = readFileSync(new URL('../apps/vendor_mobile/lib/ui/screens/storefront/templates/web/web_templates.dart', import.meta.url), 'utf8');
  const ids = [...dart.matchAll(/^\s*_t\(\s*'([a-z]+)'/gm)].map(m => m[1]);
  assert.deepEqual(ids, ORDER);
});

test('Vendor Web lists exactly the same template ids, in the same order (no retired templates)', () => {
  const web = readFileSync(new URL('../apps/vendor_web/js/pages/storefront.js', import.meta.url), 'utf8');
  const block = web.slice(web.indexOf('const TEMPLATES = ['), web.indexOf('];', web.indexOf('const TEMPLATES = [')));
  assert.deepEqual([...block.matchAll(/id: '([a-z]+)'/g)].map(m => m[1]), ORDER);
  assert.ok(!/arena|stride|ritual|feast|'market'/.test(web), 'retired template keys');
});

test('every template renders the business data on every screen and nothing else', () => {
  for (const k of ORDER) {
    const out = screens(k, ctx());
    const all = Object.values(out).join('\n');
    assert.ok(out.product.includes('Produk Alfa') && /12\.50/.test(out.product), `${k} product shows name + price`);
    assert.ok(out.product2.includes('Produk Beta'), `${k} product without photos renders`);
    assert.ok(/Produk Alfa|Kedai Uji Seratus|Tagline Uji/.test(out.home), `${k} home shows business data`);
    assert.ok(/data-act="(buy|addsel)"/.test(out.product), `${k} product has a purchase action`);
    assert.ok(!FORBIDDEN.test(all.replace(/<[^>]+>/g, ' ')), `${k} contains reference sample content: ${all.replace(/<[^>]+>/g, ' ').match(FORBIDDEN)}`);
  }
});

test('an empty catalogue renders an honest empty state (no crash)', () => {
  const empty = { ...store, categories: [], products: [] };
  for (const k of ORDER) {
    const c = ctx(empty);
    const html = T[k].home(c);
    assert.equal(typeof html, 'string', k);
    assert.ok(/sf-empty|No products/.test(html) || k === 'capsule' || k === 'collector' || k === 'combo', `${k} empty state`);
  }
});

test('customer text is escaped (no HTML injection from product names)', () => {
  const evil = { ...store, products: [{ ...store.products[0], name: '<img src=x onerror=alert(1)>' }] };
  for (const k of ORDER) {
    const out = screens(k, ctx(evil));
    assert.ok(!Object.values(out).join('').includes('<img src=x onerror'), k);
  }
});
