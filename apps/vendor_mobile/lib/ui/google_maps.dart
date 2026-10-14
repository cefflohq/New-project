import 'dart:ui' as ui;

import 'package:cefflo_loader/cefflo_loader.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';
import '../data/models.dart';
import 'delivery_pin.dart' show MapDrop, PinPoint, zoneColor;

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// Google Maps for the Vendor App (Auto Zone + Google Maps master guideline
/// Phase 5, 2026-10-14). Used when the build sets
/// `--dart-define=CEFFLO_GOOGLE_MAPS=true` and carries the native keys
/// (Android: CEFFLO_GOOGLE_MAPS_ANDROID_KEY gradle property / env; iOS:
/// CEFFLO_GOOGLE_MAPS_IOS_KEY build setting). Without the flag the
/// flutter_map maps in delivery_pin.dart are used.

const _malaysia = LatLng(4.2, 101.9);
const _pinDone = Color(0xFF16A34A);

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

/// Round drop pin drawn to a bitmap: stop navy, next mustard, done green
/// with a tick (the same colours as the flutter_map pins).
Future<BitmapDescriptor> _dropIcon(MapDrop d, {double dpr = 3}) async {
  final size = d.next ? 34.0 : 28.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(dpr);
  final c = Offset(size / 2, size / 2);
  canvas.drawCircle(c, size / 2, Paint()..color = Colors.white);
  canvas.drawCircle(
    c,
    size / 2 - 2,
    Paint()..color = d.done ? _pinDone : (d.next ? CefColors.ceffloMustard : CefColors.anchorBlue),
  );
  final tp = TextPainter(
    text: TextSpan(
      text: d.done ? '✓' : (d.label ?? ''),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: d.next && !d.done ? CefColors.anchorBlue : Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  final image = await recorder.endRecording().toImage((size * dpr).round(), (size * dpr).round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: size, height: size);
}

/// Read-only mini map with the customer's pin (pan only).
class GoogleDeliveryPinView extends StatelessWidget {
  const GoogleDeliveryPinView({super.key, required this.latitude, required this.longitude});
  final double latitude, longitude;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: point, zoom: 16),
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: {Marker(markerId: const MarkerId('drop'), position: point)},
    );
  }
}

/// Fixed-centre-pin picker on Google: the map moves under the pin. The pin
/// is set only at zoom >= 14 (same rule as the Storefront pin).
class GoogleDeliveryPinPicker extends StatefulWidget {
  const GoogleDeliveryPinPicker({super.key, required this.initial, required this.onChanged});
  final PinPoint? initial;
  final ValueChanged<PinPoint> onChanged;

  @override
  State<GoogleDeliveryPinPicker> createState() => _GoogleDeliveryPinPickerState();
}

class _GoogleDeliveryPinPickerState extends State<GoogleDeliveryPinPicker> {
  GoogleMapController? _map;
  PinPoint? _pin;
  CameraPosition? _camera;
  bool _moving = false, _locating = false;

