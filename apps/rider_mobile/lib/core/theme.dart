import 'package:flutter/material.dart';

/// Spacing derived from the locked Cefflo Driver reference set (D01–D40C).
/// The screen gutter in the references measures ~20 logical px against the
/// 390pt iPhone 13 Pro baseline, card padding ~16, card gaps ~12 and
/// section gaps ~20. The `gutter`/`cardPadding`/`cardGap`/`section` names
/// the existing scaffold already used are kept so nothing downstream has to
/// be renamed.
class Gap {
  static const gutter = 20.0; // screen side padding in every reference
  static const cardPadding = 16.0;
  static const cardGap = 12.0;
  static const section = 20.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// Geometry measured off the reference renders. Every value here exists
/// because a reference shows it, not because it is a round number.
class Sizes {
  static const headerBar = 56.0; // title row height on inner screens
  static const icon = 22.0;
  static const tapTarget = 44.0;

  /// The white surfaces attached to the bottom edge in D02–D12 read ~28
  /// radius on their top corners; list/option cards inside them read ~14–16.
  static const sheetRadius = 28.0;
  static const cardRadius = 16.0;
  static const innerRadius = 12.0;
  // Canonical interactive card shape, matched to the D02 Sign In options.
  static const actionRadius = 16.0;
  static const actionHorizontalPadding = 22.0;
  static const inputRadius = 12.0;
  static const inputHeight = 52.0;
  static const buttonHeight = 56.0;

  /// Critical Slide Action (D21.1/D21.2 Slide to Confirm Route, D22 Slide to
  /// Arrive, D23 Slide to Complete). The knob deliberately overflows the
  /// track vertically, exactly as the references draw it.
  static const slideHeight = 68.0;
  static const slideKnob = 68.0;

  static const bottomNav = 64.0;
}

/// Light Mode only (Founder scope decision). D38 Settings shows an
/// "Appearance" row and that row is reproduced, but no dark theme is built
/// behind it because no reference shows a dark screen.
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

  /// CEFFLO Yellow (D-34 locked token) — primary CTAs, the slide knob, the
  /// active bottom-nav indicator and the step-progress fill. Never body
  /// text, never a generic filled content card.
  static const accent = Color(0xFFFEC819);
  static const onAccent = Color(0xFF12213E);

  /// Navy — auth/header structure, the slide track, headings on white.
  static const navy = Color(0xFF12213E);

  /// The stops sampled off the reference header gradient: bright cobalt in
  /// the top-right corner falling to deep navy at bottom-left.
  static const gradientBright = Color(0xFF0A6BE0);
  static const gradientMid = Color(0xFF01305F);
  static const gradientDeep = Color(0xFF011F3F);

  /// Text sitting directly on the navy gradient.
  static const onNavy = Color(0xFFFFFFFF);
  static const onNavyMuted = Color(0xFFC3D3E8);

  static const light = CefColors(
    canvas: Color(0xFFF5F7FA),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE4E8F0),
    chrome: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF101C33),
    textLabel: Color(0xFF1B2B4B),
    textSecondary: Color(0xFF6B7A94),
    attention: Color(0xFFD73C2B),
    success: Color(0xFF17A34A),
    warning: Color(0xFF9A6700),
    info: Color(0xFF2A6EEC),
    iconColor: Color(0xFF1B2B4B),
  );

  /// Tint surfaces the references use for inset info rows (the pale blue
  /// blocks inside D04/D06/D08/D10/D14 cards).
  static const tintInfo = Color(0xFFEFF4FC);
  static const tintSuccess = Color(0xFFEAF7EF);
  static const tintWarning = Color(0xFFFEF6E2);
  static const tintNeutral = Color(0xFFF4F6FA);

  @override
  CefColors copyWith() => this;

  @override
  CefColors lerp(ThemeExtension<CefColors>? other, double t) =>
      other is CefColors && t >= 0.5 ? other : this;
}

extension CefColorsX on BuildContext {
  CefColors get c => Theme.of(this).extension<CefColors>()!;
  TextTheme get t => Theme.of(this).textTheme;
}

/// The navy header gradient behind every Cefflo Driver screen chrome.
const cefHeaderGradient = LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: [
    CefColors.gradientBright,
    CefColors.gradientMid,
    CefColors.gradientDeep,
  ],
  stops: [0.0, 0.48, 1.0],
);

/// Restrained two-layer navy-tinted shadow — the only elevation the
/// references show on white cards.
List<BoxShadow> cefCardShadow() => const [
  BoxShadow(color: Color(0x0A12213E), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(
    color: Color(0x1412213E),
    blurRadius: 18,
    offset: Offset(0, 8),
    spreadRadius: -8,
  ),
];

/// Softer lift for a white surface that genuinely floats over live content
/// behind it — D22's sheet over the map. Surfaces that are *attached* to the
/// navy header (the auth and navy-sheet scaffolds) take no shadow: there the
/// upward offset only paints a dark line along the join.
List<BoxShadow> cefSheetShadow() => const [
  BoxShadow(
    color: Color(0x1A0A1B33),
    blurRadius: 24,
    offset: Offset(0, -6),
    spreadRadius: -6,
  ),
];

ThemeData buildRiderTheme() {
  const c = CefColors.light;
  TextStyle t(
    double size,
    FontWeight weight,
    Color color, {
    double? spacing,
    double? height,
  }) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: c.canvas,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: c.border,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CefColors.accent,
      brightness: Brightness.light,
      surface: c.card,
      primary: CefColors.navy,
    ),
    extensions: const [c],
    textTheme: TextTheme(
      // Auth display headings — "Welcome Back", "Create your account".
      displayLarge: t(
        32,
        FontWeight.w800,
        CefColors.onNavy,
        spacing: -0.8,
        height: 1.15,
      ),
      displayMedium: t(
        26,
        FontWeight.w800,
        CefColors.onNavy,
        spacing: -0.6,
        height: 1.2,
      ),
      displaySmall: t(22, FontWeight.w800, c.textPrimary, spacing: -0.4),
      // Screen/section titles.
      titleLarge: t(18, FontWeight.w700, c.textPrimary, spacing: -0.2),
      titleMedium: t(16, FontWeight.w700, c.textPrimary),
      titleSmall: t(15, FontWeight.w700, c.textPrimary),
      // Supporting copy.
      bodyLarge: t(15, FontWeight.w500, c.textSecondary, height: 1.4),
      bodyMedium: t(14, FontWeight.w500, c.textSecondary, height: 1.4),
      bodySmall: t(13, FontWeight.w500, c.textSecondary, height: 1.4),
      labelLarge: t(14, FontWeight.w600, c.textLabel),
      labelMedium: t(13, FontWeight.w600, c.textLabel),
      labelSmall: t(12, FontWeight.w600, c.textSecondary),
    ),
  );
}
