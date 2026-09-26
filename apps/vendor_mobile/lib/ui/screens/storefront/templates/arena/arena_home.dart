/// Arena home -- Bold Showcase. A full-bleed hero split diagonally in the
/// storefront's two colours, one large hero product, the store wordmark and
/// a Shop now pill; below it a white sheet with a Popular rail and large
/// category tiles.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../data/storefront_catalog.dart';
import '../../shared/product_art.dart';
import '../../shared/storefront_common.dart';
import '../../shared/storefront_theme.dart';

class ArenaHome extends StatelessWidget {
  const ArenaHome({
    super.key,
    required this.businessName,
    required this.items,
    required this.categories,
    required this.tokens,
    required this.cart,
    required this.onOpenCategory,
    required this.onOpenItem,
    required this.onOpenCart,
  });

  final String businessName;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final ValueChanged<String> onOpenCategory;
  final ValueChanged<String> onOpenItem;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final hero = items.first;
    final cats = categories.where((c) => c.id != 'all').take(3).toList();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Hero(
          businessName: businessName,
          item: hero,
          tokens: tokens,
          cart: cart,
          onShop: () => onOpenItem(hero.id),
          onOpenCart: onOpenCart,
        ),
        Transform.translate(
          offset: const Offset(0, -22),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Heading('Popular'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final (i, item) in items.take(3).indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _PopularCard(
                          item: item,
                          tokens: tokens,
                          onTap: () => onOpenItem(item.id),
                        ),
                      ),
                    ],
                    for (var i = items.length; i < 3; i++) ...[
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                const _Heading('Categories'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final (i, c) in cats.indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _CategoryTile(
                          category: c,
                          item: items.firstWhere(
                            (it) => it.categoryId == c.id,
                            orElse: () => items[i % items.length],
                          ),
                          tokens: tokens,
                          onTap: () => onOpenCategory(c.id),
                        ),
                      ),
                    ],
                    for (var i = cats.length; i < 3; i++) ...[
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: StorefrontThemeTokens.textPrimary,
    ),
  );
}

/// The two brand colours split by a light diagonal band.
class _SplitPainter extends CustomPainter {
  _SplitPainter(this.primary, this.secondary);
  final Color primary, secondary;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = primary);
    canvas.drawPath(
      Path()
        ..moveTo(s.width * .42, 0)
        ..lineTo(s.width * .62, 0)
        ..lineTo(s.width * .30, s.height)
        ..lineTo(s.width * .10, s.height)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: .16),
    );
    canvas.drawPath(
      Path()
        ..moveTo(s.width * .62, 0)
        ..lineTo(s.width, 0)
        ..lineTo(s.width, s.height)
        ..lineTo(s.width * .30, s.height)
        ..close(),
      Paint()..color = secondary,
    );
  }

  @override
  bool shouldRepaint(_SplitPainter old) =>
      old.primary != primary || old.secondary != secondary;
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.businessName,
    required this.item,
    required this.tokens,
    required this.cart,
    required this.onShop,
    required this.onOpenCart,
  });

  final String businessName;
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final VoidCallback onShop;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final initials = businessName.trim().isEmpty
        ? '•'
        : businessName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0])
              .join()
              .toUpperCase();
    return SizedBox(
      height: 500,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SplitPainter(tokens.primary, tokens.secondary),
            ),
          ),
          if (tokens.heroImage != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: tokens.withHeroImage(const BoxDecoration()),
              ),
            ),
          // Hero product.
          Positioned(
            right: -18,
            top: 56,
            width: 236,
            height: 236,
            child: ProductArtView(item.art, accent: tokens.primary),
          ),
          // Top bar.
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _GlassCircle(icon: LucideIcons.layoutGrid, onTap: () {}),
                Expanded(
                  child: Text(
                    businessName.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: cart,
                  builder: (context, _) => _GlassCircle(
                    icon: LucideIcons.shoppingCart,
                    badge: cart.itemCount,
                    onTap: onOpenCart,
                  ),
                ),
              ],
            ),
          ),
          // Identity + CTA.
          Positioned(
            left: 22,
            right: 150,
            bottom: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: tokens.secondary, width: 3),
                  ),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: tokens.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tokens
                      .headline(item.description ?? businessName)
                      .toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    fontSize: 12,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 18),
                Material(
                  color: Colors.white,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: onShop,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: StorefrontThemeTokens.textPrimary,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            LucideIcons.arrowRight,
                            size: 18,
                            color: StorefrontThemeTokens.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Page dots.
          Positioned(
            left: 0,
            right: 0,
            bottom: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == 0 ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i == 0 ? 1 : .5),
                      borderRadius: BorderRadius.circular(3),
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

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.icon, required this.onTap, this.badge = 0});
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) => InkWell(
    customBorder: const CircleBorder(),
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          if (badge > 0)
            Positioned(
              top: 9,
              right: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({
    required this.item,
    required this.tokens,
    required this.onTap,
  });
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: StorefrontThemeTokens.muted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ProductArtView(item.art, accent: tokens.primary),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  LucideIcons.heart,
                  size: 14,
                  color: tokens.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
          Text(
            'RM ${item.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 11,
              color: StorefrontThemeTokens.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.item,
    required this.tokens,
    required this.onTap,
  });
  final StorefrontCategory category;
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: StorefrontThemeTokens.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: ProductArtView(item.art, accent: tokens.primary),
          ),
          const SizedBox(height: 6),
          Text(
            category.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}
