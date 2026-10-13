import 'dart:async';

import 'package:cefflo_loader/cefflo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/live_adapters.dart';
import '../../data/my_towns.dart';
import '../../data/place_search.dart';
import '../../data/rider_repository.dart';
import '../map_tiles.dart';
import '../widgets.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// D41 Find Jobs family (D-75, Rider Hub V1; Rider Network Strategy §7–13).
//
// Live: find_job_openings / request_job_opening / my_job_schedule /
// withdraw_job_request (migration 20261005100000). Every open opening in the
// country is listed, nearest first when location is on; the vendor's radius
// (5–20 km) shows as "Within X km" or "Y km away". A request puts the rider
// in that business's Riders > Pending; only the Owner approves. The server
// refuses overlapping shifts (60-minute buffer between businesses).
// Prototype: the same screens over clearly marked example openings.
// ---------------------------------------------------------------------------

enum _Shift { morning, noon, night }

_Shift _shiftOf(int startMinutes) => startMinutes < 11 * 60
    ? _Shift.morning
    : startMinutes < 17 * 60
    ? _Shift.noon
    : _Shift.night;

/// M1: a hiring post has a pickup time only (shift_end null) -> end = start.
int _minutesOr(Object? end, Object? start) =>
    _minutes((end ?? start) as String);

/// "7:00 AM – 11:00 AM", or "Pickup 7:00 AM" when there is no end time.
String _span(int start, int end) => end > start
    ? '${_clock(start)} – ${_clock(end)}'
    : L.jobPickupAt(_clock(start));

