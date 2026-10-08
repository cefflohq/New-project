import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/live_adapters.dart';
import '../../data/my_towns.dart';
import '../../data/rider_repository.dart';
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
  });

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
    km: 2.5,
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
    km: 3,
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
    km: 6,
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
    km: 18,
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
    final picked = await showModalBottomSheet<Object>(
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
          header: CeffloScreenHeader(
            title: L.findJobs,
            onBell: () => app.go(DRoute.notifications),
            subtitle: _AreaRow(
              label: place == null
                  ? L.chooseTown
                  : '${place.label} · ${L.withinKm('$radius')}',
              onChange: () => _changeLocation(app),
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
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final shown = [
            for (final o in all)
              if (_shift == null || o.shift == _shift) o,
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ShiftFilter(
                value: _shift,
                onChanged: (s) => setState(() => _shift = s),
              ),
              const SizedBox(height: Gap.sm),
              _RadiusFilter(
                value: radius,
                onChanged: (km) => _Jobs.setRadius(app, km),
              ),
              _SectionRow(
                title: L.myWeek,
                action: L.openSchedule,
                onAction: () => app.go(DRoute.mySchedule),
              ),
              ValueListenableBuilder<List<_Booking>>(
                valueListenable: _Jobs.bookings,
                builder: (context, b, _) => _WeekStrip(bookings: b),
              ),
              _SectionRow(title: L.openingsCount(shown.length)),
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
                _NoJobsNearby(
                  radius: radius,
                  place: place.label,
                  onExpand: radius < 50 ? () => _Jobs.setRadius(app, 50) : null,
                  onChangeLocation: () => _changeLocation(app),
                )
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
                  const SizedBox(height: Gap.cardGap),
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
            const Icon(LucideIcons.mapPin, size: 16, color: CefColors.onNavy),
            const SizedBox(width: Gap.sm),
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
            Text(
              L.changeArea,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CefColors.accent,
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

class _NoJobsNearby extends StatelessWidget {
  const _NoJobsNearby({
    required this.radius,
    required this.place,
    required this.onExpand,
    required this.onChangeLocation,
  });
  final int radius;
  final String place;
  final VoidCallback? onExpand;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Gap.lg),
    child: Column(
      children: [
        Text(
          L.noJobsWithin('$radius', place),
          textAlign: TextAlign.center,
          style: context.t.bodyMedium?.copyWith(color: context.c.textSecondary),
        ),
        const SizedBox(height: Gap.lg),
        if (onExpand != null)
          CeffloPrimaryButton(L.expandTo50, onTap: onExpand)
        else
          Text(
            L.tryAnotherLocation,
            style: context.t.bodyMedium?.copyWith(
              color: context.c.textSecondary,
            ),
          ),
        const SizedBox(height: Gap.sm),
        CeffloSecondaryButton(L.changeLocation, onTap: onChangeLocation),
      ],
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

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final towns = [
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
            TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _q = v),
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
  const _SectionRow({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.section, bottom: Gap.sm),
    child: Row(
      children: [
        Expanded(child: Text(title, style: context.t.titleSmall)),
        if (action != null)
          CeffloTextLink(
            action!,
            fontSize: 13,
            weight: FontWeight.w700,
            color: context.c.info,
            onTap: onAction ?? () {},
          ),
      ],
    ),
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

/// Seven days × Morning / Noon / Night: booked slots blue, requested yellow.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.bookings});
  final List<_Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final grid = _grid(bookings);
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: [
        for (var d = 0; d < 7; d++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  Text(
                    days[d],
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.c.textSecondary,
                    ),
                  ),
                  for (final b in grid[d]) ...[
                    const SizedBox(height: 3),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: switch (_slotOf(b)) {
                          _Slot.booked => const Color(0xFF005CC4),
                          _Slot.requested => CefColors.accent,
                          _Slot.free => CefColors.tintInfo,
                        },
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OpeningCard extends StatelessWidget {
  const _OpeningCard({required this.opening, required this.onTap});

  final _Opening opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = opening;
    return CeffloCard(
      onTap: onTap,
      shadow: false,
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _VendorBadge(opening: o),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.name, style: context.t.titleSmall),
                    Text(
                      o.meta,
                      style: context.t.bodySmall?.copyWith(
                        color: context.c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                o.pay,
                style: context.t.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Founder screen 8: days, pickup time, vehicle (no end time).
              _Pill(_daysLabel(o.days)),
              _Pill(L.jobPickupAt(_clock(o.start))),
              // Compatibility is information, not a warning (Founder 2026-10-05):
              // neutral grey; ranking and eligibility are unchanged.
              _Pill(
                o.vehicleMatch
                    ? _vehicleLabel(o.vehicle)
                    : '${_vehicleLabel(o.vehicle)} · ${L.differentVehicle}',
                tone: o.vehicleMatch ? _PillTone.neutral : _PillTone.muted,
              ),
              if (o.myStatus == 'approved')
                _Pill(L.slotBooked, tone: _PillTone.success)
              else if (o.myStatus == 'pending')
                _Pill(L.jobApplied, tone: _PillTone.success)
              else if (o.clash != null)
                _Pill(L.jobClash, tone: _PillTone.warning)
              else
                _Pill(L.jobNeeded(o.needed)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VendorBadge extends StatelessWidget {
  const _VendorBadge({required this.opening});
  final _Opening opening;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: opening.color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      opening.initials,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
  );
}

enum _PillTone { neutral, muted, success, warning }

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.tone = _PillTone.neutral});
  final String label;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _PillTone.success => (CefColors.tintSuccess, context.c.success),
      _PillTone.warning => (const Color(0xFFFDECEC), context.c.attention),
      _PillTone.neutral => (CefColors.tintInfo, CefColors.navy),
      _PillTone.muted => (CefColors.tintNeutral, context.c.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ------------------------------------------------------ D41.1 Job details

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
        final next = list[(index + 1) % list.length];
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
              const _ZoneMap(),
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
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CeffloPrimaryButton(
                sent ? L.jobApplied : L.jobApply,
                busy: _busy,
                onTap: sent || blocked || _busy ? null : () => _request(app, o),
              ),
              if (list.length > 1) ...[
                const SizedBox(height: Gap.sm),
                CeffloSecondaryButton(
                  L.nextOpening,
                  trailingChevron: true,
                  onTap: () {
                    // Swap this opening for the next (no history pile-up).
                    app.back();
                    app.go(DRoute.jobDetail, entityId: next.id);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ZoneMap extends StatelessWidget {
  const _ZoneMap();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(Sizes.cardRadius),
    child: SizedBox(
      height: 120,
      child: CustomPaint(painter: _ZonePainter(), size: Size.infinite),
    ),
  );
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
    final picked = await showModalBottomSheet<_Booking>(
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
