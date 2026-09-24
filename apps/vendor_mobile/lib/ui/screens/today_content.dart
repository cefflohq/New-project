import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../shell.dart';
import '../widgets.dart';

/// V-11 — Today (archetype A). Built only from shared blocks (PageBody,
/// KpiStrip, SectionHeading, CefListRow) so it matches every other screen.
/// Recent Delivery is capped so Need Attention stays in the first viewport.
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

  /// Recent deliveries shown before "View all".
  static const _recentLimit = 4;

  /// Need Attention rows shown on Today (the rest via "View all").
  static const _attentionLimit = 3;

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
        ? samples.take(_recentLimit).toList()
        : delivered.take(_recentLimit).map((o) {
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

    // Archetype A (Today / Overview): KPI strip directly on the white
    // surface, recent operational rows, then the Need Attention row.
    return PageBody(
      onRefresh: reload,
      children: [
        KpiStrip(
          items: [
            KpiItem('${counts[0]}', 'Total Orders'),
            KpiItem('${counts[1]}', 'Ready', color: c.success),
            KpiItem('${counts[2]}', 'Issue', color: c.attention),
            KpiItem('${counts[3]}', 'Delivered', color: CefColors.brand),
          ],
        ),
        const SizedBox(height: Gap.sm),
        SectionHeading(
          'Recent Delivery',
          trailing: CefLink(
            'View all',
            chevron: true,
            onTap: () => app.switchTab(NavTab.orders),
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
              dense: true,
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StatusChip('Delivered', success: true),
                  if (rows[i].$4.isNotEmpty) ...[
                    const SizedBox(height: Gap.xs),
                    Text(
                      rows[i].$4,
                      style: Theme.of(context).textTheme.labelSmall,
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
        SectionHeading(
          issues.isEmpty
              ? 'Need Attention'
              : 'Need Attention (${issues.length})',
          trailing: issues.isEmpty
              ? null
              : CefLink(
                  'View all',
                  chevron: true,
                  onTap: () => app.switchTab(NavTab.orders),
                ),
        ),
        if (issues.isEmpty)
          const StateBlock.empty('Nothing needs your attention.')
        else
          // Cardless rows (D-50), one per active issue, each opening its
          // order. The tinted red mark is the status indicator.
          for (final issue in issues.take(_attentionLimit))
            CefListRow(
              title: '${issue.reference} · ${issue.customerName}',
              subtitle: (issue.notes ?? '').isEmpty
                  ? 'Needs your action'
                  : issue.notes,
              leading: IconTile(
                LucideIcons.triangleAlert,
                color: c.attention,
                tinted: true,
              ),
              onTap: () => app.go(VRoute.orderDetail, entityId: issue.id),
            ),
      ],
    );
  }
}
