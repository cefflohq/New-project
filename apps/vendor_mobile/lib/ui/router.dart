import 'package:flutter/material.dart';

import '../core/routes.dart';
import 'screens/directory.dart';
import 'screens/operations.dart';
import 'screens/planning.dart';
import 'screens/prototype.dart';
import 'screens/subscription.dart';
import 'screens/storefront/storefront_customize.dart';
import 'screens/storefront/storefront_screens.dart';

/// Maps a typed [VendorLocation] to its screen.
///
/// Routes with a dedicated implementation are mapped directly. Remaining
/// inventory routes use the consolidated prototype implementation for their
/// bounded settings, help, and supporting surfaces.
Widget buildScreen(BuildContext context, VendorLocation loc) {
  final id = loc.entityId;
  return switch (loc.route) {
    VRoute.today => const TodayScreen(),
    VRoute.welcomeSetup => const WelcomeSetupScreen(),
    VRoute.setupBusinessInfo => const SetupBusinessInfoScreen(),
    VRoute.setupAddress => const SetupAddressScreen(),
    VRoute.setupServiceArea => const SetupServiceAreaScreen(),
    VRoute.setupComplete => const SetupCompleteScreen(),
    VRoute.orders => const OrdersScreen(),
    VRoute.orderDetail => OrderDetailScreen(orderId: id!),
    VRoute.newOrder => const NewOrderEntryScreen(),
    VRoute.newOrderManual => const OrderFormScreen(),
    VRoute.importOrders => const ImportOrdersScreen(),
    VRoute.editOrder => OrderFormScreen(orderId: id!),
    VRoute.zones => const ZonesScreen(),
    VRoute.zoneDetail => ZoneDetailScreen(zoneId: id!),
    VRoute.zoneConfiguration => const ZoneConfigurationScreen(),
    VRoute.createZone => const CreateZoneScreen(),
    VRoute.runDetail => RunDetailScreen(runId: id ?? 'RUN-0182'),
    VRoute.serviceArea => const ServiceAreaScreen(),
    VRoute.coverageEdit => const ServiceAreaScreen(),
    VRoute.riders => const RidersScreen(),
    VRoute.riderDetail => RiderDetailScreen(riderId: id!),
    VRoute.team => const TeamScreen(),
    VRoute.teamMemberDetail => TeamMemberDetailScreen(memberId: id!),
    VRoute.products => const ProductsScreen(),
    VRoute.productDetail => ProductFormScreen(productId: id!),
    VRoute.addProduct => const ProductFormScreen(),
    VRoute.customers => const CustomersScreen(),
    VRoute.customerDetail => CustomerDetailScreen(customerName: id!),
    VRoute.settings => const SettingsScreen(),
    VRoute.subscription => const SubscriptionScreen(),
    VRoute.choosePlan => const ChoosePlanScreen(),
    VRoute.reviewPayment => ReviewPaymentScreen(selection: id!),
    VRoute.billingHistory => const BillingHistoryScreen(),
    VRoute.storefront => const StorefrontScreen(),
    VRoute.storefrontPreview => const StorefrontTemplatePreviewScreen(),
    VRoute.storefrontTemplatePreview => StorefrontTemplatePreviewScreen(
      templateId: id,
    ),
    VRoute.branding => const CustomizeStorefrontScreen(),
    _ => UiPrototypeScreen(spec: loc.spec),
  };
}
