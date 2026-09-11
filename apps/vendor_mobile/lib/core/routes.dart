/// Typed route graph.
///
/// Audit fix 1: every route declares its real parent, so Back returns to the
/// parent instead of always landing on Today, and the bottom nav highlights
/// the owning tab on subpages.
/// Audit fix 2: navigation carries a typed entity id, so a detail screen is
/// bound to the record that was actually selected.
library;

enum NavTab { today, orders, zones, riders, menu }

enum VRoute {
  splash,
  signIn,
  signUp,
  forgotPassword,
  resetPassword,
  welcomeSetup,
  setupBusinessInfo,
  setupAddress,
  setupServiceArea,
  setupComplete,
  today,
  orders,
  orderDetail,
  newOrder,
  editOrder,
  zones,
  zoneDetail,
  reviewDispatch,
  runDetail,
  riders,
  riderDetail,
  riderRegistrationLink,
  team,
  teamMemberDetail,
  helperRegistrationLink,
  serviceArea,
  coverageEdit,
  zoneConfiguration,
  createZone,
  editZone,
  storefront,
  storefrontPreview,
  branding,
  products,
  productDetail,
  addProduct,
  businessProfile,
  businessInformation,
  businessAddress,
  businessHours,
  deliverySettings,
  profile,
  editProfile,
  security,
  changePassword,
  settings,
  notificationSettings,
  language,
  appearance,
  subscription,
  choosePlan,
  subscriptionCheckout,
  paymentSuccess,
  subscriptionDetails,
  helpSupport,
  faq,
  contactSupport,
  privacyPolicy,
  termsOfService,
  about,
  // Additional routes required by the master beyond the 60 inventory.
  notificationInbox,
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

  final VRoute route;

  /// Canonical inventory id ("V-13"), or "X-nn" for routes that are additional
  /// surfaces rather than part of the 60-screen count.
  final String id;
  final String title;
  final VRoute? parent;
  final NavTab? tab;
  final bool requiresEntityId;
}

