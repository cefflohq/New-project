// CEFFLO Customer Tracking PWA — tracking view-model adapter.
//
//   Tracking UI  <-  tracking view-model/adapter  <-  provider
//                                                     (mock now / Cefflo Core
//                                                      Backend later)
//
// The UI only ever reads the view model produced here. Swapping the mock
// provider for a Core Backend provider must not require a UI rewrite.

import { TRACKING_FIXTURE, STATUS_COPY } from './fixtures.js';

/** Customer-visible delivery states. Exactly three exist. */
export const CUSTOMER_STATUS = Object.freeze({
  PICKED_UP: 'picked_up',
  ON_THE_WAY: 'on_the_way',
  DELIVERED: 'delivered'
});

/** Ordered milestones for the shared three-point progress component. */
export const MILESTONES = Object.freeze([
  { status: CUSTOMER_STATUS.PICKED_UP, label: 'Pickup' },
  { status: CUSTOMER_STATUS.ON_THE_WAY, label: 'On the Way' },
  { status: CUSTOMER_STATUS.DELIVERED, label: 'Delivered' }
]);

/**
 * Non-journey states. "Unavailable" is a reusable exceptional template, not a
 * fourth step of the customer journey (Final Master §13).
 */
export const TRACKING_PHASE = Object.freeze({
  LOADING: 'loading',
  READY: 'ready',
  UNAVAILABLE: 'unavailable'
});

const statusIndex = (status) => MILESTONES.findIndex((milestone) => milestone.status === status);

/**
 * Builds the customer-safe view model the UI renders from.
 * Only customer-permitted fields are projected; nothing internal is carried.
 */
export function buildTrackingViewModel(source, status) {
  const reachedIndex = statusIndex(status);
  const copy = STATUS_COPY[status];
  const delivered = status === CUSTOMER_STATUS.DELIVERED;
  const onTheWay = status === CUSTOMER_STATUS.ON_THE_WAY;
  return Object.freeze({
    phase: TRACKING_PHASE.READY,
    status,
    reference: source.reference,
    vendor: source.vendor,
    statusTitle: copy.title,
    statusBody: copy.body,
    milestones: MILESTONES.map((milestone, index) => ({
      label: milestone.label,
      reached: index <= reachedIndex
    })),
    pickup: source.pickup,
    order: source.order,
    // Map/ETA/rider are only offered while they are meaningful and supplied.
    // A provider that returns no route or no ETA must degrade gracefully
    // rather than have the UI invent one.
    route: onTheWay ? source.route ?? null : null,
    eta: onTheWay ? source.eta ?? null : null,
    rider: onTheWay ? source.rider ?? null : null,
    delivery: delivered ? source.delivery : null,
    pod: delivered && source.pod?.available ? source.pod : null,
    ratingEligible: Boolean(delivered && source.rating?.eligible)
  });
}

/** Reusable customer-safe unavailable view model (no stack traces, no ids). */
export function buildUnavailableViewModel(vendor, { title, body, quiet = false } = {}) {
  return Object.freeze({
    phase: TRACKING_PHASE.UNAVAILABLE,
    vendor: vendor ?? TRACKING_FIXTURE.vendor,
    statusTitle: title || 'Tracking unavailable',
    statusBody: body || 'We could not load this delivery right now. Please check your link and try again.',
    // Neutral pre-pickup state: no warning glyph, light grey title.
    quiet
  });
}

/**
 * Neutral loading state used while a real provider is still fetching.
 * It deliberately shows no vendor identity and no fixture delivery data: a
 * tokenised tracking link must never briefly display another vendor's mock
 * order as if it were the customer's own.
 */
export function buildLoadingViewModel() {
  return Object.freeze({
    phase: TRACKING_PHASE.LOADING,
    vendor: {
      name: 'Delivery tracking',
      tagline: 'Loading your delivery details',
      theme: TRACKING_FIXTURE.vendor.theme
    },
    statusTitle: 'Loading your delivery',
    statusBody: 'One moment while we fetch the latest update.'
  });
}

/**
 * Minimal observable store. The UI subscribes; providers push.
 * (Deliberately tiny — the Master forbids turning this phase into a framework.)
 */
