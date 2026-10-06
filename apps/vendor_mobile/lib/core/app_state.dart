import 'dart:async';

import 'appearance.dart';
import 'auth_access.dart';
import 'browser_history.dart';
import 'join_link.dart';
import 'notification_alerts.dart';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/plans.dart';
import '../data/storefront_config.dart';
import '../data/vendor_repository.dart';
import 'routes.dart';
import 'ui_locale.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// Navigation + session state.
///
/// The navigation stack is a real history of typed [VendorLocation]s. Back
/// pops that history and falls back to the route's declared parent, never to
/// Today (audit fix 1).
class AppState extends ChangeNotifier {
  AppState(this.repo);

  final VendorRepository repo;

  final List<VendorLocation> _stack = [const VendorLocation(VRoute.today)];
  List<VendorLocation> get stack => List.unmodifiable(_stack);
  VendorLocation get current => _stack.last;
  bool get canGoBack => _stack.length > 1 || current.spec.parent != null;
  NavTab get activeTab => current.spec.tab ?? NavTab.today;

  List<Business> businesses = const [];
  Business? business;

  /// UI language (en / ms). Independent of country/market (Founder,
  /// 2026-09-27). Starts from the device language; an explicit choice
  /// persists on this device and follows the signed-in user.
  Locale uiLocale = resolveDeviceLocale();
  final UiLocaleStore _localeStore = UiLocaleStore();

  /// Sign-In variant hint (D-74). Presentation only; never a role.
  AuthAccess access = AuthAccess.vendor;

  bool loadingSession = true;

  /// True once [loadSession] has hydrated this signed-in account; reset by
  /// [clearSession]. Lets the app root load a session that began outside
  /// the auth screens (an emailed confirmation link) exactly once.
  bool sessionLoaded = false;
  String? sessionError;

  // ---- Storefront (V-31/X-02/V-33). Template and customization persist on
  // the server (public_order_pages, Storefront V1); these fields mirror the
  // loaded state. Products and business data are never stored here.
  String activeStorefrontTemplateId = 'arena';

  /// Saved customization per template id, so returning to a template keeps
  /// the vendor's last saved look.
  final Map<String, StorefrontBranding> _storefrontBranding = {};

  /// The vendor's saved customization for [templateId], if any.
  StorefrontBranding? savedStorefrontBranding(String templateId) =>
      _storefrontBranding[templateId];

  /// The business's real storefront (slug, published) once loaded. The UI
  /// prototype receives a representative storefront so the approved public
  /// link, copy, QR and share controls remain reviewable without a backend.
  ({String slug, bool published})? storefront;

  /// Loads the storefront and its saved appearance from the server
  /// (get_storefront creates it, unpublished, on first open).
  /// [defaultsFor] gives a template's default branding (the template
  /// registry lives in the UI layer).
  Future<void> loadStorefront(
    StorefrontBranding Function(String templateId) defaultsFor,
  ) async {
    final b = business;
    if (b == null) return;
    if (repo.isDemo) {
      storefront = (slug: 'kak-lina-kitchen', published: true);
      notifyListeners();
      return;
    }
    final m = await repo.getStorefront(b.id);
    storefront = (slug: m['slug'] as String, published: m['published'] == true);
    final key = (m['template_key'] as String?) ?? activeStorefrontTemplateId;
    final theme = Map<String, dynamic>.from((m['theme'] as Map?) ?? const {});
    activeStorefrontTemplateId = key;
    if (theme.isNotEmpty) {
      final defaults = defaultsFor(key);
      Color? hex(String k) =>
          theme[k] is String ? parseStorefrontHex(theme[k] as String) : null;
      _storefrontBranding[key] = defaults.copyWith(
        primary: hex('accent'),
        secondary: hex('secondary'),
        mode: theme['style'] == 'gradient'
            ? BrandColorMode.gradient
            : theme['style'] == 'plain'
            ? BrandColorMode.solid
            : null,
        font: StorefrontFontTreatment.values
            .where((f) => f.name == theme['font'])
            .firstOrNull,
        backgroundId: theme['background'] as String?,
        customBackground: hex('background_color'),
        tagline: theme['tagline'] as String?,
        heroPath: theme['hero_path'] as String?,
      );
    }
    notifyListeners();
  }

  Future<void> setStorefrontPublished(bool published) async {
    final b = business, s = storefront;
    if (b == null || s == null) return;
    if (!repo.isDemo) await repo.setStorefrontPublished(b.id, published);
    storefront = (slug: s.slug, published: published);
    notifyListeners();
  }

