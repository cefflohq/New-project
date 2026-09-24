import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../data/models.dart';

/// How far above the screen bottom floating toasts sit: the shell provides
/// the bottom navigation height (plus safe area) where the nav is shown.
class ToastInset extends InheritedWidget {
  const ToastInset({super.key, required this.bottom, required super.child});
  final double bottom;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToastInset>()?.bottom ?? 0;

  @override
  bool updateShouldNotify(ToastInset old) => old.bottom != bottom;
}

/// The one toast: a white rounded card floating above the bottom nav with a
/// status mark (navy check, or red alert when [error]), the message, and an
/// optional action such as Undo. Every confirmation and error in the app
/// uses it.
void showCefToast(
  BuildContext context,
  String message, {
  bool error = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final c = context.c;
  final inset = ToastInset.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(Gap.gutter, 0, Gap.gutter, inset + Gap.md),
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: error ? c.attention : CefColors.navy,
                shape: BoxShape.circle,
              ),
              child: Icon(
                error ? LucideIcons.x : LucideIcons.check,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: c.textPrimary),
              ),
            ),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

/// Shared feedback for controls that must visibly react to a tap even though
/// no backend action exists for them yet -- keeps affordances honest instead
/// of silently doing nothing.
void showNotWiredYetSnackBar(BuildContext context, String action) =>
    showCefToast(context, '$action is not wired up yet.', error: true);

/// Standalone outline icon at the approved 22px visual size inside a 44px
/// minimum interactive target. No icon tile, badge or decorative background.
class IconAction extends StatelessWidget {
  const IconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showDot = false,
    this.color,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// Icon colour; defaults to the theme icon colour. The gradient header
  /// passes white.
  final Color? color;

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
              Icon(icon, size: Sizes.icon, color: color ?? context.c.iconColor),
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
    this.padding = const EdgeInsets.all(Gap.cardPadding),
  });
  final Widget child;
  final VoidCallback? onTap;

  /// Selected state uses a full CEFFLO Yellow outline — never a filled card.
  final bool selected;
  final bool padded;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: padded ? padding : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
        border: Border.all(
          color: selected ? CefColors.accent : c.border,
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

/// The one section heading. Plain ("Recent Delivery") or, for form
/// sections, with a CEFFLO Blue [icon] and a supporting [subtitle]
/// ("Customer / Select an existing customer or add a new one.").
class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    super.key,
    this.trailing,
    this.icon,
    this.subtitle,
  });
  final String title;
  final Widget? trailing;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      // Sections separate by space, not rules: a form section (with an
      // icon) opens with a wider gap than an in-page list heading.
      padding: EdgeInsets.only(
        top: icon == null ? Gap.lg : Gap.xxl,
        bottom: Gap.sm,
      ),
      child: Row(
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: Sizes.icon, color: context.c.iconColor),
            ),
            const SizedBox(width: Gap.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: text.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The one brand backdrop: [CefGradients.brand]. The shell's chrome, Splash
/// and every [HeroSurface] paint through this, so the gradient is identical
/// everywhere.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child, this.borderRadius});
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: CefGradients.brand,
      borderRadius: borderRadius,
    ),
    child: child,
  );
}

