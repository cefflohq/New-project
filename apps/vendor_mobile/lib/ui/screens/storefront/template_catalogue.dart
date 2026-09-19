/// Template 3 -- Catalogue. Visual/collection-first: Catalogue Home ->
/// Collection -> Product Grid -> Product Detail -> Cart -> Checkout ->
/// Order Created. Editorial, image-forward, premium -- categories are
/// presented as curated "collections" rather than a browse/search list.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/storefront_catalog.dart';
import 'storefront_common.dart';
import 'storefront_theme.dart';

const _defaultVariantGroups = [
  StorefrontVariantGroup('Option', ['Standard', 'Premium']),
];

class CataloguePreview extends StatefulWidget {
  const CataloguePreview({
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
  State<CataloguePreview> createState() => _CataloguePreviewState();
}

class _CataloguePreviewState extends State<CataloguePreview> {
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
          'collection' => _CollectionView(
            categoryId: _top.categoryId!,
            categories: widget.categories,
            items: widget.items,
            tokens: tokens,
            cart: _cart,
            onBack: _pop,
            onOpenItem: (id) => _push(StorefrontStep('detail', itemId: id)),
            onOpenCart: () => _push(const StorefrontStep('cart')),
          ),
          'detail' => _CatalogueDetailView(
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
          _ => _CatalogueHome(
            businessName: widget.businessName,
            items: widget.items,
            categories: widget.categories,
            tokens: tokens,
            cart: _cart,
            onOpenCollection: (id) => _push(StorefrontStep('collection', categoryId: id)),
            onOpenCart: () => _push(const StorefrontStep('cart')),
          ),
        },
      ),
    );
  }
}

class _CatalogueHome extends StatelessWidget {
  const _CatalogueHome({
    required this.businessName,
    required this.items,
    required this.categories,
    required this.tokens,
    required this.cart,
    required this.onOpenCollection,
    required this.onOpenCart,
  });

