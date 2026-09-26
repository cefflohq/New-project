import 'package:flutter/material.dart';

import '../../../../../data/storefront_config.dart';
import '../../shared/template_definition.dart';
import 'ritual_renderer.dart';

/// Ritual -- Premium Product.
final ritualTemplate = StorefrontTemplateDef(
  id: 'ritual',
  name: 'Ritual',
  style: 'Premium Product',
  description: 'A calm, premium layout that gives each product the whole card, with an oversized price and a floating tab bar.',
  highlights: const [
    'One product per card',
    'Pill category filters',
    'Oversized pricing',
    'Floating glass navigation',
  ],
  tags: const ['Beauty', 'Gifts'],
  capabilities: const {
    StorefrontCapability.brandColour,
    StorefrontCapability.background,
    StorefrontCapability.identity,
  },
  defaults: const StorefrontBranding(
    primary: Color(0xFF4C6B52),
    secondary: Color(0xFFAFC7AE),
    mode: BrandColorMode.gradient,
    font: StorefrontFontTreatment.elegant,
  ),
  backgrounds: kLightBackgrounds,
  renderer: (d) => RitualCarePreview(
    businessName: d.businessName,
    items: d.items,
    categories: d.categories,
    tokens: d.tokens,
  ),
);
