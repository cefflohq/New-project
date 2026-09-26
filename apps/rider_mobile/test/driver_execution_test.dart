import 'package:cefflo_rider_mobile/core/app_state.dart';
import 'package:cefflo_rider_mobile/data/demo_data.dart';
import 'package:cefflo_rider_mobile/data/driver_models.dart';
import 'package:cefflo_rider_mobile/data/models.dart';
import 'package:cefflo_rider_mobile/data/rider_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Real-mode repository with in-memory rows that records every canonical
/// call. The Supabase client is never used.
class _FakeRepo extends RiderRepository {
  _FakeRepo(this.orders)
    : super(SupabaseClient('http://127.0.0.1:1', 'test-publishable-key'));

  List<RiderOrder> orders;
  final calls = <String>[];

  @override
  Future<List<RiderRelationship>> myRiderRelationships() async => const [
    RiderRelationship(
      id: 'rider-1',
      businessId: 'biz-a',
      status: 'active',
      name: 'Aiman',
      businessName: 'Dapur Manis',
      phone: '+60100000002',
      plate: 'VFY 1',
    ),
  ];

  @override
  Future<List<RiderOrder>> myOrders(String riderId) async => orders;

  @override
  Future<List<DeliverySession>> sessions(String businessId) async => const [
    DeliverySession(id: 's-1', name: 'Shah Alam Run'),
  ];

  @override
  Future<void> acceptRun({
    required String riderId,
    required String sessionId,
  }) async => calls.add('accept_run $riderId $sessionId');

  @override
  Future<void> startPickupRun({
    required String riderId,
    required String sessionId,
  }) async => calls.add('start_pickup_run $sessionId');

  @override
  Future<void> transition({
    required String riderId,
    required String orderId,
    required String next,
  }) async => calls.add('rider_transition $orderId $next');

  @override
  Future<void> saveRunSequence({
    required String riderId,
    required String sessionId,
    required List<String> orderedOrderIds,
  }) async => calls.add('save_run_sequence ${orderedOrderIds.join(',')}');

  @override
  Future<void> startRunDelivery({
    required String riderId,
    required String sessionId,
  }) async => calls.add('start_run_delivery $sessionId');

  @override
  Future<void> reportDeliveryIssue({
    required String riderId,
    required String orderId,
    required String reasonType,
    String? note,
  }) async => calls.add('rider_report_delivery_issue $orderId $reasonType');
}

RiderOrder _order(
  String id,
  DeliveryStatus status, {
  String assignment = 'accepted',
  int? seq,
  bool locked = false,
}) => RiderOrder(
  id: id,
  publicRef: 'CF-$id',
  orderNumber: '#CF-00$id',
  customerName: 'Customer $id',
  customerPhone: '+6010000$id',
  address: 'Seksyen 7, Shah Alam',
  itemCount: 1,
  note: '',
  status: status,
  deliverySessionId: 's-1',
  sequence: seq,
  assignmentStatus: assignment,
  items: const [RiderOrderItem(name: 'Brownie Box', quantity: 2)],
  sequenceLocked: locked,
);

Future<(AppState, _FakeRepo)> _hydrate(List<RiderOrder> orders) async {
  final repo = _FakeRepo(orders);
  final app = AppState(repo);
  await app.loadSession();
  return (app, repo);
}

void main() {
  test(
    'a dispatched run is projected from backend rows, not demo data',
    () async {
      final (app, _) = await _hydrate([
        _order('1', DeliveryStatus.created, assignment: 'assigned'),
        _order('2', DeliveryStatus.created, assignment: 'assigned'),
      ]);
      expect(app.runPhase, RunPhase.accept);
      expect(app.hasRun, isTrue);
      expect(app.currentRun.id, 's-1');
      expect(app.currentRun.reference, 'Shah Alam Run');
      expect(app.currentRun.stops.map((s) => s.id), ['1', '2']);
      expect(app.currentRun.stops.first.reference, '#CF-001');
      expect(app.currentRun.stops.first.items.single.name, 'Brownie Box');
      expect(app.currentRun.distanceKm, isNull);
      expect(app.profile.fullName, 'Aiman');
      expect(app.profile.fullName, isNot(DemoData.activeProfile.fullName));
      expect(app.business?.name, 'Dapur Manis');
      expect(app.todayAssigned, 2);
      expect(app.notifications, isEmpty);
      expect(app.documents, isEmpty);
    },
  );

  test('no dispatched run shows no run, never the demo run', () async {
    final (app, _) = await _hydrate(const []);
    expect(app.hasRun, isFalse);
    expect(app.currentRun.stops, isEmpty);
    expect(app.currentRun.reference, isNot(DemoData.currentRun.reference));
  });

  test('phases follow canonical assignment and order states', () async {
    expect(
      (await _hydrate([_order('1', DeliveryStatus.created)])).$1.runPhase,
      RunPhase.pickup,
    );
    expect(
      (await _hydrate([_order('1', DeliveryStatus.pickedUp)])).$1.runPhase,
      RunPhase.route,
    );
    expect(
      (await _hydrate([
        _order('1', DeliveryStatus.pickedUp, seq: 1, locked: true),
      ])).$1.runPhase,
      RunPhase.delivering,
    );
    expect(
      (await _hydrate([_order('1', DeliveryStatus.outForDelivery, seq: 1)]))
          .$1
          .runPhase,
      RunPhase.delivering,
    );
    final done = (await _hydrate([
      _order('1', DeliveryStatus.delivered, seq: 1),
    ])).$1;
    expect(done.runPhase, RunPhase.done);
    expect(done.currentRun.state, RunState.completed);
  });

  test(
    'accept -> pickup -> route call the canonical contracts in order',
    () async {
      final (app, repo) = await _hydrate([
        _order('1', DeliveryStatus.created, assignment: 'assigned'),
        _order('2', DeliveryStatus.readyForPickup, assignment: 'assigned'),
      ]);
      await app.acceptCurrentRun();
      expect(repo.calls, ['accept_run rider-1 s-1']);

      repo.calls.clear();
      await app.confirmPickup();
      expect(repo.calls, [
        'start_pickup_run s-1',
        'rider_transition 1 ready_for_pickup',
        'rider_transition 1 picked_up',
        'rider_transition 2 picked_up',
      ]);

      repo.orders = [
        _order('1', DeliveryStatus.pickedUp),
        _order('2', DeliveryStatus.pickedUp),
      ];
      await app.refreshOrders();
      expect(app.runPhase, RunPhase.route);
      repo.calls.clear();
      await app.confirmRouteAndStart();
      expect(repo.calls, ['save_run_sequence 1,2', 'start_run_delivery s-1']);
    },
  );

  test('arrival and issue reporting use canonical reasons only', () async {
    final (app, repo) = await _hydrate([
      _order('1', DeliveryStatus.pickedUp, seq: 1, locked: true),
    ]);
    expect(app.runPhase, RunPhase.delivering);
    await app.arriveAt('1');
    expect(repo.calls, [
      'rider_transition 1 out_for_delivery',
      'rider_transition 1 arrived',
    ]);

    repo.calls.clear();
    await app.reportIssue('1', IssueReason.customerNotAvailable, 'No answer');
    expect(repo.calls, ['rider_report_delivery_issue 1 customer_unreachable']);

    expect(
      () => app.reportIssue(
        '1',
        IssueReason.customerRequestedReschedule,
        'Later',
      ),
      throwsA(isA<RepositoryError>()),
    );
  });
}
