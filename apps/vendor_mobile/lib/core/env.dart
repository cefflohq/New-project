/// Runtime configuration. Values are injected at build time with
/// --dart-define; nothing is hardcoded here so no key is ever committed.
///
///   flutter run -d chrome \
///     --dart-define=CEFFLO_ENVIRONMENT=staging \
///     --dart-define=SUPABASE_URL=`https://<ref>.supabase.co` \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=`<publishable key>`
class Env {
  static const environment = String.fromEnvironment(
    'CEFFLO_ENVIRONMENT',
    defaultValue: 'unset',
  );
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Public invitation page (Vendor Web uses the same host). Overridable per
  /// build so a staging build can point at the staging invite page.
  static const inviteBaseUrl = String.fromEnvironment(
    'CEFFLO_INVITE_BASE_URL',
    defaultValue: 'https://invite.cefflo.com/',
  );

  /// Helper PWA workspace (D-73). Defaults to /helper/ beside the invite page.
  static const _helperBaseUrl = String.fromEnvironment(
    'CEFFLO_HELPER_BASE_URL',
  );
  static String get helperBaseUrl => _helperBaseUrl.isNotEmpty
      ? _helperBaseUrl
      : Uri.parse(inviteBaseUrl).resolve('../helper/').toString();

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Production Supabase project. A build must name its environment
  /// explicitly, and the URL must agree with it, so a staging build can
  /// never point at Production (or the reverse) by accident.
  static const productionProjectRef = 'lmaxtrubwdniovxyuqdy';

  static bool get _urlIsProduction =>
      Uri.tryParse(supabaseUrl)?.host == '$productionProjectRef.supabase.co';

  static bool get isValidTarget => switch (environment) {
    'production' => _urlIsProduction,
    'staging' || 'local' => !_urlIsProduction,
    _ => false,
  };

  static String get configurationProblem {
    if (!isConfigured) {
      return 'SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY were not provided at build time.';
    }
    if (!isValidTarget) {
      return 'CEFFLO_ENVIRONMENT "$environment" does not match SUPABASE_URL. '
          'Use "production" only with the Production project, and '
          '"staging" or "local" with anything else.';
    }
    return '';
  }
}
