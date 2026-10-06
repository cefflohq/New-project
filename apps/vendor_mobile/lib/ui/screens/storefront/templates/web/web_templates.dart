/// Storefront V1 templates (Founder UI references, 2026-10-06).
///
/// Each template is rendered by the public storefront itself (store/
/// templates.js) so the Vendor preview and the customer's page are the same
/// code: [StorefrontLivePreview] embeds it with the business's own
/// `storefront_preview` payload plus the vendor's unsaved customisation.
/// Ids here must match `window.CEFFLO_TEMPLATES` keys.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../../core/app_state.dart';
import '../../shared/storefront_surface.dart';
import '../../shared/storefront_theme.dart';
import '../../../../../data/storefront_config.dart';
import '../../shared/storefront_web_frame.dart';
import '../../shared/template_definition.dart';

const _caps = {
  StorefrontCapability.brandColour,
  StorefrontCapability.heroImage,
  StorefrontCapability.identity,
};

StorefrontTemplateDef _t(
  String id,
  String name,
  String style,
  String description,
  List<String> highlights,
  List<String> tags,
  Color primary,
  Color secondary, {
  bool hero = true,
}) => StorefrontTemplateDef(
  id: id,
  name: name,
  style: style,
  description: description,
  highlights: highlights,
  tags: tags,
  capabilities: hero
      ? _caps
      : const {StorefrontCapability.brandColour, StorefrontCapability.identity},
  defaults: StorefrontBranding(primary: primary, secondary: secondary),
  renderer: (d) => StorefrontLivePreview(templateId: id, data: d),
);

