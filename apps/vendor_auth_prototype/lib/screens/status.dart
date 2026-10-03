/// Boards 06, 08, 10, 11, 12 — the sheet screens that report a state rather
/// than take input.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens.dart';
import '../widgets.dart';

// ------------------------------------------------ 06 Check Your Email

class CheckYourEmailScreen extends StatelessWidget {
  const CheckYourEmailScreen({
    super.key,
    required this.onBack,
    required this.onBackToSignIn,
    required this.onTryAnotherEmail,
  });

  final VoidCallback onBack;
  final VoidCallback onBackToSignIn;
  final VoidCallback onTryAnotherEmail;

  @override
  Widget build(BuildContext context) => SheetScaffold(
    onBack: onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Gap.xs),
        // Board 06 shows this envelope bare and large; boards 10/11/12 ring
        // theirs. Each screen follows its own board.
        const StatusIcon(LucideIcons.mail, circled: false),
        const SizedBox(height: Gap.lg),
        const SheetTitle(
          'Check your email',
          subtitle:
              "If an account exists for this email, you'll receive a "
              'password reset link.',
        ),
        const SizedBox(height: Gap.md),
        const CenteredNote('Check your spam folder too.', muted: true),
        const SizedBox(height: Gap.xl),
        PrimaryButton('Back to sign in', onPressed: onBackToSignIn),
        const SizedBox(height: Gap.sm),
        OutlineButton('Try another email', onPressed: onTryAnotherEmail),
      ],
    ),
  );
}

// --------------------------------------------- 08 Password Updated

class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => SheetScaffold(
    onBack: onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Gap.sm),
        const SuccessDisc(),
        const SizedBox(height: Gap.lg),
        const SheetTitle(
          'Password updated',
          subtitle: 'Your password has been successfully changed.',
        ),
        const SizedBox(height: Gap.lg),
        const CenteredNote('You can now sign in with your new password.'),
        const SizedBox(height: Gap.xl),
        PrimaryButton('Continue to sign in', onPressed: onContinue),
      ],
    ),
  );
}

// ----------------------------------------------- 10 Verify Your Email

class VerifyYourEmailScreen extends StatefulWidget {
  const VerifyYourEmailScreen({
    super.key,
    required this.onBack,
    required this.onBackToSignIn,
    required this.onUseDifferentEmail,
    this.startSending = false,
  });

  final VoidCallback onBack;
  final VoidCallback onBackToSignIn;
  final VoidCallback onUseDifferentEmail;

  /// Opens straight into the locked "Resend in progress" state.
  final bool startSending;

  @override
  State<VerifyYourEmailScreen> createState() => _VerifyYourEmailScreenState();
}

class _VerifyYourEmailScreenState extends State<VerifyYourEmailScreen> {
  late bool _sending = widget.startSending;

  Future<void> _resend() async {
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Gap.xs),
        const StatusIcon(LucideIcons.mail),
        const SizedBox(height: Gap.lg),
        const SheetTitle(
          'Verify your email',
          subtitle:
              'Open the verification link in your email to confirm your '
              'account.',
        ),
        const SizedBox(height: Gap.md),
        const CenteredNote('Check your spam folder too.', muted: true),
        const SizedBox(height: Gap.xl),
        PrimaryButton(
          'Resend verification email',
          busy: _sending,
          busyLabel: 'Sending…',
          onPressed: _resend,
        ),
        const SizedBox(height: Gap.sm),
        OutlineButton(
          'Use a different email',
          // The board greys the secondary out while the resend is in flight.
          onPressed: _sending ? null : widget.onUseDifferentEmail,
        ),
        const SizedBox(height: Gap.lg),
        Center(
          child: TextLink('Back to sign in', onTap: widget.onBackToSignIn),
        ),
      ],
    ),
  );
}

// -------------------------------------------------- 11 Email Verified

class EmailVerifiedScreen extends StatelessWidget {
  const EmailVerifiedScreen({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => SheetScaffold(
    onBack: onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Gap.xs),
        const StatusIcon(LucideIcons.check),
        const SizedBox(height: Gap.lg),
        const SheetTitle(
          'Email verified',
          subtitle: 'Your email is confirmed.\nSign in to continue.',
        ),
        const SizedBox(height: Gap.xl),
        PrimaryButton('Continue to sign in', onPressed: onContinue),
      ],
    ),
  );
}

// ------------------------------------- 12 Verification Link Expired

class VerificationLinkExpiredScreen extends StatefulWidget {
  const VerificationLinkExpiredScreen({
    super.key,
    required this.onBack,
    required this.onBackToSignIn,
  });

  final VoidCallback onBack;
  final VoidCallback onBackToSignIn;

  @override
  State<VerificationLinkExpiredScreen> createState() =>
      _VerificationLinkExpiredScreenState();
}

class _VerificationLinkExpiredScreenState
    extends State<VerificationLinkExpiredScreen> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: navyDeep,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Prototype: no verification email is actually sent.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Gap.xs),
        const StatusIcon(LucideIcons.clock),
        const SizedBox(height: Gap.lg),
        const SheetTitle(
          'Verification link expired',
          subtitle:
              'This link has expired or is invalid.\n'
              'Request a new verification email.',
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
          'Send new verification email',
          busy: _busy,
          busyLabel: 'Sending…',
          onPressed: _resend,
        ),
        const SizedBox(height: Gap.lg),
        Center(
          child: TextLink('Back to sign in', onTap: widget.onBackToSignIn),
        ),
      ],
    ),
  );
}
