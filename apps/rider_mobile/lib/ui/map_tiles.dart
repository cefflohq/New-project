import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../core/env.dart';
import 'google_tiles.dart';

/// True when the build carries a public Mapbox token (pk.*).
bool get mapboxTiles => Env.mapboxPublicToken.startsWith('pk.');

/// Mapbox Streets raster tiles (Founder 2026-10-12); CARTO Positron when the
/// build has no token.
Widget cefTileLayer(BuildContext context) =>
    GoogleTileLayer(fallback: _fallbackTiles);

Widget _fallbackTiles(BuildContext context) => mapboxTiles
    ? TileLayer(
        urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}{r}?access_token={token}',
        additionalOptions: const {'token': Env.mapboxPublicToken},
        retinaMode: RetinaMode.isHighDensity(context),
        userAgentPackageName: 'my.cefflo.driver',
      )
    : TileLayer(
        urlTemplate:
            // CARTO's free tiles now need a key; OpenStreetMap is the keyless
            // fallback (Google is the real map).
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'my.cefflo.driver',
      );

String get mapCredit => googleTiles
    ? googleCredit
    : mapboxTiles
    ? '© Mapbox © OpenStreetMap'
    : '© OpenStreetMap';

/// Map data credit behind a small ⓘ (Founder 2026-10-13): the licences
/// (Mapbox, OpenStreetMap ODbL, geoBoundaries CC BY) require the credit to
/// be reachable on the map, not spelled out across it. Tap to show / hide.
class MapCredit extends StatefulWidget {
  const MapCredit(this.text, {super.key});
  final String text;

  @override
  State<MapCredit> createState() => _MapCreditState();
}

class _MapCreditState extends State<MapCredit> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomLeft,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _open = !_open),
        // Sized to its content: a 22 px circle closed, a pill when open
        // (a Container with alignment would stretch across the map).
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(11),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 3),
            ],
          ),
          child: _open
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    widget.text,
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                )
              : const SizedBox.square(
                  dimension: 22,
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.black54,
                  ),
                ),
        ),
      ),
    ),
  );
}

/// A map hint that shows for 2 s and then fades away (Founder 2026-10-13:
/// "No pinned ... yet" must not sit on the map).
class FadingMapHint extends StatefulWidget {
  const FadingMapHint({super.key, required this.child});
  final Widget child;

  @override
  State<FadingMapHint> createState() => _FadingMapHintState();
}

class _FadingMapHintState extends State<FadingMapHint> {
  bool _shown = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _shown = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      child: widget.child,
    ),
  );
}
