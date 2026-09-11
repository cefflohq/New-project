/// Vendor Flutter Auth family — implementation of the Founder-locked UI
/// batch (2026-09-11), per CEFFLO_FLUTTER_UI_LOCK_IMPLEMENTATION_MASTER.md.
///
/// Locked boards implemented here:
///   01 Splash · 02 Sign In · 03 Email Sign In · 04 Create Account
///   05 Forgot Password · 06 Check Your Email · 10 Verify Your Email
///   11 Email Verified · 12 Verification Link Expired
///   + the six locked Authentication states (loading, invalid credentials,
///     password mismatch, connection problem, rate limited, resend in
///     progress).
///
/// Light Mode only. Every colour below is an explicit Experience System
/// token, so these screens render identically whatever theme mode the app
/// is in — Dark Mode is HOLD and is not implemented or expanded here.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';

// ---------------------------------------------------------------- palette
//
// Navy anchor is the canonical #12213E. The locked boards show it as a
// diagonal gradient with a lighter blue lift toward the centre-right; the
// two companion stops below are shades of that same anchor, not new brand
// colours.
const _navyDeep = Color(0xFF0A1730);
const _navyBase = CefColors.navy; // #12213E
const _navyLift = Color(0xFF1E4585);

const _sheetRadius = 28.0;
const _buttonRadius = 14.0;
const _buttonHeight = 54.0;
const _fieldRadius = 14.0;

const _disabledFill = Color(0xFFE6E8EE);
const _disabledInk = Color(0xFF9AA0B4);

// ------------------------------------------------------------ auth shell

/// Owns which locked auth screen is showing. Kept local to the auth family
/// so the app's typed VRoute inventory stays exactly as it is — none of
/// these transitions add or rename a route.
enum _Stage {
  splash,
  signIn,
  emailSignIn,
  signUp,
  forgotPassword,
  checkEmail,
  verifyEmail,
  emailVerified,
  linkExpired,
  setNewPassword,
}

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  final List<_Stage> _stack = [_Stage.splash];

  /// Carried between stages so "Check your email" / "Verify your email" can
  /// show and act on the address the Rider actually typed.
  String _email = '';

  _Stage get _stage => _stack.last;

  void _go(_Stage next, {String? email}) {
    setState(() {
      if (email != null) _email = email;
      _stack.add(next);
    });
  }

  void _replace(_Stage next, {String? email}) {
    setState(() {
      if (email != null) _email = email;
      _stack
        ..clear()
        ..add(next);
    });
  }

  void _back() {
    setState(() {
      if (_stack.length > 1) {
        _stack.removeLast();
      } else {
        _stack
          ..clear()
          ..add(_Stage.signIn);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _Stage.splash => SplashScreen(onReady: () => _replace(_Stage.signIn)),
      _Stage.signIn => SignInScreen(
        onEmail: () => _go(_Stage.emailSignIn),
        onSignUp: () => _go(_Stage.signUp),
      ),
      _Stage.emailSignIn => EmailSignInScreen(
        onBack: _back,
        onForgotPassword: () => _go(_Stage.forgotPassword),
        onSignUp: () => _go(_Stage.signUp),
        onNeedsVerification: (email) => _go(_Stage.verifyEmail, email: email),
      ),
      _Stage.signUp => SignUpScreen(
        onBack: _back,
        onSignIn: () => _replace(_Stage.emailSignIn),
        onNeedsVerification: (email) => _go(_Stage.verifyEmail, email: email),
      ),
      _Stage.forgotPassword => ForgotPasswordScreen(
        onBack: _back,
        onSent: (email) => _go(_Stage.checkEmail, email: email),
      ),
      _Stage.checkEmail => CheckYourEmailScreen(
        onBack: _back,
        onBackToSignIn: () => _replace(_Stage.emailSignIn),
        onTryAnotherEmail: () => _replace(_Stage.forgotPassword),
      ),
      _Stage.verifyEmail => VerifyYourEmailScreen(
        email: _email,
        onBack: _back,
        onBackToSignIn: () => _replace(_Stage.emailSignIn),
        onUseDifferentEmail: () => _replace(_Stage.signUp),
        onExpired: () => _replace(_Stage.linkExpired, email: _email),
      ),
      _Stage.emailVerified => EmailVerifiedScreen(
        onContinue: () => _replace(_Stage.emailSignIn),
      ),
      _Stage.linkExpired => VerificationLinkExpiredScreen(
        email: _email,
        onBack: _back,
        onBackToSignIn: () => _replace(_Stage.emailSignIn),
      ),
      _Stage.setNewPassword => SetNewPasswordScreen(
        onBack: _back,
        onUpdated: () => _replace(_Stage.emailSignIn),
      ),
    };
  }
}

// ------------------------------------------------------- shared chrome

/// The locked Navy backdrop: diagonal gradient plus the soft lighter-blue
/// lift the boards show toward the centre-right.
class _NavyBackdrop extends StatelessWidget {
  const _NavyBackdrop({required this.child});
  final Widget child;

  @override
  // SizedBox.expand is load-bearing: DecoratedBox sizes to its child, so on
  // Splash — whose widest child is the ~168px progress indicator — the
  // gradient shrink-wrapped to a narrow strip and left the rest of the screen
  // flat navy. The other screens hid the bug behind full-width buttons.
  Widget build(BuildContext context) => SizedBox.expand(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navyDeep, _navyBase, _navyLift, _navyBase],
          stops: [0.0, 0.34, 0.66, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.05, -0.12),
            radius: 0.95,
            colors: [Color(0x332F6BD0), Color(0x00000000)],
          ),
        ),
        child: child,
      ),
    ),
  );
}

