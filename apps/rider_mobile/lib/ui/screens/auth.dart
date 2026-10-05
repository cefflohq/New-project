import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/keep_signed_in.dart';
import '../../core/browser_history.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/rider_repository.dart';
import '../brand.dart';
import '../bottom_surface.dart';
import '../widgets.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

import '../../core/ui_locale.dart';

/// D01–D09. The auth family owns its own stage stack: it runs before the
/// app shell exists, so it does not share the signed-in navigation graph.
class AuthFlow extends StatefulWidget {
  const AuthFlow({
    super.key,
    this.initial = DRoute.splash,
    required this.onAuthenticated,
    this.onPasswordUpdated,
    this.onCodeHold,
  });

  /// Holds the auth screens on top while a 6-digit code flow finishes:
  /// verifying creates a session, and without the hold the app root would
  /// leave before "Email verified" — or, for recovery, before the new
  /// password is set.
  final ValueChanged<bool>? onCodeHold;

  /// Recovery-link flow only: called when D08 returns to sign-in.
  final VoidCallback? onPasswordUpdated;

  final DRoute initial;

  /// Fired when the Driver reaches the signed-in app, carrying the route the
  /// shell should open on: an existing Driver lands on their own home, one
  /// arriving from an invitation lands on D10, one who declined lands on
  /// D16.
  final ValueChanged<DRoute?> onAuthenticated;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  late final List<DRoute> _stack = [widget.initial];

  /// Carried to D04.1 / D06 so they show, and resend to, the address the
  /// Driver actually typed.
  String _email = '';

  void _go(DRoute route, {String? email}) {
    setState(() {
      if (email != null) _email = email;
      _stack.add(route);
    });
    // One browser entry per auth step (edge-swipe / browser Back).
    if (hasBrowserHistory) {
      pushBrowserHistoryEntry();
      _browserDepth++;
    }
  }

  int _browserDepth = 0;
  AppState? _app;

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

  void _back() {
    if (hasBrowserHistory && _browserDepth > 0 && _stack.length > 1) {
      browserHistoryBack();
      return;
    }
    _backNow();
  }

  void _backNow() => setState(() {
    if (_stack.length > 1) {
      _stack.removeLast();
    } else {
      _stack
        ..clear()
        ..add(DRoute.signIn);
    }
  });

  void _resetTo(DRoute route) => setState(() {
    _stack
      ..clear()
      ..add(route);
  });

  /// D02 Welcome (Founder baseline 3c111db, 2026-10-04): logo lockup, then
  /// the sign-in options. Driver V1 is Email only (Founder locked), so the
  /// only option is Continue with Email.
  Widget _welcome() => WelcomeScreen(
    onGoogle: _google,
    onEmail: () => _go(DRoute.emailSignIn),
    onInvite: () => _go(DRoute.createAccount),
  );

