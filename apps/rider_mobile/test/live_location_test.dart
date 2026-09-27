import 'dart:async';

import 'package:cefflo_rider_mobile/core/live_location.dart';
import 'package:cefflo_rider_mobile/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

// ~111 m per 0.001 deg latitude.
LocationFix at(double northMeters, {double? accuracy = 10}) => LocationFix(
  latitude: 3.1 + northMeters / 111195.0,
  longitude: 101.6,
  accuracy: accuracy,
);

RiderOrder order(
  String id,
  DeliveryStatus status, {
  int? seq,
  bool locked = true,
}) => RiderOrder(
  id: id,
  publicRef: 'CF-$id',
  customerName: 'C',
  customerPhone: '',
  address: '',
  itemCount: 1,
  note: '',
  status: status,
  deliverySessionId: 's-1',
  sequence: seq,
  sequenceLocked: locked,
);

class FakeSource implements LocationSource {
  final controller = StreamController<LocationFix>.broadcast();
  LocationFix? next;
  @override
  Stream<LocationFix> watch() => controller.stream;
  @override
  Future<LocationFix?> current() async => next;
}

class FakeChannel implements LiveChannel {
  final keys = <String>{};
  final changes = StreamController<void>.broadcast();
  int hints = 0;
  bool closed = false;
  @override
  Set<String> get presentKeys => keys;
  @override
  Stream<void> get presenceChanges => changes.stream;
  @override
  Future<void> sendLocationHint() async => hints++;
  @override
  Future<void> close() async => closed = true;
}

