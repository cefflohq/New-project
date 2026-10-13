import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../core/env.dart';

/// True when the build carries a public Mapbox token (pk.*).
bool get mapboxTiles => Env.mapboxPublicToken.startsWith('pk.');

/// Mapbox Streets raster tiles (Founder 2026-10-12); CARTO Positron when the
/// build has no token.
Widget cefTileLayer(BuildContext context) => mapboxTiles
    ? TileLayer(
        urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}{r}?access_token={token}',
        additionalOptions: const {'token': Env.mapboxPublicToken},
        retinaMode: RetinaMode.isHighDensity(context),
        userAgentPackageName: 'my.cefflo.driver',
      )
    : TileLayer(
        urlTemplate:
            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
        subdomains: const ['a', 'b', 'c', 'd'],
        retinaMode: RetinaMode.isHighDensity(context),
        userAgentPackageName: 'my.cefflo.driver',
      );

String get mapCredit =>
    mapboxTiles ? '© Mapbox © OpenStreetMap' : '© OpenStreetMap © CARTO';

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
        child: Container(
          height: 22,
          padding: EdgeInsets.symmetric(horizontal: _open ? 8 : 0),
          constraints: const BoxConstraints(minWidth: 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(11),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 3),
            ],
          ),
          alignment: Alignment.center,
          child: _open
              ? Text(
                  widget.text,
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                )
              : const Icon(Icons.info_outline, size: 14, color: Colors.black54),
        ),
      ),
    ),
  );
}
