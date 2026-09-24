// CEFFLO Customer Tracking PWA — centralised prototype fixtures.
//
// Every mock value used by the Customer Tracking prototype lives here so that
// wiring the shared Cefflo Core Backend later replaces ONE module (the mock
// provider in tracking-adapter.js) instead of hunting hardcoded demo strings
// across the UI. Nothing in this file is a claim about production data: it is
// explicitly prototype fixture data for the Founder-approved reference vendor
// "Brew & Bite".

/**
 * Vendor theme tokens.
 *
 * Customer Tracking is white-label territory: the vendor owns the customer
 * relationship, so the accent colour is a VENDOR theme token, not a Cefflo
 * brand colour. The blue below is simply the reference vendor's primary; a
 * different vendor can ship a different palette without any UI change.
 */
export const VENDOR_THEME_BREW_AND_BITE = Object.freeze({
  primary: '#06317F',
  primaryStrong: '#06317F',
  primaryDeep: '#002560',
  headerTop: '#03265E',
  headerBottom: '#0788E4',
  primarySoft: '#E8EEF7',
  onPrimary: '#FFFFFF'
});

/** Customer-safe tracking fixture (see the data contract in the Final Master, §11). */
export const TRACKING_FIXTURE = Object.freeze({
  // Public, customer-facing reference only — never an internal database id.
  reference: 'BB250915001',
  vendor: {
    name: 'Brew & Bite',
    tagline: 'Good Food Brings People Together',
    theme: VENDOR_THEME_BREW_AND_BITE,
    storefrontPhoto: './assets/vendor-storefront.jpg',
    storefrontAlt: 'Brew & Bite storefront',
    address: 'No. 12, Jalan Setiawangsa, 54000 Kuala Lumpur'
  },
  order: {
    itemsLabel: '2 parcels',
    note: 'Keep dry. Thank you!'
  },
  pickup: {
    atLabel: 'Today, 10:24 AM'
  },
  // ETA is optional by design. A null `eta` must render a map area with no
  // arrival claim rather than an invented time (Final Master §7 C2).
  eta: {
    label: 'Estimated Arrival',
    valueLabel: 'Today, 11:10 AM'
  },
  // Prototype route illustration only. `live` is false because no permitted,
  // fresh rider location exists in this phase — the UI must never present a
  // fixture position as a real live location.
  route: {
    available: true,
    live: false,
    originLabel: 'Brew & Bite',
    destinationLabel: 'Delivery address'
  },
  rider: {
    name: 'Ahmad',
    photo: './assets/rider-ahmad.jpg',
    photoAlt: 'Photo of Ahmad, your rider',
    vehicle: 'Yamaha Y15ZR',
    plate: 'VJU 3281',
    contact: {
      // No fixture phone number exists for the prototype, so Call resolves to a
      // mock contact action instead of a dead or fabricated `tel:` link.
      call: { available: true, tel: null },
      chat: { available: true }
    }
  },
  delivery: {
    address: 'No. 8, Jalan Melati 3, Taman Seri, 43000 Kajang, Selangor',
    atLabel: 'Today, 11:08 AM',
    receivedBy: 'Nur Aisyah'
  },
  pod: {
    available: true,
    // POD is referenced through the POD adapter, never as a raw private
    // storage path (Final Master §11).
    reference: 'pod-doorstep',
    alt: 'Proof of delivery photo: a Brew & Bite parcel left at the doorstep',
    riderNote: 'Left at doorstep. Have a great day!'
  },
  rating: {
    eligible: true
  }
});

/** Prototype POD asset registry used by the POD adapter. */
export const POD_ASSETS = Object.freeze({
  'pod-doorstep': './assets/pod-doorstep.jpg'
});

/** Customer-safe status copy for each canonical customer-visible state. */
export const STATUS_COPY = Object.freeze({
  picked_up: {
    title: 'Pickup',
    // Customer-facing wording, never first-person rider wording.
    body: 'Your rider has picked up your order.'
  },
  on_the_way: {
    title: 'On the Way',
    body: 'Your order is on the way to you.'
  },
  delivered: {
    title: 'Delivered',
    body: 'Your order has been delivered.'
  }
});