  Future<void> _google() async {
    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      widget.onAuthenticated(null);
      return;
    }
    try {
      await app.repo.signInWithGoogle();
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, driverAuthErrorText(e), error: true);
    }
  }

  /// D03 Sign In with Email.
  Widget _signIn() => EmailSignInScreen(
    onBack: _stack.length > 1 ? _back : null,
    onSignIn: () => widget.onAuthenticated(null),
    onForgotPassword: () => _go(DRoute.forgotPassword),
    onSignUp: () => _go(DRoute.createAccount),
  );

  /// A code call whose GoTrue failure becomes the code screen's state.
  Future<void> _codeCall(Future<void> Function() call) async {
    try {
      await call();
    } on RepositoryError catch (e) {
      throw otpFailureFrom(e);
    }
  }

  /// Verifying creates a session, so hold the auth screens first; a
  /// rejected code releases the hold.
  Future<void> _verifyCode(Future<void> Function() call) async {
    widget.onCodeHold?.call(true);
    try {
      await _codeCall(call);
    } catch (_) {
      widget.onCodeHold?.call(false);
      rethrow;
    }
  }

  /// D01 → D02 is a 300ms fade: D02 fades in over D01's picture, which
  /// stays opaque underneath, so no blank or white frame shows between them.
  bool _splashFading = false;

  void _leaveSplash() {
    _resetTo(DRoute.signIn);
    setState(() => _splashFading = true);
  }

  @override
  Widget build(BuildContext context) {
    final screen = _screen(context);
    if (!_splashFading) return screen;
    return Stack(
      fit: StackFit.expand,
      children: [
        const SplashBackdrop(),
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

  Widget _screen(BuildContext context) => switch (_stack.last) {
    DRoute.splash => SplashScreen(onContinue: _leaveSplash),
    DRoute.signIn => _welcome(),
    DRoute.emailSignIn => _signIn(),
    DRoute.createAccount => CreateAccountScreen(
      onBack: _back,
      // One invitation, one acceptance: the rider already accepted in the
      // Invitation PWA. A new account goes straight into the app; live,
      // loadSession claims that consent server-side (by the invited email)
      // and lands on the stage it produces. The prototype walks the
      // designed onboarding forms instead.
      onCreated: () => widget.onAuthenticated(
        AppScope.read(context).repo.isDemo ? DRoute.chooseVehicle : null,
      ),
      onVerify: (email) => _go(DRoute.verifyEmail, email: email),
      onSignIn: () => _resetTo(DRoute.signIn),
    ),
    DRoute.verifyEmail => VerifyEmailCodeScreen(
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
      // Session exists: release the hold; the app root loads it and lands
      // on the stage it produces (as a confirmed sign-up does today).
      onContinue: () {
        widget.onCodeHold?.call(false);
        widget.onAuthenticated(null);
      },
      onBack: _back,
      onBackToSignIn: () => _resetTo(DRoute.signIn),
    ),
    DRoute.forgotPassword => ForgotPasswordScreen(
      onBack: _back,
      onSent: (email) => _go(DRoute.checkEmail, email: email),
      onBackToSignIn: () => _resetTo(DRoute.signIn),
    ),
    DRoute.checkEmail => VerifyEmailCodeScreen(
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
      onContinue: () => _go(DRoute.setNewPassword),
      onBack: _back,
      onBackToSignIn: () => _resetTo(DRoute.signIn),
    ),
    DRoute.linkExpired => LinkExpiredScreen(
      onForgotPassword: () => _go(DRoute.forgotPassword),
      onBackToSignIn: () => _resetTo(DRoute.signIn),
    ),
    DRoute.setNewPassword => SetNewPasswordScreen(
      onBack: _back,
      onUpdated: () => _go(DRoute.passwordUpdated),
    ),
    DRoute.passwordUpdated => PasswordUpdatedScreen(
      onBackToSignIn: () {
        _resetTo(DRoute.signIn);
        widget.onPasswordUpdated?.call();
      },
    ),
    _ => _signIn(),
  };
}

// ---------------------------------------------------------------------------
// Shared auth pieces
// ---------------------------------------------------------------------------

/// "Already have an account? Sign In" / "Don't have an account? Sign Up".
class CeffloInlinePrompt extends StatelessWidget {
  const CeffloInlinePrompt({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 6,
    children: [
      Text(prompt, style: context.t.bodyMedium),
      CeffloTextLink(action, onTap: onTap, fontSize: 14),
    ],
  );
}

// ---------------------------------------------------------------------------
// D01 — Splash
// ---------------------------------------------------------------------------

/// D01. The reference composition is a photographic scene (motorcycle rider,
/// passenger car, delivery van on a city highway at dusk) behind the
/// "Cefflo Driver" lockup and the DRIVE. DELIVER. TODAY. tagline.
///
/// No such photographic asset exists anywhere in this repo, and fabricating
/// one would be inventing brand material. The navy gradient below is a
/// faithful stand-in colour-graded to the reference's own grading; the
/// photograph must be supplied separately and dropped in at
/// `assets/brand/` — see the final report.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// D01 is a hold, not a gate: it shows for 2 seconds (the brand minimum)
  /// and then continues into D02 on its own. Tapping still skips ahead.
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _hold = Timer(const Duration(seconds: 2), _continue);
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  void _continue() {
    if (!mounted || _hold == null) return;
    _hold!.cancel();
    _hold = null;
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) => CefBottomSurface(
    color: CefBottomSurface.gradientBottom,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: GestureDetector(onTap: _continue, child: const SplashBackdrop()),
      ),
    ),
  );
}

/// D01's picture: the brand gradient with the official brand block centred.
/// Also kept under D02 while D02 fades in, so the hand-off has no blank frame.
class SplashBackdrop extends StatelessWidget {
  const SplashBackdrop({super.key});

  @override
  Widget build(BuildContext context) => const NavyBackdrop(
    watermark: false,
    child: Center(child: CeffloBrandBlock()),
  );
}

// ---------------------------------------------------------------------------
// D02 — Sign In
// ---------------------------------------------------------------------------

