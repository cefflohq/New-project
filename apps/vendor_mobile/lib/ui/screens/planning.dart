import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/vendor_repository.dart';
import '../async_view.dart';
import '../shell.dart';
import '../widgets.dart';

/// V-18 — Review & dispatch.
///
/// Everything shown here is the server's decision: `list_plannable_orders`
/// defines what is plannable, `propose_delivery_plan` decides grouping, the
/// candidate rider and the stop sequence, `check_run_vehicle_capacity`
/// validates the run and `build_rider_run` commits it. No grouping,
/// sequencing, coverage or capacity logic is reproduced in Dart. Distance is
/// the server's own `total_distance_km` per group, summed client-side for
/// the header tile -- never estimated. There is no server-provided
/// completion-time field, so (unlike the reference board) this does not
/// show one rather than invent an ETA.
class ReviewDispatchScreen extends StatefulWidget {
  const ReviewDispatchScreen({super.key, this.zoneId});
  final String? zoneId;
  @override
  State<ReviewDispatchScreen> createState() => _ReviewDispatchScreenState();
}

class _ReviewDispatchScreenState extends State<ReviewDispatchScreen> {
  final _viewKey =
      GlobalKey<AsyncViewState<(PlanProposal, Zone?, List<RiderRow>)>>();
  bool _dispatchingAll = false;
  String? _error;
  String? _result;
  String? _dispatchedRunId;

  Future<void> _dispatchOne(PlanGroup group) async {
    final app = AppScope.read(context);
    final business = app.business!;
    final check = await app.repo.checkRunCapacity(
      riderId: group.candidateRiderId!,
      orderIds: group.orderIds,
    );
    if (!check.compatible) {
      throw RepositoryError(check.violations.join('\n'));
    }
    final session = await app.repo.createDeliverySession(
      businessId: business.id,
    );
    final run = await app.repo.buildRiderRun(
      sessionId: session['id'] as String,
      riderId: group.candidateRiderId!,
      orderIds: group.orderIds,
      // Stable for this proposal + group, so a retry is idempotent.
      idempotencyKey: _idempotencyKey(session['id'] as String, group),
    );
    _dispatchedRunId = run['id'] as String?;
  }

