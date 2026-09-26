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

/// Where the current run is in the canonical execution lifecycle, derived
/// only from persisted assignment and order states (real build).
enum RunPhase { accept, pickup, route, delivering, done }

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
      _project();
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

  // --- real build: canonical rows projected onto the Driver UI ------------

  /// Null when the real build has no run to show.
  RunPhase? runPhase;
  bool get hasRun => repo.isDemo || runPhase != null;

  String get todayDateLabel =>
      repo.isDemo ? DemoData.todayDateLabel : _dateLabel(DateTime.now());
  int get todayAssigned => repo.isDemo
      ? DemoData.todayAssigned
      : orders
            .where(
              (o) =>
                  o.status == DeliveryStatus.created ||
                  o.status == DeliveryStatus.readyForPickup,
            )
            .length;
  int get todayOngoing => repo.isDemo
      ? DemoData.todayOngoing
      : orders
            .where(
              (o) =>
                  o.status == DeliveryStatus.pickedUp ||
                  o.status == DeliveryStatus.outForDelivery ||
                  o.status == DeliveryStatus.arrived,
            )
            .length;
  int get todayIssues => repo.isDemo
      ? DemoData.todayIssues
      : orders.where((o) => o.status == DeliveryStatus.issue).length;
  int get todayCompleted => repo.isDemo
      ? DemoData.todayCompleted
      : orders.where((o) => o.status == DeliveryStatus.delivered).length;

  static bool _terminal(DeliveryStatus s) =>
      s == DeliveryStatus.delivered ||
      s == DeliveryStatus.issue ||
      s == DeliveryStatus.cancelled;

  void _project() {
    final rel = active ?? (relationships.isEmpty ? null : relationships.first);
    if (rel != null) {
      business = DriverBusiness(
        name: rel.businessName ?? 'Business',
        category: '',
        location: rel.businessAddress ?? '',
      );
      profile = DriverProfile(
        fullName: rel.name,
        phone: rel.phone ?? '',
        email: repo.currentUser?.email ?? '',
        dateOfBirth: '',
        address: '',
        vehicleType: rel.vehicleType ?? '',
        vehicleModel: '',
        plateNumber: rel.plate ?? '',
        statusLabel: rel.isActive ? 'Active Driver' : 'Pending review',
      );
    }
    // No notification feed or document store exists on the backend yet:
    // show none rather than demo entries.
    notifications = const [];
    documents = const [];
    final all = runs;
    bool open(RiderRun r) => r.orders.any((o) => !_terminal(o.status));
    RiderRun? current;
    for (final r in all) {
      if (open(r)) {
        current = r;
        break;
      }
    }
    current ??= all.isEmpty ? null : all.last;
    history = [
      for (final r in all)
        if (!open(r)) _toDriverRun(r),
    ];
    if (current == null) {
      runPhase = null;
      routeConfirmed = false;
      currentRun = DriverRun(
        id: 'none',
        reference: '',
        dateLabel: todayDateLabel,
        zone: '',
        pickupBusinessName: business?.name ?? '',
        pickupAddress: business?.location ?? '',
        distanceKm: null,
        state: RunState.assigned,
        stops: const [],
      );
      return;
    }
    currentRun = _toDriverRun(current);
    runPhase = _phaseOf(current);
    routeConfirmed =
        runPhase == RunPhase.delivering || runPhase == RunPhase.done;
  }

  RunPhase _phaseOf(RiderRun r) {
    if (r.orders.any((o) => o.assignmentStatus == 'assigned')) {
      return RunPhase.accept;
    }
    if (r.orders.any(
      (o) =>
          o.status == DeliveryStatus.created ||
          o.status == DeliveryStatus.readyForPickup,
    )) {
      return RunPhase.pickup;
    }
    final live = r.orders.where((o) => !_terminal(o.status));
    if (live.isEmpty) return RunPhase.done;
    // Route is confirmed once start_run_delivery has locked the sequence.
    if (live.every((o) => o.status == DeliveryStatus.pickedUp) &&
        !live.any((o) => o.sequenceLocked)) {
      return RunPhase.route;
    }
    return RunPhase.delivering;
  }

  DriverRun _toDriverRun(RiderRun r) {
    final ordered = [
      ...r.orders,
    ]..sort((a, b) => (a.sequence ?? 1 << 30).compareTo(b.sequence ?? 1 << 30));
    final phase = _phaseOf(r);
    final biz = active?.businessName ?? business?.name ?? 'Business';
    return DriverRun(
      id: r.sessionId ?? 'run',
      reference: r.waveName ?? 'Delivery run',
      dateLabel: todayDateLabel,
      zone: biz,
      pickupBusinessName: biz,
      pickupAddress: active?.businessAddress ?? '',
      distanceKm: null,
      state: phase == RunPhase.done
          ? RunState.completed
          : (phase == RunPhase.delivering
                ? RunState.onTheWay
                : RunState.assigned),
      stops: [for (final o in ordered) _toStop(o)],
    );
  }

  DriverStop _toStop(RiderOrder o) => DriverStop(
    id: o.id,
    reference: '#${o.publicRef.replaceAll('-', '')}',
    customerName: o.customerName,
    addressLine1: o.address,
    phone: o.customerPhone.isEmpty ? null : o.customerPhone,
    status: o.status == DeliveryStatus.delivered
        ? StopStatus.delivered
        : (o.status == DeliveryStatus.issue ||
                  o.status == DeliveryStatus.cancelled
              ? StopStatus.issue
              : StopStatus.pending),
    items: [
      for (final i in o.items)
        DriverOrderItem(quantity: i.quantity, name: i.name),
    ],
    deliveredAt: o.completedAt == null ? null : _timeLabel(o.completedAt!),
    deliveryStatus: o.status.name,
  );

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static String _dateLabel(DateTime d) =>
      '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
  static String _timeLabel(DateTime t) =>
      '${(t.hour % 12 == 0 ? 12 : t.hour % 12).toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';

  // --- real build: canonical Driver execution actions --------------------
  // Each calls the existing canonical contract, then re-reads backend state;
  // nothing is marked locally. Failures surface as RepositoryError.

  RiderOrder? _order(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  String get _riderId => active!.id;

  Future<void> _thenRefresh(Future<void> Function() action) async {
    try {
      await action();
    } finally {
      await refreshOrders();
    }
  }

  /// accept_run for the whole run.
  Future<void> acceptCurrentRun() => _thenRefresh(
    () => repo.acceptRun(riderId: _riderId, sessionId: currentRun.id),
  );

  /// start_pickup_run, then each order created -> ready_for_pickup ->
  /// picked_up through rider_transition (the canonical two-hop pickup).
  Future<void> confirmPickup() => _thenRefresh(() async {
    await repo.startPickupRun(riderId: _riderId, sessionId: currentRun.id);
    for (final s in currentRun.stops) {
      final o = _order(s.id);
      if (o == null) continue;
      if (o.status == DeliveryStatus.created) {
        await repo.transition(
          riderId: _riderId,
          orderId: o.id,
          next: 'ready_for_pickup',
        );
      }
      if (o.status == DeliveryStatus.created ||
          o.status == DeliveryStatus.readyForPickup) {
        await repo.transition(
          riderId: _riderId,
          orderId: o.id,
          next: 'picked_up',
        );
      }
    }
  });

  /// Slide to Confirm Route: save_run_sequence with the stop order on screen,
  /// then start_run_delivery (locks the sequence, orders go out for delivery).
  Future<void> confirmRouteAndStart() async {
    if (repo.isDemo) {
      confirmRoute();
      return;
    }
    await _thenRefresh(() async {
      final ids = [
        for (final s in currentRun.stops)
          if (s.status == StopStatus.pending) s.id,
      ];
      await repo.saveRunSequence(
        riderId: _riderId,
        sessionId: currentRun.id,
        orderedOrderIds: ids,
      );
      await repo.startRunDelivery(riderId: _riderId, sessionId: currentRun.id);
    });
  }

  /// rider_transition -> out_for_delivery (if still picked up) -> arrived.
  Future<void> arriveAt(String stopId) async {
    if (repo.isDemo) return;
    final o = _order(stopId);
    if (o == null || o.status == DeliveryStatus.arrived) return;
    await _thenRefresh(() async {
      if (o.status == DeliveryStatus.pickedUp) {
        await repo.transition(
          riderId: _riderId,
          orderId: stopId,
          next: 'out_for_delivery',
        );
      }
      await repo.transition(
        riderId: _riderId,
        orderId: stopId,
        next: 'arrived',
      );
    });
  }

  /// complete_delivery with a real proof-of-delivery photo.
  Future<void> completeStop(
    String stopId,
    List<int> photoBytes,
    String extension, {
    String note = '',
  }) => _thenRefresh(
    () => repo.completeDelivery(
      riderId: _riderId,
      orderId: stopId,
      photoBytes: photoBytes,
      photoExtension: extension,
      note: note,
    ),
  );

  /// rider_report_delivery_issue with a canonical reason. Reasons with no
  /// canonical equivalent are refused honestly rather than forced.
  Future<void> reportIssue(String stopId, IssueReason reason, String note) {
    final type = switch (reason) {
      IssueReason.customerNotAvailable => 'customer_unreachable',
      IssueReason.wrongAddress => 'address_problem',
      IssueReason.itemsNotAvailable => 'vendor_not_ready',
      IssueReason.safetyConcern => 'rider_unable_to_proceed',
      IssueReason.customerRequestedReschedule || IssueReason.other => null,
    };
    if (type == null) {
      throw RepositoryError(
        'This reason can\'t be recorded yet. Choose another reason or contact the business.',
      );
    }
    return _thenRefresh(
      () => repo.reportDeliveryIssue(
        riderId: _riderId,
        orderId: stopId,
        reasonType: type,
        note: note,
      ),
    );
  }

  Future<void> refreshOrders() async {
    await _loadOrders();
    if (!repo.isDemo) _project();
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
    _loadOrders().then((_) {
      if (!repo.isDemo) _project();
      notifyListeners();
    });
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
