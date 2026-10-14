import 'package:intl/intl.dart';

/// Money in the business currency (ISO 4217, `businesses.currency`), never a
/// hard-coded "RM". Malaysia is MYR; other country packs set their own code.
class Money {
  Money._();

  /// The active currency; MYR until a business with another currency is set.
  static String currency = 'MYR';

  /// Currencies with no minor unit in daily use.
  static const _zeroDecimals = {
    'IDR', 'VND', 'KHR', 'LAK', 'MMK', 'TWD', 'JPY', 'KRW',
  };

  static void setCurrency(String? code) {
    if (code != null && RegExp(r'^[A-Z]{3}$').hasMatch(code)) currency = code;
  }

  /// Currency symbol, e.g. "RM", "S$", "Rp"; falls back to the ISO code.
  static String symbol([String? code]) {
    final c = code ?? currency;
    try {
      return NumberFormat.simpleCurrency(locale: 'en', name: c).currencySymbol;
    } catch (_) {
      return c;
    }
  }

  /// `format(3.5)` -> "RM3.50"; `format(3, trim: true)` -> "RM3".
  static String format(num amount, {String? code, bool trim = false}) {
    final c = code ?? currency;
    final whole = amount == amount.roundToDouble();
    final digits = _zeroDecimals.contains(c) || (trim && whole) ? 0 : 2;
    return '${symbol(c)}${amount.toStringAsFixed(digits)}';
  }
}
