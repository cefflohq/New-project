import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/live_location.dart';

/// Browser/OS location via geolocator: foreground only, distance-filtered.
class GeolocatorSource implements LocationSource {
  static LocationFix _fix(Position p) => LocationFix(
    latitude: p.latitude,
    longitude: p.longitude,
    accuracy: p.accuracy,
    heading: p.heading,
    speed: p.speed,
  );

  Future<bool> _allowed() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// Browsers report TIMEOUT between fixes and some platforms end the
  /// stream on error, so the watch restarts itself (after 5 s) for as long
  /// as it is listened to.
  @override
  Stream<LocationFix> watch() {
    StreamSubscription<Position>? sub;
    Timer? restart;
    late final StreamController<LocationFix> out;
    void start() {
      restart?.cancel();
      sub?.cancel();
      sub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 20,
            ),
          ).listen(
            (p) => out.add(_fix(p)),
            onError: (_) => restart = Timer(const Duration(seconds: 5), start),
            onDone: () => restart = Timer(const Duration(seconds: 5), start),
            cancelOnError: true,
          );
    }

    out = StreamController<LocationFix>(
      onListen: () async {
        if (await _allowed()) start();
      },
      onCancel: () async {
        restart?.cancel();
        await sub?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Future<LocationFix?> current() async {
    try {
      if (!await _allowed()) return null;
      return _fix(await Geolocator.getCurrentPosition());
    } catch (_) {
      return null;
    }
  }
}

/// Supabase Realtime channel `trk:<live_topic>`: reads viewers' Presence
/// keys and sends a coordinate-free `loc` hint after each write.
class SupabaseLiveChannel implements LiveChannel {
  SupabaseLiveChannel(SupabaseClient client, String topic)
    : _client = client,
      _channel = client.channel(topic) {
    _channel
        .onPresenceSync((_) => _emit())
        .onPresenceJoin((_) => _emit())
        .onPresenceLeave((_) => _emit())
        .subscribe();
  }

  final SupabaseClient _client;
  final RealtimeChannel _channel;
  final _changes = StreamController<void>.broadcast();

  void _emit() => _changes.add(null);

  @override
  Set<String> get presentKeys => {
    for (final state in _channel.presenceState())
      for (final p in state.presences)
        if (p.payload['k'] is String) p.payload['k'] as String,
  };

  @override
  Stream<void> get presenceChanges => _changes.stream;

  @override
  Future<void> sendLocationHint() async {
    await _channel.sendBroadcastMessage(event: 'loc', payload: const {});
  }

  @override
  Future<void> close() async {
    await _client.removeChannel(_channel);
    await _changes.close();
  }
}
