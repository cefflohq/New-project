import 'package:flutter/material.dart';

import '../../../../../data/storefront_config.dart';
import '../../shared/template_definition.dart';
import 'feast_renderer.dart';

/// Feast -- Rich Visual.
final feastTemplate = StorefrontTemplateDef(
  id: 'feast',
  name: 'Feast',
  style: 'Rich Visual',
  description: 'A rich, product-led layout with a swipeable carousel of large product cards. Made for cafés, food and anything that sells on looks.',
  highlights: const [
    'Swipeable product carousel',
    'Large product imagery',
    'Category pills with icons',
    'Quick add from every card',
  ],
  tags: const ['Food'],
  capabilities: const {
    StorefrontCapability.brandColour,
    StorefrontCapability.background,
    StorefrontCapability.identity,
  },
  defaults: const StorefrontBranding(
    primary: Color(0xFF7A4A21),
    secondary: Color(0xFFC89A6C),
    mode: BrandColorMode.solid,
    font: StorefrontFontTreatment.modern,
  ),
  backgrounds: kLightBackgrounds,
  renderer: (d) => TideTablePreview(
    businessName: d.businessName,
    items: d.items,
    categories: d.categories,
    tokens: d.tokens,
  ),
);
