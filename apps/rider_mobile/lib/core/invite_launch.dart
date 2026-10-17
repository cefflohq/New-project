import 'dart:io' show Platform;

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

/// Where a driver invite token arrives from (Founder 2026-10-16, option B):
/// - web: the page URL (`?join=TOKEN`);
/// - Android, app already installed: the invite page opens
///   `cefflo-driver://join?join=TOKEN`;
/// - Android, first install from the invite: Google Play hands the app the
///   install referrer `join=TOKEN` (Play Install Referrer API).
/// Returns a URI whose ?join= carries the token when one is found.
Future<Uri> inviteLaunchUri(Uri webBase) async {
  if (kIsWeb || !Platform.isAndroid) return webBase;
  try {
    final link = await AppLinks().getInitialLink();
    if (link != null && link.queryParameters['join'] != null) return link;
  } catch (_) {}
  try {
    final details = await PlayInstallReferrer.installReferrer;
    final raw = details.installReferrer ?? '';
    final token = Uri.splitQueryString(Uri.decodeComponent(raw))['join'];
    if (token != null) return Uri(queryParameters: {'join': token});
  } catch (_) {}
  return webBase;
}
