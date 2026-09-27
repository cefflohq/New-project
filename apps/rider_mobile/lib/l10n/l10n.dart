import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// UI strings for the active locale (standard gen-l10n [AppLocalizations]).
///
/// Widgets read strings through [L] so that code without a [BuildContext]
/// (models, labels, validators) localizes the same way. The shell keys its
/// subtree by locale, so a language change rebuilds every screen.
AppLocalizations get L => _current;
AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

/// Called by the app state whenever the UI locale changes.
void applyUiLocale(Locale locale) {
  _current = lookupAppLocalizations(locale);
}