  /// Save / Apply from Customize: makes [templateId] the live storefront
  /// with [branding], saved on the server first (live), so it persists.
  Future<void> applyStorefront(
    String templateId,
    StorefrontBranding branding,
  ) async {
    final b = business;
    if (!repo.isDemo && b != null) {
      // Upload a newly picked hero FIRST; hero_path changes only after the
      // upload succeeded, so the storefront never points at a missing file.
      if (branding.hasUnsavedHero) {
        final path = await repo.uploadStorefrontHero(
          b.id,
          branding.heroImage!,
          branding.heroContentType!,
        );
        branding = StorefrontBranding(
          primary: branding.primary,
          secondary: branding.secondary,
          mode: branding.mode,
          storeName: branding.storeName,
          tagline: branding.tagline,
          logoText: branding.logoText,
          hasLogo: branding.hasLogo,
          font: branding.font,
          backgroundId: branding.backgroundId,
          customBackground: branding.customBackground,
          heroImage: branding.heroImage,
          heroPath: path,
        );
      }
      await repo.saveStorefrontAppearance(b.id, templateId, {
        'accent': branding.primary.hex,
        if (branding.secondary != null) 'secondary': branding.secondary!.hex,
        'style': branding.isGradient ? 'gradient' : 'plain',
        'font': branding.font.name,
        'background': branding.backgroundId,
        if (branding.customBackground != null)
          'background_color': branding.customBackground!.hex,
        if (branding.tagline.isNotEmpty) 'tagline': branding.tagline,
        if (branding.heroPath != null) 'hero_path': branding.heroPath!,
      });
    }
    activeStorefrontTemplateId = templateId;
    _storefrontBranding[templateId] = branding;
    notifyListeners();
  }

  /// The signed-in person's name for the Today greeting, from profile
  /// metadata only. Without a name the greeting shows no name line; the
  /// account email is never displayed as a name. The demo session is the
  /// demo owner.
  String get userDisplayName {
    if (repo.isDemo) return 'Yusuf Sazali';
    final meta = repo.currentUser?.userMetadata ?? const {};
    return (meta['full_name'] ?? meta['name'] ?? '').toString().trim();
  }

  // ---- Subscription (V-50..V-54). No billing backend exists yet: the demo
  // session holds the current plan, cycle and invoices, and a payment only
  // succeeds in the demo (see [subscribe]).
  String currentPlanId = 'operate';
  BillingCycle currentCycle = BillingCycle.monthly;
  DateTime nextRenewal = DateTime(2026, 10, 24);

  SubscriptionPlan get currentPlan => planById(currentPlanId);

  late final List<Invoice> invoices = repo.isDemo
      ? [
          for (var m = 9; m >= 3; m--)
            Invoice(
              date: DateTime(2026, m, 24),
              amount: 199,
              planName: 'Operate',
              cycle: BillingCycle.monthly,
            ),
        ]
      : [];

  /// Subscribes to [plan]. Demo only: with a live backend there is no
  /// payment contract yet, so it fails and nothing is charged.
  Future<void> subscribe(SubscriptionPlan plan, BillingCycle cycle) async {
    if (!repo.isDemo) {
      throw StateError(L.paymentsNotAvailableYet);
    }
    currentPlanId = plan.id;
    currentCycle = cycle;
    nextRenewal = DateTime.now().add(
      cycle == BillingCycle.yearly
          ? const Duration(days: 365)
          : const Duration(days: 30),
    );
    notifyListeners();
  }

  // ---- Vendor availability (Today header toggle). Session state only: no
  // availability contract exists on the backend yet.
  // Starts Offline (Founder, 2026-10-01): the vendor goes Online on purpose.
  bool vendorOnline = false;

  void setVendorOnline(bool value) {
    vendorOnline = value;
    notifyListeners();
  }

  // ---- Appearance: device-local only (never synced, no DB column).
  // [appearance] is what is saved on this device; a preview paints the
  // whole app through [liveAppearance] until it is saved or rolled back.
  Appearance appearance = Appearance.standard;
  final AppearanceStore _appearanceStore = AppearanceStore();

  Future<void> restoreAppearance() async {
    appearance = await _appearanceStore.read();
    liveAppearance.value = appearance;
    notifyListeners();
  }

  void previewAppearance(Appearance next) => liveAppearance.value = next;

