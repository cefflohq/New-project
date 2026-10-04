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
/// Light Mode only (the app pins ThemeMode.light; Dark Mode is HOLD). The
/// sheets use the canonical controls and tokens from widgets.dart/theme.dart;
/// only the auth backdrops and third-party marks carry their own colours.
library;

import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/keep_signed_in.dart';
import '../../core/browser_history.dart';
import '../../core/auth_access.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../brand_block.dart';
import '../system_bars.dart';
import '../widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

import '../../core/ui_locale.dart';

// ---------------------------------------------------------------- palette
//
// Splash and every auth screen paint the canonical Vendor blue
// (CefGradients.brand, D-51); no blue is declared here.

/// Error copy sitting directly on the blue backdrop (Sign In), where the
/// canonical attention red would not be legible.
const _onBackdropError = Color(0xFFFFC9C3);

/// Top corner radius of the white auth sheet (and the language picker).
const _sheetRadius = 28.0;

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
  verifyCode,
  recoveryCode,
  emailVerified,
  linkExpired,
  setNewPassword,
}

/// Preview-build-only deterministic entry points for Founder visual audit.
/// This does not participate in canonical product navigation.
class AuthAuditScreen extends StatelessWidget {
  const AuthAuditScreen({super.key, required this.id});

  final int id;

  void _noop() {}

  @override
  Widget build(BuildContext context) => switch (id) {
    1 => SplashScreen(onReady: _noop),
    2 => SignInScreen(onEmail: _noop, onSignUp: _noop),
    3 => EmailSignInScreen(
      onBack: _noop,
      onForgotPassword: _noop,
      onSignUp: _noop,
      onNeedsVerification: (_) {},
    ),
    4 => SignUpScreen(
      onBack: _noop,
      onSignIn: _noop,
      onNeedsVerification: (_) {},
    ),
    5 => ForgotPasswordScreen(onBack: _noop, onSent: (_) {}),
    6 => CheckYourEmailScreen(
      onBack: _noop,
      onBackToSignIn: _noop,
      onTryAnotherEmail: _noop,
    ),
    7 => SetNewPasswordScreen(onBack: _noop, onUpdated: _noop),
    8 => const _PasswordUpdatedAuditScreen(),
    _ => const SizedBox.shrink(),
  };
}

/// V08 · Password Updated is not a standalone screen/route — it is the
/// shared [runAsyncFeedback] success popup, shown over Set a new password
/// once the update completes, before returning to Sign In. This audit entry
/// renders that real flow (Set a new password underneath, popup on top) so
/// the Founder can review the actual popup rather than a placeholder.
class _PasswordUpdatedAuditScreen extends StatefulWidget {
  const _PasswordUpdatedAuditScreen();

  @override
  State<_PasswordUpdatedAuditScreen> createState() =>
      _PasswordUpdatedAuditScreenState();
}

class _PasswordUpdatedAuditScreenState
    extends State<_PasswordUpdatedAuditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      runAsyncFeedback(
        context,
        action: () async {},
        processingTitle: L.updatingPassword,
        processingSubtitle: L.savingNewPassword,
        successTitle: L.passwordUpdated,
        successSubtitle: L.canNowSignNewPassword,
      );
    });
  }

  void _noop() {}

  @override
  Widget build(BuildContext context) =>
      SetNewPasswordScreen(onBack: _noop, onUpdated: _noop);
}

class AuthFlow extends StatefulWidget {
  const AuthFlow({
    super.key,
    this.onPrototypeAuthenticated,
    this.onPrototypeSignedUp,
    this.recovery = false,
    this.linkRejected = false,
    this.onRecoveryDone,
    this.onCodeHold,
    this.access = AuthAccess.vendor,
  });

  /// Holds the auth screens on top while a 6-digit code flow finishes:
  /// verifying a code creates a session, and without the hold the app root
  /// would leave the auth screens before "Email verified" is shown — or,
  /// for password recovery, before the new password is set.
  final ValueChanged<bool>? onCodeHold;

  /// Which Sign-In variant opens (D-74). The rest of the auth suite is
  /// shared; the role is resolved by the server after sign-in.
  final AuthAccess access;

  /// Opened from a password-recovery link: start at Set New Password.
  final bool recovery;

  /// Opened from an emailed link the server refused: start at Link
  /// Expired, offering a new verification email or a new reset link.
  final bool linkRejected;

  /// Called after the recovered password is saved.
  final VoidCallback? onRecoveryDone;

  final VoidCallback? onPrototypeAuthenticated;

  /// UI-prototype-only: a brand new demo account goes through the
  /// first-time business setup wizard (V06-V10) instead of straight to
  /// Today, mirroring what a real sign-up would do.
  final VoidCallback? onPrototypeSignedUp;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  late final List<_Stage> _stack = [
    widget.recovery
        ? _Stage.setNewPassword
        : widget.linkRejected
        ? _Stage.linkExpired
        : _Stage.splash,
  ];

  /// Carried between stages so "Check your email" / "Verify your email" can
  /// show and act on the address the Rider actually typed.
  String _email = '';

  _Stage get _stage => _stack.last;

  void _go(_Stage next, {String? email}) {
    setState(() {
      if (email != null) _email = email;
      _stack.add(next);
    });
    // One browser entry per auth step: the Android edge-swipe / browser
    // Back steps back here instead of leaving the app for a blank page.
    if (hasBrowserHistory) {
      pushBrowserHistoryEntry();
      _browserDepth++;
    }
  }

  int _browserDepth = 0;
  AppState? _app;

  /// Browser Back inside the auth screens (see AppState.onBrowserBack).
  bool _onBrowserBack() {
    if (!mounted) return false;
    if (_browserDepth > 0) _browserDepth--;
    if (_stack.length <= 1) return false;
    setState(() => _stack.removeLast());
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app ??= AppScope.read(context)..authBrowserBack = _onBrowserBack;
  }

