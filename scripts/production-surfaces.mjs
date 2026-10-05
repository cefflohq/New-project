// Production domain map (Founder, 2026-10-05; FINAL). One root-served
// artifact per product host. Marketing (cefflo.com / www) stays on the
// existing Vercel deployment and is not part of this map.
//
// kind 'static'  -> packaged from dist/ (scripts/build-static.mjs)
// kind 'flutter' -> a Flutter web build (built separately with production
//                   --dart-defines), packaged as-is.
export const PRODUCTION_SURFACES = Object.freeze({
  vendor: { domain: 'vendor.cefflo.com', kind: 'static', from: 'web', title: 'Owner / Vendor Web' },
  operator: { domain: 'operator.cefflo.com', kind: 'flutter', app: 'vendor', title: 'Operator (Cefflo Vendor app, Operator entry)' },
  helper: { domain: 'helper.cefflo.com', kind: 'flutter', app: 'vendor', title: 'Helper (Cefflo Vendor app, Helper entry)' },
  driver: { domain: 'driver.cefflo.com', kind: 'flutter', app: 'driver', title: 'Driver (Cefflo Driver app)' },
  invite: { domain: 'invite.cefflo.com', kind: 'static', from: 'invite', title: 'Team Invite gateway' },
  tracking: { domain: 'tracking.cefflo.com', kind: 'static', from: 'customer', title: 'Customer Tracking' },
  order: { domain: 'order.cefflo.com', kind: 'static', from: 'store', title: 'Storefront / ordering' },
  foundr: { domain: 'foundr.cefflo.com', kind: 'static', from: 'foundr', title: 'FOUNDR' },
});

// Canonical production base URLs (no internal source paths).
export const PRODUCTION_URLS = Object.freeze({
  CEFFLO_INVITE_BASE_URL: 'https://invite.cefflo.com/',
  CEFFLO_TRACKING_BASE_URL: 'https://tracking.cefflo.com/',
  CEFFLO_STOREFRONT_BASE_URL: 'https://order.cefflo.com/',
  CEFFLO_DRIVER_WEB_URL: 'https://driver.cefflo.com/',
  CEFFLO_OPERATOR_WEB_URL: 'https://operator.cefflo.com/',
  CEFFLO_HELPER_WEB_URL: 'https://helper.cefflo.com/',
});