/// Gallery order (same as `window.CEFFLO_TEMPLATE_ORDER`).
final List<StorefrontTemplateDef> kWebStorefrontTemplates = [
  _t(
    'care',
    'Care',
    'Everyday Store',
    'A clear everyday store: brand header, a hero banner, category icons, featured products, a quick list with quantity steppers and a full product page.',
    const [
      'Hero banner with Shop Now',
      'Shop by Category icons',
      'Quick list with quantity',
      'Add to Cart + Buy Now',
    ],
    const ['Health', 'Retail'],
    const Color(0xFF0E8F7E),
    const Color(0xFFE3F4F1),
  ),
  _t(
    'capsule',
    'Capsule',
    'Bold Colour',
    'Bold full-colour product pages with a white purchase card and a centred brand home where two products cross.',
    const [
      'Full-colour product pages',
      'Centred brand headline',
      'Quantity + Buy Now card',
    ],
    const ['Health', 'Beauty'],
    const Color(0xFFC8234F),
    const Color(0xFFF7C531),
  ),
  _t(
    'kit',
    'Kit',
    'Sports Showcase',
    'A sports-store layout: round category badges, a Popular rail and category cards, with a framed product hero on a diagonal two-tone page.',
    const ['Category badges', 'Popular rail', 'Framed product hero', 'Buy Now'],
    const ['Fashion'],
    const Color(0xFF253D6B),
    const Color(0xFFE1293F),
  ),
  _t(
    'brew',
    'Brew',
    'Coffee House',
    'Warm coffee-house cards with round floating photos, pill categories and a deep-toned product page.',
    const [
      'Location header + search',
      'Round photo cards',
      'Quantity + Buy now',
    ],
    const ['Food'],
    const Color(0xFF4B2A15),
    const Color(0xFFD3A06A),
  ),
  _t(
    'crimson',
    'Crimson',
    'Single Colour',
    'One strong colour: tall product cards and a product page where the item sits between the colour and a white sheet.',
    const ['Tall colour cards', 'Straddling product photo', 'Add to cart pill'],
    const ['Health', 'Retail'],
    const Color(0xFFB82838),
    const Color(0xFF2A2A2A),
  ),
  _t(
    'lift',
    'Lift',
    'Drop Collection',
    'A clean drop layout: collection banner, big category tabs with counts, two-up cards and a product page with a giant monogram.',
    const ['Collection banner', 'Category tabs with counts', 'Swipe to buy'],
    const ['Fashion'],
    const Color(0xFF111111),
    const Color(0xFFE5332A),
  ),
  _t(
    'harvest',
    'Harvest',
    'Fresh Food',
    'Fresh-food cards with round dishes rising out of each card, black pill categories and a floating bottom bar.',
    const ['Round dish cards', 'Feature card', 'Floating cart button'],
    const ['Food'],
    const Color(0xFF111111),
    const Color(0xFF3BAA4A),
  ),
  _t(
    'botanic',
    'Botanic',
    'Natural Care',
    'Soft natural panels, a quiet headline and a product page with a frosted glass purchase card.',
    const ['Soft product panels', 'Glass purchase card', 'Total price'],
    const ['Beauty'],
    const Color(0xFF86A98F),
    const Color(0xFF2F4A3A),
  ),
  _t(
    'combo',
    'Combo',
    'Build an Order',
    'Pick several items fast: a three-column grid with price pills, category counts and a floating total.',
    const ['3-column quick grid', 'Counts per category', 'Floating total'],
    const ['Food'],
    const Color(0xFFF26B2C),
    const Color(0xFF8E9BF5),
    hero: false,
  ),
  _t(
    'discover',
    'Discover',
    'Clean Marketplace',
    'A clean marketplace: banner, outlined category chips, two-up tiles and a labelled tab bar.',
    const ['Banner', 'Outlined chips', 'Two-up tiles'],
    const ['Retail'],
    const Color(0xFF22C55E),
    const Color(0xFF16A34A),
  ),
  _t(
    'atelier',
    'Atelier',
    'Fashion House',
    'A fashion house: wordmark header, promo banner, square category tiles, photo cards and a detail page with a peeking carousel.',
    const [
      'Wordmark header',
      'Photo cards',
      'Detail accordion',
      'Add to shopping bag',
    ],
    const ['Fashion'],
    const Color(0xFF111111),
    const Color(0xFFE35B2C),
  ),
  _t(
    'pour',
    'Pour',
    'Café Spotlight',
    'One item at a time: a full photo fading into the page, name and price, a black Add to Order pill and "You may also like".',
    const ['Full-bleed photo', 'Add to Order', 'You may also like'],
    const ['Food'],
    const Color(0xFF111111),
    const Color(0xFFE6E7E9),
    hero: false,
  ),
  _t(
    'tailor',
    'Tailor',
    'Menswear',
    'A tailored store: two-line wordmark, dark collection banner, grey cards with hearts and a detail page with a thumbnail column.',
    const ['Collection banner', 'Thumbnail column', 'Qty + total price'],
    const ['Fashion'],
    const Color(0xFF111111),
    const Color(0xFFF59E6B),
  ),
  _t(
    'sprint',
    'Sprint',
    'Performance',
    'An energetic layout: orange banner, icon category tiles, gradient pick cards and a raised centre cart button.',
    const ['Icon category tiles', 'Top Picks cards', 'Add to Cart'],
    const ['Fashion', 'Retail'],
    const Color(0xFF6B3BE0),
    const Color(0xFFFF7A1A),
  ),
  _t(
    'splash',
    'Splash',
    'Sports Shop',
    'A sports shop: welcome header, icon pills, promo banner, featured cards with price tags and a floating View your cart.',
    const ['Promo banner', 'Price-tag cards', 'View your cart bar'],
    const ['Retail'],
    const Color(0xFF2563EB),
    const Color(0xFFFACC15),
  ),
  _t(
    'service',
    'Service',
    'Services',
    'For services: blue location header, offer cards, round category icons and a provider-style detail page.',
    const ['Offer cards', 'Round categories', 'Order Now'],
    const ['Services'],
    const Color(0xFF5B7CF6),
    const Color(0xFFFACC15),
  ),
  _t(
    'warung',
    'Warung',
    'Local Eatery',
    'A friendly eatery: greeting, outlined chips, list rows with round dishes and a Total + Order footer.',
    const ['Greeting header', 'Dish list rows', 'Total + Order'],
    const ['Food'],
    const Color(0xFF169A49),
    const Color(0xFFE11D2E),
    hero: false,
  ),
  _t(
    'collector',
    'Collector',
    'Collections',
    'Collection-led: a collage welcome, stacked collection cards and collection pages with stats and an item grid.',
    const ['Collage welcome', 'Stacked collections', 'Collection stats'],
    const ['Gifts'],
    const Color(0xFF111111),
    const Color(0xFFF2F2F4),
    hero: false,
  ),
];

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// A template rendered by the real storefront with this business's data.
class StorefrontLivePreview extends StatefulWidget {
  const StorefrontLivePreview({
    super.key,
    required this.templateId,
    required this.data,
    this.route = '',
  });