  /// Reflects a saved business name without reloading the session.
  void renameBusiness(String name) {
    final b = business;
    if (b == null) return;
    business = Business(
      id: b.id,
      name: name,
      role: b.role,
      timezone: b.timezone,
      currency: b.currency,
    );
    businesses = [for (final x in businesses) x.id == b.id ? business! : x];
    notifyListeners();
  }

  // ---- Permanent invite link join (Operator / Helper). Kept on the device
  // until the request is submitted; grants nothing by itself.
  String? joinToken;
  final JoinLinkStore _joinStore = JoinLinkStore();

  Future<void> restoreJoinToken(Uri launch) async {
    joinToken = await _joinStore.read(launch);
    notifyListeners();
  }

  /// Business a join request was already sent to (null if none yet).
  Future<String?> joinSentBusiness() => _joinStore.sentBusiness();
  Future<void> markJoinSent(String businessId) =>
      _joinStore.markSent(businessId);

  /// The request was sent (pending) or the account is already a member.
  Future<void> finishJoin() async {
    joinToken = null;
    await _joinStore.clear();
    notifyListeners();
  }

  /// Back / cancel: the saved appearance returns.
  void discardAppearancePreview() => liveAppearance.value = appearance;

  Future<void> saveAppearance(Appearance next) async {
    appearance = next;
    liveAppearance.value = next;
    await _appearanceStore.write(next);
    notifyListeners();
  }

  // ---- Notification centre (X-01), backed by public.notifications
  // (docs/cefflo/NOTIFICATION_EVENT_MATRIX.md). The server writes every row;
  // this keeps the list, read state and preferences in step with it and
  // raises the foreground alert for rows that arrive while the app is open.
  // The demo session keeps its designed feed and never touches a backend.
  late List<AppNotification> _notifications = repo.isDemo
      ? List.of(_demoNotifications)
      : [];
  int _unreadLive = 0;
  NotificationPrefs notificationPrefs = const NotificationPrefs();
  String? notificationsError;
  VoidCallback? _cancelNotifications;
  bool _subscribedOnce = false;
  final Set<String> _seenNotifications = {};
  final Map<String, Timer> _pendingDeletes = {};

  /// The foreground alert currently shown over the app (banner), if any.
  final ValueNotifier<AppNotification?> foregroundAlert = ValueNotifier(null);

  /// Sound/vibration side effects of an alert (replaceable in tests).
  NotificationAlertEffects alertEffects = const NotificationAlertEffects();

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadNotifications =>
      repo.isDemo ? _notifications.where((n) => !n.read).length : _unreadLive;

  /// Loads the centre, preferences and starts the realtime feed (live only).
  Future<void> startNotifications() async {
    if (repo.isDemo) return;
    stopNotifications();
    await refreshNotifications();
    try {
      notificationPrefs = await repo.notificationPrefs();
    } on RepositoryError catch (_) {}
    _cancelNotifications = repo.watchNotifications(
      onChange: _onNotificationChange,
      onStatus: (subscribed) {
        if (!subscribed) return;
        // Rejoined after a drop: re-read history; alerts are never replayed.
        if (_subscribedOnce) refreshNotifications();
        _subscribedOnce = true;
      },
    );
    notifyListeners();
  }

  void stopNotifications() {
    _cancelNotifications?.call();
    _cancelNotifications = null;
    _subscribedOnce = false;
    for (final t in _pendingDeletes.values) {
      t.cancel();
    }
    _pendingDeletes.clear();
    if (!repo.isDemo) {
      _notifications = [];
      _unreadLive = 0;
      _seenNotifications.clear();
    }
    foregroundAlert.value = null;
  }

  /// App returned to the foreground (NotificationBanner observes the
  /// lifecycle): re-read the centre in case the socket slept.
  void onAppResumed() {
    if (_cancelNotifications != null) refreshNotifications();
    if (!repo.isDemo) liveTick.value++;
  }

  /// Bumped when operational truth may have changed (foreground resume, an
  /// operational notification); live lists reload silently. No polling.
  final ValueNotifier<int> liveTick = ValueNotifier(0);

  static const _liveEventPrefixes = ['order.', 'run.', 'delivery.', 'rider.', 'team.'];

  Future<void> refreshNotifications() async {
    if (repo.isDemo) return;
    try {
      final rows = await repo.notifications();
      _unreadLive = await repo.unreadNotificationCount();
      _notifications = rows
          .where((n) => !_pendingDeletes.containsKey(n.id))
          .toList();
      _seenNotifications.addAll(rows.map((n) => n.id));
      notificationsError = null;
    } on RepositoryError catch (e) {
      notificationsError = e.message;
    }
    notifyListeners();
  }

