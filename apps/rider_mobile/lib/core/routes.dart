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
  invitationLanding, // D09
  // --- Onboarding / business join (D10–D18) ----------------------------
  acceptInvitation, // D10
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

const routeSpecs = <DRoute, RouteSpec>{
  DRoute.splash: RouteSpec(route: DRoute.splash, id: 'D01', title: 'Splash'),
  DRoute.signIn: RouteSpec(route: DRoute.signIn, id: 'D02', title: 'Sign In'),
  DRoute.emailSignIn: RouteSpec(route: DRoute.emailSignIn, id: 'D03', title: 'Sign In with Email', parent: DRoute.signIn),
  DRoute.createAccount: RouteSpec(route: DRoute.createAccount, id: 'D04', title: 'Create your account', parent: DRoute.signIn),
  DRoute.forgotPassword: RouteSpec(route: DRoute.forgotPassword, id: 'D05', title: 'Forgot Password?', parent: DRoute.emailSignIn),
  DRoute.checkEmail: RouteSpec(route: DRoute.checkEmail, id: 'D06', title: 'Check your email', parent: DRoute.forgotPassword),
  DRoute.setNewPassword: RouteSpec(route: DRoute.setNewPassword, id: 'D07', title: 'Set a new password', parent: DRoute.checkEmail),
  DRoute.passwordUpdated: RouteSpec(route: DRoute.passwordUpdated, id: 'D08', title: 'Password Updated!', parent: DRoute.setNewPassword),
  DRoute.invitationLanding: RouteSpec(route: DRoute.invitationLanding, id: 'D09', title: 'Invitation Landing'),

  DRoute.acceptInvitation: RouteSpec(route: DRoute.acceptInvitation, id: 'D10', title: 'Accept Invitation', parent: DRoute.invitationLanding),
  DRoute.noBusinessConnectedHome: RouteSpec(route: DRoute.noBusinessConnectedHome, id: 'D11', title: 'No Business Connected', tab: NavTab.home),
  DRoute.driverDetails: RouteSpec(route: DRoute.driverDetails, id: 'D12', title: 'Driver Details', parent: DRoute.acceptInvitation),
  DRoute.personalDetails: RouteSpec(route: DRoute.personalDetails, id: 'D12.1', title: 'Personal Details', parent: DRoute.driverDetails),
  DRoute.vehicleAndDocuments: RouteSpec(route: DRoute.vehicleAndDocuments, id: 'D12.2', title: 'Vehicle & Documents', parent: DRoute.personalDetails),
  DRoute.pendingReview: RouteSpec(route: DRoute.pendingReview, id: 'D14.1', title: 'Application Under Review', tab: NavTab.home),
  DRoute.approved: RouteSpec(route: DRoute.approved, id: 'D14.2', title: 'You’re Approved!', tab: NavTab.home),
  DRoute.readyToGo: RouteSpec(route: DRoute.readyToGo, id: 'D14.3', title: 'Ready to Go', tab: NavTab.home),
  DRoute.noBusinessConnected: RouteSpec(route: DRoute.noBusinessConnected, id: 'D16', title: 'No Business Connected', tab: NavTab.home),
  DRoute.joinBusiness: RouteSpec(route: DRoute.joinBusiness, id: 'D17', title: 'Join Business', parent: DRoute.noBusinessConnected, tab: NavTab.home),
  DRoute.businessJoined: RouteSpec(route: DRoute.businessJoined, id: 'D18', title: 'Business Joined', parent: DRoute.joinBusiness, tab: NavTab.home),

  DRoute.today: RouteSpec(route: DRoute.today, id: 'D19', title: 'Today', tab: NavTab.home),
  DRoute.runDetails: RouteSpec(route: DRoute.runDetails, id: 'D20', title: 'Run Details', parent: DRoute.today, tab: NavTab.runs, requiresEntityId: true),
  DRoute.stopList: RouteSpec(route: DRoute.stopList, id: 'D21', title: 'Stop List', parent: DRoute.runDetails, tab: NavTab.runs, requiresEntityId: true),
  DRoute.navigationToStop: RouteSpec(route: DRoute.navigationToStop, id: 'D22', title: 'Navigation to Stop', parent: DRoute.stopList, tab: NavTab.runs, requiresEntityId: true),
  DRoute.confirmDelivery: RouteSpec(route: DRoute.confirmDelivery, id: 'D23', title: 'Confirm Delivery', parent: DRoute.navigationToStop, tab: NavTab.runs, requiresEntityId: true),
  DRoute.deliveryIssue: RouteSpec(route: DRoute.deliveryIssue, id: 'D28', title: 'Delivery Issue', parent: DRoute.confirmDelivery, tab: NavTab.runs, requiresEntityId: true),
  DRoute.reportIssue: RouteSpec(route: DRoute.reportIssue, id: 'D29', title: 'Report Issue', parent: DRoute.deliveryIssue, tab: NavTab.runs, requiresEntityId: true),
  DRoute.runCompleted: RouteSpec(route: DRoute.runCompleted, id: 'D30', title: 'Run Completed', parent: DRoute.today, tab: NavTab.runs, requiresEntityId: true),

  DRoute.deliveryHistory: RouteSpec(route: DRoute.deliveryHistory, id: 'D31', title: 'Delivery History', tab: NavTab.history),
  DRoute.historyDetail: RouteSpec(route: DRoute.historyDetail, id: 'D32', title: 'History Detail', parent: DRoute.deliveryHistory, tab: NavTab.history, requiresEntityId: true),
  DRoute.notifications: RouteSpec(route: DRoute.notifications, id: 'D33', title: 'Notifications', parent: DRoute.deliveryHistory, tab: NavTab.history),

  DRoute.profile: RouteSpec(route: DRoute.profile, id: 'D34', title: 'Profile', tab: NavTab.profile),
  DRoute.editProfile: RouteSpec(route: DRoute.editProfile, id: 'D35', title: 'Edit Profile', parent: DRoute.profile, tab: NavTab.profile),
  DRoute.vehicleDetails: RouteSpec(route: DRoute.vehicleDetails, id: 'D36', title: 'Vehicle Details', parent: DRoute.profile, tab: NavTab.profile),
  DRoute.documents: RouteSpec(route: DRoute.documents, id: 'D37', title: 'Documents', parent: DRoute.profile, tab: NavTab.profile),
  DRoute.settings: RouteSpec(route: DRoute.settings, id: 'D38', title: 'Settings', parent: DRoute.profile, tab: NavTab.profile),

  DRoute.helpSupport: RouteSpec(route: DRoute.helpSupport, id: 'D40', title: 'Help & Support', parent: DRoute.profile, tab: NavTab.profile),
  DRoute.vendorSupport: RouteSpec(route: DRoute.vendorSupport, id: 'D40-B', title: 'Vendor Support', parent: DRoute.helpSupport, tab: NavTab.profile),
  DRoute.submitTicket: RouteSpec(route: DRoute.submitTicket, id: 'D40-C', title: 'Submit Ticket', parent: DRoute.helpSupport, tab: NavTab.profile),
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
      other is RiderLocation && other.route == route && other.entityId == entityId;

  @override
  int get hashCode => Object.hash(route, entityId);

  @override
  String toString() => entityId == null ? route.name : '${route.name}:$entityId';
}

/// Lookup by the reference caption id ("D21.1"), used by the prototype's
/// deep-link preview path so any screen can be screenshotted directly.
DRoute? routeForReferenceId(String id) {
  final wanted = id.toUpperCase();
  for (final spec in routeSpecs.values) {
    if (spec.id.toUpperCase() == wanted) return spec.route;
  }
  return null;
}