int _minutes(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String _clock(int m) {
  final h = m ~/ 60, min = m % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${min.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}

List<String> get _dayNames => [L.mon, L.tue, L.wed, L.thu, L.fri, L.sat, L.sun];

String _daysLabel(List<int> days) {
  final d = [...days]..sort();
  if (d.length == 7) return L.jobDaily;
  final run = d.length >= 3 && d.last - d.first == d.length - 1;
  if (run) return '${_dayNames[d.first - 1]} – ${_dayNames[d.last - 1]}';
  return d.map((x) => _dayNames[x - 1]).join(', ');
}

String _vehicleLabel(String v) => switch (v) {
  'car' => L.vehicleCar,
  'van' => L.vehicleVan,
  _ => L.vehicleMotorbike,
};

String _payLabel(num amount, String unit) {
  final u = switch (unit) {
    'drop' => L.perDrop,
    'hour' => L.perHour,
    _ => L.perShift,
  };
  return 'RM ${_num(amount)} $u';
}

String _num(num v) =>
    v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);

class _Opening {
  const _Opening({
    required this.id,
    required this.name,
    required this.area,
    required this.start,
    required this.end,
    required this.days,
    required this.payAmount,
    required this.payUnit,
    required this.needed,
    required this.vehicle,
    required this.radiusKm,
    this.category = '',
    this.km,
    this.withinRadius,
    this.myStatus,
    this.clash,
    this.requirements = const [],
    this.vehicleMatch = true,
    this.areaLat,
    this.areaLng,
    this.drops,
  });

  /// The business's pickup area rounded to about 1 km (find_job_openings),
  /// for the work-area map. Never the store's exact location.
  final double? areaLat, areaLng;

  /// The vendor's estimated drops per run; null on older posts.
  final int? drops;

  final String id, name, area, category, payUnit, vehicle;
  final int start, end, needed;
  final List<int> days;
  final num payAmount, radiusKm;
  final num? km;
  final bool? withinRadius;
  final String? myStatus; // 'pending' | 'approved'
  final String? clash;
  final List<String> requirements;

  /// The opening's vehicle matches the rider's own (ranked first).
  final bool vehicleMatch;

  _Shift get shift => _shiftOf(start);
  String get time => _span(start, end);
  String get pay => _payLabel(payAmount, payUnit);
  String get initials => name
      .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join()
      .toUpperCase();
  Color get color => _palette[name.hashCode.abs() % _palette.length];

  /// "Bangsar · 3.5 km away": the vendor's area label and the distance from
  /// its pickup origin. Never a precise address.
  String get meta => [
    if (category.isNotEmpty) category,
    area,
    if (km != null) L.jobAway(_num(km!)),
  ].join(' · ');

  static _Opening fromRow(Map<String, dynamic> r) => _Opening(
    id: r['opening_id'] as String,
    name: (r['business_name'] ?? '').toString(),
    area: (r['area_label'] ?? '').toString(),
    start: _minutes(r['shift_start'] as String),
    end: _minutesOr(r['shift_end'], r['shift_start']),
    days: [for (final d in (r['days'] as List)) (d as num).toInt()],
    payAmount: r['pay_amount'] as num,
    payUnit: (r['pay_unit'] ?? 'shift').toString(),
    needed: (r['riders_needed'] as num).toInt(),
    vehicle: (r['vehicle_type'] ?? 'motorcycle').toString(),
    radiusKm: (r['radius_km'] as num?) ?? 10,
    km: r['distance_km'] as num?,
    withinRadius: r['within_radius'] as bool?,
    myStatus: r['my_status'] as String?,
    clash: r['clash'] as String?,
    requirements: [_vehicleLabel((r['vehicle_type'] ?? '').toString())],
    vehicleMatch: r['vehicle_match'] != false,
    areaLat: (r['area_lat'] as num?)?.toDouble(),
    areaLng: (r['area_lng'] as num?)?.toDouble(),
    drops: (r['drops_per_run'] as num?)?.toInt(),
  );

  _Opening withStatus(String? status) => _Opening(
    id: id,
    name: name,
    area: area,
    category: category,
    start: start,
    end: end,
    days: days,
    payAmount: payAmount,
    payUnit: payUnit,
    needed: needed,
    vehicle: vehicle,
    radiusKm: radiusKm,
    km: km,
    withinRadius: withinRadius,
    myStatus: status,
    clash: status == null ? clash : null,
    requirements: requirements,
    vehicleMatch: vehicleMatch,
    areaLat: areaLat,
    areaLng: areaLng,
    drops: drops,
  );
}

const _palette = [
  Color(0xFFC2410C),
  Color(0xFF0E7490),
  Color(0xFFB91C1C),
  Color(0xFF7C3AED),
  Color(0xFF15803D),
  Color(0xFF1D4ED8),
];

class _Booking {
  const _Booking({
    required this.requestId,
    required this.approved,
    required this.name,
    required this.start,
    required this.end,
    required this.days,
  });
  final String requestId, name;
  final bool approved;
  final int start, end;
  final List<int> days;

  static _Booking fromRow(Map<String, dynamic> r) => _Booking(
    requestId: r['request_id'] as String,
    approved: r['status'] == 'approved',
    name: (r['business_name'] ?? '').toString(),
    start: _minutes(r['shift_start'] as String),
    end: _minutesOr(r['shift_end'], r['shift_start']),
    days: [for (final d in (r['days'] as List)) (d as num).toInt()],
  );
}

// ------------------------------------------------------------- data store

/// Where the rider is searching from: their GPS position or a chosen town.
class _Place {
  const _Place(this.label, this.latitude, this.longitude, {this.gps = false});
  final String label;
  final double latitude, longitude;
  final bool gps;
}

/// Distance filter (D-75): default 20 km, 50 km maximum for V1.
const _radii = [5, 10, 20, 30, 50];

/// One place for the tab's data, so the three screens stay in step.
class _Jobs {
  static final openings = ValueNotifier<List<_Opening>?>(null);
  static final bookings = ValueNotifier<List<_Booking>>(const []);
  static final place = ValueNotifier<_Place?>(null);
  static final radius = ValueNotifier<int>(20);
  static final needsLocation = ValueNotifier<bool>(false);
  static final error = ValueNotifier<String?>(null);
  static final _demoRequested = <String>{};

  /// [gps]: look up the current position again (first open, "Use my
  /// location"). A chosen town stays until the rider changes it.
  static Future<void> load(AppState app, {bool gps = false}) async {
    if (app.repo.isDemo) {
      place.value ??= const _Place('Alor Setar, Kedah', 6.121, 100.368);
      openings.value = [
        for (final o in _examples)
          if ((o.km ?? 0) <= radius.value)
            o.withStatus(_demoRequested.contains(o.id) ? 'pending' : null),
      ];
      bookings.value = [
        ..._demoBookings,
        for (final o in _examples)
          if (_demoRequested.contains(o.id))
            _Booking(
              requestId: o.id,
              approved: false,
              name: o.name,
              start: o.start,
              end: o.end,
              days: o.days,
            ),
      ];
      needsLocation.value = false;
      return;
    }
    error.value = null;
    try {
      if (place.value == null || (gps && place.value!.gps) || gps) {
        final fix = await GeolocatorSource().current().timeout(
          const Duration(seconds: 8),
          onTimeout: () => null,
        );
        if (fix != null) {
          place.value = _Place(
            L.currentLocation,
            fix.latitude,
            fix.longitude,
            gps: true,
          );
        }
      }
      final at = place.value;
      bookings.value = (await app.repo.myJobSchedule())
          .map(_Booking.fromRow)
          .toList();
      if (at == null) {
        // No GPS and no town chosen: ask, never fall back to a country feed.
        needsLocation.value = true;
        openings.value = const [];
        return;
      }
      needsLocation.value = false;
      final rows = await app.repo.findJobOpenings(
        latitude: at.latitude,
        longitude: at.longitude,
        radiusKm: radius.value,
      );
      openings.value = rows.map(_Opening.fromRow).toList();
    } on RepositoryError catch (e) {
      error.value = e.message;
      openings.value ??= const [];
    } catch (_) {
      error.value = L.jobsLoadFailed;
      openings.value ??= const [];
    }
  }

  static Future<void> setRadius(AppState app, int km) {
    radius.value = km;
    return load(app);
  }

  static Future<void> setPlace(AppState app, _Place? p) {
    if (p == null) return load(app, gps: true);
    place.value = p;
    return load(app);
  }

  static Future<void> request(AppState app, _Opening o) async {
    if (app.repo.isDemo) {
      _demoRequested.add(o.id);
      return load(app);
    }
    await app.repo.requestJobOpening(o.id);
    await load(app);
  }

  static Future<void> withdraw(AppState app, _Booking b) async {
    if (app.repo.isDemo) {
      _demoRequested.remove(b.requestId);
      return load(app);
    }
    await app.repo.withdrawJobRequest(b.requestId);
    await load(app);
  }
}

/// Example openings for the prototype only (Alor Setar, Kedah).
const _examples = <_Opening>[
  _Opening(
    id: 'mak-som',
    name: 'Kedai Roti Mak Som',
    category: 'Bakery',
    area: 'Taman Uda',
    areaLat: 6.14,
    areaLng: 100.36,
    km: 2.5,
    drops: 12,
    withinRadius: true,
    radiusKm: 10,
    start: 7 * 60,
    end: 11 * 60,
    days: [1, 2, 3, 4, 5],
    payAmount: 45,
    payUnit: 'shift',
    needed: 2,
    vehicle: 'motorcycle',
    requirements: ['Motorbike', 'Own phone'],
  ),
  _Opening(
    id: 'pelita',
    name: 'Nasi Kandar Pelita Jaya',
    category: 'Restaurant',
    area: 'Jalan Langgar',
    areaLat: 6.12,
    areaLng: 100.38,
    km: 3,
    drops: 10,
    withinRadius: true,
    radiusKm: 10,
    start: 12 * 60,
    end: 15 * 60,
    days: [1, 2, 3, 4, 5, 6, 7],
    payAmount: 40,
    payUnit: 'shift',
    needed: 3,
    vehicle: 'motorcycle',
    requirements: ['Motorbike', 'Lunch rush'],
    clash: 'Clashes with Ayam Gepuk Pak Gembus (12:00 PM - 3:00 PM)',
  ),
  _Opening(
    id: 'kek-lapis',
    name: 'Kek Lapis Sarawak Mama',
    category: 'Home baker',
    area: 'Anak Bukit',
    areaLat: 6.18,
    areaLng: 100.35,
    km: 6,
    drops: 15,
    withinRadius: true,
    radiusKm: 10,
    start: 18 * 60,
    end: 21 * 60,
    days: [5, 6, 7],
    payAmount: 50,
    payUnit: 'shift',
    needed: 1,
    vehicle: 'car',
    requirements: ['Car', 'Fragile items'],
  ),
  _Opening(
    id: 'pasar-tani',
    name: 'Pasar Tani Online Kedah',
    category: 'Groceries',
    area: 'Stargate',
    areaLat: 6.13,
    areaLng: 100.37,
    km: 18,
    drops: 8,
    withinRadius: false,
    radiusKm: 10,
    start: 8 * 60,
    end: 12 * 60,
    days: [6],
    payAmount: 60,
    payUnit: 'shift',
    needed: 2,
    vehicle: 'van',
    requirements: ['Van', 'Heavy items'],
  ),
];

const _demoBookings = <_Booking>[
  _Booking(
    requestId: 'b1',
    approved: true,
    name: 'Kedai Roti Mak Som',
    start: 7 * 60,
    end: 11 * 60,
    days: [1, 2, 3, 4, 5],
  ),
  _Booking(
    requestId: 'b2',
    approved: true,
    name: 'Ayam Gepuk Pak Gembus',
    start: 12 * 60,
    end: 15 * 60,
    days: [2, 6, 7],
  ),
];

// ------------------------------------------------------------ D41 Find Jobs

class FindJobsScreen extends StatefulWidget {
  const FindJobsScreen({super.key});

  @override
  State<FindJobsScreen> createState() => _FindJobsScreenState();
}

class _FindJobsScreenState extends State<FindJobsScreen> {
  _Shift? _shift;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _Jobs.load(AppScope.read(context), gps: true);
    });
  }

  Future<void> _changeLocation(AppState app) async {
    final picked = await showCefSheet<Object>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TownPicker(),
    );
    if (picked == null || !mounted) return;
    if (picked is MyTown) {
      await _Jobs.setPlace(
        app,
        _Place(picked.name, picked.latitude, picked.longitude),
      );
    } else {
      await _Jobs.setPlace(app, null); // use my location
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ValueListenableBuilder<_Place?>(
      valueListenable: _Jobs.place,
      builder: (context, place, _) => ValueListenableBuilder<int>(
        valueListenable: _Jobs.radius,
        builder: (context, radius, _) => CeffloNavySheetScaffold(
          onRefresh: () => _Jobs.load(app),
          // Opening cards sit 10px from the screen edge (Founder
          // 2026-10-13); the shift filter keeps the usual 20px.
          bodyPadding: const EdgeInsets.fromLTRB(
            10,
            Gap.section,
            10,
            Gap.section,
          ),
          header: CeffloScreenHeader(
            title: L.findJobs,
            onBell: () => app.go(DRoute.notifications),
            // Location and My week sit on the navy (Founder 2026-10-13):
            // the white sheet holds only the shift filter and the openings.
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AreaRow(
                  label: place == null
                      ? L.chooseTown
                      : '${place.label} · ${L.withinKm('$radius')}',
                  onChange: () => _changeLocation(app),
                ),
                ValueListenableBuilder<List<_Booking>>(
                  valueListenable: _Jobs.bookings,
                  builder: (context, b, _) => b.isEmpty
                      ? const SizedBox.shrink()
                      : _HeaderWeek(
                          bookings: b,
                          onOpen: () => app.go(DRoute.mySchedule),
                        ),
                ),
              ],
            ),
          ),
          body: _body(context, app, place, radius),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, _Place? place, int radius) =>
      ValueListenableBuilder<List<_Opening>?>(
        valueListenable: _Jobs.openings,
        builder: (context, all, _) {
          if (all == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CefPageLoader(),
            );
          }
          final shown = [
            for (final o in all)
              if (_shift == null || o.shift == _shift) o,
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _ShiftFilter(
                  value: _shift,
                  onChanged: (s) => setState(() => _shift = s),
                ),
              ),
              const SizedBox(height: Gap.lg),
              ValueListenableBuilder<String?>(
                valueListenable: _Jobs.error,
                builder: (context, e, _) => e == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: Gap.md),
                        child: CeffloNote(
                          icon: LucideIcons.triangleAlert,
                          tone: CeffloNoteTone.warning,
                          body: e,
                        ),
                      ),
              ),
              if (place == null)
                _NoLocation(
                  onUseLocation: () => _Jobs.setPlace(app, null),
                  onChooseTown: () => _changeLocation(app),
                )
              else if (all.isEmpty)
                _NoJobsNearby(radius: radius, place: place.label)
              else if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Gap.lg),
                  child: Text(
                    L.noOpeningsShift,
                    textAlign: TextAlign.center,
                    style: context.t.bodyMedium?.copyWith(
                      color: context.c.textSecondary,
                    ),
                  ),
                )
              else
                for (final o in shown) ...[
                  _OpeningCard(
                    opening: o,
                    onTap: () => app.go(DRoute.jobDetail, entityId: o.id),
                  ),
                  const SizedBox(height: Gap.md),
                ],
              if (app.repo.isDemo) ...[
                const SizedBox(height: Gap.sm),
                Text(
                  L.previewOnly,
                  textAlign: TextAlign.center,
                  style: context.t.bodySmall?.copyWith(
                    color: context.c.textSecondary,
                  ),
                ),
              ],
            ],
          );
        },
      );
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.label, required this.onChange});
  final String label;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.sm, Gap.sm, 0),
    child: GestureDetector(
      onTap: onChange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CefColors.onNavy,
                ),
              ),
            ),
            const SizedBox(width: Gap.sm),
            // "Change" as a light icon; yellow is kept for the week bars.
            Semantics(
              button: true,
              label: L.changeArea,
              child: Icon(
                LucideIcons.refreshCw,
                size: 18,
                color: Colors.white.withValues(alpha: .8),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 5 · 10 · 20 · 30 · 50 km, cardless like the shift filter.
class _RadiusFilter extends StatelessWidget {
  const _RadiusFilter({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final km in _radii) ...[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(km),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '$km km',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: km == value ? FontWeight.w800 : FontWeight.w600,
                color: km == value ? CefColors.navy : context.c.textSecondary,
                decoration: km == value ? TextDecoration.underline : null,
                decorationThickness: 2,
              ),
            ),
          ),
        ),
        if (km != _radii.last) const SizedBox(width: 18),
      ],
    ],
  );
}

