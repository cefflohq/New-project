import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/money.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../async_view.dart';
import '../delivery_pin.dart';
import '../shell.dart';
import '../widgets.dart';
import 'hiring.dart';
import 'planning.dart' show showDispatchSheet;

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

import '../../core/ui_locale.dart';

/// V-16 — Zones overview: every zone on one map, then the zone list (name,
/// status, today's orders and riders). Tapping a zone opens its Zone detail.
class ZonesScreen extends StatelessWidget {
  const ZonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return PageBody(children: [StateBlock.empty(L.noBusinessLinked)]);
    }
    return AsyncView<(List<Zone>, List<VendorOrder>)>(
      loading: const SkeletonPage(
        top: [
          SkeletonBox(height: 240),
          SizedBox(height: Gap.sm),
        ],
      ),
      key: ValueKey('zones-${business.id}-${zonesRevision.value}'),
      live: true,
      load: () async => (
        await app.repo.zones(business.id),
        await app.repo.orders(business.id),
      ),
      builder: (context, data, reload) {
        final (zones, orders) = data;
        return PageBody(
          onRefresh: reload,
          children: [
            _ZonesOverviewMap(
              orders: orders,
              zones: zones.where((z) => z.isActive).toList(),
            ),
            SectionHeading(L.zones2(zones.length)),
            if (zones.isEmpty)
              StateBlock.empty(L.noZonesYetTapCreateFirst)
            else
              for (final z in zones)
                Builder(
                  builder: (context) {
                    // Counts derive from the same scoped orders read.
                    final inZone = orders.where((o) => o.zoneId == z.id);
                    final riders = {
                      for (final o in inZone)
                        if (o.assignedRiderId != null) o.assignedRiderId,
                    };
                    return CefListRow(
                      title: z.name,
                      subtitle: L.zoneOrdersRiders(
                        inZone.length,
                        riders.length,
                      ),
                      // Same colour as the zone's area on the map.
                      leading: IconTile(
                        LucideIcons.mapPin,
                        color: z.isActive && z.boundary != null
                            ? zoneColor(z)
                            : null,
                      ),
                      trailing: StatusChip(
                        z.isActive ? L.active : L.inactive,
                        success: z.isActive,
                      ),
                      // Audit fix 2: bound to this zone's id.
                      onTap: () => app.go(VRoute.zoneDetail, entityId: z.id),
                    );
                  },
                ),
            // Orders still waiting for planning but without a zone: they are
            // in no zone's plan, so surface them here to be given one.
            if (unzonedOrders(orders).isNotEmpty)
              CefListRow(
                title: L.noZoneCount(unzonedOrders(orders).length),
                subtitle: L.noZoneHint,
                icon: LucideIcons.circleAlert,
                onTap: () => _showUnzonedOrders(context, unzonedOrders(orders)),
              ),
          ],
        );
      },
    );
  }
}

/// Every pinned order across the business's zones on one real map, with
/// each zone's drawn boundary (Founder 2026-10-12).
class _ZonesOverviewMap extends StatelessWidget {
  const _ZonesOverviewMap({required this.orders, this.zones = const []});
  final List<VendorOrder> orders;
  final List<Zone> zones;

  @override
  Widget build(BuildContext context) => PinsMap(
    drops: _drops(orders),
    zones: zones,
    emptyLabel: L.mapNoPinnedOrders,
  );
}

/// Pinned orders as map drops; delivered ones show a check.
List<MapDrop> _drops(Iterable<VendorOrder> orders) => [
  for (final o in orders)
    if (o.hasPin && o.status != DeliveryStatus.cancelled)
      (
        lat: o.latitude!,
        lng: o.longitude!,
        label: null,
        done: o.status == DeliveryStatus.delivered,
        next: false,
      ),
];

/// V-28 — Service Area's zone configuration list. Distinct from the
/// operational V-16 Zones tab: no today's-order counts, just what is
/// configured and whether it is Active/Inactive.
class ZoneConfigurationScreen extends StatefulWidget {
  const ZoneConfigurationScreen({super.key});
  @override
  State<ZoneConfigurationScreen> createState() =>
      _ZoneConfigurationScreenState();
}

class _ZoneConfigurationScreenState extends State<ZoneConfigurationScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return PageBody(children: [StateBlock.empty(L.noBusinessLinked)]);
    }
    return AsyncView<List<Zone>>(
      key: ValueKey('zone-configuration-${business.id}-${zonesRevision.value}'),
      load: () => app.repo.zones(business.id),
      builder: (context, zones, reload) {
        final q = _query.text.trim().toLowerCase();
        final visible = q.isEmpty
            ? zones
            : zones.where((z) => z.name.toLowerCase().contains(q)).toList();
        return PageBody(
          onRefresh: reload,
          children: [
            CefCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: Sizes.icon,
                    color: context.c.iconColor,
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Text(
                      L.theseZonesDefineWhereDeliverAdd,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.md),
            CefSearchField(
              hint: L.searchZones,
              controller: _query,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              StateBlock.empty(L.noZonesConfiguredYet)
            else
              // Archetype C (zones list): accent map-pin disc, status pill.
              for (final z in visible)
                CefListRow(
                  title: z.name,
                  icon: LucideIcons.mapPin,
                  trailing: StatusChip(
                    z.isActive ? L.active : L.inactive,
                    success: z.isActive,
                  ),
                  onTap: () => app.go(VRoute.zoneDetail, entityId: z.id),
                ),
          ],
        );
      },
    );
  }
}

/// V-17 — Zone detail: the one operational screen for a zone (D-49). Map,
/// identity, three figures (total distance, total orders, delivered), then
/// today's deliveries -- each rider with their stops. Its header is the
/// zone's own name, with a ⋮ menu for Edit zone name / Delete zone. Review,
/// dispatch and edit-zone screens are consolidated here.
class ZoneDetailScreen extends StatefulWidget {
  const ZoneDetailScreen({super.key, required this.zoneId});
  final String zoneId;

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

typedef _ZoneData = (
  Zone,
  List<VendorOrder>,
  PlanProposal,
  List<RiderRow>,
  List<VendorRun>,
);

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  final _view = GlobalKey<AsyncViewState<_ZoneData>>();

  /// Drivers the Vendor chose for planning (null = every active driver) and
  /// how a zone is split across them.
  Set<String>? _riderIds;
  String _policy = 'balance';

  /// The loaded zone; drives the header title and the ⋮ menu.
  Zone? _zone;

