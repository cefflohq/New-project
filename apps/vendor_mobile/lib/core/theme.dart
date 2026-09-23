import 'package:flutter/material.dart';

/// Primary Latin typeface, bundled locally (see pubspec.yaml `fonts:`) --
/// no runtime font downloading. Weights available: 400/500/600/700/800.
const kFontFamily = 'Inter';

/// Declared on every TextStyle and at the ThemeData level so Simplified
/// Chinese and Tamil glyphs render from bundled fonts (also declared in
/// pubspec.yaml) instead of tofu boxes or a CanvasKit network font fetch.
/// Malay/English text is Latin and is covered by Inter itself.
const kFontFamilyFallback = ['Noto Sans SC', 'Noto Sans Tamil'];

/// Spacing scale: 4 / 8 / 12 / 16 / 20 / 24 / 32. Every gap in the app is one
/// of these steps; the named roles below are aliases onto the scale, never
/// independent values.
class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  static const gutter = xl;
  static const cardPadding = lg;
  static const cardGap = md;
  static const section = xl;
}

/// CEFFLO Experience System v1.3 (docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md,
/// D-33 through D-40). Button shape remains pill; exact card/input radius is
/// baseline evidence pending FG-ENG-03 rather than a global visual lock.
class Sizes {
  static const header = 56.0; // the one gradient header row, every route
  static const nav = 64.0; // bottom navigation, excluding safe area
  static const icon = 22.0; // visual icon size
  static const tapTarget = 44.0; // minimum interactive target
  static const controlHeight = 48.0; // text inputs and search
  static const buttonHeight = 52.0; // primary / secondary / destructive
  static const chipHeight = 36.0; // selectable choice/filter chips
  static const avatar = 40.0; // list-row avatar / icon disc
  static const listRow = 60.0; // list/settings row minimum height
  static const contactAction = 44.0; // outlined Call / WhatsApp circle
  static const cardRadius = 18.0;
  static const surfaceRadius = 24.0; // white surface entering the gradient
  static const buttonRadius = 999.0; // pill
  static const inputRadius = 18.0;
}

/// The one CEFFLO brand gradient: deep blue at the lower left rising to a
/// bright sky blue at the upper right. It paints the app chrome (header
/// band behind the status bar, detail heroes) and every in-body hero
/// surface, so the product has exactly one gradient.
class CefGradients {
  static const brand = LinearGradient(
    begin: Alignment(-1, .6),
    end: Alignment(1, -.6),
    colors: [Color(0xFF0633A8), Color(0xFF0848CC), Color(0xFF0A6BE6)],
    stops: [0, .5, 1],
  );

  /// The cyan glow in the upper right of the brand backdrop, layered over
  /// [brand] by [BrandBackdrop] (never used on its own).
  static const glow = RadialGradient(
    center: Alignment(.85, -1),
    radius: 1.1,
    colors: [Color(0xCC18A6FF), Color(0x0018A6FF)],
  );

  /// Opaque stand-in for the gradient where only one colour can be given
  /// (the browser's theme-color meta).
  static const brandChrome = Color(0xFF0848CC);
}

class CefColors extends ThemeExtension<CefColors> {
  const CefColors({
    required this.canvas,
    required this.card,
    required this.border,
    required this.chrome,
    required this.subtle,
    required this.grouped,
    required this.textPrimary,
    required this.textLabel,
    required this.textSecondary,
    required this.attention,
    required this.success,
    required this.warning,
    required this.info,
    required this.iconColor,
  });

  /// Quiet tinted fill for avatars, icon discs and placeholders.
  final Color canvas, card, border, chrome, subtle;

  /// Cool-white page tone behind grouped settings cards (Menu archetype).
  final Color grouped;
  final Color textPrimary, textLabel, textSecondary;
  final Color attention, success, warning, info, iconColor;

  /// CEFFLO Yellow -- active selection, primary controls and selected
  /// outline only. Never body text, never a generic filled content card.
  /// Formerly Signal Lime (0xFFC7F000), retired per D-33.
  static const accent = Color(0xFFFEC819);
  static const onAccent = Color(0xFF181818);

  /// CEFFLO Blue -- the brand blue of the gradient. Active navigation,
  /// active tab, section icons and inline links (D-45). Distinct from the
  /// semantic Route/Info colour, which stays for route/map semantics.
  static const brand = Color(0xFF0B5FE3);

