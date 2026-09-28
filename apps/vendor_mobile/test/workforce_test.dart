import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// D-74 workforce: Operator or Helper invitations only (never Owner), both
// authenticated; a Helper resolves into the fulfilment workspace only.
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
    expect(find.textContaining('?type=team&token='), findsOneWidget);
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
    expect(find.textContaining('To prepare'), findsOneWidget);
    expect(find.text('#CF-001'), findsOneWidget);
    expect(find.text('Start preparing'), findsOneWidget);
    // No Vendor navigation for a Helper.
    for (final tab in ['Orders', 'Zones', 'Riders', 'More']) {
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

  test('an Operator is not the Owner (Subscription hidden)', () {
    final op = Business.fromRow({
      'business_id': 'b1',
      'business_name': 'Shop',
      'member_role': 'operator',
    });
    expect(op.isOwner, isFalse);
  });
}
