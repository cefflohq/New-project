/// The scalable Storefront Template Library.
///
/// A [StorefrontTemplateDef] is one card a vendor can browse, preview and
/// "use" from the Storefront screen's "Explore Templates" gallery. There is
/// no fixed limit -- growing the library is adding entries to
/// [kStorefrontTemplateLibrary] (and, if genuinely needed, a category to
/// [kStorefrontTemplateCategories]), never a new `if template == ...` branch
/// anywhere in the app.
///
/// Many entries intentionally point at the same [StorefrontTemplate]
/// renderer engine (`browseShop`/`quickOrder`/`catalogue` -- see
/// `storefront_config.dart`). That is the "reuse business logic, not
/// presentation" split from the spec: the 3 renderers stay the actual
/// commerce/composition engines; the library is free to grow far past 3
/// named, distinctly-branded templates without a new renderer per entry.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'storefront_config.dart';

/// Filter chips shown under "Explore Templates". A plain, ordered string
/// list -- not a closed enum -- so a new category is one line here plus a
/// `category:` tag on new entries, no switch statement to extend.
const List<String> kStorefrontTemplateCategories = [
  'Food',
  'Fashion',
  'Beauty',
  'Gifts',
  'Florist',
  'Retail',
  'Sports',
  'Electronics',
];

/// One card in the Template Library.
@immutable
class StorefrontTemplateDef {
  const StorefrontTemplateDef({
    required this.id,
    required this.name,
    required this.category,
    required this.typeTag,
    required this.renderer,
    required this.previewColors,
    required this.previewIcon,
    required this.defaultBranding,
    this.version = 1,
  });

  /// Stable, persisted identifier -- used as the route entity id and as the
  /// key for the vendor's per-template branding overrides.
  final String id;

  /// Demo brand name shown on the card and as the Customize screen title
  /// ("Customize Luma").
  final String name;

  /// One of [kStorefrontTemplateCategories].
  final String category;

  /// Small tag shown on the card, e.g. "Fashion • Editorial".
  final String typeTag;

  /// Which of the 3 rendering engines actually draws this template's
  /// customer-facing preview.
  final StorefrontTemplate renderer;

  /// Gradient stand-in for a real preview photo (no network images in this
  /// prototype's asset pipeline).
  final List<Color> previewColors;
  final IconData previewIcon;

  /// The brand identity this template ships with before a vendor customizes
  /// it -- also what "Reset" on the Customize screen returns to.
  final StorefrontBranding defaultBranding;

  final int version;
}

