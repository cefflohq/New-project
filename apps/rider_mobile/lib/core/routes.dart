/// Typed route graph for the 33-screen Rider inventory
/// (docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md S4, R-01 -> R-33).
/// Same RouteSpec/parent/tab shape as Vendor Mobile's routes.dart -- one
/// shared pattern across both Flutter clients.
library;

enum NavTab { home, assignments, route, profile }

enum RRoute {
  splash, // R-01
  invitation, // R-02
  riderSetup, // R-03
  signIn, // R-04
  forgotPassword, // R-05
  resetPassword, // R-06
  home, // R-07
  runOverview, // R-08
  planRoute, // R-09
  pickup, // R-10
  pickupChecklist, // R-11
  readyToDeliver, // R-12
  activeDelivery, // R-13
  currentStop, // R-14
  proofOfDelivery, // R-15
  deliveryIssue, // R-16
  runComplete, // R-17
  assignments, // R-18
  assignmentDetail, // R-19
  profile, // R-20
  editProfile, // R-21
  vehicle, // R-22
  riderDocuments, // R-23
  settings, // R-24
  navigationSettings, // R-25
  notificationSettings, // R-26
  appearance, // R-27
  locationPermissions, // R-28
  security, // R-29
  helpSupport, // R-30
  privacyPolicy, // R-31
  termsOfService, // R-32
  about, // R-33
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

  final RRoute route;

  /// Canonical inventory id ("R-13") from the 33-screen master.
  final String id;
  final String title;
  final RRoute? parent;
  final NavTab? tab;
  final bool requiresEntityId;
}

