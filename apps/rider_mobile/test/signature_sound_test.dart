import 'dart:io';

import 'package:cefflo_rider_mobile/core/notification_alerts.dart';
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

  test('the Driver app ships the same approved signature as the Vendor App', () {
    final driver = File('assets/sounds/cefflo_signature.mp3').readAsBytesSync();
    final vendor = File(
      '../vendor_mobile/assets/sounds/cefflo_signature.mp3',
    ).readAsBytesSync();
    expect(driver, vendor);
    expect(driver.length, lessThan(60 * 1024));
  });
}