export function createTrackingStore(initial) {
  let state = initial;
  const listeners = new Set();
  return {
    getState: () => state,
    set(next) {
      state = next;
      listeners.forEach((listener) => listener(state));
    },
    subscribe(listener) {
      listeners.add(listener);
      listener(state);
      return () => listeners.delete(listener);
    }
  };
}

/**
 * Mock provider — prototype only.
 *
 * It simulates a valid tracking context locally. It does NOT read delivery
 * truth from URL query parameters in production terms; `initialStatus` is a
 * developer/demo entry point only.
 */
export function createMockTrackingProvider({ source = TRACKING_FIXTURE, initialStatus = CUSTOMER_STATUS.PICKED_UP } = {}) {
  const store = createTrackingStore(buildTrackingViewModel(source, initialStatus));
  return {
    store,
    /** Simulates a canonical delivery state change arriving from the backend. */
    applyStatus(status) {
      if (!statusIndexIsValid(status)) return;
      store.set(buildTrackingViewModel(source, status));
    },
    advance() {
      const current = store.getState();
      const next = MILESTONES[Math.min(statusIndex(current.status) + 1, MILESTONES.length - 1)];
      this.applyStatus(next.status);
    },
    fail(message) {
      store.set(buildUnavailableViewModel(source.vendor, message));
    }
  };
}

function statusIndexIsValid(status) {
  return statusIndex(status) >= 0;
}

/**
 * Backend bridge — the seam the shared Cefflo Core Backend plugs into later.
 *
 * `customer/backend.js` (unchanged, real Supabase caller) already pushes
 * canonical snapshots through `window.CEFFLOTracking.setStatus(status, payload)`.
 * Installing this bridge keeps that contract working against the new UI: raw
 * lifecycle values are mapped onto the three customer-visible states, and any
 * state that is not customer-visible resolves to the safe unavailable template
 * instead of being misrepresented as a delivery milestone.
 */
export function installBackendBridge(provider, { source = TRACKING_FIXTURE } = {}) {
  const map = {
    picked_up: CUSTOMER_STATUS.PICKED_UP,
    on_the_way: CUSTOMER_STATUS.ON_THE_WAY,
    delivered: CUSTOMER_STATUS.DELIVERED
  };
  const unavailableCopy = {
    order_confirmed: { title: 'No order yet', body: 'Tracking starts when your rider collects the order.', quiet: true },
    preparing: { title: 'No order yet', body: 'Tracking starts when your rider collects the order.', quiet: true },
    issue: { title: 'Delivery on hold', body: 'There is an issue with this delivery. The store or rider will be in touch shortly.' },
    cancelled: { title: 'Order cancelled', body: 'This order has been cancelled.' }
  };
  const bridge = Object.freeze({
    STATUS: CUSTOMER_STATUS,
    setStatus(rawStatus, payload = {}) {
      const merged = mergeBackendPayload(source, payload);
      const status = map[rawStatus];
      if (!status) {
        provider.store.set(buildUnavailableViewModel(merged.vendor, unavailableCopy[rawStatus]));
        return;
      }
      provider.store.set(buildTrackingViewModel(merged, status));
    },
    setFreshness() {
      /* The approved reference has no freshness chrome; the contract stays callable. */
    },
    getSnapshot: () => provider.store.getState()
  });
  window.CEFFLOTracking = bridge;
  return bridge;
}

/** Projects a backend snapshot payload onto the customer-safe source shape. */
function mergeBackendPayload(source, payload) {
  return {
    ...source,
    reference: payload.orderId ?? source.reference,
    vendor: { ...source.vendor, name: payload.storeName ?? source.vendor.name },
    eta: payload.estimatedArrival && payload.estimatedArrival !== '—'
      ? { label: 'Estimated Arrival', valueLabel: payload.estimatedArrival }
      : null,
    rider: payload.riderName ? { ...source.rider, name: payload.riderName } : source.rider,
    delivery: {
      ...source.delivery,
      atLabel: payload.deliveredAt && payload.deliveredAt !== '—' ? payload.deliveredAt : source.delivery.atLabel
    },
    pod: payload.podPhoto ? { ...source.pod, available: true, url: payload.podPhoto } : source.pod
  };
}