/// D-35 canonical primary lockup (mark + wordmark), bundled from
/// docs/cefflo/brand/assets/logo/ and never redrawn.
class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.height = 150});
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/cefflo-logo-primary.png',
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    // The canonical asset is 4375x4375; decoding it at full size costs
    // ~76MB per instance. Decode at 3x the display size instead — the
    // file itself is untouched, only how much of it we rasterize.
    cacheWidth: (height * 3).round(),
  );
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) => Text(
    'Operate Today.\nGrow Tomorrow.',
    textAlign: TextAlign.center,
    style: TextStyle(
      color: Colors.white.withValues(alpha: .88),
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w500,
    ),
  );
}

/// Navy header (Back + lockup) above a white rounded sheet — the shared
/// layout every locked form screen after Sign In uses.
class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.child,
    this.onBack,
    this.showHandle = false,
  });

  final Widget child;
  final VoidCallback? onBack;
  final bool showHandle;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _navyBase,
    body: _NavyBackdrop(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  if (onBack != null)
                    _BackButton(onTap: onBack!)
                  else
                    const SizedBox(width: Gap.lg),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.lg),
              child: const _BrandLockup(height: 104),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_sheetRadius),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showHandle) ...[
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
                        ],
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Back',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.chevronLeft, color: Colors.white, size: 21),
            SizedBox(width: 4),
            Text(
              'Back',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _navyBase,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF5C647A),
          fontSize: 14,
          height: 1.45,
        ),
      ),
      const SizedBox(height: Gap.section),
    ],
  );
}

// -------------------------------------------------------------- controls

/// Locked primary action: CEFFLO Yellow, near-black label, 14px radius.
/// Busy renders the locked "Signing in…"/"Sending…" spinner state; disabled
/// renders the locked grey state.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
    this.label, {
    required this.onTap,
    this.busy = false,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null && !busy;
    return SizedBox(
      height: _buttonHeight,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: CefColors.accent,
          foregroundColor: CefColors.onAccent,
          disabledBackgroundColor: busy ? CefColors.accent : _disabledFill,
          disabledForegroundColor: busy ? CefColors.onAccent : _disabledInk,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
        child: busy
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: CefColors.onAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    busyLabel ?? label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: disabled ? _disabledInk : CefColors.onAccent,
                ),
              ),
      ),
    );
  }
}

