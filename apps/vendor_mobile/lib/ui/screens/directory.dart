import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../async_view.dart';
import '../shell.dart';
import '../widgets.dart';
import 'review_parts.dart';

/// Presentation-only: canonical values stay lowercase ('active', 'van'); this
/// only affects how they are displayed.
String _titleCase(String value) => value
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});
  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  String tab = 'All';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return const PageBody(
        children: [StateBlock.empty('No business linked.')],
      );
    }
    return AsyncView<(List<Zone>, List<VendorOrder>)>(
      key: ValueKey('zones-${business.id}'),
      load: () async => (
        await app.repo.zones(business.id),
        await app.repo.orders(business.id),
      ),
      builder: (context, data, reload) {
        final (zones, orders) = data;
        final tabLabels = const ['All', 'Active', 'Inactive'];
        // Plain alphabetical by name, per the locked reference screen --
        // not grouped by status (which previously pushed inactive zones
        // to the bottom regardless of name).
        final sortedZones = [...zones]
          ..sort((a, b) => a.name.compareTo(b.name));
        return PageBody(
          onRefresh: reload,
          children: [
            SegmentedTabs(
              labels: tabLabels,
              active: tab,
              onChange: (l) => setState(() => tab = l),
            ),
            const SizedBox(height: Gap.md),
            if (zones.isEmpty)
              const StateBlock.empty(
                'No zones configured yet. Create one under Menu → Service area.',
              )
            else
              for (final z in sortedZones)
                Builder(
                  builder: (context) {
                    // Counts derive from the same scoped orders read.
                    final inZone = orders
                        .where((o) => o.zoneId == z.id)
                        .toList();
                    if (tab == 'Active' && !z.isActive) {
                      return const SizedBox.shrink();
                    }
                    if (tab == 'Inactive' && z.isActive) {
                      return const SizedBox.shrink();
                    }
                    return FlatListRow(
                      title: z.name,
                      subtitle: '${inZone.length} orders',
                      leading: IconBadge(
                        LucideIcons.mapPin,
                        color: context.c.info,
                        background: const Color(0xFFE3EEFF),
                      ),
                      trailing: StatusChip(
                        z.isActive ? 'Active' : 'Inactive',
                        tinted: true,
                        muted: !z.isActive,
                      ),
                      // Audit fix 2: bound to this zone's id.
                      onTap: () => app.go(VRoute.zoneDetail, entityId: z.id),
                    );
                  },
                ),
          ],
        );
      },
    );
  }
}

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
      return const PageBody(
        children: [StateBlock.empty('No business linked.')],
      );
    }
    return AsyncView<List<Zone>>(
      key: ValueKey('zone-configuration-${business.id}'),
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
                    color: context.c.info,
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Text(
                      'These zones define where you deliver. Add, edit or '
                      'deactivate zones anytime.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.md),
            TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search zones...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: context.c.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Sizes.inputRadius),
                  borderSide: BorderSide(color: context.c.border),
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              const StateBlock.empty('No zones configured yet.')
            else
              for (final z in visible)
                FlatListRow(
                  title: z.name,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: CefColors.navy,
                    child: Text(
                      z.name.isEmpty ? '?' : z.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  trailing: StatusChip(
                    z.isActive ? 'Active' : 'Inactive',
                    success: z.isActive,
                  ),
                  onTap: () => app.go(VRoute.editZone, entityId: z.id),
                ),
          ],
        );
      },
    );
  }
}

