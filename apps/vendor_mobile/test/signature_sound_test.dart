import 'dart:io';

import 'package:cefflo_vendor_mobile/core/notification_alerts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a burst of alerts plays the signature once per 1.5 s window', () {
    NotificationAlertEffects.resetPlaySlot();
    final t0 = DateTime(2026, 10, 7, 9);
    expect(NotificationAlertEffects.claimPlaySlot(t0), isTrue);
    expect(
      NotificationAlertEffects.claimPlaySlot(
        t0.add(const Duration(milliseconds: 400)),
      ),
      isFalse,
    );
    expect(
      NotificationAlertEffects.claimPlaySlot(
        t0.add(const Duration(milliseconds: 1600)),
      ),
      isTrue,
    );
  });

  test('the signature asset ships with the app and is short', () {
    final f = File('assets/sounds/cefflo_signature.mp3');
    expect(f.existsSync(), isTrue);
    final bytes = f.readAsBytesSync();
    expect(bytes.length, lessThan(60 * 1024));
    // MPEG audio frame sync (no ID3 header from the encoder).
    expect(bytes[0], 0xFF);
    expect(bytes[1] & 0xE0, 0xE0);
    expect(NotificationAlertEffects.signatureAsset, 'sounds/cefflo_signature.mp3');
  });
}
