import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../../data/driver_models.dart';
import '../map_canvas.dart';
import '../widgets.dart';

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
    final run = app.currentRun;
    final c = context.c;
    return CeffloNavySheetScaffold(
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
              const Text(
                'Good morning,',
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
              const Text(
                'Let’s get to it today.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
              const SizedBox(height: Gap.lg),
              NavyBusinessRow(
                business: app.business ?? DemoData.business,
                onTap: () => app.go(DRoute.profile),
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
                child: Text('Today’s Overview', style: context.t.titleMedium),
              ),
              Text(DemoData.todayDateLabel, style: context.t.bodySmall),
            ],
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              OverviewTile(
                value: DemoData.todayAssigned,
                label: 'Assigned',
                labelColor: c.success,
              ),
              const SizedBox(width: Gap.sm),
              OverviewTile(
                value: DemoData.todayOngoing,
                label: 'Ongoing',
                labelColor: const Color(0xFFE08A00),
              ),
              const SizedBox(width: Gap.sm),
              OverviewTile(
                value: DemoData.todayIssues,
                label: 'Issues',
                labelColor: c.textSecondary,
              ),
              const SizedBox(width: Gap.sm),
              OverviewTile(
                value: DemoData.todayCompleted,
                label: 'Completed',
                labelColor: c.info,
              ),
            ],
          ),
          const SizedBox(height: Gap.section),
          CeffloCard(
            padding: const EdgeInsets.all(Gap.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Current Run', style: context.t.titleMedium),
                const SizedBox(height: Gap.md),
                InkWell(
                  borderRadius: BorderRadius.circular(Sizes.innerRadius),
                  onTap: () => app.go(DRoute.runDetails, entityId: run.id),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  run.reference,
                                  style: context.t.displaySmall?.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(width: Gap.sm),
                                CeffloStatusChip(
                                  run.statusLabel,
                                  tone: ChipTone.info,
                                ),
                              ],
                            ),
                            const SizedBox(height: Gap.sm),
                            MetaRow(
                              icon: LucideIcons.mapPin,
                              text: run.zone,
                              dense: true,
                            ),
                            MetaRow(
                              icon: LucideIcons.package,
                              text:
                                  '${run.orderCount} orders  •  ${run.distanceKm} km',
                              dense: true,
                            ),
                            MetaRow(
                              icon: LucideIcons.clock,
                              text: 'Started ${run.startedAtLabel}',
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 22,
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.lg),
                CeffloPrimaryButton(
                  'View Run Details',
                  trailingArrow: true,
                  height: 52,
                  onTap: () => app.go(DRoute.runDetails, entityId: run.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D20 — Run Details
// ---------------------------------------------------------------------------

class RunDetailsScreen extends StatelessWidget {
  const RunDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final run = app.currentRun;
    return CeffloNavySheetScaffold(
      header: Column(
        children: [
          CeffloScreenHeader(
            title: 'Run Details',
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
                Row(
                  children: [
                    Text(
                      run.reference,
                      style: context.t.displayLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(width: Gap.md),
                    CeffloStatusChip(run.statusLabel, tone: ChipTone.success),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  run.dateLabel,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
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
        Gap.section,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: CefColors.tintNeutral,
              borderRadius: BorderRadius.circular(Sizes.cardRadius),
            ),
            child: Column(
              children: [
                MetaRow(icon: LucideIcons.mapPin, text: run.zone),
                MetaRow(
                  icon: LucideIcons.package,
                  text: '${run.orderCount} orders',
                ),
                MetaRow(
                  icon: LucideIcons.arrowRight,
                  text: '${run.distanceKm} km',
                ),
                MetaRow(
                  icon: LucideIcons.clock,
                  text: 'Started ${run.startedAtLabel}',
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          CeffloCard(
            padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
            child: Column(
              children: [
                _RunStep(
                  index: 1,
                  title: 'Pick up from store',
                  value: run.pickupBusinessName,
                  meta: run.pickupAddress,
                  metaIcon: LucideIcons.mapPin,
                  onTap: () => app.go(DRoute.stopList, entityId: run.id),
                  connector: true,
                ),
                _RunStep(
                  index: 2,
                  title: 'Deliver ${run.orderCount} orders',
                  meta: 'Multiple locations',
                  metaIcon: LucideIcons.mapPin,
                  onTap: () => app.go(DRoute.stopList, entityId: run.id),
                  connector: true,
                ),
                _RunStep(
                  index: 3,
                  title: 'Complete run',
                  meta: 'Mark all orders as delivered',
                  onTap: () => app.go(DRoute.runCompleted, entityId: run.id),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            'View Orders',
            trailingArrow: true,
            onTap: () => app.go(DRoute.stopList, entityId: run.id),
          ),
        ],
      ),
    );
  }
}

class _RunStep extends StatelessWidget {
  const _RunStep({
    required this.index,
    required this.title,
    this.value,
    required this.meta,
    this.metaIcon,
    required this.onTap,
    this.connector = false,
  });

  final int index;
  final String title;
  final String? value;
  final String meta;
  final IconData? metaIcon;
  final VoidCallback onTap;
  final bool connector;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 14),
              CeffloIndexBadge(index, tone: ChipTone.warning, size: 28),
              if (connector)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: c.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(Sizes.innerRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.t.titleSmall),
                          if (value != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              value!,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (metaIcon != null) ...[
                                Icon(metaIcon, size: 14, color: c.info),
                                const SizedBox(width: 5),
                              ],
                              Expanded(
                                child: Text(meta, style: context.t.bodySmall),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  /// Unit-space stop positions for the painted map in D21.2. They trace the
  /// same serpentine the reference draws through Setapak.
  static const _mapPoints = <Offset>[
    Offset(0.30, 0.86),
    Offset(0.32, 0.76),
    Offset(0.34, 0.68),
    Offset(0.41, 0.64),
    Offset(0.36, 0.56),
    Offset(0.46, 0.56),
    Offset(0.55, 0.50),
    Offset(0.52, 0.44),
    Offset(0.62, 0.42),
    Offset(0.45, 0.35),
    Offset(0.49, 0.20),
    Offset(0.52, 0.30),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final run = app.currentRun;
    final header = CeffloScreenHeader(
      title: 'Stop List',
      onBack: app.back,
      onBell: () => app.go(DRoute.notifications),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              '${run.reference}  •  ${run.orderCount} orders',
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
            '${run.distanceKm} km',
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
              'All (${all.length})',
              'Pending (${pending.length})',
              'Delivered (${delivered.length})',
            ],
            index: _filter,
            onChanged: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 6),
          if (shown.isEmpty)
            StateBlock.empty('No stops in this view.')
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
                  labels: const ['List', 'Map'],
                  index: _planTab,
                  onChanged: (i) => setState(() => _planTab = i),
                ),
                const SizedBox(height: Gap.md),
                CeffloNote(
                  icon: LucideIcons.info,
                  title: isMap
                      ? 'This map shows your current stop order.'
                      : 'Drag and drop to reorder your stops.',
                  body: isMap ? 'Switch to List view to drag and reorder.' : 'This will update your route. Available before you start.',
                ),
                const SizedBox(height: Gap.md),
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
      footer: CeffloSlideAction(
        label: 'Slide to Confirm Route',
        onConfirmed: () async {
          app.confirmRoute();
          setState(() => _filter = 0);
        },
      ),
    );
  }

  Widget _reorderList(BuildContext context, AppState app, DriverRun run) =>
      ReorderableListView.builder(
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
            Positioned.fill(
              child: MapCanvas(
                route: _mapPoints,
                // Offset from stop 1 so the driver puck and the first stop
                // pin do not sit on top of each other.
                heading: const Offset(0.23, 0.92),
                labels: const [
                  MapLabel('Setapak', Offset(0.70, 0.52), big: true),
                  MapLabel('Taman\nSetapak', Offset(0.56, 0.14)),
                  MapLabel('Danau Kota', Offset(0.16, 0.90)),
                ],
                markers: [
                  for (var i = 0; i < _mapPoints.length; i++)
                    MapMarker(position: _mapPoints[i], index: i + 1),
                ],
              ),
            ),
            Positioned(
              left: Gap.md,
              top: Gap.md,
              child: Column(
                children: const [
                  MapControlButton(icon: LucideIcons.locateFixed),
                  SizedBox(height: Gap.sm),
                  MapControlButton(icon: LucideIcons.layers),
                  SizedBox(height: Gap.sm),
                  MapControlButton(icon: LucideIcons.navigation),
                ],
              ),
            ),
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
        padding: const EdgeInsets.fromLTRB(Gap.gutter, 4, Gap.gutter, Gap.md),
        color: context.c.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetGrabber(),
            Text(
              run.reference,
              style: context.t.displaySmall?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: Gap.sm),
            Row(
              children: [
                Expanded(
                  child: MetaRow(
                    icon: LucideIcons.package,
                    text: '${run.orderCount} orders',
                    dense: true,
                  ),
                ),
                Expanded(
                  child: MetaRow(
                    icon: LucideIcons.navigation,
                    text: '${run.distanceKm} km',
                    dense: true,
                  ),
                ),
                Expanded(
                  child: MetaRow(
                    icon: LucideIcons.mapPin,
                    text: run.zone,
                    dense: true,
                  ),
                ),
              ],
            ),
            MetaRow(
              icon: LucideIcons.clock,
              text: run.estimateLabel ?? '',
              dense: true,
            ),
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
      StopStatus.delivered => ('Delivered', ChipTone.success),
      StopStatus.issue => ('Issue', ChipTone.attention),
      StopStatus.pending => ('Pending', ChipTone.warning),
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

  static const _route = <Offset>[
    Offset(0.36, 0.78),
    Offset(0.36, 0.56),
    Offset(0.47, 0.54),
    Offset(0.48, 0.34),
    Offset(0.56, 0.32),
    Offset(0.57, 0.18),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final stop = app.activeStop;
    final c = context.c;
    return Scaffold(
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
                            '${stop.distanceMetres ?? 350} m',
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
                Positioned.fill(
                  child: MapCanvas(
                    route: _route,
                    labels: const [
                      MapLabel('Setapak', Offset(0.66, 0.60), big: true),
                    ],
                    markers: const [
                      MapMarker(position: Offset(0.57, 0.18), pin: true),
                    ],
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
                      const SizedBox(height: Gap.sm),
                      const MapControlButton(icon: LucideIcons.volume2),
                      const SizedBox(height: Gap.sm),
                      const MapControlButton(icon: LucideIcons.layers),
                      const SizedBox(height: Gap.sm),
                      const MapControlButton(icon: LucideIcons.navigation),
                    ],
                  ),
                ),
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
                            text: '${stop.etaMinutes ?? 2} min',
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: MetaRow(
                            icon: LucideIcons.route,
                            text: '${stop.distanceMetres ?? 650} m',
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.md),
                    CeffloSlideAction(
                      label: 'Slide to Arrive',
                      onConfirmed: () async =>
                          app.go(DRoute.confirmDelivery, entityId: stop.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
  bool _expanded = true;
  bool _received = true;
  String? _proof;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final stop = app.activeStop;
    final c = context.c;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: 'Confirm Delivery',
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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CefColors.tintNeutral,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.user, size: 22, color: c.textLabel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.customerName,
                      style: context.t.titleMedium?.copyWith(fontSize: 16.5),
                    ),
                    const SizedBox(height: 2),
                    _iconLine(context, LucideIcons.mapPin, stop.addressLine1),
                    if (stop.addressLine2 != null)
                      _iconLine(
                        context,
                        LucideIcons.milestone,
                        stop.addressLine2!,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RoundAction(
                icon: LucideIcons.phone,
                onTap: () => _toast(context, 'Calling ${stop.customerName}…'),
              ),
              const SizedBox(width: 8),
              _RoundAction(
                icon: LucideIcons.messageCircle,
                onTap: () => _toast(context, 'Opening chat…'),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          Divider(height: 1, color: c.border),
          const SizedBox(height: Gap.md),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Order Details', style: context.t.titleMedium),
                  ),
                  Text(
                    '${stop.items.length} items',
                    style: context.t.bodyMedium,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 20,
                    color: c.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: Gap.sm),
            for (final item in stop.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${item.quantity}  ×',
                        style: context.t.bodyMedium?.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (stop.items.isEmpty)
              Text(
                'No itemised order lines for this stop.',
                style: context.t.bodySmall,
              ),
          ],
          const SizedBox(height: Gap.lg),
          Text('Proof of Delivery', style: context.t.titleMedium),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: _ProofTile(
                  icon: LucideIcons.camera,
                  label: 'Take Photo',
                  selected: _proof == 'camera',
                  onTap: () => setState(() => _proof = 'camera'),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: _ProofTile(
                  icon: LucideIcons.image,
                  label: 'Choose from Gallery',
                  selected: _proof == 'gallery',
                  onTap: () => setState(() => _proof = 'gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          InkWell(
            onTap: () => setState(() => _received = !_received),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _CheckBox(value: _received),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Customer received the order',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          // Not a screen of its own in the reference set, but D28 has to be
          // reachable from somewhere: the reference numbers it as a child of
          // D23, so this is the link into it. Deliberately quiet — it is the
          // exception path, not a peer of "Slide to Complete".
          Center(
            child: CeffloTextLink(
              'Unable to deliver? Report an issue',
              fontSize: 13.5,
              weight: FontWeight.w600,
              color: c.textSecondary,
              onTap: () => app.go(DRoute.deliveryIssue, entityId: stop.id),
            ),
          ),
        ],
      ),
      footer: CeffloSlideAction(
        label: 'Slide to Complete',
        enabled: _received,
        errorText: _received
            ? null
            : 'Confirm the customer received the order first.',
        onConfirmed: () async {
          app.markStopDelivered(stop.id);
          await showCeffloSubmitFlow(
            context,
            submittingTitle: 'Confirming delivery…',
            submittingBody: 'Please wait a moment.',
            successTitle: 'Delivery confirmed',
            successBody: '${stop.reference} has been marked as delivered.',
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
        Expanded(child: Text(text, style: context.t.bodySmall)),
      ],
    ),
  );

  void _toast(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: CefColors.navy,
        ),
      );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: CefColors.navy,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 21, color: Colors.white),
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

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: value ? const Color(0xFF1668E3) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: value ? const Color(0xFF1668E3) : context.c.border,
        width: 1.6,
      ),
    ),
    child: value
        ? const Icon(LucideIcons.check, size: 15, color: Colors.white)
        : null,
  );
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
            title: 'Delivery Issue',
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
                  'Unable to complete delivery?',
                  style: context.t.displayMedium?.copyWith(fontSize: 21),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Let us know what happened.',
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
        'Next',
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
        title: 'Report Issue',
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
                      Text('Selected Issue', style: context.t.labelSmall),
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
            label: 'Notes (Required)',
            controller: _notes,
            hint: 'Add more details about what happened…',
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
          const CeffloFieldLabel('Add Photos (Optional)'),
          const SizedBox(height: 6),
          _PhotoDropTile(
            title: _photoAdded ? 'Photo added' : 'Add Photo',
            subtitle: _photoAdded
                ? 'Tap to replace the attached photo.'
                : 'Take a photo or choose from gallery',
            icon: _photoAdded ? LucideIcons.imageUp : LucideIcons.camera,
            onTap: () => setState(() => _photoAdded = !_photoAdded),
          ),
          const SizedBox(height: Gap.md),
          const CeffloNote(
            icon: LucideIcons.info,
            body: 'Your report will be sent to the business team for review. We’ll keep you updated.',
          ),
        ],
      ),
      footer: CeffloPrimaryButton(
        'Submit',
        pill: false,
        onTap: _notes.text.trim().isEmpty
            ? null
            : () async {
                final stopId =
                    app.activeStopId ?? app.currentRun.stops.first.id;
                app.markStopIssue(stopId);
                await showCeffloSubmitFlow(
                  context,
                  submittingTitle: 'Submitting…',
                  submittingBody: 'Please wait a moment.',
                  successTitle: 'Report submitted',
                  successBody: 'The business team will review your report.',
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
    final run = DemoData.completedRun;
    return CeffloNavySheetScaffold(
      header: Column(
        children: [
          CeffloScreenHeader(
            title: 'Run Completed',
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
                  'Run Completed!',
                  style: context.t.displayMedium?.copyWith(fontSize: 25),
                ),
                const SizedBox(height: Gap.sm),
                const Text(
                  'Great job! You’ve completed\nall stops in this run.',
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
            label: '${run.orderCount} stops',
            value: '${run.deliveredCount} / ${run.orderCount} completed',
            divider: true,
          ),
          KeyValueRow(
            icon: LucideIcons.mapPin,
            label: 'Distance',
            value: '${run.distanceKm} km',
            divider: true,
          ),
          KeyValueRow(
            icon: LucideIcons.clock,
            label: 'Time',
            value: run.durationLabel ?? '',
          ),
          const SizedBox(height: Gap.md),
          const CeffloNote(
            icon: LucideIcons.info,
            body: 'All delivery details have been updated. You can view the run in your history.',
          ),
        ],
      ),
      footer: CeffloPrimaryButton(
        'Done',
        pill: false,
        onTap: () => app.switchTab(NavTab.home),
      ),
    );
  }
}