/// Locked secondary action: white fill, Navy outline, Navy label.
class _OutlineButton extends StatelessWidget {
  const _OutlineButton(this.label, {required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _buttonHeight,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _navyBase,
        disabledForegroundColor: _disabledInk,
        side: BorderSide(
          color: onTap == null ? _disabledFill : _navyBase,
          width: 1.4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// Locked plain text link ("Back to sign in", "Forgot password?").
class _TextLink extends StatelessWidget {
  const _TextLink(
    this.label, {
    required this.onTap,
    this.align = TextAlign.center,
  });
  final String label;
  final VoidCallback? onTap;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Text(
      label,
      textAlign: align,
      style: const TextStyle(
        color: _navyBase,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
        decorationColor: _navyBase,
      ),
    ),
  );
}

/// Locked form field: optional label, leading icon, optional eye toggle,
/// optional helper line, optional error line.
class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.label,
    this.helper,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? label;
  final String? helper;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              color: _navyBase,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF181818),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9AA0B4),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(widget.icon, size: 19, color: _navyBase),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 19,
                      color: const Color(0xFF6B7385),
                    ),
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                  )
                : null,
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 17),
            enabledBorder: _border(
              hasError ? CefColors.light.attention : const Color(0xFFDDE1EA),
            ),
            focusedBorder: _border(
              hasError ? CefColors.light.attention : _navyBase,
              width: 1.5,
            ),
            disabledBorder: _border(const Color(0xFFEDEFF4)),
            errorBorder: _border(CefColors.light.attention),
            focusedErrorBorder: _border(CefColors.light.attention, width: 1.5),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.error!,
            style: TextStyle(
              color: CefColors.light.attention,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ] else if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helper!,
            style: const TextStyle(color: Color(0xFF7A8194), fontSize: 12.5),
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.2}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Locked status icon: Navy outline circle with a Navy glyph.
class _StatusIcon extends StatelessWidget {
  const _StatusIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _navyBase, width: 2),
      ),
      child: Icon(icon, size: 34, color: _navyBase),
    ),
  );
}

/// One line of prose under a status icon.
class _CenteredNote extends StatelessWidget {
  const _CenteredNote(this.text, {this.muted = false});
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: muted ? const Color(0xFF8A90A0) : const Color(0xFF5C647A),
      fontSize: muted ? 13 : 14,
      height: 1.45,
    ),
  );
}

/// Turns a backend failure into the locked error copy.
///
/// Public so the locked mapping can be asserted directly in tests rather
/// than inferred from a rendered frame.
///
/// Branches on GoTrue's own `error_code` first so the locked states are
/// driven by backend truth rather than by English message text; message
/// sniffing is only the fallback for transport errors, which carry no code.
/// Anything the locked board does not define surfaces the backend's own
/// message rather than an invented one.
String authErrorText(RepositoryError e) {
  switch (e.code) {
    case 'invalid_credentials':
    case 'invalid_grant':
      return 'Email or password is incorrect. Try again.';
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
    case 'over_sms_send_rate_limit':
      return 'Too many attempts. Please wait before trying again.';
  }
  final m = e.message.toLowerCase();
  if (m.contains('socketexception') ||
      m.contains('failed host lookup') ||
      m.contains('clientexception') ||
      m.contains('xmlhttprequest') ||
      m.contains('connection') ||
      m.contains('network')) {
    return 'Unable to connect. Check your connection and try again.';
  }
  if (m.contains('rate limit') ||
      m.contains('too many') ||
      m.contains('for security purposes')) {
    return 'Too many attempts. Please wait before trying again.';
  }
  if (m.contains('invalid login') || m.contains('invalid credentials')) {
    return 'Email or password is incorrect. Try again.';
  }
  return e.message;
}

/// The backend's own signal that the account exists but is unverified —
/// the locked Verify-your-email screen's entry condition.
bool needsEmailVerification(RepositoryError e) =>
    e.code == 'email_not_confirmed' ||
    e.message.toLowerCase().contains('not confirmed');

bool _isConnectionError(String text) => text.startsWith('Unable to connect');
bool _isRateLimited(String text) => text.startsWith('Too many attempts');

