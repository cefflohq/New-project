/// Typed route graph for the Cefflo Driver screen inventory.
///
/// Numbering and titles come from the locked reference image captions
/// (D01 … D40-C), which the Founder has made authoritative for this build.
/// Where the older `13_DRIVER_FLUTTER_42_SCREEN_MASTER.md` disagrees (it
/// numbers "No Business Connected" as D11 and "Review & Submit" as D16), the
/// references win; reconciling that document is explicitly out of scope
/// here.
///
/// Internal identifiers stay "Rider" (D-38): only rendered copy says
/// "Cefflo Driver". Same RouteSpec/parent/tab shape as Vendor Mobile's
/// routes.dart — one shared pattern across both Flutter clients.
library;

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// Bottom navigation, reconciled from the references.
///
/// Two label sets appear across the set: Home/Runs/History/Profile
/// (D16, D17, D18, D19, D20, D21, D21.1, D21.2, D22, D23, D28, D29, D30,
/// D31, D32, D33, D34, D35, D36, D37, D38, D39, D40 — 23 screens) and
/// Home/Earnings|History/Help/Profile (D11, D14.1, D14.2, D14.3 — 4
/// pre-activation screens). The four-tab operational set is the clear
/// majority and covers every daily-use screen, so it is the real nav.
enum NavTab { home, runs, history, profile }

enum DRoute {
  // --- Auth (D01–D09) --------------------------------------------------
  splash, // D01
  signIn, // D02
  emailSignIn, // D03
  createAccount, // D04
  forgotPassword, // D05
  checkEmail, // D06
  setNewPassword, // D07
  passwordUpdated, // D08
  // --- Onboarding / business join (D10–D18) ----------------------------
  noBusinessConnectedHome, // D11 (home-shell variant, pre-details)
  driverDetails, // D12
  personalDetails, // D12.1
  vehicleAndDocuments, // D12.2
  pendingReview, // D14.1
  approved, // D14.2
  readyToGo, // D14.3
  noBusinessConnected, // D16
  joinBusiness, // D17
  businessJoined, // D18
  // --- Operational loop (D19–D30) --------------------------------------
  today, // D19 Today (Home)
  runDetails, // D20
  stopList, // D21 / D21.1 / D21.2
  navigationToStop, // D22
  confirmDelivery, // D23
  deliveryIssue, // D28
  reportIssue, // D29
  runCompleted, // D30
  // --- History & notifications (D31–D33) -------------------------------
  deliveryHistory, // D31
  historyDetail, // D32
  notifications, // D33
  // --- Profile & settings (D34–D39) ------------------------------------
  profile, // D34
  editProfile, // D35
  vehicleDetails, // D36
  documents, // D37
  settings, // D38
  // (D39 Select Language is a bottom sheet over D38, not a route.)
  // --- Support (D40 family) --------------------------------------------
  helpSupport, // D40
  vendorSupport, // D40-B
  submitTicket, // D40-C
  // (D40-A Contact Support is a bottom sheet over D40, not a route.)
}

class RouteSpec {
  const RouteSpec({
    required this.route,
    required this.id,
    required this.title,
    this.parent,
    this.tab,
    this.requiresEntityId = false,
  });

  final DRoute route;

  /// Canonical inventory id exactly as printed in the reference caption
  /// ("D21.1", "D40-B").
  final String id;
  final String title;
  final DRoute? parent;
  final NavTab? tab;
  final bool requiresEntityId;
}

