import 'dart:ui' show PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'money.dart';

/// One country pack from `public.countries` (Country Pack Guideline §3).
class CountryPack {
  const CountryPack({
    required this.iso2,
    required this.nameEn,
    required this.region,
    required this.currency,
    required this.phoneCode,
    this.postcodeRegex,
    this.minPayPerDrop = 0,
    this.timezone,
  });

  final String iso2, nameEn, region, currency, phoneCode;
  final String? postcodeRegex;

  /// The country's main IANA time zone (first of `countries.timezones`).
  final String? timezone;
  final num minPayPerDrop;

  static const malaysia = CountryPack(
    iso2: 'MY',
    nameEn: 'Malaysia',
    region: 'asia',
    currency: 'MYR',
    phoneCode: '+60',
    postcodeRegex: r'^\d{5}$',
    minPayPerDrop: 3,
    timezone: 'Asia/Kuala_Lumpur',
  );

  factory CountryPack.fromRow(Map<String, dynamic> r) => CountryPack(
    iso2: r['iso2'] as String,
    nameEn: (r['name_en'] as String?) ?? r['iso2'] as String,
    region: (r['region'] as String?) ?? 'asia',
    currency: (r['currency'] as String?) ?? 'MYR',
    phoneCode: (r['phone_code'] as String?) ?? '+60',
    postcodeRegex: r['postcode_regex'] as String?,
    minPayPerDrop: (r['min_pay_per_drop'] as num?) ?? 0,
    timezone: (r['timezones'] as List?)?.cast<String>().firstOrNull,
  );

  bool postcodeOk(String value) {
    final v = value.trim();
    final re = postcodeRegex;
    if (v.isEmpty || re == null) return true;
    return RegExp(re, caseSensitive: false).hasMatch(v);
  }
}

/// The country this device works in. Malaysia until a business or the
/// user's choice says otherwise; never blocks the app if loading fails.
class Country {
  Country._();

  static const _key = 'cefflo.country';
  static CountryPack current = CountryPack.malaysia;
  static List<CountryPack> selectable = const [CountryPack.malaysia];

  /// Loads the live / beta packs and restores this device's choice (else
  /// the device region when selectable, else Malaysia).
  static Future<void> init(SupabaseClient client) async {
    try {
      final rows = await client
          .from('countries')
          .select()
          .inFilter('status', ['live', 'beta'])
          .order('sort_order');
      final list = [
        for (final r in (rows as List).cast<Map<String, dynamic>>())
          CountryPack.fromRow(r),
      ];
      if (list.isNotEmpty) selectable = list;
    } catch (_) {}
    String? saved;
    try {
      saved = (await SharedPreferences.getInstance()).getString(_key);
    } catch (_) {}
    final region = PlatformDispatcher.instance.locale.countryCode;
    _apply(byCode(saved) ?? byCode(region) ?? CountryPack.malaysia);
  }

  static CountryPack? byCode(String? iso2) {
    for (final c in selectable) {
      if (c.iso2 == iso2) return c;
    }
    return null;
  }

  /// Explicit choice on this device (and on the profile when signed in).
  static Future<void> choose(CountryPack c, {SupabaseClient? client}) async {
    _apply(c);
    try {
      await (await SharedPreferences.getInstance()).setString(_key, c.iso2);
    } catch (_) {}
    if (client?.auth.currentUser != null) {
      try {
        await client!.rpc('set_my_country', params: {'p_iso2': c.iso2});
      } catch (_) {}
    }
  }

  /// A business's country wins over the device choice while it is active.
  static void useBusinessCountry(String? iso2) {
    final c = byCode(iso2);
    if (c != null) _apply(c);
  }

  static void _apply(CountryPack c) {
    current = c;
    Money.setCurrency(c.currency);
  }

  /// "012-345 6789" -> "+60123456789" (E.164) with the current country's
  /// code; international numbers ("+65 …", "0065 …") are kept.
  static String toE164(String raw, {String? phoneCode}) {
    final s = raw.trim();
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (s.startsWith('+')) return '+$digits';
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    final cc = (phoneCode ?? current.phoneCode).replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) return '+$cc${digits.substring(1)}';
    if (digits.startsWith(cc) && digits.length > cc.length + 6) {
      return '+$digits';
    }
    return '+$cc$digits';
  }

  static bool isE164(String v) => RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(v);
}
