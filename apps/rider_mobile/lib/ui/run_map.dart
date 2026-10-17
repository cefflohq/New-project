import 'dart:async';

import 'map_pin.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/live_location.dart';
import '../core/theme.dart';
import '../data/driver_models.dart';
import '../data/live_adapters.dart';
import 'map_canvas.dart' show MapControlButton, MapRecenterPill;
import 'map_tiles.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// Real run map (Founder 2026-10-12): the run's pinned stops in their
/// current order, joined by straight lines (a sequence, not a road route),
/// plus the driver's own position. No pinned stops = an empty map, never
/// invented ones. [focus] highlights one stop (the active stop).
class RunMap extends StatefulWidget {
  const RunMap({
    super.key,
    required this.stops,
    this.focus,
    this.showControls = true,
  });

  final List<DriverStop> stops;
  final DriverStop? focus;
  final bool showControls;

  @override
  State<RunMap> createState() => _RunMapState();
}

class _RunMapState extends State<RunMap> {
  static const _malaysia = LatLng(4.2, 101.9);
  final _map = MapController();
  final LocationSource _source = GeolocatorSource();
  StreamSubscription<LocationFix>? _sub;
  LatLng? _me;
  bool _ready = false;

  List<(int, DriverStop, LatLng)> get _pins => [
    for (var i = 0; i < widget.stops.length; i++)
      if (widget.stops[i].latitude != null && widget.stops[i].longitude != null)
        (
          i + 1,
          widget.stops[i],
          LatLng(widget.stops[i].latitude!, widget.stops[i].longitude!),
        ),
  ];

  @override
  void initState() {
    super.initState();
    _sub = _source.watch().listen((f) {
      if (mounted) setState(() => _me = LatLng(f.latitude, f.longitude));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _fit() {
    if (!_ready) return;
    final focus = widget.focus;
    if (focus?.latitude != null && focus?.longitude != null) {
      _map.move(LatLng(focus!.latitude!, focus.longitude!), 16);
      return;
    }
    final points = [for (final p in _pins) p.$3, ?_me];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _map.move(points.first, 15);
      return;
    }
    _map.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(48),
        maxZoom: 16,
      ),
    );
  }

  void _locate() {
    if (_ready && _me != null) _map.move(_me!, 16);
  }

  @override
  Widget build(BuildContext context) {
    final pins = _pins;
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            // Camera set before the first frame, not moved in onMapReady:
            // moving it there cancelled every first tile load and the map
            // stayed blank (QA 2026-10-13).
            initialCenter:
                widget.focus?.latitude != null &&
                    widget.focus?.longitude != null
                ? LatLng(widget.focus!.latitude!, widget.focus!.longitude!)
                : pins.isNotEmpty
                ? pins.first.$3
                : _malaysia,
            initialZoom: widget.focus?.latitude != null
                ? 16
                : pins.isNotEmpty
                ? 14
                : 5,
            initialCameraFit: widget.focus?.latitude == null && pins.length > 1
                ? CameraFit.coordinates(
                    coordinates: [for (final p in pins) p.$3],
                    padding: const EdgeInsets.all(48),
                    maxZoom: 16,
                  )
                : null,
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
            onMapReady: () => _ready = true,
          ),
          children: [
            cefTileLayer(context),
            if (pins.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [for (final p in pins) p.$3],
                    strokeWidth: 4,
                    color: const Color(0xFF1668E3),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final (n, stop, at) in pins)
                  Marker(
                    point: at,
                    width: ZoomPin.pinBox,
                    height: ZoomPin.pinBox,
                    alignment: Alignment.topCenter,
                    child: _StopDot(
                      n: n,
                      done: stop.status == StopStatus.delivered,
                      focus:
                          identical(stop, widget.focus) ||
                          stop.id == widget.focus?.id,
                    ),
                  ),
                if (_me != null)
                  Marker(
                    point: _me!,
                    width: 26,
                    height: 26,
                    child: const _MeDot(),
                  ),
              ],
            ),
            MapCredit(mapCredit),
          ],
        ),
        if (pins.isEmpty)
          Positioned(
            top: Gap.md,
            left: Gap.xl * 2,
            right: Gap.md,
            child: FadingMapHint(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(L.noPinnedStops, textAlign: TextAlign.center),
              ),
            ),
          ),
        if (widget.showControls) ...[
          Positioned(
            left: Gap.md,
            top: Gap.md,
            child: MapControlButton(
              icon: LucideIcons.locateFixed,
              onTap: _locate,
            ),
          ),
          Positioned(
            right: Gap.md,
            bottom: Gap.md,
            child: MapRecenterPill(onTap: _fit),
          ),
        ],
      ],
    );
  }
}

class _StopDot extends StatelessWidget {
  const _StopDot({required this.n, required this.done, required this.focus});
  final int n;
  final bool done, focus;

  // Cefflo map pins, same on every surface: blue stop, mustard next, green
  // done with a check; sized by zoom (Founder 2026-10-16).
  @override
  Widget build(BuildContext context) => ZoomPin(
    color: done
        ? const Color(0xFF16A34A)
        : (focus ? const Color(0xFFFFC93C) : CefPin.pinBlue),
    label: done ? '✓' : '$n',
  );
}

class _MeDot extends StatelessWidget {
  const _MeDot();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF1668E3),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [
        BoxShadow(color: Color(0x551668E3), blurRadius: 10, spreadRadius: 4),
      ],
    ),
  );
}
