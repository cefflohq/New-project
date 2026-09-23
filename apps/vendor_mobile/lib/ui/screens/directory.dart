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
                      subtitle: '${inZone.length} orders',
                      leading: Icon(
                        LucideIcons.mapPin,
                        size: Sizes.icon,
                        color: context.c.info,
                      ),
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
            CefSearchField(
              hint: 'Search zones...',
              controller: _query,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              const StateBlock.empty('No zones configured yet.')
            else
              for (final z in visible)
                CefListRow(
                  title: z.name,
                  leading: CefAvatar(z.name),
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
                            horizontal: Gap.md,
                            vertical: Gap.xs,
                          ),
                          decoration: BoxDecoration(
                            color: context.c.info,
                            borderRadius: BorderRadius.circular(
                              Sizes.buttonRadius,
                            ),
                          ),
                          child: Text(
                            zone.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: Gap.xs),
                        Icon(
                          LucideIcons.mapPin,
                          color: context.c.info,
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
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconAction(
                  icon: LucideIcons.squarePen,
                  tooltip: 'Edit zone',
                  onTap: () => app.go(VRoute.editZone, entityId: zone.id),
                ),
              ],
            ),
            const SizedBox(height: Gap.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusChip(
                zone.isActive ? 'Active' : 'Inactive',
                success: zone.isActive,
              ),
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
                CefListRow(
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
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.c.attention),
            ),
          ),
        const SizedBox(height: Gap.section),
        if (widget.isNew)
          CefButton('Create Zone', busy: busy, onTap: _save)
        else
          Row(
            children: [
              Expanded(
                child: CefButton(
                  'Delete Zone',
                  destructive: true,
                  onTap: _delete,
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
                  leading: CefAvatar(r.name),
                  trailing: StatusChip(
                    r.isActive ? 'Active' : 'Offline',
                    success: r.status == 'active',
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

/// V-21 — Rider detail. `RiderRow` only carries id/name/status/phone/
/// vehicleType/plate/maxActiveOrders, so this shows what is real (no
/// invented licence documents, date of birth, address or emergency
/// contact -- unlike the reference board, which shows fields this backend
/// does not track).
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
        return PageBody(
          onRefresh: reload,
          children: [
            ReviewProfileHero(
              name: rider.name,
              role: pending ? 'Rider Applicant' : 'Rider',
              status: pending
                  ? 'Pending Review'
                  : rider.isActive
                  ? 'Active'
                  : 'Offline',
              pending: pending,
            ),
            const SectionHeading('Contact'),
            ProfileDetailCard(
              lines: [
                ProfileDetailLine(
                  icon: LucideIcons.phone,
                  label: 'Phone',
                  value: rider.phone,
                ),
              ],
            ),
            const SectionHeading('Vehicle'),
            ProfileDetailCard(
              lines: [
                ProfileDetailLine(
                  icon: LucideIcons.bike,
                  label: 'Type',
                  value: rider.vehicleType == null
                      ? null
                      : _titleCase(rider.vehicleType!),
                ),
                if (rider.plate != null)
                  ProfileDetailLine(
                    icon: LucideIcons.hash,
                    label: 'Plate number',
                    value: rider.plate,
                  ),
              ],
            ),
            const SectionHeading('Driving Licence'),
            const ProfileDetailCard(
              lines: [
                ProfileDetailLine(
                  icon: LucideIcons.fileText,
                  label: 'Document',
                  emptyText: 'No licence document available',
                ),
              ],
            ),
            const SectionHeading('Additional Information'),
            const ProfileDetailCard(
              lines: [
                ProfileDetailLine(
                  icon: LucideIcons.info,
                  label: 'Notes',
                  emptyText: 'No additional information available.',
                ),
              ],
            ),
            if (rider.maxActiveOrders != null) ...[
              const SectionHeading('Capacity'),
              ProfileDetailCard(
                lines: [
                  ProfileDetailLine(
                    icon: LucideIcons.gauge,
                    label: 'Max active orders',
                    value: '${rider.maxActiveOrders}',
                  ),
                ],
              ),
            ],
            const SizedBox(height: Gap.section),
            if (pending)
              Row(
                children: [
                  Expanded(
                    child: CefButton(
                      'Reject',
                      secondary: true,
                      onTap: () => _notWiredYet(context, 'Rejecting riders'),
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
            Text(
              'Manage who can access your business.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SectionHeading(
              '${members.length} Member${members.length == 1 ? '' : 's'}',
              trailing: IconAction(
                icon: LucideIcons.userPlus,
                tooltip: 'Invite team member',
                onTap: () => app.go(VRoute.helperRegistrationLink),
              ),
            ),
            CefSearchField(
              hint: 'Search team members...',
              controller: _query,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              const StateBlock.empty('No team members yet.')
            else
              for (final m in visible)
                CefListRow(
                  title: m.displayName ?? m.userId,
                  subtitle: m.role,
                  leading: CefAvatar(m.displayName ?? m.userId),
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
      builder: (context, member, reload) => PageBody(
        onRefresh: reload,
        children: [
          ReviewProfileHero(
            name: member.displayName ?? member.userId,
            role: member.role,
            status: 'Active',
          ),
          const SectionHeading('Contact'),
          const ProfileDetailCard(
            lines: [
              ProfileDetailLine(icon: LucideIcons.phone, label: 'Phone'),
              ProfileDetailLine(icon: LucideIcons.mail, label: 'Email'),
            ],
          ),
          const SectionHeading('Role & Access'),
          ProfileDetailCard(
            lines: [
              ProfileDetailLine(
                icon: LucideIcons.shieldCheck,
                label: 'Role',
                value: member.role,
                note: _roleDescription(member.role),
              ),
            ],
          ),
          const SectionHeading('Status'),
          const ProfileDetailCard(
            lines: [
              ProfileDetailLine(
                icon: LucideIcons.circleCheck,
                label: 'Account Status',
                value: 'Active',
                note: 'This team member can currently access your business.',
              ),
            ],
          ),
          const SizedBox(height: Gap.section),
          CefButton(
            'Remove from Team',
            destructive: true,
            icon: LucideIcons.trash2,
            onTap: () => _confirmRemove(context, member),
          ),
        ],
      ),
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
            const CefSearchField(hint: 'Search customers...'),
            const SizedBox(height: Gap.md),
            for (final entry in customers.entries)
              CefListRow(
                title: entry.key,
                subtitle: entry.value.customerPhone,
                leading: CefAvatar(entry.key),
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
            Center(child: CefAvatar(customerName, size: 80)),
            const SizedBox(height: Gap.md),
            Center(
              child: Text(
                customerName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                customer.customerPhone,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SectionHeading('Orders'),
            for (final order in customerOrders)
              CefListRow(
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
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    Widget group(String title, List<(String, IconData, VRoute)> items) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(title),
            for (final i in items)
              CefListRow(title: i.$1, icon: i.$2, onTap: () => app.go(i.$3)),
          ],
        );

    return PageBody(
      children: [
        group('Business', [
          ('Business profile', LucideIcons.building2, VRoute.businessProfile),
          ('Team', LucideIcons.users, VRoute.team),
          ('Service area', LucideIcons.map, VRoute.serviceArea),
          ('Storefront', LucideIcons.store, VRoute.storefront),
          ('Products', LucideIcons.boxes, VRoute.products),
          ('Customers', LucideIcons.users, VRoute.customers),
        ]),
        group('App & Account', [
          ('Profile', LucideIcons.user, VRoute.profile),
          ('Security', LucideIcons.shieldCheck, VRoute.security),
          ('Privacy', LucideIcons.lock, VRoute.privacyPolicy),
          ('Notifications', LucideIcons.bell, VRoute.notificationSettings),
          ('Language', LucideIcons.globe, VRoute.language),
          ('Appearance', LucideIcons.contrast, VRoute.appearance),
        ]),
        const SizedBox(height: Gap.section),
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
              padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
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
        const SizedBox(height: Gap.xs),
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
