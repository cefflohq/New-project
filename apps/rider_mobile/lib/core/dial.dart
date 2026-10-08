import 'package:url_launcher/url_launcher.dart';

/// Opens navigation to the drop point: the exact pinned coordinates when the
/// customer pinned them, otherwise the typed address.
Future<bool> openNavigation({double? lat, double? lng, String? address}) async {
  final dest = lat != null && lng != null
      ? '$lat,$lng'
      : (address ?? '').trim();
  if (dest.isEmpty) return false;
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': dest,
    'travelmode': 'driving',
  });
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

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
