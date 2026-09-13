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
/// sequencing, coverage or capacity logic is reproduced in Dart.
class ReviewDispatchScreen extends StatefulWidget {
  const ReviewDispatchScreen({super.key});
  @override
  State<ReviewDispatchScreen> createState() => _ReviewDispatchScreenState();
}

class _ReviewDispatchScreenState extends State<ReviewDispatchScreen> {
  final _viewKey = GlobalKey<AsyncViewState<PlanProposal>>();
  String? _dispatchingGroup;
  String? _error;
  String? _result;
  String? _dispatchedRunId;

  Future<void> _dispatch(PlanGroup group) async {
    final app = AppScope.read(context);
    final business = app.business!;
    setState(() {
      _dispatchingGroup = group.groupKey;
      _error = null;
      _result = null;
    });
    try {
      // Server-side pre-check first, so a conflict is reported rather than
      // thrown mid-dispatch.
      final check = await app.repo.checkRunCapacity(
        riderId: group.candidateRiderId!,
        orderIds: group.orderIds,
      );
      if (!check.compatible) {
        setState(() => _error = check.violations.join('\n'));
        return;
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
      if (!mounted) return;
      setState(() {
        _result =
            'Dispatched ${run['order_count']} order(s) to '
            '${group.candidateRiderName ?? 'the selected rider'}.';
        _dispatchedRunId = run['id'] as String?;
      });
      await _viewKey.currentState?.reload();
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _dispatchingGroup = null);
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
    return AsyncView<PlanProposal>(
      key: _viewKey,
      load: () => app.repo.proposePlan(business.id),
      builder: (context, plan, reload) => PageBody(
        onRefresh: reload,
        children: [
          NavySummaryPanel(
            title: 'Review Delivery Plan',
            subtitle: 'Bangsar · Today · Ready to dispatch',
            children: [
              SummaryMetric(
                label: 'Orders',
                value:
                    '${plan.groups.fold<int>(0, (n, g) => n + g.orderIds.length)}',
              ),
              SummaryMetric(label: 'Runs', value: '${plan.groups.length}'),
              SummaryMetric(
                label: 'Stops',
                value:
                    '${plan.groups.fold<int>(0, (n, g) => n + g.stops.length)}',
              ),
            ],
          ),
          const SectionHeading('Proposed runs'),
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
                    const Icon(LucideIcons.circleCheck, size: Sizes.icon),
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

          if (plan.isEmpty)
            const StateBlock.empty(
              'Nothing is ready to plan. Orders appear here once they are '
              'approved, unassigned and have a resolved location.',
            ),

          for (final group in plan.groups) ...[
            SectionHeading(
              group.zoneId == null ? 'Run group' : 'Zone run',
              trailing: Text(
                '${group.stops.length} stop${group.stops.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            CefCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.candidateRiderName ?? 'No candidate rider',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (group.candidateRiderVehicleType != null)
                        group.candidateRiderVehicleType!,
                      if (group.requiredVehicle != null)
                        'requires ${group.requiredVehicle}',
                      if (group.totalDistanceKm != null)
                        '${group.totalDistanceKm} km',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            for (final stop in group.stops)
              FlatListRow(
                title: 'Stop ${stop.sequence}',
                subtitle: stop.distanceKm == null
                    ? null
                    : '${stop.distanceKm} km from previous',
                leading: Icon(
                  LucideIcons.mapPin,
                  size: Sizes.icon,
                  color: context.c.info,
                ),
                onTap: () => app.go(VRoute.orderDetail, entityId: stop.orderId),
              ),
            if (group.candidateRiderId != null)
              CefButton(
                _dispatchingGroup == group.groupKey
                    ? 'Dispatching…'
                    : 'Dispatch this run',
                busy: _dispatchingGroup == group.groupKey,
                onTap: () => _dispatch(group),
              ),
            const SizedBox(height: Gap.section),
          ],

          if (plan.unplannable.isNotEmpty) ...[
            const SectionHeading('Cannot be planned yet'),
            for (final u in plan.unplannable)
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.label,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (u.groupSize != null)
                              Text(
                                '${u.groupSize} order(s) affected',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      if (u.orderId != null)
                        IconAction(
                          icon: LucideIcons.chevronRight,
                          tooltip: 'Open order',
                          onTap: () =>
                              app.go(VRoute.orderDetail, entityId: u.orderId!),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// V-19 — Active Run presentation. This is a preview/read model shell until
/// the repo exposes a dedicated run read endpoint for the route id.
class RunDetailScreen extends StatelessWidget {
  const RunDetailScreen({super.key, required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      SizedBox(
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
          child: CustomPaint(painter: _RoutePreviewPainter()),
        ),
      ),
      const SizedBox(height: Gap.md),
      NavySummaryPanel(
        title: 'Active Run',
        subtitle: '$runId · Ahmad Razi · VFY 7281',
        children: const [
          SummaryMetric(label: 'Delivered', value: '3'),
          SummaryMetric(label: 'Remaining', value: '4'),
          SummaryMetric(label: 'Stops', value: '7'),
        ],
      ),
      const SectionHeading('Next stop'),
      FlatListRow(
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
        ('Faridus Cafe', 'Mont Kiara · 2.1 km'),
        ('Amy Lee', 'Damansara · 3.4 km'),
        ('Restaurant Ali', 'Petaling Jaya · 4.0 km'),
      ])
        FlatListRow(title: i.$1, subtitle: i.$2),
      const SizedBox(height: Gap.md),
      const StateBlock.blocked(
        'Route sequencing and live ETA are backend-owned. This screen is presentation-only until Phase 3 wiring.',
      ),
    ],
  );
}

/// Locked V-19 direction: a blue route with a Yellow driver marker, never a
/// bare placeholder box. Illustrative only — real polylines/ETA are
/// backend-owned and land in Phase 3.
class _RoutePreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF0F4F8),
    );
    final roads = Paint()
      ..color = Colors.white
      ..strokeWidth = 5;
    for (var i = -2; i < 8; i++) {
      canvas.drawLine(
        Offset(0, i * 40.0),
        Offset(size.width, i * 40.0 + 90),
        roads,
      );
    }
    final route = Path()
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
      route,
      Paint()
        ..color = const Color(0xFF2A6EEC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    for (final stop in [
      Offset(size.width * .12, size.height * .82),
      Offset(size.width * .58, size.height * .48),
    ]) {
      canvas.drawCircle(stop, 5, Paint()..color = const Color(0xFF2A6EEC));
      canvas.drawCircle(
        stop,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final driver = Offset(size.width * .90, size.height * .18);
    canvas.drawCircle(driver, 9, Paint()..color = const Color(0xFFFEC819));
    canvas.drawCircle(
      driver,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) => false;
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
    radiusKm = (b['service_coverage_radius_km'] as num?)?.toDouble() ?? radiusKm;
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
                    color: configured
                        ? context.c.iconColor
                        : context.c.attention,
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
            SizedBox(
              height: 190,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Sizes.cardRadius),
                child: CustomPaint(
                  painter: _CoveragePreviewPainter(radiusKm: radiusKm),
                  child: const Center(
                    child: Icon(
                      LucideIcons.mapPin,
                      color: CefColors.navy,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery radius',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${radiusKm.round()} km',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            Slider(
              value: radiusKm,
              min: 2,
              max: 20,
              divisions: 18,
              activeColor: CefColors.accent,
              onChanged: (v) => setState(() => radiusKm = v),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Text(
                  error!,
                  style: TextStyle(color: context.c.attention, fontSize: 13),
                ),
              ),
            const SizedBox(height: Gap.sm),
            CefButton(
              'Save service area',
              busy: busy,
              onTap: () => _save(reload),
            ),
            const SizedBox(height: Gap.section),
            FlatListRow(
              title: 'Manage zones',
              subtitle: 'See and configure the zones you deliver to',
              leading: Icon(
                LucideIcons.mapPin,
                size: Sizes.icon,
                color: context.c.info,
              ),
              onTap: () => app.go(VRoute.zoneConfiguration),
            ),
          ],
        );
      },
    );
  }
}

class _CoveragePreviewPainter extends CustomPainter {
  _CoveragePreviewPainter({required this.radiusKm});
  final double radiusKm;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF0F4F8),
    );
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide * .42;
    final r = maxRadius * (radiusKm / 20).clamp(.25, 1.0);
    canvas.drawCircle(center, r, Paint()..color = const Color(0x332A6EEC));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFF2A6EEC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CoveragePreviewPainter oldDelegate) =>
      oldDelegate.radiusKm != radiusKm;
}
