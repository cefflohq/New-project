// Template 3 — Catalogue. Visual/collection-first: Catalogue Home ->
// Collection -> Product Grid -> Product Detail -> Cart -> Checkout -> Order
// Created. Editorial, image-forward — categories are presented as curated
// "collections" rather than a browse/search list.
//
// Ports template_catalogue.dart behaviour to a static HTML render function.

import { icon } from '../icons.js';
import { esc, money, imagePlaceholder, standaloneQtyStepper, categoryChip, backBar, cartBadge, searchInput, filterItems, brandButton } from '../commerce.js';

export const key = 'catalogue';

export const DEFAULT_VARIANT_GROUPS = [{ label: 'Option', options: ['Standard', 'Premium'] }];

export function renderStage(stage, ctx) {
  if (stage === 'collection') return collectionView(ctx);
  if (stage === 'detail') return detailView(ctx);
  return homeView(ctx);
}

function homeView(ctx) {
  const { tokens, categories, items, cart } = ctx;
  const collections = categories.filter((c) => c.id !== 'all');
  return `<div class="sf-stage">
    <div class="sf-cataloguehead">
      <h1>${esc(ctx.vendor.name.toUpperCase())}</h1>
      <button type="button" class="sf-iconbtn" data-action="open-category" data-cat="all" aria-label="Search products">${icon('search', { size: 19 })}</button>
      ${cartBadge(cart)}
    </div>
    <div class="sf-scroll">
      <button type="button" class="sf-editorial-hero" data-action="open-category" data-cat="all">
        <span class="sf-editorial-hero__glyph" aria-hidden="true">${icon('image', { size: 40 })}</span>
        <span class="sf-editorial-hero__text">
          <strong>Better spaces,<br>brighter days.</strong>
          <span class="sf-editorial-hero__cta" style="background:${tokens.accentBackground};color:${tokens.onPrimary}">Explore Collection ${icon('chevronRight', { size: 13 })}</span>
        </span>
      </button>

      <h2 class="sf-section">Shop by Collection</h2>
      <div class="sf-collectiongrid">
        ${collections
          .map(
            (c) => `<button type="button" class="sf-collectiontile" data-action="open-category" data-cat="${esc(c.id)}">
              <span class="sf-collectiontile__glyph" style="color:${tokens.primary}">${icon(c.icon, { size: 28 })}</span>
              <span class="sf-collectiontile__label">${esc(c.label)}</span>
              <span class="sf-collectiontile__count">${items.filter((i) => i.categoryId === c.id).length} products</span>
            </button>`
          )
          .join('')}
      </div>

      <button type="button" class="sf-promoband" style="background:${tokens.accentBackground};color:${tokens.onPrimary}" data-action="open-category" data-cat="all">
        <span><small>NEW</small><strong>The curated collection.</strong></span>
        ${icon('chevronRight', { size: 18 })}
      </button>
    </div>
  </div>`;
}

