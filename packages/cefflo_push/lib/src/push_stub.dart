/// Non-web builds: closed-app alerts need FCM (Phase P2), not built yet.
abstract final class CefPush {
  static bool get supported => false;
  static String get permission => 'unsupported';
  static Future<bool> isOn() async => false;
  static Future<String> enable({
    required String supabaseUrl,
    required String anonKey,
    required String accessToken,
    required String app,
  }) async =>
      'unsupported';
  static Future<void> disable({
    required String supabaseUrl,
    required String anonKey,
    String? accessToken,
  }) async {}
}