Map<DRoute, RouteSpec> get routeSpecs => <DRoute, RouteSpec>{
  DRoute.splash: RouteSpec(route: DRoute.splash, id: 'D01', title: L.splash),
  DRoute.signIn: RouteSpec(route: DRoute.signIn, id: 'D02', title: L.sign),
  DRoute.emailSignIn: RouteSpec(
    route: DRoute.emailSignIn,
    id: 'D03',
    title: L.signEmail,
    parent: DRoute.signIn,
  ),
  DRoute.createAccount: RouteSpec(
    route: DRoute.createAccount,
    id: 'D04',
    title: L.createAccount,
    parent: DRoute.signIn,
  ),
  DRoute.forgotPassword: RouteSpec(
    route: DRoute.forgotPassword,
    id: 'D05',
    title: L.forgotPassword,
    parent: DRoute.emailSignIn,
  ),
  DRoute.checkEmail: RouteSpec(
    route: DRoute.checkEmail,
    id: 'D06',
    title: L.checkEmail,
    parent: DRoute.forgotPassword,
  ),
  DRoute.setNewPassword: RouteSpec(
    route: DRoute.setNewPassword,
    id: 'D07',
    title: L.setNewPassword,
    parent: DRoute.checkEmail,
  ),
  DRoute.passwordUpdated: RouteSpec(
    route: DRoute.passwordUpdated,
    id: 'D08',
    title: L.passwordUpdated,
    parent: DRoute.setNewPassword,
  ),
  DRoute.noBusinessConnectedHome: RouteSpec(
    route: DRoute.noBusinessConnectedHome,
    id: 'D11',
    title: L.noBusinessConnected,
    tab: NavTab.home,
  ),
  DRoute.driverDetails: RouteSpec(
    route: DRoute.driverDetails,
    id: 'D12',
    title: L.driverDetails,
  ),
  DRoute.personalDetails: RouteSpec(
    route: DRoute.personalDetails,
    id: 'D12.1',
    title: L.personalDetails,
    parent: DRoute.driverDetails,
  ),
  DRoute.vehicleAndDocuments: RouteSpec(
    route: DRoute.vehicleAndDocuments,
    id: 'D12.2',
    title: L.vehicleDocuments,
    parent: DRoute.personalDetails,
  ),
  DRoute.pendingReview: RouteSpec(
    route: DRoute.pendingReview,
    id: 'D14.1',
    title: L.applicationUnderReview,
    tab: NavTab.home,
  ),
  DRoute.approved: RouteSpec(
    route: DRoute.approved,
    id: 'D14.2',
    title: L.youreApproved,
    tab: NavTab.home,
  ),
  DRoute.readyToGo: RouteSpec(
    route: DRoute.readyToGo,
    id: 'D14.3',
    title: L.readyGo,
    tab: NavTab.home,
  ),
  DRoute.noBusinessConnected: RouteSpec(
    route: DRoute.noBusinessConnected,
    id: 'D16',
    title: L.noBusinessConnected,
    tab: NavTab.home,
  ),
  DRoute.joinBusiness: RouteSpec(
    route: DRoute.joinBusiness,
    id: 'D17',
    title: L.joinBusiness,
    parent: DRoute.noBusinessConnected,
    tab: NavTab.home,
  ),
  DRoute.businessJoined: RouteSpec(
    route: DRoute.businessJoined,
    id: 'D18',
    title: L.businessJoined,
    parent: DRoute.joinBusiness,
    tab: NavTab.home,
  ),

  DRoute.today: RouteSpec(
    route: DRoute.today,
    id: 'D19',
    title: L.today,
    tab: NavTab.home,
  ),
  DRoute.runDetails: RouteSpec(
    route: DRoute.runDetails,
    id: 'D20',
    title: L.runDetails,
    parent: DRoute.today,
    tab: NavTab.runs,
    requiresEntityId: true,
  ),
  DRoute.stopList: RouteSpec(
    route: DRoute.stopList,
    id: 'D21',
    title: L.stopList,
    parent: DRoute.runDetails,
    tab: NavTab.runs,
    requiresEntityId: true,
  ),
  DRoute.navigationToStop: RouteSpec(
    route: DRoute.navigationToStop,
    id: 'D22',
    title: L.navigationStop,
    parent: DRoute.stopList,
    tab: NavTab.runs,
    requiresEntityId: true,
  ),
  DRoute.confirmDelivery: RouteSpec(
    route: DRoute.confirmDelivery,
    id: 'D23',
    title: L.confirmDelivery,
    parent: DRoute.navigationToStop,
    tab: NavTab.runs,
    requiresEntityId: true,
  ),
  DRoute.deliveryIssue: RouteSpec(
    route: DRoute.deliveryIssue,
    id: 'D28',
    title: L.deliveryIssue,
    parent: DRoute.confirmDelivery,
    tab: NavTab.runs,
    requiresEntityId: true,
  ),
  DRoute.reportIssue: RouteSpec(
    route: DRoute.reportIssue,
    id: 'D29',
    title: L.reportIssue,
    parent: DRoute.deliveryIssue,
    tab: NavTab.runs,
    requiresEntityId: true,
  ),
  DRoute.runCompleted: RouteSpec(
    route: DRoute.runCompleted,
    id: 'D30',
    title: L.runCompleted,
    parent: DRoute.today,
    tab: NavTab.runs,
    requiresEntityId: true,
  ),

  DRoute.deliveryHistory: RouteSpec(
    route: DRoute.deliveryHistory,
    id: 'D31',
    title: L.deliveryHistory,
    tab: NavTab.history,
  ),
  DRoute.historyDetail: RouteSpec(
    route: DRoute.historyDetail,
    id: 'D32',
    title: L.historyDetail,
    parent: DRoute.deliveryHistory,
    tab: NavTab.history,
    requiresEntityId: true,
  ),
  DRoute.notifications: RouteSpec(
    route: DRoute.notifications,
    id: 'D33',
    title: L.notifications,
    parent: DRoute.deliveryHistory,
    tab: NavTab.history,
  ),

  DRoute.profile: RouteSpec(
    route: DRoute.profile,
    id: 'D34',
    title: L.profile,
    tab: NavTab.profile,
  ),
  DRoute.editProfile: RouteSpec(
    route: DRoute.editProfile,
    id: 'D35',
    title: L.editProfile,
    parent: DRoute.profile,
    tab: NavTab.profile,
  ),
  DRoute.vehicleDetails: RouteSpec(
    route: DRoute.vehicleDetails,
    id: 'D36',
    title: L.vehicleDetails,
    parent: DRoute.profile,
    tab: NavTab.profile,
  ),
  DRoute.documents: RouteSpec(
    route: DRoute.documents,
    id: 'D37',
    title: L.documents,
    parent: DRoute.profile,
    tab: NavTab.profile,
  ),
  DRoute.settings: RouteSpec(
    route: DRoute.settings,
    id: 'D38',
    title: L.settings,
    parent: DRoute.profile,
    tab: NavTab.profile,
  ),

  DRoute.helpSupport: RouteSpec(
    route: DRoute.helpSupport,
    id: 'D40',
    title: L.helpSupport,
    parent: DRoute.profile,
    tab: NavTab.profile,
  ),
  DRoute.vendorSupport: RouteSpec(
    route: DRoute.vendorSupport,
    id: 'D40-B',
    title: L.vendorSupport,
    parent: DRoute.helpSupport,
    tab: NavTab.profile,
  ),
  DRoute.submitTicket: RouteSpec(
    route: DRoute.submitTicket,
    id: 'D40-C',
    title: L.submitTicket,
    parent: DRoute.helpSupport,
    tab: NavTab.profile,
  ),
};

