import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/plans.dart';
import '../shell.dart';
import '../widgets.dart';

// Subscription flow (V-50, V-51, V-52, V-54; D-54). Plans come from
// data/plans.dart (the pricing candidate); payments are demo-only and use
// the one centred status modal (runAsyncFeedback) for processing, success
// and failure.

String _rm(int amount) => 'RM${_thousands(amount)}';

String _thousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

String _per(BillingCycle cycle) =>
    cycle == BillingCycle.yearly ? '/ year' : '/ month';

String _date(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// Price line: large amount + quiet period ("RM199 / month").
class _Price extends StatelessWidget {
  const _Price(this.amount, this.cycle, {this.large = false});
  final int amount;
  final BillingCycle cycle;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: _rm(amount),
            style: (large ? text.titleLarge : text.titleMedium),
          ),
          TextSpan(text: '  ${_per(cycle)}', style: text.bodySmall),
        ],
      ),
    );
  }
}

/// A feature line with a small check.
class _Feature extends StatelessWidget {
  const _Feature(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(LucideIcons.check, size: 16, color: CefColors.brand),
        ),
        const SizedBox(width: Gap.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------- V-50

/// V-50 — Subscription: the current plan (typography, no decorative plan
/// icon), this cycle's usage, then flat action rows.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final plan = app.currentPlan;
    // Demo usage for this cycle; riders / zones / team mirror the demo data.
    final usage = [
      (LucideIcons.package, 'Deliveries', 620, plan.deliveries),
      (LucideIcons.users, 'Riders', 4, plan.riders),
      (LucideIcons.mapPin, 'Zones', 6, plan.zones),
      (LucideIcons.userCog, 'Team members', 3, plan.teamUsers),
    ];
    return PageBody(
      children: [
        // Current plan: a quiet tinted summary surface.
        Container(
          padding: const EdgeInsets.all(Gap.xl),
          decoration: BoxDecoration(
            color: CefColors.brandTint,
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${plan.name} plan', style: text.titleMedium),
                  ),
                  const StatusChip('Active', success: true),
                ],
              ),
              const SizedBox(height: Gap.xs),
              _Price(
                plan.priceFor(app.currentCycle),
                app.currentCycle,
                large: true,
              ),
              const SizedBox(height: Gap.xs),
              Text(plan.tagline, style: text.bodySmall),
              if (!plan.isFree) ...[
                const SizedBox(height: Gap.md),
                Text(
                  'Next renewal on ${_date(app.nextRenewal)}',
                  style: text.bodySmall?.copyWith(color: context.c.textPrimary),
                ),
              ],
            ],
          ),
        ),
        SectionHeading(
          'Current usage',
          trailing: Text('This cycle', style: text.bodySmall),
        ),
        for (final (icon, label, used, cap) in usage)
          _UsageRow(icon: icon, label: label, used: used, cap: cap),
        const SizedBox(height: Gap.lg),
        CefListRow(
          title: 'Change plan',
          icon: LucideIcons.arrowLeftRight,
          onTap: () => app.go(VRoute.choosePlan),
        ),
        CefListRow(
          title: 'Payment method',
          icon: LucideIcons.creditCard,
          onTap: () => showNotWiredYetSnackBar(context, 'Payment methods'),
        ),
        CefListRow(
          title: 'Billing history',
          icon: LucideIcons.receipt,
          onTap: () => app.go(VRoute.billingHistory),
        ),
      ],
    );
  }
}

