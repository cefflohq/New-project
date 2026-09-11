import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';

/// Standalone outline icon at the approved 22px visual size inside a 44px
/// minimum interactive target. Same shape as Vendor Mobile's IconAction.
class IconAction extends StatelessWidget {
  const IconAction({super.key, required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: Sizes.tapTarget,
      height: Sizes.tapTarget,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, size: Sizes.icon, color: context.c.iconColor),
        ),
      ),
    ),
  );
}

class CefCard extends StatelessWidget {
  const CefCard({super.key, required this.child, this.onTap, this.selected = false, this.padded = true});
  final Widget child;
  final VoidCallback? onTap;

  /// Selected state uses a full CEFFLO Yellow outline -- never a filled card.
  final bool selected;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final body = Container(
      width: double.infinity,
      padding: padded ? const EdgeInsets.all(Gap.cardPadding) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
        border: Border.all(color: selected ? CefColors.accent : c.border, width: selected ? 1.6 : 1),
        boxShadow: cefCardShadow(),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
        onTap: onTap,
        child: body,
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.section, bottom: Gap.sm),
    child: Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        ?trailing,
      ],
    ),
  );
}

class CefButton extends StatelessWidget {
  const CefButton(this.label, {super.key, required this.onTap, this.secondary = false, this.busy = false});
  final String label;
  final VoidCallback? onTap;
  final bool secondary, busy;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: secondary ? c.card : CefColors.accent,
          foregroundColor: secondary ? c.textPrimary : CefColors.onAccent,
          disabledBackgroundColor: secondary ? c.card : CefColors.accent.withValues(alpha: .5),
          side: secondary ? BorderSide(color: c.border) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.buttonRadius)),
        ),
        child: busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: CefColors.onAccent))
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class CefField extends StatelessWidget {
  const CefField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: Gap.xs),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            style: TextStyle(fontSize: 15, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              filled: true,
              fillColor: c.card,
              contentPadding: const EdgeInsets.all(Gap.md),
              border: _border(c.border),
              enabledBorder: _border(c.border),
              focusedBorder: _border(CefColors.accent, width: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Sizes.inputRadius),
    borderSide: BorderSide(color: color, width: width),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = ChipTone.neutral});
  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = switch (tone) {
      ChipTone.neutral => (c.canvas, c.textSecondary),
      ChipTone.info => (c.info.withValues(alpha: .12), c.info),
      ChipTone.warning => (c.warning.withValues(alpha: .14), c.warning),
      ChipTone.success => (c.success.withValues(alpha: .12), c.success),
      ChipTone.attention => (c.attention.withValues(alpha: .12), c.attention),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

enum ChipTone { neutral, info, warning, success, attention }

/// Explicit, non-decorative states. Loading/empty/error are distinct so a
/// failure can never be mistaken for "no data". Same shape as Vendor
/// Mobile's StateBlock.
class StateBlock extends StatelessWidget {
  const StateBlock.loading({super.key}) : kind = StateKind.loading, message = null, onRetry = null;
  const StateBlock.empty(this.message, {super.key}) : kind = StateKind.empty, onRetry = null;
  const StateBlock.error(this.message, {super.key, this.onRetry}) : kind = StateKind.error;

  final StateKind kind;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (kind == StateKind.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final (icon, color) = switch (kind) {
      StateKind.error => (LucideIcons.triangleAlert, c.attention),
      _ => (LucideIcons.inbox, c.textSecondary),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(height: Gap.md),
          Text(message ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          if (onRetry != null) ...[
            const SizedBox(height: Gap.md),
            SizedBox(width: 160, child: CefButton('Try again', secondary: true, onTap: onRetry)),
          ],
        ],
      ),
    );
  }
}

enum StateKind { loading, empty, error }

/// Founder-locked safety component (docs/cefflo/sot/
/// 08_RIDER_FLUTTER_33_SCREEN_MASTER.md S3): every critical Rider transition
/// (Start Pickup, Start Delivery, Arrive, Complete Order, Next Stop) uses
/// SLIDE, never tap. Navy track (the SOT's "black card/background with
/// white text" direction re-expressed under D-33's Yellow/Navy palette),
/// CEFFLO Yellow circular knob, disabled/loading/failure states, and no
/// accidental-tap fallback -- the track itself has no onTap.
class CriticalSlideAction extends StatefulWidget {
  const CriticalSlideAction({
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
  State<CriticalSlideAction> createState() => _CriticalSlideActionState();
}

class _CriticalSlideActionState extends State<CriticalSlideAction> {
  double _dragX = 0;
  bool _firing = false; // duplicate-action protection while the callback is in flight

  bool get _active => widget.enabled && !widget.busy && !_firing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxDrag = trackWidth - Sizes.slideKnob - 8;
        final progress = maxDrag <= 0 ? 0.0 : (_dragX / maxDrag).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              enabled: _active,
              label: widget.label,
              hint: 'Slide to confirm',
              child: Container(
                height: Sizes.slideHeight,
                decoration: BoxDecoration(
                  color: _active ? CefColors.navy : CefColors.navy.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(Sizes.slideHeight / 2),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Center(
                      child: Opacity(
                        opacity: 1 - progress,
                        child: Text(
                          widget.label,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: _firing || widget.busy ? Duration.zero : const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      left: 4 + (maxDrag <= 0 ? 0 : _dragX),
                      top: 4,
                      child: GestureDetector(
                        onHorizontalDragUpdate: !_active
                            ? null
                            : (details) {
                                setState(() {
                                  _dragX = (_dragX + details.delta.dx).clamp(0.0, maxDrag < 0 ? 0.0 : maxDrag);
                                });
                              },
                        onHorizontalDragEnd: !_active
                            ? null
                            : (details) async {
                                if (maxDrag > 0 && _dragX >= maxDrag * 0.92) {
                                  setState(() {
                                    _dragX = maxDrag;
                                    _firing = true;
                                  });
                                  try {
                                    await widget.onConfirmed();
                                  } finally {
                                    if (mounted) setState(() { _firing = false; _dragX = 0; });
                                  }
                                } else {
                                  setState(() => _dragX = 0);
                                }
                              },
                        child: Container(
                          width: Sizes.slideKnob,
                          height: Sizes.slideKnob,
                          decoration: BoxDecoration(
                            color: _active ? CefColors.accent : CefColors.accent.withValues(alpha: .5),
                            shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
                          ),
                          child: (widget.busy || _firing)
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: CefColors.onAccent),
                                )
                              : const Icon(LucideIcons.chevronsRight, color: CefColors.onAccent),
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
                  Icon(LucideIcons.triangleAlert, size: 15, color: context.c.attention),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(widget.errorText!, style: TextStyle(fontSize: 12.5, color: context.c.attention)),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