class ZoneDetailScreen extends StatelessWidget {
  const ZoneDetailScreen({super.key, required this.zoneId});
  final String zoneId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business!;
    return AsyncView<(Zone, List<VendorOrder>)>(
      key: ValueKey('zone-$zoneId'),
      load: () async {
        final zones = await app.repo.zones(business.id);
        final zone = zones.firstWhere(
          (z) => z.id == zoneId,
          orElse: () => throw StateError('Zone not found'),
        );
        final orders = await app.repo.orders(business.id);
        return (zone, orders.where((o) => o.zoneId == zoneId).toList());
      },
      builder: (context, data, reload) {
        final (zone, orders) = data;
        final ready = orders
            .where((o) => o.status == DeliveryStatus.readyForPickup)
            .length;
        final active = orders
            .where((o) => OrderTab.ongoing.accepts(o.status))
            .length;
        final delivered = orders
            .where((o) => o.status == DeliveryStatus.delivered)
            .length;
        return PageBody(
          onRefresh: reload,
          children: [
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Sizes.cardRadius),
                child: CustomPaint(
                  painter: _CoverageMapPainter(),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF075BC7),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            zone.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Icon(
                          LucideIcons.mapPin,
                          color: Color(0xFF075BC7),
                          size: 34,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    zone.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconAction(
                  icon: LucideIcons.squarePen,
                  tooltip: 'Edit zone',
                  onTap: () => app.go(VRoute.editZone, entityId: zone.id),
                ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            StatusChip(
              zone.isActive ? 'Active' : 'Inactive',
              success: zone.isActive,
            ),
            const SectionHeading('Operational status'),
            NavySummaryPanel(
              title: 'Zone activity',
              children: [
                SummaryMetric(label: 'Total', value: '${orders.length}'),
                SummaryMetric(label: 'Ready', value: '$ready'),
                SummaryMetric(label: 'Active', value: '$active'),
                SummaryMetric(label: 'Delivered', value: '$delivered'),
              ],
            ),
            const SectionHeading('Orders'),
            if (orders.isEmpty)
              const StateBlock.empty('No orders are assigned to this zone.')
            else
              for (final o in orders)
                FlatListRow(
                  title: o.reference,
                  subtitle: '${o.customerName} · ${o.deliveryAddress}',
                  trailing: StatusChip(
                    o.status.label,
                    attention: o.status == DeliveryStatus.issue,
                    success: OrderTab.ongoing.accepts(o.status),
                  ),
                  onTap: () => app.go(VRoute.orderDetail, entityId: o.id),
                ),
            const SizedBox(height: Gap.section),
            CefButton(
              'Review & dispatch',
              onTap: () => app.go(VRoute.reviewDispatch, entityId: zoneId),
            ),
          ],
        );
      },
    );
  }
}

/// V-29 / V-30 — Create/Edit zone, bound to a real zone name and the
/// canonical create/status contracts instead of a generic Name/Phone/Email
/// stand-in. Coverage geometry itself stays server-owned: this only names
/// the zone and previews it, it never draws or computes a boundary.
class ZoneFormScreen extends StatefulWidget {
  const ZoneFormScreen({super.key, this.zoneId});
  final String? zoneId;
  bool get isNew => zoneId == null;

  @override
  State<ZoneFormScreen> createState() => _ZoneFormScreenState();
}

class _ZoneFormScreenState extends State<ZoneFormScreen> {
  final name = TextEditingController();
  bool active = true;
  bool loading = false;
  bool busy = false;
  String? error;
  final errors = <String, String>{};

  @override
  void initState() {
    super.initState();
    if (!widget.isNew) _prefill();
  }

