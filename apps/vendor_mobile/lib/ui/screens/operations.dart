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
    const steps = [
      (
        'Business Information',
        'Name, type and contact details',
        LucideIcons.store,
      ),
      ('Pickup Location', 'Where deliveries start from', LucideIcons.mapPin),
      ('Service Area', 'How far you deliver', LucideIcons.map),
    ];
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        HeroSurface(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let’s set up your business',
                style: text.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                'Just a few details before you start delivering with '
                'Cefflo. Takes about 2 minutes.',
                style: text.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .82),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
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
        CefButton('Get Started', onTap: () => app.go(VRoute.setupBusinessInfo)),
      ],
    );
  }
}

/// Shared step header for the V07–V09 setup wizard.
class _SetupStepHeader extends StatelessWidget {
  const _SetupStepHeader({
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });
  final int step, totalSteps;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xl),
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
                          ? CefColors.accent
                          : context.c.border,
                      borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                    ),
                  ),
                ),
              const SizedBox(width: Gap.xs),
              Text('Step $step of $totalSteps', style: text.bodySmall),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(title, style: text.headlineSmall),
          const SizedBox(height: Gap.xs),
          Text(subtitle, style: text.bodyMedium),
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

  static const _types = [
    'Food & Beverage',
    'Home & Living',
    'Retail',
    'Groceries',
    'Other',
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
      errors['name'] = 'Business name is required.';
    }
    if (phone.text.trim().length < 7) {
      errors['phone'] = 'Enter a valid phone number.';
    }
    setState(() {});
    if (errors.isEmpty) AppScope.read(context).go(VRoute.setupAddress);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const _SetupStepHeader(
        step: 1,
        totalSteps: 3,
        title: 'Tell us about your business',
        subtitle: 'This appears on your delivery orders and receipts.',
      ),
      CefField(
        label: 'Business Name',
        controller: name,
        hint: 'e.g. Kopi Kita',
        errorText: errors['name'],
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Type',
              style: Theme.of(context).textTheme.labelLarge,
            ),
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
        label: 'Contact Phone',
        controller: phone,
        hint: '+60 12 345 6789',
        keyboardType: TextInputType.phone,
        errorText: errors['phone'],
      ),
      const SizedBox(height: Gap.sm),
      CefButton('Continue', onTap: _continue),
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
      errors['address'] = 'Pickup address is required.';
    }
    setState(() {});
    if (errors.isEmpty) AppScope.read(context).go(VRoute.setupServiceArea);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const _SetupStepHeader(
        step: 2,
        totalSteps: 3,
        title: 'Where do deliveries start from?',
        subtitle: 'Riders pick up orders from this location.',
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
        label: 'Pickup Address',
        controller: address,
        hint: 'Search or enter your address',
        errorText: errors['address'],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CefField(
              label: 'Postcode',
              controller: postcode,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: CefField(label: 'City', controller: city),
          ),
        ],
      ),
      const SizedBox(height: Gap.sm),
      CefButton('Continue', onTap: _continue),
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
                    const _SetupStepHeader(
                      step: 3,
                      totalSteps: 3,
                      title: 'How far do you deliver?',
                      subtitle: 'Cefflo uses this to decide which orders you can accept.',
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
                      'Finish Setup',
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
    final checks = const [
      ('Business Profile', 'Completed', LucideIcons.store),
      ('Service Area', 'Configured', LucideIcons.mapPin),
      ('Team & Riders', 'Ready', LucideIcons.users),
      ('Preferences', 'Set', LucideIcons.settings),
    ];
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        HeroSurface(
          padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xxxl, Gap.xl, Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Your Business\nis '),
                    TextSpan(
                      text: 'Ready!',
                      style: TextStyle(color: CefColors.accent),
                    ),
                  ],
                ),
                style: text.displaySmall?.copyWith(
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: Gap.md),
              Text(
                'Your delivery setup is complete.\nLet’s start delivering with Cefflo.',
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
        CefButton('Go to Today', onTap: () => app.switchTab(NavTab.today)),
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
      return const PageBody(
        children: [
          StateBlock.empty('No business is linked to this account yet.'),
        ],
      );
    }
    return AsyncView<(List<VendorOrder>, List<RiderRow>)>(
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
      return const PageBody(
        children: [StateBlock.empty('No business linked.')],
      );
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
              StateBlock.empty('No ${tab.label.toLowerCase()} orders.')
            else
              for (final o in visible)
                CefListRow(
                  title: o.reference,
                  subtitle: '${o.customerName} · ${o.deliveryAddress}',
                  icon: LucideIcons.package,
                  // Archetype B: neutral status pill (Issue stays red),
                  // no chevron.
                  trailing: StatusChip(
                    o.status.label,
                    attention: o.status == DeliveryStatus.issue,
                  ),
                  showChevron: false,
                  onTap: () => app.go(VRoute.orderDetail, entityId: o.id),
                ),
          ],
        );
      },
    );
  }
}