function collectionView(ctx) {
  const { tokens, categories, items, cart, top } = ctx;
  const categoryId = top.categoryId || 'all';
  const category = categories.find((c) => c.id === categoryId) || categories[0];
  const query = top.query || '';
  const visible = filterItems(items, categoryId, query);
  const wishlist = top.wishlist || new Set();

  const cards = visible
    .map((item) => {
      const wished = wishlist.has(item.id);
      return `<div class="sf-collectioncard">
        <div class="sf-collectioncard__media">
          <button type="button" class="sf-collectioncard__img" data-action="open-item" data-item="${esc(item.id)}" aria-label="View ${esc(item.name)}">
            ${imagePlaceholder(item.icon, tokens, { size: '100%', radius: 14, iconSize: 30 })}
          </button>
          <button type="button" class="sf-wishbtn" data-action="wishlist-toggle" data-item="${esc(item.id)}" style="color:${wished ? tokens.primary : ''}" aria-pressed="${wished}" aria-label="${wished ? 'Remove' : 'Add'} ${esc(item.name)} ${wished ? 'from' : 'to'} wishlist">${icon(wished ? 'heartFilled' : 'heart', { size: 16 })}</button>
        </div>
        <p class="sf-card__name">${esc(item.name)}</p>
        ${item.description ? `<p class="sf-collectioncard__desc">${esc(item.description)}</p>` : ''}
        <div class="sf-collectioncard__row">
          <span class="sf-card__price" style="color:${tokens.primary}">${money(item.price)}</span>
          <button type="button" class="sf-iconbtn" style="color:${tokens.primary}" data-action="qty-inc" data-item="${esc(item.id)}" data-variant="" aria-label="Add ${esc(item.name)} to cart">${icon('shoppingCart', { size: 16 })}</button>
        </div>
      </div>`;
    })
    .join('');

  return `<div class="sf-stage">
    ${backBar(category.label, { trailing: cartBadge(cart) })}
    <div class="sf-toolbar sf-toolbar--pair">
      ${searchInput(`Search in ${category.label}...`, query)}
      <span class="sf-iconbtn sf-iconbtn--static" aria-hidden="true">${icon('package', { size: 17 })}</span>
    </div>
    <div class="sf-scroll">
      ${visible.length ? `<div class="sf-collectiongrid sf-collectiongrid--products">${cards}</div>` : '<p class="sf-empty">No products in this collection yet.</p>'}
    </div>
  </div>`;
}

function detailView(ctx) {
  const { tokens, items, top } = ctx;
  const item = items.find((i) => i.id === top.itemId) || items[0];
  const groups = item.variantGroups.length ? item.variantGroups : DEFAULT_VARIANT_GROUPS;
  const selection = top.selection || {};
  const qty = top.qty || 1;

  return `<div class="sf-stage">
    ${backBar('Product Detail', { trailing: `<span class="sf-iconbtn sf-iconbtn--static" aria-hidden="true">${icon('heart', { size: 19 })}</span>` })}
    <div class="sf-scroll">
      ${imagePlaceholder(item.icon, tokens, { size: '100%', radius: 18, iconSize: 48 })}
      <div class="sf-thumbrow">
        ${[0, 1, 2, 3].map((i) => `<span class="sf-thumb${i === 0 ? ' is-active' : ''}" style="${i === 0 ? `border-color:${tokens.primary}` : ''}">${imagePlaceholder(item.icon, tokens, { size: '56px', radius: 9, iconSize: 20 })}</span>`).join('')}
      </div>
      <h1 class="sf-detail__name">${esc(item.name)}</h1>
      <div class="sf-detail__row">
        <span class="sf-detail__price" style="color:${tokens.primary}">${money(item.price)}</span>
        ${item.rating ? `<span class="sf-rating">${icon('star', { size: 13 })} ${esc(item.rating)}</span>` : ''}
      </div>
      <p class="sf-detail__desc">${esc(item.description || 'No description provided for this product yet.')}</p>
      ${groups
        .map(
          (g) => `<div class="sf-variantgroup">
            <h3>${esc(g.label)}</h3>
            <div class="sf-chiprow sf-chiprow--wrap">
              ${g.options
                .map((opt) =>
                  categoryChip(opt, selection[g.label] === opt, tokens, {
                    action: 'variant-select',
                    dataAttrs: `data-group="${esc(g.label)}" data-option="${esc(opt)}"`
                  })
                )
                .join('')}
            </div>
          </div>`
        )
        .join('')}
      <div class="sf-detail__qtyrow"><span>Quantity</span>${standaloneQtyStepper(qty, tokens)}</div>
    </div>
    <div class="sf-cart__footer sf-cart__footer--pair">
      ${brandButton('Add to Cart', tokens, { action: 'add-to-cart', dataAttrs: 'data-mode="pop"', outlined: true })}
      ${brandButton('Buy Now', tokens, { action: 'add-to-cart', dataAttrs: 'data-mode="pop"' })}
    </div>
  </div>`;
}
