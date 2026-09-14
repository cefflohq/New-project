import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_state.dart';
import 'core/env.dart';
import 'core/preview_path.dart';
import 'core/responsive.dart';
import 'core/routes.dart';
import 'core/theme.dart';
import 'data/vendor_repository.dart';
import 'ui/router.dart';
import 'ui/screens/auth.dart';
import 'ui/shell.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const uiPrototype = bool.fromEnvironment('CEFFLO_UI_PROTOTYPE');
  if (uiPrototype) {
    // Flutter's web bootstrap owns the browser location. Reading the initial
    // route keeps preview-only deep links deterministic even though index.html
    // uses a root <base> for static assets.
    final browserPath = previewBrowserPath();
    final initialRoute = browserPath.isNotEmpty
        ? browserPath
        : WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    final auditId = _auditIdFromUri(
      initialRoute.isEmpty ? Uri.base : Uri.parse(initialRoute),
    );
    runApp(
      VendorMobileApp(
        repo: VendorRepository.demo(),
        auditId: auditId,
        auditLocation: auditId == null ? null : _auditLocation(auditId),
      ),
    );
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

  runApp(VendorMobileApp(repo: VendorRepository(Supabase.instance.client)));
}

class VendorMobileApp extends StatefulWidget {
  const VendorMobileApp({
    super.key,
    required this.repo,
    this.auditId,
    this.auditLocation,
  });
  final VendorRepository repo;
  final int? auditId;
  final VendorLocation? auditLocation;

  @override
  State<VendorMobileApp> createState() => _VendorMobileAppState();
}

class _VendorMobileAppState extends State<VendorMobileApp> {
  late final AppState app = AppState(widget.repo);
  bool _prototypeAuthenticated = false;

  @override
  void initState() {
    super.initState();
    if (widget.auditLocation != null) {
      _prototypeAuthenticated = true;
      final location = widget.auditLocation!;
      if (location.route != VRoute.today || location.entityId != null) {
        app.go(location.route, entityId: location.entityId);
      }
    }
    if (widget.repo.isDemo) {
      app.loadSession();
    } else if (widget.repo.currentUser != null) {
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
        // Locked: Light Mode only for the current release. No system/dark
        // theme switch is exposed (Appearance is a "Coming Soon" surface).
        themeMode: ThemeMode.light,
        theme: buildVendorTheme(Brightness.light),
        // Applied above the Navigator so every route, dialog and bottom
        // sheet lays out against the same normalized canvas.
        builder: (context, child) => ResponsiveDensity(child: child!),
        home: Builder(
          builder: (context) {
            final id = widget.auditId;
            if (widget.repo.isDemo && id != null && id <= 8) {
              return AuthAuditScreen(id: id);
            }
            if (widget.repo.isDemo && widget.auditId == 41) {
              return const _ReservedAuditScreen(
                id: 'V41',
                title: 'Delivery Settings',
                status: 'REMOVED / RESERVED',
              );
            }
            // Founder-locked Vendor Auth batch (2026-09-11): the auth family
            // owns its own stage flow, starting at the locked Splash.
            if ((widget.repo.isDemo && !_prototypeAuthenticated) ||
                (!widget.repo.isDemo && widget.repo.currentUser == null)) {
              return AuthFlow(
                onPrototypeAuthenticated: widget.repo.isDemo
                    ? () => setState(() => _prototypeAuthenticated = true)
                    : null,
                onPrototypeSignedUp: widget.repo.isDemo
                    ? () => setState(() {
                        _prototypeAuthenticated = true;
                        app.resetTo(VRoute.welcomeSetup);
                      })
                    : null,
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
            return VendorShell(child: buildScreen(context, app.current));
          },
        ),
      ),
    ),
  );
}

int? _auditIdFromUri(Uri uri) {
  if (uri.pathSegments.length != 2 ||
      uri.pathSegments.first.toLowerCase() != 'audit') {
    return null;
  }
  final raw = uri.pathSegments[1].toUpperCase();
  if (!RegExp(r'^V\d{2}$').hasMatch(raw)) return null;
  final id = int.tryParse(raw.substring(1));
  return id != null && id >= 1 && id <= 60 ? id : null;
}

VendorLocation? _auditLocation(int id) {
  if (id <= 8 || id == 41) return null;
  if (id == 9) return const VendorLocation(VRoute.welcomeSetup);
  if (id == 10) return const VendorLocation(VRoute.setupComplete);

  final canonicalId = 'V-${id.toString().padLeft(2, '0')}';
  final spec = routeSpecs.values.cast<RouteSpec?>().firstWhere(
    (candidate) => candidate?.id == canonicalId,
    orElse: () => null,
  );
  if (spec == null) return null;

  final entityId = switch (spec.route) {
    VRoute.orderDetail || VRoute.editOrder => 'ord-1001',
    VRoute.zoneDetail || VRoute.reviewDispatch => 'zone-bangsar',
    VRoute.runDetail => 'RUN-0182',
    VRoute.riderDetail => 'rider-ahmad',
    VRoute.teamMemberDetail => 'team-owner',
    VRoute.editZone => 'zone-bangsar',
    VRoute.productDetail => 'prod-1',
    _ => null,
  };
  return VendorLocation(spec.route, entityId: entityId);
}

class _ReservedAuditScreen extends StatelessWidget {
  const _ReservedAuditScreen({
    required this.id,
    required this.title,
    required this.status,
  });

  final String id;
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Gap.section),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$id · $title',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: Gap.sm),
              Text(status, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: Gap.sm),
              Text(
                'Inventory position retained for audit only. No product screen is implemented.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
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
