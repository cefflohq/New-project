import 'package:cefflo_vendor_mobile/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] as if the app were running on a device of [size] logical
/// pixels.
///
/// The test surface itself is resized, not just the reported MediaQuery:
/// `pumpWidget` lays out against the view, so injecting a MediaQuery alone
/// would report one size while the subtree was constrained to another --
/// which silently invalidates any geometry or hit-test assertion.
Future<void> _pumpDevice(
  WidgetTester tester,
  Size size,
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  const dpr = 3.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view)
          .copyWith(textScaler: textScaler),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ResponsiveDensity(child: child),
      ),
    ),
  );
}

Widget _reportedSize() => Builder(
  builder: (context) {
    final mq = MediaQuery.of(context);
    return Text(
      '${mq.size.width.toStringAsFixed(2)}'
      'x${mq.size.height.toStringAsFixed(2)}',
      textDirection: TextDirection.ltr,
    );
  },
);

void main() {
  group('density scale is a pure function of viewport width', () {
    test('the approved iPhone baseline is exactly 1.0', () {
      // iPhone 13 Pro is the locked visual baseline.
      expect(ResponsiveDensity.scaleFor(390), 1.0);
    });

    test('every roomier phone stays at 1.0 (extra space, not bigger UI)', () {
      for (final width in <double>[
        390, // iPhone 13 Pro / 14
        393, // iPhone 15 / Pixel 7
        412, // common tall Android
        414, // iPhone 11 / XR
        430, // iPhone 15 Pro Max
        600, // foldable unfolded
        1280, // desktop browser
      ]) {
        expect(
          ResponsiveDensity.scaleFor(width),
          1.0,
          reason: '$width should not be scaled',
        );
      }
    });

    test('narrow high-density Android canvases are normalized down', () {
      // Honor X7B: 1080x2412 physical at devicePixelRatio 3.0 -> 360 logical.
      final honor = ResponsiveDensity.scaleFor(360);
      expect(honor, closeTo(360 / 390, 0.0001));
      expect(honor, lessThan(1.0));
      // 375 (iPhone SE class) sits between the two.
      expect(ResponsiveDensity.scaleFor(375), closeTo(375 / 390, 0.0001));
      expect(ResponsiveDensity.scaleFor(375), greaterThan(honor));
    });

    test('the floor keeps the smallest phones legible', () {
      expect(ResponsiveDensity.scaleFor(320), ResponsiveDensity.minScale);
      expect(ResponsiveDensity.scaleFor(200), ResponsiveDensity.minScale);
      expect(ResponsiveDensity.scaleFor(0), 1.0);
      expect(ResponsiveDensity.scaleFor(double.nan), 1.0);
    });

    test('scale never enlarges the design system', () {
      for (var w = 120.0; w <= 1600; w += 7) {
        expect(ResponsiveDensity.scaleFor(w), lessThanOrEqualTo(1.0));
        expect(
          ResponsiveDensity.scaleFor(w),
          greaterThanOrEqualTo(ResponsiveDensity.minScale),
        );
      }
    });

    test('scale is monotonic in width', () {
      var previous = 0.0;
      for (var w = 120.0; w <= 600; w += 3) {
        final scale = ResponsiveDensity.scaleFor(w);
        expect(scale, greaterThanOrEqualTo(previous));
        previous = scale;
      }
    });
  });

  group('widget behaviour', () {
    testWidgets('the baseline is passed through with no wrapper at all', (
      tester,
    ) async {
      await _pumpDevice(tester, const Size(390, 844), _reportedSize());
      // Untouched canvas: the child still sees the real viewport.
      expect(find.text('390.00x844.00'), findsOneWidget);
      expect(find.byType(FittedBox), findsNothing);
    });

    testWidgets('a narrow Android canvas gains logical space', (tester) async {
      await _pumpDevice(tester, const Size(360, 804), _reportedSize());
      final scale = 360 / 390;
      final width = (360 / scale).toStringAsFixed(2);
      final height = (804 / scale).toStringAsFixed(2);
      // The app lays out against a wider/taller canvas, so more content fits
      // instead of the components growing.
      expect(find.text('${width}x$height'), findsOneWidget);
      expect(find.byType(FittedBox), findsOneWidget);
    });

    testWidgets('the child is really laid out at the normalized size', (
      tester,
    ) async {
      // Regression: an inner SizedBox gets clamped by the device's own
      // constraints, so the wider canvas never materializes and the UI is
      // merely shrunk into a corner, leaving dead space at the right/bottom.
      // The child must actually receive the enlarged constraints.
      const key = Key('canvas');
      await _pumpDevice(
        tester,
        const Size(360, 804),
        Container(key: key, color: const Color(0xFF000000)),
      );

      final scale = 360 / 390;
      final size = tester.getSize(find.byKey(key));
      expect(size.width, closeTo(360 / scale, 0.01));
      expect(size.height, closeTo(804 / scale, 0.01));

      // ...and after the transform it still covers the physical viewport
      // exactly: top-left at origin, bottom-right at the device corner.
      final topLeft = tester.getTopLeft(find.byKey(key));
      final bottomRight = tester.getBottomRight(find.byKey(key));
      expect(topLeft, const Offset(0, 0));
      expect(bottomRight.dx, closeTo(360, 0.01));
      expect(bottomRight.dy, closeTo(804, 0.01));
    });

    testWidgets('taps reach the bottom edge, where the nav bar lives', (
      tester,
    ) async {
      // Regression: a wrapper that reports the *enlarged* canvas as its own
      // size (e.g. OverflowBox) makes RenderBox.hitTest reject anything past
      // the device size, killing input in the bottom/right strip -- which is
      // precisely where the bottom navigation sits. Geometry tests pass
      // happily while the app is untappable, so assert on input directly.
      for (final size in const [
        Size(390, 844), // baseline, no wrapper
        Size(360, 804), // Honor X7B
        Size(320, 693), // clamped floor
      ]) {
        var taps = 0;
        await _pumpDevice(
          tester,
          size,
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox(height: 56, width: double.infinity),
            ),
          ),
        );

        // Tap in device coordinates, near the very bottom of the screen.
        await tester.tapAt(Offset(size.width / 2, size.height - 10));
        await tester.pump();
        expect(taps, 1, reason: 'bottom bar unreachable at $size');

        // ...and the far bottom-right corner, the worst case for a
        // size-gated hit test.
        await tester.tapAt(Offset(size.width - 4, size.height - 4));
        await tester.pump();
        expect(taps, 2, reason: 'bottom-right corner unreachable at $size');
      }
    });

    testWidgets('runaway OS text scaling is capped', (tester) async {
      await _pumpDevice(
        tester,
        const Size(390, 844),
        _reportedSize(),
        textScaler: const TextScaler.linear(2),
      );
      final context = tester.element(find.byType(Builder));
      expect(
        MediaQuery.of(context).textScaler.scale(16),
        16 * ResponsiveDensity.maxTextScale,
      );
    });

    testWidgets('text scaling within the cap is left alone', (tester) async {
      await _pumpDevice(
        tester,
        const Size(390, 844),
        _reportedSize(),
        textScaler: const TextScaler.linear(1.15),
      );
      final context = tester.element(find.byType(Builder));
      expect(MediaQuery.of(context).textScaler.scale(16), closeTo(18.4, 0.001));
    });
  });
}