  @override
  void dispose() {
    if (_app?.authBrowserBack == _onBrowserBack) _app!.authBrowserBack = null;
    super.dispose();
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
    // In the browser, in-app Back goes through history so both stay in step.
    if (hasBrowserHistory && _browserDepth > 0 && _stack.length > 1) {
      browserHistoryBack();
      return;
    }
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

  /// A code call whose GoTrue failure becomes the code screen's state.
  Future<void> _codeCall(Future<void> Function() call) async {
    try {
      await call();
    } on RepositoryError catch (e) {
      throw otpFailureFrom(e);
    }
  }

  /// Verifying creates a session, so hold the auth screens first; a
  /// rejected code releases the hold again.
  Future<void> _verifyCode(Future<void> Function() call) async {
    widget.onCodeHold?.call(true);
    try {
      await _codeCall(call);
    } catch (_) {
      widget.onCodeHold?.call(false);
      rethrow;
    }
  }

  /// Splash → Sign In is a 300ms fade: Sign In fades in over the splash
  /// picture, which stays opaque underneath, so no blank frame shows.
  bool _splashFading = false;

  void _leaveSplash() {
    _replace(_Stage.signIn);
    setState(() => _splashFading = true);
  }

  @override
  Widget build(BuildContext context) {
    final screen = _screen(context);
    if (!_splashFading) return screen;
    return Stack(
      fit: StackFit.expand,
      children: [
        SplashScreen(access: widget.access, onReady: () {}, idle: true),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          onEnd: () => setState(() => _splashFading = false),
          builder: (context, t, child) => Opacity(opacity: t, child: child),
          child: screen,
        ),
      ],
    );
  }

  Widget _screen(BuildContext context) {
    return switch (_stage) {
      _Stage.splash => SplashScreen(
        access: widget.access,
        onReady: _leaveSplash,
      ),
      _Stage.signIn => SignInScreen(
        access: widget.access,
        onEmail: () => _go(_Stage.emailSignIn),
        onSignUp: () => _go(_Stage.signUp),
        onPrototypeAuthenticated: widget.onPrototypeAuthenticated,
      ),
      _Stage.emailSignIn => EmailSignInScreen(
        onBack: _back,
        onForgotPassword: () => _go(_Stage.forgotPassword),
        onSignUp: () => _go(_Stage.signUp),
        // An unconfirmed account signing in: send it a fresh code (the
        // sign-in attempt itself sends none), then ask for it.
        onNeedsVerification: (email) async {
          try {
            await AppScope.read(context).repo.resendSignUpVerification(email);
          } on RepositoryError {
            // The code screen's resend covers a refused send.
          }
          if (mounted) _go(_Stage.verifyCode, email: email);
        },
        onPrototypeAuthenticated: widget.onPrototypeAuthenticated,
      ),
      _Stage.signUp => SignUpScreen(
        onBack: _back,
        onSignIn: () => _replace(_Stage.emailSignIn),
        onNeedsVerification: (email) => _go(_Stage.verifyCode, email: email),
        onPrototypeSignedUp: widget.onPrototypeSignedUp,
      ),
      _Stage.forgotPassword => ForgotPasswordScreen(
        onBack: _back,
        onSent: (email) => _go(_Stage.recoveryCode, email: email),
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
      _Stage.verifyCode => VerifyEmailCodeScreen(
        key: ValueKey(('verify', _email)),
        email: _email,
        onVerify: (code) => _verifyCode(
          () =>
              AppScope.read(context).repo
                  .verifySignUpCode(email: _email, code: code),
        ),
        onResend: () => _codeCall(
          () => AppScope.read(context).repo.resendSignUpVerification(_email),
        ),
        // The session exists: release the hold and the app root loads it
        // into Business Setup (Owner) or the workspace (Operator / Helper).
        onContinue: () => widget.onCodeHold?.call(false),
        onBack: _back,
        onUseDifferentEmail: () => _replace(_Stage.signUp),
        onSignIn: () => _replace(_Stage.emailSignIn),
      ),
      _Stage.recoveryCode => VerifyEmailCodeScreen(
        key: ValueKey(('recovery', _email)),
        email: _email,
        title: L.otpRecoveryTitle,
        showVerifiedState: false,
        onVerify: (code) => _verifyCode(
          () =>
              AppScope.read(context).repo
                  .verifyRecoveryCode(email: _email, code: code),
        ),
        onResend: () => _codeCall(
          () => AppScope.read(context).repo.sendPasswordReset(_email),
        ),
        onContinue: () => _go(_Stage.setNewPassword),
        onBack: _back,
        onUseDifferentEmail: () => _replace(_Stage.forgotPassword),
      ),
      _Stage.emailVerified => EmailVerifiedScreen(
        onContinue: () => _replace(_Stage.emailSignIn),
      ),
      _Stage.linkExpired => VerificationLinkExpiredScreen(
        email: _email,
        onBack: _back,
        onBackToSignIn: () => _replace(_Stage.emailSignIn),
        onForgotPassword: widget.linkRejected
            ? () => _go(_Stage.forgotPassword)
            : null,
      ),
      _Stage.setNewPassword => SetNewPasswordScreen(
        onBack: _back,
        onUpdated: () {
          _replace(_Stage.emailSignIn);
          widget.onRecoveryDone?.call();
        },
      ),
    };
  }
}

// ------------------------------------------------------- shared chrome

/// Splash's locked navy backdrop -- the canonical Anchor Blue surface
/// ([BrandBackdrop], D-47), pinned to the whole screen.
class _NavyBackdrop extends StatelessWidget {
  const _NavyBackdrop({required this.child});

  final Widget child;

  // DecoratedBox sizes to its child, so on Splash -- whose widest child is
  // the ~168px progress indicator -- the gradient once shrink-wrapped to a
  // narrow strip. SizedBox.expand pins it to the whole screen.
  @override
  Widget build(BuildContext context) =>
      SizedBox.expand(child: BrandBackdrop(child: child));
}

/// The auth backdrop: the canonical Vendor blue ([BrandBackdrop], D-51),
/// full screen. Sign In paints it edge to edge; the sheet screens paint it
/// behind their header band and sheet, so every auth screen matches Splash
/// and the app.
class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SizedBox.expand(child: BrandBackdrop(child: child));
}

