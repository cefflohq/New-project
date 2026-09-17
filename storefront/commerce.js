// CEFFLO Storefront — shared commerce primitives reused by all 3 templates.
//
// Per spec, Browse & Shop / Quick Order / Catalogue must feel genuinely
// different up through product selection, but they converge on one cart,
// one checkout and one order-confirmation flow — built once, here, instead
// of three separate commerce engines (ports storefront_common.dart).
//
// Everything in this module is preview/prototype state: no payment gateway,
// no real charge, no parallel order backend.

import { icon } from './icons.js';
import { hexToRgba } from './storefront-config.js';

/* ------------------------------------------------------------- step stack */

/**
 * Per-template in-page navigation stack (mirrors StorefrontStep / the local
 * `_stack` field each Flutter template preview owns). Browser Back pops it,
 * via history.pushState, so the hardware/software back gesture behaves the
 * way a customer expects.
 */
export function createStepStack(initialStage) {
  let stack = [{ stage: initialStage }];
  const listeners = new Set();
  const notify = () => listeners.forEach((fn) => fn());
  return {
    subscribe(fn) {
      listeners.add(fn);
      return () => listeners.delete(fn);
    },
    get top() {
      return stack[stack.length - 1];
    },
    get depth() {
      return stack.length;
    },
    push(step) {
      stack.push(step);
      history.pushState({ sfDepth: stack.length }, '');
      notify();
    },
    /** In-place patch of the current frame (e.g. category chip switch, live
     * search query, variant selection) — no history entry, mirrors a
     * Flutter `setState` on the same screen instance. */
    updateTop(patch) {
      stack[stack.length - 1] = { ...stack[stack.length - 1], ...patch };
      notify();
    },
    /** Triggers the browser Back navigation; the actual frame is popped by
     * `popFromHistory()` when the resulting `popstate` event arrives, so a
     * software back tap and a hardware/gesture back always go through the
     * same single mutation path. */
    pop() {
      if (stack.length > 1) history.back();
    },
    /** Invoked from the popstate listener only — never call directly. */
    popFromHistory() {
      if (stack.length > 1) {
        stack.pop();
        notify();
      }
    },
    reset(stage) {
      stack = [{ stage }];
      notify();
    }
  };
}

/* ----------------------------------------------------------------- money */

export const money = (value) => `RM ${Number(value).toFixed(2)}`;

