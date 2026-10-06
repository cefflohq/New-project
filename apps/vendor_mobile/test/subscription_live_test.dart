import 'dart:io';

import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/theme.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/data/plans.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/l10n/l10n.dart';
import 'package:cefflo_vendor_mobile/ui/screens/subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The server price book as seeded by 20261007110000 (published values).
const _plans = [
  {
    'key': 'free',
    'name': 'Free',
    'monthly_price_myr': 0,
    'delivery_allowance': 150,
    'driver_cap': 3,
    'zone_cap': 2,
    'team_user_cap': 1,
    'most_popular': false,
    'self_serve': true,
  },
  {
    'key': 'grow',
    'name': 'Grow',
    'monthly_price_myr': 99,
    'delivery_allowance': 500,
    'driver_cap': 10,
    'zone_cap': 5,
    'team_user_cap': 3,
    'most_popular': false,
    'self_serve': true,
  },
  {
    'key': 'operate',
    'name': 'Operate',
    'monthly_price_myr': 199,
    'delivery_allowance': 1500,
    'driver_cap': null,
    'zone_cap': null,
    'team_user_cap': 10,
    'most_popular': true,
    'self_serve': true,
  },
  {
    'key': 'scale',
    'name': 'Scale',
    'monthly_price_myr': 499,
    'delivery_allowance': 5000,
    'driver_cap': null,
    'zone_cap': null,
    'team_user_cap': 25,
    'most_popular': false,
    'self_serve': true,
  },
  {
    'key': 'enterprise',
    'name': 'Enterprise',
    'monthly_price_myr': null,
    'delivery_allowance': null,
    'driver_cap': null,
    'zone_cap': null,
    'team_user_cap': null,
    'most_popular': false,
    'self_serve': false,
  },
];

class _FakeRepo extends VendorRepository {
  _FakeRepo({this.fail = false})
    : super(
        SupabaseClient(
          'http://127.0.0.1:1',
          'test-publishable-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final bool fail;
  final changes = <String>[];

  @override
  Future<List<Map<String, dynamic>>> subscriptionPlanRows() async => [
    for (final p in _plans) Map<String, dynamic>.from(p),
  ];

  @override
  Future<Map<String, dynamic>> mySubscription(String businessId) async {
    if (fail) throw RepositoryError('network');
    return {
      'plan_key': 'free',
      'status': 'active',
      'deliveries_used': 42,
      'delivery_allowance': 150,
      'drivers_active': 2,
      'zones_active': 1,
      'team_users': 1,
      'payment_enabled': false,
    };
  }

  @override
  Future<String> requestPlanChange(String businessId, String planKey) async {
    changes.add(planKey);
    return 'payment_required';
  }
}

Future<AppState> _pump(
  WidgetTester tester,
  _FakeRepo repo,
  Widget screen,
) async {
  tester.view.physicalSize = const Size(393, 1600);
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
        home: Scaffold(body: screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return app;
}

void main() {
  setUp(() => applyUiLocale(const Locale('en')));

  testWidgets('V-50 live: real plan, status and usage; no fake renewal', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo(), const SubscriptionScreen());
    expect(find.text('Free plan'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('42 / 150'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.textContaining('Next renewal'), findsNothing);
  });

  testWidgets('V-50 live: load failure shows the error state', (tester) async {
    await _pump(tester, _FakeRepo(fail: true), const SubscriptionScreen());
    expect(find.textContaining('network'), findsOneWidget);
  });

  testWidgets(
    'V-51 live: server plans, monthly only, no candidate note, no Enterprise card',
    (tester) async {
      final repo = _FakeRepo();
      final app = await _pump(tester, repo, const SubscriptionScreen());
      expect(app.plans.map((p) => p.id), ['free', 'grow', 'operate', 'scale']);
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: MaterialApp(
            theme: buildVendorTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: ChoosePlanScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Yearly'), findsNothing);
      expect(find.text(L.plansPricesCurrentPricingCandidate), findsNothing);
      expect(find.text('150 deliveries a month'), findsOneWidget);
      expect(find.text(L.mostPopular), findsOneWidget);
    },
  );

  testWidgets(
    'V-52 live: Subscribe stops at the payment boundary, nothing changes',
    (tester) async {
      final repo = _FakeRepo();
      final app = await _pump(tester, repo, const SubscriptionScreen());
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: MaterialApp(
            theme: buildVendorTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: ReviewPaymentScreen(selection: 'operate:monthly'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('•••• 4242'),
        findsNothing,
        reason: 'no fake saved card',
      );
      await tester.tap(find.text('Subscribe'));
      await tester.pumpAndSettle();
      expect(repo.changes, ['operate']);
      expect(find.text(L.planChangeNotAvailableTitle), findsOneWidget);
      expect(app.currentPlanId, 'free', reason: 'never activated');
    },
  );

  test('app copy matches the server price book (no drift)', () {
    final seed = File(
      '../../supabase/migrations/20261007110000_subscription_plans_free_default.sql',
    ).readAsStringSync();
    for (final p in subscriptionPlans) {
      expect(
        seed.contains("('${p.id}',"),
        isTrue,
        reason: 'plan ${p.id} seeded',
      );
      expect(
        RegExp("'${p.id}', +'[A-Za-z]+', +${p.monthlyPrice}, +${p.deliveries},")
            .hasMatch(seed),
        isTrue,
        reason: '${p.id} price/allowance match the locked price book',
      );
    }
  });
}