/// V-13 — bound to the selected order id, with status-appropriate actions.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<VendorOrder>(
      key: ValueKey('order-$orderId'),
      load: () => app.repo.order(orderId),
      builder: (context, order, reload) => PageBody(
        onRefresh: reload,
        children: [
          _OrderHeroCard(order: order),
          const SizedBox(height: Gap.sm),
          _OrderInfoRow(
            icon: LucideIcons.user,
            label: 'Customer',
            title: order.customerName,
            subtitle: order.customerPhone,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconAction(
                  icon: LucideIcons.phone,
                  tooltip: 'Call',
                  onTap: () =>
                      showNotWiredYetSnackBar(context, 'Calling the customer'),
                ),
                IconAction(
                  icon: LucideIcons.messageCircle,
                  tooltip: 'Message',
                  onTap: () => showNotWiredYetSnackBar(
                    context,
                    'Messaging the customer',
                  ),
                ),
              ],
            ),
          ),
          _OrderInfoRow(
            icon: LucideIcons.mapPin,
            label: 'Deliver to',
            title: order.deliveryAddress,
            subtitle: '59100 Kuala Lumpur',
            trailing: IconAction(
              icon: LucideIcons.navigation,
              tooltip: 'Navigate',
              onTap: () =>
                  showNotWiredYetSnackBar(context, 'Navigating to the address'),
            ),
          ),
          if ((order.notes ?? '').isNotEmpty)
            _OrderInfoRow(
              icon: LucideIcons.fileText,
              label: 'Delivery Instruction',
              title: order.notes!,
            ),
          SectionHeading(
            'Items (${order.items.length})',
            trailing: CefLink(
              'View receipt',
              icon: LucideIcons.fileText,
              onTap: () => showNotWiredYetSnackBar(context, 'The receipt view'),
            ),
          ),
          for (final (index, item) in order.items.indexed)
            CefListRow(
              title: item.name,
              subtitle:
                  '${item.quantity} × RM${(item.unitPrice ?? 0).toStringAsFixed(2)}',
              leading: _ItemThumb(index: index),
            ),
          const SizedBox(height: Gap.xxl),
          CefButton(
            order.status == DeliveryStatus.readyForPickup
                ? 'Mark as On the Way'
                : 'Edit Order',
            icon: order.status == DeliveryStatus.readyForPickup
                ? LucideIcons.truck
                : null,
            onTap: () => app.go(VRoute.editOrder, entityId: order.id),
          ),
        ],
      ),
    );
  }
}

/// Hero summary that opens V-13: reference, status, meta line and the
/// three-step tracker all live inside the one shared hero surface.
class _OrderHeroCard extends StatelessWidget {
  const _OrderHeroCard({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return HeroSurface(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  order.reference,
                  style: text.headlineSmall?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: Gap.sm),
              _HeroStatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: Gap.xs),
          Text(
            'Today, ${_formatTime(order.createdAt)}  ·  ${order.items.length} items',
            style: text.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: .78),
            ),
          ),
          const SizedBox(height: Gap.lg),
          _OrderProgress(status: order.status),
        ],
      ),
    );
  }
}

/// The canonical [StatusChip] on a solid card-coloured backing: the chip's
/// light tint is only legible over a light surface, not over the hero.
class _HeroStatusPill extends StatelessWidget {
  const _HeroStatusPill({required this.status});
  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: context.c.card,
      shape: const StadiumBorder(),
    ),
    child: StatusChip(
      status.label,
      attention: status == DeliveryStatus.issue,
      success: OrderTab.ongoing.accepts(status),
    ),
  );
}

/// A labelled detail line (Customer / Deliver to / Delivery Instruction):
/// the [CefListRow] geometry, plus a caption above the value and a value
/// that wraps instead of truncating (instructions and addresses run long).
class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow({
    required this.icon,
    required this.label,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: Gap.xs, vertical: Gap.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: Sizes.icon, color: c.iconColor),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.bodySmall),
                const SizedBox(height: 2),
                Text(title, style: text.titleSmall),
                if (subtitle != null) Text(subtitle!, style: text.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: Gap.sm), trailing!],
        ],
      ),
    );
  }
}

