/// Boards 03, 04, 05, 07 — the sheet screens that take input, plus the six
/// locked Authentication states they can be in.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens.dart';
import '../widgets.dart';

/// Which locked Authentication state a form screen is showing.
///
/// Nothing here talks to a backend: a prototype has no credentials to be
/// wrong about, so these are driven by local demo timers and by the screen
/// index, never by a real response.
enum AuthState { idle, loading, invalidCredentials, connectionProblem, rateLimited }

// --------------------------------------------------- 03 Email Sign In

class EmailSignInScreen extends StatefulWidget {
  const EmailSignInScreen({
    super.key,
    required this.onBack,
    required this.onForgotPassword,
    required this.onSignUp,
    this.initialState = AuthState.idle,
  });

  final VoidCallback onBack;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;
  final AuthState initialState;

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  late final _email = TextEditingController(
    text: widget.initialState == AuthState.idle ? '' : 'someone@cefflo.test',
  );
  late final _password = TextEditingController(
    text: widget.initialState == AuthState.idle ? '' : 'hunter2hunter2',
  );
  late AuthState _state = widget.initialState;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _error => switch (_state) {
    AuthState.invalidCredentials =>
      'Email or password is incorrect. Try again.',
    AuthState.connectionProblem =>
      'Unable to connect. Check your connection and try again.',
    AuthState.rateLimited =>
      'Too many attempts. Please wait before trying again.',
    _ => null,
  };

  String get _cta =>
      _state == AuthState.connectionProblem ? 'Try again' : 'Sign In';

  Future<void> _submit() async {
    setState(() => _state = AuthState.loading);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    // Auth-only prototype: no screen is locked for "signed in", so the
    // honest demo end-state is the locked failure the boards do define.
    setState(() => _state = AuthState.invalidCredentials);
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    onBack: widget.onBack,
    showHandle: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle(
          'Sign in with Email',
          subtitle: 'Enter your email and password to continue.',
        ),
        const SizedBox(height: Gap.lg),
        AuthField(
          label: 'Email',
          hint: 'you@yourbusiness.com',
          icon: LucideIcons.mail,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: Gap.md),
        AuthField(
          label: 'Password',
          hint: 'Enter your password',
          icon: LucideIcons.lock,
          controller: _password,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          error: _error,
        ),
        const SizedBox(height: Gap.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextLink('Forgot password?', onTap: widget.onForgotPassword),
        ),
        const SizedBox(height: Gap.lg),
        PrimaryButton(
          _cta,
          busy: _state == AuthState.loading,
          busyLabel: 'Signing in…',
          // Rate limited is the one state where the board greys the CTA out.
          onPressed: _state == AuthState.rateLimited ? null : _submit,
        ),
        const SizedBox(height: Gap.lg),
        InlinePrompt(
          question: "Don't have an account?",
          action: 'Sign up',
          onTap: widget.onSignUp,
        ),
      ],
    ),
  );
}

// -------------------------------------------------- 04 Create Account

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.onBack,
    required this.onSignIn,
    required this.onCreated,
  });

  final VoidCallback onBack;
  final VoidCallback onSignIn;
  final ValueChanged<String> onCreated;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  String? _mismatch;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text != _confirm.text) {
      setState(() => _mismatch = 'Passwords must match.');
      return;
    }
    setState(() {
      _mismatch = null;
      _busy = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onCreated(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle(
          'Create your account',
          subtitle: 'Start managing your deliveries.',
          align: TextAlign.left,
        ),
        const SizedBox(height: Gap.lg),
        AuthField(
          label: 'Email',
          hint: 'you@yourbusiness.com',
          icon: LucideIcons.mail,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: Gap.md),
        AuthField(
          label: 'Password',
          hint: 'Enter your password',
          icon: LucideIcons.lock,
          controller: _password,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          helper: 'Use at least 8 characters.',
        ),
        const SizedBox(height: Gap.md),
        AuthField(
          label: 'Confirm password',
          hint: 'Confirm your password',
          icon: LucideIcons.lock,
          controller: _confirm,
          obscure: _obscureConfirm,
          onToggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          error: _mismatch,
        ),
        const SizedBox(height: Gap.lg),
        PrimaryButton(
          'Create account',
          busy: _busy,
          busyLabel: 'Creating…',
          onPressed: _submit,
        ),
        const SizedBox(height: Gap.lg),
        InlinePrompt(
          question: 'Already have an account?',
          action: 'Sign in',
          onTap: widget.onSignIn,
        ),
      ],
    ),
  );
}

// ------------------------------------------------- 05 Forgot Password

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onBack,
    required this.onSent,
    required this.onBackToSignIn,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onSent;
  final VoidCallback onBackToSignIn;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onSent(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle(
          'Forgot password?',
          subtitle: "Enter your email and we'll send you a reset link.",
        ),
        const SizedBox(height: Gap.lg),
        AuthField(
          label: 'Email',
          hint: 'you@yourbusiness.com',
          icon: LucideIcons.mail,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: Gap.lg),
        PrimaryButton(
          'Send reset link',
          busy: _busy,
          busyLabel: 'Sending…',
          onPressed: _submit,
        ),
        const SizedBox(height: Gap.lg),
        Center(
          child: TextLink('Back to sign in', onTap: widget.onBackToSignIn),
        ),
      ],
    ),
  );
}

// ----------------------------------------------- 07 Set a new password

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({
    super.key,
    required this.onBack,
    required this.onUpdated,
    this.startMismatched = false,
  });

  final VoidCallback onBack;
  final VoidCallback onUpdated;

  /// Opens straight into the locked "Password mismatch" state.
  final bool startMismatched;

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  late final _password = TextEditingController(
    text: widget.startMismatched ? 'deliverfast1' : '',
  );
  late final _confirm = TextEditingController(
    text: widget.startMismatched ? 'deliverfast2' : '',
  );
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  late bool _showMismatch = widget.startMismatched;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _matches =>
      _password.text.isNotEmpty && _password.text == _confirm.text;

  Future<void> _submit() async {
    if (!_matches) {
      setState(() => _showMismatch = true);
      return;
    }
    setState(() {
      _showMismatch = false;
      _busy = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle(
          'Set a new password',
          subtitle: 'Choose a strong password for your account.',
        ),
        const SizedBox(height: Gap.lg),
        AuthField(
          label: 'New password',
          hint: 'Enter your new password',
          icon: LucideIcons.lock,
          controller: _password,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          helper: 'Use at least 8 characters.',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Gap.md),
        AuthField(
          label: 'Confirm new password',
          hint: 'Confirm your new password',
          icon: LucideIcons.lock,
          controller: _confirm,
          obscure: _obscureConfirm,
          onToggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          // The board carries this line as a standing requirement, and turns
          // it red once the two fields actually disagree.
          helper: _showMismatch ? null : 'Passwords must match.',
          error: _showMismatch ? 'Passwords must match.' : null,
          onChanged: (_) => setState(() => _showMismatch = false),
        ),
        const SizedBox(height: Gap.lg),
        PrimaryButton(
          'Update password',
          busy: _busy,
          busyLabel: 'Updating…',
          onPressed: _matches ? _submit : null,
        ),
      ],
    ),
  );
}
