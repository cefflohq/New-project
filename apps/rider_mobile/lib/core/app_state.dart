import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/rider_repository.dart';
import 'routes.dart';

/// Navigation + session state.
///
/// The navigation stack is a real history of typed [RiderLocation]s. Back
/// pops that history and falls back to the route's declared parent -- same
/// pattern as Vendor Mobile's AppState.
class AppState extends ChangeNotifier {
  AppState(this.repo);

  final RiderRepository repo;

  final List<RiderLocation> _stack = [const RiderLocation(RRoute.home)];
  List<RiderLocation> get stack => List.unmodifiable(_stack);
  RiderLocation get current => _stack.last;
  bool get canGoBack => _stack.length > 1 || current.spec.parent != null;
  NavTab get activeTab => current.spec.tab ?? NavTab.home;

  List<RiderRelationship> relationships = const [];
  RiderRelationship? active;
  List<RiderOrder> orders = const [];
  Map<String, String> sessionNames = const {};

  /// Light Mode only for now -- Dark Mode is HOLD (Founder scope
  /// correction, 2026-09-11). No ThemeMode.system/dark path is offered.
  static const themeMode = ThemeMode.light;

  bool loadingSession = true;
  String? sessionError;

  void go(RRoute route, {String? entityId}) {
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
        ..add(RiderLocation(parent ?? RRoute.home));
    }
    notifyListeners();
  }

  void switchTab(NavTab tab) {
    final root = switch (tab) {
      NavTab.home => RRoute.home,
      NavTab.assignments => RRoute.assignments,
      NavTab.route => RRoute.home, // state-aware entry, S16: resolved by Home
      NavTab.profile => RRoute.profile,
    };
    _stack
      ..clear()
      ..add(RiderLocation(root));
    notifyListeners();
  }

  void resetTo(RRoute route) {
    _stack
      ..clear()
      ..add(RiderLocation(route));
    notifyListeners();
  }

  Future<void> loadSession() async {
    loadingSession = true;
    sessionError = null;
    notifyListeners();
    try {
      relationships = await repo.myRiderRelationships();
      final activeOnes = relationships.where((r) => r.isActive).toList();
      active = activeOnes.isEmpty ? null : activeOnes.first;
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
        .map((e) => RiderRun(
              sessionId: e.key,
              waveName: e.key != null ? sessionNames[e.key] : null,
              orders: e.value,
            ))
        .toList();
  }

  void selectRelationship(RiderRelationship r) {
    active = r;
    notifyListeners();
    _loadOrders().then((_) => notifyListeners());
  }

  void clearSession() {
    relationships = const [];
    active = null;
    orders = const [];
    _stack
      ..clear()
      ..add(const RiderLocation(RRoute.home));
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) => (context
          .getElementForInheritedWidgetOfExactType<AppScope>()!
          .widget as AppScope)
      .notifier!;
}
