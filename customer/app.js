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
const headerHost = document.getElementById('vendorHeader');
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

/** Vendor theme tokens drive the accent; Cefflo does not own this colour. */
function applyVendorTheme(theme) {
  if (!theme) return;
  const style = document.documentElement.style;
  style.setProperty('--vendor-primary', theme.primary);
  style.setProperty('--vendor-primary-strong', theme.primaryStrong);
  style.setProperty('--vendor-primary-deep', theme.primaryDeep);
  if (theme.headerTop) style.setProperty('--vendor-header-top', theme.headerTop);
  if (theme.headerBottom) style.setProperty('--vendor-header-bottom', theme.headerBottom);
  style.setProperty('--vendor-primary-soft', theme.primarySoft);
  style.setProperty('--vendor-on-primary', theme.onPrimary);
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', theme.headerTop || theme.primaryStrong);
}

/* --------------------------------------------------------------- components */

function vendorHeader(vendor) {
  return `
    <div class="vendor-header__inner">
      <span class="vendor-header__mark" aria-hidden="true">${icon('leaf', { size: 26 })}</span>
      <div class="vendor-header__text">
        <p class="vendor-header__name">${esc(vendor.name)}</p>
        <p class="vendor-header__tagline">${esc(vendor.tagline)}</p>
      </div>
    </div>`;
}

function statusHead(vm) {
  const glyph = {
    [CUSTOMER_STATUS.PICKED_UP]: 'store',
    [CUSTOMER_STATUS.ON_THE_WAY]: 'truck',
    [CUSTOMER_STATUS.DELIVERED]: 'parcel'
  }[vm.status];
  return `
    <div class="status-head">
      <span class="status-head__glyph" aria-hidden="true">${icon(glyph, { size: 34 })}</span>
      <div class="status-head__text">
        <h1 class="status-head__title" id="heroStatus">${esc(vm.statusTitle)}</h1>
        <p class="status-head__body">${esc(vm.statusBody)}</p>
      </div>
    </div>`;
}

/**
 * Exactly three milestones. Every dot carries a tick: reached dots use the
 * semantic success green (--success), future dots are light grey with a darker-grey tick.
 * State is also exposed as text so nothing depends on colour alone.
 */
function deliveryProgress(vm) {
  const parts = [];
  vm.milestones.forEach((milestone, index) => {
    if (index > 0) {
      parts.push(`<span class="progress__bar${milestone.reached ? ' is-reached' : ''}" aria-hidden="true"></span>`);
    }
    parts.push(`
      <span class="progress__step${milestone.reached ? ' is-reached' : ''}">
        <span class="progress__dot">${icon('check', { size: 18 })}</span>
        <span class="progress__label" aria-hidden="true">${esc(milestone.label)}</span>
        <span class="sr-only">${esc(milestone.label)}: ${milestone.reached ? 'completed' : 'not reached yet'}</span>
      </span>`);
  });
  return `<div class="progress" role="group" aria-label="Delivery progress">${parts.join('')}</div>`;
}

function infoRow(label, valueHtml, extraClass = '') {
  return `
    <div class="info-row ${extraClass}">
      <span class="info-row__label">${esc(label)}</span>
      <span class="info-row__value">${valueHtml}</span>
    </div>`;
}

function pickupScreen(vm) {
  return `
    <section class="card">
      <h2 class="card__title">Pickup Details</h2>
      <div class="pickup">
        ${vm.vendor.storefrontPhoto ? `<img class="pickup__thumb" src="${esc(vm.vendor.storefrontPhoto)}" alt="${esc(vm.vendor.storefrontAlt)}" loading="lazy">` : ''}
        <div class="pickup__text">
          <p class="pickup__name">${esc(vm.vendor.name)}</p>
          <p class="pickup__address">${esc(vm.vendor.address)}</p>
        </div>
      </div>
    </section>
    <section class="card card--stacked">
      <h2 class="card__title">Order Information</h2>
      ${infoRow('Tracking ID', `<span class="mono" id="trackingReference">${esc(vm.reference)}</span>
        <button class="ghost-btn" type="button" data-action="copy-reference" aria-label="Copy tracking reference">${icon('copy', { size: 18 })}</button>`, 'info-row--tight')}
      ${infoRow('Items', esc(vm.order.itemsLabel))}
      ${infoRow('Picked Up At', esc(vm.pickup.atLabel))}
      ${infoRow('Note', esc(vm.order.note))}
    </section>`;
}

function onTheWayScreen(vm) {
  const eta = vm.eta
    ? `<div class="map__eta">
         <span class="map__eta-icon" aria-hidden="true">${icon('clock', { size: 22 })}</span>
         <span class="map__eta-text"><small>${esc(vm.eta.label)}</small><strong>${esc(vm.eta.valueLabel)}</strong></span>
       </div>`
    : '';
  // The map block renders only when the view model supplies a route, so a
  // provider without route data degrades to no map instead of a fake one.
  const map = vm.route
    ? `<section class="map" aria-label="Delivery route illustration">
         ${routeMapSvg()}
         ${eta}
       </section>
       ${vm.route.live ? '' : '<p class="map__note">Illustrative route — not a live rider location.</p>'}`
    : '';
  const rider = vm.rider
    ? `<section class="rider">
         <h2 class="card__title">Rider Information</h2>
         <div class="rider__row">
           ${vm.rider.photo ? `<img class="rider__photo" src="${esc(vm.rider.photo)}" alt="${esc(vm.rider.photoAlt)}" loading="lazy">` : ''}
           <div class="rider__text">
             <p class="rider__name">${esc(vm.rider.name)}</p>
             <p class="rider__meta">${esc(vm.rider.vehicle)}</p>
             <p class="rider__meta">${esc(vm.rider.plate)}</p>
           </div>
           <div class="contact-actions">
             ${contactAction('call', 'phone', 'Call', vm.rider)}
             ${contactAction('chat', 'chat', 'Chat', vm.rider)}
           </div>
         </div>
       </section>`
    : '';
  return `${map}${rider}`;
}

