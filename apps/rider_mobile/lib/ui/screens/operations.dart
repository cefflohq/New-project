import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/dial.dart';
import '../../data/demo_data.dart';
import '../../data/driver_models.dart';
import '../map_canvas.dart';
import '../run_map.dart';
import '../bottom_surface.dart';
import '../widgets.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// Shared operational pieces
// ---------------------------------------------------------------------------

/// Icon + text meta line — "Setapak", "12 orders", "3.2 km", "Started 10:20 AM".
class MetaRow extends StatelessWidget {
  const MetaRow({
    super.key,
    required this.icon,
    required this.text,
    this.dense = false,
  });

  final IconData icon;
  final String text;
  final bool dense;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: dense ? 3 : 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: context.c.textLabel),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: context.c.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Label on the left, value on the right — D32's Zone / Vehicle / Started /
/// Completed block and D30's summary rows.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.divider = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool divider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: context.c.textLabel),
              const SizedBox(width: 11),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14.5,
                  fontWeight: icon == null ? FontWeight.w500 : FontWeight.w600,
                  color: icon == null
                      ? context.c.textSecondary
                      : context.c.textPrimary,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: context.c.textPrimary,
              ),
            ),
          ],
        ),
      ),
      if (divider) Divider(height: 1, color: context.c.border),
    ],
  );
}

/// One of D19's four Today's Overview counters.
class OverviewTile extends StatelessWidget {
  const OverviewTile({
    super.key,
    required this.value,
    required this.label,
    required this.labelColor,
  });