/// Item thumbnail placeholder used as the leading of an item [CefListRow].
class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.index});
  final int index;

  static const _icons = [
    LucideIcons.cakeSlice,
    LucideIcons.coffee,
    LucideIcons.cookie,
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: Sizes.avatar,
    height: Sizes.avatar,
    decoration: BoxDecoration(
      color: context.c.subtle,
      borderRadius: BorderRadius.circular(Gap.md),
    ),
    child: Icon(_icons[index % _icons.length], color: CefColors.navy, size: 20),
  );
}

/// V-14 — How the order gets created: one manual order, or a bulk import.
class NewOrderEntryScreen extends StatelessWidget {
  const NewOrderEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        _EntryModeCard(
          icon: LucideIcons.filePlus,
          title: 'Manual Entry',
          subtitle: 'Create a single order step by step',
          onTap: () => app.go(VRoute.newOrderManual),
        ),
        const SizedBox(height: Gap.cardGap),
        _EntryModeCard(
          icon: LucideIcons.cloudUpload,
          title: 'Import Orders',
          subtitle: 'Import multiple orders from your files',
          onTap: () => app.go(VRoute.importOrders),
        ),
        SectionHeading(
          'Recent Imports',
          trailing: CefLink(
            'View all',
            icon: LucideIcons.list,
            onTap: () => showNotWiredYetSnackBar(context, 'The import history'),
          ),
        ),
        for (final source in _ImportSource.values)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.cardGap),
            child: CefCard(
              onTap: () =>
                  showNotWiredYetSnackBar(context, 'Opening this import'),
              child: Row(
                children: [
                  _ImportSourceMark(source: source),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(source.sampleBatch, style: text.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          '${source.label} · ${source.sampleCount} orders',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(source.sampleDate, style: text.bodySmall),
                      const SizedBox(height: Gap.xs),
                      const StatusChip('Connected', success: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One of the two mode cards at the top of V-14: a tappable [CefCard] with
/// the mode's icon, title, description and a navigation chevron.
class _EntryModeCard extends StatelessWidget {
  const _EntryModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    return CefCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: Sizes.icon, color: c.info),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: Gap.sm),
          Icon(LucideIcons.chevronRight, size: 18, color: c.textSecondary),
        ],
      ),
    );
  }
}

/// The three file sources the import flow accepts. Each source uses the
/// provider's official product mark bundled locally for deterministic render.
enum _ImportSource {
  googleSheets(
    'Google Sheets',
    'Import from your Google Sheets',
    'assets/brand/google-sheets-logo.png',
    'Meal Prep Orders',
    32,
    '16 Sep 2026',
  ),
  excel(
    'Excel',
    'Upload an Excel file (.xlsx, .xls)',
    'assets/brand/microsoft-excel-logo.png',
    'Catering Sept',
    24,
    '14 Sep 2026',
  ),
  googleDrive(
    'Google Drive',
    'Import from files in your Google Drive',
    'assets/brand/google-drive-logo.png',
    'Hamper Orders',
    18,
    '12 Sep 2026',
  );

  const _ImportSource(
    this.label,
    this.description,
    this.assetPath,
    this.sampleBatch,
    this.sampleCount,
    this.sampleDate,
  );
  final String label;
  final String description;
  final String assetPath;
  final String sampleBatch;
  final int sampleCount;
  final String sampleDate;
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

/// X-04 — Pick where the bulk orders come from.
class ImportOrdersScreen extends StatelessWidget {
  const ImportOrdersScreen({super.key});

