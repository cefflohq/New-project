import 'package:cefflo_vendor_mobile/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Size size, {TextScaler textScaler = TextScaler.noScaling}) =>
    MediaQuery(
      data: MediaQueryData(size: size, textScaler: textScaler),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ResponsiveDensity(
          child: Builder(
            builder: (context) {
              final mq = MediaQuery.of(context);
              return Text(
                '${mq.size.width.toStringAsFixed(2)}'
                'x${mq.size.height.toStringAsFixed(2)}',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      ),
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
      await tester.pumpWidget(_harness(const Size(390, 844)));
      // Untouched canvas: the child still sees the real viewport.
      expect(find.text('390.00x844.00'), findsOneWidget);
      expect(find.byType(Transform), findsNothing);
    });

    testWidgets('a narrow Android canvas gains logical space', (tester) async {
      await tester.pumpWidget(_harness(const Size(360, 804)));
      final scale = 360 / 390;
      final width = (360 / scale).toStringAsFixed(2);
      final height = (804 / scale).toStringAsFixed(2);
      // The app lays out against a wider/taller canvas, so more content fits
      // instead of the components growing.
      expect(find.text('${width}x$height'), findsOneWidget);
      expect(find.byType(Transform), findsOneWidget);
    });

    testWidgets('the child is really laid out at the normalized size', (
      tester,
    ) async {
      // Regression: an inner SizedBox gets clamped by the device's own
      // constraints, so the wider canvas never materializes and the UI is
      // merely shrunk into a corner, leaving dead space at the right/bottom.
      // The child must actually receive the enlarged constraints.
      const key = Key('canvas');
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 804)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ResponsiveDensity(
              child: Container(key: key, color: const Color(0xFF000000)),
            ),
          ),
        ),
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

    testWidgets('runaway OS text scaling is capped', (tester) async {
      await tester.pumpWidget(
        _harness(const Size(390, 844), textScaler: const TextScaler.linear(2)),
      );
      final context = tester.element(find.byType(Builder));
      expect(
        MediaQuery.of(context).textScaler.scale(16),
        16 * ResponsiveDensity.maxTextScale,
      );
    });

    testWidgets('text scaling within the cap is left alone', (tester) async {
      await tester.pumpWidget(
        _harness(
          const Size(390, 844),
          textScaler: const TextScaler.linear(1.15),
        ),
      );
      final context = tester.element(find.byType(Builder));
      expect(MediaQuery.of(context).textScaler.scale(16), closeTo(18.4, 0.001));
    });
  });
}