export const esc = (value) =>
  String(value ?? '').replace(/[&<>"']/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[char]));

/* ------------------------------------------------------- shared UI atoms */

export function imagePlaceholder(iconName, tokens, { size, radius = 12, iconSize = 26 } = {}) {
  const style = `background:${hexToRgba(tokens.primary, 0.12)};border-radius:${radius}px;color:${tokens.primary};${size ? `width:${size};height:${size};` : ''}`;
  return `<span class="sf-placeholder" style="${style}">${icon(iconName, { size: iconSize })}</span>`;
}

export function brandButton(label, tokens, { action, dataAttrs = '', icon: iconName, outlined = false, trailing, disabled = false, ariaLabel } = {}) {
  const label_ = `${iconName ? icon(iconName, { size: 16, className: 'sf-btn__icon' }) : ''}<span class="sf-btn__label">${esc(label)}</span>${trailing ? `<span class="sf-btn__trailing">${esc(trailing)}</span>` : ''}`;
  const style = outlined
    ? `color:${tokens.primary};border-color:${tokens.primary}`
    : `background:${tokens.accentBackground};color:${tokens.onPrimary};border-color:transparent`;
  return `<button type="button" class="sf-btn${outlined ? ' sf-btn--outlined' : ''}" style="${style}" data-action="${action}" ${dataAttrs} ${disabled ? 'disabled' : ''} ${ariaLabel ? `aria-label="${esc(ariaLabel)}"` : ''}>${label_}</button>`;
}

export function qtyStepper(item, cart, tokens, { variantSummary = null, compact = false } = {}) {
  const qty = cart.qtyOf(item, variantSummary);
  const attrs = `data-item="${esc(item.id)}" data-variant="${esc(variantSummary || '')}"`;
  if (qty <= 0) {
    return `<button type="button" class="sf-stepper__btn sf-stepper__btn--filled" style="background:${tokens.accentBackground};" data-action="qty-inc" ${attrs} aria-label="Add ${esc(item.name)} to cart">${icon('plus', { size: 14 })}</button>`;
  }
  return `<div class="sf-stepper${compact ? ' sf-stepper--compact' : ''}">
    <button type="button" class="sf-stepper__btn" data-action="qty-dec" ${attrs} aria-label="Decrease quantity of ${esc(item.name)}">${icon('minus', { size: 13 })}</button>
    <span class="sf-stepper__value" aria-live="polite">${qty}</span>
    <button type="button" class="sf-stepper__btn sf-stepper__btn--filled" data-action="qty-inc" ${attrs} aria-label="Increase quantity of ${esc(item.name)}">${icon('plus', { size: 13 })}</button>
  </div>`;
}

/** Standalone (pre-cart) quantity control used on detail/customize pages. */
export function standaloneQtyStepper(qty, tokens) {
  return `<div class="sf-stepper">
    <button type="button" class="sf-stepper__btn" data-action="stage-qty-dec" aria-label="Decrease quantity">${icon('minus', { size: 13 })}</button>
    <span class="sf-stepper__value" aria-live="polite">${qty}</span>
    <button type="button" class="sf-stepper__btn sf-stepper__btn--filled" style="background:${tokens.accentBackground}" data-action="stage-qty-inc" aria-label="Increase quantity">${icon('plus', { size: 13 })}</button>
  </div>`;
}

export function categoryChip(label, selected, tokens, { action, dataAttrs = '', icon: iconName } = {}) {
  const style = selected ? `background:${tokens.accentBackground};color:${tokens.onPrimary}` : '';
  return `<button type="button" class="sf-chip${selected ? ' is-selected' : ''}" style="${style}" data-action="${action}" ${dataAttrs} aria-pressed="${selected}">
    ${iconName ? icon(iconName, { size: 13 }) : ''}<span>${esc(label)}</span>
  </button>`;
}

export function backBar(title, { trailing = '' } = {}) {
  return `<div class="sf-backbar">
    <button type="button" class="sf-iconbtn" data-action="back" aria-label="Back">${icon('chevronLeft', { size: 22 })}</button>
    <h1 class="sf-backbar__title">${esc(title)}</h1>
    <div class="sf-backbar__trailing">${trailing}</div>
  </div>`;
}

export function cartBadge(cart, { action = 'open-cart', ariaLabel = 'Open cart' } = {}) {
  return `<button type="button" class="sf-iconbtn sf-cartbtn" data-action="${action}" aria-label="${esc(ariaLabel)} (${cart.itemCount} item${cart.itemCount === 1 ? '' : 's'})">
    ${icon('shoppingCart', { size: 20 })}
    ${cart.itemCount > 0 ? `<span class="sf-cartbtn__badge">${cart.itemCount}</span>` : ''}
  </button>`;
}

export function searchInput(placeholder, value = '') {
  return `<div class="sf-search">
    ${icon('search', { size: 16 })}
    <input type="search" class="sf-search__input" data-role="search-input" placeholder="${esc(placeholder)}" value="${esc(value)}" aria-label="${esc(placeholder)}">
  </div>`;
}

/** Shared category/collection + live-search filter used by all 3 templates. */
export function filterItems(items, categoryId, query) {
  let visible = !categoryId || categoryId === 'all' ? items : items.filter((i) => i.categoryId === categoryId);
  const q = (query || '').trim().toLowerCase();
  if (q) visible = visible.filter((i) => i.name.toLowerCase().includes(q));
  return visible;
}

/* ---------------------------------------------------------- shared views */

export function cartView(cart, tokens, { title = 'Your Cart', showNote = false } = {}) {
  const rows = cart.lines
    .map(
      (line) => `
    <li class="sf-cartline">
      ${imagePlaceholder(line.item.icon, tokens, { size: '64px' })}
      <div class="sf-cartline__info">
        <p class="sf-cartline__name">${esc(line.item.name)}</p>
        ${line.variantSummary ? `<p class="sf-cartline__variant">${esc(line.variantSummary)}</p>` : ''}
        <p class="sf-cartline__price" style="color:${tokens.primary}">${money(line.item.price)}</p>
      </div>
      <div class="sf-cartline__actions">
        ${qtyStepper(line.item, cart, tokens, { variantSummary: line.variantSummary, compact: true })}
        <button type="button" class="sf-cartline__remove" data-action="remove-line" data-key="${esc(line.key)}" aria-label="Remove ${esc(line.item.name)} from cart">${icon('trash', { size: 16 })}</button>
      </div>
    </li>`
    )
    .join('');

  const body = cart.isEmpty
    ? `<p class="sf-empty">Your cart is empty.</p>`
    : `<ul class="sf-cartlines">${rows}</ul>
      ${showNote ? `<div class="sf-note">${icon('package', { size: 16 })}<span>Add a note (optional)</span></div>` : ''}`;

  const footer = cart.isEmpty
    ? ''
    : `<div class="sf-cart__footer">
        <div class="sf-totalsrow"><span>Subtotal</span><strong>${money(cart.subtotal)}</strong></div>
        <div class="sf-totalsrow"><span>Delivery Fee</span><strong>${money(cart.deliveryFee)}</strong></div>
        <div class="sf-totalsrow sf-totalsrow--total"><span>Total</span><strong>${money(cart.total)}</strong></div>
        ${brandButton('Proceed to Checkout', tokens, { action: 'checkout', icon: 'chevronRight' })}
      </div>`;

  return `<div class="sf-stage sf-stage--cart">
    ${backBar(`${title} (${cart.itemCount})`)}
    <div class="sf-scroll">${body}</div>
    ${footer}
  </div>`;
}

export function checkoutView(cart, tokens, checkoutState) {
  const deliveryExtra = checkoutState.delivery === 'express' ? 3 : 0;
  const total = cart.subtotal + cart.deliveryFee + deliveryExtra;

  const optionTile = (value, group, title, subtitle, selected) => `
    <button type="button" class="sf-option${selected ? ' is-selected' : ''}" style="${selected ? `border-color:${tokens.primary}` : ''}" data-action="select-${group}" data-value="${esc(value)}" aria-pressed="${selected}">
      <span class="sf-option__check" style="color:${tokens.primary}">${selected ? icon('check', { size: 15 }) : ''}</span>
      <span class="sf-option__text"><strong>${esc(title)}</strong><span>${esc(subtitle)}</span></span>
    </button>`;

  return `<div class="sf-stage sf-stage--checkout">
    ${backBar('Checkout')}
    <div class="sf-scroll">
      <section>
        <h2 class="sf-section">Customer Info</h2>
        <div class="sf-mockfield">${icon('package', { size: 15 })}<span>Full name</span></div>
        <div class="sf-mockfield">${icon('package', { size: 15 })}<span>Phone number</span></div>
        <h2 class="sf-section">Delivery Address</h2>
        <div class="sf-mockfield">${icon('mapPin', { size: 15 })}<span>Delivery address</span></div>
        <h2 class="sf-section">Delivery Option</h2>
        ${optionTile('standard', 'delivery', 'Standard delivery', '30–45 min', checkoutState.delivery === 'standard')}
        ${optionTile('express', 'delivery', 'Express delivery', '15–20 min · +RM 3.00', checkoutState.delivery === 'express')}
        <h2 class="sf-section">Payment Method</h2>
        ${optionTile('cod', 'payment', 'Cash on Delivery', 'Pay when your order arrives', checkoutState.payment === 'cod')}
        ${optionTile('card', 'payment', 'Card', 'Prototype only — no real payment is processed', checkoutState.payment === 'card')}
        <h2 class="sf-section">Order Summary</h2>
        <div class="sf-totalsrow"><span>Subtotal</span><strong>${money(cart.subtotal)}</strong></div>
        <div class="sf-totalsrow"><span>Delivery Fee</span><strong>${money(cart.deliveryFee + deliveryExtra)}</strong></div>
        <div class="sf-totalsrow sf-totalsrow--total"><span>Total</span><strong>${money(total)}</strong></div>
      </section>
    </div>
    <div class="sf-cart__footer">${brandButton('Place Order', tokens, { action: 'place-order' })}</div>
  </div>`;
}

export function orderCreatedView(tokens, orderRef) {
  return `<div class="sf-stage sf-stage--confirmed">
    <div class="sf-confirmed">
      <div class="sf-confirmed__badge" style="background:${tokens.accentBackground};color:${tokens.onPrimary}">${icon('check', { size: 30 })}</div>
      <h1 class="sf-confirmed__title">Order placed!</h1>
      <p class="sf-confirmed__body">Order ${esc(orderRef)} has been created. This is a prototype flow — no real order or payment was processed.</p>
      ${brandButton('Continue Shopping', tokens, { action: 'continue-shopping' })}
    </div>
  </div>`;
}
