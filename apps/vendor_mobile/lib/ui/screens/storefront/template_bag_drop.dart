/// Template -- Bag Drop. High-contrast streetwear storefront: Home (bold
/// uppercase wordmark header, a black promo drop banner, square
/// quick-category tiles, a badged "New Arrival" grid) -> Product Detail
/// (photo-gallery strip, uppercase name, orange price, tag pills, a
/// full-width black bag CTA) -> Cart -> Checkout -> Order Created.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/storefront_catalog.dart';
import 'storefront_common.dart';
import 'storefront_theme.dart';

const _dropOrange = Color(0xFFE2571C);

class BagDropPreview extends StatefulWidget {
  const BagDropPreview({
    super.key,
    required this.businessName,
    required this.items,
    required this.categories,
    required this.tokens,
  });

  final String businessName;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;
  final StorefrontThemeTokens tokens;

  @override
  State<BagDropPreview> createState() => _BagDropPreviewState();
}

class _BagDropPreviewState extends State<BagDropPreview> {
  final _cart = StorefrontCartController();
  final _stack = <StorefrontStep>[const StorefrontStep('home')];

  StorefrontStep get _top => _stack.last;
  void _push(StorefrontStep s) => setState(() => _stack.add(s));
  void _pop() => setState(() => _stack.length > 1 ? _stack.removeLast() : null);

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    return PopScope(
      canPop: _stack.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pop();
      },
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: switch (_top.stage) {
          'category' => _DropCategoryView(
            categoryId: _top.categoryId,
            items: widget.items,
            categories: widget.categories,
            tokens: tokens,
            onBack: _pop,
            onOpenItem: (id) => _push(StorefrontStep('detail', itemId: id)),
          ),
          'detail' => _DropDetailView(
            item: widget.items.firstWhere((i) => i.id == _top.itemId),
            tokens: tokens,
            cart: _cart,
            onBack: _pop,
          ),
          'cart' => StorefrontCartView(
            cart: _cart,
            tokens: tokens,
            onBack: _pop,
            onCheckout: () => _push(const StorefrontStep('checkout')),
          ),
          'checkout' => StorefrontCheckoutView(
            cart: _cart,
            tokens: tokens,
            onBack: _pop,
            onPlaceOrder: () {
              final ref = generateStorefrontOrderRef();
              setState(
                () => _stack.add(StorefrontStep('confirmed', itemId: ref)),
              );
            },
          ),
          'confirmed' => StorefrontOrderCreatedView(
            tokens: tokens,
            orderRef: _top.itemId ?? '',
            onDone: () {
              _cart.clear();
              setState(
                () => _stack
                  ..clear()
                  ..add(const StorefrontStep('home')),
              );
            },
          ),
          _ => _DropHome(
            businessName: widget.businessName,
            items: widget.items,
            categories: widget.categories,
            tokens: tokens,
            cart: _cart,
            onOpenCategory: (id) =>
                _push(StorefrontStep('category', categoryId: id)),
            onOpenItem: (id) => _push(StorefrontStep('detail', itemId: id)),
            onOpenCart: () => _push(const StorefrontStep('cart')),
          ),
        },
      ),
    );
  }
}