  void _onNotificationChange(String type, Map<String, dynamic> row) {
    final id = row['id']?.toString();
    if (id == null) return;
    if (type == 'INSERT') {
      if (row['app'] != 'vendor') return;
      if (_notifications.any((n) => n.id == id)) return;
      final n = AppNotification.fromRow(row);
      _notifications = [n, ..._notifications].take(50).toList();
      if (!n.read) _unreadLive++;
      notifyListeners();
      if (_seenNotifications.add(id)) _present(n);
      final key = n.eventKey ?? '';
      if (_liveEventPrefixes.any(key.startsWith)) liveTick.value++;
    } else if (type == 'UPDATE') {
      final i = _notifications.indexWhere((n) => n.id == id);
      if (i < 0) return;
      final was = _notifications[i].read;
      final now = row['read_at'] != null;
      _notifications = List.of(_notifications)
        ..[i] = _notifications[i].copyWith(read: now);
      if (!was && now) _unreadLive = (_unreadLive - 1).clamp(0, 1 << 30);
      if (was && !now) _unreadLive++;
      notifyListeners();
    } else if (type == 'DELETE') {
      final gone = _notifications.where((n) => n.id == id).toList();
      if (gone.isEmpty) return;
      _notifications = _notifications.where((n) => n.id != id).toList();
      if (!gone.first.read) _unreadLive = (_unreadLive - 1).clamp(0, 1 << 30);
      notifyListeners();
    }
  }

  /// Foreground alert: banner + sound/vibration per preferences. Rows older
  /// than two minutes (e.g. delivered late after a reconnect) only land in
  /// the centre.
  void _present(AppNotification n) {
    if (!notificationPrefs.enabled) return;
    final at = n.createdAt;
    if (at != null && DateTime.now().difference(at).inMinutes >= 2) return;
    foregroundAlert.value = n;
    alertEffects.play(
      sound: notificationPrefs.sound && notificationPlaysSound(n.eventKey),
      urgent: n.urgent,
    );
  }

  void dismissForegroundAlert() => foregroundAlert.value = null;

  Future<void> setNotificationRead(String id, {required bool read}) async {
    final before = _notifications;
    final target = before.where((n) => n.id == id).firstOrNull;
    if (target == null || target.read == read) return;
    _notifications = [
      for (final n in _notifications) n.id == id ? n.copyWith(read: read) : n,
    ];
    if (!repo.isDemo) _unreadLive += read ? -1 : 1;
    notifyListeners();
    if (repo.isDemo) return;
    try {
      if (read) {
        await repo.markNotificationsRead(ids: [id]);
      } else {
        await repo.markNotificationUnread(id);
      }
    } on RepositoryError {
      await refreshNotifications();
      rethrow;
    }
  }

  Future<void> markAllNotificationsRead() async {
    _notifications = [for (final n in _notifications) n.copyWith(read: true)];
    if (!repo.isDemo) _unreadLive = 0;
    notifyListeners();
    if (repo.isDemo) return;
    try {
      await repo.markNotificationsRead();
    } on RepositoryError {
      await refreshNotifications();
      rethrow;
    }
  }

