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

String _formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

Widget _plainIcon(BuildContext context, IconData icon, {Color? color}) =>
    Icon(icon, size: Sizes.icon, color: color ?? context.c.iconColor);

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
    return AsyncView<List<VendorOrder>>(
      key: ValueKey('today-${business.id}'),
      load: () => app.repo.orders(business.id),
      builder: (context, orders, reload) {
        final ready = orders
            .where((o) => o.status == DeliveryStatus.readyForPickup)
            .toList();
        final issues = orders
            .where((o) => o.status == DeliveryStatus.issue)
            .toList();
        final delivered = orders
            .where((o) => o.status == DeliveryStatus.delivered)
            .toList();
        final pendingApproval = orders
            .where((o) => o.status == DeliveryStatus.created)
            .toList();

        return PageBody(
          onRefresh: reload,
          children: [
            NavySummaryPanel(
              title: "Today's Orders",
              children: [
                SummaryMetric(label: 'Total', value: '${orders.length}'),
                SummaryMetric(label: 'Ready', value: '${ready.length}'),
                SummaryMetric(label: 'Issue', value: '${issues.length}'),
                SummaryMetric(label: 'Delivered', value: '${delivered.length}'),
              ],
            ),

            const SectionHeading('Needs attention'),
            if (issues.isEmpty && pendingApproval.isEmpty)
              const StateBlock.empty('Nothing needs your attention right now.')
            else ...[
              for (final o in [...issues, ...pendingApproval].take(4))
                FlatListRow(
                  title: o.reference,
                  subtitle: o.status == DeliveryStatus.issue
                      ? 'Delivery issue · ${o.customerName}'
                      : 'Awaiting approval · ${o.customerName}',
                  leading: o.status == DeliveryStatus.issue
                      ? null
                      : _plainIcon(
                          context,
                          LucideIcons.clock,
                          color: context.c.textSecondary,
                        ),
                  onTap: () => app.go(VRoute.orderDetail, entityId: o.id),
                ),
            ],

            const SectionHeading('Recent delivery'),
            if (delivered.isEmpty)
              const StateBlock.empty('No completed deliveries yet.')
            else
              // Audit fix 2: each card is bound to its own order id.
              for (final o in delivered.take(6))
                FlatListRow(
                  title: o.customerName.isEmpty ? o.reference : o.customerName,
                  subtitle: [
                    if (o.publicRef != null) o.publicRef!,
                    o.deliveryAddress,
                    if (o.completedAt != null) _formatTime(o.completedAt!),
                  ].join(' · '),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: context.c.canvas,
                    child: Icon(
                      LucideIcons.user,
                      size: 18,
                      color: context.c.textSecondary,
                    ),
                  ),
                  trailing: const StatusChip('Delivered'),
                  onTap: () => app.go(VRoute.orderDetail, entityId: o.id),
                ),
            const SizedBox(height: Gap.md),
            YellowFab(
              tooltip: 'Add order',
              onTap: () => app.go(VRoute.newOrder),
            ),
          ],
        );
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
            SearchBarField(
              hint: 'Search order number or customer...',
              onFilter: () {},
            ),
            const SizedBox(height: Gap.md),
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
                  ),
                  onTap: () => app.go(VRoute.orderDetail, entityId: o.id),
                ),
            const SizedBox(height: Gap.md),
            YellowFab(
              tooltip: 'Add order',
              onTap: () => app.go(VRoute.newOrder),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.reference,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Today, ${_formatTime(order.createdAt)}  ·  ${order.items.length} items',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusChip(
                order.status.label,
                attention: order.status == DeliveryStatus.issue,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _OrderProgress(status: order.status),
          const SizedBox(height: 18),
          _DetailCard(
            icon: LucideIcons.user,
            eyebrow: 'Customer',
            title: order.customerName,
            subtitle: order.customerPhone,
            actions: const [LucideIcons.phone, LucideIcons.messageCircle],
          ),
          const SizedBox(height: 10),
          _DetailCard(
            icon: LucideIcons.mapPin,
            eyebrow: 'Deliver to',
            title: order.deliveryAddress,
            subtitle: '59100 Kuala Lumpur',
          ),
          if ((order.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailCard(
              icon: LucideIcons.clipboardList,
              eyebrow: 'Delivery Instruction',
              title: order.notes!,
            ),
          ],
          SectionHeading(
            'Items (${order.items.length})',
            trailing: const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF1769D2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: order.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _ItemTile(item: order.items[index], index: index),
            ),
          ),
          const SizedBox(height: 18),
          _BlueButton(
            order.status == DeliveryStatus.readyForPickup
                ? 'Mark as On the Way'
                : 'Edit Order',
            onTap: () => app.go(VRoute.editOrder, entityId: order.id),
          ),
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
          widget.isNew ? 'Create a new delivery order' : 'Update order details',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _FormSection(
          icon: LucideIcons.user,
          title: 'Customer',
          child: Column(
            children: [
              CefField(
                label: 'Customer name',
                controller: name,
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
          title: 'Delivery Address',
          child: Column(
            children: [
              CefField(
                label: 'Address',
                controller: address,
                maxLines: 2,
                errorText: errors['address'],
              ),
              Container(
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.mapPin,
                    color: CefColors.accent,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _ActionRow(
          icon: LucideIcons.package,
          title: 'Order Items',
          subtitle: 'Add items',
        ),
        const SizedBox(height: 12),
        _FormSection(
          icon: LucideIcons.clipboardList,
          title: 'Delivery Instruction (Optional)',
          child: CefField(label: 'Instruction', controller: notes, maxLines: 2),
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
        _BlueButton(
          widget.isNew ? 'Create Order' : 'Update Order',
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
    const labels = ['Ready', 'Picked Up', 'On the Way', 'Delivered'];
    final active = switch (status) {
      DeliveryStatus.readyForPickup => 0,
      DeliveryStatus.pickedUp => 1,
      DeliveryStatus.outForDelivery || DeliveryStatus.arrived => 2,
      DeliveryStatus.delivered => 3,
      _ => 0,
    };
    return Row(
      children: List.generate(
        labels.length,
        (index) => Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index <= active
                            ? const Color(0xFF1769D2)
                            : const Color(0xFFDCE1EA),
                      ),
                    ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= active
                          ? const Color(0xFF1769D2)
                          : const Color(0xFFDCE1EA),
                    ),
                    child: Icon(
                      index <= active ? LucideIcons.check : LucideIcons.circle,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  if (index < labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < active
                            ? const Color(0xFF1769D2)
                            : const Color(0xFFDCE1EA),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[index],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });
  final IconData icon;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<IconData> actions;

  @override
  Widget build(BuildContext context) => CefCard(
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF1769D2), size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF0F5FF),
              child: Icon(action, color: const Color(0xFF1769D2), size: 19),
            ),
          ),
      ],
    ),
  );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.index});
  final OrderItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final icons = [
      LucideIcons.cakeSlice,
      LucideIcons.coffee,
      LucideIcons.cookie,
    ];
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            width: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icons[index % icons.length], color: CefColors.navy),
          ),
          const SizedBox(height: 5),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
          Text(
            '${item.quantity} × RM${(item.unitPrice ?? 0).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => CefCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: CefColors.navy),
            const SizedBox(width: 10),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => CefCard(
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF1769D2)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Icon(LucideIcons.chevronRight, size: 19),
      ],
    ),
  );
}

class _BlueButton extends StatelessWidget {
  const _BlueButton(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF075BC7),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          const Icon(LucideIcons.chevronRight, size: 18),
        ],
      ),
    ),
  );
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
