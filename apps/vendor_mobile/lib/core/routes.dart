/// Typed route graph.
///
/// Audit fix 1: every route declares its real parent, so Back returns to the
/// parent instead of always landing on Today, and the bottom nav highlights
/// the owning tab on subpages.
/// Audit fix 2: navigation carries a typed entity id, so a detail screen is
/// bound to the record that was actually selected.
library;

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// The five primary destinations (bottom navigation, D-51). More hosts the
/// Settings hub, so every Settings route belongs to More.
enum NavTab { today, orders, zones, riders, more }

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
  newOrderManual,
  importOrders,
  editOrder,
  zones,
  zoneDetail,
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
  storefront,
  storefrontPreview,
  storefrontTemplatePreview,
  branding,
  products,
  customers,
  customerDetail,
  productDetail,
  addProduct,
  businessProfile,
  businessInformation,
  businessAddress,
  businessHours,
  deliverySettings,
  editProfile,
  security,
  changePassword,
  settings,
  notificationSettings,
  appearance,
  subscription,
  choosePlan,
  reviewPayment,
  billingHistory,
  helpSupport,
  faq,
  contactSupport,
  privacyPolicy,
  termsOfService,
  about,
  integrations,
  // Additional routes required by the master beyond the 60 inventory.
  notificationInbox,
  hiring,
  hiringPost,
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