  final int value;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 62,
      decoration: BoxDecoration(
        color: CefColors.tintNeutral,
        borderRadius: BorderRadius.circular(Sizes.innerRadius),
        border: Border.all(color: context.c.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.c.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The translucent business identity row sitting on the navy header in D18
/// and D19.
class NavyBusinessRow extends StatelessWidget {
  const NavyBusinessRow({super.key, required this.business, this.onTap});

  final DriverBusiness business;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(Sizes.cardRadius),
    child: InkWell(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.store,
                size: 20,
                color: CefColors.navy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CefColors.onNavy,
                    ),
                  ),
                  Text(
                    business.location,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CefColors.onNavyMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: CefColors.onNavyMuted,
              ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// D19 — Today (Home)
// ---------------------------------------------------------------------------

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    return CeffloNavySheetScaffold(
      onRefresh: app.refreshOrders,
      header: CeffloBrandHeader(
        onBell: () => app.go(DRoute.notifications),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 14,
            bottom: Gap.lg,
            right: Gap.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L.goodMorning2,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
              Text(
                app.profile.fullName,
                style: context.t.displayMedium?.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 2),
              Text(
                L.letsGetToday,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(L.todaysOverview, style: context.t.titleMedium),
              ),
              Text(app.todayDateLabel, style: context.t.bodySmall),
            ],
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              OverviewTile(
                value: app.todayAssigned,
                label: L.assigned,
                labelColor: c.success,
              ),
              const SizedBox(width: Gap.sm),
              OverviewTile(
                value: app.todayOngoing,
                label: L.ongoing,
                labelColor: const Color(0xFFE08A00),
              ),
              const SizedBox(width: Gap.sm),
              OverviewTile(
                value: app.todayIssues,
                label: L.issues,
                labelColor: c.textSecondary,
              ),
              const SizedBox(width: Gap.sm),
              OverviewTile(
                value: app.todayCompleted,
                label: L.completed,
                labelColor: c.info,
              ),
            ],
          ),
          const SizedBox(height: Gap.section),
          // Every vendor's work for today in one list (Founder 2026-10-13);
          // a finished run drops off.
          Builder(
            builder: (context) {
              final jobs = app.todayJobs;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(L.todaysJobs, style: context.t.titleMedium),
                      ),
                      if (jobs.length > 1)
                        Text(
                          L.vendorsCount(jobs.length),
                          style: context.t.bodySmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  if (jobs.isEmpty)
                    CeffloNote(
                      icon: LucideIcons.calendarCheck,
                      title: L.noJobsToday,
                      body: L.noJobsTodayBody,
                    )
                  else
                    for (final job in jobs) ...[
                      _JobCard(job: job, onTap: () => app.openJob(job)),
                      const SizedBox(height: Gap.cardGap),
                    ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Ongoing: Cefflo yellow with dark text; coming soon: light grey
/// (Founder 2026-10-13). Same chip on Home and Run Details.
class _JobStatusChip extends StatelessWidget {
  const _JobStatusChip({required this.ongoing, this.done = false});
  final bool ongoing, done;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: ongoing && !done ? CefColors.accent : CefColors.tintNeutral,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      done ? L.completed : (ongoing ? L.ongoing : L.comingSoon),
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: ongoing && !done ? CefColors.onAccent : context.c.textSecondary,
      ),
    ),
  );
}

/// One vendor's job on Home: round avatar, name, pickup time, open orders,
/// Ongoing / Coming soon. Every card has the same height.
class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onTap});
  final DriverJob job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final meta = context.t.bodySmall?.copyWith(color: c.textSecondary);
    Widget line(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 16, color: c.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: meta,
          ),
        ),
      ],
    );
    return CeffloCard(
      onTap: onTap,
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        height: 116,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: CefColors.tintInfo,
                shape: BoxShape.circle,
              ),
              child: Text(
                job.initials,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CefColors.navy,
                ),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.vendorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.t.titleMedium?.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  _JobStatusChip(ongoing: job.ongoing),
                  const SizedBox(height: 6),
                  if (job.pickupTimeLabel != null)
                    line(
                      LucideIcons.clock,
                      L.jobPickupAt(job.pickupTimeLabel!),
                    ),
                  line(
                    LucideIcons.package,
                    job.orderCount == 0
                        ? L.runNoOrdersYet
                        : L.orders2(job.orderCount),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.sm),
            // Navigate / Call to the store right from Home (2026-10-13).
            _RoundAction(
              light: true,
              icon: LucideIcons.navigation,
              onTap: () async {
                if (!await openNavigation(
                      lat: job.storeLatitude,
                      lng: job.storeLongitude,
                      address: job.storeAddress,
                    ) &&
                    context.mounted) {
                  showCefToast(context, L.mapNotAvailable);
                }
              },
            ),
            if ((job.storePhone ?? '').trim().isNotEmpty) ...[
              const SizedBox(width: Gap.sm),
              _RoundAction(
                light: true,
                icon: LucideIcons.phone,
                onTap: () async {
                  if (!await dialPhone(job.storePhone) && context.mounted) {
                    showCefToast(context, L.mapNotAvailable);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D20 — Run Details
// ---------------------------------------------------------------------------

class RunDetailsScreen extends StatelessWidget {
  const RunDetailsScreen({super.key});

  static String _rm(num v) => 'RM ${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final run = app.currentRun;
    final started = run.state != RunState.assigned;
    final total = run.orderCount;
    // One line: pickup (or start) time and date on the left, status on the
    // right (Founder 2026-10-13).
    final when = started && run.startedAtLabel != null
        ? L.runStartedAt(run.startedAtLabel!)
        : (run.pickupTimeLabel == null
              ? null
              : L.jobPickupAt(run.pickupTimeLabel!));
    return CeffloNavySheetScaffold(
      onRefresh: app.refreshOrders,
      header: Column(
        children: [
          CeffloScreenHeader(
            title: L.runDetails,
            onBack: app.back,
            onBell: () => app.go(DRoute.notifications),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.gutter,
              0,
              Gap.gutter,
              Gap.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The vendor first, so the Driver knows which run
                      // this is (Founder 2026-10-13); then the time.
                      Text(
                        run.pickupBusinessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: CefColors.onNavy,
                        ),
                      ),
                      Text(
                        [?when, run.dateLabel].join(' · '),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CefColors.onNavyMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Same status as Home's card: Ongoing (yellow) or Coming
                // soon (light grey); Completed once done.
                _JobStatusChip(
                  ongoing: run.ongoing,
                  done: run.state == RunState.completed,
                ),
              ],
            ),
          ),
        ],
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.section,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (total == 0)
            CeffloNote(
              icon: LucideIcons.package,
              title: L.runNoOrdersYet,
              body: L.runStoreWillAdd,
            )
          else if (run.earningsFor(total) case final pay?)
            // Same screen before and during the run (Founder 2026-10-13):
            // the vendor and time (header), the pay, the orders.
            _RunPay(
              label: L.runYouEarn,
              amount: _rm(pay),
              detail: L.runDropsRate(total, _rm(run.payPerDrop!)),
            ),
          if (app.runPhase == RunPhase.pickup) ...[
            const SizedBox(height: Gap.md),
            _PickupChecklist(run: run),
          ] else if (started && total > 0) ...[
            // Picked up: the same checklist, every order ticked.
            const SizedBox(height: Gap.md),
            _PickupChecklist(run: run, pickedUp: true),
          ] else if (!started && total > 0) ...[
            const SizedBox(height: Gap.md),
            _RunSection(
              title: run.area == null
                  ? L.runDeliveriesSection
                  : '${L.runDeliveriesSection} · ${run.area}',
              children: [
                _StopLine(index: 1, stop: run.stops.first),
                if (total > 1) ...[
                  const SizedBox(height: Gap.sm),
                  _StopLine(index: total, stop: run.stops.last),
                ],
                if (total > 2)
                  Padding(
                    padding: const EdgeInsets.only(left: 36, top: Gap.xs),
                    child: Text(
                      L.runMoreStops(total - 2),
                      style: context.t.bodySmall,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: Gap.lg),
          _RunPrimaryAction(runId: run.id),
        ],
      ),
    );
  }
}

/// Pickup Checklist (R-11, Founder 2026-10-13): the Driver ticks every
/// order in hand against the store's sorting; Slide to Confirm Pickup stays
/// grey until all are ticked.
class _PickupChecklist extends StatelessWidget {
  const _PickupChecklist({required this.run, this.pickedUp = false});
  final DriverRun run;

  /// The run is under way: every order shows ticked, read-only.
  final bool pickedUp;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final open = pickedUp
        ? run.stops.where((s) => s.status != StopStatus.issue).toList()
        : app.pickupStops.toList();
    final done = pickedUp
        ? open.length
        : open.where((s) => app.pickupTicks.contains(s.id)).length;
    return CeffloCard(
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  L.pickupChecklist.toUpperCase(),
                  style: context.t.labelSmall?.copyWith(
                    letterSpacing: .6,
                    color: c.textSecondary,
                  ),
                ),
              ),
              Text(
                L.pickupTicked(done, open.length),
                style: context.t.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: done == open.length ? c.success : c.textSecondary,
                ),
              ),
            ],
          ),
          if (!pickedUp && !app.pickupWindowOpen) ...[
            const SizedBox(height: Gap.sm),
            CeffloNote(
              icon: LucideIcons.lock,
              body: L.pickupOpensAt(
                _clockOfMinutes(app.pickupOpensAt!),
                AppState.pickupWindowMinutes,
              ),
            ),
          ],
          const SizedBox(height: Gap.xs),
          for (final s in run.stops)
            _PickupRow(
              stop: s,
              ticked: pickedUp || app.pickupTicks.contains(s.id),
              reported: s.status == StopStatus.issue,
              readOnly: pickedUp,
              locked: !pickedUp && !app.pickupWindowOpen,
              onTap: () => app.togglePickupTick(s.id),
              onReport: () => _reportAtPickup(context, s),
            ),
        ],
      ),
    );
  }
}

