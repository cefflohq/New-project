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
  String tab = 'Ready';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return const PageBody(children: [StateBlock.empty('No business linked.')]);
    }
    return AsyncView<(List<Zone>, List<VendorOrder>)>(
      key: ValueKey('zones-${business.id}'),
      load: () async => (
        await app.repo.zones(business.id),
        await app.repo.orders(business.id),
      ),
      builder: (context, data, reload) {
        final (zones, orders) = data;
        return PageBody(
          onRefresh: reload,
          children: [
            SegmentedTabs(
              labels: const ['Ready', 'Ongoing', 'Completed'],
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
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.cardGap),
                  child: Builder(
                    builder: (context) {
                      // Counts derive from the same scoped orders read.
                      final inZone = orders.where((o) => o.zoneId == z.id).toList();
                      final n = switch (tab) {
                        'Ready' => inZone
                            .where((o) => o.status == DeliveryStatus.readyForPickup)
                            .length,
                        'Ongoing' => inZone
                            .where(
                              (o) =>
                                  OrderTab.ongoing.accepts(o.status) &&
                                  o.status != DeliveryStatus.readyForPickup,
                            )
                            .length,
                        _ => inZone
                            .where((o) => o.status == DeliveryStatus.delivered)
                            .length,
                      };
                      return CefListRow(
                        title: z.name,
                        subtitle: '$n ${tab.toLowerCase()} · ${inZone.length} total',
                        icon: LucideIcons.map,
                        trailing: z.isActive ? null : const StatusChip('Disabled'),
                        // Audit fix 2: bound to this zone's id.
                        onTap: () => app.go(VRoute.zoneDetail, entityId: z.id),
                      );
                    },
                  ),
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
        return PageBody(
          onRefresh: reload,
          children: [
            Text(zone.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Gap.md),
            CefCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${orders.length} order${orders.length == 1 ? '' : 's'} in this zone',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  StatusChip(zone.isActive ? 'Active' : 'Disabled'),
                ],
              ),
            ),
            const SectionHeading('Orders'),
            if (orders.isEmpty)
              const StateBlock.empty('No orders are assigned to this zone.')
            else
              for (final o in orders)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.cardGap),
                  child: CefListRow(
                    title: o.reference,
                    subtitle: '${o.customerName} · ${o.deliveryAddress}',
                    trailing: StatusChip(o.status.label),
                    onTap: () => app.go(VRoute.orderDetail, entityId: o.id),
                  ),
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
      return const PageBody(children: [StateBlock.empty('No business linked.')]);
    }
    return AsyncView<List<RiderRow>>(
      key: ValueKey('riders-${business.id}'),
      load: () => app.repo.riders(business.id),
      builder: (context, riders, reload) {
        final visible = switch (tab) {
          'Available' => riders.where((r) => r.isActive).toList(),
          'On delivery' => riders.where((r) => r.status == 'active').toList(),
          _ => riders,
        };
        return PageBody(
          onRefresh: reload,
          children: [
            SegmentedTabs(
              labels: const ['All', 'Available', 'On delivery'],
              active: tab,
              onChange: (l) => setState(() => tab = l),
            ),
            const SizedBox(height: Gap.md),
            CefButton(
              'Rider registration link',
              secondary: true,
              onTap: () => app.go(VRoute.riderRegistrationLink),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              const StateBlock.empty('No riders yet.')
            else
              for (final r in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.cardGap),
                  child: CefListRow(
                    title: r.name,
                    subtitle: [
                      if (r.vehicleType != null) r.vehicleType!,
                      if (r.plate != null) r.plate!,
                    ].join(' · '),
                    icon: LucideIcons.user,
                    trailing: StatusChip(r.status),
                    // Audit fix 2: bound to this rider's id.
                    onTap: () => app.go(VRoute.riderDetail, entityId: r.id),
                  ),
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
          Text(rider.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Gap.md),
          CefCard(
            child: Column(
              children: [
                _row(context, 'Status', rider.status),
                _row(context, 'Vehicle', rider.vehicleType ?? '—'),
                _row(context, 'Plate', rider.plate ?? '—'),
                _row(context, 'Phone', rider.phone ?? '—'),
                _row(context, 'Max active orders', '${rider.maxActiveOrders ?? '—'}'),
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
                  onTap: () => app.go(VRoute.teamMemberDetail, entityId: m.userId),
                ),
              ),
        ],
      ),
    );
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
          const StateBlock.blocked(
            'Product photography (upload, background removal, approve) is not '
            'wired: no background-removal provider is approved for this '
            'environment. Catalogue text fields below are live.',
          ),
          const SizedBox(height: Gap.md),
          if (products.isEmpty)
            const StateBlock.empty('No products in the catalogue yet.')
          else
            for (final p in products)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.cardGap),
                child: CefListRow(
                  title: p.name,
                  subtitle: p.displayPrice == null
                      ? p.status
                      : '${p.status} · ${p.displayPrice}',
                  icon: LucideIcons.package,
                  onTap: () => app.go(VRoute.productDetail, entityId: p.id),
                ),
              ),
        ],
      ),
    );
  }
}

/// V-46 — the Menu tab root.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    Widget group(String title, List<(String, IconData, VRoute)> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(title),
        for (final i in items)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.cardGap),
            child: CefListRow(
              title: i.$1,
              icon: i.$2,
              onTap: () => app.go(i.$3),
            ),
          ),
      ],
    );

    return PageBody(
      children: [
        CefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.business?.name ?? 'No business',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                app.business == null ? '—' : 'Role: ${app.business!.role}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        group('Business', [
          ('Team', LucideIcons.users, VRoute.team),
          ('Service area', LucideIcons.map, VRoute.serviceArea),
          ('Storefront', LucideIcons.store, VRoute.storefront),
          ('Business profile', LucideIcons.building2, VRoute.businessProfile),
        ]),
        group('Account', [
          ('Profile', LucideIcons.user, VRoute.profile),
          ('Security', LucideIcons.shieldCheck, VRoute.security),
          ('Notification settings', LucideIcons.bell, VRoute.notificationSettings),
          ('Language', LucideIcons.globe, VRoute.language),
          ('Appearance', LucideIcons.sun, VRoute.appearance),
          ('Subscription', LucideIcons.creditCard, VRoute.subscription),
        ]),
        group('Information', [
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
