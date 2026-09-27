import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../async_view.dart';
import '../shell.dart';
import '../widgets.dart';
import 'planning.dart' show CoveragePreview, RadiusSlider;
import 'today_content.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

String _formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// V-06 — Welcome. Opens first-time business setup for a brand-new demo
/// account; existing accounts skip straight to Today. Presentation only —
/// nothing here persists, real setup truth is Phase 3.
class WelcomeSetupScreen extends StatelessWidget {
  const WelcomeSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final steps = [
      (L.businessInformation2, L.nameTypeContactDetails, LucideIcons.store),
      (L.pickupLocation2, L.whereDeliveriesStartFrom, LucideIcons.mapPin),
      (L.serviceArea2, L.howFarDeliver, LucideIcons.map),
    ];
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        // A compact brand panel under the shell header: titleMedium, not a
        // second page title.
        HeroSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L.letsSetUpBusiness,
                style: text.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: Gap.xs),
              Text(
                L.justFewDetailsBeforeStartDelivering,
                style: text.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .82),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.sm),
        for (final (index, step) in steps.indexed)
          CefListRow(
            title: step.$1,
            subtitle: step.$2,
            leading: CefAvatar('${index + 1}'),
            trailing: Icon(
              step.$3,
              size: Sizes.icon,
              color: context.c.textSecondary,
            ),
          ),
        const SizedBox(height: Gap.xxl),
        CefButton(L.getStarted2, onTap: () => app.go(VRoute.setupBusinessInfo)),
      ],
    );
  }
}

/// Shared step header for the V07–V09 setup wizard: the compact progress
/// line, then the archetype-G [SectionHeading] (icon + title + subtitle).
class _SetupStepHeader extends StatelessWidget {
  const _SetupStepHeader({
    required this.step,
    required this.totalSteps,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final int step, totalSteps;
  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < totalSteps; i++)
                Padding(
                  padding: const EdgeInsets.only(right: Gap.xs),
                  child: Container(
                    width: i == step - 1 ? Gap.xl : Gap.sm,
                    height: Gap.sm,
                    decoration: BoxDecoration(
                      color: i <= step - 1
                          ? CefColors.ceffloMustard
                          : context.c.border,
                      borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                    ),
                  ),
                ),
              const SizedBox(width: Gap.xs),
              Text(L.step(step, totalSteps), style: text.bodySmall),
            ],
          ),
          SectionHeading(title, icon: icon, subtitle: subtitle),
        ],
      ),
    );
  }
}

/// V-07 — First-time business information. Required fields only, per the
/// locked "do not create a long enterprise wizard" guidance.
class SetupBusinessInfoScreen extends StatefulWidget {
  const SetupBusinessInfoScreen({super.key});
  @override
  State<SetupBusinessInfoScreen> createState() =>
      _SetupBusinessInfoScreenState();
}

class _SetupBusinessInfoScreenState extends State<SetupBusinessInfoScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  String type = _types.first;
  final errors = <String, String>{};

  static List<String> get _types => [
    L.foodBeverage,
    L.homeLiving,
    L.retail,
    L.groceries,
    L.other,
  ];

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  void _continue() {
    errors.clear();
    if (name.text.trim().isEmpty) {
      errors['name'] = L.businessNameRequired;
    }
    if (phone.text.trim().length < 7) {
      errors['phone'] = L.enterValidPhoneNumber;
    }
    setState(() {});
    if (errors.isEmpty) AppScope.read(context).go(VRoute.setupAddress);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    bottom: CefButton(L.continueText, onTap: _continue),
    children: [
      _SetupStepHeader(
        step: 1,
        totalSteps: 3,
        icon: LucideIcons.store,
        title: L.tellUsAboutBusiness,
        subtitle: L.appearsDeliveryOrdersReceipts,
      ),
      CefField(
        label: L.businessName,
        controller: name,
        hint: L.eGKopiKita,
        prefixIcon: LucideIcons.store,
        errorText: errors['name'],
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L.businessType, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final t in _types)
                  CefChoiceChip(
                    label: t,
                    selected: type == t,
                    onTap: () => setState(() => type = t),
                  ),
              ],
            ),
          ],
        ),
      ),
      CefField(
        label: L.contactPhone,
        controller: phone,
        hint: '+60 12 345 6789',
        prefixIcon: LucideIcons.phone,
        keyboardType: TextInputType.phone,
        errorText: errors['phone'],
      ),
    ],
  );
}

