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

/// D01's stacked lockup: the mark above a two-line "Cefflo" / "Driver"
/// wordmark. Sizes/weights/spacing match the splash reference.
class CeffloSplashLockup extends StatelessWidget {
  const CeffloSplashLockup({super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CeffloLogoMark(size: 118),
      const SizedBox(height: 2),
      const Text(
        'Cefflo',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 54,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -1.6,
          color: CefColors.onNavy,
        ),
      ),
      Text(
        'Driver',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 30,
          fontWeight: FontWeight.w500,
          height: 1.1,
          letterSpacing: 0.4,
          color: CefColors.onNavy.withValues(alpha: 0.88),
        ),
      ),
    ],
  );
}
