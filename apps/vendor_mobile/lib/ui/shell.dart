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

/// Focused flows that hide the primary bottom navigation: dispatch review
/// and an active run carry their own bottom actions, and the storefront
/// previews render an immersive customer-facing view the vendor nav would
/// break. Every other signed-in route keeps the canonical bottom nav.
const _focusedRoutes = {
  VRoute.reviewDispatch,
  VRoute.runDetail,
  VRoute.storefrontPreview,
  VRoute.storefrontTemplatePreview,
};

/// Routes that render their own full header (back arrow, dynamic title,
/// trailing actions) and own chrome entirely -- e.g. Screen 03, Customize
/// {Template Name}, which needs a Reset action wired to screen-local draft
/// state that the shared header cannot reach. No default header or bottom
/// nav is rendered for these.
const _ownChromeRoutes = {VRoute.branding};

/// Flat chrome: one 60px white header and one 60px bottom navigation for
/// every signed-in route, no floating glass bar, no FAB, no accent underline
/// beneath the title. The page body sits between them in a Column, so
/// content can never scroll underneath the navigation.
class VendorShell extends StatelessWidget {
  const VendorShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final route = app.current.route;
    final ownChrome = _ownChromeRoutes.contains(route);
    // While the keyboard is up the nav would ride above it and eat the
    // form's space; it returns as soon as the keyboard closes.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showNav =
        !ownChrome &&
        !keyboardOpen &&
        !_onboardingRoutes.contains(route) &&
        !_focusedRoutes.contains(route);

    return CefSystemBars(
      // The header and bottom nav paint their own `c.chrome` fill behind
      // the status/navigation bars (see _Header/_BottomNav below); this
      // only has to pick the matching transparent-bar icon treatment for
      // whichever brightness that fill actually is.
      background: dark ? Brightness.dark : Brightness.light,
      browserChromeColor: c.chrome,
      child: PopScope(
        canPop: !app.canGoBack,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && app.canGoBack) app.back();
        },
        child: Scaffold(
          // Keep the native status/navigation-bar underlay in the same
          // colour family as the app chrome. The page body paints its own
          // canvas below, so an iPhone safe-area can never expose a detached
          // strip beneath the bottom navigation.
          backgroundColor: c.chrome,
          body: Column(
            children: [
              if (!ownChrome) _Header(app: app),
              Expanded(
                // Without the nav, the body owns the bottom safe area.
                child: ColoredBox(
                  color: c.canvas,
                  child: SafeArea(
                    top: false,
                    bottom: !showNav,
                    child: child,
                  ),
                ),
              ),
              if (showNav) const _BottomNav(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final route = app.current.route;
    final isTodayRoot = route == VRoute.today;
    final title = isTodayRoot
        ? (app.business?.name ?? 'Cefflo Vendor')
        : _headerTitles[route] ?? app.current.spec.title;
    final subtitle = _headerSubtitles[route];
    return Container(
      decoration: BoxDecoration(
        color: c.chrome,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: Sizes.chrome,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
            child: Row(
              children: [
                if (app.canGoBack && !isTodayRoot)
                  IconAction(
                    icon: LucideIcons.arrowLeft,
                    tooltip: 'Back',
                    onTap: app.back,
                  )
                else
                  const SizedBox(width: Gap.lg - Gap.xs),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PageTitle(title),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isTodayRoot)
                  IconAction(
                    icon: LucideIcons.bell,
                    tooltip: 'Notifications',
                    showDot: true,
                    onTap: () => app.go(VRoute.notificationInbox),
                  ),
                ..._searchHeaderActions(context, route),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The page title. Measures the available width and steps the size down
/// (22 -> 18) so a long title such as "Notification preferences" is shown
/// in full instead of ellipsized; only a title that cannot fit even at the
/// floor size falls back to an ellipsis.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});
  final String text;

  static const _minSize = 18.0;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleLarge!;
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        var style = base;
        for (var size = base.fontSize!; size >= _minSize; size -= 1) {
          style = base.copyWith(fontSize: size);
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final fits = painter.width <= constraints.maxWidth;
          painter.dispose();
          if (fits) break;
        }
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
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
    VRoute.products => ('Add product', VRoute.addProduct),
    _ => null,
  };
  if (hint == null) {
    if (route == VRoute.storefront) {
      return [
        IconAction(
          icon: LucideIcons.circleHelp,
          tooltip: 'Help',
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
        onTap: () => app.go(addAction.$2),
      ),
    ];
  }
  return [
    IconAction(
      icon: LucideIcons.search,
      tooltip: 'Search',
      onTap: () => showSearchSheet(context, hint: hint),
    ),
    if (route == VRoute.orders)
      IconAction(
        icon: LucideIcons.slidersHorizontal,
        tooltip: 'Filter',
        onTap: () {},
      ),
    if (addAction != null)
      IconAction(
        icon: LucideIcons.plus,
        tooltip: addAction.$1,
        onTap: () => app.go(addAction.$2),
      ),
  ];
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  static const _iconSize = 24.0;
  static const _labelSize = 11.0;

  static const _items = <(NavTab, String, IconData)>[
    (NavTab.today, 'Today', LucideIcons.house),
    (NavTab.orders, 'Orders', LucideIcons.package),
    (NavTab.zones, 'Zones', LucideIcons.mapPin),
    (NavTab.riders, 'Riders', LucideIcons.users),
    (NavTab.menu, 'Menu', LucideIcons.menu),
  ];

  static const _filledIcons = <NavTab, IconData>{
    NavTab.today: Icons.home_rounded,
    NavTab.orders: Icons.inventory_2_rounded,
    NavTab.zones: Icons.location_on_rounded,
    NavTab.riders: Icons.people_alt_rounded,
    NavTab.menu: Icons.menu_rounded,
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
          height: Sizes.chrome,
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
                            color: selected ? c.info : c.textSecondary,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: _labelSize,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected ? c.info : c.textSecondary,
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

/// The one scrollable page body: 20px gutters, compact top inset, and a
/// bottom inset that clears the last row. Dragging dismisses the keyboard.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.onRefresh});
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  /// Beyond normal phone widths, content gains a centered margin rather
  /// than stretching indefinitely -- a foldable/tablet-width safeguard.
  /// No-op at every tested phone width (largest is ~412dp).
  static const _maxContentWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.md,
        Gap.gutter,
        Gap.xxl,
      ),
      children: children,
    );
    final constrained = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: list,
      ),
    );
    return onRefresh == null
        ? constrained
        : RefreshIndicator(onRefresh: onRefresh!, child: constrained);
  }
}
