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
  VRoute.runDetail: 'Active run',
  VRoute.riderRegistrationLink: 'Invite rider',
  VRoute.helperRegistrationLink: 'Invite team member',
};

/// Primary destinations (bottom-nav roots): no back arrow.
const _tabRoots = {
  VRoute.today,
  VRoute.orders,
  VRoute.zones,
  VRoute.riders,
  VRoute.settings,
};

/// Detail-hero archetype: the screen renders its identity hero on the
/// gradient through [HeroPage] and owns its white surface. These are focused
/// detail views without bottom nav.
const _heroRoutes = {
  VRoute.orderDetail,
  VRoute.riderDetail,
  VRoute.teamMemberDetail,
  VRoute.customerDetail,
};

/// Focused flows that hide the primary bottom navigation: an active run
/// carries its own bottom actions.
const _focusedRoutes = {VRoute.runDetail};

/// Visual storefront-management surfaces: the screen owns the whole canvas
/// edge to edge (its storefront visual runs behind the transparent status
/// bar, with its own overlay controls) -- no Vendor header, no bottom nav.
const _immersiveRoutes = {
  VRoute.storefront,
  VRoute.storefrontPreview,
  VRoute.storefrontTemplatePreview,
  VRoute.branding,
};

/// Routes that render their own [AppHeader] (its title and ⋮ menu act on
/// the record the screen loaded) above their own [ContentSurface], but keep
/// the bottom navigation -- Zone detail, whose header is the zone's name.
const _ownHeaderRoutes = {VRoute.zoneDetail};

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
    final immersive = _immersiveRoutes.contains(route);
    final ownHeader = _ownHeaderRoutes.contains(route);
    final hero = _heroRoutes.contains(route);
    // While the keyboard is up the nav would ride above it and eat the
    // form's space; it returns as soon as the keyboard closes.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showNav =
        !immersive &&
        !hero &&
        !keyboardOpen &&
        !_onboardingRoutes.contains(route) &&
        !_focusedRoutes.contains(route);

    final body = immersive
        ? child
        : Column(
            children: [
              if (!ownHeader) _Header(app: app),
              Expanded(
                child: _OfflineTint(
                  // Offline greys the operational screens (Today, Orders,
                  // Zones, Riders and their details); More stays in colour.
                  active: !app.vendorOnline && app.activeTab != NavTab.more,
                  child: hero || ownHeader
                      ? child
                      : ContentSurface(bottomSafeArea: !showNav, child: child),
                ),
              ),
              if (showNav) const _BottomNav(),
            ],
          );

    // Floating toasts sit above the bottom navigation where it is shown.
    final toastInset =
        MediaQuery.paddingOf(context).bottom + (showNav ? Sizes.nav : 0);

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
        // The universal Vendor background (D-52): painted once, here, under
        // every authenticated route. This element is reused across route
        // changes, so the gradient never restarts; headers and the status
        // bar are transparent windows onto it.
        child: Scaffold(
          backgroundColor: c.card,
          body: ToastInset(
            bottom: toastInset,
            child: BrandBackdrop(child: body),
          ),
        ),
      ),
    );
  }
}

/// Greys out [child] (full desaturation) while the vendor
/// is offline; colour returns as soon as they are back online.
class _OfflineTint extends StatelessWidget {
  const _OfflineTint({required this.active, required this.child});
  final bool active;
  final Widget child;

