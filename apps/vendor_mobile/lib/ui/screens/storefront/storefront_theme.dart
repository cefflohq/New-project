/// Theme tokens the storefront preview templates render from.
///
/// Vendor brand colour drives a fixed, narrow set of tokens only (primary
/// CTA, active nav/selected states, links, badges, category selection, hero
/// accents). Page background, surfaces, cards, borders and body typography
/// are neutral constants here and are never touched by [StorefrontBranding]
/// -- this is what keeps a wild vendor colour from breaking legibility.
library;

import 'package:flutter/material.dart';

import '../../../data/storefront_config.dart';

class StorefrontThemeTokens {
  StorefrontThemeTokens(this.branding)
    : onPrimary = accessibleForeground(branding.primary),
      onSecondary = accessibleForeground(branding.effectiveSecondary);

  final StorefrontBranding branding;
  final Color onPrimary;
  final Color onSecondary;

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

  // ---- Fixed neutrals. Never driven by brand colour. ----
  static const Color surface = Color(0xFFF5F6F8);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE7E9EF);
  static const Color textPrimary = Color(0xFF14171C);
  static const Color textSecondary = Color(0xFF6C7280);
  static const Color muted = Color(0xFFF0F1F4);
}
