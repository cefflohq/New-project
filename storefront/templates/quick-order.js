// Template 2 — Quick Order. Speed-first: Home -> optional Product
// Customization -> Review Order -> Checkout -> Order Created. Deliberately
// NOT Browse & Shop with different colours: no category drill-down page, no
// product detail page for simple items — quantity is adjustable right on the
// home grid, and only items that need it open a customization step.
//
// Ports template_quick_order.dart behaviour to a static HTML render function.

import { icon } from '../icons.js';
import { esc, money, imagePlaceholder, qtyStepper, standaloneQtyStepper, categoryChip, backBar, searchInput, filterItems, brandButton } from '../commerce.js';

export const key = 'quick_order';

export const DEFAULT_CUSTOMIZATION_GROUPS = [{ label: 'Options', options: ['Standard', 'Extra'] }];

export function renderStage(stage, ctx) {
  if (stage === 'customize') return customizeView(ctx);
  return homeView(ctx);
}

function homeView(ctx) {
  const { tokens, categories, items, cart, top } = ctx;
  const activeCategory = top.categoryId || 'all';
  const query = top.query || '';
  const visible = filterItems(items, activeCategory, query);

  const rows = visible
    .map((item) => {
      const action = item.needsCustomization
        ? brandButton('Add', tokens, { action: 'open-customize', dataAttrs: `data-item="${esc(item.id)}"`, icon: 'plus' })
        : `<span style="width:96px;display:flex;justify-content:flex-end">${qtyStepper(item, cart, tokens)}</span>`;
      return `<li class="sf-quickrow">
        ${imagePlaceholder(item.icon, tokens, { size: '52px' })}
        <span class="sf-quickrow__info"><strong>${esc(item.name)}</strong><span style="color:${tokens.primary}">${money(item.price)}</span></span>
        ${action}
      </li>`;
    })
    .join('');

  const footer = cart.isEmpty
    ? ''
    : `<div class="sf-cart__footer sf-cart__footer--flat">
        <button type="button" class="sf-reviewbar" style="background:${tokens.accentBackground};color:${tokens.onPrimary}" data-action="open-cart">
          <span>${cart.itemCount} items · ${money(cart.subtotal)}</span>
          <span class="sf-reviewbar__cta">Review Order ${icon('chevronRight', { size: 15 })}</span>
        </button>
      </div>`;

  return `<div class="sf-stage">
    <div class="sf-quickhead">
      <span class="sf-quickhead__mark" style="background:${tokens.accentBackground};color:${tokens.onPrimary}">${icon('store', { size: 15 })}</span>
      <div>
        <h1>${esc(ctx.vendor.name)}</h1>
        <p>Order ahead, skip the wait.</p>
      </div>
    </div>
    <div class="sf-toolbar">${searchInput('Search menu...', query)}</div>
    <div class="sf-chiprow">
      ${categories.map((c) => categoryChip(c.label, c.id === activeCategory, tokens, { action: 'category-select', dataAttrs: `data-cat="${esc(c.id)}"` })).join('')}
    </div>
    <div class="sf-scroll">
      <h2 class="sf-section sf-section--tight">Popular Today</h2>
      ${visible.length ? `<ul class="sf-quickrows">${rows}</ul>` : '<p class="sf-empty">No items found.</p>'}
    </div>
    ${footer}
  </div>`;
}

function customizeView(ctx) {
  const { tokens, items, top } = ctx;
  const item = items.find((i) => i.id === top.itemId) || items[0];
  const groups = item.variantGroups.length ? item.variantGroups : DEFAULT_CUSTOMIZATION_GROUPS;
  const selection = top.selection || {};
  const qty = top.qty || 1;

  return `<div class="sf-stage">
    ${backBar('Customize')}
    <div class="sf-scroll">
      ${imagePlaceholder(item.icon, tokens, { size: '100%', radius: 16, iconSize: 40 })}
      <h1 class="sf-detail__name">${esc(item.name)}</h1>
      <p class="sf-detail__price" style="color:${tokens.primary}">${money(item.price)}</p>
      ${item.description ? `<p class="sf-detail__desc">${esc(item.description)}</p>` : ''}
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
    <div class="sf-cart__footer">
      ${brandButton('Add to Order', tokens, { action: 'add-to-order', trailing: money(item.price * qty) })}
    </div>
  </div>`;
}
