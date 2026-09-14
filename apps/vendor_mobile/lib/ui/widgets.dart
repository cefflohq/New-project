import 'dart:async';
import 'dart:ui';

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
    this.showDot = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// Small red unread indicator anchored to the icon's top-right corner.
  final bool showDot;

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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: Sizes.icon, color: context.c.iconColor),
              if (showDot)
                Positioned(
                  top: 11,
                  right: 11,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.c.attention,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.c.chrome, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
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

  /// Selected state uses a full CEFFLO Yellow outline — never a filled card.
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
          color: selected ? CefColors.accent : c.border,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: cefCardShadow(Theme.of(context).brightness),
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

/// Sub-section header within a page (e.g. "Items (3)", "Contact"). Deliberately
/// one size step below the page-level titleLarge H1 so hierarchy stays
/// readable: page title > section heading > card/row title > body.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.section, bottom: Gap.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
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

/// A compact icon + value + label stat, bordered, meant to sit three-across
/// in a Row (e.g. distance/stops/orders, or zones/active orders/coverage).
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
        border: Border.all(color: c.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c.info),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

/// A row of exactly three [MetricTile]s with the standard gutter between.
class MetricTileRow extends StatelessWidget {
  const MetricTileRow({super.key, required this.tiles});
  final List<MetricTile> tiles;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, tile) in tiles.indexed) ...[
        if (index > 0) const SizedBox(width: Gap.sm),
        Expanded(child: tile),
      ],
    ],
  );
}

class NavySummaryPanel extends StatelessWidget {
  const NavySummaryPanel({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF102344), Color(0xFF1B3668), Color(0xFF27427E)],
      ),
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(children: children),
      ],
    ),
  );
}

class SummaryMetric extends StatelessWidget {
  const SummaryMetric({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .72),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
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
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: secondary ? c.card : CefColors.accent,
          foregroundColor: secondary ? c.textPrimary : CefColors.onAccent,
          disabledBackgroundColor: secondary
              ? c.card
              : CefColors.accent.withValues(alpha: .5),
          side: secondary ? BorderSide(color: c.border) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sizes.buttonRadius),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CefColors.onAccent,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// A page-level "add" action. Always passed to [PageBody.floatingAction] so
/// it stays pinned at a fixed corner above the bottom navigation instead of
/// scrolling with the list content.
class YellowFab extends StatelessWidget {
  const YellowFab({super.key, required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: 52,
      height: 52,
      child: Material(
        color: CefColors.accent,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Icon(
            LucideIcons.plus,
            size: 26,
            color: CefColors.onAccent,
          ),
        ),
      ),
    ),
  );
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
              focusedBorder: _border(CefColors.accent, width: 1.6),
              errorBorder: _border(c.attention),
              focusedErrorBorder: _border(c.attention, width: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sizes.inputRadius),
        borderSide: BorderSide(color: color, width: width),
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip(
    this.label, {
    super.key,
    this.attention = false,
    this.success = false,
  });
  final String label;
  final bool attention;

  /// Ongoing/active states render in the semantic success green per the
  /// locked V12 Orders spec (Ongoing green, Issue red, Delivered neutral).
  final bool success;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: attention
            ? c.attention
            : success
            ? c.success
            : c.textSecondary,
      ),
    );
  }
}

/// Underlined, evenly stretched tabs used by Orders/Zones/Riders. No pill
/// cards: the selected state is a blue underline per the locked mobile spec.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: labels.map((l) {
          final sel = l == active;
          return Expanded(
            child: InkWell(
              onTap: () => onChange(l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 42,
                    child: Center(
                      child: Text(
                        l,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                          color: sel ? c.textPrimary : c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: sel ? c.info : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SearchBarField extends StatelessWidget {
  const SearchBarField({super.key, required this.hint, this.onFilter});

  final String hint;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(Sizes.inputRadius),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 22, color: c.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onFilter != null) ...[
          const SizedBox(width: 6),
          IconAction(
            icon: LucideIcons.slidersHorizontal,
            tooltip: 'Filter',
            onTap: onFilter!,
          ),
        ],
      ],
    );
  }
}

/// Locked list-screen header pattern: the title bar carries a compact search
/// icon rather than an inline full-width field. This opens that search as a
/// focused sheet instead of permanently occupying body space.
Future<void> showSearchSheet(BuildContext context, {required String hint}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: Gap.gutter,
        right: Gap.gutter,
        top: Gap.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + Gap.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Gap.md),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(LucideIcons.search, size: 22),
              filled: true,
              fillColor: context.c.canvas,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Sizes.inputRadius),
                borderSide: BorderSide(color: context.c.border),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Preference on/off toggle. Locked: the ON state is semantic green, never
/// the yellow the app's Material seed color would otherwise apply.
class CefSwitch extends StatelessWidget {
  const CefSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Switch(
    value: value,
    onChanged: onChanged,
    activeThumbColor: Colors.white,
    activeTrackColor: context.c.success,
  );
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: icon == null
                    ? const SizedBox(width: Sizes.icon)
                    : Icon(icon, size: Sizes.icon, color: c.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: c.textSecondary,
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class FlatListRow extends StatelessWidget {
  const FlatListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: c.textSecondary,
                ),
              ],
            ],
          ),
        ),
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

