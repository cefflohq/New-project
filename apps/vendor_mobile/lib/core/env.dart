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

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// The app refuses to run against anything that is not explicitly a
  /// non-production environment. Production wiring is out of scope for this
  /// client and must never be enabled by accident.
  static bool get isNonProduction =>
      environment == 'staging' || environment == 'local';

  static String get configurationProblem {
    if (!isConfigured) {
      return 'SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY were not provided at build time.';
    }
    if (!isNonProduction) {
      return 'CEFFLO_ENVIRONMENT must be "staging" or "local" for this build. '
          'Got "$environment".';
    }
    return '';
  }
}
