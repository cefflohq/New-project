import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/env.dart';
import 'my_towns.dart';

/// Find Jobs "Change location" search (Founder 2026-10-12): Mapbox Geocoding
/// v6, limited to Malaysian towns, localities, neighbourhoods and postcodes,
/// which Mapbox resolves well. Returns [] without a pk. token or on any
/// failure, so the bundled [myTowns] list stays the fallback.
Future<List<MyTown>> searchPlaces(String query, {http.Client? client}) async {
  final q = query.trim();
  if (q.length < 3 || !Env.mapboxPublicToken.startsWith('pk.')) return const [];
  final uri = Uri.https('api.mapbox.com', '/search/geocode/v6/forward', {
    'q': q,
    'country': 'my',
    'types': 'place,locality,neighborhood,postcode',
    'limit': '6',
    'access_token': Env.mapboxPublicToken,
  });
  try {
    final res = await (client ?? http.Client())
        .get(uri)
        .timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return const [];
    final features =
        (jsonDecode(res.body) as Map<String, dynamic>)['features'] as List? ??
        const [];
    return [
      for (final f in features.cast<Map<String, dynamic>>())
        if (f['geometry']?['coordinates'] is List)
          MyTown(
            (f['properties']?['name'] ?? '') as String,
            ((f['properties']?['place_formatted'] ?? '') as String).replaceAll(
              ', Malaysia',
              '',
            ),
            ((f['geometry']['coordinates'] as List)[1] as num).toDouble(),
            ((f['geometry']['coordinates'] as List)[0] as num).toDouble(),
          ),
    ];
  } catch (_) {
    return const [];
  }
}