  Future<void> _prefill() async {
    setState(() => loading = true);
    try {
      final app = AppScope.read(context);
      final zones = await app.repo.zones(app.business!.id);
      final z = zones.firstWhere((z) => z.id == widget.zoneId);
      name.text = z.name;
      active = z.isActive;
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    errors.clear();
    if (name.text.trim().isEmpty) errors['name'] = 'Zone name is required.';
    setState(() {});
    if (errors.isNotEmpty) return;

    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      final ok = await runAsyncFeedback(
        context,
        action: () async {},
        processingTitle: 'Processing...',
        processingSubtitle: widget.isNew
            ? 'Creating your zone'
            : 'Saving your changes',
        successTitle: 'Successful',
        successSubtitle: widget.isNew
            ? 'Your new zone has been created successfully.'
            : 'Your zone has been updated successfully.',
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
      if (widget.isNew) {
        await app.repo.createZone(app.business!.id, name.text.trim());
      } else {
        await app.repo.setZoneStatus(
          widget.zoneId!,
          active ? 'active' : 'inactive',
        );
      }
      if (!mounted) return;
      app.back();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this zone?'),
        content: const Text(
          'Orders already assigned to this zone are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) AppScope.read(context).back();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const StateBlock.loading();
    return PageBody(
      children: [
        SizedBox(
          height: 170,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            child: CustomPaint(
              painter: _CoverageMapPainter(),
              child: const Center(
                child: Icon(
                  LucideIcons.mapPin,
                  color: Color(0xFF075BC7),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Gap.md),
        CefField(
          label: 'Zone name',
          controller: name,
          errorText: errors['name'],
        ),
        if (widget.isNew) ...[
          const SizedBox(height: Gap.sm),
          CefCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: Sizes.icon, color: context.c.info),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Text(
                    'This zone will cover the highlighted area on the map. '
                    'You can always edit it later.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!widget.isNew)
          CefCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'Orders can be assigned to this zone',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                CefSwitch(
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),
              ],
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              error!,
              style: TextStyle(color: context.c.attention, fontSize: 13),
            ),
          ),
        const SizedBox(height: Gap.section),
        if (widget.isNew)
          CefButton('Create Zone', busy: busy, onTap: _save)
        else
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.c.attention,
                      side: BorderSide(color: context.c.attention),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                      ),
                    ),
                    child: const Text('Delete Zone'),
                  ),
                ),
              ),
              const SizedBox(width: Gap.cardGap),
              Expanded(
                child: CefButton('Save Changes', busy: busy, onTap: _save),
              ),
            ],
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
  String tab = 'All';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return const PageBody(
        children: [StateBlock.empty('No business linked.')],
      );
    }
    return AsyncView<List<RiderRow>>(
      key: ValueKey('riders-${business.id}'),
      load: () => app.repo.riders(business.id),
      builder: (context, riders, reload) {
        // Exactly the 3 tabs shown in the locked reference screen -- the
        // "Offline" filter previously here was removed to match strictly.
        final visible = switch (tab) {
          'Active' => riders.where((r) => r.isActive).toList(),
          'Pending' => riders.where((r) => r.status == 'pending').toList(),
          _ => riders,
        };
        // Count suffixes per tab label, per the locked reference screen
        // ("All (4) / Active (3) / Pending (1)").
        const tabs = ['All', 'Active', 'Pending'];
        final tabLabels = tabs
            .map((t) {
              final count = switch (t) {
                'Active' => riders.where((r) => r.isActive).length,
                'Pending' => riders.where((r) => r.status == 'pending').length,
                _ => riders.length,
              };
              return '$t ($count)';
            })
            .toList();
        return PageBody(
          onRefresh: reload,
          children: [
            SegmentedTabs(
              labels: tabLabels,
              active: tabLabels[tabs.indexOf(tab)],
              onChange: (l) => setState(() => tab = l.split(' (').first),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              const StateBlock.empty('No riders yet.')
            else
              for (final r in visible)
                FlatListRow(
                  title: r.name,
                  subtitle: [
                    if (r.vehicleType != null) _titleCase(r.vehicleType!),
                    if (r.plate != null) r.plate!,
                  ].join(' · '),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: CefColors.navy,
                    child: Text(
                      r.name.split(' ').take(2).map((part) => part[0]).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Neutral pill (not semantic-green) per the reference,
                  // labelled with the rider's actual status so "Pending"
                  // reads correctly instead of collapsing to "Offline".
                  trailing: StatusChip(_titleCase(r.status), tinted: true),
                  // Audit fix 2: bound to this rider's id.
                  onTap: () => app.go(VRoute.riderDetail, entityId: r.id),
                ),
          ],
        );
      },
    );
  }
}

/// V-21 — Rider detail. `RiderRow` only carries id/name/status/phone/
/// vehicleType/plate/maxActiveOrders(/joinedLabel), so this shows what is
/// real (no invented licence documents, date of birth, address or
/// emergency contact -- unlike the reference board, which shows fields
/// this backend does not track).
///
/// Owns its full chrome (see `_ownChromeRoutes` in shell.dart): the locked
/// reference screen's gradient extends down to contain the avatar/name/
/// status/stats block itself, which only this screen -- not the shared
/// shell -- has the loaded rider to build. See `TallProfileHeader`.
class RiderDetailScreen extends StatelessWidget {
  const RiderDetailScreen({super.key, required this.riderId});
  final String riderId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    return AsyncView<RiderRow>(
      key: ValueKey('rider-$riderId'),
      load: () async {
        final riders = await app.repo.riders(app.business!.id);
        return riders.firstWhere(
          (r) => r.id == riderId,
          orElse: () => throw StateError('Rider not found'),
        );
      },
      builder: (context, rider, reload) {
        final pending = rider.status == 'pending';
        return PageBody(
          onRefresh: reload,
          header: TallProfileHeader(
            title: 'Rider Detail',
            name: rider.name,
            status: pending
                ? 'Pending Review'
                : rider.isActive
                ? 'Active'
                : 'Offline',
            // Per Founder direction: this whole app is demo/prototype data
            // already, so the reference's rider code ("Rider · RID-004")
            // is shown exactly rather than dropped.
            subtitle: [
              pending ? 'Rider Applicant' : 'Rider',
              if (rider.riderCode != null) rider.riderCode!,
            ].join(' · '),
            pending: pending,
            onBack: app.back,
            onMenu: () => _notWiredYet(context, 'Rider options'),
            stats: [
              (
                LucideIcons.barChart2,
                rider.maxActiveOrders == null ? '—' : '${rider.maxActiveOrders}',
                'Max orders',
              ),
              (
                LucideIcons.car,
                rider.vehicleType == null
                    ? 'Not set'
                    : _titleCase(rider.vehicleType!),
                rider.plate ?? '—',
              ),
              (LucideIcons.calendar, rider.joinedLabel ?? '—', 'Joined'),
            ],
          ),
          children: [
            FlatListRow(
              title: 'Contact',
              subtitle: rider.phone ?? 'Not provided',
              leading: Icon(LucideIcons.phone, size: 22, color: c.info),
              onTap: () => _notWiredYet(context, 'Editing rider contact'),
            ),
            FlatListRow(
              title: 'Vehicle',
              subtitle: rider.vehicleType == null
                  ? 'Not provided'
                  : [
                      _titleCase(rider.vehicleType!),
                      if (rider.plate != null) rider.plate!,
                    ].join(' · '),
              leading: Icon(LucideIcons.car, size: 22, color: c.info),
              onTap: () => _notWiredYet(context, 'Editing rider vehicle'),
            ),
            FlatListRow(
              title: 'Driving Licence',
              subtitle: 'No document',
              leading: Icon(LucideIcons.fileText, size: 22, color: c.info),
              onTap: () => _notWiredYet(context, 'Driving licence upload'),
            ),
            FlatListRow(
              title: 'Additional Information',
              subtitle: 'No additional information',
              leading: Icon(LucideIcons.fileEdit, size: 22, color: c.info),
              onTap: () => _notWiredYet(context, 'Additional information'),
            ),
            const SizedBox(height: Gap.sm),
            if (pending)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () =>
                            _notWiredYet(context, 'Rejecting riders'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.c.textPrimary,
                          side: BorderSide(color: context.c.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Sizes.buttonRadius,
                            ),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.cardGap),
                  Expanded(
                    child: CefButton(
                      'Approve Rider',
                      onTap: () => _notWiredYet(context, 'Approving riders'),
                    ),
                  ),
                ],
              )
            else
              Material(
                color: const Color(0xFFE3EEFF),
                borderRadius: BorderRadius.circular(Sizes.cardRadius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Sizes.cardRadius),
                  onTap: () => _notWiredYet(context, 'Managing riders'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gap.cardPadding,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.settings, size: 20, color: c.info),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Text(
                            'Manage Rider',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.info,
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: c.info,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _notWiredYet(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action is not wired to a backend action yet.')),
    );
  }
}

String _initialsOf(String name) => name
    .split(' ')
    .where((p) => p.isNotEmpty)
    .take(2)
    .map((p) => p[0])
    .join()
    .toUpperCase();

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
    return AsyncView<List<TeamMember>>(
      key: ValueKey('team-${app.business?.id}'),
      load: () => app.repo.team(app.business!.id),
      builder: (context, members, reload) {
        final q = _query.text.trim().toLowerCase();
        final visible = q.isEmpty
            ? members
            : members
                  .where(
                    (m) =>
                        (m.displayName ?? m.userId).toLowerCase().contains(q),
                  )
                  .toList();
        return PageBody(
          onRefresh: reload,
          children: [
            const Text(
              'Team',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF091A3C),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage who can access your business.',
              style: TextStyle(fontSize: 13, color: Color(0xFF858BA3)),
            ),
            const SizedBox(height: 24),
            SectionHeading(
              '${members.length} Member${members.length == 1 ? '' : 's'}',
              trailing: IconAction(
                icon: LucideIcons.userPlus,
                tooltip: 'Invite team member',
                onTap: () => app.go(VRoute.helperRegistrationLink),
              ),
            ),
            TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search team members...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: context.c.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Sizes.inputRadius),
                  borderSide: BorderSide(color: context.c.border),
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              const StateBlock.empty('No team members yet.')
            else
              for (final m in visible)
                FlatListRow(
                  title: m.displayName ?? m.userId,
                  subtitle: m.role,
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: CefColors.navy,
                    child: Text(
                      _initialsOf(m.displayName ?? m.userId),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  trailing: const StatusChip('Active', success: true),
                  // Audit fix 2: bound to this member's id.
                  onTap: () =>
                      app.go(VRoute.teamMemberDetail, entityId: m.userId),
                ),
          ],
        );
      },
    );
  }
}

/// V-24 — Team member detail. `TeamMember` only carries id/role/display
/// name, so this shows what is real rather than inventing contact fields
/// the backend does not track.
class TeamMemberDetailScreen extends StatelessWidget {
  const TeamMemberDetailScreen({super.key, required this.memberId});
  final String memberId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<TeamMember>(
      key: ValueKey('team-member-$memberId'),
      load: () async {
        final members = await app.repo.team(app.business!.id);
        return members.firstWhere(
          (m) => m.userId == memberId,
          orElse: () => throw StateError('Team member not found'),
        );
      },
      builder: (context, member, reload) {
        final c = context.c;
        const badgeBg = Color(0xFFE3EEFF);
        Widget contactRow({
          required IconData icon,
          required String label,
          required String value,
        }) => FlatListRow(
          title: label,
          subtitle: value,
          leading: IconBadge(icon, color: c.info, background: badgeBg),
          trailing: GestureDetector(
            onTap: () => showNotWiredYetSnackBar(context, 'Adding $label'),
            child: Text(
              'Add',
              style: TextStyle(color: c.info, fontWeight: FontWeight.w600),
            ),
          ),
        );
        Widget kvRow({
          required IconData icon,
          required Color iconBg,
          required String label,
          required String value,
          required String description,
        }) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconBadge(icon, color: c.info, background: iconBg),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );

        return PageBody(
          onRefresh: reload,
          header: TallProfileHeader(
            title: 'Team Member',
            name: member.displayName ?? member.userId,
            status: 'Active',
            subtitle: member.role,
            centered: true,
            showAvatarStatusDot: true,
            onBack: app.back,
            onMenu: () =>
                showNotWiredYetSnackBar(context, 'Team member options'),
          ),
          children: [
            SectionHeading(
              'Contact',
              trailing: GestureDetector(
                onTap: () => showNotWiredYetSnackBar(context, 'Editing contact'),
                child: Text(
                  'Edit',
                  style: TextStyle(color: c.info, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            contactRow(
              icon: LucideIcons.phone,
              label: 'Phone',
              value: 'Not provided',
            ),
            contactRow(
              icon: LucideIcons.mail,
              label: 'Email',
              value: 'Not provided',
            ),
            const SectionHeading('Role & Access'),
            kvRow(
              icon: LucideIcons.shield,
              iconBg: badgeBg,
              label: 'Role',
              value: member.role,
              description: _roleDescription(member.role),
            ),
            const SectionHeading('Status'),
            kvRow(
              icon: LucideIcons.checkCircle2,
              iconBg: const Color(0xFFDCF5E4),
              label: 'Account Status',
              value: 'Active',
              description:
                  'This team member can currently access your business.',
            ),
            const SizedBox(height: Gap.md),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _confirmRemove(context, member),
                icon: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: context.c.attention,
                ),
                label: const Text('Remove from Team'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: context.c.attention,
                  side: BorderSide(color: context.c.attention),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _roleDescription(String role) => switch (role.toLowerCase()) {
    'owner' =>
      'Full access to every part of the business, including billing and '
          'subscription.',
    'admin' =>
      'Can manage daily operations, orders, riders and team members. '
          'Cannot manage billing or subscription.',
    _ =>
      'Can access daily operations, orders and riders. Cannot manage '
          'billing or subscription.',
  };

  Future<void> _confirmRemove(BuildContext context, TeamMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.displayName ?? member.userId}?'),
        content: const Text(
          'They will lose access to this business immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) AppScope.read(context).back();
  }
}

class _CoverageMapPainter extends CustomPainter {
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
        Offset(0, i * 48.0),
        Offset(size.width, i * 48.0 + 110),
        roads,
      );
      canvas.drawLine(
        Offset(i * 58.0, 0),
        Offset(i * 58.0 - 70, size.height),
        roads,
      );
    }
    final area = Path()
      ..moveTo(size.width * .25, size.height * .35)
      ..lineTo(size.width * .48, size.height * .16)
      ..lineTo(size.width * .73, size.height * .32)
      ..lineTo(size.width * .78, size.height * .68)
      ..lineTo(size.width * .48, size.height * .82)
      ..lineTo(size.width * .22, size.height * .60)
      ..close();
    canvas.drawPath(area, Paint()..color = const Color(0x332A6EEC));
    canvas.drawPath(
      area,
      Paint()
        ..color = const Color(0xFF2A6EEC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          const SearchBarField(hint: 'Search products...'),
          const SizedBox(height: Gap.md),
          if (products.isEmpty)
            const StateBlock.empty('No products in the catalogue yet.')
          else
            for (final p in products)
              CefListRow(
                title: p.name,
                subtitle: p.displayPrice == null
                    ? p.status
                    : 'RM ${p.displayPrice!.toStringAsFixed(2)} · ${p.status}',
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
            const SearchBarField(hint: 'Search customers...'),
            const SizedBox(height: Gap.md),
            for (final entry in customers.entries)
              FlatListRow(
                title: entry.key,
                subtitle: entry.value.customerPhone,
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF0F3F8),
                  child: Text(
                    entry.key
                        .split(' ')
                        .where((part) => part.isNotEmpty)
                        .take(2)
                        .map((part) => part[0])
                        .join(),
                    style: const TextStyle(
                      color: CefColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: () => app.go(VRoute.customerDetail, entityId: entry.key),
              ),
          ],
        );
      },
    );
  }
}

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerName});
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<List<VendorOrder>>(
      key: ValueKey('customer-$customerName'),
      load: () => app.repo.orders(app.business!.id),
      builder: (context, orders, reload) {
        final customerOrders = orders
            .where((order) => order.customerName == customerName)
            .toList();
        final customer = customerOrders.first;
        return PageBody(
          onRefresh: reload,
          children: [
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: CefColors.navy,
                child: Text(
                  customerName.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
            Center(
              child: Text(
                customerName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Center(
              child: Text(
                customer.customerPhone,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SectionHeading('Orders'),
            for (final order in customerOrders)
              FlatListRow(
                title: order.reference,
                subtitle: order.deliveryAddress,
                trailing: StatusChip(
                  order.status.label,
                  attention: order.status == DeliveryStatus.issue,
                  success: OrderTab.ongoing.accepts(order.status),
                ),
                onTap: () => app.go(VRoute.orderDetail, entityId: order.id),
              ),
          ],
        );
      },
    );
  }
}

/// V-46 — the Menu tab root.
///
/// Trimmed to the 8 rows the locked reference screen shows (strict 1:1 per
/// Founder direction). `VRoute.serviceArea`, `VRoute.privacyPolicy` and
/// `VRoute.appearance` lost their only in-app entry point when their rows
/// were removed -- their screens/routes still exist and are still wired in
/// `router.dart`/`routes.dart`, just unreachable via navigation now. Flagged
/// rather than silently orphaned; re-adding an entry point for them (if
/// wanted) is a separate decision from this visual pass.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    // Local, lighter-weight section label matching the reference Settings
    // screen ("Business"/"Account") -- distinct from the bolder shared
    // SectionHeading used for page-level headings elsewhere in the app.
    Widget group(String title, List<(String, IconData, VRoute)> items) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: Gap.md, bottom: Gap.sm),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
            ),
            for (final i in items)
              CefListRow(title: i.$1, icon: i.$2, onTap: () => app.go(i.$3)),
          ],
        );