// ------------------------------------------------------------ 01 Splash

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onReady});
  final VoidCallback onReady;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Real bootstrap, not a fixed decorative timer: when a session already
  /// exists this awaits the canonical session load, so the brand moment
  /// lasts exactly as long as the work does.
  Future<void> _bootstrap() async {
    final app = AppScope.read(context);
    final started = DateTime.now();
    if (app.repo.currentUser != null) {
      await app.loadSession();
    }
    final elapsed = DateTime.now().difference(started);
    const minimumBrandMoment = Duration(milliseconds: 900);
    if (elapsed < minimumBrandMoment) {
      await Future<void>.delayed(minimumBrandMoment - elapsed);
    }
    if (mounted) widget.onReady();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _navyBase,
    body: _NavyBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 5),
            const _BrandLockup(height: 210),
            const Spacer(flex: 5),
            const _Tagline(),
            const SizedBox(height: Gap.section),
            _SplashProgress(animation: _progress),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    ),
  );
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 168,
    height: 4,
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final active = (animation.value * 3).floor() % 3;
        return Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                height: 4,
                decoration: BoxDecoration(
                  color: i == active
                      ? CefColors.accent
                      : Colors.white.withValues(alpha: .28),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        );
      },
    ),
  );
}

// ----------------------------------------------------------- 02 Sign In

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onEmail,
    required this.onSignUp,
  });
  final VoidCallback onEmail;
  final VoidCallback onSignUp;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String? _providerError;
  bool _busy = false;

  Future<void> _provider(OAuthProvider provider) async {
    setState(() {
      _busy = true;
      _providerError = null;
    });
    try {
      await AppScope.read(context).repo.signInWithProvider(provider);
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _providerError = authErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openLanguageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
      ),
      builder: (context) => const _LanguageSheet(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _navyBase,
    body: _NavyBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              // IntrinsicHeight gives the Column a bounded height inside the
              // scroll view, so the Spacer below can actually pin the
              // tagline to the bottom edge the locked board shows it at.
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _LanguagePill(onTap: _openLanguageSheet),
                      ),
                      const SizedBox(height: 34),
                      const Center(child: _BrandLockup(height: 156)),
                      const SizedBox(height: 26),
                      const Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to manage your deliveries today.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .82),
                          fontSize: 14.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _ProviderButton(
                        label: 'Continue with Apple',
                        background: Colors.black,
                        foreground: Colors.white,
                        leading: const Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 23,
                        ),
                        onTap: _busy
                            ? null
                            : () => _provider(OAuthProvider.apple),
                      ),
                      const SizedBox(height: 12),
                      _ProviderButton(
                        label: 'Continue with Google',
                        background: Colors.white,
                        foreground: const Color(0xFF181818),
                        leading: const _GoogleGlyph(),
                        onTap: _busy
                            ? null
                            : () => _provider(OAuthProvider.google),
                      ),
                      const SizedBox(height: 12),
                      _ProviderButton(
                        label: 'Continue with Email',
                        background: Colors.white,
                        foreground: const Color(0xFF181818),
                        leading: const Icon(
                          LucideIcons.mail,
                          size: 20,
                          color: _navyBase,
                        ),
                        onTap: widget.onEmail,
                      ),
                      if (_providerError != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _providerError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFC9C3),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Container(height: 1, color: Colors.white24),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .75),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(height: 1, color: Colors.white24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .85),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onSignUp,
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 28),
                      const _Tagline(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: const Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.globe, color: Colors.white, size: 19),
          SizedBox(width: 8),
          Text(
            'English',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4),
          Icon(LucideIcons.chevronDown, color: Colors.white, size: 18),
        ],
      ),
    ),
  );
}

