import 'dart:async';

import 'package:cefflo_loader/cefflo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/env.dart';
import '../data/models.dart';
import 'google_tiles.dart';
import 'map_pin.dart';
import 'widgets.dart' show CefButton;
import '../core/theme.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// CARTO Positron raster tiles: the same clean look as the OpenFreeMap
/// Positron style on Vendor Web, and raster works on Flutter web, Android and
/// iOS. Temporary until the Mapbox switch (Founder 2026-10-08).
bool get _mapbox => Env.mapboxPublicToken.startsWith('pk.');

/// Mapbox Streets raster tiles when the build carries a public pk. token
/// (Founder 2026-10-12); OpenStreetMap otherwise.
Widget _tileLayer(BuildContext context) =>
    GoogleTileLayer(fallback: _fallbackTiles);

Widget _fallbackTiles(BuildContext context) => _mapbox
    ? TileLayer(
        urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}{r}?access_token={token}',
        additionalOptions: const {'token': Env.mapboxPublicToken},
        retinaMode: RetinaMode.isHighDensity(context),
        userAgentPackageName: 'my.cefflo.vendor',
      )
    : TileLayer(
        urlTemplate:
            // CARTO's free tiles now need a key; OpenStreetMap is the keyless
            // fallback (Google is the real map).
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'my.cefflo.vendor',
      );

/// Public alias for other screens (coverage map).
Widget cefTileLayer(BuildContext context) => _tileLayer(context);

String get cefMapCredit => _credit;

String get _credit => googleTiles
    ? googleCredit
    : _mapbox
    ? '© Mapbox © OpenStreetMap'
    : '© OpenStreetMap';

const _malaysia = LatLng(4.2, 101.9);
const _pinDone = Color(0xFF16A34A);

Widget get _attribution => MapCredit(_credit);

Widget _pinIcon() => const CefPin(size: 40);