  static const _steps = [
    'Select your source (Google Sheets, Excel or Google Drive)',
    'Choose a file or connected sheet',
    'Map the columns and preview your orders',
    'Import and review the orders',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PageBody(
      children: [
        Text(
          'Choose a source to import multiple orders.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Gap.lg),
        Container(
          padding: const EdgeInsets.all(Gap.cardPadding),
          decoration: BoxDecoration(
            color: c.subtle,
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.info, size: 18, color: c.info),
                  const SizedBox(width: Gap.sm),
                  Text(
                    'How it works?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              for (final (index, step) in _steps.indexed)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _steps.length - 1 ? 0 : Gap.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: Gap.xl,
                        height: Gap.xl,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.card,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: CefColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: Gap.sm),
                      Expanded(
                        child: Text(
                          step,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Gap.section),
        for (final source in _ImportSource.values)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.cardGap),
            child: CefCard(
              onTap: () => showNotWiredYetSnackBar(
                context,
                'Importing from ${source.label}',
              ),
              child: Row(
                children: [
                  _ImportSourceMark(source: source),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          source.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: c.textSecondary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
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
      errors['name'] = 'Customer name is required.';
    }
    if (phone.text.trim().length < 7) {
      errors['phone'] = 'Enter a valid phone number.';
    }
    if (address.text.trim().isEmpty) {
      errors['address'] = 'Delivery address is required.';
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
        processingTitle: 'Processing...',
        processingSubtitle: widget.isNew
            ? 'Creating your order'
            : 'Updating your order',
        successTitle: 'Successful',
        successSubtitle: widget.isNew
            ? 'Your new order has been created successfully.'
            : 'Your order has been updated successfully.',
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
    if (loading) return const StateBlock.loading();
    return PageBody(
      children: [
        Text(
          widget.isNew
              ? 'Create a new order step by step.'
              : 'Update order details.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        // Archetype G (multi-section operational form).
        const SectionHeading(
          'Customer',
          icon: LucideIcons.user,
          subtitle: 'Select an existing customer or add a new one.',
        ),
        CefField(
          label: 'Customer name',
          controller: name,
          hint: 'Search customer by name, phone or email...',
          prefixIcon: LucideIcons.search,
          errorText: errors['name'],
        ),
        CefField(
          label: 'Phone number',
          controller: phone,
          hint: 'Enter phone number...',
          prefixIcon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
          errorText: errors['phone'],
        ),
        const _SectionDivider(),
        const SectionHeading(
          'Address',
          icon: LucideIcons.mapPin,
          subtitle: 'Delivery address',
        ),
        CefField(
          label: 'Address',
          controller: address,
          hint: 'Enter delivery address...',
          prefixIcon: LucideIcons.mapPin,
          maxLines: 2,
          errorText: errors['address'],
        ),
        const _SectionDivider(),
        const SectionHeading(
          'Items',
          icon: LucideIcons.package,
          subtitle: 'Add order items',
        ),
        CefActionRow(
          icon: LucideIcons.plus,
          label: 'Add items to this order',
          leadingDisc: true,
          onTap: () => showNotWiredYetSnackBar(context, 'Adding order items'),
        ),
        const _SectionDivider(),
        const SectionHeading(
          'Instructions',
          icon: LucideIcons.clipboardList,
          subtitle: 'Special requests (optional)',
        ),
        CefField(
          label: 'Instruction',
          controller: notes,
          hint: 'Add delivery notes...',
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
        const SizedBox(height: Gap.md),
        CefButton(
          widget.isNew ? 'Review & Create' : 'Update Order',
          onTap: _save,
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
      errors['name'] = 'Product name is required.';
    }
    final parsed = num.tryParse(price.text.trim());
    if (parsed == null || parsed < 0) {
      errors['price'] = 'Enter a valid price.';
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
        processingTitle: 'Processing...',
        processingSubtitle: widget.isNew
            ? 'Adding your product'
            : 'Updating your product',
        successTitle: 'Successful',
        successSubtitle: widget.isNew
            ? 'Your new product has been added successfully.'
            : 'Your product has been updated successfully.',
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
    if (loading) return const StateBlock.loading();
    return PageBody(
      children: [
        // Archetype H (product / content form).
        Text('Product Photo', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Gap.md),
        const _PhotoDropzone(),
        const _SectionDivider(),
        const SectionHeading('Product Details', icon: LucideIcons.package),
        CefField(
          label: 'Product name',
          controller: name,
          hint: 'Enter product name',
          errorText: errors['name'],
        ),
        CefField(
          label: 'Description',
          controller: description,
          hint: 'Enter product description',
          maxLines: 3,
        ),
        CefField(
          label: 'Price (RM)',
          controller: price,
          hint: 'RM 0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: errors['price'],
        ),
        CefListRow(
          title: 'Available',
          subtitle: 'Show this product in your storefront',
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
        const SizedBox(height: Gap.xxl),
        CefButton(
          widget.isNew ? 'Add Product' : 'Save Changes',
          busy: busy,
          onTap: _save,
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
    const labels = ['Pickup', 'On the Way', 'Delivered'];
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

/// Hairline divider between form sections (archetypes G and H).
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.sm),
    child: Divider(height: Gap.lg, color: context.c.border),
  );
}

/// Dashed photo drop area of the product form. Tapping it is not wired to a
/// picker yet, exactly as before.
class _PhotoDropzone extends StatelessWidget {
  const _PhotoDropzone();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomPaint(
      painter: _DashedRectPainter(color: c.textSecondary.withValues(alpha: .45)),
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
              'Add product photo',
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
