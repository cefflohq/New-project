import 'package:shared_preferences/shared_preferences.dart';

/// A permanent invite link (Founder, 2026-10-01) opens this app with
/// `?join=<token>`. The token is kept on the device through sign-up / email
/// verification, then submitted once with join_via_invite_link. It grants
/// nothing by itself: every join is pending until the Owner approves.
class JoinLinkStore {
  static const key = 'cefflo.join_link';

  static bool isToken(String? t) =>
      t != null && RegExp(r'^[0-9a-f]{48}$').hasMatch(t);

  /// From the launch URL when present (and remembered), else the stored one.
  Future<String?> read(Uri launch) async {
    final fromUrl = launch.queryParameters['join'];
    try {
      final p = await SharedPreferences.getInstance();
      if (isToken(fromUrl)) {
        await p.setString(key, fromUrl!);
        return fromUrl;
      }
      final stored = p.getString(key);
      return isToken(stored) ? stored : null;
    } catch (_) {
      return isToken(fromUrl) ? fromUrl : null;
    }
  }

  Future<void> clear() async {
    try {
      await (await SharedPreferences.getInstance()).remove(key);
    } catch (_) {}
  }
}
