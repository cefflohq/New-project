import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

RiderRow _rider(String status) =>
    RiderRow.fromRow({'id': 'r-$status', 'name': 'Rider', 'status': status});

void main() {
  test('pending rider is pending, never offline', () {
    final r = _rider('pending');
    expect(r.isPending, isTrue);
    expect(r.isActive, isFalse);
    expect(r.isOffline, isFalse);
  });

  test('active rider is neither pending nor offline', () {
    final r = _rider('active');
    expect(r.isActive, isTrue);
    expect(r.isPending, isFalse);
    expect(r.isOffline, isFalse);
  });

  test('approved but inactive rider is offline', () {
    final r = _rider('inactive');
    expect(r.isOffline, isTrue);
    expect(r.isPending, isFalse);
  });
}
