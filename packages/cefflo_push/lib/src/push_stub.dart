import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Native builds: closed-app alerts through FCM (Android). The system shows
/// them from the server's `notification` payload, so a closed app needs no
/// Dart code to run. docs/cefflo/security/PUSH_NOTIFICATIONS.md
abstract final class CefPush {
  static const _onKey = 'cefflo.push.fcm_token';
  static String _permission = 'default';
  static Future<bool>? _ready;

  static bool get supported => !kIsWeb && Platform.isAndroid;
  static String get permission => supported ? _permission : 'unsupported';

  static Future<bool> _init() => _ready ??= () async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final s = await FirebaseMessaging.instance.getNotificationSettings();
      _permission = _name(s.authorizationStatus);
      return true;
    } catch (e) {
      debugPrint('FCM unavailable: $e');
      _ready = null;
      return false;
    }
  }();

  static String _name(AuthorizationStatus s) => switch (s) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => 'granted',
    AuthorizationStatus.denied => 'denied',
    _ => 'default',
  };

  /// Notification ids the user tapped to open the app (closed or in the
  /// background), so the app can follow them to the order or run.
  static Stream<String> get opened async* {
    if (!supported || !await _init()) return;
    final first = await FirebaseMessaging.instance.getInitialMessage();
    final id = first?.data['id'];
    if (id is String) yield id;
    yield* FirebaseMessaging.onMessageOpenedApp
        .map((m) => m.data['id'])
        .where((id) => id is String)
        .cast<String>();
  }

  static Future<bool> isOn() async {
    if (!supported || !await _init()) return false;
    final saved = (await SharedPreferences.getInstance()).getString(_onKey);
    return saved != null && _permission == 'granted';
  }

  /// 'on' | 'denied' | 'unsupported'.
  static Future<String> enable({
    required String supabaseUrl,
    required String anonKey,
    required String accessToken,
    required String app,
  }) async {
    if (!supported || !await _init()) return 'unsupported';
    final m = FirebaseMessaging.instance;
    _permission = _name((await m.requestPermission()).authorizationStatus);
    if (_permission != 'granted') return 'denied';
    final token = await m.getToken();
    if (token == null) return 'unsupported';
    final ok = await _rpc(supabaseUrl, anonKey, accessToken, 'push_register_fcm', {
      'p_app': app,
      'p_token': token,
    });
    if (!ok) return 'unsupported';
    await (await SharedPreferences.getInstance()).setString(_onKey, token);
    return 'on';
  }

  /// Removes this device; call before sign-out.
  static Future<void> disable({
    required String supabaseUrl,
    required String anonKey,
    String? accessToken,
  }) async {
    if (!supported) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_onKey);
    if (token == null) return;
    await prefs.remove(_onKey);
    if (accessToken != null) {
      await _rpc(supabaseUrl, anonKey, accessToken, 'push_unregister', {
        'p_endpoint': token,
      });
    }
    try {
      if (await _init()) await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  static Future<bool> _rpc(
    String url,
    String anonKey,
    String accessToken,
    String name,
    Map<String, Object?> args,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('${url.replaceAll(RegExp(r'/$'), '')}/rest/v1/rpc/$name'),
        headers: {
          'apikey': anonKey,
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        },
        body: jsonEncode(args),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('push $name failed: $e');
      return false;
    }
  }
}
