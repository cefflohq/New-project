import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/models.dart';

/// Opt-in diagnostics for staging qualification only
/// (`--dart-define=CEFFLO_LIVE_DEBUG=true`); silent otherwise.
const _liveDebug = bool.fromEnvironment('CEFFLO_LIVE_DEBUG');
void _log(String m) {
  if (_liveDebug) debugPrint('[live] $m');
}

/// Phase 2B.4 / D-66 — Demand-Aware Adaptive Tracking.
///
/// GPS sampling is local and cheap; only [UploadGate] decides when a sample
/// becomes a backend write. Demand comes from validated Realtime Presence
/// ([demandLevel]); a random channel participant never counts.
enum DemandLevel { low, medium, high }

class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
}

class _Policy {
  const _Policy(this.distanceM, this.minGap, this.stale);
  final double distanceM;
  final Duration minGap;
  final Duration stale;
}

class UploadGate {
  /// Never less than 10 s between two backend location writes (D-66).
  static const floor = Duration(seconds: 10);

  /// Moves below this are GPS noise and never uploaded as movement.
  static const noiseFloorM = 25.0;

  /// Fixes less accurate than this are discarded.
  static const maxAccuracyM = 50.0;

  static const _policies = {
    DemandLevel.low: _Policy(
      500,
      Duration(seconds: 120),
      Duration(minutes: 10),
    ),
    DemandLevel.medium: _Policy(
      150,
      Duration(seconds: 30),
      Duration(minutes: 3),
    ),
    DemandLevel.high: _Policy(50, Duration(seconds: 10), Duration(seconds: 60)),
  };

  LocationFix? _last;
  DateTime? _lastAt;
  bool _eventPending = false;

  DateTime? get lastUploadAt => _lastAt;

  /// A lifecycle event (pickup, route start, arrive, complete, issue, or a
  /// demand rise) wants one fresh coordinate, still subject to [floor].
  void requestEventUpload() => _eventPending = true;

  /// Demand rose: if the last upload is older than the new level's staleness
  /// limit, the next good fix is sent.
  void onLevelRaised(DemandLevel level, DateTime now) {
    final at = _lastAt;
    if (at == null || now.difference(at) > _policies[level]!.stale) {
      _eventPending = true;
    }
  }

  bool shouldUpload(LocationFix fix, DemandLevel level, DateTime now) {
    final accuracy = fix.accuracy;
    if (accuracy != null && accuracy > maxAccuracyM) return false;
    final at = _lastAt;
    final last = _last;
    if (at != null && now.difference(at) < floor) return false;
    if (last == null || at == null) return true;
    if (_eventPending) return true;
    final moved = distanceMeters(last, fix);
    final p = _policies[level]!;
    final since = now.difference(at);
    if (moved >= p.distanceM && since >= p.minGap) return true;
    if (moved >= noiseFloorM && since >= p.stale) return true;
    return false;
  }

  void markUploaded(LocationFix fix, DateTime now) {
    _last = fix;
    _lastAt = now;
    _eventPending = false;
  }

  void reset() {
    _last = null;
    _lastAt = null;
    _eventPending = false;
  }
}

double distanceMeters(LocationFix a, LocationFix b) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h.toDouble()));
}

bool isTrackable(DeliveryStatus s) =>
    s == DeliveryStatus.pickedUp ||
    s == DeliveryStatus.outForDelivery ||
    s == DeliveryStatus.arrived;

/// Level from validated Presence only. [presentKeys] are the keys announced
/// on the run's channel; [keyToOrder] comes from `rider_live_keys` for this
/// rider's own trackable orders. Unknown keys are ignored.
DemandLevel demandLevel({
  required Iterable<String> presentKeys,
  required Map<String, String> keyToOrder,
  required List<RiderOrder> orders,
}) {
  var level = DemandLevel.low;
  final byId = {for (final o in orders) o.id: o};
  for (final key in presentKeys.toSet()) {
    final order = byId[keyToOrder[key]];
    if (order == null || !isTrackable(order.status)) continue;
    final DemandLevel l;
    if (order.status == DeliveryStatus.arrived) {
      l = DemandLevel.high;
    } else if (!order.sequenceLocked || order.sequence == null) {
      l = DemandLevel.medium;
    } else {
      final ahead = orders.where(
        (o) =>
            o.deliverySessionId == order.deliverySessionId &&
            o.sequence != null &&
            o.sequence! < order.sequence! &&
            o.status != DeliveryStatus.delivered &&
            o.status != DeliveryStatus.cancelled &&
            o.status != DeliveryStatus.issue,
      );
      l = ahead.isEmpty ? DemandLevel.high : DemandLevel.medium;
    }
    if (l.index > level.index) level = l;
  }
  return level;
}

