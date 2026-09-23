import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import 'system_bars.dart';
import 'widgets.dart';

/// First-time business setup (V06-V10). Before the business exists there is
/// nothing for Orders/Products/Customers/More to show, so the wizard hides
/// the primary bottom navigation instead of exposing a shell it can't serve.
const _onboardingRoutes = {
  VRoute.welcomeSetup,
  VRoute.setupBusinessInfo,
  VRoute.setupAddress,
  VRoute.setupServiceArea,
  VRoute.setupComplete,
};

/// Header copy that differs from the route inventory name. Every other route
/// shows its `RouteSpec.title`. Sentence case like every other page title.
const _headerTitles = <VRoute, String>{
  VRoute.reviewDispatch: 'Review delivery plan',
  VRoute.runDetail: 'Active run',
  VRoute.riderRegistrationLink: 'Invite rider',
  VRoute.helperRegistrationLink: 'Invite team member',
};

/// Small subtitle shown under the page title, for routes where the spec
/// calls for one (Screen 02 -- Template Preview).
const _headerSubtitles = <VRoute, String>{
  VRoute.storefrontPreview: 'See how your products look with this template',
  VRoute.storefrontTemplatePreview:
      'See how your products look with this template',
};

/// Primary destinations (bottom-nav roots): no back arrow.
const _tabRoots = {VRoute.today, VRoute.orders, VRoute.zones, VRoute.riders};

/// Detail-hero archetype: the screen renders its identity hero on the
/// gradient through [HeroPage] and owns its white surface. These are focused
/// detail views without bottom nav.
const _heroRoutes = {
  VRoute.orderDetail,
  VRoute.riderDetail,
  VRoute.teamMemberDetail,
  VRoute.customerDetail,
};

/// Focused flows that hide the primary bottom navigation: dispatch review
/// and an active run carry their own bottom actions, and the storefront
/// previews render an immersive customer-facing view the vendor nav would
/// break.
const _focusedRoutes = {
  VRoute.reviewDispatch,
  VRoute.runDetail,
  VRoute.storefrontPreview,
  VRoute.storefrontTemplatePreview,
};

/// Routes that render their own [AppHeader] (dynamic title, trailing
/// actions wired to screen-local state) -- in white on the shell's brand
/// backdrop, above a [ContentSurface] -- e.g. Screen 03, Customize
/// {Template Name}, whose Reset action needs the screen's draft state. No
/// default header or bottom nav is rendered for these.
const _ownChromeRoutes = {VRoute.branding};

/// One edge-to-edge canvas: the CEFFLO brand gradient starts at the very
/// top of the screen (behind the transparent status bar) and carries the
/// header; the page's white surface enters below it with rounded top
/// corners; the white bottom navigation (or, without it, the surface
/// itself) continues behind the transparent gesture area. Content sits
/// between header and nav in a Column, so it never scrolls under the nav.
class VendorShell extends StatelessWidget {
  const VendorShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final route = app.current.route;
    final ownChrome = _ownChromeRoutes.contains(route);
    final hero = _heroRoutes.contains(route);
    // While the keyboard is up the nav would ride above it and eat the
    // form's space; it returns as soon as the keyboard closes.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showNav =
        !ownChrome &&
        !hero &&
        !keyboardOpen &&
        !_onboardingRoutes.contains(route) &&
        !_focusedRoutes.contains(route);

    // Own-chrome routes draw their own AppHeader (white, on this same
    // backdrop) above a ContentSurface.
    final body = ownChrome
        ? child
        : Column(
            children: [
              _Header(app: app),
              Expanded(
                child: hero
                    ? child
                    : ContentSurface(bottomSafeArea: !showNav, child: child),
              ),
              if (showNav) const _BottomNav(),
            ],
          );

    return CefSystemBars.split(
      // Gradient behind the status bar; white nav or surface behind the
      // gesture area.
      statusBarBackground: Brightness.dark,
      navigationBarBackground: Brightness.light,
      browserChromeColor: CefGradients.brandChrome,
      child: PopScope(
        canPop: !app.canGoBack,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && app.canGoBack) app.back();
        },
        child: Scaffold(
          backgroundColor: c.card,
          body: BrandBackdrop(child: body),
        ),
      ),
    );
  }
}