/// The one in-body hero surface: the [BrandBackdrop] on the card radius.
/// Used for onboarding heroes and promotional/help panels; content on it is
/// white.
class HeroSurface extends StatelessWidget {
  const HeroSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.cardPadding),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: BrandBackdrop(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// One figure in a [KpiStrip].
class KpiItem {
  const KpiItem(this.value, this.label, {this.color, this.icon});
  final String value;
  final String label;

  /// Semantic colour for the value (and label) -- e.g. success for Ready,
  /// attention for Issue. Defaults to the primary text colour.
  final Color? color;

  /// Optional navy outline icon above the value (detail stat rows).
  final IconData? icon;
}

/// The one KPI / stat row: equal columns of value + label separated by
/// hairline dividers, drawn directly on the white surface (Today overview,
/// zone activity, rider stats, dispatch totals).
class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key, required this.items});
  final List<KpiItem> items;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) VerticalDivider(width: 1, thickness: 1, color: c.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.xs,
                  vertical: Gap.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: Sizes.icon, color: c.iconColor),
                      const SizedBox(height: Gap.xs),
                    ],
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.value,
                        maxLines: 1,
                        style:
                            (item.icon == null
                                    ? text.displaySmall
                                    : text.titleMedium)
                                ?.copyWith(color: item.color),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Labels scale down rather than truncate in narrow
                    // columns ("Total Orders" at 360 wide).
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                          color: item.color == c.attention ? c.attention : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The one button. Primary is the yellow pill (one per screen); secondary is
/// the neutral outlined pill; destructive is the red outlined pill used for
/// sign out / remove / reject. All share one height, radius and label style.
/// [compact] is the inline variant (40 tall, as wide as its label) for an
/// in-row action such as "Edit zone"; a compact secondary is CEFFLO Blue.
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
    this.compact = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool secondary, destructive, busy, compact;

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
        ? (compact ? CefColors.brand : c.textPrimary)
        : CefColors.onAccent;
    return SizedBox(
      width: compact ? null : double.infinity,
      height: compact ? 40 : Sizes.buttonHeight,
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
                      : compact
                      ? CefColors.brand
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
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(color: foreground),
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
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(color: foreground),
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
    this.maxLength,
  }) : assert(controller == null || initialValue == null);
  final String? label;

  /// Caps the input and shows the live "n/max" counter under the field.
  final int? maxLength;
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
            maxLength: w.maxLength,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: w.enabled ? c.textPrimary : c.textSecondary),
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

/// The one inline text link (e.g. a SectionHeading's "View all"): CEFFLO
/// Blue label with an optional leading icon and trailing chevron, padded to
/// a comfortable tap area.
class CefLink extends StatelessWidget {
  const CefLink(
    this.label, {
    super.key,
    required this.onTap,
    this.icon,
    this.chevron = false,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool chevron;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(Gap.sm),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sizes.tapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: CefColors.brand),
              const SizedBox(width: Gap.xs),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: CefColors.brand),
            ),
            if (chevron) ...[
              const SizedBox(width: 2),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: CefColors.brand,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// The one status pill: a rounded pill with the label on a light fill.
/// Neutral grey by default; success / attention / warning / info tint it
/// semantically where the state needs to stand out.
class StatusChip extends StatelessWidget {
  const StatusChip(
    this.label, {
    super.key,
    this.attention = false,
    this.success = false,
    this.warning = false,
    this.info = false,
  });
  final String label;
  final bool attention;
  final bool success;
  final bool warning;

  /// CEFFLO Blue tint: in-progress states ("On the way").
  final bool info;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final semantic = attention
        ? c.attention
        : success
        ? c.success
        : warning
        ? c.warning
        : info
        ? CefColors.brand
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 5),
      decoration: BoxDecoration(
        color: semantic?.withValues(alpha: .12) ?? c.subtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(height: 1.3, color: semantic ?? c.textSecondary),
      ),
    );
  }
}

/// The one delivery-status pill, so an order reads the same colour on every
/// screen: Ready / Delivered green, in-progress blue, awaiting approval
/// amber, Issue red, Cancelled neutral.
class DeliveryStatusChip extends StatelessWidget {
  const DeliveryStatusChip(this.status, {super.key});
  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    DeliveryStatus.readyForPickup ||
    DeliveryStatus.delivered => StatusChip(status.label, success: true),
    DeliveryStatus.pickedUp ||
    DeliveryStatus.outForDelivery ||
    DeliveryStatus.arrived => StatusChip(status.label, info: true),
    DeliveryStatus.created => StatusChip(status.label, warning: true),
    DeliveryStatus.issue => StatusChip(status.label, attention: true),
    DeliveryStatus.cancelled => StatusChip(status.label),
  };
}

