import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import '../core/env.dart';

/// Google roadmap tiles through the Map Tiles API (Founder 2026-10-15:
/// Google Maps), drawn under the existing flutter_map pins, lines and zones.
/// The key is restricted to this app's package + signing cert, so the
/// requests carry both; a debug-signed build is refused and falls back.
const _package = 'com.cefflo.driver';
const _certSha1 = 'B545297662DAAC96A6935870895AF1173732F099';

bool get googleTiles => Env.googleMapsApiKey.isNotEmpty;

Map<String, String> get _headers => kIsWeb
    ? const {}
    : const {'X-Android-Package': _package, 'X-Android-Cert': _certSha1};

class _Session {
  Future<String?>? future;
  DateTime expiry = DateTime(0);
  bool pending = false;
}

/// One tile session per map language, so labels follow the app's language.
final _sessions = <String, _Session>{};

/// One tile session per app run and language (a session lasts ~2 weeks); a
/// failed request is retried after a minute.
Future<String?> _googleSession(String language) {
  final s = _sessions.putIfAbsent(language, _Session.new);
  // Reuse the in-flight or live session: the map rebuilds its layers on every
  // camera frame, and a fresh future each build would never finish loading.
  if (s.future != null && (s.pending || DateTime.now().isBefore(s.expiry))) {
    return s.future!;
  }
  s.pending = true;
  return s.future = () async {
    try {
      final res = await http.post(
        Uri.parse(
          'https://tile.googleapis.com/v1/createSession?key=${Env.googleMapsApiKey}',
        ),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'mapType': 'roadmap',
          'language': language,
          'region': 'MY',
          'scale': 'scaleFactor2x',
          'highDpi': true,
        }),
      );
      if (res.statusCode != 200) throw StateError('tiles ${res.statusCode}');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      s.expiry = DateTime.fromMillisecondsSinceEpoch(
        int.parse(body['expiry'] as String) * 1000,
      ).subtract(const Duration(hours: 1));
      s.pending = false;
      return body['session'] as String;
    } catch (e) {
      debugPrint('Google tiles unavailable: $e');
      // Keep the failed result for a minute so rebuilds show the fallback
      // instead of retrying every frame.
      s.expiry = DateTime.now().add(const Duration(minutes: 1));
      s.pending = false;
      return null;
    }
  }();
}

/// Google tiles when the build has a key and a session opens; [fallback]
/// (Mapbox / CARTO) otherwise.
class GoogleTileLayer extends StatelessWidget {
  const GoogleTileLayer({super.key, required this.fallback});
  final WidgetBuilder fallback;

  @override
  Widget build(BuildContext context) {
    if (!googleTiles) return fallback(context);
    return FutureBuilder<String?>(
      future: _googleSession(
        Localizations.localeOf(context).languageCode == 'ms'
            ? 'ms-MY'
            : 'en-MY',
      ),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final session = snap.data;
        if (session == null) return fallback(context);
        return TileLayer(
          urlTemplate: 'https://tile.googleapis.com/v1/2dtiles/{z}/{x}/{y}?session={session}&key={key}',
          additionalOptions: {'session': session, 'key': Env.googleMapsApiKey},
          // A mutable copy: flutter_map adds its own User-Agent to this map.
          tileProvider: NetworkTileProvider(headers: {..._headers}),
          maxNativeZoom: 22,
          userAgentPackageName: _package,
        );
      },
    );
  }
}

/// Google's required on-map credit.
const googleCredit = 'Map data © Google';
