import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import 'brand.dart';

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

/// The approved yellow primary CTA.
///
/// The trailing arrow is **not** a blanket rule: each reference shows its own
/// button either with an arrow ("Create Account →", "Send Reset Link →",
/// "Update Password →", "Back to Sign In →", "Accept Invitation →",
/// "Continue →", "Next →", "Submit for Review →", "Go to Today →",
/// "Go to Home →", "View Run Details →", "View Orders →") or without it
/// ("Sign Up", "Sign In", "Save", "Done", "Submit", "Next" on D28,
/// "Submit Ticket"). Callers state which, per button.
class CeffloPrimaryButton extends StatelessWidget {
  const CeffloPrimaryButton(
    this.label, {
    super.key,
    required this.onTap,
    this.trailingArrow = false,
    this.busy = false,
    this.pill = true,
    this.height = Sizes.buttonHeight,
  });

  final String label;
  final VoidCallback? onTap;
  final bool trailingArrow;
  final bool busy;

  /// Pill (D02/D03/D12.x/D34-D40) vs the softer 16px radius the operational
  /// screens use (D28 Next, D29 Submit, D30 Done).
  final bool pill;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: Material(
      color: onTap == null && !busy
          ? CefColors.accent.withValues(alpha: 0.45)
          : CefColors.accent,
      borderRadius: BorderRadius.circular(
        pill ? Sizes.buttonRadius : Sizes.softButtonRadius,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          pill ? Sizes.buttonRadius : Sizes.softButtonRadius,
        ),
        onTap: busy ? null : onTap,
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: CefColors.onAccent,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CefColors.onAccent,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (trailingArrow) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 19,
                        color: CefColors.onAccent,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    ),
  );
}

