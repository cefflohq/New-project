import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../shell.dart';
import '../widgets.dart';

/// V-11 — Today. Uses the same shared building blocks (PageBody,
/// SectionHeading, FlatListRow) as every other screen, so its type/spacing/
/// card density matches V-01..V-60 rather than a screen-specific set of
/// hand-picked sizes.
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
    // Exactly the 5 riders/times shown in the locked reference screen --
    // strict 1:1 with the reference takes priority over the longer demo
    // list previously here.
    const samples = [
      ('Ahmad Razi', 'VFY 7281', 'Bangsar', '2:24 PM'),
      ('Siti Aminah', 'BMD 4120', 'Sentul', '1:56 PM'),
      ('Jason Lim', 'VDT 3302', 'Setapak', '12:41 PM'),
      ('Nur Iman', 'VFE 9812', 'Shah Alam', '11:28 AM'),
      ('Daniel Tan', 'BPL 6683', 'Petaling Jaya', '10:54 AM'),
    ];
    final rows = demo
        ? samples
        : delivered.take(5).map((o) {
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
        _OverviewStats(
          stats: [
            ('Total Orders', '${counts[0]}', c.textPrimary),
            ('Ready', '${counts[1]}', const Color(0xFF42CE82)),
            ('Issue', '${counts[2]}', const Color(0xFFFF3653)),
            ('Delivered', '${counts[3]}', c.info),
          ],
        ),
        SectionHeading(
          'Recent Delivery',
          trailing: GestureDetector(
            onTap: () => app.switchTab(NavTab.orders),
            child: const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF1769D2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (rows.isEmpty)
          const StateBlock.empty('No completed deliveries yet.')
        else
          for (var i = 0; i < rows.length; i++)
            FlatListRow(
              title: rows[i].$1,
              subtitle: [
                if (rows[i].$2.isNotEmpty) rows[i].$2,
                rows[i].$3,
              ].join(' · '),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE9EEF5),
                child: Text(
                  rows[i].$1.split(' ').map((s) => s[0]).take(2).join(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: CefColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StatusChip('Delivered', tinted: true, success: true),
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
        const SizedBox(height: Gap.sm),
        FlatListRow(
          title: 'Need Attention',
          subtitle: counts[2] == 0
              ? 'Nothing needs your attention'
              : '${counts[2]} orders need your action',
          leading: Icon(Icons.warning_rounded, color: c.attention, size: 26),
          onTap: () {
            if (issues.isNotEmpty) {
              app.go(VRoute.orderDetail, entityId: issues.first.id);
            } else {
              app.switchTab(NavTab.orders);
            }
          },
        ),
      ],
    );
  }
}

/// Overview's 4-up stat row (Total Orders / Ready / Issue / Delivered),
/// each column centred with a thin vertical divider between -- matches the
/// locked reference screen (a plain white row, not a navy summary card).
class _OverviewStats extends StatelessWidget {
  const _OverviewStats({required this.stats});

  /// (label, value, value colour) per column, left to right.
  final List<(String, String, Color)> stats;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0)
                  VerticalDivider(width: 1, thickness: 1, color: c.border),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stats[i].$2,
                        style: TextStyle(
                          fontSize: 26,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: stats[i].$3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        stats[i].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        Divider(height: 1, color: c.border),
      ],
    );
  }
}
