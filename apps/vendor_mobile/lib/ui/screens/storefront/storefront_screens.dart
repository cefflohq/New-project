/// Storefront: template selector, template preview host and brand colour
/// customization. This is the only place these three concerns live -- see
/// module doc comments in `storefront_common.dart` / `storefront_config.dart`
/// for the shared commerce flow and the presentation-config boundary.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_state.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models.dart';
import '../../../data/storefront_catalog.dart';
import '../../../data/storefront_config.dart';
import '../../async_view.dart';
import '../../shell.dart';
import '../../widgets.dart';
import 'storefront_theme.dart';
import 'template_browse_shop.dart';
import 'template_catalogue.dart';
import 'template_quick_order.dart';

Widget _icon(BuildContext context, IconData icon) =>
    Icon(icon, size: Sizes.icon, color: context.c.iconColor);

/// Renders the right template for [template], themed from [branding], fed by
/// [items]/[categories]. No AppState/repository coupling here so the exact
/// same widget can render a saved-selection preview and a live, unsaved
/// customize-mode draft.
class StorefrontPreviewSurface extends StatelessWidget {
  const StorefrontPreviewSurface({
    super.key,
    required this.businessName,
    required this.template,
    required this.branding,
    required this.items,
    required this.categories,
  });

  final String businessName;
  final StorefrontTemplate template;
  final StorefrontBranding branding;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;

  @override
  Widget build(BuildContext context) {
    final tokens = StorefrontThemeTokens(branding);
    final surface = switch (template) {
      StorefrontTemplate.browseShop => BrowseShopPreview(
        businessName: businessName,
        items: items,
        categories: categories,
        tokens: tokens,
      ),
      StorefrontTemplate.quickOrder => QuickOrderPreview(
        businessName: businessName,
        items: items,
        categories: categories,
        tokens: tokens,
      ),
      StorefrontTemplate.catalogue => CataloguePreview(
        businessName: businessName,
        items: items,
        categories: categories,
        tokens: tokens,
      ),
    };
    // Fixed device-like frame so the preview reads as "what my customer will
    // see" rather than app content stretched to fill the vendor screen.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white),
            child: surface,
          ),
        ),
      ),
    );
  }
}

/// Loads the vendor's real catalogue (falling back to fixtures only when it
/// is empty) and hands it to [StorefrontPreviewSurface]. Reused by both the
/// plain Preview route and the Customize screen's live preview tab.
class StorefrontCatalogueBoundPreview extends StatelessWidget {
  const StorefrontCatalogueBoundPreview({
    super.key,
    required this.template,
    required this.branding,
  });

  final StorefrontTemplate template;
  final StorefrontBranding branding;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<List<Product>>(
      key: ValueKey('storefront-catalog-${app.business?.id}'),
      load: () => app.business == null
          ? Future.value(const <Product>[])
          : app.repo.products(app.business!.id),
      builder: (context, products, _) {
        final items = storefrontItemsFrom(products);
        final categories = storefrontCategoriesFrom(items);
        return StorefrontPreviewSurface(
          businessName: app.business?.name ?? 'Your Storefront',
          template: template,
          branding: branding,
          items: items,
          categories: categories,
        );
      },
    );
  }
}

/// V-31 -- Storefront. Template selector: exactly the 3 templates, each
/// previewable and selectable, with a clear current-selection state. Manage
/// links (brand customization, products) sit below, unchanged in destination
/// from the previous Storefront menu.
class StorefrontScreen extends StatelessWidget {
  const StorefrontScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final selected = app.selectedStorefrontTemplate;
    return PageBody(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF102344), Color(0xFF1453B7), Color(0xFF12213E)],
            ),
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STOREFRONT',
                style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8),
              ),
              const SizedBox(height: 6),
              const Text('Choose how customers shop with you.',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Pick a template, preview it, then customize your brand colour.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            ],
          ),
        ),
        const SectionHeading('Templates'),
        for (final t in StorefrontTemplate.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TemplateCard(
              template: t,
              isSelected: t == selected,
              onPreview: () => app.go(VRoute.storefrontTemplatePreview, entityId: t.key),
              onSelect: () => app.selectStorefrontTemplate(t),
            ),
          ),
        const SectionHeading('Manage'),
        FlatListRow(
          title: 'Customize brand',
          subtitle: 'Colours, logo and tagline',
          leading: _icon(context, LucideIcons.palette),
          onTap: () => app.go(VRoute.branding),
        ),
        FlatListRow(
          title: 'Products',
          subtitle: 'Manage catalog items',
          leading: _icon(context, LucideIcons.package),
          onTap: () => app.go(VRoute.products),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onPreview,
    required this.onSelect,
  });

  final StorefrontTemplate template;
  final bool isSelected;
  final VoidCallback onPreview;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => CefCard(
    selected: isSelected,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(template: template),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(template.label, style: Theme.of(context).textTheme.titleSmall),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: CefColors.accent, borderRadius: BorderRadius.circular(999)),
                          child: const Text('Selected', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: CefColors.onAccent)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(template.tagline, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: template.defaultColor)),
                  const SizedBox(height: 4),
                  Text(template.description, style: Theme.of(context).textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onPreview,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.c.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text('Preview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: isSelected ? null : onSelect,
                  style: FilledButton.styleFrom(
                    backgroundColor: CefColors.accent,
                    foregroundColor: CefColors.onAccent,
                    disabledBackgroundColor: context.c.card,
                    disabledForegroundColor: context.c.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text(isSelected ? 'In Use' : 'Use Template', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Small schematic layout thumbnail -- not a literal screenshot -- that
/// visually distinguishes the 3 templates at a glance (grid vs. list vs.
/// collection tiles), tinted with the template's default colour.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.template});
  final StorefrontTemplate template;

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: template.defaultColor.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: switch (template) {
      StorefrontTemplate.browseShop => Column(
        children: [
          _bar(template.defaultColor, height: 14),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _block(template.defaultColor)),
                const SizedBox(width: 4),
                Expanded(child: _block(template.defaultColor.withValues(alpha: .5))),
              ],
            ),
          ),
        ],
      ),
      StorefrontTemplate.quickOrder => Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == 2 ? 0 : 4),
              child: _bar(template.defaultColor.withValues(alpha: i == 0 ? 1 : .4), height: 11),
            ),
        ],
      ),
      StorefrontTemplate.catalogue => Column(
        children: [
          Expanded(flex: 2, child: _block(template.defaultColor)),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _block(template.defaultColor.withValues(alpha: .6))),
                const SizedBox(width: 4),
                Expanded(child: _block(template.defaultColor.withValues(alpha: .3))),
              ],
            ),
          ),
        ],
      ),
    },
  );

  Widget _bar(Color color, {required double height}) => Container(
    width: double.infinity,
    height: height,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
  );

  Widget _block(Color color) => Container(
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
  );
}

/// V-32 -- Storefront preview, bound to the vendor's currently selected
/// template. X-02 -- an explicit per-template preview (any of the 3,
/// regardless of what's currently selected), reachable from each template
/// card's Preview action.
class StorefrontTemplatePreviewScreen extends StatelessWidget {
  const StorefrontTemplatePreviewScreen({super.key, this.templateKey});
  final String? templateKey;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final template = templateKey == null
        ? app.selectedStorefrontTemplate
        : StorefrontTemplate.fromKey(templateKey);
    return Container(
      color: StorefrontThemeTokens.surface,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StorefrontCatalogueBoundPreview(template: template, branding: app.storefrontBranding),
    );
  }
}
