/// Shared commerce primitives reused by all 3 storefront templates.
///
/// Per spec, Browse & Shop / Quick Order / Catalogue must feel genuinely
/// different up through product selection, but they converge on one cart,
/// one checkout and one order-confirmation flow -- built once, here, instead
/// of three separate commerce engines. Everything in this file is
/// preview/prototype state: there is no payment gateway, no real charge, and
/// no parallel order backend. `StorefrontCartController` lives only for the
/// lifetime of a single preview session and is never written back to
/// canonical order data.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/storefront_catalog.dart';
import 'storefront_theme.dart';

const double kStorefrontDeliveryFee = 6.00;

/// Client-side mock order reference -- there is no order backend behind
/// this preview, so nothing here is a real order id.
String generateStorefrontOrderRef() {
  final n = DateTime.now().millisecondsSinceEpoch % 1000000;
  return 'SF-${n.toString().padLeft(6, '0')}';
}

/// A single step in a template's local, in-preview navigation stack. Kept
/// local to each template (not a [VRoute]) since these are illustrative
/// customer-facing steps inside one Preview, not vendor app screens in the
/// canonical route inventory.
class StorefrontStep {
  const StorefrontStep(this.stage, {this.categoryId, this.itemId});
  final String stage;
  final String? categoryId;
  final String? itemId;
}

class StorefrontCartLine {
  StorefrontCartLine({
    required this.item,
    this.qty = 1,
    this.variantSummary,
  });

  final StorefrontItem item;
  int qty;
  final String? variantSummary;

  String get key => '${item.id}::${variantSummary ?? ''}';
  num get lineTotal => item.price * qty;
}

/// Session-local cart state. Not persisted, not backend-wired -- a
/// deliberately isolated prototype-payment boundary (spec: "no real payment
/// backend, no order backend").
class StorefrontCartController extends ChangeNotifier {
  final Map<String, StorefrontCartLine> _lines = {};

  List<StorefrontCartLine> get lines => _lines.values.toList(growable: false);
  int get itemCount => _lines.values.fold(0, (sum, l) => sum + l.qty);
  num get subtotal => _lines.values.fold<num>(0, (sum, l) => sum + l.lineTotal);
  num get deliveryFee => _lines.isEmpty ? 0 : kStorefrontDeliveryFee;
  num get total => subtotal + deliveryFee;
  bool get isEmpty => _lines.isEmpty;

  int qtyOf(StorefrontItem item, {String? variantSummary}) {
    final key = '${item.id}::${variantSummary ?? ''}';
    return _lines[key]?.qty ?? 0;
  }

  void add(StorefrontItem item, {String? variantSummary, int qty = 1}) {
    final key = '${item.id}::${variantSummary ?? ''}';
    final existing = _lines[key];
    if (existing != null) {
      existing.qty += qty;
    } else {
      _lines[key] = StorefrontCartLine(
        item: item,
        qty: qty,
        variantSummary: variantSummary,
      );
    }
    notifyListeners();
  }

  void setQty(String key, int qty) {
    if (qty <= 0) {
      _lines.remove(key);
    } else {
      _lines[key]?.qty = qty;
    }
    notifyListeners();
  }

  void remove(String key) {
    _lines.remove(key);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}

// --------------------------------------------------------- shared building blocks

/// Brand-coloured CTA. Distinct from the vendor app's [CefButton] (which is
/// always CEFFLO-yellow) because this button renders *inside the customer
/// preview* and must react to the vendor's chosen brand colour.
class StorefrontBrandButton extends StatelessWidget {
  const StorefrontBrandButton({
    super.key,
    required this.label,
    required this.tokens,
    this.onTap,
    this.icon,
    this.outlined = false,
    this.trailing,
  });

  final String label;
  final StorefrontThemeTokens tokens;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool outlined;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: tokens.primary, width: 1.4),
            foregroundColor: tokens.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _label(),
        ),
      );
    }
    return Container(
      height: 48,
      decoration: tokens.accentDecoration(radius: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(
                color: tokens.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
              child: _label(iconColor: tokens.onPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label({Color? iconColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 8),
      ],
      Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      if (trailing != null) ...[
        const SizedBox(width: 8),
        Text(trailing!),
      ],
    ],
  );
}

class StorefrontQtyStepper extends StatelessWidget {
  const StorefrontQtyStepper({
    super.key,
    required this.qty,
    required this.onChanged,
    required this.tokens,
    this.compact = false,
  });

  final int qty;
  final ValueChanged<int> onChanged;
  final StorefrontThemeTokens tokens;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 26.0 : 32.0;
    Widget btn(IconData icon, VoidCallback onTap, {bool filled = false}) =>
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? tokens.primary : StorefrontThemeTokens.muted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 13 : 15,
              color: filled ? tokens.onPrimary : StorefrontThemeTokens.textPrimary,
            ),
          ),
        );
    if (qty <= 0) {
      return btn(LucideIcons.plus, () => onChanged(1), filled: true);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(LucideIcons.minus, () => onChanged(qty - 1)),
        SizedBox(
          width: compact ? 22 : 28,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ),
        btn(LucideIcons.plus, () => onChanged(qty + 1), filled: true),
      ],
    );
  }
}

