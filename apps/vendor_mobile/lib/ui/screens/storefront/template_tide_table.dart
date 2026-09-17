/// Template -- Tide Table. Airy seafood/food-delivery storefront: Home
/// (hamburger header, "Delicious Seafood" heading, pill filters, dish cards
/// whose photo breaks out of the top of the card) -> Product Detail (a
/// large dish photo, an inline quantity stepper, a delivery-time note and a
/// floating dark cart FAB) -> Cart -> Checkout -> Order Created.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/storefront_catalog.dart';
import 'storefront_common.dart';
import 'storefront_theme.dart';

class TideTablePreview extends StatefulWidget {
  const TideTablePreview({
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
  State<TideTablePreview> createState() => _TideTablePreviewState();
}

class _TideTablePreviewState extends State<TideTablePreview> {
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
        decoration: const BoxDecoration(color: StorefrontThemeTokens.surface),
        child: switch (_top.stage) {
          'detail' => _DishDetailView(
            item: widget.items.firstWhere((i) => i.id == _top.itemId),
            tokens: tokens,
            cart: _cart,
            onBack: _pop,
            onOpenCart: () => _push(const StorefrontStep('cart')),
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
          _ => _TideHome(
            businessName: widget.businessName,
            items: widget.items,
            categories: widget.categories,
            tokens: tokens,
            cart: _cart,
            onOpenItem: (id) => _push(StorefrontStep('detail', itemId: id)),
            onOpenCart: () => _push(const StorefrontStep('cart')),
          ),
        },
      ),
    );
  }
}

class _TideHome extends StatefulWidget {
  const _TideHome({
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
  State<_TideHome> createState() => _TideHomeState();
}

class _TideHomeState extends State<_TideHome> {
  String active = 'all';
  final _favorites = <String>{};

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final visible = active == 'all'
        ? widget.items
        : widget.items.where((i) => i.categoryId == active).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Icon(
                LucideIcons.menu,
                size: 20,
                color: StorefrontThemeTokens.textPrimary,
              ),
              const Spacer(),
              const Icon(
                LucideIcons.search,
                size: 20,
                color: StorefrontThemeTokens.textPrimary,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            children: [
              Text(
                widget.businessName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'We made healthy seafood for you',
                style: TextStyle(
                  fontSize: 13,
                  color: StorefrontThemeTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    StorefrontCategoryChip(
                      label: 'Popular',
                      selected: active == 'all',
                      tokens: tokens,
                      onTap: () => setState(() => active = 'all'),
                    ),
                    for (final c in widget.categories.where(
                      (c) => c.id != 'all',
                    ))
                      StorefrontCategoryChip(
                        label: c.label,
                        selected: active == c.id,
                        tokens: tokens,
                        onTap: () => setState(() => active = c.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              for (final item in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: _DishCard(
                    item: item,
                    tokens: tokens,
                    favored: _favorites.contains(item.id),
                    onFavorite: () => setState(
                      () => _favorites.contains(item.id)
                          ? _favorites.remove(item.id)
                          : _favorites.add(item.id),
                    ),
                    onAdd: () => widget.cart.add(item),
                    onTap: () => widget.onOpenItem(item.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({
    required this.item,
    required this.tokens,
    required this.favored,
    required this.onFavorite,
    required this.onAdd,
    required this.onTap,
  });
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final bool favored;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 14),
            decoration: BoxDecoration(
              color: StorefrontThemeTokens.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description ?? 'Fresh and crispy.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: StorefrontThemeTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: tokens.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 74),
                Column(
                  children: [
                    InkWell(
                      onTap: onFavorite,
                      child: Icon(
                        LucideIcons.heart,
                        size: 17,
                        color: favored
                            ? tokens.primary
                            : StorefrontThemeTokens.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onAdd,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: StorefrontThemeTokens.textPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: StorefrontThemeTokens.card,
                boxShadow: const [
                  BoxShadow(color: Color(0x1F000000), blurRadius: 10),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: StorefrontImagePlaceholder(
                icon: item.icon,
                size: double.infinity,
                radius: 999,
                tint: tokens.primary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DishDetailView extends StatefulWidget {
  const _DishDetailView({
    required this.item,
    required this.tokens,
    required this.cart,
    required this.onBack,
    required this.onOpenCart,
  });
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final VoidCallback onBack;
  final VoidCallback onOpenCart;

  @override
  State<_DishDetailView> createState() => _DishDetailViewState();
}

class _DishDetailViewState extends State<_DishDetailView> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tokens = widget.tokens;
    return Stack(
      children: [
        Column(
          children: [
            StorefrontBackBar(title: '', onBack: widget.onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: StorefrontImagePlaceholder(
                      icon: item.icon,
                      size: double.infinity,
                      radius: 999,
                      tint: tokens.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Spice & herbs',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.description ?? 'One of the easiest, freshest picks -- prepared and lightly seasoned in a butter-oil finish.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: StorefrontThemeTokens.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      StorefrontQtyStepper(
                        qty: qty,
                        tokens: tokens,
                        onChanged: (q) => setState(() => qty = q < 1 ? 1 : q),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        LucideIcons.clock,
                        size: 15,
                        color: StorefrontThemeTokens.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Delivered in 28 Min',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: StorefrontThemeTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${(item.price * qty).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: InkWell(
            onTap: () {
              widget.cart.add(item, qty: qty);
              widget.onOpenCart();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: StorefrontThemeTokens.textPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.shoppingCart,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
