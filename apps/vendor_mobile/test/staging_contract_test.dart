@Tags(['live'])
library;

import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live contract test against the Cefflo STAGING project.
///
/// Run with:
///   flutter test test/staging_contract_test.dart --tags live \
///     --dart-define=SUPABASE_URL=`https://<ref>.supabase.co` \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=`<publishable key>`
///
/// It proves the client really reaches the canonical backend and that RLS
/// denies unauthenticated access — it never writes and never touches
/// production.
void main() {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  late VendorRepository repo;

  setUpAll(() async {
    if (url.isEmpty || key.isEmpty) return;
    expect(
      url.contains('tomvvmwktehexwhktenw'),
      isTrue,
      reason: 'Live tests must target the staging project only.',
    );
    final client = SupabaseClient(url, key);
    repo = VendorRepository(client);
  });

  test('get_my_businesses exists and is empty for an anonymous caller', () async {
    if (url.isEmpty || key.isEmpty) {
      markTestSkipped('SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY not provided');
      return;
    }
    final businesses = await repo.myBusinesses();
    expect(businesses, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('orders are not readable without a session (RLS holds)', () async {
    if (url.isEmpty || key.isEmpty) {
      markTestSkipped('SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY not provided');
      return;
    }
    final orders = await repo.orders('00000000-0000-0000-0000-000000000000');
    expect(orders, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a contract missing from staging is classified as blocked, not success', () async {
    if (url.isEmpty || key.isEmpty) {
      markTestSkipped('SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY not provided');
      return;
    }
    // propose_delivery_plan exists in supabase/migrations but is not deployed
    // to staging. The client must surface that as a blocked contract rather
    // than reporting a successful action.
    await expectLater(
      () => repo.proposePlan(sessionId: '00000000-0000-0000-0000-000000000000'),
      throwsA(
        isA<RepositoryError>().having(
          (e) => e.isMissingContract,
          'isMissingContract',
          isTrue,
        ),
      ),
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a deployed contract fails with a real backend error, not a blocked state', () async {
    if (url.isEmpty || key.isEmpty) {
      markTestSkipped('SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY not provided');
      return;
    }
    // approve_order is deployed; an anonymous caller must be rejected by the
    // backend's own rules, which is a normal error rather than a missing
    // contract.
    await expectLater(
      () => repo.approveOrder('00000000-0000-0000-0000-000000000000'),
      throwsA(
        isA<RepositoryError>().having(
          (e) => e.isMissingContract,
          'isMissingContract',
          isFalse,
        ),
      ),
    );
  }, timeout: const Timeout(Duration(seconds: 30)));
}
