/// CEFFLO Vendor Auth — UI prototype of the Founder-locked boards.
///
/// Standalone on purpose. There is no Supabase client, no repository and no
/// network call anywhere in this package: every transition is local state, so
/// the prototype cannot touch auth truth or the shipped implementation in
/// apps/vendor_mobile. Light Mode only; Dark Mode is HOLD and absent.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'screens/entry.dart';
import 'screens/forms.dart';
import 'screens/status.dart';
import 'tokens.dart';

void main() => runApp(const PrototypeApp());

/// Every locked destination, so the screen index can reach all of them
/// without having to walk a flow to get there.
enum Stage {
  splash('01 Splash'),
  signIn('02 Sign In'),
  emailSignIn('03 Email Sign In'),
  signUp('04 Create Account'),
  forgotPassword('05 Forgot Password'),
  checkEmail('06 Check Your Email'),
  setNewPassword('07 Set a New Password'),
  passwordUpdated('08 Password Updated'),
  verifyEmail('10 Verify Your Email'),
  emailVerified('11 Email Verified'),
  linkExpired('12 Verification Link Expired'),
  stateLoading('State · Loading'),
  stateInvalid('State · Invalid credentials'),
  stateMismatch('State · Password mismatch'),
  stateConnection('State · Connection problem'),
  stateRateLimited('State · Rate limited'),
  stateResending('State · Resend in progress');

  const Stage(this.label);

  final String label;
}

class PrototypeApp extends StatelessWidget {
  const PrototypeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CEFFLO Vendor Auth — prototype',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        brightness: Brightness.light,
      ),
      textTheme: cefTextTheme(),
    ),
    home: const AuthFlow(),
  );
}

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  final List<Stage> _stack = [Stage.splash];
  String _language = 'English';

  Stage get _stage => _stack.last;

  void _go(Stage next) => setState(() => _stack.add(next));

  void _replace(Stage next) => setState(() {
    _stack
      ..clear()
      ..add(next);
  });

  void _back() => setState(() {
    if (_stack.length > 1) {
      _stack.removeLast();
    } else {
      _stack
        ..clear()
        ..add(Stage.signIn);
    }
  });

  Future<void> _openLanguageSheet() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
      ),
      builder: (_) => LanguageSheet(selected: _language),
    );
    if (picked != null && mounted) setState(() => _language = picked);
  }

  Future<void> _openIndex() async {
    final picked = await showModalBottomSheet<Stage>(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
      ),
      builder: (_) => _ScreenIndex(current: _stage),
    );
    if (picked != null && mounted) _replace(picked);
  }

  Widget _screen() => switch (_stage) {
    Stage.splash => SplashScreen(onReady: () => _replace(Stage.signIn)),
    Stage.signIn => SignInScreen(
      language: _language,
      onLanguage: _openLanguageSheet,
      onEmail: () => _go(Stage.emailSignIn),
      onSignUp: () => _go(Stage.signUp),
    ),
    Stage.emailSignIn => EmailSignInScreen(
      onBack: _back,
      onForgotPassword: () => _go(Stage.forgotPassword),
      onSignUp: () => _go(Stage.signUp),
    ),
    Stage.signUp => SignUpScreen(
      onBack: _back,
      onSignIn: () => _replace(Stage.emailSignIn),
      onCreated: (_) => _go(Stage.verifyEmail),
    ),
    Stage.forgotPassword => ForgotPasswordScreen(
      onBack: _back,
      onSent: (_) => _go(Stage.checkEmail),
      onBackToSignIn: () => _replace(Stage.emailSignIn),
    ),
    Stage.checkEmail => CheckYourEmailScreen(
      onBack: _back,
      onBackToSignIn: () => _replace(Stage.emailSignIn),
      onTryAnotherEmail: () => _replace(Stage.forgotPassword),
    ),
    Stage.setNewPassword => SetNewPasswordScreen(
      onBack: _back,
      onUpdated: () => _replace(Stage.passwordUpdated),
    ),
    Stage.passwordUpdated => PasswordUpdatedScreen(
      onBack: _back,
      onContinue: () => _replace(Stage.emailSignIn),
    ),
    Stage.verifyEmail => VerifyYourEmailScreen(
      onBack: _back,
      onBackToSignIn: () => _replace(Stage.emailSignIn),
      onUseDifferentEmail: () => _replace(Stage.signUp),
    ),
    Stage.emailVerified => EmailVerifiedScreen(
      onBack: _back,
      onContinue: () => _replace(Stage.emailSignIn),
    ),
    Stage.linkExpired => VerificationLinkExpiredScreen(
      onBack: _back,
      onBackToSignIn: () => _replace(Stage.emailSignIn),
    ),

    // The locked Authentication states, opened directly.
    Stage.stateLoading => EmailSignInScreen(
      onBack: _back,
      onForgotPassword: () => _go(Stage.forgotPassword),
      onSignUp: () => _go(Stage.signUp),
      initialState: AuthState.loading,
    ),
    Stage.stateInvalid => EmailSignInScreen(
      onBack: _back,
      onForgotPassword: () => _go(Stage.forgotPassword),
      onSignUp: () => _go(Stage.signUp),
      initialState: AuthState.invalidCredentials,
    ),
    Stage.stateConnection => EmailSignInScreen(
      onBack: _back,
      onForgotPassword: () => _go(Stage.forgotPassword),
      onSignUp: () => _go(Stage.signUp),
      initialState: AuthState.connectionProblem,
    ),
    Stage.stateRateLimited => EmailSignInScreen(
      onBack: _back,
      onForgotPassword: () => _go(Stage.forgotPassword),
      onSignUp: () => _go(Stage.signUp),
      initialState: AuthState.rateLimited,
    ),
    Stage.stateMismatch => SetNewPasswordScreen(
      onBack: _back,
      onUpdated: () => _replace(Stage.passwordUpdated),
      startMismatched: true,
    ),
    Stage.stateResending => VerifyYourEmailScreen(
      onBack: _back,
      onBackToSignIn: () => _replace(Stage.emailSignIn),
      onUseDifferentEmail: () => _replace(Stage.signUp),
      startSending: true,
    ),
  };

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _screen(),
      // Prototype chrome, deliberately not part of any locked board: a way
      // to reach every screen without walking a flow. Hidden on Splash so
      // the brand moment stays clean.
      if (_stage != Stage.splash)
        // Top-right, over the Navy header. Bottom-right covered the primary
        // CTA on every sheet screen — the one control you most need to press.
        Positioned(
          right: 12,
          top: 0,
          child: SafeArea(child: _IndexButton(onTap: _openIndex)),
        ),
    ],
  );
}

class _IndexButton extends StatelessWidget {
  const _IndexButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    // Sits on the Navy backdrop, so it reads as an overlay on the header
    // rather than a second solid pill competing with the brand.
    color: Colors.white.withValues(alpha: .14),
    shape: StadiumBorder(
      side: BorderSide(color: Colors.white.withValues(alpha: .22)),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.layoutGrid, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Screens',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ScreenIndex extends StatelessWidget {
  const _ScreenIndex({required this.current});

  final Stage current;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD7DAE2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          const Text(
            'Locked screens',
            style: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Prototype navigation — not part of the locked UI.',
            style: TextStyle(
              color: inkMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: Gap.md),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final stage in Stage.values)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      stage.label,
                      style: TextStyle(
                        color: stage == current ? navy : inkMuted,
                        fontSize: 15,
                        fontWeight: stage == current
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    trailing: stage == current
                        ? const Icon(LucideIcons.check, size: 18, color: navy)
                        : null,
                    onTap: () => Navigator.of(context).pop(stage),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
