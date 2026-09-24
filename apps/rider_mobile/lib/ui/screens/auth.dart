import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../brand.dart';
import '../widgets.dart';

/// D01–D09. The auth family owns its own stage stack: it runs before the
/// app shell exists, so it does not share the signed-in navigation graph.
class AuthFlow extends StatefulWidget {
  const AuthFlow({
    super.key,
    this.initial = DRoute.splash,
    required this.onAuthenticated,
  });

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

  void _go(DRoute route) => setState(() => _stack.add(route));

  void _back() => setState(() {
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

  @override
  Widget build(BuildContext context) => switch (_stack.last) {
    DRoute.splash => SplashScreen(onContinue: () => _resetTo(DRoute.signIn)),
    DRoute.signIn => SignInScreen(
      onEmail: () => _go(DRoute.emailSignIn),
      onSignUp: () => _go(DRoute.createAccount),
    ),
    DRoute.emailSignIn => EmailSignInScreen(
      onBack: _back,
      onSignIn: () => widget.onAuthenticated(null),
      onForgotPassword: () => _go(DRoute.forgotPassword),
      onSignUp: () => _go(DRoute.createAccount),
    ),
    DRoute.createAccount => CreateAccountScreen(
      onBack: _back,
      onCreated: () => _go(DRoute.invitationLanding),
      onSignIn: () => _resetTo(DRoute.emailSignIn),
    ),
    DRoute.forgotPassword => ForgotPasswordScreen(
      onBack: _back,
      onSent: () => _go(DRoute.checkEmail),
      onBackToSignIn: () => _resetTo(DRoute.emailSignIn),
    ),
    DRoute.checkEmail => CheckEmailScreen(
      onBack: _back,
      onOpenLink: () => _go(DRoute.setNewPassword),
      onBackToSignIn: () => _resetTo(DRoute.emailSignIn),
    ),
    DRoute.setNewPassword => SetNewPasswordScreen(
      onBack: _back,
      onUpdated: () => _go(DRoute.passwordUpdated),
    ),
    DRoute.passwordUpdated => PasswordUpdatedScreen(
      onBackToSignIn: () => _resetTo(DRoute.emailSignIn),
    ),
    // Accepting the invitation drops the Driver into the signed-in shell at
    // D10; "Maybe Later" lands on the same shell with no business connected.
    DRoute.invitationLanding => InvitationLandingScreen(
      onAccept: () => widget.onAuthenticated(DRoute.acceptInvitation),
      onDecline: () => _resetTo(DRoute.signIn),
      onMaybeLater: () => widget.onAuthenticated(DRoute.noBusinessConnected),
    ),
    _ => SignInScreen(
      onEmail: () => _go(DRoute.emailSignIn),
      onSignUp: () => _go(DRoute.createAccount),
    ),
  };
}

// ---------------------------------------------------------------------------
// Shared auth pieces
// ---------------------------------------------------------------------------

/// Full-width bordered social/email control (D02). Icon left, label centred.
class CeffloAuthOption extends StatelessWidget {
  const CeffloAuthOption({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.iconChild,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? iconChild;

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
          // Full width explicitly: the row is centred in a Column, so
          // without this the Stack would shrink-wrap the label and the
          // left-positioned icon would land on top of it.
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Sizes.buttonRadius),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              iconChild ?? Icon(icon, size: 24, color: CefColors.navy),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact half-width variant used by D03's Apple / Google pair.
class CeffloAuthChip extends StatelessWidget {
  const CeffloAuthChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.iconChild,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? iconChild;

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
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Sizes.buttonRadius),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconChild ?? Icon(icon, size: 21, color: CefColors.navy),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Third-party sign-in marks
// ---------------------------------------------------------------------------
//
// `lucide_icons_flutter` ships no brand logos (its `apple` glyph is the fruit,
// not the Apple Inc. mark), and `assets/brand/` is Cefflo-only by policy, so
// the two marks the references draw on D02/D03 are reproduced here from their
// official outlines rather than approximated with drawing primitives.

/// Minimal SVG path-data reader — enough for the two brand outlines below
/// (`M m L l H h V v C c S s Z z`; neither mark uses arcs or quadratics).
Path _svgPath(String d) {
  final tokens = RegExp(r'[MmLlHhVvCcSsZz]|-?\d*\.?\d+(?:[eE][-+]?\d+)?')
      .allMatches(d)
      .map((m) => m[0]!)
      .toList();

  final path = Path();
  var i = 0;
  var x = 0.0, y = 0.0; // current point
  var cx = 0.0, cy = 0.0; // last cubic control point, for S/s reflection
  var startX = 0.0, startY = 0.0;
  var command = '';
  var lastWasCubic = false;

  double next() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (RegExp(r'^[A-Za-z]$').hasMatch(tokens[i])) command = tokens[i++];
    final rel = command.toLowerCase() == command;
    switch (command.toLowerCase()) {
      case 'm':
        final nx = next(), ny = next();
        x = rel ? x + nx : nx;
        y = rel ? y + ny : ny;
        path.moveTo(x, y);
        startX = x;
        startY = y;
        // A repeated coordinate pair after M is an implicit lineTo.
        command = rel ? 'l' : 'L';
        lastWasCubic = false;
      case 'l':
        final nx = next(), ny = next();
        x = rel ? x + nx : nx;
        y = rel ? y + ny : ny;
        path.lineTo(x, y);
        lastWasCubic = false;
      case 'h':
        final nx = next();
        x = rel ? x + nx : nx;
        path.lineTo(x, y);
        lastWasCubic = false;
      case 'v':
        final ny = next();
        y = rel ? y + ny : ny;
        path.lineTo(x, y);
        lastWasCubic = false;
      case 'c':
        final x1 = rel ? x + next() : next(), y1 = rel ? y + next() : next();
        final x2 = rel ? x + next() : next(), y2 = rel ? y + next() : next();
        final nx = rel ? x + next() : next(), ny = rel ? y + next() : next();
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
        lastWasCubic = true;
      case 's':
        final x1 = lastWasCubic ? 2 * x - cx : x;
        final y1 = lastWasCubic ? 2 * y - cy : y;
        final x2 = rel ? x + next() : next(), y2 = rel ? y + next() : next();
        final nx = rel ? x + next() : next(), ny = rel ? y + next() : next();
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
        lastWasCubic = true;
      case 'z':
        path.close();
        x = startX;
        y = startY;
        lastWasCubic = false;
    }
  }
  return path;
}

/// Paints one or more SVG outlines, scaled uniformly into the widget box.
class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter(this.shapes, this.viewBox);

  /// (path data, fill colour) pairs, painted in order.
  final List<(String, Color)> shapes;
  final Size viewBox;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / viewBox.width,
      size.height / viewBox.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - viewBox.width * scale) / 2,
      (size.height - viewBox.height * scale) / 2,
    );
    canvas.scale(scale);
    for (final (d, color) in shapes) {
      canvas.drawPath(_svgPath(d), Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) =>
      oldDelegate.shapes != shapes || oldDelegate.viewBox != viewBox;
}

/// The Apple mark used by "Continue with Apple" (D02) and D03's Apple chip.
class AppleGlyph extends StatelessWidget {
  const AppleGlyph({super.key, this.size = 22, this.color = Colors.black});
  final double size;
  final Color color;

