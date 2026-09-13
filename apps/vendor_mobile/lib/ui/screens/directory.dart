import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../async_view.dart';
import '../shell.dart';
import '../widgets.dart';

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
            SearchBarField(hint: 'Search zones...', onFilter: () {}),
            const SizedBox(height: Gap.md),
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
                    return FlatListRow(
                      title: z.name,
                      subtitle: '${inZone.length} orders',
                      leading: Icon(
                        LucideIcons.mapPin,
                        size: Sizes.icon,
                        color: context.c.info,
                      ),
                      trailing: z.isActive
                          ? null
                          : const StatusChip('Disabled'),
                      // Audit fix 2: bound to this zone's id.
                      onTap: () => app.go(VRoute.zoneDetail, entityId: z.id),
                    );
                  },
                ),
            const SizedBox(height: Gap.md),
            YellowFab(
              tooltip: 'Add zone',
              onTap: () => app.go(VRoute.createZone),
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
            StatusChip(zone.isActive ? 'Active' : 'Disabled'),
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
                  trailing: StatusChip(o.status.label),
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
                FlatListRow(
                  title: r.name,
                  subtitle: [
                    if (r.vehicleType != null) r.vehicleType!,
                    if (r.plate != null) r.plate!,
                  ].join(' · '),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: CefColors.navy,
                    child: Text(
                      r.name.split(' ').take(2).map((part) => part[0]).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  trailing: StatusChip(r.status),
                  // Audit fix 2: bound to this rider's id.
                  onTap: () => app.go(VRoute.riderDetail, entityId: r.id),
                ),
            const SizedBox(height: Gap.md),
            YellowFab(
              tooltip: 'Add rider',
              onTap: () => app.go(VRoute.riderRegistrationLink),
            ),
          ],
        );
      },
    );
  }
}

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
      builder: (context, rider, reload) => PageBody(
        onRefresh: reload,
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: CefColors.navy,
              child: Text(
                rider.name.split(' ').take(2).map((part) => part[0]).join(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              rider.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Center(
            child: Text(
              rider.phone ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: Gap.md),
          CefCard(
            child: Column(
              children: [
                _row(context, 'Status', rider.status),
                _row(context, 'Vehicle', rider.vehicleType ?? '—'),
                _row(context, 'Plate', rider.plate ?? '—'),
                _row(context, 'Phone', rider.phone ?? '—'),
                _row(
                  context,
                  'Max active orders',
                  '${rider.maxActiveOrders ?? '—'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(k, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Text(v, style: Theme.of(context).textTheme.titleSmall)),
      ],
    ),
  );
}

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<List<TeamMember>>(
      key: ValueKey('team-${app.business?.id}'),
      load: () => app.repo.team(app.business!.id),
      builder: (context, members, reload) => PageBody(
        onRefresh: reload,
        children: [
          if (members.isEmpty)
            const StateBlock.empty('No team members yet.')
          else
            for (final m in members)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.cardGap),
                child: CefListRow(
                  title: m.displayName ?? m.userId,
                  subtitle: m.role,
                  icon: LucideIcons.user,
                  // Audit fix 2: bound to this member's id.
                  onTap: () =>
                      app.go(VRoute.teamMemberDetail, entityId: m.userId),
                ),
              ),
        ],
      ),
    );
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
          const SizedBox(height: Gap.md),
          YellowFab(
            tooltip: 'Add product',
            onTap: () => app.go(VRoute.addProduct),
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
                trailing: StatusChip(order.status.label),
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
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B2A57), Color(0xFF0867D5), Color(0xFF12213E)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR APP, YOUR WAY',
                style: TextStyle(
                  color: Color(0xFF69B6FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Simple settings\nfor a smoother experience.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: CefColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        group('Operations', [
          ('Zones', LucideIcons.mapPin, VRoute.zones),
          ('Riders', LucideIcons.bike, VRoute.riders),
        ]),
        group('Business', [
          ('Team', LucideIcons.users, VRoute.team),
          ('Service area', LucideIcons.map, VRoute.serviceArea),
          ('Storefront', LucideIcons.store, VRoute.storefront),
          ('Business profile', LucideIcons.building2, VRoute.businessProfile),
        ]),
        group('Preferences', [
          ('Notifications', LucideIcons.bell, VRoute.notificationSettings),
          ('Language', LucideIcons.globe, VRoute.language),
          ('Appearance', LucideIcons.sun, VRoute.appearance),
        ]),
        group('Account', [
          ('Profile', LucideIcons.user, VRoute.profile),
          ('Security', LucideIcons.shieldCheck, VRoute.security),
          ('Privacy', LucideIcons.shield, VRoute.privacyPolicy),
          ('Subscription', LucideIcons.creditCard, VRoute.subscription),
        ]),
        group('Support', [
          ('Help & support', LucideIcons.circleHelp, VRoute.helpSupport),
          ('About Cefflo', LucideIcons.info, VRoute.about),
        ]),
        const SizedBox(height: Gap.section),
        CefButton(
          'Sign out',
          secondary: true,
          onTap: () async {
            await app.repo.signOut();
            app.clearSession();
          },
        ),
      ],
    );
  }
}

/// Appearance (V-49) — real, applies immediately.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    Widget option(String label, ThemeMode mode) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.cardGap),
      child: CefCard(
        selected: app.themeMode == mode,
        onTap: () => app.setThemeMode(mode),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            if (app.themeMode == mode)
              const Icon(LucideIcons.check, size: 18, color: Color(0xFF181818)),
          ],
        ),
      ),
    );

    return PageBody(
      children: [
        option('Use device setting', ThemeMode.system),
        option('Light', ThemeMode.light),
        option('Dark', ThemeMode.dark),
      ],
    );
  }
}
