import 'package:cefflo_loader/cefflo_loader.dart';

import 'core/auth_access.dart';
import 'ui/screens/helper_workspace.dart';

import 'package:flutter/material.dart';

import 'core/keep_signed_in.dart';

import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_state.dart';
import 'core/appearance.dart';
import 'core/browser_history.dart';
import 'core/chrome_color.dart';
import 'core/env.dart';
import 'core/preview_path.dart';
import 'core/responsive.dart';
import 'core/routes.dart';
import 'core/safe_area.dart';
import 'core/theme.dart';
import 'l10n/l10n.dart';
import 'core/ui_locale.dart';
import 'data/vendor_repository.dart';
import 'ui/brand_block.dart';
import 'ui/router.dart';
import 'ui/screens/auth.dart';
import 'ui/shell.dart';
import 'ui/system_bars.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await precacheBrandAssets();

  // Global edge-to-edge system chrome (see ui/system_bars.dart). Must run
  // once before the first frame so Android lays the Flutter canvas out
  // full-screen behind the status/navigation bars -- a no-op on Web, where
  // there is no native system bar to affect.
  CefSystemBars.enableEdgeToEdge();

  // Keeps the browser/OS status bar in sync with the app's own chrome
  // colour instead of a hand-edited hex string in index.html that can
  // silently drift out of sync with it. Locked Light Mode only (see
  // themeMode below), so CefColors.light is always the correct source.
  syncBrowserChromeColor(CefColors.light.chrome);

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
        // Prototype only: ?access=helper previews the Helper workspace.
        repo: VendorRepository.demo(
          demoRole: switch (authAccessFromUri(Uri.base)) {
            AuthAccess.helper => 'helper',
            AuthAccess.operator => 'operator',
            AuthAccess.vendor => 'owner',
          },
        ),
        access: authAccessFromUri(Uri.base),
        auditId: auditId,
        auditLocation: auditId == null ? null : _auditLocation(auditId),
      ),
    );
    return;
  }

  if (!Env.isConfigured || !Env.isValidTarget) {
    runApp(ConfigurationErrorApp(message: Env.configurationProblem));
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  await endSessionIfNotKept(Supabase.instance.client);

  runApp(
    VendorMobileApp(
      repo: VendorRepository(Supabase.instance.client),
      access: authAccessFromUri(Uri.base),
    ),
  );
}

class VendorMobileApp extends StatefulWidget {
  const VendorMobileApp({
    super.key,
    required this.repo,
    this.access = AuthAccess.vendor,
    this.auditId,
    this.auditLocation,
  });
  final VendorRepository repo;

  /// Sign-In variant (D-74); presentation only, never a role.
  final AuthAccess access;
  final int? auditId;
  final VendorLocation? auditLocation;

  @override
  State<VendorMobileApp> createState() => _VendorMobileAppState();
}

class _VendorMobileAppState extends State<VendorMobileApp> {
  late final AppState app = AppState(widget.repo);
  bool _prototypeAuthenticated = false;

  /// A password-recovery link opened the app (native deep link).
  bool _recovering = false;

  /// An emailed auth link opened the app but the server refused it
  /// (expired, already used, or opened away from the requesting device).
  bool _linkRejected = false;

  /// A 6-digit code flow is finishing inside the auth screens (see
  /// AuthFlow.onCodeHold): keep them on top even though a session exists.
  bool _codeHold = false;

  @override
  void initState() {
    super.initState();
    applyUiLocale(app.uiLocale);
    app.restoreUiLocale();
    app.restoreAppearance();
    listenBrowserBack(app.onBrowserBack);
    if (!widget.repo.isDemo) app.restoreJoinToken(Uri.base);
    app.access = widget.access;
    // Sign Out calls app.clearSession(), which lives in AppState -- but the
    // "is a prototype session authenticated" flag below has to live here
    // instead, since it gates which widget MaterialApp.home builds, before
    // AppScope/AppState even exists in the tree. Without this hook, Sign
    // Out cleared business data but never reached this flag, so the app
    // shell stayed on screen instead of returning to Sign In.
    app.onSignOut = () {
      if (mounted) setState(() => _prototypeAuthenticated = false);
    };
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
    widget.repo.authChanges.listen(_onAuthChange, onError: _onAuthLinkError);
  }

