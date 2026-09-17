// CEFFLO Storefront — application shell and action dispatch.
//
// A customer visits `storefront/?vendor=<id>&template=<key>` (or just
// `storefront/` for a default demoable fixture vendor, same "never blank on
// a missing token" rule the Customer Tracking PWA follows). This module:
//   1. resolves the vendor/template/brand-colour config (storefront-config.js)
//   2. resolves the product/category catalogue (fixtures.js)
//   3. mounts the selected template's screens, sharing one cart/checkout/
//      order-created flow across all three (commerce.js)
//
// All state here is prototype/session-local: no payment gateway, no order
// backend, no database writes.

import { resolveStorefrontConfig } from './storefront-config.js';
import { resolveCatalog } from './fixtures.js';
import { createCart, generateOrderRef } from './cart.js';
import { createStepStack, cartView, checkoutView, orderCreatedView } from './commerce.js';
import * as browseShop from './templates/browse-shop.js';
import * as quickOrder from './templates/quick-order.js';
import { DEFAULT_CUSTOMIZATION_GROUPS } from './templates/quick-order.js';
import * as catalogue from './templates/catalogue.js';
import { DEFAULT_VARIANT_GROUPS } from './templates/catalogue.js';

const TEMPLATE_MODULES = {
  browse_shop: browseShop,
  quick_order: quickOrder,
  catalogue: catalogue
};

const root = document.getElementById('app');
const params = new URLSearchParams(location.search);

/* ---------------------------------------------------------------- state */

const config = resolveStorefrontConfig(params);
const { items, categories } = resolveCatalog(config.vendorId);
const cart = createCart();
const stack = createStepStack('home');
const checkoutState = { delivery: 'standard', payment: 'cod' };
const templateModule = TEMPLATE_MODULES[config.template.key] || browseShop;

/* ------------------------------------------------------------- theming */

function applyTheme(tokens) {
  const style = document.documentElement.style;
  style.setProperty('--sf-primary', tokens.primary);
  style.setProperty('--sf-secondary', tokens.secondary);
  style.setProperty('--sf-on-primary', tokens.onPrimary);
  style.setProperty('--sf-accent-bg', tokens.accentBackground);
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', tokens.primary);
}

applyTheme(config.tokens);

/* ---------------------------------------------------------- item lookup */

function findItem(id) {
  return items.find((i) => i.id === id) || null;
}

function defaultGroupsFor(item) {
  if (config.template.key === 'quick_order') return item.variantGroups.length ? item.variantGroups : DEFAULT_CUSTOMIZATION_GROUPS;
  if (config.template.key === 'catalogue') return item.variantGroups.length ? item.variantGroups : DEFAULT_VARIANT_GROUPS;
  return [];
}

function defaultSelectionFor(item) {
  const groups = defaultGroupsFor(item);
  if (!groups.length) return null;
  return Object.fromEntries(groups.map((g) => [g.label, g.options[0]]));
}

/* --------------------------------------------------------------- render */

function ctxFor(top) {
  return { vendor: config.vendor, items, categories, tokens: config.tokens, cart, top };
}

function render() {
  const top = stack.top;
  let html;
  if (top.stage === 'cart') {
    html = cartView(cart, config.tokens, { title: config.template.cartTitle, showNote: config.template.showCartNote });
  } else if (top.stage === 'checkout') {
    html = checkoutView(cart, config.tokens, checkoutState);
  } else if (top.stage === 'confirmed') {
    html = orderCreatedView(config.tokens, top.orderRef);
  } else {
    html = templateModule.renderStage(top.stage, ctxFor(top));
  }
  root.innerHTML = `<div class="sf-app" data-template="${config.template.key}">${html}</div>`;

  if (!prefersReducedMotion()) {
    const stage = root.querySelector('.sf-stage');
    if (stage) {
      stage.classList.add('is-entering');
      requestAnimationFrame(() => requestAnimationFrame(() => stage.classList.remove('is-entering')));
    }
  }

  const heading = root.querySelector('h1, .sf-backbar__title');
  heading?.setAttribute('tabindex', '-1');
}

const reduceMotionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
const prefersReducedMotion = () => reduceMotionQuery.matches;

/* ---------------------------------------------------------------- cart */

function adjustQty(itemId, variant, delta) {
  const item = findItem(itemId);
  if (!item) return;
  const variantSummary = variant || null;
  const current = cart.qtyOf(item, variantSummary);
  const next = current + delta;
  if (current === 0 && delta > 0) {
    cart.add(item, { qty: 1, variantSummary });
  } else {
    cart.setQty(cartKeyOf(itemId, variantSummary), next);
  }
}

function cartKeyOf(itemId, variantSummary) {
  return `${itemId}::${variantSummary || ''}`;
}

/* --------------------------------------------------------- action dispatch */

