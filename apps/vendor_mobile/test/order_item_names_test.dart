import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

// Storefront orders store the line name as product_name_snapshot (manual
// orders use name). Both must reach the Helper board and order details.
void main() {
  const storefront = {
    'quantity': 2,
    'product_id': 'p1',
    'product_name_snapshot': 'Kek Coklat',
    'display_price_snapshot': 45.5,
  };
  const manual = {'name': 'Nasi Lemak', 'qty': 1};

  test('order details read both line shapes', () {
    final a = OrderItem.fromJson(Map<String, dynamic>.from(storefront));
    expect(a.name, 'Kek Coklat');
    expect(a.quantity, 2);
    expect(a.unitPrice, 45.5);
    expect(
      OrderItem.fromJson(Map<String, dynamic>.from(manual)).name,
      'Nasi Lemak',
    );
  });

  test('Helper board lines and item count include storefront orders', () {
    final t = FulfilmentTask.fromRow({
      'order_id': 'o1',
      'items': [storefront, manual],
      'preparation_status': 'not_started',
    });
    expect(t.lines.map((l) => l.name), ['Kek Coklat', 'Nasi Lemak']);
    expect(t.itemCount, 3);
    expect(t.items, ['2× Kek Coklat', '1× Nasi Lemak']);
  });
}
