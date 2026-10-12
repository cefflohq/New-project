import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The propose_delivery_plan contract (migration 20261012120000): split runs,
/// per-order unplannable reasons, excluded drivers and the business-local
/// plan date. The pre-migration shape must still parse.
void main() {
  setUp(() => applyUiLocale(const Locale('en')));

  test('parses split runs, per-order reasons, exclusions and plan date', () {
    final plan = PlanProposal.fromJson({
      'plan_date': '2026-10-13',
      'policy': 'balance',
      'groups': [
        {
          'group_key': 'z1:any:1',
          'zone_id': 'z1',
          'candidate_rider_id': 'r1',
          'part': 1,
          'parts': 3,
          'tier': 'any',
          'rider_remaining_after': 0,
          'stops': [
            {'order_id': 'o1', 'sequence': 1, 'distance_from_previous_km': 0.4},
          ],
        },
      ],
      'unplannable_orders': [
        {'order_id': 'o9', 'reason': 'insufficient_capacity', 'zone_id': 'z1'},
        {
          'order_id': 'o8',
          'reason': 'declined_awaiting_recovery',
          'zone_id': 'z1',
        },
        {'order_id': 'o7', 'reason': 'in_preparation', 'zone_id': null},
      ],
      'excluded_riders': [
        {'rider_id': 'r2', 'rider_name': 'Ali', 'reason': 'rider_has_open_run'},
        {'rider_id': 'r3', 'reason': 'not_eligible'},
      ],
    });
    expect(plan.planDate, '2026-10-13');
    expect(plan.policy, 'balance');
    expect(plan.groups.single.part, 1);
    expect(plan.groups.single.parts, 3);
    expect(plan.groups.single.orderIds, ['o1']);
    expect(plan.unplannable.map((u) => u.zoneId), ['z1', 'z1', null]);
    expect(plan.unplannable[0].label, 'Not enough driver capacity');
    expect(plan.unplannable[1].label, 'Driver declined: reassign or recover');
    expect(plan.unplannable[2].label, 'Being prepared');
    expect(plan.excludedRiders[0].label('x'), 'Ali already has an open run');
    expect(plan.excludedRiders[1].label('Abu'), 'Abu is not an active driver');
  });

  test('the pre-migration shape still parses', () {
    final plan = PlanProposal.fromJson({
      'groups': [
        {
          'group_key': 'unzoned',
          'zone_id': null,
          'stops': [
            {'order_id': 'o1', 'sequence': 1},
          ],
        },
      ],
      'unplannable_orders': [
        {
          'group_key': 'z1',
          'reason': 'no_compatible_capacity_sufficient_rider',
          'group_size': 30,
        },
      ],
    });
    expect(plan.groups.single.parts, 1);
    expect(plan.excludedRiders, isEmpty);
    expect(plan.planDate, isNull);
    expect(plan.unplannable.single.orderId, isNull);
    expect(plan.unplannable.single.groupSize, 30);
  });

  test('Malay labels exist for every new reason', () {
    applyUiLocale(const Locale('ms'));
    final plan = PlanProposal.fromJson({
      'unplannable_orders': [
        for (final r in [
          'insufficient_capacity',
          'vehicle_incompatible',
          'in_preparation',
          'sorted_before_run',
          'in_locked_run',
          'declined_awaiting_recovery',
        ])
          {'order_id': r, 'reason': r},
      ],
      'excluded_riders': [
        for (final r in ['rider_has_open_run', 'no_capacity', 'not_eligible'])
          {'rider_id': r, 'reason': r, 'rider_name': 'Ali'},
      ],
    });
    for (final u in plan.unplannable) {
      expect(u.label, isNot(u.reason));
    }
    for (final e in plan.excludedRiders) {
      expect(e.label('Ali'), startsWith('Ali '));
      expect(e.label('Ali'), isNot(contains(e.reason)));
    }
  });
}
