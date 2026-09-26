/// The one canonical shape of a Storefront template.
///
/// A template is a reusable storefront LAYOUT. It owns presentation only:
/// its renderer, its default theme and what vendors may customize. Vendor
/// data (business identity, products, prices, categories) is injected at
/// render time through [StorefrontRenderData] and is never stored in, or
/// duplicated per, a template -- switching templates re-renders the same
/// vendor data through another layout.
///
/// Every template lives in `templates/<id>/` and is listed once in
/// `templates/template_registry.dart`. The gallery, Template Preview and
/// Customize screens read only this type; none of them branches on a
/// template id. See `templates/STOREFRONT_TEMPLATE_GUIDE.md`.
library;

import 'package:flutter/material.dart';

import '../../../../data/storefront_catalog.dart';
import '../../../../data/storefront_config.dart';
import 'storefront_theme.dart';

/// What a vendor may customize on a template. The Customize screen renders
/// exactly the controls a template declares -- nothing disabled, nothing
/// shown "just in case".
enum StorefrontCapability {
  /// Brand / accent colour (swatches plus a custom picker).
  brandColour,

  /// Page background: the template's own treatments, plus a custom tint.
  background,

  /// A vendor photo behind the template's hero / banner.
  heroImage,

  /// Store name and tagline shown by the template (defaults to the
  /// vendor's Business Profile).
  identity,
}

/// Whether a template can be chosen today.
enum TemplateAvailability { available, comingSoon }

/// One background treatment a template offers ("Default", "Warm", ...).
@immutable
class StorefrontBackgroundOption {
  const StorefrontBackgroundOption(this.id, this.label, this.color);

  /// Stable id stored in `StorefrontBranding.backgroundId`.
  final String id;
  final String label;
  final Color color;
}

/// Everything a renderer receives: vendor data plus the resolved theme.
@immutable
class StorefrontRenderData {
  const StorefrontRenderData({
    required this.businessName,
    required this.items,
    required this.categories,
    required this.tokens,
  });

  final String businessName;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;
  final StorefrontThemeTokens tokens;
}

typedef StorefrontRendererBuilder = Widget Function(StorefrontRenderData data);

@immutable
class StorefrontTemplateDef {
  const StorefrontTemplateDef({
    required this.id,
    required this.name,
    required this.style,
    required this.description,
    required this.highlights,
    required this.tags,
    required this.capabilities,
    required this.defaults,
    required this.renderer,
    this.backgrounds = const [],
    this.previewAsset,
    this.availability = TemplateAvailability.available,
    this.version = 1,
  });

  /// Stable, persisted identifier (route entity id and branding key).
  /// Never shown to vendors, never renamed.
  final String id;

  /// Display name ("Arena"). Can change without touching any UI code.
  final String name;

  /// One-line layout style shown under the name ("Bold Showcase").
  final String style;

  /// Short description for Template Preview.
  final String description;

  /// Layout features listed on Template Preview.
  final List<String> highlights;

  /// Discovery tags (filter chips). Metadata only: any vendor may use any
  /// template.
  final List<String> tags;

  final Set<StorefrontCapability> capabilities;

  /// The template's own theme: accent colours, type treatment and default
  /// background. Store name/tagline stay empty -- they come from the vendor.
  final StorefrontBranding defaults;

  /// Page background treatments (first = the template default). Only read
  /// when [capabilities] contains [StorefrontCapability.background].
  final List<StorefrontBackgroundOption> backgrounds;

  /// Draws the customer-facing storefront.
  final StorefrontRendererBuilder renderer;

  /// Optional static thumbnail. When null the gallery renders a live
  /// miniature of [renderer] with the vendor's own data.
  final String? previewAsset;

  final TemplateAvailability availability;
  final int version;

  bool supports(StorefrontCapability c) => capabilities.contains(c);

  /// The page colour [branding] resolves to on this template.
  Color backgroundFor(StorefrontBranding branding) {
    if (!supports(StorefrontCapability.background) || backgrounds.isEmpty) {
      return backgrounds.isEmpty
          ? StorefrontThemeTokens.surface
          : backgrounds.first.color;
    }
    if (branding.backgroundId == kCustomBackgroundId &&
        branding.customBackground != null) {
      return branding.customBackground!;
    }
    return backgrounds
        .firstWhere(
          (b) => b.id == branding.backgroundId,
          orElse: () => backgrounds.first,
        )
        .color;
  }
}

/// Background treatments shared by the light templates. A template may
/// declare its own list instead.
const kLightBackgrounds = [
  StorefrontBackgroundOption(
    kTemplateBackgroundId,
    'Default',
    Color(0xFFF5F6F8),
  ),
  StorefrontBackgroundOption('white', 'White', Color(0xFFFFFFFF)),
  StorefrontBackgroundOption('warm', 'Warm', Color(0xFFF7F2EA)),
  StorefrontBackgroundOption('cool', 'Cool', Color(0xFFEEF3F9)),
];