/// The one initials avatar. Light (soft fill, navy initials) by default;
/// [filled] gives the navy disc with white initials used for people lists.
class CefAvatar extends StatelessWidget {
  const CefAvatar(
    this.name, {
    super.key,
    this.size = Sizes.avatar,
    this.filled = false,
  });
  final String name;
  final double size;
  final bool filled;

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
    decoration: BoxDecoration(
      color: filled ? CefColors.navy : context.c.subtle,
      shape: BoxShape.circle,
    ),
    child: Text(
      initialsOf(name),
      style: TextStyle(
        color: filled ? Colors.white : CefColors.navy,
        fontSize: size * .36,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// The one icon treatment (D-48): a 24px navy outline icon, bare -- no
/// container -- centred in a fixed 44px slot so rows, detail rows, settings
/// and actions all line up. [circle] draws the round 1px outline used only
/// by the Call and WhatsApp contact actions. Only bottom navigation icons
/// are coloured; [color] is for status indicators alone (e.g. Need
/// Attention in red).
class IconTile extends StatelessWidget {
  const IconTile(
    IconData this.icon, {
    super.key,
    this.color,
    this.onTap,
    this.circle = false,
  }) : glyph = null;

  /// A composed outline mark (e.g. WhatsApp) in place of an icon.
  const IconTile.glyph(
    Widget this.glyph, {
    super.key,
    this.onTap,
    this.circle = false,
  }) : icon = null,
       color = null;

  final IconData? icon;
  final Widget? glyph;
  final Color? color;
  final bool circle;

  /// Makes the slot itself the tap target (actions).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: circle ? c.card : Colors.transparent,
      shape: CircleBorder(
        side: circle ? BorderSide(color: c.border) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: Sizes.avatar,
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                size: Sizes.icon,
                color: color ?? c.iconColor,
              ),
              child: glyph ?? Icon(icon),
            ),
          ),
        ),
      ),
    );
  }
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
          // Shrink-wraps its label: a chip is only as wide as its text,
          // whether it sits in a Wrap or a horizontal list.
          child: Container(
            height: Sizes.chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? CefColors.onAccent : c.textPrimary,
                ),
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
                    height: 48,
                    child: Center(
                      child: Text(
                        l,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: sel ? CefColors.brand : c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: Gap.lg),
                    decoration: BoxDecoration(
                      color: sel ? CefColors.brand : Colors.transparent,
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
      style: Theme.of(context).textTheme.bodyLarge,
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

/// The one list / settings row: optional leading (an [icon], shown in an
/// [IconTile], or any widget such as a [CefAvatar]), title, subtitle,
/// optional trailing widget, and a chevron whenever the row navigates.
/// Rows are separated by a hairline divider; inside a [CefListGroup] the
/// group draws inset dividers instead.
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
    this.subtitleMaxLines = 1,
    this.emphasis,
    this.dense = false,
    this.showDivider = true,
    this.titleColor,
  }) : assert(icon == null || leading == null);

  /// Destructive option rows (e.g. Delete zone) pass the attention colour.
  final Color? titleColor;

  /// False when the row sits alone inside its own card.
  final bool showDivider;

  /// One step smaller type (title 15, subtitle 13) for rows carrying a
  /// two-line trailing block, e.g. Today's Recent Delivery.
  final bool dense;

  /// Unread / read treatment (notifications): true = bold title, false =
  /// muted title. Null = the standard row.
  final bool? emphasis;

  final String title;

  /// Subtitles are one ellipsized line; a settings row whose explanation
  /// must be read in full (e.g. notification preferences) passes 2.
  final int subtitleMaxLines;
  final String? subtitle;
  final IconData? icon;

  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Set false for rows whose tap selects in place (a radio choice) or for
  /// operational lists whose reference shows no chevron.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final grouped = _ListGroupScope.of(context);
    final lead = leading ?? (icon == null ? null : IconTile(icon!));
    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: grouped ? 56 : Sizes.listRow),
          padding: EdgeInsets.symmetric(
            horizontal: grouped ? Gap.lg : 0,
            vertical: grouped ? Gap.sm : Gap.md,
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
                      style:
                          switch (emphasis) {
                            true =>
                              Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            false =>
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: c.textSecondary,
                              ),
                            null => Theme.of(context).textTheme.titleSmall,
                          }?.copyWith(
                            fontSize: dense ? 15 : null,
                            color: titleColor,
                          ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: subtitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: dense ? 13 : null),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: Gap.sm),
                // Capped at half the screen, so a long pill or large OS text
                // shrinks the trailing content instead of overflowing; a
                // small trailing widget leaves the title its full width.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width / 2,
                  ),
                  child: trailing,
                ),
              ],
              if (onTap != null && showChevron) ...[
                const SizedBox(width: Gap.sm),
                Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: c.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    // Inside a group the group draws the separators. A free-standing row
    // gets a light hairline inset past its leading icon -- never a
    // full-width rule.
    if (grouped || !showDivider) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        Divider(
          height: 1,
          thickness: 1,
          indent: lead == null ? 0 : Sizes.avatar + Gap.md,
          color: c.border.withValues(alpha: .6),
        ),
      ],
    );
  }
}

