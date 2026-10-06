import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/driver_models.dart' show vehicleTypeLabel;
import '../../data/payments.dart';
import '../brand.dart' show NavyBackdrop;
import '../widgets.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// Change fee (Founder 2026-10-06): a vehicle-type or plate change costs
/// RM50, paid with Curlec (Malaysia) or Stripe (international). The change is
/// applied only after a confirmed payment; until a provider is connected the
/// Pay action says so and nothing changes (never a fake success).
class VehicleChangePaymentScreen extends StatefulWidget {
  const VehicleChangePaymentScreen({
    super.key,
    required this.fromVehicle,
    required this.toVehicle,
    required this.fromPlate,
    required this.toPlate,
  });

  final String fromVehicle, toVehicle, fromPlate, toPlate;

  @override
  State<VehicleChangePaymentScreen> createState() =>
      _VehicleChangePaymentScreenState();
}

class _VehicleChangePaymentScreenState
    extends State<VehicleChangePaymentScreen> {
  late PaymentProvider _provider = defaultProviderFor(
    AppScope.read(context).profile.phone,
  );
  bool _busy = false;

  Future<void> _pay() async {
    setState(() => _busy = true);
    final outcome = await driverPayments.payVehicleChange(
      provider: _provider,
      vehicleType: widget.toVehicle,
      plate: widget.toPlate,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PaymentOutcome.paid:
        await AppScope.read(context).loadSession();
        if (!mounted) return;
        showCefToast(context, L.vehicleChangePaid);
        Navigator.of(context).pop(true);
      case PaymentOutcome.notConnected:
        await showCeffloSheet<void>(
          context,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.gutter,
              0,
              Gap.gutter,
              Gap.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetGrabber(),
                const SizedBox(height: 6),
                Text(
                  L.paymentsNotConnectedTitle,
                  textAlign: TextAlign.center,
                  style: context.t.titleLarge,
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  L.paymentsNotConnectedBody,
                  textAlign: TextAlign.center,
                  style: context.t.bodyMedium?.copyWith(
                    color: context.c.textSecondary,
                  ),
                ),
                const SizedBox(height: Gap.lg),
                Builder(
                  builder: (sheet) => CeffloPrimaryButton(
                    L.okGotIt,
                    onTap: () => Navigator.of(sheet).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      case PaymentOutcome.cancelled:
        break;
      case PaymentOutcome.failed:
        showCefToast(context, L.paymentFailed, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    Widget change(String label, String from, String to) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.t.bodyMedium?.copyWith(color: c.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              from == to ? to : '$from  →  $to',
              textAlign: TextAlign.end,
              style: context.t.titleSmall,
            ),
          ),
        ],
      ),
    );
    Widget method(PaymentProvider p, String title, String subtitle) {
      final on = _provider == p;
      return Padding(
        padding: const EdgeInsets.only(bottom: Gap.sm),
        child: CeffloCard(
          shadow: false,
          onTap: () => setState(() => _provider = p),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                p == PaymentProvider.curlec
                    ? LucideIcons.landmark
                    : LucideIcons.creditCard,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.t.titleSmall),
                    Text(
                      subtitle,
                      style: context.t.bodySmall?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                on ? LucideIcons.circleCheck : LucideIcons.circle,
                size: 22,
                color: on ? CefColors.navy : c.textSecondary,
              ),
            ],
          ),
        ),
      );
    }

    // Pushed over the shell as its own route: paint the shell's navy
    // backdrop so the header matches every other Driver screen.
    return NavyBackdrop(
      watermark: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CeffloNavySheetScaffold(
          header: CeffloScreenHeader(
            title: L.changeFee,
            onBack: () => Navigator.of(context).pop(false),
            onBell: () => app.go(DRoute.notifications),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CeffloCard(
                shadow: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    change(
                      L.vehicleType,
                      vehicleTypeLabel(widget.fromVehicle),
                      vehicleTypeLabel(widget.toVehicle),
                    ),
                    change(
                      L.registrationPlateNumber,
                      widget.fromPlate.isEmpty ? '—' : widget.fromPlate,
                      widget.toPlate.isEmpty ? '—' : widget.toPlate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(L.changeFee, style: context.t.titleMedium),
                  ),
                  Text(
                    ringgit(vehicleChangeFeeSen),
                    style: context.t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.lg),
              Text(L.paymentMethod, style: context.t.titleMedium),
              const SizedBox(height: Gap.sm),
              method(PaymentProvider.curlec, 'Curlec', L.curlecMethods),
              method(PaymentProvider.stripe, 'Stripe', L.stripeMethods),
              const SizedBox(height: Gap.sm),
              CeffloNote(icon: LucideIcons.info, body: L.changeAfterPayment),
            ],
          ),
          footer: CeffloPrimaryButton(
            L.payAmount(ringgit(vehicleChangeFeeSen)),
            busy: _busy,
            onTap: _busy ? null : _pay,
          ),
        ),
      ),
    );
  }
}