/// White, bordered secondary action — D14.1 "View Submitted Details" and
/// D40-B "Back to Help & Support".
class CeffloSecondaryButton extends StatelessWidget {
  const CeffloSecondaryButton(
    this.label, {
    super.key,
    required this.onTap,
    this.trailingChevron = false,
    this.pill = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool trailingChevron;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final radius = BorderRadius.circular(
      pill ? Sizes.buttonRadius : Sizes.softButtonRadius,
    );
    return SizedBox(
      width: double.infinity,
      height: Sizes.buttonHeight,
      child: Material(
        color: c.card,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: c.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: Row(
              mainAxisAlignment: trailingChevron
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                if (trailingChevron) const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                if (trailingChevron)
                  Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: c.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Underlined text link — "Back to Sign In", "Decline", "Sign Up".
class CeffloTextLink extends StatelessWidget {
  const CeffloTextLink(
    this.label, {
    super.key,
    required this.onTap,
    this.color,
    this.fontSize = 15,
    this.weight = FontWeight.w700,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;
  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: fontSize,
          fontWeight: weight,
          color: color ?? context.c.textPrimary,
          decoration: TextDecoration.underline,
          decorationColor: color ?? context.c.textPrimary,
        ),
      ),
    ),
  );
}

/// Circular translucent back control on the navy header (D03–D10, D12.x).
class CeffloBackButton extends StatelessWidget {
  const CeffloBackButton({super.key, required this.onTap, this.onNavy = true});

  final VoidCallback onTap;
  final bool onNavy;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Back',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: Sizes.tapTarget,
        height: Sizes.tapTarget,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onNavy
              ? const Color(0xFF0B1B33).withValues(alpha: 0.55)
              : CefColors.tintNeutral,
        ),
        child: Icon(
          LucideIcons.chevronLeft,
          size: 22,
          color: onNavy ? CefColors.onNavy : CefColors.navy,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Header chrome
// ---------------------------------------------------------------------------

/// Navy bar with a back control, a centred title and the notifications bell
/// — the header on D20–D23, D28–D40C.
class CeffloScreenHeader extends StatelessWidget {
  const CeffloScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onBell,
    this.subtitle,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onBell;

  /// Optional second row under the title (D21's "#CF1003 · 12 orders · 3.2 km").
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) => NavyBackdrop(
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.md, 6, Gap.md, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: Sizes.tapTarget,
              child: Row(
                children: [
                  SizedBox(
                    width: Sizes.tapTarget,
                    child: onBack == null
                        ? null
                        : CeffloBackButton(onTap: onBack!),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: CefColors.onNavy,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Sizes.tapTarget,
                    child: onBell == null
                        ? null
                        : CeffloBellButton(onTap: onBell!),
                  ),
                ],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: subtitle!,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class CeffloBellButton extends StatelessWidget {
  const CeffloBellButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Notifications',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox(
        width: Sizes.tapTarget,
        height: Sizes.tapTarget,
        child: Icon(LucideIcons.bell, size: 23, color: CefColors.onNavy),
      ),
    ),
  );
}

/// The "Cefflo Driver" branded header used by the home-family screens
/// (D11, D14.1–14.3, D16, D18, D19): wordmark on the left, bell on the
/// right, optional back control, then free-form navy content below.
class CeffloBrandHeader extends StatelessWidget {
  const CeffloBrandHeader({
    super.key,
    this.onBack,
    this.onBell,
    this.centerWordmark = false,
    this.child,
  });

  final VoidCallback? onBack;
  final VoidCallback? onBell;
  final bool centerWordmark;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Gap.gutter, 6, Gap.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: Sizes.tapTarget,
            child: Row(
              children: [
                if (onBack != null) ...[
                  CeffloBackButton(onTap: onBack!),
                  const SizedBox(width: Gap.sm),
                ],
                if (centerWordmark) const Spacer(),
                const CeffloDriverWordmark(),
                const Spacer(),
                if (onBell != null) CeffloBellButton(onTap: onBell!),
              ],
            ),
          ),
          ?child,
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Auth layout
// ---------------------------------------------------------------------------

/// The shared D02–D12 auth geometry: navy gradient top with an optional back
/// control and step progress, a display heading + supporting line, and a
/// white surface **attached to the bottom edge of the screen** (never a
/// floating card) with rounded top corners.
class CeffloAuthScaffold extends StatelessWidget {
  const CeffloAuthScaffold({
    super.key,
    this.onBack,
    this.title,
    this.subtitle,
    this.step,
    this.headerTrailing,
    this.headerAction,
    required this.sheet,
    this.sheetPadding = const EdgeInsets.fromLTRB(
      Gap.gutter,
      Gap.xl,
      Gap.gutter,
      Gap.xl,
    ),
    this.scrollable = true,
    this.headerChild,
  });

  final VoidCallback? onBack;
  final String? title;
  final String? subtitle;
  final CeffloStepProgress? step;

  /// e.g. D12.1's avatar chip sitting to the right of the heading block.
  final Widget? headerTrailing;

  /// e.g. D09's "Maybe Later" text action in the top-right.
  final Widget? headerAction;

  /// Fully custom navy content, used when a screen's header is not the
  /// standard title/subtitle pair (D06, D08).
  final Widget? headerChild;

  final Widget sheet;
  final EdgeInsets sheetPadding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final header =
        headerChild ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (step != null) ...[step!, const SizedBox(height: Gap.lg)],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(title!, style: context.t.displayLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: Gap.sm),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: CefColors.onNavyMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (headerTrailing != null) ...[
                  const SizedBox(width: Gap.md),
                  headerTrailing!,
                ],
              ],
            ),
          ],
        );