/// The four languages the CEFFLO product supports. Only English is
/// selectable in this build: no Flutter localization layer is wired yet, so
/// offering the others would be a language switch that changes nothing.
/// Disclosed as a gap rather than faked.
///
/// NOT FOUNDER-LOCKED. The locked Sign In board shows the language pill, but
/// no board locks what the pill opens. This is a deliberately plain
/// disclosure sheet standing in for that unlocked screen so the locked
/// control is not dead — it awaits a Founder lock of its own.
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  // Endonyms would be the right call, but the bundled Manrope carries no Han
  // or Tamil glyphs and CanvasKit does not fall back to system fonts, so
  // '中文' and 'தமிழ்' rendered as tofu boxes. English names render correctly
  // in the type we actually ship; restoring the endonyms needs a font that
  // covers those scripts to be bundled first.
  static const _languages = [
    ('English', 'en', true),
    ('Bahasa Melayu', 'ms', false),
    ('Chinese (Simplified)', 'zh', false),
    ('Tamil', 'ta', false),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
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
          const SizedBox(height: 18),
          const Text(
            'Language',
            style: TextStyle(
              color: _navyBase,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          for (final (label, _, available) in _languages)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                opacity: available ? 1 : .55,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: available ? _navyBase : const Color(0xFFDDE1EA),
                      width: available ? 1.4 : 1.2,
                    ),
                    borderRadius: BorderRadius.circular(_fieldRadius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF181818),
                          ),
                        ),
                      ),
                      if (available)
                        const Icon(
                          LucideIcons.check,
                          size: 19,
                          color: _navyBase,
                        )
                      else
                        const Text(
                          'Not in this build',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A90A0),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'Only English is available in this build. The other languages are '
            'part of the product but their Flutter translations are not wired '
            'yet.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF8A90A0),
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Widget leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _buttonHeight,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: .6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 12),
          // Flexible so a longer localized label or a larger text scale
          // shortens the label instead of overflowing the button.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Placeholder mark. Google's official multi-colour "G" is a third-party
/// brand asset that is not in this repository, and this project's own logo
/// doctrine forbids redrawing a brand mark — so this renders a neutral
/// stand-in and the gap is reported rather than approximated.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFDDE1EA), width: 1.2),
    ),
    child: const Text(
      'G',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4285F4),
      ),
    ),
  );
}

// ----------------------------------------------------- 03 Email Sign In

class EmailSignInScreen extends StatefulWidget {
  const EmailSignInScreen({
    super.key,
    required this.onBack,
    required this.onForgotPassword,
    required this.onSignUp,
    required this.onNeedsVerification,
  });

  final VoidCallback onBack;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;
  final ValueChanged<String> onNeedsVerification;

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final app = AppScope.read(context);
      await app.repo.signInWithPassword(
        email: _email.text,
        password: _password.text,
      );
      await app.loadSession();
    } on RepositoryError catch (e) {
      if (needsEmailVerification(e)) {
        if (mounted) widget.onNeedsVerification(_email.text.trim());
        return;
      }
      if (mounted) setState(() => _error = authErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connection = _error != null && _isConnectionError(_error!);
    final limited = _error != null && _isRateLimited(_error!);
    return _SheetScaffold(
      onBack: widget.onBack,
      showHandle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetTitle(
            'Sign in with Email',
            'Enter your email and password to continue.',
          ),
          _AuthField(
            controller: _email,
            label: 'Email',
            hint: 'you@yourbusiness.com',
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            enabled: !_busy,
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: _password,
            label: 'Password',
            hint: 'Enter your password',
            icon: LucideIcons.lock,
            obscure: true,
            enabled: !_busy,
            error: _error,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _TextLink(
              'Forgot password?',
              onTap: _busy ? null : widget.onForgotPassword,
              align: TextAlign.right,
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            connection ? 'Try again' : 'Sign in',
            busyLabel: 'Signing in…',
            busy: _busy,
            onTap: limited ? null : _signIn,
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 14, color: Color(0xFF5C647A)),
              ),
              _TextLink('Sign up', onTap: _busy ? null : widget.onSignUp),
            ],
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------- 04 Create Account

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.onBack,
    required this.onSignIn,
    required this.onNeedsVerification,
  });

  final VoidCallback onBack;
  final VoidCallback onSignIn;
  final ValueChanged<String> onNeedsVerification;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _confirmError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_password.text != _confirm.text) {
      setState(() => _confirmError = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _confirmError = null;
    });
    try {
      final app = AppScope.read(context);
      final needsVerification = await app.repo.signUpWithPassword(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      if (needsVerification) {
        widget.onNeedsVerification(_email.text.trim());
      } else {
        await app.loadSession();
      }
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = authErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Create your account',
          style: TextStyle(
            color: _navyBase,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Start managing your deliveries.',
          style: TextStyle(
            color: Color(0xFF5C647A),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: Gap.section),
        _AuthField(
          controller: _email,
          label: 'Email',
          hint: 'you@yourbusiness.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          enabled: !_busy,
          error: _error,
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: _password,
          label: 'Password',
          hint: 'Enter your password',
          icon: LucideIcons.lock,
          obscure: true,
          helper: 'Use at least 8 characters.',
          enabled: !_busy,
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: _confirm,
          label: 'Confirm password',
          hint: 'Confirm your password',
          icon: LucideIcons.lock,
          obscure: true,
          enabled: !_busy,
          error: _confirmError,
          onChanged: (_) {
            if (_confirmError != null) setState(() => _confirmError = null);
          },
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          'Create account',
          busyLabel: 'Creating account…',
          busy: _busy,
          onTap: _create,
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Already have an account? ',
              style: TextStyle(fontSize: 14, color: Color(0xFF5C647A)),
            ),
            _TextLink('Sign in', onTap: _busy ? null : widget.onSignIn),
          ],
        ),
      ],
    ),
  );
}

