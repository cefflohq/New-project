// CEFFLO Customer Tracking PWA — application shell and screens.
//
// Screens: C1 Pickup, C2 On the Way, C3 Delivered, C4 Proof of Delivery,
// plus the C3-R1 Thank You popup (a modal over C3, never a separate page).
//
// The UI is state-driven and reads only the customer-safe view model produced
// by tracking-adapter.js. No business truth is hardwired into the markup.

import { TRACKING_FIXTURE } from './fixtures.js';
import {
  CUSTOMER_STATUS,
  TRACKING_PHASE,
  buildLoadingViewModel,
  createMockTrackingProvider,
  installBackendBridge
} from './tracking-adapter.js';
import { createRatingAdapter } from './rating-adapter.js';
import { createPodAdapter } from './pod-adapter.js';
import { icon, routeMapSvg } from './icons.js';

const root = document.getElementById('app');
const sheet = document.getElementById('sheet');
const overlayRoot = document.getElementById('overlayRoot');

const reduceMotionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
const prefersReducedMotion = () => reduceMotionQuery.matches;

const POPUP_DWELL_MS = 3000;

const params = new URLSearchParams(location.search);
const hasBackendToken = Boolean(params.get('token'));

/* ---------------------------------------------------------------- adapters */

const provider = createMockTrackingProvider({
  source: TRACKING_FIXTURE,
  initialStatus: normaliseStatusParam(params.get('state')) ?? CUSTOMER_STATUS.PICKED_UP
});

// In token mode the real caller (customer/backend.js) drives the same store
// through the window.CEFFLOTracking contract it already speaks. Until it
// answers, the screen holds a neutral loading state — never mock fixture data.
if (hasBackendToken) {
  installBackendBridge(provider, { source: TRACKING_FIXTURE, live: true });
  provider.store.set(buildLoadingViewModel());
}

const rating = createRatingAdapter({ reference: TRACKING_FIXTURE.reference });
const podAdapter = createPodAdapter();

// QA/demo helper: `?rated=1` boots straight into the already-rated C3 state.
if (params.get('rated') === '1' && !rating.getState().submitted) {
  rating.submit(Number(params.get('ratedValue')) || 4).then(() => {
    rating.acknowledgePopup();
    render();
  });
}

/* ------------------------------------------------------------------- state */

const ui = {
  view: 'tracking', // 'tracking' | 'pod'
  podImageUrl: null,
  ratingPreview: 0,
  ratingValue: 0,
  ratingByPointer: false,
  sheetState: 'idle', // 'idle' | 'submitting' | 'success' | 'error'
  detailsOpen: false,
  lastFocused: null
};

/* ------------------------------------------------------------------ helpers */

