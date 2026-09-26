import 'package:flutter/material.dart';

import '../../../../../data/storefront_config.dart';
import '../../shared/template_definition.dart';
import 'arena_renderer.dart';

/// Arena -- Bold Showcase.
final arenaTemplate = StorefrontTemplateDef(
  id: 'arena',
  name: 'Arena',
  style: 'Bold Showcase',
  description: 'A bold and modern layout with a full-screen hero, perfect for fashion, sports, lifestyle and premium brands.',
  highlights: const [
    'Full-screen hero section',
    'Product showcase',
    'Category navigation',
    'Modern and clean design',
    'Mobile optimised',
  ],
  tags: const ['Fashion', 'Gifts'],
  capabilities: const {
    StorefrontCapability.brandColour,
    StorefrontCapability.background,
    StorefrontCapability.heroImage,
    StorefrontCapability.identity,
  },
  defaults: const StorefrontBranding(
    primary: Color(0xFF17233D),
    secondary: Color(0xFFB4222E),
    mode: BrandColorMode.gradient,
    font: StorefrontFontTreatment.bold,
  ),
  backgrounds: kLightBackgrounds,
  renderer: (d) => MatchDayPreview(
    businessName: d.businessName,
    items: d.items,
    categories: d.categories,
    tokens: d.tokens,
  ),
);
