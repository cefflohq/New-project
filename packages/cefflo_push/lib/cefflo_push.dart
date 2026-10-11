/// Closed-app alerts on this device (Web Push), the Flutter side of
/// `shared/push/push.js`. Web builds only; elsewhere [CefPush.supported] is
/// false. docs/cefflo/security/PUSH_NOTIFICATIONS.md
library;

export 'src/push_stub.dart' if (dart.library.js_interop) 'src/push_web.dart';
