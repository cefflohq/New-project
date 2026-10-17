import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:cefflo_vendor_mobile/core/ui_locale.dart';

/// The suite asserts English copy; the product's first launch is Bahasa
/// Melayu (tested in localization_test.dart).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  firstLaunchLocale = const Locale('en');
  await testMain();
}
