import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../widgets.dart';

/// V-02 — canonical Supabase email authentication.
///
/// Apple and Google are part of the approved sign-in order but no OAuth
/// provider is configured for this environment, so they are shown as an
/// explicit dependency state rather than a button that cannot work
/// (audit fix 7). Recovery is reconciled to the same email code flow instead
/// of a separate password reset that the backend does not implement.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  bool sent = false;
  bool busy = false;
  String? error;
  String? notice;

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!email.text.contains('@')) {
      setState(() => error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AppScope.read(context).repo.sendEmailOtp(email.text);
      if (mounted) {
        setState(() {
          sent = true;
          notice = 'We sent a sign-in code to ${email.text.trim()}.';
        });
      }
    } on RepositoryError catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final app = AppScope.read(context);
      await app.repo.verifyEmailOtp(email.text, code.text);
      await app.loadSession();
    } on RepositoryError catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.gutter),
          children: [
            const SizedBox(height: 40),
            Text('Cefflo Vendor', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Sign in to your business workspace.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Gap.section),
            CefField(
              label: 'Email address',
              controller: email,
              keyboardType: TextInputType.emailAddress,
            ),
            if (sent)
              CefField(
                label: 'Sign-in code',
                controller: code,
                keyboardType: TextInputType.number,
              ),
            if (notice != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: Text(notice!, style: Theme.of(context).textTheme.bodySmall),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: Text(
                  error!,
                  style: TextStyle(color: c.attention, fontSize: 13),
                ),
              ),
            CefButton(
              sent ? 'Verify and continue' : 'Email me a sign-in code',
              busy: busy,
              onTap: sent ? _verify : _send,
            ),
            if (sent) ...[
              const SizedBox(height: Gap.cardGap),
              CefButton(
                'Use a different email',
                secondary: true,
                onTap: () => setState(() {
                  sent = false;
                  notice = null;
                  code.clear();
                }),
              ),
            ],
            const SizedBox(height: Gap.section),
            const StateBlock.blocked(
              'Apple and Google sign-in are part of the approved order but no '
              'OAuth provider is configured for this environment yet.',
            ),
          ],
        ),
      ),
    );
  }
}
