import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/vendor_repository.dart';
import '../async_view.dart';
import '../shell.dart';
import '../widgets.dart';
import 'today_content.dart';

String _formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

Widget _plainIcon(BuildContext context, IconData icon, {Color? color}) =>
    Icon(icon, size: Sizes.icon, color: color ?? context.c.iconColor);

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
    return PageBody(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF102344), Color(0xFF1B3668), Color(0xFF27427E)],
            ),
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Let’s set up your business',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Just a few details before you start delivering with '
                'Cefflo. Takes about 2 minutes.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: 14.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.section),
        for (final (index, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.cardGap),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F3F8),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: CefColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.$1,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.$2,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(step.$3, size: Sizes.icon, color: context.c.textSecondary),
              ],
            ),
          ),
        const SizedBox(height: Gap.section),
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          for (var i = 0; i < totalSteps; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: i == step - 1 ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= step - 1
                      ? CefColors.accent
                      : const Color(0xFFE3E6EE),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Step $step of $totalSteps',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 10),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: Gap.section),
    ],
  );
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
            const SizedBox(height: Gap.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _types)
                  ChoiceChip(
                    label: Text(t),
                    selected: type == t,
                    onSelected: (_) => setState(() => type = t),
                    selectedColor: CefColors.accent,
                    labelStyle: TextStyle(
                      color: type == t
                          ? CefColors.onAccent
                          : context.c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: context.c.card,
                    side: BorderSide(color: context.c.border),
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
          color: const Color(0xFFEAF0F4),
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
          border: Border.all(color: context.c.border),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(LucideIcons.mapPin, size: 44, color: CefColors.navy),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  LucideIcons.locateFixed,
                  color: context.c.iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: Gap.md),
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
    return PageBody(
      children: [
        const _SetupStepHeader(
          step: 3,
          totalSteps: 3,
          title: 'How far do you deliver?',
          subtitle: 'Cefflo uses this to decide which orders you can accept.',
        ),
        SizedBox(
          height: 190,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            child: CustomPaint(
              painter: _CoveragePreviewPainter(radiusKm: radiusKm),
              child: const Center(
                child: Icon(
                  LucideIcons.mapPin,
                  color: CefColors.navy,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Gap.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery radius',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              '${radiusKm.round()} km',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        Slider(
          value: radiusKm,
          min: 2,
          max: 20,
          divisions: 18,
          activeColor: CefColors.accent,
          onChanged: (v) => setState(() => radiusKm = v),
        ),
        const SizedBox(height: Gap.sm),
        CefButton('Finish Setup', onTap: () => app.go(VRoute.setupComplete)),
      ],
    );
  }
}

class _CoveragePreviewPainter extends CustomPainter {
  _CoveragePreviewPainter({required this.radiusKm});
  final double radiusKm;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF0F4F8),
    );
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide * .42;
    final r = maxRadius * (radiusKm / 20).clamp(.25, 1.0);
    canvas.drawCircle(center, r, Paint()..color = const Color(0x332A6EEC));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFF2A6EEC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CoveragePreviewPainter oldDelegate) =>
      oldDelegate.radiusKm != radiusKm;
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
    return PageBody(
      children: [
        Container(
          height: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF102344), Color(0xFF1B3668), Color(0xFF27427E)],
            ),
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: 1.04,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    TextSpan(text: 'Your Business\nis '),
                    TextSpan(
                      text: 'Ready!',
                      style: TextStyle(color: CefColors.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your delivery setup is complete.\nLet’s start delivering with Cefflo.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: 14.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        for (final item in checks)
          FlatListRow(
            title: item.$1,
            subtitle: item.$2,
            leading: _plainIcon(context, item.$3),
            trailing: Icon(
              LucideIcons.circleCheck,
              size: Sizes.icon,
              color: context.c.success,
            ),
          ),
        const SizedBox(height: Gap.section),
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
          floatingAction: YellowFab(
            tooltip: 'Add order',
            onTap: () => app.go(VRoute.newOrder),
          ),
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
                FlatListRow(
                  title: o.reference,
                  subtitle: '${o.customerName} · ${o.deliveryAddress}',
                  leading: _plainIcon(context, LucideIcons.package),
                  trailing: StatusChip(
                    o.status.label,
                    attention: o.status == DeliveryStatus.issue,
                    success: OrderTab.ongoing.accepts(o.status),
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
          const SizedBox(height: Gap.section),
          _OrderInfoRow(
            icon: LucideIcons.user,
            label: 'Customer',
            title: order.customerName,
            subtitle: order.customerPhone,
            trailing: Row(
              children: [
                _StackedAction(
                  icon: LucideIcons.phone,
                  label: 'Call',
                  onTap: () =>
                      showNotWiredYetSnackBar(context, 'Calling the customer'),
                ),
                const SizedBox(width: Gap.sm),
                _StackedAction(
                  icon: LucideIcons.messageCircle,
                  label: 'Message',
                  onTap: () => showNotWiredYetSnackBar(
                    context,
                    'Messaging the customer',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          _OrderInfoRow(
            icon: LucideIcons.mapPin,
            label: 'Deliver to',
            title: order.deliveryAddress,
            subtitle: '59100 Kuala Lumpur',
            trailing: _TintedPillButton(
              icon: LucideIcons.map,
              label: 'Navigate',
              onTap: () =>
                  showNotWiredYetSnackBar(context, 'Navigating to the address'),
            ),
          ),
          if ((order.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: Gap.lg),
            _OrderInfoRow(
              icon: LucideIcons.fileText,
              label: 'Delivery Instruction',
              title: order.notes!,
            ),
          ],
          const SizedBox(height: Gap.section),
          Divider(height: 1, color: context.c.border),
          SectionHeading(
            'Items (${order.items.length})',
            trailing: _TintedLink(
              icon: LucideIcons.fileText,
              label: 'View receipt',
              onTap: () => showNotWiredYetSnackBar(context, 'The receipt view'),
            ),
          ),
          for (final (index, item) in order.items.indexed) ...[
            if (index > 0) Divider(height: 1, color: context.c.border),
            _OrderItemRow(item: item, index: index),
          ],
          const SizedBox(height: Gap.section),
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

/// Blue gradient summary card that opens V-13: reference, status pill, meta
/// line and the three-step tracker all live inside it.
class _OrderHeroCard extends StatelessWidget {
  const _OrderHeroCard({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.info, const Color(0xFF0B57C7)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  order.reference,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              _HeroStatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Today, ${_formatTime(order.createdAt)}  ·  ${order.items.length} items',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _OrderProgress(status: order.status),
        ],
      ),
    );
  }
}

class _HeroStatusPill extends StatelessWidget {
  const _HeroStatusPill({required this.status});
  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final attention = status == DeliveryStatus.issue;
    final dot = attention ? context.c.attention : context.c.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: attention
            ? context.c.attention.withValues(alpha: .16)
            : const Color(0xFFDFF4E7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: dot,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled row: tinted circular icon, label + value, optional trailing
/// action. Replaces the bordered detail cards -- the reference draws these
/// as plain rows on the page, not as cards.
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.info.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: c.info),
        ),
        const SizedBox(width: Gap.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: Gap.sm), trailing!],
      ],
    );
  }
}

/// Circular tinted icon with its label underneath (Call / Message).
class _StackedAction extends StatelessWidget {
  const _StackedAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.info.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: c.info),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tinted pill button used for the inline Navigate action.
class _TintedPillButton extends StatelessWidget {
  const _TintedPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.info.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: c.info),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: c.info,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline text link with a leading icon (View receipt).
class _TintedLink extends StatelessWidget {
  const _TintedLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: c.info),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: c.info,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One item line: thumbnail, name, quantity x unit price, chevron.
class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, required this.index});
  final OrderItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    const icons = [
      LucideIcons.cakeSlice,
      LucideIcons.coffee,
      LucideIcons.cookie,
    ];
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icons[index % icons.length],
              color: CefColors.navy,
              size: 24,
            ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} × RM${(item.unitPrice ?? 0).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 18, color: c.textSecondary),
        ],
      ),
    );
  }
}

