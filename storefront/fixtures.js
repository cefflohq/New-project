// CEFFLO Storefront — centralised prototype fixtures.
//
// Mirrors the shape of apps/vendor_mobile/lib/data/storefront_catalog.dart's
// fixture set (id/name/price/categoryId/description/icon/needsCustomization/
// variantGroups/rating/inStock). Deliberately generic — not a real vendor's
// branding or products — so wiring a real per-vendor catalogue later
// replaces `resolveCatalog()` only, never the templates that render it.

export const FIXTURE_VENDOR = Object.freeze({
  id: 'demo-vendor',
  name: 'Your Store',
  tagline: 'A better storefront, made simple.'
});

export const FIXTURE_CATEGORIES = Object.freeze([
  Object.freeze({ id: 'all', label: 'All', icon: 'layoutGrid' }),
  Object.freeze({ id: 'featured', label: 'Featured', icon: 'sparkles' }),
  Object.freeze({ id: 'everyday', label: 'Everyday', icon: 'package' }),
  Object.freeze({ id: 'new', label: 'New', icon: 'badgePlus' })
]);

export const FIXTURE_ITEMS = Object.freeze([
  Object.freeze({
    id: 'fx-1',
    name: 'Signature Item',
    price: 18.9,
    categoryId: 'featured',
    description: 'Your best-selling product goes here.',
    icon: 'star',
    rating: 4.8,
    inStock: true,
    needsCustomization: false,
    variantGroups: []
  }),
  Object.freeze({
    id: 'fx-2',
    name: 'Everyday Essential',
    price: 12.5,
    categoryId: 'everyday',
    description: 'A regularly reordered catalogue item.',
    icon: 'package',
    inStock: true,
    needsCustomization: true,
    variantGroups: [Object.freeze({ label: 'Size', options: ['S', 'M', 'L'] })]
  }),
  Object.freeze({
    id: 'fx-3',
    name: 'New Arrival',
    price: 29.0,
    categoryId: 'new',
    description: 'Freshly added to the catalogue.',
    icon: 'badgePlus',
    rating: 4.6,
    inStock: true,
    needsCustomization: false,
    variantGroups: [Object.freeze({ label: 'Colour', options: ['Natural', 'Charcoal', 'Sand'] })]
  }),
  Object.freeze({
    id: 'fx-4',
    name: 'Popular Pick',
    price: 9.9,
    categoryId: 'everyday',
    description: 'Frequently added to orders.',
    icon: 'flame',
    inStock: true,
    needsCustomization: true,
    variantGroups: []
  }),
  Object.freeze({
    id: 'fx-5',
    name: 'Featured Bundle',
    price: 45.0,
    categoryId: 'featured',
    description: 'A curated set worth highlighting.',
    icon: 'gift',
    rating: 4.9,
    inStock: true,
    needsCustomization: false,
    variantGroups: []
  }),
  Object.freeze({
    id: 'fx-6',
    name: 'Everyday Value',
    price: 6.5,
    categoryId: 'everyday',
    description: 'A low-friction, high-frequency item.',
    icon: 'leaf',
    inStock: true,
    needsCustomization: false,
    variantGroups: []
  })
]);

/**
 * Catalogue adapter seam: today this always resolves to the fixture set
 * regardless of vendorId. A real per-vendor catalogue read (mirroring
 * `storefrontItemsFrom`/`storefrontCategoriesFrom` in storefront_catalog.dart)
 * replaces only this function.
 */
export function resolveCatalog(_vendorId) {
  return { items: FIXTURE_ITEMS, categories: FIXTURE_CATEGORIES };
}
