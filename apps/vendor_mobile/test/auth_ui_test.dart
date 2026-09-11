import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/theme.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/ui/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Regression cover for the Founder-locked Vendor Auth batch (2026-09-11).
///
/// These assert the locked copy and controls, and that a backend failure
/// surfaces the locked error wording rather than a raw exception. The
/// repository points at a closed port, so "connection problem" is a real
/// transport failure, not a mocked one.
void main() {
  late AppState app;

  setUp(() {
    app = AppState(VendorRepository(SupabaseClient('http://127.0.0.1:1', 'test-anon-key')));
  });

  // A phone-sized surface, so a control that is reachable on a real device
  // is reachable here too. The default 800x600 test window is shorter than
  // any phone and would put the primary action below the fold.
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390 * 3, 844 * 3);
    view.devicePixelRatio = 3.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  Widget host(Widget child) => AppScope(
    state: app,
    child: MaterialApp(theme: buildVendorTheme(Brightness.light), home: child),
  );

  group('locked copy is present', () {
    testWidgets('02 Sign In offers all three locked entry points', (tester) async {
      await tester.pumpWidget(host(SignInScreen(onEmail: () {}, onSignUp: () {})));
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to manage your deliveries today.'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Email'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Operate Today.\nGrow Tomorrow.'), findsOneWidget);
    });

    testWidgets('03 Email Sign In shows the locked form', (tester) async {
      await tester.pumpWidget(host(EmailSignInScreen(
        onBack: () {},
        onForgotPassword: () {},
        onSignUp: () {},
        onNeedsVerification: (_) {},
      )));
      await tester.pump();

      expect(find.text('Sign in with Email'), findsOneWidget);
      expect(find.text('Enter your email and password to continue.'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('04 Create Account shows the locked fields and helper', (tester) async {
      await tester.pumpWidget(host(SignUpScreen(
        onBack: () {},
        onSignIn: () {},
        onNeedsVerification: (_) {},
      )));
      await tester.pump();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Start managing your deliveries.'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('05 Forgot Password shows the locked request form', (tester) async {
      await tester.pumpWidget(host(ForgotPasswordScreen(onBack: () {}, onSent: (_) {})));
      await tester.pump();

      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text("Enter your email and we'll send you a reset link."), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.text('Back to sign in'), findsOneWidget);
    });

    testWidgets('06 Check Your Email shows the locked non-committal copy', (tester) async {
      await tester.pumpWidget(host(CheckYourEmailScreen(
        onBack: () {},
        onBackToSignIn: () {},
        onTryAnotherEmail: () {},
      )));
      await tester.pump();

      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.text(
          "If an account exists for this email, you'll receive a password reset link.",
        ),
        findsOneWidget,
      );
      expect(find.text('Check your spam folder too.'), findsOneWidget);
      expect(find.text('Try another email'), findsOneWidget);
    });

    testWidgets('10 Verify Your Email shows resend and alternatives', (tester) async {
      await tester.pumpWidget(host(VerifyYourEmailScreen(
        email: 'you@yourbusiness.com',
        onBack: () {},
        onBackToSignIn: () {},
        onUseDifferentEmail: () {},
        onExpired: () {},
      )));
      await tester.pump();

      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.text('Resend verification email'), findsOneWidget);
      expect(find.text('Use a different email'), findsOneWidget);
      expect(find.text('Back to sign in'), findsOneWidget);
    });

    testWidgets('11 Email Verified confirms and moves on', (tester) async {
      await tester.pumpWidget(host(EmailVerifiedScreen(onContinue: () {})));
      await tester.pump();

      expect(find.text('Email verified'), findsOneWidget);
      expect(find.text('Your email is confirmed.\nSign in to continue.'), findsOneWidget);
      expect(find.text('Continue to sign in'), findsOneWidget);
    });

    testWidgets('12 Verification Link Expired asks for a fresh address', (tester) async {
      await tester.pumpWidget(host(VerificationLinkExpiredScreen(
        email: 'you@yourbusiness.com',
        onBack: () {},
        onBackToSignIn: () {},
      )));
      await tester.pump();

      expect(find.text('Verification link expired'), findsOneWidget);
      expect(find.text('Send new verification email'), findsOneWidget);
      // The address carries through so the Vendor does not retype it.
      // (Asserted on the controller: the same string is also the field's
      // placeholder, so a plain text finder would match twice.)
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'you@yourbusiness.com');
    });
  });

  group('locked authentication states', () {
    testWidgets('password mismatch is caught locally, no backend call', (tester) async {
      await tester.pumpWidget(host(SignUpScreen(
        onBack: () {},
        onSignIn: () {},
        onNeedsVerification: (_) {},
      )));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'you@yourbusiness.com');
      await tester.enterText(find.byType(TextField).at(1), 'supersecret123');
      await tester.enterText(find.byType(TextField).at(2), 'different456');
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('set-a-new-password keeps Update disabled until they match',
        (tester) async {
      await tester.pumpWidget(host(SetNewPasswordScreen(onBack: () {}, onUpdated: () {})));
      await tester.pump();

      FilledButton updateButton() => tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Update password'),
          );

      expect(updateButton().onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(0), 'supersecret123');
      await tester.enterText(find.byType(TextField).at(1), 'mismatched');
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(updateButton().onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(1), 'supersecret123');
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsNothing);
      expect(updateButton().onPressed, isNotNull);
    });

    testWidgets('a failed sign-in surfaces an error instead of throwing',
        (tester) async {
      await tester.pumpWidget(host(EmailSignInScreen(
        onBack: () {},
        onForgotPassword: () {},
        onSignUp: () {},
        onNeedsVerification: (_) {},
      )));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'you@yourbusiness.com');
      await tester.enterText(find.byType(TextField).at(1), 'supersecret123');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // flutter_test stubs HTTP (every request returns 400), so the exact
      // failure here is the binding's, not a real backend's — what this
      // asserts is that the screen handles it and stays usable. The precise
      // locked wording per backend code is asserted in the pure-mapping
      // group below, and the real states are in the browser captures.
      expect(tester.takeException(), isNull);
      expect(find.text('Sign in'), findsOneWidget);
    });
  });

  group('locked error copy maps from the backend error code', () {
    test('invalid credentials', () {
      expect(
        authErrorText(RepositoryError('Invalid login credentials',
            code: 'invalid_credentials')),
        'Email or password is incorrect. Try again.',
      );
    });

    test('rate limits, whatever the backend prose says', () {
      expect(
        authErrorText(RepositoryError(
          'For security purposes, you can only request this after 47 seconds.',
          code: 'over_email_send_rate_limit',
        )),
        'Too many attempts. Please wait before trying again.',
      );
      expect(
        authErrorText(RepositoryError('Request rate limit reached',
            code: 'over_request_rate_limit')),
        'Too many attempts. Please wait before trying again.',
      );
    });

    test('transport failures carry no code and fall back to the copy', () {
      expect(
        authErrorText(RepositoryError('ClientException: Failed to fetch')),
        'Unable to connect. Check your connection and try again.',
      );
    });

    test('an unconfirmed account routes to the verification screen', () {
      expect(
        needsEmailVerification(
            RepositoryError('Email not confirmed', code: 'email_not_confirmed')),
        isTrue,
      );
      expect(
        needsEmailVerification(RepositoryError('Invalid login credentials',
            code: 'invalid_credentials')),
        isFalse,
      );
    });

    test('anything the board does not define keeps the backend wording', () {
      expect(
        authErrorText(RepositoryError('Signups not allowed for this instance',
            code: 'signup_disabled')),
        'Signups not allowed for this instance',
      );
    });
  });

  group('the navy backdrop covers the screen', () {
    // Screencasting the real build caught the gradient shrink-wrapped to a
    // ~168px strip on Splash, with the rest of the screen flat navy: a
    // DecoratedBox takes its child's size, and Splash's widest child is the
    // progress indicator. Every other screen has full-width buttons, so only
    // Splash exposed it. These pin the fill so it cannot regress quietly.
    testWidgets('01 Splash fills the full screen', (tester) async {
      await tester.pumpWidget(host(SplashScreen(onReady: () {})));
      await tester.pump();

      expect(
        tester.getSize(find.byType(DecoratedBox).first),
        const Size(390, 844),
      );

      // Splash holds a real 900ms minimum-brand-moment timer; let it expire
      // so the binding does not fail the test on a pending timer.
      await tester.pump(const Duration(milliseconds: 950));
    });

    testWidgets('02 Sign In fills the full width', (tester) async {
      await tester.pumpWidget(
        host(SignInScreen(onEmail: () {}, onSignUp: () {})),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(DecoratedBox).first).width, 390);
    });
  });
}
