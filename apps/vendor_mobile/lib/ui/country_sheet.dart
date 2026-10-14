import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/country.dart';

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
  final regions = <String>[];
  for (final c in Country.selectable) {
    if (!regions.contains(c.region)) regions.add(c.region);
  }
  return showModalBottomSheet<CountryPack>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(
              countryLabel(sheet),
              style: Theme.of(sheet).textTheme.titleLarge,
            ),
          ),
          for (final r in regions) ...[
            ListTile(dense: true, title: Text(_regionNames[r] ?? r)),
            for (final c in Country.selectable.where((x) => x.region == r))
              ListTile(
                title: Text('${c.nameEn}  ${c.phoneCode}'),
                trailing: c.iso2 == Country.current.iso2
                    ? const Icon(LucideIcons.check)
                    : null,
                onTap: () => Navigator.of(sheet).pop(c),
              ),
          ],
        ],
      ),
    ),
  );
}