class _PickupRow extends StatelessWidget {
  const _PickupRow({
    required this.stop,
    required this.ticked,
    required this.reported,
    required this.onTap,
    required this.onReport,
    this.readOnly = false,
    this.locked = false,
  });
  final DriverStop stop;
  final bool ticked, reported, readOnly;

  /// Before the pickup window: greyed, no tick, no Report.
  final bool locked;
  final VoidCallback onTap, onReport;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final items = stop.items.fold(0, (a, i) => a + i.quantity);
    final row = InkWell(
      onTap: reported || readOnly || locked ? null : onTap,
      borderRadius: BorderRadius.circular(Sizes.innerRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Ticked: a solid green circle with a white check.
            if (ticked && !reported)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: c.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 16,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                reported ? LucideIcons.circleAlert : LucideIcons.circle,
                size: 24,
                color: reported ? c.attention : c.textSecondary,
              ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.reference, style: context.t.titleSmall),
                  Text(
                    reported
                        ? L.pickupReported
                        : [
                            stop.customerName,
                            if (items > 0) L.itemsCount(items),
                          ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.t.bodySmall?.copyWith(
                      color: reported ? c.attention : null,
                    ),
                  ),
                ],
              ),
            ),
            if (!reported && !readOnly)
              TextButton(
                onPressed: locked ? null : onReport,
                child: Text(L.pickupReport),
              ),
          ],
        ),
      ),
    );
    return locked ? Opacity(opacity: .45, child: row) : row;
  }
}

String _clockOfMinutes(int m) {
  final h = (m ~/ 60) % 24, min = m % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${min.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}

/// Report a problem with one order at pickup (R-11): not ready at the store
/// or an item missing, both recorded as vendor_not_ready with the note. The
/// order leaves the run's pickup; the rest can still be picked up.
Future<void> _reportAtPickup(BuildContext context, DriverStop stop) async {
  final app = AppScope.read(context);
  final note = TextEditingController();
  var notReady = true;
  final sent = await showCeffloSheet<bool>(
    context,
    child: StatefulBuilder(
      builder: (sheet, set) => Padding(
        padding: EdgeInsets.fromLTRB(
          Gap.gutter,
          Gap.sm,
          Gap.gutter,
          MediaQuery.viewInsetsOf(sheet).bottom + Gap.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetGrabber(),
            Text(
              L.pickupProblemTitle(stop.reference),
              style: sheet.t.titleMedium,
            ),
            const SizedBox(height: Gap.md),
            CeffloSegmentedTabs(
              labels: [L.pickupNotReady, L.pickupItemMissing],
              index: notReady ? 0 : 1,
              onChanged: (i) => set(() => notReady = i == 0),
            ),
            const SizedBox(height: Gap.md),
            CeffloTextField(
              label: L.pickupNoteHint,
              controller: note,
              maxLines: 2,
            ),
            const SizedBox(height: Gap.lg),
            CeffloPrimaryButton(
              L.submit,
              onTap: () => Navigator.of(sheet).pop(true),
            ),
          ],
        ),
      ),
    ),
  );
  if (sent != true) return;
  final text = [
    notReady ? L.pickupNotReady : L.pickupItemMissing,
    if (note.text.trim().isNotEmpty) note.text.trim(),
  ].join(': ');
  try {
    await app.reportIssue(stop.id, IssueReason.itemsNotAvailable, text);
    app.pickupTicks.remove(stop.id);
  } catch (e) {
    if (context.mounted) showCefToast(context, '$e', error: true);
  }
}

/// The Driver's pay for this run, from the per-drop hiring contract.
class _RunPay extends StatelessWidget {
  const _RunPay({
    required this.label,
    required this.amount,
    required this.detail,
  });
  final String label, amount, detail;

  @override
  Widget build(BuildContext context) => CeffloCard(
    shadow: false,
    color: CefColors.tintSuccess,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.t.bodySmall),
              Text(
                amount,
                style: context.t.displaySmall?.copyWith(fontSize: 22),
              ),
              Text(detail, style: context.t.bodySmall),
            ],
          ),
        ),
        CeffloStatusChip(L.runPerDrop, tone: ChipTone.success),
      ],
    ),
  );
}