class _ListGroupScope extends InheritedWidget {
  const _ListGroupScope({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ListGroupScope>() != null;

  @override
  bool updateShouldNotify(_ListGroupScope oldWidget) => false;
}

/// The one grouped card of rows: an optional muted group [label] above a
/// white rounded, hairline-bordered card holding [CefListRow]s separated by
/// dividers inset past the icon disc. Settings groups (on a
/// `PageBody(grouped: true)`) and detail-screen information cards share it.
class CefListGroup extends StatelessWidget {
  const CefListGroup({super.key, this.label, required this.children});
  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xs, 0, 0, Gap.sm),
              child: Text(
                label!,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(Sizes.cardRadius),
              border: Border.all(color: c.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _ListGroupScope(
              child: Column(
                children: [
                  for (final (i, child) in children.indexed) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: Gap.lg + Sizes.avatar + Gap.md,
                        color: c.border.withValues(alpha: .6),
                      ),
                    child,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one tinted action row: a CEFFLO Blue tinted, rounded, full-width
/// row for a secondary in-form or on-page action ("Add items to this
/// order"). Its icon sits in the standard [IconTile].
class CefActionRow extends StatelessWidget {
  const CefActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.chevron = true,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool chevron;

  /// Optional supporting line under the label ("Riders can scan this code").
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Material(
    color: CefColors.brandTint,
    borderRadius: BorderRadius.circular(Sizes.inputRadius),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Sizes.inputRadius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.sm,
        ),
        child: Row(
          children: [
            IconTile(icon),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: subtitle == null ? CefColors.brand : null,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (chevron)
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: context.c.textSecondary,
              ),
          ],
        ),
      ),
    ),
  );
}

/// White pill on the gradient hero carrying a semantic dot + label
/// ("● Active"), for the detail-hero archetype.
class HeroStatusPill extends StatelessWidget {
  const HeroStatusPill(this.label, {super.key, this.color});
  final String label;

  /// Dot and label colour; defaults to success green.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? context.c.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: Gap.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

/// One meta line under a [DetailHero] identity: plain text ("Rider") or an
/// icon + text ("VFY 7281" beside a vehicle icon).
class HeroLine {
  const HeroLine(this.text, {this.icon});
  final String text;
  final IconData? icon;
}

/// Identity block drawn ON the gradient for the detail-hero archetype
/// (rider / team member / customer / order): a large light [leading]
/// (usually a [CefAvatar]) beside a white title, an optional status pill
/// and meta [lines].
class DetailHero extends StatelessWidget {
  const DetailHero({
    super.key,
    this.leading,
    required this.title,
    this.status,
    this.lines = const [],
  });

  /// Avatar beside a left-aligned identity (people). Without it the
  /// identity is centred (an order: reference, status, meta).
  final Widget? leading;
  final String title;
  final Widget? status;
  final List<HeroLine> lines;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Colors.white.withValues(alpha: .88);
    final centred = leading == null;
    final identity = Column(
      crossAxisAlignment: centred
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          textAlign: centred ? TextAlign.center : TextAlign.start,
          overflow: TextOverflow.ellipsis,
          style: text.titleLarge?.copyWith(color: Colors.white),
        ),
        if (status != null) ...[const SizedBox(height: Gap.sm), status!],
        for (final line in lines) ...[
          const SizedBox(height: Gap.xs),
          Row(
            mainAxisSize: centred ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (line.icon != null) ...[
                Icon(line.icon, size: 18, color: muted),
                const SizedBox(width: Gap.xs),
              ],
              Flexible(
                child: Text(
                  line.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(color: muted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.xs,
        Gap.gutter,
        Gap.xl,
      ),
      child: centred
          ? SizedBox(width: double.infinity, child: identity)
          : Row(
              children: [
                leading!,
                const SizedBox(width: Gap.xl),
                Expanded(child: identity),
              ],
            ),
    );
  }
}

/// The one stats card on detail screens: a [KpiStrip] of icon / value /
/// label columns inside a card (rider Total orders · Rating · Joined,
/// business Products · Orders · Rating).
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.items});
  final List<KpiItem> items;

  @override
  Widget build(BuildContext context) => CefCard(
    padding: const EdgeInsets.symmetric(horizontal: Gap.xs, vertical: Gap.sm),
    child: KpiStrip(items: items),
  );
}

// ---------------------------------------------------------------------------
// Contact actions (D-46): one component for every person/entity detail
// screen with a usable phone number.
// ---------------------------------------------------------------------------

/// Opens the native dialer for [phone].
Future<void> launchPhoneCall(BuildContext context, String phone) => _launch(
  context,
  Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')),
  'the phone app',
);

/// Opens a WhatsApp conversation with [phone] (international number).
Future<void> launchWhatsApp(BuildContext context, String phone) => _launch(
  context,
  Uri.https('wa.me', '/${phone.replaceAll(RegExp(r'\D'), '')}'),
  'WhatsApp',
);

/// Opens turn-by-turn directions to [address] in the maps app / Google Maps.
Future<void> launchDirections(BuildContext context, String address) => _launch(
  context,
  Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': address,
  }),
  'maps',
);

