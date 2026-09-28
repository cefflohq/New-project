import 'dart:js_interop';

import 'package:flutter/painting.dart';

@JS('document.querySelector')
external JSAny? _querySelector(JSString selectors);

extension type _MetaElement(JSObject _) implements JSObject {
  external void setAttribute(JSString name, JSString value);
}

/// Writes [color] into the live `<meta name="theme-color">` tag so the
/// browser/OS status bar is derived from the same `CefColors` value the
/// header/bottom-nav chrome actually renders with, instead of a hand-edited
/// hex string in `index.html` that can silently drift out of sync with it.
///
/// `SystemChrome.setSystemUIOverlayStyle` (used in `shell.dart` for native
/// builds) does not reach this tag on Flutter Web on this engine version --
/// verified empirically: the tag's value was still the static HTML default
/// seconds after the app finished booting. This talks to the DOM directly
/// instead of relying on that channel.
void syncBrowserChromeColor(Color color) {
  final meta = _querySelector('meta[name="theme-color"]'.toJS);
  if (meta == null) return;
  (meta as _MetaElement).setAttribute('content'.toJS, _toHex(color).toJS);
}

String _toHex(Color color) {
  int channel(double v) => (v * 255).round().clamp(0, 255);
  final r = channel(color.r).toRadixString(16).padLeft(2, '0');
  final g = channel(color.g).toRadixString(16).padLeft(2, '0');
  final b = channel(color.b).toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}
