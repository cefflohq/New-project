import 'package:flutter/material.dart';

import 'map_pin.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import 'map_tiles.dart';

/// Mini map of the customer's pinned drop point. Pan-only (no zoom/rotate);
/// tapping it calls [onTap] so the Driver can open navigation. Raster
/// OpenStreetMap tiles work on Flutter web, Android and iOS; temporary until
/// the Mapbox switch.

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
            cefTileLayer(context),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: const CefPin(size: 40),
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
