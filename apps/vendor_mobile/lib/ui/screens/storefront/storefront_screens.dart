/// Storefront: Template Library (Screen 01) and Template Preview (Screen
/// 02). See `storefront_customize.dart` for Screen 03 (Customize {Template
/// Name}) and module doc comments in `storefront_common.dart` /
/// `storefront_config.dart` / `storefront_templates.dart` for the shared
/// commerce flow, the presentation-config boundary and the scalable
/// template registry respectively.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_state.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models.dart';
import '../../../data/storefront_catalog.dart';
import '../../../data/storefront_config.dart';
import '../../../data/storefront_templates.dart';
import '../../async_view.dart';
import '../../shell.dart';
import '../../widgets.dart';
import 'storefront_theme.dart';
import 'template_bag_drop.dart';
import 'template_browse_shop.dart';
import 'template_catalogue.dart';
import 'template_discover_market.dart';
import 'template_match_day.dart';
import 'template_origin_run.dart';
import 'template_quick_order.dart';
import 'template_ritual_care.dart';
import 'template_tide_table.dart';

/// Renders the right renderer engine for [template], themed and branded
/// from [branding], fed by [items]/[categories]. No AppState/repository
/// coupling here so the exact same widget can render a saved-selection
/// preview and a live, unsaved customize-mode draft.
class StorefrontPreviewSurface extends StatelessWidget {
  const StorefrontPreviewSurface({
    super.key,
    required this.template,
    required this.branding,
    required this.items,
    required this.categories,
  });

  final StorefrontTemplate template;
  final StorefrontBranding branding;
  final List<StorefrontItem> items;
  final List<StorefrontCategory> categories;

  @override
  Widget build(BuildContext context) {
    final tokens = StorefrontThemeTokens(branding);
    // The template's own on-brand name, not the vendor's internal Cefflo
    // business name -- the customer-facing chrome should read "LUMA", not
    // whatever the vendor typed as their Cefflo account name.
    final businessName = branding.storeName.isNotEmpty
        ? branding.storeName
        : 'Your Storefront';
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
      StorefrontTemplate.matchDay => MatchDayPreview(
        businessName: businessName,
        items: items,
        categories: categories,
        tokens: tokens,
      ),
      StorefrontTemplate.discoverMarket => DiscoverMarketPreview(
        businessName: businessName,
        items: items,
        categories: categories,
        tokens: tokens,
      ),
      StorefrontTemplate.ritualCare => RitualCarePreview(
        businessName: businessName,
        items: items,
        categories: categories,
        tokens: tokens,
      ),
      StorefrontTemplate.bagDrop => BagDropPreview(
        businessName: businessName,
        items: items,
        categories: categories,
        tokens: tokens,
      ),
      StorefrontTemplate.originRun => OriginRunPreview(
        businessName: businessName,
        items: items,
        categories: categories,
        tokens: tokens,
      ),
      StorefrontTemplate.tideTable => TideTablePreview(
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
/// Template Preview screen and the Customize screen's "See Live Preview".
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
          template: template,
          branding: branding,
          items: items,
          categories: categories,
        );
      },
    );
  }
}

/// Small gradient-plus-icon stand-in for a real preview photo, reused at
/// different sizes for the Current Storefront thumbnail and each Explore
/// Templates card (no network images in this prototype's asset pipeline).
class _TemplateArt extends StatelessWidget {
  const _TemplateArt({
    required this.def,
    this.radius = 14,
    this.iconScale = 0.34,
  });
  final StorefrontTemplateDef def;
  final double radius;
  final double iconScale;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: def.previewColors,
      ),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: LayoutBuilder(
      builder: (context, c) => Icon(
        def.previewIcon,
        size: c.maxWidth.isFinite ? (c.maxWidth * iconScale).clamp(18, 56) : 32,
        color: Colors.white.withValues(alpha: .55),
      ),
    ),
  );
}

