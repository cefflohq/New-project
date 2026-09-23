import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../shell.dart';
import '../widgets.dart';

/// V-11 — Today. Uses the same shared building blocks (PageBody,
/// NavySummaryPanel, SectionHeading, CefListRow) as every other screen, so
/// its type/spacing/card density matches V-01..V-60 rather than a
/// screen-specific set of hand-picked sizes.
class TodayContent extends StatelessWidget {
  const TodayContent({
    super.key,
    required this.orders,
    required this.riders,
    required this.reload,
  });
  final List<VendorOrder> orders;
  final List<RiderRow> riders;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final demo = app.repo.isDemo;
    final delivered = orders
        .where((o) => o.status == DeliveryStatus.delivered)
        .toList();
    final issues = orders
        .where((o) => o.status == DeliveryStatus.issue)
        .toList();
    final ready = orders
        .where((o) => o.status == DeliveryStatus.readyForPickup)
        .length;
    final counts = demo
        ? [48, 12, 3, 33]
        : [orders.length, ready, issues.length, delivered.length];
    const samples = [
      ('Ahmad Razi', 'VFY 7281', 'Bangsar', '2:24 PM'),
      ('Siti Aminah', 'BMD 4120', 'Sentul', '1:56 PM'),
      ('Jason Lim', 'VDT 3302', 'Setapak', '12:41 PM'),
      ('Nur Iman', 'VFE 9812', 'Shah Alam', '11:28 AM'),
      ('Daniel Tan', 'BPL 6683', 'Petaling Jaya', '10:54 AM'),
      ('Farah Lee', 'VDS 7721', 'Putrajaya', '09:17 AM'),
      ('Hafiz Khan', 'BPQ 3091', 'Klang', '08:36 AM'),
    ];
    final rows = demo
        ? samples
        : delivered.take(7).map((o) {
            final match = riders.where((r) => r.id == o.assignedRiderId);
            final rider = match.isEmpty ? null : match.first;
            final t = o.completedAt;
            final time = t == null
                ? ''
                : '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
            return (
              rider?.name ?? 'Unassigned rider',
              rider?.plate ?? '',
              o.deliveryAddress,
              time,
            );
          }).toList();

    return PageBody(
      onRefresh: reload,
      children: [
        NavySummaryPanel(
          title: "Today's Orders",
          children: [
            SummaryMetric(label: 'Total', value: '${counts[0]}'),
            SummaryMetric(
              label: 'Ready',
              value: '${counts[1]}',
              valueColor: const Color(0xFF42CE82),
            ),
            SummaryMetric(
              label: 'Issue',
              value: '${counts[2]}',
              valueColor: const Color(0xFFFF3653),
            ),
            SummaryMetric(label: 'Delivered', value: '${counts[3]}'),
          ],
        ),
        const SizedBox(height: Gap.cardGap),
        Material(
          color: c.attention.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            onTap: () {
              if (issues.isNotEmpty) {
                app.go(VRoute.orderDetail, entityId: issues.first.id);
              } else {
                app.switchTab(NavTab.orders);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.cardPadding,
                vertical: Gap.md,
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.triangleAlert,
                    color: c.attention,
                    size: Sizes.icon,
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Attention',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          counts[2] == 0
                              ? 'Nothing needs your attention'
                              : '${counts[2]} orders need your action',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: c.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        SectionHeading(
          'Recent Delivery',
          trailing: GestureDetector(
            onTap: () => app.switchTab(NavTab.orders),
            child: Text(
              'View All',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: c.info),
            ),
          ),
        ),
        if (rows.isEmpty)
          const StateBlock.empty('No completed deliveries yet.')
        else
          for (var i = 0; i < rows.length; i++)
            CefListRow(
              title: rows[i].$1,
              subtitle: [
                if (rows[i].$2.isNotEmpty) rows[i].$2,
                rows[i].$3,
              ].join(' · '),
              leading: CefAvatar(rows[i].$1),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StatusChip('Delivered'),
                  if (rows[i].$4.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      rows[i].$4,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              onTap: () {
                if (!demo) {
                  app.go(VRoute.orderDetail, entityId: delivered[i].id);
                } else {
                  app.switchTab(NavTab.riders);
                }
              },
            ),
      ],
    );
  }
}