function handleAction(action, el) {
  switch (action) {
    case 'back':
      // history.back() fires an async `popstate`; the frame is popped and
      // re-rendered there (see the popstate listener below), not here.
      stack.pop();
      return false;
    case 'open-cart':
      stack.push({ stage: 'cart' });
      return true;
    case 'checkout':
      stack.push({ stage: 'checkout' });
      return true;
    case 'place-order': {
      const orderRef = generateOrderRef();
      stack.push({ stage: 'confirmed', orderRef });
      return true;
    }
    case 'continue-shopping':
      cart.clear();
      checkoutState.delivery = 'standard';
      checkoutState.payment = 'cod';
      stack.reset('home');
      return true;
    case 'open-item': {
      const itemId = el.dataset.item;
      const item = findItem(itemId);
      if (!item) return true;
      stack.push({ stage: 'detail', itemId, qty: 1, selection: defaultSelectionFor(item) });
      return true;
    }
    case 'open-customize': {
      const itemId = el.dataset.item;
      const item = findItem(itemId);
      if (!item) return true;
      stack.push({ stage: 'customize', itemId, qty: 1, selection: defaultSelectionFor(item) });
      return true;
    }
    case 'open-category': {
      const stage = config.template.categoryStage || 'category';
      stack.push({ stage, categoryId: el.dataset.cat, query: '' });
      return true;
    }
    case 'category-select':
      stack.updateTop({ categoryId: el.dataset.cat, query: '' });
      return true;
    case 'qty-inc':
      adjustQty(el.dataset.item, el.dataset.variant, +1);
      return true;
    case 'qty-dec':
      adjustQty(el.dataset.item, el.dataset.variant, -1);
      return true;
    case 'remove-line':
      cart.remove(el.dataset.key);
      return true;
    case 'select-delivery':
      checkoutState.delivery = el.dataset.value;
      return true;
    case 'select-payment':
      checkoutState.payment = el.dataset.value;
      return true;
    case 'stage-qty-inc':
      stack.updateTop({ qty: (stack.top.qty || 1) + 1 });
      return true;
    case 'stage-qty-dec':
      stack.updateTop({ qty: Math.max(1, (stack.top.qty || 1) - 1) });
      return true;
    case 'variant-select':
      stack.updateTop({ selection: { ...(stack.top.selection || {}), [el.dataset.group]: el.dataset.option } });
      return true;
    case 'wishlist-toggle': {
      const wishlist = new Set(stack.top.wishlist || []);
      const id = el.dataset.item;
      wishlist.has(id) ? wishlist.delete(id) : wishlist.add(id);
      stack.updateTop({ wishlist });
      return true;
    }
    case 'add-to-cart': {
      const top = stack.top;
      const item = findItem(top.itemId);
      if (!item) return true;
      const qty = top.qty || 1;
      const variantSummary = top.selection ? Object.values(top.selection).join(' · ') : null;
      cart.add(item, { qty, variantSummary });
      if (el.dataset.mode === 'checkout') stack.push({ stage: 'checkout' });
      else stack.pop();
      return true;
    }
    case 'add-to-order': {
      const top = stack.top;
      const item = findItem(top.itemId);
      if (!item) return true;
      const qty = top.qty || 1;
      const variantSummary = top.selection ? Object.values(top.selection).join(' · ') : '';
      cart.add(item, { qty, variantSummary });
      stack.pop();
      return true;
    }
    default:
      return false;
  }
}

root.addEventListener('click', (event) => {
  const el = event.target.closest('[data-action]');
  if (!el || el.disabled) return;
  if (handleAction(el.dataset.action, el)) render();
});

root.addEventListener('input', (event) => {
  const el = event.target;
  if (el.dataset.role === 'search-input') {
    stack.updateTop({ query: el.value });
    // Re-render, but keep focus + caret position in the search field.
    const selectionStart = el.selectionStart;
    render();
    const revived = root.querySelector('[data-role="search-input"]');
    if (revived) {
      revived.focus();
      revived.setSelectionRange(selectionStart, selectionStart);
    }
  }
});

window.addEventListener('popstate', () => {
  stack.popFromHistory();
  render();
});
reduceMotionQuery.addEventListener?.('change', render);

/* ----------------------------------------------- developer QA/demo panel */

/**
 * Developer-only convenience for switching template/vendor/brand colour
 * while exercising the prototype. It is NOT part of the customer-facing UI
 * and only renders behind `?dev=1`, same convention as the Customer
 * Tracking PWA's `?dev=1` state simulator.
 */
function mountDevPanel() {
  if (params.get('dev') !== '1') return;
  const panel = document.createElement('div');
  panel.className = 'sf-devbar';
  const presets = ['#2A6EEC', '#E0463A', '#12805C', '#7A4A21', '#4C2A85'];
  panel.innerHTML = `
    <span class="sf-devbar__label">Prototype dev panel</span>
    ${Object.keys(TEMPLATE_MODULES)
      .map((k) => `<button type="button" data-tpl="${k}">${k.replace('_', ' ')}</button>`)
      .join('')}
    ${presets.map((c) => `<button type="button" class="sf-devbar__swatch" data-color="${c}" style="background:${c}" aria-label="Preview brand colour ${c}"></button>`).join('')}
  `;
  panel.addEventListener('click', (event) => {
    const button = event.target.closest('button');
    if (!button) return;
    const next = new URLSearchParams(location.search);
    if (button.dataset.tpl) next.set('template', button.dataset.tpl);
    if (button.dataset.color) next.set('color', button.dataset.color);
    location.search = next.toString();
  });
  document.body.appendChild(panel);
}

/* -------------------------------------------------------------- bootstrap */

render();
mountDevPanel();

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js', { scope: './' }).catch((error) => {
      console.warn('CEFFLO Storefront service worker unavailable:', error);
    });
  });
}
