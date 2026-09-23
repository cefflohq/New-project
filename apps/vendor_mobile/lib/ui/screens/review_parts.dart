import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets.dart';

/// Person profile hero shared by Rider Detail and Team Member Detail: the
/// canonical [HeroSurface] with a [CefAvatar], the person's name, a light
/// status pill and their role.
class ReviewProfileHero extends StatelessWidget {
  const ReviewProfileHero({
    super.key,
    required this.name,
    required this.role,
    required this.status,
    this.pending = false,
  });
  final String name, role, status;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return HeroSurface(
      padding: const EdgeInsets.all(Gap.xl),
      child: Row(
        children: [
          CefAvatar(name, size: 72),
          const SizedBox(width: Gap.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .78),
                  ),
                ),
                const SizedBox(height: Gap.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: Gap.xs,
                  ),
                  decoration: BoxDecoration(
                    color: pending ? CefColors.accent : Colors.white,
                    borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                  ),
                  child: Text(
                    status,
                    maxLines: 1,
                    style: text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: pending ? CefColors.onAccent : CefColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One labelled fact on a profile (phone, vehicle, role...). A missing
/// [value] renders [emptyText] as muted supporting text instead.
class ProfileDetailLine {
  const ProfileDetailLine({
    required this.icon,
    required this.label,
    this.value,
    this.note,
    this.emptyText = 'Not provided',
  });
  final IconData icon;
  final String label;
  final String? value;
  final String? note;
  final String emptyText;
}

/// The one information block for the person detail screens: a [CefCard] of
/// icon + label + value lines, so Rider Detail and Team Member Detail read
/// identically.
class ProfileDetailCard extends StatelessWidget {
  const ProfileDetailCard({super.key, required this.lines});
  final List<ProfileDetailLine> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    return CefCard(
      child: Column(
        children: [
          for (final (i, line) in lines.indexed) ...[
            if (i > 0) const SizedBox(height: Gap.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(line.icon, size: Sizes.icon, color: c.iconColor),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.label, style: text.bodySmall),
                      const SizedBox(height: 2),
                      if (line.value == null)
                        Text(
                          line.emptyText,
                          style: text.bodyMedium?.copyWith(
                            color: c.textSecondary,
                          ),
                        )
                      else
                        Text(line.value!, style: text.titleSmall),
                      if (line.note != null) ...[
                        const SizedBox(height: Gap.xs),
                        Text(line.note!, style: text.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
