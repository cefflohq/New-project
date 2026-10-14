import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/env.dart';
import '../core/theme.dart';
import 'google_maps.dart';
import 'map_tiles.dart';

/// Mini map of the customer's pinned drop point. Pan-only (no zoom/rotate);
/// tapping it calls [onTap] so the Driver can open navigation. Raster
/// OpenStreetMap tiles work on Flutter web, Android and iOS; temporary until
/// the Mapbox switch.
bool get _mapbox => Env.mapboxPublicToken.startsWith('pk.');

class DeliveryPinMap extends StatelessWidget {
  const DeliveryPinMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onTap,
    this.height = 220,
  });

  final double latitude;
  final double longitude;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (Env.googleMaps) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
        child: SizedBox(
          height: height,
          child: GoogleDeliveryPinMap(latitude: latitude, longitude: longitude, onTap: onTap),
        ),
      );
    }
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
        ),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag,
            ),
            onTap: (_, _) => onTap(),
          ),
          children: [
            // Mapbox Streets when the build carries a pk. token (Founder
            // 2026-10-12); CARTO Positron otherwise.
            if (_mapbox)
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}{r}?access_token={token}',
                additionalOptions: const {'token': Env.mapboxPublicToken},
                retinaMode: RetinaMode.isHighDensity(context),
                userAgentPackageName: 'my.cefflo.driver',
              )
            else
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
                userAgentPackageName: 'my.cefflo.driver',
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: const Icon(
                    LucideIcons.mapPin,
                    size: 40,
                    color: CefColors.navy,
                  ),
                ),
              ],
            ),
            MapCredit(mapCredit),
          ],
        ),
      ),
    );
  }
}