/// The white surface that enters the gradient with rounded top corners.
/// Carries the bottom safe area when no bottom navigation sits below it, so
/// the surface itself continues behind the system gesture area.
class ContentSurface extends StatelessWidget {
  const ContentSurface({
    super.key,
    required this.child,
    this.bottomSafeArea = true,
  });
  final Widget child;
  final bool bottomSafeArea;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(Sizes.surfaceRadius),
    ),
    child: ColoredBox(
      color: context.c.card,
      child: SafeArea(top: false, bottom: bottomSafeArea, child: child),
    ),
  );
}

/// The one header row (D-46): [leading] actions, a title centred on the
/// SCREEN, [trailing] actions. Both side slots take the width of the wider
/// side, so an extra icon on one side never pushes the title off centre.
/// Same height, type and safe-area handling on every route; the shell and
/// own-chrome screens both render through it.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading = const [],
    this.trailing = const [],
  });
  final String title;
  final String? subtitle;
  final List<Widget> leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final slots = leading.length > trailing.length
        ? leading.length
        : trailing.length;
    // Keep a gutter-sized margin even when neither side has an action.
    final side = slots == 0 ? Gap.lg : slots * Sizes.tapTarget;
    return SafeArea(
      bottom: false,
      // Minimum, not fixed: a title + subtitle grows with the OS text size
      // instead of overflowing.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.header),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
          child: Row(
            children: [
              SizedBox(
                width: side,
                child: Row(children: leading),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Long titles shrink to fit rather than ellipsize.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: .82),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: side,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: trailing,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White header back arrow, shared by the shell and own-chrome screens.
class HeaderBackButton extends StatelessWidget {
  const HeaderBackButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconAction(
    icon: LucideIcons.arrowLeft,
    tooltip: 'Back',
    color: Colors.white,
    onTap: onTap,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final route = app.current.route;
    final isRoot = _tabRoots.contains(route);
    final title = route == VRoute.today
        ? (app.business?.name ?? 'Cefflo Vendor')
        : _headerTitles[route] ?? app.current.spec.title;
    return AppHeader(
      title: title,
      subtitle: _headerSubtitles[route],
      leading: [
        // Settings lives in the Today header (D-46), not the bottom nav.
        if (route == VRoute.today)
          IconAction(
            icon: LucideIcons.settings,
            tooltip: 'Settings',
            color: Colors.white,
            onTap: () => app.go(VRoute.settings),
          )
        else if (!isRoot && app.canGoBack)
          HeaderBackButton(onTap: app.back),
      ],
      trailing: [
        if (route == VRoute.today)
          IconAction(
            icon: LucideIcons.bell,
            tooltip: 'Notifications',
            showDot: true,
            color: Colors.white,
            onTap: () => app.go(VRoute.notificationInbox),
          ),
        ..._searchHeaderActions(context, route),
      ],
    );
  }
}

/// Locked list-screen header pattern: a compact search icon (and, on Orders,
/// a filter icon) in the title bar, in place of an inline full-width field.
List<Widget> _searchHeaderActions(BuildContext context, VRoute route) {
  final app = AppScope.of(context);
  final hint = switch (route) {
    VRoute.orders => 'Search order number or customer...',
    VRoute.zones => 'Search zones...',
    VRoute.riders => 'Search riders...',
    _ => null,
  };
  final addAction = switch (route) {
    VRoute.orders => ('Add order', VRoute.newOrder),
    VRoute.zones || VRoute.zoneConfiguration => ('Add zone', VRoute.createZone),
    VRoute.riders => ('Invite rider', VRoute.riderRegistrationLink),
    VRoute.team => ('Invite team member', VRoute.helperRegistrationLink),
    VRoute.products => ('Add product', VRoute.addProduct),
    _ => null,
  };
  if (hint == null) {
    if (route == VRoute.storefront) {
      return [
        IconAction(
          icon: LucideIcons.circleHelp,
          tooltip: 'Help',
          color: Colors.white,
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('About the Template Library'),
              content: const Text(
                'Pick a template and preview it with your own products, '
                'then tap "Use This Template" to make it your live '
                'storefront. Switching templates never changes your '
                'products, prices or stock.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    if (addAction == null) return const [];
    return [
      IconAction(
        icon: LucideIcons.plus,
        tooltip: addAction.$1,
        color: Colors.white,
        onTap: () => app.go(addAction.$2),
      ),
    ];
  }
  return [
    IconAction(
      icon: LucideIcons.search,
      tooltip: 'Search',
      color: Colors.white,
      onTap: () => showSearchSheet(context, hint: hint),
    ),
    if (route == VRoute.orders)
      IconAction(
        icon: LucideIcons.slidersHorizontal,
        tooltip: 'Filter',
        color: Colors.white,
        onTap: () {},
      ),
    if (addAction != null)
      IconAction(
        icon: LucideIcons.plus,
        tooltip: addAction.$1,
        color: Colors.white,
        onTap: () => app.go(addAction.$2),
      ),
  ];
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  static const _iconSize = 26.0;
  static const _labelSize = 12.0;

  static const _items = <(NavTab, String, IconData)>[
    (NavTab.today, 'Today', LucideIcons.house),
    (NavTab.orders, 'Orders', LucideIcons.package),
    (NavTab.zones, 'Zones', LucideIcons.mapPin),
    (NavTab.riders, 'Riders', LucideIcons.users),
  ];

  static const _filledIcons = <NavTab, IconData>{
    NavTab.today: Icons.home_rounded,
    NavTab.orders: Icons.inventory_2_rounded,
    NavTab.zones: Icons.location_on_rounded,
    NavTab.riders: Icons.people_alt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.chrome,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: Sizes.nav,
          child: Row(
            children: _items.map((item) {
              final selected = app.activeTab == item.$1;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => app.switchTab(item.$1),
                    child: Semantics(
                      selected: selected,
                      button: true,
                      label: item.$2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? _filledIcons[item.$1]! : item.$3,
                            size: _iconSize,
                            color: selected ? CefColors.brand : c.textSecondary,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: _labelSize,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected
                                  ? CefColors.brand
                                  : c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Active indicator (D-45): a short CEFFLO Blue
                          // bar under the active label.
                          Container(
                            width: 22,
                            height: 3,
                            decoration: BoxDecoration(
                              color: selected
                                  ? CefColors.brand
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// The one fixed primary-action area: sits under the scrolling content and
/// above the bottom navigation (or the gesture area), so a screen's primary
/// CTA stays reachable however long the content above it grows. Pages opt in
/// through [PageBody.bottom] / [HeroPage.bottomAction].
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.c.card,
      border: Border(top: BorderSide(color: context.c.border)),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: PageBody.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Gap.gutter,
            Gap.md,
            Gap.gutter,
            Gap.md,
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// The one scrollable page body: 20px gutters, compact top inset, and a
/// bottom inset that clears the last row. Dragging dismisses the keyboard.
/// [grouped] paints the cool-white page tone behind [CefListGroup] cards
/// (Settings archetype). [bottom] pins the page's primary action in a
/// [StickyActionBar] below the scrolling content.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.onRefresh,
    this.grouped = false,
    this.bottom,
  });
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final bool grouped;
  final Widget? bottom;

  /// Beyond normal phone widths, content gains a centered margin rather
  /// than stretching indefinitely -- a foldable/tablet-width safeguard.
  /// No-op at every tested phone width (largest is ~412dp).
  static const maxContentWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        bottom == null ? Gap.xxl : Gap.lg,
      ),
      children: children,
    );
    final constrained = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: list,
      ),
    );
    final scroll = onRefresh == null
        ? constrained
        : RefreshIndicator(onRefresh: onRefresh!, child: constrained);
    final toned = grouped
        ? ColoredBox(color: context.c.grouped, child: scroll)
        : scroll;
    if (bottom == null) return toned;
    return Column(
      children: [
        Expanded(child: toned),
        StickyActionBar(child: bottom!),
      ],
    );
  }
}

/// Detail-hero archetype body (rider / team member / customer / order
/// detail): [hero] is drawn directly on the gradient, then the white
/// surface enters with rounded top corners and holds [children] with the
/// standard gutters. The whole page scrolls together; the surface always
/// reaches the bottom edge, behind the gesture area. [bottomAction] pins the
/// primary action below the scroll, above the gesture area.
class HeroPage extends StatelessWidget {
  const HeroPage({
    super.key,
    required this.hero,
    required this.children,
    this.onRefresh,
    this.bottomAction,
  });
  final Widget hero;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final scroll = CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: hero),
        SliverFillRemaining(
          hasScrollBody: false,
          child: ContentSurface(
            bottomSafeArea: bottomAction == null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Gap.gutter,
                Gap.lg,
                Gap.gutter,
                bottomAction == null ? Gap.xxl : Gap.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
    final body = onRefresh == null
        ? scroll
        : RefreshIndicator(onRefresh: onRefresh!, child: scroll);
    if (bottomAction == null) return body;
    return Column(
      children: [
        Expanded(child: body),
        ColoredBox(
          color: context.c.card,
          child: SafeArea(
            top: false,
            child: StickyActionBar(child: bottomAction!),
          ),
        ),
      ],
    );
  }
}
