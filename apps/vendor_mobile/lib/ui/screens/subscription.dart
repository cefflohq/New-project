import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/plans.dart';
import '../async_view.dart';
import '../shell.dart';
import '../widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

// Subscription flow (V-50, V-51, V-52, V-54; D-54). Plans come from
// data/plans.dart (the pricing candidate); payments are demo-only and use
// the one centred status modal (runAsyncFeedback) for processing, success
// and failure.

String _rm(int amount) => L.rm4(_thousands(amount));

String _thousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

String _per(BillingCycle cycle) =>
    cycle == BillingCycle.yearly ? L.perYear : L.perMonth;

String _date(DateTime d) {
  final months = [
    L.jan,
    L.feb,
    L.mar,
    L.apr,
    L.may,
    L.jun,
    L.jul,
    L.aug,
    L.sep,
    L.oct,
    L.nov,
    L.dec,
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
        Padding(
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
    if (app.repo.isDemo) return const _SubscriptionBody(sub: null);
    // Live: the server's price book + this business's plan and usage.
    return AsyncView<LiveSubscription?>(
      key: ValueKey('subscription-${app.business?.id}'),
      load: app.loadSubscription,
      builder: (context, sub, reload) =>
          _SubscriptionBody(sub: sub, onRefresh: reload),
    );
  }
}

class _SubscriptionBody extends StatelessWidget {
  const _SubscriptionBody({required this.sub, this.onRefresh});

  /// Null in the demo (designed sample usage).
  final LiveSubscription? sub;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final plan = app.currentPlan;
    final live = sub;
    // Usage this cycle: live counts from the server (only completed
    // deliveries count); the demo keeps its designed sample.
    final usage = [
      (
        LucideIcons.package,
        L.deliveries,
        live?.deliveriesUsed ?? 620,
        plan.deliveries,
      ),
      (LucideIcons.users, L.riders, live?.driversActive ?? 4, plan.riders),
      (LucideIcons.mapPin, L.zones, live?.zonesActive ?? 6, plan.zones),
      (
        LucideIcons.userCog,
        L.teamMembers,
        live?.teamUsers ?? 3,
        plan.teamUsers,
      ),
    ];
    final status = live?.status ?? 'active';
    final trial = live?.trialEndsAt;
    return PageBody(
      onRefresh: onRefresh,
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
                    child: Text(L.plan(plan.name), style: text.titleMedium),
                  ),
                  StatusChip(switch (status) {
                    'trial' => L.subTrial,
                    'past_due' => L.subPastDue,
                    'suspended' => L.subSuspended,
                    'cancelled' => L.subCancelled,
                    _ => L.active,
                  }, success: status == 'active' || status == 'trial'),
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
              // Renewal dates come with a payment provider; live shows
              // only what the server records (a trial end).
              if (live == null && !plan.isFree) ...[
                const SizedBox(height: Gap.md),
                Text(
                  L.nextRenewal(_date(app.nextRenewal)),
                  style: text.bodySmall?.copyWith(color: context.c.textPrimary),
                ),
              ],
              if (trial != null) ...[
                const SizedBox(height: Gap.md),
                Text(
                  L.trialEnds(_date(trial.toLocal())),
                  style: text.bodySmall,
                ),
              ],
            ],
          ),
        ),
        SectionHeading(
          L.currentUsage,
          trailing: Text(L.cycle, style: text.bodySmall),
        ),
        for (final (icon, label, used, cap) in usage)
          _UsageRow(icon: icon, label: label, used: used, cap: cap),
        const SizedBox(height: Gap.lg),
        CefListRow(
          title: L.changePlan,
          icon: LucideIcons.arrowLeftRight,
          onTap: () => app.go(VRoute.choosePlan),
        ),
        CefListRow(
          title: L.paymentMethod2,
          icon: LucideIcons.creditCard,
          onTap: () => showNotWiredYetSnackBar(context, L.paymentMethods),
        ),
        CefListRow(
          title: L.billingHistory2,
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
        ? L.unlimited(_thousands(used))
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
        unchanged ? L.currentPlan : L.continueText,
        onTap: unchanged
            ? null
            : () => app.go(
                VRoute.reviewPayment,
                entityId: '$_selected:${_cycle.name}',
              ),
      ),
      children: [
        Text(L.selectPlanThatFitsBusiness, style: text.bodyMedium),
        const SizedBox(height: Gap.md),
        // Yearly billing is not an approved price: demo only.
        if (app.repo.isDemo) ...[
          _CycleToggle(
            cycle: _cycle,
            onChanged: (c) => setState(() => _cycle = c),
          ),
          const SizedBox(height: Gap.md),
        ],
        for (final plan in app.plans) ...[
          _PlanOption(
            plan: plan,
            cycle: _cycle,
            selected: plan.id == _selected,
            current: plan.id == app.currentPlanId,
            onTap: () => setState(() => _selected = plan.id),
          ),
          const SizedBox(height: Gap.md),
        ],
        if (app.repo.isDemo)
          Text(
            L.plansPricesCurrentPricingCandidate,
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
          option(BillingCycle.monthly, L.monthly),
          option(BillingCycle.yearly, L.yearly, note: L.t2MonthsFree),
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
                                L.mostPopular,
                                style: text.labelSmall?.copyWith(
                                  color: CefColors.onAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (current) ...[
                            Text(L.current, style: text.labelSmall),
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
  late final SubscriptionPlan _plan = AppScope.read(context)
      .planFor(widget.selection.split(':').first);
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
    final live = !app.repo.isDemo;
    // Live: the server stops the change before payment (not enabled yet),
    // so the honest outcome is the failure state -- nothing changes and
    // nothing is charged.
    final ok = await runAsyncFeedback(
      context,
      action: () => app.subscribe(_plan, _cycle),
      processingTitle: live ? L.checkingYourPlan : L.processingPayment,
      processingSubtitle: live
          ? L.pleaseWaitMoment
          : L.pleaseWaitWhileWeConfirmPayment,
      successTitle: L.subscriptionActive,
      failureTitle: live
          ? L.planChangeNotAvailableTitle
          : L.paymentUnsuccessful,
      failureMessage: live
          ? L.planChangeNotAvailableBody
          : L.weCouldntProcessPaymentNoCharge,
      failureSecondaryLabel: live ? L.contactSupport2 : L.changePaymentMethod,
      onFailureSecondary: live
          ? () => launchSupportEmail(
              context,
              subject: L.planQuestionSubject,
              body: _plan.name,
            )
          : () {},
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
      bottom: CefButton(L.subscribe, onTap: _busy ? null : _subscribe),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.plan(_plan.name), style: text.titleMedium),
                  _Price(total, _cycle),
                ],
              ),
            ),
            CefLink(L.change, onTap: app.back),
          ],
        ),
        const SizedBox(height: Gap.xs),
        for (final f in _plan.features) _Feature(f),
        const SizedBox(height: Gap.lg),
        const CefDivider(),
        CefListRow(
          title: L.billingCycle,
          trailing: Text(
            _cycle == BillingCycle.yearly ? L.yearly : L.monthly,
            style: text.bodyMedium?.copyWith(color: c.textPrimary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Gap.md),
          child: Row(
            children: [
              Expanded(child: Text(L.total, style: text.titleMedium)),
              Text(_rm(total), style: text.titleMedium),
            ],
          ),
        ),
        // Saved payment methods come with the payment provider: demo only.
        if (!_plan.isFree && app.repo.isDemo) ...[
          SectionHeading(L.paymentMethod2),
          for (final (id, title, subtitle, icon) in [
            ('card', L.creditDebitCard, '•••• 4242', LucideIcons.creditCard),
            ('fpx', L.fpxOnlineBanking, null, LucideIcons.landmark),
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
            L.demoNoRealPaymentProcessed,
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
          StateBlock.empty(L.noInvoicesYet)
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
                  StatusChip(inv.paid ? L.paid : L.due, success: inv.paid),
                  IconAction(
                    icon: LucideIcons.download,
                    tooltip: L.downloadInvoice,
                    color: c.iconColor,
                    onTap: () =>
                        showNotWiredYetSnackBar(context, L.invoiceDownload),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
