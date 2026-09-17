/// Storefront presentation configuration.
///
/// This is deliberately separate from [Product]/catalogue data (see
/// `storefront_catalog.dart`) and from order data: it only ever describes
/// *how* a storefront looks, never *what* it sells or *what was ordered*.
/// There is no backend for it yet, so it lives as in-memory vendor session
/// state on [AppState] (`activeStorefrontTemplateId` / per-template branding
/// overrides) -- a Storefront configuration adapter boundary rather than a
/// parallel production API.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The rendering engines a Template Library entry can point at. Selecting a
/// template changes layout and flow only -- it never touches
/// product/catalogue or order data. This is intentionally NOT the same
/// concept as "a template a vendor can pick" (see `StorefrontTemplateDef` in
/// `storefront_templates.dart`) -- many library entries can share one
/// renderer, which is exactly what lets the library grow without a new
/// renderer per entry ("reuse business logic, not presentation").
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
  ),
  matchDay(
    key: 'match_day',
    label: 'Match Day',
    tagline: 'Team-kit drop',
    description:
        'Bold, diagonal-split sports-kit storefront: club/team-style '
        'category badges, a swipeable hero product card and a size-run '
        'selector. Best for sportswear, team kits and athletic gear.',
    defaultColor: Color(0xFF17233D),
  ),
  discoverMarket(
    key: 'discover_market',
    label: 'Discover Market',
    tagline: 'Marketplace first',
    description:
        'Clean electronics-marketplace storefront: a promo clearance '
        'banner, pill category filters and a persistent bottom tab bar '
        'with Home, Search, Favorites and Profile. Best for electronics '
        'and gadget retailers.',
    defaultColor: Color(0xFF15A66E),
  ),
  ritualCare(
    key: 'ritual_care',
    label: 'Ritual Care',
    tagline: 'Routine first',
    description:
        'Calm, sage-toned skincare storefront built around one hero '
        'product at a time, with a frosted glass product-detail panel '
        'over a full-bleed photo. Best for skincare and natural care.',
    defaultColor: Color(0xFF4C6B52),
  ),
  bagDrop(
    key: 'bag_drop',
    label: 'Bag Drop',
    tagline: 'Streetwear drop',
    description:
        'High-contrast streetwear storefront: a bold promo drop banner, '
        'square quick-category tiles and a photo-gallery product detail '
        'with an uppercase name and a full-width bag CTA. Best for '
        'streetwear and apparel drops.',
    defaultColor: Color(0xFFE2571C),
  ),
  originRun(
    key: 'origin_run',
    label: 'Origin Run',
    tagline: 'Athletic editorial',
    description:
        'Stark black-and-white athletic-editorial storefront: an italic '
        'wordmark, angled hero shots and a product detail with a '
        'vertical size list, colour-swatch rail and a "Swipe" bag CTA. '
        'Best for sneakers and performance footwear.',
    defaultColor: Color(0xFF14171C),
  ),
  tideTable(
    key: 'tide_table',
    label: 'Tide Table',
    tagline: 'Fresh catch',
    description:
        'Airy seafood/food-delivery storefront: dish photos that break '
        'out of the top of their card, heart/quick-add actions and a '
        'floating dark cart FAB on product detail. Best for seafood, '
        'fresh-food and delivery-led menus.',
    defaultColor: Color(0xFF1F2A24),
  );

  const StorefrontTemplate({
    required this.key,
    required this.label,
    required this.tagline,
    required this.description,
    required this.defaultColor,
  });

  /// Stable identifier, kept for persistence/debugging -- no longer used as
  /// a route entity id (library entries have their own ids for that).
  final String key;
  final String label;
  final String tagline;
  final String description;

  /// The brand colour a fresh (never-customized) storefront on this renderer
  /// starts with, used only as a last-resort fallback.
  final Color defaultColor;

  static StorefrontTemplate fromKey(String? key) =>
      values.firstWhere((t) => t.key == key, orElse: () => browseShop);
}

/// Primary Brand Color mode: a flat colour, or a 2-colour gradient.
enum BrandColorMode { solid, gradient }

