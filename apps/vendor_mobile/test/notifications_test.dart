import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/notification_alerts.dart';
import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/core/theme.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/ui/notification_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A live (non-demo) repository whose notification contract is in memory,
/// so AppState's backend path runs without a network.
class _FakeRepo extends VendorRepository {
  _FakeRepo() : super(SupabaseClient('http://127.0.0.1:9', 'anon'));

  List<Map<String, dynamic>> rows = [];
  NotificationPrefs prefs = const NotificationPrefs();
  final calls = <String>[];
  void Function(String, Map<String, dynamic>)? push;
  void Function(bool)? status;
  bool failWrites = false;

  @override
  Future<List<AppNotification>> notifications() async {
    calls.add('list');
    return rows.map(AppNotification.fromRow).toList();
  }

  @override
  Future<int> unreadNotificationCount() async =>
      rows.where((r) => r['read_at'] == null).length;

  @override
  Future<NotificationPrefs> notificationPrefs() async => prefs;

  @override
  Future<void> saveNotificationPrefs(NotificationPrefs p) async {
    calls.add('prefs:${p.enabled}/${p.sound}');
    prefs = p;
  }

  @override
  Future<void> markNotificationsRead({List<String>? ids}) async {
    if (failWrites) throw RepositoryError('offline');
    calls.add('read:${ids?.join(',') ?? 'all'}');
  }

  @override
  Future<void> markNotificationUnread(String id) async =>
      calls.add('unread:$id');

  @override
  Future<void> deleteNotification(String id) async => calls.add('delete:$id');

  @override
  VoidCallback? watchNotifications({
    required void Function(String type, Map<String, dynamic> row) onChange,
    required void Function(bool subscribed) onStatus,
  }) {
    push = onChange;
    status = onStatus;
    calls.add('watch');
    return () => calls.add('unwatch');
  }
}

class _Effects extends NotificationAlertEffects {
  _Effects(this.log);
  final List<String> log;
  @override
  void play({required bool sound, required bool urgent}) =>
      log.add('sound=$sound urgent=$urgent');
}