  Future<void> _dispatchAll(List<PlanGroup> dispatchable) async {
    setState(() {
      _dispatchingAll = true;
      _error = null;
      _result = null;
    });
    var dispatchedOrders = 0;
    try {
      for (final group in dispatchable) {
        await _dispatchOne(group);
        dispatchedOrders += group.orderIds.length;
      }
      if (!mounted) return;
      setState(
        () => _result =
            'Dispatched $dispatchedOrders order(s) across '
            '${dispatchable.length} run${dispatchable.length == 1 ? '' : 's'}.',
      );
      await _viewKey.currentState?.reload();
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _dispatchingAll = false);
    }
  }

  String _idempotencyKey(String sessionId, PlanGroup group) {
    // Deterministic UUID-shaped key from the session and the group's orders.
    final seed = '$sessionId|${group.orderIds.join(',')}'.hashCode
        .abs()
        .toString();
    final hex = seed.padLeft(12, '0').substring(0, 12);
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4000-8000-${hex.padRight(12, '0').substring(0, 12)}';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return const PageBody(
        children: [StateBlock.empty('No business linked.')],
      );
    }
    return AsyncView<(PlanProposal, Zone?, List<RiderRow>)>(
      key: _viewKey,
      load: () async {
        final plan = await app.repo.proposePlan(business.id);
        final riders = await app.repo.riders(business.id);
        Zone? zone;
        if (widget.zoneId != null) {
          for (final z in await app.repo.zones(business.id)) {
            if (z.id == widget.zoneId) {
              zone = z;
              break;
            }
          }
        }
        return (plan, zone, riders);
      },
      builder: (context, data, reload) {
        final (fullPlan, zone, riders) = data;
        // Display-only filter to the zone the vendor drilled in from --
        // grouping/eligibility itself is still entirely the server's.
        final groups = widget.zoneId == null
            ? fullPlan.groups
            : fullPlan.groups.where((g) => g.zoneId == widget.zoneId).toList();
        // UnplannableEntry carries no zone reference, so a zone drill-down
        // cannot attribute these to it without guessing -- only show them
        // on the all-zones view.
        final unplannable = widget.zoneId == null
            ? fullPlan.unplannable
            : const <UnplannableEntry>[];
        final totalOrders = groups.fold<int>(
          0,
          (n, g) => n + g.orderIds.length,
        );
        final totalStops = groups.fold<int>(0, (n, g) => n + g.stops.length);
        final totalDistance = groups.fold<num>(
          0,
          (n, g) => n + (g.totalDistanceKm ?? 0),
        );
        final dispatchable = groups
            .where((g) => g.candidateRiderId != null)
            .toList();
        final today = DateTime.now();
        final text = Theme.of(context).textTheme;

        return PageBody(
          onRefresh: reload,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: Sizes.icon,
                  color: context.c.info,
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone?.name ?? 'All zones',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Today, ${_formatDate(today)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (groups.isNotEmpty)
                  const StatusChip('Ready to dispatch', success: true),
              ],
            ),
            const SizedBox(height: Gap.md),
            HeroSurface(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: Gap.xs),
                    child: Icon(
                      LucideIcons.package,
                      color: Colors.white,
                      size: Sizes.icon,
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalOrders Order${totalOrders == 1 ? '' : 's'}',
                          style: text.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${groups.length} Run${groups.length == 1 ? '' : 's'} · $totalStops Stop${totalStops == 1 ? '' : 's'}',
                          style: text.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: .78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (groups.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          LucideIcons.chartNoAxesColumnIncreasing,
                          color: Colors.white.withValues(alpha: .72),
                          size: 16,
                        ),
                        const SizedBox(height: Gap.xs),
                        Text(
                          'Optimized for\nefficiency',
                          textAlign: TextAlign.right,
                          style: text.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: .72),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: Gap.md),
            KpiStrip(
              items: [
                KpiItem(
                  '${totalDistance.toStringAsFixed(1)} km',
                  'Total distance',
                  icon: LucideIcons.route,
                ),
                KpiItem(
                  '$totalStops',
                  'Total stops',
                  icon: LucideIcons.mapPin,
                ),
                KpiItem(
                  '$totalOrders',
                  'Total orders',
                  icon: LucideIcons.clipboardList,
                ),
              ],
            ),
            SectionHeading('Proposed Runs (${groups.length})'),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.cardGap),
                child: CefCard(
                  onTap: _dispatchedRunId == null
                      ? null
                      : () => app.go(
                          VRoute.runDetail,
                          entityId: _dispatchedRunId,
                        ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.circleCheck,
                        size: Sizes.icon,
                        color: context.c.success,
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Text(
                          _result!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (_dispatchedRunId != null)
                        Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: context.c.textSecondary,
                        ),
                    ],
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.cardGap),
                child: CefCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.triangleAlert,
                        size: Sizes.icon,
                        color: context.c.attention,
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (groups.isEmpty)
              const StateBlock.empty(
                'Nothing is ready to plan. Orders appear here once they are '
                'approved, unassigned and have a resolved location.',
              ),

            for (final (index, group) in groups.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.cardGap),
                child: CefCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Run ${index + 1}',
                              style: text.titleMedium,
                            ),
                          ),
                          StatusChip('${group.stops.length} stops'),
                        ],
                      ),
                      const SizedBox(height: Gap.md),
                      Row(
                        children: [
                          CefAvatar(
                            (group.candidateRiderName ?? '').trim().isEmpty
                                ? '?'
                                : group.candidateRiderName!,
                          ),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.candidateRiderName ??
                                      'No candidate rider',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  () {
                                    final rider = _riderFor(
                                      riders,
                                      group.candidateRiderId,
                                    );
                                    return [
                                      if (group.candidateRiderVehicleType !=
                                          null)
                                        group.candidateRiderVehicleType!,
                                      if (rider?.plate != null) rider!.plate!,
                                      if (group.candidateRiderVehicleType ==
                                              null &&
                                          rider?.plate == null &&
                                          group.requiredVehicle != null)
                                        'requires ${group.requiredVehicle}',
                                    ].join(' · ');
                                  }(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.sm),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.package,
                            size: 14,
                            color: context.c.textSecondary,
                          ),
                          const SizedBox(width: Gap.xs),
                          Text(
                            '${group.orderIds.length} order${group.orderIds.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: Gap.md),
                          Icon(
                            LucideIcons.route,
                            size: 14,
                            color: context.c.textSecondary,
                          ),
                          const SizedBox(width: Gap.xs),
                          Text(
                            group.totalDistanceKm == null
                                ? '${group.stops.length} stop${group.stops.length == 1 ? '' : 's'}'
                                : '~${group.totalDistanceKm} km',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.sm),
                      for (final stop in group.stops)
                        CefListRow(
                          title: 'Stop ${stop.sequence}',
                          subtitle: stop.distanceKm == null
                              ? null
                              : '${stop.distanceKm} km from previous',
                          icon: LucideIcons.mapPin,
                          onTap: () => app.go(
                            VRoute.orderDetail,
                            entityId: stop.orderId,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            if (unplannable.isNotEmpty) ...[
              const SectionHeading('Cannot be planned yet'),
              for (final u in unplannable)
                CefListRow(
                  title: u.label,
                  subtitle: u.groupSize == null
                      ? null
                      : '${u.groupSize} order(s) affected',
                  leading: Icon(
                    LucideIcons.triangleAlert,
                    size: Sizes.icon,
                    color: context.c.attention,
                  ),
                  onTap: u.orderId == null
                      ? null
                      : () => app.go(VRoute.orderDetail, entityId: u.orderId!),
                ),
              const SizedBox(height: Gap.md),
            ],

            if (dispatchable.isNotEmpty) ...[
              const SizedBox(height: Gap.sm),
              CefButton(
                _dispatchingAll
                    ? 'Dispatching…'
                    : 'Dispatch ${dispatchable.length} Run${dispatchable.length == 1 ? '' : 's'}',
                busy: _dispatchingAll,
                onTap: () => _dispatchAll(dispatchable),
              ),
            ],
          ],
        );
      },
    );
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

