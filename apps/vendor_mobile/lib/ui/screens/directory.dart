import 'dart:math' as math;

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

/// V-16 — Zones overview: every zone on one map, then the zone list (name,
/// status, today's orders and riders). Tapping a zone opens its Zone detail.
class ZonesScreen extends StatelessWidget {
  const ZonesScreen({super.key});

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
      loading: const SkeletonPage(
        top: [
          SkeletonBox(height: 240),
          SizedBox(height: Gap.sm),
        ],
      ),
      key: ValueKey('zones-${business.id}'),
      load: () async => (
        await app.repo.zones(business.id),
        await app.repo.orders(business.id),
      ),
      builder: (context, data, reload) {
        final (zones, orders) = data;
        String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
        return PageBody(
          onRefresh: reload,
          children: [
            _ZonesOverviewMap(zones: zones),
            SectionHeading('Zones (${zones.length})'),
            if (zones.isEmpty)
              const StateBlock.empty(
                'No zones yet. Tap + to create your first zone.',
              )
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
                      subtitle:
                          '${plural(inZone.length, 'order')} · '
                          '${plural(riders.length, 'rider')}',
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

/// All zones on one illustrative map: each zone is a polygon with a pin and
/// its name, the first active zone emphasised in Anchor Blue. Geometry stays
/// server-owned; this is a preview layout, not real boundaries.
class _ZonesOverviewMap extends StatelessWidget {
  const _ZonesOverviewMap({required this.zones});
  final List<Zone> zones;

  /// Fractional centres for up to eight zones, the emphasised one first.
  static const _slots = [
    (.50, .52),
    (.26, .20),
    (.80, .22),
    (.20, .62),
    (.76, .70),
    (.44, .86),
    (.88, .46),
    (.10, .40),
  ];

  @override
  Widget build(BuildContext context) {
    final shown = zones.take(_slots.length).toList();
    final focus = shown.indexWhere((z) => z.isActive);
    return SizedBox(
      height: 240,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
        child: LayoutBuilder(
          builder: (context, box) => CustomPaint(
            painter: _ZonesOverviewPainter(
              count: shown.length,
              focus: focus,
              slots: _slots,
              ground: context.c.subtle,
              road: context.c.card,
            ),
            child: Stack(
              children: [
                for (final (i, z) in shown.indexed)
                  Positioned(
                    left: box.maxWidth * _slots[i].$1 - 55,
                    top: box.maxHeight * _slots[i].$2 - 22,
                    width: 110,
                    child: _ZonePinLabel(name: z.name, focused: i == focus),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZonePinLabel extends StatelessWidget {
  const _ZonePinLabel({required this.name, required this.focused});
  final String name;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.mapPin,
          size: Sizes.icon,
          color: focused ? CefColors.brand : context.c.iconColor,
        ),
        const SizedBox(height: 2),
        if (focused)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: CefColors.brand,
              borderRadius: BorderRadius.circular(Sizes.buttonRadius),
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(color: Colors.white),
            ),
          )
        else
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.labelMedium?.copyWith(color: context.c.textPrimary),
          ),
      ],
    );
  }
}

class _ZonesOverviewPainter extends CustomPainter {
  const _ZonesOverviewPainter({
    required this.count,
    required this.focus,
    required this.slots,
    required this.ground,
    required this.road,
  });
  final int count, focus;
  final List<(double, double)> slots;
  final Color ground, road;

  @override
  void paint(Canvas canvas, Size size) {
    _paintStreets(canvas, size, ground, road);
    for (var i = 0; i < count; i++) {
      final centre = Offset(
        size.width * slots[i].$1,
        size.height * slots[i].$2,
      );
      final r = i == focus ? size.height * .24 : size.height * .15;
      final hex = Path();
      for (var k = 0; k < 6; k++) {
        final angle = (k * 60 - 30) * 3.1415926535 / 180;
        final point = centre + Offset(r * 1.1 * _cos(angle), r * _sin(angle));
        k == 0
            ? hex.moveTo(point.dx, point.dy)
            : hex.lineTo(point.dx, point.dy);
      }
      hex.close();
      final emphasis = i == focus;
      canvas.drawPath(
        hex,
        Paint()
          ..color = CefColors.brand.withValues(alpha: emphasis ? .22 : .08),
      );
      canvas.drawPath(
        hex,
        Paint()
          ..color = CefColors.brand.withValues(alpha: emphasis ? 1 : .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = emphasis ? 2 : 1.2,
      );
    }
  }

  static double _cos(double a) => math.cos(a);
  static double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_ZonesOverviewPainter old) =>
      old.count != count || old.focus != focus || old.ground != ground;
}

/// Light street grid shared by the zone map painters.
void _paintStreets(Canvas canvas, Size size, Color ground, Color road) {
  canvas.drawRect(Offset.zero & size, Paint()..color = ground);
  final roads = Paint()
    ..color = road
    ..strokeWidth = 5;
  for (var i = -2; i < 10; i++) {
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

typedef _ZoneData = (Zone, List<VendorOrder>, PlanProposal, List<RiderRow>);

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  final _view = GlobalKey<AsyncViewState<_ZoneData>>();

  /// The loaded zone; drives the header title and the ⋮ menu.
  Zone? _zone;

  Future<_ZoneData> _load() async {
    final app = AppScope.read(context);
    final businessId = app.business!.id;
    final zones = await app.repo.zones(businessId);
    final zone = zones.firstWhere(
      (z) => z.id == widget.zoneId,
      orElse: () => throw StateError('Zone not found'),
    );
    final orders = await app.repo.orders(businessId);
    final plan = await app.repo.proposePlan(businessId);
    final riders = await app.repo.riders(businessId);
    if (mounted) setState(() => _zone = zone);
    return (
      zone,
      orders.where((o) => o.zoneId == widget.zoneId).toList(),
      plan,
      riders,
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
              tooltip: 'Zone options',
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
              builder: (context, data, reload) =>
                  _ZoneDetailBody(data: data, reload: reload),
            ),
          ),
        ),
      ],
    );
  }

  /// Zone options: exactly Edit zone name and Delete zone.
  void _showZoneOptions(Zone zone) {
    final c = context.c;
    showModalBottomSheet<void>(
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
              Text(
                'Zone options',
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
              const SizedBox(height: Gap.sm),
              CefListRow(
                title: 'Edit zone name',
                icon: LucideIcons.pencil,
                showChevron: false,
                onTap: () {
                  Navigator.of(sheet).pop();
                  _editName(zone);
                },
              ),
              _DestructiveRow(
                label: 'Delete zone',
                onTap: () {
                  Navigator.of(sheet).pop();
                  _confirmDelete(zone);
                },
              ),
              const SizedBox(height: Gap.lg),
              CefButton(
                'Cancel',
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
    final name = await showModalBottomSheet<String>(
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
    if (name == null || name == zone.name || !mounted) return;
    try {
      final updated = await app.repo.renameZone(zone.id, name);
      if (!mounted) return;
      setState(() => _zone = updated);
      await _view.currentState?.reload();
      if (!mounted) return;
      showCefToast(context, 'Zone renamed to ${updated.name}');
    } catch (e) {
      if (mounted) {
        showCefToast(context, 'Could not rename: $e', error: true);
      }
    }
  }

  Future<void> _confirmDelete(Zone zone) async {
    final app = AppScope.read(context);
    final confirmed = await showModalBottomSheet<bool>(
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
                'Delete ${zone.name}?',
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
              const SizedBox(height: Gap.xs),
              Text(
                'This will remove the zone from your delivery setup.',
                style: Theme.of(sheet).textTheme.bodyMedium,
              ),
              const SizedBox(height: Gap.xl),
              Row(
                children: [
                  Expanded(
                    child: CefButton(
                      'Cancel',
                      secondary: true,
                      onTap: () => Navigator.of(sheet).pop(false),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: CefButton(
                      'Delete',
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
      await app.repo.deleteZone(zone.id);
      if (!mounted) return;
      showCefToast(context, '${zone.name} deleted');
      app.back();
    } catch (e) {
      if (mounted) {
        showCefToast(context, 'Could not delete: $e', error: true);
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
  late final _controller = TextEditingController(text: widget.initialName);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Zone name is required.');
      return;
    }
    Navigator.of(context).pop(name);
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
          Text(
            'Edit zone name',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Gap.md),
          CefField(
            controller: _controller,
            hint: 'Zone name',
            prefixIcon: LucideIcons.mapPin,
            errorText: _error,
          ),
          Row(
            children: [
              Expanded(
                child: CefButton(
                  'Cancel',
                  secondary: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(child: CefButton('Save', onTap: _save)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ZoneDetailBody extends StatelessWidget {
  const _ZoneDetailBody({required this.data, required this.reload});
  final _ZoneData data;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final (zone, orders, plan, riders) = data;
    final groups = plan.groups
        .where((g) => g.zoneId == zone.id && g.stops.isNotEmpty)
        .toList();
    final distance = groups.fold<num>(
      0,
      (sum, g) => sum + (g.totalDistanceKm ?? 0),
    );
    // Delivered is what has actually been delivered -- 0 until it happens.
    final delivered = orders
        .where((o) => o.status == DeliveryStatus.delivered)
        .length;
    final byId = {for (final o in orders) o.id: o};
    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Gap.gutter,
          Gap.lg,
          Gap.gutter,
          Gap.xxl,
        ),
        children: [
          _ZoneMap(name: zone.name),
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
                zone.isActive ? 'Active' : 'Inactive',
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
                groups.isEmpty ? '0 km' : '${distance.toStringAsFixed(1)} km',
                'Total distance',
                icon: LucideIcons.route,
              ),
              KpiItem(
                '${orders.length}',
                'Total orders',
                icon: LucideIcons.clipboardList,
              ),
              KpiItem('$delivered', 'Delivered', icon: LucideIcons.circleCheck),
            ],
          ),
          const SectionHeading("Today's deliveries"),
          if (groups.isEmpty)
            const StateBlock.empty('No deliveries planned in this zone today.')
          else
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
            ],
        ],
      ),
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
    final name = group.candidateRiderName ?? rider?.name ?? 'Unassigned rider';
    final count = group.stops.length;
    return CefListRow(
      title: name,
      subtitle: [
        if (group.candidateRiderVehicleType != null)
          _titleCase(group.candidateRiderVehicleType!),
        if (rider?.plate != null) rider!.plate!,
      ].join(' · '),
      leading: CefAvatar(name, filled: true),
      trailing: StatusChip('$count order${count == 1 ? '' : 's'}'),
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
      if (stop.distanceKm != null) '${stop.distanceKm} km',
      if (stop.travelMinutes != null) '${stop.travelMinutes} min',
    ].join(' · ');
    final eta = stop.etaAt == null ? null : _formatTime(stop.etaAt!);
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
          '${order?.customerName ?? 'Delivery'} removed from today',
        );
        onRemoved();
      },
      child: CefListRow(
        title: order?.customerName ?? stop.orderId,
        subtitle: meta.isEmpty ? null : meta,
        leading: SizedBox(
          width: Sizes.avatar,
          child: Center(child: _SequenceBadge(stop.sequence)),
        ),
        trailing: eta == null ? null : Text(eta, style: text.bodySmall),
        onTap: onTap,
      ),
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
    decoration: const BoxDecoration(
      color: CefColors.brand,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$sequence',
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Colors.white),
    ),
  );
}

/// Zone detail map: the zone's polygon with its name pill and pin. The
/// strongest visual element of the screen.
class _ZoneMap extends StatelessWidget {
  const _ZoneMap({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
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

/// V-29 — Create zone, bound to the canonical `create_zone` contract.
/// Coverage geometry stays server-owned: this only names the zone and
/// previews it. Editing and deleting a zone live in Zone detail's ⋮ menu.
class CreateZoneScreen extends StatefulWidget {
  const CreateZoneScreen({super.key});

  @override
  State<CreateZoneScreen> createState() => _CreateZoneScreenState();
}

class _CreateZoneScreenState extends State<CreateZoneScreen> {
  final name = TextEditingController();
  bool busy = false;
  String? error;
  String? nameError;

  Future<void> _save() async {
    setState(
      () => nameError = name.text.trim().isEmpty
          ? 'Zone name is required.'
          : null,
    );
    if (nameError != null) return;

    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      final ok = await runAsyncFeedback(
        context,
        action: () async {},
        processingTitle: 'Processing...',
        processingSubtitle: 'Creating your zone',
        successTitle: 'Successful',
        successSubtitle: 'Your new zone has been created successfully.',
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
      await app.repo.createZone(app.business!.id, name.text.trim());
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
      bottom: CefButton('Create Zone', busy: busy, onTap: _save),
      children: [
        SizedBox(
          height: 170,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            child: CustomPaint(
              painter: _CoverageMapPainter.of(context),
              child: const Center(
                child: Icon(
                  LucideIcons.mapPin,
                  color: CefColors.brand,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Gap.md),
        Text(
          'This zone will cover the highlighted area on the map. '
          'You can always edit it later.',
          style: text.bodySmall,
        ),
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
          'Offline' => riders.where((r) => r.isOffline).toList(),
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
                    r.isActive
                        ? 'Active'
                        : r.isPending
                        ? 'Pending'
                        : 'Offline',
                    success: r.isActive,
                    warning: r.isPending,
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
      loading: const SkeletonHeroPage(),
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
      loading: const SkeletonHeroPage(),
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
    _paintStreets(canvas, size, ground, road);
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
            // Cardless order rows (D-50).
            for (final order in customerOrders)
              CefListRow(
                title: order.reference,
                subtitle: order.deliveryAddress,
                icon: LucideIcons.package,
                trailing: DeliveryStatusChip(order.status),
                onTap: () => app.go(VRoute.orderDetail, entityId: order.id),
              ),
          ],
        );
      },
    );
  }
}

/// Languages the app offers: code and native name.
const vendorLanguages = [
  ('ms', 'Bahasa Melayu'),
  ('en', 'English'),
  ('zh', '中文'),
  ('ta', 'தமிழ்'),
];

String languageName(String code) => vendorLanguages
    .firstWhere((l) => l.$1 == code, orElse: () => vendorLanguages[1])
    .$2;

/// Language picker: a small bottom sheet; choosing applies and closes.
void showLanguageSheet(BuildContext context) {
  final app = AppScope.read(context);
  showListSheet(
    context,
    title: 'Language',
    children: [
      for (final (code, name) in vendorLanguages)
        CefListRow(
          title: name,
          showChevron: false,
          trailing: app.locale == code
              ? const Icon(
                  LucideIcons.check,
                  size: Sizes.icon,
                  color: CefColors.brand,
                )
              : null,
          onTap: () {
            app.setLocale(code);
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
        label('Account'),
        row('Profile', LucideIcons.user, VRoute.editProfile),
        row('Security', LucideIcons.lock, VRoute.security),
        row('Notifications', LucideIcons.bell, VRoute.notificationSettings),
        CefListRow(
          title: 'Language',
          icon: LucideIcons.globe,
          trailing: Text(languageName(app.locale), style: text.bodySmall),
          onTap: () => showLanguageSheet(context),
        ),
        row('Appearance', LucideIcons.palette, VRoute.appearance),
        label('Business'),
        row('Business Profile', LucideIcons.building2, VRoute.businessProfile),
        row('Storefront', LucideIcons.store, VRoute.storefront),
        row('Products', LucideIcons.package, VRoute.products),
        row('Team', LucideIcons.users, VRoute.team),
        row(
          'Subscription',
          LucideIcons.creditCard,
          VRoute.subscription,
          trailing: StatusChip(app.currentPlan.name, info: true),
        ),
        label('Support'),
        row('Help & Support', LucideIcons.circleHelp, VRoute.helpSupport),
        row('Privacy', LucideIcons.shieldCheck, VRoute.privacyPolicy),
        row('About Cefflo', LucideIcons.info, VRoute.about),
        const SizedBox(height: Gap.sm),
        CefListRow(
          title: 'Sign out',
          leading: IconTile(LucideIcons.logOut, color: c.attention),
          titleColor: c.attention,
          showChevron: false,
          showDivider: false,
          onTap: () async {
            await app.repo.signOut();
            app.clearSession();
          },
        ),
        const SizedBox(height: Gap.sm),
        Center(child: Text('Version 1.0.0', style: text.labelSmall)),
      ],
    );
  }
}
