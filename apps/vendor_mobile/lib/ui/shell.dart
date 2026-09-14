import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/theme.dart';
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

/// Flat white chrome: 60px header and 60px sticky bottom navigation, no
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: c.chrome,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: c.chrome,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: PopScope(
        canPop: !app.canGoBack,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && app.canGoBack) app.back();
        },
        child: Scaffold(
          backgroundColor: c.canvas,
          body: Column(
            children: [
              _Header(app: app),
              Expanded(child: child),
              if (!isOnboarding) const _BottomNav(),
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
    return Container(
      color: c.chrome,
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
                  const SizedBox(width: Gap.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                    child: Text(
                      isTodayRoot
                          ? (app.business?.name ?? 'Cefflo Vendor')
                          : spec.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isTodayRoot
                          ? const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF091A3C),
                            )
                          : Theme.of(context).textTheme.titleLarge,
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
                ..._searchHeaderActions(context, app.current.route),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Locked list-screen header pattern: a compact search icon (and, on Orders,
/// a filter icon) in the title bar, in place of an inline full-width field.
List<Widget> _searchHeaderActions(BuildContext context, VRoute route) {
  final hint = switch (route) {
    VRoute.orders => 'Search order number or customer...',
    VRoute.zones => 'Search zones...',
    VRoute.riders => 'Search riders...',
    _ => null,
  };
  if (hint == null) return const [];
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
  ];
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  static const _items = <(NavTab, String, IconData)>[
    (NavTab.today, 'Today', LucideIcons.house),
    (NavTab.orders, 'Orders', LucideIcons.package),
    (NavTab.zones, 'Zones', LucideIcons.mapPin),
    (NavTab.riders, 'Riders', LucideIcons.users),
    (NavTab.menu, 'Settings', LucideIcons.settings),
  ];

  static const _filledIcons = <NavTab, IconData>{
    NavTab.today: Icons.home_rounded,
    NavTab.orders: Icons.inventory_2_rounded,
    NavTab.zones: Icons.location_on_rounded,
    NavTab.riders: Icons.people_alt_rounded,
    NavTab.menu: Icons.settings_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final today = app.current.route == VRoute.today;
    return Container(
      decoration: BoxDecoration(
        color: c.chrome,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: today ? 58 : Sizes.chrome,
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
                            size: today ? 24 : Sizes.icon,
                            color: selected
                                ? CefColors.accent
                                : c.textSecondary,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: today ? 10 : 11,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected ? c.textPrimary : c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const SizedBox(height: 2),
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
  const PageBody({
    super.key,
    required this.children,
    this.onRefresh,
    this.floatingAction,
  });
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  /// A page-level action (e.g. [YellowFab]) pinned at a fixed bottom-right
  /// position, above the bottom navigation -- it never scrolls with the
  /// list content beneath it.
  final Widget? floatingAction;

  /// Beyond normal phone widths, content gains a centered margin rather
  /// than stretching indefinitely -- a foldable/tablet-width safeguard.
  /// No-op at every tested phone width (largest is ~412dp).
  static const _maxContentWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.md,
        Gap.gutter,
        floatingAction == null ? Gap.section : Gap.section + 64,
      ),
      children: children,
    );
    final constrained = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: list,
      ),
    );
    final body = onRefresh == null
        ? constrained
        : RefreshIndicator(onRefresh: onRefresh!, child: constrained);
    if (floatingAction == null) return body;
    return Stack(
      children: [
        body,
        Positioned(
          right: Gap.gutter,
          bottom: Gap.gutter,
          child: floatingAction!,
        ),
      ],
    );
  }
}
