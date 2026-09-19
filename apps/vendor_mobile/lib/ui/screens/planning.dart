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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Gap.cardPadding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0065E4),
                    Color(0xFF003B91),
                    Color(0xFF071C46),
                  ],
                ),
                borderRadius: BorderRadius.circular(Sizes.cardRadius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.package,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalOrders Order${totalOrders == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${groups.length} Run${groups.length == 1 ? '' : 's'} · $totalStops Stop${totalStops == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .78),
                            fontSize: 12.5,
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
                          color: Colors.white.withValues(alpha: .7),
                          size: 16,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Optimized for\nefficiency',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .7),
                            fontSize: 10.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: Gap.md),
            MetricTileRow(
              tiles: [
                MetricTile(
                  icon: LucideIcons.route,
                  value: '${totalDistance.toStringAsFixed(1)} km',
                  label: 'Total distance',
                ),
                MetricTile(
                  icon: LucideIcons.mapPin,
                  value: '$totalStops',
                  label: 'Total stops',
                ),
                MetricTile(
                  icon: LucideIcons.clipboardList,
                  value: '$totalOrders',
                  label: 'Total orders',
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
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: CefColors.navy,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: Gap.sm),
                          Expanded(
                            child: Text(
                              'Run ${index + 1}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F2FF),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '${group.stops.length} stops',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0864E8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.sm),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: CefColors.navy,
                            child: Text(
                              _initialsOf(group.candidateRiderName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: Gap.sm),
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
                          const SizedBox(width: 4),
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
                          const SizedBox(width: 4),
                          Text(
                            group.totalDistanceKm == null
                                ? '${group.stops.length} stop${group.stops.length == 1 ? '' : 's'}'
                                : '~${group.totalDistanceKm} km',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const Divider(height: Gap.section),
                      for (final stop in group.stops)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Gap.sm),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 16,
                                color: context.c.info,
                              ),
                              const SizedBox(width: Gap.sm),
                              Expanded(
                                child: Text(
                                  stop.distanceKm == null
                                      ? 'Stop ${stop.sequence}'
                                      : 'Stop ${stop.sequence} · ${stop.distanceKm} km from previous',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              IconAction(
                                icon: LucideIcons.chevronRight,
                                tooltip: 'Open order',
                                onTap: () => app.go(
                                  VRoute.orderDetail,
                                  entityId: stop.orderId,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            if (unplannable.isNotEmpty) ...[
              const SectionHeading('Cannot be planned yet'),
              for (final u in unplannable)
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
                            onTap: () => app.go(
                              VRoute.orderDetail,
                              entityId: u.orderId!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
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

String _initialsOf(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  return name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();
}

/// V-19 — Active Run presentation. This is a preview/read model shell until
/// the repo exposes a dedicated run read endpoint for the route id.
class RunDetailScreen extends StatelessWidget {
  const RunDetailScreen({super.key, required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Row(
        children: [
          Text(
            runId,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          const StatusChip('Active', success: true),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'Bangsar · Ahmad Razi · VFY 7281',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 270,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(painter: _RoutePreviewPainter()),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Expanded(
            child: Text(
              '3 of 7 delivered',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Text('4 remaining', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: const LinearProgressIndicator(
          value: 3 / 7,
          minHeight: 10,
          backgroundColor: Color(0xFFE3E7F0),
          valueColor: AlwaysStoppedAnimation(Color(0xFF0864E8)),
        ),
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
    for (final fraction in const [
      Offset(.25, .58),
      Offset(.43, .43),
      Offset(.73, .48),
    ]) {
      final center = Offset(
        size.width * fraction.dx,
        size.height * fraction.dy,
      );
      canvas.drawCircle(center, 12, Paint()..color = const Color(0xFF0864E8));
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
    canvas.drawCircle(driver, 20, Paint()..color = const Color(0xFFFEC819));
    final marker = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.two_wheeler.codePoint),
        style: TextStyle(
          fontFamily: Icons.two_wheeler.fontFamily,
          fontSize: 23,
          color: const Color(0xFF12213E),
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
