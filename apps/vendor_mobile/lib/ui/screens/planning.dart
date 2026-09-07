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

      final session = await app.repo.createDeliverySession(businessId: business.id);
      final run = await app.repo.buildRiderRun(
        sessionId: session['id'] as String,
        riderId: group.candidateRiderId!,
        orderIds: group.orderIds,
        // Stable for this proposal + group, so a retry is idempotent.
        idempotencyKey: _idempotencyKey(session['id'] as String, group),
      );
      if (!mounted) return;
      setState(() => _result = 'Dispatched ${run['order_count']} order(s) to '
          '${group.candidateRiderName ?? 'the selected rider'}.');
      await _viewKey.currentState?.reload();
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _dispatchingGroup = null);
    }
  }

  String _idempotencyKey(String sessionId, PlanGroup group) {
    // Deterministic UUID-shaped key from the session and the group's orders.
    final seed = '$sessionId|${group.orderIds.join(',')}'.hashCode.abs().toString();
    final hex = seed.padLeft(12, '0').substring(0, 12);
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4000-8000-${hex.padRight(12, '0').substring(0, 12)}';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return const PageBody(children: [StateBlock.empty('No business linked.')]);
    }
    return AsyncView<PlanProposal>(
      key: _viewKey,
      load: () => app.repo.proposePlan(business.id),
      builder: (context, plan, reload) => PageBody(
        onRefresh: reload,
        children: [
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.cardGap),
              child: CefCard(
                child: Row(
                  children: [
                    const Icon(LucideIcons.circleCheck, size: Sizes.icon),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Text(_result!, style: Theme.of(context).textTheme.bodyMedium),
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
                    Icon(LucideIcons.triangleAlert, size: Sizes.icon, color: context.c.attention),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
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
              group.zoneId == null ? 'Ungrouped orders' : 'Zone group',
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
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.cardGap),
                child: CefListRow(
                  title: 'Stop ${stop.sequence}',
                  subtitle: stop.distanceKm == null
                      ? null
                      : '${stop.distanceKm} km from previous',
                  icon: LucideIcons.mapPin,
                  onTap: () => app.go(VRoute.orderDetail, entityId: stop.orderId),
                ),
              ),
            if (group.candidateRiderId != null)
              CefButton(
                _dispatchingGroup == group.groupKey ? 'Dispatching…' : 'Dispatch this run',
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
                      Icon(LucideIcons.triangleAlert, size: Sizes.icon, color: context.c.attention),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.label, style: Theme.of(context).textTheme.titleSmall),
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
                          onTap: () => app.go(VRoute.orderDetail, entityId: u.orderId!),
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

/// V-26 / V-27 — Service area. Coverage is a server decision; this screen only
/// configures the origin and radius the server uses.
class ServiceAreaScreen extends StatefulWidget {
  const ServiceAreaScreen({super.key});
  @override
  State<ServiceAreaScreen> createState() => _ServiceAreaScreenState();
}

class _ServiceAreaScreenState extends State<ServiceAreaScreen> {
  final lat = TextEditingController();
  final lng = TextEditingController();
  final radius = TextEditingController();
  bool busy = false;
  String? error;
  String? saved;
  bool loaded = false;

  @override
  void dispose() {
    lat.dispose();
    lng.dispose();
    radius.dispose();
    super.dispose();
  }

  void _prefill(Map<String, dynamic> b) {
    if (loaded) return;
    loaded = true;
    lat.text = (b['service_origin_latitude'] ?? '').toString();
    lng.text = (b['service_origin_longitude'] ?? '').toString();
    radius.text = (b['service_coverage_radius_km'] ?? '').toString();
  }

  Future<void> _save(Future<void> Function() reload) async {
    final app = AppScope.read(context);
    final latitude = double.tryParse(lat.text.trim());
    final longitude = double.tryParse(lng.text.trim());
    final km = num.tryParse(radius.text.trim());
    if (latitude == null || longitude == null || km == null || km <= 0) {
      setState(() => error = 'Enter a valid origin and a positive radius.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      saved = null;
    });
    try {
      await app.repo.setServiceArea(
        businessId: app.business!.id,
        latitude: latitude,
        longitude: longitude,
        radiusKm: km,
      );
      if (!mounted) return;
      setState(() => saved = 'Service area saved.');
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
      return const PageBody(children: [StateBlock.empty('No business linked.')]);
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
                    configured ? LucideIcons.circleCheck : LucideIcons.circleAlert,
                    size: Sizes.icon,
                    color: configured ? context.c.iconColor : context.c.attention,
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Text(
                      configured
                          ? 'Coverage is configured. The server decides each '
                                'order’s coverage from this origin and radius.'
                          : 'No service area configured. Orders will report '
                                '“Service area not set” instead of a coverage verdict.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeading('Origin and radius'),
            CefField(label: 'Origin latitude', controller: lat, keyboardType: TextInputType.number),
            CefField(label: 'Origin longitude', controller: lng, keyboardType: TextInputType.number),
            CefField(label: 'Radius (km)', controller: radius, keyboardType: TextInputType.number),
            if (saved != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Text(saved!, style: Theme.of(context).textTheme.bodySmall),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Text(
                  error!,
                  style: TextStyle(color: context.c.attention, fontSize: 13),
                ),
              ),
            CefButton('Save service area', busy: busy, onTap: () => _save(reload)),
          ],
        );
      },
    );
  }
}
