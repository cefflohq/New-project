/// Which Vendor Sign-In variant the app opens with (D-74).
///
/// A presentation hint only. It never grants a role: after sign-in the
/// role comes from the server (get_my_businesses). Opening the Operator Sign-In does not make anyone an
/// Operator.
enum AuthAccess { vendor, operator, helper }

/// `?access=operator` / `?access=helper` on the launch URL (web preview /
/// links) selects that Sign-In. Without it, the dedicated production entry
/// host decides (operator.cefflo.com / helper.cefflo.com, Founder domain map
/// 2026-10-05). Anything else is the standard Vendor Sign-In.
AuthAccess authAccessFromUri(Uri uri) =>
    switch (uri.queryParameters['access']) {
      'operator' => AuthAccess.operator,
      'helper' => AuthAccess.helper,
      _ => switch (uri.host.split('.').first) {
        'operator' => AuthAccess.operator,
        'helper' => AuthAccess.helper,
        _ => AuthAccess.vendor,
      },
    };