  /// Removes [id] and returns what is needed to undo it. Live, the server
  /// delete runs once the undo window has passed.
  (int, AppNotification)? deleteNotification(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index < 0) return null;
    final removed = _notifications[index];
    _notifications = List.of(_notifications)..removeAt(index);
    if (!repo.isDemo) {
      if (!removed.read) _unreadLive = (_unreadLive - 1).clamp(0, 1 << 30);
      _pendingDeletes[id] = Timer(const Duration(seconds: 5), () {
        _pendingDeletes.remove(id);
        repo.deleteNotification(id).catchError((_) => refreshNotifications());
      });
    }
    notifyListeners();
    return (index, removed);
  }

  void restoreNotification((int, AppNotification) entry) {
    final (index, notification) = entry;
    _pendingDeletes.remove(notification.id)?.cancel();
    if (!repo.isDemo && !notification.read) _unreadLive++;
    _notifications = List.of(_notifications)
      ..insert(index.clamp(0, _notifications.length), notification);
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    _notifications = [];
    if (!repo.isDemo) _unreadLive = 0;
    notifyListeners();
    if (repo.isDemo) return;
    try {
      await repo.clearNotifications();
    } on RepositoryError {
      await refreshNotifications();
      rethrow;
    }
  }

  Future<void> setNotificationPrefs(NotificationPrefs next) async {
    if (!repo.isDemo) await repo.saveNotificationPrefs(next);
    notificationPrefs = next;
    notifyListeners();
  }

  /// Opens a notification: marks it read and follows its deep-link. A row
  /// from another of the user's businesses switches to that business first.
  void openNotification(AppNotification n) {
    if (!n.read) setNotificationRead(n.id, read: true).catchError((_) {});
    final other = businesses.where(
      (b) => b.id == n.businessId && b.id != business?.id,
    );
    if (other.isNotEmpty) business = other.first;
    switch (n.targetScreen) {
      case 'order' when n.targetId != null:
        go(VRoute.orderDetail, entityId: n.targetId);
      case 'rider' when n.targetId != null:
        go(VRoute.riderDetail, entityId: n.targetId);
      case 'riders' || 'rider':
        go(VRoute.riders);
      case 'runs':
        go(VRoute.zones);
      default:
        notifyListeners();
    }
  }

  void go(VRoute route, {String? entityId}) {
    final spec = routeSpecs[route]!;
    assert(
      !spec.requiresEntityId || entityId != null,
      '${spec.id} requires an entity id',
    );
    final next = VendorLocation(route, entityId: entityId);
    if (next == current) return;
    _stack.add(next);
    // One browser history entry per in-app step, so the browser / Android
    // edge-swipe Back returns here instead of leaving the app.
    if (hasBrowserHistory) {
      pushBrowserHistoryEntry();
      _historyDepth++;
    }
    notifyListeners();
  }

  /// Set by the auth screens while they are shown: handles the browser's
  /// Back inside the auth stack; returns false when there is nothing to pop.
  bool Function()? authBrowserBack;

  /// Browser entries pushed by [go] that have not been popped yet.
  int _historyDepth = 0;

  /// The browser's Back (swipe or button): pops the app's stack. Called
  /// from the popstate listener set up at startup.
  void onBrowserBack() {
    // The sign-in / sign-up screens keep their own stack: they go first.
    if (authBrowserBack?.call() ?? false) return;
    if (_historyDepth > 0) _historyDepth--;
    if (canGoBack) _back();
  }

  /// Server data changed outside a screen's own load (e.g. a pop-up created
  /// a record): listening screens rebuild and reload what they show.
  void dataChanged() => notifyListeners();

  void back() {
    // In the browser, in-app Back goes through the browser's history so
    // both stay in step (popstate then calls onBrowserBack once).
    if (hasBrowserHistory && _historyDepth > 0) {
      browserHistoryBack();
      return;
    }
    _back();
  }

  void _back() {
    if (_stack.length > 1) {
      _stack.removeLast();
    } else {
      final parent = current.spec.parent;
      _stack
        ..clear()
        ..add(VendorLocation(parent ?? VRoute.today));
    }
    notifyListeners();
  }

  /// Pops back to the nearest [route] in the history (e.g. Subscription
  /// after a completed payment); resets to it if it is not in the stack.
  void backTo(VRoute route) {
    final i = _stack.lastIndexWhere((l) => l.route == route);
    if (i < 0) {
      resetTo(route);
      return;
    }
    _stack.removeRange(i + 1, _stack.length);
    notifyListeners();
  }

  void switchTab(NavTab tab) {
    final root = switch (tab) {
      NavTab.today => VRoute.today,
      NavTab.orders => VRoute.orders,
      NavTab.zones => VRoute.zones,
      NavTab.riders => VRoute.riders,
      NavTab.more => VRoute.settings,
    };
    _stack
      ..clear()
      ..add(VendorLocation(root));
    notifyListeners();
  }

  void resetTo(VRoute route) {
    _stack
      ..clear()
      ..add(VendorLocation(route));
    notifyListeners();
  }

  /// Applies a stored explicit choice (device), if any. Called at startup.
  Future<void> restoreUiLocale() async {
    final stored = await _localeStore.read();
    if (stored != null) _applyUiLocale(stored);
  }

  /// Explicit user choice: applied now, persisted on this device and saved
  /// to the user's profile when signed in. Operational state is untouched.
  Future<void> setUiLocale(Locale next) async {
    _applyUiLocale(next);
    await _localeStore.write(next);
    if (!repo.isDemo && repo.currentUser != null) {
      await repo.saveUiLocale(next.languageCode);
    }
  }

  void _applyUiLocale(Locale next) {
    uiLocale = next;
    applyUiLocale(next);
    notifyListeners();
  }

  Future<void> loadSession() async {
    loadingSession = true;
    sessionError = null;
    notifyListeners();
    try {
      // The signed-in user's own language follows them across devices.
      final own = parseUiLocale(repo.currentUser?.userMetadata?['ui_locale']);
      if (own != null && own != uiLocale) {
        _applyUiLocale(own);
        await _localeStore.write(own);
      }
      // Memberships come only from the permanent invite link flow: join
      // request → Pending → Owner approval (no email-invitation claim).
      // Phase 0 role isolation: an entry only ever opens a business where
      // the account holds that entry's role (an Owner of A who is Operator
      // of B, opening Operator Access, lands on B and never sees A).
      businesses = businessesForAccess(await repo.myBusinesses(), access);
      business = businesses.isEmpty ? null : businesses.first;
      // Signed in through the Operator Sign-In but no membership was
      // claimed: say so. Business setup would make this account an Owner.
      if (business == null && access != AuthAccess.vendor) {
        // A sent join request waiting for the Owner reads as pending, not
        // as "no access".
        final pending = await repo.myPendingJoinRole(
          prefer: access == AuthAccess.helper ? 'helper' : 'operator',
        );
        sessionError = switch ((access, pending)) {
          (AuthAccess.helper, 'helper') => L.helperRequestPending,
          (AuthAccess.helper, _) => L.noHelperAccessYet,
          (_, 'operator') => L.operatorRequestPending,
          _ => L.noOperatorAccessYet,
        };
        return;
      }
      // A signed-in account without a business starts in business setup.
      if (!repo.isDemo && business == null) {
        _stack
          ..clear()
          ..add(const VendorLocation(VRoute.welcomeSetup));
      }
      if (!repo.isDemo && business != null) {
        startNotifications();
      }
      sessionLoaded = true;
    } on RepositoryError catch (e) {
      sessionError = e.message;
    } finally {
      loadingSession = false;
      notifyListeners();
    }
  }

  /// Business setup answers carried from step 1 to the step that creates
  /// the business. Session-only; never persisted on the device.
  ({String name, String phone})? setupDraft;

  void selectBusiness(Business b) {
    business = b;
    notifyListeners();
  }

  /// Set by the app root so [clearSession] can reset the "is a prototype
  /// session authenticated" flag it owns. That flag lives outside AppState
  /// (it gates which widget MaterialApp.home builds, before AppScope even
  /// exists), so without this hook Sign Out clears business data but never
  /// reaches the flag that actually decides whether AuthFlow or the app
  /// shell is shown -- the user stays "signed in" on screen.
  VoidCallback? onSignOut;

  void clearSession() {
    sessionLoaded = false;
    stopNotifications();
    sessionError = null;
    businesses = const [];
    business = null;
    _stack
      ..clear()
      ..add(const VendorLocation(VRoute.today));
    onSignOut?.call();
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget
              as AppScope)
          .notifier!;

  /// [read] that tolerates a tree without an AppScope (isolated widgets).
  static AppState? maybeRead(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()?.widget
              as AppScope?)
          ?.notifier;
}

