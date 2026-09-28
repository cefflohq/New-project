// CEFFLO Customer Tracking PWA — rating adapter.
//
//   Rating UI  <-  rating adapter  <-  local success simulation now
//                                      (server persistence later)
//
// The UI never talks to a rating backend directly. In this phase submission is
// a local simulation with local persistence so the rated state survives a
// refresh; no production rating API is called or claimed.

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
  const stored = readStored(reference);
  let state = {
    submitted: Boolean(stored),
    value: stored?.value ?? 0,
    /** True only for a rating submitted in THIS session (drives the popup). */
    justSubmitted: false,
    pending: false
  };

  return {
    getState: () => ({ ...state }),
    async submit(value) {
      if (state.submitted || state.pending) return { ok: false, reason: 'already-submitted' };
      if (!Number.isInteger(value) || value < 1 || value > 5) return { ok: false, reason: 'invalid' };
      state = { ...state, pending: true, value };
      await new Promise((resolve) => setTimeout(resolve, latencyMs));
      // Optional persistence seam: when the real backend caller is present
      // (customer/backend.js, token mode) the same event it already listens for
      // is emitted. In prototype mode nothing is sent anywhere.
      window.dispatchEvent(new CustomEvent('cefflo:delivery-rated', { detail: { rating: value, feedback: null } }));
      state = { submitted: true, value, justSubmitted: true, pending: false };
      writeStored(reference, { value, at: new Date().toISOString() });
      return { ok: true, value };
    },
    /** Clears the one-shot popup flag so a refresh never replays it. */
    acknowledgePopup() {
      state = { ...state, justSubmitted: false };
    }
  };
}
