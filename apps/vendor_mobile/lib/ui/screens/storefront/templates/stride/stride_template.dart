import 'package:flutter/material.dart';

import '../../../../../data/storefront_config.dart';
import '../../shared/template_definition.dart';
import 'stride_renderer.dart';

/// Stride -- Clean Minimal.
final strideTemplate = StorefrontTemplateDef(
  id: 'stride',
  name: 'Stride',
  style: 'Clean Minimal',
  description: 'An ultra-clean, minimal layout: generous white space, a collection hero card and a quiet two-column grid.',
  highlights: const [
    'Collection hero card',
    'Labelled category tabs',
    'Minimal two-column grid',
    'Colour and size options',
  ],
  tags: const ['Fashion'],
  capabilities: const {
    StorefrontCapability.brandColour,
    StorefrontCapability.identity,
  },
  defaults: const StorefrontBranding(
    primary: Color(0xFF14171C),
    secondary: Color(0xFFE23B3B),
    mode: BrandColorMode.solid,
    font: StorefrontFontTreatment.elegant,
  ),
  backgrounds: const [
    StorefrontBackgroundOption(kTemplateBackgroundId, 'Default', Colors.white),
  ],
  renderer: (d) => OriginRunPreview(
    businessName: d.businessName,
    items: d.items,
    categories: d.categories,
    tokens: d.tokens,
  ),
);
