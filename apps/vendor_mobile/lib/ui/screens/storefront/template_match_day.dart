/// Template -- Match Day. Sports-kit storefront built from a dark,
/// diagonal-split product-detail treatment paired with a clean white
/// browse: Home (club-badge category row + Popular grid) -> Category ->
/// Product Detail (diagonal navy/accent split, size run, No/Yes action) ->
/// Cart -> Checkout -> Order Created. Deliberately NOT Browse & Shop with
/// different colours: the detail screen's dark diagonal split and size-run
/// selector are the genuinely distinct composition this template exists for.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/storefront_catalog.dart';
import 'storefront_common.dart';
import 'storefront_theme.dart';

const _defaultSizeRun = ['S', 'M', 'L', 'XL', 'XXL'];

/// Diagonal cut used by the product-detail hero background -- a lightweight
/// stand-in for the reference's angled two-tone kit-shop split.
class _DiagonalClipper extends CustomClipper<Path> {
  const _DiagonalClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.46, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width * 0.58, size.height)
    ..close();

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class MatchDayPreview extends StatefulWidget {
  const MatchDayPreview({
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
  State<MatchDayPreview> createState() => _MatchDayPreviewState();
}

class _MatchDayPreviewState extends State<MatchDayPreview> {
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
          'category' => _CategoryView(
            categoryId: _top.categoryId,
            items: widget.items,
            categories: widget.categories,
            tokens: tokens,
            cart: _cart,
            onBack: _pop,
            onOpenItem: (id) => _push(StorefrontStep('detail', itemId: id)),
            onOpenCart: () => _push(const StorefrontStep('cart')),
          ),
          'detail' => _KitDetailView(
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
          _ => _KitHome(
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

class _MatchTopBar extends StatelessWidget {
  const _MatchTopBar({
    required this.businessName,
    required this.tokens,
    required this.cart,
    required this.onOpenCart,
    this.dark = false,
  });

  final String businessName;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final VoidCallback onOpenCart;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : StorefrontThemeTokens.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Icon(LucideIcons.grid3x3, size: 18, color: fg.withValues(alpha: .8)),
          const Spacer(),
          Text(
            businessName.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 1.2,
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
                  Icon(LucideIcons.shoppingBag, size: 19, color: fg),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE23B3B),
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
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
    );
  }
}

class _KitHome extends StatelessWidget {
  const _KitHome({
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
    final popular = items.take(3).toList();
    return Column(
      children: [
        _MatchTopBar(
          businessName: businessName,
          tokens: tokens,
          cart: cart,
          onOpenCart: onOpenCart,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              SizedBox(
                height: 74,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final c in shopCategories)
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: InkWell(
                          onTap: () => onOpenCategory(c.id),
                          borderRadius: BorderRadius.circular(999),
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: StorefrontThemeTokens.border,
                                    width: 1.4,
                                  ),
                                ),
                                child: Icon(
                                  LucideIcons.shield,
                                  size: 20,
                                  color: tokens.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Popular',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final item in popular)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _KitPopularCard(
                          item: item,
                          tokens: tokens,
                          onTap: () => onOpenItem(item.id),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Categories',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  for (final c in shopCategories)
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onOpenCategory(c.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: StorefrontThemeTokens.muted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(c.icon, size: 24, color: tokens.primary),
                            const SizedBox(height: 8),
                            Text(
                              c.label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
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

class _KitPopularCard extends StatelessWidget {
  const _KitPopularCard({
    required this.item,
    required this.tokens,
    required this.onTap,
  });
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: StorefrontThemeTokens.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StorefrontThemeTokens.border),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: StorefrontImagePlaceholder(
                  icon: item.icon,
                  size: double.infinity,
                  tint: tokens.primary,
                ),
              ),
              const Positioned(
                right: 2,
                top: 2,
                child: Icon(LucideIcons.heart, size: 13, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'RM ${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Add',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: tokens.onPrimary,
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

class _CategoryView extends StatefulWidget {
  const _CategoryView({
    required this.categoryId,
    required this.items,
    required this.categories,
    required this.tokens,
    required this.cart,
    required this.onBack,
    required this.onOpenItem,
    required this.onOpenCart,
  });

  final String? categoryId;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenItem;
  final VoidCallback onOpenCart;

  @override
  State<_CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<_CategoryView> {
  late String active = widget.categoryId ?? 'all';

  @override
  Widget build(BuildContext context) {
    final visible = active == 'all'
        ? widget.items
        : widget.items.where((i) => i.categoryId == active).toList();
    return Column(
      children: [
        StorefrontBackBar(
          title: 'Category & Products',
          onBack: widget.onBack,
          trailing: [
            AnimatedBuilder(
              animation: widget.cart,
              builder: (context, _) => IconButton(
                onPressed: widget.onOpenCart,
                icon: Badge(
                  isLabelVisible: widget.cart.itemCount > 0,
                  label: Text('${widget.cart.itemCount}'),
                  backgroundColor: widget.tokens.primary,
                  child: const Icon(LucideIcons.shoppingBag, size: 19),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final c in widget.categories)
                StorefrontCategoryChip(
                  label: c.label,
                  selected: active == c.id,
                  tokens: widget.tokens,
                  onTap: () => setState(() => active = c.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.72,
            children: [
              for (final item in visible)
                _KitPopularCard(
                  item: item,
                  tokens: widget.tokens,
                  onTap: () => widget.onOpenItem(item.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KitDetailView extends StatefulWidget {
  const _KitDetailView({
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
  State<_KitDetailView> createState() => _KitDetailViewState();
}

class _KitDetailViewState extends State<_KitDetailView> {
  late List<String> sizes = widget.item.variantGroups.isNotEmpty
      ? widget.item.variantGroups.first.options
      : _defaultSizeRun;
  late String size = sizes.length > 2 ? sizes[2] : sizes.first;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tokens = widget.tokens;
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF17233D)),
              ),
              ClipPath(
                clipper: const _DiagonalClipper(),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: tokens.secondary),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MatchTopBar(
                      businessName: item.categoryId.toUpperCase(),
                      tokens: tokens,
                      cart: widget.cart,
                      onOpenCart: widget.onBack,
                      dark: true,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            Icon(
                              LucideIcons.shield,
                              size: 26,
                              color: Colors.white.withValues(alpha: .85),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.categoryId.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF223454),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                padding: const EdgeInsets.all(18),
                                child: StorefrontImagePlaceholder(
                                  icon: item.icon,
                                  size: double.infinity,
                                  radius: 16,
                                  tint: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                4,
                                (i) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: i == 0 ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: i == 0 ? .95 : .4,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'RM ${item.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    for (final s in sizes)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: InkWell(
                                          onTap: () => setState(() => size = s),
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: size == s
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: .6,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              s,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: size == s
                                                    ? const Color(0xFF17233D)
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: StorefrontThemeTokens.card,
            border: Border(
              top: BorderSide(color: StorefrontThemeTokens.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: StorefrontThemeTokens.border,
                        width: 1.4,
                      ),
                      foregroundColor: StorefrontThemeTokens.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'No',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StorefrontBrandButton(
                  label: 'Yes -- Buy Now',
                  tokens: tokens,
                  onTap: () {
                    widget.cart.add(item, variantSummary: 'Size $size');
                    widget.onBuyNow();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
