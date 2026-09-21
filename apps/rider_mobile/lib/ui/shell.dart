import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import 'widgets.dart';

/// Routes that own the whole viewport and draw no bottom navigation.
///
/// Two groups, both taken from the references: the multi-step onboarding
/// forms (D10, D12, D12.1, D12.2), which are a wizard rather than a tab —
/// every one of them renders the full-bleed `CeffloAuthScaffold` — and D22
/// Navigation to Stop, whose reference is edge-to-edge map with no tab bar.
const _fullBleedRoutes = <DRoute>{
  DRoute.acceptInvitation,
  DRoute.driverDetails,
  DRoute.personalDetails,
  DRoute.vehicleAndDocuments,
  DRoute.navigationToStop,
};

/// The signed-in app shell: each screen paints its own navy header (that is
/// how the references draw them), so the shell owns only the four-tab bottom
/// navigation, the system-chrome colour and hardware-back handling.
class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final fullBleed = _fullBleedRoutes.contains(app.current.route);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Every Driver screen opens on the navy gradient, so the status bar
      // carries light icons over it.
      value: SystemUiOverlayStyle(
        statusBarColor: CefColors.gradientBright,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: c.chrome,
        systemNavigationBarDividerColor: c.chrome,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope(
        canPop: !app.canGoBack,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && app.canGoBack) app.back();
        },
        child: fullBleed
            ? child
            : Scaffold(
                backgroundColor: c.canvas,
                body: Column(
                  children: [
                    Expanded(child: child),
                    CeffloBottomNav(
                      active: app.activeTab,
                      onTap: app.switchTab,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