/// Read-only mini map with the customer's pin. Pan-only, no zoom or rotate.
class DeliveryPinView extends StatelessWidget {
  const DeliveryPinView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 220,
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
            _tileLayer(context),
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
    this.height = 340,
    this.fullscreen = false,
  });
  final PinPoint? initial;
  final ValueChanged<PinPoint> onChanged;
  final double height;

  /// The same picker filling the screen (Founder 2026-10-15: a corner
  /// button maximises the map); its corner button closes it.
  final bool fullscreen;

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

  Future<void> _toggleFullscreen() async {
    if (widget.fullscreen) {
      Navigator.of(context).pop();
      return;
    }
    PinPoint? moved;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          body: DeliveryPinPicker(
            initial: _pin ?? _centre,
            height: double.infinity,
            fullscreen: true,
            onChanged: (p) => moved = p,
          ),
        ),
      ),
    );
    final p = moved;
    if (p == null || !mounted) return;
    setState(() => _set(p.lat, p.lng));
    _controller.move(LatLng(p.lat, p.lng), 17);
  }

  /// Where the map looks now, so the full-screen map opens on the same spot.
  PinPoint? get _centre {
    try {
      final c = _controller.camera.center;
      return _controller.camera.zoom >= 14
          ? (lat: c.latitude, lng: c.longitude)
          : null;
    } catch (_) {
      return null;
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
    final radius = BorderRadius.circular(
      widget.fullscreen ? 0 : Sizes.cardRadius,
    );
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          border: widget.fullscreen ? null : Border.all(color: c.border),
          borderRadius: radius,
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
              children: [_tileLayer(context), _attribution],
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
              left: 10,
              top: widget.fullscreen
                  ? MediaQuery.paddingOf(context).top + 10
                  : 10,
              child: Material(
                color: c.card,
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: widget.fullscreen ? L.exitFullScreen : L.fullScreen,
                  icon: Icon(
                    widget.fullscreen
                        ? LucideIcons.minimize2
                        : LucideIcons.maximize2,
                    size: 18,
                  ),
                  onPressed: _toggleFullscreen,
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: widget.fullscreen
                  ? MediaQuery.paddingOf(context).top + 10
                  : 10,
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
              bottom: widget.fullscreen
                  ? MediaQuery.paddingOf(context).bottom + 22
                  : 22,
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
                          child: CefDots(size: 7),
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

/// Each zone keeps one colour on every map and in the zone list, so zones are
/// told apart without labels sitting on top of the map's own place names.
const _zonePalette = [
  Color(0xFF1E5EFF),
  Color(0xFFE8590C),
  Color(0xFF2B8A3E),
  Color(0xFF9C36B5),
  Color(0xFFC2255C),
  Color(0xFF0B7285),
  Color(0xFFB08900),
  Color(0xFF5C3D2E),
];
Color zoneColor(Zone z) =>
    _zonePalette[z.id.codeUnits.fold<int>(
          0,
          (a, b) => (a * 31 + b) & 0xFFFFFF,
        ) %
        _zonePalette.length];

/// Read-only map with several customer pins (run stops, zone orders). Fits
/// all pins; Malaysia overview when none. Pins only -- no rider location.
class PinsMap extends StatefulWidget {
  const PinsMap({
    super.key,
    required this.drops,
    this.height = 300,
    this.emptyLabel,
    this.zones = const [],
    this.onZoneTap,
    this.selectedZoneIds,
  });
  final List<MapDrop> drops;

  /// Null fills the space the parent gives (Zones tab, full map).
  final double? height;
  final String? emptyLabel;

  /// Zones with a drawn boundary are drawn under the pins.
  final List<Zone> zones;

  /// Tapping inside a zone's area reports it (Founder 2026-10-16).
  final ValueChanged<Zone>? onZoneTap;

  /// While selecting zones: these draw strongly, the rest faded.
  final Set<String>? selectedZoneIds;

  @override
  State<PinsMap> createState() => _PinsMapState();
}

class _PinsMapState extends State<PinsMap> {
  final _hits = LayerHitNotifier<String>(null);

  @override
  void dispose() {
    _hits.dispose();
    super.dispose();
  }

  void _onTap() {
    final ids = _hits.value?.hitValues;
    if (ids == null || ids.isEmpty || widget.onZoneTap == null) return;
    // Smallest zone on top wins: hit values come topmost first.
    final zone = widget.zones.where((z) => z.id == ids.first).firstOrNull;
    if (zone != null) widget.onZoneTap!(zone);
  }

  @override
  Widget build(BuildContext context) {
    final drops = widget.drops;
    final zones = widget.zones;
    final height = widget.height;
    final emptyLabel = widget.emptyLabel;
    final selected = widget.selectedZoneIds;
    final c = context.c;
    final shapes = zones.where((z) => z.boundary != null).toList();
    final points = [
      for (final d in drops) LatLng(d.lat, d.lng),
      for (final z in shapes)
        for (final (lat, lng) in z.boundary!) LatLng(lat, lng),
    ];
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
    // Cefflo map pins, same on every surface: blue stop, mustard next,
    // green done with a check; sized by zoom (Founder 2026-10-16).
    Widget dot(MapDrop d) => ZoomPin(
      color: d.done
          ? _pinDone
          : d.next
          ? CefColors.ceffloMustard
          : CefPin.pinBlue,
      label: d.done ? '✓' : d.label,
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
              // Re-fit when the zones or pins change (a new zone appears).
              key: ValueKey(Object.hashAll(points)),
              options: options,
              children: [
                _tileLayer(context),
                if (shapes.isNotEmpty)
                  GestureDetector(
                    onTap: widget.onZoneTap == null ? null : _onTap,
                    child: PolygonLayer<String>(
                      hitNotifier: _hits,
                      polygons: [
                        for (final z in shapes)
                          Polygon<String>(
                            hitValue: z.id,
                            points: [
                              for (final (lat, lng) in z.boundary!)
                                LatLng(lat, lng),
                            ],
                            holePointsList: [
                              for (final h in z.holes)
                                [for (final (lat, lng) in h) LatLng(lat, lng)],
                            ],
                            // Soft zones: light tint, thin translucent edge;
                            // a picked zone (selecting) stands out.
                            color: zoneColor(z).withValues(
                              alpha: selected == null
                                  ? .12
                                  : selected.contains(z.id)
                                  ? .45
                                  : .06,
                            ),
                            borderColor: zoneColor(z).withValues(
                              alpha: selected?.contains(z.id) ?? false
                                  ? 1
                                  : .55,
                            ),
                            borderStrokeWidth: selected?.contains(z.id) ?? false
                                ? 3
                                : 1.5,
                          ),
                      ],
                    ),
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
                        width: ZoomPin.pinBox,
                        height: ZoomPin.pinBox,
                        alignment: Alignment.topCenter,
                        child: dot(d),
                      ),
                  ],
                ),
              ],
            ),
            // Auto zone areas come from geoBoundaries (CC BY 4.0).
            MapCredit(shapes.isEmpty ? _credit : '$_credit © geoBoundaries'),
            if (drops.isEmpty && shapes.isEmpty && emptyLabel != null)
              Positioned(
                left: Gap.md,
                right: Gap.md,
                top: Gap.md,
                child: FadingMapHint(
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
                      emptyLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Zone boundary editor (Founder 2026-10-12, option B): tap the map to add a
/// corner; Undo / Clear; returns the ring through [onSave]. Other zones'
/// boundaries show faintly for reference.
class ZoneBoundaryEditor extends StatefulWidget {
  const ZoneBoundaryEditor({
    super.key,
    required this.zone,
    required this.others,
    required this.onSave,
  });
  final Zone zone;
  final List<Zone> others;
  final Future<void> Function(List<(double, double)>? ring) onSave;

  @override
  State<ZoneBoundaryEditor> createState() => _ZoneBoundaryEditorState();
}

class _ZoneBoundaryEditorState extends State<ZoneBoundaryEditor> {
  late List<LatLng> pts = [
    for (final (lat, lng) in widget.zone.boundary ?? const <(double, double)>[])
      LatLng(lat, lng),
  ];
  bool busy = false;
  String? error;

  Future<void> _save(List<(double, double)>? ring) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onSave(ring);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ref = [
      ...pts,
      for (final z in widget.others)
        for (final (lat, lng) in z.boundary ?? const <(double, double)>[])
          LatLng(lat, lng),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.zone.boundary == null
                ? L.drawZoneBoundary
                : L.editZoneBoundary,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Gap.xs),
          Text(
            L.drawZoneBoundaryHint,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Gap.md),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Sizes.cardRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: ref.isEmpty ? _malaysia : ref.first,
                      initialZoom: ref.isEmpty ? 6 : 13,
                      initialCameraFit: ref.length > 1
                          ? CameraFit.coordinates(
                              coordinates: ref,
                              padding: const EdgeInsets.all(40),
                              maxZoom: 15,
                            )
                          : null,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                      ),
                      onTap: (_, at) {
                        if (pts.length < 200) setState(() => pts.add(at));
                      },
                    ),
                    children: [
                      _tileLayer(context),
                      PolygonLayer(
                        polygons: [
                          for (final z in widget.others)
                            if (z.boundary != null)
                              Polygon(
                                points: [
                                  for (final (lat, lng) in z.boundary!)
                                    LatLng(lat, lng),
                                ],
                                color: Colors.transparent,
                                borderColor: c.textSecondary,
                                borderStrokeWidth: 1.5,
                                pattern: StrokePattern.dashed(
                                  segments: const [6, 4],
                                ),
                              ),
                          if (pts.length >= 3)
                            Polygon(
                              points: pts,
                              color: CefColors.anchorBlue.withValues(
                                alpha: .15,
                              ),
                              borderColor: CefColors.anchorBlue,
                              borderStrokeWidth: 2.5,
                            ),
                        ],
                      ),
                      if (pts.length == 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: pts,
                              color: CefColors.anchorBlue,
                              strokeWidth: 2.5,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          for (final p in pts)
                            Marker(
                              point: p,
                              width: 16,
                              height: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CefColors.anchorBlue,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      MapCredit(_credit),
                    ],
                  ),
                  Positioned(
                    top: Gap.sm,
                    right: Gap.sm,
                    child: Row(
                      children: [
                        _MapChip(
                          L.undo,
                          pts.isEmpty
                              ? null
                              : () => setState(() => pts.removeLast()),
                        ),
                        const SizedBox(width: Gap.xs),
                        _MapChip(
                          L.clear,
                          pts.isEmpty ? null : () => setState(pts.clear),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: Gap.sm),
            Text(error!, style: TextStyle(color: c.attention)),
          ],
          const SizedBox(height: Gap.md),
          CefButton(
            L.save,
            busy: busy,
            onTap: pts.length < 3
                ? null
                : () => _save([for (final p in pts) (p.latitude, p.longitude)]),
          ),
          if (widget.zone.boundary != null) ...[
            const SizedBox(height: Gap.sm),
            CefButton(
              L.removeZoneBoundary,
              secondary: true,
              onTap: busy ? null : () => _save(null),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip(this.label, this.onTap);
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(999),
    elevation: 2,
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: onTap == null ? Colors.black38 : CefColors.navy,
          ),
        ),
      ),
    ),
  );
}

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