    final sheetSurface = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.c.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Sizes.sheetRadius),
        ),
        boxShadow: cefSheetShadow(),
      ),
      padding: sheetPadding.copyWith(
        bottom: sheetPadding.bottom + MediaQuery.of(context).padding.bottom,
      ),
      child: sheet,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: NavyBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.gutter,
                  6,
                  Gap.gutter,
                  Gap.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: Sizes.tapTarget,
                      child: Row(
                        children: [
                          if (onBack != null) CeffloBackButton(onTap: onBack!),
                          const Spacer(),
                          ?headerAction,
                        ],
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                    header,
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: scrollable
                      ? SingleChildScrollView(
                          reverse: true,
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: sheetSurface,
                        )
                      : sheetSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navy header content followed by a white surface that fills the rest of
/// the screen and stays attached to the bottom edge. This is the layout the
/// signed-in navy screens share (D11, D14.1–14.3, D16, D17, D18, D19, D20,
/// D23, D28, D30, D32–D40C) — the same attached-surface rule as the auth
/// family, but sitting inside the app shell so the bottom navigation is
/// drawn by the shell, not by the screen.
class CeffloNavySheetScaffold extends StatelessWidget {
  const CeffloNavySheetScaffold({
    super.key,
    required this.header,
    required this.body,
    this.bodyPadding = const EdgeInsets.fromLTRB(
      Gap.gutter,
      Gap.section,
      Gap.gutter,
      Gap.section,
    ),
    this.scrollable = true,
    this.footer,
    this.sheetRadius = Sizes.sheetRadius,
  });

  /// Content drawn on the navy gradient (header bar, headings, hero rows).
  final Widget header;

  /// Content inside the white surface.
  final Widget body;
  final EdgeInsets bodyPadding;
  final bool scrollable;

  /// Pinned inside the white surface, below the scrolling body (slide
  /// actions, primary CTAs).
  final Widget? footer;
  final double sheetRadius;

  @override
  Widget build(BuildContext context) {
    final sheetChild = Padding(padding: bodyPadding, child: body);
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: cefHeaderGradient),
      child: Stack(
        children: [
          const ChevronWatermark(),
          Column(
            children: [
              header,
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.c.card,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(sheetRadius),
                    ),
                    boxShadow: cefSheetShadow(),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Expanded(
                        child: scrollable
                            ? SingleChildScrollView(child: sheetChild)
                            : sheetChild,
                      ),
                      if (footer != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Gap.gutter,
                            Gap.sm,
                            Gap.gutter,
                            Gap.lg,
                          ),
                          child: footer!,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Segmented step indicator — "Step 1 of 3" under a row of pill segments
/// (D04, D07, D10, D12, D12.1, D12.2).
class CeffloStepProgress extends StatelessWidget {
  const CeffloStepProgress({
    super.key,
    required this.current,
    required this.total,
    required this.segments,
    this.label,
  });

  /// 1-based index of the current step.
  final int current;

  /// Total steps, as printed in the caption line.
  final int total;

  /// Number of segment bars drawn. The references do not always draw one
  /// bar per step (D04 shows 4 bars for "Step 1 of 3"), so this is explicit.
  final int segments;

  final String? label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          for (var i = 0; i < segments; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Container(
              width: 34,
              height: 5,
              decoration: BoxDecoration(
                color: i < current
                    ? CefColors.accent
                    : CefColors.onNavy.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: Gap.sm),
      Text(
        label ?? 'Step $current of $total',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CefColors.onNavy.withValues(alpha: 0.85),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

/// Labelled input with the reference's leading-icon treatment: 52px tall,
/// 12px radius, hairline border, white fill, muted icon and hint.
class CeffloTextField extends StatelessWidget {
  const CeffloTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.readOnly = false,
    this.maxLines = 1,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final bool readOnly;
  final int maxLines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CeffloFieldLabel(label),
        const SizedBox(height: 6),
        Container(
          constraints: BoxConstraints(
            minHeight: maxLines > 1 ? 0 : Sizes.inputHeight,
          ),
          decoration: BoxDecoration(
            color: readOnly ? CefColors.tintNeutral : c.card,
            borderRadius: BorderRadius.circular(Sizes.inputRadius),
            border: Border.all(color: c.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
                  child: Icon(icon, size: 20, color: c.textSecondary),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscure,
                  readOnly: readOnly || onTap != null,
                  onTap: onTap,
                  maxLines: obscure ? 1 : maxLines,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: readOnly ? c.textSecondary : c.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: maxLines > 1 ? 14 : 15,
                    ),
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
              if (suffix != null) ...[const SizedBox(width: 8), suffix!],
            ],
          ),
        ),
      ],
    );
  }
}

class CeffloFieldLabel extends StatelessWidget {
  const CeffloFieldLabel(this.label, {super.key, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: context.c.textLabel,
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 4), trailing!],
    ],
  );
}

/// Password field with the eye / eye-off reveal toggle the references show.
class CeffloPasswordField extends StatefulWidget {
  const CeffloPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;

  @override
  State<CeffloPasswordField> createState() => _CeffloPasswordFieldState();
}

class _CeffloPasswordFieldState extends State<CeffloPasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => CeffloTextField(
    label: widget.label,
    controller: widget.controller,
    hint: widget.hint,
    icon: LucideIcons.lock,
    obscure: _hidden,
    suffix: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _hidden = !_hidden),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Icon(
          _hidden ? LucideIcons.eyeOff : LucideIcons.eye,
          size: 20,
          color: context.c.textSecondary,
        ),
      ),
    ),
  );
}

/// Phone input with the Malaysian flag + dial-code prefix shown in D04,
/// D12, D12.1 and D35.
class CeffloPhoneField extends StatelessWidget {
  const CeffloPhoneField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) => CeffloTextField(
    label: label,
    controller: controller,
    hint: hint,
    icon: LucideIcons.phone,
    keyboardType: TextInputType.phone,
  );
}