/// V-08 — Pickup location. Keeps the same map-box + address field language
/// as Business Address (V39) so the two never feel like different products.
class SetupAddressScreen extends StatefulWidget {
  const SetupAddressScreen({super.key});
  @override
  State<SetupAddressScreen> createState() => _SetupAddressScreenState();
}

class _SetupAddressScreenState extends State<SetupAddressScreen> {
  final address = TextEditingController();
  final postcode = TextEditingController();
  final city = TextEditingController();
  final errors = <String, String>{};

  @override
  void dispose() {
    address.dispose();
    postcode.dispose();
    city.dispose();
    super.dispose();
  }

  void _continue() {
    errors.clear();
    if (address.text.trim().isEmpty) {
      errors['address'] = L.pickupAddressRequired;
    }
    setState(() {});
    if (errors.isEmpty) AppScope.read(context).go(VRoute.setupServiceArea);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    bottom: CefButton(L.continueText, onTap: _continue),
    children: [
      _SetupStepHeader(
        step: 2,
        totalSteps: 3,
        icon: LucideIcons.mapPin,
        title: L.whereDoDeliveriesStartFrom,
        subtitle: L.ridersPickUpOrdersFromLocation,
      ),
      Container(
        height: 180,
        decoration: BoxDecoration(
          color: context.c.subtle,
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
          border: Border.all(color: context.c.border),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(LucideIcons.mapPin, size: 44, color: CefColors.navy),
            ),
            Positioned(
              right: Gap.md,
              bottom: Gap.md,
              child: Container(
                width: Sizes.tapTarget,
                height: Sizes.tapTarget,
                decoration: BoxDecoration(
                  color: context.c.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.c.border),
                ),
                child: Icon(
                  LucideIcons.locateFixed,
                  size: Sizes.icon,
                  color: context.c.iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: Gap.lg),
      CefField(
        label: L.pickupAddress,
        controller: address,
        hint: L.searchEnterAddress,
        prefixIcon: LucideIcons.search,
        errorText: errors['address'],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CefField(
              label: L.postcode,
              controller: postcode,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: CefField(label: L.city, controller: city),
          ),
        ],
      ),
    ],
  );
}

/// V-09 — Service area. A friendly radius picker rather than raw
/// latitude/longitude fields, per the locked "avoid technical geometry
/// terminology" guidance.
class SetupServiceAreaScreen extends StatefulWidget {
  const SetupServiceAreaScreen({super.key});
  @override
  State<SetupServiceAreaScreen> createState() => _SetupServiceAreaScreenState();
}

class _SetupServiceAreaScreenState extends State<SetupServiceAreaScreen> {
  double radiusKm = 5;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // The coverage preview absorbs the spare height so "Finish Setup" sits
    // at the bottom of the viewport on tall phones instead of leaving dead
    // space below it; on short phones the preview keeps its minimum and the
    // page scrolls.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Gap.gutter,
                Gap.md,
                Gap.gutter,
                Gap.xxl,
              ),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SetupStepHeader(
                      step: 3,
                      totalSteps: 3,
                      icon: LucideIcons.map,
                      title: L.howFarDoDeliver,
                      subtitle: L.ceffloUsesDecideWhichOrdersCan,
                    ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 190),
                        child: CoveragePreview(radiusKm: radiusKm),
                      ),
                    ),
                    const SizedBox(height: Gap.lg),
                    RadiusSlider(
                      radiusKm: radiusKm,
                      onChanged: (v) => setState(() => radiusKm = v),
                    ),
                    const SizedBox(height: Gap.lg),
                    CefButton(
                      L.finishSetup,
                      onTap: () => app.go(VRoute.setupComplete),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// V-10 — Setup Complete presentation. It does not persist anything; real
/// setup truth is Phase 3.
class SetupCompleteScreen extends StatelessWidget {
  const SetupCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final checks = [
      (L.businessProfile2, L.completed, LucideIcons.store),
      (L.serviceArea2, L.configured, LucideIcons.mapPin),
      (L.teamRiders, L.ready, LucideIcons.users),
      (L.preferences, L.setText, LucideIcons.settings),
    ];
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        HeroSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: L.business2),
                    TextSpan(
                      text: L.ready2,
                      style: TextStyle(color: CefColors.ceffloMustard),
                    ),
                  ],
                ),
                style: text.titleMedium?.copyWith(
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                L.deliverySetupCompleteLetsStartDelivering,
                style: text.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .82),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.sm),
        for (final item in checks)
          CefListRow(
            title: item.$1,
            subtitle: item.$2,
            icon: item.$3,
            trailing: Icon(
              LucideIcons.circleCheck,
              size: Sizes.icon,
              color: context.c.success,
            ),
          ),
        const SizedBox(height: Gap.xxl),
        CefButton(L.goToday, onTap: () => app.switchTab(NavTab.today)),
      ],
    );
  }
}