/// Flat placeholder image tile (no network images in a mock/fixture data
/// path) keyed off the item's icon, tinted by brand accent so it still reads
/// as "on brand" without touching neutral surfaces.
class StorefrontImagePlaceholder extends StatelessWidget {
  const StorefrontImagePlaceholder({
    super.key,
    required this.icon,
    this.size = 56,
    this.radius = 12,
    this.tint,
  });

  final IconData icon;
  final double size;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: (tint ?? StorefrontThemeTokens.textSecondary).withValues(alpha: .1),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Icon(icon, size: size * 0.42, color: tint ?? StorefrontThemeTokens.textSecondary),
  );
}

class StorefrontBackBar extends StatelessWidget {
  const StorefrontBackBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing = const [],
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(LucideIcons.chevronLeft),
          color: StorefrontThemeTokens.textPrimary,
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: StorefrontThemeTokens.textPrimary,
            ),
          ),
        ),
        ...trailing,
      ],
    ),
  );
}

// --------------------------------------------------------- shared cart / checkout / confirmation

class StorefrontCartView extends StatelessWidget {
  const StorefrontCartView({
    super.key,
    required this.cart,
    required this.tokens,
    required this.onBack,
    required this.onCheckout,
    this.title = 'Your Cart',
    this.showNote = false,
  });