/// Select-style control with a trailing chevron (Vehicle Type in D12/D12.2/
/// D36, Category in D40-C).
class CeffloSelectField<T> extends StatelessWidget {
  const CeffloSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
    this.optionLabel,
  });

  final String label;
  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final IconData? icon;
  final String Function(T)? optionLabel;

  String _text(T v) => optionLabel?.call(v) ?? '$v';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CeffloFieldLabel(label),
        const SizedBox(height: 6),
        Container(
          height: Sizes.inputHeight,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(Sizes.inputRadius),
            border: Border.all(color: c.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: c.textSecondary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    icon: Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: c.textSecondary,
                    ),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                    items: [
                      for (final o in options)
                        DropdownMenuItem(value: o, child: Text(_text(o))),
                    ],
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Surfaces
// ---------------------------------------------------------------------------

class CeffloCard extends StatelessWidget {
  const CeffloCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Gap.cardPadding),
    this.color,
    this.border = true,
    this.shadow = true,
    this.radius = Sizes.cardRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final bool border;
  final bool shadow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final body = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: c.border) : null,
        boxShadow: shadow ? cefCardShadow() : null,
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: body,
      ),
    );
  }
}

/// Flat tinted block used for the inset notes in D04/D05/D06/D08/D10/D12.2/
/// D14.x/D17/D29/D30/D40-B.
class CeffloNote extends StatelessWidget {
  const CeffloNote({
    super.key,
    required this.icon,
    this.title,
    required this.body,
    this.tone = CeffloNoteTone.info,
  });

  final IconData icon;
  final String? title;
  final String body;
  final CeffloNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = switch (tone) {
      CeffloNoteTone.info => (CefColors.tintInfo, c.info),
      CeffloNoteTone.neutral => (CefColors.tintNeutral, c.textSecondary),
      CeffloNoteTone.warning => (CefColors.tintWarning, c.warning),
      CeffloNoteTone.success => (CefColors.tintSuccess, c.success),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Sizes.innerRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: context.t.titleSmall),
                  const SizedBox(height: 3),
                ],
                Text(body, style: context.t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum CeffloNoteTone { info, neutral, warning, success }

/// Icon + title + subtitle + chevron, on a tinted inset row. The repeated
/// "pick an option" pattern in D11, D16, D17, D40 and D40-A.
class CeffloOptionRow extends StatelessWidget {
  const CeffloOptionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconChild,
    this.dense = false,
  });

  final IconData icon;
  final Widget? iconChild;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Sizes.innerRadius),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: dense ? 10 : 13,
            horizontal: 12,
          ),
          child: Row(
            children: [
              iconChild ??
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Icon(icon, size: 21, color: CefColors.navy),
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.t.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: context.t.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 20, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon + title + supporting line with no chevron — the benefit lists in
/// D09, D10 and D18.
class CeffloFeatureRow extends StatelessWidget {
  const CeffloFeatureRow({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 22, color: CefColors.navy),
        ),
        const SizedBox(width: 13),
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
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    ),
  );
}

/// Pill status chip (Pending / Delivered / Completed / Verified / Uploaded /
/// On the way).
class CeffloStatusChip extends StatelessWidget {
  const CeffloStatusChip(
    this.label, {
    super.key,
    this.tone = ChipTone.neutral,
    this.icon,
  });

