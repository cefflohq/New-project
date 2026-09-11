import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_state.dart';
import 'core/env.dart';
import 'core/theme.dart';
import 'data/vendor_repository.dart';
import 'ui/router.dart';
import 'ui/screens/auth.dart';
import 'ui/shell.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured || !Env.isNonProduction) {
    runApp(ConfigurationErrorApp(message: Env.configurationProblem));
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );

  runApp(VendorMobileApp(repo: VendorRepository(Supabase.instance.client)));
}

class VendorMobileApp extends StatefulWidget {
  const VendorMobileApp({super.key, required this.repo});
  final VendorRepository repo;

  @override
  State<VendorMobileApp> createState() => _VendorMobileAppState();
}

class _VendorMobileAppState extends State<VendorMobileApp> {
  late final AppState app = AppState(widget.repo);

  @override
  void initState() {
    super.initState();
    if (widget.repo.currentUser != null) {
      app.loadSession();
    } else {
      app.loadingSession = false;
    }
    widget.repo.authChanges.listen((state) {
      if (state.session == null) {
        app.clearSession();
      }
    });
  }

  @override
  Widget build(BuildContext context) => AppScope(
    state: app,
    child: AnimatedBuilder(
      animation: app,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cefflo Vendor',
        themeMode: app.themeMode,
        theme: buildVendorTheme(Brightness.light),
        darkTheme: buildVendorTheme(Brightness.dark),
        home: Builder(
          builder: (context) {
            // Founder-locked Vendor Auth batch (2026-09-11): the auth family
            // owns its own stage flow, starting at the locked Splash.
            if (widget.repo.currentUser == null) return const AuthFlow();
            if (app.loadingSession) {
              return const Scaffold(body: StateBlock.loading());
            }
            if (app.sessionError != null) {
              return Scaffold(
                body: SafeArea(
                  child: StateBlock.error(
                    app.sessionError!,
                    onRetry: app.loadSession,
                  ),
                ),
              );
            }
            return VendorShell(child: buildScreen(context, app.current));
          },
        ),
      ),
    ),
  );
}

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildVendorTheme(Brightness.light),
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.section),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cefflo Vendor is not configured',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Gap.md),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: Gap.md),
                const Text(
                  'Pass CEFFLO_ENVIRONMENT, SUPABASE_URL and '
                  'SUPABASE_PUBLISHABLE_KEY with --dart-define.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
