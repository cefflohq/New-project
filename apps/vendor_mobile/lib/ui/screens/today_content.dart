import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../data/models.dart';

/// Founder reference layout, scoped exclusively to Today.
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
  static const navy = Color(0xFF091A3C);
  static const muted = Color(0xFF858BA3);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
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
    return RefreshIndicator(
      onRefresh: reload,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0864E8),
                      Color(0xFF003888),
                      Color(0xFF061C48),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Orders",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(
                        4,
                        (i) => Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: i == 0
                                  ? null
                                  : const Border(
                                      left: BorderSide(
                                        color: Color(0x334E8AEA),
                                      ),
                                    ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${counts[i]}',
                                  style: TextStyle(
                                    fontSize: 25,
                                    height: 1.15,
                                    fontWeight: FontWeight.w600,
                                    color: [
                                      Colors.white,
                                      const Color(0xFF42CE82),
                                      const Color(0xFFFF3653),
                                      Colors.white,
                                    ][i],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  ['Total', 'Ready', 'Issue', 'Delivered'][i],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: [
                                      Colors.white,
                                      const Color(0xFF42CE82),
                                      const Color(0xFFFF3653),
                                      Colors.white,
                                    ][i],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: const Color(0xFFFDE9ED),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (issues.isNotEmpty) {
                      app.go(VRoute.orderDetail, entityId: issues.first.id);
                    } else {
                      app.switchTab(NavTab.orders);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFF20D2A),
                          size: 34,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Need Attention',
                                style: TextStyle(
                                  color: navy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                counts[2] == 0
                                    ? 'Nothing needs your attention'
                                    : '${counts[2]} orders need your action',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: navy, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent Delivery',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => app.switchTab(NavTab.orders),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF096BD8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No completed deliveries yet.'),
                ),
              for (var i = 0; i < rows.length; i++)
                InkWell(
                  onTap: () {
                    if (!demo) {
                      app.go(VRoute.orderDetail, entityId: delivered[i].id);
                    } else {
                      app.switchTab(NavTab.riders);
                    }
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 61),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF0F1F5)),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: const Color(0xFFE9EEF5),
                          child: Text(
                            rows[i].$1
                                .split(' ')
                                .map((s) => s[0])
                                .take(2)
                                .join(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rows[i].$1,
                                style: const TextStyle(
                                  color: navy,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    rows[i].$2,
                                    style: const TextStyle(
                                      color: navy,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      rows[i].$3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F3F8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Delivered',
                                style: TextStyle(color: muted, fontSize: 10),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              rows[i].$4,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: navy, size: 21),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
