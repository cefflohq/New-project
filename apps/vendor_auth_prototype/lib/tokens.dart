/// CEFFLO Experience System tokens, as the locked Vendor Auth boards use them.
///
/// Light Mode only — Dark Mode is HOLD and is deliberately absent. Every
/// colour is written out explicitly rather than read from a theme, so a
/// screen renders identically no matter what theme mode wraps it.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ------------------------------------------------------------------ colour

/// Navy anchor from the board swatch (#12213E). The two companions are
/// shades of that same anchor used by the backdrop gradient, not new brand
/// colours.
const navyDeep = Color(0xFF0A1730);
const navy = Color(0xFF12213E);
const navyLift = Color(0xFF1E4585);

/// Yellow anchor from the board swatch (#FEC819).
const yellow = Color(0xFFFEC819);

const ink = navy;
const inkMuted = Color(0xFF5C647A);
const inkFaint = Color(0xFF98A0B3);

const surface = Color(0xFFFFFFFF);
const fieldBorder = Color(0xFFE1E5EE);
const attention = Color(0xFFD73C2B);

const disabledFill = Color(0xFFE6E8EE);
const disabledInk = Color(0xFF9AA0B4);

// ------------------------------------------------------------------ shape

const sheetRadius = 28.0;
const buttonRadius = 14.0;
const buttonHeight = 48.0;
const fieldRadius = 14.0;

// ------------------------------------------------------------------- type

TextTheme cefTextTheme() => GoogleFonts.manropeTextTheme();

/// Manrope carries no Han or Tamil glyphs, and CanvasKit does not fall back
/// to system fonts, so the locked endonyms on screen 09 would render as tofu
/// boxes. These two faces cover those scripts; everything else stays Manrope.
TextStyle hanFace(TextStyle base) => GoogleFonts.notoSansSc(textStyle: base);
TextStyle tamilFace(TextStyle base) =>
    GoogleFonts.notoSansTamil(textStyle: base);

// --------------------------------------------------------------- spacing

abstract final class Gap {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

// --------------------------------------------------------------- backdrop

/// The locked Navy backdrop: a diagonal sweep plus the softer lighter-blue
/// lift the boards show toward the centre-right.
///
/// The gradient spans whatever box it is given, so a caller that wants the
/// full sweep inside a short header band must size that band itself — handing
/// it the whole screen would show only the dark top of the sweep.
class NavyBackdrop extends StatelessWidget {
  const NavyBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [navyDeep, navy, navyLift, navy],
          stops: [0.0, 0.34, 0.66, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.05, -0.12),
            radius: 0.95,
            colors: [Color(0x332F6BD0), Color(0x00000000)],
          ),
        ),
        child: child,
      ),
    ),
  );
}

// ------------------------------------------------------------------ brand

/// Share of the canonical master's height that the lockup actually occupies.
/// The D-35 file is a 4375x4375 canvas with the portrait lockup centred in
/// it, so a plain `height:` renders a logo visibly ~28% smaller than the
/// number implies.
const _lockupInkRatio = 0.7225;

/// D-35 canonical primary lockup, bundled unmodified and never redrawn.
///
/// [height] is the height of the *visible* lockup, not of the asset's square
/// canvas, so the numbers at each call site can be read off the boards.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.height = 150,
    this.blurSigma = 0,
    this.opacity = 1,
  });

  final double height;

  /// Soft-focus pass, as the locked sheet boards render the header lockup.
  final double blurSigma;

  /// Lets the sheet header carry the logo as a soft brand signal without
  /// competing with the form card.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final box = height / _lockupInkRatio;
    Widget image = Image.asset(
      'assets/brand/cefflo-logo-primary.png',
      height: box,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      // The master is 4375x4375; decoding it at full size costs ~76MB per
      // instance. Decode at 3x display size — the file itself is untouched.
      cacheWidth: (box * 3).round(),
    );
    if (opacity < 1) {
      image = Opacity(opacity: opacity, child: image);
    }
    if (blurSigma > 0) {
      image = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.decal,
        ),
        child: image,
      );
    }
    return image;
  }
}

class Tagline extends StatelessWidget {
  const Tagline({super.key});

  @override
  Widget build(BuildContext context) => Text(
    'Operate Today.\nGrow Tomorrow.',
    textAlign: TextAlign.center,
    style: TextStyle(
      color: Colors.white.withValues(alpha: .88),
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w500,
    ),
  );
}