  static const _greyscale = ColorFilter.matrix([
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) =>
      active ? ColorFiltered(colorFilter: _greyscale, child: child) : child;
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
    this.sideWidth,
    this.onTitleTap,
  });
  final String title;
  final String? subtitle;
  final List<Widget> leading;
  final List<Widget> trailing;

  /// Fixed width for both side slots when a side holds more than an icon
  /// (Today's date); defaults to the widest side's icon count.
  final double? sideWidth;

  /// Makes the title a selector with a small dropdown mark (Today's
  /// business switcher).
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final slots = leading.length > trailing.length
        ? leading.length
        : trailing.length;
    // Keep a gutter-sized margin even when neither side has an action.
    final side = sideWidth ?? (slots == 0 ? Gap.lg : slots * Sizes.tapTarget);
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
                    GestureDetector(
                      onTap: onTitleTap,
                      behavior: HitTestBehavior.opaque,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: text.headlineMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            if (onTitleTap != null) ...[
                              const SizedBox(width: Gap.xs),
                              const Icon(
                                LucideIcons.chevronDown,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
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
    final today = route == VRoute.today;
    final header = AppHeader(
      title: title,
      sideWidth: today ? 100 : null,
      onTitleTap: today ? () => _showBusinessSwitcher(context, app) : null,
      leading: [
        if (today)
          const _OnlineToggle()
        else if (!isRoot && app.canGoBack)
          HeaderBackButton(onTap: app.back),
      ],
      trailing: [
        if (route == VRoute.today)
          IconAction(
            icon: LucideIcons.bell,
            tooltip: 'Notifications',
            showDot: app.unreadNotifications > 0,
            color: Colors.white,
            onTap: () => app.go(VRoute.notificationInbox),
          ),
        ..._searchHeaderActions(context, route),
      ],
    );
    if (route != VRoute.today) return header;
    return Column(
      children: [
        header,
        _TodayGreeting(name: app.userDisplayName),
      ],
    );
  }
}

/// Today's availability switch: the Founder-referenced toggle (blue track,
/// white knob) with "Online" / "Offline" inside the track. Offline greys the
/// operational screens (see [VendorShell]).
class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final on = app.vendorOnline;
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(left: Gap.md),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Semantics(
            toggled: on,
            label: on ? 'Online' : 'Offline',
            button: true,
            child: GestureDetector(
              onTap: () {
                app.setVendorOnline(!on);
                showCefToast(
                  context,
                  on
                      ? "You're offline. New orders are paused."
                      : "You're online.",
                );
              },
              child: _ToggleTrack(on: on),
            ),
          ),
        ),
      ),
    );
  }
}

/// The toggle itself: a pill track (Vendor blue when on, muted when off)
/// with a white round knob; the state label sits in the track's free space
/// -- "Online" left of the knob, "Offline" right of it.
class _ToggleTrack extends StatelessWidget {
  const _ToggleTrack({required this.on});
  final bool on;

  static const _w = 88.0, _h = 30.0, _knob = 24.0;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      on ? 'Online' : 'Offline',
      maxLines: 1,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _w,
      height: _h,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: on ? context.c.success : Colors.white.withValues(alpha: .28),
        borderRadius: BorderRadius.circular(_h),
        border: Border.all(color: Colors.white.withValues(alpha: .55)),
      ),
      child: Stack(
        children: [
          // Label in the space the knob is not using.
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: on ? Gap.sm : _knob + Gap.xs,
                right: on ? _knob + Gap.xs : Gap.sm,
              ),
              child: Center(child: FittedBox(child: label)),
            ),
          ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _knob,
              height: _knob,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Today title's dropdown: the businesses this account can run, the
/// current one checked.
void _showBusinessSwitcher(BuildContext context, AppState app) {
  showListSheet(
    context,
    title: 'Your businesses',
    children: [
      for (final b in app.businesses)
        CefListRow(
          title: b.name,
          subtitle: b.role,
          icon: LucideIcons.store,
          showChevron: false,
          trailing: b.id == app.business?.id
              ? const Icon(
                  LucideIcons.check,
                  size: Sizes.icon,
                  color: CefColors.brand,
                )
              : null,
          onTap: () {
            Navigator.of(context).pop();
            app.selectBusiness(b);
          },
        ),
    ],
  );
}

/// Today's greeting on the canonical blue, under the header: time-of-day
/// salutation, the person's name, and one line of context.
class _TodayGreeting extends StatelessWidget {
  const _TodayGreeting({required this.name});
  final String name;

