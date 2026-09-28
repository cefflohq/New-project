import 'package:cefflo_vendor_mobile/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression cover for the Manrope -> Inter typography migration.
///
/// Asserts the active global font family is Inter (bundled locally, not
/// GoogleFonts) with the correct multilingual fallback declared, in both
/// brightness variants and across every named TextTheme role the app
/// actually styles.
void main() {
  group('Inter typography migration', () {
    for (final brightness in Brightness.values) {
      final theme = buildVendorTheme(brightness);

      // ThemeData.fontFamily/fontFamilyFallback are constructor-only: they
      // are applied to the roles this app does NOT explicitly style (e.g.
      // bodyLarge), so checking one of those confirms the app-wide default
      // -- not just the named roles core/theme.dart sets directly.
      test(
        '$brightness global default (an unstyled role) resolves to Inter',
        () {
          expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
        },
      );

      test(
        '$brightness global default fontFamilyFallback covers SC and Tamil',
        () {
          expect(
            theme.textTheme.bodyLarge?.fontFamilyFallback,
            containsAll(['Noto Sans SC', 'Noto Sans Tamil']),
          );
        },
      );

      test('$brightness every styled TextTheme role uses Inter', () {
        final roles = <String, TextStyle?>{
          'titleLarge': theme.textTheme.titleLarge,
          'titleMedium': theme.textTheme.titleMedium,
          'titleSmall': theme.textTheme.titleSmall,
          'bodyMedium': theme.textTheme.bodyMedium,
          'bodySmall': theme.textTheme.bodySmall,
          'labelLarge': theme.textTheme.labelLarge,
          'displaySmall': theme.textTheme.displaySmall,
        };
        for (final entry in roles.entries) {
          expect(
            entry.value?.fontFamily,
            'Inter',
            reason: '${entry.key} should be styled with Inter',
          );
          expect(
            entry.value?.fontFamilyFallback,
            containsAll(['Noto Sans SC', 'Noto Sans Tamil']),
            reason:
                '${entry.key} should fall back to the bundled '
                'multilingual fonts, not tofu boxes or a network fetch',
          );
        }
      });

      test('$brightness KPI role (displaySmall) is ExtraBold per the locked '
          'weight table', () {
        expect(theme.textTheme.displaySmall?.fontWeight, FontWeight.w800);
      });

      test('$brightness no FontWeight.w900 appears in the named TextTheme '
          '(w900 is avoided unless explicitly required)', () {
        final weights = [
          theme.textTheme.titleLarge?.fontWeight,
          theme.textTheme.titleMedium?.fontWeight,
          theme.textTheme.titleSmall?.fontWeight,
          theme.textTheme.bodyMedium?.fontWeight,
          theme.textTheme.bodySmall?.fontWeight,
          theme.textTheme.labelLarge?.fontWeight,
          theme.textTheme.displaySmall?.fontWeight,
        ];
        expect(weights, isNot(contains(FontWeight.w900)));
      });
    }

    test('kFontFamily/kFontFamilyFallback constants match the bundled '
        'pubspec.yaml font declarations', () {
      expect(kFontFamily, 'Inter');
      expect(kFontFamilyFallback, ['Noto Sans SC', 'Noto Sans Tamil']);
    });
  });
}