const esc = (value) =>
  String(value ?? '').replace(/[&<>"']/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[char]));

function normaliseStatusParam(value) {
  const allowed = [CUSTOMER_STATUS.PICKED_UP, CUSTOMER_STATUS.ON_THE_WAY, CUSTOMER_STATUS.DELIVERED];
  return allowed.includes(value) ? value : null;
}

/* --------------------------------------------------------------- components */

// Founder-approved Customer Tracking polish (2026-09-29): white page, near-
// black headings, blue for identity/navigation, yellow for the live signal
// and rating, green for completion, red for errors, grey footer.

const DASH = '—';
const known = (value) => (value !== undefined && value !== null && value !== '' && value !== DASH ? value : null);

const PARCEL_ART = `<svg viewBox="0 0 240 150" aria-hidden="true" focusable="false">
  <defs><linearGradient id="bxTop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F3D9AE"/><stop offset="1" stop-color="#E4BF86"/></linearGradient>
  <linearGradient id="bxL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E2B878"/><stop offset="1" stop-color="#D5A65F"/></linearGradient></defs>
  <g fill="#EAF1FF"><ellipse cx="46" cy="72" rx="20" ry="13"/><ellipse cx="62" cy="66" rx="16" ry="14"/><ellipse cx="190" cy="60" rx="18" ry="14"/><ellipse cx="206" cy="66" rx="16" ry="11"/></g>
  <ellipse cx="120" cy="134" rx="70" ry="6" fill="#E3EBF8"/>
  <path d="M84 52 120 40l36 12-36 12z" fill="url(#bxTop)"/>
  <path d="M84 52v58l36 22V64z" fill="url(#bxL)"/>
  <path d="M156 52v58l-36 22V64z" fill="#C99555"/>
  <path d="M104 45.5 140 57.5v14l-8-3v-12L96 44.5z" fill="#fff" opacity=".75"/>
  <circle cx="160" cy="112" r="20" fill="#22A559"/><circle cx="160" cy="112" r="20" fill="none" stroke="#fff" stroke-width="3"/>
  <path d="m151 112 6 6 12-12" fill="none" stroke="#fff" stroke-width="4.2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>`;

const ERROR_ART = `<svg viewBox="0 0 240 150" aria-hidden="true" focusable="false">
  <g fill="#EEF3FB"><ellipse cx="44" cy="80" rx="20" ry="13"/><ellipse cx="60" cy="74" rx="15" ry="13"/><ellipse cx="196" cy="68" rx="17" ry="13"/><ellipse cx="210" cy="74" rx="14" ry="10"/></g>
  <path d="M86 24h52l22 22v82a6 6 0 0 1-6 6H86a6 6 0 0 1-6-6V30a6 6 0 0 1 6-6z" fill="#EDF2FB"/>
  <path d="M138 24v16a6 6 0 0 0 6 6h16z" fill="#DCE5F4"/>
  <circle cx="98" cy="46" r="6" fill="#D6E1F4"/>
  <g stroke="#D3DEF1" stroke-width="7" stroke-linecap="round"><path d="M96 70h44M96 86h40M96 102h30"/></g>
  <circle cx="160" cy="104" r="24" fill="#EF4056"/>
  <path d="M160 92v14" stroke="#fff" stroke-width="5" stroke-linecap="round"/><circle cx="160" cy="116" r="3.2" fill="#fff"/>
</svg>`;

function vendorName(vm) {
  const name = known(vm.vendor?.name);
  // The token-mode placeholder ("Delivery tracking") is not a vendor identity.
  if (!name || name === 'Delivery tracking') return '<div class="vendor-name vendor-name--empty" aria-hidden="true"></div>';
  return `<p class="vendor-name">${esc(name)}</p>`;
}

function statusHead(vm) {
  return `
    <section class="hero">
      <h1 class="hero__title" id="heroStatus">${esc(vm.statusTitle)}</h1>
      <p class="hero__body">${esc(vm.statusBody)}</p>
    </section>`;
}

function etaCard(vm) {
  if (!vm.eta) return '';
  return `
    <div class="fact fact--blue">
      <small>${icon('clock', { size: 16 })}Estimated arrival</small>
      <strong>${esc(vm.eta.valueLabel)}</strong>
    </div>`;
}

function deliveredCard(vm) {
  const at = known(vm.delivery?.atLabel);
  if (!at) return '';
  return `
    <div class="fact fact--green">
      <small><span class="fact__tick">${icon('check', { size: 11 })}</span>Delivered at</small>
      <strong>${esc(at)}</strong>
    </div>`;
}

/**
 * On the Way visual. The prototype (no token) shows the illustrative route
 * and says so; a real order shows the rider scene plus, when the backend has
 * one, the latest authorised rider point as a map link. No map is faked.
 */
function trackingVisual(vm) {
  if (vm.route) {
    return `
      <section class="map" aria-label="Delivery route illustration">
        ${routeMapSvg()}
        ${vm.route.live ? '' : '<span class="map__tag">Illustrative route</span>'}
      </section>`;
  }
  return `<div class="scene scene--on_the_way"><img src="./assets/rider-on-the-way.webp" alt="Your rider on the way" width="820" height="479"></div>`;
}

function visual(vm) {
  if (vm.status === CUSTOMER_STATUS.PICKED_UP) {
    return '<div class="scene"><img src="./assets/order-arriving.webp" alt="Your order has been picked up" width="820" height="479"></div>';
  }
  if (vm.status === CUSTOMER_STATUS.ON_THE_WAY) return trackingVisual(vm);
  return `<div class="scene scene--art">${PARCEL_ART}</div>`;
}

/** One progress component for every state; only the reached flags change. */
function deliveryProgress(vm) {
  const labels = ['Picked Up', 'On the Way', 'Delivered'];
  const reached = vm.milestones.filter((m) => m.reached).length;
  const steps = vm.milestones.map((milestone, index) => `
      <li class="steps__item${milestone.reached ? ' is-reached' : ''}">
        <span class="steps__dot">${milestone.reached ? icon('check', { size: 14 }) : index + 1}</span>
        <span class="steps__label" aria-hidden="true">${esc(labels[index] || milestone.label)}</span>
        <span class="sr-only">${esc(labels[index] || milestone.label)}: ${milestone.reached ? 'completed' : 'not reached yet'}</span>
      </li>`).join('');
  return `<ol class="steps" style="--fill:${Math.max(0, reached - 1) / (vm.milestones.length - 1)}" aria-label="Delivery progress">${steps}</ol>`;
}

function riderCard(vm) {
  const rider = vm.rider || vm.liveRider;
  if (!rider) return '';
  const initial = esc((rider.name || 'R').trim().charAt(0).toUpperCase() || 'R');
  const meta = [known(rider.vehicle), known(rider.plate)].filter(Boolean).join(' · ');
  return `
    <section class="rider-card" aria-label="Your rider">
      ${rider.photo
        ? `<img class="rider-card__avatar" src="${esc(rider.photo)}" alt="${esc(rider.photoAlt || '')}" loading="lazy">`
        : `<span class="rider-card__avatar rider-card__avatar--initial" aria-hidden="true">${initial}</span>`}
      <div class="rider-card__text">
        <strong>${esc(rider.name)}</strong>
        ${meta ? `<small>${esc(meta)}</small>` : ''}
        ${riderLive(rider)}
      </div>
      <div class="contact-actions">
        ${contactAction('call', 'phone', 'Call', rider)}
        ${contactAction('chat', 'chat', 'Message', rider)}
      </div>
    </section>`;
}

/** D-66: truthful last known rider point + stops before this order. */
function riderLive(rider) {
  const parts = [];
  if (Number.isInteger(rider.stopsAhead)) {
    parts.push(`<span class="live-chip">${esc(rider.stopsAhead === 0 ? 'Your delivery is next' : `${rider.stopsAhead} ${rider.stopsAhead === 1 ? 'stop' : 'stops'} before yours`)}</span>`);
  }
  const loc = rider.location;
  if (loc) {
    const mins = Math.max(0, Math.round((Date.now() - new Date(loc.recordedAt).getTime()) / 60000));
    const when = mins < 1 ? 'just now' : `${mins} min ago`;
    parts.push(`<a class="rider__loc" href="https://www.google.com/maps?q=${encodeURIComponent(`${loc.lat},${loc.lng}`)}" target="_blank" rel="noopener">Location updated ${esc(when)}</a>`);
  }
  return parts.length ? `<span class="rider-card__live">${parts.join('')}</span>` : '';
}

function contactAction(kind, glyph, label, rider) {
  if (!rider?.contact?.[kind]?.available) return '';
  return `<button class="contact-btn" type="button" data-action="contact-${kind}"
    aria-label="${esc(label)} ${esc(rider.name)}, your rider">${icon(glyph, { size: 19 })}</button>`;
}

function detailRow(label, value) {
  return known(value) ? `<div class="details__row"><small>${esc(label)}</small><strong>${esc(value)}</strong></div>` : '';
}

/** Collapsed by default; expands in place (no navigation). Customer-relevant fields only. */
function detailsCard(vm) {
  const ref = String(vm.reference ?? '').replace(/^#/, '');
  const rows = [];
  if (known(ref)) {
    rows.push(`<div class="details__row"><small>Order</small><strong class="details__ref">#<span id="trackingReference">${esc(ref)}</span>
      <button class="ghost-btn" type="button" data-action="copy-reference" aria-label="Copy tracking reference">${icon('copy', { size: 15 })}</button></strong></div>`);
  }
  rows.push(detailRow('From', vm.vendor?.name), detailRow('Pickup address', vm.vendor?.address));
  if (vm.status === CUSTOMER_STATUS.PICKED_UP) {
    rows.push(detailRow('Picked up at', vm.pickup?.atLabel), detailRow('Items', vm.order?.itemsLabel), detailRow('Note', vm.order?.note));
  }
  if (vm.status === CUSTOMER_STATUS.DELIVERED) {
    rows.push(detailRow('Delivered to', vm.delivery?.address), detailRow('Received by', vm.delivery?.receivedBy));
    if (vm.pod) {
      rows.push(`<button class="pod-row" type="button" data-action="open-pod">
        <span class="pod-row__thumb">${ui.podImageUrl ? `<img src="${esc(ui.podImageUrl)}" alt="">` : icon('expand', { size: 15 })}</span>
        <span class="pod-row__text"><strong>Proof of Delivery</strong><small>View the delivery photo</small></span>${icon('chevronRight', { size: 18 })}</button>`);
    }
  }
  const open = ui.detailsOpen;
  return `
    <section class="details${open ? ' is-open' : ''}">
      <button class="details__toggle" type="button" data-action="toggle-details" aria-expanded="${open}" aria-controls="detailsBody">
        ${icon('note', { size: 20 })}<span>Delivery details</span><span class="details__chev">${icon('chevronRight', { size: 18 })}</span>
      </button>
      <div class="details__body" id="detailsBody"${open ? '' : ' inert'}><div class="details__inner">${rows.join('')}</div></div>
    </section>`;
}

function unavailableScreen(vm) {
  return `
    <section class="unavailable${vm.quiet ? ' unavailable--quiet' : ''}">
      <h1 class="hero__title" id="heroStatus">${esc(vm.statusTitle)}</h1>
      <p class="hero__body">${esc(vm.statusBody)}</p>
      ${vm.quiet ? '' : `<div class="scene scene--art scene--error">${ERROR_ART}</div>`}
    </section>
    <button class="btn-yellow" type="button" data-action="retry-tracking">${icon('refresh', { size: 19 })}Try Again</button>`;
}

function loadingScreen(vm) {
  return `
    <section class="unavailable" aria-busy="true">
      <span class="spinner" aria-hidden="true"></span>
      <h1 class="hero__title" id="heroStatus">${esc(vm.statusTitle)}</h1>
      <p class="hero__body">${esc(vm.statusBody)}</p>
    </section>`;
}

function poweredByCefflo() {
  return '<footer class="powered">Powered by <strong>Cefflo</strong></footer>';
}

function trackingScreen(vm) {
  if (vm.phase === TRACKING_PHASE.UNAVAILABLE) {
    return `<div class="screen screen--unavailable">${vendorName(vm)}<div class="screen__main">${unavailableScreen(vm)}</div>${poweredByCefflo()}</div>`;
  }
  if (vm.phase === TRACKING_PHASE.LOADING) {
    return `<div class="screen">${vendorName(vm)}<div class="screen__main">${loadingScreen(vm)}</div>${poweredByCefflo()}</div>`;
  }
  const facts = vm.status === CUSTOMER_STATUS.ON_THE_WAY ? etaCard(vm) : vm.status === CUSTOMER_STATUS.DELIVERED ? deliveredCard(vm) : '';
  return `
    <div class="screen screen--${vm.status}${vm.ratingEligible ? ' has-sheet' : ''}">
      ${vendorName(vm)}
      <div class="screen__main">
        ${statusHead(vm)}
        ${facts}
        ${visual(vm)}
        ${deliveryProgress(vm)}
        ${vm.status === CUSTOMER_STATUS.DELIVERED ? '' : riderCard(vm)}
        ${detailsCard(vm)}
      </div>
      ${poweredByCefflo()}
    </div>`;
}

/** C4 — POD detail. Deliberately contains nothing else (no tracking id, no address). */
function podScreen(vm) {
  return `
    <div class="screen screen--pod">
      <div class="pod-head">
        <button class="icon-btn" type="button" data-action="back-to-tracking" aria-label="Back to delivery tracking">
          ${icon('chevronLeft', { size: 24 })}
        </button>
        <h1 class="pod-head__title">Proof of Delivery</h1>
      </div>
      <button class="pod-figure" type="button" data-action="open-fullscreen"
        aria-label="View proof of delivery photo full screen">
        ${ui.podImageUrl
          ? `<img src="${esc(ui.podImageUrl)}" alt="${esc(vm.pod.alt)}">`
          : '<span class="pod-figure__placeholder">Photo unavailable</span>'}
      </button>
      <section class="card pod-meta">
        ${podMetaRow('calendar', 'Delivered at', vm.delivery.atLabel)}
        ${podMetaRow('person', 'Received by', vm.delivery.receivedBy)}
        ${podMetaRow('note', 'Rider note', vm.pod.riderNote)}
      </section>
      ${poweredByCefflo()}
    </div>`;
}

function podMetaRow(glyph, label, value) {
  return `
    <div class="pod-meta__row">
      <span class="pod-meta__icon" aria-hidden="true">${icon(glyph, { size: 21 })}</span>
      <span class="pod-meta__label">${esc(label)}</span>
      <span class="pod-meta__value">${esc(value)}</span>
    </div>`;
}

/* ------------------------------------------------------------------ render */

function render() {
  const vm = provider.store.getState();

  const showPod = ui.view === 'pod' && vm.phase === TRACKING_PHASE.READY && vm.pod;
  sheet.innerHTML = showPod ? podScreen(vm) : trackingScreen(vm);
  sheet.scrollTop = 0;

  if (!prefersReducedMotion()) {
    const screen = sheet.firstElementChild;
    if (screen) {
      screen.classList.add('is-entering');
      requestAnimationFrame(() => requestAnimationFrame(() => screen.classList.remove('is-entering')));
    }
  }
  renderSheet(vm);
  if (vm.pod && !ui.podImageUrl) resolvePod(vm);
}

async function resolvePod(vm) {
  const url = await podAdapter.resolve(vm.pod);
  if (!url || ui.podImageUrl === url) return;
  ui.podImageUrl = url;
  render();
}

/* ------------------------------------------------------------ interactions */

sheet.addEventListener('click', (event) => {
  const trigger = event.target.closest('[data-action]');
  if (!trigger) return;
  const action = trigger.dataset.action;
  if (action === 'copy-reference') copyReference(trigger);
  if (action === 'open-pod') openPod();
  if (action === 'back-to-tracking') closePod();
  if (action === 'open-fullscreen') openFullscreen();
  if (action === 'contact-call') contact('call', trigger);
  if (action === 'contact-chat') contact('chat', trigger);
  if (action === 'toggle-details') toggleDetails(trigger);
  if (action === 'retry-tracking') retryTracking(trigger);
});

/** Smooth in-place expand/collapse; no re-render, no navigation. */
function toggleDetails(trigger) {
  ui.detailsOpen = !ui.detailsOpen;
  const card = trigger.closest('.details');
  card.classList.toggle('is-open', ui.detailsOpen);
  trigger.setAttribute('aria-expanded', String(ui.detailsOpen));
  card.querySelector('.details__body').toggleAttribute('inert', !ui.detailsOpen);
}

/**
 * Try Again reloads the link, which re-runs the one real public_tracking
 * read; nothing about the failure is guessed.
 */
function retryTracking(trigger) {
  trigger.disabled = true;
  trigger.classList.add('is-busy');
  setTimeout(() => location.reload(), prefersReducedMotion() ? 0 : 200);
}

function copyReference(trigger) {
  const value = document.getElementById('trackingReference')?.textContent?.trim();
  if (!value) return;
  navigator.clipboard?.writeText(value).catch(() => {});
  flash(trigger, 'Tracking reference copied');
}

/**
 * Prototype contact behaviour: a real `tel:` link is used only when a fixture
 * number genuinely exists, otherwise a mock acknowledgement. No production
 * messaging provider is connected or claimed.
 */
function contact(kind, trigger) {
  const vm = provider.store.getState();
  const tel = vm.rider?.contact?.call?.tel;
  if (kind === 'call' && tel) {
    location.href = `tel:${tel}`;
    return;
  }
  flash(
    trigger,
    kind === 'call'
      ? 'Calling is simulated in this prototype.'
      : 'Chat is simulated in this prototype.'
  );
}

/** Small, polite, non-blocking confirmation used by prototype-level actions. */
function flash(anchor, message) {
  anchor?.classList.add('is-pressed');
  setTimeout(() => anchor?.classList.remove('is-pressed'), 160);
  let toast = document.getElementById('toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'toast';
    toast.className = 'toast';
    toast.setAttribute('role', 'status');
    toast.setAttribute('aria-live', 'polite');
    overlayRoot.appendChild(toast);
  }
  toast.textContent = message;
  toast.classList.add('is-visible');
  clearTimeout(flash.timer);
  flash.timer = setTimeout(() => toast.classList.remove('is-visible'), 2200);
}

/* ------------------------------------------------------------------ C3 ⇄ C4 */

function openPod() {
  if (ui.view === 'pod') return;
  ui.view = 'pod';
  history.pushState({ view: 'pod' }, '', '#proof-of-delivery');
  render();
  sheet.querySelector('.pod-head .icon-btn')?.focus({ preventScroll: true });
}

function closePod({ fromHistory = false } = {}) {
  if (ui.view !== 'pod') return;
  ui.view = 'tracking';
  if (!fromHistory) history.back();
  else render();
}

window.addEventListener('popstate', () => {
  if (document.querySelector('.fullscreen')) {
    closeFullscreen({ fromHistory: true });
    return;
  }
  const wantsPod = location.hash === '#proof-of-delivery';
  ui.view = wantsPod ? 'pod' : 'tracking';
  render();
});

/* ------------------------------------------------- fullscreen POD viewer */

function openFullscreen() {
  if (!ui.podImageUrl || document.querySelector('.fullscreen')) return;
  const vm = provider.store.getState();
  ui.lastFocused = document.activeElement;
  const node = document.createElement('div');
  node.className = 'fullscreen';
  node.setAttribute('role', 'dialog');
  node.setAttribute('aria-modal', 'true');
  node.setAttribute('aria-label', 'Proof of delivery photo');
  node.innerHTML = `
    <button class="fullscreen__close" type="button" aria-label="Close photo">${icon('close', { size: 22 })}</button>
    <div class="fullscreen__stage">
      <img class="fullscreen__image" src="${esc(ui.podImageUrl)}" alt="${esc(vm.pod.alt)}">
    </div>
    <p class="fullscreen__hint">Pinch or double-tap to zoom</p>`;
  overlayRoot.appendChild(node);
  history.pushState({ view: 'fullscreen' }, '', location.hash || '#proof-of-delivery');
  attachZoom(node.querySelector('.fullscreen__stage'), node.querySelector('.fullscreen__image'));
  node.querySelector('.fullscreen__close').addEventListener('click', () => closeFullscreen());
  node.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') closeFullscreen();
  });
  node.querySelector('.fullscreen__close').focus({ preventScroll: true });
}

function closeFullscreen({ fromHistory = false } = {}) {
  const node = document.querySelector('.fullscreen');
  if (!node) return;
  node.remove();
  if (!fromHistory) history.back();
  ui.lastFocused?.focus?.({ preventScroll: true });
}

/** Modest CSS-transform zoom: double-tap toggle, two-pointer pinch, drag pan. */
function attachZoom(stage, image) {
  let scale = 1;
  let offsetX = 0;
  let offsetY = 0;
  const pointers = new Map();
  let pinchStart = null;
  let panStart = null;

  const apply = () => {
    image.style.transform = `translate(${offsetX}px, ${offsetY}px) scale(${scale})`;
    stage.classList.toggle('is-zoomed', scale > 1.02);
  };
  const clamp = () => {
    scale = Math.min(Math.max(scale, 1), 4);
    if (scale === 1) {
      offsetX = 0;
      offsetY = 0;
    }
  };

  stage.addEventListener('dblclick', () => {
    scale = scale > 1.02 ? 1 : 2.2;
    clamp();
    apply();
  });
  stage.addEventListener('pointerdown', (event) => {
    stage.setPointerCapture(event.pointerId);
    pointers.set(event.pointerId, event);
    if (pointers.size === 2) {
      const [a, b] = [...pointers.values()];
      pinchStart = { distance: Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY), scale };
    } else if (scale > 1.02) {
      panStart = { x: event.clientX - offsetX, y: event.clientY - offsetY };
    }
  });
  stage.addEventListener('pointermove', (event) => {
    if (!pointers.has(event.pointerId)) return;
    pointers.set(event.pointerId, event);
    if (pointers.size === 2 && pinchStart) {
      const [a, b] = [...pointers.values()];
      const distance = Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY);
      scale = pinchStart.scale * (distance / pinchStart.distance);
      clamp();
      apply();
    } else if (panStart && scale > 1.02) {
      offsetX = event.clientX - panStart.x;
      offsetY = event.clientY - panStart.y;
      apply();
    }
  });
  const release = (event) => {
    pointers.delete(event.pointerId);
    if (pointers.size < 2) pinchStart = null;
    if (pointers.size === 0) panStart = null;
  };
  stage.addEventListener('pointerup', release);
  stage.addEventListener('pointercancel', release);
}

