import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';

/// Shared feedback for controls that must visibly react to a tap even though
/// no backend action exists for them yet -- keeps affordances honest instead
/// of silently doing nothing.
void showNotWiredYetSnackBar(BuildContext context, String action) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$action is not wired up yet.')));
}

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

/// The one feature/hero surface: [CefGradients.hero] on the card radius.
/// Summary panels, hero cards, profile heroes and invitation cards all paint
/// through this, so the product has exactly one gradient treatment.
class HeroSurface extends StatelessWidget {
  const HeroSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.cardPadding),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      gradient: CefGradients.hero,
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
    ),
    child: child,
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
  Widget build(BuildContext context) => HeroSurface(
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
        const SizedBox(height: Gap.md),
        Row(children: children),
      ],
    ),
  );
}

class SummaryMetric extends StatelessWidget {
  const SummaryMetric({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;

  /// Overrides the value colour for a semantic count (e.g. a red "Issue"
  /// tile) inside an otherwise all-white navy panel. Defaults to white.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
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
            color: (valueColor ?? Colors.white).withValues(alpha: .72),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// The one button. Primary is the yellow pill (one per screen); secondary is
/// the neutral outlined pill; destructive is the red outlined pill used for
/// sign out / remove / reject. All share one height, radius and label style.
class CefButton extends StatelessWidget {
  const CefButton(
    this.label, {
    super.key,
    required this.onTap,
    this.secondary = false,
    this.destructive = false,
    this.busy = false,
    this.busyLabel,
    this.icon,
  });
  final String label;
  final VoidCallback? onTap;
  final bool secondary, destructive, busy;

  /// Progress copy shown beside the spinner while [busy] (e.g. "Signing in…").
  final String? busyLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final outlined = secondary || destructive;
    final foreground = destructive
        ? c.attention
        : outlined
        ? c.textPrimary
        : CefColors.onAccent;
    return SizedBox(
      width: double.infinity,
      height: Sizes.buttonHeight,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: outlined ? c.card : CefColors.accent,
          foregroundColor: foreground,
          disabledBackgroundColor: outlined
              ? c.card
              : CefColors.accent.withValues(alpha: .5),
          disabledForegroundColor: foreground.withValues(alpha: .5),
          side: outlined
              ? BorderSide(
                  color: destructive
                      ? c.attention.withValues(alpha: .45)
                      : c.border,
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sizes.buttonRadius),
          ),
        ),
        child: busy
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  ),
                  if (busyLabel != null) ...[
                    const SizedBox(width: Gap.sm),
                    Flexible(
                      child: Text(
                        busyLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: Gap.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The one text input (forms, auth, settings). Geometry, border and focus
/// colour come from the theme's inputDecorationTheme. Pass a [controller]
/// for live forms, or an [initialValue] for a prefilled field that owns its
/// own state. [obscureText] adds the standard show/hide password toggle.
class CefField extends StatefulWidget {
  const CefField({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.obscureText = false,
  }) : assert(controller == null || initialValue == null);
  final String? label;
  final TextEditingController? controller;
  final String? initialValue, hint, errorText, helperText;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon, suffixIcon;
  final bool enabled, obscureText;

  @override
  State<CefField> createState() => _CefFieldState();
}

class _CefFieldState extends State<CefField> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final w = widget;
    final Widget? suffix = w.obscureText
        ? IconButton(
            onPressed: () => setState(() => _hidden = !_hidden),
            icon: Icon(
              _hidden ? LucideIcons.eye : LucideIcons.eyeOff,
              size: 20,
            ),
            tooltip: _hidden ? 'Show password' : 'Hide password',
          )
        : w.suffixIcon == null
        ? null
        : Icon(w.suffixIcon, size: 20);
    final hasError = w.errorText != null && w.errorText!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (w.label != null) ...[
            Text(w.label!, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: Gap.sm),
          ],
          TextFormField(
            controller: w.controller,
            initialValue: w.initialValue,
            keyboardType: w.keyboardType,
            maxLines: w.obscureText ? 1 : w.maxLines,
            onChanged: w.onChanged,
            enabled: w.enabled,
            obscureText: _hidden,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: w.enabled ? c.textPrimary : c.textSecondary,
            ),
            decoration: InputDecoration(
              hintText: w.hint,
              errorText: hasError ? w.errorText : null,
              helperText: w.helperText,
              helperMaxLines: 2,
              errorMaxLines: 2,
              fillColor: w.enabled ? c.card : c.subtle,
              prefixIcon: w.prefixIcon == null
                  ? null
                  : Icon(w.prefixIcon, size: 20),
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}

/// The one status treatment (SOT 7.2): a small pill, semantic-coloured
/// label on a light tint of the same colour. Neutral by default.
class StatusChip extends StatelessWidget {
  const StatusChip(
    this.label, {
    super.key,
    this.attention = false,
    this.success = false,
    this.warning = false,
  });
  final String label;
  final bool attention;

  /// Ongoing/active states render in the semantic success green per the
  /// locked V12 Orders spec (Ongoing green, Issue red, Delivered neutral).
  final bool success;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = attention
        ? c.attention
        : success
        ? c.success
        : warning
        ? c.warning
        : c.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// The one initials avatar used for people, customers and zones.
class CefAvatar extends StatelessWidget {
  const CefAvatar(this.name, {super.key, this.size = Sizes.avatar});
  final String name;
  final double size;

  static String initialsOf(String name) => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0])
      .join()
      .toUpperCase();

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: context.c.subtle, shape: BoxShape.circle),
    child: Text(
      initialsOf(name),
      style: TextStyle(
        color: CefColors.navy,
        fontSize: size * .34,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// The one selectable chip (business type, template category, filters).
/// Selected = CEFFLO Yellow fill with near-black label; unselected = white
/// with the standard hairline border. Lay out with Wrap(spacing: 8,
/// runSpacing: 8) or a horizontal list with 8px gaps.
class CefChoiceChip extends StatelessWidget {
  const CefChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? CefColors.accent : c.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? CefColors.accent : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: Sizes.chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? CefColors.onAccent : c.textPrimary,
              ),
            ),
          ),
        ),
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

/// The one search input: a real text field with the standard input
/// geometry and an optional filter action beside it.
class CefSearchField extends StatelessWidget {
  const CefSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onFilter,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.c.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(LucideIcons.search, size: 20),
      ),
    );
    if (onFilter == null) return field;
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: Gap.xs),
        IconAction(
          icon: LucideIcons.slidersHorizontal,
          tooltip: 'Filter',
          onTap: onFilter!,
        ),
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
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Sizes.cardRadius),
      ),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: Gap.gutter,
        right: Gap.gutter,
        top: Gap.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Gap.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Gap.md),
          CefSearchField(hint: hint, autofocus: true),
        ],
      ),
    ),
  );
}

