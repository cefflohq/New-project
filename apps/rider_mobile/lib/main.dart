import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_state.dart';
import 'core/env.dart';
import 'core/live_location.dart';
import 'core/responsive.dart';
import 'core/routes.dart';
import 'core/safe_area.dart';
import 'core/theme.dart';
import 'core/ui_locale.dart';
import 'data/live_adapters.dart';
import 'data/rider_repository.dart';
import 'ui/router.dart';
import 'ui/screens/auth.dart';
import 'ui/shell.dart';
import 'ui/widgets.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge: the app draws behind transparent status and gesture bars.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // UI prototype / preview boot mode. No Supabase credentials, no network:
  // every screen reads `demo_data.dart` fixtures through
  // `RiderRepository.demo()`, so the whole D01-D40C set is runnable and
  // screenshot-able. Same convention as Vendor Mobile's main.dart.
  //
  //   flutter build web --dart-define=CEFFLO_UI_PROTOTYPE=true
  const uiPrototype = bool.fromEnvironment('CEFFLO_UI_PROTOTYPE');
  if (uiPrototype) {
    runApp(
      DriverMobileApp(
        repo: RiderRepository.demo(),
        previewId: previewIdFromUri(Uri.base),
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

  final repo = RiderRepository(Supabase.instance.client);
  runApp(DriverMobileApp(repo: repo, live: _liveFor(repo)));
}

LiveLocationService _liveFor(RiderRepository repo) => LiveLocationService(
  source: GeolocatorSource(),
  channelFor: (topic) => SupabaseLiveChannel(repo.realtimeClient, topic),
  loadKeys: repo.liveKeys,
  write: (riderId, fix) => repo.recordLocation(
    riderId: riderId,
    latitude: fix.latitude,
    longitude: fix.longitude,
    accuracy: fix.accuracy,
    heading: fix.heading,
    speed: fix.speed,
  ),
);

/// Resolves `?screen=D21.2` (or `/screen/D21.2`) to a route, so any one of
/// the locked reference screens can be opened directly in the preview build
/// for review or screenshotting.
///
/// This exists because a handful of screens are reached by a *server* event
/// in real life, not by a tap: D14.1 Application Under Review waits for the
/// business to approve the Driver, and no reference draws a CTA out of it.
/// Rather than invent a button the references do not show, the preview
/// addresses those states directly. Same idea as Vendor Mobile's
/// `/audit/V##` path.
String? previewIdFromUri(Uri uri) {
  final query = uri.queryParameters['screen'];
  if (query != null) return query;
  final segments = uri.pathSegments;
  if (segments.length >= 2 && segments[segments.length - 2] == 'screen') {
    return segments.last;
  }
  if (uri.fragment.isNotEmpty) {
    return Uri.parse(uri.fragment).queryParameters['screen'];
  }
  return null;
}

/// The lifecycle stage a preview-addressed screen implies, so the shell's
/// Home tab and bottom navigation behave the way that screen's reference
/// shows them.
DriverStage _stageFor(DRoute route) => switch (route) {
  DRoute.noBusinessConnected ||
  DRoute.noBusinessConnectedHome ||
  DRoute.joinBusiness ||
  DRoute.businessJoined => DriverStage.noBusiness,
  DRoute.pendingReview => DriverStage.pendingReview,
  DRoute.approved || DRoute.readyToGo => DriverStage.approved,
  _ => DriverStage.active,
};

class DriverMobileApp extends StatefulWidget {
  const DriverMobileApp({
    super.key,
    required this.repo,
    this.previewId,
    this.live,
  });

  final RiderRepository repo;

  /// Phase 2B.4 live location (real build only).
  final LiveLocationService? live;

  /// Preview-only deep link: a reference caption id such as "D21.2"
  /// (see [previewIdFromUri]).
  final String? previewId;

  @override
  State<DriverMobileApp> createState() => _DriverMobileAppState();
}

class _DriverMobileAppState extends State<DriverMobileApp> {
  late final AppState app = AppState(widget.repo, live: widget.live);
  bool _prototypeAuthenticated = false;

  /// A password-recovery link opened the app (native deep link).
  bool _recovering = false;

  /// A 6-digit code flow is finishing inside the auth screens: keep them
  /// on top even though a session exists (AuthFlow.onCodeHold).
  bool _codeHold = false;

  /// An emailed auth link opened the app but the server refused it
  /// (expired, already used, or opened away from the requesting device).
  bool _linkRejected = false;

  /// Auth routes are owned by [AuthFlow], which runs before the shell.
  static const _authRoutes = {
    DRoute.splash,
    DRoute.signIn,
    DRoute.emailSignIn,
    DRoute.createAccount,
    DRoute.forgotPassword,
    DRoute.checkEmail,
    DRoute.setNewPassword,
    DRoute.passwordUpdated,
    DRoute.verifyEmail,
    DRoute.linkExpired,
  };

  DRoute? get _previewRoute {
    final id = widget.previewId;
    return id == null ? null : routeForReferenceId(id);
  }

  DRoute get _authInitial {
    final preview = _previewRoute;
    return preview != null && _authRoutes.contains(preview)
        ? preview
        : DRoute.splash;
  }

  @override
  void initState() {
    super.initState();
    applyUiLocale(app.uiLocale);
    app.restoreUiLocale();
    if (!app.repo.isDemo) app.restoreJoinToken(Uri.base);
    app.onPrototypeSignOut = () {
      if (mounted) setState(() => _prototypeAuthenticated = false);
    };
    final preview = _previewRoute;
    if (preview != null && !_authRoutes.contains(preview)) {
      app.stage = _stageFor(preview);
      // The Stop List's two phases are the same route: "D21" is the
      // confirmed operational list, "D21.1"/"D21.2" the planning surface.
      final id = widget.previewId!.toUpperCase();
      app.routeConfirmed = preview == DRoute.stopList && id == 'D21';
      app.stopListMapView = id == 'D21.2';
      app.resetTo(
        preview,
        entityId: routeSpecs[preview]!.requiresEntityId
            ? app.currentRun.id
            : null,
      );
      _prototypeAuthenticated = true;
    }
    if (widget.repo.isDemo || widget.repo.currentUser != null) {
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
        // A sign-up confirmation link signs the Driver in outside the auth
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
    if (state.session == null) app.clearSession();
  }

  /// supabase_flutter reports a refused callback link as a stream error.
  void _onAuthLinkError(Object error) {
    if (!mounted || error is! AuthException) return;
    setState(() => _linkRejected = true);
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
        title: L.ceffloDriver,
        // BM + EN (Founder 2026-09-27). Country never selects language.
        locale: app.uiLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        // Locked Light Mode only: D38 shows an Appearance row, but no
        // reference draws a dark screen, so no dark theme is built behind it.
        themeMode: AppState.themeMode,
        theme: buildRiderTheme(),
        // Applied above the Navigator so every route, dialog and bottom
        // sheet lays out against the same normalized canvas.
        builder: (context, child) => LocaleRefresh(
          locale: app.uiLocale,
          child: _EdgeToEdgeInsets(child: ResponsiveDensity(child: child!)),
        ),
        home: Builder(
          builder: (context) {
            if (!_signedIn || _recovering || _codeHold) {
              return AuthFlow(
                key: ValueKey((_recovering, _linkRejected)),
                initial: _recovering
                    ? DRoute.setNewPassword
                    : _linkRejected
                    ? DRoute.linkExpired
                    : _authInitial,
                // A recovery link or a recovery code: either way the new
                // password is followed by signing out, then Sign In.
                onPasswordUpdated: _recovering || _codeHold
                    ? () async {
                        await widget.repo.signOut();
                        if (mounted) {
                          setState(() {
                            _recovering = false;
                            _codeHold = false;
                          });
                        }
                      }
                    : null,
                onCodeHold: (hold) {
                  if (!mounted) return;
                  setState(() => _codeHold = hold);
                  if (!hold &&
                      widget.repo.currentUser != null &&
                      !app.loadingSession &&
                      !app.sessionLoaded) {
                    app.loadSession();
                  }
                },
                onAuthenticated: (landing) {
                  app.stage = landing == null ? app.stage : _stageFor(landing);
                  app.resetTo(landing ?? app.homeRoute);
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

/// Edge-to-edge on the web: the page draws behind the Android gesture bar,
/// so the bottom system inset the engine does not report is added to
/// MediaQuery here, once -- every SafeArea (bottom navigation, sheets) then
/// clears the gesture pill while its own background continues behind it.
/// No-op on native builds.
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