/* ------------------------------------------------ rating bottom sheet */

// Delivered only. Choosing a star IS the submission (tap, or drag across the
// stars and release). The same sheet then shows submitting (blue spinner) and,
// only after the server confirmed, success (green check). A failure keeps the
// chosen rating and offers a retry — never a fake success.

function sheetBody(state) {
  if (state === 'submitting') {
    return `<div class="sheet-state" role="status" aria-live="polite">
      <span class="sheet-spinner" aria-hidden="true"></span>
      <h2 class="sheet-title">Thanks for your rating!</h2>
      <p class="sheet-sub">Submitting your feedback…</p></div>`;
  }
  if (state === 'success') {
    return `<div class="sheet-state" role="status" aria-live="polite">
      <span class="sheet-success" aria-hidden="true">${icon('check', { size: 28 })}</span>
      <h2 class="sheet-title">Thank you!</h2>
      <p class="sheet-sub">Your feedback helps us improve our delivery service.</p></div>`;
  }
  const value = state === 'error' ? ui.ratingValue : 0;
  return `<div class="sheet-state">
      <h2 class="sheet-title" id="ratingTitle">Rate your delivery</h2>
      <p class="sheet-sub">How was your experience?</p>
      <div class="stars" id="starGroup" role="group" aria-labelledby="ratingTitle">
        ${[1, 2, 3, 4, 5].map((n) => `
          <button class="star${n <= value ? ' is-selected' : ''}" type="button" data-value="${n}" tabindex="${n === Math.max(1, value) ? '0' : '-1'}" aria-label="Rate ${n} out of 5 stars">
            <span class="star__outline">${icon('starOutline', { size: 38 })}</span>
            <span class="star__filled">${icon('starFilled', { size: 38 })}</span>
          </button>`).join('')}
      </div>
      ${state === 'error' ? `<div class="sheet-error" role="alert"><span>We couldn't save your rating. Please try again.</span>
        <button class="sheet-retry" type="button" data-action="retry-rating">Try again</button></div>` : ''}
    </div>`;
}