    return PageBody(
      children: [
        // Trimmed to exactly the 8 rows (4+4, in this order) shown in the
        // locked reference screen -- strict 1:1 per Founder direction.
        // Business profile/Service area/Privacy/Language/Appearance rows
        // were removed from this list; see the class-level orphan note
        // below for which of those routes lost their only entry point.
        group('Business', [
          ('Storefront', LucideIcons.store, VRoute.storefront),
          ('Products', LucideIcons.boxes, VRoute.products),
          ('Team', LucideIcons.users, VRoute.team),
          ('Customers', LucideIcons.users, VRoute.customers),
        ]),
        group('Account', [
          ('Profile', LucideIcons.user, VRoute.profile),
          ('Security', LucideIcons.shieldCheck, VRoute.security),
          ('Notifications', LucideIcons.bell, VRoute.notificationSettings),
          ('Help & Support', LucideIcons.circleHelp, VRoute.helpSupport),
        ]),
        const SizedBox(height: Gap.section),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () async {
              await app.repo.signOut();
              app.clearSession();
            },
            icon: Icon(
              LucideIcons.logOut,
              size: 18,
              color: context.c.attention,
            ),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.c.attention,
              side: BorderSide(color: context.c.attention),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Sizes.buttonRadius),
              ),
            ),
          ),
        ),
        const SizedBox(height: Gap.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => app.go(VRoute.helpSupport),
              child: Text(
                'Help & Support',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('|', style: Theme.of(context).textTheme.bodySmall),
            ),
            GestureDetector(
              onTap: () => app.go(VRoute.about),
              child: Text(
                'About Cefflo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