RiderRow? _riderFor(List<RiderRow> riders, String? riderId) {
  if (riderId == null) return null;
  for (final r in riders) {
    if (r.id == riderId) return r;
  }
  return null;
}

/// V-19 — Active Run presentation. This is a preview/read model shell until
/// the repo exposes a dedicated run read endpoint for the route id.
class RunDetailScreen extends StatelessWidget {
  const RunDetailScreen({super.key, required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Row(
          children: [
            Flexible(child: Text(runId, style: text.headlineSmall)),
            const SizedBox(width: Gap.md),
            const StatusChip('Active', success: true),
          ],
        ),
        const SizedBox(height: Gap.xs),
        Text('Bangsar · Ahmad Razi · VFY 7281', style: text.bodySmall),
        const SizedBox(height: Gap.md),
        SizedBox(
          height: 240,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            child: CustomPaint(
              painter: _RoutePreviewPainter(
                ground: c.subtle,
                route: c.info,
                road: c.card,
              ),
            ),
          ),
        ),
        const SizedBox(height: Gap.lg),
        Row(
          children: [
            Expanded(child: Text('3 of 7 delivered', style: text.titleMedium)),
            Text('4 remaining', style: text.bodySmall),
          ],
        ),
        const SizedBox(height: Gap.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(Sizes.buttonRadius),
          child: LinearProgressIndicator(
            value: 3 / 7,
            minHeight: Gap.sm,
            backgroundColor: c.subtle,
            valueColor: AlwaysStoppedAnimation(c.info),
          ),
        ),
        const SectionHeading('Next stop'),
        CefListRow(
          title: 'Nadia Rahman',
          subtitle: 'Bangsar · 1.2 km · 8 min',
          leading: Icon(
            LucideIcons.mapPin,
            size: Sizes.icon,
            color: context.c.info,
          ),
          trailing: const StatusChip('Next'),
        ),
        const SectionHeading('Upcoming stops'),
        for (final i in const [
          ('Firdaus Cafe', 'Mont Kiara · 2.1 km'),
          ('Amy Lee', 'Damansara · 3.4 km'),
          ('Restoran Ali', 'Petaling Jaya · 4.0 km'),
        ])
          CefListRow(title: i.$1, subtitle: i.$2),
        const SizedBox(height: Gap.md),
        const StateBlock.blocked(
          'Route sequencing and live ETA are backend-owned. This screen is presentation-only until Phase 3 wiring.',
        ),
      ],
    );
  }
}

