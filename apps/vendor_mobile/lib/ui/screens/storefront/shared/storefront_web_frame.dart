/// The real public storefront renderer (store/) embedded as the preview.
library;

export 'storefront_web_frame_stub.dart'
    if (dart.library.js_interop) 'storefront_web_frame_web.dart';
