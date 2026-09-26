/// Storefront management: V-31 Storefront (current storefront + Explore
/// Templates), X-02 Template Preview and V-32 View storefront. Customize
/// (V-33) lives in `storefront_customize.dart`.
///
/// Everything here renders from the template registry
/// (`templates/template_registry.dart`) through the generic surfaces in
/// `shared/storefront_surface.dart`; no screen branches on a template id.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_state.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../shell.dart';
import '../../system_bars.dart';
import '../../widgets.dart';
import 'shared/storefront_surface.dart';
import 'shared/template_definition.dart';
import 'templates/template_registry.dart';

/// Capability names as shown to vendors.
const _capabilityLabels = {
  StorefrontCapability.brandColour: 'Brand colour',
  StorefrontCapability.background: 'Background',
  StorefrontCapability.heroImage: 'Hero image',
  StorefrontCapability.identity: 'Store name',
};

/// The template's own colour field behind its miniature: the storefront's
/// brand, not the Vendor app's blue.
BoxDecoration storefrontStageDecoration(Color accent) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.lerp(accent, Colors.black, .45)!,
      Color.lerp(accent, Colors.black, .15)!,
    ],
  ),
);

/// Round control over a storefront visual (Back, Close).
class StorefrontOverlayButton extends StatelessWidget {
  const StorefrontOverlayButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.light = true,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// Light glyph on a dark visual; dark glyph on a light one.
  final bool light;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tooltip,
    child: Material(
      color: light ? Colors.black.withValues(alpha: .28) : context.c.subtle,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: Sizes.tapTarget,
          child: Icon(
            icon,
            size: 22,
            color: light ? Colors.white : CefColors.navy,
          ),
        ),
      ),
    ),
  );
}

/// Small semantic-green "Active" mark.
class _ActiveMark extends StatelessWidget {
  const _ActiveMark({this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final green = context.c.success;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: green, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          'Active',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: onDark ? Colors.white : green),
        ),
      ],
    );
  }
}

/// Filter chip: Cefflo blue when selected (the selection colour), outline
/// otherwise.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? CefColors.brand : c.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? CefColors.brand : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: Sizes.chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: selected ? Colors.white : c.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// A phone-shaped frame around a storefront miniature.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child, this.radius = 22});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: kStorefrontViewport.width / kStorefrontViewport.height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    ),
  );
}

// ------------------------------------------------------------ V-31

