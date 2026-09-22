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

const _reviewTitles = <VRoute, String>{
  VRoute.reviewDispatch: 'Review Delivery Plan',
  VRoute.runDetail: 'Active Run',
  VRoute.riderDetail: 'Rider Detail',
  VRoute.riderRegistrationLink: 'Invite Rider',
  VRoute.team: 'Team',
  VRoute.teamMemberDetail: 'Team Member',
  // Storefront preview renders an immersive customer-facing view -- the
  // vendor bottom nav would break that illusion.
  VRoute.storefrontPreview: 'Storefront Preview',
  VRoute.storefrontTemplatePreview: 'Template Preview',
};

/// Small subtitle shown under a review-title header, for routes where the
/// spec calls for one (Screen 02 -- Template Preview).
const _reviewSubtitles = <VRoute, String>{
  VRoute.storefrontPreview: 'See how your products look with this template',
  VRoute.storefrontTemplatePreview:
      'See how your products look with this template',
};

/// Routes that render their own full header (back arrow, dynamic title,
/// trailing actions) and own chrome entirely -- e.g. Screen 03, Customize
/// {Template Name}, which needs a Reset action wired to screen-local draft
/// state that the shared header cannot reach. No default header or bottom
/// nav is rendered for these.
const _ownChromeRoutes = {VRoute.branding};

/// Flat chrome: 60px header and 60px sticky bottom navigation, no
/// floating glass bar, no FAB, no accent underline beneath the title.
class VendorShell extends StatelessWidget {
  const VendorShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isOnboarding = _onboardingRoutes.contains(app.current.route);
    final hasHeader = !_ownChromeRoutes.contains(app.current.route);
    final hasGradientHeader =
        hasHeader && !_reviewTitles.containsKey(app.current.route);

    return CefSystemBars.split(
      // The gradient header is always a dark-blue fill, so its status bar
      // icons stay white regardless of light/dark theme; the bottom nav
      // still paints `c.chrome`, so its icon treatment keeps following the
      // theme brightness as before.
      statusBarBackground: hasGradientHeader
          ? Brightness.dark
          : (dark ? Brightness.dark : Brightness.light),
      navigationBarBackground: dark ? Brightness.dark : Brightness.light,
      browserChromeColor: hasGradientHeader
          ? const Color(0xFF1257C4)
          : c.chrome,
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
              if (!_ownChromeRoutes.contains(app.current.route))
                _Header(app: app),
              Expanded(
                child: ColoredBox(color: c.canvas, child: child),
              ),
              if (!isOnboarding &&
                  !_reviewTitles.containsKey(app.current.route) &&
                  !_ownChromeRoutes.contains(app.current.route))
                const _BottomNav(),
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
    final spec = app.current.spec;
    final isTodayRoot = app.current.route == VRoute.today;
    final reviewTitle = _reviewTitles[app.current.route];
    if (reviewTitle != null) {
      final subtitle = _reviewSubtitles[app.current.route];
      return Container(
        decoration: BoxDecoration(
          color: c.chrome,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: subtitle == null ? 56 : 68,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconAction(
                  icon: LucideIcons.arrowLeft,
                  tooltip: 'Back',
                  onTap: app.back,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        reviewTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF091A3C),
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),
        ),
      );
    }
    // Deep navy -> bright cyan-blue diagonal wash, brightening toward the
    // top-right corner, per the locked reference screens (Today, Orders,
    // Zones, Riders, Settings all share this exact header treatment).
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1, 1),
          end: Alignment(1, -1),
          colors: [Color(0xFF0B1E4E), Color(0xFF1257C4), Color(0xFF1E9CF2)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.gutter,
                Gap.lg,
                Gap.md,
                Gap.lg,
              ),
              child: Row(
                children: [
                  if (app.canGoBack && !isTodayRoot)
                    IconAction(
                      icon: LucideIcons.arrowLeft,
                      tooltip: 'Back',
                      onTap: app.back,
                      color: Colors.white,
                    )
                  else
                    const SizedBox(width: Gap.xs),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                      child: Text(
                        isTodayRoot
                            ? (app.business?.name ?? 'Cefflo Vendor')
                            : spec.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (isTodayRoot)
                    IconAction(
                      icon: LucideIcons.bell,
                      tooltip: 'Notifications',
                      showDot: true,
                      onTap: () => app.go(VRoute.notificationInbox),
                      color: Colors.white,
                      dotRingColor: const Color(0xFF1257C4),
                    ),
                  ..._searchHeaderActions(
                    context,
                    app.current.route,
                    iconColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          // Rounded white "lip" the body sheet appears to grow out of --
          // painted here (rather than by the body) so it always sits flush
          // against this header's own gradient with no seam.
          Container(
            height: 22,
            decoration: BoxDecoration(
              color: c.canvas,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Locked list-screen header pattern: a compact search icon (and, on Orders,
/// a filter icon) in the title bar, in place of an inline full-width field.
List<Widget> _searchHeaderActions(
  BuildContext context,
  VRoute route, {
  Color? iconColor,
}) {
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
          color: iconColor,
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
        color: iconColor,
        onTap: () => app.go(addAction.$2),
      ),
    ];
  }
  return [
    IconAction(
      icon: LucideIcons.search,
      tooltip: 'Search',
      color: iconColor,
      onTap: () => showSearchSheet(context, hint: hint),
    ),
    if (route == VRoute.orders)
      IconAction(
        icon: LucideIcons.slidersHorizontal,
        tooltip: 'Filter',
        color: iconColor,
        onTap: () {},
      ),
    if (addAction != null)
      IconAction(
        icon: LucideIcons.plus,
        tooltip: addAction.$1,
        color: iconColor,
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
                          const SizedBox(height: 3),
                          // Small underline dash beneath the active tab's
                          // label, per the locked reference screens.
                          Container(
                            width: 18,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: selected ? c.info : Colors.transparent,
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

/// Standard scrollable page body with the approved 12px gutter.
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
      padding: EdgeInsets.fromLTRB(Gap.gutter, Gap.md, Gap.gutter, Gap.section),
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
