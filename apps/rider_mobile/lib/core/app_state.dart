import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../data/driver_models.dart';
import '../data/models.dart';
import '../data/rider_repository.dart';
import 'routes.dart';

/// Where the signed-in Driver sits in the account lifecycle the references
/// describe: no business yet (D11/D16/D17), details submitted and awaiting
/// the business's review (D14.1), approved (D14.2), operating (D14.3/D19).
enum DriverStage { noBusiness, pendingReview, approved, active }

/// Navigation + session state.
///
/// The navigation stack is a real history of typed [RiderLocation]s. Back
/// pops that history and falls back to the route's declared parent -- same
/// pattern as Vendor Mobile's AppState. Identifiers stay "Rider" internally
/// per D-38; only rendered copy says "Driver".
class AppState extends ChangeNotifier {
  AppState(this.repo);

  final RiderRepository repo;

  final List<RiderLocation> _stack = [const RiderLocation(DRoute.today)];
  List<RiderLocation> get stack => List.unmodifiable(_stack);
  RiderLocation get current => _stack.last;
  bool get canGoBack => _stack.length > 1 || current.spec.parent != null;
  NavTab get activeTab => current.spec.tab ?? NavTab.home;

  // --- canonical backend session ----------------------------------------
  List<RiderRelationship> relationships = const [];
  RiderRelationship? active;
  List<RiderOrder> orders = const [];
  Map<String, String> sessionNames = const {};

  bool loadingSession = true;
  String? sessionError;

  /// Light Mode only. D38 shows an Appearance row; no dark theme is built
  /// behind it because no reference shows a dark screen.
  static const themeMode = ThemeMode.light;

  // --- driver-facing presentation state ---------------------------------
  DriverStage stage = DriverStage.active;
  DriverProfile profile = DemoData.activeProfile;
  DriverBusiness? business = DemoData.business;
  DriverRun currentRun = DemoData.currentRun;
  List<DriverRun> history = DemoData.history;
  List<DriverNotification> notifications = DemoData.notifications;
  List<DriverDocument> documents = DemoData.documents;
  List<DriverDocument> onboardingDocuments = DemoData.onboardingDocuments;
  String language = 'English';

  /// D21.1/D21.2 let the Driver reorder stops and slide to confirm the
  /// route; once confirmed, D21's filtered Stop List is what the route
  /// shows. Both are the same D21 screen family, distinguished by this flag.
  bool routeConfirmed = false;

  /// Which of the two planning tabs D21.1/D21.2 opens on. Only the preview
  /// deep link sets this; in normal use the Driver just taps the toggle.
  bool stopListMapView = false;

  void confirmRoute() {
    routeConfirmed = true;
    notifyListeners();
  }

  /// The reason picked on D28, carried into D29's summary card.
  IssueReason issueReason = IssueReason.customerNotAvailable;

  void setIssueReason(IssueReason reason) {
    issueReason = reason;
    notifyListeners();
  }

  /// The category picked on the D40-A sheet, which decides whether the flow
  /// lands on D40-B (vendor-owned) or D40-C (Cefflo ticket) and pre-fills
  /// D40-C's Category select.
  SupportCategory supportCategory = SupportCategory.ceffloAppIssue;

  void setSupportCategory(SupportCategory category) {
    supportCategory = category;
    notifyListeners();
  }

  /// The stop currently being navigated to / confirmed (D22, D23, D28, D29).
  String? activeStopId;
  DriverStop get activeStop => currentRun.stops.firstWhere(
    (s) => s.id == activeStopId,
    orElse: () => currentRun.stops.first,
  );

  // --- navigation --------------------------------------------------------

