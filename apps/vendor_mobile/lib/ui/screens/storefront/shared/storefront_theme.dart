/// Theme tokens the storefront preview templates render from.
///
/// Vendor brand colour drives a fixed, narrow set of tokens only (primary
/// CTA, active nav/selected states, links, badges, category selection, hero
/// accents). Page background, surfaces, cards, borders and body typography
/// are neutral constants here and are never touched by [StorefrontBranding]
/// -- this is what keeps a wild vendor colour from breaking legibility.
library;

import 'package:flutter/material.dart';

import '../../../../data/storefront_config.dart';

class StorefrontThemeTokens {
  StorefrontThemeTokens(this.branding, {this.background = surface})
    : onPrimary = accessibleForeground(branding.primary),
      onSecondary = accessibleForeground(branding.effectiveSecondary);

  final StorefrontBranding branding;
  final Color onPrimary;
  final Color onSecondary;

  /// Page background: the template's default treatment, or the vendor's
  /// chosen one (templates with the background capability).
  final Color background;

  /// Vendor hero/banner photo, when the template supports one and the
  /// vendor supplied it.
  ImageProvider? get heroImage =>
      branding.heroImage == null ? null : MemoryImage(branding.heroImage!);

  /// Store name and tagline come from the vendor, never from the template.
  String get storeName => branding.storeName;
  String get tagline => branding.tagline;

  /// Hero headline: the vendor's tagline, else [fallback].
  String headline(String fallback) => tagline.isNotEmpty ? tagline : fallback;

  Color get primary => branding.primary;
  Color get secondary => branding.effectiveSecondary;

  /// Primary CTA / active nav / selected-state fill. Solid colour, or a
  /// 2-stop gradient when the vendor picked Gradient mode.
  Gradient? get accentGradient => branding.isGradient
      ? LinearGradient(colors: [branding.primary, branding.effectiveSecondary])
      : null;

  BoxDecoration accentDecoration({double radius = 0}) => BoxDecoration(
    color: accentGradient == null ? primary : null,
    gradient: accentGradient,
    borderRadius: BorderRadius.circular(radius),
  );

  /// [base] with the vendor's hero photo laid under the banner content
  /// (darkened so white banner text stays legible). Unchanged without one.
  BoxDecoration withHeroImage(BoxDecoration base) {
    final image = heroImage;
    if (image == null) return base;
    return base.copyWith(
      image: DecorationImage(
        image: image,
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: .38),
          BlendMode.darken,
        ),
      ),
    );
  }

  // ---- Fixed neutrals. Never driven by brand colour. ----
  static const Color surface = Color(0xFFF5F6F8);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE7E9EF);
  static const Color textPrimary = Color(0xFF14171C);
  static const Color textSecondary = Color(0xFF6C7280);
  static const Color muted = Color(0xFFF0F1F4);
}