  void _onAuthChange(AuthState state) {
    if (!mounted) return;
    switch (state.event) {
      case AuthChangeEvent.passwordRecovery:
        setState(() {
          _recovering = true;
          _linkRejected = false;
        });
      case AuthChangeEvent.signedIn:
        // A sign-up confirmation link signs the user in outside the auth
        // screens. Rebuild, and load the session after this frame unless
        // the sign-in screen is already doing it.
        setState(() => _linkRejected = false);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _recovering || _codeHold) return;
          if (widget.repo.currentUser != null &&
              !app.loadingSession &&
              !app.sessionLoaded) {
            app.loadSession();
          }
        });
      default:
        break;
    }
    if (state.session == null) {
      app.clearSession();
    }
  }

  /// supabase_flutter reports a refused callback link as a stream error.
  void _onAuthLinkError(Object error) {
    if (!mounted || error is! AuthException) return;
    setState(() => _linkRejected = true);
  }

  ThemeData _themeWithAccent() {
    CefColors.applyAccent(liveAppearance.value.accent);
    return buildVendorTheme(Brightness.light);
  }

  @override
  Widget build(BuildContext context) => AppScope(
    state: app,
    child: AnimatedBuilder(
      // The device-local Appearance drives the accent (active tabs, nav,
      // accent icons) live, including while it is only being previewed.
      animation: Listenable.merge([app, liveAppearance]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cefflo Vendor',
        // BM + EN (Founder 2026-09-27). Country never selects language.
        locale: app.uiLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        // Locked: Light Mode only for the current release. No system/dark
        // theme switch is exposed (Appearance is a "Coming Soon" surface).
        themeMode: ThemeMode.light,
        theme: _themeWithAccent(),
        // Applied above the Navigator so every route, dialog and bottom
        // sheet lays out against the same normalized canvas, and -- since
        // this app is overwhelmingly light-background -- gets the
        // reusable edge-to-edge system-bar treatment for a light screen by
        // default. Screens with a dark background (Splash, Sign In, the
        // Auth sheet family) nest their own CefSystemBars deeper in the
        // tree, which takes precedence for that route.
        builder: (context, child) => CefLoaderHost(
          child: LocaleRefresh(
            locale: app.uiLocale,
            accent: CefColors.brand,
            child: CefSystemBars(
              background: Brightness.light,
              browserChromeColor: CefColors.light.chrome,
              child: _EdgeToEdgeInsets(child: ResponsiveDensity(child: child!)),
            ),
          ),
        ),
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
            if (widget.repo.isDemo && widget.auditId == 42) {
              return const _ReservedAuditScreen(
                id: 'V42',
                title: 'Profile',
                status: 'REMOVED — merged into Settings (D-46)',
              );
            }
            if (widget.repo.isDemo && widget.auditId == 48) {
              return const _ReservedAuditScreen(
                id: 'V48',
                title: 'Language',
                status: 'Bottom sheet from More (D-54)',
              );
            }
            if (widget.repo.isDemo && widget.auditId == 53) {
              return const _ReservedAuditScreen(
                id: 'V53',
                title: 'Payment Success',
                status: 'Centred modal over Review & Payment (D-54)',
              );
            }
            if (widget.repo.isDemo && widget.auditId == 18) {
              return const _ReservedAuditScreen(
                id: 'V18',
                title: 'Review Delivery Plan',
                status: 'REMOVED — consolidated into Zone detail (D-49)',
              );
            }
            if (widget.repo.isDemo && widget.auditId == 30) {
              return const _ReservedAuditScreen(
                id: 'V30',
                title: 'Edit Zone',
                status: 'REMOVED — Zone detail ⋮ Zone options (D-49)',
              );
            }
            // Founder-locked Vendor Auth batch (2026-09-11): the auth family
            // owns its own stage flow, starting at the locked Splash.
            if (_recovering ||
                _codeHold ||
                (widget.repo.isDemo && !_prototypeAuthenticated) ||
                (!widget.repo.isDemo && widget.repo.currentUser == null)) {
              return AuthFlow(
                key: ValueKey((_recovering, _linkRejected)),
                access: widget.access,
                recovery: _recovering,
                linkRejected: _linkRejected,
                onRecoveryDone: () async {
                  await widget.repo.signOut();
                  if (mounted) {
                    setState(() {
                      _recovering = false;
                      _codeHold = false;
                    });
                  }
                },
                onCodeHold: (hold) {
                  if (!mounted) return;
                  setState(() => _codeHold = hold);
                  // Released with a session (sign-up verified): load it,
                  // which the signedIn listener skipped while held.
                  if (!hold &&
                      widget.repo.currentUser != null &&
                      !app.loadingSession &&
                      !app.sessionLoaded) {
                    app.loadSession();
                  }
                },
                onPrototypeAuthenticated: widget.repo.isDemo
                    ? () => setState(() => _prototypeAuthenticated = true)
                    : null,
                onPrototypeSignedUp: widget.repo.isDemo
                    ? () => setState(() {
                        _prototypeAuthenticated = true;
                        // Operator / Helper never register a business.
                        if (widget.access == AuthAccess.vendor) {
                          app.resetTo(VRoute.welcomeSetup);
                        }
                      })
                    : null,
              );
            }
            // Opened from a permanent invite link: finish the join request
            // before anything else (never Business Setup, which would make
            // this account an Owner).
            if (!widget.repo.isDemo && app.joinToken != null) {
              return JoinRequestScreen(token: app.joinToken!);
            }
            if (app.loadingSession) {
              return const Scaffold(body: StateBlock.loading());
            }
            if (app.sessionError != null) {
              return Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.gutter),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StateBlock.error(
                          app.sessionError!,
                          onRetry: app.loadSession,
                        ),
                        // A signed-in account that cannot continue (e.g. no
                        // Operator access yet) can switch account.
                        TextButton(
                          onPressed: () async {
                            await widget.repo.signOut();
                            app.clearSession();
                          },
                          child: Text(L.signOut),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            // D-74 role resolution: a Helper gets only the fulfilment
            // workspace, never the Vendor shell or its navigation.
            if (app.business?.isHelper ?? false) {
              return const HelperWorkspaceScreen();
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
  if (id <= 8 || const {18, 30, 41, 42, 48, 53}.contains(id)) return null;
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
    VRoute.zoneDetail => 'zone-bangsar',
    VRoute.runDetail => 'RUN-0182',
    VRoute.riderDetail => 'rider-ahmad',
    VRoute.teamMemberDetail => 'team-owner',
    VRoute.productDetail => 'prod-1',
    VRoute.reviewPayment => 'operate:monthly',
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
    home: CefSystemBars(
      background: Brightness.light,
      browserChromeColor: CefColors.light.chrome,
      child: Scaffold(
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
    ),
  );
}

/// Edge-to-edge on the web (D-53): the page draws behind the Android gesture
/// bar, so the bottom system inset the engine does not report is added to
/// MediaQuery here, once -- every SafeArea (bottom navigation, sheets,
/// surfaces) then clears the gesture pill while its own background continues
/// behind it. No-op on native builds.
class _EdgeToEdgeInsets extends StatelessWidget {
  const _EdgeToEdgeInsets({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = webSafeAreaBottom();
    if (bottom <= media.padding.bottom) return child;
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(bottom: bottom),
        viewPadding: media.viewPadding.copyWith(bottom: bottom),
      ),
      child: child,
    );
  }
}
