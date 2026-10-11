import 'dart:js_interop';

@JS('cefPush')
external _Bridge? get _bridge;

extension type _Bridge(JSObject _) implements JSObject {
  external JSBoolean supported();
  external JSString permission();
  external JSPromise<JSBoolean> isOn();
  external JSPromise<JSString> enable(JSObject options);
  external JSPromise<JSAny?> disable(JSObject options);
}

@JS('Object')
extension type _Obj._(JSObject _) implements JSObject {
  external _Obj();
}

extension on _Obj {
  external set supabaseUrl(JSString v);
  external set anonKey(JSString v);
  external set accessToken(JSString? v);
  external set app(JSString v);
}

/// Web builds: delegates to `window.cefPush` (shared/push/push.js).
abstract final class CefPush {
  static bool get supported => _bridge?.supported().toDart ?? false;
  static String get permission => _bridge?.permission().toDart ?? 'unsupported';

  static Future<bool> isOn() async {
    final b = _bridge;
    if (b == null) return false;
    try {
      return (await b.isOn().toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  /// 'on' | 'denied' | 'unsupported'. Call from a tap (browser rule).
  static Future<String> enable({
    required String supabaseUrl,
    required String anonKey,
    required String accessToken,
    required String app,
  }) async {
    final b = _bridge;
    if (b == null) return 'unsupported';
    final o = _Obj()
      ..supabaseUrl = supabaseUrl.toJS
      ..anonKey = anonKey.toJS
      ..accessToken = accessToken.toJS
      ..app = app.toJS;
    return (await b.enable(o).toDart).toDart;
  }

  /// Removes this device; call before sign-out.
  static Future<void> disable({
    required String supabaseUrl,
    required String anonKey,
    String? accessToken,
  }) async {
    final b = _bridge;
    if (b == null) return;
    final o = _Obj()
      ..supabaseUrl = supabaseUrl.toJS
      ..anonKey = anonKey.toJS
      ..accessToken = accessToken?.toJS;
    try {
      await b.disable(o).toDart;
    } catch (_) {}
  }
}
