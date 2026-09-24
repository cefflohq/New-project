import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../async_view.dart';
import '../shell.dart';
import '../widgets.dart';

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
                'No zones configured yet. Create one under Settings → Service area.',
              )
            else
              for (final z in zones)
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
                    return CefListRow(
                      title: z.name,
                      subtitle:
                          '${inZone.length} order${inZone.length == 1 ? '' : 's'}',
                      icon: LucideIcons.mapPin,
                      trailing: StatusChip(
                        z.isActive ? 'Active' : 'Inactive',
                        success: z.isActive,
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
                    color: context.c.iconColor,
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
            CefSearchField(
              hint: 'Search zones...',
              controller: _query,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              const StateBlock.empty('No zones configured yet.')
            else
              // Archetype C (zones list): accent map-pin disc, status pill.
              for (final z in visible)
                CefListRow(
                  title: z.name,
                  icon: LucideIcons.mapPin,
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

/// V-17 — Delivery plan. An operational screen, not a map screen: what zone
/// this is, where, what is happening in it today, which orders belong to it,
/// and the dispatch action (pinned so it never falls below the fold).
class ZoneDetailScreen extends StatelessWidget {
  const ZoneDetailScreen({super.key, required this.zoneId});
  final String zoneId;

  /// Rows shown before "View all"; the rest open in a sheet.
  static const _previewRows = 4;

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
        final c = context.c;
        final text = Theme.of(context).textTheme;
        final ready = orders
            .where((o) => o.status == DeliveryStatus.readyForPickup)
            .length;
        final active = orders
            .where((o) => OrderTab.ongoing.accepts(o.status))
            .length;
        final delivered = orders
            .where((o) => o.status == DeliveryStatus.delivered)
            .length;
        Widget orderRow(VendorOrder o, {VoidCallback? before}) => CefListRow(
          title: o.reference,
          subtitle: o.customerName,
          icon: LucideIcons.package,
          trailing: DeliveryStatusChip(o.status),
          onTap: () {
            before?.call();
            app.go(VRoute.orderDetail, entityId: o.id);
          },
        );
        return PageBody(
          onRefresh: reload,
          bottom: CefButton(
            'Review & dispatch (${orders.length})',
            icon: LucideIcons.send,
            onTap: () => app.go(VRoute.reviewDispatch, entityId: zoneId),
          ),
          children: [
            _ZoneMap(name: zone.name),
            const SizedBox(height: Gap.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            zone.isActive ? 'Active' : 'Inactive',
                            success: zone.isActive,
                          ),
                        ],
                      ),
                      if (zone.locality != null) ...[
                        const SizedBox(height: 2),
                        Text(zone.locality!, style: text.bodySmall),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Gap.sm),
                CefButton(
                  'Edit zone',
                  secondary: true,
                  compact: true,
                  icon: LucideIcons.squarePen,
                  onTap: () => app.go(VRoute.editZone, entityId: zone.id),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            // Operational status: one tinted panel, today's figures only.
            Container(
              padding: const EdgeInsets.fromLTRB(
                Gap.lg,
                Gap.md,
                Gap.lg,
                Gap.xs,
              ),
              decoration: BoxDecoration(
                color: c.grouped,
                borderRadius: BorderRadius.circular(Sizes.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Operational status',
                          style: text.titleSmall,
                        ),
                      ),
                      Text('Today', style: text.bodySmall),
                    ],
                  ),
                  KpiStrip(
                    items: [
                      KpiItem('${orders.length}', 'Total'),
                      KpiItem('$ready', 'Ready', color: c.success),
                      KpiItem('$active', 'Active', color: CefColors.brand),
                      KpiItem(
                        '$delivered',
                        'Delivered',
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SectionHeading(
              'Orders (${orders.length})',
              trailing: orders.length > _previewRows
                  ? CefLink(
                      'View all',
                      chevron: true,
                      onTap: () => showListSheet(
                        context,
                        title: '${zone.name} orders (${orders.length})',
                        children: [
                          for (final o in orders)
                            orderRow(
                              o,
                              before: () => Navigator.of(context).pop(),
                            ),
                        ],
                      ),
                    )
                  : null,
            ),
            if (orders.isEmpty)
              const StateBlock.empty('No orders are assigned to this zone.')
            else
              CefListGroup(
                children: [
                  for (final o in orders.take(_previewRows)) orderRow(o),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Compact zone map preview: the illustrative coverage polygon with the
/// zone's name pill and pin. Kept short so the operational content below
/// stays in view.
class _ZoneMap extends StatelessWidget {
  const _ZoneMap({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 180,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      child: CustomPaint(
        painter: _CoverageMapPainter.of(context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.md,
                  vertical: Gap.xs,
                ),
                decoration: BoxDecoration(
                  color: CefColors.brand,
                  borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                ),
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: Gap.xs),
              const Icon(LucideIcons.mapPin, color: CefColors.brand, size: 28),
            ],
          ),
        ),
      ),
    ),
  );
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
    final text = Theme.of(context).textTheme;
    // Archetype G (multi-section form): coverage preview, then one
    // SectionHeading per section, CefFields and the CTA.
    return PageBody(
      bottom: CefButton(
        widget.isNew ? 'Create Zone' : 'Save Changes',
        busy: busy,
        onTap: _save,
      ),
      children: [
        SizedBox(
          height: 170,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            child: CustomPaint(
              painter: _CoverageMapPainter.of(context),
              child: Center(
                child: Icon(
                  LucideIcons.mapPin,
                  color: context.c.info,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        if (widget.isNew) ...[
          const SizedBox(height: Gap.md),
          Text(
            'This zone will cover the highlighted area on the map. '
            'You can always edit it later.',
            style: text.bodySmall,
          ),
        ],
        const SectionHeading(
          'Zone details',
          icon: LucideIcons.mapPin,
          subtitle: 'Name the area you deliver to',
        ),
        CefField(
          label: 'Zone name',
          controller: name,
          hint: 'Enter zone name',
          prefixIcon: LucideIcons.mapPin,
          errorText: errors['name'],
        ),
        if (!widget.isNew) ...[
          const SectionHeading('Status', icon: LucideIcons.circleCheck),
          CefListRow(
            title: 'Active',
            subtitle: 'Orders can be assigned to this zone',
            subtitleMaxLines: 2,
            trailing: CefSwitch(
              value: active,
              onChanged: (v) => setState(() => active = v),
            ),
          ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              error!,
              style: text.bodySmall?.copyWith(color: context.c.attention),
            ),
          ),
        if (!widget.isNew) ...[
          const SizedBox(height: Gap.md),
          CefButton(
            'Delete Zone',
            destructive: true,
            icon: LucideIcons.trash2,
            onTap: _delete,
          ),
        ],
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
        final visible = switch (tab) {
          'Active' => riders.where((r) => r.isActive).toList(),
          'Offline' => riders.where((r) => !r.isActive).toList(),
          'Pending' => riders.where((r) => r.status == 'pending').toList(),
          _ => riders,
        };
        return PageBody(
          onRefresh: reload,
          children: [
            SegmentedTabs(
              labels: const ['All', 'Active', 'Offline', 'Pending'],
              active: tab,
              onChange: (l) => setState(() => tab = l),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              const StateBlock.empty('No riders yet.')
            else
              for (final r in visible)
                CefListRow(
                  title: r.name,
                  subtitle: [
                    if (r.vehicleType != null) _titleCase(r.vehicleType!),
                    if (r.plate != null) r.plate!,
                  ].join(' · '),
                  leading: CefAvatar(r.name, filled: true),
                  trailing: StatusChip(
                    r.isActive ? 'Active' : 'Offline',
                    success: r.isActive,
                  ),
                  // Audit fix 2: bound to this rider's id.
                  onTap: () => app.go(VRoute.riderDetail, entityId: r.id),
                ),
          ],
        );
      },
    );
  }
}

/// "12 Jan 2024" -- the one short date format on detail stats.
String _shortDate(DateTime d) {
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
        final plate = rider.plate ?? '';
        return HeroPage(
          onRefresh: reload,
          hero: DetailHero(
            leading: CefAvatar(rider.name, size: 88),
            title: rider.name,
            status: HeroStatusPill(
              pending
                  ? 'Pending Review'
                  : rider.isActive
                  ? 'Active'
                  : 'Offline',
              color: pending
                  ? context.c.warning
                  : rider.isActive
                  ? null
                  : context.c.textSecondary,
            ),
            lines: [
              HeroLine(pending ? 'Rider applicant' : 'Rider'),
              if (plate.isNotEmpty)
                HeroLine(plate, icon: _vehicleIcon(rider.vehicleType)),
            ],
          ),
          bottomAction: pending
              ? Row(
                  children: [
                    Expanded(
                      child: CefButton(
                        'Reject',
                        secondary: true,
                        onTap: () => showNotWiredYetSnackBar(
                          context,
                          'Rejecting riders',
                        ),
                      ),
                    ),
                    const SizedBox(width: Gap.cardGap),
                    Expanded(
                      child: CefButton(
                        'Approve Rider',
                        onTap: () => showNotWiredYetSnackBar(
                          context,
                          'Approving riders',
                        ),
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
                  'Total orders',
                  icon: LucideIcons.package,
                ),
                KpiItem(
                  rider.rating?.toStringAsFixed(1) ?? '—',
                  'Customer rating',
                  icon: LucideIcons.star,
                ),
                KpiItem(
                  rider.joinedAt == null ? '—' : _shortDate(rider.joinedAt!),
                  'Joined',
                  icon: LucideIcons.calendarDays,
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            ContactCard(phone: rider.phone),
            const CefListGroup(
              children: [
                CefListRow(
                  title: 'Driving Licence',
                  subtitle: 'No licence document available',
                  icon: LucideIcons.fileText,
                ),
                CefListRow(
                  title: 'Additional Information',
                  subtitle: 'No additional information available.',
                  icon: LucideIcons.clipboardList,
                ),
              ],
            ),
          ],
        );
      },
    );
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
            CefSearchField(
              hint: 'Search team members...',
              controller: _query,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              const StateBlock.empty('No team members yet.')
            else
              // Archetype D (people list): filled avatar, status pill.
              for (final m in visible)
                CefListRow(
                  title: m.displayName ?? m.userId,
                  subtitle: m.role,
                  leading: CefAvatar(m.displayName ?? m.userId, filled: true),
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
      key: ValueKey('team-member-$memberId'),
      load: () async {
        final members = await app.repo.team(app.business!.id);
        return members.firstWhere(
          (m) => m.userId == memberId,
          orElse: () => throw StateError('Team member not found'),
        );
      },
      builder: (context, member, reload) {
        final name = member.displayName ?? member.userId;
        return HeroPage(
          onRefresh: reload,
          hero: DetailHero(
            leading: CefAvatar(name, size: 88),
            title: name,
            status: const HeroStatusPill('Active'),
            lines: [HeroLine(member.role)],
          ),
          children: [
            ContactCard(phone: member.phone),
            CefListGroup(
              children: [
                CefListRow(
                  title: 'Email',
                  subtitle: member.email ?? 'Not provided',
                  icon: LucideIcons.mail,
                ),
                CefListRow(
                  title: 'Role & access',
                  subtitle: '${member.role} · ${_roleDescription(member.role)}',
                  subtitleMaxLines: 3,
                  icon: LucideIcons.shieldCheck,
                ),
                const CefListRow(
                  title: 'Account status',
                  subtitle:
                      'Active · This team member can currently access your '
                      'business.',
                  subtitleMaxLines: 2,
                  icon: LucideIcons.circleCheck,
                ),
              ],
            ),
            if (member.isOwner)
              Text(
                'The business owner always keeps full access and cannot be '
                'removed from the team.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              CefButton(
                'Remove from Team',
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

/// Illustrative coverage preview (Zone detail / Zone form). Coverage
/// geometry stays server-owned; this never draws a real boundary. The zone
/// is drawn in CEFFLO Blue, the one brand blue.
class _CoverageMapPainter extends CustomPainter {
  const _CoverageMapPainter({
    required this.ground,
    required this.road,
    required this.area,
  });

  factory _CoverageMapPainter.of(BuildContext context) => _CoverageMapPainter(
    ground: context.c.subtle,
    road: context.c.card,
    area: CefColors.brand,
  );

  final Color ground, road, area;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final roads = Paint()
      ..color = road
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
    final coverage = Path()
      ..moveTo(size.width * .25, size.height * .35)
      ..lineTo(size.width * .48, size.height * .16)
      ..lineTo(size.width * .73, size.height * .32)
      ..lineTo(size.width * .78, size.height * .68)
      ..lineTo(size.width * .48, size.height * .82)
      ..lineTo(size.width * .22, size.height * .60)
      ..close();
    canvas.drawPath(coverage, Paint()..color = area.withValues(alpha: .2));
    canvas.drawPath(
      coverage,
      Paint()
        ..color = area
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Boundary vertices, as the zone editor shows them.
    for (final (dx, dy) in const [
      (.25, .35),
      (.48, .16),
      (.73, .32),
      (.78, .68),
      (.48, .82),
      (.22, .60),
    ]) {
      final at = Offset(size.width * dx, size.height * dy);
      canvas.drawCircle(at, 4, Paint()..color = road);
      canvas.drawCircle(
        at,
        4,
        Paint()
          ..color = area
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(_CoverageMapPainter oldDelegate) =>
      oldDelegate.ground != ground ||
      oldDelegate.road != road ||
      oldDelegate.area != area;
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
          const CefSearchField(hint: 'Search products...'),
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
            // Archetype D (people list).
            const CefSearchField(hint: 'Search customers...'),
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
              const HeroLine('Customer'),
              HeroLine(
                '$count order${count == 1 ? '' : 's'}',
                icon: LucideIcons.package,
              ),
            ],
          ),
          children: [
            ContactCard(phone: customer.customerPhone),
            SectionHeading('Orders ($count)'),
            CefListGroup(
              children: [
                for (final order in customerOrders)
                  CefListRow(
                    title: order.reference,
                    subtitle: order.deliveryAddress,
                    icon: LucideIcons.package,
                    trailing: DeliveryStatusChip(order.status),
                    onTap: () => app.go(VRoute.orderDetail, entityId: order.id),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// V-46 — Settings, opened from the Today header (D-46). The one directory
/// of account, business and support destinations: nothing here is repeated
/// on another page.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    Widget group(String title, List<(String, IconData, VRoute)> items) =>
        CefListGroup(
          label: title,
          children: [
            for (final i in items)
              CefListRow(title: i.$1, icon: i.$2, onTap: () => app.go(i.$3)),
          ],
        );

    // Archetype F (Settings): grouped white cards on the cool-white page.
    return PageBody(
      grouped: true,
      children: [
        group('Account', [
          ('Personal information', LucideIcons.fileUser, VRoute.editProfile),
          ('Security', LucideIcons.lock, VRoute.security),
          ('Notifications', LucideIcons.bell, VRoute.notificationSettings),
          ('Language', LucideIcons.globe, VRoute.language),
          ('Appearance', LucideIcons.palette, VRoute.appearance),
          ('Privacy', LucideIcons.shieldCheck, VRoute.privacyPolicy),
        ]),
        group('Business', [
          ('Business profile', LucideIcons.building2, VRoute.businessProfile),
          ('Storefront', LucideIcons.store, VRoute.storefront),
          ('Products', LucideIcons.package, VRoute.products),
          ('Team', LucideIcons.users, VRoute.team),
          ('Customers', LucideIcons.contactRound, VRoute.customers),
          ('Service area', LucideIcons.map, VRoute.serviceArea),
        ]),
        group('Support', [
          ('Help & support', LucideIcons.circleHelp, VRoute.helpSupport),
          ('About Cefflo', LucideIcons.info, VRoute.about),
        ]),
        CefButton(
          'Sign out',
          destructive: true,
          icon: LucideIcons.logOut,
          onTap: () async {
            await app.repo.signOut();
            app.clearSession();
          },
        ),
        const SizedBox(height: Gap.md),
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
