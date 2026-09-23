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
    final categories = ['All', ...kStorefrontTemplateCategories];
    return PageBody(
      children: [
        // First block sits at the top of the white surface (a leading
        // SectionHeading would add its section gap under the header).
        Text(
          'Current Storefront',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Gap.md),
        _CurrentStorefrontCard(def: active),
        const SectionHeading(
          'Explore Templates',
          subtitle: 'Choose a template and see how your products look.',
        ),
        SizedBox(
          height: Sizes.chipHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
            itemBuilder: (context, i) => CefChoiceChip(
              label: categories[i],
              selected: category == categories[i],
              onTap: () => setState(() => category = categories[i]),
            ),
          ),
        ),
        const SizedBox(height: Gap.lg),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: Gap.md,
            crossAxisSpacing: Gap.md,
            childAspectRatio: 0.8,
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
          icon: LucideIcons.package,
          onTap: () => app.go(VRoute.products),
        ),
      ],
    );
  }
}

class _CurrentStorefrontCard extends StatelessWidget {
  const _CurrentStorefrontCard({required this.def});
  final StorefrontTemplateDef def;

  static const _viewLabel = 'View Storefront';

  /// Whether the two page buttons fit side by side at the current width and
  /// text scale without truncating; otherwise they stack.
  static bool _buttonsFitInRow(BuildContext context, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(
        text: _viewLabel,
        // CefButton's label metrics.
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    // Label + the button's horizontal padding.
    final needed = painter.width + Gap.lg * 2;
    painter.dispose();
    return needed <= (maxWidth - Gap.md) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final view = CefButton(
      _viewLabel,
      secondary: true,
      onTap: () => app.go(VRoute.storefrontPreview),
    );
    final customize = CefButton(
      'Customize',
      onTap: () => app.go(VRoute.branding),
    );
    return CefCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: _TemplateArt(def: def, radius: 12, iconScale: .4),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      def.typeTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gap.sm),
              const StatusChip('Active'),
            ],
          ),
          const SizedBox(height: Gap.lg),
          LayoutBuilder(
            builder: (context, box) => _buttonsFitInRow(context, box.maxWidth)
                ? Row(
                    children: [
                      Expanded(child: view),
                      const SizedBox(width: Gap.md),
                      Expanded(child: customize),
                    ],
                  )
                : Column(
                    children: [
                      view,
                      const SizedBox(height: Gap.sm),
                      customize,
                    ],
                  ),
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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // The one card: yellow selected outline marks the active template; the
    // template art keeps its own identity inside it.
    return CefCard(
      padded: false,
      selected: isActive,
      onTap: onOpen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Sizes.cardRadius - 1),
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
                      top: Gap.sm,
                      left: Gap.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CefColors.accent,
                          borderRadius: BorderRadius.circular(
                            Sizes.buttonRadius,
                          ),
                        ),
                        child: Text(
                          'Active',
                          style: text.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CefColors.onAccent,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: Gap.sm,
                    bottom: Gap.sm,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.arrowUpRight,
                        size: 14,
                        color: CefColors.onAccent,
                      ),
                    ),
                  ),
                  Positioned(
                    left: Gap.md,
                    bottom: Gap.md,
                    right: 44,
                    child: Text(
                      def.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.md,
                vertical: Gap.sm,
              ),
              child: Text(
                def.typeTag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
            Gap.gutter,
            Gap.md,
            Gap.gutter,
            Gap.md + MediaQuery.of(context).viewPadding.bottom,
          ),
          decoration: BoxDecoration(
            color: context.c.chrome,
            border: Border(top: BorderSide(color: context.c.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: CefButton(
                  'Back',
                  secondary: true,
                  onTap: () => app.back(),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                flex: 2,
                child: CefButton(
                  isActive ? 'Currently Active' : 'Use This Template',
                  onTap: isActive
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