/// One usage line: label, "used / cap" and a thin progress bar; an
/// unlimited cap shows the count without a bar.
class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.icon,
    required this.label,
    required this.used,
    required this.cap,
  });
  final IconData icon;
  final String label;
  final int used;
  final int? cap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    final value = cap == null
        ? '${_thousands(used)} · Unlimited'
        : '${_thousands(used)} / ${_thousands(cap!)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: Row(
        children: [
          SizedBox(
            width: Sizes.avatar,
            child: Icon(icon, size: Sizes.icon, color: c.iconColor),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(label, style: text.titleSmall)),
                    Text(
                      value,
                      style: text.bodySmall?.copyWith(color: c.textPrimary),
                    ),
                  ],
                ),
                if (cap != null) ...[
                  const SizedBox(height: Gap.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Gap.xs),
                    child: LinearProgressIndicator(
                      value: (used / cap!).clamp(0, 1).toDouble(),
                      minHeight: 6,
                      color: CefColors.brand,
                      backgroundColor: c.subtle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- V-51

/// V-51 — Choose a plan: Monthly / Yearly, then the plans. The selected
/// plan is a restrained Anchor Blue treatment (tint, thin outline, check);
/// mustard appears only as the small "Most Popular" badge.
class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({super.key});

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  late final _app = AppScope.read(context);
  late String _selected = _app.currentPlanId;
  late BillingCycle _cycle = _app.currentCycle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final unchanged =
        _selected == app.currentPlanId && _cycle == app.currentCycle;
    return PageBody(
      bottom: CefButton(
        unchanged ? 'Current plan' : 'Continue',
        onTap: unchanged
            ? null
            : () => app.go(
                VRoute.reviewPayment,
                entityId: '$_selected:${_cycle.name}',
              ),
      ),
      children: [
        Text(
          'Select the plan that fits your business.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: Gap.md),
        _CycleToggle(
          cycle: _cycle,
          onChanged: (c) => setState(() => _cycle = c),
        ),
        const SizedBox(height: Gap.md),
        for (final plan in subscriptionPlans) ...[
          _PlanOption(
            plan: plan,
            cycle: _cycle,
            selected: plan.id == _selected,
            current: plan.id == app.currentPlanId,
            onTap: () => setState(() => _selected = plan.id),
          ),
          const SizedBox(height: Gap.md),
        ],
        Text(
          'Plans and prices are the current pricing candidate.',
          textAlign: TextAlign.center,
          style: text.labelSmall,
        ),
      ],
    );
  }
}

class _CycleToggle extends StatelessWidget {
  const _CycleToggle({required this.cycle, required this.onChanged});
  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    Widget option(BillingCycle value, String label, {String? note}) {
      final on = cycle == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? CefColors.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(Sizes.buttonRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
              // Scales down rather than overflowing at large text sizes.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: text.labelLarge?.copyWith(
                        color: on ? Colors.white : c.textPrimary,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(width: Gap.xs),
                      Text(
                        note,
                        style: text.labelSmall?.copyWith(
                          color: on ? Colors.white : c.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Gap.xs),
      decoration: BoxDecoration(
        color: c.subtle,
        borderRadius: BorderRadius.circular(Sizes.buttonRadius),
      ),
      child: Row(
        children: [
          option(BillingCycle.monthly, 'Monthly'),
          option(BillingCycle.yearly, 'Yearly', note: '2 months free'),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.cycle,
    required this.selected,
    required this.current,
    required this.onTap,
  });
  final SubscriptionPlan plan;
  final BillingCycle cycle;
  final bool selected, current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(Sizes.cardRadius);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? CefColors.brandTint : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? CefColors.brand : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: Gap.sm,
                        runSpacing: Gap.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            plan.name,
                            style: text.titleSmall?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (plan.mostPopular) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Gap.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CefColors.ceffloMustard,
                                borderRadius: BorderRadius.circular(
                                  Sizes.buttonRadius,
                                ),
                              ),
                              child: Text(
                                'Most Popular',
                                style: text.labelSmall?.copyWith(
                                  color: CefColors.onAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (current) ...[
                            Text('Current', style: text.labelSmall),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: Sizes.icon,
                      color: selected ? CefColors.brand : c.border,
                    ),
                  ],
                ),
                const SizedBox(height: Gap.xs),
                _Price(plan.priceFor(cycle), cycle),
                const SizedBox(height: 2),
                Text(plan.tagline, style: text.bodySmall),
                const SizedBox(height: Gap.xs),
                for (final f in plan.features) _Feature(f),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- V-52

/// V-52 — Review & Payment: the selected plan, billing cycle, total and
/// payment method, then Subscribe. Processing / success / failure are the
/// centred status modal over this screen.
class ReviewPaymentScreen extends StatefulWidget {
  const ReviewPaymentScreen({super.key, required this.selection});

  /// "planId:cycle", e.g. "operate:monthly".
  final String selection;

  @override
  State<ReviewPaymentScreen> createState() => _ReviewPaymentScreenState();
}

class _ReviewPaymentScreenState extends State<ReviewPaymentScreen> {
  late final SubscriptionPlan _plan = planById(
    widget.selection.split(':').first,
  );
  late final BillingCycle _cycle = BillingCycle.values.firstWhere(
    (c) => c.name == widget.selection.split(':').last,
    orElse: () => BillingCycle.monthly,
  );
  String _method = 'card';
  bool _busy = false;

  Future<void> _subscribe() async {
    if (_busy) return; // no duplicate submission
    setState(() => _busy = true);
    final app = AppScope.read(context);
    final ok = await runAsyncFeedback(
      context,
      action: () => app.subscribe(_plan, _cycle),
      processingTitle: 'Processing payment',
      processingSubtitle: 'Please wait while we confirm your payment.',
      successTitle: 'Subscription active',
      failureTitle: 'Payment unsuccessful',
      failureMessage: "We couldn't process your payment.\nNo charge was made.",
      failureSecondaryLabel: 'Change payment method',
      onFailureSecondary: () {},
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) app.backTo(VRoute.subscription);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final text = Theme.of(context).textTheme;
    final total = _plan.priceFor(_cycle);
    return PageBody(
      // Disabled while the payment modal runs (no duplicate submission);
      // the modal itself shows progress.
      bottom: CefButton('Subscribe', onTap: _busy ? null : _subscribe),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_plan.name} plan', style: text.titleMedium),
                  _Price(total, _cycle),
                ],
              ),
            ),
            CefLink('Change', onTap: app.back),
          ],
        ),
        const SizedBox(height: Gap.xs),
        for (final f in _plan.features) _Feature(f),
        const SizedBox(height: Gap.lg),
        const CefDivider(),
        CefListRow(
          title: 'Billing cycle',
          trailing: Text(
            _cycle == BillingCycle.yearly ? 'Yearly' : 'Monthly',
            style: text.bodyMedium?.copyWith(color: c.textPrimary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Gap.md),
          child: Row(
            children: [
              Expanded(child: Text('Total', style: text.titleMedium)),
              Text(_rm(total), style: text.titleMedium),
            ],
          ),
        ),
        if (!_plan.isFree) ...[
          const SectionHeading('Payment method'),
          for (final (id, title, subtitle, icon) in const [
            (
              'card',
              'Credit / Debit card',
              '•••• 4242',
              LucideIcons.creditCard,
            ),
            ('fpx', 'FPX online banking', null, LucideIcons.landmark),
          ])
            CefListRow(
              title: title,
              subtitle: subtitle,
              icon: icon,
              showChevron: false,
              trailing: Icon(
                _method == id
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: Sizes.icon,
                color: _method == id ? CefColors.brand : c.border,
              ),
              onTap: () => setState(() => _method = id),
            ),
        ],
        if (app.repo.isDemo) ...[
          const SizedBox(height: Gap.md),
          Text(
            'Demo — no real payment is processed.',
            textAlign: TextAlign.center,
            style: text.labelSmall,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- V-54

/// V-54 — Billing History: one cardless row per invoice (date, amount,
/// plan · period, Paid, download).
class BillingHistoryScreen extends StatelessWidget {
  const BillingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final invoices = app.invoices;
    return PageBody(
      children: [
        if (invoices.isEmpty)
          const StateBlock.empty('No invoices yet.')
        else
          for (final inv in invoices)
            CefListRow(
              title: _date(inv.date),
              subtitle:
                  '${_rm(inv.amount)}.00 · ${inv.planName} · '
                  '${inv.cycle == BillingCycle.yearly ? 'Yearly' : 'Monthly'}',
              showChevron: false,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusChip(inv.paid ? 'Paid' : 'Due', success: inv.paid),
                  IconAction(
                    icon: LucideIcons.download,
                    tooltip: 'Download invoice',
                    color: c.iconColor,
                    onTap: () =>
                        showNotWiredYetSnackBar(context, 'Invoice download'),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
