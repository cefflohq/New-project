import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../widgets.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// D41 Find Jobs family (Rider Hub, docs/cefflo/strategy/
// CEFFLO_RIDER_NETWORK_STRATEGY.md §7–13; Founder 2026-10-05).
//
// There is no Rider Hub backend yet (D-67), so the live app shows a clear
// "coming soon" state and never an invented opening. The prototype walks
// the designed flow with example openings so it can be reviewed. Rules the
// design keeps: a rider may join many vendors; booked times never overlap
// (with a travel buffer); a request lands in the vendor's Riders > Pending
// and only the Owner can approve it.
// ---------------------------------------------------------------------------

enum _Shift { morning, noon, night }

String _shiftLabel(_Shift s) => switch (s) {
  _Shift.morning => L.shiftMorning,
  _Shift.noon => L.shiftNoon,
  _Shift.night => L.shiftNight,
};

class _Opening {
  const _Opening({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.km,
    required this.shift,
    required this.time,
    required this.days,
    required this.pay,
    required this.needed,
    required this.vehicle,
    required this.color,
    required this.requirements,
    this.clash,
  });

  final String id, name, category, area, time, days, pay, vehicle;
  final double km;
  final _Shift shift;
  final int needed;
  final Color color;
  final List<String> requirements;

  /// Why this opening cannot be requested (overlap or travel buffer).
  final String? clash;

  String get initials => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join();
}

/// Example openings for the prototype only (Alor Setar, Kedah).
const _examples = <_Opening>[
  _Opening(
    id: 'mak-som',
    name: 'Kedai Roti Mak Som',
    category: 'Bakery',
    area: 'Taman Uda',
    km: 2.4,
    shift: _Shift.morning,
    time: '7:00 – 11:00 AM',
    days: 'Mon – Fri',
    pay: 'RM 45 / shift',
    needed: 2,
    vehicle: 'Motorcycle',
    color: Color(0xFFC2410C),
    requirements: ['Motorcycle', 'Own phone'],
  ),
  _Opening(
    id: 'pelita',
    name: 'Nasi Kandar Pelita Jaya',
    category: 'Restaurant',
    area: 'Jalan Langgar',
    km: 3.1,
    shift: _Shift.noon,
    time: '12:00 – 3:00 PM',
    days: 'Daily',
    pay: 'RM 40 / shift',
    needed: 3,
    vehicle: 'Motorcycle',
    color: Color(0xFF0E7490),
    requirements: ['Motorcycle', 'Lunch rush'],
    clash: 'Clashes with Ayam Gepuk Pak Gembus (12:00 – 3:00 PM, Tue).',
  ),
  _Opening(
    id: 'pak-gembus',
    name: 'Ayam Gepuk Pak Gembus',
    category: 'Restaurant',
    area: 'Mergong',
    km: 4.8,
    shift: _Shift.noon,
    time: '12:30 – 3:30 PM',
    days: 'Sat – Sun',
    pay: 'RM 9 / drop',
    needed: 1,
    vehicle: 'Motorcycle',
    color: Color(0xFFB91C1C),
    requirements: ['Motorcycle', 'Weekend'],
  ),
  _Opening(
    id: 'kek-lapis',
    name: 'Kek Lapis Sarawak Mama',
    category: 'Home baker',
    area: 'Anak Bukit',
    km: 6.2,
    shift: _Shift.night,
    time: '6:00 – 9:00 PM',
    days: 'Fri – Sun',
    pay: 'RM 50 / shift',
    needed: 1,
    vehicle: 'Car',
    color: Color(0xFF7C3AED),
    requirements: ['Car', 'Fragile items'],
  ),
  _Opening(
    id: 'pasar-tani',
    name: 'Pasar Tani Online Kedah',
    category: 'Groceries',
    area: 'Stargate',
    km: 7.9,
    shift: _Shift.morning,
    time: '8:00 AM – 12:00 PM',
    days: 'Sat',
    pay: 'RM 60 / shift',
    needed: 2,
    vehicle: 'Van',
    color: Color(0xFF15803D),
    requirements: ['Van', 'Heavy items'],
    clash: 'Too close to Kedai Roti Mak Som (ends 11:00 AM, 18 km away). A 1 h travel buffer is needed.',
  ),
];

/// Prototype session state: which example openings were requested.
final _requested = ValueNotifier<Set<String>>(<String>{});

// ------------------------------------------------------------ D41 Find Jobs

class FindJobsScreen extends StatefulWidget {
  const FindJobsScreen({super.key});