/// A concrete place in the app: a route plus the entity it is bound to
/// (an order id for delivery-flow screens, a run id for run screens).
class RiderLocation {
  const RiderLocation(this.route, {this.entityId});
  final DRoute route;
  final String? entityId;

  RouteSpec get spec => routeSpecs[route]!;

  @override
  bool operator ==(Object other) =>
      other is RiderLocation &&
      other.route == route &&
      other.entityId == entityId;

  @override
  int get hashCode => Object.hash(route, entityId);

  @override
  String toString() =>
      entityId == null ? route.name : '${route.name}:$entityId';
}

/// Lookup by the reference caption id ("D21.1"), used by the prototype's
/// deep-link preview path so any screen can be screenshotted directly.
DRoute? routeForReferenceId(String id) {
  final wanted = id.toUpperCase();
  // D21.1 and D21.2 are two phases of one screen (the List/Map route-
  // planning surface), so they share D21's route and are told apart by
  // AppState.routeConfirmed rather than by owning a route each.
  const aliases = <String, DRoute>{
    'D21.1': DRoute.stopList,
    'D21.2': DRoute.stopList,
  };
  final alias = aliases[wanted];
  if (alias != null) return alias;
  for (final spec in routeSpecs.values) {
    if (spec.id.toUpperCase() == wanted) return spec.route;
  }
  return null;
}