const _demoNotifications = [
  AppNotification(
    id: 'n-attention',
    kind: NotificationKind.attention,
    title: '3 orders need your action',
    body: 'Review issues before they delay a run.',
    timeLabel: '2 min ago',
  ),
  AppNotification(
    id: 'n-ready',
    kind: NotificationKind.order,
    title: '#CF-1008 is ready for pickup',
    body: 'Brew & Bites · 9 items',
    timeLabel: '18 min ago',
  ),
  AppNotification(
    id: 'n-rider',
    kind: NotificationKind.rider,
    title: 'Ahmad Razi is online',
    body: 'Available for the next Bangsar run.',
    timeLabel: '1 h ago',
    read: true,
  ),
  AppNotification(
    id: 'n-system',
    kind: NotificationKind.system,
    title: 'System update',
    body: 'Everything is operating normally.',
    timeLabel: 'Yesterday',
    read: true,
  ),
];

/// The memberships an entry may open (Phase 0, Founder 2026-10-05). The
/// role still comes from the server; this only stops Operator / Helper
/// Access from landing in a business where the account has another role
/// (e.g. its own Owner business). The Vendor entry keeps every membership.
List<Business> businessesForAccess(List<Business> all, AuthAccess access) =>
    switch (access) {
      AuthAccess.operator => [
        for (final b in all)
          if (b.role == 'operator') b,
      ],
      AuthAccess.helper => [
        for (final b in all)
          if (b.isHelper) b,
      ],
      AuthAccess.vendor => all,
    };
