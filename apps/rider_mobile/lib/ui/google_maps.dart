import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/live_location.dart';
import '../data/driver_models.dart';
import '../data/live_adapters.dart';

/// Google Maps for the Driver App (Auto Zone + Google Maps master guideline
/// Phase 5, 2026-10-14). Used when the build sets
/// `--dart-define=CEFFLO_GOOGLE_MAPS=true` and carries the native keys
/// (Android: CEFFLO_GOOGLE_MAPS_ANDROID_KEY gradle property / env; iOS:
/// CEFFLO_GOOGLE_MAPS_IOS_KEY build setting). Without the flag the
/// flutter_map maps are used, so a build without keys is unchanged.

const _navy = Color(0xFF01265E);
const _next = Color(0xFFFFC93C);
const _done = Color(0xFF16A34A);
const _route = Color(0xFF1668E3);
const _malaysia = LatLng(4.2, 101.9);

/// Round numbered stop pin drawn to a bitmap (same colours as the
/// flutter_map pins: stop navy, focus yellow, delivered green with a tick).
Future<BitmapDescriptor> _stopIcon(int n, {required bool done, required bool focus, double dpr = 3}) async {
  const size = 34.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(dpr);
  const c = Offset(size / 2, size / 2);
  canvas.drawCircle(c, size / 2, Paint()..color = Colors.white);
  canvas.drawCircle(c, size / 2 - 2, Paint()..color = done ? _done : (focus ? _next : _navy));
  final label = done ? '✓' : '$n';
  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: focus && !done ? _navy : Colors.white),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  final image = await recorder.endRecording().toImage((size * dpr).round(), (size * dpr).round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: size, height: size);
}

LatLngBounds _bounds(List<LatLng> points) {
  var s = points.first.latitude, n = s, w = points.first.longitude, e = w;
  for (final p in points) {
    s = p.latitude < s ? p.latitude : s;
    n = p.latitude > n ? p.latitude : n;
    w = p.longitude < w ? p.longitude : w;
    e = p.longitude > e ? p.longitude : e;
  }
  return LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e));
}

/// Run map on Google: the run's pinned stops in order, joined by straight
/// lines (a sequence, not a road route), plus the driver's own position.
class GoogleRunMap extends StatefulWidget {
  const GoogleRunMap({super.key, required this.stops, this.focus, this.showControls = true});

  final List<DriverStop> stops;
  final DriverStop? focus;
  final bool showControls;

  @override
  State<GoogleRunMap> createState() => _GoogleRunMapState();
}

class _GoogleRunMapState extends State<GoogleRunMap> {
  GoogleMapController? _map;
  final LocationSource _source = GeolocatorSource();
  StreamSubscription<LocationFix>? _sub;
  final Map<String, BitmapDescriptor> _icons = {};

  List<(int, DriverStop, LatLng)> get _pins => [
    for (var i = 0; i < widget.stops.length; i++)
      if (widget.stops[i].latitude != null && widget.stops[i].longitude != null)
        (i + 1, widget.stops[i], LatLng(widget.stops[i].latitude!, widget.stops[i].longitude!)),
  ];

  bool _isFocus(DriverStop s) => identical(s, widget.focus) || s.id == widget.focus?.id;

  @override
  void initState() {
    super.initState();
    // The blue "me" dot is Google's own (myLocationEnabled); the stream
    // only keeps the permission prompt and location service warm.
    _sub = _source.watch().listen((_) {});
    _loadIcons();
  }

  @override
  void didUpdateWidget(GoogleRunMap old) {
    super.didUpdateWidget(old);
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    for (final (n, stop, _) in _pins) {
      final done = stop.status == StopStatus.delivered, focus = _isFocus(stop);
      final key = '$n|$done|$focus';
      _icons[key] ??= await _stopIcon(n, done: done, focus: focus);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    _map?.dispose();
    super.dispose();
  }

  CameraPosition get _start {
    final f = widget.focus;
    if (f?.latitude != null && f?.longitude != null) {
      return CameraPosition(target: LatLng(f!.latitude!, f.longitude!), zoom: 16);
    }
    final pins = _pins;
    return CameraPosition(target: pins.isNotEmpty ? pins.first.$3 : _malaysia, zoom: pins.isNotEmpty ? 14 : 5);
  }

  void _fit() {
    final f = widget.focus;
    if (f?.latitude != null && f?.longitude != null) {
      _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(f!.latitude!, f.longitude!), 16));
      return;
    }
    final points = [for (final p in _pins) p.$3];
    if (points.isEmpty) return;
    _map?.animateCamera(points.length == 1
        ? CameraUpdate.newLatLngZoom(points.first, 15)
        : CameraUpdate.newLatLngBounds(_bounds(points), 48));
  }

  @override
  Widget build(BuildContext context) {
    final pins = _pins;
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _start,
          onMapCreated: (c) {
            _map = c;
            if (widget.focus?.latitude == null && pins.length > 1) {
              Future.delayed(const Duration(milliseconds: 300), _fit);
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: widget.showControls,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          polylines: {
            if (pins.length > 1)
              Polyline(polylineId: const PolylineId('run'), points: [for (final p in pins) p.$3], width: 4, color: _route),
          },
          markers: {
            for (final (n, stop, at) in pins)
              Marker(
                markerId: MarkerId(stop.id),
                position: at,
                anchor: const Offset(.5, .5),
                zIndexInt: _isFocus(stop) ? 2 : 1,
                icon: _icons['$n|${stop.status == StopStatus.delivered}|${_isFocus(stop)}'] ?? BitmapDescriptor.defaultMarker,
              ),
          },
        ),
        if (widget.showControls)
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              heroTag: null,
              onPressed: _fit,
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
      ],
    );
  }
}

/// Mini map of the customer's pinned drop point on Google; a tap calls
/// [onTap] (the Driver opens navigation).
class GoogleDeliveryPinMap extends StatelessWidget {
  const GoogleDeliveryPinMap({super.key, required this.latitude, required this.longitude, required this.onTap});

  final double latitude;
  final double longitude;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: point, zoom: 16),
      liteModeEnabled: Theme.of(context).platform == TargetPlatform.android,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onTap: (_) => onTap(),
      markers: {Marker(markerId: const MarkerId('drop'), position: point, onTap: onTap)},
    );
  }
}