/// V-11 — KPIs, attention and delivery planning all derive from one scoped
/// orders read, so a KPI can never disagree with the list behind it.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return PageBody(
        children: [StateBlock.empty(L.noBusinessLinkedAccountYet)],
      );
    }
    return AsyncView<(List<VendorOrder>, List<RiderRow>)>(
      loading: const SkeletonPage.today(),
      key: ValueKey('today-${business.id}'),
      load: () async => (
        await app.repo.orders(business.id),
        await app.repo.riders(business.id),
      ),
      builder: (context, data, reload) {
        return TodayContent(orders: data.$1, riders: data.$2, reload: reload);
      },
    );
  }
}

/// V-12 — Ongoing / Issue / Delivered tabs over canonical statuses.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderTab tab = OrderTab.ongoing;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return PageBody(children: [StateBlock.empty(L.noBusinessLinked)]);
    }
    return AsyncView<List<VendorOrder>>(
      key: ValueKey('orders-${business.id}'),
      load: () => app.repo.orders(business.id),
      builder: (context, orders, reload) {
        final visible = orders.where((o) => tab.accepts(o.status)).toList();
        final tabLabels = OrderTab.values
            .map(
              (t) =>
                  '${t.label} (${orders.where((o) => t.accepts(o.status)).length})',
            )
            .toList();
        return PageBody(
          onRefresh: reload,
          children: [
            SegmentedTabs(
              labels: tabLabels,
              active: tabLabels[OrderTab.values.indexOf(tab)],
              onChange: (l) => setState(() {
                final label = l.split(' ').first;
                tab = OrderTab.values.firstWhere((t) => t.label == label);
              }),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              StateBlock.empty(L.noOrders(tab.label.toLowerCase()))
            else
              for (final o in visible)
                CefListRow(
                  title: o.reference,
                  subtitle: '${o.customerName} · ${o.deliveryAddress}',
                  icon: LucideIcons.package,
                  trailing: DeliveryStatusChip(
                    o.status,
                    approved: o.isApproved,
                  ),
                  onTap: () => app.go(VRoute.orderDetail, entityId: o.id),
                ),
          ],
        );
      },
    );
  }
}

