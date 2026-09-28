import 'package:cefflo_vendor_mobile/core/auth_access.dart';
import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:cefflo_vendor_mobile/ui/screens/auth.dart';
import 'package:cefflo_vendor_mobile/ui/screens/helper_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Founder-approved Helper boards (D-74): Sign-In, Preparation, Zones
// (pickup-time order), Packing and Sorting (grey slider until N/N, then
// deliberate "Slide to Confirm Pickup"), Ready for Pickup (rider + plate).
void main() {
  setUp(resetDemoFulfilment);

  Future<void> pumpHelper(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      VendorMobileApp(
        repo: VendorRepository.demo(demoRole: 'helper'),
        access: AuthAccess.helper,
        auditLocation: const VendorLocation(VRoute.today),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  SlideToConfirm slider(WidgetTester tester) =>
      tester.widget<SlideToConfirm>(find.byType(SlideToConfirm));

  Future<void> slide(WidgetTester tester) async {
    await tester.drag(
      find.byKey(const ValueKey('slide-handle')),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Helper Sign-In shows the Helper context', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      VendorMobileApp(repo: VendorRepository.demo(), access: AuthAccess.helper),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Helper Access'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to your preparation tasks'), findsOneWidget);
    expect(find.text('Operator Access'), findsNothing);
  });

  testWidgets('Preparation aggregates the workload', (tester) async {
    await pumpHelper(tester);
    expect(find.text('Kak Lina Kitchen'), findsOneWidget);
    expect(find.text('Preparation'), findsWidgets);
    expect(find.text('20'), findsOneWidget); // orders
    expect(find.text('Nasi Ayam'), findsOneWidget);
    expect(find.text('Required Items'), findsOneWidget);
  });

  testWidgets('Zones are ordered by pickup time, earliest first', (
    tester,
  ) async {
    await pumpHelper(tester);
    await tester.tap(find.text('Zones').last);
    await tester.pumpAndSettle();
    final names = ['Shah Alam', 'Petaling Jaya', 'Klang'];
    final ys = [for (final n in names) tester.getTopLeft(find.text(n)).dy];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.byKey(const ValueKey('zone-pickup-Shah Alam')), findsOneWidget);
    expect(find.text('0 / 8 packed'), findsOneWidget);
  });

  testWidgets('Packing: grey until N/N, then a deliberate slide', (
    tester,
  ) async {
    await pumpHelper(tester);
    await tester.tap(find.text('Zones').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shah Alam'));
    await tester.pumpAndSettle();
    expect(find.text('Slide to Confirm Pickup'), findsOneWidget);
    expect(find.text('Slide to Confirm Packing'), findsNothing);
    expect(find.text('0 / 8'), findsOneWidget);
    expect(slider(tester).enabled, isFalse);
    for (var n = 1001; n <= 1007; n++) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('order-ord-$n')),
        200,
      );
      await tester.tap(find.byKey(ValueKey('order-ord-$n')));
      await tester.pumpAndSettle();
    }
    expect(find.text('7 / 8'), findsOneWidget);
    expect(slider(tester).enabled, isFalse); // 7/8: still disabled
    await slide(tester); // a drag while disabled does nothing
    expect(find.text('7 / 8'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('order-ord-1008')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('order-ord-1008')));
    await tester.pumpAndSettle();
    expect(find.text('8 / 8'), findsOneWidget);
    expect(slider(tester).enabled, isTrue); // enabled, NOT confirmed
    expect(find.text('Packing'), findsWidgets); // still on Packing
    await slide(tester);
    // Deliberate slide confirmed packing -> Sorting for the same Zone.
    expect(find.text('Sorting'), findsWidgets);
    expect(find.text('0 / 8'), findsOneWidget);
  });

  testWidgets('Sorting to Ready for Pickup with rider and plate', (
    tester,
  ) async {
    await pumpHelper(tester);
    await tester.tap(find.text('Zones').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shah Alam'));
    await tester.pumpAndSettle();
    for (var n = 1001; n <= 1008; n++) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('order-ord-$n')),
        200,
      );
      await tester.tap(find.byKey(ValueKey('order-ord-$n')));
      await tester.pumpAndSettle();
    }
    expect(find.text('8 / 8'), findsOneWidget);
    expect(slider(tester).enabled, isTrue);
    await slide(tester);
    expect(find.text('Pickup Time'), findsOneWidget);
    expect(slider(tester).enabled, isFalse);
    for (var n = 1001; n <= 1008; n++) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('order-ord-$n')),
        200,
      );
      await tester.tap(find.byKey(ValueKey('order-ord-$n')));
      await tester.pumpAndSettle();
    }
    expect(find.text('8 / 8'), findsOneWidget);
    expect(find.text('Sorted'), findsWidgets);
    expect(slider(tester).enabled, isTrue);
    await slide(tester);
    expect(find.text('Ready for Pickup'), findsWidgets);
    expect(find.text('This zone is ready for rider pickup.'), findsOneWidget);
    expect(find.text('PICKUP RIDER'), findsOneWidget);
    expect(find.text('Amir Hakim'), findsOneWidget);
    expect(find.text('Motorcycle'), findsOneWidget);
    expect(find.text('VMC 4312'), findsOneWidget);
    // No extra actions on this screen.
    for (final t in ['Notify Rider', 'Assign Rider', 'Next Step']) {
      expect(find.text(t), findsNothing);
    }
  });
}