class _RunSection extends StatelessWidget {
  const _RunSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CeffloCard(
    shadow: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: context.t.labelSmall?.copyWith(
            letterSpacing: .6,
            color: context.c.textSecondary,
          ),
        ),
        const SizedBox(height: Gap.sm),
        ...children,
      ],
    ),
  );
}

class _StopLine extends StatelessWidget {
  const _StopLine({required this.index, required this.stop});
  final int index;
  final DriverStop stop;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CeffloIndexBadge(index, tone: ChipTone.info, size: 26),
      const SizedBox(width: Gap.md - 2),
      Expanded(
        child: Text(
          stop.addressLine1,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.t.bodyMedium,
        ),
      ),
    ],
  );
}

/// D20's primary button, following the canonical run phase: accept_run,
/// Plan Route, the pickup handoff, then the deliveries. None once done or
/// for an empty run.
class _RunPrimaryAction extends StatefulWidget {
  const _RunPrimaryAction({required this.runId});
  final String runId;

  @override
  State<_RunPrimaryAction> createState() => _RunPrimaryActionState();
}

class _RunPrimaryActionState extends State<_RunPrimaryAction> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showCefToast(context, '$e', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final run = app.currentRun;
    if (run.orderCount == 0) return const SizedBox.shrink();
    void stops() => app.go(DRoute.stopList, entityId: widget.runId);
    final phase = app.repo.isDemo && app.runPhase == null
        ? (run.state == RunState.assigned
              ? RunPhase.route
              : run.state == RunState.completed
              ? RunPhase.done
              : RunPhase.delivering)
        : app.runPhase;
    return switch (phase) {
      RunPhase.accept => CeffloPrimaryButton(
        L.acceptRun,
        busy: _busy,
        onTap: _busy ? null : () => _run(app.acceptCurrentRun),
      ),
      // Pickup Checklist (Founder 2026-10-13): grey and locked until every
      // order is ticked; the pickup then opens Plan Route.
      RunPhase.pickup => CeffloSlideAction(
        label: L.slideConfirmPickup,
        enabled: app.allPickupTicked,
        onConfirmed: () async {
          try {
            await app.confirmPickup();
            app.go(DRoute.stopList, entityId: widget.runId);
          } catch (e) {
            if (context.mounted) showCefToast(context, '$e', error: true);
          }
        },
      ),
      RunPhase.route => CeffloPrimaryButton(L.runPlanRoute, onTap: stops),
      RunPhase.delivering => CeffloPrimaryButton(
        L.runContinueDelivery,
        onTap: stops,
      ),
      RunPhase.done || null => const SizedBox.shrink(),
    };
  }
}

// ---------------------------------------------------------------------------
// D21 / D21.1 / D21.2 — Stop List
// ---------------------------------------------------------------------------

/// One screen family with two phases, exactly as the references draw it:
/// before the route is confirmed it is the planning surface with the
/// List/Map toggle and "Slide to Confirm Route" (D21.1 / D21.2); once
/// confirmed it is the filtered operational Stop List (D21).
class StopListScreen extends StatefulWidget {
  const StopListScreen({super.key});

  @override
  State<StopListScreen> createState() => _StopListScreenState();
}