/// V-13 — bound to the selected order id, with status-appropriate actions.
/// Archetype E (detail hero): reference, status, meta and the tracker on the
/// gradient; customer / delivery / items on the white surface. Items show a
/// compact preview (the full list opens in a sheet) and the primary action
/// is pinned, so a large order never pushes it off screen.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  /// Item rows shown on the page; the rest open in the items sheet.
  static const _previewItems = 3;

  static const _itemIcons = [
    LucideIcons.cakeSlice,
    LucideIcons.coffee,
    LucideIcons.cookie,
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<(VendorOrder, List<Zone>)>(
      loading: const SkeletonHeroPage(),
      key: ValueKey('order-$orderId'),
      load: () async => (
        await app.repo.order(orderId),
        await app.repo.zones(app.business!.id),
      ),
      builder: (context, data, reload) {
        final (order, zones) = data;
        final items = order.items;
        // Pre-dispatch only: approval and zone are planning inputs the
        // server rejects once a rider holds the order.
        final planning =
            order.status == DeliveryStatus.created &&
            order.assignedRiderId == null;
        final zone = zones.where((z) => z.id == order.zoneId).firstOrNull;
        final phone = order.customerPhone.trim();
        Widget itemRow((int, OrderItem) entry) => CefListRow(
          title: entry.$2.name,
          subtitle:
              '${entry.$2.quantity} × '
              'RM${(entry.$2.unitPrice ?? 0).toStringAsFixed(2)}',
          icon: _itemIcons[entry.$1 % _itemIcons.length],
        );
        final hidden = items.length - _previewItems;
        return HeroPage(
          onRefresh: reload,
          hero: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DetailHero(
                title: order.reference,
                status: HeroStatusPill(
                  order.statusLabel,
                  color: switch (order.status) {
                    DeliveryStatus.issue => context.c.attention,
                    final s when OrderTab.ongoing.accepts(s) => null,
                    _ => context.c.textSecondary,
                  },
                ),
                lines: [
                  HeroLine(
                    L.todayItem(
                      _formatTime(order.createdAt),
                      items.length,
                      items.length == 1 ? '' : 's',
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.gutter,
                  0,
                  Gap.gutter,
                  Gap.xl,
                ),
                child: _OrderProgress(status: order.status),
              ),
            ],
          ),
          // Delivery progression (On the Way, Delivered) is driven by the
          // Rider app and only reflected here (D-53): the vendor gets no
          // delivery-status action. The existing Edit Order action is kept
          // where it was shown before; a Ready order has no bottom action.
          bottomAction: order.status == DeliveryStatus.readyForPickup
              ? null
              : planning && order.approvedAt == null
              ? Row(
                  children: [
                    Expanded(
                      child: CefButton(
                        L.editOrder2,
                        secondary: true,
                        onTap: () =>
                            app.go(VRoute.editOrder, entityId: order.id),
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: _ApproveOrderButton(
                        orderId: order.id,
                        onApproved: reload,
                      ),
                    ),
                  ],
                )
              : CefButton(
                  L.editOrder2,
                  onTap: () => app.go(VRoute.editOrder, entityId: order.id),
                ),
          children: [
            CefListRow(
              title: L.customer,
              subtitle: phone.isEmpty
                  ? order.customerName
                  : '${order.customerName}\n$phone',
              subtitleMaxLines: 2,
              icon: LucideIcons.user,
              trailing: phone.isEmpty ? null : ContactActions(phone: phone),
            ),
            CefListRow(
              title: L.deliver,
              subtitle: order.deliveryAddress,
              subtitleMaxLines: 2,
              icon: LucideIcons.mapPin,
              trailing: OutlinedIconAction(
                label: L.directions,
                icon: LucideIcons.navigation,
                onTap: () => launchDirections(context, order.deliveryAddress),
              ),
            ),
            CefListRow(
              title: L.zone,
              subtitle: zone?.name ?? L.notSet,
              icon: LucideIcons.map,
              showChevron: planning,
              onTap: planning
                  ? () => _pickZone(context, order, zones, reload)
                  : null,
            ),
            if ((order.notes ?? '').isNotEmpty)
              CefListRow(
                title: L.deliveryInstruction,
                subtitle: order.notes,
                subtitleMaxLines: 3,
                icon: LucideIcons.fileText,
              ),
            SectionHeading(
              L.items(items.length),
              trailing: CefLink(
                L.viewReceipt,
                icon: LucideIcons.fileText,
                onTap: () => showNotWiredYetSnackBar(context, L.receiptView),
              ),
            ),
            if (items.isEmpty)
              StateBlock.empty(L.noItemsOrder)
            else ...[
              for (final entry in items.indexed.take(_previewItems))
                itemRow(entry),
              if (hidden > 0)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CefLink(
                    L.viewAllItems(items.length),
                    chevron: true,
                    onTap: () => showListSheet(
                      context,
                      title: L.items(items.length),
                      children: [for (final e in items.indexed) itemRow(e)],
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// Order → Zone through the canonical `update_order_details` contract.
Future<void> _pickZone(
  BuildContext context,
  VendorOrder order,
  List<Zone> zones,
  Future<void> Function() reload,
) => showListSheet(
  context,
  title: L.zone,
  children: [
    for (final z in zones.where((z) => z.isActive))
      Builder(
        builder: (sheet) => CefListRow(
          title: z.name,
          subtitle: z.locality,
          icon: LucideIcons.map,
          showChevron: false,
          trailing: z.id == order.zoneId
              ? Icon(LucideIcons.circleCheck, color: sheet.c.info)
              : null,
          onTap: () async {
            Navigator.of(sheet).pop();
            if (z.id == order.zoneId) return;
            try {
              await AppScope.read(context).repo
                  .updateOrder(orderId: order.id, zoneId: z.id);
              if (context.mounted) {
                showCefToast(context, L.zoneSet(z.name));
              }
              await reload();
            } catch (e) {
              if (context.mounted) {
                showCefToast(context, L.couldNotSetZone(e), error: true);
              }
            }
          },
        ),
      ),
  ],
);

/// Vendor approval (D-17) through the canonical `approve_order` contract.
class _ApproveOrderButton extends StatefulWidget {
  const _ApproveOrderButton({required this.orderId, required this.onApproved});
  final String orderId;
  final Future<void> Function() onApproved;

  @override
  State<_ApproveOrderButton> createState() => _ApproveOrderButtonState();
}

class _ApproveOrderButtonState extends State<_ApproveOrderButton> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await AppScope.read(context).repo.approveOrder(widget.orderId);
      if (mounted) showCefToast(context, L.orderApproved);
      await widget.onApproved();
    } catch (e) {
      if (mounted) showCefToast(context, L.couldNotApprove(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CefButton(
    L.approveOrder,
    busy: _busy,
    busyLabel: L.approving,
    onTap: _busy ? null : _approve,
  );
}

/// V-14 — How the order gets created: one manual order, or a bulk import.
/// The two modes are navigation rows; Recent Imports is an entity list
/// (archetype B: logo leading, pill trailing, no chevron).
class NewOrderEntryScreen extends StatelessWidget {
  const NewOrderEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      children: [
        CefListRow(
          icon: LucideIcons.filePlus,
          title: L.manualEntry,
          subtitle: L.createSingleOrderStepByStep,
          subtitleMaxLines: 2,
          onTap: () => app.go(VRoute.newOrderManual),
        ),
        CefListRow(
          icon: LucideIcons.cloudUpload,
          title: L.importOrders2,
          subtitle: L.importMultipleOrdersFromFiles,
          subtitleMaxLines: 2,
          onTap: () => app.go(VRoute.importOrders),
        ),
        SectionHeading(
          L.recentImports,
          trailing: CefLink(
            L.viewAll,
            chevron: true,
            onTap: () => showNotWiredYetSnackBar(context, L.importHistory),
          ),
        ),
        for (final source in _ImportSource.values)
          CefListRow(
            leading: _ImportSourceMark(source: source),
            title: source.sampleBatch,
            subtitle:
                L.importSampleSubtitle(
                  source.label,
                  source.sampleCount,
                  source.sampleDate,
                ),
            subtitleMaxLines: 2,
            trailing: StatusChip(L.connected, success: true),
            showChevron: false,
            onTap: () => showNotWiredYetSnackBar(context, L.openingImport),
          ),
      ],
    );
  }
}

/// The three file sources the import flow accepts. Each source uses the
/// provider's official product mark bundled locally for deterministic render.
enum _ImportSource {
  googleSheets('assets/brand/google-sheets-logo.png', 32),
  excel('assets/brand/microsoft-excel-logo.png', 24),
  googleDrive('assets/brand/google-drive-logo.png', 18);

  const _ImportSource(this.assetPath, this.sampleCount);

  final String assetPath;
  final int sampleCount;

  String get label => switch (this) {
    _ImportSource.googleSheets => L.googleSheets,
    _ImportSource.excel => L.excel,
    _ImportSource.googleDrive => L.googleDrive,
  };

  String get description => switch (this) {
    _ImportSource.googleSheets => L.importFromGoogleSheets,
    _ImportSource.excel => L.uploadExcelFileXlsxXls,
    _ImportSource.googleDrive => L.importFromFilesGoogleDrive,
  };

  String get sampleBatch => switch (this) {
    _ImportSource.googleSheets => L.mealPrepOrders,
    _ImportSource.excel => L.cateringSept,
    _ImportSource.googleDrive => L.hamperOrders,
  };

  String get sampleDate => switch (this) {
    _ImportSource.googleSheets => L.t16Sep2026,
    _ImportSource.excel => L.t14Sep2026,
    _ImportSource.googleDrive => L.t12Sep2026,
  };
}

class _ImportSourceMark extends StatelessWidget {
  const _ImportSourceMark({required this.source});
  final _ImportSource source;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: Sizes.avatar,
    height: Sizes.avatar,
    child: Center(
      child: Image.asset(
        source.assetPath,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    ),
  );
}

/// X-04 — Pick where the bulk orders come from: the numbered guidance rows
/// (same step-row language as Welcome), then one navigation row per source.
class ImportOrdersScreen extends StatelessWidget {
  const ImportOrdersScreen({super.key});

  static List<(String, String)> get _steps => [
    (L.selectSource, L.googleSheetsExcelGoogleDrive),
    (L.chooseFile, L.pickConnectedSheet),
    (L.mapColumns, L.previewOrders),
    (L.importText, L.reviewOrders),
  ];

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Text(
        L.chooseSourceImportMultipleOrders,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      SectionHeading(L.howWorks, icon: LucideIcons.info),
      for (final (index, step) in _steps.indexed)
        CefListRow(
          leading: CefAvatar('${index + 1}'),
          title: step.$1,
          subtitle: step.$2,
          subtitleMaxLines: 2,
        ),
      SectionHeading(L.sources, icon: LucideIcons.cloudUpload),
      for (final source in _ImportSource.values)
        CefListRow(
          leading: _ImportSourceMark(source: source),
          title: source.label,
          subtitle: source.description,
          subtitleMaxLines: 2,
          onTap: () =>
              showNotWiredYetSnackBar(context, L.importingFrom(source.label)),
        ),
    ],
  );
}

/// X-03 / V-15 — Save validates and persists through the canonical RPC. The
/// screen only navigates after the backend confirms the write.
class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key, this.orderId});
  final String? orderId;
  bool get isNew => orderId == null;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final notes = TextEditingController();
  bool loading = false;
  bool busy = false;
  String? error;
  final errors = <String, String>{};

  @override
  void initState() {
    super.initState();
    if (!widget.isNew) _prefill();
  }

  Future<void> _prefill() async {
    setState(() => loading = true);
    try {
      final app = AppScope.read(context);
      final o = await app.repo.order(widget.orderId!);
      name.text = o.customerName;
      phone.text = o.customerPhone;
      address.text = o.deliveryAddress;
      notes.text = o.notes ?? '';
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool _validate() {
    errors.clear();
    if (name.text.trim().isEmpty) {
      errors['name'] = L.customerNameRequired;
    }
    if (phone.text.trim().length < 7) {
      errors['phone'] = L.enterValidPhoneNumber;
    }
    if (address.text.trim().isEmpty) {
      errors['address'] = L.deliveryAddressRequired;
    }
    setState(() {});
    return errors.isEmpty;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      final ok = await runAsyncFeedback(
        context,
        action: () async {},
        processingTitle: L.processing,
        processingSubtitle: widget.isNew ? L.creatingOrder : L.updatingOrder,
        successTitle: L.successful,
        successSubtitle: widget.isNew
            ? L.newOrderHasBeenCreatedSuccessfully
            : L.orderHasBeenUpdatedSuccessfully,
      );
      if (!mounted || !ok) return;
      if (widget.isNew) {
        app.go(VRoute.orderDetail, entityId: 'ord-1001');
      } else {
        app.back();
      }
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.isNew) {
        final id = await app.repo.createOrder(
          businessId: app.business!.id,
          customerName: name.text.trim(),
          customerPhone: phone.text.trim(),
          deliveryAddress: address.text.trim(),
          notes: notes.text.trim(),
        );
        if (!mounted) return;
        app.go(VRoute.orderDetail, entityId: id);
      } else {
        await app.repo.updateOrder(
          orderId: widget.orderId!,
          customerName: name.text.trim(),
          customerPhone: phone.text.trim(),
          deliveryAddress: address.text.trim(),
          notes: notes.text.trim(),
        );
        if (!mounted) return;
        app.back();
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SkeletonPage(rows: 6);
    return PageBody(
      bottom: CefButton(
        widget.isNew ? L.reviewCreate : L.updateOrder,
        onTap: _save,
      ),
      children: [
        Text(
          widget.isNew ? L.createNewOrderStepByStep : L.updateOrderDetails,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        // Archetype G (multi-section operational form).
        SectionHeading(
          L.customer,
          icon: LucideIcons.user,
          subtitle: L.selectExistingCustomerAddNewOne,
        ),
        CefField(
          label: L.customerName,
          controller: name,
          hint: L.searchCustomerByNamePhoneEmail,
          prefixIcon: LucideIcons.search,
          errorText: errors['name'],
        ),
        CefField(
          label: L.phoneNumber,
          controller: phone,
          hint: L.enterPhoneNumber,
          prefixIcon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
          errorText: errors['phone'],
        ),
        SectionHeading(
          L.address,
          icon: LucideIcons.mapPin,
          subtitle: L.deliveryAddress,
        ),
        CefField(
          label: L.address,
          controller: address,
          hint: L.enterDeliveryAddress,
          prefixIcon: LucideIcons.mapPin,
          maxLines: 2,
          errorText: errors['address'],
        ),
        SectionHeading(
          L.items2,
          icon: LucideIcons.package,
          subtitle: L.addOrderItems,
        ),
        CefActionRow(
          icon: LucideIcons.plus,
          label: L.addItemsOrder,
          onTap: () => showNotWiredYetSnackBar(context, L.addingOrderItems),
        ),
        SectionHeading(
          L.instructions,
          icon: LucideIcons.clipboardList,
          subtitle: L.specialRequestsOptional,
        ),
        CefField(
          label: L.instruction,
          controller: notes,
          hint: L.addDeliveryNotes,
          maxLines: 2,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.md),
            child: Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.c.attention),
            ),
          ),
      ],
    );
  }
}

/// V-35 / V-36 — Edit/Add product, bound to the canonical Product fields
/// instead of a generic Name/Phone/Email stand-in.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.productId});
  final String? productId;
  bool get isNew => productId == null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  bool active = true;
  bool loading = false;
  bool busy = false;
  String? error;
  final errors = <String, String>{};

  @override
  void initState() {
    super.initState();
    if (!widget.isNew) _prefill();
  }

  Future<void> _prefill() async {
    setState(() => loading = true);
    try {
      final app = AppScope.read(context);
      final products = await app.repo.products(app.business!.id);
      final p = products.firstWhere((p) => p.id == widget.productId);
      name.text = p.name;
      description.text = p.description ?? '';
      price.text = p.displayPrice?.toStringAsFixed(2) ?? '';
      active = p.status == 'active';
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool _validate() {
    errors.clear();
    if (name.text.trim().isEmpty) {
      errors['name'] = L.productNameRequired;
    }
    final parsed = num.tryParse(price.text.trim());
    if (parsed == null || parsed < 0) {
      errors['price'] = L.enterValidPrice;
    }
    setState(() {});
    return errors.isEmpty;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      final ok = await runAsyncFeedback(
        context,
        action: () async {},
        processingTitle: L.processing,
        processingSubtitle: widget.isNew ? L.addingProduct : L.updatingProduct,
        successTitle: L.successful,
        successSubtitle: widget.isNew
            ? L.newProductHasBeenAddedSuccessfully
            : L.productHasBeenUpdatedSuccessfully,
      );
      if (!mounted || !ok) return;
      app.back();
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final priceValue = num.parse(price.text.trim());
      if (widget.isNew) {
        await app.repo.createProduct(
          businessId: app.business!.id,
          name: name.text.trim(),
          description: description.text.trim(),
          displayPrice: priceValue,
          status: active ? 'active' : 'inactive',
        );
      } else {
        await app.repo.updateProduct(
          productId: widget.productId!,
          name: name.text.trim(),
          description: description.text.trim(),
          displayPrice: priceValue,
          status: active ? 'active' : 'inactive',
        );
      }
      if (!mounted) return;
      app.back();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SkeletonPage(rows: 6);
    return PageBody(
      bottom: CefButton(
        widget.isNew ? L.addProduct2 : L.saveChanges,
        busy: busy,
        onTap: _save,
      ),
      children: [
        // Archetype H (product / content form).
        Text(L.productPhoto, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Gap.md),
        const _PhotoDropzone(),
        SectionHeading(L.productDetails, icon: LucideIcons.package),
        CefField(
          label: L.productName,
          controller: name,
          hint: L.enterProductName,
          errorText: errors['name'],
        ),
        CefField(
          label: L.description,
          controller: description,
          hint: L.enterProductDescription,
          maxLines: 3,
        ),
        CefField(
          label: L.priceRm,
          controller: price,
          hint: L.rm000,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: errors['price'],
        ),
        CefListRow(
          title: L.available,
          subtitle: L.showProductStorefront,
          trailing: CefSwitch(
            value: active,
            onChanged: (v) => setState(() => active = v),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.c.attention),
            ),
          ),
      ],
    );
  }
}

/// The order-specific three-node delivery tracker drawn inside the order
/// hero, so every colour is white-on-hero.
class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.status});
  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    // Three visible steps. The V-13 reference draws a "Ready" order with the
    // Pickup node already highlighted, so readyForPickup lights node 0 rather
    // than leaving the whole tracker dim.
    final labels = [L.pickup, L.way2, L.delivered];
    final active = switch (status) {
      DeliveryStatus.readyForPickup || DeliveryStatus.pickedUp => 0,
      DeliveryStatus.outForDelivery || DeliveryStatus.arrived => 1,
      DeliveryStatus.delivered => 2,
      _ => -1,
    };
    // Reached nodes are solid white with a navy glyph, future nodes are a
    // translucent white wash.
    const icons = [
      LucideIcons.package,
      LucideIcons.truck,
      LucideIcons.circleCheck,
    ];
    final caption = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: List.generate(labels.length, (index) {
        final reached = index <= active;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: Colors.white.withValues(
                          alpha: index <= active ? 1 : .3,
                        ),
                      ),
                    ),
                  Container(
                    width: Gap.xxxl,
                    height: Gap.xxxl,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached
                          ? Colors.white
                          : Colors.white.withValues(alpha: .22),
                    ),
                    child: Icon(
                      icons[index],
                      size: 16,
                      color: reached
                          ? CefColors.navy
                          : Colors.white.withValues(alpha: .85),
                    ),
                  ),
                  if (index < labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: Colors.white.withValues(
                          alpha: index < active ? 1 : .3,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Gap.sm),
              Text(
                labels[index],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: caption?.copyWith(
                  fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.white.withValues(alpha: reached ? 1 : .75),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Dashed photo drop area of the product form. Tapping it is not wired to a
/// picker yet, exactly as before.
class _PhotoDropzone extends StatelessWidget {
  const _PhotoDropzone();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomPaint(
      painter: _DashedRectPainter(
        color: c.textSecondary.withValues(alpha: .45),
      ),
      child: Container(
        height: 132,
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.grouped,
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.imagePlus, size: 34, color: c.iconColor),
            const SizedBox(height: Gap.sm),
            Text(
              L.addProductPhoto,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(Sizes.cardRadius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}
