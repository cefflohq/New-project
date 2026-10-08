import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({Object? lat, Object? lng}) => {
  'id': 'o1',
  'delivery_status': 'created',
  'customer_name': 'Aina',
  'customer_phone': '0123456789',
  'delivery_address': '12 Jalan A, KL',
  'created_at': '2026-10-08T01:00:00Z',
  'latitude': lat,
  'longitude': lng,
};

void main() {
  test('order with coordinates has a pin', () {
    final o = VendorOrder.fromRow(_row(lat: 3.139, lng: 101));
    expect(o.hasPin, isTrue);
    expect(o.latitude, 3.139);
    expect(o.longitude, 101.0);
  });

  test('order without coordinates, or with only one, has no pin', () {
    expect(VendorOrder.fromRow(_row()).hasPin, isFalse);
    expect(VendorOrder.fromRow(_row(lat: 3.1)).hasPin, isFalse);
  });
}