Map<String, dynamic> _row(
  String id, {
  String key = 'order.new_customer',
  String priority = 'normal',
  Map<String, dynamic> target = const {'screen': 'order', 'id': 'o1'},
  DateTime? at,
  bool read = false,
  String business = 'b1',
}) => {
  'id': id,
  'app': 'vendor',
  'business_id': business,
  'event_key': key,
  'category': 'operational',
  'priority': priority,
  'title': 'Server title $id',
  'body': 'Server body $id',
  'target': target,
  'params': {'ref': 'CF-1'},
  'created_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
  'read_at': read ? DateTime.now().toUtc().toIso8601String() : null,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepo repo;
  late AppState app;
  late List<String> effects;

  setUp(() async {
    repo = _FakeRepo()..rows = [_row('n1'), _row('n2', read: true)];
    effects = [];
    app = AppState(repo)
      ..alertEffects = _Effects(effects)
      ..businesses = const [
        Business(id: 'b1', name: 'Kopi Kita', role: 'owner'),
        Business(id: 'b2', name: 'Dapur Dua', role: 'operator'),
      ];
    app.business = app.businesses.first;
    await app.startNotifications();
  });

  tearDown(() => app.stopNotifications());

  test('operational events and foreground resume reload live lists', () {
    final before = app.liveTick.value;
    repo.push!('INSERT', _row('nl1', key: 'order.new_customer'));
    expect(app.liveTick.value, before + 1);
    repo.push!('INSERT', _row('nl2', key: 'platform.announcement'));
    expect(app.liveTick.value, before + 1, reason: 'not operational');
    app.onAppResumed();
    expect(app.liveTick.value, before + 2);
  });
  test('Sound off: banner shows, the signature does not play', () async {
    await app.setNotificationPrefs(
      const NotificationPrefs(enabled: true, sound: false),
    );
    repo.push!('INSERT', _row('ns1'));
    expect(app.foregroundAlert.value?.id, 'ns1');
    expect(effects, ['sound=false urgent=false']);
  });
  test('loads the centre and unread count from the backend', () {
    expect(app.notifications.map((n) => n.id), ['n1', 'n2']);
    expect(app.unreadNotifications, 1);
    expect(repo.calls, containsAllInOrder(['list', 'watch']));
    expect(app.foregroundAlert.value, isNull, reason: 'no alert on load');
  });

  test('new row: centre + badge + banner + sound, once per id', () {
    repo.push!('INSERT', _row('n3'));
    expect(app.notifications.first.id, 'n3');
    expect(app.unreadNotifications, 2);
    expect(app.foregroundAlert.value?.id, 'n3');
    expect(effects, ['sound=true urgent=false']);
    repo.push!('INSERT', _row('n3'));
    expect(app.notifications.where((n) => n.id == 'n3'), hasLength(1));
    expect(effects, hasLength(1));
  });

  test('urgent rows vibrate; run.completed has no sound', () {
    repo.push!('INSERT', _row('n4', key: 'delivery.issue', priority: 'urgent'));
    expect(app.foregroundAlert.value!.urgent, isTrue);
    repo.push!('INSERT', _row('n5', key: 'run.completed'));
    expect(effects, ['sound=true urgent=true', 'sound=false urgent=false']);
  });

  test('rows older than two minutes land in the centre without alert', () {
    repo.push!(
      'INSERT',
      _row('old', at: DateTime.now().subtract(const Duration(minutes: 10))),
    );
    expect(app.notifications.first.id, 'old');
    expect(app.foregroundAlert.value, isNull);
    expect(effects, isEmpty);
  });

  test('Notifications off: no banner or sound, centre still records', () async {
    await app.setNotificationPrefs(
      const NotificationPrefs(enabled: false, sound: true),
    );
    expect(repo.calls, contains('prefs:false/true'));
    repo.push!('INSERT', _row('n6'));
    expect(app.foregroundAlert.value, isNull);
    expect(effects, isEmpty);
    expect(app.unreadNotifications, 2);
  });

  test('Sound off: banner without sound', () async {
    await app.setNotificationPrefs(
      const NotificationPrefs(enabled: true, sound: false),
    );
    repo.push!('INSERT', _row('n7'));
    expect(app.foregroundAlert.value?.id, 'n7');
    expect(effects, ['sound=false urgent=false']);
  });

  test('read / unread / mark all go to the backend', () async {
    await app.setNotificationRead('n1', read: true);
    expect(app.unreadNotifications, 0);
    await app.setNotificationRead('n2', read: false);
    expect(app.unreadNotifications, 1);
    await app.markAllNotificationsRead();
    expect(app.unreadNotifications, 0);
    expect(
      repo.calls,
      containsAllInOrder(['read:n1', 'unread:n2', 'read:all']),
    );
  });

  test('a failed write re-reads backend truth and reports the error', () async {
    repo.failWrites = true;
    await expectLater(
      app.setNotificationRead('n1', read: true),
      throwsA(isA<RepositoryError>()),
    );
    expect(app.unreadNotifications, 1, reason: 'restored from the backend');
  });

  test('realtime UPDATE/DELETE from another device keep the badge true', () {
    repo.push!('UPDATE', {..._row('n1'), 'read_at': '2026-09-29T00:00:00Z'});
    expect(app.unreadNotifications, 0);
    repo.push!('DELETE', {'id': 'n2'});
    expect(app.notifications.map((n) => n.id), ['n1']);
  });

  testWidgets('delete waits for the undo window before the server delete', (
    tester,
  ) async {
    final undo = app.deleteNotification('n1')!;
    expect(app.unreadNotifications, 0);
    await tester.pump(const Duration(seconds: 2));
    app.restoreNotification(undo);
    expect(app.unreadNotifications, 1);
    await tester.pump(const Duration(seconds: 6));
    expect(repo.calls, isNot(contains('delete:n1')));
    app.deleteNotification('n1');
    await tester.pump(const Duration(seconds: 6));
    expect(repo.calls, contains('delete:n1'));
  });

  test('reconnect re-reads history without replaying alerts', () async {
    repo.status!(true); // first subscribe
    final before = repo.calls.where((c) => c == 'list').length;
    repo.rows = [_row('n8'), ...repo.rows];
    repo.status!(true); // rejoined after a drop
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls.where((c) => c == 'list').length, before + 1);
    expect(app.notifications.first.id, 'n8');
    expect(app.foregroundAlert.value, isNull);
  });

  test('deep-links: order, runs, rider; other business switches first', () {
    app.openNotification(app.notifications.first);
    expect(
      app.current,
      const VendorLocation(VRoute.orderDetail, entityId: 'o1'),
    );
    app.openNotification(
      AppNotification.fromRow(
        _row('b', key: 'run.declined', target: {'screen': 'runs'}),
      ),
    );
    expect(app.current.route, VRoute.zones);
    app.openNotification(
      AppNotification.fromRow(
        _row(
          'c',
          key: 'rider.joined',
          target: {'screen': 'rider', 'id': 'r1'},
          business: 'b2',
        ),
      ),
    );
    expect(
      app.current,
      const VendorLocation(VRoute.riderDetail, entityId: 'r1'),
    );
    expect(app.business!.id, 'b2');
    expect(repo.calls, contains('read:n1'));
  });

  test('sign-out stops the feed and clears live rows', () {
    app.stopNotifications();
    expect(repo.calls, contains('unwatch'));
    expect(app.notifications, isEmpty);
    expect(app.unreadNotifications, 0);
  });

  test('demo session never touches a backend', () async {
    final demo = AppState(VendorRepository.demo());
    await demo.startNotifications();
    expect(demo.notifications, isNotEmpty);
    await demo.markAllNotificationsRead();
    expect(demo.unreadNotifications, 0);
  });

  testWidgets('banner: ~3 s normal, ~5 s urgent, swipe up, tap opens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVendorTheme(Brightness.light),
        home: AppScope(
          state: app,
          child: const Scaffold(body: Stack(children: [NotificationBanner()])),
        ),
      ),
    );
    repo.push!('INSERT', _row('n9', target: {'screen': 'order', 'id': 'o9'}));
    await tester.pump();
    expect(find.text('New customer order CF-1'), findsOneWidget);
    expect(find.text('Cefflo'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.byKey(const ValueKey('notification-banner')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-banner')), findsNothing);

    repo.push!('INSERT', _row('n12'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.fling(
      find.byKey(const ValueKey('notification-banner')),
      const Offset(0, -80),
      800,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-banner')), findsNothing);
    expect(
      app.current,
      isNot(const VendorLocation(VRoute.orderDetail, entityId: 'o1')),
    );

    repo.push!('INSERT', _row('n13', priority: 'urgent'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const ValueKey('notification-banner')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-banner')), findsNothing);

    repo.push!(
      'INSERT',
      _row('n10', key: 'delivery.issue', priority: 'urgent'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Server body n10'), findsOneWidget, reason: 'rider note');
    await tester.tap(find.text('Server body n10'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-banner')), findsNothing);
    expect(
      app.current,
      const VendorLocation(VRoute.orderDetail, entityId: 'o1'),
    );
  });

  testWidgets('banner renders in dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVendorTheme(Brightness.dark),
        home: AppScope(
          state: app,
          child: const Scaffold(body: Stack(children: [NotificationBanner()])),
        ),
      ),
    );
    repo.push!('INSERT', _row('n11'));
    await tester.pump();
    expect(find.byKey(const ValueKey('notification-banner')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
