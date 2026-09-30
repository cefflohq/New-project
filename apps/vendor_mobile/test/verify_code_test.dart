import 'dart:async';

import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/theme.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/ui/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Interaction cover for the 6-digit email verification screen (UI only;
/// the handlers stand in for the auth flow that will own the backend calls).
void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390 * 3, 844 * 3);
    view.devicePixelRatio = 3.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  late List<String> verified;
  late int resends;

  Widget host({
    Future<void> Function(String)? onVerify,
    Future<void> Function()? onResend,
    int cooldown = 60,
    VoidCallback? onContinue,
  }) {
    verified = [];
    resends = 0;
    return AppScope(
      state: AppState(VendorRepository.demo()),
      child: MaterialApp(
        theme: buildVendorTheme(Brightness.light),
        home: VerifyEmailCodeScreen(
          email: 'owner@example.com',
          resendCooldown: cooldown,
          onVerify:
              onVerify ??
              (code) async {
                verified.add(code);
              },
          onResend:
              onResend ??
              () async {
                resends++;
              },
          onContinue: onContinue ?? () {},
          onBack: () {},
          onUseDifferentEmail: () {},
        ),
      ),
    );
  }

  Finder input() => find.byKey(const Key('otp-input'));

  testWidgets('shows the destination, six boxes and a disabled Verify', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump();
    expect(find.text('owner@example.com'), findsWidgets);
    expect(find.text('Enter the 6-digit code we sent to'), findsOneWidget);
    expect(find.byKey(const Key('otp-resend-countdown')), findsOneWidget);
    final input = tester.widget<TextField>(find.byKey(const Key('otp-input')));
    expect(input.keyboardType, TextInputType.number);
    expect(input.autofillHints, contains(AutofillHints.oneTimeCode));
  });

  testWidgets('digits only, capped at six; completing the code verifies once', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.enterText(input(), '12a3');
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(verified, isEmpty);
    await tester.enterText(input(), '123456789');
    await tester.pumpAndSettle();
    expect(verified, ['123456']);
  });

  testWidgets('a pasted code with separators fills all six boxes', (
    tester,
  ) async {
    final pending = Completer<void>();
    String? sent;
    await tester.pumpWidget(
      host(
        onVerify: (code) {
          sent = code;
          return pending.future;
        },
      ),
    );
    await tester.pump();
    await tester.enterText(input(), '482 - 913');
    await tester.pump();
    expect(sent, '482913');
    for (final d in ['4', '8', '2', '9', '1', '3']) {
      expect(find.text(d), findsOneWidget);
    }
    // Nothing reads as verified while the backend is still checking.
    expect(find.byKey(const Key('otp-verified')), findsNothing);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('otp-verified')), findsOneWidget);
  });

  testWidgets('backspace removes the last digit', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.enterText(input(), '123');
    await tester.pump();
    await tester.enterText(input(), '12');
    await tester.pump();
    expect(find.text('3'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('an incorrect code shows the error and never a success', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        onVerify: (_) async => throw const OtpFailure(OtpFailureKind.incorrect),
      ),
    );
    await tester.pump();
    await tester.enterText(input(), '000000');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('otp-error')), findsOneWidget);
    expect(find.byKey(const Key('otp-verified')), findsNothing);
    // Editing the code clears the error.
    await tester.enterText(input(), '00000');
    await tester.pump();
    expect(find.byKey(const Key('otp-error')), findsNothing);
  });

  testWidgets('an expired code clears the boxes and offers a new code', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        cooldown: 0,
        onVerify: (_) async => throw const OtpFailure(OtpFailureKind.expired),
      ),
    );
    await tester.pump();
    await tester.enterText(input(), '111111');
    await tester.pumpAndSettle();
    expect(
      find.text('This code has expired. Request a new code to continue.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('otp-send-new')), findsOneWidget);
    expect(find.text('1'), findsNothing);
    await tester.tap(find.byKey(const Key('otp-send-new')));
    await tester.pumpAndSettle();
    expect(resends, 1);
    expect(find.byKey(const Key('otp-notice')), findsOneWidget);
    expect(find.byKey(const Key('otp-verify')), findsOneWidget);
  });

  testWidgets('resend waits for the cooldown, then sends and restarts it', (
    tester,
  ) async {
    await tester.pumpWidget(host(cooldown: 3));
    await tester.pump();
    expect(find.text('Resend code in 3s'), findsOneWidget);
    expect(find.byKey(const Key('otp-resend')), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(const Key('otp-resend')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(resends, 1);
    expect(
      find.text('A new code is on its way to owner@example.com.'),
      findsOneWidget,
    );
    expect(find.text('Resend code in 3s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a backend retry window replaces the default cooldown', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        cooldown: 0,
        onResend: () async => throw const OtpFailure(
          OtpFailureKind.rateLimited,
          retryAfterSeconds: 42,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('otp-resend')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Resend code in 42s'), findsOneWidget);
    expect(find.byKey(const Key('otp-error')), findsOneWidget);
    await tester.pump(const Duration(seconds: 42));
  });

  testWidgets(
    'verified appears only after the backend accepts; Continue hands off',
    (tester) async {
      var continued = false;
      await tester.pumpWidget(host(onContinue: () => continued = true));
      await tester.pump();
      expect(find.byKey(const Key('otp-verified')), findsNothing);
      await tester.enterText(input(), '246810');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('otp-verified')), findsOneWidget);
      await tester.tap(find.text('Continue'));
      expect(continued, isTrue);
    },
  );

  testWidgets('password recovery hands straight to Set New Password', (
    tester,
  ) async {
    var handedOff = false;
    await tester.pumpWidget(
      AppScope(
        state: AppState(VendorRepository.demo()),
        child: MaterialApp(
          theme: buildVendorTheme(Brightness.light),
          home: VerifyEmailCodeScreen(
            email: 'owner@example.com',
            title: 'Reset your password',
            showVerifiedState: false,
            onVerify: (_) async {},
            onResend: () async {},
            onContinue: () => handedOff = true,
            onBack: () {},
            onUseDifferentEmail: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Reset your password'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('otp-input')), '135790');
    await tester.pumpAndSettle();
    expect(handedOff, isTrue);
    expect(find.byKey(const Key('otp-verified')), findsNothing);
  });
}