Map<VRoute, RouteSpec> get routeSpecs => <VRoute, RouteSpec>{
  VRoute.splash: RouteSpec(route: VRoute.splash, id: 'V-01', title: L.splash),
  VRoute.signIn: RouteSpec(route: VRoute.signIn, id: 'V-02', title: L.sign),
  VRoute.signUp: RouteSpec(
    route: VRoute.signUp,
    id: 'V-03',
    title: L.createAccount,
    parent: VRoute.signIn,
  ),
  VRoute.forgotPassword: RouteSpec(
    route: VRoute.forgotPassword,
    id: 'V-04',
    title: L.accountRecovery,
    parent: VRoute.signIn,
  ),
  VRoute.resetPassword: RouteSpec(
    route: VRoute.resetPassword,
    id: 'V-05',
    title: L.resetPassword,
    parent: VRoute.forgotPassword,
  ),
  VRoute.welcomeSetup: RouteSpec(
    route: VRoute.welcomeSetup,
    id: 'V-06',
    title: L.welcome,
  ),
  VRoute.setupBusinessInfo: RouteSpec(
    route: VRoute.setupBusinessInfo,
    id: 'V-07',
    title: L.businessInformation,
    parent: VRoute.welcomeSetup,
  ),
  VRoute.setupAddress: RouteSpec(
    route: VRoute.setupAddress,
    id: 'V-08',
    title: L.pickupLocation,
    parent: VRoute.setupBusinessInfo,
  ),
  VRoute.setupServiceArea: RouteSpec(
    route: VRoute.setupServiceArea,
    id: 'V-09',
    title: L.serviceArea,
    parent: VRoute.setupAddress,
  ),
  VRoute.setupComplete: RouteSpec(
    route: VRoute.setupComplete,
    id: 'V-10',
    title: L.setupComplete,
    parent: VRoute.setupServiceArea,
  ),

  VRoute.today: RouteSpec(
    route: VRoute.today,
    id: 'V-11',
    title: L.today,
    tab: NavTab.today,
  ),
  VRoute.orders: RouteSpec(
    route: VRoute.orders,
    id: 'V-12',
    title: L.orders,
    tab: NavTab.orders,
  ),
  VRoute.orderDetail: RouteSpec(
    route: VRoute.orderDetail,
    id: 'V-13',
    title: L.orderDetail,
    parent: VRoute.orders,
    tab: NavTab.orders,
    requiresEntityId: true,
  ),
  VRoute.newOrder: RouteSpec(
    route: VRoute.newOrder,
    id: 'V-14',
    title: L.newOrder,
    parent: VRoute.orders,
    tab: NavTab.orders,
  ),
  VRoute.newOrderManual: RouteSpec(
    route: VRoute.newOrderManual,
    id: 'X-03',
    title: L.newOrder,
    parent: VRoute.newOrder,
    tab: NavTab.orders,
  ),
  VRoute.importOrders: RouteSpec(
    route: VRoute.importOrders,
    id: 'X-04',
    title: L.importOrders,
    parent: VRoute.newOrder,
    tab: NavTab.orders,
  ),
  VRoute.editOrder: RouteSpec(
    route: VRoute.editOrder,
    id: 'V-15',
    title: L.editOrder,
    parent: VRoute.orderDetail,
    tab: NavTab.orders,
    requiresEntityId: true,
  ),

  VRoute.zones: RouteSpec(
    route: VRoute.zones,
    id: 'V-16',
    title: L.zones,
    tab: NavTab.zones,
  ),
  // V-17 is the one operational screen for a zone (D-49): its header shows
  // the zone's own name; review, dispatch and edit-zone screens were
  // consolidated into it (V-18 / V-30 are audit markers only).
  VRoute.zoneDetail: RouteSpec(
    route: VRoute.zoneDetail,
    id: 'V-17',
    title: L.zone,
    parent: VRoute.zones,
    tab: NavTab.zones,
    requiresEntityId: true,
  ),
  VRoute.runDetail: RouteSpec(
    route: VRoute.runDetail,
    id: 'V-19',
    title: L.deliveryProgress,
    parent: VRoute.zones,
    tab: NavTab.zones,
    requiresEntityId: true,
  ),

  VRoute.riders: RouteSpec(
    route: VRoute.riders,
    id: 'V-20',
    title: L.riders,
    tab: NavTab.riders,
  ),
  VRoute.riderDetail: RouteSpec(
    route: VRoute.riderDetail,
    id: 'V-21',
    title: L.riderDetail,
    parent: VRoute.riders,
    tab: NavTab.riders,
    requiresEntityId: true,
  ),
  VRoute.riderRegistrationLink: RouteSpec(
    route: VRoute.riderRegistrationLink,
    id: 'V-22',
    title: L.riderRegistrationLink,
    parent: VRoute.riders,
    tab: NavTab.riders,
  ),

  VRoute.team: RouteSpec(
    route: VRoute.team,
    id: 'V-23',
    title: L.team,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.teamMemberDetail: RouteSpec(
    route: VRoute.teamMemberDetail,
    id: 'V-24',
    title: L.teamMember,
    parent: VRoute.team,
    tab: NavTab.more,
    requiresEntityId: true,
  ),
  VRoute.helperRegistrationLink: RouteSpec(
    route: VRoute.helperRegistrationLink,
    id: 'V-25',
    title: L.teamMemberRegistrationLink,
    parent: VRoute.team,
    tab: NavTab.more,
  ),

  VRoute.serviceArea: RouteSpec(
    route: VRoute.serviceArea,
    id: 'V-26',
    title: L.serviceArea,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.coverageEdit: RouteSpec(
    route: VRoute.coverageEdit,
    id: 'V-27',
    title: L.coverage,
    parent: VRoute.serviceArea,
    tab: NavTab.more,
  ),
  VRoute.zoneConfiguration: RouteSpec(
    route: VRoute.zoneConfiguration,
    id: 'V-28',
    title: L.zoneConfiguration,
    parent: VRoute.serviceArea,
    tab: NavTab.more,
  ),
  VRoute.createZone: RouteSpec(
    route: VRoute.createZone,
    id: 'V-29',
    title: L.createZone,
    parent: VRoute.zoneConfiguration,
    tab: NavTab.more,
  ),

  VRoute.storefront: RouteSpec(
    route: VRoute.storefront,
    id: 'V-31',
    title: L.storefront,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.storefrontPreview: RouteSpec(
    route: VRoute.storefrontPreview,
    id: 'V-32',
    title: L.viewStorefront,
    parent: VRoute.storefront,
    tab: NavTab.more,
  ),
  VRoute.storefrontTemplatePreview: RouteSpec(
    route: VRoute.storefrontTemplatePreview,
    id: 'X-02',
    title: L.templatePreview,
    parent: VRoute.storefront,
    tab: NavTab.more,
    requiresEntityId: true,
  ),
  VRoute.branding: RouteSpec(
    route: VRoute.branding,
    id: 'V-33',
    title: L.customize,
    parent: VRoute.storefront,
    tab: NavTab.more,
  ),
  VRoute.products: RouteSpec(
    route: VRoute.products,
    id: 'V-34',
    title: L.products,
    parent: VRoute.storefront,
    tab: NavTab.more,
  ),
  VRoute.customers: RouteSpec(
    route: VRoute.customers,
    id: 'X-05',
    title: L.customers,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.customerDetail: RouteSpec(
    route: VRoute.customerDetail,
    id: 'X-06',
    title: L.customer,
    parent: VRoute.customers,
    tab: NavTab.more,
    requiresEntityId: true,
  ),
  VRoute.productDetail: RouteSpec(
    route: VRoute.productDetail,
    id: 'V-35',
    title: L.editProduct,
    parent: VRoute.products,
    tab: NavTab.more,
    requiresEntityId: true,
  ),
  VRoute.addProduct: RouteSpec(
    route: VRoute.addProduct,
    id: 'V-36',
    title: L.addProduct,
    parent: VRoute.products,
    tab: NavTab.more,
  ),

  VRoute.businessProfile: RouteSpec(
    route: VRoute.businessProfile,
    id: 'V-37',
    title: L.businessProfile,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.businessInformation: RouteSpec(
    route: VRoute.businessInformation,
    id: 'V-38',
    title: L.businessInformation,
    parent: VRoute.businessProfile,
    tab: NavTab.more,
  ),
  VRoute.businessAddress: RouteSpec(
    route: VRoute.businessAddress,
    id: 'V-39',
    title: L.businessAddress,
    parent: VRoute.businessProfile,
    tab: NavTab.more,
  ),
  VRoute.businessHours: RouteSpec(
    route: VRoute.businessHours,
    id: 'V-40',
    title: L.businessHours,
    parent: VRoute.businessProfile,
    tab: NavTab.more,
  ),
  VRoute.deliverySettings: RouteSpec(
    route: VRoute.deliverySettings,
    id: 'V-41',
    title: L.deliverySettings,
    parent: VRoute.businessProfile,
    tab: NavTab.more,
  ),

  // V-42 Profile was a second directory of the Account settings (D-46): its
  // destinations live once, in Settings. The inventory position is kept as
  // an audit marker only.
  VRoute.editProfile: RouteSpec(
    route: VRoute.editProfile,
    id: 'V-43',
    title: L.profile,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.security: RouteSpec(
    route: VRoute.security,
    id: 'V-44',
    title: L.security,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.changePassword: RouteSpec(
    route: VRoute.changePassword,
    id: 'V-45',
    title: L.changePassword,
    parent: VRoute.security,
    tab: NavTab.more,
  ),
  VRoute.settings: RouteSpec(
    route: VRoute.settings,
    id: 'V-46',
    title: L.more,
    tab: NavTab.more,
  ),
  VRoute.notificationSettings: RouteSpec(
    route: VRoute.notificationSettings,
    id: 'V-47',
    title: L.notificationPreferences,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.appearance: RouteSpec(
    route: VRoute.appearance,
    id: 'V-49',
    title: L.appearance,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),

  // Subscription (D-54; previously on HOLD). V-53 Payment Success is the
  // centred success modal, not a route.
  VRoute.subscription: RouteSpec(
    route: VRoute.subscription,
    id: 'V-50',
    title: L.subscription,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.choosePlan: RouteSpec(
    route: VRoute.choosePlan,
    id: 'V-51',
    title: L.choosePlan,
    parent: VRoute.subscription,
    tab: NavTab.more,
  ),
  VRoute.reviewPayment: RouteSpec(
    route: VRoute.reviewPayment,
    id: 'V-52',
    title: L.reviewPayment,
    parent: VRoute.choosePlan,
    tab: NavTab.more,
    requiresEntityId: true,
  ),
  VRoute.billingHistory: RouteSpec(
    route: VRoute.billingHistory,
    id: 'V-54',
    title: L.billingHistory,
    parent: VRoute.subscription,
    tab: NavTab.more,
  ),

  VRoute.helpSupport: RouteSpec(
    route: VRoute.helpSupport,
    id: 'V-55',
    title: L.helpSupport,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.faq: RouteSpec(
    route: VRoute.faq,
    id: 'V-56',
    title: L.helpCentre,
    parent: VRoute.helpSupport,
    tab: NavTab.more,
  ),
  VRoute.contactSupport: RouteSpec(
    route: VRoute.contactSupport,
    id: 'V-57',
    title: L.contactSupport,
    parent: VRoute.helpSupport,
    tab: NavTab.more,
  ),
  VRoute.privacyPolicy: RouteSpec(
    route: VRoute.privacyPolicy,
    id: 'V-58',
    title: L.privacyPolicy,
    parent: VRoute.about,
    tab: NavTab.more,
  ),
  VRoute.termsOfService: RouteSpec(
    route: VRoute.termsOfService,
    id: 'V-59',
    title: L.termsService,
    parent: VRoute.about,
    tab: NavTab.more,
  ),
  VRoute.integrations: RouteSpec(
    route: VRoute.integrations,
    id: 'X-INT',
    title: L.integrations,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),
  VRoute.about: RouteSpec(
    route: VRoute.about,
    id: 'V-60',
    title: L.aboutCefflo,
    parent: VRoute.settings,
    tab: NavTab.more,
  ),

  VRoute.hiring: RouteSpec(
    route: VRoute.hiring,
    id: 'X-02',
    title: L.hiring,
    parent: VRoute.team,
    tab: NavTab.more,
  ),
  VRoute.hiringPost: RouteSpec(
    route: VRoute.hiringPost,
    id: 'X-03',
    title: L.hrPostTitle,
    parent: VRoute.riders,
    tab: NavTab.riders,
    requiresEntityId: true,
  ),
  VRoute.notificationInbox: RouteSpec(
    route: VRoute.notificationInbox,
    id: 'X-01',
    title: L.notifications,
    parent: VRoute.today,
    tab: NavTab.today,
  ),
};

/// A concrete place in the app: a route plus the entity it is bound to.
class VendorLocation {
  const VendorLocation(this.route, {this.entityId});
  final VRoute route;
  final String? entityId;

  RouteSpec get spec => routeSpecs[route]!;

  @override
  bool operator ==(Object other) =>
      other is VendorLocation &&
      other.route == route &&
      other.entityId == entityId;

  @override
  int get hashCode => Object.hash(route, entityId);

  @override
  String toString() =>
      entityId == null ? route.name : '${route.name}:$entityId';
}
