/// Feast home -- Rich Visual. Avatar, store location and bell; a pill search
/// with an accent button; icon category pills; then a swipeable carousel of
/// large gradient product cards whose round product image breaks out of
/// the card top, with neighbouring cards peeking at the edges.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../data/storefront_catalog.dart';
import '../../shared/product_art.dart';
import '../../shared/storefront_common.dart';
import '../../shared/storefront_theme.dart';

class FeastHome extends StatefulWidget {
  const FeastHome({
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
  State<FeastHome> createState() => _FeastHomeState();
}

class _FeastHomeState extends State<FeastHome> {
  String _active = 'all';
  final _pages = PageController(viewportFraction: .72);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

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
    final soft = Color.lerp(t.primary, Colors.white, .45)!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color.lerp(t.primary, Colors.white, .8),
                      child: Icon(LucideIcons.user, size: 18, color: t.primary),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.mapPin, size: 18, color: soft),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: StorefrontThemeTokens.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onOpenCart,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          LucideIcons.bell,
                          size: 21,
                          color: StorefrontThemeTokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.only(left: 20, right: 5),
                  decoration: BoxDecoration(
                    color: StorefrontThemeTokens.muted,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: StorefrontThemeTokens.border),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Search',
                          style: TextStyle(
                            fontSize: 14,
                            color: StorefrontThemeTokens.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: soft,
                        ),
                        child: const Icon(
                          LucideIcons.search,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: StorefrontThemeTokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: chips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final c = chips[i];
                    final on = c.id == _active;
                    return GestureDetector(
                      onTap: () => setState(() => _active = c.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: on ? soft : StorefrontThemeTokens.muted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              c.icon,
                              size: 15,
                              color: on
                                  ? Colors.white
                                  : StorefrontThemeTokens.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: on
                                    ? Colors.white
                                    : StorefrontThemeTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 350,
                child: shown.isEmpty
                    ? const Center(
                        child: Text(
                          'No products in this category yet.',
                          style: TextStyle(
                            color: StorefrontThemeTokens.textSecondary,
                          ),
                        ),
                      )
                    : PageView.builder(
                        controller: _pages,
                        itemCount: shown.length,
                        itemBuilder: (context, i) => _CarouselCard(
                          item: shown[i],
                          tokens: t,
                          onTap: () => widget.onOpenItem(shown[i].id),
                          onAdd: () => widget.cart.add(shown[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
        _BottomNav(tokens: t, onOpenCart: widget.onOpenCart),
      ],
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
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
  Widget build(BuildContext context) {
    final dark = Color.lerp(tokens.primary, Colors.black, .35)!;
    final light = Color.lerp(tokens.primary, Colors.white, .15)!;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          children: [
            Positioned(
              top: 78,
              left: 0,
              right: 0,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [light, dark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: dark.withValues(alpha: .35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
            // Round product image breaking out of the card top.
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 168,
                height: 168,
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF6F3EF),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ProductArtView(item.art, accent: tokens.primary),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.star,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.rating}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if ((item.description ?? '').isNotEmpty)
                    Text(
                      item.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'RM ${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            LucideIcons.plus,
                            color: tokens.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.tokens, required this.onOpenCart});
  final StorefrontThemeTokens tokens;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(40, 10, 40, 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.house,
              size: 22,
              color: Color.lerp(tokens.primary, Colors.white, .3),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(tokens.primary, Colors.white, .3),
              ),
            ),
          ],
        ),
        const Icon(
          LucideIcons.heart,
          size: 22,
          color: StorefrontThemeTokens.textSecondary,
        ),
        GestureDetector(
          onTap: onOpenCart,
          child: const Icon(
            LucideIcons.layoutGrid,
            size: 22,
            color: StorefrontThemeTokens.textSecondary,
          ),
        ),
      ],
    ),
  );
}