  static const _body =
      'M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 '
      '134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 '
      '123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-'
      '155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 '
      '66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 '
      '2.6 198.3 99.2z';
  static const _leaf =
      'M554.1 159.4c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1'
      '-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 '
      '7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 '
      '135.5-71.3z';

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _BrandMarkPainter([
        (_body, color),
        (_leaf, color),
      ], const Size(814, 1000)),
    ),
  );
}

/// The four-colour Google "G" used by "Continue with Google" (D02) and
/// D03's Google chip.
class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({super.key, this.size = 22});
  final double size;

  static const _blue =
      'M45.12 24.5c0-1.56-.14-3.06-.4-4.5H24v8.51h11.84c-.51 2.75-2.06 '
      '5.08-4.39 6.64v5.52h7.11c4.16-3.83 6.56-9.47 6.56-16.17z';
  static const _green =
      'M24 46c5.94 0 10.92-1.97 14.56-5.33l-7.11-5.52c-1.97 1.32-4.49 '
      '2.1-7.45 2.1-5.73 0-10.58-3.87-12.31-9.07H4.34v5.7C7.96 41.07 15.4 '
      '46 24 46z';
  static const _yellow =
      'M11.69 28.18C11.25 26.86 11 25.45 11 24s.25-2.86.69-4.18v-5.7H4.34'
      'C2.85 17.09 2 20.45 2 24s.85 6.91 2.34 9.88l7.35-5.7z';
  static const _red =
      'M24 10.75c3.23 0 6.13 1.11 8.41 3.29l6.31-6.31C34.91 4.18 29.93 2 '
      '24 2 15.4 2 7.96 6.93 4.34 14.12l7.35 5.7c1.73-5.2 6.58-9.07 '
      '12.31-9.07z';

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _BrandMarkPainter(const [
        (_blue, Color(0xFF4285F4)),
        (_green, Color(0xFF34A853)),
        (_yellow, Color(0xFFFBBC05)),
        (_red, Color(0xFFEA4335)),
      ], const Size(48, 48)),
    ),
  );
}

