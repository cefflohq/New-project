import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';

/// Standalone outline icon at the approved 22px visual size inside a 44px
/// minimum interactive target. No icon tile, badge or decorative background.
class IconAction extends StatelessWidget {
  const IconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
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
  const CefCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padded = true,
  });
  final Widget child;
  final VoidCallback? onTap;

  /// Selected state uses a full Signal Lime outline — never a lime fill.
  final bool selected;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: padded ? const EdgeInsets.all(Gap.cardPadding) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
        border: Border.all(
          color: selected ? CefColors.lime : c.border,
          width: selected ? 1.6 : 1,
        ),
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

class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.selected = false,
    this.onTap,
  });
  final String label, value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CefCard(
    selected: selected,
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class CefButton extends StatelessWidget {
  const CefButton(
    this.label, {
    super.key,
    required this.onTap,
    this.secondary = false,
    this.busy = false,
  });
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
          backgroundColor: secondary ? c.card : CefColors.lime,
          foregroundColor: secondary ? c.textPrimary : const Color(0xFF181818),
          disabledBackgroundColor: secondary ? c.card : CefColors.lime.withValues(alpha: .5),
          side: secondary ? BorderSide(color: c.border) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF181818)),
              )
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
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String? hint, errorText;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;

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
            maxLines: maxLines,
            onChanged: onChanged,
            style: TextStyle(fontSize: 15, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              isDense: true,
              filled: true,
              fillColor: c.card,
              contentPadding: const EdgeInsets.all(Gap.md),
              border: _border(c.border),
              enabledBorder: _border(c.border),
              focusedBorder: _border(CefColors.lime, width: 1.6),
              errorBorder: _border(c.attention),
              focusedErrorBorder: _border(c.attention, width: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.attention = false});
  final String label;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: attention ? c.attention : c.textSecondary,
        ),
      ),
    );
  }
}

/// Segmented control used for Orders/Zones/Riders tabs — outlined container,
/// lime outline on the active segment.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.active,
    required this.onChange,
  });
  final List<String> labels;
  final String active;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: labels.map((l) {
          final sel = l == active;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onChange(l),
                child: Container(
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: sel ? CefColors.lime : Colors.transparent,
                      width: 1.6,
                    ),
                  ),
                  child: Text(
                    l,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                      color: sel ? c.textPrimary : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CefListRow extends StatelessWidget {
  const CefListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CefCard(
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: Sizes.icon, color: c.iconColor),
            const SizedBox(width: Gap.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(LucideIcons.chevronRight, size: 18, color: c.textSecondary),
        ],
      ),
    );
  }
}

/// Explicit, non-decorative states. Loading/empty/error are distinct so a
/// failure can never be mistaken for "no data".
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
  const StateBlock.blocked(this.message, {super.key})
    : kind = StateKind.blocked,
      onRetry = null;

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
      StateKind.blocked => (LucideIcons.lock, c.textSecondary),
      _ => (LucideIcons.inbox, c.textSecondary),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(height: Gap.md),
          Text(
            message ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: Gap.md),
            SizedBox(
              width: 160,
              child: CefButton('Try again', secondary: true, onTap: onRetry),
            ),
          ],
        ],
      ),
    );
  }
}

enum StateKind { loading, empty, error, blocked }