  void go(DRoute route, {String? entityId}) {
    final spec = routeSpecs[route]!;
    assert(
      !spec.requiresEntityId || entityId != null,
      '${spec.id} requires an entity id',
    );
    final next = RiderLocation(route, entityId: entityId);
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
        ..add(RiderLocation(parent ?? homeRoute));
    }
    notifyListeners();
  }

  /// The home tab is state-aware: which screen "Home" means depends on where
  /// the Driver is in the lifecycle, exactly as the references lay it out.
  DRoute get homeRoute => switch (stage) {
    DriverStage.noBusiness => DRoute.noBusinessConnected,
    DriverStage.pendingReview => DRoute.pendingReview,
    // Once approved, Home is D14.3 Ready to Go. D14.2 "You're Approved!" is
    // the one-time arrival screen, not a tab destination.
    DriverStage.approved => DRoute.readyToGo,
    DriverStage.active => DRoute.today,
  };

  void switchTab(NavTab tab) {
    final root = switch (tab) {
      NavTab.home => homeRoute,
      NavTab.runs =>
        stage == DriverStage.active ? DRoute.runDetails : homeRoute,
      NavTab.history => DRoute.deliveryHistory,
      NavTab.profile => DRoute.profile,
    };
    _stack
      ..clear()
      ..add(
        RiderLocation(
          root,
          entityId: root == DRoute.runDetails ? currentRun.id : null,
        ),
      );
    notifyListeners();
  }

  void resetTo(DRoute route, {String? entityId}) {
    _stack
      ..clear()
      ..add(RiderLocation(route, entityId: entityId));
    notifyListeners();
  }

  // --- driver-facing mutations -------------------------------------------

  void setStage(DriverStage next) {
    stage = next;
    notifyListeners();
  }

  void setLanguage(String next) {
    language = next;
    notifyListeners();
  }

  void setActiveStop(String stopId) {
    activeStopId = stopId;
    notifyListeners();
  }

  void reorderStops(int oldIndex, int newIndex) {
    final stops = [...currentRun.stops];
    if (newIndex > oldIndex) newIndex -= 1;
    stops.insert(newIndex, stops.removeAt(oldIndex));
    currentRun = currentRun.copyWith(stops: stops);
    notifyListeners();
  }

  /// D21.1's drag-to-reorder, in `ReorderableListView.onReorderItem` terms:
  /// [newIndex] is already expressed against the list with the dragged stop
  /// removed, so no off-by-one correction is applied.
  void moveStop(int oldIndex, int newIndex) {
    final stops = [...currentRun.stops];
    stops.insert(newIndex, stops.removeAt(oldIndex));
    currentRun = currentRun.copyWith(stops: stops);
    notifyListeners();
  }

  void markStopDelivered(String stopId) {
    currentRun = currentRun.copyWith(
      stops: [
        for (final s in currentRun.stops)
          if (s.id == stopId)
            s.copyWith(status: StopStatus.delivered, deliveredAt: 'Just now')
          else
            s,
      ],
    );
    notifyListeners();
  }

  void markStopIssue(String stopId) {
    currentRun = currentRun.copyWith(
      stops: [
        for (final s in currentRun.stops)
          if (s.id == stopId) s.copyWith(status: StopStatus.issue) else s,
      ],
    );
    notifyListeners();
  }

  void updateProfile(DriverProfile next) {
    profile = next;
    notifyListeners();
  }

  /// D33 — tapping a notification clears its unread dot. Prototype-local:
  /// nothing is persisted, there is no read receipt on the backend yet.
  void markNotificationRead(DriverNotification target) {
    notifications = [
      for (final n in notifications)
        if (identical(n, target)) n.copyWith(unread: false) else n,
    ];
    notifyListeners();
  }

  /// D37 — a document re-submitted for review drops back to "uploaded"
  /// until the business verifies it again.
  void setDocumentState(String id, DocumentState state) {
    documents = [
      for (final d in documents)
        if (d.id == id) d.copyWith(state: state) else d,
    ];
    notifyListeners();
  }

  // --- canonical backend hydration ---------------------------------------

  Future<void> loadSession() async {
    if (repo.isDemo) {
      loadingSession = false;
      notifyListeners();
      return;
    }
    loadingSession = true;
    sessionError = null;
    notifyListeners();
    try {
      relationships = await repo.myRiderRelationships();
      final activeOnes = relationships.where((r) => r.isActive).toList();
      active = activeOnes.isEmpty ? null : activeOnes.first;
      stage = active != null
          ? DriverStage.active
          : relationships.any((r) => r.isPending)
          ? DriverStage.pendingReview
          : DriverStage.noBusiness;
      // Land on the screen the hydrated relationship stage owns; the default
      // stack root (Today) is only correct for an active relationship.
      _stack
        ..clear()
        ..add(RiderLocation(homeRoute));
      if (active != null) await _loadOrders();
    } on RepositoryError catch (e) {
      sessionError = e.message;
    } finally {
      loadingSession = false;
      notifyListeners();
    }
  }

  Future<void> _loadOrders() async {
    final rider = active;
    if (rider == null) {
      orders = const [];
      return;
    }
    orders = await repo.myOrders(rider.id);
    try {
      final rows = await repo.sessions(rider.businessId);
      sessionNames = {for (final s in rows) s.id: s.name};
    } on RepositoryError {
      // Never block hydration on this -- a missing Wave name falls back to
      // a factual order-count label, same as the live Rider PWA.
      sessionNames = const {};
    }
  }

  Future<void> refreshOrders() async {
    await _loadOrders();
    notifyListeners();
  }

  /// Groups this Rider's orders by delivery_session_id -- presentation
  /// grouping only, never invented membership.
  List<RiderRun> get runs {
    final byKey = <String?, List<RiderOrder>>{};
    for (final o in orders) {
      byKey.putIfAbsent(o.deliverySessionId, () => []).add(o);
    }
    return byKey.entries
        .map(
          (e) => RiderRun(
            sessionId: e.key,
            waveName: e.key != null ? sessionNames[e.key] : null,
            orders: e.value,
          ),
        )
        .toList();
  }

  void selectRelationship(RiderRelationship r) {
    active = r;
    notifyListeners();
    _loadOrders().then((_) => notifyListeners());
  }

  /// Set by `main.dart` in prototype boot mode so D34/D38's Log Out can hand
  /// control back to the pre-auth [AuthFlow] without the shell knowing how
  /// the root widget is composed.
  VoidCallback? onPrototypeSignOut;

  void signOutPrototype() {
    stage = DriverStage.active;
    routeConfirmed = false;
    currentRun = DemoData.currentRun;
    clearSession();
    onPrototypeSignOut?.call();
  }

  Future<void> signOut() async {
    if (!repo.isDemo) {
      await repo.signOut();
    }
    clearSession();
  }

  void clearSession() {
    relationships = const [];
    active = null;
    orders = const [];
    _stack
      ..clear()
      ..add(const RiderLocation(DRoute.today));
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