/// Preference on/off toggle. Locked: the ON state is semantic green, never
/// the yellow the app's Material seed color would otherwise apply. A null
/// [onChanged] renders the disabled (unavailable) state.
class CefSwitch extends StatelessWidget {
  const CefSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.success : c.border,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: const WidgetStatePropertyAll(null),
    );
  }
}

/// The one list / settings row: optional leading (an [icon] or any widget
/// such as a [CefAvatar]), title, one-line subtitle, optional trailing
/// widget, and a chevron whenever the row navigates. Rows are separated by
/// a hairline divider.
class CefListRow extends StatelessWidget {
  const CefListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  }) : assert(icon == null || leading == null);

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Set false for rows whose tap selects in place (e.g. a radio choice)
  /// rather than navigating.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lead =
        leading ??
        (icon == null
            ? null
            : Icon(icon, size: Sizes.icon, color: c.iconColor));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.xs,
            vertical: Gap.sm,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              if (lead != null) ...[lead, const SizedBox(width: Gap.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: Gap.sm),
                trailing!,
              ],
              if (onTap != null && showChevron) ...[
                const SizedBox(width: Gap.sm),
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
      // Dim + blur the entire screen behind the card, not just a scrim --
      // this is what makes the popup read as a focused, modal moment
      // instead of a thin overlay on top of the still-legible page.
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(color: Colors.black.withValues(alpha: .45)),
        ),
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: switch (_stage) {
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
    CefColors.navy,
    CefColors.accent,
    CefColors.navy,
    CefColors.accent,
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
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
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
        decoration: BoxDecoration(
          color: context.c.success.withValues(alpha: .12),
          shape: BoxShape.circle,
        ),
        child: Icon(LucideIcons.check, color: context.c.success, size: 30),
      ),
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
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
        decoration: BoxDecoration(
          color: context.c.attention.withValues(alpha: .1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          LucideIcons.triangleAlert,
          color: context.c.attention,
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
          color: context.c.subtle,
          borderRadius: BorderRadius.circular(Sizes.inputRadius),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.wifiOff, size: 18, color: context.c.textSecondary),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Text(
                'Please check your internet connection and try again.',
                style: Theme.of(context).textTheme.bodySmall,
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
