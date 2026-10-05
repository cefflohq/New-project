import 'dart:js_interop';

import 'package:flutter/painting.dart';

@JS('document.documentElement')
external _Styled? get _html;

@JS('document.body')
external _Styled? get _body;

extension type _Styled(JSObject _) implements JSObject {
  external _Style get style;
}

extension type _Style(JSObject _) implements JSObject {
  external set backgroundColor(JSString value);
}

/// Paints the page's root background with the colour at the bottom edge of
/// the current screen. Android browsers that do not draw the page behind
/// the gesture / navigation bar tint that bar with the root background, and
/// an edge-to-edge page shows it under the bar, so this keeps the screen
/// visually continuous to the physical edge (no separate footer strip).
void syncBrowserBottomColor(Color color) {
  final hex = _toHex(color).toJS;
  _html?.style.backgroundColor = hex;
  _body?.style.backgroundColor = hex;
}

String _toHex(Color color) {
  int channel(double v) => (v * 255).round().clamp(0, 255);
  final r = channel(color.r).toRadixString(16).padLeft(2, '0');
  final g = channel(color.g).toRadixString(16).padLeft(2, '0');
  final b = channel(color.b).toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}
