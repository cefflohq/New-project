// CEFFLO Customer Tracking PWA — rating adapter.
//
//   Rating UI  <-  rating adapter  <-  submit_rating (token mode, via
//                                      customer/backend.js) / local simulation
//                                      (prototype mode, no token)
//
// The UI never talks to a rating backend directly. Success is reported only
// after the server confirmed the rating (token mode).

const STORAGE_PREFIX = 'cefflo.customer.rating.v1:';

function storageKey(reference) {
  return `${STORAGE_PREFIX}${reference}`;
}

function readStored(reference) {
  try {
    const raw = localStorage.getItem(storageKey(reference));
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    return typeof parsed?.value === 'number' ? parsed : null;
  } catch {
    return null;
  }
}

function writeStored(reference, record) {
  try {
    localStorage.setItem(storageKey(reference), JSON.stringify(record));
  } catch {
    /* Private-mode storage failures must never block the rated UI state. */
  }
}

/**
 * Creates the rating adapter for one tracking reference.
 *
 * `submit` resolves only on a successful (simulated) submission — the Thank You
 * popup is allowed to appear only after that resolution, exactly as a real
 * server round trip would behave.
 */
export function createRatingAdapter({ reference, latencyMs = 260 } = {}) {
  // `reference` may be a function: a live order's reference is known only
  // once public_tracking answers, and each order keeps its own local record.
  const refOf = typeof reference === 'function' ? reference : () => reference;
  let state = {
    submitted: false,
    value: 0,
    /** True only for a rating submitted in THIS session (drives the popup). */
    justSubmitted: false,
    pending: false
  };
  const syncStored = () => {
    const stored = readStored(refOf());
    if (stored && !state.submitted) state = { ...state, submitted: true, value: stored.value };
  };

  return {
    getState: () => {
      syncStored();
      return { ...state };
    },
    async submit(value) {
      syncStored();
      if (state.submitted || state.pending) return { ok: false, reason: 'already-submitted' };
      if (!Number.isInteger(value) || value < 1 || value > 5) return { ok: false, reason: 'invalid' };
      state = { ...state, pending: true, value };
      // Token mode: the real submit_rating call (customer/backend.js) must
      // confirm before the UI may show success. A failure keeps the chosen
      // value and allows a retry; nothing is marked as rated.
      const persist = window.CEFFLO_CUSTOMER?.submitRating;
      try {
        if (persist) await persist(value, null);
        else await new Promise((resolve) => setTimeout(resolve, latencyMs)); // prototype only
      } catch (error) {
        // The server already holds a rating for this order (e.g. another
        // device): that is a settled state, not a customer-facing error.
        if (/already submitted/i.test(String(error?.message ?? error))) {
          state = { ...state, submitted: true, pending: false };
          return { ok: false, reason: 'already-submitted' };
        }
        state = { ...state, pending: false };
        return { ok: false, reason: 'failed', error };
      }
      state = { submitted: true, value, justSubmitted: true, pending: false };
      writeStored(refOf(), { value, at: new Date().toISOString() });
      return { ok: true, value };
    },
    /** Clears the one-shot popup flag so a refresh never replays it. */
    acknowledgePopup() {
      state = { ...state, justSubmitted: false };
    }
  };
}
