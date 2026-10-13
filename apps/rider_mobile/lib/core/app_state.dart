import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../data/driver_models.dart';
import '../data/models.dart';
import '../data/rider_repository.dart';
import 'live_location.dart';
import 'notification_alerts.dart';
import 'browser_history.dart';
import 'join_link.dart';
import 'ui_locale.dart';
import 'routes.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// Where the signed-in Driver sits in the account lifecycle the references
/// describe: no business yet (D11/D16/D17), details submitted and awaiting
/// the business's review (D14.1), approved (D14.2), operating (D14.3/D19).
enum DriverStage { noBusiness, pendingReview, approved, active }

/// Where the current run is in the canonical execution lifecycle, derived
/// only from persisted assignment and order states (real build).
/// Real-build run phases, in the locked order (Plan Route -> Pickup
/// Checklist -> Delivery Run): accept, plan (Plan Route), pickup (Pickup
/// Checklist), route (picked up, ready for Slide to Start Delivery),
/// delivering, done.
enum RunPhase { accept, pickup, route, delivering, done }

/// Navigation + session state.
///
/// The navigation stack is a real history of typed [RiderLocation]s. Back
/// pops that history and falls back to the route's declared parent -- same
/// pattern as Vendor Mobile's AppState. Identifiers stay "Rider" internally
/// per D-38; only rendered copy says "Driver".
class AppState extends ChangeNotifier {
  AppState(this.repo, {this.live});

  final RiderRepository repo;

  /// Phase 2B.4 rider live location (real build only; null in demo/tests).
  final LiveLocationService? live;

  void _syncLive() {
    final l = live;
    final rider = active;
    if (l == null || repo.isDemo || rider == null) return;
    l.sync(orders, rider.id).catchError((_) {});
  }

  /// A lifecycle event wants one fresh coordinate (still gated, D-66).
  void _liveEvent() {
    live?.event().catchError((_) {});
  }

  final List<RiderLocation> _stack = [const RiderLocation(DRoute.today)];
  List<RiderLocation> get stack => List.unmodifiable(_stack);
  RiderLocation get current => _stack.last;
  bool get canGoBack => _stack.length > 1 || current.spec.parent != null;
  NavTab get activeTab => current.spec.tab ?? NavTab.home;

  // --- canonical backend session ----------------------------------------
  List<RiderRelationship> relationships = const [];

  /// Vehicle chosen on V2, carried to V3 (stored `rider_vehicle_type`).
  String registrationVehicle = 'motorcycle';

  /// Number plate typed on V3, carried to D12.2.
  String registrationPlate = '';
  RiderRelationship? active;
  List<RiderOrder> orders = const [];

  /// Open orders of the Driver's other active vendors, by relationship id
  /// (Home lists every vendor's work for today).
  Map<String, List<RiderOrder>> otherOrders = const {};

  /// Every vendor's orders, for Today's Overview.
  Iterable<RiderOrder> get allOrders => [
    ...orders,
    for (final list in otherOrders.values) ...list,
  ];
  Map<String, String> sessionNames = const {};

  bool loadingSession = true;

  /// True once [loadSession] has hydrated this signed-in account; reset by
  /// [clearSession]. Lets the app root load a session that began outside
  /// the auth screens (an emailed confirmation link) exactly once.
  bool sessionLoaded = false;
  String? sessionError;

  /// Light Mode only. D38 shows an Appearance row; no dark theme is built
  /// behind it because no reference shows a dark screen.
  static const themeMode = ThemeMode.light;

  // --- driver-facing presentation state ---------------------------------
  DriverStage stage = DriverStage.active;
  // Demo fixtures seed the prototype only; a live session starts empty and
  // is filled from the backend by [loadSession].
  late DriverProfile profile = repo.isDemo
      ? DemoData.activeProfile
      : DriverProfile(
          fullName: '',
          phone: '',
          email: repo.currentUser?.email ?? '',
          dateOfBirth: '',
          address: '',
          vehicleType: '',
          vehicleModel: '',
          plateNumber: '',
          statusLabel: '',
        );
  late DriverBusiness? business = repo.isDemo ? DemoData.business : null;
  late DriverRun currentRun = repo.isDemo ? DemoData.currentRun : _emptyRun();
  late List<DriverRun> history = repo.isDemo ? DemoData.history : const [];
  late List<DriverNotification> notifications = repo.isDemo
      ? DemoData.notifications
      : const [];
  late List<DriverDocument> documents = repo.isDemo
      ? DemoData.documents
      : const [];
  late List<DriverDocument> onboardingDocuments = repo.isDemo
      ? DemoData.onboardingDocuments
      : const [];