function renderSheet(vm) {
  let node = document.getElementById('ratingSheet');
  const wanted = vm.phase === TRACKING_PHASE.READY && vm.ratingEligible && ui.view === 'tracking';
  if (!wanted) { node?.remove(); return; }
  const state = rating.getState().submitted ? 'success' : ui.sheetState;
  if (!node) {
    node = document.createElement('section');
    node.id = 'ratingSheet';
    node.className = 'rate-sheet';
    node.setAttribute('aria-label', 'Rate your delivery');
    node.innerHTML = '<span class="rate-sheet__handle" aria-hidden="true"></span><div class="rate-sheet__body"></div>';
    overlayRoot.appendChild(node);
    requestAnimationFrame(() => requestAnimationFrame(() => node.classList.add('is-open')));
  }
  if (node.dataset.state === state && state !== 'error') return;
  node.dataset.state = state;
  const body = node.querySelector('.rate-sheet__body');
  body.classList.remove('is-swapping');
  void body.offsetWidth;
  body.innerHTML = sheetBody(state);
  body.classList.add('is-swapping');
}

function starButtons() {
  return [...document.querySelectorAll('#starGroup .star')];
}

function paintStars(value) {
  starButtons().forEach((button) => button.classList.toggle('is-selected', Number(button.dataset.value) <= value));
}

