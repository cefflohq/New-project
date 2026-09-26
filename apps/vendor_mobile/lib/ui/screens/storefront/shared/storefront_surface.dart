/// Generic template rendering: resolves a template + the vendor's
/// customization + the vendor's catalogue into the template's renderer.
/// Used by the gallery miniatures, Template Preview, Customize's live
/// preview and View storefront -- none of which know which template they
/// draw.
library;

import 'package:flutter/material.dart';

import '../../../../core/app_state.dart';
import '../../../../data/models.dart';
import '../../../../data/storefront_catalog.dart';
import '../../../../data/storefront_config.dart';
import 'storefront_theme.dart';
import 'template_definition.dart';

/// The logical phone viewport every template is laid out in before a
/// miniature scales it down.
const kStorefrontViewport = Size(390, 800);

/// The customization a template renders with for this vendor: their saved
/// customization, else the template defaults -- with the store name falling
/// back to the vendor's Business Profile, never to demo copy.
StorefrontBranding storefrontBrandingFor(
  AppState app,
  StorefrontTemplateDef def,
) {
  final branding = app.savedStorefrontBranding(def.id) ?? def.defaults;
  if (branding.storeName.isNotEmpty) return branding;
  return branding.copyWith(storeName: app.business?.name ?? 'Your store');
}

/// The vendor's catalogue in storefront shape. Loaded once per screen and
/// shared by every template on it.
@immutable
class StorefrontCatalogue {
  const StorefrontCatalogue(this.items, this.categories);
  factory StorefrontCatalogue.from(List<Product> products) {
    final items = storefrontItemsFrom(products);
    return StorefrontCatalogue(items, storefrontCategoriesFrom(items));
  }

  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;
}

/// Loads the vendor's products once and hands them to [builder]. While
/// loading it paints a quiet blank (it often sits inside a small preview,
/// where a page skeleton would not fit); if loading fails the templates
/// preview with the neutral fixture catalogue rather than an error inside
/// a thumbnail.
class StorefrontCatalogueLoader extends StatefulWidget {
  const StorefrontCatalogueLoader({super.key, required this.builder});
  final Widget Function(BuildContext context, StorefrontCatalogue catalogue)
  builder;

  @override
  State<StorefrontCatalogueLoader> createState() =>
      _StorefrontCatalogueLoaderState();
}

class _StorefrontCatalogueLoaderState extends State<StorefrontCatalogueLoader> {
  late final Future<StorefrontCatalogue> _catalogue = _load();

  Future<StorefrontCatalogue> _load() async {
    final app = AppScope.read(context);
    final business = app.business;
    try {
      final products = business == null
          ? const <Product>[]
          : await app.repo.products(business.id);
      return StorefrontCatalogue.from(products);
    } catch (_) {
      return StorefrontCatalogue.from(const []);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StorefrontCatalogue>(
    future: _catalogue,
    builder: (context, snap) => snap.hasData
        ? widget.builder(context, snap.data!)
        : const SizedBox.expand(),
  );
}

/// One template drawn full size with [branding] and [catalogue].
class StorefrontSurface extends StatelessWidget {
  const StorefrontSurface({
    super.key,
    required this.def,
    required this.branding,
    required this.catalogue,
  });

  final StorefrontTemplateDef def;
  final StorefrontBranding branding;
  final StorefrontCatalogue catalogue;

  @override
  Widget build(BuildContext context) {
    final tokens = StorefrontThemeTokens(
      branding,
      background: def.backgroundFor(branding),
    );
    return ColoredBox(
      color: tokens.background,
      child: def.renderer(
        StorefrontRenderData(
          businessName: branding.storeName,
          items: catalogue.items,
          categories: catalogue.categories,
          tokens: tokens,
        ),
      ),
    );
  }
}

/// A template laid out at [kStorefrontViewport] and scaled to fit its
/// slot: the real storefront in miniature, not an illustration of it.
/// Non-interactive unless [interactive].
class StorefrontMiniature extends StatelessWidget {
  const StorefrontMiniature({
    super.key,
    required this.def,
    required this.branding,
    required this.catalogue,
    this.interactive = false,
    this.viewport = kStorefrontViewport,
  });

  final StorefrontTemplateDef def;
  final StorefrontBranding branding;
  final StorefrontCatalogue catalogue;
  final bool interactive;
  final Size viewport;

  @override
  Widget build(BuildContext context) {
    final asset = def.previewAsset;
    if (asset != null && !interactive) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }
    final page = MediaQuery(
      // The miniature is its own little phone: no system insets, no
      // user text scaling blowing up a scaled-down layout.
      data: MediaQuery.of(context).copyWith(
        size: viewport,
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        textScaler: TextScaler.noScaling,
      ),
      child: SizedBox.fromSize(
        size: viewport,
        child: StorefrontSurface(
          def: def,
          branding: branding,
          catalogue: catalogue,
        ),
      ),
    );
    return RepaintBoundary(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          child: interactive ? page : IgnorePointer(child: page),
        ),
      ),
    );
  }
}
