// CEFFLO Storefront — session-local cart controller.
//
// Ports StorefrontCartController from storefront_common.dart behaviour-for-
// behaviour. This is preview/prototype state only: there is no payment
// gateway, no real charge, and no order backend behind it. The cart lives
// only for the lifetime of one browser tab session and is never written back
// to canonical order data.

export const DELIVERY_FEE = 6.0;

export function cartKey(itemId, variantSummary) {
  return `${itemId}::${variantSummary || ''}`;
}

export function createCart() {
  const lines = new Map();
  const listeners = new Set();

  function notify() {
    listeners.forEach((listener) => listener());
  }

  const cart = {
    subscribe(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    get lines() {
      return [...lines.values()];
    },
    get itemCount() {
      return [...lines.values()].reduce((sum, line) => sum + line.qty, 0);
    },
    get subtotal() {
      return [...lines.values()].reduce((sum, line) => sum + line.item.price * line.qty, 0);
    },
    get deliveryFee() {
      return lines.size === 0 ? 0 : DELIVERY_FEE;
    },
    get total() {
      return cart.subtotal + cart.deliveryFee;
    },
    get isEmpty() {
      return lines.size === 0;
    },
    qtyOf(item, variantSummary = null) {
      return lines.get(cartKey(item.id, variantSummary))?.qty || 0;
    },
    add(item, { qty = 1, variantSummary = null } = {}) {
      const key = cartKey(item.id, variantSummary);
      const existing = lines.get(key);
      if (existing) existing.qty += qty;
      else lines.set(key, { key, item, qty, variantSummary });
      notify();
    },
    setQty(key, qty) {
      if (qty <= 0) lines.delete(key);
      else if (lines.has(key)) lines.get(key).qty = qty;
      notify();
    },
    remove(key) {
      lines.delete(key);
      notify();
    },
    clear() {
      lines.clear();
      notify();
    }
  };
  return cart;
}

/** Client-side mock order reference — there is no order backend behind this
 * prototype, so nothing here is a real order id. */
export function generateOrderRef() {
  const n = Date.now() % 1000000;
  return `SF-${String(n).padStart(6, '0')}`;
}
