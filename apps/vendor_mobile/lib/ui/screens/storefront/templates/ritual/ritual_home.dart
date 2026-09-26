/// Ritual home -- Premium Product. A calm, one-product-at-a-time layout:
/// avatar and round icon actions, a large headline, outline category pills,
/// then large soft-tinted product cards with an oversized price and a round
/// add button; a floating glass tab bar sits over the content.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../data/storefront_catalog.dart';
import '../../shared/product_art.dart';
import '../../shared/storefront_common.dart';
import '../../shared/storefront_theme.dart';

class RitualHome extends StatefulWidget {
  const RitualHome({
    super.key,
    required this.businessName,
    required this.items,
    required this.categories,
    required this.tokens,
    required this.cart,
    required this.onOpenItem,
    required this.onOpenCart,
  });

  final String businessName;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final ValueChanged<String> onOpenItem;
  final VoidCallback onOpenCart;

  @override
  State<RitualHome> createState() => _RitualHomeState();
}

class _RitualHomeState extends State<RitualHome> {
  String _active = 'all';

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final shown = _active == 'all'
        ? widget.items
        : widget.items.where((i) => i.categoryId == _active).toList();
    final chips = [
      const StorefrontCategory('all', 'All', LucideIcons.layoutGrid),
      ...widget.categories.where((c) => c.id != 'all'),
    ];
    final initial = widget.businessName.trim().isEmpty
        ? '•'
        : widget.businessName.trim()[0].toUpperCase();
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Color.lerp(t.primary, Colors.white, .75),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: t.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: widget.cart,
                  builder: (context, _) => _RoundAction(
                    icon: LucideIcons.bell,
                    badge: widget.cart.itemCount > 0
                        ? '${widget.cart.itemCount}'
                        : null,
                    badgeColor: t.primary,
                    onTap: widget.onOpenCart,
                  ),
                ),
                const SizedBox(width: 10),
                _RoundAction(icon: LucideIcons.grip, onTap: () {}),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    t.headline('Your complete\ndaily routine'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: StorefrontThemeTokens.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _RoundAction(icon: LucideIcons.search, size: 50, onTap: () {}),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = chips[i];
                  final on = c.id == _active;
                  return GestureDetector(
                    onTap: () => setState(() => _active = c.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: on
                            ? Color.lerp(t.primary, Colors.white, .25)
                            : null,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: on
                              ? Colors.transparent
                              : StorefrontThemeTokens.border,
                        ),
                      ),
                      child: Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: on
                              ? Colors.white
                              : StorefrontThemeTokens.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            for (final item in shown) ...[
              _ProductCard(
                item: item,
                tokens: t,
                onTap: () => widget.onOpenItem(item.id),
                onAdd: () => widget.cart.add(item),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 22,
          child: Center(
            child: _GlassNav(tokens: t, onOpenCart: widget.onOpenCart),
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.badge,
    this.badgeColor,
  });
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: StorefrontThemeTokens.border),
              ),
              child: Icon(
                icon,
                size: 19,
                color: StorefrontThemeTokens.textPrimary,
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.tokens,
    required this.onTap,
    required this.onAdd,
  });
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(tokens.primary, Colors.white, .9)!,
            Color.lerp(tokens.primary, Colors.white, .8)!,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: ProductArtView(item.art, accent: tokens.primary),
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: StorefrontThemeTokens.textPrimary,
            ),
          ),
          if ((item.description ?? '').isNotEmpty)
            Text(
              item.description!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: StorefrontThemeTokens.textSecondary,
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 50),
              Expanded(
                child: Text(
                  'RM ${item.price.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                    color: StorefrontThemeTokens.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(tokens.primary, Colors.white, .3),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _GlassNav extends StatelessWidget {
  const _GlassNav({required this.tokens, required this.onOpenCart});
  final StorefrontThemeTokens tokens;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: .7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _navDot(LucideIcons.house, active: true),
            _navDot(LucideIcons.shoppingCart, onTap: onOpenCart),
            _navDot(LucideIcons.heart),
            _navDot(LucideIcons.user),
          ],
        ),
      ),
    ),
  );

  Widget _navDot(IconData icon, {bool active = false, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.transparent,
            boxShadow: active
                ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 8)]
                : null,
          ),
          child: Icon(icon, size: 19, color: StorefrontThemeTokens.textPrimary),
        ),
      );
}
