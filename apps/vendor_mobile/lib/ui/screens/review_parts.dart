import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../widgets.dart';

/// Shared full-bleed "tall profile header" for the two person-detail screens
/// (Rider Detail, Team Member Detail) that own their entire chrome (see
/// `_ownChromeRoutes` in shell.dart) instead of the default flat back-arrow
/// header. The gradient extends down to contain the avatar/name/status
/// block itself -- not a card floating on a white page -- per the locked
/// reference screens, then rounds into the white sheet below exactly like
/// the shared tab-root header's "lip" (shell.dart's `_Header`).
///
/// Both reference screens share this gradient-profile-block pattern but
/// differ in two ways: Team Member centers everything and has no stat row;
/// Rider Detail left-aligns the avatar next to the name block and adds a
/// 3-up stat row beneath it. Both are expressed here via [centered] and
/// [stats] rather than as two separate widgets, since duplicating the
/// gradient/lip/back-arrow plumbing for a one-parameter difference would be
/// the kind of drift this shared-widget pass is meant to avoid.
class TallProfileHeader extends StatelessWidget {
  const TallProfileHeader({
    super.key,
    required this.title,
    required this.name,
    required this.status,
    this.subtitle,
    this.centered = false,
    this.pending = false,
    this.showAvatarStatusDot = false,
    this.stats,
    required this.onBack,
    this.onMenu,
  });

  final String title;
  final String name;
  final String status;
  final String? subtitle;
  final bool centered;
  final bool pending;

  /// Small green dot overlapping the avatar's bottom-right corner --
  /// Team Member Detail's reference shows this, Rider Detail's doesn't.
  final bool showAvatarStatusDot;

  /// (icon, value, label) columns, separated by thin dividers -- Rider
  /// Detail only.
  final List<(IconData, String, String)>? stats;

  final VoidCallback onBack;
  final VoidCallback? onMenu;

  static const _gradient = LinearGradient(
    begin: Alignment(-1, 1),
    end: Alignment(1, -1),
    colors: [Color(0xFF0B1E4E), Color(0xFF1257C4), Color(0xFF1E9CF2)],
    stops: [0, 0.55, 1],
  );

  @override
  Widget build(BuildContext context) {
    final pillBg = pending ? const Color(0xFFFEC819) : Colors.white;
    final pillFg = pending ? const Color(0xFF102344) : const Color(0xFF1B8F4C);
    final avatarInitials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join()
        .toUpperCase();

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFDCE7F3),
          child: Text(
            avatarInitials,
            style: const TextStyle(
              fontSize: 28,
              color: Color(0xFF12213E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showAvatarStatusDot)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF2FB86C),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
      ],
    );

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: pillFg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: pillFg,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final nameText = Text(
      name,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );

    final subtitleText = subtitle == null
        ? null
        : Text(
            subtitle!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          );

    final profileBlock = centered
        ? Column(
            children: [
              avatar,
              const SizedBox(height: 14),
              nameText,
              const SizedBox(height: 8),
              pill,
              if (subtitleText != null) ...[
                const SizedBox(height: 8),
                subtitleText,
              ],
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    nameText,
                    const SizedBox(height: 8),
                    pill,
                    if (subtitleText != null) ...[
                      const SizedBox(height: 6),
                      subtitleText,
                    ],
                  ],
                ),
              ),
            ],
          );

    return Container(
      decoration: const BoxDecoration(gradient: _gradient),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconAction(
                      icon: LucideIcons.arrowLeft,
                      tooltip: 'Back',
                      onTap: onBack,
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (onMenu != null)
                      IconAction(
                        icon: LucideIcons.moreVertical,
                        tooltip: 'More',
                        onTap: onMenu!,
                        color: Colors.white,
                      )
                    else
                      const SizedBox(width: Sizes.tapTarget),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.gutter,
              Gap.sm,
              Gap.gutter,
              Gap.lg,
            ),
            child: profileBlock,
          ),
          if (stats != null) ...[
            const SizedBox(height: Gap.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.gutter),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    for (var i = 0; i < stats!.length; i++) ...[
                      if (i > 0)
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Colors.white24,
                        ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              stats![i].$1,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stats![i].$2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stats![i].$3,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Gap.lg),
          ],
          // Rounded white "lip" the body sheet grows out of -- same trick
          // as the shared tab-root header (shell.dart's _Header).
          Builder(
            builder: (context) => Container(
              height: 22,
              decoration: BoxDecoration(
                color: context.c.canvas,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