  Future<_ZoneData> _load() async {
    final app = AppScope.read(context);
    final businessId = app.business!.id;
    final zones = await app.repo.zones(businessId);
    final zone = zones.firstWhere(
      (z) => z.id == widget.zoneId,
      orElse: () => throw StateError(L.zoneNotFound),
    );
    final orders = await app.repo.orders(businessId);
    final plan = await app.repo.proposePlan(
      businessId,
      riderIds: _riderIds?.toList(),
      policy: _policy,
    );
    final riders = await app.repo.riders(businessId);
    final runs = await app.repo.runs(businessId);
    if (mounted) setState(() => _zone = zone);
    return (
      zone,
      orders.where((o) => o.zoneId == widget.zoneId).toList(),
      plan,
      riders,
      runs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final zone = _zone;
    return Column(
      children: [
        AppHeader(
          title: zone?.name ?? '',
          leading: [HeaderBackButton(onTap: AppScope.read(context).back)],
          trailing: [
            IconAction(
              icon: LucideIcons.ellipsis,
              tooltip: L.zoneOptions,
              color: Colors.white,
              onTap: zone == null ? () {} : () => _showZoneOptions(zone),
            ),
          ],
        ),
        Expanded(
          child: ContentSurface(
            bottomSafeArea: false,
            child: AsyncView<_ZoneData>(
              loading: const SkeletonPage(
                top: [
                  SkeletonBox(height: 200),
                  SizedBox(height: Gap.md),
                  SkeletonKpis(count: 3),
                  SkeletonHeading(link: false),
                ],
                rows: 3,
              ),
              key: _view,
              load: _load,
              builder: (context, data, reload) => _ZoneDetailBody(
                data: data,
                reload: reload,
                selectedRiders: _riderIds,
                policy: _policy,
                onPlanSettings: (riderIds, policy) {
                  setState(() {
                    _riderIds = riderIds;
                    _policy = policy;
                  });
                  _view.currentState?.reload();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Draw / edit / remove the zone's boundary in a near-full-height sheet.
  Future<void> _editBoundary(Zone zone) async {
    final app = AppScope.read(context);
    final others = (await app.repo.zones(app.business!.id))
        .where((z) => z.id != zone.id && z.boundary != null)
        .toList();
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.c.card,
      builder: (sheet) => SizedBox(
        height: MediaQuery.sizeOf(sheet).height * .9,
        child: ZoneBoundaryEditor(
          zone: zone,
          others: others,
          onSave: (ring) => app.repo.setZoneBoundary(zone.id, ring),
        ),
      ),
    );
    if (saved == true && mounted) {
      zonesRevision.value++;
      _view.currentState?.reload();
    }
  }

  /// Zone options: edit name, draw boundary, delete zone.
  void _showZoneOptions(Zone zone) {
    final c = context.c;
    showCefSheet<void>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Sizes.cardRadius),
        ),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Gap.gutter,
            Gap.xl,
            Gap.gutter,
            Gap.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(L.zoneOptions, style: Theme.of(sheet).textTheme.titleMedium),
              const SizedBox(height: Gap.sm),
              CefListRow(
                title: L.editZoneName,
                icon: LucideIcons.pencil,
                showChevron: false,
                onTap: () {
                  Navigator.of(sheet).pop();
                  _editName(zone);
                },
              ),
              CefListRow(
                title: zone.boundary == null
                    ? L.drawZoneBoundary
                    : L.editZoneBoundary,
                icon: LucideIcons.pentagon,
                showChevron: false,
                onTap: () {
                  Navigator.of(sheet).pop();
                  _editBoundary(zone);
                },
              ),
              _DestructiveRow(
                label: L.deleteZone,
                onTap: () {
                  Navigator.of(sheet).pop();
                  _confirmDelete(zone);
                },
              ),
              const SizedBox(height: Gap.lg),
              CefButton(
                L.cancel,
                secondary: true,
                onTap: () => Navigator.of(sheet).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editName(Zone zone) async {
    final app = AppScope.read(context);
    final picked = await showCefSheet<(String, AreaSuggestion?)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Sizes.cardRadius),
        ),
      ),
      builder: (sheet) => _EditZoneNameSheet(initialName: zone.name),
    );
    if (picked == null || !mounted) return;
    final (name, place) = picked;
    if (name == zone.name && place == null) return;
    try {
      final updated = await app.repo.renameZone(zone.id, name, place: place);
      if (!mounted) return;
      setState(() => _zone = updated);
      await _view.currentState?.reload();
      if (!mounted) return;
      showCefToast(context, L.zoneRenamed(updated.name));
    } catch (e) {
      if (mounted) {
        showCefToast(context, L.couldNotRename(e), error: true);
      }
    }
  }

  Future<void> _confirmDelete(Zone zone) async {
    final app = AppScope.read(context);
    final confirmed = await showCefSheet<bool>(
      context: context,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Sizes.cardRadius),
        ),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Gap.gutter,
            Gap.xl,
            Gap.gutter,
            Gap.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                L.delete(zone.name),
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
              const SizedBox(height: Gap.xs),
              Text(
                L.willRemoveZoneFromDeliverySetup,
                style: Theme.of(sheet).textTheme.bodyMedium,
              ),
              const SizedBox(height: Gap.xl),
              Row(
                children: [
                  Expanded(
                    child: CefButton(
                      L.cancel,
                      secondary: true,
                      onTap: () => Navigator.of(sheet).pop(false),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: CefButton(
                      L.delete2,
                      destructive: true,
                      onTap: () => Navigator.of(sheet).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      // Leaves the list; the row stays for order history (delete_zone).
      await app.repo.deleteZone(zone.id);
      if (!mounted) return;
      zonesRevision.value++;
      app.dataChanged();
      showCefToast(context, L.removedFromDeliverySetup(zone.name));
      app.back();
    } catch (e) {
      if (mounted) {
        showCefToast(context, L.couldNotDelete(e), error: true);
      }
    }
  }
}

/// A red, destructive action row for option sheets (Delete zone).
class _DestructiveRow extends StatelessWidget {
  const _DestructiveRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final red = context.c.attention;
    return CefListRow(
      title: label,
      leading: IconTile(LucideIcons.trash2, color: red),
      titleColor: red,
      showChevron: false,
      showDivider: false,
      onTap: onTap,
    );
  }
}

/// Lightweight editor for the zone name: one field, Cancel / Save.
class _EditZoneNameSheet extends StatefulWidget {
  const _EditZoneNameSheet({required this.initialName});
  final String initialName;

  @override
  State<_EditZoneNameSheet> createState() => _EditZoneNameSheetState();
}

class _EditZoneNameSheetState extends State<_EditZoneNameSheet> {
  // Owned by the sheet, so it outlives the closing animation.
  late final _controller = ZoneNameController(text: widget.initialName);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = L.zoneNameRequired);
      return;
    }
    Navigator.of(context).pop((name, _controller.place));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      Gap.gutter,
      Gap.xl,
      Gap.gutter,
      MediaQuery.viewInsetsOf(context).bottom + Gap.lg,
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(L.editZoneName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Gap.md),
          ZoneNameInput(
            controller: _controller,
            hint: L.zoneName,
            errorText: _error,
          ),
          Row(
            children: [
              Expanded(
                child: CefButton(
                  L.cancel,
                  secondary: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(child: CefButton(L.save, onTap: _save)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ZoneDetailBody extends StatelessWidget {
  const _ZoneDetailBody({
    required this.data,
    required this.reload,
    required this.selectedRiders,
    required this.policy,
    required this.onPlanSettings,
  });
  final _ZoneData data;
  final Future<void> Function() reload;
  final Set<String>? selectedRiders;
  final String policy;
  final void Function(Set<String>? riderIds, String policy) onPlanSettings;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final (zone, orders, plan, riders, allRuns) = data;
    final byId = {for (final o in orders) o.id: o};
    // Dispatched work is canonical persisted runs; the proposal only covers
    // what is still waiting to be dispatched.
    final runs = allRuns
        .where((r) => r.isOpen && r.orderIds.any(byId.containsKey))
        .toList();
    final groups = plan.groups
        .where((g) => g.zoneId == zone.id && g.stops.isNotEmpty)
        .toList();
    final unplanned = plan.unplannable
        .where((u) => u.zoneId == zone.id && u.orderId != null)
        .toList();
    final active = riders.where((r) => r.isActive).toList();
    final chosen = selectedRiders;
    final distance = groups.fold<num>(
      0,
      (sum, g) => sum + (g.totalDistanceKm ?? 0),
    );
    // Delivered is what has actually been delivered -- 0 until it happens.
    final delivered = orders
        .where((o) => o.status == DeliveryStatus.delivered)
        .length;
    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Gap.gutter,
          Gap.lg,
          Gap.gutter,
          Gap.xxl,
        ),
        children: [
          _ZoneMap(orders: orders, zone: zone),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Flexible(
                child: Text(
                  zone.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium,
                ),
              ),
              const SizedBox(width: Gap.sm),
              StatusChip(
                zone.isActive ? L.active : L.inactive,
                success: zone.isActive,
              ),
            ],
          ),
          if (zone.locality != null) ...[
            const SizedBox(height: 2),
            Text(zone.locality!, style: text.bodySmall),
          ],
          const SizedBox(height: Gap.md),
          // Three operational figures, no enclosing card.
          KpiStrip(
            items: [
              KpiItem(
                groups.isEmpty ? L.t0Km : L.km(distance.toStringAsFixed(1)),
                L.totalDistance,
                icon: LucideIcons.route,
              ),
              KpiItem(
                '${orders.length}',
                L.totalOrders,
                icon: LucideIcons.clipboardList,
              ),
              KpiItem('$delivered', L.delivered, icon: LucideIcons.circleCheck),
            ],
          ),
          SectionHeading(L.todaysDeliveries),
          CefListRow(
            title: L.planDrivers,
            subtitle: [
              chosen == null
                  ? L.planDriversAll
                  : L.planDriversCount(chosen.length),
              policy == 'fill' ? L.planFill : L.planBalance,
            ].join(' · '),
            icon: LucideIcons.users,
            onTap: () => _showPlanSettings(
              context,
              riders: active,
              selected: chosen,
              policy: policy,
              onApply: onPlanSettings,
            ),
          ),
          for (final e in plan.excludedRiders)
            Padding(
              padding: const EdgeInsets.only(top: Gap.xs),
              child: Text(
                e.label(
                  riders.where((r) => r.id == e.riderId).firstOrNull?.name ??
                      L.rider,
                ),
                style: text.bodySmall,
              ),
            ),
          if (groups.isEmpty && runs.isEmpty && unplanned.isEmpty)
            StateBlock.empty(L.noDeliveriesPlannedZoneToday)
          else ...[
            for (final r in runs) ...[
              _DispatchedRiderHeader(
                run: r,
                rider: riders.where((x) => x.id == r.riderId).firstOrNull,
              ),
              for (final stop in r.stops.where(
                (s) => byId.containsKey(s.orderId),
              ))
                CefListRow(
                  title: byId[stop.orderId]?.customerName ?? stop.orderId,
                  subtitle: byId[stop.orderId]?.statusLabel,
                  leading: SizedBox(
                    width: Sizes.avatar,
                    child: Center(child: _SequenceBadge(stop.sequence)),
                  ),
                  onTap: () =>
                      app.go(VRoute.orderDetail, entityId: stop.orderId),
                ),
            ],
            for (final g in groups) ...[
              _RiderHeader(
                group: g,
                rider: riders
                    .where((r) => r.id == g.candidateRiderId)
                    .firstOrNull,
              ),
              for (final stop in g.stops)
                _DeliveryStopRow(
                  stop: stop,
                  order: byId[stop.orderId],
                  isLast: stop == g.stops.last,
                  onRemoved: reload,
                  onTap: () =>
                      app.go(VRoute.orderDetail, entityId: stop.orderId),
                ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CefLink(
                  L.dispatch,
                  chevron: true,
                  onTap: () => showDispatchSheet(
                    context,
                    zone: zone,
                    group: g,
                    riders: riders,
                    onDispatched: reload,
                    deliveryDate: plan.planDate,
                  ),
                ),
              ),
            ],
            if (unplanned.isNotEmpty) ...[
              SectionHeading(L.planNotPlanned(unplanned.length)),
              for (final u in unplanned)
                CefListRow(
                  title: byId[u.orderId]?.customerName ?? u.orderId!,
                  subtitle: u.label,
                  icon: LucideIcons.circleAlert,
                  onTap: () => app.go(VRoute.orderDetail, entityId: u.orderId),
                ),
            ],
          ],
          if (groups.isNotEmpty) ...[
            const SizedBox(height: Gap.sm),
            Text(L.planPolicyHint, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// A rider with dispatched (persisted) work in this zone. Opens V-19.
class _DispatchedRiderHeader extends StatelessWidget {
  const _DispatchedRiderHeader({required this.run, required this.rider});
  final VendorRun run;
  final RiderRow? rider;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final name = rider?.name ?? L.rider;
    return CefListRow(
      title: name,
      subtitle: [
        if (rider?.vehicleType != null) vehicleTypeLabel(rider!.vehicleType!),
        if (rider?.plate != null) rider!.plate!,
      ].join(' · '),
      leading: CefAvatar(name, filled: true),
      trailing: StatusChip(run.statusLabel, info: true),
      onTap: () => app.go(VRoute.runDetail, entityId: run.id),
    );
  }
}

/// The rider leading a group of today's deliveries: avatar, name, vehicle ·
/// plate, and a neutral "n orders" count (metadata, never yellow).
class _RiderHeader extends StatelessWidget {
  const _RiderHeader({required this.group, required this.rider});
  final PlanGroup group;
  final RiderRow? rider;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final name = group.candidateRiderName ?? rider?.name ?? L.unassignedRider;
    final count = group.stops.length;
    return CefListRow(
      title: name,
      subtitle: [
        if (group.candidateRiderVehicleType != null)
          vehicleTypeLabel(group.candidateRiderVehicleType!),
        if (rider?.plate != null) rider!.plate!,
      ].join(' · '),
      leading: CefAvatar(name, filled: true),
      trailing: StatusChip(L.order(count, count == 1 ? '' : 's')),
      onTap: group.candidateRiderId == null
          ? null
          : () => app.go(VRoute.riderDetail, entityId: group.candidateRiderId),
    );
  }
}

/// One stop in today's deliveries: sequence, customer, distance · time and
/// the planned arrival. Cardless, divided by a hairline; swipe to delete.
class _DeliveryStopRow extends StatelessWidget {
  const _DeliveryStopRow({
    required this.stop,
    required this.order,
    required this.isLast,
    required this.onRemoved,
    required this.onTap,
  });
  final PlanStop stop;
  final VendorOrder? order;
  final bool isLast;
  final Future<void> Function() onRemoved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    final meta = [
      if (stop.distanceKm != null) L.km2(stop.distanceKm!),
      if (stop.travelMinutes != null) L.min(stop.travelMinutes!),
    ].join(' · ');
    final eta = stop.etaAt == null ? null : _formatTime(stop.etaAt!);
    final row = CefListRow(
      title: order?.customerName ?? stop.orderId,
      subtitle: meta.isEmpty ? null : meta,
      leading: SizedBox(
        width: Sizes.avatar,
        child: Center(child: _SequenceBadge(stop.sequence)),
      ),
      trailing: eta == null ? null : Text(eta, style: text.bodySmall),
      onTap: onTap,
    );
    // Removing a delivery from today's plan has no canonical contract yet
    // (D-61), so the real build offers no swipe at all.
    if (!AppScope.of(context).repo.isDemo) return row;
    return Dismissible(
      key: ValueKey('stop-${stop.orderId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: c.attention,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
        child: const Icon(
          LucideIcons.trash2,
          color: Colors.white,
          size: Sizes.icon,
        ),
      ),
      // A deliberate, full swipe: a partial drag snaps back.
      dismissThresholds: const {DismissDirection.endToStart: .5},
      confirmDismiss: (_) async {
        final app = AppScope.read(context);
        try {
          await app.repo.removeFromTodaysDeliveries(stop.orderId);
          return true;
        } catch (e) {
          if (context.mounted) {
            showCefToast(context, '$e', error: true);
          }
          return false;
        }
      },
      onDismissed: (_) {
        showCefToast(
          context,
          L.removedFromToday(order?.customerName ?? L.delivery),
        );
        onRemoved();
      },
      child: row,
    );
  }

  static String _formatTime(DateTime t) =>
      '${t.hour % 12 == 0 ? 12 : t.hour % 12}:'
      '${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// Stop order indicator: the sequence number in an Anchor Blue dot.
class _SequenceBadge extends StatelessWidget {
  const _SequenceBadge(this.sequence);
  final int sequence;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: CefColors.brand, shape: BoxShape.circle),
    child: Text(
      '$sequence',
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Colors.white),
    ),
  );
}

/// Zone detail map: this zone's pinned orders on a real map.
class _ZoneMap extends StatelessWidget {
  const _ZoneMap({required this.orders, required this.zone});
  final List<VendorOrder> orders;
  final Zone zone;

  @override
  Widget build(BuildContext context) => PinsMap(
    height: 260,
    drops: _drops(orders),
    zones: [zone],
    emptyLabel: L.mapNoPinnedOrders,
  );
}

/// V-29 — Create zone, bound to the canonical `create_zone` contract.
/// Coverage geometry stays server-owned: this only names the zone and
/// previews it. Editing and deleting a zone live in Zone detail's ⋮ menu.
class CreateZoneScreen extends StatefulWidget {
  const CreateZoneScreen({super.key});

  @override
  State<CreateZoneScreen> createState() => _CreateZoneScreenState();
}

class _CreateZoneScreenState extends State<CreateZoneScreen> {
  final name = ZoneNameController();
  bool busy = false;
  String? error;
  String? nameError;

  Future<void> _save() async {
    setState(
      () => nameError = name.text.trim().isEmpty ? L.zoneNameRequired : null,
    );
    if (nameError != null) return;

    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      final ok = await runAsyncFeedback(
        context,
        action: () async {},
        processingTitle: L.processing,
        processingSubtitle: L.creatingZone,
        successTitle: L.successful,
        successSubtitle: L.newZoneHasBeenCreatedSuccessfully,
      );
      if (!mounted || !ok) return;
      app.back();
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await app.repo.createZone(
        app.business!.id,
        name.text.trim(),
        place: name.place,
      );
      if (!mounted) return;
      app.back();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageBody(
      bottom: CefButton(L.createZone2, busy: busy, onTap: _save),
      children: [
        // Real map of the zones already drawn (Founder 2026-10-12); the
        // new zone's boundary is drawn from Zone detail after it exists.
        FutureBuilder<List<Zone>>(
          future: AppScope.read(context).repo
              .zones(AppScope.read(context).business!.id),
          builder: (context, snap) => PinsMap(
            height: 240,
            drops: const [],
            zones: (snap.data ?? const <Zone>[])
                .where((z) => z.isActive)
                .toList(),
          ),
        ),
        const SizedBox(height: Gap.md),
        Text(L.zoneWillCoverHighlightedAreaMap, style: text.bodySmall),
        SectionHeading(
          L.zoneDetails,
          icon: LucideIcons.mapPin,
          subtitle: L.nameAreaDeliver,
        ),
        ZoneNameInput(
          label: L.zoneName,
          controller: name,
          hint: L.enterZoneName,
          errorText: nameError,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              error!,
              style: text.bodySmall?.copyWith(color: context.c.attention),
            ),
          ),
      ],
    );
  }
}

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});
  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  /// Selected filter: 0 All, 1 Active (on a run now), 2 Pending (registered,
  /// waiting for the vendor's approval). Index, never display text, so
  /// filtering works in every language.
  int tab = 0;

  /// A run the rider is working right now (accepted through delivering).
  static const _onRun = {'accepted', 'picking_up', 'delivering'};

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return PageBody(children: [StateBlock.empty(L.noBusinessLinked)]);
    }
    return ValueListenableBuilder<RidersMode>(
      valueListenable: ridersMode,
      builder: (context, _, _) => AsyncView<(List<RiderRow>, Set<String>)>(
        key: ValueKey('riders-${business.id}'),
        live: true,
        load: () async {
          await loadOpenOpenings(app);
          // Removed or rejected riders (inactive) are no longer on the team.
          final riders = (await app.repo.riders(business.id))
              .where((r) => r.status != 'inactive')
              .toList();
          final runs = await app.repo.runs(business.id);
          return (
            riders,
            {
              for (final r in runs)
                if (_onRun.contains(r.status)) r.riderId,
            },
          );
        },
        builder: (context, data, reload) {
          final (riders, onRun) = data;
          final visible = switch (tab) {
            1 => riders.where((r) => onRun.contains(r.id)).toList(),
            2 => riders.where((r) => r.isPending).toList(),
            _ => riders,
          };
          final tabLabels = [L.all, L.active, L.pending];
          final mode = ridersMode.value;
          return PageBody(
            onRefresh: reload,
            children: [
              // Draft D (Founder 2026-10-05): Riders | Openings for the
              // Owner; the header "+" adds whatever is showing.
              if (business.canHire) ...[
                const RidersModeSwitch(),
                const SizedBox(height: Gap.md),
              ],
              if (business.canHire && mode == RidersMode.openings)
                const OpeningsList()
              else ...[
                SegmentedTabs(
                  labels: tabLabels,
                  active: tabLabels[tab],
                  onChange: (l) => setState(() => tab = tabLabels.indexOf(l)),
                ),
                const SizedBox(height: Gap.md),
                if (visible.isEmpty)
                  StateBlock.empty(switch (tab) {
                    1 => L.noActiveRidersYet,
                    2 => L.noPendingRidersYet,
                    _ => L.noRidersYet,
                  })
                else
                  for (final r in visible)
                    CefListRow(
                      title: r.name,
                      subtitle: [
                        if (r.vehicleType != null)
                          vehicleTypeLabel(r.vehicleType!),
                        if (r.plate != null) r.plate!,
                      ].join(' · '),
                      leading: CefAvatar(r.name, filled: true),
                      trailing: onRun.contains(r.id)
                          ? StatusChip(L.active, success: true)
                          : r.isPending
                          ? StatusChip(L.pending, warning: true)
                          : null,
                      // Audit fix 2: bound to this rider's id.
                      onTap: () => app.go(VRoute.riderDetail, entityId: r.id),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// "12 Jan 2024" -- the one short date format on detail stats.
String _shortDate(DateTime d) {
  final months = [
    L.jan,
    L.feb,
    L.mar,
    L.apr,
    L.may,
    L.jun,
    L.jul,
    L.aug,
    L.sep,
    L.oct,
    L.nov,
    L.dec,
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

IconData _vehicleIcon(String? type) => switch (type?.toLowerCase()) {
  'car' => LucideIcons.car,
  'van' || 'truck' => LucideIcons.truck,
  'bicycle' => LucideIcons.bike,
  _ => LucideIcons.motorbike,
};

/// V-21 — Rider detail (archetype E). Identity, role and plate on the
/// gradient; one stats card (Total orders · Customer rating · Joined); the
/// shared Contact card; then licence / additional information. Figures the
/// backend does not supply show "—" rather than an invented value.
class RiderDetailScreen extends StatelessWidget {
  const RiderDetailScreen({super.key, required this.riderId});
  final String riderId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<RiderRow>(
      loading: const SkeletonHeroPage(),
      key: ValueKey('rider-$riderId'),
      live: true,
      load: () async {
        final riders = await app.repo.riders(app.business!.id);
        return riders.firstWhere(
          (r) => r.id == riderId,
          orElse: () => throw StateError(L.riderNotFound),
        );
      },
      builder: (context, rider, reload) {
        final pending = rider.status == 'pending';
        final plate = rider.plate ?? '';
        return HeroPage(
          onRefresh: reload,
          hero: DetailHero(
            leading: CefAvatar(rider.name, size: 88),
            title: rider.name,
            status: HeroStatusPill(
              pending
                  ? L.pendingReview
                  : rider.isActive
                  ? L.active
                  : L.offline,
              color: pending
                  ? context.c.warning
                  : rider.isActive
                  ? null
                  : context.c.textSecondary,
            ),
            lines: [
              HeroLine(pending ? L.riderApplicant : L.rider),
              if (plate.isNotEmpty)
                HeroLine(plate, icon: _vehicleIcon(rider.vehicleType)),
            ],
          ),
          // Driver approval/rejection: Owner and Operator (M2; enforced
          // server-side by approve_pending_rider / deactivate_rider).
          bottomAction: pending && (app.business?.canHire ?? false)
              ? Row(
                  children: [
                    Expanded(
                      child: CefButton(
                        L.reject,
                        secondary: true,
                        onTap: () => _decideRider(context, rider.id, false),
                      ),
                    ),
                    const SizedBox(width: Gap.cardGap),
                    Expanded(
                      child: CefButton(
                        L.approveRider,
                        onTap: () => _decideRider(context, rider.id, true),
                      ),
                    ),
                  ],
                )
              : null,
          children: [
            StatsCard(
              items: [
                KpiItem(
                  rider.totalOrders?.toString() ?? '—',
                  L.totalOrders,
                  icon: LucideIcons.package,
                ),
                KpiItem(
                  rider.rating?.toStringAsFixed(1) ?? '—',
                  L.customerRating,
                  icon: LucideIcons.star,
                ),
                KpiItem(
                  rider.joinedAt == null ? '—' : _shortDate(rider.joinedAt!),
                  L.joined,
                  icon: LucideIcons.calendarDays,
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            ContactCard(phone: rider.phone),
            CefListGroup(
              children: [
                CefListRow(
                  title: L.drivingLicence,
                  subtitle: L.noLicenceDocumentAvailable,
                  icon: LucideIcons.fileText,
                ),
                CefListRow(
                  title: L.additionalInformation,
                  subtitle: L.noAdditionalInformationAvailable,
                  icon: LucideIcons.clipboardList,
                ),
              ],
            ),
            // Rider removal is Owner-only (enforced by deactivate_rider).
            if (!pending &&
                rider.status != 'inactive' &&
                app.business?.isOwner == true)
              CefButton(
                L.removeRider,
                destructive: true,
                icon: LucideIcons.trash2,
                onTap: () => _confirmRemoveRider(context, rider),
              ),
          ],
        );
      },
    );
  }

  /// Security & Access Master Part III §20/§21/§23: typed CONFIRM, backend
  /// removal (refused while the rider has open work), fresh read-back.
  Future<void> _confirmRemoveRider(BuildContext context, RiderRow rider) async {
    final confirmed = await showTypedConfirmDialog(
      context,
      title: L.removeRiderTitle(rider.name),
      message: L.removeRiderBody(rider.name),
      actionLabel: L.removeRider,
    );
    if (!confirmed || !context.mounted) return;
    final app = AppScope.read(context);
    try {
      await app.repo.removeRider(rider.id);
      final after = (await app.repo.riders(app.business!.id))
          .where((r) => r.id == rider.id);
      if (!context.mounted) return;
      if (after.isNotEmpty && after.first.status != 'inactive') {
        showCefToast(context, L.removalNotConfirmed, error: true);
        return;
      }
      app.dataChanged();
      showCefToast(context, L.riderRemoved);
      app.back();
    } catch (e) {
      if (!context.mounted) return;
      final message = '$e'.contains('active work')
          ? L.riderHasActiveWorkCannotRemove
          : '$e';
      showCefToast(context, message, error: true);
    }
  }
}

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // Founder screen 6: Team is a view over riders (Drivers) and
    // business_members (Operators/Helpers); one tab per role.
    return AsyncView<
      (List<TeamMember>, List<Map<String, dynamic>>, List<RiderRow>)
    >(
      key: ValueKey('team-${app.business?.id}'),
      live: true,
      load: () async => (
        await app.repo.team(app.business!.id),
        await app.repo.pendingTeamRequests(app.business!.id),
        // Approved drivers only; pending ones stay on Drivers > Pending.
        (await app.repo.riders(app.business!.id))
            .where((r) => r.status != 'inactive' && !r.isPending)
            .toList(),
      ),
      builder: (context, data, reload) => ValueListenableBuilder<TeamTab>(
        valueListenable: teamTab,
        builder: (context, tab, _) {
          final (members, requests, drivers) = data;
          final q = _query.text.trim().toLowerCase();
          bool hit(String s) => q.isEmpty || s.toLowerCase().contains(q);
          final role = tab == TeamTab.helpers ? 'helper' : 'operator';
          final people = members
              .where((m) => m.role.toLowerCase() == role && hit(m.label))
              .toList();
          final roleRequests = requests
              .where((r) => (r['role'] ?? 'operator') == role)
              .toList();
          final shown = drivers.where((r) => hit(r.name)).toList();
          final labels = [L.teamDrivers, L.teamOperators, L.teamHelpers];
          return PageBody(
            onRefresh: reload,
            children: [
              SegmentedTabs(
                labels: labels,
                active: labels[tab.index],
                onChange: (l) =>
                    teamTab.value = TeamTab.values[labels.indexOf(l)],
              ),
              const SizedBox(height: Gap.md),
              CefSearchField(
                hint: L.searchTeamMembers,
                controller: _query,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Gap.md),
              if (tab == TeamTab.drivers)
                if (shown.isEmpty)
                  StateBlock.empty(L.noTeamDrivers)
                else
                  for (final r in shown)
                    CefListRow(
                      title: r.name,
                      subtitle: [
                        if (r.vehicleType != null)
                          vehicleTypeLabel(r.vehicleType!),
                        if (r.plate != null) r.plate!,
                      ].join(' · '),
                      leading: CefAvatar(r.name, filled: true),
                      trailing: StatusChip(L.active, success: true),
                      onTap: () => app.go(VRoute.riderDetail, entityId: r.id),
                    )
              else ...[
                // Invite-link joins wait here until the Owner decides.
                if (roleRequests.isNotEmpty) ...[
                  SectionHeading(L.joinRequests, icon: LucideIcons.userPlus),
                  for (final r in roleRequests)
                    TeamRequestRow(request: r, onDecided: reload),
                  const SizedBox(height: Gap.md),
                ],
                if (people.isEmpty)
                  StateBlock.empty(
                    tab == TeamTab.helpers
                        ? L.noTeamHelpers
                        : L.noTeamOperators,
                  )
                else
                  // Archetype D (people list): filled avatar, status pill.
                  for (final m in people)
                    CefListRow(
                      title: m.label,
                      subtitle: roleLabel(m.role),
                      leading: CefAvatar(m.label, filled: true),
                      trailing: StatusChip(L.active, success: true),
                      // Audit fix 2: bound to this member's id.
                      onTap: () =>
                          app.go(VRoute.teamMemberDetail, entityId: m.userId),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// V-24 — Team member detail (archetype E): identity and role on the
/// gradient, the shared Contact card, then email / role & access / account
/// status. The owner cannot be removed, so the action is not offered.
class TeamMemberDetailScreen extends StatelessWidget {
  const TeamMemberDetailScreen({super.key, required this.memberId});
  final String memberId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<TeamMember>(
      loading: const SkeletonHeroPage(),
      key: ValueKey('team-member-$memberId'),
      load: () async {
        final members = await app.repo.team(app.business!.id);
        return members.firstWhere(
          (m) => m.userId == memberId,
          orElse: () => throw StateError(L.teamMemberNotFound),
        );
      },
      builder: (context, member, reload) {
        final name = member.label;
        return HeroPage(
          onRefresh: reload,
          hero: DetailHero(
            leading: CefAvatar(name, size: 88),
            title: name,
            status: HeroStatusPill(L.active),
            lines: [HeroLine(roleLabel(member.role))],
          ),
          children: [
            ContactCard(phone: member.phone),
            CefListGroup(
              children: [
                CefListRow(
                  title: L.email,
                  subtitle: member.email ?? L.notProvided,
                  icon: LucideIcons.mail,
                ),
                CefListRow(
                  title: L.roleAccess,
                  subtitle:
                      '${roleLabel(member.role)} · ${_roleDescription(member.role)}',
                  subtitleMaxLines: 3,
                  icon: LucideIcons.shieldCheck,
                ),
                CefListRow(
                  title: L.accountStatus,
                  subtitle: L.activeTeamMemberCanAccessBusiness,
                  subtitleMaxLines: 2,
                  icon: LucideIcons.circleCheck,
                ),
              ],
            ),
            if (member.isOwner)
              Text(
                L.businessOwnerAlwaysKeepsFullAccess,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              )
            // Removal is Owner-only (enforced by update_team_member).
            else if (app.business?.isOwner == true)
              CefButton(
                L.removeMember,
                destructive: true,
                icon: LucideIcons.trash2,
                onTap: () => _confirmRemove(context, member),
              ),
          ],
        );
      },
    );
  }

  String _roleDescription(String role) => switch (role.toLowerCase()) {
    'owner' => L.fullAccessIncludingBillingSubscription,
    _ => L.canAccessDailyOperationsOrdersRiders,
  };

  /// Security & Access Master Part III §19/§23: typed CONFIRM, backend
  /// removal, then a fresh read-back before reporting success.
  Future<void> _confirmRemove(BuildContext context, TeamMember member) async {
    final confirmed = await showTypedConfirmDialog(
      context,
      title: L.removeMemberTitle(member.label),
      message: L.removeMemberBody(member.label),
      actionLabel: L.removeMember,
    );
    if (!confirmed || !context.mounted) return;
    final app = AppScope.read(context);
    final businessId = app.business!.id;
    try {
      await app.repo.removeTeamMember(businessId, member.userId);
      final stillMember = (await app.repo.team(businessId))
          .any((m) => m.userId == member.userId);
      if (!context.mounted) return;
      if (stillMember) {
        showCefToast(context, L.removalNotConfirmed, error: true);
        return;
      }
      app.dataChanged();
      showCefToast(context, L.memberRemoved);
      app.back();
    } catch (e) {
      if (context.mounted) showCefToast(context, '$e', error: true);
    }
  }
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<List<Product>>(
      key: ValueKey('products-${app.business?.id}'),
      load: () => app.repo.products(app.business!.id),
      builder: (context, products, reload) => PageBody(
        onRefresh: reload,
        children: [
          // Archetype B list: package disc, price · status.
          CefSearchField(hint: L.searchProducts),
          const SizedBox(height: Gap.md),
          if (products.isEmpty)
            StateBlock.empty(L.noProductsCatalogueYet)
          else
            for (final p in products)
              CefListRow(
                title: p.name,
                subtitle: p.displayPrice == null
                    ? p.status
                    : '${Money.format(p.displayPrice!)} · ${p.status}',
                icon: LucideIcons.package,
                onTap: () => app.go(VRoute.productDetail, entityId: p.id),
              ),
        ],
      ),
    );
  }
}

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<List<VendorOrder>>(
      key: ValueKey('customers-${app.business?.id}'),
      load: () => app.repo.orders(app.business!.id),
      builder: (context, orders, reload) {
        final customers = <String, VendorOrder>{};
        for (final order in orders) {
          customers.putIfAbsent(order.customerName, () => order);
        }
        return PageBody(
          onRefresh: reload,
          children: [
            // Archetype D (people list).
            CefSearchField(hint: L.searchCustomers),
            const SizedBox(height: Gap.md),
            for (final entry in customers.entries)
              CefListRow(
                title: entry.key,
                subtitle: entry.value.customerPhone,
                leading: CefAvatar(entry.key, filled: true),
                onTap: () => app.go(VRoute.customerDetail, entityId: entry.key),
              ),
          ],
        );
      },
    );
  }
}

/// X-06 — Customer detail (archetype E): identity on the gradient, the
/// shared Contact card, then this customer's orders. Customer-specific
/// information only -- no rider statistics.
class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerName});
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<List<VendorOrder>>(
      loading: const SkeletonHeroPage(),
      key: ValueKey('customer-$customerName'),
      load: () => app.repo.orders(app.business!.id),
      builder: (context, orders, reload) {
        final customerOrders = orders
            .where((order) => order.customerName == customerName)
            .toList();
        final customer = customerOrders.first;
        final count = customerOrders.length;
        return HeroPage(
          onRefresh: reload,
          hero: DetailHero(
            leading: CefAvatar(customerName, size: 88),
            title: customerName,
            lines: [
              HeroLine(L.customer),
              HeroLine(
                L.order(count, count == 1 ? '' : 's'),
                icon: LucideIcons.package,
              ),
            ],
          ),
          children: [
            ContactCard(phone: customer.customerPhone),
            SectionHeading(L.orders2(count)),
            // Cardless order rows (D-50).
            for (final order in customerOrders)
              CefListRow(
                title: order.reference,
                subtitle: order.deliveryAddress,
                icon: LucideIcons.package,
                trailing: DeliveryStatusChip(
                  order.status,
                  approved: order.isApproved,
                ),
                onTap: () => app.go(VRoute.orderDetail, entityId: order.id),
              ),
          ],
        );
      },
    );
  }
}

/// Native name of a supported UI language (never translated).
String languageName(Locale locale) => uiLanguageNames[locale.languageCode]!;

/// Language picker (English / Bahasa Melayu): choosing applies and closes.
void showLanguageSheet(BuildContext context) {
  final app = AppScope.read(context);
  showListSheet(
    context,
    title: L.language,
    children: [
      for (final locale in supportedUiLocales)
        CefListRow(
          title: languageName(locale),
          showChevron: false,
          trailing: app.uiLocale == locale
              ? Icon(
                  LucideIcons.check,
                  size: Sizes.icon,
                  color: CefColors.brand,
                )
              : null,
          onTap: () {
            app.setUiLocale(locale);
            Navigator.of(context).pop();
          },
        ),
    ],
  );
}

/// V-46 — More (D-54): the one settings hub, cardless on white. Account,
/// Business, Support as flat rows with light dividers, then Sign out and
/// the version.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final text = Theme.of(context).textTheme;
    Widget label(String title) => Padding(
      padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.xs),
      child: Text(title, style: text.labelMedium),
    );
    Widget row(String title, IconData icon, VRoute route, {Widget? trailing}) =>
        CefListRow(
          title: title,
          icon: icon,
          trailing: trailing,
          onTap: () => app.go(route),
        );
    return PageBody(
      children: [
        label(L.account),
        row(L.profile, LucideIcons.user, VRoute.editProfile),
        // Password opens Change Password directly (Founder, 2026-10-01).
        row(L.password, LucideIcons.lock, VRoute.changePassword),
        row(L.notifications, LucideIcons.bell, VRoute.notificationSettings),
        CefListRow(
          title: L.language,
          icon: LucideIcons.globe,
          trailing: Text(languageName(app.uiLocale), style: text.bodySmall),
          onTap: () => showLanguageSheet(context),
        ),
        row(L.appearance, LucideIcons.palette, VRoute.appearance),
        label(L.business),
        // D-74: business details and Team are Owner-only.
        if (app.business?.isOwner ?? true)
          row(
            L.businessProfile2,
            LucideIcons.building2,
            VRoute.businessProfile,
          ),
        row(L.storefront, LucideIcons.store, VRoute.storefront),
        row(L.products, LucideIcons.package, VRoute.products),
        row(L.integrations, LucideIcons.plug, VRoute.integrations),
        if (app.business?.isOwner ?? true)
          row(L.team, LucideIcons.users, VRoute.team),
        // M2: the Operator reaches Hiring here (Team is Owner-only).
        if (app.business?.role == 'operator')
          row(L.hiring, LucideIcons.userSearch, VRoute.hiring),
        // D-73: Subscription/Billing is Owner-only (presentation; the
        // server never grants billing authority from this).
        if (app.business?.isOwner ?? true)
          row(
            L.subscription,
            LucideIcons.creditCard,
            VRoute.subscription,
            // The plan chip once the plan is known (live: loaded from the
            // server on the Subscription screen; demo: the session plan).
            trailing: app.repo.isDemo || app.liveSubscription != null
                ? StatusChip(app.currentPlan.name, info: true)
                : null,
          ),
        label(L.support),
        row(L.helpSupport2, LucideIcons.circleHelp, VRoute.helpSupport),
        row(L.aboutCefflo, LucideIcons.info, VRoute.about),
        const SizedBox(height: Gap.sm),
        // Centred, and confirmed in a bottom sheet before signing out
        // (Founder, 2026-10-01); Yes returns to the sign-in screen.
        Center(
          child: TextButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: Icon(LucideIcons.logOut, color: c.attention),
            label: Text(
              L.signOut,
              style: text.titleSmall?.copyWith(color: c.attention),
            ),
          ),
        ),
        const SizedBox(height: Gap.sm),
        Center(child: AppVersionText(style: text.labelSmall, prefix: true)),
      ],
    );
  }
}

/// Bumped when a zone is created from the Create Zone pop-up, so the zone
/// lists (keyed on it) load again.
final ValueNotifier<int> zonesRevision = ValueNotifier(0);

/// Create Zone as a centred pop-up (Founder, 2026-09-30): the name only, no
/// map, the mustard primary action. Creates through the existing
/// create_zone RPC; the pop-up closes only after the server accepts.
Future<void> showCreateZoneDialog(BuildContext context) =>
    // Slides up from the bottom (Founder, 2026-10-01); lifts above the
    // keyboard while typing.
    showCefSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .35),
      builder: (_) => const _CreateZoneDialog(),
    );

class _CreateZoneDialog extends StatefulWidget {
  const _CreateZoneDialog();

  @override
  State<_CreateZoneDialog> createState() => _CreateZoneDialogState();
}

class _CreateZoneDialogState extends State<_CreateZoneDialog> {
  final _name = ZoneNameController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = L.zoneNameRequired);
      return;
    }
    final app = AppScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!app.repo.isDemo) {
        await app.repo.createZone(app.business!.id, name, place: _name.place);
      }
      if (!mounted) return;
      zonesRevision.value++;
      app.dataChanged();
      Navigator.of(context).pop();
      showCefToast(context, L.newZoneHasBeenCreatedSuccessfully);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: context.c.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Sizes.cardRadius + 6),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.xxl,
                Gap.xl,
                Gap.xxl,
                Gap.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    L.createZone,
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    L.nameAreaDeliver,
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: Gap.xl),
                  ZoneNameInput(
                    label: L.zoneName,
                    controller: _name,
                    hint: L.enterZoneName,
                    errorText: _error,
                    enabled: !_busy,
                  ),
                  const SizedBox(height: Gap.sm),
                  CefButton(L.createZone2, busy: _busy, onTap: _save),
                  const SizedBox(height: Gap.xs),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: Text(L.cancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pending rider decision through the existing canonical functions
/// (approve_pending_rider / deactivate_rider), then back to the list.
Future<void> _decideRider(
  BuildContext context,
  String riderId,
  bool approve,
) async {
  final app = AppScope.read(context);
  try {
    if (approve) {
      await app.repo.approvePendingRider(riderId);
    } else {
      await app.repo.rejectPendingRider(riderId);
    }
    if (!context.mounted) return;
    app.dataChanged();
    showCefToast(context, approve ? L.riderApproved : L.riderRejected);
    app.back();
  } catch (e) {
    if (context.mounted) showCefToast(context, '$e', error: true);
  }
}

class TeamRequestRow extends StatefulWidget {
  const TeamRequestRow({
    super.key,
    required this.request,
    required this.onDecided,
  });
  final Map<String, dynamic> request;
  final Future<void> Function() onDecided;

  @override
  State<TeamRequestRow> createState() => TeamRequestRowState();
}

class TeamRequestRowState extends State<TeamRequestRow> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final app = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await app.repo.decideTeamRequest(widget.request['id'] as String, approve);
      if (!mounted) return;
      showCefToast(context, approve ? L.requestApproved : L.requestRejected);
      await widget.onDecided();
    } catch (e) {
      if (mounted) showCefToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final name = (r['name'] ?? '') as String;
    final role = r['role'] == 'helper' ? L.helperText : L.operatorText;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CefListRow(
            title: name,
            subtitle: [
              role,
              if (r['phone'] != null) r['phone'] as String,
            ].join(' · '),
            leading: CefAvatar(name, filled: true),
            trailing: StatusChip(L.pending, warning: true),
            showChevron: false,
            showDivider: false,
          ),
          Row(
            children: [
              Expanded(
                child: CefButton(
                  L.reject,
                  secondary: true,
                  compact: true,
                  onTap: _busy ? null : () => _decide(false),
                ),
              ),
              const SizedBox(width: Gap.cardGap),
              Expanded(
                child: CefButton(
                  L.approveText,
                  busy: _busy,
                  compact: true,
                  onTap: () => _decide(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmSignOut(BuildContext context) async {
  final app = AppScope.read(context);
  final text = Theme.of(context).textTheme;
  final yes = await showCefSheet<bool>(
    context: context,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Sizes.cardRadius),
      ),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Gap.gutter,
          Gap.xl,
          Gap.gutter,
          Gap.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              L.signOutConfirmTitle,
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            const SizedBox(height: Gap.xs),
            Text(
              L.signOutConfirmBody,
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
            const SizedBox(height: Gap.xl),
            CefButton(
              L.yesSignOut,
              destructive: true,
              onTap: () => Navigator.of(sheet).pop(true),
            ),
            const SizedBox(height: Gap.sm),
            CefButton(
              L.cancel,
              secondary: true,
              onTap: () => Navigator.of(sheet).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  if (yes != true) return;
  await app.repo.signOut();
  app.clearSession();
}

/// Plan settings: which active drivers this plan may use, and Balance or
/// Fill. Applying re-requests the proposal; nothing is saved.
Future<void> _showPlanSettings(
  BuildContext context, {
  required List<RiderRow> riders,
  required Set<String>? selected,
  required String policy,
  required void Function(Set<String>? riderIds, String policy) onApply,
}) => showCefSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _PlanSettingsSheet(
    riders: riders,
    selected: selected,
    policy: policy,
    onApply: onApply,
  ),
);

class _PlanSettingsSheet extends StatefulWidget {
  const _PlanSettingsSheet({
    required this.riders,
    required this.selected,
    required this.policy,
    required this.onApply,
  });
  final List<RiderRow> riders;
  final Set<String>? selected;
  final String policy;
  final void Function(Set<String>? riderIds, String policy) onApply;

  @override
  State<_PlanSettingsSheet> createState() => _PlanSettingsSheetState();
}

class _PlanSettingsSheetState extends State<_PlanSettingsSheet> {
  late final Set<String> _picked = {
    ...(widget.selected ?? widget.riders.map((r) => r.id)),
  };
  late String _policy = widget.policy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final all = widget.riders.every((r) => _picked.contains(r.id));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Gap.gutter,
          Gap.xl,
          Gap.gutter,
          Gap.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(L.planDrivers, style: text.titleMedium),
            const SizedBox(height: Gap.sm),
            if (widget.riders.isEmpty)
              StateBlock.empty(L.noActiveRidersYet)
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in widget.riders)
                      CheckboxListTile(
                        value: _picked.contains(r.id),
                        title: Text(r.name),
                        subtitle: r.vehicleType == null
                            ? null
                            : Text(vehicleTypeLabel(r.vehicleType!)),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(
                          () => v == true
                              ? _picked.add(r.id)
                              : _picked.remove(r.id),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: Gap.md),
            Text(L.planSplit, style: text.titleSmall),
            RadioGroup<String>(
              groupValue: _policy,
              onChanged: (v) => setState(() => _policy = v ?? _policy),
              child: Column(
                children: [
                  for (final (value, label) in [
                    ('balance', L.planBalance),
                    ('fill', L.planFill),
                  ])
                    RadioListTile<String>(
                      value: value,
                      title: Text(label),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            Text(L.planPolicyHint, style: text.bodySmall),
            const SizedBox(height: Gap.md),
            if (_picked.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Text(L.planPickDriver, style: text.bodySmall),
              ),
            CefButton(
              L.planApply,
              onTap: _picked.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onApply(all ? null : {..._picked}, _policy);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// Orders that need a zone before they can be planned: approved
/// (`approved_at`, the same field propose_delivery_plan uses), still
/// `created` (so not delivered, and in the state where Order detail lets the
/// Vendor set a zone), no driver, and no zone. The Zones count and the list
/// both use this one predicate.
List<VendorOrder> unzonedOrders(Iterable<VendorOrder> orders) => [
  for (final o in orders)
    if (o.isApproved &&
        o.status == DeliveryStatus.created &&
        o.assignedRiderId == null &&
        o.zoneId == null)
      o,
];

/// Lists the unzoned orders; each opens Order detail, where the existing
/// zone selector assigns one.
Future<void> _showUnzonedOrders(
  BuildContext context,
  List<VendorOrder> orders,
) => showCefSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheet) {
    final text = Theme.of(sheet).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Gap.gutter,
          Gap.xl,
          Gap.gutter,
          Gap.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(L.noZoneCount(orders.length), style: text.titleMedium),
            const SizedBox(height: Gap.xs),
            Text(L.noZoneHint, style: text.bodyMedium),
            const SizedBox(height: Gap.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in orders)
                    CefListRow(
                      title: o.reference,
                      subtitle: '${o.customerName} · ${o.deliveryAddress}',
                      icon: LucideIcons.package,
                      onTap: () {
                        Navigator.of(sheet).pop();
                        AppScope.read(context)
                            .go(VRoute.orderDetail, entityId: o.id);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);

/// Zone name text plus the town the vendor picked from the suggestions
/// (null when they typed a name of their own).
class ZoneNameController extends TextEditingController {
  ZoneNameController({super.text});
  AreaSuggestion? place;
  String? _pickedLabel;

  void pick(AreaSuggestion a) {
    place = a;
    _pickedLabel = a.label;
    text = a.label;
    selection = TextSelection.collapsed(offset: a.label.length);
  }

  @override
  set value(TextEditingValue v) {
    if (_pickedLabel != null && v.text != _pickedLabel) {
      place = null;
      _pickedLabel = null;
    }
    super.value = v;
  }
}

/// Zone name field that suggests official areas as you type
/// (Founder 2026-10-13: "se" -> Seremban, Negeri Sembilan).
class ZoneNameInput extends StatefulWidget {
  const ZoneNameInput({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
  });
  final ZoneNameController controller;
  final String? label, hint, errorText;
  final bool enabled;

  @override
  State<ZoneNameInput> createState() => _ZoneNameInputState();
}

class _ZoneNameInputState extends State<ZoneNameInput> {
  Timer? _debounce;
  List<AreaSuggestion> _options = const [];
  int _seq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String q) {
    _debounce?.cancel();
    if (widget.controller.place != null || q.trim().length < 2) {
      if (_options.isNotEmpty) setState(() => _options = const []);
      return;
    }
    final seq = ++_seq;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final found = await AppScope.read(context).repo.searchAreas(q);
      if (mounted && seq == _seq) setState(() => _options = found);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CefField(
          label: widget.label,
          controller: widget.controller,
          hint: widget.hint,
          prefixIcon: LucideIcons.mapPin,
          errorText: widget.errorText,
          enabled: widget.enabled,
          onChanged: _changed,
        ),
        if (_options.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: Gap.md),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(Sizes.cardRadius),
              border: Border.all(color: c.border),
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final a in _options)
                  InkWell(
                    onTap: () {
                      widget.controller.pick(a);
                      setState(() => _options = const []);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gap.lg,
                        vertical: Gap.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 18,
                            color: c.textSecondary,
                          ),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.label, style: text.bodyLarge),
                                if (a.state != null)
                                  Text(a.state!, style: text.bodySmall),
                              ],
                            ),
                          ),
                        ],
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
