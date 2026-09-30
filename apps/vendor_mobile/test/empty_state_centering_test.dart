import 'package:cefflo_vendor_mobile/core/theme.dart';
import 'package:cefflo_vendor_mobile/ui/shell.dart';
import 'package:cefflo_vendor_mobile/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Founder, 2026-10-01: an empty / error state sits in the MIDDLE of the
/// space left below the page's own controls (tabs, search) -- on every
/// screen and phone height, by layout, never a fixed offset.
void main() {
  for (final height in const [560.0, 700.0, 900.0]) {
    testWidgets('empty state centred under the tabs at height $height', (
      tester,
    ) async {
      tester.view.physicalSize = Size(393, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVendorTheme(Brightness.light),
          home: Scaffold(
            body: SizedBox(
              height: height,
              child: PageBody(
                children: [
                  const SizedBox(key: Key('tabs'), height: 60),
                  StateBlock.empty('No riders yet.'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final tabsBottom = tester.getBottomLeft(find.byKey(const Key('tabs'))).dy;
      final center = tester.getCenter(find.byType(StateBlock)).dy;
      final mid = (tabsBottom + height) / 2;
      // PageBody's own bottom padding shifts the true centre slightly up.
      expect((center - mid).abs(), lessThan(20));
      expect(center, greaterThan(tabsBottom + (height - tabsBottom) * .35));
    });
  }
}