const starAt = (event) => document.elementFromPoint(event.clientX, event.clientY)?.closest?.('#starGroup .star');

overlayRoot.addEventListener('pointerdown', (event) => {
  const star = event.target.closest('#starGroup .star');
  if (!star) return;
  event.preventDefault();
  ui.ratingPreview = Number(star.dataset.value);
  paintStars(ui.ratingPreview);
});

window.addEventListener('pointermove', (event) => {
  if (!ui.ratingPreview) return;
  const star = starAt(event);
  if (!star) return;
  ui.ratingPreview = Number(star.dataset.value);
  paintStars(ui.ratingPreview);
});

window.addEventListener('pointerup', (event) => {
  if (!ui.ratingPreview) return;
  const star = starAt(event);
  const value = star ? Number(star.dataset.value) : ui.ratingPreview;
  ui.ratingPreview = 0;
  ui.ratingByPointer = true;
  submitRating(value);
});

window.addEventListener('pointercancel', () => {
  if (!ui.ratingPreview) return;
  ui.ratingPreview = 0;
  paintStars(ui.sheetState === 'error' ? ui.ratingValue : 0);
});

// Keyboard: arrows move focus and preview, Enter/Space (native click) commits.
overlayRoot.addEventListener('keydown', (event) => {
  const star = event.target.closest?.('#starGroup .star');
  if (!star) return;
  const buttons = starButtons();
  const index = buttons.indexOf(star);
  let next = index;
  if (event.key === 'ArrowRight' || event.key === 'ArrowUp') next = Math.min(index + 1, buttons.length - 1);
  else if (event.key === 'ArrowLeft' || event.key === 'ArrowDown') next = Math.max(index - 1, 0);
  else if (event.key === 'Home') next = 0;
  else if (event.key === 'End') next = buttons.length - 1;
  else return;
  event.preventDefault();
  buttons.forEach((button, position) => button.setAttribute('tabindex', position === next ? '0' : '-1'));
  buttons[next].focus();
  paintStars(next + 1);
});