  final String businessName;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final ValueChanged<String> onOpenCollection;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final collections = categories.where((c) => c.id != 'all').toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Text(businessName.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: .5)),
              const Spacer(),
              const Icon(LucideIcons.search, size: 19, color: StorefrontThemeTokens.textSecondary),
              const SizedBox(width: 14),
              AnimatedBuilder(
                animation: cart,
                builder: (context, _) => InkWell(
                  onTap: onOpenCart,
                  child: Badge(
                    isLabelVisible: cart.itemCount > 0,
                    label: Text('${cart.itemCount}'),
                    backgroundColor: tokens.primary,
                    child: const Icon(LucideIcons.shoppingCart, size: 19, color: StorefrontThemeTokens.textPrimary),
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
              AspectRatio(
                aspectRatio: 1.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: StorefrontThemeTokens.muted,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Icon(LucideIcons.image, size: 44, color: StorefrontThemeTokens.textSecondary.withValues(alpha: .35)),
                      ),
                      Positioned(
                        left: 18,
                        bottom: 18,
                        right: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Better spaces,\nbrighter days.',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21, height: 1.15, color: StorefrontThemeTokens.textPrimary),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: tokens.accentDecoration(radius: 999),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Explore Collection', style: TextStyle(color: tokens.onPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
                                  Icon(LucideIcons.chevronRight, size: 13, color: tokens.onPrimary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text('Shop by Collection', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  for (final c in collections)
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onOpenCollection(c.id),
                      child: Container(
                        decoration: BoxDecoration(color: StorefrontThemeTokens.muted, borderRadius: BorderRadius.circular(14)),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Icon(c.icon, size: 30, color: tokens.primary.withValues(alpha: .5)),
                            ),
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  Text(
                                    '${items.where((i) => i.categoryId == c.id).length} products',
                                    style: const TextStyle(fontSize: 10.5, color: StorefrontThemeTokens.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: tokens.accentDecoration(radius: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEW', style: TextStyle(color: tokens.onPrimary.withValues(alpha: .75), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text('The curated collection.', style: TextStyle(color: tokens.onPrimary, fontWeight: FontWeight.w800, fontSize: 14.5)),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, color: tokens.onPrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollectionView extends StatefulWidget {
  const _CollectionView({
    required this.categoryId,
    required this.categories,
    required this.items,
    required this.tokens,
    required this.cart,
    required this.onBack,
    required this.onOpenItem,
    required this.onOpenCart,
  });

  final String categoryId;
  final List<StorefrontCategory> categories;
  final List<StorefrontItem> items;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenItem;
  final VoidCallback onOpenCart;

  @override
  State<_CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<_CollectionView> {
  final wishlisted = <String>{};

  @override
  Widget build(BuildContext context) {
    final category = widget.categories.firstWhere((c) => c.id == widget.categoryId,
        orElse: () => widget.categories.first);
    final visible = widget.items.where((i) => i.categoryId == widget.categoryId).toList();
    return Column(
      children: [
        StorefrontBackBar(
          title: category.label,
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
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: StorefrontThemeTokens.muted, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(LucideIcons.search, size: 16, color: StorefrontThemeTokens.textSecondary),
                    const SizedBox(width: 8),
                    Text('Search in ${category.label}...', style: const TextStyle(fontSize: 12, color: StorefrontThemeTokens.textSecondary)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: StorefrontThemeTokens.muted, borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.package, size: 17, color: StorefrontThemeTokens.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('No products in this collection yet.', style: TextStyle(color: StorefrontThemeTokens.textSecondary)))
              : GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.7,
                  children: [
                    for (final item in visible)
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => widget.onOpenItem(item.id),
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
                                    aspectRatio: 1.1,
                                    child: StorefrontImagePlaceholder(icon: item.icon, size: double.infinity, tint: widget.tokens.primary),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: InkWell(
                                      onTap: () => setState(() => wishlisted.contains(item.id)
                                          ? wishlisted.remove(item.id)
                                          : wishlisted.add(item.id)),
                                      child: Icon(
                                        LucideIcons.heart,
                                        size: 16,
                                        color: wishlisted.contains(item.id) ? widget.tokens.primary : StorefrontThemeTokens.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                              if (item.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(item.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10.5, color: StorefrontThemeTokens.textSecondary)),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('RM ${item.price.toStringAsFixed(2)}',
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: widget.tokens.primary)),
                                  ),
                                  InkWell(
                                    onTap: () => widget.cart.add(item),
                                    child: Icon(LucideIcons.shoppingCart, size: 15, color: widget.tokens.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CatalogueDetailView extends StatefulWidget {
  const _CatalogueDetailView({required this.item, required this.tokens, required this.cart, required this.onBack});
  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final VoidCallback onBack;

  @override
  State<_CatalogueDetailView> createState() => _CatalogueDetailViewState();
}

class _CatalogueDetailViewState extends State<_CatalogueDetailView> {
  int qty = 1;
  late final groups = widget.item.variantGroups.isEmpty ? _defaultVariantGroups : widget.item.variantGroups;
  late final Map<String, String> selection = {for (final g in groups) g.label: g.options.first};

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
                aspectRatio: 1.05,
                child: StorefrontImagePlaceholder(icon: item.icon, size: double.infinity, radius: 18, tint: tokens.primary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => Container(
                    width: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: i == 0 ? tokens.primary : StorefrontThemeTokens.border, width: i == 0 ? 1.6 : 1),
                    ),
                    child: StorefrontImagePlaceholder(icon: item.icon, size: double.infinity, radius: 9, tint: tokens.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('RM ${item.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: tokens.primary)),
                  const Spacer(),
                  if (item.rating != null) ...[
                    const Icon(LucideIcons.star, size: 13, color: Color(0xFFE0A72B)),
                    const SizedBox(width: 3),
                    Text('${item.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.description ?? 'No description provided for this product yet.',
                style: const TextStyle(fontSize: 13, color: StorefrontThemeTokens.textSecondary, height: 1.4),
              ),
              for (final g in groups) ...[
                const SizedBox(height: 18),
                Text(g.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final opt in g.options)
                      StorefrontCategoryChip(
                        label: opt,
                        selected: selection[g.label] == opt,
                        tokens: tokens,
                        onTap: () => setState(() => selection[g.label] = opt),
                      ),
                  ],
                ),
              ],
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
                    widget.cart.add(item, qty: qty, variantSummary: selection.values.join(' · '));
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
                    widget.cart.add(item, qty: qty, variantSummary: selection.values.join(' · '));
                    widget.onBack();
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
