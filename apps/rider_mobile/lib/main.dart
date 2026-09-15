import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_state.dart';
import 'core/env.dart';
import 'core/responsive.dart';
import 'core/theme.dart';
import 'data/rider_repository.dart';
import 'ui/router.dart';
import 'ui/screens/auth.dart';
import 'ui/shell.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // UI prototype / preview boot mode. No Supabase credentials, no network:
  // every screen reads `demo_data.dart` fixtures through
  // `RiderRepository.demo()`, so the whole D01-D40C set is runnable and
  // screenshot-able. Same convention as Vendor Mobile's main.dart.
  //
  //   flutter build web --dart-define=CEFFLO_UI_PROTOTYPE=true
  const uiPrototype = bool.fromEnvironment('CEFFLO_UI_PROTOTYPE');
  if (uiPrototype) {
    runApp(DriverMobileApp(repo: RiderRepository.demo()));
    return;
  }

  if (!Env.isConfigured || !Env.isNonProduction) {
    runApp(ConfigurationErrorApp(message: Env.configurationProblem));
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );

  runApp(DriverMobileApp(repo: RiderRepository(Supabase.instance.client)));
}

class DriverMobileApp extends StatefulWidget {
  const DriverMobileApp({super.key, required this.repo});

  final RiderRepository repo;

  @override
  State<DriverMobileApp> createState() => _DriverMobileAppState();
}

class _DriverMobileAppState extends State<DriverMobileApp> {
  late final AppState app = AppState(widget.repo);
  bool _prototypeAuthenticated = false;

  @override
  void initState() {
    super.initState();
    app.onPrototypeSignOut = () {
      if (mounted) setState(() => _prototypeAuthenticated = false);
    };
    if (widget.repo.isDemo || widget.repo.currentUser != null) {
      app.loadSession();
    } else {
      app.loadingSession = false;
    }
    widget.repo.authChanges.listen((state) {
      if (state.session == null) app.clearSession();
    });
  }

  bool get _signedIn => widget.repo.isDemo
      ? _prototypeAuthenticated
      : widget.repo.currentUser != null;

  @override
  Widget build(BuildContext context) => AppScope(
    state: app,
    child: AnimatedBuilder(
      animation: app,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cefflo Driver',
        // Locked Light Mode only: D38 shows an Appearance row, but no
        // reference draws a dark screen, so no dark theme is built behind it.
        themeMode: AppState.themeMode,
        theme: buildRiderTheme(),
        // Applied above the Navigator so every route, dialog and bottom
        // sheet lays out against the same normalized canvas.
        builder: (context, child) => ResponsiveDensity(child: child!),
        home: Builder(
          builder: (context) {
            if (!_signedIn) {
              return AuthFlow(
                onAuthenticated: () {
                  app.resetTo(app.homeRoute);
                  setState(() => _prototypeAuthenticated = true);
                },
              );
            }
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
            return DriverShell(child: buildScreen(context, app.current));
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
    theme: buildRiderTheme(),
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.section),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cefflo Driver is not configured',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Gap.md),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: Gap.md),
                const Text(
                  'Pass CEFFLO_ENVIRONMENT, SUPABASE_URL and '
                  'SUPABASE_PUBLISHABLE_KEY with --dart-define, or build the '
                  'preview with --dart-define=CEFFLO_UI_PROTOTYPE=true.',
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