Future<void> _launch(BuildContext context, Uri uri, String target) async {
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    showCefToast(context, 'Could not open $target.', error: true);
  }
}

/// The one Call + WhatsApp pair: [OutlinedIconAction]s. Only rendered for
/// a real number -- callers show "Not provided" instead of fake actions when
/// there is none.
class ContactActions extends StatelessWidget {
  const ContactActions({super.key, required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      OutlinedIconAction(
        label: 'Call',
        semanticLabel: 'Call $phone',
        icon: LucideIcons.phone,
        circle: true,
        onTap: () => launchPhoneCall(context, phone),
      ),
      const SizedBox(width: Gap.xs),
      OutlinedIconAction(
        label: 'WhatsApp',
        semanticLabel: 'WhatsApp $phone',
        glyph: const WhatsAppGlyph(),
        circle: true,
        onTap: () => launchWhatsApp(context, phone),
      ),
    ],
  );
}

/// The one utility action on detail rows (Call, WhatsApp, Directions): an
/// [IconTile] as the tap target with a caption underneath. Call and
/// WhatsApp pass [circle] for the round outline; others stay bare.
class OutlinedIconAction extends StatelessWidget {
  const OutlinedIconAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.glyph,
    this.semanticLabel,
    this.circle = false,
  }) : assert((icon == null) != (glyph == null));

  /// Round outline -- Call and WhatsApp only.
  final bool circle;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// A composed outline mark (e.g. WhatsApp) in place of [icon].
  final Widget? glyph;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel ?? label,
    excludeSemantics: true,
    child: SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          glyph == null
              ? IconTile(icon!, onTap: onTap, circle: circle)
              : IconTile.glyph(glyph!, onTap: onTap, circle: circle),
          const SizedBox(height: Gap.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: context.c.textPrimary),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Outline WhatsApp mark: the round speech bubble with a handset inside,
/// composed from the Lucide set so it matches every other outline icon.
/// Takes its size and colour from the surrounding [IconTheme].
class WhatsAppGlyph extends StatelessWidget {
  const WhatsAppGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 20;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.messageCircle, size: size, color: theme.color),
          Transform.translate(
            offset: Offset(size * .02, -size * .02),
            child: Icon(
              LucideIcons.phone,
              size: size * .42,
              color: theme.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// The one contact block on detail screens: grey phone disc, [title], the
/// number, and [ContactActions]. Without a number it reads "Not provided"
/// and offers no actions.
class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.phone, this.title = 'Contact'});
  final String? phone;
  final String title;

  @override
  Widget build(BuildContext context) {
    final number = phone?.trim() ?? '';
    return CefListGroup(
      children: [
        CefListRow(
          title: title,
          subtitle: number.isEmpty ? 'Not provided' : number,
          icon: LucideIcons.phone,
          trailing: number.isEmpty ? null : ContactActions(phone: number),
        ),
      ],
    );
  }
}

/// A focused bottom sheet listing a complete set of rows ("View all" for an
/// order's items or a zone's orders) so the page itself stays compact.
Future<void> showListSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Sizes.cardRadius),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.gutter,
                Gap.xl,
                Gap.gutter,
                Gap.sm,
              ),
              child: Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  Gap.gutter,
                  0,
                  Gap.gutter,
                  Gap.lg,
                ),
                children: children,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Skeleton loading: page-shaped placeholders instead of a spinner.