/// Locked global async action feedback: Tap -> Processing -> Success/Error
/// as one persistent sheet over a blurred, dimmed, non-interactive backdrop.
///
/// [action] is demo-only here: it runs against local/static prototype state,
/// never a real backend call, per the current UI-only scope. Returns whether
/// the sheet ended on Success.
Future<bool> runAsyncFeedback(
  BuildContext context, {
  required Future<void> Function() action,
  required String processingTitle,
  required String processingSubtitle,
  required String successTitle,
  required String successSubtitle,
  Widget? successDetail,
  String doneLabel = 'Done',
}) {
  final completer = Completer<bool>();
  showGeneralDialog<void>(
    context: context,
    barrierLabel: processingTitle,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, _, _) => _AsyncFeedbackOverlay(
      action: action,
      processingTitle: processingTitle,
      processingSubtitle: processingSubtitle,
      successTitle: successTitle,
      successSubtitle: successSubtitle,
      successDetail: successDetail,
      doneLabel: doneLabel,
      onSettled: (success) {
        if (!completer.isCompleted) completer.complete(success);
      },
    ),
  );
  return completer.future;
}

enum _FeedbackStage { processing, success, error }

class _AsyncFeedbackOverlay extends StatefulWidget {
  const _AsyncFeedbackOverlay({
    required this.action,
    required this.processingTitle,
    required this.processingSubtitle,
    required this.successTitle,
    required this.successSubtitle,
    required this.successDetail,
    required this.doneLabel,
    required this.onSettled,
  });

  final Future<void> Function() action;
  final String processingTitle;
  final String processingSubtitle;
  final String successTitle;
  final String successSubtitle;
  final Widget? successDetail;
  final String doneLabel;
  final ValueChanged<bool> onSettled;

  @override
  State<_AsyncFeedbackOverlay> createState() => _AsyncFeedbackOverlayState();
}

class _AsyncFeedbackOverlayState extends State<_AsyncFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();
  _FeedbackStage _stage = _FeedbackStage.processing;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _stage = _FeedbackStage.processing);
    try {
      // Keeps the wave animation visible for a beat even on instant demo
      // actions, so the state change never feels like a flicker.
      await Future.wait([
        widget.action(),
        Future.delayed(const Duration(milliseconds: 900)),
      ]);
      if (mounted) setState(() => _stage = _FeedbackStage.success);
    } catch (_) {
      if (mounted) setState(() => _stage = _FeedbackStage.error);
    }
  }

  void _finish(bool success) {
    widget.onSettled(success);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(color: Colors.black.withValues(alpha: .28)),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E6EE),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  switch (_stage) {
                    _FeedbackStage.processing => _ProcessingBody(
                      dots: _dots,
                      title: widget.processingTitle,
                      subtitle: widget.processingSubtitle,
                    ),
                    _FeedbackStage.success => _SuccessBody(
                      title: widget.successTitle,
                      subtitle: widget.successSubtitle,
                      detail: widget.successDetail,
                      doneLabel: widget.doneLabel,
                      onDone: () => _finish(true),
                    ),
                    _FeedbackStage.error => _ErrorBody(
                      onCancel: () => _finish(false),
                      onRetry: _run,
                    ),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ProcessingBody extends StatelessWidget {
  const _ProcessingBody({
    required this.dots,
    required this.title,
    required this.subtitle,
  });
  final Animation<double> dots;
  final String title;
  final String subtitle;

  static const _dotColors = [
    Color(0xFF12213E),
    Color(0xFFFEC819),
    Color(0xFF12213E),
    Color(0xFFFEC819),
  ];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 22,
        child: AnimatedBuilder(
          animation: dots,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final wave = Curves.easeInOut.transform(
                (((dots.value - i * 0.16) % 1) + 1) % 1,
              );
              final scale =
                  0.55 + 0.45 * (wave < 0.5 ? wave * 2 : (1 - wave) * 2);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Opacity(
                  opacity: 0.45 + 0.55 * scale,
                  child: Transform.scale(
                    scale: 0.7 + 0.3 * scale,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _dotColors[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      const SizedBox(height: 22),
      Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 14),
      Text(
        'Please keep this app open.\nThis may take a few moments.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: const Color(0xFF9AA1B2)),
      ),
    ],
  );
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.doneLabel,
    required this.onDone,
  });
  final String title;
  final String subtitle;
  final Widget? detail;
  final String doneLabel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Color(0xFFE7F0FE),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.check,
          color: Color(0xFF1769D2),
          size: 30,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      if (detail != null) ...[const SizedBox(height: 16), detail!],
      const SizedBox(height: 22),
      CefButton(doneLabel, onTap: onDone),
    ],
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onCancel, required this.onRetry});
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Color(0xFFE7F0FE),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.triangleAlert,
          color: Color(0xFF1769D2),
          size: 28,
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Something went wrong',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Text(
        'We couldn\'t complete this action right now.\nPlease try again.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F8),
          borderRadius: BorderRadius.circular(Sizes.inputRadius),
        ),
        child: Row(
          children: const [
            Icon(LucideIcons.wifiOff, size: 18, color: Color(0xFF666C80)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Please check your internet connection and try again.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF666C80)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: CefButton('Cancel', secondary: true, onTap: onCancel),
          ),
          const SizedBox(width: 12),
          Expanded(child: CefButton('Try Again', onTap: onRetry)),
        ],
      ),
    ],
  );
}