class _NoLocation extends StatelessWidget {
  const _NoLocation({required this.onUseLocation, required this.onChooseTown});
  final VoidCallback onUseLocation, onChooseTown;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Gap.lg),
    child: Column(
      children: [
        const Icon(LucideIcons.mapPinned, size: 34, color: CefColors.navy),
        const SizedBox(height: Gap.md),
        Text(
          L.needLocationTitle,
          textAlign: TextAlign.center,
          style: context.t.titleMedium,
        ),
        const SizedBox(height: Gap.xs),
        Text(
          L.needLocationBody,
          textAlign: TextAlign.center,
          style: context.t.bodyMedium?.copyWith(color: context.c.textSecondary),
        ),
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton(L.useMyLocation, onTap: onUseLocation),
        const SizedBox(height: Gap.sm),
        CeffloSecondaryButton(L.chooseTown, onTap: onChooseTown),
      ],
    ),
  );
}

/// Centred on the empty screen, message only (Founder 2026-10-13): the
/// area and distance are changed from "Change" in the header.
class _NoJobsNearby extends StatelessWidget {
  const _NoJobsNearby({required this.radius, required this.place});
  final int radius;
  final String place;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .5,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.searchX, size: 34, color: context.c.textSecondary),
          const SizedBox(height: Gap.md),
          Text(
            L.noJobsWithin('$radius', place),
            textAlign: TextAlign.center,
            style: context.t.titleMedium,
          ),
          const SizedBox(height: Gap.xs),
          Text(
            L.jobsChangeAreaHint,
            textAlign: TextAlign.center,
            style: context.t.bodySmall?.copyWith(
              color: context.c.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Change location: "Use my location" or a searchable list of towns.
class _TownPicker extends StatefulWidget {
  const _TownPicker();

  @override
  State<_TownPicker> createState() => _TownPickerState();
}

class _TownPickerState extends State<_TownPicker> {
  String _q = '';
  List<MyTown> _remote = const [];
  Timer? _debounce;

  void _search(String v) {
    setState(() => _q = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final found = await searchPlaces(v);
      if (mounted && _q == v) setState(() => _remote = found);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final towns = [
      if (q.length >= 3) ..._remote,
      for (final t in myTowns)
        if (q.isEmpty ||
            t.name.toLowerCase().contains(q) ||
            t.state.toLowerCase().contains(q))
          t,
    ];
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: Padding(
        padding: EdgeInsets.only(
          left: Gap.gutter,
          right: Gap.gutter,
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(L.changeLocation, style: context.t.titleMedium),
            const SizedBox(height: Gap.md),
            // How far: lives here now, not as a second row on Find Jobs.
            ValueListenableBuilder<int>(
              valueListenable: _Jobs.radius,
              builder: (context, km, _) => _RadiusFilter(
                value: km,
                onChanged: (v) => _Jobs.setRadius(AppScope.read(context), v),
              ),
            ),
            const SizedBox(height: Gap.sm),
            TextField(
              autofocus: false,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: L.searchTown,
                prefixIcon: const Icon(LucideIcons.search, size: 18),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.locateFixed),
              title: Text(L.useMyLocation),
              onTap: () => Navigator.of(context).pop('gps'),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: towns.length,
                itemBuilder: (context, i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(towns[i].name),
                  subtitle: Text(towns[i].state),
                  onTap: () => Navigator.of(context).pop(towns[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// All · Morning · Noon · Night: one cardless line, underline on the
/// selected shift (Founder, 2026-10-05).
class _ShiftFilter extends StatelessWidget {
  const _ShiftFilter({required this.value, required this.onChanged});

  final _Shift? value;
  final ValueChanged<_Shift?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget item(String label, _Shift? shift) {
      final on = value == shift;
      return Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(shift),
          child: Container(
            padding: const EdgeInsets.only(top: 6, bottom: 9),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: on ? CefColors.navy : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: on ? CefColors.navy : c.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          item(L.shiftAll, null),
          const SizedBox(width: 22),
          item(L.shiftMorning, _Shift.morning),
          const SizedBox(width: 22),
          item(L.shiftNoon, _Shift.noon),
          const SizedBox(width: 22),
          item(L.shiftNight, _Shift.night),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.section, bottom: Gap.sm),
    child: Text(title, style: context.t.titleSmall),
  );
}

enum _Slot { free, booked, requested }

/// day (0–6) × shift (0–2) → the booking in it, if any.
List<List<_Booking?>> _grid(List<_Booking> bookings) {
  final g = List.generate(7, (_) => List<_Booking?>.filled(3, null));
  for (final b in bookings) {
    final s = _shiftOf(b.start).index;
    for (final d in b.days) {
      final cur = g[d - 1][s];
      if (cur == null || (!cur.approved && b.approved)) g[d - 1][s] = b;
    }
  }
  return g;
}

_Slot _slotOf(_Booking? b) =>
    b == null ? _Slot.free : (b.approved ? _Slot.booked : _Slot.requested);

/// One card per shop, draft 7 (Founder 2026-10-13): badge and name on
/// top, a divider, then days · pickup · distance on the left and the pay
/// on the right. Wide side padding; every card the same height.
class _OpeningCard extends StatelessWidget {
  const _OpeningCard({required this.opening, required this.onTap});

  final _Opening opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = opening;
    final c = context.c;
    final (String? tag, Color tagColor) = switch (o) {
      _ when o.myStatus == 'approved' => (L.slotBooked, c.success),
      _ when o.myStatus == 'pending' => (L.jobApplied, c.success),
      _ when o.clash != null => (L.jobClash, const Color(0xFFDC2626)),
      _ => (null, c.textPrimary),
    };
    final unit = switch (o.payUnit) {
      'drop' => L.perDrop,
      'hour' => L.perHour,
      _ => L.perShift,
    };
    TextStyle style(double size, FontWeight w, [Color? color]) => TextStyle(
      fontFamily: 'Manrope',
      fontSize: size,
      fontWeight: w,
      color: color ?? c.textPrimary,
    );
    return CeffloCard(
      onTap: onTap,
      shadow: false,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: o.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  o.initials,
                  style: style(14, FontWeight.w800, Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  o.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style(16.5, FontWeight.w800),
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: tagColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(tag, style: style(12.5, FontWeight.w700, tagColor)),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 1, color: c.border),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  [
                    _daysLabel(o.days),
                    _clock(o.start),
                    // Drops per run, not distance (Founder 2026-10-13);
                    // older posts without it keep the distance.
                    if (o.drops != null)
                      L.jobDrops(o.drops!)
                    else if (o.km != null)
                      '${_num(o.km!)} km',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style(14, FontWeight.w600),
                ),
              ),
              const SizedBox(width: Gap.md),
              Text(
                'RM ${_num(o.payAmount)}',
                style: style(17, FontWeight.w800),
              ),
              const SizedBox(width: 4),
              Text(unit, style: style(12.5, FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

/// My week on the navy header: one bar per day, yellow where the Driver
/// has a booked slot (lighter when only requested), white "Open schedule".
class _HeaderWeek extends StatelessWidget {
  const _HeaderWeek({required this.bookings, required this.onOpen});
  final List<_Booking> bookings;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final grid = _grid(bookings);
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const label = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: CefColors.onNavy,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.md, Gap.sm, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(L.myWeek, style: label)),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpen,
                child: Text('${L.openSchedule} ›', style: label),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Text(
                          days[d],
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: CefColors.onNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color:
                                grid[d].any((b) => _slotOf(b) == _Slot.booked)
                                ? CefColors.accent
                                : grid[d].any(
                                    (b) => _slotOf(b) == _Slot.requested,
                                  )
                                ? CefColors.accent.withValues(alpha: .5)
                                : Colors.white.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _busy = false;

  Future<void> _request(AppState app, _Opening o) async {
    setState(() => _busy = true);
    try {
      await _Jobs.request(app, o);
    } on RepositoryError catch (e) {
      if (!mounted) return;
      if (e.message.contains('marketplace verification required')) {
        showCefToast(context, L.mvRequiredToApply, error: true);
        AppScope.read(context).go(DRoute.documents);
      } else {
        showCefToast(context, e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ValueListenableBuilder<List<_Opening>?>(
      valueListenable: _Jobs.openings,
      builder: (context, all, _) {
        final list = all ?? const <_Opening>[];
        final index = list.indexWhere((o) => o.id == widget.jobId);
        if (index < 0) {
          return CeffloNavySheetScaffold(
            header: CeffloScreenHeader(title: L.findJobs, onBack: app.back),
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.xl),
              child: Text(
                L.noOpeningsShift,
                textAlign: TextAlign.center,
                style: context.t.bodyMedium,
              ),
            ),
          );
        }
        final o = list[index];
        final sent = o.myStatus != null;
        final blocked = !sent && o.clash != null;
        return CeffloNavySheetScaffold(
          header: CeffloScreenHeader(
            title: o.name,
            onBack: app.back,
            onBell: () => app.go(DRoute.notifications),
            subtitle: Text(
              o.meta,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13.5,
                color: CefColors.onNavyMuted,
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ZoneMap(lat: o.areaLat, lng: o.areaLng),
              // Founder screen 9: Days, Pickup time, Pay per drop, Vehicle,
              // Drivers needed, then About this hiring.
              _Kv(L.jobDays, _daysLabel(o.days)),
              _Kv(L.jobPickupTime, _clock(o.start)),
              _Kv(o.payUnit == 'drop' ? L.jobPayPerDrop : L.jobPay, o.pay),
              _Kv(L.jobVehicle, _vehicleLabel(o.vehicle)),
              _Kv(L.jobRidersNeeded, '${o.needed}'),
              _SectionRow(title: L.jobAbout),
              CeffloNote(
                icon: blocked ? LucideIcons.triangleAlert : LucideIcons.info,
                tone: blocked ? CeffloNoteTone.warning : CeffloNoteTone.info,
                body: sent
                    ? L.jobWaitingApproval
                    : (o.clash ?? L.jobOwnerReviews),
              ),
            ],
          ),
          // Back left, Apply right, one row (Founder 2026-10-13).
          footer: Row(
            children: [
              Expanded(child: CeffloSecondaryButton(L.back, onTap: app.back)),
              const SizedBox(width: Gap.md),
              Expanded(
                child: CeffloPrimaryButton(
                  sent ? L.jobApplied : L.jobApply,
                  busy: _busy,
                  onTap: sent || blocked || _busy
                      ? null
                      : () => _request(app, o),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Where the job is: a ~1.5 km circle around the rounded pickup area
/// (Founder 2026-10-13), so the driver sees the work area but not the
/// store's address before being hired. Illustrative when the area is unknown.
class _ZoneMap extends StatelessWidget {
  const _ZoneMap({this.lat, this.lng});
  final double? lat, lng;

  @override
  Widget build(BuildContext context) {
    final known = lat != null && lng != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      child: SizedBox(
        height: known ? 220 : 120,
        child: !known
            ? CustomPaint(painter: _ZonePainter(), size: Size.infinite)
            : Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(lat!, lng!),
                      initialZoom: 13,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      cefTileLayer(context),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(lat!, lng!),
                            radius: 1500,
                            useRadiusInMeter: true,
                            color: const Color(0xFF01265E)
                                .withValues(alpha: .12),
                            borderColor: const Color(0xFF01265E)
                                .withValues(alpha: .55),
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                      MapCredit(mapCredit),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Illustrative zone (no map provider while Mapbox is on hold).
class _ZonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE6EEF8),
    );
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;
    for (var x = -size.height; x < size.width; x += 30) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * .7, 0),
        road,
      );
    }
    final c = Offset(size.width * .5, size.height * .5);
    final r = Rect.fromCenter(
      center: c,
      width: size.width * .46,
      height: size.height * .64,
    );
    canvas.drawOval(r, Paint()..color = const Color(0x22005CC4));
    canvas.drawOval(
      r,
      Paint()
        ..color = const Color(0xFF005CC4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(c, 9, Paint()..color = Colors.white);
    canvas.drawCircle(c, 6, Paint()..color = CefColors.navy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Kv extends StatelessWidget {
  const _Kv(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: context.t.bodyMedium?.copyWith(
              color: context.c.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

// ----------------------------------------------------- D41.2 My Schedule

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _Jobs.load(AppScope.read(context));
    });
  }

  Future<void> _release(AppState app, List<_Booking> bookings) async {
    final picked = await showCefSheet<_Booking>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.gutter, 0, Gap.gutter, Gap.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(L.releaseSlot, style: sheet.t.titleMedium),
              const SizedBox(height: Gap.md),
              for (final b in bookings)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(b.name),
                  subtitle: Text(
                    '${_daysLabel(b.days)} · ${_span(b.start, b.end)}'
                    '${b.approved ? '' : ' · ${L.slotRequested}'}',
                  ),
                  trailing: TextButton(
                    onPressed: () => Navigator.of(sheet).pop(b),
                    child: Text(L.withdrawBooking),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    try {
      await _Jobs.withdraw(app, picked);
      if (mounted) showCefToast(context, L.bookingWithdrawn);
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ValueListenableBuilder<List<_Booking>>(
      valueListenable: _Jobs.bookings,
      builder: (context, bookings, _) => CeffloNavySheetScaffold(
        onRefresh: () => _Jobs.load(app),
        header: CeffloScreenHeader(
          title: L.mySchedule,
          onBack: app.back,
          onBell: () => app.go(DRoute.notifications),
          subtitle: Text(
            app.repo.isDemo
                ? L.scheduleWeekSub
                : L.scheduleCount(bookings.length),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13.5,
              color: CefColors.onNavyMuted,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScheduleGrid(bookings: bookings),
            const SizedBox(height: Gap.md),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _Legend(CefColors.navy, L.slotBooked),
                _Legend(const Color(0xFFFFF4CC), L.slotRequested),
              ],
            ),
            const SizedBox(height: Gap.lg),
            CeffloNote(
              icon: LucideIcons.info,
              body: bookings.isEmpty ? L.noBookingsYet : L.scheduleNote,
            ),
          ],
        ),
        footer: bookings.isEmpty
            ? null
            : CeffloSecondaryButton(
                L.releaseSlot,
                onTap: () => _release(app, bookings),
              ),
      ),
    );
  }
}

class _ScheduleGrid extends StatelessWidget {
  const _ScheduleGrid({required this.bookings});
  final List<_Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final grid = _grid(bookings);
    final head = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
      color: context.c.textSecondary,
    );
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 44),
            for (final h in [L.shiftMorning, L.shiftNoon, L.shiftNight])
              Expanded(
                child: Text(h, textAlign: TextAlign.center, style: head),
              ),
          ],
        ),
        for (var d = 0; d < 7; d++)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    _dayNames[d],
                    style: head.copyWith(color: context.c.textPrimary),
                  ),
                ),
                for (var s = 0; s < 3; s++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: _SlotTile(booking: grid[d][s]),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({this.booking});
  final _Booking? booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final (bg, fg) = switch (_slotOf(b)) {
      _Slot.booked => (CefColors.navy, Colors.white),
      _Slot.requested => (const Color(0xFFFFF4CC), const Color(0xFF5B4500)),
      _Slot.free => (CefColors.tintInfo, context.c.textSecondary),
    };
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: b == null
          ? const SizedBox.shrink()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                Text(
                  b.approved ? _span(b.start, b.end) : L.slotRequested,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10.5,
                    color: fg.withValues(alpha: .85),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: context.t.bodySmall?.copyWith(color: context.c.textSecondary),
      ),
    ],
  );
}
