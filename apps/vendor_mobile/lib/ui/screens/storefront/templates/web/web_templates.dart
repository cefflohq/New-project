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

const _legacy = _t;

/// Template Library order (same as `window.CEFFLO_TEMPLATE_ORDER`): the five
/// templates, each following one Founder UI reference (2026-10-17).
final List<StorefrontTemplateDef> kWebStorefrontTemplates = [
  _t(
    'warung',
    'Menu',
    'Food & Drinks',
    'A friendly menu: greeting, category chips, dish rows with round plates and an Order button; the dish page ends in a Total + Order footer.',
    const [
      'Greeting header',
      'Round dish rows',
      'Total + Order',
    ],
    const ['Food'],
    const Color(0xFF169A49),
    const Color(0xFFE11D2E),
    hero: false,
  ),
  _t(
    'tailor',
    'Showcase',
    'Fashion & Beauty',
    'Photo-first: a black collection banner, two-up product cards with hearts, and a product page with size circles, Qty, Total price and Add to Bag.',
    const [
      'Collection banner',
      'Two-up photo cards',
      'Sizes + Add to Bag',
    ],
    const ['Retail'],
    const Color(0xFF111111),
    const Color(0xFFF59E6B),
  ),
  _t(
    'care',
    'Basket',
    'Groceries & Everyday',
    'Buy many items fast: a hero banner, category icons, a quick list with quantity keys and a View Cart bar, and a product page with Add to Cart + Buy Now.',
    const [
      'Shop by Category icons',
      'Quick list with quantity',
      'Add to Cart + Buy Now',
    ],
    const ['Retail'],
    const Color(0xFF1677D8),
    const Color(0xFFE8F2FD),
  ),
  _t(
    'service',
    'Service',
    'Services & Bookings',
    'For services: a blue location header, offer cards, round service icons and a provider-style page with Book Service Now.',
    const [
      'Offer cards',
      'Round service icons',
      'Book Service Now',
    ],
    const ['Services'],
    const Color(0xFF5B7CF6),
    const Color(0xFFFACC15),
  ),
  _t(
    'pour',
    'Spotlight',
    'Flowers & Gifts',
    'Warm and photo-led for florists and gifts: a greeting, search, category chips and large bouquet cards; the product page has a photo column, sizes and Add to Cart + Buy Now.',
    const [
      'Large bouquet cards',
      'Sizes and quantity',
      'Add to Cart + Buy Now',
    ],
    const ['Gifts'],
    const Color(0xFFF8BB5E),
    const Color(0xFF111111),
  ),
];