  @override
  State<FindJobsScreen> createState() => _FindJobsScreenState();
}

class _FindJobsScreenState extends State<FindJobsScreen> {
  _Shift? _shift;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final demo = app.repo.isDemo;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.findJobs,
        onBell: () => app.go(DRoute.notifications),
        subtitle: demo ? const _AreaRow() : null,
      ),
      body: demo ? _openings(context, app) : const _ComingSoon(),
    );
  }

  Widget _openings(BuildContext context, AppState app) =>
      ValueListenableBuilder<Set<String>>(
        valueListenable: _requested,
        builder: (context, requested, _) {
          final shown = [
            for (final o in _examples)
              if (_shift == null || o.shift == _shift) o,
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ShiftFilter(
                value: _shift,
                onChanged: (s) => setState(() => _shift = s),
              ),
              _SectionRow(
                title: L.myWeek,
                action: L.openSchedule,
                onAction: () => app.go(DRoute.mySchedule),
              ),
              _WeekStrip(requested: requested),
              _SectionRow(title: L.openingsCount(shown.length)),
              if (shown.isEmpty)
                Text(L.noOpeningsShift, style: context.t.bodyMedium)
              else
                for (final o in shown) ...[
                  _OpeningCard(
                    opening: o,
                    requested: requested.contains(o.id),
                    onTap: () => app.go(DRoute.jobDetail, entityId: o.id),
                  ),
                  const SizedBox(height: Gap.cardGap),
                ],
              const SizedBox(height: Gap.sm),
              Text(
                L.previewOnly,
                textAlign: TextAlign.center,
                style: context.t.bodySmall?.copyWith(
                  color: context.c.textSecondary,
                ),
              ),
            ],
          );
        },
      );
}

class _AreaRow extends StatelessWidget {
  const _AreaRow();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.sm, Gap.sm, 0),
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
          const Expanded(
            child: Text(
              'Alor Setar, Kedah · 10 km',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CefColors.onNavy,
              ),
            ),
          ),
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
  );
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

/// Seven days × Morning / Noon / Night: booked slots navy, requested yellow.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.requested});
  final Set<String> requested;

  @override
  Widget build(BuildContext context) {
    final grid = _weekGrid(requested);
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
                  for (final s in grid[d]) ...[
                    const SizedBox(height: 3),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: switch (s) {
                          _Slot.booked => const Color(0xFF005CC4),
                          _Slot.requested => CefColors.accent,
                          _ => CefColors.tintInfo,
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

enum _Slot { free, booked, requested, buffer }

/// The prototype week: Mak Som every weekday morning, Pak Gembus Tuesday
/// noon, Pelita Jaya weekend noon; requests show as requested.
List<List<_Slot>> _weekGrid(Set<String> requested) {
  final g = List.generate(7, (_) => List.filled(3, _Slot.free));
  for (var d = 0; d < 5; d++) {
    g[d][0] = _Slot.booked;
  }
  g[0][1] = _Slot.buffer;
  g[1][1] = _Slot.booked;
  g[5][1] = g[6][1] = requested.contains('pak-gembus')
      ? _Slot.requested
      : _Slot.booked;
  if (requested.contains('kek-lapis')) {
    for (final d in [4, 5, 6]) {
      g[d][2] = _Slot.requested;
    }
  }
  return g;
}

class _OpeningCard extends StatelessWidget {
  const _OpeningCard({
    required this.opening,
    required this.requested,
    required this.onTap,
  });

  final _Opening opening;
  final bool requested;
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
                      '${o.category} · ${o.area} · ${o.km} km',
                      style: context.t.bodySmall?.copyWith(
                        color: context.c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                o.pay.split(' / ').first,
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
              _Pill(_shiftLabel(o.shift)),
              _Pill(o.time),
              _Pill(o.days),
              if (requested)
                _Pill(L.jobRequested, tone: _PillTone.success)
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

enum _PillTone { neutral, success, warning }

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

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Gap.xl),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: CefColors.tintInfo,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.searchCheck,
            size: 32,
            color: CefColors.navy,
          ),
        ),
        const SizedBox(height: Gap.lg),
        Text(
          L.findJobsComingSoonTitle,
          textAlign: TextAlign.center,
          style: context.t.titleMedium,
        ),
        const SizedBox(height: Gap.sm),
        Text(
          L.findJobsComingSoonBody,
          textAlign: TextAlign.center,
          style: context.t.bodyMedium?.copyWith(color: context.c.textSecondary),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------ D41.1 Job details

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final index = _examples.indexWhere((o) => o.id == jobId);
    if (!app.repo.isDemo || index < 0) {
      return CeffloNavySheetScaffold(
        header: CeffloScreenHeader(title: L.findJobs, onBack: app.back),
        body: const _ComingSoon(),
      );
    }
    final o = _examples[index];
    final next = _examples[(index + 1) % _examples.length];
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _requested,
      builder: (context, requested, _) {
        final sent = requested.contains(o.id);
        final blocked = !sent && o.clash != null;
        return CeffloNavySheetScaffold(
          header: CeffloScreenHeader(
            title: o.name,
            onBack: app.back,
            onBell: () => app.go(DRoute.notifications),
            subtitle: Text(
              '${o.category} · ${o.area} · ${o.km} km',
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
              _SectionRow(title: L.jobShift),
              _Kv(L.jobTime, '${_shiftLabel(o.shift)} · ${o.time}'),
              _Kv(L.jobDays, o.days),
              _Kv(L.jobPay, o.pay),
              _Kv(L.jobRidersNeeded, '${o.needed}'),
              _Kv(L.jobVehicle, o.vehicle),
              _SectionRow(title: L.jobRequirements),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final r in o.requirements) _Pill(r)],
              ),
              const SizedBox(height: Gap.lg),
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
                sent ? L.requestSent : L.requestToJoin,
                onTap: sent || blocked
                    ? null
                    : () => _requested.value = {...requested, o.id},
              ),
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

class MyScheduleScreen extends StatelessWidget {
  const MyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.repo.isDemo) {
      return CeffloNavySheetScaffold(
        header: CeffloScreenHeader(title: L.mySchedule, onBack: app.back),
        body: const _ComingSoon(),
      );
    }
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _requested,
      builder: (context, requested, _) => CeffloNavySheetScaffold(
        header: CeffloScreenHeader(
          title: L.mySchedule,
          onBack: app.back,
          onBell: () => app.go(DRoute.notifications),
          subtitle: Text(
            L.scheduleWeekSub,
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
            _ScheduleGrid(requested: requested),
            const SizedBox(height: Gap.md),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _Legend(CefColors.navy, L.slotBooked),
                _Legend(const Color(0xFFFFF4CC), L.slotRequested),
                _Legend(const Color(0xFFE8ECF3), L.slotTravelBuffer),
              ],
            ),
            const SizedBox(height: Gap.lg),
            CeffloNote(icon: LucideIcons.info, body: L.scheduleNote),
          ],
        ),
        footer: CeffloSecondaryButton(L.releaseSlot, onTap: () {}),
      ),
    );
  }
}

