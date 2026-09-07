import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('route inventory', () {
    test('covers V-01..V-60 exactly once', () {
      final ids = routeSpecs.values
          .map((s) => s.id)
          .where((id) => id.startsWith('V-'))
          .toList();
      expect(ids.toSet(), hasLength(60));
      for (var i = 1; i <= 60; i++) {
        expect(ids, contains('V-${i.toString().padLeft(2, '0')}'));
      }
    });

    test('additional surfaces are not counted inside the 60', () {
      final extra = routeSpecs.values.where((s) => !s.id.startsWith('V-')).toList();
      expect(extra, isNotEmpty);
      for (final s in extra) {
        expect(s.id, startsWith('X-'));
      }
    });

    test('every declared parent exists', () {
      for (final s in routeSpecs.values) {
        if (s.parent != null) expect(routeSpecs.containsKey(s.parent), isTrue);
      }
    });
  });

  group('audit fix 1 — parent navigation', () {
    test('detail routes return to their parent, not Today', () {
      expect(routeSpecs[VRoute.orderDetail]!.parent, VRoute.orders);
      expect(routeSpecs[VRoute.editOrder]!.parent, VRoute.orderDetail);
      expect(routeSpecs[VRoute.riderDetail]!.parent, VRoute.riders);
      expect(routeSpecs[VRoute.teamMemberDetail]!.parent, VRoute.team);
      expect(routeSpecs[VRoute.zoneDetail]!.parent, VRoute.zones);
      expect(routeSpecs[VRoute.productDetail]!.parent, VRoute.products);
      expect(routeSpecs[VRoute.changePassword]!.parent, VRoute.security);
    });

    test('subpages keep the owning tab active', () {
      expect(routeSpecs[VRoute.orderDetail]!.tab, NavTab.orders);
      expect(routeSpecs[VRoute.reviewDispatch]!.tab, NavTab.zones);
      expect(routeSpecs[VRoute.riderDetail]!.tab, NavTab.riders);
      expect(routeSpecs[VRoute.subscription]!.tab, NavTab.menu);
    });
  });

  group('audit fix 2 — id-bound details', () {
    test('detail routes require an entity id', () {
      for (final r in [
        VRoute.orderDetail,
        VRoute.editOrder,
        VRoute.zoneDetail,
        VRoute.riderDetail,
        VRoute.teamMemberDetail,
        VRoute.productDetail,
      ]) {
        expect(routeSpecs[r]!.requiresEntityId, isTrue, reason: r.name);
      }
    });

    test('locations with different ids are distinct', () {
      const a = VendorLocation(VRoute.orderDetail, entityId: 'a');
      const b = VendorLocation(VRoute.orderDetail, entityId: 'b');
      expect(a, isNot(equals(b)));
    });
  });

  group('audit fix 4 — canonical statuses are never renamed', () {
    test('wire values match the database enum', () {
      expect(
        DeliveryStatus.values.map((s) => s.wire).toList(),
        ['created', 'ready_for_pickup', 'picked_up', 'out_for_delivery',
         'arrived', 'delivered', 'issue', 'cancelled'],
      );
    });

    test('tabs group statuses without overlapping', () {
      final seen = <DeliveryStatus>{};
      for (final tab in OrderTab.values) {
        for (final s in tab.statuses) {
          expect(seen.add(s), isTrue, reason: '${s.name} appears in two tabs');
        }
      }
      expect(OrderTab.ongoing.accepts(DeliveryStatus.readyForPickup), isTrue);
      expect(OrderTab.issue.accepts(DeliveryStatus.issue), isTrue);
      expect(OrderTab.delivered.accepts(DeliveryStatus.delivered), isTrue);
    });
  });

  group('audit fix 3 — status-appropriate actions', () {
    VendorOrder order(DeliveryStatus s, {String? rider}) => VendorOrder(
      id: 'id',
      status: s,
      customerName: 'A',
      customerPhone: '1',
      deliveryAddress: 'B',
      createdAt: DateTime(2026),
      assignedRiderId: rider,
    );

    test('a delivered order offers no planning or edit action', () {
      final o = order(DeliveryStatus.delivered);
      expect(o.canPlan, isFalse);
      expect(o.canEdit, isFalse);
      expect(o.isTerminal, isTrue);
    });

    test('an unassigned ready order can be planned', () {
      expect(order(DeliveryStatus.readyForPickup).canPlan, isTrue);
      expect(order(DeliveryStatus.readyForPickup, rider: 'r').canPlan, isFalse);
    });

    test('only a created order can be approved', () {
      expect(order(DeliveryStatus.created).canApprove, isTrue);
      expect(order(DeliveryStatus.delivered).canApprove, isFalse);
    });
  });
}
