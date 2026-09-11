import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// CEFFLO Experience System v1.1 (docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md,
/// D-33/D-34). cardRadius already matched the locked 14px card radius before
/// this reconciliation; buttonRadius/inputRadius are new here, replacing
/// widgets.dart's previously hardcoded 12px on both.
class Sizes {
  static const chrome = 60.0; // header + bottom nav, excluding safe areas
  static const icon = 22.0; // visual icon size
  static const tapTarget = 44.0; // minimum interactive target
  static const cardRadius = 14.0;
  static const buttonRadius = 999.0; // pill
  static const inputRadius = 14.0;
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
    required this.success,
    required this.warning,
    required this.info,
    required this.iconColor,
  });

  final Color canvas, card, border, chrome;
  final Color textPrimary, textLabel, textSecondary;
  final Color attention, success, warning, info, iconColor;

  /// CEFFLO Yellow -- active selection, primary controls and selected
  /// outline only. Never body text, never a generic filled content card.
  /// Formerly Signal Lime (0xFFC7F000), retired per D-33.
  static const accent = Color(0xFFFEC819);
  static const onAccent = Color(0xFF181818);

  /// Navy -- selective raised surface (status/hero cards, auth screens) in
  /// Light, and the most-raised anchor tier of the 3-level Dark stack.
  /// Same value in both modes (SOT S3.2).
  static const navy = Color(0xFF12213E);

  static const light = CefColors(
    canvas: Color(0xFFF7F8FA), // Workspace
    card: Color(0xFFFFFFFF), // Surface
    border: Color(0xFFE3E6EE),
    chrome: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF181818),
    textLabel: Color(0xFF242424),
    textSecondary: Color(0xFF666C80),
    attention: Color(0xFFD73C2B),
    success: Color(0xFF248648),
    warning: Color(0xFF9A6700), // text-on-tint, D-34
    info: Color(0xFF2A6EEC),
    iconColor: Color(0xFF242424),
  );

  /// Dark Canvas -> Dark/Tinted Surface -> Navy raised anchor (SOT S3.2).
  /// Semantic colours are hue-preserving lightened variants of the Light
  /// values, each verified >=4.5:1 against `card` (the dark surface).
  /// `warning` reuses D-34's dark text-on-tint value directly rather than
  /// recomputing one, since that value was itself adopted from this app's
  /// own sibling Rider Web dark mode.
  static const dark = CefColors(
    canvas: Color(0xFF0A0B0D),
    card: Color(0xFF1A2030),
    border: Color(0xFF2C2F3A),
    chrome: Color(0xFF1A2030),
    textPrimary: Color(0xFFF4F6F8),
    textLabel: Color(0xFFE2E5E9),
    textSecondary: Color(0xFFAFB6BD),
    attention: Color(0xFFDF6153),
    success: Color(0xFF2BA156),
    warning: Color(0xFFF5A524), // text-on-tint, D-34
    info: Color(0xFF4D86EF),
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

/// SOT S5A: restrained border + subtle two-layer soft shadow, both
/// Navy-tinted rather than pure black. Same two layers used by the Invite
/// and Marketing Prelaunch web pilots' --shadow-card-tight/-soft tokens.
List<BoxShadow> cefCardShadow(Brightness brightness) {
  if (brightness == Brightness.dark) return const [];
  return const [
    BoxShadow(color: Color(0x0D12213E), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x1412213E),
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: -4,
    ),
  ];
}

ThemeData buildVendorTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? CefColors.dark : CefColors.light;
  final base = GoogleFonts.manropeTextTheme();
  TextStyle t(double size, FontWeight weight, Color color, {double? spacing}) =>
      base.bodyMedium!.copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.canvas,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: c.border,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CefColors.accent,
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