/// V-31 -- Storefront. The live storefront as the dominant visual (running
/// behind the transparent status bar), then Explore Templates: registry-
/// driven filters and a gallery of real miniature storefronts.
class StorefrontScreen extends StatefulWidget {
  const StorefrontScreen({super.key});

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  static const _all = 'All';
  String _filter = _all;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final active = storefrontTemplateById(app.activeStorefrontTemplateId);
    final filters = [_all, ...storefrontTemplateTags()];
    final visible = _filter == _all
        ? kStorefrontTemplates
        : kStorefrontTemplates.where((t) => t.tags.contains(_filter)).toList();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return CefSystemBars.split(
      statusBarBackground: Brightness.dark,
      navigationBarBackground: Brightness.light,
      child: ColoredBox(
        color: context.c.card,
        child: StorefrontCatalogueLoader(
          builder: (context, catalogue) => ListView(
            padding: EdgeInsets.only(bottom: Gap.lg + bottomInset),
            children: [
              _CurrentStorefrontHero(def: active, catalogue: catalogue),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.gutter,
                  Gap.xxl,
                  Gap.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Explore Templates', style: text.titleMedium),
                    const SizedBox(height: Gap.xs),
                    Text(
                      'Preview any layout with your own products.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
              SizedBox(
                height: Sizes.chipHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Gap.gutter),
                  itemCount: filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
                  itemBuilder: (context, i) => _FilterChip(
                    label: filters[i],
                    selected: _filter == filters[i],
                    onTap: () => setState(() => _filter = filters[i]),
                  ),
                ),
              ),
              const SizedBox(height: Gap.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.gutter),
                child: visible.isEmpty
                    ? const StateBlock.empty('No templates here yet.')
                    : _TemplateGrid(
                        templates: visible,
                        activeId: active.id,
                        catalogue: catalogue,
                      ),
              ),
              const SizedBox(height: Gap.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.gutter),
                child: Column(
                  children: [
                    const CefDivider(),
                    CefListRow(
                      title: 'Products',
                      subtitle: 'Every template shows these products',
                      icon: LucideIcons.package,
                      showDivider: false,
                      onTap: () => app.go(VRoute.products),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The active storefront, full bleed: its miniature rises from the bottom
/// of the template's own colour field; Back, name, Active and the two
/// actions sit over it.
class _CurrentStorefrontHero extends StatelessWidget {
  const _CurrentStorefrontHero({required this.def, required this.catalogue});
  final StorefrontTemplateDef def;
  final StorefrontCatalogue catalogue;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final branding = storefrontBrandingFor(app, def);
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final height = (media.size.height * .62).clamp(470.0, 600.0);
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: storefrontStageDecoration(branding.primary),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // The storefront itself, a phone rising from the bottom edge.
            Positioned(
              top: top + Sizes.header + Gap.xs,
              bottom: -Gap.xxxl * 2,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => app.go(VRoute.storefrontPreview),
                  child: _PhoneFrame(
                    child: StorefrontMiniature(
                      def: def,
                      branding: branding,
                      catalogue: catalogue,
                    ),
                  ),
                ),
              ),
            ),
            // Legibility scrim for the overlay text and actions.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 250,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, .42, 1],
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: .82),
                        Colors.black.withValues(alpha: .9),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: top + (Sizes.header - Sizes.tapTarget) / 2,
              left: Gap.lg,
              right: Gap.lg,
              child: Row(
                children: [
                  StorefrontOverlayButton(
                    icon: LucideIcons.arrowLeft,
                    tooltip: 'Back',
                    onTap: app.back,
                  ),
                  Expanded(
                    child: Text(
                      'Storefront',
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: Sizes.tapTarget),
                ],
              ),
            ),
            Positioned(
              left: Gap.gutter,
              right: Gap.gutter,
              bottom: Gap.gutter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          def.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      const _ActiveMark(onDark: true),
                    ],
                  ),
                  Text(
                    def.style,
                    style: text.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: .8),
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _GlassButton(
                          label: 'View storefront',
                          onTap: () => app.go(VRoute.storefrontPreview),
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: CefButton(
                          'Customize',
                          onTap: () =>
                              app.go(VRoute.branding, entityId: def.id),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary action over a dark visual: translucent white pill.
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: Colors.white.withValues(alpha: .16),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: .5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: Sizes.buttonHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.md),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Explore Templates: any number of entries, two per row on phones.
class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid({
    required this.templates,
    required this.activeId,
    required this.catalogue,
  });
  final List<StorefrontTemplateDef> templates;
  final String activeId;
  final StorefrontCatalogue catalogue;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 600 ? 3 : 2;
      final width = (box.maxWidth - Gap.md * (columns - 1)) / columns;
      return Wrap(
        spacing: Gap.md,
        runSpacing: Gap.xl,
        children: [
          for (final t in templates)
            SizedBox(
              width: width,
              child: _TemplateTile(
                def: t,
                active: t.id == activeId,
                catalogue: catalogue,
              ),
            ),
        ],
      );
    },
  );
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.def,
    required this.active,
    required this.catalogue,
  });
  final StorefrontTemplateDef def;
  final bool active;
  final StorefrontCatalogue catalogue;

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final text = Theme.of(context).textTheme;
    final available = def.availability == TemplateAvailability.available;
    return Semantics(
      button: available,
      selected: active,
      label: '${def.name}, ${def.style}${active ? ', active' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: available
            ? () => app.go(VRoute.storefrontTemplatePreview, entityId: def.id)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: .74,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(
                        color: active ? CefColors.brand : c.border,
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_radius),
                      child: Opacity(
                        opacity: available ? 1 : .5,
                        child: StorefrontMiniature(
                          def: def,
                          branding: storefrontBrandingFor(app, def),
                          catalogue: catalogue,
                        ),
                      ),
                    ),
                  ),
                  if (active)
                    Positioned(
                      top: Gap.sm,
                      right: Gap.sm,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: CefColors.brand,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Gap.md),
            Row(
              children: [
                Flexible(
                  child: Text(
                    def.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: Gap.sm),
                  const _ActiveMark(),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              available ? def.style : 'Coming soon',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ X-02

/// X-02 -- Template Preview: the template, large and live (tap through it
/// with your own products), then what it is and one action. Nothing is
/// activated here -- Use This Template continues to Customize.
class StorefrontTemplatePreviewScreen extends StatelessWidget {
  const StorefrontTemplatePreviewScreen({super.key, required this.templateId});
  final String templateId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final def = storefrontTemplateById(templateId);
    final isActive = def.id == app.activeStorefrontTemplateId;
    final branding = storefrontBrandingFor(app, def);
    final media = MediaQuery.of(context);
    final text = Theme.of(context).textTheme;
    final stageHeight = (media.size.height * .62).clamp(470.0, 640.0);
    final capabilities = [
      for (final e in _capabilityLabels.entries)
        if (def.supports(e.key)) e.value,
    ];
    return CefSystemBars.split(
      statusBarBackground: Brightness.dark,
      navigationBarBackground: Brightness.light,
      child: ColoredBox(
        color: context.c.card,
        child: StorefrontCatalogueLoader(
          builder: (context, catalogue) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(
                      height: stageHeight,
                      child: DecoratedBox(
                        decoration: storefrontStageDecoration(branding.primary),
                        child: Stack(
                          children: [
                            Positioned(
                              top: media.padding.top + Sizes.header + Gap.xs,
                              bottom: Gap.xl,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _PhoneFrame(
                                  radius: 24,
                                  child: StorefrontMiniature(
                                    def: def,
                                    branding: branding,
                                    catalogue: catalogue,
                                    interactive: true,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top:
                                  media.padding.top +
                                  (Sizes.header - Sizes.tapTarget) / 2,
                              left: Gap.lg,
                              child: StorefrontOverlayButton(
                                icon: LucideIcons.arrowLeft,
                                tooltip: 'Back',
                                onTap: app.back,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Gap.gutter,
                        Gap.xxl,
                        Gap.gutter,
                        Gap.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(def.name, style: text.titleLarge),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: Gap.md),
                                const _ActiveMark(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            def.style,
                            style: text.titleSmall?.copyWith(
                              color: context.c.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: Gap.md),
                          Text(def.description, style: text.bodyMedium),
                          const SizedBox(height: Gap.lg),
                          for (final h in def.highlights)
                            Padding(
                              padding: const EdgeInsets.only(bottom: Gap.sm),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.check,
                                    size: 18,
                                    color: CefColors.brand,
                                  ),
                                  const SizedBox(width: Gap.md),
                                  Expanded(
                                    child: Text(h, style: text.bodyLarge),
                                  ),
                                ],
                              ),
                            ),
                          if (capabilities.isNotEmpty) ...[
                            const SizedBox(height: Gap.sm),
                            Text(
                              'Customize: ${capabilities.join(' · ')}',
                              style: text.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              StickyActionBar(
                child: CefButton(
                  isActive ? 'Customize' : 'Use This Template',
                  onTap: () => app.go(VRoute.branding, entityId: def.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ V-32

/// V-32 -- View storefront: the live storefront at full size, exactly as
/// customers get it, under a slim close bar.
class LiveStorefrontScreen extends StatelessWidget {
  const LiveStorefrontScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final def = storefrontTemplateById(app.activeStorefrontTemplateId);
    final branding = storefrontBrandingFor(app, def);
    final text = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    return CefSystemBars(
      background: Brightness.light,
      child: ColoredBox(
        color: context.c.card,
        child: Column(
          children: [
            SizedBox(height: media.padding.top),
            SizedBox(
              height: Sizes.header,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                child: Row(
                  children: [
                    StorefrontOverlayButton(
                      icon: LucideIcons.x,
                      tooltip: 'Close',
                      light: false,
                      onTap: app.back,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Your storefront', style: text.titleSmall),
                          Text(
                            '${def.name} · ${def.style}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Sizes.tapTarget),
                  ],
                ),
              ),
            ),
            const CefDivider(),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: StorefrontCatalogueLoader(
                  builder: (context, catalogue) => StorefrontSurface(
                    def: def,
                    branding: branding,
                    catalogue: catalogue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
