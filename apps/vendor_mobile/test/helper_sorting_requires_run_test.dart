import 'package:cefflo_vendor_mobile/core/auth_access.dart';
import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:cefflo_vendor_mobile/ui/screens/helper_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sorting requires a Run (migration 20261012140000). A Helper board with
/// one Zone: two orders with a Run and one without. Records every write.
class _BoardRepo extends VendorRepository {
  _BoardRepo() : super.demo(demoRole: 'helper');

  final calls = <String>[];
  final status = {
    'o-run-1': 'not_started',
    'o-run-2': 'not_started',
    'o-norun': 'not_started',
  };
  final runOf = {'o-run-1': 'run-1', 'o-run-2': 'run-1', 'o-norun': null};
  bool packingConfirmed = false;

  @override
  Future<FulfilmentBoard> myFulfilmentBoard(String businessId) async =>
      FulfilmentBoard(
        businessName: 'Test Kitchen',
        businessToday: '2026-10-12',
        tasks: [
          for (final id in status.keys)
            FulfilmentTask(
              orderId: id,
              orderNumber: '#$id',
              customerName: id,
              items: const ['Nasi'],
              lines: const [(name: 'Nasi', qty: 1)],
              status: status[id]!,
              zoneId: 'zone-a',
              zoneName: 'Alpha',
              runId: runOf[id],
              orderDate: '2026-10-12',
              packingConfirmed: packingConfirmed,
            ),
        ],
      );

  @override
  Future<void> advancePreparation(String orderId, String next) async {
    calls.add('advance:$orderId:$next');
    if (next == 'sorted' && runOf[orderId] == null) {
      throw RepositoryError('sorting requires a run');
    }
    status[orderId] = next;
  }

  @override
  Future<void> confirmPacking(
    String businessId,
    String? zoneId,
    String? orderDate,
  ) async {
    calls.add('confirmPacking:$zoneId:$orderDate');
    packingConfirmed = true;
  }

  @override
  Future<void> confirmSorting(
    String businessId,
    String? zoneId,
    String? runId,
    String? orderDate,
  ) async {
    calls.add('confirmSorting:$zoneId:$runId:$orderDate');
    if (runId == null) throw RepositoryError('sorting requires a run');
    for (final id in status.keys) {
      if (runOf[id] == runId) status[id] = 'ready';
    }
  }
}

void main() {
  testWidgets('without a Run the slide confirms packing only; with a Run it '
      'still sorts and releases', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _BoardRepo();
    await tester.pumpWidget(
      VendorMobileApp(
        repo: repo,
        access: AuthAccess.helper,
        auditLocation: const VendorLocation(VRoute.today),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zones').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    // Packing before a Run is still allowed.
    for (final id in ['o-run-1', 'o-run-2', 'o-norun']) {
      await tester.tap(find.byKey(ValueKey('order-$id')));
      await tester.pumpAndSettle();
    }
    expect(repo.status.values.toSet(), {'packed'});
    expect(find.text('Waiting for a run'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('slide-handle')),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();

    // Packing confirmed; sorting only for orders that have a Run.
    expect(repo.calls, contains('confirmPacking:zone-a:2026-10-12'));
    expect(repo.calls, isNot(contains('advance:o-norun:sorted')));
    expect(repo.calls, contains('advance:o-run-1:sorted'));
    expect(repo.calls, contains('advance:o-run-2:sorted'));
    expect(repo.calls.where((c) => c.startsWith('confirmSorting')), [
      'confirmSorting:zone-a:run-1:null',
    ]);
    expect(repo.status, {
      'o-run-1': 'ready',
      'o-run-2': 'ready',
      'o-norun': 'packed',
    });
    // The Helper is told the rest waits for a Run; no Ready screen.
    expect(
      find.text(
        'Packed. Sorting starts once the vendor builds a run for these orders.',
      ),
      findsOneWidget,
    );
    expect(find.text('This zone is ready for driver pickup.'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Nothing left the slide can do until the Run exists.
    final slider = tester.widget<SlideToConfirm>(find.byType(SlideToConfirm));
    expect(slider.enabled, isFalse);
  });
}
