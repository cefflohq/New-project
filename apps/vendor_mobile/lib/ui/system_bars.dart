import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cefflo's single reusable mechanism for edge-to-edge Android/iOS system
/// chrome. No screen or widget should call
/// `SystemChrome.setSystemUIOverlayStyle` / build a raw
/// `SystemUiOverlayStyle` directly -- wrap the screen's root in
/// [CefSystemBars] instead, so every route gets the same treatment:
///
///   * the status bar and navigation/gesture bar are always fully
///     transparent, so the screen's own background paints edge-to-edge
///     behind them (see [enableEdgeToEdge], which must run once at startup
///     for that background to actually extend under the bars instead of
///     being letterboxed above/below them);
///   * system icons (status bar + nav bar) switch between light and dark
///     automatically based on the [Brightness] of whatever the screen
///     itself is painting directly behind each bar -- never a hardcoded
///     app color;
///   * Android's automatic contrast scrim behind the bars is disabled,
///     since Cefflo already guarantees icon legibility by picking the
///     right brightness rather than relying on the OS to darken/lighten a
///     translucent bar.
///
/// A screen with one uniform background (e.g. the navy Auth/Splash boards)
/// declares it once: `CefSystemBars(background: Brightness.dark, ...)`.
/// A screen whose top and bottom differ (e.g. a navy header over a white
/// sheet) declares each independently via [CefSystemBars.split] so the
/// status bar and navigation bar each get the icon color that is actually
/// legible against what is behind them.
class CefSystemBars extends StatelessWidget {
  /// One [background] brightness for both the status bar and the
  /// navigation/gesture bar -- the common case for a screen with a single
  /// full-bleed background color.
  const CefSystemBars({
    super.key,
    required Brightness background,
    required this.child,
  }) : statusBarBackground = background,
       navigationBarBackground = background;

  /// Independent brightness for the status bar and the navigation bar, for
  /// screens whose top and bottom regions have different backgrounds (e.g.
  /// a dark header over a light sheet).
  const CefSystemBars.split({
    super.key,
    required this.statusBarBackground,
    required this.navigationBarBackground,
    required this.child,
  });

  /// The brightness of whatever is painted directly behind the status bar
  /// (top of screen) -- not the icon color itself. `Brightness.dark` means
  /// a dark background, which gets light/white status bar icons.
  final Brightness statusBarBackground;

  /// The brightness of whatever is painted directly behind the
  /// navigation/gesture bar (bottom of screen) -- not the icon color
  /// itself. `Brightness.dark` means a dark background, which gets
  /// light/white navigation bar icons.
  final Brightness navigationBarBackground;

  final Widget child;

  /// Must run once at startup, before the first frame, so Android actually
  /// lays Flutter's canvas out full-screen underneath the system bars
  /// instead of insetting it. Without this, a transparent
  /// [SystemUiOverlayStyle] has nothing to show through -- the bars would
  /// just reveal the native window background (typically white) rather
  /// than the app's own content.
  static void enableEdgeToEdge() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// The actual transparent, brightness-aware overlay style. Exposed as a
  /// pure function (rather than only via the widget) so call sites that
  /// need the raw value -- e.g. a test asserting on the computed style --
  /// don't have to pump a widget tree to get one.
  static SystemUiOverlayStyle styleFor({
    required Brightness statusBarBackground,
    required Brightness navigationBarBackground,
  }) {
    final statusIcons = statusBarBackground == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    final navIcons = navigationBarBackground == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Android status bar icon color.
      statusBarIconBrightness: statusIcons,
      // iOS: this is the brightness of the background *behind* the bar
      // (matching our own semantics exactly), not the icon color.
      statusBarBrightness: statusBarBackground,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: navIcons,
      // Disable Android's automatic scrim behind translucent/transparent
      // bars -- otherwise a faint dark strip reappears even with a
      // transparent color, defeating the point of this widget.
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: styleFor(
      statusBarBackground: statusBarBackground,
      navigationBarBackground: navigationBarBackground,
    ),
    child: child,
  );
}
