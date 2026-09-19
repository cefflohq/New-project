/// Template -- Origin Run. Stark black-and-white athletic-editorial
/// storefront: Home (italic wordmark, a bleeding-out hero card, labelled
/// category tabs, an arrow-button grid) -> Product Detail (angled hero shot
/// over a faint watermark, a vertical size list, a colour-swatch rail and a
/// "Swipe" bag CTA) -> Cart -> Checkout -> Order Created.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/storefront_catalog.dart';
import 'storefront_common.dart';
import 'storefront_theme.dart';

const _originSizes = ['8', '8.5', '9', '9.5', '10'];
const _originSwatches = [
  Color(0xFFE8C93B),
  Color(0xFF2E9E52),
  Color(0xFFD23B3B),
  Color(0xFF2E5FD2),
];

class OriginRunPreview extends StatefulWidget {
  const OriginRunPreview({
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
  State<OriginRunPreview> createState() => _OriginRunPreviewState();
}

class _OriginRunPreviewState extends State<OriginRunPreview> {
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
          'detail' => _OriginDetailView(
            item: widget.items.firstWhere((i) => i.id == _top.itemId),
            tokens: tokens,
            cart: _cart,
            onBack: _pop,
            onBuyNow: () => _push(const StorefrontStep('checkout')),
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
          _ => _OriginHome(
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

class _OriginHome extends StatefulWidget {
  const _OriginHome({
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
  State<_OriginHome> createState() => _OriginHomeState();
}

class _OriginHomeState extends State<_OriginHome> {
  late String active = widget.categories
      .firstWhere((c) => c.id != 'all', orElse: () => widget.categories.first)
      .id;

  @override
  Widget build(BuildContext context) {
    final tabs = widget.categories.where((c) => c.id != 'all').toList();
    final hero = widget.items.first;
    final grid = widget.items.where((i) => i.categoryId == active).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFE3E3E3)),
                  ),
                ),
                child: const Icon(
                  LucideIcons.chevronLeft,
                  size: 15,
                  color: Colors.black38,
                ),
              ),
              const Spacer(),
              Text(
                widget.businessName.toUpperCase(),
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFFB9B9B9),
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: widget.cart,
                builder: (context, _) => InkWell(
                  onTap: widget.onOpenCart,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0xFFE3E3E3)),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          LucideIcons.shoppingBag,
                          size: 15,
                          color: Colors.black,
                        ),
                        if (widget.cart.itemCount > 0)
                          const Positioned(
                            right: 4,
                            top: 4,
                            child: CircleAvatar(
                              radius: 3,
                              backgroundColor: Colors.black,
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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            children: [
              const Text(
                'New Collection',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              ),
              Text(
                '${widget.businessName} Original 2025',
                style: const TextStyle(
                  fontSize: 12,
                  color: StorefrontThemeTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => widget.onOpenItem(hero.id),
                child: SizedBox(
                  height: 130,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 110,
                        padding: const EdgeInsets.fromLTRB(18, 16, 90, 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              hero.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              "Men's shoes",
                              style: TextStyle(
                                fontSize: 10.5,
                                color: StorefrontThemeTokens.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Shop now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: -6,
                        top: 0,
                        bottom: 0,
                        child: Transform.rotate(
                          angle: -0.25,
                          child: Icon(
                            hero.icon,
                            size: 118,
                            color: widget.tokens.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0 ? Colors.black : const Color(0xFFDDDDDD),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (final t in tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 22),
                      child: InkWell(
                        onTap: () => setState(() => active = t.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: active == t.id
                                    ? Colors.black
                                    : const Color(0xFFC7C7C7),
                              ),
                            ),
                            Text(
                              '${widget.items.where((i) => i.categoryId == t.id).length} items',
                              style: const TextStyle(
                                fontSize: 10,
                                color: StorefrontThemeTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
                children: [
                  for (final item in grid)
                    InkWell(
                      onTap: () => widget.onOpenItem(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                            Expanded(
                              child: Icon(
                                item.icon,
                                size: 54,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${item.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const Text(
                                        'Price',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: StorefrontThemeTokens
                                              .textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Icon(
                                    LucideIcons.arrowRight,
                                    size: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

class _OriginDetailView extends StatefulWidget {
  const _OriginDetailView({
    required this.item,
    required this.tokens,
    required this.cart,
    required this.onBack,
    required this.onBuyNow,
  });
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final VoidCallback onBack;
  final VoidCallback onBuyNow;

  @override
  State<_OriginDetailView> createState() => _OriginDetailViewState();
}

class _OriginDetailViewState extends State<_OriginDetailView> {
  String size = _originSizes[2];
  Color swatch = _originSwatches.first;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              InkWell(
                onTap: widget.onBack,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0xFFE3E3E3)),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.chevronLeft,
                    size: 15,
                    color: Colors.black,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(LucideIcons.heart, size: 18, color: Colors.black),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Icon(
                          LucideIcons.footprints,
                          size: 220,
                          color: Colors.black.withValues(alpha: .05),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 12,
                        child: Column(
                          children: [
                            for (final s in _originSizes)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => setState(() => size = s),
                                  child: Container(
                                    width: 40,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: size == s
                                          ? Colors.black
                                          : Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFFE3E3E3),
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      s,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: size == s
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Transform.rotate(
                        angle: -0.35,
                        child: Icon(
                          item.icon,
                          size: 170,
                          color: widget.tokens.primary,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 12,
                        child: Column(
                          children: [
                            for (final c in _originSwatches)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => setState(() => swatch = c),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c,
                                      border: Border.all(
                                        color: swatch == c
                                            ? Colors.black
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const Text(
                              'Color',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: StorefrontThemeTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 11,
                    color: StorefrontThemeTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: InkWell(
            onTap: () {
              widget.cart.add(item, variantSummary: 'Size $size');
              widget.onBuyNow();
            },
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.shoppingBag,
                    size: 17,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Swipe',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  const Text(
                    '>>>',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
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
