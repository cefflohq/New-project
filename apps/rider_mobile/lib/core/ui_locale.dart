import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UI languages for the Malaysia launch (Founder decision 2026-09-27):
/// English and Bahasa Melayu. Country/market is a separate setting and never
/// selects the UI language.
const supportedUiLocales = [Locale('en'), Locale('ms')];

/// Native names shown in the language picker; never translated.
const uiLanguageNames = {'en': 'English', 'ms': 'Bahasa Melayu'};

/// First-launch rule: the first supported device language, else English.
Locale resolveDeviceLocale([List<Locale>? device]) {
  for (final l in device ?? PlatformDispatcher.instance.locales) {
    for (final s in supportedUiLocales) {
      if (s.languageCode == l.languageCode) return s;
    }
  }
  return const Locale('en');
}

Locale? parseUiLocale(Object? code) {
  for (final s in supportedUiLocales) {
    if (s.languageCode == code) return s;
  }
  return null;
}

/// The explicit choice on this device. It overrides device detection until
/// cleared. Storage failures are non-fatal: the device language applies.
class UiLocaleStore {
  static const key = 'cefflo.ui_locale';

  Future<Locale?> read() async {
    try {
      return parseUiLocale(
        (await SharedPreferences.getInstance()).getString(key),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Locale locale) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        key,
        locale.languageCode,
      );
    } catch (_) {}
  }
}

/// Rebuilds every descendant when the UI locale changes, so screens that
/// read strings through `L` switch language in place (state is kept).
class LocaleRefresh extends StatefulWidget {
  const LocaleRefresh({super.key, required this.locale, required this.child});

  final Locale locale;
  final Widget child;

  @override
  State<LocaleRefresh> createState() => _LocaleRefreshState();
}

class _LocaleRefreshState extends State<LocaleRefresh> {
  @override
  void didUpdateWidget(LocaleRefresh old) {
    super.didUpdateWidget(old);
    if (old.locale != widget.locale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        void walk(Element e) {
          e.markNeedsBuild();
          e.visitChildren(walk);
        }

        (context as Element).visitChildren(walk);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
