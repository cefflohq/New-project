/// Storefront presentation configuration.
///
/// This is deliberately separate from [Product]/catalogue data (see
/// `storefront_catalog.dart`) and from order data: it only ever describes
/// *how* a storefront looks, never *what* it sells or *what was ordered*.
/// There is no backend for it yet, so it lives as in-memory vendor session
/// state on [AppState] (`selectedStorefrontTemplate` /
/// `customStorefrontBranding`) -- a Storefront configuration adapter boundary
/// rather than a parallel production API.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The three storefront presentation templates a vendor can choose between.
/// Selecting a template changes layout and flow only -- it never touches
/// product/catalogue or order data.
enum StorefrontTemplate {
  browseShop(
    key: 'browse_shop',
    label: 'Browse & Shop',
    tagline: 'Discovery first',
    description:
        'Conventional retail storefront: browse categories, search, and '
        'shop. Best for pharmacy, beauty, groceries and general retail.',
    defaultColor: Color(0xFF2A6EEC),
  ),
  quickOrder(
    key: 'quick_order',
    label: 'Quick Order',
    tagline: 'Speed first',
    description:
        'Fast, compact ordering with minimal taps -- quantity steppers, '
        'quick customization and an always-visible order summary. Best for '
        'F&B, cafes and bakeries.',
    defaultColor: Color(0xFF7A4A21),
  ),
  catalogue(
    key: 'catalogue',
    label: 'Catalogue',
    tagline: 'Visual first',
    description:
        'Editorial, collection-led storefront built around large imagery. '
        'Best for furniture, home, florist, gifts and fashion.',
    defaultColor: Color(0xFF4C2A85),
  );

  const StorefrontTemplate({
    required this.key,
    required this.label,
    required this.tagline,
    required this.description,
    required this.defaultColor,
  });

  /// Stable identifier used as the route entity id and for persistence.
  final String key;
  final String label;
  final String tagline;
  final String description;

  /// The brand colour a fresh (never-customized) storefront on this template
  /// starts with, and what "Reset to Template Default" returns to.
  final Color defaultColor;

  static StorefrontTemplate fromKey(String? key) =>
      values.firstWhere((t) => t.key == key, orElse: () => browseShop);
}

/// Primary Brand Color mode: a flat colour, or a 2-colour gradient.
enum BrandColorMode { solid, gradient }

/// Vendor-controlled brand identity. Deliberately narrow: only the tokens the
/// spec allows a vendor colour to drive (primary CTA, active nav, selected
/// states, links, badges, category selection, hero accents). Everything else
/// (page background, cards, borders, body typography) is a fixed neutral
/// defined by [StorefrontThemeTokens], never by this class.
@immutable
class StorefrontBranding {
  const StorefrontBranding({
    required this.primary,
    this.secondary,
    this.mode = BrandColorMode.solid,
  });

  final Color primary;

  /// Only meaningful when [mode] is [BrandColorMode.gradient]; also doubles
  /// as an optional Secondary/Accent colour.
  final Color? secondary;
  final BrandColorMode mode;

  bool get isGradient => mode == BrandColorMode.gradient;

  Color get effectiveSecondary => secondary ?? primary;

  StorefrontBranding copyWith({
    Color? primary,
    Color? secondary,
    BrandColorMode? mode,
    bool clearSecondary = false,
  }) => StorefrontBranding(
    primary: primary ?? this.primary,
    secondary: clearSecondary ? null : (secondary ?? this.secondary),
    mode: mode ?? this.mode,
  );

  static StorefrontBranding defaultFor(StorefrontTemplate t) =>
      StorefrontBranding(primary: t.defaultColor);
}

/// Automatic accessible foreground colour (black/white) for a given
/// background, per WCAG relative-luminance contrast -- never left to the
/// vendor to pick by hand.
Color accessibleForeground(Color background) {
  double linear(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  final luminance =
      0.2126 * linear(background.r) +
      0.7152 * linear(background.g) +
      0.0722 * linear(background.b);
  return luminance > 0.55 ? const Color(0xFF14171C) : Colors.white;
}
