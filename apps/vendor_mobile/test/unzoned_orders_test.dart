import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/l10n/l10n.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:cefflo_vendor_mobile/ui/screens/directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _unzoned = VendorOrder(
  id: 'ord-nozone',
  orderNumber: '#CF-777',
  status: DeliveryStatus.created,
  customerName: 'Aina Zainal',
  customerPhone: '+60 12 000 0000',
  deliveryAddress: 'Jalan Tiada Zon 1',
  createdAt: DateTime(2026, 10, 12, 9),
  approvedAt: DateTime(2026, 10, 12, 9, 5),
);

/// Demo data plus pre-dispatch orders without a zone; records zone updates.
class _UnzonedRepo extends VendorRepository {
  _UnzonedRepo() : super.demo();
  final updates = <String, String?>{};

  @override
  Future<List<VendorOrder>> orders(String businessId) async => [
    ...await super.orders(businessId),
    _unzoned,
    // Not listed: already has a rider, or already delivered.
    VendorOrder(
      id: 'ord-nozone-assigned',
      status: DeliveryStatus.created,
      customerName: 'Assigned',
      customerPhone: '+60 12 000 0001',
      deliveryAddress: 'x',
      createdAt: DateTime(2026, 10, 12),
      assignedRiderId: 'rider-ahmad',
    ),
    VendorOrder(
      id: 'ord-nozone-unapproved',
      status: DeliveryStatus.created,
      customerName: 'Unapproved',
      customerPhone: '+60 12 000 0003',
      deliveryAddress: 'x',
      createdAt: DateTime(2026, 10, 12),
    ),
    VendorOrder(
      id: 'ord-nozone-done',
      status: DeliveryStatus.delivered,
      customerName: 'Delivered',
      customerPhone: '+60 12 000 0002',
      deliveryAddress: 'x',
      createdAt: DateTime(2026, 10, 12),
    ),
  ];

  @override
  Future<VendorOrder> order(String orderId) async =>
      orderId == _unzoned.id ? _unzoned : super.order(orderId);

  @override
  Future<VendorOrder> updateOrder({
    required String orderId,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? notes,
    List<OrderItem>? items,
    String? zoneId,
    bool clearZone = false,
  }) async {
    updates[orderId] = zoneId;
    return _unzoned;
  }
}

Future<_UnzonedRepo> _pumpZones(WidgetTester tester) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = _UnzonedRepo();
  await tester.pumpWidget(
    VendorMobileApp(
      repo: repo,
      auditLocation: const VendorLocation(VRoute.zones),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUp(() => applyUiLocale(const Locale('en')));

  test('every approved/assigned/delivered/zoned combination', () {
    final orders = <VendorOrder>[];
    final expected = <String>[];
    for (final approved in [true, false]) {
      for (final assigned in [true, false]) {
        for (final delivered in [true, false]) {
          for (final zoned in [true, false]) {
            final id = 'a$approved-r$assigned-d$delivered-z$zoned';
            orders.add(
              VendorOrder(
                id: id,
                status: delivered
                    ? DeliveryStatus.delivered
                    : DeliveryStatus.created,
                customerName: id,
                customerPhone: '1',
                deliveryAddress: 'x',
                createdAt: DateTime(2026),
                approvedAt: approved ? DateTime(2026) : null,
                assignedRiderId: assigned ? 'rider-1' : null,
                zoneId: zoned ? 'zone-1' : null,
              ),
            );
            if (approved && !assigned && !delivered && !zoned) {
              expected.add(id);
            }
          }
        }
      }
    }
    expect(orders, hasLength(16));
    expect(unzonedOrders(orders).map((o) => o.id), expected);
    expect(expected, ['atrue-rfalse-dfalse-zfalse']);
  });

  test('cancelled or in-progress orders are not listed', () {
    for (final status in [
      DeliveryStatus.cancelled,
      DeliveryStatus.issue,
      DeliveryStatus.readyForPickup,
    ]) {
      final o = VendorOrder(
        id: '$status',
        status: status,
        customerName: 'x',
        customerPhone: '1',
        deliveryAddress: 'x',
        createdAt: DateTime(2026),
        approvedAt: DateTime(2026),
      );
      expect(unzonedOrders([o]), isEmpty, reason: '$status');
    }
  });

  test('only pre-dispatch orders without a zone are unzoned', () {
    final zoned = VendorOrder(
      id: 'z',
      status: DeliveryStatus.created,
      customerName: 'Z',
      customerPhone: '1',
      deliveryAddress: 'x',
      createdAt: DateTime(2026),
      zoneId: 'zone-pj',
    );
    expect(unzonedOrders([_unzoned, zoned]).map((o) => o.id), [_unzoned.id]);
  });

  test('labels exist in English and Malay', () {
    expect(L.noZoneCount(2), 'No zone (2)');
    expect(
      L.whySortedBeforeRun,
      'Sorted before a run: locked to its zone group',
    );
    expect(L.whyInLockedRun, 'In a locked run: needs whole-run recovery');
    expect(L.whyInPreparation, 'Being prepared');
    applyUiLocale(const Locale('ms'));
    expect(L.noZoneCount(2), 'Tiada zon (2)');
    expect(L.noZoneHint, isNot(contains('Assign')));
    expect(L.whySortedBeforeRun, contains('Diisih sebelum ada larian'));
    expect(L.whyInLockedRun, contains('larian yang dikunci'));
    expect(L.whyInPreparation, 'Sedang disediakan');
  });

  testWidgets('Zones map shows unzoned orders; one opens Order detail with the '
      'zone selector, which assigns a zone', (tester) async {
    final repo = await _pumpZones(tester);
    final entry = find.text('No zone (1)');
    expect(entry, findsOneWidget);

    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text('#CF-777'), findsOneWidget);
    expect(find.textContaining('Assigned'), findsNothing);
    expect(find.textContaining('Delivered ·'), findsNothing);
    expect(find.textContaining('Unapproved'), findsNothing);

    await tester.tap(find.text('#CF-777'));
    await tester.pumpAndSettle();
    final zoneRow = find.text(L.notSet);
    await tester.scrollUntilVisible(zoneRow, 200);
    await tester.tap(zoneRow);
    await tester.pumpAndSettle();
    final zones = await repo.zones('demo');
    final target = zones.firstWhere((z) => z.isActive);
    await tester.tap(find.text(target.name).last);
    await tester.pumpAndSettle();
    expect(repo.updates[_unzoned.id], target.id);
  });
}
