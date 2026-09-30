import 'package:cefflo_rider_mobile/core/app_state.dart';
import 'package:cefflo_rider_mobile/core/routes.dart';
import 'package:cefflo_rider_mobile/core/theme.dart';
import 'package:cefflo_rider_mobile/data/rider_repository.dart';
import 'package:cefflo_rider_mobile/ui/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(AppState app, Widget child) => AppScope(
    state: app,
    child: MaterialApp(theme: buildRiderTheme(), home: child),
  );

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(393 * 3, 852 * 3);
    view.devicePixelRatio = 3;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  testWidgets('a password-recovery link opens D07 Set a new password', (
    tester,
  ) async {
    final app = AppState(RiderRepository.demo());
    await tester.pumpWidget(
      host(
        app,
        AuthFlow(
          initial: DRoute.setNewPassword,
          onAuthenticated: (_) {},
          onPasswordUpdated: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SetNewPasswordScreen), findsOneWidget);
  });

  test('recovery links use the native app callback', () {
    expect(authRedirectUrl, 'cefflo-driver://auth-callback');
  });

  test('a web build returns recovery links to the page it is served from', () {
    expect(
      webAuthRedirectUrl(Uri.parse('https://driver.example.app/?code=abc#/x')),
      'https://driver.example.app/',
    );
    expect(
      webAuthRedirectUrl(Uri.parse('http://127.0.0.1:8080/app/')),
      'http://127.0.0.1:8080/app/',
    );
  });

  test('auth errors map from backend codes, not provider prose', () {
    expect(
      driverAuthErrorText(
        RepositoryError('provider wording', code: 'invalid_credentials'),
      ),
      'Email or password is incorrect. Try again.',
    );
    expect(
      driverAuthErrorText(
        RepositoryError('provider wording', code: 'over_request_rate_limit'),
      ),
      'Too many attempts. Please wait before trying again.',
    );
    expect(
      driverAuthErrorText(RepositoryError('ClientException: Failed to fetch')),
      'Unable to connect. Check your connection and try again.',
    );
  });

  testWidgets('prototype sign-in remains local and usable', (tester) async {
    final app = AppState(RiderRepository.demo());
    var authenticated = false;
    await tester.pumpWidget(
      host(
        app,
        EmailSignInScreen(
          onBack: () {},
          onSignIn: () => authenticated = true,
          onForgotPassword: () {},
          onSignUp: () {},
        ),
      ),
    );

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(authenticated, isTrue);
  });

  testWidgets('Driver Sign In is Email only: no Google or Apple options', (
    tester,
  ) async {
    final app = AppState(RiderRepository.demo());
    await tester.pumpWidget(
      host(app, AuthFlow(initial: DRoute.signIn, onAuthenticated: (_) {})),
    );
    await tester.pump();
    expect(find.byType(EmailSignInScreen), findsOneWidget);
    for (final provider in [
      'Apple',
      'Google',
      'Continue with Apple',
      'Continue with Google',
    ]) {
      expect(find.text(provider), findsNothing, reason: provider);
    }
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Have an invite?'), findsOneWidget);
  });

  testWidgets('Verify Email counts down, then resends through the backend', (
    tester,
  ) async {
    final app = AppState(RiderRepository.demo());
    await tester.pumpWidget(
      host(
        app,
        VerifyEmailScreen(
          email: 'driver@example.test',
          onBack: () {},
          onBackToSignIn: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('driver@example.test'), findsOneWidget);
    // An email was just sent: the resend is cooling down, not fake-disabled.
    expect(find.text('Resend email (60s)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Resend email (59s)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 60));
    expect(find.text('Resend email'), findsOneWidget);

    // The prototype build has no backend: the real call fails and says so.
    // Nothing is shown as sent.
    await tester.tap(find.text('Resend email'));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('driver-resend-sent')), findsNothing);
    expect(find.byKey(const Key('driver-auth-error')), findsOneWidget);
  });

  testWidgets(
    'Forgot Password asks for the 6-digit code sent to that address',
    (tester) async {
      final app = AppState(RiderRepository.demo());
      await tester.pumpWidget(
        host(
          app,
          AuthFlow(initial: DRoute.forgotPassword, onAuthenticated: (_) {}),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'me@example.test');
      await tester.tap(find.text('Send Code'));
      await tester.pump();
      expect(find.byType(VerifyEmailCodeScreen), findsOneWidget);
      expect(find.text('Reset your password'), findsOneWidget);
      expect(find.text('me@example.test'), findsOneWidget);
      expect(find.text('you@domain.com'), findsNothing);
      expect(find.text('Resend code in 60s'), findsOneWidget);
    },
  );

  testWidgets('a refused emailed link opens D09 with real next steps', (
    tester,
  ) async {
    final app = AppState(RiderRepository.demo());
    await tester.pumpWidget(
      host(app, AuthFlow(initial: DRoute.linkExpired, onAuthenticated: (_) {})),
    );
    await tester.pump();
    expect(find.byType(LinkExpiredScreen), findsOneWidget);
    expect(find.text('Resend verification email'), findsOneWidget);
    await tester.tap(find.text('Send a new reset link'));
    await tester.pump();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });
}
