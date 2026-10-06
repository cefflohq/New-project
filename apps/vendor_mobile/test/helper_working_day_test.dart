import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/ui/screens/helper_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

FulfilmentTask _t(String id, String date, {DateTime? pickedUp}) =>
    FulfilmentTask(
      orderId: id,
      orderNumber: id,
      customerName: 'C',
      items: const [],
      status: 'not_started',
      orderDate: date,
      pickedUpAt: pickedUp,
    );

/// Regression: the Helper board used the EARLIEST open order date (and the
/// device clock as fallback), so unfinished orders from earlier days hid
/// today's work ("yesterday's date"). It now follows the business's own
/// today from the server.
void main() {
  final tasks = [
    _t('old', '2026-10-04'),
    _t('yday', '2026-10-05'),
    _t('a', '2026-10-06'),
    _t('b', '2026-10-06'),
    _t('done', '2026-10-06', pickedUp: DateTime(2026, 10, 6)),
  ];

  test('uses the business-local today, not the earliest open day', () {
    final set = helperWorkingSet(tasks, '2026-10-06');
    expect(set.map((t) => t.orderId), ['a', 'b']);
  });

  test('picked-up orders are not open work', () {
    expect(
      helperWorkingSet(tasks, '2026-10-06').any((t) => t.orderId == 'done'),
      isFalse,
    );
  });

  test('a business ahead of UTC: its date is the server day, whatever the device says', () {
    // e.g. 07:00 in Kuala Lumpur = 23:00 UTC the day before: the server says
    // 2026-10-06, so 2026-10-05 work is not shown as today.
    expect(
      helperWorkingSet(
        tasks,
        '2026-10-06',
      ).every((t) => t.orderDate == '2026-10-06'),
      isTrue,
    );
  });

  test('no work today -> empty (never falls back to an older day)', () {
    expect(helperWorkingSet(tasks, '2026-10-07'), isEmpty);
  });

  test('demo build without a server day keeps the earliest-day behaviour', () {
    expect(helperWorkingSet(tasks, null).map((t) => t.orderId), ['old']);
  });
}