/// The one layout every auth screen after Sign In uses: the Sign In blue
/// backdrop with a Back row and crisp lockup in the header band, and a white
/// rounded sheet below it that fills the rest of the screen.
///
/// Header and sheet scroll together, so where the sheet begins is decided by
/// the header's own content, never by a per-screen offset. While the
/// keyboard is open the lockup folds away so the form and its primary action
/// get the room.
class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.child,
    this.onBack,
    this.showBrand = true,
  });

  final Widget child;
  final VoidCallback? onBack;

  /// The brand lockup above the sheet. Code-entry screens drop it (Founder,
  /// 2026-09-30) so the sheet sits higher and the task stays uncluttered.
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return CefSystemBars.split(
      statusBarBackground: Brightness.dark,
      navigationBarBackground: Brightness.light,
      child: Scaffold(
        backgroundColor: context.c.card,
        body: _AuthBackdrop(
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: Gap.sm),
                      SizedBox(
                        height: Sizes.tapTarget,
                        child: Row(
                          children: [
                            if (onBack != null) _BackButton(onTap: onBack!),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: Gap.sm),
                              child: _LanguagePill(
                                onTap: () => openAuthLanguageSheet(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: keyboardOpen || !showBrand
                            ? const SizedBox(
                                width: double.infinity,
                                height: Gap.lg,
                              )
                            : const Padding(
                                padding: EdgeInsets.only(bottom: Gap.xxl),
                                child: OfficialWordmark(
                                  height: 28,
                                  semanticLabel: 'Cefflo',
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.c.card,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_sheetRadius),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Gap.gutter,
                        Gap.xxl,
                        Gap.gutter,
                        Gap.xxl,
                      ),
                      child: child,
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
}

/// Back: the chevron alone, in a standard 44px target set against the
/// screen edge — no "Back" label (Founder, 2026-09-30).
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    // 12px from the screen edge, like every surface.
    padding: const EdgeInsets.only(left: Gap.md),
    child: IconButton(
      onPressed: onTap,
      tooltip: L.back,
      icon: const Icon(LucideIcons.chevronLeft, size: 24),
      color: Colors.white,
      constraints: const BoxConstraints.tightFor(
        width: Sizes.tapTarget,
        height: Sizes.tapTarget,
      ),
      padding: EdgeInsets.zero,
    ),
  );
}

/// The one sheet heading: optional status icon, centred title, centred
/// supporting line. Screens follow it with [Gap.xxl] before their fields or
/// primary action.
class _SheetHeading extends StatelessWidget {
  const _SheetHeading(this.title, this.subtitle, {this.status});
  final String title;
  final String subtitle;
  final _StatusIcon? status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status != null) ...[status!, const SizedBox(height: Gap.xl)],
        Text(title, textAlign: TextAlign.center, style: text.titleMedium),
        // Form screens carry no instruction line under the title (Founder,
        // 2026-10-04); status screens keep their explanation.
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: Gap.sm),
          _CenteredNote(subtitle),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------- controls

/// Plain inline text link ("Back to sign in", "Forgot password?").
class _TextLink extends StatelessWidget {
  const _TextLink(
    this.label, {
    super.key,
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
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: CefColors.navy,
        decoration: TextDecoration.underline,
        decorationColor: CefColors.navy,
      ),
    ),
  );
}

/// "Don't have an account? Sign up" style footer under a sheet's CTA.
class _FooterPrompt extends StatelessWidget {
  const _FooterPrompt(this.prompt, this.link);
  final String prompt;
  final _TextLink link;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(prompt, style: Theme.of(context).textTheme.bodyMedium),
      link,
    ],
  );
}

/// Status icon: Navy outline circle with a Navy glyph.
class _StatusIcon extends StatelessWidget {
  const _StatusIcon(this.icon, {this.circled = true});

  final IconData icon;

  /// Boards 10/11/12 ring the glyph; board 06 shows the envelope bare and
  /// larger. Each screen follows its own locked board — the inconsistency
  /// between the two boards is flagged for the Founder rather than smoothed
  /// over by picking one treatment for both.
  final bool circled;

  @override
  Widget build(BuildContext context) => Center(
    child: circled
        ? Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CefColors.navy, width: 2),
            ),
            child: Icon(icon, size: 34, color: CefColors.navy),
          )
        : Icon(icon, size: 62, color: CefColors.navy),
  );
}

/// Centred supporting prose on a sheet.
class _CenteredNote extends StatelessWidget {
  const _CenteredNote(
    this.text, {
    super.key,
    this.muted = false,
    this.error = false,
  });
  final String text;
  final bool muted;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final base = muted || error ? theme.bodySmall : theme.bodyMedium;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: base?.copyWith(
        height: 1.45,
        color: error ? context.c.attention : null,
      ),
    );
  }
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
      return L.emailPasswordIncorrectTryAgain;
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
    case 'over_sms_send_rate_limit':
      return L.tooManyAttemptsPleaseWaitBefore;
  }
  final m = e.message.toLowerCase();
  if (m.contains('socketexception') ||
      m.contains('failed host lookup') ||
      m.contains('clientexception') ||
      m.contains('xmlhttprequest') ||
      m.contains('connection') ||
      m.contains('network')) {
    return L.unableConnectCheckConnectionTryAgain;
  }
  if (m.contains('rate limit') ||
      m.contains('too many') ||
      m.contains('for security purposes')) {
    return L.tooManyAttemptsPleaseWaitBefore;
  }
  if (m.contains('invalid login') || m.contains('invalid credentials')) {
    return L.emailPasswordIncorrectTryAgain;
  }
  return e.message;
}

/// The backend's own signal that the account exists but is unverified —
/// the locked Verify-your-email screen's entry condition.
bool needsEmailVerification(RepositoryError e) =>
    e.code == 'email_not_confirmed' ||
    e.message.toLowerCase().contains('not confirmed');

/// Maps a GoTrue failure on a 6-digit code (verify or resend) to the code
/// screen's states. GoTrue reports an expired and a mistyped code alike
/// (`otp_expired`, "Token has expired or is invalid"), so both read as
/// [OtpFailureKind.incorrect] — the copy covers either. A resend refused by
/// the email rate limit carries the backend's own wait time.
OtpFailure otpFailureFrom(RepositoryError e) {
  final m = e.message.toLowerCase();
  final wait = RegExp(r'after (\d+) seconds?').firstMatch(m);
  final retry = wait == null ? null : int.tryParse(wait.group(1)!);
  switch (e.code) {
    case 'otp_expired':
    case 'otp_disabled':
    case 'invalid_credentials':
      return const OtpFailure(OtpFailureKind.incorrect);
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return OtpFailure(OtpFailureKind.rateLimited, retryAfterSeconds: retry);
  }
  final text = authErrorText(e);
  if (_isConnectionError(text)) {
    return const OtpFailure(OtpFailureKind.network);
  }
  if (_isRateLimited(text) || retry != null) {
    return OtpFailure(OtpFailureKind.rateLimited, retryAfterSeconds: retry);
  }
  if (m.contains('expired') || m.contains('invalid')) {
    return const OtpFailure(OtpFailureKind.incorrect);
  }
  return OtpFailure(OtpFailureKind.other, message: e.message);
}

bool _isConnectionError(String text) => text.startsWith(L.unableConnect);
bool _isRateLimited(String text) => text.startsWith(L.tooManyAttempts);

