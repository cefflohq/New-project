import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Spacing per the CEFFLO Experience System (docs/cefflo/sot/
/// 12_EXPERIENCE_SYSTEM.md): 12px gutter, ~13px card padding, 11-12px card
/// gaps, 20px section gaps. Same values as Vendor Mobile's Gap -- one shared
/// spacing language across both Flutter clients.
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

/// Rider-specific addition to the shared Sizes vocabulary: R-flow slide
/// actions need a taller, thumb-reachable target than a normal button
/// (Founder-locked safety rule, docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_
/// MASTER.md S3 -- one-handed operation, no accidental tap fallback).
class Sizes {
  static const chrome = 60.0; // header + bottom nav, excluding safe areas
  static const icon = 22.0; // visual icon size
  static const tapTarget = 44.0; // minimum interactive target
  static const cardRadius = 14.0;
  static const buttonRadius = 999.0; // pill
  static const inputRadius = 14.0;
  static const slideHeight = 64.0; // Critical Slide Action track height
  static const slideKnob = 56.0; // Critical Slide Action knob diameter
}

/// Light Mode only (Founder scope correction, 2026-09-11): Rider Flutter is
/// a new build and ships Light Mode only for now. Dark Mode is HOLD for a
/// later pass -- no CefColors.dark exists here, unlike Vendor Mobile's
/// theme.dart, deliberately.
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

  /// CEFFLO Yellow -- active selection, primary controls, and the Critical
  /// Slide Action knob only. Never body text, never a generic filled
  /// content card, never a permanent background.
  static const accent = Color(0xFFFEC819);
  static const onAccent = Color(0xFF181818);

  /// Navy -- selective raised surface (status/hero cards, auth screens,
  /// the field-execution header per the SOT's "black card" Slide direction
  /// re-expressed as Navy under D-33). Same value as Vendor Mobile's Navy.
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
/// Navy-tinted rather than pure black. Same two layers as Vendor Mobile's
/// cefCardShadow() and the web pilots' --shadow-card-tight/-soft tokens.
List<BoxShadow> cefCardShadow() => const [
  BoxShadow(color: Color(0x0D12213E), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x1412213E), blurRadius: 16, offset: Offset(0, 6), spreadRadius: -4),
];

ThemeData buildRiderTheme() {
  const c = CefColors.light;
  final base = GoogleFonts.manropeTextTheme();
  TextStyle t(double size, FontWeight weight, Color color, {double? spacing}) =>
      base.bodyMedium!.copyWith(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: c.canvas,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: c.border,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CefColors.accent,
      brightness: Brightness.light,
      surface: c.card,
    ),
    extensions: const [c],
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
      // KPI/display 29.
      displaySmall: t(29, FontWeight.w600, c.textPrimary, spacing: -0.8),
    ),
  );
}