class _StopListScreenState extends State<StopListScreen> {
  late int _planTab = AppScope.read(context).stopListMapView
      ? 1
      : 0; // 0 = List (D21.1), 1 = Map (D21.2)
  int _filter = 0; // 0 = All, 1 = Pending, 2 = Delivered

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final run = app.currentRun;
    final header = CeffloScreenHeader(
      title: L.stopList,
      onBack: app.back,
      onBell: () => app.go(DRoute.notifications),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              L.orders3(run.reference, run.orderCount),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CefColors.onNavy,
              ),
            ),
          ),
          const Icon(LucideIcons.navigation, size: 16, color: CefColors.onNavy),
          const SizedBox(width: 6),
          Text(
            run.distanceText,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CefColors.onNavy,
            ),
          ),
        ],
      ),
    );

    if (app.routeConfirmed) return _confirmed(context, app, run, header);
    return _planning(context, app, run, header);
  }

  // --- D21 (route confirmed) ---------------------------------------------

  Widget _confirmed(
    BuildContext context,
    AppState app,
    DriverRun run,
    Widget header,
  ) {
    final all = run.stops;
    final pending = all.where((s) => s.status != StopStatus.delivered).toList();
    final delivered = all
        .where((s) => s.status == StopStatus.delivered)
        .toList();
    final shown = switch (_filter) {
      1 => pending,
      2 => delivered,
      _ => all,
    };
    return CeffloNavySheetScaffold(
      onRefresh: app.refreshOrders,
      header: header,
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CeffloSegmentedTabs(
            labels: [
              L.all(all.length),
              L.pending(pending.length),
              L.delivered2(delivered.length),
            ],
            index: _filter,
            onChanged: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 6),
          if (shown.isEmpty)
            StateBlock.empty(L.noStopsView)
          else
            for (final stop in shown) ...[
              StopRow(
                index: all.indexOf(stop) + 1,
                stop: stop,
                onTap: () {
                  app.setActiveStop(stop.id);
                  app.go(DRoute.navigationToStop, entityId: stop.id);
                },
              ),
              if (stop != shown.last)
                Divider(height: 1, color: context.c.border),
            ],
        ],
      ),
    );
  }

  // --- D21.1 / D21.2 (planning) ------------------------------------------

  Widget _planning(
    BuildContext context,
    AppState app,
    DriverRun run,
    Widget header,
  ) {
    final isMap = _planTab == 1;
    return CeffloNavySheetScaffold(
      header: header,
      scrollable: false,
      bodyPadding: EdgeInsets.fromLTRB(
        isMap ? 0 : Gap.gutter,
        Gap.lg,
        isMap ? 0 : Gap.gutter,
        0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMap ? Gap.gutter : 0),
            child: Column(
              children: [
                CeffloSegmentedTabs(
                  labels: [L.list, L.map],
                  index: _planTab,
                  onChanged: (i) => setState(() => _planTab = i),
                ),
                const SizedBox(height: Gap.md),
                // One short hint line, List tab only and only when there is
                // something to reorder (Founder 2026-10-13: no long note).
                if (!isMap && run.stops.length > 1) ...[
                  Row(
                    children: [
                      Icon(
                        LucideIcons.gripVertical,
                        size: 16,
                        color: context.c.textSecondary,
                      ),
                      const SizedBox(width: Gap.xs),
                      Text(
                        L.dragToReorder,
                        style: context.t.bodySmall?.copyWith(
                          color: context.c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.sm),
                ],
              ],
            ),
          ),
          Expanded(
            child: isMap
                ? _mapView(context, run)
                : _reorderList(context, app, run),
          ),
        ],
      ),
      // Founder 2026-10-13: Pickup Checklist -> Plan Route (here) -> Slide to
      // Start Delivery, which saves this stop order and starts the run. On
      // the List tab only, never for an empty run, and only once the
      // pickup is done.
      footer:
          isMap ||
              run.stops.isEmpty ||
              (!app.repo.isDemo && app.runPhase != RunPhase.route)
          ? null
          : CeffloSlideAction(
              label: L.slideStartDelivery,
              onConfirmed: () async {
                try {
                  // save_run_sequence (this order) + start_run_delivery.
                  await app.confirmRouteAndStart();
                  if (mounted) setState(() => _filter = 0);
                } catch (e) {
                  if (context.mounted) {
                    showCefToast(context, '$e', error: true);
                  }
                }
              },
            ),
    );
  }

  Widget _reorderList(BuildContext context, AppState app, DriverRun run) =>
      run.stops.isEmpty
      ? StateBlock.empty(L.noStopsView)
      : ReorderableListView.builder(
          padding: EdgeInsets.zero,
          buildDefaultDragHandles: false,
          itemCount: run.stops.length,
          // `onReorderItem` already reports the destination index with the
          // dragged row removed, so no off-by-one correction is applied here.
          onReorderItem: app.moveStop,
          proxyDecorator: (child, index, animation) => Material(
            color: context.c.card,
            elevation: 6,
            shadowColor: const Color(0x33101C33),
            borderRadius: BorderRadius.circular(Sizes.innerRadius),
            child: child,
          ),
          itemBuilder: (context, i) => Column(
            key: ValueKey(run.stops[i].id),
            children: [
              StopRow(
                index: i + 1,
                stop: run.stops[i],
                trailing: ReorderableDragStartListener(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Icon(
                      LucideIcons.menu,
                      size: 22,
                      color: context.c.textSecondary,
                    ),
                  ),
                ),
              ),
              if (i < run.stops.length - 1)
                Divider(height: 1, color: context.c.border),
            ],
          ),
        );

  Widget _mapView(BuildContext context, DriverRun run) => Column(
    children: [
      Expanded(
        child: Stack(
          children: [
            // Real map, the prototype included (demo stops carry real
            // Setapak coordinates).
            Positioned.fill(child: RunMap(stops: run.stops)),
          ],
        ),
      ),
    ],
  );
}

/// One row in the Stop List (D21, D21.1).
class StopRow extends StatelessWidget {
  const StopRow({
    super.key,
    required this.index,
    required this.stop,
    this.onTap,
    this.trailing,
  });