// ------------------------------------------------------------ 01 Splash

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onReady,
    this.access = AuthAccess.vendor,
    this.idle = false,
  });
  final VoidCallback onReady;

  /// Picture only (no bootstrap): the copy that stays under Sign In while
  /// Sign In fades in, so the hand-off never shows a blank frame.
  final bool idle;

  /// Which entry opened the app: the label under the logo names it.
  final AuthAccess access;

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
    if (widget.idle) {
      _progress.stop();
    } else {
      _bootstrap();
    }
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
    const minimumBrandMoment = Duration(seconds: 2);
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
  Widget build(BuildContext context) => CefSystemBars(
    background: Brightness.dark,
    browserChromeColor: CefGradients.brandChrome,
    child: Scaffold(
      backgroundColor: CefColors.navy,
      body: _NavyBackdrop(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The official brand block, centred like every surface's splash.
            Center(
              child: CeffloBrandBlock(
                labelKey: const Key('splash-access'),
                label: switch (widget.access) {
                  AuthAccess.vendor => 'Vendor',
                  AuthAccess.operator => L.operatorAccess,
                  AuthAccess.helper => L.helperAccess,
                },
              ),
            ),
            // Tagline and progress stay below the brand block.
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Tagline(),
                    const SizedBox(height: Gap.section),
                    _SplashProgress(animation: _progress),
                    const SizedBox(height: Gap.section),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ----------------------------------------------------------- 02 Sign In

/// Founder-locked V1 sign-in providers for Cefflo Vendor (and the Operator
/// and Helper access modes, which share it): Android shows Continue with
/// Google + Email; iOS is Email only; Apple is out of V1. The web build is
/// the QA harness for the Android app, so it follows Android.
bool get vendorGoogleSignIn =>
    kIsWeb || defaultTargetPlatform == TargetPlatform.android;

/// Height of Sign In's top row (language pill).
const double _welcomeTopRow = 44;

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onEmail,
    required this.onSignUp,
    this.onPrototypeAuthenticated,
    this.access = AuthAccess.vendor,
  });

  /// Operator Sign-In (Founder board, D-74): same providers and flow, with
  /// the Operator Access context. Never sets the role.
  final AuthAccess access;
  final VoidCallback onEmail;
  final VoidCallback onSignUp;
  final VoidCallback? onPrototypeAuthenticated;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String? _providerError;
  bool _busy = false;

  Future<void> _google() async {
    if (widget.onPrototypeAuthenticated != null) {
      widget.onPrototypeAuthenticated!();
      return;
    }
    setState(() {
      _busy = true;
      _providerError = null;
    });
    try {
      await AppScope.read(context).repo.signInWithGoogle();
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _providerError = authErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openLanguageSheet() => openAuthLanguageSheet(context);

  /// Operator / Helper Sign-In variants (Founder boards, D-74).
  bool get operator => widget.access != AuthAccess.vendor;
  bool get helper => widget.access == AuthAccess.helper;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = context.c.textPrimary;
    return CefSystemBars(
      background: Brightness.dark,
      browserChromeColor: CefGradients.brandChrome,
      child: Scaffold(
        backgroundColor: CefColors.navy,
        body: _AuthBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Viewport-aware vertical rhythm: the layout reads the height
                // actually available (Flutter Web tracks the visible, dynamic
                // viewport, so browser chrome is already excluded; SafeArea
                // clears the notch and the home indicator). k runs 0 on a
                // short phone to 1 on a tall one; gaps shrink first, then the
                // hero, while the provider buttons keep their full touch size.
                final k =
                    ((constraints.maxHeight - _compactHeight) /
                            (_roomyHeight - _compactHeight))
                        .clamp(0.0, 1.0);
                double fit(double short, double tall) =>
                    short + (tall - short) * k;
                final buttonGap = fit(Gap.sm + 2, Gap.md);
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    // IntrinsicHeight bounds the Column inside the scroll
                    // view so the flexible spacers can share the free height;
                    // the scroll view only engages when even the compact
                    // composition cannot fit (landscape, very large text).
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.gutter,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: fit(Gap.xs, Gap.md)),
                            SizedBox(
                              height: _welcomeTopRow,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _LanguagePill(onTap: _openLanguageSheet),
                              ),
                            ),
                            // Vendor: the brand block sits exactly where the
                            // splash centres it. Operator and Helper carry a
                            // chip and copy too, so they keep the flexible
                            // spacing.
                            if (operator)
                              const Spacer(flex: 3)
                            else
                              SizedBox(
                                height: CeffloBrandBlock.gapAbove(
                                  context,
                                  MediaQuery.paddingOf(context).top +
                                      fit(Gap.xs, Gap.md) +
                                      _welcomeTopRow,
                                ),
                              ),
                            // The official brand block, as on Splash.
                            const Center(
                              child: CeffloBrandBlock(label: 'Vendor'),
                            ),
                            if (operator) ...[
                              SizedBox(height: fit(Gap.md, Gap.xl)),
                              Center(
                                child: _AccessChip(
                                  icon: helper
                                      ? LucideIcons.package
                                      : LucideIcons.users,
                                  label: helper ? L.helperAccess : null,
                                ),
                              ),
                              SizedBox(height: fit(Gap.sm, Gap.lg)),
                              Text(
                                L.welcomeBack,
                                textAlign: TextAlign.center,
                                style: text.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: fit(28, 32),
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5,
                                ),
                              ),
                              const SizedBox(height: Gap.xs),
                              Text(
                                helper
                                    ? L.signInPreparationTasks
                                    : L.signInStoreOperations,
                                textAlign: TextAlign.center,
                                style: text.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: .9),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                            SizedBox(height: fit(Gap.lg, Gap.xxl)),
                            const Spacer(flex: 3),
                            if (vendorGoogleSignIn) ...[
                              _ProviderButton(
                                label: L.continueGoogle,
                                foreground: ink,
                                leading: const _GoogleGlyph(),
                                onTap: _busy ? null : _google,
                              ),
                              SizedBox(height: buttonGap),
                            ],
                            _ProviderButton(
                              label: L.continueEmail,
                              foreground: CefColors.navy,
                              leading: const Icon(
                                LucideIcons.mail,
                                size: Sizes.icon,
                                color: CefColors.navy,
                              ),
                              onTap: widget.onEmail,
                            ),
                            if (_providerError != null) ...[
                              SizedBox(height: buttonGap),
                              Text(
                                _providerError!,
                                textAlign: TextAlign.center,
                                style: text.bodySmall?.copyWith(
                                  color: _onBackdropError,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            SizedBox(height: fit(Gap.lg, Gap.xxl)),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  L.haveInvite,
                                  style: text.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: .85),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: widget.onSignUp,
                                  child: Text(
                                    L.getStarted,
                                    style: text.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Thumb zone (Founder, 2026-10-04): the buttons
                            // and invite line sit at the bottom, as on Driver.
                            const SizedBox(height: Gap.lg),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Heights (logical px, inside the safe area) between which the sign-in
/// composition interpolates from its compact to its roomy rhythm.
const _compactHeight = 560.0;
const _roomyHeight = 780.0;

/// "Operator Access" context chip on the Operator Sign-In (D-74).
class _AccessChip extends StatelessWidget {
  const _AccessChip({required this.icon, this.label});
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: Gap.sm),
        Text(
          label ?? L.operatorAccess,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
}

/// English / Bahasa Melayu picker, from any auth screen.
void openAuthLanguageSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
    ),
    builder: (context) => const _LanguageSheet(),
  );
}

/// Language control, top right on every auth screen: the globe and the
/// language code (EN / BM) — no pill, no chevron (Founder, 2026-09-30).
class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final code = AppScope.of(context).uiLocale.languageCode;
    return Semantics(
      button: true,
      label: uiLanguageNames[code],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.buttonRadius),
        child: SizedBox(
          height: Sizes.tapTarget,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.globe, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  code == 'ms' ? 'BM' : 'EN',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Language picker on the sign-in screen: English and Bahasa Melayu, by
/// their native names. Choosing applies immediately and persists.
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    final app = AppScope.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Gap.gutter,
          Gap.lg,
          Gap.gutter,
          Gap.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // This one is a real, draggable modal sheet, so it keeps a handle.
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                ),
              ),
            ),
            const SizedBox(height: Gap.lg),
            Text(L.language, style: text.titleMedium),
            const SizedBox(height: Gap.md),
            for (final locale in supportedUiLocales)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Sizes.inputRadius),
                  onTap: () {
                    app.setUiLocale(locale);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: Sizes.controlHeight,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gap.lg,
                      vertical: Gap.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: app.uiLocale == locale
                            ? CefColors.navy
                            : c.border,
                        width: app.uiLocale == locale ? 1.4 : 1,
                      ),
                      borderRadius: BorderRadius.circular(Sizes.inputRadius),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            uiLanguageNames[locale.languageCode]!,
                            style: text.titleSmall,
                          ),
                        ),
                        if (app.uiLocale == locale)
                          const Icon(
                            LucideIcons.check,
                            size: 20,
                            color: CefColors.navy,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.foreground,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Color foreground;
  final Widget leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: Sizes.buttonHeight,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: foreground,
        disabledBackgroundColor: Colors.white.withValues(alpha: .6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.buttonRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: Gap.md),
          // Flexible so a longer localized label or a larger text scale
          // shortens the label instead of overflowing the button.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Official multicolour Google "G", downloaded from Google's current Sign
/// in with Google branding asset and kept at its original aspect ratio.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 22,
    height: 22,
    child: Center(
      child: Image.asset(
        'assets/brand/google-g-logo.png',
        width: 20,
        height: 20.4,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
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
    this.onPrototypeAuthenticated,
  });

  final VoidCallback onBack;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;
  final ValueChanged<String> onNeedsVerification;
  final VoidCallback? onPrototypeAuthenticated;

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

  bool _keep = true;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final app = AppScope.read(context);
      if (widget.onPrototypeAuthenticated != null) {
        await app.loadSession();
        if (mounted) widget.onPrototypeAuthenticated!();
        return;
      }
      await app.repo.signInWithPassword(
        email: _email.text,
        password: _password.text,
      );
      await saveKeepSignedIn(_keep);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeading(L.signEmail, ''),
          const SizedBox(height: Gap.xxl),
          CefField(
            controller: _email,
            label: L.email,
            hint: 'you@yourbusiness.com',
            prefixIcon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            enabled: !_busy,
          ),
          CefField(
            controller: _password,
            label: L.password,
            hint: L.enterPassword,
            prefixIcon: LucideIcons.lock,
            obscureText: true,
            enabled: !_busy,
            errorText: _error,
          ),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,

              children: [
                KeepLoggedInCheck(
                  value: _keep,
                  label: L.keepLoggedIn,
                  onChanged: (v) => setState(() => _keep = v),
                ),

                _TextLink(
                  L.forgotPassword,
                  onTap: _busy ? null : widget.onForgotPassword,
                  align: TextAlign.right,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xxl),
          CefButton(
            connection ? L.tryAgain : L.sign,
            busy: _busy,
            busyLabel: L.signing,
            onTap: limited ? null : _signIn,
          ),
          const SizedBox(height: Gap.xl),
          _FooterPrompt(
            L.dontHaveAccount,
            _TextLink(L.signUp, onTap: _busy ? null : widget.onSignUp),
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
    this.onPrototypeSignedUp,
  });

  final VoidCallback onBack;
  final VoidCallback onSignIn;
  final ValueChanged<String> onNeedsVerification;

  /// UI-prototype-only: a brand new demo account goes through the
  /// first-time business setup wizard, not straight to Today.
  final VoidCallback? onPrototypeSignedUp;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _alreadyRegistered = false;
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
      setState(() => _confirmError = L.passwordsDoNotMatch);
      return;
    }
    if (widget.onPrototypeSignedUp != null) {
      widget.onPrototypeSignedUp!();
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
    } on EmailAlreadyRegistered {
      if (mounted) setState(() => _alreadyRegistered = true);
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
        _SheetHeading(L.createAccount2, ''),
        const SizedBox(height: Gap.xxl),
        CefField(
          controller: _email,
          label: L.email,
          hint: 'you@yourbusiness.com',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          enabled: !_busy,
          errorText: _error,
          onChanged: (_) {
            if (_alreadyRegistered) setState(() => _alreadyRegistered = false);
          },
        ),
        CefField(
          controller: _password,
          label: L.password,
          hint: L.enterPassword,
          prefixIcon: LucideIcons.lock,
          obscureText: true,
          helperText: L.useLeast8Characters,
          enabled: !_busy,
        ),
        CefField(
          controller: _confirm,
          label: L.confirmPassword,
          hint: L.confirmPassword2,
          prefixIcon: LucideIcons.lock,
          obscureText: true,
          enabled: !_busy,
          errorText: _confirmError,
          onChanged: (_) {
            if (_confirmError != null) setState(() => _confirmError = null);
          },
        ),
        const SizedBox(height: Gap.md),
        if (_alreadyRegistered) ...[
          Text(
            L.emailAlreadyRegistered,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: context.c.attention),
          ),
          const SizedBox(height: Gap.xs),
          _FooterPrompt(
            L.alreadyHaveAccount,
            _TextLink(L.sign, onTap: widget.onSignIn),
          ),
          const SizedBox(height: Gap.md),
        ],
        CefButton(
          L.createAccount,
          busy: _busy,
          busyLabel: L.creatingAccount,
          onTap: _create,
        ),
        const SizedBox(height: Gap.xl),
        _FooterPrompt(
          L.alreadyHaveAccount,
          _TextLink(L.sign, onTap: _busy ? null : widget.onSignIn),
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
        _SheetHeading(L.forgotPassword, ''),
        const SizedBox(height: Gap.xxl),
        CefField(
          controller: _email,
          label: L.email,
          hint: 'you@yourbusiness.com',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          enabled: !_busy,
          errorText: _error,
        ),
        const SizedBox(height: Gap.md),
        CefButton(
          _error != null && _isConnectionError(_error!)
              ? L.tryAgain
              : L.sendResetLink,
          busy: _busy,
          busyLabel: L.sending,
          onTap: _error != null && _isRateLimited(_error!) ? null : _send,
        ),
        const SizedBox(height: Gap.xl),
        _TextLink(L.backSign, onTap: _busy ? null : widget.onBack),
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
        _SheetHeading(
          L.checkEmail,
          L.ifAccountExistsEmailYoullReceive,
          status: _StatusIcon(LucideIcons.mail, circled: false),
        ),
        const SizedBox(height: Gap.md),
        _CenteredNote(L.checkSpamFolderToo, muted: true),
        const SizedBox(height: Gap.xxl),
        CefButton(L.backSign, onTap: onBackToSignIn),
        const SizedBox(height: Gap.md),
        CefButton(L.tryAnotherEmail, secondary: true, onTap: onTryAnotherEmail),
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
        setState(() => _notice = L.verificationEmailSent(widget.email));
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
        _SheetHeading(
          L.verifyEmail,
          L.openVerificationLinkEmailConfirmAccount,
          status: _StatusIcon(LucideIcons.mail),
        ),
        const SizedBox(height: Gap.md),
        _CenteredNote(L.checkSpamFolderToo, muted: true),
        if (_notice != null) ...[
          const SizedBox(height: Gap.md),
          _CenteredNote(_notice!),
        ],
        if (_error != null) ...[
          const SizedBox(height: Gap.md),
          _CenteredNote(_error!, error: true),
        ],
        const SizedBox(height: Gap.xxl),
        CefButton(
          L.resendVerificationEmail,
          busy: _busy,
          busyLabel: L.sending,
          onTap: _error != null && _isRateLimited(_error!) ? null : _resend,
        ),
        const SizedBox(height: Gap.md),
        CefButton(
          L.useDifferentEmail,
          secondary: true,
          onTap: _busy ? null : widget.onUseDifferentEmail,
        ),
        const SizedBox(height: Gap.xl),
        _TextLink(L.backSign, onTap: _busy ? null : widget.onBackToSignIn),
      ],
    ),
  );
}