/// A named type treatment applied to storefront brand text. The app only
/// bundles the Inter font family (see `core/theme.dart`) -- there is no
/// runtime font download pipeline, so "Font Style" is implemented as
/// distinct Inter-based weight/spacing/case treatments rather than swapping
/// in new font families. This is a deliberate, disclosed constraint (see the
/// implementation report), not a silent simplification of the reference.
enum StorefrontFontTreatment {
  modern('Modern (Inter)', FontWeight.w600, false, -0.2, false),
  bold('Bold (Inter)', FontWeight.w800, false, -0.4, false),
  elegant('Elegant (Inter Italic)', FontWeight.w500, true, 0.1, false),
  classic('Classic (Inter Caps)', FontWeight.w700, false, 1.1, true);

  const StorefrontFontTreatment(
    this.label,
    this.weight,
    this.italic,
    this.letterSpacing,
    this.upperCase,
  );

  final String label;
  final FontWeight weight;
  final bool italic;
  final double letterSpacing;

  /// Whether this treatment renders brand text in upper case (e.g. the
  /// "Classic" wordmark look).
  final bool upperCase;

  TextStyle apply(TextStyle base) => base.copyWith(
    fontWeight: weight,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    letterSpacing: letterSpacing,
  );

  String transform(String s) => upperCase ? s.toUpperCase() : s;
}

/// Vendor-controlled brand identity for one storefront template. Colour
/// fields are deliberately narrow in what they drive (primary CTA, active
/// nav, selected states, links, badges, category selection, hero accents) --
/// see `StorefrontThemeTokens` for the fixed neutrals nothing here ever
/// touches. `storeName`/`tagline`/`logoText`/`font` are the "Branding" tab
/// identity fields from the Customize screen.
@immutable
class StorefrontBranding {
  const StorefrontBranding({
    required this.primary,
    this.secondary,
    this.mode = BrandColorMode.solid,
    this.storeName = '',
    this.tagline = '',
    this.logoText = '',
    this.hasLogo = true,
    this.font = StorefrontFontTreatment.modern,
  });

  final Color primary;

  /// The vendor's Secondary Colour. Also doubles as the gradient's second
  /// stop when [mode] is [BrandColorMode.gradient].
  final Color? secondary;
  final BrandColorMode mode;

  final String storeName;
  final String tagline;

  /// Wordmark text shown in the Store Logo box. Prototype-only -- there is
  /// no image upload pipeline yet, so the "logo" is a styled text mark
  /// (consistent with the initials-avatar pattern used elsewhere in this
  /// app), not an uploaded asset.
  final String logoText;

  /// False after "Remove" -- render a neutral placeholder instead of
  /// [logoText].
  final bool hasLogo;

  final StorefrontFontTreatment font;

  bool get isGradient => mode == BrandColorMode.gradient;

  Color get effectiveSecondary => secondary ?? primary;

  /// Fallback wordmark derived from the store name when [logoText] is blank.
  String get effectiveLogoText =>
      logoText.isNotEmpty ? logoText : storeName.toUpperCase();

  StorefrontBranding copyWith({
    Color? primary,
    Color? secondary,
    BrandColorMode? mode,
    String? storeName,
    String? tagline,
    String? logoText,
    bool? hasLogo,
    StorefrontFontTreatment? font,
    bool clearSecondary = false,
  }) => StorefrontBranding(
    primary: primary ?? this.primary,
    secondary: clearSecondary ? null : (secondary ?? this.secondary),
    mode: mode ?? this.mode,
    storeName: storeName ?? this.storeName,
    tagline: tagline ?? this.tagline,
    logoText: logoText ?? this.logoText,
    hasLogo: hasLogo ?? this.hasLogo,
    font: font ?? this.font,
  );
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

String _hexOf(Color c) =>
    '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

/// Shared hex formatting/parsing helpers so the Customize screen's Primary
/// and Secondary hex fields behave identically.
extension StorefrontColorHex on Color {
  String get hex => _hexOf(this);
}

Color? parseStorefrontHex(String raw) {
  var v = raw.trim();
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length != 6) return null;
  final value = int.tryParse(v, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}
