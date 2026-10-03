/// Shared controls for the locked Vendor Auth boards.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'tokens.dart';

/// Navy header (Back + lockup) above a white rounded sheet — the layout every
/// locked form screen after Sign In uses.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.child,
    this.onBack,
    this.showHandle = false,
  });

  final Widget child;
  final VoidCallback? onBack;
  final bool showHandle;

  /// Visible height of the header lockup on the locked boards. Keep this
  /// fixed so the blurred logo never grows or shrinks between form states.
  static const _headerLockup = 112.0;
  static const _backRow = 44.0;

  /// Smallest the Navy band may squeeze to before the page starts scrolling.
  static const _minBrandBand = 108.0;

  @override
  Widget build(BuildContext context) {
    // The sheet is exactly as tall as its content, and the whole page scrolls
    // when that no longer fits. Sizing the sheet to the leftover space made
    // every screen the same height, and letting it scroll inside a fixed
    // frame clipped it at both ends — the title sliced by the card's top edge,
    // the CTA pushed past the bottom of the screen.
    return Scaffold(
      backgroundColor: navy,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            // IntrinsicHeight gives the Expanded below a bounded height to
            // divide, which a bare scroll view cannot.
            child: IntrinsicHeight(
              child: NavyBackdrop(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      SizedBox(
                        height: _backRow,
                        child: Row(
                          children: [
                            if (onBack != null)
                              BackChevron(onTap: onBack!)
                            else
                              const SizedBox(width: Gap.lg),
                          ],
                        ),
                      ),
                      // The lockup centres itself in whatever Navy the sheet
                      // leaves, and scales down rather than sliding under the
                      // card and showing half a wordmark.
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: _minBrandBand,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(24, 8, 24, 22),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              // Soft-focus, per the locked sheet boards.
                              child: BrandLockup(
                                height: _headerLockup,
                                blurSigma: 5.2,
                                opacity: .74,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(sheetRadius),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 18, 24, 44),
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
                    ],
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

class BackChevron extends StatelessWidget {
  const BackChevron({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    icon: const Icon(LucideIcons.chevronLeft, size: 22, color: Colors.white),
    label: const Text(
      'Back',
      style: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      foregroundColor: Colors.white,
    ),
  );
}

/// Centred sheet title with its supporting line, as boards 05/06/10/11/12
/// and the auth states show it.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.title, {super.key, this.subtitle, this.align});

  final String title;
  final String? subtitle;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    final a = align ?? TextAlign.center;
    return Column(
      crossAxisAlignment: a == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: a,
          style: const TextStyle(
            color: ink,
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Gap.xs),
          Text(
            subtitle!,
            textAlign: a,
            style: const TextStyle(
              color: inkMuted,
              fontSize: 15.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Filled Yellow CTA. Shows [busyLabel] with a spinner while [busy], and
/// greys out when [onPressed] is null — both straight off the locked states.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.busy = false,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: ink,
          disabledBackgroundColor: busy ? yellow : disabledFill,
          disabledForegroundColor: busy ? ink : disabledInk,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
        child: busy
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(ink),
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Text(
                    busyLabel ?? label,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

/// Navy-outlined secondary, as "Try another email" / "Use a different email".
class OutlineButton extends StatelessWidget {
  const OutlineButton(this.label, {super.key, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: buttonHeight,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        disabledForegroundColor: disabledInk,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        side: BorderSide(
          color: onPressed == null ? fieldBorder : navy,
          width: 1.4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// Underlined navy text link, as "Back to sign in" / "Forgot password?".
class TextLink extends StatelessWidget {
  const TextLink(
    this.label, {
    super.key,
    required this.onTap,
    this.bold = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: ink,
        fontSize: 15,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        decoration: TextDecoration.underline,
        decorationColor: ink,
      ),
    ),
  );
}

/// Labelled field with a leading glyph, an optional eye toggle, and either a
/// helper line or an error line beneath — the locked field anatomy.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.obscure = false,
    this.onToggleObscure,
    this.helper,
    this.error,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? helper;
  final String? error;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ink,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Gap.xs),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: ink, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: inkFaint, fontSize: 16),
            filled: true,
            fillColor: surface,
            prefixIcon: Icon(icon, size: 21, color: ink),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 21,
                      color: inkMuted,
                    ),
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 17),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldRadius),
              borderSide: BorderSide(
                color: hasError ? attention : fieldBorder,
                width: hasError ? 1.4 : 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldRadius),
              borderSide: BorderSide(
                color: hasError ? attention : navy,
                width: 1.4,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: Gap.xs),
          Text(
            error!,
            style: const TextStyle(
              color: attention,
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else if (helper != null) ...[
          const SizedBox(height: Gap.xs),
          Text(
            helper!,
            style: const TextStyle(
              color: inkMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Navy outline ring around a glyph (boards 10/11/12 and the resend state).
/// Board 06 shows its envelope bare and larger, so [circled] is false there —
/// each screen follows its own board rather than one treatment for both.
class StatusIcon extends StatelessWidget {
  const StatusIcon(this.icon, {super.key, this.circled = true});

  final IconData icon;
  final bool circled;

  @override
  Widget build(BuildContext context) => Center(
    child: circled
        ? Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: navy, width: 2),
            ),
            child: Icon(icon, size: 34, color: navy),
          )
        : Icon(icon, size: 62, color: navy),
  );
}

/// Board 08's success mark: a filled Yellow disc with a navy tick.
class SuccessDisc extends StatelessWidget {
  const SuccessDisc({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: CircleAvatar(
      radius: 44,
      backgroundColor: yellow,
      child: Icon(LucideIcons.check, size: 42, color: ink),
    ),
  );
}

/// One centred line of prose under a status icon.
class CenteredNote extends StatelessWidget {
  const CenteredNote(this.text, {super.key, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: muted ? inkFaint : inkMuted,
      fontSize: muted ? 14.5 : 15.5,
      height: 1.45,
      fontWeight: FontWeight.w500,
    ),
  );
}

/// "Don't have an account? Sign up" — a Wrap, not a Row, because at phone
/// width the two halves overflow a Row by ~86px.
class InlinePrompt extends StatelessWidget {
  const InlinePrompt({
    super.key,
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
        style: const TextStyle(
          color: inkMuted,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      TextLink(action, onTap: onTap),
    ],
  );
}
