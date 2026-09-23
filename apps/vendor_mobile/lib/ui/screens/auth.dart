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

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../system_bars.dart';
import '../widgets.dart';

// ---------------------------------------------------------------- palette
//
// Splash's navy sweep is the app-wide Anchor Blue (CefGradients.brand,
// D-47); it is no longer declared here.

// The bright CEFFLO blue sweep shared by Sign In and every sheet screen
// after it, so the journey reads as one continuous backdrop.
const _skyTop = Color(0xFF51BDF8);
const _skyMid = Color(0xFF0B67E8);
const _skyDeep = Color(0xFF031A50);

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
        processingTitle: 'Updating password…',
        processingSubtitle: 'Saving your new password.',
        successTitle: 'Password updated',
        successSubtitle: 'You can now sign in with your new password.',
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
  });

  final VoidCallback? onPrototypeAuthenticated;

  /// UI-prototype-only: a brand new demo account goes through the
  /// first-time business setup wizard (V06-V10) instead of straight to
  /// Today, mirroring what a real sign-up would do.
  final VoidCallback? onPrototypeSignedUp;

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
        onPrototypeAuthenticated: widget.onPrototypeAuthenticated,
      ),
      _Stage.emailSignIn => EmailSignInScreen(
        onBack: _back,
        onForgotPassword: () => _go(_Stage.forgotPassword),
        onSignUp: () => _go(_Stage.signUp),
        onNeedsVerification: (email) => _go(_Stage.verifyEmail, email: email),
        onPrototypeAuthenticated: widget.onPrototypeAuthenticated,
      ),
      _Stage.signUp => SignUpScreen(
        onBack: _back,
        onSignIn: () => _replace(_Stage.emailSignIn),
        onNeedsVerification: (email) => _go(_Stage.verifyEmail, email: email),
        onPrototypeSignedUp: widget.onPrototypeSignedUp,
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

/// The bright CEFFLO blue auth backdrop. Sign In paints it full screen; the
/// sheet screens paint the same full-screen sweep behind their header band
/// and sheet, so the top of every auth screen matches Sign In exactly.
class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyMid, _skyDeep],
          stops: [0, .44, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(.42, -.08),
            radius: .82,
            colors: [Color(0x663CA8FF), Color(0x00000000)],
          ),
        ),
        child: child,
      ),
    ),
  );
}

/// Share of the canonical master's height that the lockup actually occupies.
/// The D-35 file is a 4375x4375 canvas with the portrait lockup centred in
/// it, so a plain `height:` renders a logo visibly ~28% smaller than the
/// number implies.
const _lockupInkRatio = 0.7225;

/// D-35 canonical primary lockup (mark + wordmark), bundled from
/// docs/cefflo/brand/assets/logo/ and never redrawn. Always crisp.
///
/// [height] is the height of the *visible* lockup, not of the asset's square
/// canvas.
class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.height = 150});

  final double height;

  @override
  Widget build(BuildContext context) {
    final box = height / _lockupInkRatio;
    return Image.asset(
      'assets/brand/cefflo-logo-primary.png',
      height: box,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      // The canonical asset is 4375x4375; decoding it at full size costs
      // ~76MB per instance. Decode at 3x the display size instead — the
      // file itself is untouched, only how much of it we rasterize.
      cacheWidth: (box * 3).round(),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) => Text(
    'Operate Today.\nGrow Tomorrow.',
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Colors.white.withValues(alpha: .88), height: 1.45),
  );
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
  const _SheetScaffold({required this.child, this.onBack});

  final Widget child;
  final VoidCallback? onBack;

  /// Visible height of the header lockup.
  static const _headerLockup = 96.0;

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
                      SizedBox(
                        height: Sizes.tapTarget,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: onBack == null
                              ? null
                              : _BackButton(onTap: onBack!),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: keyboardOpen
                            ? const SizedBox(
                                width: double.infinity,
                                height: Gap.lg,
                              )
                            : const Padding(
                                padding: EdgeInsets.only(bottom: Gap.xxl),
                                child: _BrandLockup(height: _headerLockup),
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: Gap.sm),
    child: Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.md,
            vertical: Gap.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.chevronLeft,
                color: Colors.white,
                size: Sizes.icon,
              ),
              const SizedBox(width: Gap.xs),
              Text(
                'Back',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
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
        const SizedBox(height: Gap.sm),
        _CenteredNote(subtitle),
      ],
    );
  }
}

