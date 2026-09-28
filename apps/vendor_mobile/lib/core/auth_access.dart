/// Which Vendor Sign-In variant the app opens with (D-74).
///
/// A presentation hint only. It never grants a role: after sign-in the
/// role comes from the server (claim_my_team_invitations, then
/// get_my_businesses). Opening the Operator Sign-In does not make anyone an
/// Operator.
enum AuthAccess { vendor, operator }

/// `?access=operator` on the launch URL (web preview / links) selects the
/// Operator Sign-In. Anything else is the standard Vendor Sign-In.
AuthAccess authAccessFromUri(Uri uri) =>
    uri.queryParameters['access'] == 'operator'
    ? AuthAccess.operator
    : AuthAccess.vendor;