/// Earlier templates (`window.CEFFLO_TEMPLATE_LEGACY`): still rendered for
/// storefronts saved on them, no longer offered in the Template Library.
final List<StorefrontTemplateDef> kLegacyWebStorefrontTemplates = [
  _legacy(
    'homefood',
    'Dapur',
    'Home-Based Food',
    'The menu for today as clear meal rows with photo, description, price and quantity; add-on dishes sit in their own section.',
    const [
      'Menu for today with hours',
      'Meal rows with quantity',
      'Add-on dishes on the product page',
    ],
    const ['Food'],
    const Color(0xFFC2410C),
    const Color(0xFFFFF7ED),
  ),
  _legacy(
    'bakery',
    'Patisserie',
    'Bakery & Dessert',
    'Editorial hero, quiet collection tabs and a two-column gallery of tall photos; product pages lead with a large photo.',
    const [
      'Large product photography',
      'Collections',
      'Availability on the product page',
    ],
    const ['Desserts & Drinks'],
    const Color(0xFF9D174D),
    const Color(0xFFFDF2F8),
  ),
  _legacy(
    'eatery',
    'Kedai Makan',
    'Restaurant & Outlet',
    'A dense menu: search, sticky category tabs, a popular strip and compact rows with one-tap add.',
    const [
      'Menu search',
      'Sticky category tabs',
      'Compact rows with quick add',
    ],
    const ['Food'],
    const Color(0xFFB91C1C),
    const Color(0xFFFEF2F2),
  ),
  _legacy(
    'cafe',
    'Kafe',
    'Cafe & Beverage',
    'A compact drink menu: segmented categories and a three-across grid with one-tap add.',
    const [
      'Segmented categories',
      'Three-across drink grid',
      'You may also like',
    ],
    const ['Desserts & Drinks'],
    const Color(0xFF1F2937),
    const Color(0xFFF3F4F6),
  ),
  _legacy(
    'catering',
    'Katering',
    'Catering & Corporate',
    'A business card header, numbered package cards and a clear note for scheduled orders.',
    const [
      'Business details up top',
      'Numbered packages',
      'Scheduled-order note',
    ],
    const ['Food'],
    const Color(0xFF0F766E),
    const Color(0xFFF0FDFA),
  ),
  _legacy(
    'frozen',
    'Sejuk Beku',
    'Frozen & Ready-to-Cook',
    'A stocking-up catalogue: bordered two-up cards with quantity always visible.',
    const [
      'Search and category tabs',
      'Quantity on every card',
      'Product information',
    ],
    const ['Food'],
    const Color(0xFF1D4ED8),
    const Color(0xFFEFF6FF),
  ),
  _legacy(
    'florist',
    'Florist',
    'Florist & Gift',
    'Editorial full-bleed hero, occasions as photo tiles and one large photo per gift.',
    const ['Full-bleed hero', 'Shop by occasion', 'Large gift photos'],
    const ['Gifts'],
    const Color(0xFF3F3F46),
    const Color(0xFFFAF7F2),
  ),
  _legacy(
    'laundry',
    'Dobi',
    'Laundry & Services',
    'A service price list: service area and hours up top, grouped services with what the price covers.',
    const [
      'Service area and hours',
      'Grouped price list',
      'Quick add per service',
    ],
    const ['Services'],
    const Color(0xFF0369A1),
    const Color(0xFFF0F9FF),
  ),
  _legacy(
    'retail',
    'Jenama',
    'Retail & Local Products',
    'Brand first: centred logo, banner, numbered bestsellers, collection tabs and a clean square grid.',
    const ['Centred brand', 'Numbered bestsellers', 'Square product grid'],
    const ['Retail'],
    const Color(0xFF111827),
    const Color(0xFFF59E0B),
  ),
  _legacy(
    'outlets',
    'Rangkaian',
    'Multi-Outlet SME',
    'A brand band, the area you serve and an organised catalogue with a category rail on wide screens.',
    const ['Brand band', 'Service area and hours', 'Category rail and grid'],
    const ['Retail'],
    const Color(0xFF4338CA),
    const Color(0xFFEEF2FF),
  ),
  _legacy(
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
  _legacy(
    'kit',
    'Kit',
    'Sports Showcase',
    'A sports-store layout: round category badges, a Popular rail and category cards, with a framed product hero on a diagonal two-tone page.',
    const ['Category badges', 'Popular rail', 'Framed product hero', 'Buy Now'],
    const ['Fashion'],
    const Color(0xFF253D6B),
    const Color(0xFFE1293F),
  ),
  _legacy(
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
  _legacy(
    'crimson',
    'Crimson',
    'Single Colour',
    'One strong colour: tall product cards and a product page where the item sits between the colour and a white sheet.',
    const ['Tall colour cards', 'Straddling product photo', 'Add to cart pill'],
    const ['Health', 'Retail'],
    const Color(0xFFB82838),
    const Color(0xFF2A2A2A),
  ),
  _legacy(
    'lift',
    'Lift',
    'Drop Collection',
    'A clean drop layout: collection banner, big category tabs with counts, two-up cards and a product page with a giant monogram.',
    const ['Collection banner', 'Category tabs with counts', 'Swipe to buy'],
    const ['Fashion'],
    const Color(0xFF111111),
    const Color(0xFFE5332A),
  ),
  _legacy(
    'harvest',
    'Harvest',
    'Fresh Food',
    'Fresh-food cards with round dishes rising out of each card, black pill categories and a floating bottom bar.',
    const ['Round dish cards', 'Feature card', 'Floating cart button'],
    const ['Food'],
    const Color(0xFF111111),
    const Color(0xFF3BAA4A),
  ),
  _legacy(
    'botanic',
    'Botanic',
    'Natural Care',
    'Soft natural panels, a quiet headline and a product page with a frosted glass purchase card.',
    const ['Soft product panels', 'Glass purchase card', 'Total price'],
    const ['Beauty'],
    const Color(0xFF86A98F),
    const Color(0xFF2F4A3A),
  ),
  _legacy(
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
  _legacy(
    'discover',
    'Discover',
    'Clean Marketplace',
    'A clean marketplace: banner, outlined category chips, two-up tiles and a labelled tab bar.',
    const ['Banner', 'Outlined chips', 'Two-up tiles'],
    const ['Retail'],
    const Color(0xFF22C55E),
    const Color(0xFF16A34A),
  ),
  _legacy(
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
  _legacy(
    'sprint',
    'Sprint',
    'Performance',
    'An energetic layout: orange banner, icon category tiles, gradient pick cards and a raised centre cart button.',
    const ['Icon category tiles', 'Top Picks cards', 'Add to Cart'],
    const ['Fashion', 'Retail'],
    const Color(0xFF6B3BE0),
    const Color(0xFFFF7A1A),
  ),
  _legacy(
    'splash',
    'Splash',
    'Sports Shop',
    'A sports shop: welcome header, icon pills, promo banner, featured cards with price tags and a floating View your cart.',
    const ['Promo banner', 'Price-tag cards', 'View your cart bar'],
    const ['Retail'],
    const Color(0xFF2563EB),
    const Color(0xFFFACC15),
  ),
  _legacy(
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
    final logo = b.logoImage;
    if (logo != null) {
      store['logo_url'] =
          'data:${b.logoContentType ?? 'image/png'};base64,${base64Encode(logo)}';
    } else if (b.logoPath == null && base != null) {
      store.remove('logo_url');
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
