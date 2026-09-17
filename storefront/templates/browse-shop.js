// Template 1 — Browse & Shop. Discovery-first: Home/Browse -> Category ->
// Product listing -> Product Detail -> Cart -> Checkout -> Order Created.
// Clean, modern, retail-oriented. Renders whatever vendor data/branding the
// adapter supplies — no vendor content is hardcoded here.
//
// Ports template_browse_shop.dart behaviour to a static HTML render function.

import { icon } from '../icons.js';
import { esc, money, imagePlaceholder, qtyStepper, standaloneQtyStepper, categoryChip, backBar, cartBadge, searchInput, filterItems, brandButton } from '../commerce.js';

export const key = 'browse_shop';

export function renderStage(stage, ctx) {
  if (stage === 'category') return categoryView(ctx);
  if (stage === 'detail') return detailView(ctx);
  return homeView(ctx);
}

function topBar(ctx) {
  return `<div class="sf-topbar">
    <span class="sf-topbar__mark" style="background:${ctx.tokens.accentBackground};color:${ctx.tokens.onPrimary}">${icon('store', { size: 15 })}</span>
    <h1 class="sf-topbar__name">${esc(ctx.vendor.name)}</h1>
    <button type="button" class="sf-iconbtn" data-action="open-category" data-cat="all" aria-label="Search products">${icon('search', { size: 19 })}</button>
    ${cartBadge(ctx.cart)}
  </div>`;
}

function homeView(ctx) {
  const { tokens, categories, items } = ctx;
  const shopCategories = categories.filter((c) => c.id !== 'all');
  const featured = items.slice(0, 4);
  return `<div class="sf-stage">
    ${topBar(ctx)}
    <div class="sf-scroll">
      <section class="sf-hero" style="background:${tokens.accentBackground};color:${tokens.onPrimary}">
        <h2>Everything you need,<br>made simple.</h2>
        <p>Quality picks for you and your family.</p>
        <button type="button" class="sf-hero__cta" style="color:${tokens.primary}" data-action="open-category" data-cat="all">Shop Now ${icon('chevronRight', { size: 14 })}</button>
      </section>

      <div class="sf-rowhead"><h3>Shop by Category</h3>
        <button type="button" class="sf-link" style="color:${tokens.primary}" data-action="open-category" data-cat="all">View All</button>
      </div>
      <div class="sf-catgrid">
        ${shopCategories
          .map(
            (c) => `<button type="button" class="sf-cattile" data-action="open-category" data-cat="${esc(c.id)}">
              <span class="sf-cattile__icon" style="background:${hexA(tokens.primary)};color:${tokens.primary}">${icon(c.icon, { size: 19 })}</span>
              <span class="sf-cattile__label">${esc(c.label)}</span>
            </button>`
          )
          .join('')}
      </div>

      <div class="sf-rowhead"><h3>Featured Products</h3>
        <button type="button" class="sf-link" style="color:${tokens.primary}" data-action="open-category" data-cat="all">View All</button>
      </div>
      <div class="sf-cardgrid">
        ${featured.map((item) => productCard(item, tokens)).join('')}
      </div>
    </div>
  </div>`;
}

function productCard(item, tokens) {
  return `<button type="button" class="sf-card" data-action="open-item" data-item="${esc(item.id)}">
    ${imagePlaceholder(item.icon, tokens, { size: '100%', radius: 14, iconSize: 30 })}
    <p class="sf-card__name">${esc(item.name)}</p>
    <p class="sf-card__price" style="color:${tokens.primary}">${money(item.price)}</p>
  </button>`;
}

function categoryView(ctx) {
  const { tokens, categories, items, cart, top } = ctx;
  const categoryId = top.categoryId || 'all';
  const query = top.query || '';
  const visible = filterItems(items, categoryId, query);
  const rows = visible
    .map(
      (item) => `<li class="sf-listrow">
        <button type="button" class="sf-listrow__link" data-action="open-item" data-item="${esc(item.id)}">
          ${imagePlaceholder(item.icon, tokens, { size: '56px' })}
          <span class="sf-listrow__info">
            <strong>${esc(item.name)}</strong>
            ${item.description ? `<span class="sf-listrow__desc">${esc(item.description)}</span>` : ''}
            <span class="sf-listrow__price">${money(item.price)}</span>
          </span>
        </button>
        <span class="sf-listrow__stepper">${qtyStepper(item, cart, tokens)}</span>
      </li>`
    )
    .join('');

  const footer = cart.isEmpty
    ? ''
    : `<div class="sf-cart__footer sf-cart__footer--split">
        <span class="sf-cart__mini"><small>${cart.itemCount} items</small><strong>${money(cart.subtotal)}</strong></span>
        ${brandButton('View Cart', tokens, { action: 'open-cart', icon: 'chevronRight' })}
      </div>`;

  return `<div class="sf-stage">
    ${backBar('Category & Products', { trailing: cartBadge(cart) })}
    <div class="sf-toolbar">
      ${searchInput('Search products...', query)}
    </div>
    <div class="sf-chiprow">
      ${categories.map((c) => categoryChip(c.label, c.id === categoryId, tokens, { action: 'category-select', dataAttrs: `data-cat="${esc(c.id)}"` })).join('')}
    </div>
    <div class="sf-scroll">
      ${visible.length ? `<ul class="sf-listrows">${rows}</ul>` : '<p class="sf-empty">No products found.</p>'}
    </div>
    ${footer}
  </div>`;
}

function detailView(ctx) {
  const { tokens, items, cart, top } = ctx;
  const item = items.find((i) => i.id === top.itemId) || items[0];
  const qty = top.qty || 1;
  return `<div class="sf-stage">
    ${backBar('Product Detail', { trailing: `<span class="sf-iconbtn sf-iconbtn--static" aria-hidden="true">${icon('heart', { size: 19 })}</span>` })}
    <div class="sf-scroll">
      ${imagePlaceholder(item.icon, tokens, { size: '100%', radius: 18, iconSize: 46 })}
      <h1 class="sf-detail__name">${esc(item.name)}</h1>
      <div class="sf-detail__row">
        <span class="sf-detail__price" style="color:${tokens.primary}">${money(item.price)}</span>
        <span class="sf-stock ${item.inStock ? 'is-in' : 'is-out'}">${icon(item.inStock ? 'check' : 'x', { size: 13 })} ${item.inStock ? 'In stock' : 'Out of stock'}</span>
      </div>
      <p class="sf-detail__desc">${esc(item.description || 'No description provided for this product yet.')}</p>
      <div class="sf-detail__qtyrow"><span>Quantity</span>${standaloneQtyStepper(qty, tokens)}</div>
    </div>
    <div class="sf-cart__footer sf-cart__footer--pair">
      ${brandButton('Add to Cart', tokens, { action: 'add-to-cart', dataAttrs: 'data-mode="pop"', outlined: true })}
      ${brandButton('Buy Now', tokens, { action: 'add-to-cart', dataAttrs: 'data-mode="checkout"' })}
    </div>
  </div>`;
}

function hexA(hex) {
  return `${hex}1F`;
}