overlayRoot.addEventListener('click', (event) => {
  if (event.target.closest('[data-action="retry-rating"]')) { submitRating(ui.ratingValue); return; }
  const star = event.target.closest('#starGroup .star');
  if (!star) return;
  // A pointer release already submitted; the click that follows is ignored.
  if (ui.ratingByPointer) { ui.ratingByPointer = false; return; }
  submitRating(Number(star.dataset.value));
});

async function submitRating(value) {
  const state = rating.getState();
  if (state.submitted || state.pending || !value) return;
  ui.ratingValue = value;
  paintStars(value);
  await new Promise((resolve) => setTimeout(resolve, prefersReducedMotion() ? 0 : 180)); // let the fill land
  ui.sheetState = 'submitting';
  renderSheet(provider.store.getState());
  const shownAt = Date.now();
  const result = await rating.submit(value);
  // Keep the submitting state readable instead of flashing past it.
  const rest = 650 - (Date.now() - shownAt);
  if (rest > 0 && !prefersReducedMotion()) await new Promise((resolve) => setTimeout(resolve, rest));
  ui.sheetState = result.ok ? 'success' : 'error';
  if (result.ok) rating.acknowledgePopup();
  renderSheet(provider.store.getState());
}

/* ----------------------------------------------- developer state simulator */

