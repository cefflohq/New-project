import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import 'brand.dart';
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

/// The signed-in app shell: paints the one navy gradient behind every
/// screen (headers are transparent windows onto it), owns the four-tab
/// bottom navigation, the edge-to-edge system bars and hardware-back
/// handling.
class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final fullBleed = _fullBleedRoutes.contains(app.current.route);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Every Driver screen opens on the navy gradient, so the status bar
      // carries light icons over it.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope(
        canPop: !app.canGoBack,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && app.canGoBack) app.back();
        },
        // The one navy gradient (D-52 parity with Vendor): painted once
        // here, behind the transparent status bar and every screen's
        // transparent header; this element persists across tab changes so
        // the gradient never restarts.
        child: NavyBackdrop(
          watermark: false,
          child: fullBleed
              ? child
              : Scaffold(
                  backgroundColor: Colors.transparent,
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
      ),
    );
  }
}
