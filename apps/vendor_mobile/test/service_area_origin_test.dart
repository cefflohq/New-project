import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/theme.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/l10n/l10n.dart';
import 'package:cefflo_vendor_mobile/ui/screens/planning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live-mode repository with the service-area reads/writes held in memory.
class _FakeRepo extends VendorRepository {
  _FakeRepo({this.saved, this.located})
    : super(
        SupabaseClient(
          'http://127.0.0.1:1',
          'test-publishable-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final ({double latitude, double longitude})? saved;
  final ({double latitude, double longitude})? located;
  final writes = <Map<String, Object?>>[];
  var locateCalls = 0;

  @override
  Future<Map<String, dynamic>> business(String businessId) async => {
    'id': businessId,
    'address': '12 Jalan Test, Petaling Jaya',
    'service_origin_latitude': saved?.latitude,
    'service_origin_longitude': saved?.longitude,
    'service_coverage_radius_km': saved == null ? null : 5,
  };

  @override
  Future<({double latitude, double longitude})?> locateBusinessAddress(
    String businessId,
  ) async {
    locateCalls++;
    return located;
  }

  @override
  Future<Map<String, dynamic>> setServiceArea({
    required String businessId,
    required double latitude,
    required double longitude,
    required num radiusKm,
  }) async {
    writes.add({'lat': latitude, 'lng': longitude, 'r': radiusKm});
    return {};
  }
}

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  tester.view.physicalSize = const Size(393, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final app = AppState(repo)
    ..business = const Business(id: 'b1', name: 'Test', role: 'owner');
  await tester.pumpWidget(
    AppScope(
      state: app,
      child: MaterialApp(
        theme: buildVendorTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ServiceAreaScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => applyUiLocale(const Locale('en')));

  testWidgets('no saved origin: the business address is located and saved', (
    tester,
  ) async {
    final repo = _FakeRepo(located: (latitude: 3.1073, longitude: 101.6067));
    await _pump(tester, repo);
    expect(repo.locateCalls, 1);
    await tester.tap(find.text(L.saveServiceArea));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(repo.writes.single['lat'], 3.1073);
    expect(repo.writes.single['lng'], 101.6067);
  });

  testWidgets('unlocatable address: required state, nothing saved, no KL', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);
    expect(find.text(L.pickupLocationRequired), findsOneWidget);
    expect(find.text(L.tryLocatingAgain), findsOneWidget);
    await tester.tap(find.text(L.saveServiceArea));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(repo.writes, isEmpty);
  });

  testWidgets('a saved origin is kept and never re-geocoded', (tester) async {
    final repo = _FakeRepo(saved: (latitude: 1.4927, longitude: 103.7414));
    await _pump(tester, repo);
    expect(repo.locateCalls, 0);
    await tester.tap(find.text(L.saveServiceArea));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(repo.writes.single['lat'], 1.4927);
    expect(repo.writes.single['lng'], 103.7414);
  });
}
