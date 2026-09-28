// The canonical CEFFLO static web surfaces (D-62). This list is the single
// source for what the static build publishes. Flutter clients build from
// apps/vendor_mobile and apps/rider_mobile with their own toolchain.
//
// Canonical UI products: Vendor (Mobile + Web/Desktop), Driver (Flutter
// Mobile), Customer Tracking (PWA), Founder (Web/PWA), Invitation (PWA),
// Helper (PWA).
// Public Website: NOT IMPLEMENTED.
export const CANONICAL_SURFACES = Object.freeze({
  vendor: 'Vendor Web/Desktop',
  customer: 'Customer Tracking PWA',
  foundr: 'Founder Web/PWA',
  // Invitation PWA: rider and team (Operator / Helper) invitations (D-72/D-74).
  // The accountless Helper PWA of D-73 is retired: Helpers use Cefflo Vendor.
  invite: 'Invitation PWA',
  // Not a product: kill-switch worker for retired web surfaces.
  retired: 'Retirement worker',
  shared: 'Shared runtime client/config',
});

// Removed surfaces that must never be published again.
export const FORBIDDEN_OUTPUT_DIRS = Object.freeze(['rider', 'marketing', 'previews', 'storefront']);

// The removed Vendor Web/Desktop welcome presentation.
export const OBSOLETE_VENDOR_WELCOME_MARKERS = Object.freeze([
  'id="welcome"',
  'welcome-hero-photo',
  'welcome-actions',
  'showAuthWelcome',
  "switchScreen('welcome')",
  'pressWelcomeButton',
  'welcomeButtonPress',
]);
