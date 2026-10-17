import 'package:cefflo_loader/cefflo_loader.dart';
import 'package:cefflo_vendor_mobile/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared loader's text follows the app language (no Bahasa Melayu
/// "Memuatkan…" on an English app).
void main() {
  test('loader text follows the UI language', () {
    applyUiLocale(const Locale('en'));
    expect(CefLoaderTokens.defaultLabel, 'Loading…');
    expect(CefLoaderTokens.slowLabel, 'Still loading, please wait a moment');
    applyUiLocale(const Locale('ms'));
    expect(CefLoaderTokens.defaultLabel, 'Memuatkan…');
    applyUiLocale(const Locale('en'));
  });
}
