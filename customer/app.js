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
  popupTimer: null,
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

// Founder direction (2026-09-29): the approved illustrated layout (big status
// title, rider-on-scooter scene, three-step progress, rider + details cards)
// in the Cefflo palette — blue gradient with Cefflo Yellow accents.

const DASH = '—';
const known = (value) => (value !== undefined && value !== null && value !== '' && value !== DASH ? value : null);

const ILLUSTRATION = {
  [CUSTOMER_STATUS.PICKED_UP]: { src: './assets/order-arriving.webp', alt: 'Your order has been collected' },
  [CUSTOMER_STATUS.ON_THE_WAY]: { src: './assets/rider-on-the-way.webp', alt: 'Your rider on the way' }
};

function topBar(vm) {
  const refresh = hasBackendToken
    ? `<button class="refresh-btn" type="button" data-action="refresh" aria-label="Refresh tracking status">${icon('refresh', { size: 16 })}</button>`
    : '';
  return `
    <div class="topbar">
      <span class="topbar__store">${icon('store', { size: 16 })}<span>${esc(vm.vendor?.name)}</span></span>
      ${refresh}
    </div>`;
}

function hero(vm) {
  const eta = vm.eta
    ? `<div class="hero__eta"><small>${esc(vm.eta.label || 'Estimated arrival')}</small><strong>${esc(vm.eta.valueLabel)}</strong></div>`
    : '';
  const deliveredAt = vm.status === CUSTOMER_STATUS.DELIVERED && known(vm.delivery?.atLabel)
    ? `<div class="hero__eta"><small>Delivered at</small><strong>${esc(vm.delivery.atLabel)}</strong></div>`
    : '';
  return `
    <section class="hero">
      <h1 class="hero__title" id="heroStatus">${esc(vm.statusTitle)}</h1>
      <p class="hero__body">${esc(vm.statusBody)}</p>
      ${eta}${deliveredAt}
    </section>`;
}

function illustration(vm) {
  const art = ILLUSTRATION[vm.status];
  if (!art) return '';
  return `<div class="scene scene--${vm.status}"><img src="${art.src}" alt="${esc(art.alt)}" width="820" height="479"></div>`;
}

/**
 * Exactly three milestones. Done steps are Cefflo blue with a tick; the
 * current step carries the yellow ring. State is also exposed as text so
 * nothing depends on colour alone.
 */
function deliveryProgress(vm) {
  const current = vm.status === CUSTOMER_STATUS.DELIVERED ? -1 : vm.milestones.filter((m) => m.reached).length - 1;
  const steps = vm.milestones.map((milestone, index) => {
    const state = index === current ? 'is-current' : milestone.reached ? 'is-done' : '';
    return `
      <li class="steps__item ${state}">
        <span class="steps__dot">${milestone.reached && index !== current ? icon('check', { size: 15 }) : index + 1}</span>
        <span class="steps__label" aria-hidden="true">${esc(milestone.label)}</span>
        <span class="sr-only">${esc(milestone.label)}: ${milestone.reached ? (index === current ? 'current step' : 'completed') : 'not reached yet'}</span>
      </li>`;
  }).join('');
  const reached = vm.milestones.filter((m) => m.reached).length;
  return `<ol class="steps" style="--fill:${Math.max(0, reached - 1) / (vm.milestones.length - 1)}" aria-label="Delivery progress">${steps}</ol>`;
}