class _ScheduleGrid extends StatelessWidget {
  const _ScheduleGrid({required this.requested});
  final Set<String> requested;

  @override
  Widget build(BuildContext context) {
    final grid = _weekGrid(requested);
    final days = [L.mon, L.tue, L.wed, L.thu, L.fri, L.sat, L.sun];
    String? vendor(int d, int s) => switch ((d, s)) {
      (< 5, 0) => 'Mak Som',
      (1, 1) => 'Pak Gembus',
      (> 4, 1) =>
        requested.contains('pak-gembus') ? 'Pak Gembus' : 'Pelita Jaya',
      (> 3, 2) => 'Kek Lapis',
      _ => null,
    };
    String? hours(int d, int s) => switch ((d, s)) {
      (< 5, 0) => '7 – 11 AM',
      (_, 1) => '12 – 3 PM',
      _ => null,
    };
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
                    days[d],
                    style: head.copyWith(color: context.c.textPrimary),
                  ),
                ),
                for (var s = 0; s < 3; s++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: _SlotTile(
                        slot: grid[d][s],
                        vendor: vendor(d, s),
                        hours: grid[d][s] == _Slot.requested
                            ? L.slotRequested
                            : hours(d, s),
                      ),
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
  const _SlotTile({required this.slot, this.vendor, this.hours});
  final _Slot slot;
  final String? vendor, hours;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (slot) {
      _Slot.booked => (CefColors.navy, Colors.white),
      _Slot.requested => (const Color(0xFFFFF4CC), const Color(0xFF5B4500)),
      _Slot.buffer => (const Color(0xFFE8ECF3), context.c.textSecondary),
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
      child: switch (slot) {
        _Slot.free => const SizedBox.shrink(),
        _Slot.buffer => Text(
          L.slotTravelBuffer,
          style: TextStyle(fontFamily: 'Manrope', fontSize: 10.5, color: fg),
        ),
        _ => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vendor ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            if (hours != null)
              Text(
                hours!,
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
      },
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