// ---------------------------------------------------------------------------

/// Softly pulses its [child] while content loads. One animation drives
/// every placeholder inside it.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});
  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: .55,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: FadeTransition(opacity: _controller, child: widget.child),
  );
}

/// One placeholder shape: a rounded cool-grey bar, or a circle.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.circle = false,
  });
  final double? width;
  final double height;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: circle ? height : width,
    height: height,
    decoration: BoxDecoration(
      color: context.c.border,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(Gap.sm),
    ),
  );
}

/// Placeholder for one [CefListRow]: leading circle, title and subtitle
/// bars, a trailing pill + caption, the inset hairline.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: Sizes.listRow,
        child: Row(
          children: [
            const SkeletonBox(height: Sizes.avatar, circle: true),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: .7,
                    child: const SkeletonBox(height: 14),
                  ),
                  const SizedBox(height: Gap.sm),
                  FractionallySizedBox(
                    widthFactor: .45,
                    child: const SkeletonBox(height: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.lg),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonBox(width: 72, height: 22),
                SizedBox(height: Gap.sm),
                SkeletonBox(width: 48, height: 12),
              ],
            ),
          ],
        ),
      ),
      Divider(
        height: 1,
        thickness: 1,
        indent: Sizes.avatar + Gap.md,
        color: context.c.border.withValues(alpha: .6),
      ),
    ],
  );
}

/// Placeholder for a [KpiStrip] of [count] columns.
class SkeletonKpis extends StatelessWidget {
  const SkeletonKpis({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0)
            VerticalDivider(width: 1, thickness: 1, color: context.c.border),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Gap.md,
                vertical: Gap.sm,
              ),
              child: Column(
                children: [
                  SkeletonBox(height: 28),
                  SizedBox(height: Gap.sm),
                  SkeletonBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Placeholder for a [SectionHeading], optionally with a trailing link.
class SkeletonHeading extends StatelessWidget {
  const SkeletonHeading({super.key, this.link = true});
  final bool link;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.sm),
    child: Row(
      children: [
        const SkeletonBox(width: 150, height: 20),
        const Spacer(),
        if (link) const SkeletonBox(width: 64, height: 16),
      ],
    ),
  );
}

/// The default loading state for a page: a heading and rows in the page
/// gutters. [top] adds page-specific shapes above (KPIs, a map...).
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({super.key, this.top = const [], this.rows = 5});
  final List<Widget> top;
  final int rows;

  /// Today: overview figures, recent deliveries, need attention.
  const SkeletonPage.today({super.key})
    : top = const [SkeletonKpis(), SizedBox(height: Gap.sm), SkeletonHeading()],
      rows = 4;

  @override
  Widget build(BuildContext context) => SkeletonPulse(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      children: [
        ...top,
        if (top.isEmpty) const SkeletonHeading(link: false),
        for (var i = 0; i < rows; i++) const SkeletonRow(),
      ],
    ),
  );
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
        padding: EdgeInsets.symmetric(vertical: Gap.xxxl),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final (icon, color) = switch (kind) {
      StateKind.error => (LucideIcons.triangleAlert, c.attention),
      StateKind.blocked => (LucideIcons.lock, c.textSecondary),
      _ => (LucideIcons.inbox, c.textSecondary),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xxl),
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
          padding: const EdgeInsets.symmetric(horizontal: Gap.xxl),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(Gap.xxl),
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
                padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
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
      const SizedBox(height: Gap.xxl),
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: Gap.sm),
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
      const SizedBox(height: Gap.lg),
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: Gap.sm),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      if (detail != null) ...[const SizedBox(height: Gap.lg), detail!],
      const SizedBox(height: Gap.xxl),
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
      const SizedBox(height: Gap.lg),
      Text(
        'Something went wrong',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: Gap.sm),
      Text(
        'We couldn\'t complete this action right now.\nPlease try again.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: Gap.lg),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Gap.md),
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
      const SizedBox(height: Gap.lg),
      Row(
        children: [
          Expanded(
            child: CefButton('Cancel', secondary: true, onTap: onCancel),
          ),
          const SizedBox(width: Gap.md),
          Expanded(child: CefButton('Try Again', onTap: onRetry)),
        ],
      ),
    ],
  );
}