function riderCard(vm) {
  const rider = vm.rider || vm.liveRider;
  if (!rider) return '';
  const initial = esc((rider.name || 'R').trim().charAt(0).toUpperCase() || 'R');
  const meta = [known(rider.vehicle), known(rider.plate)].filter(Boolean).join(' · ') || 'Delivery rider';
  return `
    <section class="rider-card">
      <p class="eyebrow">Your rider</p>
      <div class="rider-card__row">
        ${rider.photo
          ? `<img class="rider-card__avatar" src="${esc(rider.photo)}" alt="${esc(rider.photoAlt || '')}" loading="lazy">`
          : `<span class="rider-card__avatar rider-card__avatar--initial" aria-hidden="true">${initial}</span>`}
        <div class="rider-card__text">
          <strong>${esc(rider.name)}</strong>
          <small>${esc(meta)}</small>
          ${riderLive(rider)}
        </div>
        <div class="contact-actions">
          ${contactAction('call', 'phone', 'Call', rider)}
          ${contactAction('chat', 'chat', 'Chat', rider)}
        </div>
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
  const available = Boolean(rider?.contact?.[kind]?.available);
  if (!available) return '';
  return `
    <button class="contact-btn" type="button" data-action="contact-${kind}"
      aria-label="${esc(label)} ${esc(rider.name)}, your rider">${icon(glyph, { size: 19 })}</button>`;
}

function detailRow(label, value) {
  return known(value) ? `<div class="details__row"><small>${esc(label)}</small><strong>${esc(value)}</strong></div>` : '';
}

function detailsCard(vm) {
  const ref = String(vm.reference ?? '').replace(/^#/, '');
  const rows = [detailRow('From', vm.vendor?.name), detailRow('Pickup address', vm.vendor?.address)];
  if (vm.status === CUSTOMER_STATUS.PICKED_UP) {
    rows.push(detailRow('Picked up at', vm.pickup?.atLabel), detailRow('Items', vm.order?.itemsLabel), detailRow('Note', vm.order?.note));
  }
  if (vm.status === CUSTOMER_STATUS.DELIVERED) {
    rows.push(detailRow('Delivered to', vm.delivery?.address), detailRow('Received by', vm.delivery?.receivedBy));
  }
  return `
    <section class="details">
      <div class="details__head">
        <h2>Delivery Details</h2>
        ${known(ref) ? `<span class="details__ref">Order #<span id="trackingReference">${esc(ref)}</span>
          <button class="ghost-btn" type="button" data-action="copy-reference" aria-label="Copy tracking reference">${icon('copy', { size: 15 })}</button></span>` : ''}
      </div>
      ${rows.join('')}
    </section>`;
}

function podButton(vm) {
  if (!vm.pod) return '';
  return `
    <button class="pod-cta" type="button" data-action="open-pod">
      <span class="pod-cta__thumb">${ui.podImageUrl ? `<img src="${esc(ui.podImageUrl)}" alt="">` : icon('expand', { size: 16 })}</span>
      <span class="pod-cta__text"><strong>Proof of Delivery</strong><small>View the delivery photo</small></span>
      ${icon('chevronRight', { size: 18 })}
    </button>`;
}

/**
 * Five stars are shown immediately — no gate button, no feedback form, no
 * second submit control. Choosing a star IS the submission.
 */
function ratingBlock(vm, ratingState) {
  if (!vm.ratingEligible) return '';
  if (ratingState.submitted) {
    return `
      <section class="rating is-rated" aria-labelledby="ratingTitle">
        <span class="rating__done" aria-hidden="true">${icon('check', { size: 20 })}</span>
        <div>
          <h2 class="rating__title" id="ratingTitle">Thank you</h2>
          <div class="stars stars--readonly" role="img" aria-label="You rated this delivery ${ratingState.value} out of 5 stars">
            ${[1, 2, 3, 4, 5].map((value) => `<span class="star${value <= ratingState.value ? ' is-selected' : ''}">${icon(value <= ratingState.value ? 'starFilled' : 'starOutline', { size: 18 })}</span>`).join('')}
          </div>
        </div>
      </section>`;
  }
  return `
    <section class="rating" aria-labelledby="ratingTitle">
      <h2 class="rating__title" id="ratingTitle">Rate your delivery</h2>
      <p class="rating__hint">How was your experience?</p>
      <div class="stars" id="starGroup" role="group" aria-labelledby="ratingTitle">
        ${[1, 2, 3, 4, 5].map((value) => `
          <button class="star" type="button" data-value="${value}" tabindex="${value === 1 ? '0' : '-1'}"
            aria-label="Rate ${value} out of 5 stars">
            <span class="star__outline">${icon('starOutline', { size: 34 })}</span>
            <span class="star__filled">${icon('starFilled', { size: 34 })}</span>
          </button>`).join('')}
      </div>
    </section>`;
}

function unavailableScreen(vm) {
  return `
    <section class="unavailable${vm.quiet ? ' unavailable--quiet' : ''}">
      ${vm.quiet ? `<span class="unavailable__glyph unavailable__glyph--quiet" aria-hidden="true">${icon('clock', { size: 26 })}</span>` : '<span class="unavailable__glyph" aria-hidden="true">!</span>'}
      <h1 class="hero__title" id="heroStatus">${esc(vm.statusTitle)}</h1>
      <p class="hero__body">${esc(vm.statusBody)}</p>
    </section>`;
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

function trackingScreen(vm, ratingState) {
  if (vm.phase === TRACKING_PHASE.UNAVAILABLE) {
    return `<div class="screen screen--centered">${unavailableScreen(vm)}${poweredByCefflo()}</div>`;
  }
  if (vm.phase === TRACKING_PHASE.LOADING) {
    return `<div class="screen screen--centered">${loadingScreen(vm)}${poweredByCefflo()}</div>`;
  }
  const delivered = vm.status === CUSTOMER_STATUS.DELIVERED;
  return `
    <div class="screen screen--${vm.status}">
      ${topBar(vm)}
      ${hero(vm)}
      ${illustration(vm)}
      ${deliveryProgress(vm)}
      ${riderCard(vm)}
      ${detailsCard(vm)}
      ${delivered ? podButton(vm) + ratingBlock(vm, ratingState) : ''}
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
  sheet.innerHTML = showPod ? podScreen(vm) : trackingScreen(vm, rating.getState());
  sheet.scrollTop = 0;

  if (!prefersReducedMotion()) {
    const screen = sheet.firstElementChild;
    if (screen) {
      screen.classList.add('is-entering');
      requestAnimationFrame(() => requestAnimationFrame(() => screen.classList.remove('is-entering')));
    }
  }
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
  if (action === 'refresh') refreshNow(trigger);
});

