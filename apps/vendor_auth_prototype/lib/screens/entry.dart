/// Boards 01, 02 and 09 — the screens painted straight onto the Navy
/// backdrop, before any white sheet appears.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens.dart';
import '../widgets.dart';

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
    // A prototype has no bootstrap to wait on, so the brand moment is a
    // plain timer here. The shipped app ties this to real session loading.
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onReady();
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: navy,
    body: NavyBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 5),
            const BrandLockup(height: 200),
            const SizedBox(height: Gap.xs),
            Text(
              'Vendor',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .92),
                fontSize: 21,
                fontWeight: FontWeight.w500,
                letterSpacing: .2,
              ),
            ),
            const Spacer(flex: 5),
            const Tagline(),
            const SizedBox(height: Gap.xl),
            _SplashProgress(animation: _progress),
            const SizedBox(height: Gap.xl),
          ],
        ),
      ),
    ),
  );
}

/// Three segments with the lit one travelling left to right, as board 01
/// shows at the foot of the Splash.
class _SplashProgress extends StatelessWidget {
  const _SplashProgress({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final lit = (animation.value * 3).floor() % 3;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          return Container(
            width: 56,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == lit ? yellow : Colors.white.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      );
    },
  );
}

// ----------------------------------------------------------- 02 Sign In

class SignInScreen extends StatelessWidget {
  const SignInScreen({
    super.key,
    required this.onEmail,
    required this.onSignUp,
    required this.onLanguage,
    required this.language,
  });

  final VoidCallback onEmail;
  final VoidCallback onSignUp;
  final VoidCallback onLanguage;
  final String language;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: navy,
    body: NavyBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              // IntrinsicHeight so the Spacer below has a bounded height to
              // divide; inside a plain scroll view it would be unbounded and
              // the tagline would float up under the sign-up prompt.
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _LanguagePill(
                          label: language,
                          onTap: onLanguage,
                        ),
                      ),
                      const SizedBox(height: Gap.xl),
                      const Center(child: BrandLockup(height: 145)),
                      const SizedBox(height: Gap.xl),
                      const Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: Gap.xs),
                      Text(
                        'Sign in to manage your deliveries today.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .82),
                          fontSize: 15.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: Gap.xl),
                      ProviderButton(
                        label: 'Continue with Apple',
                        glyph: const Icon(
                          Icons.apple,
                          size: 22,
                          color: Colors.black,
                        ),
                        onTap: () => _providerNote(context, 'Apple'),
                      ),
                      const SizedBox(height: Gap.sm),
                      ProviderButton(
                        label: 'Continue with Google',
                        glyph: const _GoogleGlyph(),
                        onTap: () => _providerNote(context, 'Google'),
                      ),
                      const SizedBox(height: Gap.sm),
                      ProviderButton(
                        label: 'Continue with Email',
                        filled: true,
                        glyph: const Icon(
                          LucideIcons.mail,
                          size: 21,
                          color: ink,
                        ),
                        onTap: onEmail,
                      ),
                      const SizedBox(height: Gap.lg),
                      const _OrDivider(),
                      const SizedBox(height: Gap.lg),
                      _DarkInlinePrompt(
                        question: "Don't have an account?",
                        action: 'Sign up',
                        onTap: onSignUp,
                      ),
                      const Spacer(),
                      const Tagline(),
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

  void _providerNote(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: navyDeep,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '$provider sign-in is not wired in this prototype.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

/// Locked provider button. Board 02 shows Apple and Google on white and
/// Email on Yellow — the Yellow one is the emphasised path.
class ProviderButton extends StatelessWidget {
  const ProviderButton({
    super.key,
    required this.label,
    required this.glyph,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final Widget glyph;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: buttonHeight,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? yellow : surface,
        foregroundColor: filled ? ink : Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          glyph,
          const SizedBox(width: Gap.sm),
          // Flexible, because at phone width these labels overflow a Row.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Stand-in for Google's multi-colour "G". The official mark is not in the
/// repo, and the prototype deliberately has no extra brand-asset dependency.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 22,
    height: 22,
    child: Center(
      child: Text(
        'G',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
        ),
      ),
    ),
  );
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.globe, size: 21, color: Colors.white),
        const SizedBox(width: Gap.sm),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(LucideIcons.chevronDown, size: 19, color: Colors.white),
      ],
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: Colors.white.withValues(alpha: .28)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          child: Text(
            'or',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .82),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// The sign-up prompt as it reads on Navy rather than on the white sheet.
class _DarkInlinePrompt extends StatelessWidget {
  const _DarkInlinePrompt({
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        '$question ',
        style: TextStyle(
          color: Colors.white.withValues(alpha: .82),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      GestureDetector(
        onTap: onTap,
        child: Text(
          action,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white,
          ),
        ),
      ),
    ],
  );
}

// -------------------------------------------------- 09 Select Language

/// The four product languages. Board 09 locks the endonyms, so they are
/// rendered in faces that actually carry those scripts.
const languageOptions = [
  ('English', 'en'),
  ('Bahasa Melayu', 'ms'),
  ('中文 (简体)', 'zh'),
  ('தமிழ்', 'ta'),
];

class LanguageSheet extends StatefulWidget {
  const LanguageSheet({super.key, required this.selected});

  final String selected;

  @override
  State<LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<LanguageSheet> {
  late String _choice = widget.selected;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
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
          const SheetTitle(
            'Select language',
            subtitle: 'Choose your preferred language.',
          ),
          const SizedBox(height: Gap.lg),
          for (final (name, code) in languageOptions) ...[
            _LanguageRow(
              name: name,
              code: code,
              selected: _choice == name,
              onTap: () => setState(() => _choice = name),
            ),
            const SizedBox(height: Gap.sm),
          ],
          const SizedBox(height: Gap.sm),
          PrimaryButton(
            'Continue',
            onPressed: () => Navigator.of(context).pop(_choice),
          ),
        ],
      ),
    ),
  );
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.name,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  /// Board 09 gives each language a round badge: a globe for English, and a
  /// short script cue for the rest.
  Widget get _badge {
    const base = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: ink,
    );
    final child = switch (code) {
      'en' => const Icon(LucideIcons.globe, size: 19, color: ink),
      'ms' => const Text('BM', style: base),
      'zh' => Text('中', style: hanFace(base)),
      _ => Text('த', style: tamilFace(base)),
    };
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEFF2F7),
      ),
      child: child,
    );
  }

  TextStyle get _nameStyle {
    const base = TextStyle(
      color: ink,
      fontSize: 16.5,
      fontWeight: FontWeight.w700,
    );
    return switch (code) {
      'zh' => hanFace(base),
      'ta' => tamilFace(base),
      _ => base,
    };
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fieldRadius),
        border: Border.all(
          color: selected ? navy : fieldBorder,
          width: selected ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          _badge,
          const SizedBox(width: Gap.md),
          Expanded(child: Text(name, style: _nameStyle)),
          if (selected)
            const Icon(LucideIcons.circleCheck, size: 24, color: navy)
          else
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD3D9E4), width: 1.6),
              ),
            ),
        ],
      ),
    ),
  );
}
