@Tags(['live'])
library;

import 'package:cefflo_rider_mobile/data/rider_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Read-only contract checks against the canonical CEFFLO staging project.
///
/// Anonymous calls must either return no rows through RLS or be rejected by
/// the deployed RPC's own authorization checks. A missing RPC is always a
/// failure. These probes do not create users, upload proof, or persist data.
void main() {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  const anyUuid = '00000000-0000-0000-0000-000000000000';
  final configured = url.isNotEmpty && key.isNotEmpty;

  late RiderRepository repo;

  setUpAll(() {
    if (!configured) return;
    expect(
      url.contains('tomvvmwktehexwhktenw'),
      isTrue,
      reason: 'Live tests must target the staging project only.',
    );
    repo = RiderRepository(SupabaseClient(url, key));
  });

  Future<void> expectDeployedButRefused(Future<void> Function() call) =>
      expectLater(
        call,
        throwsA(
          isA<RepositoryError>().having(
            (error) => error.isMissingContract,
            'isMissingContract',
            isFalse,
          ),
        ),
      );

  test('rider relationships require a signed-in identity', () async {
    if (!configured) return markTestSkipped('staging config not provided');
    await expectLater(
      repo.myRiderRelationships,
      throwsA(isA<RepositoryError>()),
    );
  });

  test('orders and sessions are hidden from anonymous callers', () async {
    if (!configured) return markTestSkipped('staging config not provided');
    expect(await repo.myOrders(anyUuid), isEmpty);
    expect(await repo.sessions(anyUuid), isEmpty);
  }, timeout: const Timeout(Duration(seconds: 30)));

  group('rider workflow contracts are deployed', () {
    test('accept_assignment', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.acceptAssignment(riderId: anyUuid, orderId: anyUuid),
      );
    });

    test('decline_assignment', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.declineAssignment(riderId: anyUuid, orderId: anyUuid),
      );
    });

    test('accept_run', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.acceptRun(riderId: anyUuid, sessionId: anyUuid),
      );
    });

    test('decline_run', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.declineRun(riderId: anyUuid, sessionId: anyUuid),
      );
    });

    test('save_run_sequence', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.saveRunSequence(
          riderId: anyUuid,
          sessionId: anyUuid,
          orderedOrderIds: const [anyUuid],
        ),
      );
    });

    test('start_pickup_run', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.startPickupRun(riderId: anyUuid, sessionId: anyUuid),
      );
    });

    test('start_run_delivery', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.startRunDelivery(riderId: anyUuid, sessionId: anyUuid),
      );
    });

    test('rider_transition', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.transition(
          riderId: anyUuid,
          orderId: anyUuid,
          next: 'arrived',
        ),
      );
    });

    test('rider_report_delivery_issue', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.reportDeliveryIssue(
          riderId: anyUuid,
          orderId: anyUuid,
          reasonType: 'customer_unreachable',
        ),
      );
    });
  });
}