/// V-14 / V-15 — Save validates and persists through the canonical RPC. The
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
        const SizedBox(height: 16),
        _FormSection(
          icon: LucideIcons.user,
          title: 'Customer',
          subtitle: 'Select an existing customer or add a new one.',
          child: Column(
            children: [
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
                keyboardType: TextInputType.phone,
                errorText: errors['phone'],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _FormSection(
          icon: LucideIcons.mapPin,
          title: 'Address',
          subtitle: 'Delivery address',
          child: CefField(
            label: 'Address',
            controller: address,
            hint: 'Enter delivery address...',
            maxLines: 2,
            errorText: errors['address'],
          ),
        ),
        const SizedBox(height: 12),
        _FormSection(
          icon: LucideIcons.package,
          title: 'Items',
          subtitle: 'Add order items',
          child: _PickerField(
            hint: 'Add items to this order...',
            onTap: () => showNotWiredYetSnackBar(context, 'Adding order items'),
          ),
        ),
        const SizedBox(height: 12),
        _FormSection(
          icon: LucideIcons.clipboardList,
          title: 'Instructions',
          subtitle: 'Special requests (optional)',
          child: CefField(
            label: 'Instruction',
            controller: notes,
            hint: 'Add delivery notes...',
            maxLines: 2,
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.md),
            child: Text(
              error!,
              style: TextStyle(color: context.c.attention, fontSize: 13),
            ),
          ),
        const SizedBox(height: 16),
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
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3F8),
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            border: Border.all(color: context.c.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.imagePlus,
                color: context.c.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                'Add product photo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FormSection(
          icon: LucideIcons.package,
          title: 'Product Details',
          child: Column(
            children: [
              CefField(
                label: 'Product name',
                controller: name,
                errorText: errors['name'],
              ),
              CefField(
                label: 'Description',
                controller: description,
                maxLines: 2,
              ),
              CefField(
                label: 'Price (RM)',
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: errors['price'],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CefCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Show this product in your storefront',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              CefSwitch(
                value: active,
                onChanged: (v) => setState(() => active = v),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              error!,
              style: TextStyle(color: context.c.attention, fontSize: 13),
            ),
          ),
        const SizedBox(height: 16),
        CefButton(
          widget.isNew ? 'Add Product' : 'Save Changes',
          busy: busy,
          onTap: _save,
        ),
      ],
    );
  }
}

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
    // Rendered on the blue hero card, so every colour here is white-on-blue:
    // reached nodes are solid white with a blue glyph, future nodes are a
    // translucent white wash.
    const icons = [
      LucideIcons.package,
      LucideIcons.truck,
      LucideIcons.circleCheck,
    ];
    final blue = context.c.info;
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
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached
                          ? Colors.white
                          : Colors.white.withValues(alpha: .22),
                    ),
                    child: Icon(
                      icons[index],
                      size: 17,
                      color: reached
                          ? blue
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
              const SizedBox(height: 7),
              Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
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

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => CefCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.c.info, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

/// A field-shaped row that opens something instead of accepting typing --
/// the reference draws Address and Items this way (placeholder + chevron).
class _PickerField extends StatelessWidget {
  const _PickerField({required this.hint, required this.onTap});
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.inputRadius),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(Sizes.inputRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Runs a backend action and only reports success when the call returns.
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.action,
    required this.onDone,
  });
  final String label;
  final Future<void> Function() action;
  final Future<void> Function() onDone;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool busy = false;
  String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CefButton(
        widget.label,
        busy: busy,
        onTap: () async {
          setState(() {
            busy = true;
            error = null;
          });
          try {
            await widget.action();
            await widget.onDone();
          } on RepositoryError catch (e) {
            if (mounted) setState(() => error = e.message);
          } finally {
            if (mounted) setState(() => busy = false);
          }
        },
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: Gap.sm),
          child: Text(
            error!,
            style: TextStyle(color: context.c.attention, fontSize: 13),
          ),
        ),
    ],
  );
}