/**
 * Developer-only lifecycle simulation. This is NOT a customer control: there is
 * no visible Next/Advance button in the customer UI, and the panel below only
 * renders when the page is opened with `?dev=1`.
 */
window.CEFFLO_CUSTOMER_DEV = Object.freeze({
  status: (status) => provider.applyStatus(status),
  advance: () => provider.advance(),
  fail: (copy) => provider.fail(copy),
  resetRating: () => {
    localStorage.removeItem(`cefflo.customer.rating.v1:${TRACKING_FIXTURE.reference}`);
    location.reload();
  }
});

function mountDevPanel() {
  if (params.get('dev') !== '1') return;
  const panel = document.createElement('div');
  panel.className = 'devbar';
  panel.innerHTML = `
    <span class="devbar__label">Prototype state simulator</span>
    <button type="button" data-status="picked_up">C1</button>
    <button type="button" data-status="on_the_way">C2</button>
    <button type="button" data-status="delivered">C3</button>
    <button type="button" data-dev="reset">Reset rating</button>`;
  panel.addEventListener('click', (event) => {
    const button = event.target.closest('button');
    if (!button) return;
    if (button.dataset.dev === 'reset') window.CEFFLO_CUSTOMER_DEV.resetRating();
    else provider.applyStatus(button.dataset.status);
  });
  overlayRoot.appendChild(panel);
}

/* -------------------------------------------------------------- bootstrap */

provider.store.subscribe(() => {
  // A canonical state change re-renders the tracking experience in place —
  // same shell, no page reload.
  if (ui.view === 'pod' && !provider.store.getState().pod) ui.view = 'tracking';
  render();
});

reduceMotionQuery.addEventListener?.('change', render);
mountDevPanel();
root.dataset.ready = 'true';
