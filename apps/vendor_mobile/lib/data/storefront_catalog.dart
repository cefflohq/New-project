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
    this.icon = LucideIcons.package,
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
  final IconData icon;

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
    name: 'Signature Item',
    price: 18.90,
    categoryId: 'featured',
    description: 'Your best-selling product goes here.',
    icon: LucideIcons.star,
    rating: 4.8,
  ),
  StorefrontItem(
    id: 'fx-2',
    name: 'Everyday Essential',
    price: 12.50,
    categoryId: 'everyday',
    description: 'A regularly reordered catalogue item.',
    icon: LucideIcons.package,
    needsCustomization: true,
    variantGroups: [
      StorefrontVariantGroup('Size', ['S', 'M', 'L']),
    ],
  ),
  StorefrontItem(
    id: 'fx-3',
    name: 'New Arrival',
    price: 29.00,
    categoryId: 'new',
    description: 'Freshly added to the catalogue.',
    icon: LucideIcons.badgePlus,
    rating: 4.6,
    variantGroups: [
      StorefrontVariantGroup('Colour', ['Natural', 'Charcoal', 'Sand']),
    ],
  ),
  StorefrontItem(
    id: 'fx-4',
    name: 'Popular Pick',
    price: 9.90,
    categoryId: 'everyday',
    description: 'Frequently added to orders.',
    icon: LucideIcons.flame,
    needsCustomization: true,
  ),
  StorefrontItem(
    id: 'fx-5',
    name: 'Featured Bundle',
    price: 45.00,
    categoryId: 'featured',
    description: 'A curated set worth highlighting.',
    icon: LucideIcons.gift,
    rating: 4.9,
  ),
  StorefrontItem(
    id: 'fx-6',
    name: 'Everyday Value',
    price: 6.50,
    categoryId: 'everyday',
    description: 'A low-friction, high-frequency item.',
    icon: LucideIcons.leaf,
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
  const icons = [
    LucideIcons.package,
    LucideIcons.star,
    LucideIcons.gift,
    LucideIcons.leaf,
    LucideIcons.flame,
    LucideIcons.badgePlus,
  ];
  return [
    for (final (i, p) in active.indexed)
      StorefrontItem(
        id: p.id,
        name: p.name,
        price: p.displayPrice ?? 0,
        categoryId: p.categoryId ?? _genericCategoryIds[i % _genericCategoryIds.length],
        description: p.description,
        icon: icons[i % icons.length],
        needsCustomization: i.isOdd,
        variantGroups: i % 3 == 0
            ? const [StorefrontVariantGroup('Option', ['Standard', 'Large'])]
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