// ------------------------------------------ 10b Verify Email (6-digit code)

/// Why a code was not accepted, as the backend reports it. The wiring layer
/// maps GoTrue's `error_code` onto these; the screen never guesses. GoTrue
/// answers an expired and a mistyped code with the same `otp_expired`, so
/// [incorrect] is the default and [expired] is used only when the backend
/// says so unambiguously.
enum OtpFailureKind { incorrect, expired, rateLimited, network, other }

class OtpFailure implements Exception {
  const OtpFailure(this.kind, {this.message, this.retryAfterSeconds});
  final OtpFailureKind kind;

  /// The backend's own text, shown for [OtpFailureKind.other].
  final String? message;

  /// Resend cooldown the backend asked for, when it says ("…after 42
  /// seconds"); the screen's default cooldown is only a fallback.
  final int? retryAfterSeconds;
}

/// Verify your email with the 6-digit code sent at sign-up. Presentation
/// and interaction only: [onVerify] and [onResend] are supplied by the auth
/// flow, which owns the backend calls. Nothing here decides success — the
/// verified state is shown only after [onVerify] completes. The code lives
/// in the field's controller for the lifetime of the screen and is never
/// logged or persisted.
class VerifyEmailCodeScreen extends StatefulWidget {
  const VerifyEmailCodeScreen({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onResend,
    required this.onContinue,
    required this.onBack,
    required this.onUseDifferentEmail,
    this.resendCooldown = 60,
    this.title,
    this.showVerifiedState = true,
    this.onSignIn,
  });