  final String label;
  final ChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = switch (tone) {
      ChipTone.neutral => (CefColors.tintNeutral, c.textSecondary),
      ChipTone.info => (const Color(0xFF1668E3), Colors.white),
      ChipTone.warning => (const Color(0xFFFDEBCB), const Color(0xFF9A6700)),
      ChipTone.success => (CefColors.tintSuccess, c.success),
      ChipTone.attention => (const Color(0xFFFCE9E7), c.attention),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

enum ChipTone { neutral, info, warning, success, attention }

/// Numbered navy circle used for stop indices (D21, D21.1, D32) and the
/// ordered step list in D06/D20.
class CeffloIndexBadge extends StatelessWidget {
  const CeffloIndexBadge(
    this.index, {
    super.key,
    this.tone = ChipTone.neutral,
    this.size = 30,
  });
  final int index;
  final ChipTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ChipTone.warning => (CefColors.accent, CefColors.onAccent),
      ChipTone.neutral => (CefColors.tintNeutral, context.c.textSecondary),
      _ => (CefColors.navy, Colors.white),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        '$index',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// White segmented tab control — D17 (Invite Link / QR Code), D21 (All /
/// Pending / Delivered), D21.1–21.2 (List / Map), D31, D33.
class CeffloSegmentedTabs extends StatelessWidget {
  const CeffloSegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CefColors.tintNeutral,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? c.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: i == index ? Border.all(color: c.border) : null,
                    boxShadow: i == index ? cefCardShadow() : null,
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13.5,
                      fontWeight: i == index
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: i == index ? c.textPrimary : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Settings/profile navigation row — D34 and D38.
class CeffloListTile extends StatelessWidget {
  const CeffloListTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final colour = danger ? c.attention : CefColors.navy;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 22, color: colour),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: danger ? c.attention : c.textPrimary,
                  ),
                ),
              ),
              if (value != null) ...[
                Text(value!, style: context.t.bodyMedium),
                const SizedBox(width: 8),
              ],
              if (!danger)
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

/// Uploaded/verified document row — D12.2 (with thumbnail + remove) and D37
/// (with expiry + Verified chip).
class CeffloDocumentRow extends StatelessWidget {
  const CeffloDocumentRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.statusLabel,
    this.statusTone = ChipTone.success,
    this.thumbnail,
    this.onRemove,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? statusLabel;
  final ChipTone statusTone;
  final Widget? thumbnail;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.innerRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CefColors.tintNeutral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: CefColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.t.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: context.t.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (statusLabel != null)
                    CeffloStatusChip(
                      statusLabel!,
                      tone: statusTone,
                      icon: LucideIcons.circleCheck,
                    ),
                  if (thumbnail != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 54,
                            height: 36,
                            child: thumbnail,
                          ),
                        ),
                        if (onRemove != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onRemove,
                            child: Icon(
                              LucideIcons.circleX,
                              size: 22,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (onTap != null && thumbnail == null && statusLabel != null)
                    const SizedBox.shrink(),
                ],
              ),
              if (onTap != null && thumbnail == null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A placeholder stand-in for an uploaded document photo. No fabricated
/// identity-document imagery is bundled with the app.
class DocumentThumbPlaceholder extends StatelessWidget {
  const DocumentThumbPlaceholder({super.key, required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    color: CefColors.tintNeutral,
    alignment: Alignment.center,
    child: Icon(icon, size: 18, color: context.c.textSecondary),
  );
}

// ---------------------------------------------------------------------------
// Bottom navigation
// ---------------------------------------------------------------------------

class CeffloBottomNav extends StatelessWidget {
  const CeffloBottomNav({super.key, required this.active, required this.onTap});

  final NavTab active;
  final ValueChanged<NavTab> onTap;

  static const _items = <(NavTab, IconData, String)>[
    (NavTab.home, LucideIcons.house, 'Home'),
    (NavTab.runs, LucideIcons.tag, 'Runs'),
    (NavTab.history, LucideIcons.archive, 'History'),
    (NavTab.profile, LucideIcons.user, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.chrome,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: Sizes.bottomNav,
          child: Row(
            children: [
              for (final (tab, icon, label) in _items)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(tab),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 23,
                          color: tab == active
                              ? CefColors.accent
                              : c.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11.5,
                            fontWeight: tab == active
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: tab == active
                                ? CefColors.navy
                                : c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 22,
                          height: 3,
                          decoration: BoxDecoration(
                            color: tab == active
                                ? CefColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
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
}

// ---------------------------------------------------------------------------
// Critical slide action
// ---------------------------------------------------------------------------

/// Navy track, CEFFLO Yellow circular knob overflowing the track vertically,
/// chevron glyph — D21.1/D21.2 "Slide to Confirm Route", D22 "Slide to
/// Arrive", D23 "Slide to Complete". Deliberately has no tap fallback: a
/// critical transition is never a single accidental tap away.
class CeffloSlideAction extends StatefulWidget {
  const CeffloSlideAction({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.enabled = true,
    this.busy = false,
    this.errorText,
  });

  final String label;
  final Future<void> Function() onConfirmed;
  final bool enabled;
  final bool busy;
  final String? errorText;

  @override
  State<CeffloSlideAction> createState() => _CeffloSlideActionState();
}

class _CeffloSlideActionState extends State<CeffloSlideAction> {
  double _dragX = 0;
  bool _firing = false;

  bool get _active => widget.enabled && !widget.busy && !_firing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final trackWidth = constraints.maxWidth;
      final maxDrag = math.max(0.0, trackWidth - Sizes.slideKnob - 4);
      final progress = maxDrag <= 0 ? 0.0 : (_dragX / maxDrag).clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            enabled: _active,
            label: widget.label,
            hint: 'Slide to confirm',
            child: SizedBox(
              height: Sizes.slideKnob,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Container(
                      height: Sizes.slideHeight,
                      decoration: BoxDecoration(
                        color: _active
                            ? CefColors.navy
                            : CefColors.navy.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(
                          Sizes.slideHeight / 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(left: Sizes.slideKnob),
                      child: Opacity(
                        opacity: 1 - progress,
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _firing || widget.busy
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    left: _dragX,
                    child: GestureDetector(
                      onHorizontalDragUpdate: !_active
                          ? null
                          : (d) => setState(() {
                              _dragX = (_dragX + d.delta.dx).clamp(
                                0.0,
                                maxDrag,
                              );
                            }),
                      onHorizontalDragEnd: !_active
                          ? null
                          : (_) async {
                              if (maxDrag > 0 && _dragX >= maxDrag * 0.9) {
                                setState(() {
                                  _dragX = maxDrag;
                                  _firing = true;
                                });
                                try {
                                  await widget.onConfirmed();
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _firing = false;
                                      _dragX = 0;
                                    });
                                  }
                                }
                              } else {
                                setState(() => _dragX = 0);
                              }
                            },
                      child: Container(
                        width: Sizes.slideKnob,
                        height: Sizes.slideKnob,
                        decoration: BoxDecoration(
                          color: _active
                              ? CefColors.accent
                              : CefColors.accent.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2E12213E),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: (widget.busy || _firing)
                            ? const Padding(
                                padding: EdgeInsets.all(22),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: CefColors.onAccent,
                                ),
                              )
                            : const Icon(
                                LucideIcons.chevronRight,
                                size: 26,
                                color: CefColors.onAccent,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: Gap.sm),
            Row(
              children: [
                Icon(
                  LucideIcons.triangleAlert,
                  size: 15,
                  color: context.c.attention,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.c.attention,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Processing identity + modals
// ---------------------------------------------------------------------------

/// The four-dot processing motif (alternating blue / CEFFLO Yellow) shown in
/// the Contact Support "Submitting…" modal. A real sequential wave — dot 1 →
/// 2 → 3 → 4 → repeat — never a CircularProgressIndicator.
class FourDotLoader extends StatefulWidget {
  const FourDotLoader({super.key, this.dotSize = 16, this.spacing = 12});
  final double dotSize;
  final double spacing;

  @override
  State<FourDotLoader> createState() => _FourDotLoaderState();
}

class _FourDotLoaderState extends State<FourDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  static const _colors = [
    Color(0xFF1668E3),
    CefColors.accent,
    Color(0xFF1668E3),
    CefColors.accent,
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) SizedBox(width: widget.spacing),
          Builder(
            builder: (_) {
              // One quarter-cycle lead per dot produces the wave.
              final phase = (_c.value - i * 0.18) % 1.0;
              final lift = phase < 0.45
                  ? math.sin(phase / 0.45 * math.pi)
                  : 0.0;
              return Transform.translate(
                offset: Offset(0, -lift * 5),
                child: Opacity(
                  opacity: 0.45 + 0.55 * lift,
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    ),
  );
}

/// Shared modal geometry so a processing modal and its success modal keep
/// the same size, position and corner radius as they swap.
class CeffloModal extends StatelessWidget {
  const CeffloModal({super.key, required this.child, this.width = 300});
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          color: context.c.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330A1B33),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
      ),
    ),
  );
}

/// Big green success tick — D08, D12.3, D14.2, D18, D30 and the support
/// "Request submitted" modal.
class CeffloSuccessTick extends StatelessWidget {
  const CeffloSuccessTick({super.key, this.size = 76, this.glow = false});
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final tick = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF22B865),
        shape: BoxShape.circle,
      ),
      child: Icon(LucideIcons.check, size: size * 0.5, color: Colors.white),
    );
    if (!glow) return tick;
    return Container(
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF22B865).withValues(alpha: 0.16),
      ),
      child: tick,
    );
  }
}

/// Dimmed + blurred backdrop host for the processing/success modal pair.
Future<T?> showCeffloModal<T>(BuildContext context, Widget modal) =>
    showDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x99101C33),
      builder: (_) => modal,
    );

/// The processing half of the reference's two-step submit motif: four dots
/// over a title and a supporting line, on the shared [CeffloModal] geometry.
class CeffloSubmittingModal extends StatelessWidget {
  const CeffloSubmittingModal({
    super.key,
    this.title = 'Submitting…',
    this.body = 'Please wait a moment.',
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => CeffloModal(
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: FourDotLoader(),
        ),
        const SizedBox(height: Gap.lg),
        Text(title, style: context.t.displaySmall?.copyWith(fontSize: 20)),
        const SizedBox(height: Gap.sm),
        Text(body, textAlign: TextAlign.center, style: context.t.bodyMedium),
      ],
    ),
  );
}

/// The success half of the same motif — identical geometry, so the pair
/// swaps in place rather than resizing.
class CeffloSubmittedModal extends StatelessWidget {
  const CeffloSubmittedModal({
    super.key,
    required this.title,
    required this.body,
    required this.onDone,
    this.doneLabel = 'Done',
  });

  final String title;
  final String body;
  final VoidCallback onDone;
  final String doneLabel;

  @override
  Widget build(BuildContext context) => CeffloModal(
    child: Column(
      children: [
        const CeffloSuccessTick(size: 62),
        const SizedBox(height: Gap.lg),
        Text(title, style: context.t.displaySmall?.copyWith(fontSize: 20)),
        const SizedBox(height: Gap.sm),
        Text(body, textAlign: TextAlign.center, style: context.t.bodyMedium),
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton(doneLabel, onTap: onDone, height: 52, pill: false),
      ],
    ),
  );
}

/// The reference's two-step submit motif, in one call: a dimmed/blurred
/// backdrop behind a "Submitting…" modal that swaps in place for a success
/// modal with a Done button. Every submit-type action in the reference set
/// (ticket submit, confirm delivery, report issue, document submit-for-review)
/// uses this same pair, so it is written once here rather than per screen.
///
/// Prototype only: the delay stands in for a network round trip. Nothing is
/// sent anywhere.
Future<void> showCeffloSubmitFlow(
  BuildContext context, {
  String submittingTitle = 'Submitting…',
  String submittingBody = 'Please wait a moment.',
  required String successTitle,
  required String successBody,
  String doneLabel = 'Done',
  Duration delay = const Duration(milliseconds: 1300),
  VoidCallback? onDone,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showCeffloModal<void>(
      context,
      CeffloSubmittingModal(title: submittingTitle, body: submittingBody),
    ),
  );
  await Future<void>.delayed(delay);
  if (!navigator.mounted) return;
  navigator.pop();
  await showCeffloModal<void>(
    navigator.context,
    Builder(
      builder: (modalContext) => CeffloSubmittedModal(
        title: successTitle,
        body: successBody,
        doneLabel: doneLabel,
        onDone: () => Navigator.of(modalContext).pop(),
      ),
    ),
  );
  onDone?.call();
}

/// Reference bottom sheet geometry: white, 24px top radius, grabber, and
/// content padded to the screen gutter (D39 Select Language, D40-A Contact
/// Support).
Future<T?> showCeffloSheet<T>(BuildContext context, {required Widget child}) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66101C33),
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: CefColors.light.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(top: false, child: child),
      ),
    );

class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.c.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class StateBlock extends StatelessWidget {
  const StateBlock.loading({super.key})
    : kind = StateKind.loading,
      message = null,
      onRetry = null;
  const StateBlock.empty(this.message, {super.key})
    : kind = StateKind.empty,
      onRetry = null;
  const StateBlock.error(this.message, {super.key, this.onRetry})
    : kind = StateKind.error;

  final StateKind kind;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (kind == StateKind.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: FourDotLoader()),
      );
    }
    final (icon, color) = switch (kind) {
      StateKind.error => (LucideIcons.triangleAlert, c.attention),
      _ => (LucideIcons.package, c.textSecondary),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: Gap.gutter),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: Gap.md),
          Text(
            message ?? '',
            textAlign: TextAlign.center,
            style: context.t.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: Gap.lg),
            SizedBox(
              width: 180,
              child: CeffloSecondaryButton('Try again', onTap: onRetry),
            ),
          ],
        ],
      ),
    );
  }
}

enum StateKind { loading, empty, error }