/// "OR" rule with a hairline either side (D02, D03).
class CeffloOrDivider extends StatelessWidget {
  const CeffloOrDivider({super.key, this.label = 'OR'});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Expanded(child: Divider(color: c.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: c.border, height: 1)),
      ],
    );
  }
}

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
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(prompt, style: context.t.bodyMedium),
      const SizedBox(width: 6),
      CeffloTextLink(action, onTap: onTap, fontSize: 14),
    ],
  );
}

/// The globe + language + chevron pill at the foot of D02.
class LanguagePill extends StatelessWidget {
  const LanguagePill({
    super.key,
    required this.language,
    required this.onTap,
    this.onDark = false,
  });
  final String language;
  final VoidCallback onTap;

  /// D02 sits the selector straight on the blue backdrop with no pill behind
  /// it; every other placement draws it on a white sheet.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.globe,
          size: 20,
          color: onDark ? CefColors.onNavy : CefColors.navy,
        ),
        const SizedBox(width: 10),
        Text(
          language,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: onDark ? CefColors.onNavy : c.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          LucideIcons.chevronDown,
          size: 18,
          color: onDark
              ? CefColors.onNavy.withValues(alpha: .9)
              : c.textSecondary,
        ),
      ],
    );
    if (onDark) {
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: row,
        ),
      );
    }
    return Center(
      child: Material(
        color: CefColors.tintNeutral,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.border),
            ),
            child: row,
          ),
        ),
      ),
    );
  }
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
  /// D01 is a hold, not a gate: it shows for ~3 seconds and then continues
  /// into D02 on its own. Tapping still skips ahead.
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _hold = Timer(const Duration(seconds: 3), _continue);
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
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
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
      body: GestureDetector(
        onTap: _continue,
        child: NavyBackdrop(
          watermark: false,
          // Logo mark and "Cefflo Driver" wordmark only, centred on screen.
          child: const SafeArea(
            child: Center(child: CeffloSplashLockup(width: 120)),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// D02 — Sign In
// ---------------------------------------------------------------------------

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
  String _language = 'English';

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.gutter),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: LanguagePill(
                    language: _language,
                    onDark: true,
                    onTap: () => _pickLanguage(context),
                  ),
                ),
                const Spacer(flex: 3),
                const CeffloSplashLockup(),
                const Spacer(flex: 4),
                CeffloAuthOption(
                  label: 'Continue with Apple',
                  iconChild: const AppleGlyph(size: 24),
                  onTap: widget.onEmail,
                ),
                const SizedBox(height: Gap.md),
                CeffloAuthOption(
                  label: 'Continue with Google',
                  iconChild: const GoogleGlyph(size: 24),
                  onTap: widget.onEmail,
                ),
                const SizedBox(height: Gap.md),
                CeffloAuthOption(
                  label: 'Continue with Email',
                  icon: LucideIcons.mail,
                  onTap: widget.onEmail,
                ),
                const SizedBox(height: Gap.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Have an invite?',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: CefColors.onNavy.withValues(alpha: .85),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: widget.onSignUp,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        child: Text(
                          'Get started',
                          style: TextStyle(
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
  );

  Future<void> _pickLanguage(BuildContext context) async {
    final picked = await showLanguageSheet(context, _language);
    if (picked != null && mounted) setState(() => _language = picked);
  }
}

/// D39 Select Language — reused by D02's language pill and D38's Language
/// row, since the references draw the same sheet in both places.
Future<String?> showLanguageSheet(BuildContext context, String current) {
  var selected = current;
  return showCeffloSheet<String>(
    context,
    child: StatefulBuilder(
      builder: (context, setSheetState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetGrabber(),
          const SizedBox(height: 6),
          Text('Select Language', style: context.t.titleLarge),
          const SizedBox(height: Gap.lg),
          for (final lang in DemoData.languages)
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
                            lang,
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
              'Done',
              onTap: () => Navigator.of(context).pop(selected),
            ),
          ),
        ],
      ),
    ),
  );
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
    required this.onBack,
    required this.onSignIn,
    required this.onForgotPassword,
    required this.onSignUp,
  });

  final VoidCallback onBack;
  final VoidCallback onSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    onBack: widget.onBack,
    title: 'Sign In with Email',
    subtitle: 'Enter your email and password\nto continue.',
    sheet: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CeffloTextField(
          label: 'Email',
          controller: _email,
          hint: 'you@domain.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: Gap.lg),
        CeffloPasswordField(
          label: 'Password',
          controller: _password,
          hint: 'Enter your password',
        ),
        const SizedBox(height: Gap.md),
        Align(
          alignment: Alignment.centerRight,
          child: CeffloTextLink(
            'Forgot Password?',
            onTap: widget.onForgotPassword,
            fontSize: 14,
            color: CefColors.navy,
          ),
        ),
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton('Sign In', onTap: widget.onSignIn),
        const SizedBox(height: Gap.section),
        const CeffloOrDivider(),
        const SizedBox(height: Gap.lg),
        Text('Continue with', style: context.t.bodyLarge),
        const SizedBox(height: Gap.md),
        Row(
          children: [
            Expanded(
              child: CeffloAuthChip(
                label: 'Apple',
                iconChild: const AppleGlyph(size: 21),
                onTap: widget.onSignIn,
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: CeffloAuthChip(
                label: 'Google',
                iconChild: const GoogleGlyph(),
                onTap: widget.onSignIn,
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.section),
        CeffloInlinePrompt(
          prompt: 'Don’t have an account?',
          action: 'Sign Up',
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
    required this.onSignIn,
  });

  final VoidCallback onBack;
  final VoidCallback onCreated;
  final VoidCallback onSignIn;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    onBack: widget.onBack,
    title: 'Create your\naccount',
    subtitle: 'Let’s get you started. Create your\nCefflo Driver account.',
    sheet: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CeffloTextField(
          label: 'Full Name',
          controller: _name,
          hint: 'Enter your full name',
          icon: LucideIcons.user,
        ),
        const SizedBox(height: Gap.md),
        CeffloTextField(
          label: 'Email',
          controller: _email,
          hint: 'you@domain.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: Gap.md),
        CeffloPhoneField(
          label: 'Phone Number',
          controller: _phone,
          hint: 'Enter your phone number',
        ),
        const SizedBox(height: Gap.md),
        CeffloPasswordField(
          label: 'Password',
          controller: _password,
          hint: 'Create a password',
        ),
        const SizedBox(height: Gap.md),
        const CeffloNote(
          icon: LucideIcons.info,
          body: 'Password must be at least 8 characters\nwith a number and a letter.',
        ),
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton('Create Account', onTap: widget.onCreated),
        const SizedBox(height: Gap.lg),
        CeffloInlinePrompt(
          prompt: 'Already have an account?',
          action: 'Sign In',
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
  final VoidCallback onSent;
  final VoidCallback onBackToSignIn;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    onBack: widget.onBack,
    title: 'Forgot\nPassword?',
    subtitle: 'No worries. Enter your email and\nwe’ll send you a reset link.',
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
          label: 'Email',
          controller: _email,
          hint: 'you@domain.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton('Send Reset Link', onTap: widget.onSent),
        const SizedBox(height: Gap.lg),
        CeffloTextLink('Back to Sign In', onTap: widget.onBackToSignIn),
        const SizedBox(height: 44),
        const CeffloNote(
          icon: LucideIcons.lock,
          title: 'Keep your account secure',
          body: 'We’ll send a secure link to reset your password. The link will expire after a short period.',
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
    required this.onOpenLink,
    required this.onBackToSignIn,
    this.email = 'you@domain.com',
  });

  final VoidCallback onBack;
  final VoidCallback onOpenLink;
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
          Text('Check your email', style: context.t.displayMedium),
          const SizedBox(height: Gap.sm),
          const Text(
            'We’ve sent a password reset link to',
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
                  'Edit',
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
          _numbered(
            context,
            1,
            'Open your email inbox',
            'Check your inbox (and spam folder).',
          ),
          _numbered(
            context,
            2,
            'Click the reset link',
            'Follow the instructions in the email.',
          ),
          _numbered(
            context,
            3,
            'Set a new password',
            'Return to the app and sign in.',
          ),
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
                    Text(
                      'Didn’t receive the email?',
                      style: context.t.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You can request a new link in 60 seconds.',
                      style: context.t.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          // Disabled resend, exactly as the reference renders it.
          Container(
            height: Sizes.buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CefColors.tintNeutral,
              borderRadius: BorderRadius.circular(Sizes.buttonRadius),
            ),
            child: Text(
              'Resend Email (58s)',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          Center(child: CeffloTextLink('Back to Sign In', onTap: onOpenLink)),
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

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    onBack: widget.onBack,
    title: 'Set a new\npassword',
    subtitle: 'Choose a strong password for\nyour Cefflo Driver account.',
    sheet: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CeffloPasswordField(
          label: 'New Password',
          controller: _password,
          hint: 'Enter new password',
        ),
        const SizedBox(height: Gap.md),
        CeffloPasswordField(
          label: 'Confirm Password',
          controller: _confirm,
          hint: 'Confirm your password',
        ),
        const SizedBox(height: Gap.md),
        const CeffloNote(
          icon: LucideIcons.info,
          body: 'Password must be at least 8 characters\nwith a number and a letter.',
        ),
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton('Update Password', onTap: widget.onUpdated),
      ],
    ),
  );
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
          'Password Updated!',
          textAlign: TextAlign.center,
          style: context.t.displayMedium,
        ),
        const SizedBox(height: Gap.md),
        const Text(
          'Your password has been\nsuccessfully updated.',
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
        const CeffloNote(
          icon: LucideIcons.shield,
          title: 'Your account is secure',
          body: 'You can now sign in with your new password.',
        ),
        const SizedBox(height: Gap.md),
        const CeffloNote(
          icon: LucideIcons.smartphone,
          title: 'You’ll stay signed in',
          body: 'On this device, you can continue using the app.',
        ),
        const SizedBox(height: Gap.section),
        CeffloPrimaryButton('Back to Sign In', onTap: onBackToSignIn),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D09 — Invitation Landing
// ---------------------------------------------------------------------------

class InvitationLandingScreen extends StatelessWidget {
  const InvitationLandingScreen({
    super.key,
    required this.onAccept,
    required this.onDecline,
    required this.onMaybeLater,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onMaybeLater;

  @override
  Widget build(BuildContext context) {
    final business = DemoData.invitingBusiness;
    return CeffloAuthScaffold(
      headerAction: GestureDetector(
        onTap: onMaybeLater,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Text(
            'Maybe Later',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CefColors.onNavy.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
      title: 'You’re Invited!',
      subtitle:
          'Join ${business.name} on Cefflo. Be part of their delivery team '
          'and start making deliveries.',
      sheetPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.xl,
      ),
      scrollable: false,
      sheet: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BusinessIdentityRow(business: business),
          const SizedBox(height: Gap.lg),
          const CeffloFeatureRow(
            icon: LucideIcons.users,
            title: 'Work with a trusted local business',
            body: 'Make deliveries within their service area.',
          ),
          const CeffloFeatureRow(
            icon: LucideIcons.clock,
            title: 'Start delivering today',
            body: 'Get access once your account is approved.',
          ),
          const CeffloFeatureRow(
            icon: LucideIcons.shield,
            title: 'All in one app',
            body: 'Orders, navigation and support.',
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton('Accept Invitation', onTap: onAccept),
          const SizedBox(height: Gap.md),
          Center(child: CeffloTextLink('Decline', onTap: onDecline)),
        ],
      ),
    );
  }
}

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