const routeSpecs = <VRoute, RouteSpec>{
  VRoute.splash: RouteSpec(route: VRoute.splash, id: 'V-01', title: 'Splash'),
  VRoute.signIn: RouteSpec(route: VRoute.signIn, id: 'V-02', title: 'Sign in'),
  VRoute.signUp: RouteSpec(route: VRoute.signUp, id: 'V-03', title: 'Create account', parent: VRoute.signIn),
  VRoute.forgotPassword: RouteSpec(route: VRoute.forgotPassword, id: 'V-04', title: 'Account recovery', parent: VRoute.signIn),
  VRoute.resetPassword: RouteSpec(route: VRoute.resetPassword, id: 'V-05', title: 'Reset password', parent: VRoute.forgotPassword),
  VRoute.welcomeSetup: RouteSpec(route: VRoute.welcomeSetup, id: 'V-06', title: 'Welcome'),
  VRoute.setupBusinessInfo: RouteSpec(route: VRoute.setupBusinessInfo, id: 'V-07', title: 'Business information', parent: VRoute.welcomeSetup),
  VRoute.setupAddress: RouteSpec(route: VRoute.setupAddress, id: 'V-08', title: 'Pickup location', parent: VRoute.setupBusinessInfo),
  VRoute.setupServiceArea: RouteSpec(route: VRoute.setupServiceArea, id: 'V-09', title: 'Service area', parent: VRoute.setupAddress),
  VRoute.setupComplete: RouteSpec(route: VRoute.setupComplete, id: 'V-10', title: 'Setup complete', parent: VRoute.setupServiceArea),

  VRoute.today: RouteSpec(route: VRoute.today, id: 'V-11', title: 'Today', tab: NavTab.today),
  VRoute.orders: RouteSpec(route: VRoute.orders, id: 'V-12', title: 'Orders', tab: NavTab.orders),
  VRoute.orderDetail: RouteSpec(route: VRoute.orderDetail, id: 'V-13', title: 'Order detail', parent: VRoute.orders, tab: NavTab.orders, requiresEntityId: true),
  VRoute.newOrder: RouteSpec(route: VRoute.newOrder, id: 'V-14', title: 'New order', parent: VRoute.orders, tab: NavTab.orders),
  VRoute.editOrder: RouteSpec(route: VRoute.editOrder, id: 'V-15', title: 'Edit order', parent: VRoute.orderDetail, tab: NavTab.orders, requiresEntityId: true),

  VRoute.zones: RouteSpec(route: VRoute.zones, id: 'V-16', title: 'Zones', tab: NavTab.zones),
  VRoute.zoneDetail: RouteSpec(route: VRoute.zoneDetail, id: 'V-17', title: 'Delivery plan', parent: VRoute.zones, tab: NavTab.zones, requiresEntityId: true),
  VRoute.reviewDispatch: RouteSpec(route: VRoute.reviewDispatch, id: 'V-18', title: 'Review & dispatch', parent: VRoute.zoneDetail, tab: NavTab.zones, requiresEntityId: true),
  VRoute.runDetail: RouteSpec(route: VRoute.runDetail, id: 'V-19', title: 'Delivery progress', parent: VRoute.zones, tab: NavTab.zones, requiresEntityId: true),

  VRoute.riders: RouteSpec(route: VRoute.riders, id: 'V-20', title: 'Riders', tab: NavTab.riders),
  VRoute.riderDetail: RouteSpec(route: VRoute.riderDetail, id: 'V-21', title: 'Rider detail', parent: VRoute.riders, tab: NavTab.riders, requiresEntityId: true),
  VRoute.riderRegistrationLink: RouteSpec(route: VRoute.riderRegistrationLink, id: 'V-22', title: 'Rider registration link', parent: VRoute.riders, tab: NavTab.riders),

  VRoute.team: RouteSpec(route: VRoute.team, id: 'V-23', title: 'Team', parent: VRoute.settings, tab: NavTab.menu),
  VRoute.teamMemberDetail: RouteSpec(route: VRoute.teamMemberDetail, id: 'V-24', title: 'Team member', parent: VRoute.team, tab: NavTab.menu, requiresEntityId: true),
  VRoute.helperRegistrationLink: RouteSpec(route: VRoute.helperRegistrationLink, id: 'V-25', title: 'Helper registration link', parent: VRoute.team, tab: NavTab.menu),

  VRoute.serviceArea: RouteSpec(route: VRoute.serviceArea, id: 'V-26', title: 'Service area', parent: VRoute.settings, tab: NavTab.menu),
  VRoute.coverageEdit: RouteSpec(route: VRoute.coverageEdit, id: 'V-27', title: 'Coverage', parent: VRoute.serviceArea, tab: NavTab.menu),
  VRoute.zoneConfiguration: RouteSpec(route: VRoute.zoneConfiguration, id: 'V-28', title: 'Zone configuration', parent: VRoute.serviceArea, tab: NavTab.menu),
  VRoute.createZone: RouteSpec(route: VRoute.createZone, id: 'V-29', title: 'Create zone', parent: VRoute.zoneConfiguration, tab: NavTab.menu),
  VRoute.editZone: RouteSpec(route: VRoute.editZone, id: 'V-30', title: 'Edit zone', parent: VRoute.zoneConfiguration, tab: NavTab.menu, requiresEntityId: true),

  VRoute.storefront: RouteSpec(route: VRoute.storefront, id: 'V-31', title: 'Storefront', parent: VRoute.settings, tab: NavTab.menu),
  VRoute.storefrontPreview: RouteSpec(route: VRoute.storefrontPreview, id: 'V-32', title: 'Storefront preview', parent: VRoute.storefront, tab: NavTab.menu),
  VRoute.branding: RouteSpec(route: VRoute.branding, id: 'V-33', title: 'Branding', parent: VRoute.storefront, tab: NavTab.menu),
  VRoute.products: RouteSpec(route: VRoute.products, id: 'V-34', title: 'Products', parent: VRoute.storefront, tab: NavTab.menu),
  VRoute.productDetail: RouteSpec(route: VRoute.productDetail, id: 'V-35', title: 'Edit product', parent: VRoute.products, tab: NavTab.menu, requiresEntityId: true),
  VRoute.addProduct: RouteSpec(route: VRoute.addProduct, id: 'V-36', title: 'Add product', parent: VRoute.products, tab: NavTab.menu),

  VRoute.businessProfile: RouteSpec(route: VRoute.businessProfile, id: 'V-37', title: 'Business profile', parent: VRoute.settings, tab: NavTab.menu),
  VRoute.businessInformation: RouteSpec(route: VRoute.businessInformation, id: 'V-38', title: 'Business information', parent: VRoute.businessProfile, tab: NavTab.menu),
  VRoute.businessAddress: RouteSpec(route: VRoute.businessAddress, id: 'V-39', title: 'Business address', parent: VRoute.businessProfile, tab: NavTab.menu),
  VRoute.businessHours: RouteSpec(route: VRoute.businessHours, id: 'V-40', title: 'Business hours', parent: VRoute.businessProfile, tab: NavTab.menu),
  VRoute.deliverySettings: RouteSpec(route: VRoute.deliverySettings, id: 'V-41', title: 'Delivery settings', parent: VRoute.businessProfile, tab: NavTab.menu),

  VRoute.profile: RouteSpec(route: VRoute.profile, id: 'V-42', title: 'Profile', parent: VRoute.settings, tab: NavTab.menu),
  VRoute.editProfile: RouteSpec(route: VRoute.editProfile, id: 'V-43', title: 'Edit profile', parent: VRoute.profile, tab: NavTab.menu),
  VRoute.security: RouteSpec(route: VRoute.security, id: 'V-44', title: 'Security', parent: VRoute.profile, tab: NavTab.menu),
  VRoute.changePassword: RouteSpec(route: VRoute.changePassword, id: 'V-45', title: 'Change password', parent: VRoute.security, tab: NavTab.menu),
  VRoute.settings: RouteSpec(route: VRoute.settings, id: 'V-46', title: 'Menu', tab: NavTab.menu),
  VRoute.notificationSettings: RouteSpec(route: VRoute.notificationSettings, id: 'V-47', title: 'Notification settings', parent: VRoute.settings, tab: NavTab.menu),
  VRoute.language: RouteSpec(route: VRoute.language, id: 'V-48', title: 'Language', parent: VRoute.settings, tab: NavTab.menu),
  VRoute.appearance: RouteSpec(route: VRoute.appearance, id: 'V-49', title: 'Appearance', parent: VRoute.settings, tab: NavTab.menu),

  VRoute.subscription: RouteSpec(route: VRoute.subscription, id: 'V-50', title: 'Subscription', parent: VRoute.settings, tab: NavTab.menu),
  VRoute.choosePlan: RouteSpec(route: VRoute.choosePlan, id: 'V-51', title: 'Choose plan', parent: VRoute.subscription, tab: NavTab.menu),
  VRoute.subscriptionCheckout: RouteSpec(route: VRoute.subscriptionCheckout, id: 'V-52', title: 'Checkout', parent: VRoute.choosePlan, tab: NavTab.menu),
  VRoute.paymentSuccess: RouteSpec(route: VRoute.paymentSuccess, id: 'V-53', title: 'Confirmation', parent: VRoute.subscriptionCheckout, tab: NavTab.menu),
  VRoute.subscriptionDetails: RouteSpec(route: VRoute.subscriptionDetails, id: 'V-54', title: 'Subscription details', parent: VRoute.subscription, tab: NavTab.menu),

  VRoute.helpSupport: RouteSpec(route: VRoute.helpSupport, id: 'V-55', title: 'Help & support', parent: VRoute.settings, tab: NavTab.menu),
  VRoute.faq: RouteSpec(route: VRoute.faq, id: 'V-56', title: 'Help centre', parent: VRoute.helpSupport, tab: NavTab.menu),
  VRoute.contactSupport: RouteSpec(route: VRoute.contactSupport, id: 'V-57', title: 'Contact support', parent: VRoute.helpSupport, tab: NavTab.menu),
  VRoute.privacyPolicy: RouteSpec(route: VRoute.privacyPolicy, id: 'V-58', title: 'Privacy policy', parent: VRoute.about, tab: NavTab.menu),
  VRoute.termsOfService: RouteSpec(route: VRoute.termsOfService, id: 'V-59', title: 'Terms of service', parent: VRoute.about, tab: NavTab.menu),
  VRoute.about: RouteSpec(route: VRoute.about, id: 'V-60', title: 'About Cefflo', parent: VRoute.settings, tab: NavTab.menu),

  VRoute.notificationInbox: RouteSpec(route: VRoute.notificationInbox, id: 'X-01', title: 'Notifications', parent: VRoute.today, tab: NavTab.today),
};

/// A concrete place in the app: a route plus the entity it is bound to.
class VendorLocation {
  const VendorLocation(this.route, {this.entityId});
  final VRoute route;
  final String? entityId;

  RouteSpec get spec => routeSpecs[route]!;

  @override
  bool operator ==(Object other) =>
      other is VendorLocation && other.route == route && other.entityId == entityId;

  @override
  int get hashCode => Object.hash(route, entityId);

  @override
  String toString() => entityId == null ? route.name : '${route.name}:$entityId';
}
