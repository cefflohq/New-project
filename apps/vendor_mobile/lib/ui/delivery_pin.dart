import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// Raster OpenStreetMap tiles work on Flutter web, Android and iOS. Temporary
/// until the Mapbox switch (Founder 2026-10-08).
const _tiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _tileAgent = 'my.cefflo.vendor';
const _malaysia = LatLng(4.2, 101.9);

const _attribution = SimpleAttributionWidget(
  source: Text('© OpenStreetMap'),
  alignment: Alignment.bottomLeft,
);

Widget _pinIcon() =>
    const Icon(LucideIcons.mapPin, size: 40, color: CefColors.navy);

/// Read-only mini map with the customer's pin. Pan-only, no zoom or rotate.
class DeliveryPinView extends StatelessWidget {
  const DeliveryPinView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 180,
  });
  final double latitude, longitude;
  final double height;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: context.c.border),
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
        ),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(urlTemplate: _tiles, userAgentPackageName: _tileAgent),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: _pinIcon(),
                ),
              ],
            ),
            _attribution,
          ],
        ),
      ),
    );
  }
}

/// A picked drop point. Null until the vendor locates or deliberately moves
/// the map at zoom >= 14 (same rule as the Storefront pin).
typedef PinPoint = ({double lat, double lng});

/// Fixed-centre-pin picker: the map moves under the pin. Locate + zoom
/// controls, like the Storefront.
class DeliveryPinPicker extends StatefulWidget {
  const DeliveryPinPicker({
    super.key,
    required this.initial,
    required this.onChanged,
    this.height = 260,
  });
  final PinPoint? initial;
  final ValueChanged<PinPoint> onChanged;
  final double height;

  @override
  State<DeliveryPinPicker> createState() => _DeliveryPinPickerState();
}

class _DeliveryPinPickerState extends State<DeliveryPinPicker> {
  final _controller = MapController();
  PinPoint? _pin;
  bool _moving = false, _locating = false;

  @override
  void initState() {
    super.initState();
    _pin = widget.initial;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(double lat, double lng) {
    _pin = (
      lat: double.parse(lat.toStringAsFixed(6)),
      lng: double.parse(lng.toStringAsFixed(6)),
    );
    widget.onChanged(_pin!);
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() => _set(p.latitude, p.longitude));
      _controller.move(LatLng(p.latitude, p.longitude), 17);
    } catch (_) {
      // Location off or timed out: the vendor can still move the map.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _zoom(double d) => _controller.move(
    _controller.camera.center,
    (_controller.camera.zoom + d).clamp(3, 19),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final start = _pin;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: start == null
                    ? _malaysia
                    : LatLng(start.lat, start.lng),
                initialZoom: start == null ? 5 : 17,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onPositionChanged: (camera, byUser) {
                  if (!byUser) return;
                  final moving = _moving;
                  _moving = true;
                  if (!moving) setState(() {});
                },
                onMapEvent: (e) {
                  if (e is! MapEventMoveEnd &&
                      e is! MapEventFlingAnimationEnd &&
                      e is! MapEventDoubleTapZoomEnd &&
                      e is! MapEventScrollWheelZoom) {
                    return;
                  }
                  if (!_moving) return;
                  _moving = false;
                  final cam = e.camera;
                  setState(() {
                    if (cam.zoom >= 14) {
                      _set(cam.center.latitude, cam.center.longitude);
                    }
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _tiles,
                  userAgentPackageName: _tileAgent,
                ),
                _attribution,
              ],
            ),
            // Fixed centre pin; its tip sits on the map centre.
            IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _pin != null || _moving ? 1 : 0,
                  child: Transform.translate(
                    offset: Offset(0, _moving ? -30 : -20),
                    child: _pinIcon(),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Material(
                color: c.card,
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    IconButton(
                      tooltip: L.zoomIn,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      onPressed: () => _zoom(1),
                    ),
                    Container(width: 24, height: 1, color: c.border),
                    IconButton(
                      tooltip: L.zoomOut,
                      icon: const Icon(LucideIcons.minus, size: 18),
                      onPressed: () => _zoom(-1),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 22,
              child: Material(
                color: c.card,
                elevation: 3,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: L.useMyLocation,
                  onPressed: _locating ? null : _locate,
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.locateFixed, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One drop on a [PinsMap]. [label] is the stop sequence when known.
typedef MapDrop = ({
  double lat,
  double lng,
  String? label,
  bool done,
  bool next,
});

/// Read-only map with several customer pins (run stops, zone orders). Fits
/// all pins; Malaysia overview when none. Pins only -- no rider location.
class PinsMap extends StatelessWidget {
  const PinsMap({
    super.key,
    required this.drops,
    this.height = 240,
    this.emptyLabel,
  });
  final List<MapDrop> drops;
  final double height;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final points = [for (final d in drops) LatLng(d.lat, d.lng)];
    final MapOptions options;
    if (points.length > 1) {
      options = MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(40),
          maxZoom: 16,
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
        ),
      );
    } else {
      options = MapOptions(
        initialCenter: points.isEmpty ? _malaysia : points.first,
        initialZoom: points.isEmpty ? 5.5 : 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
        ),
      );
    }
    Widget dot(MapDrop d) => Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: d.done
            ? c.success
            : d.next
            ? CefColors.ceffloMustard
            : CefColors.anchorBlue,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
      ),
      child: d.done
          ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
          : Text(
              d.label ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: d.next ? CefColors.navy : Colors.white,
              ),
            ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              options: options,
              children: [
                TileLayer(
                  urlTemplate: _tiles,
                  userAgentPackageName: _tileAgent,
                ),
                MarkerLayer(
                  markers: [
                    // Next stop last so it draws on top.
                    for (final d in [
                      ...drops.where((d) => !d.next),
                      ...drops.where((d) => d.next),
                    ])
                      Marker(
                        point: LatLng(d.lat, d.lng),
                        width: d.next ? 34 : 28,
                        height: d.next ? 34 : 28,
                        child: dot(d),
                      ),
                  ],
                ),
              ],
            ),
            // Plain text credit: SimpleAttributionWidget overflows before
            // the map has a width.
            Positioned(
              left: Gap.sm,
              bottom: Gap.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: Colors.white70,
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ),
            ),
            if (drops.isEmpty && emptyLabel != null)
              Positioned(
                left: Gap.md,
                right: Gap.md,
                top: Gap.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.md,
                    vertical: Gap.sm,
                  ),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    emptyLabel!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