/// V-31 -- Storefront. "Current Storefront" (compact, the active template)
/// above "Explore Templates" (the scalable library gallery, filterable by
/// category). Reference: primary spec image, Screen 01.
class StorefrontScreen extends StatefulWidget {
  const StorefrontScreen({super.key});

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  String category = 'All';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final active = app.activeStorefrontTemplate;
    final visible = category == 'All'
        ? kStorefrontTemplateLibrary
        : kStorefrontTemplateLibrary
              .where((t) => t.category == category)
              .toList();
    return PageBody(
      children: [
        const SectionHeading('Current Storefront'),
        _CurrentStorefrontCard(def: active),
        const SectionHeading('Explore Templates'),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            'Choose a template and see how your products look.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryChip(
                label: 'All',
                selected: category == 'All',
                onTap: () => setState(() => category = 'All'),
              ),
              for (final cat in kStorefrontTemplateCategories)
                _CategoryChip(
                  label: cat,
                  selected: category == cat,
                  onTap: () => setState(() => category = cat),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, i) => _TemplateGalleryCard(
            def: visible[i],
            isActive: visible[i].id == active.id,
            onOpen: () => app.go(
              VRoute.storefrontTemplatePreview,
              entityId: visible[i].id,
            ),
          ),
        ),
        const SectionHeading('Manage'),
        CefListRow(
          title: 'Products',
          subtitle: 'Manage catalog items',
          leading: Icon(
            LucideIcons.package,
            size: Sizes.icon,
            color: context.c.iconColor,
          ),
          onTap: () => app.go(VRoute.products),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? CefColors.accent : c.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? CefColors.accent : c.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? CefColors.onAccent : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentStorefrontCard extends StatelessWidget {
  const _CurrentStorefrontCard({required this.def});
  final StorefrontTemplateDef def;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CefCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: _TemplateArt(def: def, radius: 12, iconScale: .4),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            def.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.c.success.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: context.c.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      def.typeTag,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                  child: OutlinedButton.icon(
                    onPressed: () => app.go(VRoute.storefrontPreview),
                    icon: const Icon(LucideIcons.externalLink, size: 15),
                    label: const Text(
                      'View Storefront',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.c.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: () => app.go(VRoute.branding),
                    style: FilledButton.styleFrom(
                      backgroundColor: CefColors.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Customize',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateGalleryCard extends StatelessWidget {
  const _TemplateGalleryCard({
    required this.def,
    required this.isActive,
    required this.onOpen,
  });
  final StorefrontTemplateDef def;
  final bool isActive;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(Sizes.cardRadius),
    child: InkWell(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
          border: Border.all(
            color: isActive ? CefColors.accent : context.c.border,
            width: isActive ? 1.6 : 1,
          ),
          boxShadow: cefCardShadow(Theme.of(context).brightness),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _TemplateArt(def: def, radius: 0),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: .55),
                        ],
                        stops: const [0.4, 1],
                      ),
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: CefColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: CefColors.onAccent,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.arrowUpRight,
                        size: 14,
                        color: Color(0xFF14171C),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    right: 40,
                    child: Text(
                      def.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Text(
                def.typeTag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: context.c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// V-32 -- Storefront preview, bound to whichever template is currently
/// active. X-02 -- Template Preview for any single library entry
/// (regardless of what's currently active), reached from each Explore
/// Templates card. Header ("Template Preview" + subtitle) is rendered by
/// [VendorShell]; this screen owns the realistic render + the
/// Back/Use This Template bar.
class StorefrontTemplatePreviewScreen extends StatelessWidget {
  const StorefrontTemplatePreviewScreen({super.key, this.templateId});
  final String? templateId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final def = templateId == null
        ? app.activeStorefrontTemplate
        : storefrontTemplateById(templateId!);
    final branding = app.brandingFor(def.id);
    final isActive = def.id == app.activeStorefrontTemplateId;
    return Column(
      children: [
        Expanded(
          child: Container(
            color: StorefrontThemeTokens.surface,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: StorefrontCatalogueBoundPreview(
              template: def.renderer,
              branding: branding,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.of(context).viewPadding.bottom,
          ),
          decoration: BoxDecoration(
            color: context.c.chrome,
            border: Border(top: BorderSide(color: context.c.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => app.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.c.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: isActive
                        ? null
                        : () {
                            app.useStorefrontTemplate(def.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${def.name} is now your active storefront.',
                                ),
                              ),
                            );
                            app.back();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: context.c.info,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: context.c.info.withValues(
                        alpha: .5,
                      ),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      isActive ? 'Currently Active' : 'Use This Template',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
