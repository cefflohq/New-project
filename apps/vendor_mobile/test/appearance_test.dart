import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/appearance.dart';
import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/core/theme.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrastWithWhite(Color c) => (1.05) / (c.computeLuminance() + .05);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    liveAppearance.value = Appearance.standard;
  });

  test('fresh install is the Cefflo standard appearance', () async {
    final a = await AppearanceStore().read();
    expect(a, Appearance.standard);
    expect(a.backdrop, CefGradients.brand);
  });

  test('saved appearance survives a restart (device storage)', () async {
    await AppearanceStore().write(
      const Appearance(color: 0xFF12A150, gradient: false),
    );
    // A new store instance reads what the previous run saved.
    final a = await AppearanceStore().read();
    expect(a, const Appearance(color: 0xFF12A150, gradient: false));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {
      AppearanceStore.colorKey,
      AppearanceStore.gradientKey,
    });
  });

  test('contrast safeguard keeps white header text legible', () {
    for (final c in const [
      Color(0xFFFFC93C),
      Color(0xFFFFFFFF),
      Color(0xFFB3E5FC),
    ]) {
      expect(_contrastWithWhite(legibleBackdropColor(c)), greaterThan(4.4));
    }
    // A dark colour is already legible and is kept as chosen.
    expect(
      legibleBackdropColor(const Color(0xFF0B1220)),
      const Color(0xFF0B1220),
    );
    // Gradient is derived from the one colour; plain is flat.
    const plain = Appearance(color: 0xFF12A150, gradient: false);
    expect(plain.backdrop.colors.toSet().length, 1);
    const grad = Appearance(color: 0xFF12A150);
    expect(grad.backdrop.colors.length, 2);
    expect(
      grad.backdrop.colors.last,
      legibleBackdropColor(const Color(0xFF12A150)),
    );
  });

  testWidgets('preview applies app-wide; leaving without Save rolls back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      VendorMobileApp(
        repo: VendorRepository.demo(),
        auditLocation: const VendorLocation(VRoute.appearance),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Green'));
    await tester.pumpAndSettle();
    expect(liveAppearance.value.color, 0xFF12A150);

    await tester.tap(find.text('Plain'));
    await tester.pumpAndSettle();
    expect(
      liveAppearance.value,
      const Appearance(color: 0xFF12A150, gradient: false),
    );

    // Leave without saving: the saved (standard) appearance returns.
    final app = AppScope.read(tester.element(find.text('Green')));
    app.go(VRoute.today);
    await tester.pumpAndSettle();
    expect(liveAppearance.value, Appearance.standard);
    expect(await AppearanceStore().read(), Appearance.standard);
  });

  testWidgets('Save persists on this device only', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      VendorMobileApp(
        repo: VendorRepository.demo(),
        auditLocation: const VendorLocation(VRoute.appearance),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Purple'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Purple'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(await AppearanceStore().read(), const Appearance(color: 0xFF7C3AED));

    final app = AppScope.read(tester.element(find.text('Purple')));
    app.go(VRoute.today);
    await tester.pumpAndSettle();
    expect(liveAppearance.value, const Appearance(color: 0xFF7C3AED));
    await tester.pump(const Duration(seconds: 4));
  });
}