  final StorefrontCartController cart;
  final StorefrontThemeTokens tokens;
  final VoidCallback onBack;
  final VoidCallback onCheckout;
  final String title;
  final bool showNote;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: cart,
    builder: (context, _) => Column(
      children: [
        StorefrontBackBar(title: '$title (${cart.itemCount})', onBack: onBack),
        Expanded(
          child: cart.isEmpty
              ? const Center(
                  child: Text(
                    'Your cart is empty.',
                    style: TextStyle(color: StorefrontThemeTokens.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    for (final line in cart.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StorefrontImagePlaceholder(icon: line.item.icon, tint: tokens.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  if (line.variantSummary != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        line.variantSummary!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: StorefrontThemeTokens.textSecondary,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'RM ${line.item.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: tokens.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StorefrontQtyStepper(
                                  qty: line.qty,
                                  tokens: tokens,
                                  compact: true,
                                  onChanged: (q) => cart.setQty(line.key, q),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => cart.remove(line.key),
                                  child: const Icon(
                                    LucideIcons.trash2,
                                    size: 16,
                                    color: StorefrontThemeTokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (showNote) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: StorefrontThemeTokens.muted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.package, size: 16, color: StorefrontThemeTokens.textSecondary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Add a note (optional)',
                                style: TextStyle(fontSize: 13, color: StorefrontThemeTokens.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        if (!cart.isEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: StorefrontThemeTokens.card,
              border: Border(top: BorderSide(color: StorefrontThemeTokens.border)),
            ),
            child: Column(
              children: [
                _totalsRow('Subtotal', cart.subtotal),
                _totalsRow('Delivery Fee', cart.deliveryFee),
                const Divider(height: 18, color: StorefrontThemeTokens.border),
                _totalsRow('Total', cart.total, emphasize: true),
                const SizedBox(height: 12),
                StorefrontBrandButton(
                  label: 'Proceed to Checkout',
                  icon: LucideIcons.chevronRight,
                  tokens: tokens,
                  onTap: onCheckout,
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _totalsRow(String label, num value, {bool emphasize = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 15 : 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            color: emphasize ? StorefrontThemeTokens.textPrimary : StorefrontThemeTokens.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          'RM ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: emphasize ? 15 : 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            color: StorefrontThemeTokens.textPrimary,
          ),
        ),
      ],
    ),
  );
}

enum _DeliveryOption { standard, express }

enum _PaymentOption { cod, card }

class StorefrontCheckoutView extends StatefulWidget {
  const StorefrontCheckoutView({
    super.key,
    required this.cart,
    required this.tokens,
    required this.onBack,
    required this.onPlaceOrder,
  });

  final StorefrontCartController cart;
  final StorefrontThemeTokens tokens;
  final VoidCallback onBack;
  final VoidCallback onPlaceOrder;

  @override
  State<StorefrontCheckoutView> createState() => _StorefrontCheckoutViewState();
}

class _StorefrontCheckoutViewState extends State<StorefrontCheckoutView> {
  _DeliveryOption delivery = _DeliveryOption.standard;
  _PaymentOption payment = _PaymentOption.cod;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    return Column(
      children: [
        StorefrontBackBar(title: 'Checkout', onBack: widget.onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              _section('Customer Info'),
              _mockField('Full name', LucideIcons.package),
              const SizedBox(height: 10),
              _mockField('Phone number', LucideIcons.package),
              _section('Delivery Address'),
              _mockField('Delivery address', LucideIcons.mapPin),
              _section('Delivery Option'),
              _optionTile(
                'Standard delivery',
                '30-45 min',
                selected: delivery == _DeliveryOption.standard,
                onTap: () => setState(() => delivery = _DeliveryOption.standard),
              ),
              _optionTile(
                'Express delivery',
                '15-20 min · +RM 3.00',
                selected: delivery == _DeliveryOption.express,
                onTap: () => setState(() => delivery = _DeliveryOption.express),
              ),
              _section('Payment Method'),
              _optionTile(
                'Cash on Delivery',
                'Pay when your order arrives',
                selected: payment == _PaymentOption.cod,
                onTap: () => setState(() => payment = _PaymentOption.cod),
              ),
              _optionTile(
                'Card',
                'Prototype only -- no real payment is processed',
                selected: payment == _PaymentOption.card,
                onTap: () => setState(() => payment = _PaymentOption.card),
              ),
              _section('Order Summary'),
              _summaryRow('Subtotal', widget.cart.subtotal),
              _summaryRow(
                'Delivery Fee',
                widget.cart.deliveryFee + (delivery == _DeliveryOption.express ? 3 : 0),
              ),
              const Divider(height: 20, color: StorefrontThemeTokens.border),
              _summaryRow(
                'Total',
                widget.cart.subtotal +
                    widget.cart.deliveryFee +
                    (delivery == _DeliveryOption.express ? 3 : 0),
                emphasize: true,
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
            label: 'Place Order',
            tokens: tokens,
            onTap: widget.onPlaceOrder,
          ),
        ),
      ],
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: StorefrontThemeTokens.textPrimary),
    ),
  );

  Widget _mockField(String hint, IconData icon) => Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: StorefrontThemeTokens.muted,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: StorefrontThemeTokens.textSecondary),
        const SizedBox(width: 10),
        Text(hint, style: const TextStyle(fontSize: 13, color: StorefrontThemeTokens.textSecondary)),
      ],
    ),
  );

  Widget _optionTile(
    String title,
    String subtitle, {
    required bool selected,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: StorefrontThemeTokens.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? widget.tokens.primary : StorefrontThemeTokens.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? LucideIcons.check : null,
              size: 16,
              color: widget.tokens.primary,
            ),
            if (!selected) const SizedBox(width: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: StorefrontThemeTokens.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _summaryRow(String label, num value, {bool emphasize = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 15 : 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            color: emphasize ? StorefrontThemeTokens.textPrimary : StorefrontThemeTokens.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          'RM ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: emphasize ? 15 : 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class StorefrontOrderCreatedView extends StatelessWidget {
  const StorefrontOrderCreatedView({
    super.key,
    required this.tokens,
    required this.orderRef,
    required this.onDone,
  });

  final StorefrontThemeTokens tokens;
  final String orderRef;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: tokens.accentDecoration(radius: 38),
          child: Icon(LucideIcons.check, color: tokens.onPrimary, size: 34),
        ),
        const SizedBox(height: 20),
        const Text(
          'Order placed!',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: StorefrontThemeTokens.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Order $orderRef has been created. This is a prototype flow -- '
          'no real order or payment was processed.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: StorefrontThemeTokens.textSecondary),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: StorefrontBrandButton(label: 'Continue Shopping', tokens: tokens, onTap: onDone),
        ),
      ],
    ),
  );
}

class StorefrontCategoryChip extends StatelessWidget {
  const StorefrontCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final StorefrontThemeTokens tokens;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? tokens.primary : StorefrontThemeTokens.muted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? tokens.onPrimary : StorefrontThemeTokens.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? tokens.onPrimary : StorefrontThemeTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
