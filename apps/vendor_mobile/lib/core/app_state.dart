import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/storefront_config.dart';
import '../data/storefront_templates.dart';
import '../data/vendor_repository.dart';
import 'routes.dart';

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
  String locale = 'en';

  bool loadingSession = true;
  String? sessionError;

  // ---- Storefront presentation config (V-31/X-02/V-33). Deliberately
  // separate from product/catalogue and order data: this only ever
  // describes which library template is active (activeStorefrontTemplateId)
  // and per-template brand identity (_brandingOverrides). No backend yet, so
  // it's in-memory session state -- a Storefront configuration adapter
  // boundary, not a parallel production API.
  String activeStorefrontTemplateId = kDefaultStorefrontTemplateId;

  StorefrontTemplateDef get activeStorefrontTemplate =>
      storefrontTemplateById(activeStorefrontTemplateId);

  /// Per-template branding overrides. Keyed by library entry id so a
  /// vendor's edits to e.g. "Luma" survive switching to another template
  /// and back, without ever bleeding into a different template's identity.
  final Map<String, StorefrontBranding> _brandingOverrides = {};

  StorefrontBranding brandingFor(String templateId) =>
      _brandingOverrides[templateId] ??
      storefrontTemplateById(templateId).defaultBranding;

  StorefrontBranding get storefrontBranding =>
      brandingFor(activeStorefrontTemplateId);

  /// "Use This Template" -- makes [templateId] the active storefront.
  /// Never touches product/catalogue data.
  void useStorefrontTemplate(String templateId) {
    activeStorefrontTemplateId = templateId;
    notifyListeners();
  }

  void saveStorefrontBranding(String templateId, StorefrontBranding branding) {
    _brandingOverrides[templateId] = branding;
    notifyListeners();
  }

  void resetStorefrontBranding(String templateId) {
    _brandingOverrides.remove(templateId);
    notifyListeners();
  }

  /// The signed-in person's name for the Today greeting: profile metadata,
  /// else the email's local part. The demo session is the demo owner.
  String get userDisplayName {
    if (repo.isDemo) return 'Yusuf Sazali';
    final user = repo.currentUser;
    final meta = user?.userMetadata ?? const {};
    final name = (meta['full_name'] ?? meta['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    return user?.email?.split('@').first ?? '';
  }

  // ---- Notification centre (X-01). No notification backend exists yet, so
  // this is session state seeded with the demo feed; every management action
  // (read, unread, delete, clear) is real within the session.
  late List<AppNotification> _notifications = repo.isDemo
      ? List.of(_demoNotifications)
      : [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadNotifications => _notifications.where((n) => !n.read).length;

  void setNotificationRead(String id, {required bool read}) {
    _notifications = [
      for (final n in _notifications) n.id == id ? n.copyWith(read: read) : n,
    ];
    notifyListeners();
  }

  void markAllNotificationsRead() {
    _notifications = [for (final n in _notifications) n.copyWith(read: true)];
    notifyListeners();
  }

  /// Removes [id] and returns what is needed to undo it.
  (int, AppNotification)? deleteNotification(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index < 0) return null;
    final removed = _notifications[index];
    _notifications = List.of(_notifications)..removeAt(index);
    notifyListeners();
    return (index, removed);
  }

  void restoreNotification((int, AppNotification) entry) {
    final (index, notification) = entry;
    _notifications = List.of(_notifications)
      ..insert(index.clamp(0, _notifications.length), notification);
    notifyListeners();
  }

  void clearNotifications() {
    _notifications = [];
    notifyListeners();
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
    notifyListeners();
  }

  void back() {
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

  void setLocale(String value) {
    locale = value;
    notifyListeners();
  }

  Future<void> loadSession() async {
    loadingSession = true;
    sessionError = null;
    notifyListeners();
    try {
      businesses = await repo.myBusinesses();
      business = businesses.isEmpty ? null : businesses.first;
    } on RepositoryError catch (e) {
      sessionError = e.message;
    } finally {
      loadingSession = false;
      notifyListeners();
    }
  }

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
    title: 'ORD-1008 is ready for pickup',
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