const routeSpecs = <RRoute, RouteSpec>{
  RRoute.splash: RouteSpec(route: RRoute.splash, id: 'R-01', title: 'Splash'),

  RRoute.invitation: RouteSpec(route: RRoute.invitation, id: 'R-02', title: 'Accept invite'),
  RRoute.riderSetup: RouteSpec(route: RRoute.riderSetup, id: 'R-03', title: 'Rider setup', parent: RRoute.invitation),
  RRoute.signIn: RouteSpec(route: RRoute.signIn, id: 'R-04', title: 'Sign in'),
  RRoute.forgotPassword: RouteSpec(route: RRoute.forgotPassword, id: 'R-05', title: 'Forgot password', parent: RRoute.signIn),
  RRoute.resetPassword: RouteSpec(route: RRoute.resetPassword, id: 'R-06', title: 'Reset password', parent: RRoute.forgotPassword),

  RRoute.home: RouteSpec(route: RRoute.home, id: 'R-07', title: 'Home', tab: NavTab.home),

  RRoute.runOverview: RouteSpec(route: RRoute.runOverview, id: 'R-08', title: 'Run overview', parent: RRoute.home, tab: NavTab.route, requiresEntityId: true),
  RRoute.planRoute: RouteSpec(route: RRoute.planRoute, id: 'R-09', title: 'Plan route', parent: RRoute.runOverview, tab: NavTab.route, requiresEntityId: true),

  RRoute.pickup: RouteSpec(route: RRoute.pickup, id: 'R-10', title: 'Pickup', parent: RRoute.planRoute, tab: NavTab.route, requiresEntityId: true),
  RRoute.pickupChecklist: RouteSpec(route: RRoute.pickupChecklist, id: 'R-11', title: 'Pickup checklist', parent: RRoute.pickup, tab: NavTab.route, requiresEntityId: true),
  RRoute.readyToDeliver: RouteSpec(route: RRoute.readyToDeliver, id: 'R-12', title: 'Ready to deliver', parent: RRoute.pickupChecklist, tab: NavTab.route, requiresEntityId: true),

  RRoute.activeDelivery: RouteSpec(route: RRoute.activeDelivery, id: 'R-13', title: 'Active delivery', parent: RRoute.home, tab: NavTab.route, requiresEntityId: true),
  RRoute.currentStop: RouteSpec(route: RRoute.currentStop, id: 'R-14', title: 'Current stop', parent: RRoute.activeDelivery, tab: NavTab.route, requiresEntityId: true),
  RRoute.proofOfDelivery: RouteSpec(route: RRoute.proofOfDelivery, id: 'R-15', title: 'Proof of delivery', parent: RRoute.currentStop, tab: NavTab.route, requiresEntityId: true),
  RRoute.deliveryIssue: RouteSpec(route: RRoute.deliveryIssue, id: 'R-16', title: 'Delivery issue', parent: RRoute.currentStop, tab: NavTab.route, requiresEntityId: true),
  RRoute.runComplete: RouteSpec(route: RRoute.runComplete, id: 'R-17', title: 'Run complete', parent: RRoute.activeDelivery, tab: NavTab.route, requiresEntityId: true),

  RRoute.assignments: RouteSpec(route: RRoute.assignments, id: 'R-18', title: 'Assignments', tab: NavTab.assignments),
  RRoute.assignmentDetail: RouteSpec(route: RRoute.assignmentDetail, id: 'R-19', title: 'Assignment detail', parent: RRoute.assignments, tab: NavTab.assignments, requiresEntityId: true),

  RRoute.profile: RouteSpec(route: RRoute.profile, id: 'R-20', title: 'Profile', tab: NavTab.profile),
  RRoute.editProfile: RouteSpec(route: RRoute.editProfile, id: 'R-21', title: 'Edit profile', parent: RRoute.profile, tab: NavTab.profile),
  RRoute.vehicle: RouteSpec(route: RRoute.vehicle, id: 'R-22', title: 'Vehicle', parent: RRoute.profile, tab: NavTab.profile),
  RRoute.riderDocuments: RouteSpec(route: RRoute.riderDocuments, id: 'R-23', title: 'Rider documents', parent: RRoute.profile, tab: NavTab.profile),

  RRoute.settings: RouteSpec(route: RRoute.settings, id: 'R-24', title: 'Settings', parent: RRoute.profile, tab: NavTab.profile),
  RRoute.navigationSettings: RouteSpec(route: RRoute.navigationSettings, id: 'R-25', title: 'Navigation', parent: RRoute.settings, tab: NavTab.profile),
  RRoute.notificationSettings: RouteSpec(route: RRoute.notificationSettings, id: 'R-26', title: 'Notifications', parent: RRoute.settings, tab: NavTab.profile),
  RRoute.appearance: RouteSpec(route: RRoute.appearance, id: 'R-27', title: 'Appearance & language', parent: RRoute.settings, tab: NavTab.profile),
  RRoute.locationPermissions: RouteSpec(route: RRoute.locationPermissions, id: 'R-28', title: 'Location & permissions', parent: RRoute.settings, tab: NavTab.profile),

  RRoute.security: RouteSpec(route: RRoute.security, id: 'R-29', title: 'Security', parent: RRoute.profile, tab: NavTab.profile),

  RRoute.helpSupport: RouteSpec(route: RRoute.helpSupport, id: 'R-30', title: 'Help & support', parent: RRoute.profile, tab: NavTab.profile),

  RRoute.privacyPolicy: RouteSpec(route: RRoute.privacyPolicy, id: 'R-31', title: 'Privacy policy', parent: RRoute.about, tab: NavTab.profile),
  RRoute.termsOfService: RouteSpec(route: RRoute.termsOfService, id: 'R-32', title: 'Terms of service', parent: RRoute.about, tab: NavTab.profile),
  RRoute.about: RouteSpec(route: RRoute.about, id: 'R-33', title: 'About Cefflo', parent: RRoute.profile, tab: NavTab.profile),
};

/// A concrete place in the app: a route plus the entity it is bound to
/// (an order id for delivery-flow screens, a session id for run screens).
class RiderLocation {
  const RiderLocation(this.route, {this.entityId});
  final RRoute route;
  final String? entityId;

  RouteSpec get spec => routeSpecs[route]!;

  @override
  bool operator ==(Object other) =>
      other is RiderLocation && other.route == route && other.entityId == entityId;

  @override
  int get hashCode => Object.hash(route, entityId);

  @override
  String toString() => entityId == null ? route.name : '${route.name}:$entityId';
}