  final String templateId;
  final StorefrontRenderData data;
  final String route;

  @override
  State<StorefrontLivePreview> createState() => _StorefrontLivePreviewState();
}

class _StorefrontLivePreviewState extends State<StorefrontLivePreview> {
  late final Future<Map<String, dynamic>?> _base =
      AppScope.maybeRead(context)?.storefrontPreviewPayload() ??
      Future.value(null);

  /// Server payload + the vendor's unsaved customisation. Demo builds have
  /// no server payload: their catalogue (names, prices) stands in.
  Map<String, dynamic> _payload(Map<String, dynamic>? base) {
    final d = widget.data, t = d.tokens, b = t.branding;
    final store = <String, dynamic>{
      ...?base,
      if (base == null) ...{
        'slug': 'preview',
        'business': {'name': d.businessName},
        'categories': [
          for (final c in d.categories)
            if (c.id != 'all') {'id': c.id, 'name': c.label},
        ],
        'products': [
          for (final i in d.items)
            {
              'id': i.id,
              'category_id': i.categoryId,
              'name': i.name,
              'description': i.description ?? '',
              'display_price': i.price,
              'images': const [],
            },
        ],
      },
    };
    final theme = Map<String, dynamic>.from(
      (store['theme'] as Map?) ?? const {},
    );
    theme['accent'] = _hex(t.primary);
    theme['secondary'] = _hex(t.secondary);
    if (t.tagline.isNotEmpty) theme['tagline'] = t.tagline;
    store['theme'] = theme;
    store['template_key'] = widget.templateId;
    if (t.storeName.isNotEmpty) {
      store['business'] = {
        ...?(store['business'] as Map?)?.cast<String, dynamic>(),
        'name': t.storeName,
      };
    }
    final bytes = b.heroImage;
    if (bytes != null) {
      store['hero_url'] =
          'data:${b.heroContentType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
    }
    return store;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: _base,
    builder: (context, snap) => snap.connectionState != ConnectionState.done
        ? const ColoredBox(color: Color(0xFFF5F6F8))
        : StorefrontWebFrame(
            templateId: widget.templateId,
            payload: _payload(snap.data),
            interactive: widget.data.interactive,
            route: widget.route,
          ),
  );
}

/// One storefront screen of [def] at [viewport] (e.g. a 390 x 844 phone),
/// scaled to fit its slot -- the X-02 Live Preview frames.
class StorefrontFramedPreview extends StatelessWidget {
  const StorefrontFramedPreview({
    super.key,
    required this.def,
    required this.branding,
    required this.catalogue,
    required this.viewport,
    this.route = '',
  });

  final StorefrontTemplateDef def;
  final StorefrontBranding branding;
  final StorefrontCatalogue catalogue;
  final Size viewport;
  final String route;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox.fromSize(
        size: viewport,
        child: StorefrontLivePreview(
          key: ValueKey('${def.id}-$route-${viewport.width}'),
          templateId: def.id,
          route: route,
          data: StorefrontRenderData(
            businessName: branding.storeName,
            items: catalogue.items,
            categories: catalogue.categories,
            tokens: StorefrontThemeTokens(
              branding,
              background: def.backgroundFor(branding),
            ),
          ),
        ),
      ),
    ),
  );
}