  /// Sign-up only: an escape route to Sign In ("Already have an
  /// account?"). Any pending invite stays on the device.
  final VoidCallback? onSignIn;

  final String email;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;

  /// Into the existing post-verification flow (Business Setup for an
  /// Owner, the workspace for an Operator or Helper).
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final VoidCallback onUseDifferentEmail;

  /// Seconds before another code may be requested. A code was just sent
  /// when this screen opens, so the countdown starts immediately.
  final int resendCooldown;

  /// The same screen serves password recovery: a different heading, and on
  /// success it hands straight to Set New Password instead of showing the
  /// verified state.
  final String? title;
  final bool showVerifiedState;

  static const length = 6;

  @override
  State<VerifyEmailCodeScreen> createState() => _VerifyEmailCodeScreenState();
}

class _VerifyEmailCodeScreenState extends State<VerifyEmailCodeScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _left = 0;
  bool _verifying = false;
  bool _resending = false;
  bool _verified = false;
  OtpFailureKind? _failure;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _startCooldown(widget.resendCooldown);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    _left = seconds;
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  bool get _complete => _code.text.length == VerifyEmailCodeScreen.length;

  void _changed(String value) {
    // Typing again after a rejected code clears the error state.
    if (_failure != null || _error != null) {
      setState(() {
        _failure = null;
        _error = null;
      });
    } else {
      setState(() {});
    }
    if (_complete && !_verifying && _failure == null) _verify();
  }

  String _failureText(OtpFailure f) => switch (f.kind) {
    OtpFailureKind.incorrect => L.otpIncorrect,
    OtpFailureKind.expired => L.otpExpired,
    OtpFailureKind.rateLimited => L.tooManyAttemptsPleaseWaitBefore,
    OtpFailureKind.network => L.unableConnectCheckConnectionTryAgain,
    OtpFailureKind.other => f.message ?? L.otpIncorrect,
  };

  Future<void> _verify() async {
    if (!_complete || _verifying) return;
    setState(() {
      _verifying = true;
      _failure = null;
      _error = null;
      _notice = null;
    });
    try {
      await widget.onVerify(_code.text);
      if (!mounted) return;
      _timer?.cancel();
      _focus.unfocus();
      if (!widget.showVerifiedState) return widget.onContinue();
      setState(() => _verified = true);
    } on OtpFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _failure = f.kind;
        _error = _failureText(f);
        if (f.kind == OtpFailureKind.expired) _code.clear();
      });
      if (f.kind != OtpFailureKind.expired) {
        _code.selection = TextSelection.collapsed(offset: _code.text.length);
        _focus.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _left > 0) return;
    setState(() {
      _resending = true;
      _error = null;
      _notice = null;
    });
    try {
      await widget.onResend();
      if (!mounted) return;
      setState(() {
        _failure = null;
        _code.clear();
        _notice = L.otpResent(widget.email);
        _startCooldown(widget.resendCooldown);
      });
      _focus.requestFocus();
    } on OtpFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _error = _failureText(f);
        if (f.retryAfterSeconds != null) _startCooldown(f.retryAfterSeconds!);
      });
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verified) {
      return _SheetScaffold(
        showBrand: false,
        child: Column(
          key: const Key('otp-verified'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success content centred in the sheet; Continue at its foot.
            const Spacer(),
            _SheetHeading(
              L.emailVerified,
              L.otpVerifiedLead,
              status: _StatusIcon(LucideIcons.check),
            ),
            const Spacer(),
            CefButton(L.otpContinue, onTap: widget.onContinue),
          ],
        ),
      );
    }
    final text = Theme.of(context).textTheme;
    final expired = _failure == OtpFailureKind.expired;
    return _SheetScaffold(
      showBrand: false,
      onBack: _verifying ? null : widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeading(
            widget.title ?? L.verifyEmail,
            L.otpLead,
            status: _StatusIcon(LucideIcons.mail),
          ),
          const SizedBox(height: Gap.xs),
          Text(
            widget.email,
            key: const Key('otp-email'),
            textAlign: TextAlign.center,
            style: text.titleSmall,
          ),
          const SizedBox(height: Gap.xxl),
          _OtpBoxes(
            controller: _code,
            focusNode: _focus,
            enabled: !_verifying && !expired,
            error: _failure != null && !expired,
            onChanged: _changed,
          ),
          if (_error != null) ...[
            const SizedBox(height: Gap.md),
            Semantics(
              liveRegion: true,
              child: _CenteredNote(
                _error!,
                error: true,
                key: const Key('otp-error'),
              ),
            ),
          ],
          if (_notice != null) ...[
            const SizedBox(height: Gap.md),
            Semantics(
              liveRegion: true,
              child: _CenteredNote(_notice!, key: const Key('otp-notice')),
            ),
          ],
          const SizedBox(height: Gap.xxl),
          if (expired)
            CefButton(
              L.otpSendNew,
              key: const Key('otp-send-new'),
              busy: _resending,
              busyLabel: L.sending,
              onTap: _left > 0 ? null : _resend,
            )
          else
            CefButton(
              L.otpVerify,
              key: const Key('otp-verify'),
              busy: _verifying,
              busyLabel: L.otpVerifying,
              onTap: _complete && _failure == null ? _verify : null,
            ),
          const SizedBox(height: Gap.xl),
          _ResendLine(
            left: _left,
            busy: _resending,
            hidden: expired && _left <= 0,
            onResend: _verifying ? null : _resend,
          ),
          const SizedBox(height: Gap.lg),
          _TextLink(
            L.useDifferentEmail,
            onTap: _verifying ? null : widget.onUseDifferentEmail,
          ),
          const SizedBox(height: Gap.lg),
          _CenteredNote(L.checkSpamFolderToo, muted: true),
          if (widget.onSignIn != null) ...[
            const SizedBox(height: Gap.md),
            _FooterPrompt(
              L.alreadyHaveAccount,
              _TextLink(L.sign, onTap: _verifying ? null : widget.onSignIn),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Didn't get the code? Resend code" — or the countdown while the
/// backend's resend window is closed.
class _ResendLine extends StatelessWidget {
  const _ResendLine({
    required this.left,
    required this.busy,
    required this.hidden,
    required this.onResend,
  });
  final int left;
  final bool busy;
  final bool hidden;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    if (hidden) return const SizedBox.shrink();
    final body = Theme.of(context).textTheme.bodyMedium;
    if (left > 0) {
      return Text(
        L.otpResendIn(left),
        key: const Key('otp-resend-countdown'),
        textAlign: TextAlign.center,
        style: body?.copyWith(color: context.c.textSecondary),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Gap.xs,
      children: [
        Text(L.otpNoCode, style: body),
        busy
            ? Text(L.sending, style: body)
            : _TextLink(
                L.otpResend,
                onTap: onResend,
                key: const Key('otp-resend'),
              ),
      ],
    );
  }
}

/// Six digit boxes over one hidden numeric field: the system keyboard,
/// one-time-code autofill, paste of the whole code and backspace all come
/// from the platform field, and the boxes show where the next digit goes.
class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const n = VerifyEmailCodeScreen.length;
    return Semantics(
      label: L.otpCodeLabel,
      textField: true,
      child: SizedBox(
        height: 58,
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: Listenable.merge([controller, focusNode]),
              builder: (context, _) {
                final v = controller.text;
                return Row(
                  children: [
                    for (var i = 0; i < n; i++) ...[
                      if (i > 0) SizedBox(width: i == n ~/ 2 ? Gap.md : Gap.sm),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: enabled ? c.card : c.subtle,
                            borderRadius: BorderRadius.circular(
                              Sizes.inputRadius * .75,
                            ),
                            border: Border.all(
                              color: error
                                  ? c.attention
                                  : focusNode.hasFocus &&
                                        (i == v.length ||
                                            (v.length == n && i == n - 1))
                                  ? CefColors.ceffloMustard
                                  : c.border,
                              width:
                                  error || (focusNode.hasFocus && i == v.length)
                                  ? 1.6
                                  : 1,
                            ),
                          ),
                          child: Text(
                            i < v.length ? v[i] : '',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: enabled
                                      ? c.textPrimary
                                      : c.textSecondary,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  key: const Key('otp-input'),
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  onChanged: onChanged,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(n),
                  ],
                  showCursor: false,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        _SheetHeading(
          L.emailVerified,
          L.emailConfirmedSignContinue,
          status: _StatusIcon(LucideIcons.check),
        ),
        const SizedBox(height: Gap.xxl),
        CefButton(L.continueSign, onTap: onContinue),
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
    this.onForgotPassword,
  });

  final String email;
  final VoidCallback onBack;
  final VoidCallback onBackToSignIn;

  /// Set when an emailed link opened the app and the server refused it. The
  /// link may have been a sign-up confirmation or a password reset, so both
  /// ways forward are offered.
  final VoidCallback? onForgotPassword;

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
        setState(() => _notice = L.verificationEmailSent2(_email.text.trim()));
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
        _SheetHeading(
          widget.onForgotPassword != null
              ? L.linkNoLongerValid
              : L.verificationLinkExpired,
          widget.onForgotPassword != null
              ? L.linkExpiredOrUsedRequestNew
              : L.linkHasExpiredInvalidRequestNew,
          status: _StatusIcon(LucideIcons.clock),
        ),
        if (_notice != null) ...[
          const SizedBox(height: Gap.md),
          _CenteredNote(_notice!),
        ],
        const SizedBox(height: Gap.xxl),
        CefField(
          controller: _email,
          label: L.email,
          hint: 'you@yourbusiness.com',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          enabled: !_busy,
          errorText: _error,
        ),
        const SizedBox(height: Gap.md),
        CefButton(
          L.sendNewVerificationEmail,
          busy: _busy,
          busyLabel: L.sending,
          onTap: _error != null && _isRateLimited(_error!) ? null : _send,
        ),
        if (widget.onForgotPassword != null) ...[
          const SizedBox(height: Gap.lg),
          _TextLink(
            L.sendNewResetLink,
            onTap: _busy ? null : widget.onForgotPassword,
          ),
        ],
        const SizedBox(height: Gap.xl),
        _TextLink(L.backSign, onTap: _busy ? null : widget.onBackToSignIn),
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
      setState(() => _confirmError = L.passwordsDoNotMatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(context).repo.updatePassword(_password.text);
      if (!mounted) return;
      setState(() => _busy = false);
      // V08 · Password Updated: confirm the change with the shared
      // async-feedback popup (locked pattern, see runAsyncFeedback) before
      // returning to Sign In, instead of silently jumping back.
      await runAsyncFeedback(
        context,
        action: () async {},
        processingTitle: L.updatingPassword,
        processingSubtitle: L.savingNewPassword,
        successTitle: L.passwordUpdated,
        successSubtitle: L.canNowSignNewPassword,
      );
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
        _SheetHeading(L.setNewPassword, ''),
        const SizedBox(height: Gap.xxl),
        CefField(
          controller: _password,
          label: L.newPassword,
          hint: L.enterNewPassword,
          prefixIcon: LucideIcons.lock,
          obscureText: true,
          enabled: !_busy,
          errorText: _error,
          onChanged: (_) => setState(() {}),
        ),
        CefField(
          controller: _confirm,
          label: L.confirmPassword,
          hint: L.confirmPassword2,
          prefixIcon: LucideIcons.lock,
          obscureText: true,
          enabled: !_busy,
          errorText:
              _confirmError ??
              (_confirm.text.isNotEmpty && _password.text != _confirm.text
                  ? L.passwordsDoNotMatch
                  : null),
          onChanged: (_) => setState(() => _confirmError = null),
        ),
        const SizedBox(height: Gap.md),
        CefButton(
          L.updatePassword,
          busy: _busy,
          busyLabel: L.updating,
          onTap: _canSubmit ? _update : null,
        ),
      ],
    ),
  );
}

/// Join through a permanent invite link (Founder, 2026-10-01): the signed-in
/// invitee confirms their details and sends ONE request. It is always
/// pending -- the Owner approves or rejects it in Team -- so this screen
/// never grants access and never opens Business Setup.
class JoinRequestScreen extends StatefulWidget {
  const JoinRequestScreen({super.key, required this.token});
  final String token;

  @override
  State<JoinRequestScreen> createState() => _JoinRequestScreenState();
}

class _JoinRequestScreenState extends State<JoinRequestScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  Map<String, dynamic>? _link;
  bool _loading = true, _busy = false;

  /// The server's answer: 'pending' (request sent / already waiting) or
  /// 'active' (this account is already part of the business).
  String? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefilled from the signed-in account; the invitee can change it.
    _name.text = AppScope.read(context).userDisplayName;
    _resolve();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final app = AppScope.read(context);
    try {
      final link = await app.repo.resolveInviteLink(widget.token);
      if (mounted) setState(() => _link = link);
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _business => (_link?['business_name'] as String?) ?? 'Cefflo';
  bool get _open => _link?['status'] == 'open';

  Future<void> _send() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = L.nameRequired);
      return;
    }
    final app = AppScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await app.repo.joinViaInviteLink(
        token: widget.token,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      if (!mounted) return;
      // Never a silent redirect: 'active' is a terminal "already part of"
      // state the invitee acknowledges.
      setState(
        () => _result = res['status'] == 'active' ? 'active' : 'pending',
      );
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Done with this invite: back into the app as this account.
  Future<void> _continue() async {
    final app = AppScope.read(context);
    await app.finishJoin();
    await app.loadSession();
  }

  /// Switch account but KEEP the pending invite: after signing in again the
  /// same invite opens (the token stays on the device).
  Future<void> _useAnotherAccount() async {
    final app = AppScope.read(context);
    await app.repo.signOut();
    app.clearSession();
  }

  Future<void> _signOut() async {
    final app = AppScope.read(context);
    await app.finishJoin();
    await app.repo.signOut();
    app.clearSession();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final app = AppScope.of(context);
    final email = app.repo.currentUser?.email ?? '';
    final account = Padding(
      padding: const EdgeInsets.only(top: Gap.md),
      child: Column(
        children: [
          if (email.isNotEmpty)
            Text(
              L.signedInAs(email),
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
          TextButton(
            onPressed: _busy ? null : _useAnotherAccount,
            child: Text(L.useAnotherAccount),
          ),
        ],
      ),
    );
    final Widget body;
    if (_loading) {
      body = const SkeletonForm(fields: 2);
    } else if (_result == 'active') {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeading(L.alreadyPartOf(_business), L.alreadyPartOfBody),
          const SizedBox(height: Gap.xxl),
          CefButton(L.continueToApp, onTap: _continue),
          account,
        ],
      );
    } else if (_result == 'pending') {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeading(L.joinPendingTitle, L.joinPendingBody(_business)),
          const SizedBox(height: Gap.xxl),
          CefButton(L.signOut, secondary: true, onTap: _signOut),
        ],
      );
    } else if (!_open) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StateBlock.error(_error ?? L.joinLinkUnavailable),
          const SizedBox(height: Gap.lg),
          CefButton(L.signOut, secondary: true, onTap: _signOut),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeading(L.joinTitle(_business), L.joinBody),
          const SizedBox(height: Gap.xl),
          Text(
            _link?['kind'] == 'helper' ? L.helperText : L.operatorText,
            style: text.labelLarge,
          ),
          const SizedBox(height: Gap.md),
          CefField(
            controller: _name,
            label: L.fullName,
            prefixIcon: LucideIcons.user,
            enabled: !_busy,
            errorText: _error,
          ),
          CefField(
            controller: _phone,
            label: L.phoneNumber,
            prefixIcon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            enabled: !_busy,
          ),
          const SizedBox(height: Gap.md),
          CefButton(L.joinSubmit, busy: _busy, onTap: _send),
          account,
        ],
      );
    }
    return _SheetScaffold(child: body);
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) => Text(
    L.operateTodayGrowTomorrow,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Colors.white.withValues(alpha: .88), height: 1.45),
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
                      ? CefColors.ceffloMustard
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
