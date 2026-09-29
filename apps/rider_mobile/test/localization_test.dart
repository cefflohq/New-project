import 'dart:convert';
import 'dart:io';

import 'package:cefflo_rider_mobile/core/app_state.dart';
import 'package:cefflo_rider_mobile/core/theme.dart';
import 'package:cefflo_rider_mobile/core/ui_locale.dart';
import 'package:cefflo_rider_mobile/data/rider_repository.dart';
import 'package:cefflo_rider_mobile/l10n/l10n.dart';
import 'package:cefflo_rider_mobile/ui/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    applyUiLocale(const Locale('en'));
  });

  group('first launch follows a supported device language', () {
    test('Bahasa Melayu device → BM', () {
      expect(
        resolveDeviceLocale([const Locale('ms', 'MY')]),
        const Locale('ms'),
      );
    });
    test('English device → English', () {
      expect(
        resolveDeviceLocale([const Locale('en', 'US')]),
        const Locale('en'),
      );
    });
    test('unsupported device language → English', () {
      expect(
        resolveDeviceLocale([const Locale('fr'), const Locale('ja')]),
        const Locale('en'),
      );
    });
    test('first supported language in the device list wins', () {
      expect(
        resolveDeviceLocale([
          const Locale('fr'),
          const Locale('ms'),
          const Locale('en'),
        ]),
        const Locale('ms'),
      );
    });
  });

  test('explicit choice persists and overrides the device language', () async {
    final app = AppState(RiderRepository.demo());
    await app.setUiLocale(const Locale('ms'));
    expect(L.done, 'Selesai');

    final restarted = AppState(RiderRepository.demo());
    await restarted.restoreUiLocale();
    expect(restarted.uiLocale, const Locale('ms'));

    await restarted.setUiLocale(const Locale('en'));
    expect(L.done, 'Done');
  });

  test('changing language never touches operational state', () async {
    final app = AppState(RiderRepository.demo());
    final run = app.currentRun;
    final business = app.business;
    final stage = app.stage;
    final orders = app.orders;
    await app.setUiLocale(const Locale('ms'));
    expect(identical(app.currentRun, run), isTrue);
    expect(identical(app.business, business), isTrue);
    expect(app.stage, stage);
    expect(identical(app.orders, orders), isTrue);
  });

  testWidgets('Sign In renders in Bahasa Melayu', (tester) async {
    final app = AppState(RiderRepository.demo());
    await app.setUiLocale(const Locale('ms'));
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: MaterialApp(
          theme: buildRiderTheme(),
          locale: app.uiLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: EmailSignInScreen(
            onSignIn: () {},
            onForgotPassword: () {},
            onSignUp: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Lupa Kata Laluan?'), findsOneWidget);
    expect(find.text('Ada jemputan?'), findsOneWidget);
    expect(find.text('Bahasa Melayu'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsNothing);
  });

  test('every English string has a Bahasa Melayu translation', () {
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    final ms =
        jsonDecode(File('lib/l10n/app_ms.arb').readAsStringSync()) as Map;
    final keys = en.keys.where((k) => !(k as String).startsWith('@'));
    expect(keys.where((k) => !ms.containsKey(k)), isEmpty);
    expect(supportedUiLocales, const [Locale('en'), Locale('ms')]);
  });
}
