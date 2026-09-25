import 'dart:js_interop';

@JS('document.getElementById')
external _Probe? _byId(JSString id);

extension type _Probe(JSObject _) implements JSObject {
  external num get offsetHeight;
}

/// The bottom system inset (Android gesture / navigation area) of an
/// edge-to-edge page, read from the `#cef-safe-area` probe in index.html,
/// whose height is `env(safe-area-inset-bottom)`. Flutter Web does not
/// report this inset itself, so without it the bottom navigation would sit
/// under the gesture pill once the page draws behind the system bar.
double webSafeAreaBottom() =>
    (_byId('cef-safe-area'.toJS)?.offsetHeight ?? 0).toDouble();
