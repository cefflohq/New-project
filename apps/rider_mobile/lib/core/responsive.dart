import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Normalizes the *logical* canvas the app lays out against, so that one set
/// of fixed design-token sizes reads at the same perceived density on every
/// phone.
///
/// Every size in this app is a fixed logical-pixel value (see `Gap`, `Sizes`
/// and the locked `TextTheme`) taken off the 390 x 844 iPhone 13 Pro frame
/// the reference renders use. Nothing scales with screen height, and that is
/// deliberate — but "one logical pixel" is not a constant share of the
/// screen across devices. High-density Android phones report a *narrower*
/// logical canvas (a 6.8" handset at devicePixelRatio 3.0 hands Flutter only
/// 360 logical px) so identical components eat a larger share of the screen
/// and less content fits.
///
/// Clamping the canvas instead of the components fixes the cause rather than
/// the symptom: below [designWidth] the UI is uniformly scaled by
/// `width / designWidth` and handed a correspondingly wider logical canvas,
/// so components keep their exact design-token size *relative to the
/// baseline* and the extra room shows more content rather than bigger
/// widgets. At and above [designWidth] the tree is passed through untouched,
/// so the approved reference rendering cannot drift.
///
/// Ported (not imported) from `apps/vendor_mobile/lib/core/responsive.dart`
/// — the two Flutter clients are separate projects with separate pubspecs.
class ResponsiveDensity extends StatelessWidget {
  const ResponsiveDensity({super.key, required this.child});

  final Widget child;

  /// The approved visual baseline: iPhone 13 Pro's logical width, which is
  /// also the frame every Cefflo Driver reference image was rendered at.
  static const double designWidth = 390.0;

  /// Floor on the normalization, so an unusually narrow handset cannot
  /// shrink typography and tap targets below a comfortable size.
  static const double minScale = 0.85;

  /// Upper bound on OS/browser text scaling. Accessibility scaling still
  /// applies up to this cap; only runaway values that would break the
  /// layout are limited.
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
      // FittedBox lays the child out unconstrained (so the SizedBox really
      // gets the enlarged canvas), sizes *itself* to the true viewport (so
      // hit-testing still covers the bottom navigation), and hit-tests
      // through its own paint transform. BoxFit.fill is uniform here by
      // construction: both axes resolve to the same single scale.
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: logicalSize.width,
          height: logicalSize.height,
          child: child,
        ),
      ),
    );
  }
}
