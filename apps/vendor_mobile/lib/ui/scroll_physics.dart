import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Premium scrolling everywhere (Founder 2026-10-16): a weighted glide that
/// slows sooner than the platform default and settles with a soft bounce,
/// so lists feel deliberate rather than slippery.
class CefScrollPhysics extends BouncingScrollPhysics {
  const CefScrollPhysics({super.parent})
    : super(decelerationRate: ScrollDecelerationRate.fast);

  @override
  CefScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      CefScrollPhysics(parent: buildParent(ancestor));

  /// A flick carries less speed: the list feels heavier under the thumb.
  @override
  double get maxFlingVelocity => 4500;

  @override
  double carriedMomentum(double existingVelocity) =>
      super.carriedMomentum(existingVelocity) * .6;

  /// A softer, slightly damped settle at the ends.
  @override
  SpringDescription get spring =>
      SpringDescription.withDampingRatio(mass: .7, stiffness: 120, ratio: 1.05);
}

/// Applies [CefScrollPhysics] app-wide, with mouse drag on web.
class CefScrollBehavior extends MaterialScrollBehavior {
  const CefScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const CefScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    if (kIsWeb) PointerDeviceKind.mouse,
  };
}