function contactAction(kind, glyph, label, rider) {
  const available = Boolean(rider?.contact?.[kind]?.available);
  if (!available) return '';
  return `
    <span class="contact-action">
      <button class="contact-action__btn" type="button" data-action="contact-${kind}"
        aria-label="${esc(label)} ${esc(rider.name)}, your rider">${icon(glyph, { size: 23 })}</button>
      <span class="contact-action__label">${esc(label)}</span>
    </span>`;
}

function deliveredScreen(vm, ratingState) {
  const pod = vm.pod
    ? `<div class="info-row info-row--pod">
         <span class="info-row__label">Proof of Delivery</span>
         <button class="pod-thumb" type="button" data-action="open-pod" aria-label="Open proof of delivery">
           ${ui.podImageUrl
             ? `<img src="${esc(ui.podImageUrl)}" alt="${esc(vm.pod.alt)}">`
             : '<span class="pod-thumb__placeholder" aria-hidden="true"></span>'}
           <span class="pod-thumb__badge" aria-hidden="true">${icon('expand', { size: 15 })}</span>
         </button>
       </div>`
    : '';
  return `
    <section class="card">
      <h2 class="card__title">Delivery Details</h2>
      <div class="destination">
        <span class="destination__glyph" aria-hidden="true">${icon('home', { size: 28 })}</span>
        <p class="destination__address">${esc(vm.delivery.address)}</p>
      </div>
      ${infoRow('Delivered At', esc(vm.delivery.atLabel))}
      ${infoRow('Received By', esc(vm.delivery.receivedBy))}
      ${pod}
    </section>
    ${ratingBlock(vm, ratingState)}`;
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
        <h2 class="rating__title" id="ratingTitle">How was your delivery?</h2>
        <div class="stars stars--readonly" role="img"
          aria-label="You rated this delivery ${ratingState.value} out of 5 stars">
          ${[1, 2, 3, 4, 5].map((value) => `
            <span class="star${value <= ratingState.value ? ' is-selected' : ''}">
              ${icon(value <= ratingState.value ? 'starFilled' : 'starOutline', { size: 34 })}
            </span>`).join('')}
        </div>
        <p class="rating__hint rating__hint--rated">Thanks for your rating</p>
      </section>`;
  }
  return `
    <section class="rating" aria-labelledby="ratingTitle">
      <h2 class="rating__title" id="ratingTitle">How was your delivery?</h2>
      <div class="stars" id="starGroup" role="group" aria-labelledby="ratingTitle">
        ${[1, 2, 3, 4, 5].map((value) => `
          <button class="star" type="button" data-value="${value}" tabindex="${value === 1 ? '0' : '-1'}"
            aria-label="Rate ${value} out of 5 stars">
            <span class="star__outline">${icon('starOutline', { size: 34 })}</span>
            <span class="star__filled">${icon('starFilled', { size: 34 })}</span>
          </button>`).join('')}
      </div>
      <p class="rating__hint">Tap a star to rate your rider and delivery experience.</p>
    </section>`;
}

function unavailableScreen(vm) {
  return `
    <section class="unavailable${vm.quiet ? ' unavailable--quiet' : ''}">
      ${vm.quiet ? '' : '<span class="unavailable__glyph" aria-hidden="true">!</span>'}
      <h1 class="status-head__title" id="heroStatus">${esc(vm.statusTitle)}</h1>
      <p class="status-head__body">${esc(vm.statusBody)}</p>
    </section>`;
}

function loadingScreen(vm) {
  return `
    <section class="unavailable" aria-busy="true">
      <span class="spinner" aria-hidden="true"></span>
      <h1 class="status-head__title" id="heroStatus">${esc(vm.statusTitle)}</h1>
      <p class="status-head__body">${esc(vm.statusBody)}</p>
    </section>`;
}

function poweredByCefflo() {
  return '<footer class="powered">Powered by <strong>Cefflo</strong></footer>';
}

function trackingScreen(vm, ratingState) {
  if (vm.phase === TRACKING_PHASE.UNAVAILABLE) {
    return `<div class="screen">${unavailableScreen(vm)}${poweredByCefflo()}</div>`;
  }
  if (vm.phase === TRACKING_PHASE.LOADING) {
    return `<div class="screen">${loadingScreen(vm)}${poweredByCefflo()}</div>`;
  }
  const body = {
    [CUSTOMER_STATUS.PICKED_UP]: () => pickupScreen(vm),
    [CUSTOMER_STATUS.ON_THE_WAY]: () => onTheWayScreen(vm),
    [CUSTOMER_STATUS.DELIVERED]: () => deliveredScreen(vm, ratingState)
  }[vm.status];
  return `
    <div class="screen screen--${vm.status}">
      ${statusHead(vm)}
      ${deliveryProgress(vm)}
      <div class="screen__body">${body()}</div>
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
  applyVendorTheme(vm.vendor?.theme);
  headerHost.innerHTML = vendorHeader(vm.vendor);

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
});

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
