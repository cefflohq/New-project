import 'dart:js_interop';

@JS('window.location.pathname')
external JSString get _browserPathname;

String previewBrowserPath() => _browserPathname.toDart;