  /// Light tint of CEFFLO Blue: accent icon discs and tinted action rows.
  static const brandTint = Color(0xFFEAF2FF);

  /// Navy -- selective raised surface (status/hero cards, auth screens) in
  /// Light, and the most-raised anchor tier of the 3-level Dark stack.
  /// Same value in both modes (SOT S3.2).
  static const navy = Color(0xFF12213E);

  static const light = CefColors(
    canvas: Color(0xFFFFFFFF), // Mobile workspace
    card: Color(0xFFFFFFFF), // Surface
    border: Color(0xFFE6E9F0),
    chrome: Color(0xFFFFFFFF),
    subtle: Color(0xFFF0F2F6),
    grouped: Color(0xFFF4F6FA),
    textPrimary: Color(0xFF0F1A36), // dark navy
    textLabel: Color(0xFF1B2540),
    textSecondary: Color(0xFF6B7489), // muted cool grey
    attention: Color(0xFFD73C2B),
    success: Color(0xFF248648),
    warning: Color(0xFF9A6700), // text-on-tint, D-34
    info: Color(0xFF2A6EEC),
    iconColor: Color(0xFF1B2540),
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
    subtle: Color(0xFF242B3D),
    grouped: Color(0xFF0A0B0D),
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
  TextStyle t(double size, FontWeight weight, Color color, {double? spacing}) =>
      TextStyle(
        fontFamily: kFontFamily,
        fontFamilyFallback: kFontFamilyFallback,
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
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFamilyFallback,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CefColors.accent,
      brightness: brightness,
      surface: c.card,
    ),
    extensions: [c],
    // The one text-input treatment. CefField / CefSearchField rely on it, and
    // any bare TextField inherits the same geometry instead of Material's.
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: c.card,
      hintStyle: t(15, FontWeight.w500, c.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIconColor: c.textSecondary,
      suffixIconColor: c.textSecondary,
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      border: _inputBorder(c.border),
      enabledBorder: _inputBorder(c.border),
      disabledBorder: _inputBorder(c.border),
      focusedBorder: _inputBorder(CefColors.accent, width: 1.6),
      errorBorder: _inputBorder(c.attention),
      focusedErrorBorder: _inputBorder(c.attention, width: 1.6),
    ),
    // The one slider treatment (service-area radius and any future slider).
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: CefColors.accent,
      inactiveTrackColor: c.border,
      thumbColor: CefColors.accent,
      overlayColor: CefColors.accent.withValues(alpha: .16),
      tickMarkShape: SliderTickMarkShape.noTickMark,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      trackShape: const RoundedRectSliderTrackShape(),
      showValueIndicator: ShowValueIndicator.never,
    ),
    // One typographic hierarchy for every screen. Screens use these roles;
    // they do not declare their own sizes.
    textTheme: TextTheme(
      // Detail-hero identity (white, on the gradient).
      titleLarge: t(28, FontWeight.w700, c.textPrimary, spacing: -0.7),
      // Header title (white, centred in the gradient header row).
      headlineMedium: t(20, FontWeight.w700, c.textPrimary, spacing: -0.3),
      // Primary content heading inside a page body.
      headlineSmall: t(20, FontWeight.w700, c.textPrimary, spacing: -0.4),
      // Section heading / card title.
      titleMedium: t(18, FontWeight.w700, c.textPrimary, spacing: -0.3),
      // List/settings row title.
      titleSmall: t(16, FontWeight.w600, c.textPrimary, spacing: -0.2),
      // Body / supporting text.
      bodyMedium: t(14, FontWeight.w500, c.textSecondary),
      // Metadata / caption / row subtitle.
      bodySmall: t(14, FontWeight.w500, c.textSecondary),
      // Field labels.
      labelLarge: t(14, FontWeight.w600, c.textLabel),
      // KPI 29. ExtraBold per the locked weight table (major KPI values
      // only) -- matches SummaryMetric's already-w800 dashboard KPI style.
      displaySmall: t(29, FontWeight.w800, c.textPrimary, spacing: -0.8),
    ),
  );
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sizes.inputRadius),
      borderSide: BorderSide(color: color, width: width),
    );
