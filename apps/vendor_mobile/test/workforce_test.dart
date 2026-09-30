import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/auth_access.dart';
import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/ui/screens/auth.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// D-74 workforce: Operator or Helper invitations only (never Owner), both
// authenticated; a Helper resolves into the fulfilment workspace only.
class _NoMembershipRepo extends VendorRepository {
  _NoMembershipRepo() : super.demo();
  @override
  Future<List<Business>> myBusinesses() async => const [];
}

class _HelperRepo extends VendorRepository {
  _HelperRepo() : super.demo();
  @override
  Future<List<Business>> myBusinesses() async => const [
    Business(id: 'business-demo', name: 'Kopi Kita', role: 'helper'),
  ];
}

void main() {
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

  testWidgets('team invite offers Operator and Helper, never Owner', (
    tester,
  ) async {
    await pumpAt(tester, const VendorLocation(VRoute.helperRegistrationLink));
    expect(find.text('Operator'), findsOneWidget);
    expect(find.text('Helper'), findsOneWidget);
    expect(find.text('Owner'), findsNothing);
    expect(
      find.text(
        'Help manage daily delivery operations. Requires a Vendor account.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a Helper is invited by email into the team link', (
    tester,
  ) async {
    await pumpAt(tester, const VendorLocation(VRoute.helperRegistrationLink));
    await tester.tap(find.text('Helper'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Help prepare, pack and hand over orders. Uses the Cefflo Vendor app.',
      ),
      findsOneWidget,
    );
    expect(find.text('Email'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'aina@example.com');
    await tester.tap(find.text('Generate invite link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('?type=team&token='), findsWidgets);
    expect(find.textContaining('type=helper'), findsNothing);
  });

  testWidgets('a Helper lands in the fulfilment workspace, not the shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      VendorMobileApp(
        repo: _HelperRepo(),
        auditLocation: const VendorLocation(VRoute.today),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Kak Lina Kitchen'), findsOneWidget);
    expect(find.text('Required Items'), findsOneWidget);
    // No Vendor navigation for a Helper (Helper tabs only).
    for (final tab in ['Orders', 'Riders', 'Today']) {
      expect(find.text(tab), findsNothing);
    }
  });

  test('fulfilment rows carry no contact or address fields', () {
    final t = FulfilmentTask.fromRow({
      'order_id': 'o1',
      'order_number': '#CF-002',
      'customer_name': 'Aina',
      'items': [
        {'name': 'Nasi Lemak', 'quantity': 2},
      ],
      'preparation_status': 'ready',
      'handover_rider_name': 'Zahid',
      'customer_phone': '+60123',
      'delivery_address': 'Jalan 1',
    });
    expect(t.items, ['2× Nasi Lemak']);
    expect(t.handoverRiderName, 'Zahid');
  });

  test('sorting checkpoints and pickup parse per order', () {
    final t = FulfilmentTask.fromRow({
      'order_id': 'o2',
      'order_number': '#CF-041',
      'customer_name': 'Amir',
      'items': const [],
      'preparation_status': 'packed',
      'packing_confirmed': true,
      'zone_id': 'z1',
      'zone_name': 'Shah Alam',
      'run_id': 'r1',
      'order_date': '2026-09-29',
      'picked_up_at': '2026-09-29T03:34:00Z',
      'handover_rider_name': 'Amir',
    });
    expect(t.packingConfirmed, isTrue);
    expect(t.zoneId, 'z1');
    expect(t.runId, 'r1');
    expect(t.pickedUp, isTrue);
    final ext = FulfilmentTask.fromRow({
      'order_id': 'o3',
      'order_number': '#CF-042',
      'customer_name': 'Siti',
      'items': const [],
      'preparation_status': 'ready',
      'handover_external': {
        'provider_name': 'Lalamove',
        'driver_name': 'Ali',
        'vehicle': 'VAN 1234',
      },
    });
    expect(ext.handoverProvider, 'Lalamove · Ali · VAN 1234');
  });

  Future<void> pumpSignIn(WidgetTester tester, AuthAccess access) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      VendorMobileApp(repo: VendorRepository.demo(), access: access),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(SignInScreen), findsOneWidget);
  }

  testWidgets('Operator Sign-In shows the Operator context', (tester) async {
    await pumpSignIn(tester, AuthAccess.operator);
    expect(find.text('Operator Access'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to your store operations'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('standard Vendor Sign-In has no Operator context', (
    tester,
  ) async {
    await pumpSignIn(tester, AuthAccess.vendor);
    expect(find.text('Operator Access'), findsNothing);
    expect(find.text('Continue with Email'), findsOneWidget);
  });

  test('access hint comes only from the launch URL', () {
    expect(
      authAccessFromUri(Uri.parse('https://x/?access=operator')),
      AuthAccess.operator,
    );
    expect(authAccessFromUri(Uri.parse('https://x/')), AuthAccess.vendor);
    expect(
      authAccessFromUri(Uri.parse('https://x/?access=owner')),
      AuthAccess.vendor,
    );
  });

  test('Operator sign-in without a claimed membership never opens '
      'business setup', () async {
    final app = AppState(_NoMembershipRepo())..access = AuthAccess.operator;
    await app.loadSession();
    expect(app.business, isNull);
    expect(app.sessionError, contains('no Operator access yet'));
    expect(app.current.route, isNot(VRoute.welcomeSetup));
  });

  test('roles resolve from membership', () {
    final helper = Business.fromRow({
      'business_id': 'b1',
      'business_name': 'Shop',
      'member_role': 'helper',
    });
    expect(helper.isHelper, isTrue);
    expect(helper.isOwner, isFalse);
  });

  testWidgets('Operator Settings hide business details, Team, billing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      VendorMobileApp(
        repo: VendorRepository.demo(demoRole: 'operator'),
        access: AuthAccess.operator,
        auditLocation: const VendorLocation(VRoute.settings),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Business Profile'), findsNothing);
    expect(find.text('Team'), findsNothing);
    expect(find.text('Subscription'), findsNothing);
    expect(find.text('Storefront'), findsOneWidget); // Operator scope kept
  });

  testWidgets('Operator opening an Owner-only page lands on Settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      VendorMobileApp(
        repo: VendorRepository.demo(demoRole: 'operator'),
        access: AuthAccess.operator,
        auditLocation: const VendorLocation(VRoute.businessProfile),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Storefront'), findsOneWidget); // Settings, not profile
  });

  test('an Operator is not the Owner (Subscription hidden)', () {
    final op = Business.fromRow({
      'business_id': 'b1',
      'business_name': 'Shop',
      'member_role': 'operator',
    });
    expect(op.isOwner, isFalse);
  });
}
