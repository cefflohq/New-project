/// Template -- Discover Market. Electronics-marketplace storefront built
/// around a persistent bottom tab bar (Home / Search / Favorites /
/// Profile) -- the one navigational pattern none of the other renderers
/// use. Home -> (Search | Favorites | Profile) tabs, with Product Detail ->
/// Cart -> Checkout -> Order Created pushed as full-screen overlays that
/// temporarily hide the tab bar.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/storefront_catalog.dart';
import 'storefront_common.dart';
import 'storefront_theme.dart';

enum _MarketTab { home, search, favorites, profile }

class DiscoverMarketPreview extends StatefulWidget {
  const DiscoverMarketPreview({
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
  State<DiscoverMarketPreview> createState() => _DiscoverMarketPreviewState();
}

class _DiscoverMarketPreviewState extends State<DiscoverMarketPreview> {
  final _cart = StorefrontCartController();
  final _stack = <StorefrontStep>[const StorefrontStep('tabs')];
  _MarketTab _tab = _MarketTab.home;
  final _favorites = <String>{};
  String _activeCategory = 'all';

  StorefrontStep get _top => _stack.last;
  void _push(StorefrontStep s) => setState(() => _stack.add(s));
  void _pop() => setState(() => _stack.length > 1 ? _stack.removeLast() : null);
  void _toggleFavorite(String id) => setState(
    () => _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id),
  );

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
          'detail' => _MarketDetailView(
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
                  ..add(const StorefrontStep('tabs')),
              );
            },
          ),
          _ => Column(
            children: [
              Expanded(
                child: switch (_tab) {
                  _MarketTab.home => _MarketHome(
                    businessName: widget.businessName,
                    items: widget.items,
                    categories: widget.categories,
                    tokens: tokens,
                    cart: _cart,
                    favorites: _favorites,
                    active: _activeCategory,
                    onCategory: (id) => setState(() => _activeCategory = id),
                    onOpenItem: (id) =>
                        _push(StorefrontStep('detail', itemId: id)),
                    onOpenCart: () => _push(const StorefrontStep('cart')),
                    onToggleFavorite: _toggleFavorite,
                  ),
                  _MarketTab.search => _MarketSearch(
                    items: widget.items,
                    tokens: tokens,
                    onOpenItem: (id) =>
                        _push(StorefrontStep('detail', itemId: id)),
                  ),
                  _MarketTab.favorites => _MarketFavorites(
                    items: widget.items
                        .where((i) => _favorites.contains(i.id))
                        .toList(),
                    tokens: tokens,
                    onOpenItem: (id) =>
                        _push(StorefrontStep('detail', itemId: id)),
                  ),
                  _MarketTab.profile => _MarketProfile(
                    businessName: widget.businessName,
                    tokens: tokens,
                  ),
                },
              ),
              _MarketTabBar(
                tab: _tab,
                tokens: tokens,
                onSelect: (t) => setState(() => _tab = t),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _MarketHome extends StatelessWidget {
  const _MarketHome({
    required this.businessName,
    required this.items,
    required this.categories,
    required this.tokens,
    required this.cart,
    required this.favorites,
    required this.active,
    required this.onCategory,
    required this.onOpenItem,
    required this.onOpenCart,
    required this.onToggleFavorite,
  });

  final String businessName;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final Set<String> favorites;
  final String active;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onOpenItem;
  final VoidCallback onOpenCart;
  final ValueChanged<String> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final visible = active == 'all'
        ? items
        : items.where((i) => i.categoryId == active).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Discover',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
              ),
            ),
            AnimatedBuilder(
              animation: cart,
              builder: (context, _) => InkWell(
                onTap: onOpenCart,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: StorefrontThemeTokens.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: StorefrontThemeTokens.border),
                      ),
                      child: const Icon(
                        LucideIcons.shoppingBag,
                        size: 16,
                        color: StorefrontThemeTokens.textPrimary,
                      ),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: tokens.accentDecoration(radius: 999),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: tokens.onPrimary,
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
        const SizedBox(height: 14),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: StorefrontThemeTokens.muted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.search,
                size: 16,
                color: StorefrontThemeTokens.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Search',
                style: TextStyle(
                  fontSize: 13,
                  color: StorefrontThemeTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: tokens.accentDecoration(radius: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clearance\nSales',
                      style: TextStyle(
                        color: tokens.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.onPrimary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.percent,
                            size: 12,
                            color: tokens.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Up to 50%',
                            style: TextStyle(
                              color: tokens.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.smartphone,
                size: 46,
                color: tokens.onPrimary.withValues(alpha: .55),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'Categories',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const Spacer(),
            Text(
              'See all',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: tokens.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in categories)
                StorefrontCategoryChip(
                  label: c.label,
                  selected: active == c.id,
                  tokens: tokens,
                  onTap: () => onCategory(c.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.78,
          children: [
            for (final item in visible)
              _MarketProductCard(
                item: item,
                tokens: tokens,
                favored: favorites.contains(item.id),
                onTap: () => onOpenItem(item.id),
                onFavorite: () => onToggleFavorite(item.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _MarketProductCard extends StatelessWidget {
  const _MarketProductCard({
    required this.item,
    required this.tokens,
    required this.favored,
    required this.onTap,
    required this.onFavorite,
  });
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final bool favored;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

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
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: StorefrontImagePlaceholder(
                  icon: item.icon,
                  size: double.infinity,
                  tint: tokens.primary,
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: InkWell(
                  onTap: onFavorite,
                  child: Icon(
                    LucideIcons.heart,
                    size: 16,
                    color: favored
                        ? tokens.primary
                        : StorefrontThemeTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(LucideIcons.star, size: 11, color: Color(0xFFE0A72B)),
              const SizedBox(width: 3),
              Text(
                '${item.rating ?? 4.8}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '\$${item.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: tokens.primary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MarketSearch extends StatefulWidget {
  const _MarketSearch({
    required this.items,
    required this.tokens,
    required this.onOpenItem,
  });
  final List<StorefrontItem> items;
  final StorefrontThemeTokens tokens;
  final ValueChanged<String> onOpenItem;

  @override
  State<_MarketSearch> createState() => _MarketSearchState();
}

class _MarketSearchState extends State<_MarketSearch> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final results = query.isEmpty
        ? widget.items
        : widget.items
              .where((i) => i.name.toLowerCase().contains(query))
              .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 14),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: StorefrontThemeTokens.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.search,
                  size: 16,
                  color: StorefrontThemeTokens.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: StorefrontThemeTokens.textSecondary,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              children: [
                for (final item in results)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: StorefrontImagePlaceholder(
                      icon: item.icon,
                      tint: widget.tokens.primary,
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                    onTap: () => widget.onOpenItem(item.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketFavorites extends StatelessWidget {
  const _MarketFavorites({
    required this.items,
    required this.tokens,
    required this.onOpenItem,
  });
  final List<StorefrontItem> items;
  final StorefrontThemeTokens tokens;
  final ValueChanged<String> onOpenItem;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'No favorites yet -- tap the heart on a product.',
                    style: TextStyle(
                      color: StorefrontThemeTokens.textSecondary,
                    ),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.78,
                  children: [
                    for (final item in items)
                      _MarketProductCard(
                        item: item,
                        tokens: tokens,
                        favored: true,
                        onTap: () => onOpenItem(item.id),
                        onFavorite: () {},
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}

class _MarketProfile extends StatelessWidget {
  const _MarketProfile({required this.businessName, required this.tokens});
  final String businessName;
  final StorefrontThemeTokens tokens;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
    children: [
      Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: tokens.accentDecoration(radius: 36),
          alignment: Alignment.center,
          child: Icon(LucideIcons.user, size: 30, color: tokens.onPrimary),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          businessName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      const SizedBox(height: 24),
      for (final row in const [
        (LucideIcons.package, 'My Orders'),
        (LucideIcons.mapPin, 'Delivery Addresses'),
        (LucideIcons.tag, 'Coupons & Offers'),
        (LucideIcons.user, 'Account Settings'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: StorefrontThemeTokens.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  row.$1,
                  size: 17,
                  color: StorefrontThemeTokens.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row.$2,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 15,
                  color: StorefrontThemeTokens.textSecondary,
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _MarketTabBar extends StatelessWidget {
  const _MarketTabBar({
    required this.tab,
    required this.tokens,
    required this.onSelect,
  });
  final _MarketTab tab;
  final StorefrontThemeTokens tokens;
  final ValueChanged<_MarketTab> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      color: StorefrontThemeTokens.card,
      border: Border(top: BorderSide(color: StorefrontThemeTokens.border)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _tabItem(LucideIcons.home, 'Home', _MarketTab.home),
        _tabItem(LucideIcons.search, 'Search', _MarketTab.search),
        _tabItem(LucideIcons.heart, 'Favorites', _MarketTab.favorites),
        _tabItem(LucideIcons.user, 'Profile', _MarketTab.profile),
      ],
    ),
  );

  Widget _tabItem(IconData icon, String label, _MarketTab value) {
    final selected = tab == value;
    final color = selected
        ? tokens.primary
        : StorefrontThemeTokens.textSecondary;
    return InkWell(
      onTap: () => onSelect(value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketDetailView extends StatefulWidget {
  const _MarketDetailView({
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
  State<_MarketDetailView> createState() => _MarketDetailViewState();
}

class _MarketDetailViewState extends State<_MarketDetailView> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tokens = widget.tokens;
    return Column(
      children: [
        StorefrontBackBar(title: 'Product Detail', onBack: widget.onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: StorefrontImagePlaceholder(
                  icon: item.icon,
                  size: double.infinity,
                  radius: 18,
                  tint: tokens.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    LucideIcons.star,
                    size: 14,
                    color: Color(0xFFE0A72B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.rating ?? 4.8} rating',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: StorefrontThemeTokens.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: tokens.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description ??
                    'No description provided for this product yet.',
                style: const TextStyle(
                  fontSize: 13,
                  color: StorefrontThemeTokens.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
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
          child: StorefrontBrandButton(
            label: 'Add to Cart',
            icon: LucideIcons.shoppingBag,
            tokens: tokens,
            onTap: () {
              widget.cart.add(item, qty: qty);
              widget.onBack();
            },
          ),
        ),
      ],
    );
  }
}