// -------------------------------------------------- 05 Forgot Password

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onBack,
    required this.onSent,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onSent;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(context).repo.sendPasswordReset(_email.text);
      if (mounted) widget.onSent(_email.text.trim());
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = authErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetTitle(
          'Forgot password?',
          "Enter your email and we'll send you a reset link.",
        ),
        _AuthField(
          controller: _email,
          label: 'Email',
          hint: 'you@yourbusiness.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          enabled: !_busy,
          error: _error,
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          _error != null && _isConnectionError(_error!)
              ? 'Try again'
              : 'Send reset link',
          busyLabel: 'Sending…',
          busy: _busy,
          onTap: _error != null && _isRateLimited(_error!) ? null : _send,
        ),
        const SizedBox(height: 18),
        _TextLink('Back to sign in', onTap: _busy ? null : widget.onBack),
      ],
    ),
  );
}

// ------------------------------------------------- 06 Check Your Email

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
  Widget build(BuildContext context) => _SheetScaffold(
    onBack: onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        const _StatusIcon(LucideIcons.mail),
        const SizedBox(height: 20),
        const Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _navyBase,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        const _CenteredNote(
          "If an account exists for this email, you'll receive a password "
          'reset link.',
        ),
        const SizedBox(height: 12),
        const _CenteredNote('Check your spam folder too.', muted: true),
        const SizedBox(height: 26),
        _PrimaryButton('Back to sign in', onTap: onBackToSignIn),
        const SizedBox(height: 12),
        _OutlineButton('Try another email', onTap: onTryAnotherEmail),
      ],
    ),
  );
}

// ------------------------------------------------ 10 Verify Your Email

class VerifyYourEmailScreen extends StatefulWidget {
  const VerifyYourEmailScreen({
    super.key,
    required this.email,
    required this.onBack,
    required this.onBackToSignIn,
    required this.onUseDifferentEmail,
    required this.onExpired,
  });

  final String email;
  final VoidCallback onBack;
  final VoidCallback onBackToSignIn;
  final VoidCallback onUseDifferentEmail;
  final VoidCallback onExpired;

  @override
  State<VerifyYourEmailScreen> createState() => _VerifyYourEmailScreenState();
}

class _VerifyYourEmailScreenState extends State<VerifyYourEmailScreen> {
  bool _busy = false;
  String? _error;
  String? _notice;

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await AppScope.read(context).repo.resendSignUpVerification(widget.email);
      if (mounted) {
        setState(() => _notice = 'Verification email sent to ${widget.email}.');
      }
    } on RepositoryError catch (e) {
      final text = authErrorText(e);
      if (e.message.toLowerCase().contains('expired')) {
        if (mounted) widget.onExpired();
        return;
      }
      if (mounted) setState(() => _error = text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        const _StatusIcon(LucideIcons.mail),
        const SizedBox(height: 20),
        const Text(
          'Verify your email',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _navyBase,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        const _CenteredNote(
          'Open the verification link in your email to confirm your account.',
        ),
        const SizedBox(height: 12),
        const _CenteredNote('Check your spam folder too.', muted: true),
        if (_notice != null) ...[
          const SizedBox(height: 12),
          _CenteredNote(_notice!),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CefColors.light.attention,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 26),
        _PrimaryButton(
          'Resend verification email',
          busyLabel: 'Sending…',
          busy: _busy,
          onTap: _error != null && _isRateLimited(_error!) ? null : _resend,
        ),
        const SizedBox(height: 12),
        _OutlineButton(
          'Use a different email',
          onTap: _busy ? null : widget.onUseDifferentEmail,
        ),
        const SizedBox(height: 18),
        _TextLink(
          'Back to sign in',
          onTap: _busy ? null : widget.onBackToSignIn,
        ),
      ],
    ),
  );
}