/// Locked V-19 direction: a blue route with a Yellow driver marker, never a
/// bare placeholder box. Illustrative only — real polylines/ETA are
/// backend-owned and land in Phase 3.
class _RoutePreviewPainter extends CustomPainter {
  _RoutePreviewPainter({
    required this.ground,
    required this.route,
    required this.road,
  });
  final Color ground, route, road;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final roads = Paint()
      ..color = road
      ..strokeWidth = 5;
    for (var i = -2; i < 8; i++) {
      canvas.drawLine(
        Offset(0, i * 40.0),
        Offset(size.width, i * 40.0 + 90),
        roads,
      );
    }
    final path = Path()
      ..moveTo(size.width * .12, size.height * .82)
      ..quadraticBezierTo(
        size.width * .35,
        size.height * .30,
        size.width * .58,
        size.height * .48,
      )
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .62,
        size.width * .90,
        size.height * .18,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    for (final stop in [
      Offset(size.width * .12, size.height * .82),
      Offset(size.width * .58, size.height * .48),
    ]) {
      canvas.drawCircle(stop, 5, Paint()..color = route);
      canvas.drawCircle(
        stop,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    for (final fraction in const [
      Offset(.25, .58),
      Offset(.43, .43),
      Offset(.73, .48),
    ]) {
      final center = Offset(
        size.width * fraction.dx,
        size.height * fraction.dy,
      );
      canvas.drawCircle(center, 12, Paint()..color = route);
      final check = Path()
        ..moveTo(center.dx - 4, center.dy)
        ..lineTo(center.dx - 1, center.dy + 3)
        ..lineTo(center.dx + 5, center.dy - 4);
      canvas.drawPath(
        check,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final driver = Offset(size.width * .90, size.height * .18);
    canvas.drawCircle(driver, 20, Paint()..color = CefColors.accent);
    final marker = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.two_wheeler.codePoint),
        style: TextStyle(
          fontFamily: Icons.two_wheeler.fontFamily,
          fontSize: 23,
          color: CefColors.navy,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    marker.paint(canvas, driver - Offset(marker.width / 2, marker.height / 2));
    canvas.drawCircle(
      driver,
      20,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) =>
      oldDelegate.ground != ground ||
      oldDelegate.route != route ||
      oldDelegate.road != road;
}

/// V-26 / V-27 — Service area. Coverage is a server decision; this screen
/// only configures the origin and radius the server uses. The origin is
/// carried as plain doubles rather than shown as raw latitude/longitude —
/// the locked guidance is to avoid technical geometry language, so the
/// vendor only ever sees a delivery-radius slider and a coverage preview.
class ServiceAreaScreen extends StatefulWidget {
  const ServiceAreaScreen({super.key});
  @override
  State<ServiceAreaScreen> createState() => _ServiceAreaScreenState();
}

class _ServiceAreaScreenState extends State<ServiceAreaScreen> {
  // Kuala Lumpur city-centre fallback: the demo/UI-only origin used until a
  // real pickup-location picker is wired in Phase 3.
  double latitude = 3.1390;
  double longitude = 101.6869;
  double radiusKm = 5;
  bool busy = false;
  String? error;
  bool loaded = false;

  void _prefill(Map<String, dynamic> b) {
    if (loaded) return;
    loaded = true;
    latitude = (b['service_origin_latitude'] as num?)?.toDouble() ?? latitude;
    longitude =
        (b['service_origin_longitude'] as num?)?.toDouble() ?? longitude;
    radiusKm =
        (b['service_coverage_radius_km'] as num?)?.toDouble() ?? radiusKm;
  }

  Future<void> _save(Future<void> Function() reload) async {
    final app = AppScope.read(context);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await app.repo.setServiceArea(
        businessId: app.business!.id,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      if (!mounted) return;
      await runAsyncFeedback(
        context,
        action: () async {},
        processingTitle: 'Processing...',
        processingSubtitle: 'Saving your service area',
        successTitle: 'Successful',
        successSubtitle: 'Your service area has been saved.',
      );
      if (!mounted) return;
      await reload();
    } on RepositoryError catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return const PageBody(
        children: [StateBlock.empty('No business linked.')],
      );
    }
    return AsyncView<Map<String, dynamic>>(
      key: ValueKey('service-area-${business.id}'),
      load: () => app.repo.business(business.id),
      builder: (context, b, reload) {
        _prefill(b);
        final configured = b['service_coverage_radius_km'] != null;
        return PageBody(
          children: [
            CefCard(
              child: Row(
                children: [
                  Icon(
                    configured
                        ? LucideIcons.circleCheck
                        : LucideIcons.circleAlert,
                    size: Sizes.icon,
                    color: configured ? context.c.success : context.c.attention,
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Text(
                      configured
                          ? 'Coverage is configured. Cefflo decides each '
                                'order’s coverage from this.'
                          : 'No service area configured yet. Orders will show '
                                '“Not set” instead of a coverage verdict.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeading('How far do you deliver?'),
            SizedBox(height: 190, child: CoveragePreview(radiusKm: radiusKm)),
            const SizedBox(height: Gap.md),
            RadiusSlider(
              radiusKm: radiusKm,
              onChanged: (v) => setState(() => radiusKm = v),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Text(
                  error!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.c.attention),
                ),
              ),
            const SizedBox(height: Gap.sm),
            CefButton(
              'Save service area',
              busy: busy,
              onTap: () => _save(reload),
            ),
            const SizedBox(height: Gap.section),
            CefListRow(
              title: 'Manage zones',
              subtitle: 'See and configure the zones you deliver to',
              icon: LucideIcons.mapPin,
              onTap: () => app.go(VRoute.zoneConfiguration),
            ),
          ],
        );
      },
    );
  }
}

/// Illustrative coverage circle around the pickup pin, shared by the setup
/// wizard (V-09) and the Service Area screen (V-26) so both draw the same
/// preview. Fills whatever box its parent gives it.
class CoveragePreview extends StatelessWidget {
  const CoveragePreview({super.key, required this.radiusKm});
  final double radiusKm;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      child: CustomPaint(
        painter: _CoveragePreviewPainter(
          radiusKm: radiusKm,
          ground: c.subtle,
          coverage: c.info,
        ),
        child: const Center(
          child: Icon(LucideIcons.mapPin, color: CefColors.navy, size: 30),
        ),
      ),
    );
  }
}

/// "Delivery radius" label + value and the 2–20 km slider, shared by V-09
/// and V-26 so the radius control has one treatment.
class RadiusSlider extends StatelessWidget {
  const RadiusSlider({
    super.key,
    required this.radiusKm,
    required this.onChanged,
  });
  final double radiusKm;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Delivery radius', style: text.titleSmall),
            Text('${radiusKm.round()} km', style: text.titleSmall),
          ],
        ),
        Slider(
          value: radiusKm,
          min: 2,
          max: 20,
          divisions: 18,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CoveragePreviewPainter extends CustomPainter {
  _CoveragePreviewPainter({
    required this.radiusKm,
    required this.ground,
    required this.coverage,
  });
  final double radiusKm;
  final Color ground, coverage;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide * .42;
    final r = maxRadius * (radiusKm / 20).clamp(.25, 1.0);
    canvas.drawCircle(
      center,
      r,
      Paint()..color = coverage.withValues(alpha: .2),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = coverage
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CoveragePreviewPainter oldDelegate) =>
      oldDelegate.radiusKm != radiusKm ||
      oldDelegate.ground != ground ||
      oldDelegate.coverage != coverage;
}
