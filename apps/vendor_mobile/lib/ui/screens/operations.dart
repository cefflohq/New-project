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
        children: [StateBlock.empty('No business is linked to this account yet.')],
      );
    }
    return AsyncView<List<VendorOrder>>(
      key: ValueKey('today-${business.id}'),
      load: () => app.repo.orders(business.id),
      builder: (context, orders, reload) {
        final ongoing = orders.where((o) => OrderTab.ongoing.accepts(o.status)).toList();
        final ready = orders.where((o) => o.status == DeliveryStatus.readyForPickup).toList();
        final issues = orders.where((o) => o.status == DeliveryStatus.issue).toList();
        final delivered = orders.where((o) => o.status == DeliveryStatus.delivered).toList();
        final pendingApproval = orders.where((o) => o.status == DeliveryStatus.created).toList();

        return PageBody(
          onRefresh: reload,
          children: [
            Row(
              children: [
                Expanded(child: KpiTile(label: 'Total orders', value: '${orders.length}')),
                const SizedBox(width: Gap.cardGap),
                Expanded(child: KpiTile(label: 'Ready', value: '${ready.length}')),
              ],
            ),
            const SizedBox(height: Gap.cardGap),
            Row(
              children: [
                Expanded(child: KpiTile(label: 'Issues', value: '${issues.length}')),
                const SizedBox(width: Gap.cardGap),
                Expanded(child: KpiTile(label: 'Delivered', value: '${delivered.length}')),
              ],
            ),

            const SectionHeading('Needs attention'),
            if (issues.isEmpty && pendingApproval.isEmpty)
              const StateBlock.empty('Nothing needs your attention right now.')
            else ...[
              for (final o in [...issues, ...pendingApproval].take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.cardGap),
                  child: CefListRow(
                    title: o.status == DeliveryStatus.issue
                        ? 'Delivery issue · ${o.reference}'
                        : 'Awaiting approval · ${o.reference}',
                    subtitle: '${o.customerName} · ${o.deliveryAddress}',
                    icon: o.status == DeliveryStatus.issue
                        ? LucideIcons.triangleAlert
                        : LucideIcons.clock,
                    onTap: () => app.go(VRoute.orderDetail, entityId: o.id),
                  ),
                ),
            ],

            const SectionHeading('Delivery planning'),
            CefCard(
              onTap: () => app.switchTab(NavTab.zones),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ongoing.length} order${ongoing.length == 1 ? '' : 's'} in progress',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Open Zones to prepare and dispatch delivery plans.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 18, color: context.c.textSecondary),
                ],
              ),
            ),

            const SectionHeading('Recent delivery'),
            if (delivered.isEmpty)
              const StateBlock.empty('No completed deliveries yet.')
            else
              // Audit fix 2: each card is bound to its own order id.
              for (final o in delivered.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.cardGap),
                  child: CefListRow(
                    title: o.customerName.isEmpty ? o.reference : o.customerName,
                    subtitle: o.completedAt == null
                        ? o.deliveryAddress
                        : '${o.deliveryAddress} · ${_formatTime(o.completedAt!)}',
                    icon: LucideIcons.circleCheck,
                    onTap: () => app.go(VRoute.orderDetail, entityId: o.id),
                  ),
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
      return const PageBody(children: [StateBlock.empty('No business linked.')]);
    }
    return AsyncView<List<VendorOrder>>(
      key: ValueKey('orders-${business.id}'),
      load: () => app.repo.orders(business.id),
      builder: (context, orders, reload) {
        final visible = orders.where((o) => tab.accepts(o.status)).toList();
        return PageBody(
          onRefresh: reload,
          children: [
            SegmentedTabs(
              labels: OrderTab.values.map((t) => t.label).toList(),
              active: tab.label,
              onChange: (l) => setState(
                () => tab = OrderTab.values.firstWhere((t) => t.label == l),
              ),
            ),
            const SizedBox(height: Gap.md),
            SizedBox(
              width: double.infinity,
              child: CefButton(
                'New order',
                secondary: true,
                onTap: () => app.go(VRoute.newOrder),
              ),
            ),
            const SizedBox(height: Gap.md),
            if (visible.isEmpty)
              StateBlock.empty('No ${tab.label.toLowerCase()} orders.')
            else
              for (final o in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.cardGap),
                  child: CefListRow(
                    title: o.reference,
                    subtitle: '${o.customerName} · ${o.deliveryAddress}',
                    trailing: StatusChip(
                      o.status.label,
                      attention: o.status == DeliveryStatus.issue,
                    ),
                    onTap: () => app.go(VRoute.orderDetail, entityId: o.id),
                  ),
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
                child: Text(order.reference, style: Theme.of(context).textTheme.titleLarge),
              ),
              StatusChip(
                order.status.label,
                attention: order.status == DeliveryStatus.issue,
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          CefCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv(context, 'Customer', order.customerName),
                _kv(context, 'Phone', order.customerPhone),
                _kv(context, 'Address', order.deliveryAddress),
                if ((order.notes ?? '').isNotEmpty) _kv(context, 'Notes', order.notes!),
                _kv(context, 'Created', _formatTime(order.createdAt)),
                if (order.origin != null) _kv(context, 'Origin', order.origin!),
                _kv(context, 'Zone', order.zoneId == null ? 'Not assigned' : 'Assigned'),
                _kv(
                  context,
                  'Rider',
                  order.assignedRiderId == null ? 'Not assigned' : 'Assigned',
                ),
              ],
            ),
          ),
          const SectionHeading('Items'),
          if (order.items.isEmpty)
            const StateBlock.empty('No line items recorded for this order.')
          else
            CefCard(
              child: Column(
                children: [
                  for (final i in order.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '×${i.quantity}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: Gap.section),
          if (order.canApprove)
            _ActionButton(
              label: 'Approve order',
              action: () => app.repo.approveOrder(order.id),
              onDone: reload,
            ),
          if (order.canEdit) ...[
            const SizedBox(height: Gap.cardGap),
            CefButton(
              'Edit order',
              secondary: true,
              onTap: () => app.go(VRoute.editOrder, entityId: order.id),
            ),
          ],
          // Audit fix 3: no planning CTA once the order is terminal.
          if (order.canPlan) ...[
            const SizedBox(height: Gap.cardGap),
            CefButton(
              'Open zones to plan',
              secondary: true,
              onTap: () => app.switchTab(NavTab.zones),
            ),
          ],
          if (order.isTerminal)
            Padding(
              padding: const EdgeInsets.only(top: Gap.md),
              child: Text(
                'This order is ${order.status.label.toLowerCase()}. No further delivery action is available.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(k, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            v.isEmpty ? '—' : v,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    ),
  );
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
    if (name.text.trim().isEmpty) errors['name'] = 'Customer name is required.';
    if (phone.text.trim().length < 7) errors['phone'] = 'Enter a valid phone number.';
    if (address.text.trim().isEmpty) errors['address'] = 'Delivery address is required.';
    setState(() {});
    return errors.isEmpty;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final app = AppScope.read(context);
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
        CefField(label: 'Customer name', controller: name, errorText: errors['name']),
        CefField(
          label: 'Phone number',
          controller: phone,
          keyboardType: TextInputType.phone,
          errorText: errors['phone'],
        ),
        CefField(
          label: 'Delivery address',
          controller: address,
          maxLines: 2,
          errorText: errors['address'],
        ),
        CefField(label: 'Delivery notes', controller: notes, maxLines: 3),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.md),
            child: Text(
              error!,
              style: TextStyle(color: context.c.attention, fontSize: 13),
            ),
          ),
        CefButton(
          widget.isNew ? 'Create order' : 'Save changes',
          busy: busy,
          onTap: _save,
        ),
      ],
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
