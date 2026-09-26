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

import '../../../../../data/storefront_catalog.dart';
import '../../shared/product_art.dart';
import '../../shared/storefront_common.dart';
import 'ritual_home.dart';
import '../../shared/storefront_theme.dart';

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
        decoration: BoxDecoration(color: widget.tokens.background),
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
          _ => RitualHome(
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
    // A Column with the photo area as the flexible Expanded slice and the
    // frosted panel as a normal trailing sibling -- not an Align(
    // bottomCenter) floated inside a Stack. Every other renderer's stage
    // widgets are Columns for exactly this reason: a Column reliably fills
    // and divides the frame under this screen's Center -> ConstrainedBox
    // ancestor, where a bare Stack (or an Align positioned inside one)
    // does not reliably resolve to "pinned to the bottom of the frame" in
    // this app's web renderer -- it rendered pinned to the *top* instead,
    // caught via manual screenshot verification of the new template.
    return Column(
      children: [
        Expanded(
          child: Stack(
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
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: ProductArtView(item.art, accent: tokens.primary),
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
            ],
          ),
        ),
        ClipRRect(
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
                mainAxisSize: MainAxisSize.min,
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
                    'RM ${(item.price * qty).toStringAsFixed(2)}',
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
      ],
    );
  }
}
