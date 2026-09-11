import 'package:flutter/material.dart';

/// Spacing per the Founder-approved compact spec: 12px gutter, ~13px card
/// padding, 11-12px card gaps, 20px section gaps.
class Gap {
  static const gutter = 12.0;
  static const cardPadding = 13.0;
  static const cardGap = 11.0;
  static const section = 20.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
}

class Sizes {
  static const chrome = 60.0; // header + bottom nav, excluding safe areas
  static const icon = 22.0; // visual icon size
  static const tapTarget = 44.0; // minimum interactive target
  static const cardRadius = 14.0;
}

class CefColors extends ThemeExtension<CefColors> {
  const CefColors({
    required this.canvas,
    required this.card,
    required this.border,
    required this.chrome,
    required this.textPrimary,
    required this.textLabel,
    required this.textSecondary,
    required this.attention,
    required this.iconColor,
  });

  final Color canvas, card, border, chrome;
  final Color textPrimary, textLabel, textSecondary;
  final Color attention, iconColor;

  /// Signal Lime — active selection, primary controls and selected outline
  /// only. Never body text, never a generic filled content card.
  static const lime = Color(0xFFC7F000);

  static const light = CefColors(
    canvas: Color(0xFFF1F3F6),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFDCE0E5),
    chrome: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF181818),
    textLabel: Color(0xFF242424),
    textSecondary: Color(0xFF454545),
    attention: Color(0xFFC45050),
    iconColor: Color(0xFF242424),
  );

  /// Identical geometry to light; only tokens change. Contrast values are
  /// chosen to stay legible against the dark canvas.
  static const dark = CefColors(
    canvas: Color(0xFF111315),
    card: Color(0xFF1B1E21),
    border: Color(0xFF31363B),
    chrome: Color(0xFF16191C),
    textPrimary: Color(0xFFF4F6F8),
    textLabel: Color(0xFFE2E5E9),
    textSecondary: Color(0xFFAFB6BD),
    attention: Color(0xFFD87878),
    iconColor: Color(0xFFE2E5E9),
  );

  @override
  CefColors copyWith() => this;

  @override
  CefColors lerp(ThemeExtension<CefColors>? other, double t) =>
      other is CefColors && t >= 0.5 ? other : this;
}

extension CefColorsX on BuildContext {
  CefColors get c => Theme.of(this).extension<CefColors>()!;
}

ThemeData buildVendorTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? CefColors.dark : CefColors.light;
  TextStyle t(double size, FontWeight weight, Color color, {double? spacing}) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.canvas,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: c.border,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CefColors.lime,
      brightness: brightness,
      surface: c.card,
    ),
    extensions: [c],
    textTheme: TextTheme(
      // Page/section titles 18/650.
      titleLarge: t(18, FontWeight.w600, c.textPrimary, spacing: -0.2),
      // Card primary 15-16/650.
      titleMedium: t(16, FontWeight.w600, c.textPrimary),
      titleSmall: t(15, FontWeight.w600, c.textPrimary),
      // Supporting 14/500.
      bodyMedium: t(14, FontWeight.w500, c.textSecondary),
      bodySmall: t(13, FontWeight.w500, c.textSecondary),
      labelLarge: t(14, FontWeight.w600, c.textLabel),
      // KPI 29.
      displaySmall: t(29, FontWeight.w600, c.textPrimary, spacing: -0.8),
    ),
  );
}
