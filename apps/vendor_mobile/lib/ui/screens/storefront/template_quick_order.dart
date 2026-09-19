/// Template 2 -- Quick Order. Speed-first: Home -> optional Product
/// Customization -> Review Order -> Checkout -> Order Created. Deliberately
/// NOT Browse & Shop with different colours: no category-drill-down, no
/// product detail page for simple items -- quantity is adjustable right on
/// the home grid, and only items that need it open a customization step.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/storefront_catalog.dart';
import 'storefront_common.dart';
import 'storefront_theme.dart';

const _defaultCustomizationGroups = [
  StorefrontVariantGroup('Options', ['Standard', 'Extra']),
];

class QuickOrderPreview extends StatefulWidget {
  const QuickOrderPreview({
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
  State<QuickOrderPreview> createState() => _QuickOrderPreviewState();
}

class _QuickOrderPreviewState extends State<QuickOrderPreview> {
  final _cart = StorefrontCartController();
  final _stack = <StorefrontStep>[const StorefrontStep('home')];
  String activeCategory = 'all';

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
          'customize' => _CustomizeView(
            item: widget.items.firstWhere((i) => i.id == _top.itemId),
            tokens: tokens,
            onBack: _pop,
            onAdd: (variant, qty) {
              _cart.add(widget.items.firstWhere((i) => i.id == _top.itemId), variantSummary: variant, qty: qty);
              _pop();
            },
          ),
          'review' => StorefrontCartView(
            cart: _cart,
            tokens: tokens,
            title: 'Your Order',
            showNote: true,
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
          _ => _QuickHome(
            businessName: widget.businessName,
            items: widget.items,
            categories: widget.categories,
            tokens: tokens,
            cart: _cart,
            active: activeCategory,
            onCategory: (id) => setState(() => activeCategory = id),
            onCustomize: (id) => _push(StorefrontStep('customize', itemId: id)),
            onReview: () => _push(const StorefrontStep('review')),
          ),
        },
      ),
    );
  }
}

class _QuickHome extends StatelessWidget {
  const _QuickHome({
    required this.businessName,
    required this.items,
    required this.categories,
    required this.tokens,
    required this.cart,
    required this.active,
    required this.onCategory,
    required this.onCustomize,
    required this.onReview,
  });

  final String businessName;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;
  final StorefrontThemeTokens tokens;
  final StorefrontCartController cart;
  final String active;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onCustomize;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final visible = active == 'all' ? items : items.where((i) => i.categoryId == active).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: tokens.accentDecoration(radius: 999),
                child: Icon(LucideIcons.store, size: 15, color: tokens.onPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(businessName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                    const Text('Order ahead, skip the wait.', style: TextStyle(fontSize: 10.5, color: StorefrontThemeTokens.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: StorefrontThemeTokens.muted, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(LucideIcons.search, size: 16, color: StorefrontThemeTokens.textSecondary),
              SizedBox(width: 8),
              Text('Search menu...', style: TextStyle(fontSize: 12.5, color: StorefrontThemeTokens.textSecondary)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final c in categories)
                StorefrontCategoryChip(label: c.label, selected: active == c.id, tokens: tokens, onTap: () => onCategory(c.id)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              const Text('Popular Today', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 10),
              for (final item in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: StorefrontThemeTokens.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: StorefrontThemeTokens.border),
                    ),
                    child: Row(
                      children: [
                        StorefrontImagePlaceholder(icon: item.icon, tint: tokens.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                              const SizedBox(height: 3),
                              Text('RM ${item.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: tokens.primary)),
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: cart,
                          builder: (context, _) {
                            if (item.needsCustomization) {
                              return StorefrontBrandButton(
                                label: 'Add',
                                icon: LucideIcons.plus,
                                tokens: tokens,
                                onTap: () => onCustomize(item.id),
                              );
                            }
                            return SizedBox(
                              width: 96,
                              child: StorefrontQtyStepper(
                                qty: cart.qtyOf(item),
                                tokens: tokens,
                                onChanged: (q) {
                                  final current = cart.qtyOf(item);
                                  if (q > current) {
                                    cart.add(item);
                                  } else {
                                    cart.setQty('${item.id}::', q);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: cart,
          builder: (context, _) => cart.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: const BoxDecoration(
                    color: StorefrontThemeTokens.card,
                    border: Border(top: BorderSide(color: StorefrontThemeTokens.border)),
                  ),
                  child: InkWell(
                    onTap: onReview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: tokens.accentDecoration(radius: 12),
                      child: Row(
                        children: [
                          Text('${cart.itemCount} items · RM ${cart.subtotal.toStringAsFixed(2)}',
                              style: TextStyle(color: tokens.onPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                          const Spacer(),
                          Text('Review Order', style: TextStyle(color: tokens.onPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                          Icon(LucideIcons.chevronRight, size: 15, color: tokens.onPrimary),
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

class _CustomizeView extends StatefulWidget {
  const _CustomizeView({
    required this.item,
    required this.tokens,
    required this.onBack,
    required this.onAdd,
  });

  final StorefrontItem item;
  final StorefrontThemeTokens tokens;
  final VoidCallback onBack;
  final void Function(String variantSummary, int qty) onAdd;

  @override
  State<_CustomizeView> createState() => _CustomizeViewState();
}

class _CustomizeViewState extends State<_CustomizeView> {
  late final groups = widget.item.variantGroups.isEmpty ? _defaultCustomizationGroups : widget.item.variantGroups;
  late final Map<String, String> selection = {for (final g in groups) g.label: g.options.first};
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tokens = widget.tokens;
    final summary = selection.entries.map((e) => e.value).join(' · ');
    return Column(
      children: [
        StorefrontBackBar(title: 'Customize', onBack: widget.onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              AspectRatio(
                aspectRatio: 1.4,
                child: StorefrontImagePlaceholder(icon: item.icon, size: double.infinity, radius: 16, tint: tokens.primary),
              ),
              const SizedBox(height: 14),
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 4),
              Text('RM ${item.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: tokens.primary)),
              if (item.description != null) ...[
                const SizedBox(height: 8),
                Text(item.description!, style: const TextStyle(fontSize: 12.5, color: StorefrontThemeTokens.textSecondary)),
              ],
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
              const SizedBox(height: 20),
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
          child: StorefrontBrandButton(
            label: 'Add to Order',
            trailing: 'RM ${(item.price * qty).toStringAsFixed(2)}',
            tokens: tokens,
            onTap: () => widget.onAdd(summary, qty),
          ),
        ),
      ],
    );
  }
}
