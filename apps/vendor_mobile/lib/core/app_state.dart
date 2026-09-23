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
