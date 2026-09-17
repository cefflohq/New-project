/// Template 1 -- Browse & Shop. Discovery-first: Home/Browse -> Category ->
/// Product listing -> Product Detail -> Cart -> Checkout -> Order Created.
/// Clean, modern, retail-oriented. Renders whatever vendor data/branding the
/// adapter supplies -- no vendor content is hardcoded here.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/storefront_catalog.dart';
import 'storefront_common.dart';
import 'storefront_theme.dart';

class BrowseShopPreview extends StatefulWidget {
  const BrowseShopPreview({
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
  State<BrowseShopPreview> createState() => _BrowseShopPreviewState();
}

class _BrowseShopPreviewState extends State<BrowseShopPreview> {
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
          'detail' => _DetailView(
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
              setState(() => _stack.add(StorefrontStep('confirmed', itemId: ref)));
            },
          ),
          'confirmed' => StorefrontOrderCreatedView(
            tokens: tokens,
            orderRef: _top.itemId ?? '',
            onDone: () {
              _cart.clear();
              setState(() => _stack
                ..clear()
                ..add(const StorefrontStep('home')));
            },
          ),
          _ => _HomeView(
            businessName: widget.businessName,
            items: widget.items,
            categories: widget.categories,
            tokens: tokens,
            cart: _cart,
            onOpenCategory: (id) => _push(StorefrontStep('category', categoryId: id)),
            onOpenItem: (id) => _push(StorefrontStep('detail', itemId: id)),
            onOpenCart: () => _push(const StorefrontStep('cart')),
          ),
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.businessName,
    required this.tokens,
    required this.cart,
    required this.onOpenCart,
  });

  final String businessName;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: tokens.accentDecoration(radius: 8),
          child: Icon(LucideIcons.store, size: 15, color: tokens.onPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            businessName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        const Icon(LucideIcons.search, size: 19, color: StorefrontThemeTokens.textSecondary),
        const SizedBox(width: 14),
        AnimatedBuilder(
          animation: cart,
          builder: (context, _) => InkWell(
            onTap: onOpenCart,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(LucideIcons.shoppingCart, size: 20, color: StorefrontThemeTokens.textPrimary),
                if (cart.itemCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: tokens.accentDecoration(radius: 999),
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      child: Text(
                        '${cart.itemCount}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: tokens.onPrimary),
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

class _HomeView extends StatelessWidget {
  const _HomeView({
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
    final featured = items.take(4).toList();
    final shopCategories = categories.where((c) => c.id != 'all').toList();
    return Column(
      children: [
        _TopBar(businessName: businessName, tokens: tokens, cart: cart, onOpenCart: onOpenCart),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: tokens.accentDecoration(radius: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Everything you need,\nmade simple.',
                      style: TextStyle(color: tokens.onPrimary, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Quality picks for you and your family.',
                      style: TextStyle(color: tokens.onPrimary.withValues(alpha: .85), fontSize: 12.5),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(color: tokens.onPrimary, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Shop Now', style: TextStyle(color: tokens.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.chevronRight, size: 14, color: tokens.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Shop by Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const Spacer(),
                  Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tokens.primary)),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 8,
                childAspectRatio: 0.78,
                children: [
                  for (final c in shopCategories.take(8))
                    InkWell(
                      onTap: () => onOpenCategory(c.id),
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: tokens.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(c.icon, size: 20, color: tokens.primary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Text('Featured Products', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const Spacer(),
                  Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tokens.primary)),
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
                  for (final item in featured)
                    _ProductCard(item: item, tokens: tokens, onTap: () => onOpenItem(item.id)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.tokens, required this.onTap});
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
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: StorefrontImagePlaceholder(icon: item.icon, size: double.infinity, tint: tokens.primary),
          ),
          const SizedBox(height: 8),
          Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('RM ${item.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: tokens.primary)),
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
                  child: const Icon(LucideIcons.shoppingCart, size: 19),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: StorefrontThemeTokens.muted, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(LucideIcons.search, size: 16, color: StorefrontThemeTokens.textSecondary),
              SizedBox(width: 8),
              Text('Search products...', style: TextStyle(fontSize: 12.5, color: StorefrontThemeTokens.textSecondary)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              for (final item in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => widget.onOpenItem(item.id),
                    child: Row(
                      children: [
                        StorefrontImagePlaceholder(icon: item.icon, tint: widget.tokens.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                              if (item.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    item.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, color: StorefrontThemeTokens.textSecondary),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text('RM ${item.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: widget.cart,
                          builder: (context, _) => StorefrontQtyStepper(
                            qty: widget.cart.qtyOf(item),
                            tokens: widget.tokens,
                            onChanged: (q) {
                              final current = widget.cart.qtyOf(item);
                              if (q > current) {
                                widget.cart.add(item);
                              } else {
                                widget.cart.setQty('${item.id}::', q);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: widget.cart,
          builder: (context, _) => widget.cart.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: const BoxDecoration(
                    color: StorefrontThemeTokens.card,
                    border: Border(top: BorderSide(color: StorefrontThemeTokens.border)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${widget.cart.itemCount} items', style: const TextStyle(fontSize: 11.5, color: StorefrontThemeTokens.textSecondary)),
                          Text('RM ${widget.cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 150,
                        child: StorefrontBrandButton(
                          label: 'View Cart',
                          icon: LucideIcons.chevronRight,
                          tokens: widget.tokens,
                          onTap: widget.onOpenCart,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({
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
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tokens = widget.tokens;
    return Column(
      children: [
        StorefrontBackBar(title: 'Product Detail', onBack: widget.onBack, trailing: const [
          Icon(LucideIcons.heart, size: 19, color: StorefrontThemeTokens.textSecondary),
        ]),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: StorefrontImagePlaceholder(icon: item.icon, size: double.infinity, radius: 18, tint: tokens.primary),
              ),
              const SizedBox(height: 16),
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('RM ${item.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: tokens.primary)),
                  const Spacer(),
                  Icon(item.inStock ? LucideIcons.check : LucideIcons.x, size: 14, color: item.inStock ? Colors.green : Colors.red),
                  const SizedBox(width: 4),
                  Text(item.inStock ? 'In stock' : 'Out of stock', style: const TextStyle(fontSize: 12, color: StorefrontThemeTokens.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.description ?? 'No description provided for this product yet.',
                style: const TextStyle(fontSize: 13, color: StorefrontThemeTokens.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const Spacer(),
                  StorefrontQtyStepper(qty: qty, tokens: tokens, onChanged: (q) => setState(() => qty = q < 1 ? 1 : q)),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: StorefrontThemeTokens.card,
            border: Border(top: BorderSide(color: StorefrontThemeTokens.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: StorefrontBrandButton(
                  label: 'Add to Cart',
                  outlined: true,
                  tokens: tokens,
                  onTap: () {
                    widget.cart.add(item, qty: qty);
                    widget.onBack();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StorefrontBrandButton(
                  label: 'Buy Now',
                  tokens: tokens,
                  onTap: () {
                    widget.cart.add(item, qty: qty);
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