/// 14 library entries across 8 categories. The original 8 entries
/// deliberately share only 3 renderers (browseShop x3, catalogue x3,
/// quickOrder x2); 6 later entries (MatchPoint, CircuitHub, Ritual, Bag
/// Drop, Origin Run, Tide Table) each ship a genuinely distinct renderer of
/// their own -- see the implementation report for why each entry was
/// grouped the way it was.
final List<StorefrontTemplateDef> kStorefrontTemplateLibrary = [
  StorefrontTemplateDef(
    id: 'foundation',
    name: 'Foundation',
    category: 'Retail',
    typeTag: 'Retail • Essentials',
    renderer: StorefrontTemplate.browseShop,
    previewColors: const [Color(0xFF3A4A63), Color(0xFF0F172A)],
    previewIcon: LucideIcons.store,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF2A6EEC),
      secondary: Color(0xFF60A5FA),
      mode: BrandColorMode.gradient,
      storeName: 'Foundation',
      tagline: 'Everything you need, beautifully organized.',
      logoText: 'FOUNDATION',
      font: StorefrontFontTreatment.modern,
    ),
  ),
  StorefrontTemplateDef(
    id: 'luma',
    name: 'Luma',
    category: 'Fashion',
    typeTag: 'Fashion • Editorial',
    renderer: StorefrontTemplate.catalogue,
    previewColors: const [Color(0xFFD9C7B8), Color(0xFF8C7159)],
    previewIcon: LucideIcons.shirt,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF0F3BFF),
      secondary: Color(0xFFF6C440),
      mode: BrandColorMode.gradient,
      storeName: 'Luma Boutique',
      tagline: 'Fashion for a brighter you.',
      logoText: 'LUMA',
      font: StorefrontFontTreatment.elegant,
    ),
  ),
  StorefrontTemplateDef(
    id: 'deligo',
    name: 'DeliGo',
    category: 'Food',
    typeTag: 'Food • Visual Menu',
    renderer: StorefrontTemplate.quickOrder,
    previewColors: const [Color(0xFFF7A93B), Color(0xFFE0562C)],
    previewIcon: LucideIcons.utensils,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFFE0562C),
      secondary: Color(0xFFF7A93B),
      mode: BrandColorMode.gradient,
      storeName: 'DeliGo Kitchen',
      tagline: 'Good food. Brighter days.',
      logoText: 'DELIGO',
      font: StorefrontFontTreatment.bold,
    ),
  ),
  StorefrontTemplateDef(
    id: 'bloomco',
    name: 'Bloom & Co.',
    category: 'Florist',
    typeTag: 'Florist • Immersive',
    renderer: StorefrontTemplate.catalogue,
    previewColors: const [Color(0xFFF3C9D2), Color(0xFFE07A9A)],
    previewIcon: LucideIcons.flower2,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFFC8517A),
      secondary: Color(0xFFF3C9D2),
      mode: BrandColorMode.gradient,
      storeName: 'Bloom & Co.',
      tagline: 'Fresh blooms, happier days.',
      logoText: 'BLOOM & CO.',
      font: StorefrontFontTreatment.elegant,
    ),
  ),
  StorefrontTemplateDef(
    id: 'glow',
    name: 'Glow',
    category: 'Beauty',
    typeTag: 'Beauty • Elegant',
    renderer: StorefrontTemplate.catalogue,
    previewColors: const [Color(0xFFF6D9C4), Color(0xFFE7A17A)],
    previewIcon: LucideIcons.sparkles,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFFB5713F),
      secondary: Color(0xFFF6D9C4),
      mode: BrandColorMode.gradient,
      storeName: 'Glow Skincare',
      tagline: 'Skincare that cares.',
      logoText: 'GLOW',
      font: StorefrontFontTreatment.modern,
    ),
  ),
  StorefrontTemplateDef(
    id: 'giftbox',
    name: 'The Gift Box',
    category: 'Gifts',
    typeTag: 'Gifts • Warm',
    renderer: StorefrontTemplate.browseShop,
    previewColors: const [Color(0xFFEBAE7A), Color(0xFF9B5A2B)],
    previewIcon: LucideIcons.gift,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF9B5A2B),
      secondary: Color(0xFFEBAE7A),
      mode: BrandColorMode.gradient,
      storeName: 'The Gift Box',
      tagline: 'Meaningful gifts for every occasion.',
      logoText: 'THE GIFT BOX',
      font: StorefrontFontTreatment.classic,
    ),
  ),
  StorefrontTemplateDef(
    id: 'urbancart',
    name: 'UrbanCart',
    category: 'Retail',
    typeTag: 'Retail • Everyday',
    renderer: StorefrontTemplate.browseShop,
    previewColors: const [Color(0xFF6B7280), Color(0xFF1F2937)],
    previewIcon: LucideIcons.shoppingBag,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF1F2937),
      secondary: Color(0xFF6B7280),
      mode: BrandColorMode.gradient,
      storeName: 'UrbanCart',
      tagline: 'Smarter everyday living.',
      logoText: 'URBANCART',
      font: StorefrontFontTreatment.bold,
    ),
  ),
  StorefrontTemplateDef(
    id: 'brewbar',
    name: 'BrewBar',
    category: 'Food',
    typeTag: 'Food • Quick Menu',
    renderer: StorefrontTemplate.quickOrder,
    previewColors: const [Color(0xFF7A4A21), Color(0xFF3E2410)],
    previewIcon: LucideIcons.coffee,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF7A4A21),
      secondary: Color(0xFFD9A066),
      mode: BrandColorMode.gradient,
      storeName: 'BrewBar Café',
      tagline: 'Your daily brew, done right.',
      logoText: 'BREWBAR',
      font: StorefrontFontTreatment.modern,
    ),
  ),
  StorefrontTemplateDef(
    id: 'matchpoint',
    name: 'MatchPoint',
    category: 'Sports',
    typeTag: 'Sports • Team Kit',
    renderer: StorefrontTemplate.matchDay,
    previewColors: const [Color(0xFFB4222E), Color(0xFF17233D)],
    previewIcon: LucideIcons.shirt,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF17233D),
      secondary: Color(0xFFB4222E),
      mode: BrandColorMode.gradient,
      storeName: 'MatchPoint',
      tagline: 'Kit up for game day.',
      logoText: 'MATCHPOINT',
      font: StorefrontFontTreatment.bold,
    ),
  ),
  StorefrontTemplateDef(
    id: 'circuithub',
    name: 'CircuitHub',
    category: 'Electronics',
    typeTag: 'Electronics • Marketplace',
    renderer: StorefrontTemplate.discoverMarket,
    previewColors: const [Color(0xFF15A66E), Color(0xFF0B7A4F)],
    previewIcon: LucideIcons.smartphone,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF15A66E),
      secondary: Color(0xFF0B7A4F),
      mode: BrandColorMode.gradient,
      storeName: 'CircuitHub',
      tagline: 'Tech worth discovering.',
      logoText: 'CIRCUITHUB',
      font: StorefrontFontTreatment.modern,
    ),
  ),
  StorefrontTemplateDef(
    id: 'ritualcare',
    name: 'Ritual',
    category: 'Beauty',
    typeTag: 'Beauty • Natural Care',
    renderer: StorefrontTemplate.ritualCare,
    previewColors: const [Color(0xFFAFC7AE), Color(0xFF4C6B52)],
    previewIcon: LucideIcons.leaf,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF4C6B52),
      secondary: Color(0xFFAFC7AE),
      mode: BrandColorMode.gradient,
      storeName: 'Ritual',
      tagline: 'Your complete natural care routine.',
      logoText: 'RITUAL',
      font: StorefrontFontTreatment.elegant,
    ),
  ),
  StorefrontTemplateDef(
    id: 'bagdrop',
    name: 'Bag Drop',
    category: 'Fashion',
    typeTag: 'Fashion • Streetwear',
    renderer: StorefrontTemplate.bagDrop,
    previewColors: const [Color(0xFF14171C), Color(0xFFE2571C)],
    previewIcon: LucideIcons.shoppingBag,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF14171C),
      secondary: Color(0xFFE2571C),
      mode: BrandColorMode.solid,
      storeName: 'Bag Drop',
      tagline: 'Fresh drops, straight to your bag.',
      logoText: 'BAG DROP',
      font: StorefrontFontTreatment.bold,
    ),
  ),
  StorefrontTemplateDef(
    id: 'originrun',
    name: 'Origin Run',
    category: 'Fashion',
    typeTag: 'Fashion • Athletic Editorial',
    renderer: StorefrontTemplate.originRun,
    previewColors: const [Color(0xFF2A2E36), Color(0xFF0A0B0D)],
    previewIcon: LucideIcons.footprints,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF14171C),
      secondary: Color(0xFFE23B3B),
      mode: BrandColorMode.solid,
      storeName: 'Origin Run',
      tagline: 'Engineered for the next mile.',
      logoText: 'ORIGIN RUN',
      font: StorefrontFontTreatment.elegant,
    ),
  ),
  StorefrontTemplateDef(
    id: 'tidetable',
    name: 'Tide Table',
    category: 'Food',
    typeTag: 'Food • Fresh Catch',
    renderer: StorefrontTemplate.tideTable,
    previewColors: const [Color(0xFF3E5C52), Color(0xFF1F2A24)],
    previewIcon: LucideIcons.fish,
    defaultBranding: const StorefrontBranding(
      primary: Color(0xFF1F2A24),
      secondary: Color(0xFFE0562C),
      mode: BrandColorMode.solid,
      storeName: 'Tide Table',
      tagline: 'We made healthy seafood for you.',
      logoText: 'TIDE TABLE',
      font: StorefrontFontTreatment.modern,
    ),
  ),
];

/// The Storefront screen's default active template before any vendor ever
/// taps "Use This Template".
const String kDefaultStorefrontTemplateId = 'foundation';

StorefrontTemplateDef storefrontTemplateById(String id) =>
    kStorefrontTemplateLibrary.firstWhere(
      (t) => t.id == id,
      orElse: () => kStorefrontTemplateLibrary.first,
    );
