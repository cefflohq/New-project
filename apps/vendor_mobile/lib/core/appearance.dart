import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

/// The app backdrop the user chose on THIS device (Founder, 2026-09-30):
/// device-local only -- never a profile column, never synced. `color`
/// null is the Cefflo standard appearance (the default on a fresh install).
/// Only the brand backdrop follows it; semantic status colours, the white
/// content surface and the mustard CTA never change.
class Appearance {
  const Appearance({this.color, this.gradient = true});
  final int? color;
  final bool gradient;

  static const standard = Appearance();

  bool get isStandard => color == null;

  @override
  bool operator ==(Object other) =>
      other is Appearance && other.color == color && other.gradient == gradient;

  @override
  int get hashCode => Object.hash(color, gradient);

  /// The backdrop every [BrandBackdrop] paints.
  LinearGradient get backdrop {
    if (color == null) return CefGradients.brand;
    final base = legibleBackdropColor(Color(color!));
    if (!gradient) {
      return LinearGradient(colors: [base, base]);
    }
    // Minimalist, derived from the one colour: deeper at the top, the
    // chosen tone at the bottom. Both ends keep white text legible.
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.lerp(base, const Color(0xFF000000), .35)!, base],
    );
  }

  /// Accent for icons, active tabs and navigation on white: the chosen
  /// colour, deepened until it reads at 4.5:1 on white. Null = standard.
  Color? get accent =>
      color == null ? null : legibleBackdropColor(Color(color!));

  /// Single colour for the status bar / browser chrome.
  Color get chrome =>
      color == null ? CefGradients.brandChrome : backdrop.colors.first;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

/// Contrast safeguard: the header text and icons on the backdrop are white,
/// so a light choice (yellow, white, pastel) is deepened until white reads
/// at 4.5:1 or better. The hue is kept.
Color legibleBackdropColor(Color c) {
  const white = Color(0xFFFFFFFF), black = Color(0xFF000000);
  var out = c.withValues(alpha: 1);
  for (var i = 0; i < 20 && _contrast(out, white) < 4.5; i++) {
    out = Color.lerp(out, black, .08)!;
  }
  return out;
}

/// What every [BrandBackdrop] paints right now: the saved appearance, or
/// the unsaved preview while Appearance is open.
final ValueNotifier<Appearance> liveAppearance = ValueNotifier(
  Appearance.standard,
);

/// Persistence on this device only (shared_preferences). Failures are
/// non-fatal: the standard appearance applies.
class AppearanceStore {
  static const colorKey = 'cefflo.appearance.color';
  static const gradientKey = 'cefflo.appearance.gradient';

  Future<Appearance> read() async {
    try {
      final p = await SharedPreferences.getInstance();
      return Appearance(
        color: p.getInt(colorKey),
        gradient: p.getBool(gradientKey) ?? true,
      );
    } catch (_) {
      return Appearance.standard;
    }
  }

  Future<void> write(Appearance a) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (a.color == null) {
        await p.remove(colorKey);
      } else {
        await p.setInt(colorKey, a.color!);
      }
      await p.setBool(gradientKey, a.gradient);
    } catch (_) {}
  }
}
