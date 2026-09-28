import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('a persisted run parses the canonical assignment + stops embed', () {
    final run = VendorRun.fromRow({
      'id': 'ra-1',
      'rider_id': 'r-1',
      'delivery_session_id': 's-1',
      'status': 'assigned',
      'assigned_at': '2026-09-25T09:00:00Z',
      'delivery_sessions': {'id': 's-1', 'name': 'Bangsar Run'},
      'delivery_stops': [
        {'order_id': 'o-2', 'sequence': 2, 'status': 'created'},
        {'order_id': 'o-1', 'sequence': 1, 'status': 'delivered'},
      ],
    });
    expect(run.sessionName, 'Bangsar Run');
    expect(run.orderIds, ['o-1', 'o-2']);
    expect(run.delivered, 1);
    expect(run.isOpen, isTrue);
    expect(run.statusLabel, 'Dispatched');
    expect(
      VendorRun.fromRow({
        'id': 'ra-2',
        'rider_id': 'r-1',
        'delivery_session_id': 's-1',
        'status': 'completed',
      }).isOpen,
      isFalse,
    );
  });

  test('dispatch idempotency keys are RFC 4122 v4 and unique', () {
    final a = VendorRepository.newIdempotencyKey();
    final b = VendorRepository.newIdempotencyKey();
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(a),
      isTrue,
    );
    expect(a, isNot(b));
  });

  test('prototype dispatch never fakes a backend success', () async {
    final repo = VendorRepository.demo();
    await expectLater(
      repo.dispatchRun(
        businessId: 'business-demo',
        sessionName: 'Bangsar Run',
        riderId: 'rider-ahmad',
        orderIds: const ['ord-1001'],
        idempotencyKey: VendorRepository.newIdempotencyKey(),
      ),
      throwsA(isA<RepositoryError>()),
    );
  });

  test('prototype zone delete archives instead of removing', () async {
    final repo = VendorRepository.demo();
    final zone = (await repo.zones('business-demo')).first;
    final archived = await repo.deactivateZone(zone.id);
    expect(archived.status, 'inactive');
    expect(
      (await repo.zones('business-demo')).map((z) => z.id),
      contains(zone.id),
    );
  });

  testWidgets('V-19 renders the persisted run, not fixed demo copy', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const VendorLocation(VRoute.runDetail, entityId: 'RUN-0182'),
    );
    expect(find.text('Bangsar Run'), findsOneWidget);
    expect(find.text('On the way'), findsWidgets);
    expect(find.text('1 of 3 delivered'), findsOneWidget);
    expect(find.text('Bangsar · Ahmad Razi · VFY 7281'), findsNothing);
    expect(find.textContaining('presentation-only'), findsNothing);
  });
}