/// D39 Select Language — reused by D02's language pill and D38's Language
/// row, since the references draw the same sheet in both places.
/// Offers exactly the supported UI languages, by their native names.
Future<Locale?> showLanguageSheet(BuildContext context, Locale current) {
  var selected = current;
  return showCeffloSheet<Locale>(
    context,
    child: StatefulBuilder(
      builder: (context, setSheetState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetGrabber(),
          const SizedBox(height: 6),
          Text(L.selectLanguage, style: context.t.titleLarge),
          const SizedBox(height: Gap.lg),
          for (final lang in supportedUiLocales)
            Column(
              children: [
                InkWell(
                  onTap: () => setSheetState(() => selected = lang),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gap.gutter,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            uiLanguageNames[lang.languageCode]!,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.c.textPrimary,
                            ),
                          ),
                        ),
                        _RadioDot(selected: lang == selected),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: context.c.border,
                  indent: Gap.gutter,
                  endIndent: Gap.gutter,
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.gutter,
              Gap.lg,
              Gap.gutter,
              Gap.lg,
            ),
            child: CeffloPrimaryButton(
              L.done,
              onTap: () => Navigator.of(context).pop(selected),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// D02 — Welcome (baseline 3c111db; Email only)
// ---------------------------------------------------------------------------
/// Height of D02's top row (language control).
const double _welcomeTopRow = 48;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onGoogle,
    required this.onEmail,
    required this.onInvite,
  });
  final VoidCallback onGoogle;
  final VoidCallback onEmail;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) => CefBottomSurface(
    color: CefBottomSurface.gradientBottom,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: NavyBackdrop(
          child: SafeArea(
            // Spaced layout on a phone; scrolls instead of overflowing on a
            // short screen.
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Gap.gutter),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: _welcomeTopRow,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AuthLanguageControl(),
                          ),
                        ),
                        // Same place as on the splash (screen-centred).
                        SizedBox(
                          height: CeffloBrandBlock.gapAbove(
                            context,
                            MediaQuery.paddingOf(context).top + _welcomeTopRow,
                          ),
                        ),
                        const CeffloBrandBlock(),
                        const Spacer(),
                        _WelcomeOption(
                          label: L.continueWithGoogle,
                          image: 'assets/brand/google-g-logo.png',
                          onTap: onGoogle,
                        ),
                        const SizedBox(height: Gap.md),
                        _WelcomeOption(
                          label: L.continueWithEmail,
                          icon: LucideIcons.mail,
                          onTap: onEmail,
                        ),
                        const SizedBox(height: Gap.xl),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              L.haveInvite,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: CefColors.onNavy.withValues(alpha: .85),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: onInvite,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 4,
                                ),
                                child: Text(
                                  L.getStarted,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: CefColors.onNavy,
                                    decoration: TextDecoration.underline,
                                    decorationColor: CefColors.onNavy,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Gap.lg),
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

/// D02's full-width option button (3c111db CeffloAuthOption).
class _WelcomeOption extends StatelessWidget {
  const _WelcomeOption({
    required this.label,
    this.icon,
    this.image,
    required this.onTap,
  });
  final String label;
  final IconData? icon;
  final String? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(Sizes.buttonRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Sizes.buttonRadius),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Sizes.buttonRadius),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              image != null
                  ? Image.asset(image!, width: 22, height: 22)
                  : Icon(icon, size: 24, color: CefColors.navy),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
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

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? CefColors.accent : context.c.border,
        width: selected ? 2.5 : 1.6,
      ),
    ),
    child: selected
        ? Center(
            child: Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: CefColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          )
        : null,
  );
}

// ---------------------------------------------------------------------------
// D03 — Email Sign In
// ---------------------------------------------------------------------------

class EmailSignInScreen extends StatefulWidget {
  const EmailSignInScreen({
    super.key,
    this.onBack,
    required this.onSignIn,
    required this.onForgotPassword,
    required this.onSignUp,
  });

