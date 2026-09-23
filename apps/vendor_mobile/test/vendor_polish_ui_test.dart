import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cefflo_vendor_mobile/core/theme.dart';

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
      // D-46: Menu is no longer a bottom-navigation destination.
      expect(find.text('Menu'), findsNothing);
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

  Future<void> pumpAt(WidgetTester tester, VendorLocation location) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      VendorMobileApp(repo: VendorRepository.demo(), auditLocation: location),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Settings opens from the Today header, one directory', (
    tester,
  ) async {
    await pumpAt(tester, const VendorLocation(VRoute.today));
    // Four destinations only.
    for (final label in ['Today', 'Orders', 'Zones', 'Riders']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Menu'), findsNothing);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Business'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Support'), 200);
    expect(find.text('Support'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Personal information'), -200);
    // Account destinations appear once, not via a second Profile page.
    expect(find.text('Personal information'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('header titles are centred on the screen', (tester) async {
    // Today has an icon on both sides; Orders has three trailing actions
    // and none leading -- both titles still sit on the screen centre line.
    await pumpAt(tester, const VendorLocation(VRoute.orders));
    expect(tester.getCenter(find.text('Orders').first).dx, closeTo(196.5, 1));
  });

  testWidgets('rider detail uses the canonical stats and contact actions', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const VendorLocation(VRoute.riderDetail, entityId: 'rider-ahmad'),
    );
    expect(find.text('Total orders'), findsOneWidget);
    expect(find.text('Customer rating'), findsOneWidget);
    expect(find.text('Joined'), findsOneWidget);
    expect(find.text('12 Jan 2024'), findsOneWidget);
    expect(find.text('VFY 7281'), findsOneWidget);
    expect(find.text('Max orders'), findsNothing);
    expect(find.bySemanticsLabel('Call +60 12 345 6789'), findsOneWidget);
    expect(find.bySemanticsLabel('WhatsApp +60 12 345 6789'), findsOneWidget);
  });

  testWidgets('no contact actions without a phone number', (tester) async {
    await pumpAt(
      tester,
      const VendorLocation(VRoute.teamMemberDetail, entityId: 'team-helper'),
    );
    expect(find.text('Not provided'), findsWidgets);
    expect(find.text('WhatsApp'), findsNothing);
    expect(find.text('Remove from Team'), findsOneWidget);
  });

  testWidgets('the owner cannot be removed from the team', (tester) async {
    await pumpAt(
      tester,
      const VendorLocation(VRoute.teamMemberDetail, entityId: 'team-owner'),
    );
    expect(find.text('Remove from Team'), findsNothing);
    expect(find.text('WhatsApp'), findsOneWidget);
  });

  testWidgets('a large order keeps its primary action on screen', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const VendorLocation(VRoute.orderDetail, entityId: 'ord-1008'),
    );
    final cta = find.text('Mark as On the Way');
    expect(cta, findsOneWidget);
    expect(tester.getBottomLeft(cta).dy, lessThan(852));
    // Nine items: a compact preview plus the full list on demand.
    expect(find.text('View all 9 items'), findsOneWidget);
    expect(find.text('Kaya Toast'), findsNothing);
    await tester.ensureVisible(find.text('View all 9 items'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View all 9 items'));
    await tester.pumpAndSettle();
    expect(find.text('Items (9)'), findsWidgets);
    expect(find.text('Kaya Toast'), findsOneWidget);
  });

  testWidgets('zone detail previews four orders and pins dispatch', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const VendorLocation(VRoute.zoneDetail, entityId: 'zone-bangsar'),
    );
    expect(find.text('Review & dispatch (5)'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('Review & dispatch (5)')).dy,
      lessThan(852),
    );
    expect(find.text('View all'), findsOneWidget);
    expect(find.text('Edit zone'), findsOneWidget);
  });

  testWidgets('Today caps Recent Delivery at four rows', (tester) async {
    await pumpAt(tester, const VendorLocation(VRoute.today));
    expect(find.text('Delivered'), findsNWidgets(5)); // 4 pills + KPI label
    expect(find.text('Need Attention'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Need Attention')).dy,
      lessThan(852 - Sizes.nav),
    );
  });

  testWidgets('Orders header carries search and add only', (tester) async {
    await pumpAt(tester, const VendorLocation(VRoute.orders));
    expect(find.byTooltip('Search'), findsOneWidget);
    expect(find.byTooltip('Add order'), findsOneWidget);
    expect(find.byTooltip('Filter'), findsNothing);
  });

  testWidgets('notification centre manages read state and deletion', (
    tester,
  ) async {
    await pumpAt(tester, const VendorLocation(VRoute.notificationInbox));
    final app = AppScope.read(tester.element(find.byType(Scaffold).first));
    expect(app.unreadNotifications, 2);

    // Tap opens an unread entry and marks it read.
    await tester.tap(find.text('3 orders need your action'));
    await tester.pumpAndSettle();
    expect(app.unreadNotifications, 1);

    // Swipe left deletes, with Undo.
    await tester.drag(find.text('System update'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('System update'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('System update'), findsOneWidget);

    // Header menu: mark all as read, then clear.
    await tester.tap(find.byTooltip('Notification options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(app.unreadNotifications, 0);
    await tester.tap(find.byTooltip('Notification options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all notifications'));
    await tester.pumpAndSettle();
    expect(find.text("You're all caught up."), findsOneWidget);
  });

  testWidgets('invite QR opens in a modal, not inline', (tester) async {
    await pumpAt(tester, const VendorLocation(VRoute.riderRegistrationLink));
    expect(find.text('Scan to join'), findsNothing);
    await tester.tap(find.text('Show QR code'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Scan to join'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('order identity is centred on the hero', (tester) async {
    await pumpAt(
      tester,
      const VendorLocation(VRoute.orderDetail, entityId: 'ord-1001'),
    );
    expect(tester.getCenter(find.text('ORD-1001')).dx, closeTo(196.5, 1));
    expect(find.text('Directions'), findsOneWidget);
  });
}
