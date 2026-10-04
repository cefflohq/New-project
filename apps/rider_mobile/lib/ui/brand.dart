import 'dart:async';
import 'dart:math' as math;
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
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Center(
      child: _OfficialCrop(
        asset: _officialSymbol,
        width: size * 0.822,
        height: size,
        canvas: size * 1.783,
      ),
    ),
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
        child: _OfficialStack(width: width),
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

/// Official symbol over official wordmark, [width] wide (the wordmark's
/// visible width), for compact uses that carry no surface label.
class _OfficialStack extends StatelessWidget {
  const _OfficialStack({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    final u = width / 1.02;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OfficialCrop(
          asset: _officialSymbol,
          width: u * 0.822,
          height: u,
          canvas: u * 1.783,
        ),
        SizedBox(height: u * 0.37),
        _OfficialCrop(
          asset: _officialWordmark,
          width: width,
          height: u * 0.272,
          canvas: u * 1.745,
          centre: const Offset(0.491, 0.504),
        ),
      ],
    );
  }
}

/// The official Cefflo brand block, identical on every surface's splash and
/// first Welcome screen: the official symbol, the official wordmark, then the
/// surface label. One unit `u` (the symbol's visible height) sizes everything;
/// the ratios come from the approved Driver splash. `u` follows the screen
/// (27% of width, 14.25% of height, whichever is smaller) within 84–128, so
/// the block never stretches. The official files keep their transparent
/// padding, so each is shown through a crop box at its visible size.
class CeffloBrandBlock extends StatelessWidget {
  const CeffloBrandBlock({super.key, this.label = 'Driver'});

  final String label;

  static double unitFor(Size screen) =>
      math.min(screen.width * 0.27, screen.height * 0.1425).clamp(84.0, 128.0);

  /// The block's laid-out height for unit [u] (symbol, gap, wordmark, gap,
  /// one label line).
  static double heightFor(double u) => u * 1.932;

  /// Space to put above the block in a column that starts [columnTop] px
  /// from the top of the screen so the block sits exactly where the splash
  /// centres it. Never less than [min] (short screens just flow).
  static double gapAbove(
    BuildContext context,
    double columnTop, {
    double min = 16,
  }) {
    final size = MediaQuery.sizeOf(context);
    final u = unitFor(size);
    return math.max(min, size.height / 2 - heightFor(u) / 2 - columnTop);
  }

  @override
  Widget build(BuildContext context) {
    final u = unitFor(MediaQuery.sizeOf(context));
    return Semantics(
      label: 'Cefflo $label',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OfficialCrop(
              asset: _officialSymbol,
              width: u * 0.822,
              height: u,
              canvas: u * 1.783,
            ),
            SizedBox(height: u * 0.37),
            _OfficialCrop(
              asset: _officialWordmark,
              width: u * 1.02,
              height: u * 0.272,
              canvas: u * 1.745,
              centre: const Offset(0.491, 0.504),
            ),
            SizedBox(height: u * 0.05),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: u * 0.2,
                fontWeight: FontWeight.w500,
                height: 1.2,
                letterSpacing: u * 0.002,
                color: CefColors.onNavy.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The official files as supplied (2813² canvases, resampled to 1024² for
/// delivery only; geometry untouched): docs/cefflo/brand/assets/logo/
/// cefflo-official-symbol.png and cefflo-official-wordmark.png.
const _officialSymbol = 'assets/brand/cefflo-symbol.png';
const _officialWordmark = 'assets/brand/cefflo-wordmark.png';

/// Shows [asset] (a square canvas drawn at [canvas]) through a [width]×[height]
/// window centred on the artwork's [centre] (fractions of the canvas).
class _OfficialCrop extends StatelessWidget {
  const _OfficialCrop({
    required this.asset,
    required this.width,
    required this.height,
    required this.canvas,
    this.centre = const Offset(0.5, 0.5),
  });

  final String asset;
  final double width;
  final double height;
  final double canvas;
  final Offset centre;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ClipRect(
      child: OverflowBox(
        minWidth: canvas,
        maxWidth: canvas,
        minHeight: canvas,
        maxHeight: canvas,
        child: Transform.translate(
          offset: Offset(
            (0.5 - centre.dx) * canvas,
            (0.5 - centre.dy) * canvas,
          ),
          child: Image.asset(
            asset,
            width: canvas,
            height: canvas,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    ),
  );
}

/// Decodes the official symbol and wordmark into the image cache before the
/// first frame, so the Flutter splash never paints without its logo (the
/// identical HTML pre-splash stays up meanwhile). Gives up after 3s.
Future<void> precacheBrandAssets() => Future.wait([
  for (final asset in const [_officialSymbol, _officialWordmark])
    () {
      final done = Completer<void>();
      final stream = AssetImage(asset).resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, _) {
          if (!done.isCompleted) done.complete();
          stream.removeListener(listener);
        },
        onError: (_, _) {
          if (!done.isCompleted) done.complete();
        },
      );
      stream.addListener(listener);
      return done.future;
    }(),
]).timeout(const Duration(seconds: 3), onTimeout: () => const []);
