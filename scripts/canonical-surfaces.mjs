// The canonical CEFFLO static web surfaces (D-62). This list is the single
// source for what the static build publishes. Flutter clients build from
// apps/vendor_mobile and apps/rider_mobile with their own toolchain.
//
// Canonical UI products: Vendor (Mobile + Web/Desktop), Driver (Flutter
// Mobile), Customer Tracking (PWA), Founder (Web/PWA), Invitation (PWA),
// Helper (PWA).
// Public Website: website/index.html, published at the root (dist/index.html).
export const CANONICAL_SURFACES = Object.freeze({
  customer: 'Customer Tracking PWA',
  foundr: 'Founder Web/PWA',
  // Invitation PWA: rider and team (Operator / Helper) invitations (D-72/D-74).
  // The accountless Helper PWA of D-73 is retired: Helpers use Cefflo Vendor.
  invite: 'Invitation PWA',
  // Not a product: kill-switch worker for retired web surfaces.
  retired: 'Retirement worker',
  shared: 'Shared runtime client/config',
  // Public Storefront (Storefront V1): served at {CEFFLO_STOREFRONT_BASE_URL}{slug}.
  store: 'Storefront (public)',
});

// Removed surfaces that must never be published again.
// 'vendor' is the legacy Vendor Web, retired 2026-10-04 for apps/vendor_web (/web/).
export const FORBIDDEN_OUTPUT_DIRS = Object.freeze(['rider', 'marketing', 'previews', 'storefront', 'vendor']);