/** Token mode only: goes through backend.js's coalescing gate, never around it. */
function refreshNow(trigger) {
  trigger.classList.add('is-spinning');
  setTimeout(() => trigger.classList.remove('is-spinning'), 700);
  window.CEFFLO_CUSTOMER?.refresh?.();
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

/* ---------------------------------------------------------------- rating */

function starButtons() {
  return [...sheet.querySelectorAll('#starGroup .star')];
}

function paintStars(value) {
  starButtons().forEach((button) => {
    button.classList.toggle('is-selected', Number(button.dataset.value) <= value);
  });
}

sheet.addEventListener('pointerdown', (event) => {
  const star = event.target.closest('#starGroup .star');
  if (!star) return;
  ui.ratingPreview = Number(star.dataset.value);
  paintStars(ui.ratingPreview);
});

sheet.addEventListener('pointermove', (event) => {
  if (!ui.ratingPreview) return;
  const group = sheet.querySelector('#starGroup');
  if (!group) return;
  const target = document.elementFromPoint(event.clientX, event.clientY)?.closest?.('#starGroup .star');
  if (!target) return;
  ui.ratingPreview = Number(target.dataset.value);
  paintStars(ui.ratingPreview);
});

sheet.addEventListener('pointerup', (event) => {
  if (!ui.ratingPreview) return;
  const group = sheet.querySelector('#starGroup');
  const target = group && document.elementFromPoint(event.clientX, event.clientY)?.closest?.('#starGroup .star');
  const value = target ? Number(target.dataset.value) : ui.ratingPreview;
  ui.ratingPreview = 0;
  submitRating(value);
});

sheet.addEventListener('pointercancel', () => {
  if (!ui.ratingPreview) return;
  ui.ratingPreview = 0;
  paintStars(0);
});

// Keyboard: arrows move focus and preview, Enter/Space (native click) commits.
sheet.addEventListener('keydown', (event) => {
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

sheet.addEventListener('click', (event) => {
  const star = event.target.closest('#starGroup .star');
  if (star) submitRating(Number(star.dataset.value));
});

async function submitRating(value) {
  const state = rating.getState();
  if (state.submitted || state.pending) return;
  paintStars(value);
  const result = await rating.submit(value);
  if (!result.ok) return;
  render(); // C3 becomes the rated / read-only state.
  openThankYouPopup();
}

/* ------------------------------------------------- C3-R1 Thank You popup */

function openThankYouPopup() {
  const state = rating.getState();
  // Only a rating submitted in this session opens the popup; a reopened or
  // refreshed already-rated C3 never replays it.
  if (!state.justSubmitted) return;
  ui.lastFocused = document.activeElement;

  const node = document.createElement('div');
  node.className = 'popup';
  node.innerHTML = `
    <div class="popup__backdrop"></div>
    <div class="popup__card" role="alertdialog" aria-modal="true" aria-labelledby="popupTitle" aria-describedby="popupBody">
      <button class="popup__close" type="button" aria-label="Close">${icon('close', { size: 20 })}</button>
      <span class="popup__halo" aria-hidden="true">
        <span class="popup__disc">${icon('check', { size: 34 })}</span>
      </span>
      <h2 class="popup__title" id="popupTitle">Thank you!</h2>
      <p class="popup__body" id="popupBody">Thanks for rating your delivery.</p>
    </div>`;
  overlayRoot.appendChild(node);

  const close = () => closeThankYouPopup(node);
  node.querySelector('.popup__close').addEventListener('click', close);
  node.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') close();
    if (event.key === 'Tab') keepFocusInside(event, node);
  });
  node.querySelector('.popup__close').focus({ preventScroll: true });

  // ~3 second dwell, then auto-dismiss back to the C3 rated state.
  ui.popupTimer = setTimeout(close, POPUP_DWELL_MS);
}

function closeThankYouPopup(node) {
  clearTimeout(ui.popupTimer);
  ui.popupTimer = null;
  rating.acknowledgePopup();
  const remove = () => node.remove();
  if (prefersReducedMotion()) remove();
  else {
    node.classList.add('is-leaving');
    setTimeout(remove, 240);
  }
  // Focus returns to C3 — the popup must never trap the customer after it ends.
  const target = sheet.querySelector('.rating') || sheet.querySelector('.screen');
  target?.setAttribute('tabindex', '-1');
  target?.focus({ preventScroll: true });
}

function keepFocusInside(event, node) {
  const focusable = [...node.querySelectorAll('button')];
  if (!focusable.length) return;
  const first = focusable[0];
  const last = focusable[focusable.length - 1];
  if (event.shiftKey && document.activeElement === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
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
