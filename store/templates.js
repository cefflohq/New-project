// Cefflo Storefront V1 templates. One template per Founder-supplied UI
// reference (2026-10-06), reproduced 1:1 in structure, hierarchy and
// treatment. Every word, price and picture comes from the business's own
// storefront data; reference elements with no Cefflo data behind them
// (ratings, sizes/variants, stock counts, discounts, delivery ETA) are left
// out rather than faked. Each template: home(c) and product(c, p); some add
// category(c, id) / intro(c) / bar(c) where the reference shows them.
(function () {
  'use strict';
  const T = {};
  // Customer-facing template chrome follows the shopper's language (store.js
  // CEFFLO_I18N); vendor data passes through untouched.
  const L = s => (typeof window !== 'undefined' && window.CEFFLO_I18N ? window.CEFFLO_I18N(s) : s);
  const first = c => c.list(null, '')[0];
  const chips = (c, cls = 'chip', allLabel = 'All', withAll = true) =>
    (withAll ? `<button type="button" class="${cls}${!c.ui.cat ? ' on' : ''}" ${c.cat(null)}>${c.esc(L(allLabel))}</button>` : '') +
    c.s.categories.map(k => `<button type="button" class="${cls}${c.ui.cat === k.id ? ' on' : ''}" ${c.cat(k.id)}>${c.esc(k.name)}</button>`).join('');
  const dots = (n, at = 0, cls = 'dots') => `<div class="${cls}">${Array.from({ length: Math.max(1, Math.min(n, 5)) }, (_, i) => `<i class="${i === at ? 'on' : ''}"></i>`).join('')}</div>`;
  const brand = c => c.esc(c.s.name);
  const desc = (c, p, fb = '') => c.esc(p.description || fb);
  const gallery = (c, p, cls) => p.images.length > 1
    ? `<div class="${cls}">${p.images.map((_, i) => `<button type="button" class="${i === c.ui.img ? 'on' : ''}" ${c.selImg(i)}>${c.img(p, '', i)}</button>`).join('')}</div>` : '';

  // ======================================================== 1. CAPSULE
  // Bold colour product pages (crimson / yellow) and a centred steel-blue
  // brand home with two products crossing.
  T.capsule = {
    name: 'Capsule', defaults: { accent: '#C8234F', accent2: '#F7C531', bg: '#5B8DB9', bar: '#5B8DB9' },
    head(c, back) {
      return `<header class="cap-top">${back ? `<button type="button" class="cap-back" data-act="back" aria-label="${L("Back")}">${c.icon('back')}</button>` : ''}<span class="cap-logo"></span><b>${brand(c)}</b><span class="cap-me">${c.esc(c.initials(c.s.name).slice(0, 1))}</span>${c.toCart('cap-icon', c.icon('basket'))}</header>`;
    },
    home(c) {
      const ps = c.list(null, '');
      return `<section class="cap-home">
        ${this.head(c, false)}
        <nav class="cap-pills"><a href="#/all" class="cap-pill">${L("Products")}</a><a href="#/all" class="cap-pill">${L("Contact")}</a></nav>
        <p class="cap-kicker">${c.esc([c.s.area, c.openLabel()].filter(Boolean).join(' · '))}</p>
        <h1 class="cap-title">${c.esc(c.headline(c.s.name))}</h1>
        <div class="cap-duo">${ps.slice(0, 2).map((p, i) => `<button type="button" class="cap-duo-${i}" ${c.open(p.id)}>${c.img(p)}</button>`).join('') || c.empty()}</div>
        <p class="cap-about">About ${brand(c)}</p>
        <p class="cap-sub">${c.esc(c.hoursText() || c.s.area || '')}</p>
      </section>`;
    },
    all(c) {
      const ps = c.list();
      return `<section class="cap-home cap-all">
        ${this.head(c, true)}
        <div class="cap-tabs">${c.s.categories.map(k => `<button type="button" class="${c.ui.cat === k.id ? 'on' : ''}" ${c.cat(k.id)}>${c.icon('sparkle')}${c.esc(k.name)}</button>`).join('')}</div>
        <div class="cap-list">${ps.map(p => `<button type="button" class="cap-row" ${c.open(p.id)}>${c.img(p)}<span><b>${c.esc(p.name)}</b><small>${c.money(p.price)}</small></span>${c.icon('chevronRight')}</button>`).join('') || c.empty()}</div>
      </section>`;
    },
    product(c, p) {
      const i = c.list(null, '').indexOf(p);
      return `<section class="cap-pdp ${i % 2 ? 'alt' : ''}">
        ${this.head(c, true)}
        <div class="cap-tabs">${c.s.categories.slice(0, 3).map(k => `<span class="${k.id === p.categoryId ? 'on' : ''}">${c.icon('sparkle')}${c.esc(k.name)}</span>`).join('')}</div>
        ${p.images.length > 1 ? `<div class="cap-steps">${p.images.slice(0, 3).map((_, n) => `<button type="button" class="${n === c.ui.img ? 'on' : ''}" ${c.selImg(n)}>${n + 1}</button>`).join('')}</div>` : ''}
        <div class="cap-shot">${c.img(p, '', c.ui.img)}</div>
        <div class="cap-card">
          <h1>${c.esc(p.name)}</h1>
          <p class="cap-mg">${c.esc(c.catName(p.categoryId))}</p>
          <div class="cap-buyrow"><b>${c.money(p.price)}</b>${c.stepper('__sel', 'cap-step')}</div>
          ${c.buy(`${c.icon('basket')} Buy Now`, 'cap-buy')}
        </div>
      </section>`;
    },
  };

  // ======================================================== 2. KIT
  // Sports-store: diagonal two-tone hero card, size-style pills row, and a
  // white home with round category badges, Popular rail and Categories.
  T.kit = {
    name: 'Kit', defaults: { accent: '#253D6B', accent2: '#E1293F', bg: '#EEF2F7', bar: '#ffffff' },
    home(c) {
      const ps = c.list(), all = c.list(null, '');
      return `<section class="kit-home">
        <header class="kit-head"><button type="button" class="kit-ic" data-act="catpage" data-id="" aria-label="${L("All products")}">${c.icon('grid')}</button><b class="kit-logo">${brand(c)}</b>${c.toCart('kit-ic kit-cart', c.icon('basket'))}</header>
        <div class="kit-badges"><button type="button" class="kit-filter${!c.ui.cat ? ' on' : ''}" ${c.cat(null)} aria-label="${L("All")}">${c.icon('filter')}</button>${c.s.categories.map(k => { const p = all.find(x => x.categoryId === k.id); return `<button type="button" class="kit-badge${c.ui.cat === k.id ? ' on' : ''}" ${c.cat(k.id)} title="${c.esc(k.name)}">${p ? c.img(p) : c.esc(c.initials(k.name))}</button>`; }).join('')}</div>
        <div class="kit-sec"><h2>${L("Popular")}</h2><span class="kit-bar"><i></i></span></div>
        <div class="kit-rail">${ps.map(p => `<article class="kit-card" ${c.open(p.id)}>${c.img(p)}<span class="kit-heart">${c.icon('heart')}</span><div class="kit-meta"><b>${c.esc(p.name)}</b><span>${c.moneyShort(p.price)}</span><button type="button" ${c.add(p.id)}>${L("Add")}</button></div></article>`).join('') || c.empty()}</div>
        <div class="kit-sec"><h2>${L("Categories")}</h2><span class="kit-bar"><i></i></span></div>
        <div class="kit-cats">${c.s.categories.map(k => { const p = all.find(x => x.categoryId === k.id); return `<button type="button" class="kit-cat" ${c.catPage(k.id)}>${c.img(p)}<span>${c.esc(k.name)}</span></button>`; }).join('') || all.slice(0, 6).map(p => `<button type="button" class="kit-cat" ${c.open(p.id)}>${c.img(p)}<span>${c.esc(p.name)}</span></button>`).join('')}</div>
      </section>`;
    },
    product(c, p) {
      const all = c.list(null, ''), i = all.indexOf(p);
      const prev = all[i - 1], next = all[i + 1];
      return `<section class="kit-pdp">
        <header class="kit-head light"><button type="button" class="kit-ic" data-act="back" aria-label="${L("Back")}">${c.icon('grid')}</button><b class="kit-logo">${brand(c)}</b>${c.toCart('kit-ic', c.icon('basket'))}</header>
        <div class="kit-stage">
          <div class="kit-frame"><span class="kit-under"></span>
            <span class="kit-tag">${c.esc(c.catName(p.categoryId) || c.s.name)}</span>
            <p class="kit-name">${c.esc(p.name)}</p>
            ${c.img(p, 'kit-shot', c.ui.img)}
            ${dots(p.images.length || 1, c.ui.img)}
          </div>
          ${prev ? `<button type="button" class="kit-side l" ${c.open(prev.id)}>${L("Prev")}</button>` : ''}
          ${next ? `<button type="button" class="kit-side r" ${c.open(next.id)}>${L("Next")}</button>` : ''}
        </div>
        <div class="kit-price"><span><sup>RM</sup>${c.esc(Number(p.price).toFixed(Number.isInteger(p.price) ? 0 : 2))}</span>${c.stepper('__sel', 'kit-step')}</div>
        <div class="kit-actions"><button type="button" class="kit-cartbtn" data-act="addsel" aria-label="${L("Add to cart")}">${c.icon('cart')}</button>${c.buy(L('BUY NOW'), 'kit-buy')}</div>
      </section>`;
    },
  };

  // ======================================================== 3. BREW
  // Coffee-house: avatar + location header, search, pill categories, a
  // carousel of brown cards with round floating photos; detail with a deep
  // brown top, round photo, chip price, About and quantity pill.
  T.brew = {
    name: 'Brew', defaults: { accent: '#4B2A15', accent2: '#D3A06A', bg: '#ffffff', bar: '#ffffff' },
    home(c) {
      const ps = c.list();
      return `<section class="brew-home">
        <header class="brew-head"><span class="brew-av">${c.esc(c.initials(c.s.name))}</span><span class="brew-loc">${c.icon('pin')}${c.esc(c.s.area || c.s.name)}</span>${c.toCart('brew-bell', c.icon('bell'))}</header>
        <label class="brew-search">${c.searchInput(L('Search'))}<span>${c.icon('search')}</span></label>
        <h2 class="brew-h">${L("Categories")}</h2>
        <div class="brew-chips"><button type="button" class="brew-chip${!c.ui.cat ? ' on' : ''}" ${c.cat(null)}>${c.icon('apps')}All</button>${c.s.categories.map(k => `<button type="button" class="brew-chip${c.ui.cat === k.id ? ' on' : ''}" ${c.cat(k.id)}>${c.icon('tag')}${c.esc(k.name)}</button>`).join('')}</div>
        <div class="brew-rail">${ps.map(p => `<article class="brew-card" ${c.open(p.id)}><div class="brew-cup">${c.img(p)}</div><div class="brew-body"><h3>${c.esc(p.name)}</h3><p>${c.esc(c.catName(p.categoryId))}</p><b>${c.money(p.price)}</b></div><button type="button" class="brew-plus" ${c.add(p.id)} aria-label="${L("Add")}">${c.icon('plus')}</button></article>`).join('') || c.empty()}</div>
        <nav class="brew-nav"><button type="button" class="on" data-act="home">${c.icon('home')}<i></i></button><button type="button" data-act="catpage" data-id="">${c.icon('heart')}</button><button type="button" data-act="tocart">${c.icon('apps')}</button></nav>
      </section>`;
    },
    product(c, p) {
      return `<section class="brew-pdp">
        <div class="brew-top"><button type="button" class="brew-o" data-act="back" aria-label="${L("Back")}">${c.icon('arrowLeft')}</button>${c.toCart('brew-o', c.icon('bag'))}<div class="brew-plate">${c.img(p, '', c.ui.img)}</div></div>
        <div class="brew-info">
          <span class="brew-cat">${c.esc(c.catName(p.categoryId) || c.s.name)}</span>
          <div class="brew-title"><h1>${c.esc(p.name)}</h1><span class="brew-pr">${c.money(p.price)}</span></div>
          ${gallery(c, p, 'brew-thumbs')}
          ${p.description ? `<h2>${L("About")}</h2><p class="brew-about">${desc(c, p)}</p>` : ''}
          <div class="brew-qty"><span>${L("Quantity")}</span>${c.stepper('__sel', 'brew-step')}</div>
          <div class="brew-actions">${c.toCart('brew-ring', c.icon('bag'))}${c.buy(L('Buy now'), 'brew-buy')}</div>
        </div>
      </section>`;
    },
  };

  // ======================================================== 4. CRIMSON
  // Single bold colour: red detail page with an uppercase kicker, the
  // product straddling a white sheet and a dark "Add to cart" pill; category
  // view with grey chips and tall red cards with a round down button.
  T.crimson = {
    name: 'Crimson', defaults: { accent: '#B82838', accent2: '#2A2A2A', bg: '#ffffff', bar: '#B82838' },
    home(c) {
      const ps = c.list();
      return `<section class="cri-home">
        <header class="cri-head"><button type="button" class="cri-ic" data-act="catpage" data-id="" aria-label="${L("All")}">${c.icon('menu2')}</button><b>${brand(c)}</b>${c.toCart('cri-ic', c.icon('bag'))}</header>
        <div class="cri-chips">${chips(c, 'cri-chip')}</div>
        <div class="cri-rail">${ps.map((p, i) => `<article class="cri-card ${i ? 'dim' : ''}" ${c.open(p.id)}><small>${c.esc(c.catName(p.categoryId) || 'Product')}</small><h3>${c.esc(p.name)}</h3>${c.img(p)}<span class="cri-down">${c.icon('arrowDown')}</span></article>`).join('') || c.empty()}</div>
        ${dots(ps.length || 1)}
      </section>`;
    },
    product(c, p) {
      return `<section class="cri-pdp">
        <div class="cri-red">
          <header class="cri-head on"><button type="button" class="cri-ic" data-act="back" aria-label="${L("Back")}">${c.icon('arrowLeft')}</button><span></span>${c.toCart('cri-ic w', c.icon('menu'))}</header>
          <small>${c.esc(c.catName(p.categoryId) || c.s.name)}</small>
          <h1>${c.esc(p.name)}</h1>
          <p class="cri-big">${c.money(p.price)}</p>
          <p class="cri-cap">${c.esc(c.s.name)}</p>
          <div class="cri-shot">${c.img(p, '', c.ui.img)}</div>
        </div>
        <div class="cri-sheet">
          <div class="cri-row"><h2>${c.esc(p.name)}</h2><button type="button" class="cri-add" data-act="buy">Add to cart ${c.icon('check')}</button></div>
          ${gallery(c, p, 'cri-thumbs')}
          ${p.description ? `<p class="cri-desc">${desc(c, p)}</p>` : ''}
        </div>
      </section>`;
    },
  };

  // ======================================================== 5. LIFT
  // Sneaker-drop: banner card, big text category tabs with item counts,
  // two-up grey cards with an arrow button, a floating bottom bar with a
  // black search circle; detail with a giant watermark and a Swipe button.
  T.lift = {
    name: 'Lift', defaults: { accent: '#111111', accent2: '#E5332A', bg: '#ffffff', bar: '#ffffff' },
    home(c) {
      const all = c.list(null, ''), ps = c.list(), f = all[0];
      const counts = id => all.filter(p => p.categoryId === id).length;
      return `<section class="lift-home">
        <header class="lift-head"><button type="button" class="lift-sq" data-act="catpage" data-id="" aria-label="${L("All")}">${c.icon('arrowLeft')}</button><b class="lift-logo">${brand(c)}</b>${c.toCart('lift-sq', c.icon('bag'))}</header>
        <h1 class="lift-h">${c.esc(c.headline(L('New Collection')))}</h1><p class="lift-sub">${c.esc(c.s.name)}</p>
        ${f ? `<div class="lift-banner"><div><b>${c.esc(f.name)}</b><small>${c.esc(c.catName(f.categoryId))}</small><button type="button" ${c.open(f.id)}>${L("Shop now")}</button></div>${c.hero(f, 'lift-bimg')}</div>${dots(3, 0, 'dots lift-dots')}` : ''}
        <div class="lift-tabs"><button type="button" class="${!c.ui.cat ? 'on' : ''}" ${c.cat(null)}><b>${L("All")}</b><small>${all.length} items</small></button>${c.s.categories.map(k => `<button type="button" class="${c.ui.cat === k.id ? 'on' : ''}" ${c.cat(k.id)}><b>${c.esc(k.name)}</b><small>${counts(k.id)} items</small></button>`).join('')}</div>
        <div class="lift-grid">${ps.map(p => `<article class="lift-card" ${c.open(p.id)}><b>${c.esc(p.name)}</b><span class="lift-sw"><i></i><i></i><i></i></span>${c.img(p)}<div class="lift-foot"><span><b>${c.moneyShort(p.price)}</b><small>${L("Price")}</small></span><button type="button" ${c.add(p.id)} aria-label="${L("Add")}">${c.icon('arrowRight')}</button></div></article>`).join('') || c.empty()}</div>
        <nav class="lift-nav"><button type="button" data-act="home">${c.icon('home')}</button><label class="lift-find">${c.icon('search')}${c.searchInput('', 'lift-q')}</label><button type="button" data-act="tocart">${c.icon('heart')}</button></nav>
      </section>`;
    },
    product(c, p) {
      return `<section class="lift-pdp">
        <header class="lift-head"><button type="button" class="lift-sq" data-act="back" aria-label="${L("Back")}">${c.icon('arrowLeft')}</button><span></span>${c.toCart('lift-sq', c.icon('bag'))}</header>
        <h1 class="lift-pt">${c.esc(p.name)}</h1>
        <div class="lift-stage"><span class="lift-mark">${c.esc(c.initials(c.s.name))}</span>${c.img(p, 'lift-shot', c.ui.img)}
          ${p.images.length > 1 ? `<div class="lift-col">${p.images.map((_, i) => `<button type="button" class="${i === c.ui.img ? 'on' : ''}" ${c.selImg(i)}>${i + 1}</button>`).join('')}</div>` : ''}
          <div class="lift-fav"><small>${L("Qty")}</small>${c.stepper('__sel', 'lift-step')}</div>
        </div>
        <div class="lift-price"><b>${c.moneyShort(p.price)}</b><small>${L("Price")}</small></div>
        ${p.description ? `<p class="lift-desc">${desc(c, p)}</p>` : ''}
        <button type="button" class="lift-swipe" data-act="buy"><span class="lift-knob">${c.icon('bag')}</span><span>${L("Swipe")}</span><span class="lift-chev">›››</span></button>
      </section>`;
    },
  };

  // ======================================================== 6. HARVEST
  // Fresh-food: menu + search header, big title + soft subtitle, black pill
  // categories, two-up cards with round dishes rising out of the card, a
  // wide feature card and a black pill bottom nav; detail with a big dish,
  // label, title, description, quantity and a round cart button.
  T.harvest = {
    name: 'Harvest', defaults: { accent: '#111111', accent2: '#3BAA4A', bg: '#ffffff', bar: '#ffffff' },
    home(c) {
      const ps = c.list(), [w, ...rest] = ps.length > 2 ? [ps[ps.length - 1], ...ps.slice(0, -1)] : [null, ...ps];
      return `<section class="hv-home">
        <header class="hv-head"><button type="button" class="hv-ic" data-act="catpage" data-id="" aria-label="${L("All")}">${c.icon('menu2')}</button><label class="hv-find">${c.searchInput('', 'hv-q')}${c.icon('search')}</label></header>
        <h1 class="hv-h">${brand(c)}</h1><p class="hv-sub">${c.esc(c.headline(c.s.area || ''))}</p>
        <div class="hv-chips">${chips(c, 'hv-chip', L('Popular'))}</div>
        <div class="hv-grid">${rest.map(p => `<article class="hv-card" ${c.open(p.id)}><div class="hv-dish">${c.img(p)}</div><h3>${c.esc(p.name)}</h3><p>${c.esc(p.description)}</p><b>${c.money(p.price)}</b><div class="hv-acts"><button type="button" class="hv-plus" ${c.add(p.id)} aria-label="${L("Add")}">${c.icon('plus')}</button><span class="hv-heart">${c.icon('heart')}</span></div></article>`).join('') || (w ? '' : c.empty())}</div>
        ${w ? `<article class="hv-wide" ${c.open(w.id)}><div><span class="hv-acts"><span class="hv-heart">${c.icon('heart')}</span><button type="button" class="hv-plus" ${c.add(w.id)} aria-label="${L("Add")}">${c.icon('plus')}</button></span><h3>${c.esc(w.name)}</h3><p>${c.esc(w.description)}</p><b>${c.money(w.price)}</b></div><div class="hv-dish">${c.img(w)}</div></article>` : ''}
        <nav class="hv-nav"><button type="button" class="on" data-act="home">${c.icon('home')}</button><button type="button" data-act="catpage" data-id="">${c.icon('heart')}</button><button type="button" data-act="tocart">${c.icon('bell')}</button><button type="button" data-act="tocart">${c.icon('user')}</button></nav>
      </section>`;
    },
    product(c, p) {
      return `<section class="hv-pdp">
        <header class="hv-head"><button type="button" class="hv-ic" data-act="back" aria-label="${L("Back")}">${c.icon('back')}</button></header>
        <div class="hv-big">${c.img(p, '', c.ui.img)}</div>
        ${dots(p.images.length || 1, c.ui.img)}
        <small class="hv-lab">${c.esc(c.catName(p.categoryId) || c.s.name)}</small>
        <h1 class="hv-title">${c.esc(p.name)}</h1>
        ${p.description ? `<p class="hv-desc">${desc(c, p)}</p>` : ''}
        ${gallery(c, p, 'hv-thumbs')}
        <div class="hv-row">${c.stepper('__sel', 'hv-step')}<b>${c.money(p.price)}</b></div>
        <button type="button" class="hv-fab" data-act="buy" aria-label="${L("Add to cart")}">${c.icon('cart')}</button>
      </section>`;
    },
  };

  // ======================================================== 7. BOTANIC
  // Natural care: avatar + bell + dots, a large quiet title with a round
  // search, outlined pills with a sage active pill, soft rounded product
  // panels with a big price and sage + button, glass nav; detail with a
  // full-bleed image and a frosted glass purchase card with a slide button.
  T.botanic = {
    name: 'Botanic', defaults: { accent: '#86A98F', accent2: '#2F4A3A', bg: '#E9F0F0', bar: '#E9F0F0' },
    home(c) {
      const ps = c.list();
      return `<section class="bo-home">
        <header class="bo-head"><span class="bo-av">${c.esc(c.initials(c.s.name))}</span><span class="bo-gap"></span>${c.toCart('bo-ring', c.icon('bag'))}<button type="button" class="bo-ring" data-act="catpage" data-id="" aria-label="${L("All")}">${c.icon('dots')}</button></header>
        <div class="bo-title"><h1>${c.esc(c.headline(c.s.name))}</h1><label class="bo-ring bo-search">${c.icon('search')}${c.searchInput('', 'bo-q')}</label></div>
        <div class="bo-chips">${chips(c, 'bo-chip', L('All'))}</div>
        <div class="bo-list">${ps.map(p => `<article class="bo-card" ${c.open(p.id)}><div class="bo-img">${c.img(p)}</div><h3>${c.esc(p.name)}</h3><p>${c.esc(c.catName(p.categoryId))}</p><div class="bo-pr"><b>${c.money(p.price)}</b><button type="button" class="bo-plus" ${c.add(p.id)} aria-label="${L("Add")}">${c.icon('plus')}</button></div></article>`).join('') || c.empty()}</div>
        <nav class="bo-nav"><button type="button" class="on" data-act="home">${c.icon('home')}</button><button type="button" data-act="tocart">${c.icon('cart')}</button><button type="button" data-act="catpage" data-id="">${c.icon('heart')}</button><button type="button" data-act="tocart">${c.icon('user')}</button></nav>
      </section>`;
    },
    product(c, p) {
      return `<section class="bo-pdp">
        <div class="bo-bg">${c.img(p, '', c.ui.img)}</div>
        <header class="bo-head over"><button type="button" class="bo-ring" data-act="back" aria-label="${L("Back")}">${c.icon('back')}</button><b>${L("Product detail")}</b><span class="bo-ring">${c.icon('heart')}</span></header>
        <div class="bo-glass">
          <h1>${c.esc(p.name)}</h1>
          ${p.description ? `<p>${desc(c, p)}</p>` : ''}
          ${c.stepper('__sel', 'bo-step')}
          <small>${L("Total Price")}</small>
          <b class="bo-total">${c.money(p.price * c.ui.sel)}</b>
          <button type="button" class="bo-slide" data-act="buy"><span>${c.icon('cart')}</span><em>${L("Add to cart &nbsp;\u203a\u203a")}</em><span class="r">${c.icon('cart')}</span></button>
        </div>
      </section>`;
    },
  };

  // ======================================================== 8. COMBO
  // Build-your-order: two thumbnails above a big centred title, small tab
  // pills with counts, a 3-column product grid with price pills (the picked
  // product lifts onto a white card) and a floating orange total button.
  T.combo = {
    name: 'Combo', defaults: { accent: '#F26B2C', accent2: '#8E9BF5', bg: '#F2F3F6', bar: '#F2F3F6' },
    home(c) {
      const ps = c.list(), all = c.list(null, '');
      const counts = id => all.filter(p => p.categoryId === id).reduce((s, p) => s + c.qty(p.id), 0);
      return `<section class="cb-home">
        <div class="cb-thumbs">${all.slice(0, 2).map(p => `<span>${c.img(p)}</span>`).join('')}</div>
        <h1 class="cb-h">${c.esc(c.headline(c.s.name))}</h1>
        <div class="cb-tabs">${c.s.categories.map(k => `<button type="button" class="${c.ui.cat === k.id ? 'on' : ''}" ${c.cat(k.id)}>${c.esc(k.name)} <i>${counts(k.id)}</i></button>`).join('') || `<button type="button" class="on">${L("All")} <i>${c.count()}</i></button>`}</div>
        <div class="cb-grid">${ps.map(p => `<article class="cb-item${c.qty(p.id) ? ' on' : ''}" ${c.add(p.id)}>${c.qty(p.id) ? `<span class="cb-tag">${c.icon('sparkle')} ${c.qty(p.id)}</span>` : ''}${c.img(p)}<p>${c.esc(p.name)}</p><span class="cb-pill">+ ${c.moneyShort(p.price)}</span></article>`).join('') || c.empty()}</div>
        <button type="button" class="cb-detail" data-act="${ps[0] ? 'open' : 'home'}" data-id="${c.esc(ps[0]?.id || '')}">${L("Product details")}</button>
      </section>`;
    },
    bar(c) { return `<button type="button" class="cb-total" data-act="tocart">${c.icon('plus')} ${c.money(c.total())}</button>`; },
    product(c, p) {
      return `<section class="cb-pdp">
        <header class="cb-top"><button type="button" class="cb-x" data-act="back" aria-label="${L("Back")}">${c.icon('arrowLeft')}</button></header>
        <div class="cb-hero">${c.img(p, '', c.ui.img)}</div>
        <h1 class="cb-h">${c.esc(p.name)}</h1>
        ${p.description ? `<p class="cb-desc">${desc(c, p)}</p>` : ''}
        <div class="cb-tabs">${c.stepper('__sel', 'cb-step')}</div>
        <button type="button" class="cb-total static" data-act="buy">${c.icon('plus')} ${c.money(p.price * c.ui.sel)}</button>
      </section>`;
    },
  };

  // ======================================================== 9. DISCOVER
  // Clean marketplace: "Discover" title with a bag badge, grey search,
  // green banner with a white pill, outlined category chips, two-up grey
  // tiles and a labelled bottom tab bar.
  T.discover = {
    name: 'Discover', defaults: { accent: '#22C55E', accent2: '#16A34A', bg: '#ffffff', bar: '#ffffff' },
    home(c) {
      const ps = c.list(), f = c.list(null, '')[0];
      return `<section class="dc-home">
        <header class="dc-head"><h1>${brand(c)}</h1>${c.toCart('dc-bag', c.icon('bag'))}</header>
        <label class="dc-search">${c.searchInput(L('Search'))}${c.icon('search')}</label>
        <div class="dc-banner"><div><h2>${c.esc(c.headline(L('Discover')))}</h2>${c.openLabel() ? `<span class="dc-pill">${c.icon('clock')} ${c.esc(c.openLabel())}</span>` : ''}</div>${c.hero(f, 'dc-bimg')}</div>
        <div class="dc-sec"><h3>${L("Categories")}</h3><a href="#/all">${L("See all")}</a></div>
        <div class="dc-chips">${chips(c, 'dc-chip')}</div>
        <div class="dc-grid">${ps.map(p => `<article class="dc-card" ${c.open(p.id)}><div class="dc-tile">${c.img(p)}</div><p>${c.esc(p.name)}</p><b>${c.money(p.price)}</b></article>`).join('') || c.empty()}</div>
        <nav class="dc-tabs"><button type="button" class="on" data-act="home">${c.icon('home')}<span>${L("Home")}</span></button><button type="button" data-act="catpage" data-id="">${c.icon('search')}<span>${L("Search")}</span></button><button type="button" data-act="tocart">${c.icon('heart')}<span>${L("Cart")}</span></button><button type="button" data-act="tocart">${c.icon('user')}<span>${L("Profile")}</span></button></nav>
      </section>`;
    },
    product(c, p) {
      return `<section class="dc-pdp">
        <header class="dc-head"><button type="button" class="dc-round" data-act="back" aria-label="${L("Back")}">${c.icon('back')}</button>${c.toCart('dc-bag', c.icon('bag'))}</header>
        <div class="dc-tile big">${c.img(p, '', c.ui.img)}</div>
        ${gallery(c, p, 'dc-thumbs')}
        <p class="dc-cat">${c.esc(c.catName(p.categoryId))}</p>
        <h1 class="dc-name">${c.esc(p.name)}</h1>
        <b class="dc-price">${c.money(p.price)}</b>
        ${p.description ? `<p class="dc-desc">${desc(c, p)}</p>` : ''}
        <div class="dc-buy">${c.stepper('__sel', 'dc-step')}${c.buy(L('Add to cart'), 'dc-cta')}</div>
      </section>`;
    },
  };

  // ======================================================== 10. ATELIER
  // Fashion house: hamburger, wordmark, round search; a promo banner with
  // a black "Shop now", square outlined category tiles, "New Arrival" two-up
  // photo cards with overlay text; detail with a peeking image carousel,
  // orange price, uppercase title, chips, Detail accordion and black CTA.
  T.atelier = {
    name: 'Atelier', defaults: { accent: '#111111', accent2: '#E35B2C', bg: '#ffffff', bar: '#ffffff' },
    home(c) {
      const ps = c.list(), f = c.list(null, '')[0];
      return `<section class="at-home">
        <header class="at-head"><button type="button" class="at-ring" data-act="catpage" data-id="" aria-label="${L("All")}">${c.icon('menu')}</button><b class="at-logo">${brand(c)}</b>${c.toCart('at-ring', c.icon('search'))}</header>
        <div class="at-banner"><div><h2>${c.esc(c.headline(c.s.name))}</h2><button type="button" ${f ? c.open(f.id) : ''}>${L("SHOP Now")}</button></div>${c.hero(f, 'at-bimg')}</div>
        <div class="at-cats">${c.s.categories.map(k => `<button type="button" class="${c.ui.cat === k.id ? 'on' : ''}" ${c.cat(k.id)}>${c.icon('tag')}<span>${c.esc(k.name)}</span></button>`).join('')}</div>
        <div class="at-sec"><h3>${L("New Arrival")}</h3><a href="#/all">${L("See all")}</a></div>
        <div class="at-grid">${ps.map((p, i) => `<article class="at-card" ${c.open(p.id)}>${c.img(p)}${i < 2 ? '<span class="at-badge">NEW</span>' : ''}<div class="at-over"><b>${c.money(p.price)}</b><span>${c.esc(p.name)}</span></div></article>`).join('') || c.empty()}</div>
        <nav class="at-nav"><button type="button" class="on" data-act="home">${c.icon('home')}</button><button type="button" data-act="catpage" data-id="">${c.icon('apps')}</button><button type="button" data-act="tocart">${c.icon('basket')}</button><button type="button" data-act="tocart">${c.icon('user')}</button></nav>
      </section>`;
    },
    product(c, p) {
      const n = p.images.length;
      return `<section class="at-pdp">
        <header class="at-head"><button type="button" class="at-ring" data-act="back" aria-label="${L("Back")}">${c.icon('back')}</button><b class="at-ptitle">${c.esc(p.name)}</b><span class="at-ring">${c.icon('heart')}</span></header>
        <div class="at-car">${n > 1 ? `<button type="button" class="at-peek" ${c.selImg((c.ui.img + n - 1) % n)}>${c.img(p, '', (c.ui.img + n - 1) % n)}</button>` : '<span class="at-peek ghost"></span>'}<div class="at-main">${c.img(p, '', c.ui.img)}</div>${n > 1 ? `<button type="button" class="at-peek" ${c.selImg((c.ui.img + 1) % n)}>${c.img(p, '', (c.ui.img + 1) % n)}</button>` : '<span class="at-peek ghost"></span>'}</div>
        <b class="at-price">${c.money(p.price)}</b>
        <h1 class="at-name">${c.esc(p.name)}</h1>
        <div class="at-chips"><span class="on">${L("NEW")}</span>${c.catName(p.categoryId) ? `<span>${c.esc(c.catName(p.categoryId))}</span>` : ''}<span>${brand(c)}</span></div>
        ${p.description ? `<details class="at-acc" open><summary>DETAIL ${c.icon('chevronDown')}</summary><p>${desc(c, p)}</p></details>` : ''}
        <div class="at-qty">${c.stepper('__sel', 'at-step')}</div>
        ${c.buy(`${c.icon('bag')} ADD TO SHOPPING BAG`, 'at-cta')}
      </section>`;
    },
  };

  // ======================================================== 11. POUR
  // Café single-item focus: a full-height photo fading into soft grey, the
  // name and price centred, a segmented control, a black pill CTA and a
  // "You may also like" rail. Home shows the featured item this way.
  T.pour = {
    name: 'Pour', defaults: { accent: '#111111', accent2: '#E6E7E9', bg: '#EDEEEF', bar: '#EDEEEF' },
    home(c) { const f = c.list()[0] || first(c); return f ? this.product(c, f, true) : `<section class="po-pdp">${c.empty()}</section>`; },
    product(c, p, home) {
      const others = c.list(null, '').filter(x => x.id !== p.id);
      return `<section class="po-pdp">
        <div class="po-photo">${c.img(p, '', c.ui.img)}</div>
        <header class="po-head">${home ? `<span class="po-brand">${brand(c)}</span>` : `<button type="button" class="po-ic" data-act="back" aria-label="${L("Back")}">${c.icon('back')}</button>`}${c.toCart('po-ic', c.icon('heart'))}</header>
        <div class="po-body">
          <h1>${c.esc(p.name)}</h1>
          <p class="po-price">${c.money(p.price)}</p>
          <div class="po-row"><div class="po-seg">${c.stepper('__sel', 'po-step')}</div><button type="button" class="po-cta" data-act="${home ? 'addsel' : 'buy'}">${L("Add to Order")}</button></div>
          ${home && c.count() ? `<button type="button" class="po-view" data-act="tocart">View order · ${c.count()} · ${c.money(c.total())}</button>` : ''}
          ${others.length ? `<h2>${L("You may also like")}</h2><div class="po-rail">${others.map(o => `<article class="po-card" ${c.open(o.id)}>${c.img(o)}<b>${c.esc(o.name)}</b><span>${c.money(o.price)}</span></article>`).join('')}</div>` : ''}
        </div>
      </section>`;
    },
    bar: false,
  };

  // ======================================================== 12. TAILOR
  // Menswear: two-line serif wordmark, dark banner card with thumbnails and
  // "Explore Collection", "New Popular Items", black active chips and grey
  // two-up cards with hearts; detail with thumbnail column, quantity +
  // total price and a black "Add to Bag".
  T.tailor = {
    name: 'Tailor', defaults: { accent: '#111111', accent2: '#F59E6B', bg: '#ffffff', bar: '#ffffff' },
    home(c) {
      const ps = c.list(), all = c.list(null, ''), f = all[0];
      return `<section class="tl-home">
        <header class="tl-head"><span class="tl-logo"><b>${brand(c)}</b><small>${c.esc(c.s.area || 'Store')}</small></span>${c.toCart('tl-bag', c.icon('bag'))}</header>
        <div class="tl-banner"><div><h2>${c.esc(c.headline(c.s.name))}</h2><p>${c.esc(c.s.categories.map(k => k.name).slice(0, 3).join(' & '))}</p><div class="tl-mini">${all.slice(0, 3).map(p => `<span>${c.img(p)}</span>`).join('')}</div><button type="button" data-act="catpage" data-id="">${L("Explore Collection \u203a\u203a")}</button></div>${c.hero(f, 'tl-bimg')}</div>
        ${dots(3, 0, 'dots tl-dots')}
        <div class="tl-sec"><h3>${L("New Popular Items")}</h3><a href="#/all">${L("See All \u203a")}</a></div>
        <div class="tl-grid">${all.slice(0, 2).map(p => card(c, p)).join('')}</div>
        <div class="tl-chips">${chips(c, 'tl-chip', 'New & Featured')}</div>
        <div class="tl-grid">${ps.map(p => card(c, p)).join('') || c.empty()}</div>
        <nav class="tl-nav"><button type="button" class="on" data-act="home">${c.icon('home')}</button><button type="button" data-act="catpage" data-id="">${c.icon('search')}</button><button type="button" data-act="tocart">${c.icon('heart')}</button><button type="button" data-act="tocart">${c.icon('user')}</button></nav>
      </section>`;
      function card(c, p) { return `<article class="tl-card" ${c.open(p.id)}><span class="tl-heart">${c.icon('heart')}</span>${c.img(p)}<p>${c.esc(p.name)}</p></article>`; }
    },
    product(c, p) {
      return `<section class="tl-pdp">
        <div class="tl-stage">${c.img(p, 'tl-shot', c.ui.img)}
          <header class="tl-over"><button type="button" class="tl-blk" data-act="back" aria-label="${L("Back")}">${c.icon('back')}</button>${c.toCart('tl-blk', c.icon('share'))}</header>
          ${p.images.length > 1 ? `<div class="tl-col">${p.images.map((_, i) => `<button type="button" class="${i === c.ui.img ? 'on' : ''}" ${c.selImg(i)}>${c.img(p, '', i)}</button>`).join('')}</div>` : ''}
        </div>
        <div class="tl-sheet">
          <div class="tl-badges"><span class="o">${L("New")}</span>${c.catName(p.categoryId) ? `<span class="g">${c.esc(c.catName(p.categoryId))}</span>` : ''}</div>
          <div class="tl-nm"><h1>${c.esc(p.name)}</h1>${c.icon('heart')}</div>
          <p class="tl-sub">${c.esc(p.description || c.s.name)}</p>
          <div class="tl-qtyrow"><div><small>${L("Qty")}</small>${c.stepper('__sel', 'tl-step')}</div><div class="tl-tot"><small>${L("Total price")}</small><b>${c.money(p.price * c.ui.sel)}</b></div></div>
          ${c.buy(`${c.icon('bag')} Add to Bag`, 'tl-cta')}
        </div>
      </section>`;
    },
  };

  // ======================================================== 13. SPRINT
  // Performance retail: orange banner with headline + "Shop Now", category
  // icon tiles with a purple active tile, "Top Picks" cards with a gradient
  // backdrop, heart and purple +, black nav bar with a raised purple circle;
  // detail with gradient stage, price card, description, thumbnail picker
  // and an outlined heart + purple "Add to Cart".
  T.sprint = {
    name: 'Sprint', defaults: { accent: '#6B3BE0', accent2: '#FF7A1A', bg: '#ffffff', bar: '#ffffff' },
    home(c) {
      const ps = c.list(), f = c.list(null, '')[0];
      return `<section class="sp-home">
        <header class="sp-head"><button type="button" class="sp-ic" data-act="catpage" data-id="" aria-label="${L("All")}">${c.icon('menu2')}</button><b>${brand(c)}</b>${c.toCart('sp-ic', c.icon('bag'))}</header>
        <div class="sp-banner"><div><h2>${c.esc(c.headline(c.s.name))}</h2><p>${c.esc(c.s.area || '')}</p><button type="button" ${f ? c.open(f.id) : ''}>${L("Shop Now")}</button></div>${c.hero(f, 'sp-bimg')}${dots(3, 0, 'dots sp-dots')}</div>
        <div class="sp-cats"><button type="button" class="${!c.ui.cat ? 'on' : ''}" ${c.cat(null)}>${c.icon('flame')}<span>${L("Popular")}</span></button>${c.s.categories.map(k => `<button type="button" class="${c.ui.cat === k.id ? 'on' : ''}" ${c.cat(k.id)}>${c.icon('tag')}<span>${c.esc(k.name)}</span></button>`).join('')}</div>
        <div class="sp-sec"><h3>${L("Top Picks")}</h3><a href="#/all">${L("View All")}</a></div>
        <div class="sp-rail">${ps.map(p => `<article class="sp-card" ${c.open(p.id)}><span class="sp-heart">${c.icon('heart')}</span>${c.img(p)}<h4>${c.esc(p.name)}</h4><p>${c.esc(c.catName(p.categoryId))}</p><b>${c.money(p.price)}</b><button type="button" class="sp-plus" ${c.add(p.id)} aria-label="${L("Add")}">${c.icon('plus')}</button></article>`).join('') || c.empty()}</div>
        <nav class="sp-nav"><button type="button" class="on" data-act="home">${c.icon('home')}</button><button type="button" data-act="catpage" data-id="">${c.icon('search')}</button><button type="button" class="sp-mid" data-act="tocart">${c.icon('bag')}</button><button type="button" data-act="tocart">${c.icon('heart')}</button><button type="button" data-act="tocart">${c.icon('user')}</button></nav>
      </section>`;
    },
    product(c, p) {
      return `<section class="sp-pdp">
        <div class="sp-stage">
          <header class="sp-head"><button type="button" class="sp-sq" data-act="back" aria-label="${L("Back")}">${c.icon('arrowLeft')}</button><span></span>${c.toCart('sp-sq', c.icon('share'))}</header>
          <h1>${c.esc(p.name)}</h1><p class="sp-cat">${c.esc(c.catName(p.categoryId) || c.s.name)}</p>
          ${c.img(p, 'sp-shot', c.ui.img)}
          <div class="sp-pc"><small>${L("Price")}</small><b>${c.money(p.price)}</b></div>
        </div>
        <div class="sp-info">
          ${p.description ? `<h2>${L("Description")}</h2><p>${desc(c, p)}</p>` : ''}
          ${p.images.length > 1 ? `<h2>${L("Select Image")}</h2><div class="sp-thumbs">${p.images.map((_, i) => `<button type="button" class="${i === c.ui.img ? 'on' : ''}" ${c.selImg(i)}>${c.img(p, '', i)}</button>`).join('')}</div>` : ''}
          <h2>${L("Quantity")}</h2>${c.stepper('__sel', 'sp-step')}
          <div class="sp-buy"><span class="sp-out">${c.icon('heart')}</span>${c.buy(`${c.icon('cart')} Add to Cart`, 'sp-cta')}</div>
        </div>
      </section>`;
    },
  };

  // ======================================================== 14. SPLASH
  // Sports shop: avatar "Welcome Back", search + filter, icon pills with a
  // blue active pill, blue promo banner with a yellow button, "Featured
  // Products" cards with a price tag and heart, a labelled tab bar; the
  // listing screen with icon category tiles, a two-up grid and a floating
  // blue "View your cart" bar.
  T.splash = {
    name: 'Splash', defaults: { accent: '#2563EB', accent2: '#FACC15', bg: '#F4F7FC', bar: '#F4F7FC' },
    home(c) {
      const all = c.list(null, ''), f = all[0];
      return `<section class="sl-home">
        <header class="sl-head"><span class="sl-av">${c.esc(c.initials(c.s.name))}</span><span class="sl-hi"><small>${L("Welcome")}</small><b>${brand(c)}</b></span>${c.toCart('sl-cart', c.icon('cart'))}</header>
        <div class="sl-srow"><label class="sl-search">${c.icon('search')}${c.searchInput(L("What's on your list?"))}</label><button type="button" class="sl-filter" data-act="catpage" data-id="" aria-label="${L("Browse")}">${c.icon('filter')}</button></div>
        <div class="sl-pills"><button type="button" class="${!c.ui.cat ? 'on' : ''}" ${c.cat(null)}>${c.icon('apps')} All Products</button>${c.s.categories.map(k => `<button type="button" class="${c.ui.cat === k.id ? 'on' : ''}" ${c.cat(k.id)}>${c.icon('tag')} ${c.esc(k.name)}</button>`).join('')}</div>
        <div class="sl-banner"><div><h2>${c.esc(c.headline(c.s.name))}</h2><p>${c.esc([c.s.area, c.openLabel()].filter(Boolean).join(' · '))}</p><button type="button" data-act="catpage" data-id="">${c.icon('bag')} Shop Now</button></div>${c.hero(f, 'sl-bimg')}${dots(4, 0, 'dots sl-dots')}</div>
        <h3 class="sl-h">${L("Featured Products")}</h3>
        <div class="sl-rail">${c.list().map(p => `<article class="sl-card" ${c.open(p.id)}><div class="sl-ph">${c.img(p)}<span class="sl-price">${c.money(p.price)}</span><span class="sl-heart">${c.icon('heart')}</span></div><small>${c.esc(c.catName(p.categoryId))}</small><b>${c.esc(p.name)}</b></article>`).join('') || c.empty()}</div>
        <nav class="sl-tabs"><button type="button" class="on" data-act="home">${c.icon('home')}<span>${L("Home")}</span></button><button type="button" data-act="tocart">${c.icon('box')}<span>${L("Orders")}</span></button><button type="button" data-act="catpage" data-id="">${c.icon('heart')}<span>${L("Browse")}</span></button><button type="button" data-act="tocart">${c.icon('user')}<span>${L("Profile")}</span></button></nav>
      </section>`;
    },
    category(c, id) {
      const ps = c.list(id === null ? c.ui.cat : id);
      return `<section class="sl-cat">
        <header class="sl-srow"><button type="button" class="sl-back" data-act="home" aria-label="${L("Back")}">${c.icon('arrowLeft')}</button><label class="sl-search">${c.icon('search')}${c.searchInput(c.catName(id) || 'Search')}</label></header>
        <div class="sl-tiles"><button type="button" class="${!id ? 'on' : ''}" ${c.catPage(null)}><span>${c.icon('apps')}</span>${L("All")}</button>${c.s.categories.map(k => { const f = c.list(k.id, '')[0]; return `<button type="button" class="${id === k.id ? 'on' : ''}" ${c.catPage(k.id)}><span>${f ? c.img(f) : c.icon('tag')}</span>${c.esc(k.name)}</button>`; }).join('')}</div>
        <div class="sl-grid">${ps.map(p => `<article class="sl-card" ${c.open(p.id)}><div class="sl-ph">${c.img(p)}<span class="sl-heart">${c.icon('heart')}</span><span class="sl-price">${c.money(p.price)}</span></div><b>${c.esc(p.name)}</b></article>`).join('') || c.empty()}</div>
      </section>`;
    },
    bar(c) { return `<button type="button" class="sl-bar" data-act="tocart"><span>${L("View your cart")}</span><i>${c.count()}x</i><b>${c.money(c.total())}</b></button>`; },
    product(c, p) {
      return `<section class="sl-pdp">
        <header class="sl-srow"><button type="button" class="sl-back" data-act="back" aria-label="${L("Back")}">${c.icon('arrowLeft')}</button><b class="sl-pt">${c.esc(c.catName(p.categoryId) || c.s.name)}</b>${c.toCart('sl-cart', c.icon('cart'))}</header>
        <div class="sl-big">${c.img(p, '', c.ui.img)}<span class="sl-price">${c.money(p.price)}</span></div>
        ${gallery(c, p, 'sl-thumbs')}
        <h1>${c.esc(p.name)}</h1>
        ${p.description ? `<p class="sl-desc">${desc(c, p)}</p>` : ''}
        <div class="sl-buyrow">${c.stepper('__sel', 'sl-step')}${c.buy(L('Add to cart'), 'sl-cta')}</div>
      </section>`;
    },
  };

  // ======================================================== 15. SERVICE
  // Services directory: blue rounded header with location + bell, search and
  // filter, "#SpecialForYou" photo offer cards, round category icons and
  // "Popular" cards; detail with photo + gallery strip, chip, name,
  // location, tabs, About, provider row and a blue full-width CTA.
  T.service = {
    name: 'Service', defaults: { accent: '#5B7CF6', accent2: '#FACC15', bg: '#ffffff', bar: '#5B7CF6' },
    home(c) {
      const ps = c.list(), all = c.list(null, '');
      return `<section class="sv-home">
        <header class="sv-top"><div class="sv-loc"><small>${L("Location")}</small><b>${c.icon('pin')} ${c.esc(c.s.area || c.s.name)} ${c.icon('chevronDown')}</b></div>${c.toCart('sv-bell', c.icon('bag'))}
          <div class="sv-srow"><label class="sv-search">${c.icon('search')}${c.searchInput(L('Search'))}</label><button type="button" class="sv-filter" data-act="catpage" data-id="" aria-label="${L("Browse")}">${c.icon('filter')}</button></div></header>
        <div class="sv-sec"><h3>#SpecialForYou</h3><a href="#/all">${L("See All")}</a></div>
        <div class="sv-offers">${all.slice(0, 4).map(p => `<article class="sv-offer" ${c.open(p.id)}>${c.img(p)}<div><span class="sv-lt">${c.esc(c.catName(p.categoryId) || c.s.name)}</span><h4>${c.esc(p.name)}</h4><p>${L("From")} <b>${c.money(p.price)}</b></p><button type="button" class="sv-claim" ${c.add(p.id)}>${L("Add")}</button></div></article>`).join('')}</div>
        ${dots(Math.min(all.length, 3) || 1, 0, 'dots sv-dots')}
        <div class="sv-sec"><h3>${L("Services")}</h3><a href="#/all">${L("See all")}</a></div>
        <div class="sv-cats">${c.s.categories.map(k => { const f = all.find(p => p.categoryId === k.id); return `<button type="button" class="${c.ui.cat === k.id ? 'on' : ''}" ${c.cat(k.id)}><span>${f ? c.img(f) : c.icon('tag')}</span>${c.esc(k.name)}</button>`; }).join('')}</div>
        <div class="sv-sec"><h3>${L("Popular")}</h3><a href="#/all">${L("See all")}</a></div>
        <div class="sv-pop">${ps.map(p => `<article class="sv-card" ${c.open(p.id)}>${c.img(p)}<span class="sv-bm">${c.icon('heart')}</span><b>${c.esc(p.name)}</b><small>${c.money(p.price)}</small></article>`).join('') || c.empty()}</div>
        <nav class="sv-nav"><button type="button" class="on" data-act="home">${c.icon('home')}<span>${L("Home")}</span></button><button type="button" data-act="catpage" data-id="">${c.icon('pin')}<span>${L("Explore")}</span></button><button type="button" data-act="tocart">${c.icon('bag')}<span>${L("Cart")}</span></button><button type="button" data-act="tocart">${c.icon('user')}<span>${L("Profile")}</span></button></nav>
      </section>`;
    },
    product(c, p) {
      return `<section class="sv-pdp">
        <div class="sv-photo">${c.img(p, '', c.ui.img)}
          <header class="sv-over"><button type="button" class="sv-wh" data-act="back" aria-label="${L("Back")}">${c.icon('arrowLeft')}</button><span class="sv-gap"></span>${c.toCart('sv-wh', c.icon('bag'))}</header>
          ${p.images.length > 1 ? `<div class="sv-strip">${p.images.slice(0, 5).map((_, i) => `<button type="button" class="${i === c.ui.img ? 'on' : ''}" ${c.selImg(i)}>${c.img(p, '', i)}</button>`).join('')}</div>` : ''}
        </div>
        <div class="sv-body">
          <span class="sv-chip">${c.esc(c.catName(p.categoryId) || c.s.name)}</span>
          <h1>${c.esc(p.name)}</h1>
          <p class="sv-addr">${c.esc([c.s.area, c.hoursText()].filter(Boolean).join(' · '))}</p>
          <div class="sv-tabs"><span class="on">${L("About")}</span><span>${c.money(p.price)}</span></div>
          ${p.description ? `<h2>${L("About")}</h2><p class="sv-about">${desc(c, p)}</p>` : ''}
          <h2>${L("Provided by")}</h2>
          <div class="sv-prov"><span class="sv-pav">${c.esc(c.initials(c.s.name))}</span><div><b>${brand(c)}</b><small>${c.esc(c.openLabel() || 'Service provider')}</small></div></div>
          <div class="sv-q">${c.stepper('__sel', 'sv-step')}</div>
          ${c.buy(L('Order Now'), 'sv-cta')}
        </div>
      </section>`;
    },
  };

  // ======================================================== 16. WARUNG
  // Local eatery: menu, pill search, bag with badge; a time-of-day greeting,
  // "Choose a category" with outlined green chips, list rows whose round
  // dish overhangs the card's left edge with a green order button; detail
  // with a big dish, payment detail rows and a Total + green CTA footer.
  T.warung = {
    name: 'Warung', defaults: { accent: '#169A49', accent2: '#E11D2E', bg: '#ffffff', bar: '#ffffff' },
    home(c) {
      const ps = c.list();
      return `<section class="wr-home">
        <header class="wr-head"><button type="button" class="wr-ic" data-act="catpage" data-id="" aria-label="${L("All")}">${c.icon('menu')}</button><label class="wr-search">${c.icon('search')}${c.searchInput(L('What would you like today?'))}</label>${c.toCart('wr-bag', c.icon('bag'))}</header>
        <h1 class="wr-hi">${c.greeting()}, ${brand(c)}</h1><p class="wr-sub">${c.esc(c.headline(c.openLabel() || ''))}</p>
        <div class="wr-sec"><h2>${L("Choose a category")}</h2>${c.icon('filter')}</div>
        <div class="wr-chips">${chips(c, 'wr-chip')}</div>
        <div class="wr-list">${ps.map(p => `<article class="wr-row" ${c.open(p.id)}><div class="wr-dish">${c.img(p)}</div><div class="wr-tx"><h3>${c.esc(p.name)}</h3><p>${c.esc(p.description)}</p><div class="wr-foot"><b>${c.money(p.price)}</b><button type="button" class="wr-btn" ${c.add(p.id)}>${c.qty(p.id) ? `${L('Added')} · ${c.qty(p.id)}` : L('Order')}</button></div></div></article>`).join('') || c.empty()}</div>
      </section>`;
    },
    product(c, p) {
      return `<section class="wr-pdp">
        <header class="wr-head"><button type="button" class="wr-ic" data-act="back" aria-label="${L("Back")}">${c.icon('arrowLeft')}</button><span></span>${c.toCart('wr-bag', c.icon('bag'))}</header>
        <div class="wr-big">${c.img(p, '', c.ui.img)}</div>
        ${gallery(c, p, 'wr-thumbs')}
        <h1 class="wr-name">${c.esc(p.name)}</h1>
        ${p.description ? `<p class="wr-desc">${desc(c, p)}</p>` : ''}
        <div class="wr-pay"><div class="wr-ph"><b>${L("Payment detail")}</b><span class="wr-tagl">${c.esc(c.s.name)}</span></div>
          <div class="wr-line"><span>${L("Price")}</span><span>${c.money(p.price)}</span></div>
          <div class="wr-line"><span>${L("Quantity")}</span>${c.stepper('__sel', 'wr-step')}</div></div>
        <footer class="wr-total"><div><small>${L("Total")}</small><b>${c.money(p.price * c.ui.sel)}</b></div>${c.buy(`${c.icon('shield')} Order`, 'wr-cta')}</footer>
      </section>`;
    },
  };

  // ======================================================== 17. COLLECTOR
  // Collection-led: a collage welcome with title, line and a black
  // "Continue"; home with logo + avatar, search, black active tab pills and
  // stacked collection cards; a collection page with a collage banner,
  // avatar, stats, tabs and a two-up item grid with black + buttons.
  T.collector = {
    name: 'Collector', defaults: { accent: '#111111', accent2: '#F2F2F4', bg: '#F4F4F6', bar: '#F4F4F6' },
    intro(c) {
      const all = c.list(null, '');
      return `<section class="co-intro">
        <div class="co-collage">${all.slice(0, 6).map(p => `<span>${c.img(p)}</span>`).join('') || '<span class="sf-ph"></span>'}</div>
        <div class="co-sheet"><span class="co-grip"></span><h1>${c.esc(c.headline(c.s.name))}</h1><p>${c.esc([c.s.name, c.s.area].filter(Boolean).join(' · '))}</p><button type="button" class="co-go" data-act="intro">${L("Continue")}</button></div>
      </section>`;
    },
    home(c) {
      const all = c.list(null, '');
      const groups = (c.s.categories.length ? c.s.categories : [{ id: null, name: c.s.name }]).filter(k => !c.ui.cat || k.id === c.ui.cat);
      return `<section class="co-home">
        <header class="co-head"><span class="co-logo">${c.icon('apps')}</span><b>${brand(c)}</b><span class="co-av">${c.esc(c.initials(c.s.name))}</span></header>
        <label class="co-search">${c.icon('search')}${c.searchInput('Search products…')}</label>
        <div class="co-chips">${chips(c, 'co-chip', 'Recent')}</div>
        <div class="co-sec"><h3>${L("Collections")}</h3><a href="#/all">${L("View all")}</a></div>
        ${groups.map(k => { const ps = all.filter(p => !k.id || p.categoryId === k.id); const f = ps[0]; return f ? `<article class="co-stack" ${c.catPage(k.id)}><span class="co-back2"></span><span class="co-back1"></span><div class="co-front">${c.img(f)}<span class="co-n">${ps.length}</span></div><div class="co-meta"><b>${c.esc(k.name)}</b><small>From ${c.money(Math.min(...ps.map(p => p.price)))}</small></div><div class="co-btns"><span>${c.icon('info')} ${ps.length} items</span><span class="dark">${c.icon('apps')} Collection</span></div></article>` : ''; }).join('') || c.empty()}
      </section>`;
    },
    category(c, id) {
      const ps = c.list(id || null), k = c.s.categories.find(x => x.id === id);
      const prices = ps.map(p => p.price);
      return `<section class="co-col">
        <div class="co-banner">${ps.slice(0, 6).map(p => `<span>${c.img(p)}</span>`).join('') || '<span class="sf-ph"></span>'}<header class="co-over"><button type="button" class="co-rd" data-act="home" aria-label="${L("Back")}">${c.icon('back')}</button>${c.toCart('co-rd', c.icon('bag'))}</header></div>
        <div class="co-prof"><span class="co-pav">${c.esc(c.initials(k?.name || c.s.name))}</span><h1>${c.esc(k?.name || c.s.name)} ${c.icon('check', 'co-ver')}</h1><p>${c.esc(c.headline(c.s.name))}</p>
          <div class="co-stats"><div><b>${ps.length}</b><small>${L("Items")}</small></div><div><b>${prices.length ? c.money(Math.min(...prices)) : '—'}</b><small>${L("From")}</small></div><div><b>${prices.length ? c.money(Math.max(...prices)) : '—'}</b><small>${L("Up to")}</small></div><div><b>${c.qty ? c.count() : 0}</b><small>${L("In cart")}</small></div></div></div>
        <div class="co-chips"><span class="co-chip on">${L("Items")}</span><span class="co-chip">${c.esc(c.s.name)}</span></div>
        <div class="co-grid">${ps.map(p => `<article class="co-item" ${c.open(p.id)}>${c.img(p)}<b>${c.esc(p.name)}</b><small>${c.money(p.price)}</small><button type="button" class="co-plus" ${c.add(p.id)} aria-label="${L("Add")}">${c.icon('plus')}</button></article>`).join('') || c.empty()}</div>
      </section>`;
    },
    product(c, p) {
      return `<section class="co-pdp">
        <div class="co-pimg">${c.img(p, '', c.ui.img)}<header class="co-over"><button type="button" class="co-rd" data-act="back" aria-label="${L("Back")}">${c.icon('back')}</button>${c.toCart('co-rd', c.icon('bag'))}</header></div>
        <div class="co-sheet"><span class="co-grip"></span>${gallery(c, p, 'co-thumbs')}<h1>${c.esc(p.name)}</h1><p>${c.esc(p.description || c.catName(p.categoryId))}</p>
          <div class="co-stats"><div><b>${c.money(p.price)}</b><small>${L("Price")}</small></div><div><b>${c.esc(c.catName(p.categoryId) || '—')}</b><small>${L("Collection")}</small></div></div>
          <div class="co-qrow">${c.stepper('__sel', 'co-step')}${c.buy(L('Add to cart'), 'co-go')}</div></div>
      </section>`;
    },
  };

  // ======================================================== 18. CARE
  // Pharmacy / everyday store (with the vendor Live Preview): brand header
  // with search, cart badge and menu; blue hero banner with "Shop Now";
  // "Shop by Category" icon grid; Featured Products; a list screen with
  // quantity steppers and a "View Cart" footer; a detail screen with image
  // counter, thumbnails, price, quantity, outlined Add to Cart + Buy Now.
  T.care = {
    name: 'Care', defaults: { accent: '#1677D8', accent2: '#E8F2FD', bg: '#ffffff', bar: '#ffffff' },
    home(c) {
      const all = c.list(null, ''), f = all[0];
      return `<section class="ca-home">
        ${head(c)}
        <div class="ca-banner"><div><h2>${c.esc(c.headline(c.s.name))}</h2><p>${c.esc([c.s.area, c.openLabel()].filter(Boolean).join(' · '))}</p><button type="button" data-act="catpage" data-id="">Shop Now ${c.icon('arrowRight')}</button></div>${c.hero(f, 'ca-bimg')}${dots(3, 0, 'dots ca-dots')}</div>
        <div class="ca-sec"><h3>${L("Shop by Category")}</h3><a href="#/all">View All ${c.icon('arrowRight')}</a></div>
        <div class="ca-cats">${c.s.categories.slice(0, 8).map(k => `<button type="button" ${c.catPage(k.id)}><span>${c.icon('box')}</span>${c.esc(k.name)}</button>`).join('') || `<button type="button" ${c.catPage(null)}><span>${c.icon('apps')}</span>${L("All")}</button>`}</div>
        <div class="ca-sec"><h3>${L("Featured Products")}</h3><a href="#/all">View All ${c.icon('arrowRight')}</a></div>
        <div class="ca-feat">${c.list().map(p => `<article class="ca-card" ${c.open(p.id)}><span class="ca-heart">${c.icon('heart')}</span>${c.img(p)}<b>${c.esc(p.name)}</b><small>${c.esc(p.description)}</small><div class="ca-pr"><b>${c.money(p.price)}</b><button type="button" ${c.add(p.id)} aria-label="${L("Add to cart")}">${c.icon('cart')}</button></div></article>`).join('') || c.empty()}</div>
        ${nav(c, 'home')}
      </section>`;
    },
    category(c, id) {
      const ps = c.list(id === null ? c.ui.cat : id);
      return `<section class="ca-list">
        ${head(c)}
        <label class="ca-search">${c.searchInput('Search products…')}${c.icon('search')}</label>
        <div class="ca-chips"><button type="button" class="ca-chip${!id ? ' on' : ''}" ${c.catPage(null)}>${L("All")}</button>${c.s.categories.map(k => `<button type="button" class="ca-chip${id === k.id ? ' on' : ''}" ${c.catPage(k.id)}>${c.esc(k.name)}</button>`).join('')}</div>
        <div class="ca-rows">${ps.map(p => `<article class="ca-row"><button type="button" class="ca-rimg" ${c.open(p.id)}>${c.img(p)}</button><div ${c.open(p.id)}><b>${c.esc(p.name)}</b><small>${c.esc(p.description)}</small><span>${c.money(p.price)}</span></div>${c.stepper(p.id, 'ca-step')}</article>`).join('') || c.empty()}</div>
        ${nav(c, 'cat')}
      </section>`;
    },
    bar(c) { return `<div class="ca-bar"><div><small>${c.count()} item${c.count() === 1 ? '' : 's'}</small><b>${c.money(c.total())}</b></div><button type="button" data-act="tocart">View Cart ${c.icon('arrowRight')}</button></div>`; },
    product(c, p) {
      const n = Math.max(1, p.images.length);
      return `<section class="ca-pdp">
        <header class="ca-ph"><button type="button" class="ca-ic" data-act="back" aria-label="${L("Back")}">${c.icon('back')}</button><span></span><span class="ca-ic">${c.icon('heart')}</span>${c.toCart('ca-ic', c.icon('cart'))}</header>
        <div class="ca-big">${c.img(p, '', c.ui.img)}<span class="ca-count">${c.ui.img + 1}/${n}</span></div>
        ${gallery(c, p, 'ca-thumbs')}
        <h1>${c.esc(p.name)}</h1>
        <p class="ca-sub">${c.esc(c.catName(p.categoryId))}</p>
        <b class="ca-price">${c.money(p.price)}</b>
        ${p.description ? `<p class="ca-desc">${desc(c, p)}</p>` : ''}
        <div class="ca-qty">${c.stepper('__sel', 'ca-step')}</div>
        <div class="ca-two"><button type="button" class="ca-out" data-act="addsel">${c.icon('cart')} Add to Cart</button>${c.buy(L('Buy Now'), 'ca-fill')}</div>
      </section>`;
    },
  };
  function head(c) { return `<header class="ca-head"><span class="ca-logo">${c.icon('plus')}</span><div class="ca-bn"><b>${c.esc(c.s.name)}</b><small>${c.esc(c.s.tagline || c.s.area || '')}</small></div><button type="button" class="ca-ic" data-act="catpage" data-id="" aria-label="${L("Search")}">${c.icon('search')}</button>${c.toCart('ca-ic', c.icon('cart'))}<button type="button" class="ca-ic" data-act="catpage" data-id="" aria-label="${L("Menu")}">${c.icon('menu')}</button></header>`; }
  function nav(c, at) { return `<nav class="ca-nav"><button type="button" class="${at === 'home' ? 'on' : ''}" data-act="home">${c.icon('home')}<span>${L("Home")}</span></button><button type="button" class="${at === 'cat' ? 'on' : ''}" data-act="catpage" data-id="">${c.icon('apps')}<span>${L("Categories")}</span></button><button type="button" data-act="tocart">${c.icon('orders')}<span>${L("Cart")}</span></button><button type="button" data-act="tocart">${c.icon('user')}<span>${L("Account")}</span></button></nav>`; }

  window.CEFFLO_TEMPLATES = T;
  // Gallery order + discovery tags (the Vendor App reads the same list).
  window.CEFFLO_TEMPLATE_ORDER = ['care', 'capsule', 'kit', 'brew', 'crimson', 'lift', 'harvest', 'botanic', 'combo', 'discover', 'atelier', 'pour', 'tailor', 'sprint', 'splash', 'service', 'warung', 'collector'];
})();
