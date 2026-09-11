@Tags(['live'])
library;

import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live contract tests against the Cefflo STAGING project.
///
/// Run with:
///   flutter test test/staging_contract_test.dart --tags live \
///     --dart-define=SUPABASE_URL=`https://<ref>.supabase.co` \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=`<publishable key>`
///
/// These prove the client really reaches the canonical backend and that RLS
/// and the RPC grant model hold. They never write and never touch production.
void main() {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  const anyUuid = '00000000-0000-0000-0000-000000000000';
  final configured = url.isNotEmpty && key.isNotEmpty;

  late VendorRepository repo;

  setUpAll(() {
    if (!configured) return;
    expect(
      url.contains('tomvvmwktehexwhktenw'),
      isTrue,
      reason: 'Live tests must target the staging project only.',
    );
    repo = VendorRepository(SupabaseClient(url, key));
  });

  /// The contract exists and answered with its own tenant rules, rather than
  /// being absent from this environment.
  Future<void> expectDeployedButRefused(Future<void> Function() call) =>
      expectLater(
        call,
        throwsA(
          isA<RepositoryError>().having(
            (e) => e.isMissingContract,
            'isMissingContract',
            isFalse,
          ),
        ),
      );

  test('get_my_businesses is deployed and denied to anonymous callers', () async {
    if (!configured) return markTestSkipped('staging config not provided');
    // f2_11_rpc_grant_hardening revoked this from anon. An anonymous caller
    // must be refused outright rather than receiving an empty list, which
    // would be indistinguishable from "you have no businesses".
    await expectLater(
      () => repo.myBusinesses(),
      throwsA(
        isA<RepositoryError>()
            .having((e) => e.isMissingContract, 'isMissingContract', isFalse)
            .having((e) => e.message, 'message', contains('permission denied')),
      ),
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('orders are not readable without a session (RLS holds)', () async {
    if (!configured) return markTestSkipped('staging config not provided');
    expect(await repo.orders(anyUuid), isEmpty);
  }, timeout: const Timeout(Duration(seconds: 30)));

  group('coverage, planning and dispatch contracts are deployed', () {
    // Each of these was previously missing from staging. They must now exist
    // (never "missing contract") and refuse an anonymous caller on their own
    // tenant rules instead.
    test('propose_delivery_plan', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(() => repo.proposePlan(anyUuid));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('list_plannable_orders', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(() => repo.plannableOrders(anyUuid));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('order_coverage_status', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(() => repo.orderCoverageStatus(anyUuid));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('is_within_coverage', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.isWithinCoverage(businessId: anyUuid, latitude: 3.07, longitude: 101.5),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('set_business_service_area', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.setServiceArea(
          businessId: anyUuid,
          latitude: 3.07,
          longitude: 101.5,
          radiusKm: 10,
        ),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('check_run_vehicle_capacity', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.checkRunCapacity(riderId: anyUuid, orderIds: const [anyUuid]),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('create_delivery_session', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.createDeliverySession(businessId: anyUuid),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('build_rider_run', () async {
      if (!configured) return markTestSkipped('staging config not provided');
      await expectDeployedButRefused(
        () => repo.buildRiderRun(
          sessionId: anyUuid,
          riderId: anyUuid,
          orderIds: const [anyUuid],
          idempotencyKey: '11111111-1111-4111-8111-111111111111',
        ),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  test('previously working contracts still respond (no regression)', () async {
    if (!configured) return markTestSkipped('staging config not provided');
    await expectDeployedButRefused(() => repo.approveOrder(anyUuid));
    await expectDeployedButRefused(() => repo.createZone(anyUuid, 'probe'));
    await expectDeployedButRefused(
      () => repo.updateOrder(orderId: anyUuid, customerName: 'probe'),
    );
  }, timeout: const Timeout(Duration(seconds: 45)));
}