void main() {
  final t0 = DateTime(2026, 9, 27, 12);

  group('UploadGate', () {
    test('never writes less than 10 s apart, even for events', () {
      final g = UploadGate()..markUploaded(at(0), t0);
      g.requestEventUpload();
      expect(
        g.shouldUpload(
          at(900),
          DemandLevel.high,
          t0.add(const Duration(seconds: 9)),
        ),
        isFalse,
      );
      expect(
        g.shouldUpload(
          at(900),
          DemandLevel.high,
          t0.add(const Duration(seconds: 10)),
        ),
        isTrue,
      );
    });

    test('stationary rider never uploads repeats, at any level', () {
      final g = UploadGate()..markUploaded(at(0), t0);
      for (final l in DemandLevel.values) {
        expect(
          g.shouldUpload(at(20), l, t0.add(const Duration(hours: 1))),
          isFalse,
        );
      }
    });

    test('movement thresholds per level', () {
      final g = UploadGate()..markUploaded(at(0), t0);
      final t = t0.add(const Duration(seconds: 130));
      expect(g.shouldUpload(at(60), DemandLevel.high, t), isTrue);
      expect(g.shouldUpload(at(60), DemandLevel.medium, t), isFalse);
      expect(g.shouldUpload(at(160), DemandLevel.medium, t), isTrue);
      expect(g.shouldUpload(at(160), DemandLevel.low, t), isFalse);
      expect(g.shouldUpload(at(510), DemandLevel.low, t), isTrue);
    });

    test('staleness fallback only after moving past the noise floor', () {
      final g = UploadGate()..markUploaded(at(0), t0);
      expect(
        g.shouldUpload(
          at(30),
          DemandLevel.high,
          t0.add(const Duration(seconds: 61)),
        ),
        isTrue,
      );
      expect(
        g.shouldUpload(
          at(30),
          DemandLevel.medium,
          t0.add(const Duration(seconds: 181)),
        ),
        isTrue,
      );
      expect(
        g.shouldUpload(
          at(30),
          DemandLevel.low,
          t0.add(const Duration(minutes: 9)),
        ),
        isFalse,
      );
      expect(
        g.shouldUpload(
          at(30),
          DemandLevel.low,
          t0.add(const Duration(minutes: 11)),
        ),
        isTrue,
      );
    });

    test('inaccurate fixes are discarded', () {
      final g = UploadGate();
      expect(
        g.shouldUpload(at(0, accuracy: 80), DemandLevel.high, t0),
        isFalse,
      );
      expect(g.shouldUpload(at(0, accuracy: 40), DemandLevel.high, t0), isTrue);
    });

    test('level rise forces one upload only when the last one is stale', () {
      final g = UploadGate()..markUploaded(at(0), t0);
      g.onLevelRaised(DemandLevel.high, t0.add(const Duration(seconds: 30)));
      expect(
        g.shouldUpload(
          at(0),
          DemandLevel.high,
          t0.add(const Duration(seconds: 30)),
        ),
        isFalse,
      );
      g.onLevelRaised(DemandLevel.high, t0.add(const Duration(seconds: 90)));
      expect(
        g.shouldUpload(
          at(0),
          DemandLevel.high,
          t0.add(const Duration(seconds: 90)),
        ),
        isTrue,
      );
    });
  });

  group('demandLevel (validated presence only)', () {
    final orders = [
      order('a', DeliveryStatus.outForDelivery, seq: 1),
      order('b', DeliveryStatus.outForDelivery, seq: 2),
      order('c', DeliveryStatus.delivered, seq: 0),
    ];
    final keys = {'ka': 'a', 'kb': 'b', 'kc': 'c'};

    test('no viewers or unknown keys = LOW', () {
      expect(
        demandLevel(presentKeys: const [], keyToOrder: keys, orders: orders),
        DemandLevel.low,
      );
      expect(
        demandLevel(
          presentKeys: const ['random'],
          keyToOrder: keys,
          orders: orders,
        ),
        DemandLevel.low,
      );
    });

    test('next stop viewer = HIGH, later stop viewer = MEDIUM', () {
      expect(
        demandLevel(
          presentKeys: const ['ka'],
          keyToOrder: keys,
          orders: orders,
        ),
        DemandLevel.high,
      );
      expect(
        demandLevel(
          presentKeys: const ['kb'],
          keyToOrder: keys,
          orders: orders,
        ),
        DemandLevel.medium,
      );
    });

    test(
      'finished order key never counts; unlocked sequence caps at MEDIUM',
      () {
        expect(
          demandLevel(
            presentKeys: const ['kc'],
            keyToOrder: keys,
            orders: orders,
          ),
          DemandLevel.low,
        );
        final unlocked = [
          order('a', DeliveryStatus.pickedUp, seq: 1, locked: false),
        ];
        expect(
          demandLevel(
            presentKeys: const ['ka'],
            keyToOrder: {'ka': 'a'},
            orders: unlocked,
          ),
          DemandLevel.medium,
        );
      },
    );

    test('arrived = HIGH', () {
      final o = [order('b', DeliveryStatus.arrived, seq: 5)];
      expect(
        demandLevel(
          presentKeys: const ['kb'],
          keyToOrder: {'kb': 'b'},
          orders: o,
        ),
        DemandLevel.high,
      );
    });
  });

  group('LiveLocationService', () {
    late FakeSource source;
    late FakeChannel channel;
    late List<LocationFix> writes;
    late DateTime now;
    late LiveLocationService svc;

    setUp(() {
      source = FakeSource();
      channel = FakeChannel();
      writes = [];
      now = t0;
      svc = LiveLocationService(
        source: source,
        channelFor: (_) => channel,
        write: (_, f) async => writes.add(f),
        loadKeys: (_) async => [(orderId: 'a', topic: 'trk:x', key: 'ka')],
        clock: () => now,
      );
    });

    test(
      'inactive without a trackable order; one write serves all viewers',
      () async {
        await svc.sync([order('a', DeliveryStatus.created)], 'r1');
        expect(svc.active, isFalse);

        await svc.sync([
          order('a', DeliveryStatus.outForDelivery, seq: 1),
        ], 'r1');
        expect(svc.active, isTrue);
        channel.keys.addAll({'ka', 'intruder'});
        channel.changes.add(null);
        await Future<void>.delayed(Duration.zero);
        expect(svc.level, DemandLevel.high);

        source.controller.add(at(0));
        await Future<void>.delayed(Duration.zero);
        expect(writes, hasLength(1));
        expect(channel.hints, 1);

        now = now.add(const Duration(seconds: 5));
        source.controller.add(at(200));
        await Future<void>.delayed(Duration.zero);
        expect(writes, hasLength(1), reason: '10 s floor');
      },
    );

    test('stops and closes the channel when nothing is trackable', () async {
      await svc.sync([order('a', DeliveryStatus.outForDelivery, seq: 1)], 'r1');
      await svc.sync([order('a', DeliveryStatus.delivered, seq: 1)], 'r1');
      expect(svc.active, isFalse);
      expect(channel.closed, isTrue);
    });

    test('lifecycle event uploads a fresh fix', () async {
      await svc.sync([order('a', DeliveryStatus.outForDelivery, seq: 1)], 'r1');
      source.next = at(0);
      await svc.event();
      expect(writes, hasLength(1));
    });
  });
}