  static String _salutation(DateTime now) => now.hour < 12
      ? 'Good Morning,'
      : now.hour < 18
      ? 'Good Afternoon,'
      : 'Good Evening,';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Colors.white.withValues(alpha: .82);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.xs,
        Gap.gutter,
        Gap.xl,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _salutation(DateTime.now()),
              style: text.bodyLarge?.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            if (name.isNotEmpty)
              Text(
                '$name!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge?.copyWith(color: Colors.white),
              ),
            const SizedBox(height: Gap.xs),
            Text(
              "Here's what's happening today.",
              style: text.bodyMedium?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Locked list-screen header pattern: a compact search icon (and an add
/// action where the list has one) in the title bar, in place of an inline
/// full-width field.
List<Widget> _searchHeaderActions(BuildContext context, VRoute route) {
  final app = AppScope.of(context);
  final hint = switch (route) {
    VRoute.orders => 'Search order number or customer...',
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
  if (route == VRoute.notificationInbox) {
    return [
      IconAction(
        icon: LucideIcons.ellipsis,
        tooltip: 'Notification options',
        color: Colors.white,
        onTap: () => showListSheet(
          context,
          title: 'Notifications',
          children: [
            CefListRow(
              title: 'Mark all as read',
              icon: LucideIcons.checkCheck,
              showChevron: false,
              onTap: () {
                Navigator.of(context).pop();
                app.markAllNotificationsRead();
              },
            ),
            CefListRow(
              title: 'Clear all notifications',
              icon: LucideIcons.trash2,
              showChevron: false,
              onTap: () {
                Navigator.of(context).pop();
                app.clearNotifications();
              },
            ),
          ],
        ),
      ),
    ];
  }
  if (hint == null) {
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

  /// (tab, label, default outline icon, active filled icon). The only
  /// coloured icons in the app: active = filled, in the Anchor Blue of the
  /// top background (#01265E); default = navy outline.
  static const _items = <(NavTab, String, IconData, Widget)>[
    (NavTab.today, 'Today', LucideIcons.house, Icon(Icons.home_rounded)),
    (NavTab.orders, 'Orders', LucideIcons.package, _FilledCube()),
    (
      NavTab.zones,
      'Zones',
      LucideIcons.mapPin,
      Icon(Icons.location_on_rounded),
    ),
    (
      NavTab.riders,
      'Riders',
      LucideIcons.users,
      Icon(Icons.people_alt_rounded),
    ),
    (NavTab.more, 'More', LucideIcons.menu, Icon(LucideIcons.menu)),
  ];

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
              // Active = the Anchor Blue of the top background (Founder,
              // 2026-09-24); inactive = neutral.
              final tone = selected ? CefColors.anchorBlue : c.iconColor;
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
                          IconTheme(
                            data: IconThemeData(size: Sizes.icon, color: tone),
                            child: selected ? item.$4 : Icon(item.$3),
                          ),
                          const SizedBox(height: Gap.xs),
                          Text(
                            item.$2,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: tone,
                                ),
                          ),
                          const SizedBox(height: Gap.xs),
                          // Active indicator: a short Anchor Blue bar under
                          // the active label.
                          Container(
                            width: 22,
                            height: 3,
                            decoration: BoxDecoration(
                              color: selected
                                  ? CefColors.anchorBlue
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

/// The active Orders icon: a solid isometric cube with light edge lines,
/// matching the Icon Family sheet. Material has no filled cube, so it is
/// drawn; size and colour come from the surrounding [IconTheme].
class _FilledCube extends StatelessWidget {
  const _FilledCube();

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? Sizes.icon;
    return CustomPaint(
      size: Size.square(size),
      painter: _FilledCubePainter(theme.color ?? CefColors.anchorBlue),
    );
  }
}

class _FilledCubePainter extends CustomPainter {
  const _FilledCubePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = Offset(w * .5, h * .08);
    final upperLeft = Offset(w * .12, h * .29);
    final upperRight = Offset(w * .88, h * .29);
    final centre = Offset(w * .5, h * .5);
    final lowerLeft = Offset(w * .12, h * .71);
    final lowerRight = Offset(w * .88, h * .71);
    final bottom = Offset(w * .5, h * .92);
    final hexagon = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(upperRight.dx, upperRight.dy)
      ..lineTo(lowerRight.dx, lowerRight.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(lowerLeft.dx, lowerLeft.dy)
      ..lineTo(upperLeft.dx, upperLeft.dy)
      ..close();
    canvas.drawPath(
      hexagon,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..strokeJoin = StrokeJoin.round,
    );
    final edges = Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..strokeWidth = w * .06
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(upperLeft, centre, edges)
      ..drawLine(upperRight, centre, edges)
      ..drawLine(centre, bottom, edges);
  }

  @override
  bool shouldRepaint(_FilledCubePainter old) => old.color != color;
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

/// Loading state for the detail-hero archetype: an avatar and identity bars
/// on the gradient, then rows on the white surface. Only the placeholder
/// shapes pulse; the white surface stays solid.
class SkeletonHeroPage extends StatelessWidget {
  const SkeletonHeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final onHero = Colors.white.withValues(alpha: .18);
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: onHero,
        borderRadius: BorderRadius.circular(Gap.sm),
      ),
    );
    return HeroPage(
      hero: SkeletonPulse(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Gap.gutter,
            Gap.xs,
            Gap.gutter,
            Gap.xl,
          ),
          child: Row(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: onHero,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Gap.xl),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(160, 26),
                  const SizedBox(height: Gap.sm),
                  bar(80, 22),
                  const SizedBox(height: Gap.sm),
                  bar(110, 14),
                ],
              ),
            ],
          ),
        ),
      ),
      children: const [
        SkeletonPulse(
          child: Column(
            children: [
              SkeletonKpis(count: 3),
              SkeletonRow(),
              SkeletonRow(),
              SkeletonRow(),
              SkeletonRow(),
            ],
          ),
        ),
      ],
    );
  }
}