/// Platform seams, so the service logic is testable without GPS or sockets.
abstract class LocationSource {
  Stream<LocationFix> watch();
  Future<LocationFix?> current();
}

abstract class LiveChannel {
  /// Presence keys currently announced by viewers on this channel.
  Set<String> get presentKeys;
  Stream<void> get presenceChanges;
  Future<void> sendLocationHint();
  Future<void> close();
}

typedef ChannelFactory = LiveChannel Function(String topic);
typedef LocationWriter = Future<void> Function(String riderId, LocationFix fix);
typedef LiveKeysLoader =
    Future<List<({String orderId, String topic, String key})>> Function(
      String riderId,
    );

/// Runs only while this rider has a trackable order. One write serves every
/// viewer; the broadcast after it carries no coordinates.
class LiveLocationService {
  LiveLocationService({
    required this.source,
    required this.channelFor,
    required this.write,
    required this.loadKeys,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final LocationSource source;
  final ChannelFactory channelFor;
  final LocationWriter write;
  final LiveKeysLoader loadKeys;
  final DateTime Function() _now;

  final gate = UploadGate();
  final Map<String, LiveChannel> _channels = {};
  final List<StreamSubscription<void>> _presenceSubs = [];
  StreamSubscription<LocationFix>? _fixes;
  Map<String, String> _keyToOrder = const {};
  List<RiderOrder> _orders = const [];
  DemandLevel level = DemandLevel.low;
  bool _writing = false;
  String? _riderId;

  bool get active => _fixes != null;

  /// Called after every orders refresh.
  Future<void> sync(List<RiderOrder> orders, String riderId) async {
    _orders = orders;
    if (_riderId != null && _riderId != riderId) await stop();
    _riderId = riderId;
    if (!orders.any((o) => isTrackable(o.status))) {
      await stop();
      return;
    }
    final keys = await loadKeys(riderId);
    _keyToOrder = {for (final k in keys) k.key: k.orderId};
    final topics = keys.map((k) => k.topic).toSet();
    for (final t in _channels.keys.toList()) {
      if (!topics.contains(t)) {
        await _channels.remove(t)!.close();
      }
    }
    for (final t in topics) {
      if (_channels.containsKey(t)) continue;
      final ch = channelFor(t);
      _channels[t] = ch;
      _presenceSubs.add(ch.presenceChanges.listen((_) => _recompute()));
    }
    _fixes ??= source.watch().listen(_onFix);
    _recompute();
  }

  /// A lifecycle event wants a fresh coordinate now.
  Future<void> event() async {
    if (!active) return;
    gate.requestEventUpload();
    final fix = await source.current();
    if (fix != null) await _onFix(fix);
  }

  void _recompute() {
    final present = _channels.values.expand((c) => c.presentKeys);
    final next = demandLevel(
      presentKeys: present,
      keyToOrder: _keyToOrder,
      orders: _orders,
    );
    if (next.index > level.index) gate.onLevelRaised(next, _now());
    if (next != level) _log('level ${level.name} -> ${next.name}');
    level = next;
  }

  Future<void> _onFix(LocationFix fix) async {
    final now = _now();
    final riderId = _riderId;
    if (riderId == null || _writing || !gate.shouldUpload(fix, level, now)) {
      return;
    }
    _writing = true;
    try {
      await write(riderId, fix);
      gate.markUploaded(fix, now);
      _log('write ${level.name} ${fix.latitude.toStringAsFixed(5)}');
      for (final ch in _channels.values) {
        await ch.sendLocationHint();
      }
    } catch (_) {
      // A failed write is retried by the next qualifying fix.
    } finally {
      _writing = false;
    }
  }

  Future<void> stop() async {
    await _fixes?.cancel();
    _fixes = null;
    for (final s in _presenceSubs) {
      await s.cancel();
    }
    _presenceSubs.clear();
    for (final c in _channels.values) {
      await c.close();
    }
    _channels.clear();
    _keyToOrder = const {};
    level = DemandLevel.low;
    _riderId = null;
    gate.reset();
  }
}
