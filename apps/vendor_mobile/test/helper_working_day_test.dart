import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/ui/screens/helper_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

FulfilmentTask _s(
  String id,
  String date,
  String status, {
  DateTime? pickedUp,
}) => FulfilmentTask(
  orderId: id,
  orderNumber: id,
  customerName: 'C',
  items: const [],
  status: status,
  orderDate: date,
  pickedUpAt: pickedUp,
);

/// Active Helper workload = business TODAY + UNFINISHED work of the previous
/// 7 business calendar days (Founder 2026-10-06). Regression for the old
/// "yesterday" bug (earliest open day / device clock).
void main() {
  const today = '2026-10-06';
  final tasks = [
    _s('A-today', '2026-10-06', 'not_started'),
    _s('today-ready', '2026-10-06', 'ready'),
    _s('B-1day', '2026-10-05', 'preparing'),
    _s('C-7day', '2026-09-29', 'packed'),
    _s('D-8day', '2026-09-28', 'not_started'),
    _s('E-ready-old', '2026-10-05', 'ready'),
    _s('picked', '2026-10-06', 'ready', pickedUp: DateTime(2026, 10, 6)),
    _s('future', '2026-10-07', 'not_started'),
  ];
  List<String> ids(String? t) =>
      helperWorkingSet(tasks, t).map((x) => x.orderId).toList();

  test('A today unfinished visible; today Ready stays (today board)', () {
    expect(ids(today), containsAll(['A-today', 'today-ready']));
  });
  test('B 1-day backlog unfinished visible', () {
    expect(ids(today), contains('B-1day'));
  });
  test('C 7-day backlog (29 Sep) visible', () {
    expect(ids(today), contains('C-7day'));
  });
  test('D 8-day backlog (28 Sep) not in the active workload', () {
    expect(ids(today), isNot(contains('D-8day')));
  });
  test('E completed (Ready) work from an earlier day is not carried', () {
    expect(ids(today), isNot(contains('E-ready-old')));
  });
  test('F carried work keeps its exact state', () {
    final c = helperWorkingSet(
      tasks,
      today,
    ).firstWhere((t) => t.orderId == 'C-7day');
    expect(c.status, 'packed');
  });
  test('picked-up and future-dated work are not active', () {
    expect(ids(today), isNot(anyOf(contains('picked'), contains('future'))));
  });
  test('G/I window follows the server business day, not the device', () {
    // next business-local day: 29 Sep drops out, 7 Oct work appears
    expect(ids('2026-10-07'), isNot(contains('C-7day')));
    expect(ids('2026-10-07'), contains('future'));
    expect(ids('2026-10-07'), contains('B-1day'));
  });
  test('demo build without a server day keeps the earliest-day behaviour', () {
    expect(ids(null), ['D-8day']);
  });
}
