/// Storefront catalogue adapter.
///
/// The Storefront Template screen is presentation only -- it is never where
/// a vendor recreates products. Canonical product data (images, name,
/// description, category, price, stock, status, variants) stays owned by
/// [Product] / `VendorRepository.products`. This file only adapts that
/// canonical shape into the light "shelf item" shape the storefront preview
/// templates render, and -- only when the vendor's real catalogue is empty --
/// falls back to a clearly-isolated fixture set so a template preview always
/// has something representative to show. No parallel backend, no invented
/// persistence.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart' show IconData;

import 'models.dart';

class StorefrontCategory {
  const StorefrontCategory(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

class StorefrontItem {
  const StorefrontItem({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.description,
    this.art = ProductArt.parcel,
    this.needsCustomization = false,
    this.variantGroups = const [],
    this.rating,
    this.inStock = true,
  });

  final String id;
  final String name;
  final num price;
  final String categoryId;
  final String? description;

  /// Illustration drawn for the product until the catalogue carries real
  /// product photos (Product has no image field yet).
  final ProductArt art;

  /// Quick Order template only: whether this item opens a customization step
  /// (size/ice/sugar/add-ons) before it can be added.
  final bool needsCustomization;

  /// Catalogue template only: e.g. Colour -> [Walnut, Oak, Black].
  final List<StorefrontVariantGroup> variantGroups;
  final double? rating;
  final bool inStock;
}

class StorefrontVariantGroup {
  const StorefrontVariantGroup(this.label, this.options);
  final String label;
  final List<String> options;
}

/// Fixture categories, deliberately generic (not pharmacy/cafe/furniture
/// specific) since real templates must render whatever the vendor supplies.
const _fixtureCategories = <StorefrontCategory>[
  StorefrontCategory('all', 'All', LucideIcons.layoutGrid),
  StorefrontCategory('featured', 'Featured', LucideIcons.sparkles),
  StorefrontCategory('everyday', 'Everyday', LucideIcons.package),
  StorefrontCategory('new', 'New', LucideIcons.badgePlus),
];

const _fixtureItems = <StorefrontItem>[
  StorefrontItem(
    id: 'fx-1',
    name: 'Signature Tee',
    price: 59.00,
    categoryId: 'featured',
    description: 'Your best-selling product goes here.',
    art: ProductArt.tee,
    rating: 4.8,
    variantGroups: [
      StorefrontVariantGroup('Size', ['S', 'M', 'L', 'XL']),
    ],
  ),
  StorefrontItem(
    id: 'fx-2',
    name: 'Daily Runner',
    price: 189.00,
    categoryId: 'new',
    description: 'Freshly added to the catalogue.',
    art: ProductArt.sneaker,
    rating: 4.7,
    variantGroups: [
      StorefrontVariantGroup('Size', ['7', '8', '9', '10']),
    ],
  ),
  StorefrontItem(
    id: 'fx-3',
    name: 'Recovery Cream',
    price: 48.90,
    categoryId: 'featured',
    description: 'Light daily cream, 50 ml.',
    art: ProductArt.jar,
    rating: 4.9,
  ),
  StorefrontItem(
    id: 'fx-4',
    name: 'House Latte',
    price: 12.50,
    categoryId: 'everyday',
    description: 'Frequently added to orders.',
    art: ProductArt.cup,
    needsCustomization: true,
  ),
  StorefrontItem(
    id: 'fx-5',
    name: 'Gift Bundle',
    price: 89.00,
    categoryId: 'featured',
    description: 'A curated set worth highlighting.',
    art: ProductArt.gift,
    rating: 4.9,
  ),
  StorefrontItem(
    id: 'fx-6',
    name: 'Harvest Bowl',
    price: 16.90,
    categoryId: 'everyday',
    description: 'A low-friction, high-frequency item.',
    art: ProductArt.bowl,
    needsCustomization: true,
  ),
];

/// Generic category ids assigned (round-robin) to real vendor products that
/// have no `category_id` of their own, so collections/category chips always
/// have real, matching product counts instead of an "All"-only bucket that
/// no collection tile actually points at.
const _genericCategoryIds = ['featured', 'everyday', 'new'];

/// Adapts the vendor's real catalogue when it has products, otherwise falls
/// back to the fixture set above. Never mutated, never duplicated.
List<StorefrontItem> storefrontItemsFrom(List<Product> vendorProducts) {
  final active = vendorProducts.where((p) => p.status != 'archived').toList();
  if (active.isEmpty) return _fixtureItems;
  return [
    for (final (i, p) in active.indexed)
      StorefrontItem(
        id: p.id,
        name: p.name,
        price: p.displayPrice ?? 0,
        categoryId:
            p.categoryId ?? _genericCategoryIds[i % _genericCategoryIds.length],
        description: p.description,
        art: productArtFor(p.name, i),
        needsCustomization: i.isOdd,
        variantGroups: i % 3 == 0
            ? const [
                StorefrontVariantGroup('Option', ['Standard', 'Large']),
              ]
            : const [],
        inStock: p.status == 'active',
      ),
  ];
}

List<StorefrontCategory> storefrontCategoriesFrom(List<StorefrontItem> items) {
  if (items.isEmpty) return _fixtureCategories;
  final ids = {for (final i in items) i.categoryId}..remove('all');
  if (ids.isEmpty) return _fixtureCategories;
  StorefrontCategory labelled(String id) => _fixtureCategories.firstWhere(
    (c) => c.id == id,
    orElse: () => StorefrontCategory(id, _titleCase(id), LucideIcons.tag),
  );
  return [
    const StorefrontCategory('all', 'All', LucideIcons.layoutGrid),
    for (final id in ids) labelled(id),
  ];
}

String _titleCase(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[_-]'), ' ').trim();
  if (cleaned.isEmpty) return raw;
  return cleaned
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Illustration families for product imagery. Neutral, brand-free drawings
/// (see `ui/screens/storefront/shared/product_art.dart`).
enum ProductArt {
  tee,
  sneaker,
  jar,
  bottle,
  cup,
  bowl,
  cake,
  pastry,
  bag,
  gift,
  parcel,
}

const _artKeywords = <ProductArt, List<String>>{
  ProductArt.cup: [
    'latte',
    'coffee',
    'kopi',
    'tea',
    'teh',
    'matcha',
    'drink',
    'juice',
    'milk',
    'mocha',
    'cappuccino',
  ],
  ProductArt.cake: ['cake', 'kek', 'brownie', 'tart', 'cheesecake', 'dessert'],
  ProductArt.pastry: [
    'croissant',
    'bread',
    'roti',
    'bun',
    'pastry',
    'bagel',
    'donut',
    'cookie',
  ],
  ProductArt.bowl: [
    'rice',
    'nasi',
    'noodle',
    'mee',
    'salad',
    'bowl',
    'soup',
    'meal',
    'prawn',
    'fish',
  ],
  ProductArt.tee: [
    'shirt',
    'tee',
    'jersey',
    'kit',
    'hoodie',
    'baju',
    'jacket',
    'dress',
  ],
  ProductArt.sneaker: ['shoe', 'sneaker', 'kasut', 'runner', 'boot'],
  ProductArt.jar: ['cream', 'balm', 'mask', 'scrub', 'jar'],
  ProductArt.bottle: [
    'serum',
    'oil',
    'bottle',
    'perfume',
    'toner',
    'lotion',
    'shampoo',
  ],
  ProductArt.bag: ['bag', 'beg', 'tote', 'backpack', 'pouch'],
  ProductArt.gift: [
    'gift',
    'hamper',
    'bundle',
    'set',
    'box',
    'flower',
    'bouquet',
  ],
};

/// Best-guess illustration for a vendor product from its name; a stable
/// rotation when nothing matches.
ProductArt productArtFor(String name, int index) {
  final n = name.toLowerCase();
  for (final e in _artKeywords.entries) {
    if (e.value.any(n.contains)) return e.key;
  }
  const fallback = [
    ProductArt.parcel,
    ProductArt.gift,
    ProductArt.bag,
    ProductArt.jar,
  ];
  return fallback[index % fallback.length];
}