  /// Null when this is the first auth screen (nothing to go back to).
  final VoidCallback? onBack;
  final VoidCallback onSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _keep = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      widget.onSignIn();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await app.repo.signInWithPassword(_email.text, _password.text);
      await saveKeepSignedIn(_keep);
      await app.loadSession();
      if (mounted) widget.onSignIn();
    } on RepositoryError catch (error) {
      if (mounted) setState(() => _error = driverAuthErrorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    onBack: widget.onBack,
    title: L.signEmail,
    subtitle: L.enterEmailPasswordContinue,
    sheet: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CeffloTextField(
          label: L.email,
          controller: _email,
          hint: 'you@domain.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: Gap.lg),
        CeffloPasswordField(
          label: L.password,
          controller: _password,
          hint: L.enterPassword,
        ),
        if (_error != null) ...[
          const SizedBox(height: Gap.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _error!,
              key: const Key('driver-auth-error'),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC83D4B),
              ),
            ),
          ),
        ],
        const SizedBox(height: Gap.sm),
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

              CeffloTextLink(
                L.forgotPassword,
                onTap: widget.onForgotPassword,
                fontSize: 14,
                color: CefColors.navy,
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton(
          _busy ? L.signing : L.sign,
          busy: _busy,
          onTap: _busy ? null : _submit,
        ),
        const SizedBox(height: Gap.section),
        // Drivers join through a business invitation; account creation
        // follows it (the claim is bound server-side to the invited email).
        CeffloInlinePrompt(
          prompt: L.haveInvite,
          action: L.getStarted,
          onTap: widget.onSignUp,
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D04 — Create Account
// ---------------------------------------------------------------------------

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    required this.onBack,
    required this.onCreated,
    required this.onVerify,
    required this.onSignIn,
  });

  final VoidCallback onBack;
  final VoidCallback onCreated;

  /// The project requires email confirmation: open D04.1 for this address.
  final ValueChanged<String> onVerify;
  final VoidCallback onSignIn;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool _alreadyRegistered = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      widget.onCreated();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final needsVerification = await app.repo.signUpWithPassword(
        email: _email.text,
        password: _password.text,
        fullName: _name.text,
        phone: _phone.text,
      );
      if (!mounted) return;
      if (needsVerification) {
        widget.onVerify(_email.text.trim());
      } else {
        await app.loadSession();
        if (mounted) widget.onCreated();
      }
    } on EmailAlreadyRegistered {
      if (mounted) setState(() => _alreadyRegistered = true);
    } on RepositoryError catch (error) {
      if (mounted) setState(() => _error = driverAuthErrorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    onBack: widget.onBack,
    title: L.createAccount2,
    subtitle: L.letsGetStartedCreateCeffloDriver,
    sheet: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CeffloTextField(
          label: L.fullName,
          controller: _name,
          hint: L.enterFullName,
          icon: LucideIcons.user,
        ),
        const SizedBox(height: Gap.md),
        CeffloTextField(
          label: L.email,
          controller: _email,
          hint: 'you@domain.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: Gap.md),
        CeffloPhoneField(
          label: L.phoneNumber,
          controller: _phone,
          hint: L.enterPhoneNumber,
        ),
        const SizedBox(height: Gap.md),
        CeffloPasswordField(
          label: L.password,
          controller: _password,
          hint: L.createPassword,
        ),
        const SizedBox(height: Gap.md),
        CeffloNote(
          icon: LucideIcons.info,
          body: L.passwordMustLeast8CharactersNumber,
        ),
        if (_error != null) ...[
          const SizedBox(height: Gap.sm),
          Text(
            _error!,
            key: const Key('driver-auth-error'),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC83D4B),
            ),
          ),
        ],
        if (_alreadyRegistered) ...[
          const SizedBox(height: Gap.md),
          Text(
            L.emailAlreadyRegistered,
            key: const Key('driver-email-registered'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC83D4B),
            ),
          ),
          const SizedBox(height: Gap.xs),
          CeffloInlinePrompt(
            prompt: L.alreadyHaveAccount,
            action: L.sign,
            onTap: widget.onSignIn,
          ),
        ],
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton(
          _busy ? L.creatingAccount : L.createAccount3,
          busy: _busy,
          onTap: _busy ? null : _create,
        ),
        const SizedBox(height: Gap.lg),
        CeffloInlinePrompt(
          prompt: L.alreadyHaveAccount,
          action: L.sign,
          onTap: widget.onSignIn,
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D05 — Forgot Password
// ---------------------------------------------------------------------------

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
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      widget.onSent(_email.text.trim());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await app.repo.sendPasswordReset(_email.text);
      if (mounted) widget.onSent(_email.text.trim());
    } on RepositoryError catch (error) {
      if (mounted) setState(() => _error = driverAuthErrorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    onBack: widget.onBack,
    title: L.forgotPassword2,
    subtitle: L.noWorriesEnterEmailWellSend,
    scrollable: false,
    sheetPadding: const EdgeInsets.fromLTRB(
      Gap.gutter,
      Gap.xl,
      Gap.gutter,
      Gap.xl,
    ),
    sheet: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CeffloTextField(
          label: L.email,
          controller: _email,
          hint: 'you@domain.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        if (_error != null) ...[
          const SizedBox(height: Gap.sm),
          Text(
            _error!,
            key: const Key('driver-auth-error'),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC83D4B),
            ),
          ),
        ],
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton(
          _busy ? L.sending : L.sendResetLink,
          busy: _busy,
          onTap: _busy ? null : _send,
        ),
        const SizedBox(height: Gap.lg),
        CeffloTextLink(L.backSign, onTap: widget.onBackToSignIn),
        const SizedBox(height: 44),
        CeffloNote(
          icon: LucideIcons.lock,
          title: L.keepAccountSecure,
          body: L.wellSendSecureLinkResetPassword,
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D06 — Check Your Email
// ---------------------------------------------------------------------------

class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({
    super.key,
    required this.onBack,
    required this.onBackToSignIn,
    required this.email,
  });

  final VoidCallback onBack;
  final VoidCallback onBackToSignIn;
  final String email;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CeffloAuthScaffold(
      onBack: onBack,
      headerChild: Column(
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1C36).withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.mail,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: CefColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 18,
                      color: CefColors.onAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          Text(L.checkEmail, style: context.t.displayMedium),
          const SizedBox(height: Gap.sm),
          Text(
            L.weveSentPasswordResetLink,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: CefColors.onNavyMuted,
            ),
          ),
          const SizedBox(height: Gap.md),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF071A33).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(Sizes.cardRadius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.mail, size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                CeffloTextLink(
                  L.edit,
                  onTap: onBack,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
      sheet: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _numbered(context, 1, L.openEmailInbox, L.checkInboxSpamFolder),
          _numbered(context, 2, L.clickResetLink, L.followInstructionsEmail),
          _numbered(context, 3, L.setNewPassword, L.returnAppSign),
          const SizedBox(height: Gap.md),
          Divider(color: c.border, height: 1),
          const SizedBox(height: Gap.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.clock, size: 22, color: c.textLabel),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L.didntReceiveEmail, style: context.t.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      L.canRequestNewLink60Seconds,
                      style: context.t.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          ResendEmailButton(
            onResend: () =>
                AppScope.read(context).repo.sendPasswordReset(email),
          ),
          const SizedBox(height: Gap.lg),
          Center(child: CeffloTextLink(L.backSign, onTap: onBackToSignIn)),
        ],
      ),
    );
  }

  Widget _numbered(BuildContext context, int n, String title, String body) =>
      Padding(
        padding: const EdgeInsets.only(bottom: Gap.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CeffloIndexBadge(n, tone: ChipTone.neutral, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.t.titleSmall),
                  const SizedBox(height: 2),
                  Text(body, style: context.t.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
}

/// A real resend: calls [onResend], then counts down [cooldown] before it
/// can be used again (an email was just sent when the screen opened, so the
/// countdown starts immediately unless [coolingDown] is false). Success and
/// failure come from the backend; nothing is shown as sent that was not.
class ResendEmailButton extends StatefulWidget {
  const ResendEmailButton({
    super.key,
    required this.onResend,
    this.label,
    this.coolingDown = true,
  });

  final Future<void> Function() onResend;
  final String? label;
  final bool coolingDown;

  /// Matches the "request a new link in 60 seconds" copy.
  static const cooldown = 60;

  @override
  State<ResendEmailButton> createState() => _ResendEmailButtonState();
}

class _ResendEmailButtonState extends State<ResendEmailButton> {
  Timer? _timer;
  int _left = 0;
  bool _busy = false;
  String? _notice;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.coolingDown) _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _left = ResendEmailButton.cooldown;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _left--);
      if (_left <= 0) timer.cancel();
    });
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _notice = null;
      _error = null;
    });
    try {
      await widget.onResend();
      if (!mounted) return;
      setState(() {
        _notice = L.emailSentCheckInbox;
        _startCooldown();
      });
    } on RepositoryError catch (error) {
      if (mounted) setState(() => _error = driverAuthErrorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label ?? L.resendEmail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CeffloPrimaryButton(
          _busy
              ? L.sending
              : _left > 0
              ? L.resendEmailIn(_left)
              : label,
          key: const Key('driver-resend-email'),
          busy: _busy,
          onTap: _busy || _left > 0 ? null : _send,
        ),
        if (_notice != null || _error != null) ...[
          const SizedBox(height: Gap.sm),
          Text(
            _error ?? _notice!,
            key: Key(
              _error != null ? 'driver-auth-error' : 'driver-resend-sent',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _error != null
                  ? const Color(0xFFC83D4B)
                  : context.c.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Navy header shared by D04.1: mail badge, title, lead line and the
/// address the email went to.
class _MailSentHeader extends StatelessWidget {
  const _MailSentHeader({
    required this.title,
    required this.lead,
    required this.email,
    required this.onEdit,
  });

  final String title;
  final String lead;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: const Color(0xFF0A1C36).withValues(alpha: 0.75),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Icon(LucideIcons.mail, size: 42, color: Colors.white),
      ),
      const SizedBox(height: Gap.lg),
      Text(title, style: context.t.displayMedium, textAlign: TextAlign.center),
      const SizedBox(height: Gap.sm),
      Text(
        lead,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: CefColors.onNavyMuted,
        ),
      ),
      const SizedBox(height: Gap.md),
      Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF071A33).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.mail, size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            CeffloTextLink(
              L.edit,
              onTap: onEdit,
              fontSize: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// D04.1 — Verify Your Email
// ---------------------------------------------------------------------------

/// After sign-up on a project that requires email confirmation. The emailed
/// link returns to the app (auth callback), which signs the Driver in; the
/// app root reacts to that sign-in, so this screen needs no polling.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.onBack,
    required this.onBackToSignIn,
  });

  final String email;
  final VoidCallback onBack;
  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    onBack: onBack,
    headerChild: _MailSentHeader(
      title: L.verifyYourEmail,
      lead: L.weSentVerificationLinkTo,
      email: email,
      onEdit: onBack,
    ),
    sheet: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          L.openLinkOnThisPhone,
          textAlign: TextAlign.center,
          style: context.t.bodyLarge,
        ),
        const SizedBox(height: Gap.md),
        Text(
          L.checkInboxSpamFolder,
          textAlign: TextAlign.center,
          style: context.t.bodySmall,
        ),
        const SizedBox(height: Gap.xl),
        ResendEmailButton(
          onResend: () =>
              AppScope.read(context).repo.resendSignUpVerification(email),
        ),
        const SizedBox(height: Gap.lg),
        Center(child: CeffloTextLink(L.useDifferentEmail, onTap: onBack)),
        const SizedBox(height: Gap.md),
        Center(child: CeffloTextLink(L.backSign, onTap: onBackToSignIn)),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D08.2 — Verify Email with a 6-digit code
// ---------------------------------------------------------------------------

/// Why a code was not accepted, as the backend reports it. The wiring layer
/// maps GoTrue's `error_code` onto these; the screen never guesses. GoTrue
/// answers an expired and a mistyped code with the same `otp_expired`, so
/// [incorrect] is the default and [expired] is used only when the backend
/// says so unambiguously.
enum OtpFailureKind { incorrect, expired, rateLimited, network, other }

class OtpFailure implements Exception {
  const OtpFailure(this.kind, {this.message, this.retryAfterSeconds});
  final OtpFailureKind kind;
  final String? message;

  /// Resend cooldown the backend asked for, when it says so.
  final int? retryAfterSeconds;
}

/// Verify your email with the 6-digit code sent at sign-up. Presentation
/// and interaction only: [onVerify] and [onResend] come from the auth flow,
/// which owns the backend calls; the verified state appears only after
/// [onVerify] completes. The code is never logged or persisted.
class VerifyEmailCodeScreen extends StatefulWidget {
  const VerifyEmailCodeScreen({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onResend,
    required this.onContinue,
    required this.onBack,
    required this.onBackToSignIn,
    this.resendCooldown = ResendEmailButton.cooldown,
    this.title,
    this.showVerifiedState = true,
  });

  final String email;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;

  /// Into the existing Driver onboarding / access flow.
  final VoidCallback onContinue;

  /// Edit the address (back to sign-up), as the mail header's edit action.
  final VoidCallback onBack;
  final VoidCallback onBackToSignIn;
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
    setState(() {
      _failure = null;
      _error = null;
    });
    if (_complete && !_verifying) _verify();
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
      if (f.kind != OtpFailureKind.expired) _focus.requestFocus();
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

  static const _errorColor = Color(0xFFC83D4B);

  Widget _note(String text, {required bool error, Key? key}) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      key: key,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: error ? _errorColor : context.c.textSecondary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_verified) {
      // Success content centred in the sheet, Continue at its foot: the
      // navy header stays a slim band, so no area of the screen sits empty.
      return CeffloAuthScaffold(
        scrollable: false,
        sheet: Column(
          key: const Key('otp-verified'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: CefColors.navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 44,
                  color: CefColors.accent,
                ),
              ),
            ),
            const SizedBox(height: Gap.xl),
            Text(
              L.otpEmailVerified,
              textAlign: TextAlign.center,
              style: context.t.displayMedium?.copyWith(
                color: context.c.textPrimary,
              ),
            ),
            const SizedBox(height: Gap.sm),
            Text(
              L.otpVerifiedLead,
              textAlign: TextAlign.center,
              style: context.t.bodyLarge,
            ),
            const Spacer(),
            CeffloPrimaryButton(L.otpContinue, onTap: widget.onContinue),
          ],
        ),
      );
    }
    final expired = _failure == OtpFailureKind.expired;
    return CeffloAuthScaffold(
      onBack: _verifying ? null : widget.onBack,
      headerChild: _MailSentHeader(
        title: widget.title ?? L.verifyYourEmail,
        lead: L.otpLead,
        email: widget.email,
        onEdit: widget.onBack,
      ),
      sheet: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DriverOtpBoxes(
            controller: _code,
            focusNode: _focus,
            enabled: !_verifying && !expired,
            error: _failure != null && !expired,
            onChanged: _changed,
          ),
          if (_error != null) ...[
            const SizedBox(height: Gap.md),
            _note(_error!, error: true, key: const Key('otp-error')),
          ],
          if (_notice != null) ...[
            const SizedBox(height: Gap.md),
            _note(_notice!, error: false, key: const Key('otp-notice')),
          ],
          const SizedBox(height: Gap.xl),
          if (expired)
            CeffloPrimaryButton(
              _resending ? L.sending : L.otpSendNew,
              key: const Key('otp-send-new'),
              busy: _resending,
              onTap: _left > 0 ? null : _resend,
            )
          else
            CeffloPrimaryButton(
              _verifying ? L.otpVerifying : L.otpVerify,
              key: const Key('otp-verify'),
              busy: _verifying,
              onTap: _complete && _failure == null ? _verify : null,
            ),
          const SizedBox(height: Gap.lg),
          if (!(expired && _left <= 0))
            Center(
              child: _left > 0
                  ? Text(
                      L.otpResendIn(_left),
                      key: const Key('otp-resend-countdown'),
                      style: context.t.bodySmall,
                    )
                  : Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: Gap.xs,
                      children: [
                        Text(L.otpNoCode, style: context.t.bodyLarge),
                        _resending
                            ? Text(L.sending, style: context.t.bodyLarge)
                            : CeffloTextLink(
                                L.otpResend,
                                key: const Key('otp-resend'),
                                onTap: () {
                                  if (!_verifying) _resend();
                                },
                              ),
                      ],
                    ),
            ),
          const SizedBox(height: Gap.md),
          // Sign-up: an escape route for an existing account; any pending
          // invite stays on the device. Recovery keeps "Back to Sign In".
          if (widget.showVerifiedState)
            CeffloInlinePrompt(
              prompt: L.alreadyHaveAccount,
              action: L.sign,
              onTap: () {
                if (!_verifying) widget.onBackToSignIn();
              },
            )
          else
            Center(
              child: CeffloTextLink(
                L.backSign,
                onTap: () {
                  if (!_verifying) widget.onBackToSignIn();
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Six digit boxes in the Driver input geometry over one hidden numeric
/// field (keyboard, one-time-code autofill, paste and backspace come from
/// the platform field).
class _DriverOtpBoxes extends StatelessWidget {
  const _DriverOtpBoxes({
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
        height: Sizes.inputHeight + 4,
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: Listenable.merge([controller, focusNode]),
              builder: (context, _) {
                final v = controller.text;
                final active = focusNode.hasFocus
                    ? (v.length < n ? v.length : n - 1)
                    : -1;
                return Row(
                  children: [
                    for (var i = 0; i < n; i++) ...[
                      if (i > 0) const SizedBox(width: Gap.sm),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: enabled ? c.card : CefColors.tintNeutral,
                            borderRadius: BorderRadius.circular(
                              Sizes.inputRadius,
                            ),
                            border: Border.all(
                              color: error
                                  ? const Color(0xFFC83D4B)
                                  : i == active
                                  ? CefColors.navy
                                  : c.border,
                              width: error || i == active ? 1.8 : 1,
                            ),
                          ),
                          child: Text(
                            i < v.length ? v[i] : '',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: enabled ? c.textPrimary : c.textSecondary,
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
                    counterText: '',
                    isCollapsed: true,
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

// ---------------------------------------------------------------------------
// D09 — Link No Longer Valid
// ---------------------------------------------------------------------------

/// An emailed link (sign-up confirmation or password reset) that opened the
/// app but was expired, already used, or opened away from the device that
/// requested it. The server's answer is final; this offers a new email.
class LinkExpiredScreen extends StatefulWidget {
  const LinkExpiredScreen({
    super.key,
    required this.onForgotPassword,
    required this.onBackToSignIn,
  });

  final VoidCallback onForgotPassword;
  final VoidCallback onBackToSignIn;

  @override
  State<LinkExpiredScreen> createState() => _LinkExpiredScreenState();
}

class _LinkExpiredScreenState extends State<LinkExpiredScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    title: L.linkNoLongerValid,
    subtitle: L.linkExpiredOrUsedRequestNew,
    sheet: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CeffloTextField(
          label: L.email,
          controller: _email,
          hint: 'you@domain.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: Gap.lg),
        ResendEmailButton(
          label: L.resendVerificationEmail,
          coolingDown: false,
          onResend: () =>
              AppScope.read(context).repo.resendSignUpVerification(_email.text),
        ),
        const SizedBox(height: Gap.lg),
        Center(
          child: CeffloTextLink(
            L.sendNewResetLink,
            onTap: widget.onForgotPassword,
          ),
        ),
        const SizedBox(height: Gap.md),
        Center(child: CeffloTextLink(L.backSign, onTap: widget.onBackToSignIn)),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D07 — Set New Password
// ---------------------------------------------------------------------------

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

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_password.text != _confirm.text) {
      setState(() => _error = L.passwordsDoNotMatch);
      return;
    }
    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      widget.onUpdated();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await app.repo.updatePassword(_password.text);
      if (mounted) widget.onUpdated();
    } on RepositoryError catch (error) {
      if (mounted) setState(() => _error = driverAuthErrorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    onBack: widget.onBack,
    title: L.setNewPassword2,
    subtitle: L.chooseStrongPasswordCeffloDriverAccount,
    sheet: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CeffloPasswordField(
          label: L.newPassword,
          controller: _password,
          hint: L.enterNewPassword,
        ),
        const SizedBox(height: Gap.md),
        CeffloPasswordField(
          label: L.confirmPassword,
          controller: _confirm,
          hint: L.confirmPassword2,
        ),
        const SizedBox(height: Gap.md),
        CeffloNote(
          icon: LucideIcons.info,
          body: L.passwordMustLeast8CharactersNumber,
        ),
        if (_error != null) ...[
          const SizedBox(height: Gap.sm),
          Text(
            _error!,
            key: const Key('driver-auth-error'),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC83D4B),
            ),
          ),
        ],
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton(
          _busy ? L.updating : L.updatePassword,
          busy: _busy,
          onTap: _busy ? null : _update,
        ),
      ],
    ),
  );
}

String driverAuthErrorText(RepositoryError error) {
  const invalid = {'invalid_credentials', 'invalid_grant'};
  const limited = {
    'over_email_send_rate_limit',
    'over_request_rate_limit',
    'rate_limit_exceeded',
  };
  if (invalid.contains(error.code)) {
    return L.emailPasswordIncorrectTryAgain;
  }
  if (limited.contains(error.code)) {
    return L.tooManyAttemptsPleaseWaitBefore;
  }
  final lower = error.message.toLowerCase();
  if (lower.contains('clientexception') ||
      lower.contains('failed to fetch') ||
      lower.contains('socket')) {
    return L.unableConnectCheckConnectionTryAgain;
  }
  return error.message;
}

/// Maps a GoTrue failure on a 6-digit code (verify or resend) to the code
/// screen's states. GoTrue reports an expired and a mistyped code alike
/// (`otp_expired`), so both read as [OtpFailureKind.incorrect]. A resend
/// refused by the email rate limit carries the backend's own wait time.
OtpFailure otpFailureFrom(RepositoryError e) {
  final m = e.message.toLowerCase();
  final wait = RegExp(r'after (\d+) seconds?').firstMatch(m);
  final retry = wait == null ? null : int.tryParse(wait.group(1)!);
  const limited = {
    'over_email_send_rate_limit',
    'over_request_rate_limit',
    'rate_limit_exceeded',
  };
  if (e.code == 'otp_expired' || e.code == 'otp_disabled') {
    return const OtpFailure(OtpFailureKind.incorrect);
  }
  if (limited.contains(e.code) || retry != null) {
    return OtpFailure(OtpFailureKind.rateLimited, retryAfterSeconds: retry);
  }
  final text = driverAuthErrorText(e);
  if (text == L.unableConnectCheckConnectionTryAgain) {
    return const OtpFailure(OtpFailureKind.network);
  }
  if (m.contains('expired') || m.contains('invalid')) {
    return const OtpFailure(OtpFailureKind.incorrect);
  }
  return OtpFailure(OtpFailureKind.other, message: e.message);
}

// ---------------------------------------------------------------------------
// D08 — Password Updated
// ---------------------------------------------------------------------------

class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({super.key, required this.onBackToSignIn});
  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    headerChild: Column(
      children: [
        const SizedBox(height: Gap.section),
        const CeffloSuccessTick(size: 96, glow: true),
        const SizedBox(height: Gap.xl),
        Text(
          L.passwordUpdated,
          textAlign: TextAlign.center,
          style: context.t.displayMedium,
        ),
        const SizedBox(height: Gap.md),
        Text(
          L.passwordHasBeenSuccessfullyUpdated,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: CefColors.onNavyMuted,
          ),
        ),
      ],
    ),
    scrollable: false,
    sheet: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CeffloNote(
          icon: LucideIcons.shield,
          title: L.accountSecure,
          body: L.canNowSignNewPassword,
        ),
        const SizedBox(height: Gap.md),
        CeffloNote(
          icon: LucideIcons.smartphone,
          title: L.youllStaySigned,
          body: L.deviceCanContinueUsingApp,
        ),
        const SizedBox(height: Gap.section),
        CeffloPrimaryButton(L.backSign, onTap: onBackToSignIn),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D09 — Invitation Landing
// ---------------------------------------------------------------------------

/// Business identity row — logo tile, name, category, location. Repeated in
/// D09, D10, D18, D19 and D40-B.
class BusinessIdentityRow extends StatelessWidget {
  const BusinessIdentityRow({
    super.key,
    required this.business,
    this.onTap,
    this.compact = false,
  });

  final dynamic business;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: CefColors.navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.store,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name as String, style: context.t.titleMedium),
                    if (!compact) ...[
                      const SizedBox(height: 1),
                      Text(
                        business.category as String,
                        style: context.t.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 13,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          business.location as String,
                          style: context.t.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: c.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
