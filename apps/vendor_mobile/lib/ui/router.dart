import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import 'screens/directory.dart';
import 'screens/operations.dart';
import 'screens/planning.dart';
import 'screens/prototype.dart';
import 'screens/storefront/storefront_customize.dart';
import 'screens/storefront/storefront_screens.dart';
import 'shell.dart';
import 'widgets.dart';

/// Maps a typed [VendorLocation] to its screen.
///
/// Routes that have not been migrated yet render [NotMigratedScreen], which
/// states plainly that the route is pending. They are never dressed up as
/// working screens.
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
    VRoute.createZone => const ZoneFormScreen(),
    VRoute.editZone => ZoneFormScreen(zoneId: id!),
    VRoute.reviewDispatch => ReviewDispatchScreen(zoneId: id),
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
    VRoute.settings => const MenuScreen(),
    VRoute.storefront => const StorefrontScreen(),
    VRoute.storefrontPreview => const StorefrontTemplatePreviewScreen(),
    VRoute.storefrontTemplatePreview => StorefrontTemplatePreviewScreen(
      templateId: id,
    ),
    VRoute.branding => const CustomizeStorefrontScreen(),
    _ => UiPrototypeScreen(spec: loc.spec),
  };
}

class NotMigratedScreen extends StatelessWidget {
  const NotMigratedScreen({super.key, required this.spec});
  final RouteSpec spec;

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      CefCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${spec.id} · ${spec.title}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Gap.sm),
            Text(
              'This route is in the approved inventory but has not been '
              'migrated to Flutter yet. It is listed here so the route map '
              'stays complete and countable — it is not a working screen.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ],
  );
}
