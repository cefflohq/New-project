/// Storefront presentation configuration (the vendor's customization of a
/// template -- never the template's layout, never product data).
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
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// The template's own default background treatment.
const kTemplateBackgroundId = 'template';

/// The vendor's own background colour ([StorefrontBranding.customBackground]).
const kCustomBackgroundId = 'custom';

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
    this.backgroundId = kTemplateBackgroundId,
    this.customBackground,
    this.heroImage,
  });

  /// Id of one of the template's own background treatments
  /// (`StorefrontTemplateDef.backgrounds`), or [kCustomBackgroundId].
  final String backgroundId;

  /// The vendor's own background colour when [backgroundId] is
  /// [kCustomBackgroundId].
  final Color? customBackground;

  /// Vendor-supplied hero/banner photo (templates with the hero-image
  /// capability only). In-memory bytes until the storefront has a media
  /// backend.
  final Uint8List? heroImage;

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
    String? backgroundId,
    Color? customBackground,
    Uint8List? heroImage,
    bool clearSecondary = false,
    bool clearHeroImage = false,
  }) => StorefrontBranding(
    primary: primary ?? this.primary,
    secondary: clearSecondary ? null : (secondary ?? this.secondary),
    mode: mode ?? this.mode,
    storeName: storeName ?? this.storeName,
    tagline: tagline ?? this.tagline,
    logoText: logoText ?? this.logoText,
    hasLogo: hasLogo ?? this.hasLogo,
    font: font ?? this.font,
    backgroundId: backgroundId ?? this.backgroundId,
    customBackground: customBackground ?? this.customBackground,
    heroImage: clearHeroImage ? null : (heroImage ?? this.heroImage),
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
