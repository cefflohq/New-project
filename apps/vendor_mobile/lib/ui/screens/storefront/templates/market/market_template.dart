import 'package:flutter/material.dart';

import '../../../../../data/storefront_config.dart';
import '../../shared/template_definition.dart';
import 'market_renderer.dart';

/// Market -- Clean Commerce.
final marketTemplate = StorefrontTemplateDef(
  id: 'market',
  name: 'Market',
  style: 'Clean Commerce',
  description: 'A clean, fast-to-scan commerce layout: search, a promo banner, category pills and a product grid.',
  highlights: const [
    'Search first',
    'Promo banner with your photo',
    'Category pills',
    'Product grid with ratings',
  ],
  tags: const ['Gifts', 'Beauty', 'Fashion'],
  capabilities: const {
    StorefrontCapability.brandColour,
    StorefrontCapability.background,
    StorefrontCapability.heroImage,
    StorefrontCapability.identity,
  },
  defaults: const StorefrontBranding(
    primary: Color(0xFF15A66E),
    secondary: Color(0xFF0B7A4F),
    mode: BrandColorMode.gradient,
    font: StorefrontFontTreatment.modern,
  ),
  backgrounds: kLightBackgrounds,
  renderer: (d) => DiscoverMarketPreview(
    businessName: d.businessName,
    items: d.items,
    categories: d.categories,
    tokens: d.tokens,
  ),
);
