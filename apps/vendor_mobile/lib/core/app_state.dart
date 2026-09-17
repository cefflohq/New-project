import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/storefront_config.dart';
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

  // ---- Storefront presentation config (V-31/V-33). Deliberately separate
  // from product/catalogue and order data: this only ever describes layout
  // (selectedStorefrontTemplate) and brand identity (customStorefrontBranding).
  // No backend yet, so it's in-memory session state -- a Storefront
  // configuration adapter boundary, not a parallel production API.
  StorefrontTemplate selectedStorefrontTemplate = StorefrontTemplate.browseShop;

  /// Null until the vendor explicitly saves a brand colour; until then, the
  /// effective branding just follows whichever template is selected. Once
  /// set, it persists across template switches ("the template controls
  /// layout, the vendor controls brand identity").
  StorefrontBranding? customStorefrontBranding;

  StorefrontBranding get storefrontBranding =>
      customStorefrontBranding ?? StorefrontBranding.defaultFor(selectedStorefrontTemplate);

  void selectStorefrontTemplate(StorefrontTemplate template) {
    selectedStorefrontTemplate = template;
    notifyListeners();
  }

  void saveStorefrontBranding(StorefrontBranding branding) {
    customStorefrontBranding = branding;
    notifyListeners();
  }

  void resetStorefrontBranding() {
    customStorefrontBranding = null;
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
