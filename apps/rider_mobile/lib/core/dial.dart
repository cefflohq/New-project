import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer for [phone]. Returns false when there is no usable
/// number or the device cannot dial, so the caller can say so.
Future<bool> dialPhone(String? phone) async {
  final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.length < 6) return false;
  try {
    return await launchUrl(Uri(scheme: 'tel', path: digits));
  } catch (_) {
    return false;
  }
}
