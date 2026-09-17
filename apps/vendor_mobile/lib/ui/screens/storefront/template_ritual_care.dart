/// Template -- Ritual Care. Calm, sage-toned skincare storefront: Home
/// (greeting + pill category tabs + one large hero product + a "You may
/// also like" scroller) -> Product Detail (full-bleed hero photo with a
/// frosted-glass bottom panel) -> Cart -> Checkout -> Order Created.
/// Deliberately single-product-at-a-time on Home (not a grid) and the
/// glassmorphism detail panel is the genuinely distinct composition this
/// template exists for.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/storefront_catalog.dart';
import 'storefront_common.dart';
import 'storefront_theme.dart';

class RitualCarePreview extends StatefulWidget {
  const RitualCarePreview({
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
  State<RitualCarePreview> createState() => _RitualCarePreviewState();
}

class _RitualCarePreviewState extends State<RitualCarePreview> {
  final _cart = StorefrontCartController();
  final _stack = <StorefrontStep>[const StorefrontStep('home')];
  final _favorites = <String>{};

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
          'detail' => _RitualDetailView(
            item: widget.items.firstWhere((i) => i.id == _top.itemId),
            tokens: tokens,
            cart: _cart,
            favored: _favorites.contains(_top.itemId),
            onToggleFavorite: () => setState(
              () => _favorites.contains(_top.itemId!)
                  ? _favorites.remove(_top.itemId)
                  : _favorites.add(_top.itemId!),
            ),
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
          _ => _RitualHome(
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

class _RitualHome extends StatefulWidget {
  const _RitualHome({
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
  State<_RitualHome> createState() => _RitualHomeState();
}

class _RitualHomeState extends State<_RitualHome> {
  late String active = widget.categories
      .firstWhere((c) => c.id != 'all', orElse: () => widget.categories.first)
      .id;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final inCategory = widget.items
        .where((i) => i.categoryId == active)
        .toList();
    final featured = inCategory.isNotEmpty
        ? inCategory.first
        : widget.items.first;
    final more = widget.items.where((i) => i.id != featured.id).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: StorefrontThemeTokens.muted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.user,
                  size: 16,
                  color: StorefrontThemeTokens.textSecondary,
                ),
              ),
              const Spacer(),
              const Icon(
                LucideIcons.bell,
                size: 19,
                color: StorefrontThemeTokens.textSecondary,
              ),
              const SizedBox(width: 14),
              const Icon(
                LucideIcons.moreHorizontal,
                size: 19,
                color: StorefrontThemeTokens.textSecondary,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            children: [
              Text(
                'Your complete\nnatural care routine',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 21,
                  height: 1.2,
                  color: tokens.primary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
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
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => widget.onOpenItem(featured.id),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: StorefrontThemeTokens.card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: StorefrontThemeTokens.border),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    tokens.secondary.withValues(alpha: .5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            StorefrontImagePlaceholder(
                              icon: featured.icon,
                              size: 96,
                              radius: 20,
                              tint: tokens.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        featured.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        featured.description ?? 'Light daily-use formula.',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: StorefrontThemeTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '\$${featured.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: tokens.primary,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              widget.cart.add(featured);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${featured.name} added to cart.',
                                  ),
                                  duration: const Duration(milliseconds: 900),
                                ),
                              );
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: tokens.accentDecoration(radius: 999),
                              child: Icon(
                                LucideIcons.plus,
                                size: 20,
                                color: tokens.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'You may also like',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 128,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final item in more)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => widget.onOpenItem(item.id),
                          child: Container(
                            width: 96,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: StorefrontThemeTokens.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: StorefrontThemeTokens.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StorefrontImagePlaceholder(
                                  icon: item.icon,
                                  size: 42,
                                  tint: tokens.primary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                  ),
                                ),
                                Text(
                                  '\$${item.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: tokens.primary,
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
            ],
          ),
        ),
        _RitualNavBar(
          tokens: tokens,
          cart: widget.cart,
          onOpenCart: widget.onOpenCart,
        ),
      ],
    );
  }
}

class _RitualNavBar extends StatelessWidget {
  const _RitualNavBar({
    required this.tokens,
    required this.cart,
    required this.onOpenCart,
  });
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      color: StorefrontThemeTokens.card,
      border: Border(top: BorderSide(color: StorefrontThemeTokens.border)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(LucideIcons.home, size: 20, color: tokens.primary),
        AnimatedBuilder(
          animation: cart,
          builder: (context, _) => InkWell(
            onTap: onOpenCart,
            child: Badge(
              isLabelVisible: cart.itemCount > 0,
              label: Text('${cart.itemCount}'),
              backgroundColor: tokens.primary,
              child: const Icon(
                LucideIcons.shoppingCart,
                size: 20,
                color: StorefrontThemeTokens.textSecondary,
              ),
            ),
          ),
        ),
        const Icon(
          LucideIcons.heart,
          size: 20,
          color: StorefrontThemeTokens.textSecondary,
        ),
        const Icon(
          LucideIcons.user,
          size: 20,
          color: StorefrontThemeTokens.textSecondary,
        ),
      ],
    ),
  );
}

class _RitualDetailView extends StatefulWidget {
  const _RitualDetailView({
    required this.item,
    required this.tokens,
    required this.cart,
    required this.favored,
    required this.onToggleFavorite,
    required this.onBack,
  });
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final bool favored;
  final VoidCallback onToggleFavorite;
  final VoidCallback onBack;

  @override
  State<_RitualDetailView> createState() => _RitualDetailViewState();
}

class _RitualDetailViewState extends State<_RitualDetailView> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tokens = widget.tokens;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tokens.secondary.withValues(alpha: .45),
                tokens.primary.withValues(alpha: .85),
              ],
            ),
          ),
        ),
        Center(
          child: Icon(
            item.icon,
            size: 190,
            color: Colors.white.withValues(alpha: .28),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                InkWell(
                  onTap: widget.onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      size: 18,
                      color: StorefrontThemeTokens.textPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: widget.onToggleFavorite,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.heart,
                      size: 17,
                      color: widget.favored
                          ? tokens.primary
                          : StorefrontThemeTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .82),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description ?? 'Light daily-use formula.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: StorefrontThemeTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        StorefrontQtyStepper(
                          qty: qty,
                          tokens: tokens,
                          onChanged: (q) => setState(() => qty = q < 1 ? 1 : q),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Total Price',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.primary.withValues(alpha: .7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$${(item.price * qty).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: StorefrontBrandButton(
                            label: 'Add to cart',
                            trailing: '>>>',
                            outlined: true,
                            tokens: tokens,
                            onTap: () {
                              widget.cart.add(item, qty: qty);
                              widget.onBack();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            widget.cart.add(item, qty: qty);
                            widget.onBack();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: tokens.accentDecoration(radius: 12),
                            child: Icon(
                              LucideIcons.shoppingCart,
                              size: 20,
                              color: tokens.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