  @override
  void initState() {
    super.initState();
    _pin = widget.initial;
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  void _set(double lat, double lng) {
    _pin = (lat: double.parse(lat.toStringAsFixed(6)), lng: double.parse(lng.toStringAsFixed(6)));
    widget.onChanged(_pin!);
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      if (!mounted) return;
      setState(() => _set(p.latitude, p.longitude));
      _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.latitude, p.longitude), 17));
    } catch (_) {
      // Location off or timed out: the vendor can still move the map.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final start = _pin;
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: start == null ? _malaysia : LatLng(start.lat, start.lng),
            zoom: start == null ? 5 : 17,
          ),
          onMapCreated: (m) => _map = m,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          onCameraMoveStarted: () => setState(() => _moving = true),
          onCameraMove: (cam) => _camera = cam,
          onCameraIdle: () {
            if (!_moving) return;
            final cam = _camera;
            setState(() {
              _moving = false;
              if (cam != null && cam.zoom >= 14) _set(cam.target.latitude, cam.target.longitude);
            });
          },
        ),
        // Fixed centre pin; its tip sits on the map centre.
        IgnorePointer(
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _pin != null || _moving ? 1 : 0,
              child: Transform.translate(
                offset: Offset(0, _moving ? -30 : -20),
                child: const Icon(LucideIcons.mapPin, size: 40, color: CefColors.navy),
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
                  onPressed: () => _map?.animateCamera(CameraUpdate.zoomIn()),
                ),
                Container(width: 24, height: 1, color: c.border),
                IconButton(
                  tooltip: L.zoomOut,
                  icon: const Icon(LucideIcons.minus, size: 18),
                  onPressed: () => _map?.animateCamera(CameraUpdate.zoomOut()),
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
                  ? const SizedBox(width: 18, height: 18, child: CefDots(size: 7))
                  : const Icon(LucideIcons.locateFixed, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

/// Read-only map with several customer pins and the zones' boundaries.
/// Fits everything; Malaysia overview when empty.
class GooglePinsMap extends StatefulWidget {
  const GooglePinsMap({super.key, required this.drops, this.zones = const []});
  final List<MapDrop> drops;
  final List<Zone> zones;

  @override
  State<GooglePinsMap> createState() => _GooglePinsMapState();
}

class _GooglePinsMapState extends State<GooglePinsMap> {
  GoogleMapController? _map;
  final Map<MapDrop, BitmapDescriptor> _icons = {};

  List<LatLng> get _points => [
    for (final d in widget.drops) LatLng(d.lat, d.lng),
    for (final z in widget.zones)
      if (z.boundary != null)
        for (final (lat, lng) in z.boundary!) LatLng(lat, lng),
  ];

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  @override
  void didUpdateWidget(GooglePinsMap old) {
    super.didUpdateWidget(old);
    _loadIcons();
    _fit();
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    for (final d in widget.drops) {
      _icons[d] ??= await _dropIcon(d);
    }
    if (mounted) setState(() {});
  }

  void _fit() {
    final points = _points;
    if (points.length < 2) return;
    _map?.animateCamera(CameraUpdate.newLatLngBounds(_bounds(points), 40));
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    final shapes = widget.zones.where((z) => z.boundary != null);
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: points.isEmpty ? _malaysia : points.first,
        zoom: points.isEmpty ? 5.5 : 15,
      ),
      onMapCreated: (m) {
        _map = m;
        Future.delayed(const Duration(milliseconds: 300), _fit);
      },
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      polygons: {
        for (final z in shapes)
          Polygon(
            polygonId: PolygonId(z.id),
            points: [for (final (lat, lng) in z.boundary!) LatLng(lat, lng)],
            holes: [
              for (final h in z.holes) [for (final (lat, lng) in h) LatLng(lat, lng)],
            ],
            // Soft zones: light tint, thin translucent edge.
            fillColor: zoneColor(z).withValues(alpha: .12),
            strokeColor: zoneColor(z).withValues(alpha: .55),
            strokeWidth: 2,
          ),
      },
      markers: {
        for (final (i, d) in widget.drops.indexed)
          Marker(
            markerId: MarkerId('d$i'),
            position: LatLng(d.lat, d.lng),
            anchor: const Offset(.5, .5),
            // Next stop on top.
            zIndexInt: d.next ? 2 : 1,
            icon: _icons[d] ?? BitmapDescriptor.defaultMarker,
          ),
      },
    );
  }
}

/// Coverage preview on Google: the service origin and its radius circle.
class GoogleCoverageMap extends StatelessWidget {
  const GoogleCoverageMap({super.key, required this.latitude, required this.longitude, required this.radiusKm});
  final double latitude, longitude, radiusKm;

  @override
  Widget build(BuildContext context) {
    final centre = LatLng(latitude, longitude);
    return GoogleMap(
      // Re-centre when the origin or radius changes.
      key: ValueKey('$latitude,$longitude,$radiusKm'),
      initialCameraPosition: CameraPosition(target: centre, zoom: _zoomFor(radiusKm)),
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      circles: {
        Circle(
          circleId: const CircleId('coverage'),
          center: centre,
          radius: radiusKm * 1000,
          fillColor: CefColors.anchorBlue.withValues(alpha: .10),
          strokeColor: CefColors.anchorBlue.withValues(alpha: .6),
          strokeWidth: 2,
        ),
      },
      markers: {Marker(markerId: const MarkerId('origin'), position: centre)},
    );
  }

  static double _zoomFor(double km) => km <= 3 ? 13 : km <= 6 ? 12 : km <= 12 ? 11 : km <= 25 ? 10 : 9;
}