// -------------------------------------------------------------- controls

/// Plain inline text link ("Back to sign in", "Forgot password?").
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
  const _CenteredNote(this.text, {this.muted = false, this.error = false});
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
    const minimumBrandMoment = Duration(seconds: 3);
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
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 5),
              const _BrandLockup(height: 200),
              const Spacer(flex: 5),
              const _Tagline(),
              const SizedBox(height: Gap.section),
              _SplashProgress(animation: _progress),
              const SizedBox(height: Gap.section),
            ],
          ),
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
    this.onPrototypeAuthenticated,
  });
  final VoidCallback onEmail;
  final VoidCallback onSignUp;
  final VoidCallback? onPrototypeAuthenticated;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String? _providerError;
  bool _busy = false;

  Future<void> _provider(OAuthProvider provider) async {
    if (widget.onPrototypeAuthenticated != null) {
      widget.onPrototypeAuthenticated!();
      return;
    }
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
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
      ),
      builder: (context) => const _LanguageSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = context.c.textPrimary;
    return CefSystemBars(
      background: Brightness.dark,
      browserChromeColor: _skyTop,
      child: Scaffold(
        backgroundColor: CefColors.navy,
        body: _AuthBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  // IntrinsicHeight gives the Column a bounded height inside
                  // the scroll view, so the Spacers can pin the provider
                  // stack toward the bottom edge as the locked board shows.
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gap.gutter,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: Gap.md),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _LanguagePill(onTap: _openLanguageSheet),
                          ),
                          const Spacer(flex: 5),
                          const Center(child: _BrandLockup(height: 128)),
                          Text(
                            'VENDOR',
                            textAlign: TextAlign.center,
                            style: text.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 6,
                            ),
                          ),
                          const Spacer(flex: 4),
                          _ProviderButton(
                            label: 'Continue with Apple',
                            foreground: ink,
                            leading: Icon(
                              Icons.apple,
                              color: ink,
                              size: Sizes.icon,
                            ),
                            onTap: _busy
                                ? null
                                : () => _provider(OAuthProvider.apple),
                          ),
                          const SizedBox(height: Gap.md),
                          _ProviderButton(
                            label: 'Continue with Google',
                            foreground: ink,
                            leading: const _GoogleGlyph(),
                            onTap: _busy
                                ? null
                                : () => _provider(OAuthProvider.google),
                          ),
                          const SizedBox(height: Gap.md),
                          _ProviderButton(
                            label: 'Continue with Email',
                            foreground: CefColors.navy,
                            leading: const Icon(
                              LucideIcons.mail,
                              size: Sizes.icon,
                              color: CefColors.navy,
                            ),
                            onTap: widget.onEmail,
                          ),
                          if (_providerError != null) ...[
                            const SizedBox(height: Gap.md),
                            Text(
                              _providerError!,
                              textAlign: TextAlign.center,
                              style: text.bodySmall?.copyWith(
                                color: _onBackdropError,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: Gap.xxl),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Have an invite? ',
                                style: text.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: .85),
                                ),
                              ),
                              GestureDetector(
                                onTap: widget.onSignUp,
                                child: Text(
                                  'Get started',
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
                          const SizedBox(height: Gap.xxxl),
                        ],
                      ),
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
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(Sizes.buttonRadius),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm, horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.globe, color: Colors.white, size: 20),
          const SizedBox(width: Gap.sm),
          Text(
            'English',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(width: Gap.xs),
          const Icon(LucideIcons.chevronDown, color: Colors.white, size: 18),
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

  // English names are used here rather than endonyms ('中文', 'தமிழ்') as a
  // deliberate, currently-unchanged copy choice for this unlocked sheet —
  // not a font limitation. The Inter migration bundles Noto Sans SC and
  // Noto Sans Tamil as fontFamilyFallback, so native endonyms would render
  // correctly if a future Founder-locked copy change calls for them.
  static const _languages = [
    ('English', 'en', true),
    ('Bahasa Melayu', 'ms', false),
    ('Chinese (Simplified)', 'zh', false),
    ('Tamil', 'ta', false),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
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
            Text('Language', style: text.titleMedium),
            const SizedBox(height: Gap.md),
            for (final (label, _, available) in _languages)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Opacity(
                  opacity: available ? 1 : .55,
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
                        color: available ? CefColors.navy : c.border,
                        width: available ? 1.4 : 1,
                      ),
                      borderRadius: BorderRadius.circular(Sizes.inputRadius),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(label, style: text.titleSmall)),
                        if (available)
                          const Icon(
                            LucideIcons.check,
                            size: 20,
                            color: CefColors.navy,
                          )
                        else
                          Text('Not in this build', style: text.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: Gap.xs),
            Text(
              'Only English is available in this build. The other languages '
              'are part of the product but their Flutter translations are not '
              'wired yet.',
              style: text.bodySmall?.copyWith(height: 1.4),
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
          const _SheetHeading(
            'Sign in with Email',
            'Enter your email and password to continue.',
          ),
          const SizedBox(height: Gap.xxl),
          CefField(
            controller: _email,
            label: 'Email',
            hint: 'you@yourbusiness.com',
            prefixIcon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            enabled: !_busy,
          ),
          CefField(
            controller: _password,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: LucideIcons.lock,
            obscureText: true,
            enabled: !_busy,
            errorText: _error,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _TextLink(
              'Forgot password?',
              onTap: _busy ? null : widget.onForgotPassword,
              align: TextAlign.right,
            ),
          ),
          const SizedBox(height: Gap.xxl),
          CefButton(
            connection ? 'Try again' : 'Sign in',
            busy: _busy,
            busyLabel: 'Signing in…',
            onTap: limited ? null : _signIn,
          ),
          const SizedBox(height: Gap.xl),
          _FooterPrompt(
            "Don't have an account? ",
            _TextLink('Sign up', onTap: _busy ? null : widget.onSignUp),
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
        const _SheetHeading(
          'Create your account',
          'Start managing your deliveries.',
        ),
        const SizedBox(height: Gap.xxl),
        CefField(
          controller: _email,
          label: 'Email',
          hint: 'you@yourbusiness.com',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          enabled: !_busy,
          errorText: _error,
        ),
        CefField(
          controller: _password,
          label: 'Password',
          hint: 'Enter your password',
          prefixIcon: LucideIcons.lock,
          obscureText: true,
          helperText: 'Use at least 8 characters.',
          enabled: !_busy,
        ),
        CefField(
          controller: _confirm,
          label: 'Confirm password',
          hint: 'Confirm your password',
          prefixIcon: LucideIcons.lock,
          obscureText: true,
          enabled: !_busy,
          errorText: _confirmError,
          onChanged: (_) {
            if (_confirmError != null) setState(() => _confirmError = null);
          },
        ),
        const SizedBox(height: Gap.md),
        CefButton(
          'Create account',
          busy: _busy,
          busyLabel: 'Creating account…',
          onTap: _create,
        ),
        const SizedBox(height: Gap.xl),
        _FooterPrompt(
          'Already have an account? ',
          _TextLink('Sign in', onTap: _busy ? null : widget.onSignIn),
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
        const _SheetHeading(
          'Forgot password?',
          "Enter your email and we'll send you a reset link.",
        ),
        const SizedBox(height: Gap.xxl),
        CefField(
          controller: _email,
          label: 'Email',
          hint: 'you@yourbusiness.com',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          enabled: !_busy,
          errorText: _error,
        ),
        const SizedBox(height: Gap.md),
        CefButton(
          _error != null && _isConnectionError(_error!)
              ? 'Try again'
              : 'Send reset link',
          busy: _busy,
          busyLabel: 'Sending…',
          onTap: _error != null && _isRateLimited(_error!) ? null : _send,
        ),
        const SizedBox(height: Gap.xl),
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
        const _SheetHeading(
          'Check your email',
          "If an account exists for this email, you'll receive a password "
              'reset link.',
          status: _StatusIcon(LucideIcons.mail, circled: false),
        ),
        const SizedBox(height: Gap.md),
        const _CenteredNote('Check your spam folder too.', muted: true),
        const SizedBox(height: Gap.xxl),
        CefButton('Back to sign in', onTap: onBackToSignIn),
        const SizedBox(height: Gap.md),
        CefButton(
          'Try another email',
          secondary: true,
          onTap: onTryAnotherEmail,
        ),
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
        const _SheetHeading(
          'Verify your email',
          'Open the verification link in your email to confirm your account.',
          status: _StatusIcon(LucideIcons.mail),
        ),
        const SizedBox(height: Gap.md),
        const _CenteredNote('Check your spam folder too.', muted: true),
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
          'Resend verification email',
          busy: _busy,
          busyLabel: 'Sending…',
          onTap: _error != null && _isRateLimited(_error!) ? null : _resend,
        ),
        const SizedBox(height: Gap.md),
        CefButton(
          'Use a different email',
          secondary: true,
          onTap: _busy ? null : widget.onUseDifferentEmail,
        ),
        const SizedBox(height: Gap.xl),
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
        const _SheetHeading(
          'Email verified',
          'Your email is confirmed.\nSign in to continue.',
          status: _StatusIcon(LucideIcons.check),
        ),
        const SizedBox(height: Gap.xxl),
        CefButton('Continue to sign in', onTap: onContinue),
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
        const _SheetHeading(
          'Verification link expired',
          'This link has expired or is invalid.\nRequest a new verification email.',
          status: _StatusIcon(LucideIcons.clock),
        ),
        if (_notice != null) ...[
          const SizedBox(height: Gap.md),
          _CenteredNote(_notice!),
        ],
        const SizedBox(height: Gap.xxl),
        CefField(
          controller: _email,
          label: 'Email',
          hint: 'you@yourbusiness.com',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          enabled: !_busy,
          errorText: _error,
        ),
        const SizedBox(height: Gap.md),
        CefButton(
          'Send new verification email',
          busy: _busy,
          busyLabel: 'Sending…',
          onTap: _error != null && _isRateLimited(_error!) ? null : _send,
        ),
        const SizedBox(height: Gap.xl),
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
      if (!mounted) return;
      setState(() => _busy = false);
      // V08 · Password Updated: confirm the change with the shared
      // async-feedback popup (locked pattern, see runAsyncFeedback) before
      // returning to Sign In, instead of silently jumping back.
      await runAsyncFeedback(
        context,
        action: () async {},
        processingTitle: 'Updating password…',
        processingSubtitle: 'Saving your new password.',
        successTitle: 'Password updated',
        successSubtitle: 'You can now sign in with your new password.',
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
        const _SheetHeading(
          'Set a new password',
          'Choose a strong password for your account.',
        ),
        const SizedBox(height: Gap.xxl),
        CefField(
          controller: _password,
          label: 'New password',
          hint: 'Enter a new password',
          prefixIcon: LucideIcons.lock,
          obscureText: true,
          enabled: !_busy,
          errorText: _error,
          onChanged: (_) => setState(() {}),
        ),
        CefField(
          controller: _confirm,
          label: 'Confirm password',
          hint: 'Confirm your password',
          prefixIcon: LucideIcons.lock,
          obscureText: true,
          enabled: !_busy,
          errorText:
              _confirmError ??
              (_confirm.text.isNotEmpty && _password.text != _confirm.text
                  ? 'Passwords do not match.'
                  : null),
          onChanged: (_) => setState(() => _confirmError = null),
        ),
        const SizedBox(height: Gap.md),
        CefButton(
          'Update password',
          busy: _busy,
          busyLabel: 'Updating…',
          onTap: _canSubmit ? _update : null,
        ),
      ],
    ),
  );
}
