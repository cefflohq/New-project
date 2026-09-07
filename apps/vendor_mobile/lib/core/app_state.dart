import 'package:flutter/material.dart';

import '../data/models.dart';
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
  ThemeMode themeMode = ThemeMode.system;
  String locale = 'en';

  bool loadingSession = true;
  String? sessionError;

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
      NavTab.menu => VRoute.settings,
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

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
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

  void clearSession() {
    businesses = const [];
    business = null;
    _stack
      ..clear()
      ..add(const VendorLocation(VRoute.today));
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