// --------------------------------------------------- 11 Email Verified

class EmailVerifiedScreen extends StatelessWidget {
  const EmailVerifiedScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        const _StatusIcon(LucideIcons.check),
        const SizedBox(height: 20),
        const Text(
          'Email verified',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _navyBase,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        const _CenteredNote('Your email is confirmed.\nSign in to continue.'),
        const SizedBox(height: 26),
        _PrimaryButton('Continue to sign in', onTap: onContinue),
      ],
    ),
  );
}

// ------------------------------------------ 12 Verification Link Expired

class VerificationLinkExpiredScreen extends StatefulWidget {
  const VerificationLinkExpiredScreen({
    super.key,
    required this.email,
    required this.onBack,
    required this.onBackToSignIn,
  });

  final String email;
  final VoidCallback onBack;
  final VoidCallback onBackToSignIn;

  @override
  State<VerificationLinkExpiredScreen> createState() =>
      _VerificationLinkExpiredScreenState();
}

class _VerificationLinkExpiredScreenState
    extends State<VerificationLinkExpiredScreen> {
  late final TextEditingController _email = TextEditingController(
    text: widget.email,
  );
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await AppScope.read(context).repo.resendSignUpVerification(_email.text);
      if (mounted) {
        setState(
          () => _notice = 'Verification email sent to ${_email.text.trim()}.',
        );
      }
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = authErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        const _StatusIcon(LucideIcons.clock),
        const SizedBox(height: 20),
        const Text(
          'Verification link expired',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _navyBase,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        const _CenteredNote(
          'This link has expired or is invalid.\nRequest a new verification email.',
        ),
        if (_notice != null) ...[
          const SizedBox(height: 12),
          _CenteredNote(_notice!),
        ],
        const SizedBox(height: 22),
        _AuthField(
          controller: _email,
          label: 'Email',
          hint: 'you@yourbusiness.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          enabled: !_busy,
          error: _error,
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          'Send new verification email',
          busyLabel: 'Sending…',
          busy: _busy,
          onTap: _error != null && _isRateLimited(_error!) ? null : _send,
        ),
        const SizedBox(height: 18),
        _TextLink(
          'Back to sign in',
          onTap: _busy ? null : widget.onBackToSignIn,
        ),
      ],
    ),
  );
}

// ------------------------------------------------ Set a new password

/// Locked "Set a new password" state. Reachable only with an active
/// recovery session (i.e. after the emailed reset link has been opened);
/// this screen never creates one itself.
class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({
    super.key,
    required this.onBack,
    required this.onUpdated,
  });

  final VoidCallback onBack;
  final VoidCallback onUpdated;

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _confirmError;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _password.text.isNotEmpty &&
      _confirm.text.isNotEmpty &&
      _password.text == _confirm.text;

  Future<void> _update() async {
    if (_password.text != _confirm.text) {
      setState(() => _confirmError = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(context).repo.updatePassword(_password.text);
      if (mounted) widget.onUpdated();
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = authErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetTitle(
          'Set a new password',
          'Choose a strong password for your account.',
        ),
        _AuthField(
          controller: _password,
          label: 'New password',
          hint: 'Enter a new password',
          icon: LucideIcons.lock,
          obscure: true,
          enabled: !_busy,
          error: _error,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: _confirm,
          label: 'Confirm password',
          hint: 'Confirm your password',
          icon: LucideIcons.lock,
          obscure: true,
          enabled: !_busy,
          error:
              _confirmError ??
              (_confirm.text.isNotEmpty && _password.text != _confirm.text
                  ? 'Passwords do not match.'
                  : null),
          onChanged: (_) => setState(() => _confirmError = null),
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          'Update password',
          busyLabel: 'Updating…',
          busy: _busy,
          onTap: _canSubmit ? _update : null,
        ),
      ],
    ),
  );
}