  DriverRun _emptyRun() => DriverRun(
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

  /// UI language (en / ms). Independent of country/market (Founder,
  /// 2026-09-27). Starts from the device language; an explicit choice
  /// persists on this device and follows the signed-in user.
  Locale uiLocale = resolveDeviceLocale();
  final UiLocaleStore _localeStore = UiLocaleStore();

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
    // One browser entry per in-app step: the Android edge-swipe / browser
    // Back returns here instead of leaving the app for a blank page.
    if (hasBrowserHistory) {
      pushBrowserHistoryEntry();
      _historyDepth++;
    }
    notifyListeners();
  }

  int _historyDepth = 0;

  /// Set by the auth screens while shown; handles Back inside their stack.
  bool Function()? authBrowserBack;

  /// The browser's Back (swipe or button).
  void onBrowserBack() {
    if (authBrowserBack?.call() ?? false) return;
    if (_historyDepth > 0) _historyDepth--;
    if (_stack.length > 1 || current.spec.parent != null) _back();
  }

  void back() {
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

  /// Where "the run" opens: Run Details first, then the Stop List from its
  /// button (Founder 2026-10-13).
  DRoute get runRoute => DRoute.runDetails;

  void switchTab(NavTab tab) {
    final root = switch (tab) {
      NavTab.home => homeRoute,
      NavTab.runs => stage == DriverStage.active ? runRoute : homeRoute,
      NavTab.jobs => DRoute.findJobs,
      NavTab.history => DRoute.deliveryHistory,
      NavTab.profile => DRoute.profile,
    };
    _stack
      ..clear()
      ..add(
        RiderLocation(
          root,
          entityId: root == DRoute.runDetails || root == DRoute.stopList
              ? currentRun.id
              : null,
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
            s.copyWith(status: StopStatus.delivered, deliveredAt: L.justNow)
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

  /// Real build: saves the Driver's own details on the server, then reloads.
  Future<void> saveMyDriverProfile({
    required String fullName,
    required String phone,
    required String vehicleType,
    required String plate,
  }) async {
    await repo.updateMyDriverProfile(
      fullName: fullName,
      phone: phone,
      vehicleType: vehicleType,
      plate: plate,
    );
    await loadSession();
  }

  /// The vehicle to show / edit: the business relationship, else the
  /// Driver's registration choice.
  String get myVehicleType => profile.vehicleType.isNotEmpty
      ? profile.vehicleType
      : (repo.registration['vehicle_type']?.toString() ?? 'motorcycle');

  void updateProfile(DriverProfile next) {
    profile = next;
    notifyListeners();
  }

  // --- D33 notification centre, backed by public.notifications ----------
  // (docs/cefflo/NOTIFICATION_EVENT_MATRIX.md). The server writes every
  // row; this keeps the list, read state and preferences in step with it and
  // raises the foreground alert for rows arriving while the app is open.
  int _unreadLive = 0;
  NotificationPrefs notificationPrefs = const NotificationPrefs();
  String? notificationsError;
  void Function()? _cancelNotifications;
  bool _subscribedOnce = false;
  final Set<String> _seenNotifications = {};

  /// The foreground alert currently shown over the app, if any.
  final ValueNotifier<DriverNotification?> foregroundAlert = ValueNotifier(
    null,
  );

  /// Sound/vibration side effects of an alert (replaceable in tests).
  NotificationAlertEffects alertEffects = const NotificationAlertEffects();

  int get unreadNotifications => repo.isDemo
      ? notifications.where((n) => n.unread && !n.archived).length
      : _unreadLive;

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
    if (!repo.isDemo) {
      notifications = const [];
      _unreadLive = 0;
      _seenNotifications.clear();
    }
    foregroundAlert.value = null;
  }

  /// App returned to the foreground (NotificationBanner observes the
  /// lifecycle): re-read the centre in case the socket slept.
  void onAppResumed() {
    if (_cancelNotifications != null) refreshNotifications();
    if (!repo.isDemo && sessionLoaded && !loadingSession) {
      resyncOnResume().catchError((_) {});
    }
  }

  /// Back in the foreground: re-read the relationship and the assigned work,
  /// since realtime may have dropped while backgrounded. A relationship that
  /// changed (removed, approved, another business) re-resolves the whole
  /// session; otherwise only the orders refresh, keeping the current screen.
  Future<void> resyncOnResume() async {
    final rows = await repo.myRiderRelationships();
    final stillActive = rows.where((r) => r.isActive).toList();
    final sameActive =
        stillActive.isNotEmpty && stillActive.first.id == active?.id;
    final unchanged =
        rows.length == relationships.length &&
        rows.every(
          (r) => relationships.any((o) => o.id == r.id && o.status == r.status),
        );
    if (!sameActive || !unchanged) {
      await loadSession();
    } else {
      await refreshOrders();
    }
  }

  Future<void> refreshNotifications() async {
    if (repo.isDemo) return;
    try {
      final rows = await repo.notifications();
      _unreadLive = await repo.unreadNotificationCount();
      notifications = rows;
      _seenNotifications.addAll(rows.map((n) => n.id!));
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
      if (row['app'] != 'rider') return;
      if (notifications.any((n) => n.id == id)) return;
      final n = DriverNotification.fromRow(row);
      notifications = [n, ...notifications].take(50).toList();
      if (n.unread) _unreadLive++;
      notifyListeners();
      if (_seenNotifications.add(id)) _present(n);
      // A run or account change: re-read the operational truth it reports.
      if (n.eventKey?.startsWith('run.') == true) {
        refreshOrders().catchError((_) {});
      } else if (n.eventKey?.startsWith('rider.') == true) {
        loadSession().catchError((_) {});
      }
    } else if (type == 'UPDATE') {
      final i = notifications.indexWhere((n) => n.id == id);
      if (i < 0) return;
      final wasUnread = notifications[i].unread;
      final nowUnread = row['read_at'] == null;
      notifications = List.of(notifications)
        ..[i] = notifications[i].copyWith(unread: nowUnread);
      if (wasUnread && !nowUnread) _unreadLive = max(0, _unreadLive - 1);
      if (!wasUnread && nowUnread) _unreadLive++;
      notifyListeners();
    } else if (type == 'DELETE') {
      final gone = notifications.where((n) => n.id == id).toList();
      if (gone.isEmpty) return;
      notifications = notifications.where((n) => n.id != id).toList();
      if (gone.first.unread) _unreadLive = max(0, _unreadLive - 1);
      notifyListeners();
    }
  }

  /// Foreground alert: banner + sound/vibration per preferences. Rows older
  /// than two minutes only land in the centre.
  void _present(DriverNotification n) {
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

  Future<void> _setRead(DriverNotification target, bool read) async {
    if (target.unread == !read) return;
    notifications = [
      for (final n in notifications)
        if (identical(n, target) || (n.id != null && n.id == target.id))
          n.copyWith(unread: !read)
        else
          n,
    ];
    if (!repo.isDemo) _unreadLive = max(0, _unreadLive + (read ? -1 : 1));
    notifyListeners();
    if (repo.isDemo || target.id == null) return;
    try {
      if (read) {
        await repo.markNotificationsRead(ids: [target.id!]);
      } else {
        await repo.markNotificationUnread(target.id!);
      }
    } on RepositoryError {
      await refreshNotifications();
      rethrow;
    }
  }

  /// D33 — tapping a notification clears its unread dot (server read state).
  Future<void> markNotificationRead(DriverNotification target) =>
      _setRead(target, true);

  Future<void> markNotificationUnread(DriverNotification target) =>
      _setRead(target, false);

  Future<void> markAllNotificationsRead() async {
    notifications = [for (final n in notifications) n.copyWith(unread: false)];
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

  Future<void> setNotificationPrefs(NotificationPrefs next) async {
    if (!repo.isDemo) await repo.saveNotificationPrefs(next);
    notificationPrefs = next;
    notifyListeners();
  }

  /// Opens a notification: marks it read and follows its deep-link.
  void openNotification(DriverNotification n) {
    if (n.unread) markNotificationRead(n).catchError((_) {});
    if (n.targetScreen == 'runs') {
      go(
        hasRun ? runRoute : homeRoute,
        entityId: hasRun ? currentRun.id : null,
      );
    } else {
      notifyListeners();
    }
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
      // The signed-in user's own language follows them across devices.
      final own = parseUiLocale(repo.currentUser?.userMetadata?['ui_locale']);
      if (own != null && own != uiLocale) {
        _applyUiLocale(own);
        await _localeStore.write(own);
      }
      // One invitation, one acceptance: a consent given in the Invitation
      // PWA becomes the pending membership here, before relationships are
      // read. Best-effort -- a failed claim never blocks signing in, and the
      // next session load retries it.
      try {
        await repo.claimMyRiderInvitations();
      } on RepositoryError catch (_) {}
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
      // Registration (V2 Choose Your Vehicle -> V3 Your Driver Details)
      // comes first for a rider with no business who has not chosen a
      // vehicle yet.
      if (stage == DriverStage.noBusiness &&
          repo.registration['vehicle_type'] == null) {
        _stack.add(const RiderLocation(DRoute.chooseVehicle));
      }
      // Opened from a business's permanent invite link: go straight to
      // Join Business with the link filled in.
      // Any stage: a rider may belong to several businesses, so an
      // existing membership never hides a new invite.
      if (joinToken != null) {
        _stack.add(const RiderLocation(DRoute.joinBusiness));
      }
      if (active != null) await _loadOrders();
      _project();
      if (_cancelNotifications == null) startNotifications();
      sessionLoaded = true;
    } on RepositoryError catch (e) {
      sessionError = e.message;
    } finally {
      loadingSession = false;
      notifyListeners();
    }
  }

  // ---- Permanent invite link (rider). Kept on the device through sign-up
  // until the join request is sent; grants nothing by itself.
  String? joinToken;
  final JoinLinkStore _joinStore = JoinLinkStore();

  Future<void> restoreJoinToken(Uri launch) async {
    joinToken = await _joinStore.read(launch);
    notifyListeners();
  }

  Future<void> finishJoin() async {
    joinToken = null;
    await _joinStore.clear();
  }

  Future<void> _loadOrders() async {
    final rider = active;
    if (rider == null) {
      orders = const [];
      return;
    }
    orders = await repo.myOrders(rider.id);
    _syncLive();
    final others = <String, List<RiderOrder>>{};
    for (final rel in relationships) {
      if (!rel.isActive || rel.id == rider.id) continue;
      try {
        others[rel.id] = await repo.myOrders(rel.id);
      } on RepositoryError {
        // One vendor failing must not hide the others.
      }
    }
    otherOrders = others;
    try {
      _schedule = await repo.myJobSchedule();
    } on RepositoryError {
      // Run Details then simply shows no pay / pickup time.
      _schedule = const [];
    }
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

  /// The Driver's own hiring bookings (my_job_schedule).
  List<Map<String, dynamic>> _schedule = const [];

  /// Today's approved contract with the active business, if any: the pickup
  /// time, the pay per drop and the area for Run Details.
  Map<String, dynamic>? get _todayContract {
    final bid = active?.businessId;
    return bid == null ? null : _contractFor(bid);
  }

  /// Today's approved contract with [businessId], if any.
  Map<String, dynamic>? _contractFor(String businessId) {
    final today = DateTime.now().weekday;
    for (final r in _schedule) {
      final days = [
        for (final d in (r['days'] as List? ?? const [])) (d as num).toInt(),
      ];
      if (r['business_id']?.toString() == businessId &&
          r['status'] == 'approved' &&
          days.contains(today)) {
        return r;
      }
    }
    return null;
  }

  /// Home's "Today's jobs": one entry per active vendor with work today,
  /// ongoing first, then coming soon by pickup time. A vendor whose run is
  /// finished (no open orders left) is not listed; a vendor with a contract
  /// for today but no orders yet is coming soon.
  List<DriverJob> get todayJobs {
    if (repo.isDemo) return DemoData.todayJobs;
    final jobs = <DriverJob>[];
    for (final rel in relationships) {
      if (!rel.isActive) continue;
      final list = rel.id == active?.id
          ? orders
          : (otherOrders[rel.id] ?? const []);
      final open = list.where((o) => !_terminal(o.status)).toList();
      final contract = _contractFor(rel.businessId);
      final hadOrders = list.isNotEmpty;
      if (open.isEmpty && (hadOrders || contract == null)) continue;
      final start = contract?['shift_start']?.toString().split(':');
      jobs.add(
        DriverJob(
          relationshipId: rel.id,
          vendorName: rel.businessName ?? L.business,
          orderCount: open.length,
          ongoing: _isOngoing(open),
          pickupTimeLabel: _clockOf(contract?['shift_start']),
          storePhone: rel.businessPhone,
          storeAddress: rel.businessAddress,
          storeLatitude: rel.businessLatitude,
          storeLongitude: rel.businessLongitude,
          pickupMinutes: start == null || start.length < 2
              ? null
              : (int.tryParse(start[0]) ?? 0) * 60 +
                    (int.tryParse(start[1]) ?? 0),
        ),
      );
    }
    jobs.sort((a, b) {
      if (a.ongoing != b.ongoing) return a.ongoing ? -1 : 1;
      return (a.pickupMinutes ?? 1 << 20).compareTo(b.pickupMinutes ?? 1 << 20);
    });
    return jobs;
  }

  /// Opens a vendor's job from Home: makes it the active vendor, then shows
  /// its Run Details.
  Future<void> openJob(DriverJob job) async {
    if (repo.isDemo) {
      // Prototype: each vendor opens its own run (the ongoing one under
      // way, the others at their Pickup Checklist).
      if (job.ongoing) {
        currentRun = DemoData.currentRun;
        runPhase = null;
        routeConfirmed = true;
      } else {
        currentRun = DemoData.pickupRunFor(job);
        runPhase = RunPhase.pickup;
        pickupTicks.clear();
      }
      notifyListeners();
    } else if (job.relationshipId != active?.id) {
      final rel = relationships.firstWhere((r) => r.id == job.relationshipId);
      active = rel;
      await _loadOrders();
      _project();
      notifyListeners();
    }
    go(runRoute, entityId: currentRun.id);
  }

  static String? _clockOf(Object? t) {
    final p = t?.toString().split(':');
    if (p == null || p.length < 2) return null;
    final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
  }

  /// Null when the real build has no run to show.
  RunPhase? runPhase;
  bool get hasRun => repo.isDemo || runPhase != null;

  String get todayDateLabel =>
      repo.isDemo ? DemoData.todayDateLabel : _dateLabel(DateTime.now());
  int get todayAssigned => repo.isDemo
      ? DemoData.todayAssigned
      : allOrders
            .where(
              (o) =>
                  o.status == DeliveryStatus.created ||
                  o.status == DeliveryStatus.readyForPickup,
            )
            .length;
  int get todayOngoing => repo.isDemo
      ? DemoData.todayOngoing
      : allOrders
            .where(
              (o) =>
                  o.status == DeliveryStatus.pickedUp ||
                  o.status == DeliveryStatus.outForDelivery ||
                  o.status == DeliveryStatus.arrived,
            )
            .length;
  int get todayIssues => repo.isDemo
      ? DemoData.todayIssues
      : allOrders.where((o) => o.status == DeliveryStatus.issue).length;
  int get todayCompleted => repo.isDemo
      ? DemoData.todayCompleted
      : allOrders.where((o) => o.status == DeliveryStatus.delivered).length;

  static bool _terminal(DeliveryStatus s) =>
      s == DeliveryStatus.delivered ||
      s == DeliveryStatus.issue ||
      s == DeliveryStatus.cancelled;

  void _project() {
    final rel = active ?? (relationships.isEmpty ? null : relationships.first);
    if (rel != null) {
      business = DriverBusiness(
        name: rel.businessName ?? L.business,
        category: '',
        location: rel.businessAddress ?? '',
        // Contact only while the relationship is active.
        phone: rel.isActive ? rel.businessPhone : null,
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
        statusLabel: rel.isActive ? L.activeDriver : L.pendingReview,
      );
    }
    // No document store exists on the backend yet: show none rather than
    // demo entries. Notifications are loaded by [startNotifications].
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
    // No open run: show the most recently finished one (independent of
    // row order).
    DateTime finishedAt(RiderRun r) => r.orders
        .map((o) => o.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .fold(
          DateTime.fromMillisecondsSinceEpoch(0),
          (a, b) => b.isAfter(a) ? b : a,
        );
    current ??= all.isEmpty
        ? null
        : all.reduce((a, b) => finishedAt(b).isAfter(finishedAt(a)) ? b : a);
    history = [
      for (final r in all)
        if (!open(r)) _toDriverRun(r),
    ];
    if (current == null) {
      runPhase = null;
      routeConfirmed = false;
      currentRun = _emptyRun();
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
      // Founder 2026-10-13: the Pickup Checklist comes first (tick every
      // order, Slide to Confirm Pickup), then Plan Route, then Start
      // Delivery. Orders not yet picked up mean the run is at pickup.
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
    final biz = active?.businessName ?? business?.name ?? L.business;
    // A finished run is dated by its last completed delivery, so History
    // never labels an older run with today's date.
    final finished = [
      for (final o in r.orders)
        if (o.completedAt != null) o.completedAt!,
    ]..sort();
    return DriverRun(
      id: r.sessionId ?? 'run',
      reference: r.waveName ?? L.deliveryRun,
      dateLabel: phase == RunPhase.done && finished.isNotEmpty
          ? _dateLabel(finished.last)
          : todayDateLabel,
      completedAtLabel: phase == RunPhase.done && finished.isNotEmpty
          ? _timeLabel(finished.last)
          : null,
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
      pickupTimeLabel: _clockOf(_todayContract?['shift_start']),
      payPerDrop: _todayContract?['pay_unit'] == 'drop'
          ? _todayContract!['pay_amount'] as num?
          : null,
      area: (_todayContract?['area_label'] as String?)?.trim().isEmpty ?? true
          ? null
          : _todayContract!['area_label'] as String,
      pickupLatitude: active?.businessLatitude,
      pickupLongitude: active?.businessLongitude,
      ongoing: _isOngoing(r.orders),
    );
  }

  /// One rule for Home and Run Details: picked up and not finished.
  static bool _isOngoing(Iterable<RiderOrder> orders) => orders.any(
    (o) =>
        o.status == DeliveryStatus.pickedUp ||
        o.status == DeliveryStatus.outForDelivery ||
        o.status == DeliveryStatus.arrived,
  );

  DriverStop _toStop(RiderOrder o) => DriverStop(
    id: o.id,
    reference: o.orderNumber ?? o.publicRef,
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
    latitude: o.latitude,
    longitude: o.longitude,
    note: o.note.trim().isEmpty ? null : o.note.trim(),
  );

  static List<String> get _days => [
    L.mon,
    L.tue,
    L.wed,
    L.thu,
    L.fri,
    L.sat,
    L.sun,
  ];
  static List<String> get _months => [
    L.jan,
    L.feb,
    L.mar,
    L.apr,
    L.may,
    L.jun,
    L.jul,
    L.aug,
    L.sep,
    L.oct,
    L.nov,
    L.dec,
  ];
  // Backend timestamps arrive in UTC; labels are always the device's time.
  static String _dateLabel(DateTime utc) {
    final d = utc.toLocal();
    return '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  static String _timeLabel(DateTime utc) => _clock(utc.toLocal());
  static String _clock(DateTime t) =>
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

  Future<void> _thenRefresh(
    Future<void> Function() action, {
    bool locationEvent = false,
  }) async {
    try {
      await action();
    } finally {
      await refreshOrders();
    }
    if (locationEvent) _liveEvent();
  }

  /// The next stop in the locked sequence becomes out_for_delivery as soon
  /// as it is current (route start, or the previous stop finished), so the
  /// customer sees On the Way while the rider is actually heading there.
  /// The backend enforces the sequence; a refusal is ignored.
  Future<void> _advanceCurrentStop({String? finishedId}) async {
    final session = currentRun.id;
    final pending =
        orders
            .where(
              (o) =>
                  o.deliverySessionId == session &&
                  o.id != finishedId &&
                  o.sequence != null &&
                  (o.status == DeliveryStatus.pickedUp ||
                      o.status == DeliveryStatus.outForDelivery ||
                      o.status == DeliveryStatus.arrived),
            )
            .toList()
          ..sort((a, b) => a.sequence!.compareTo(b.sequence!));
    if (pending.isEmpty || pending.first.status != DeliveryStatus.pickedUp) {
      return;
    }
    try {
      await repo.transition(
        riderId: _riderId,
        orderId: pending.first.id,
        next: 'out_for_delivery',
      );
    } on RepositoryError {
      // Not current yet per the backend; the next refresh stays truthful.
    }
  }

  /// Pickup Checklist: the stop ids the Driver has ticked as in hand.
  /// Slide to Confirm Pickup unlocks once every order is ticked. Local to
  /// this device; the pickup itself is recorded by [confirmPickup].
  final Set<String> pickupTicks = {};

  void togglePickupTick(String stopId) {
    pickupTicks.contains(stopId)
        ? pickupTicks.remove(stopId)
        : pickupTicks.add(stopId);
    notifyListeners();
  }

  /// Orders still to pick up (an order reported at pickup drops out).
  Iterable<DriverStop> get pickupStops =>
      currentRun.stops.where((s) => s.status == StopStatus.pending);

  bool get allPickupTicked =>
      pickupStops.isNotEmpty &&
      pickupStops.every((s) => pickupTicks.contains(s.id));

  /// accept_run for the whole run.
  Future<void> acceptCurrentRun() => _thenRefresh(
    () => repo.acceptRun(riderId: _riderId, sessionId: currentRun.id),
  );

  /// start_pickup_run, then each order created -> ready_for_pickup ->
  /// picked_up through rider_transition (the canonical two-hop pickup).
  /// Prototype only (?screen=D20.1): the demo run at the Pickup Checklist.
  void startDemoPickup() {
    currentRun = DemoData.pickupRunFor(DemoData.todayJobs[1]);
    runPhase = RunPhase.pickup;
    pickupTicks.clear();
  }

  Future<void> confirmPickup() async {
    if (repo.isDemo) {
      // Prototype: the pickup is local; Plan Route comes next.
      currentRun = currentRun.copyWith(
        stops: [
          for (final s in currentRun.stops)
            if (s.status == StopStatus.pending) s,
        ],
      );
      runPhase = RunPhase.route;
      pickupTicks.clear();
      notifyListeners();
      return;
    }
    return _confirmPickupLive();
  }

  Future<void> _confirmPickupLive() => _thenRefresh(() async {
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
    pickupTicks.clear();
  }, locationEvent: true);

  /// Slide to Start Delivery (after the Pickup Checklist): save_run_sequence
  /// with the stop order on screen, then start_run_delivery (locks the
  /// sequence; the backend refuses it while pickup is incomplete).
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
      await _loadOrders();
      await _advanceCurrentStop();
    }, locationEvent: true);
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
    }, locationEvent: true);
  }

  /// complete_delivery with a real proof-of-delivery photo.
  Future<void> completeStop(
    String stopId,
    List<int> photoBytes,
    String extension, {
    String note = '',
  }) => _thenRefresh(() async {
    await repo.completeDelivery(
      riderId: _riderId,
      orderId: stopId,
      photoBytes: photoBytes,
      photoExtension: extension,
      note: note,
    );
    await _advanceCurrentStop(finishedId: stopId);
  }, locationEvent: true);

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
      throw RepositoryError(L.reasonCantRecordedYetChooseAnother);
    }
    if (repo.isDemo && runPhase == RunPhase.pickup) {
      // Prototype pickup: mark the order reported locally.
      currentRun = currentRun.copyWith(
        stops: [
          for (final s in currentRun.stops)
            s.id == stopId ? s.copyWith(status: StopStatus.issue) : s,
        ],
      );
      notifyListeners();
      return Future.value();
    }
    return _thenRefresh(() async {
      await repo.reportDeliveryIssue(
        riderId: _riderId,
        orderId: stopId,
        reasonType: type,
        note: note,
      );
      await _advanceCurrentStop(finishedId: stopId);
    }, locationEvent: true);
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
    sessionLoaded = false;
    stopNotifications();
    live?.stop().catchError((_) {});
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
