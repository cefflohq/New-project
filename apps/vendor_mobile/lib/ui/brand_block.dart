import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The official Cefflo brand block, identical on every surface's splash and
/// first Welcome screen: the official symbol, the official wordmark, then the
/// surface label. One unit `u` (the symbol's visible height) sizes everything;
/// the ratios come from the approved Driver splash. `u` follows the screen
/// (27% of width, 14.25% of height, whichever is smaller) within 84–128, so
/// the block never stretches. The official files keep their transparent
/// padding, so each is shown through a crop box at its visible size.
class CeffloBrandBlock extends StatelessWidget {
  const CeffloBrandBlock({super.key, required this.label, this.labelKey});

  final String label;
  final Key? labelKey;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OfficialCrop(
          asset: officialSymbol,
          width: u * 0.822,
          height: u,
          canvas: u * 1.783,
          semanticLabel: 'Cefflo',
        ),
        SizedBox(height: u * 0.37),
        OfficialWordmark(height: u * 0.272),
        SizedBox(height: u * 0.05),
        Text(
          label,
          key: labelKey,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: u * 0.2,
            fontWeight: FontWeight.w500,
            height: 1.2,
            letterSpacing: u * 0.002,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

/// The official wordmark alone at a visible [height] (form headers).
class OfficialWordmark extends StatelessWidget {
  const OfficialWordmark({super.key, required this.height, this.semanticLabel});

  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final u = height / 0.272;
    return OfficialCrop(
      asset: officialWordmark,
      width: u * 1.02,
      height: height,
      canvas: u * 1.745,
      centre: const Offset(0.491, 0.504),
      semanticLabel: semanticLabel,
    );
  }
}

/// The official files as supplied (2813² canvases, resampled to 1024² for
/// delivery only; geometry untouched): docs/cefflo/brand/assets/logo/
/// cefflo-official-symbol.png and cefflo-official-wordmark.png.
const officialSymbol = 'assets/brand/cefflo-symbol.png';
const officialWordmark = 'assets/brand/cefflo-wordmark.png';

/// Shows [asset] (a square canvas drawn at [canvas]) through a [width]×[height]
/// window centred on the artwork's [centre] (fractions of the canvas).
class OfficialCrop extends StatelessWidget {
  const OfficialCrop({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
    required this.canvas,
    this.centre = const Offset(0.5, 0.5),
    this.semanticLabel,
  });

  final String asset;
  final double width;
  final double height;
  final double canvas;
  final Offset centre;
  final String? semanticLabel;

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
            semanticLabel: semanticLabel,
            excludeFromSemantics: semanticLabel == null,
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
  for (final asset in const [officialSymbol, officialWordmark])
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
