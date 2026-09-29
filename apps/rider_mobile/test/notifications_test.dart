import 'package:cefflo_rider_mobile/core/app_state.dart';
import 'package:cefflo_rider_mobile/core/notification_alerts.dart';
import 'package:cefflo_rider_mobile/core/routes.dart';
import 'package:cefflo_rider_mobile/core/theme.dart';
import 'package:cefflo_rider_mobile/data/driver_models.dart';
import 'package:cefflo_rider_mobile/data/models.dart';
import 'package:cefflo_rider_mobile/data/rider_repository.dart';
import 'package:cefflo_rider_mobile/ui/notification_banner.dart';
import 'package:cefflo_rider_mobile/ui/screens/history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live (non-demo) repository with an in-memory notification contract.
class _FakeRepo extends RiderRepository {
  _FakeRepo() : super(SupabaseClient('http://127.0.0.1:1', 'anon'));

  List<Map<String, dynamic>> rows = [];
  NotificationPrefs prefs = const NotificationPrefs();
  final calls = <String>[];
  void Function(String, Map<String, dynamic>)? push;
  void Function(bool)? status;

  @override
  Future<List<DriverNotification>> notifications() async {
    calls.add('list');
    return rows.map(DriverNotification.fromRow).toList();
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
  Future<void> markNotificationsRead({List<String>? ids}) async =>
      calls.add('read:${ids?.join(',') ?? 'all'}');

  @override
  Future<void> markNotificationUnread(String id) async =>
      calls.add('unread:$id');

  @override
  Future<List<RiderRelationship>> myRiderRelationships() async => const [];

  @override
  Future<List<RiderOrder>> myOrders(String riderId) async {
    calls.add('orders');
    return const [];
  }

  @override
  void Function()? watchNotifications({
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
  String key = 'run.assigned',
  String priority = 'urgent',
  Map<String, dynamic> params = const {'business': 'Dapur Manis', 'orders': 3},
  DateTime? at,
  bool read = false,
}) => {
  'id': id,
  'app': 'rider',
  'business_id': 'b1',
  'event_key': key,
  'category': 'operational',
  'priority': priority,
  'title': 'Server title $id',
  'body': 'Server body $id',
  'target': {'screen': key.startsWith('run.') ? 'runs' : 'none'},
  'params': params,
  'created_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
  'read_at': read ? DateTime.now().toUtc().toIso8601String() : null,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepo repo;
  late AppState app;
  late List<String> effects;

  setUp(() async {
    repo = _FakeRepo()
      ..rows = [
        _row('n1'),
        _row('n2', key: 'rider.approved', priority: 'normal', read: true),
      ];
    effects = [];
    app = AppState(repo)..alertEffects = _Effects(effects);
    await app.startNotifications();
  });

  tearDown(() => app.stopNotifications());

  test('loads the centre and unread count from the backend', () {
    expect(app.notifications.map((n) => n.id), ['n1', 'n2']);
    expect(app.unreadNotifications, 1);
    expect(app.notifications.first.urgent, isTrue);
    expect(app.foregroundAlert.value, isNull);
  });

  test('urgent run event: banner, sound and vibration; run data re-read', () {
    app.active = const RiderRelationship(
      id: 'rider-1',
      businessId: 'b1',
      status: 'active',
      name: 'Aiman',
    );
    repo.push!('INSERT', _row('n3'));
    expect(app.foregroundAlert.value?.id, 'n3');
    expect(effects, ['sound=true urgent=true']);
    expect(repo.calls, contains('orders'));
    expect(
      notificationCopy(app.notifications.first).title,
      'New run from Dapur Manis',
    );
    expect(
      notificationCopy(app.notifications.first).body,
      '3 orders assigned to you. Open it to accept.',
    );
  });

  test('normal event: no vibration; deactivation has no sound', () {
    repo.push!(
      'INSERT',
      _row(
        'n4',
        key: 'platform.announcement',
        priority: 'normal',
        params: const {},
      ),
    );
    repo.push!(
      'INSERT',
      _row('n5', key: 'rider.deactivated', priority: 'normal'),
    );
    expect(effects, ['sound=true urgent=false', 'sound=false urgent=false']);
    expect(
      notificationCopy(app.notifications[1]).title,
      'Server title n4',
      reason: 'broadcast keeps server copy',
    );
  });

  test('duplicate and stale rows never alert', () {
    repo.push!('INSERT', _row('n1'));
    repo.push!(
      'INSERT',
      _row('old', at: DateTime.now().subtract(const Duration(minutes: 5))),
    );
    expect(effects, isEmpty);
    expect(app.notifications.where((n) => n.id == 'n1'), hasLength(1));
    expect(app.notifications.first.id, 'old');
  });

  test('preferences: off suppresses alert; sound off keeps banner', () async {
    await app.setNotificationPrefs(const NotificationPrefs(enabled: false));
    repo.push!('INSERT', _row('n6'));
    expect(app.foregroundAlert.value, isNull);
    expect(effects, isEmpty);
    await app.setNotificationPrefs(
      const NotificationPrefs(enabled: true, sound: false),
    );
    repo.push!('INSERT', _row('n7'));
    expect(app.foregroundAlert.value?.id, 'n7');
    expect(effects, ['sound=false urgent=true']);
    expect(
      repo.calls,
      containsAllInOrder(['prefs:false/true', 'prefs:true/false']),
    );
  });

  test('read / unread / mark all use the backend', () async {
    await app.markNotificationRead(app.notifications.first);
    await app.markNotificationUnread(app.notifications.last);
    await app.markAllNotificationsRead();
    expect(app.unreadNotifications, 0);
    expect(
      repo.calls,
      containsAllInOrder(['read:n1', 'unread:n2', 'read:all']),
    );
  });

  test('reconnect re-reads history without replaying alerts', () async {
    repo.status!(true);
    repo.rows = [_row('n8'), ...repo.rows];
    repo.status!(true);
    await Future<void>.delayed(Duration.zero);
    expect(app.notifications.first.id, 'n8');
    expect(app.foregroundAlert.value, isNull);
  });

  test('run deep-link opens the run (or home without one)', () {
    app.openNotification(app.notifications.first);
    expect(app.current.route, anyOf(DRoute.runDetails, app.homeRoute));
    expect(repo.calls, contains('read:n1'));
  });

  test('sign-out stops the feed', () {
    app.clearSession();
    expect(repo.calls, contains('unwatch'));
    expect(app.notifications, isEmpty);
  });

  test('demo session never touches a backend', () async {
    final demo = AppState(RiderRepository.demo());
    await demo.startNotifications();
    await demo.markAllNotificationsRead();
    expect(demo.unreadNotifications, 0);
  });

  testWidgets('urgent banner stays; normal leaves after ~6 s', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRiderTheme(),
        home: AppScope(
          state: app,
          child: const Scaffold(body: Stack(children: [NotificationBanner()])),
        ),
      ),
    );
    repo.push!('INSERT', _row('u1'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('New run from Dapur Manis'), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();
    repo.push!('INSERT', _row('u2', key: 'rider.approved', priority: 'normal'));
    await tester.pump();
    expect(find.text('You are approved'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-banner')), findsNothing);
  });

  testWidgets('centre: urgent label, settings sheet saves to backend', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRiderTheme(),
        home: AppScope(state: app, child: const NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Urgent'), findsOneWidget);
    expect(find.text('You are approved'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('notif-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pref-sound')));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('prefs:true/false'));
    expect(
      find.text('Alerts when the app is closed are not available yet.'),
      findsOneWidget,
    );
  });
}
