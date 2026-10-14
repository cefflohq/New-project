import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/country.dart';
import '../core/theme.dart';
import 'widgets.dart';

/// "Country" / "Negara" without a generated l10n key (added with the next
/// gen-l10n pass).
String countryLabel(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ms' ? 'Negara' : 'Country';

const _regionNames = {
  'asia': 'Asia',
  'europe': 'Europe',
  'middle_east': 'Middle East',
  'oceania': 'Oceania',
  'americas': 'Americas',
  'africa': 'Africa',
};

/// Region > Country picker (live / beta packs only). Returns the pick.
Future<CountryPack?> showCountrySheet(BuildContext context) {
  final regions = <String>[
    for (final c in Country.selectable)
      if (!Country.selectable
          .takeWhile((x) => x != c)
          .any((x) => x.region == c.region))
        c.region,
  ];
  return showCeffloSheet<CountryPack>(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetGrabber(),
        const SizedBox(height: 6),
        Text(
          countryLabel(context),
          textAlign: TextAlign.center,
          style: context.t.titleLarge,
        ),
        const SizedBox(height: Gap.lg),
        for (final r in regions) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.gutter, 8, Gap.gutter, 4),
            child: Text(
              _regionNames[r] ?? r,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.c.textSecondary,
              ),
            ),
          ),
          for (final c in Country.selectable.where((x) => x.region == r))
            InkWell(
              onTap: () => Navigator.of(context).pop(c),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.gutter,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${c.nameEn}  ${c.phoneCode}',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.c.textPrimary,
                        ),
                      ),
                    ),
                    if (c.iso2 == Country.current.iso2)
                      Icon(LucideIcons.check, size: 20, color: context.c.textPrimary),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: Gap.lg),
      ],
    ),
  );
}