class _DropHome extends StatelessWidget {
  const _DropHome({
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
    final shopCategories = categories.where((c) => c.id != 'all').toList();
    final arrivals = items.take(4).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Icon(LucideIcons.menu, size: 20, color: Colors.black),
              const Spacer(),
              Text(
                businessName.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: cart,
                builder: (context, _) => InkWell(
                  onTap: onOpenCart,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        LucideIcons.search,
                        size: 20,
                        color: Colors.black,
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: _dropOrange,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              '${cart.itemCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buy 1\nGet 3',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'SHOP NOW',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.shirt,
                      size: 56,
                      color: Colors.white.withValues(alpha: .4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final c in shopCategories)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () => onOpenCategory(c.id),
                          child: Container(
                            width: 76,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE3E3E3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(c.icon, size: 20, color: Colors.black),
                                const SizedBox(height: 6),
                                Text(
                                  c.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Text(
                    'New Arrival',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Spacer(),
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: StorefrontThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
                children: [
                  for (final (i, item) in arrivals.indexed)
                    _DropCard(
                      item: item,
                      badge: i.isEven ? 'NEW' : 'SALE -40%',
                      onTap: () => onOpenItem(item.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DropCard extends StatelessWidget {
  const _DropCard({
    required this.item,
    required this.badge,
    required this.onTap,
  });
  final StorefrontItem item;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(4),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: StorefrontImagePlaceholder(
                  icon: item.icon,
                  size: double.infinity,
                  radius: 4,
                  tint: Colors.black54,
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _dropOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${item.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: _dropOrange,
          ),
        ),
        Text(
          item.name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ],
    ),
  );
}

class _DropCategoryView extends StatelessWidget {
  const _DropCategoryView({
    required this.categoryId,
    required this.items,
    required this.categories,
    required this.tokens,
    required this.onBack,
    required this.onOpenItem,
  });
  final String? categoryId;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;
  final StorefrontThemeTokens tokens;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenItem;

  @override
  Widget build(BuildContext context) {
    final label = categories
        .firstWhere((c) => c.id == categoryId, orElse: () => categories.first)
        .label;
    final visible = items.where((i) => i.categoryId == categoryId).toList();
    return Column(
      children: [
        StorefrontBackBar(title: label.toUpperCase(), onBack: onBack),
        Expanded(
          child: visible.isEmpty
              ? const Center(
                  child: Text(
                    'No products in this category yet.',
                    style: TextStyle(
                      color: StorefrontThemeTokens.textSecondary,
                    ),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                  children: [
                    for (final item in visible)
                      _DropCard(
                        item: item,
                        badge: 'NEW',
                        onTap: () => onOpenItem(item.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DropDetailView extends StatefulWidget {
  const _DropDetailView({
    required this.item,
    required this.tokens,
    required this.cart,
    required this.onBack,
  });
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final VoidCallback onBack;

  @override
  State<_DropDetailView> createState() => _DropDetailViewState();
}

class _DropDetailViewState extends State<_DropDetailView> {
  bool expanded = true;
  int gallery = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Column(
      children: [
        StorefrontBackBar(
          title: item.name.toUpperCase(),
          onBack: widget.onBack,
          trailing: const [
            Icon(LucideIcons.heart, size: 19, color: Colors.black),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              AspectRatio(
                aspectRatio: 1.05,
                child: StorefrontImagePlaceholder(
                  icon: item.icon,
                  size: double.infinity,
                  radius: 6,
                  tint: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => InkWell(
                    onTap: () => setState(() => gallery = i),
                    child: Container(
                      width: 58,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: gallery == i
                              ? Colors.black
                              : const Color(0xFFE3E3E3),
                          width: gallery == i ? 1.8 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: StorefrontImagePlaceholder(
                        icon: item.icon,
                        size: double.infinity,
                        radius: 3,
                        tint: Colors.black38,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: _dropOrange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.name.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in [
                    'NEW',
                    item.categoryId.toUpperCase(),
                    'REGULAR FIT',
                  ])
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => expanded = !expanded),
                child: Row(
                  children: [
                    const Text(
                      'DETAIL',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      expanded
                          ? LucideIcons.chevronRight
                          : LucideIcons.chevronLeft,
                      size: 16,
                    ),
                  ],
                ),
              ),
              if (expanded) ...[
                const SizedBox(height: 8),
                Text(
                  item.description ?? 'A creatively styled unisex piece, cut to a straight, relaxed fit.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: StorefrontThemeTokens.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                widget.cart.add(item);
                widget.onBack();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'ADD TO SHOPPING BAG',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: .5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
