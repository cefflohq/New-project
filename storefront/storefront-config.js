// CEFFLO Storefront — theme/config adapter boundary.
//
//   Storefront UI  <-  storefront-config adapter  <-  vendor branding lookup
//                                                      (fixture now / vendor's
//                                                       saved config later)
//
// This mirrors apps/vendor_mobile/lib/data/storefront_config.dart: template
// selection and brand colour are presentation-only, never catalogue/order
// data. There is no backend for it yet, so `loadVendorBranding()` below is
// the ONE seam a later pass swaps for a real per-vendor read (the same
// `{ templateKey, primary, secondary, mode }` shape a vendor's Customize
// Storefront screen would save) — nothing else in the UI has to change.

import { FIXTURE_VENDOR } from './fixtures.js';

export const STOREFRONT_TEMPLATES = Object.freeze({
  browse_shop: Object.freeze({
    key: 'browse_shop',
    label: 'Browse & Shop',
    tagline: 'Discovery first',
    description: 'Conventional retail storefront: browse categories, search, and shop.',
    defaultColor: '#2A6EEC',
    categoryStage: 'category',
    cartTitle: 'Your Cart',
    showCartNote: false
  }),
  quick_order: Object.freeze({
    key: 'quick_order',
    label: 'Quick Order',
    tagline: 'Speed first',
    description: 'Fast, compact ordering with minimal taps and an always-visible order summary.',
    defaultColor: '#7A4A21',
    categoryStage: null,
    cartTitle: 'Your Order',
    showCartNote: true
  }),
  catalogue: Object.freeze({
    key: 'catalogue',
    label: 'Catalogue',
    tagline: 'Visual first',
    description: 'Editorial, collection-led storefront built around large imagery.',
    defaultColor: '#4C2A85',
    categoryStage: 'collection',
    cartTitle: 'Your Cart',
    showCartNote: false
  })
});

export function templateFromKey(key) {
  return STOREFRONT_TEMPLATES[key] || STOREFRONT_TEMPLATES.browse_shop;
}

/* --------------------------------------------------------------- colour */

function hexToRgb(hex) {
  const clean = String(hex || '').replace('#', '').padEnd(6, '0').slice(0, 6);
  return {
    r: parseInt(clean.slice(0, 2), 16) || 0,
    g: parseInt(clean.slice(2, 4), 16) || 0,
    b: parseInt(clean.slice(4, 6), 16) || 0
  };
}

export function hexToRgba(hex, alpha) {
  const { r, g, b } = hexToRgb(hex);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

/**
 * Automatic accessible foreground colour (black/white) for a given
 * background, by WCAG relative-luminance — ports
 * `accessibleForeground()` from storefront_config.dart channel-for-channel.
 * The vendor never picks text colour by hand.
 */
export function accessibleForeground(hex) {
  const { r, g, b } = hexToRgb(hex);
  const linear = (channel) => {
    const c = channel / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  };
  const luminance = 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
  return luminance > 0.55 ? '#14171C' : '#FFFFFF';
}

function isValidHex(value) {
  return typeof value === 'string' && /^#?[0-9a-fA-F]{6}$/.test(value);
}

function normaliseHex(value) {
  const v = value.startsWith('#') ? value : `#${value}`;
  return v.toUpperCase();
}

/**
 * Fixture "vendor-saved branding" lookup — prototype only. A real pass
 * replaces this body with a Supabase read keyed by vendorId; the shape it
 * returns is fixed so nothing downstream (theme tokens, templates) needs to
 * change when that happens.
 */
function loadVendorBranding(vendorId) {
  return {
    vendor: { ...FIXTURE_VENDOR, id: vendorId },
    templateKey: null,
    primary: null,
    secondary: null,
    mode: 'solid'
  };
}

/**
 * Resolves the full storefront session config from the page's
 * URLSearchParams. Without a real vendor id (no `?vendor=`), this degrades
 * to the fixture vendor so the page is always viewable/demoable — the same
 * "never blank on a missing token" rule the Customer Tracking PWA follows.
 *
 * `?color=`, `?secondary=` and `?mode=` are a dev/demo override only: they
 * let the adapter be exercised with a non-default brand colour before a real
 * "vendor saved branding" backend exists, standing in for what the Vendor
 * app's Customize Storefront screen would eventually save.
 */
export function resolveStorefrontConfig(params) {
  const vendorId = params.get('vendor') || FIXTURE_VENDOR.id;
  const saved = loadVendorBranding(vendorId);
  const template = templateFromKey(params.get('template') || saved.templateKey);

  const colorParam = params.get('color');
  const secondaryParam = params.get('secondary');
  const modeParam = params.get('mode');

  const primary = isValidHex(colorParam) ? normaliseHex(colorParam) : saved.primary || template.defaultColor;
  const mode = modeParam === 'gradient' ? 'gradient' : modeParam === 'solid' ? 'solid' : saved.mode || 'solid';
  const secondary = isValidHex(secondaryParam) ? normaliseHex(secondaryParam) : saved.secondary || null;
  const isGradient = mode === 'gradient';
  const effectiveSecondary = isGradient ? secondary || primary : primary;

  const branding = { primary, secondary, mode, isGradient, effectiveSecondary };
  const tokens = Object.freeze({
    primary,
    secondary: effectiveSecondary,
    onPrimary: accessibleForeground(primary),
    onSecondary: accessibleForeground(effectiveSecondary),
    isGradient,
    accentBackground: isGradient
      ? `linear-gradient(135deg, ${primary}, ${effectiveSecondary})`
      : primary
  });

  return { vendorId, vendor: saved.vendor, template, branding, tokens };
}
