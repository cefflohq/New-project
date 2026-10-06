/// Driver paid changes (Founder 2026-10-06): a vehicle-type or plate change
/// costs RM50 per change, paid in the app — Curlec in Malaysia, Stripe
/// internationally.
///
/// The UI and this contract are in place; no provider is connected yet (no
/// API keys, global V1 gate "Payments: HOLD, never fake success"). Connecting
/// one means implementing [DriverPayments] for it and enabling it with the
/// `CEFFLO_DRIVER_PAYMENTS` build flag — the screens stay the same.
library;

enum PaymentProvider { curlec, stripe }

/// What the Driver picks: real payment methods, never a provider name
/// (Founder 2026-10-06). Malaysian methods run through Curlec; international
/// cards / wallets through Stripe.
enum PaymentMethod {
  fpx, // local online banking (FPX)
  touchNGo,
  grabPay,
  boost,
  shopeePay,
  atome, // pay later
  card, // Visa / Mastercard (Malaysian cards via Curlec)
  internationalCard, // Visa / Mastercard / Amex via Stripe
  applePay,
  googlePay,
}

extension PaymentMethodX on PaymentMethod {
  PaymentProvider get provider => switch (this) {
    PaymentMethod.internationalCard ||
    PaymentMethod.applePay ||
    PaymentMethod.googlePay => PaymentProvider.stripe,
    _ => PaymentProvider.curlec,
  };
}

/// The fee for one vehicle / plate change, in sen (RM50.00).
const vehicleChangeFeeSen = 5000;

/// RM50.00 style label for an amount in sen.
String ringgit(int sen) => 'RM${(sen / 100).toStringAsFixed(2)}';

enum PaymentOutcome { paid, cancelled, failed, notConnected }

abstract class DriverPayments {
  /// Takes the vehicle-change fee and, only once the provider confirms it,
  /// lets the server apply the change. Never reports [PaymentOutcome.paid]
  /// without a confirmed payment.
  Future<PaymentOutcome> payVehicleChange({
    required PaymentMethod method,
    required String vehicleType,
    required String plate,
  });
}

/// No provider connected: every attempt reports [PaymentOutcome.notConnected]
/// and nothing is changed.
class UnconnectedPayments implements DriverPayments {
  const UnconnectedPayments();

  @override
  Future<PaymentOutcome> payVehicleChange({
    required PaymentMethod method,
    required String vehicleType,
    required String plate,
  }) async => PaymentOutcome.notConnected;
}

/// The payments in use. Stays [UnconnectedPayments] until a provider is
/// wired and the build enables it.
const DriverPayments driverPayments = UnconnectedPayments();

/// Malaysian Drivers (+60 / local numbers) start on online banking;
/// others on an international card.
PaymentMethod defaultMethodFor(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final local = phone.trim().startsWith('0') || digits.startsWith('60');
  return local ? PaymentMethod.fpx : PaymentMethod.internationalCard;
}
