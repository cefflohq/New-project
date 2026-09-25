import 'package:cefflo_rider_mobile/core/app_state.dart';
import 'package:cefflo_rider_mobile/core/routes.dart';
import 'package:cefflo_rider_mobile/data/models.dart';
import 'package:cefflo_rider_mobile/data/rider_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Real-mode repository whose backend reads are fixed in memory. The client
/// is never called: every method the session path uses is overridden.
class _FakeRepo extends RiderRepository {
  _FakeRepo(this.rels)
    : super(SupabaseClient('http://127.0.0.1:1', 'test-publishable-key'));

  final List<RiderRelationship> rels;
  var signedOut = false;

  @override
  Future<List<RiderRelationship>> myRiderRelationships() async => rels;

  @override
  Future<List<RiderOrder>> myOrders(String riderId) async => const [];

  @override
  Future<void> signOut() async => signedOut = true;
}

RiderRelationship _rel(String id, String business, String status) =>
    RiderRelationship(
      id: id,
      businessId: business,
      status: status,
      name: 'Test Driver',
    );

void main() {
  Future<AppState> hydrate(List<RiderRelationship> rels) async {
    final app = AppState(_FakeRepo(rels));
    await app.loadSession();
    return app;
  }

  test('no relationship lands on No Business Connected, not Today', () async {
    final app = await hydrate(const []);
    expect(app.stage, DriverStage.noBusiness);
    expect(app.current.route, DRoute.noBusinessConnected);
    expect(app.active, isNull);
  });

  test('pending relationship lands on Pending Review', () async {
    final app = await hydrate([_rel('r1', 'bA', 'pending')]);
    expect(app.stage, DriverStage.pendingReview);
    expect(app.current.route, DRoute.pendingReview);
    expect(app.active, isNull);
  });

  test('one active relationship lands on Today scoped to that rider', () async {
    final app = await hydrate([_rel('r1', 'bA', 'active')]);
    expect(app.stage, DriverStage.active);
    expect(app.current.route, DRoute.today);
    expect(app.active?.id, 'r1');
  });

  test('multiple active relationships keep an explicit selection', () async {
    final app = await hydrate([
      _rel('r1', 'bA', 'active'),
      _rel('r2', 'bB', 'active'),
    ]);
    expect(app.relationships, hasLength(2));
    app.selectRelationship(app.relationships[1]);
    expect(app.active?.id, 'r2');
    expect(app.active?.businessId, 'bB');
  });

  test('real sign-out revokes through the repository', () async {
    final repo = _FakeRepo([_rel('r1', 'bA', 'active')]);
    final app = AppState(repo);
    await app.loadSession();
    await app.signOut();
    expect(repo.signedOut, isTrue);
    expect(app.relationships, isEmpty);
    expect(app.active, isNull);
  });
}
