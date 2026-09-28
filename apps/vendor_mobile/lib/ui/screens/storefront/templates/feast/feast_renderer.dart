/// Template -- Tide Table. Airy seafood/food-delivery storefront: Home
/// (hamburger header, "Delicious Seafood" heading, pill filters, dish cards
/// whose photo breaks out of the top of the card) -> Product Detail (a
/// large dish photo, an inline quantity stepper, a delivery-time note and a
/// floating dark cart FAB) -> Cart -> Checkout -> Order Created.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../data/storefront_catalog.dart';
import '../../shared/storefront_common.dart';
import 'feast_home.dart';
import '../../shared/storefront_theme.dart';

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
        decoration: BoxDecoration(color: widget.tokens.background),
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
          _ => FeastHome(
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
                    child: StorefrontProductImage(
                      item: item,
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
                    item.description ??
                        'No description provided for this product yet.',
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
                    'RM ${(item.price * qty).toStringAsFixed(2)}',
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
