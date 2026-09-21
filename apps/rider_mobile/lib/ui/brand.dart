import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The chevron watermark the reference headers carry on their right-hand
/// side: two nested left-pointing chevrons in a slightly lighter blue,
/// bleeding off the right edge. Painted rather than shipped as an image
/// because it is a flat geometric wash, not the brand mark — the brand mark
/// itself is only ever drawn from `assets/brand/` (see [CeffloLogoMark]).
class ChevronWatermark extends StatelessWidget {
  const ChevronWatermark({super.key});

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ClipRect(child: CustomPaint(painter: _ChevronPainter())),
    ),
  );
}

class _ChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Anchored to the right edge and vertically centred in the header, the
    // same placement every navy reference header uses.
    final h = size.height;
    final w = size.width;
    final cy = h * 0.52;
    final span = h * 0.95;

    void chevron(double tipX, double thickness, double opacity) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(tipX + span * 0.62, cy - span * 0.62)
        ..lineTo(tipX, cy)
        ..lineTo(tipX + span * 0.62, cy + span * 0.62);
      canvas.drawPath(path, paint);
    }

    chevron(w - span * 0.30, span * 0.26, 0.055);
    chevron(w - span * 0.02, span * 0.26, 0.085);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) => false;
}

/// Full-bleed navy gradient with the chevron watermark. Used as the backdrop
/// for every navy surface: auth headers, screen headers and the splash.
class NavyBackdrop extends StatelessWidget {
  const NavyBackdrop({super.key, required this.child, this.watermark = true});

  final Widget child;
  final bool watermark;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: cefHeaderGradient),
    child: Stack(children: [if (watermark) const ChevronWatermark(), child]),
  );
}

/// The Cefflo mark, drawn from the canonical D-35 asset. Never redrawn,
/// approximated or recoloured in code.
class CeffloLogoMark extends StatelessWidget {
  const CeffloLogoMark({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/cefflo-logo-mark.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
  );
}

/// Soft-focus Cefflo lockup used as a quiet identity layer behind auth
/// headings. The source remains the canonical supplied asset; only the
/// presentation is softened so form copy stays dominant.
class CeffloAuthWatermark extends StatelessWidget {
  const CeffloAuthWatermark({
    super.key,
    this.width = 112,
    this.blurSigma = 4.2,
    this.opacity = 0.28,
  });

  final double width;
  final double blurSigma;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Opacity(
      opacity: opacity,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.decal,
        ),
        child: Image.asset(
          _splashAsset,
          width: width,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    ),
  );
}

/// "Cefflo Driver" as a single-line inline lockup — bold "Cefflo" followed
/// by a lighter "Driver". This is the header treatment in D11, D14.1–14.3,
/// D16, D17, D18 and D19.
class CeffloDriverWordmark extends StatelessWidget {
  const CeffloDriverWordmark({super.key, this.fontSize = 20});
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'Cefflo',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: CefColors.onNavy,
            letterSpacing: -0.4,
          ),
        ),
        const TextSpan(text: ' '),
        TextSpan(
          text: 'Driver',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: CefColors.onNavy.withValues(alpha: 0.92),
            letterSpacing: -0.2,
          ),
        ),
      ],
    ),
  );
}

/// D01's splash artwork: the folded chevron mark with its yellow accent above
/// the "Cefflo" wordmark, supplied as one combined lockup. The master is a
/// 2813×2813 canvas that is mostly transparent margin; the shipped asset is
/// that master cropped to its ink (x 796–2100, y 568–2446, so 1304×1878),
/// with no resampling or recolouring, so the artwork's box is the artwork and
/// the "Driver" line below it sits against the wordmark rather than against a
/// band of nothing.
const _splashAsset = 'assets/brand/cefflo-logo-splash.png';
const _splashArtworkAspect = 1878 / 1304;

/// D01's stacked lockup: the supplied mark-and-"Cefflo" artwork with
/// "Driver" set beneath it as the second line of the same lockup — lighter
/// weight, white, sized and tracked against the baked wordmark so the two
/// read as one mark. Proportions/spacing match the splash reference.
class CeffloSplashLockup extends StatelessWidget {
  const CeffloSplashLockup({super.key, this.width = 156});

  final double width;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        _splashAsset,
        width: width,
        height: width * _splashArtworkAspect,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
      const SizedBox(height: 4),
      Text(
        'Driver',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: width * 0.17,
          fontWeight: FontWeight.w500,
          height: 1.0,
          letterSpacing: 1.0,
          color: CefColors.onNavy.withValues(alpha: 0.9),
        ),
      ),
    ],
  );
}
