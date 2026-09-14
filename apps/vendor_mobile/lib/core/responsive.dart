import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Normalizes the *logical* canvas the app lays out against, so that one set
/// of fixed design-token sizes reads at the same perceived density on every
/// phone.
///
/// Why this exists
/// ---------------
/// Every size in this app is a fixed logical-pixel value (see `Gap`, `Sizes`
/// and the locked `TextTheme`). Nothing scales with screen height, and that
/// is deliberate. The problem is that "one logical pixel" is not a constant
/// share of the screen across platforms:
///
///   * iPhone 13 Pro (the approved visual baseline) reports a 390 x 844
///     logical canvas.
///   * High-density Android phones report a *narrower* canvas even when the
///     handset is physically much larger. A 6.8" Honor X7B (1080 x 2412
///     physical) runs at devicePixelRatio 3.0, so the browser hands Flutter
///     only 360 x 804 logical pixels -- 8% narrower than the 6.1" iPhone.
///
/// Identical components therefore eat a larger share of the Android screen
/// and less content fits, which reads as "oversized / stretched" even though
/// no component actually changed size. Clamping the canvas instead of the
/// components fixes the cause rather than the symptom.
///
/// What it does
/// ------------
/// When a viewport is narrower than [designWidth], the UI is uniformly
/// scaled down by `width / designWidth` and handed a correspondingly wider
/// logical canvas. Components keep their exact design-token sizes *relative
/// to the baseline*, and the extra canvas shows more content rather than
/// bigger widgets.
///
/// This is a pure function of viewport width -- there is no platform check
/// and no per-device special case, so it behaves correctly across small,
/// tall and large phones at any pixel density or aspect ratio.
///
/// Viewports at or above [designWidth] are returned untouched, so the
/// approved iPhone rendering is preserved exactly (390 -> scale 1.0) and
/// roomier devices simply get more usable space.
class ResponsiveDensity extends StatelessWidget {
  const ResponsiveDensity({super.key, required this.child});

  final Widget child;

  /// The approved visual baseline: iPhone 13 Pro's logical width.
  static const double designWidth = 390.0;

  /// Floor on the normalization, so an unusually narrow handset cannot
  /// shrink typography and tap targets below a comfortable size. 0.85 keeps
  /// the smallest common phone (320 logical px) legible.
  static const double minScale = 0.85;

  /// Upper bound on OS/browser text scaling. Android surfaces the system
  /// font-size preference to the app, and an extreme setting reflows every
  /// row and card. Accessibility scaling still applies up to this cap; only
  /// runaway values that would break the layout are limited.
  static const double maxTextScale = 1.3;

  /// Density scale for a given viewport width. Exactly 1.0 at and above
  /// [designWidth]; clamped at [minScale] below it.
  static double scaleFor(double viewportWidth) {
    if (!viewportWidth.isFinite || viewportWidth <= 0) return 1.0;
    if (viewportWidth >= designWidth) return 1.0;
    return math.max(viewportWidth / designWidth, minScale);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = scaleFor(mq.size.width);
    // Probe the scaler rather than assuming it is linear.
    final needsTextClamp = mq.textScaler.scale(16) > 16 * maxTextScale;

    // The approved baseline and anything roomier is passed through
    // completely untouched -- no wrapper, no transform, no MediaQuery
    // override -- so its rendering cannot drift.
    if (scale == 1.0 && !needsTextClamp) return child;

    final textScaler = needsTextClamp
        ? mq.textScaler.clamp(maxScaleFactor: maxTextScale)
        : mq.textScaler;

    if (scale == 1.0) {
      return MediaQuery(
        data: mq.copyWith(textScaler: textScaler),
        child: child,
      );
    }

    final logicalSize = mq.size / scale;
    return MediaQuery(
      data: mq.copyWith(
        size: logicalSize,
        textScaler: textScaler,
        // Insets are physical edges of the device; they have to be expressed
        // in the same (now larger) logical space as the canvas, otherwise
        // SafeArea would reserve the wrong amount of room.
        padding: mq.padding / scale,
        viewPadding: mq.viewPadding / scale,
        viewInsets: mq.viewInsets / scale,
        systemGestureInsets: mq.systemGestureInsets / scale,
      ),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        // OverflowBox (not SizedBox) because the incoming constraints are the
        // device's own, and the whole point is to lay the app out against a
        // *larger* canvas than the device reports before scaling it back
        // down to fit. A SizedBox would simply be clamped to the device size
        // and the normalization would silently do nothing but shrink.
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: logicalSize.width,
          maxWidth: logicalSize.width,
          minHeight: logicalSize.height,
          maxHeight: logicalSize.height,
          child: child,
        ),
      ),
    );
  }
}