  final int index;
  final DriverStop stop;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (label, tone) = switch (stop.status) {
      StopStatus.delivered => (L.delivered, ChipTone.success),
      StopStatus.issue => (L.issue, ChipTone.attention),
      StopStatus.pending => (L.pending2, ChipTone.warning),
    };
    final address = [
      stop.addressLine1,
      if (stop.addressLine2 != null) stop.addressLine2!,
    ].join(' ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: CeffloIndexBadge(index, tone: ChipTone.info, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stop.reference, style: context.t.labelSmall),
                              const SizedBox(height: 1),
                              Text(
                                stop.customerName,
                                style: context.t.titleSmall?.copyWith(
                                  fontSize: 15.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CeffloStatusChip(label, tone: tone),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: c.info,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(address, style: context.t.bodySmall),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              trailing ??
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: c.textSecondary,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D22 — Navigation to Stop
// ---------------------------------------------------------------------------

class NavigationToStopScreen extends StatelessWidget {
  const NavigationToStopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final stop = app.activeStop;
    final c = context.c;
    return CefBottomSurface(
      color: context.c.card,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: c.card,
          body: Column(
            children: [
              // Turn instruction card, sitting on the device status bar.
              Container(
                color: CefColors.navy,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.lg,
                      Gap.md,
                      Gap.lg,
                      Gap.lg,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.cornerUpRight,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(width: Gap.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.distanceMetres == null
                                    ? '—'
                                    : '${stop.distanceMetres} m',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              Text(
                                stop.addressLine1.replaceAll(',', ''),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: CefColors.onNavyMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Real map focused on the active stop, the prototype
                    // included (demo stops carry real coordinates).
                    Positioned.fill(
                      child: RunMap(
                        stops: app.currentRun.stops,
                        focus: stop,
                        showControls: false,
                      ),
                    ),
                    Positioned(
                      left: Gap.md,
                      top: Gap.md,
                      child: Column(
                        children: [
                          MapControlButton(
                            icon: LucideIcons.chevronLeft,
                            onTap: app.back,
                          ),
                        ],
                      ),
                    ),
                    if (app.repo.isDemo)
                      const Positioned(
                        right: Gap.md,
                        bottom: Gap.md,
                        child: MapRecenterPill(),
                      ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Sizes.sheetRadius),
                  ),
                  boxShadow: cefSheetShadow(),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.gutter,
                      0,
                      Gap.gutter,
                      Gap.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SheetGrabber(),
                        const SizedBox(height: 4),
                        Text(stop.reference, style: context.t.labelSmall),
                        const SizedBox(height: 1),
                        Text(
                          stop.customerName,
                          style: context.t.displaySmall?.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        MetaRow(
                          icon: LucideIcons.mapPin,
                          text: [
                            stop.addressLine1,
                            if (stop.addressLine2 != null) stop.addressLine2!,
                          ].join(' '),
                          dense: true,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: MetaRow(
                                icon: LucideIcons.clock,
                                text: stop.etaMinutes == null
                                    ? '—'
                                    : L.min(stop.etaMinutes!),
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: MetaRow(
                                icon: LucideIcons.route,
                                text: stop.distanceMetres == null
                                    ? '—'
                                    : '${stop.distanceMetres} m',
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Gap.md),
                        CeffloSlideAction(
                          label: L.slideArrive,
                          onConfirmed: () async {
                            // Real build: rider_transition -> arrived.
                            try {
                              await app.arriveAt(stop.id);
                              app.go(DRoute.confirmDelivery, entityId: stop.id);
                            } catch (e) {
                              if (context.mounted) {
                                showCefToast(context, '$e', error: true);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D23 — Confirm Delivery (+ Proof of Delivery)
// ---------------------------------------------------------------------------

class ConfirmDeliveryScreen extends StatefulWidget {
  const ConfirmDeliveryScreen({super.key});

  @override
  State<ConfirmDeliveryScreen> createState() => _ConfirmDeliveryScreenState();
}

class _ConfirmDeliveryScreenState extends State<ConfirmDeliveryScreen> {
  String? _proof;
  OverlayEntry? _notice;

  /// Real proof-of-delivery photo (real build). complete_delivery requires
  /// a stored POD object, so nothing completes without one.
  XFile? _photo;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (photo != null && mounted) {
      setState(() {
        _photo = photo;
        _proof = 'camera';
      });
    }
  }

  @override
  void dispose() {
    _notice?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final stop = app.activeStop;
    final c = context.c;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.confirmDelivery,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Only what the Driver needs at the door (Founder 2026-10-13):
          // customer, address (with house number), note, a short item line;
          // Call and Chat beside the name. No map, no pin line.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.customerName,
                      style: context.t.titleMedium?.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: Gap.sm),
                    _iconLine(
                      context,
                      LucideIcons.mapPin,
                      [
                        stop.addressLine1.trim().replaceFirst(
                          RegExp(r',$'),
                          '',
                        ),
                        ?stop.addressLine2,
                      ].join(', '),
                    ),
                    if (stop.note != null) ...[
                      const SizedBox(height: Gap.xs),
                      _iconLine(context, LucideIcons.stickyNote, stop.note!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Gap.sm),
              _RoundAction(
                light: true,
                icon: LucideIcons.phone,
                onTap: AppScope.read(context).repo.isDemo
                    ? () => _showTopNotice(
                        context,
                        L.calling(stop.customerName),
                        LucideIcons.phone,
                      )
                    : () async {
                        if (!await dialPhone(stop.phone) && context.mounted) {
                          showCefToast(context, L.phoneNotAvailable);
                        }
                      },
              ),
              const SizedBox(width: Gap.sm),
              // Chat: WhatsApp with the customer's number.
              _RoundAction(
                light: true,
                icon: LucideIcons.messageCircle,
                onTap: AppScope.read(context).repo.isDemo
                    ? () => _showTopNotice(
                        context,
                        L.openingChat,
                        LucideIcons.messageCircle,
                      )
                    : () async {
                        if (!await openWhatsApp(stop.phone) &&
                            context.mounted) {
                          showCefToast(context, L.phoneNotAvailable);
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          // Order details, short: one line.
          Text(L.orderDetails, style: context.t.titleSmall),
          const SizedBox(height: Gap.xs),
          Text(
            stop.items.isEmpty
                ? L.noItemisedOrderLinesStop
                : stop.items.map((i) => '${i.quantity}× ${i.name}').join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.t.bodyMedium,
          ),
          const SizedBox(height: Gap.lg),
          Text(L.proofDelivery, style: context.t.titleMedium),
          const SizedBox(height: Gap.md),
          _ProofTile(
            icon: LucideIcons.camera,
            label: _photo == null ? L.takePhoto : L.photoAdded,
            selected: _proof == 'camera',
            onTap: AppScope.read(context).repo.isDemo
                ? () => setState(() => _proof = 'camera')
                : _takePhoto,
          ),
          const SizedBox(height: Gap.lg),
          // Not a screen of its own in the reference set, but D28 has to be
          // reachable from somewhere: the reference numbers it as a child of
          // D23, so this is the link into it. Deliberately quiet — it is the
          // exception path, not a peer of "Slide to Complete".
          Center(
            child: CeffloTextLink(
              L.unableDeliverReportIssue,
              fontSize: 13.5,
              weight: FontWeight.w600,
              color: c.textSecondary,
              onTap: () => app.go(DRoute.deliveryIssue, entityId: stop.id),
            ),
          ),
        ],
      ),
      footer: CeffloSlideAction(
        label: L.slideComplete,
        onConfirmed: () async {
          final real = !app.repo.isDemo;
          final photo = _photo;
          if (real && photo == null) {
            showCefToast(context, L.takeProofDeliveryPhotoFirst, error: false);
            return;
          }
          if (!real) app.markStopDelivered(stop.id);
          await showCeffloSubmitFlow(
            context,
            submittingTitle: L.confirmingDelivery,
            submittingBody: L.pleaseWaitMoment,
            successTitle: L.deliveryConfirmed,
            successBody: L.hasBeenMarkedDelivered(stop.reference),
            // Real build: POD upload + complete_delivery before success.
            action: real
                ? () async {
                    final bytes = await photo!.readAsBytes();
                    final name = photo.name.toLowerCase();
                    final ext = name.endsWith('.png') ? 'png' : 'jpg';
                    await app.completeStop(stop.id, bytes, ext);
                  }
                : null,
            onDone: () {
              if (app.currentRun.pendingCount == 0) {
                app.resetTo(DRoute.runCompleted, entityId: app.currentRun.id);
              } else {
                app.back();
                app.back();
              }
            },
          );
        },
      ),
    );
  }

  Widget _iconLine(BuildContext context, IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(
      children: [
        Icon(icon, size: 14, color: context.c.info),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.t.bodySmall,
          ),
        ),
      ],
    ),
  );

  void _showTopNotice(BuildContext context, String message, IconData icon) {
    _notice?.remove();
    final overlay = Overlay.of(context);
    final c = context.c;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.paddingOf(context).top + Gap.md,
        left: Gap.gutter,
        right: Gap.gutter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.lg,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: CefColors.tintNeutral,
              borderRadius: BorderRadius.circular(Sizes.actionRadius),
              border: Border.all(color: c.border),
              boxShadow: cefCardShadow(),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: c.info),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Text(
                    message,
                    style: context.t.bodyMedium?.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _notice = entry;
    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (_notice == entry) {
        entry.remove();
        _notice = null;
      }
    });
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.light = false,
  });
  final IconData icon;
  final VoidCallback onTap;

  /// Light grey with a navy icon (Home's job cards); navy otherwise.
  final bool light;

  @override
  Widget build(BuildContext context) => Material(
    color: light ? CefColors.tintNeutral : CefColors.navy,
    shape: CircleBorder(
      side: light
          ? const BorderSide(color: Color(0xFFE1E6EE))
          : BorderSide.none,
    ),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: 21,
          color: light ? CefColors.navy : Colors.white,
        ),
      ),
    ),
  );
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: selected ? CefColors.tintInfo : CefColors.tintNeutral,
      borderRadius: BorderRadius.circular(Sizes.innerRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Sizes.innerRadius),
        onTap: onTap,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Sizes.innerRadius),
            border: Border.all(color: selected ? c.info : c.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: selected ? c.info : c.textLabel),
              const SizedBox(height: Gap.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: context.t.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D28 — Delivery Issue
// ---------------------------------------------------------------------------

class DeliveryIssueScreen extends StatefulWidget {
  const DeliveryIssueScreen({super.key});

  @override
  State<DeliveryIssueScreen> createState() => _DeliveryIssueScreenState();
}

class _DeliveryIssueScreenState extends State<DeliveryIssueScreen> {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloNavySheetScaffold(
      header: Column(
        children: [
          CeffloScreenHeader(
            title: L.deliveryIssue,
            onBack: app.back,
            onBell: () => app.go(DRoute.notifications),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.gutter,
              0,
              Gap.gutter,
              Gap.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L.unableCompleteDelivery,
                  style: context.t.displayMedium?.copyWith(fontSize: 21),
                ),
                const SizedBox(height: 3),
                Text(
                  L.letUsKnowWhatHappened,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: CefColors.onNavyMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.sm,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final reason in IssueReason.values) ...[
            _ReasonRow(
              reason: reason,
              selected: app.issueReason == reason,
              onTap: () => app.setIssueReason(reason),
            ),
            if (reason != IssueReason.values.last)
              Divider(height: 1, color: context.c.border),
          ],
        ],
      ),
      footer: CeffloPrimaryButton(
        L.next,
        pill: false,
        onTap: () => app.go(
          DRoute.reportIssue,
          entityId: app.activeStopId ?? app.currentRun.stops.first.id,
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final IssueReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? CefColors.tintInfo : Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFF1668E3) : context.c.border,
                  width: selected ? 6 : 1.8,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reason.title, style: context.t.titleSmall),
                  const SizedBox(height: 2),
                  Text(reason.body, style: context.t.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// D29 — Report Issue
// ---------------------------------------------------------------------------

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _notes = TextEditingController();
  bool _photoAdded = false;

  @override
  void initState() {
    super.initState();
    _notes.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final reason = app.issueReason;
    final c = context.c;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.reportIssue,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CefColors.tintNeutral,
              borderRadius: BorderRadius.circular(Sizes.cardRadius),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.package, size: 26, color: c.textLabel),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L.selectedIssue, style: context.t.labelSmall),
                      const SizedBox(height: 1),
                      Text(
                        reason.title,
                        style: context.t.titleSmall?.copyWith(fontSize: 15.5),
                      ),
                      const SizedBox(height: 2),
                      Text(reason.body, style: context.t.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          CeffloTextField(
            label: L.notesRequired,
            controller: _notes,
            hint: L.addMoreDetailsAboutWhatHappened,
            maxLines: 4,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_notes.text.length}/500',
              style: context.t.labelSmall,
            ),
          ),
          const SizedBox(height: Gap.md),
          CeffloFieldLabel(L.addPhotosOptional),
          const SizedBox(height: 6),
          _PhotoDropTile(
            title: _photoAdded ? L.photoAdded : L.addPhoto,
            subtitle: _photoAdded
                ? L.tapReplaceAttachedPhoto
                : L.takePhotoChooseFromGallery,
            icon: _photoAdded ? LucideIcons.imageUp : LucideIcons.camera,
            onTap: () => setState(() => _photoAdded = !_photoAdded),
          ),
          const SizedBox(height: Gap.md),
          CeffloNote(
            icon: LucideIcons.info,
            body: L.reportWillSentBusinessTeamReview,
          ),
        ],
      ),
      footer: CeffloPrimaryButton(
        L.submit,
        pill: false,
        onTap: _notes.text.trim().isEmpty
            ? null
            : () async {
                final stopId =
                    app.activeStopId ?? app.currentRun.stops.first.id;
                if (app.repo.isDemo) app.markStopIssue(stopId);
                await showCeffloSubmitFlow(
                  context,
                  submittingTitle: L.submitting,
                  submittingBody: L.pleaseWaitMoment,
                  successTitle: L.reportSubmitted,
                  successBody: L.businessTeamWillReviewReport,
                  // Real build: rider_report_delivery_issue, recorded before
                  // any success is shown.
                  action: app.repo.isDemo
                      ? null
                      : () => app.reportIssue(
                          stopId,
                          app.issueReason,
                          _notes.text.trim(),
                        ),
                  onDone: () =>
                      app.resetTo(DRoute.stopList, entityId: app.currentRun.id),
                );
              },
      ),
    );
  }
}

class _PhotoDropTile extends StatelessWidget {
  const _PhotoDropTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: CefColors.tintNeutral,
    borderRadius: BorderRadius.circular(Sizes.cardRadius),
    child: InkWell(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: Gap.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
          border: Border.all(color: context.c.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: context.c.textLabel),
            const SizedBox(height: Gap.sm),
            Text(title, style: context.t.titleSmall),
            const SizedBox(height: 2),
            Text(subtitle, style: context.t.bodySmall),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// D30 — Run Completed
// ---------------------------------------------------------------------------

class RunCompletedScreen extends StatelessWidget {
  const RunCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final run = app.repo.isDemo ? DemoData.completedRun : app.currentRun;
    return CeffloNavySheetScaffold(
      header: Column(
        children: [
          CeffloScreenHeader(
            title: L.runCompleted,
            onBack: app.back,
            onBell: () => app.go(DRoute.notifications),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.gutter,
              Gap.sm,
              Gap.gutter,
              Gap.xl,
            ),
            child: Column(
              children: [
                const CeffloSuccessTick(size: 84, glow: true),
                const SizedBox(height: Gap.lg),
                Text(
                  L.runCompleted2,
                  style: context.t.displayMedium?.copyWith(fontSize: 25),
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  L.greatJobYouveCompletedAllStops,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: CefColors.onNavyMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  run.reference,
                  style: context.t.displaySmall?.copyWith(fontSize: 20),
                ),
              ),
              Text(run.dateLabel, style: context.t.bodySmall),
            ],
          ),
          const SizedBox(height: Gap.sm),
          KeyValueRow(
            icon: LucideIcons.package,
            label: L.stops2(run.orderCount),
            value: L.completed2(run.deliveredCount, run.orderCount),
            divider: true,
          ),
          KeyValueRow(
            icon: LucideIcons.mapPin,
            label: L.distance,
            value: run.distanceText,
            divider: true,
          ),
          KeyValueRow(
            icon: LucideIcons.clock,
            label: L.time,
            value: run.durationLabel ?? '',
          ),
          const SizedBox(height: Gap.md),
          CeffloNote(
            icon: LucideIcons.info,
            body: L.allDeliveryDetailsHaveBeenUpdated,
          ),
        ],
      ),
      footer: CeffloPrimaryButton(
        L.done,
        pill: false,
        onTap: () => app.switchTab(NavTab.home),
      ),
    );
  }
}
