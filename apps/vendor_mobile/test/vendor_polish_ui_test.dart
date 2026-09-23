import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final routes = <VRoute>[
    VRoute.setupComplete,
    VRoute.today,
    VRoute.orders,
    VRoute.importOrders,
    VRoute.zones,
    VRoute.riders,
    VRoute.team,
    VRoute.products,
    VRoute.settings,
    VRoute.language,
  ];

  for (final route in routes) {
    testWidgets('${route.name} renders at the iPhone 15 viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        VendorMobileApp(
          repo: VendorRepository.demo(),
          auditLocation: VendorLocation(route),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      if (route != VRoute.team && route != VRoute.setupComplete) {
        expect(find.text('Menu'), findsWidgets);
      }
    });
  }

  testWidgets('Import orders shows guidance before official source cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      VendorMobileApp(
        repo: VendorRepository.demo(),
        auditLocation: const VendorLocation(VRoute.importOrders),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('How it works?')).dy,
      lessThan(tester.getTopLeft(find.text('Google Sheets')).dy),
    );
    expect(find.text('Excel'), findsOneWidget);
    expect(find.text('Google Drive'), findsOneWidget);
  });

  testWidgets('Products exposes its add action in the header', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      VendorMobileApp(
        repo: VendorRepository.demo(),
        auditLocation: const VendorLocation(VRoute.products),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add product'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.byTooltip('Add product'));
    await tester.pumpAndSettle();
    expect(find.text('Add product'), findsOneWidget);
  });

  testWidgets('the fifth navigation item opens Menu', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      VendorMobileApp(
        repo: VendorRepository.demo(),
        auditLocation: const VendorLocation(VRoute.products),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Business'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
