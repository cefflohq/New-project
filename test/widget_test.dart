import 'package:cefflo_vendor/main.dart';
import 'package:cefflo_vendor/scenes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scene registry contains V-01 through V-60 exactly once', () {
    expect(scenes, hasLength(60));
    expect(scenes.map((scene) => scene.id).toSet(), hasLength(60));
    expect(scenes.first.id, 'V-01');
    expect(scenes.last.id, 'V-60');
  });

  test('unresolved contracts remain honest holds', () {
    expect(sceneById('V-41').hold, isTrue);
    for (var id = 50; id <= 54; id++) {
      expect(sceneById('V-$id').hold, isTrue);
    }
  });

  test('every declared scene destination resolves', () {
    final ids = scenes.map((scene) => scene.id).toSet();
    for (final scene in scenes) {
      if (scene.next != null) expect(ids, contains(scene.next));
    }
  });

  testWidgets('primary navigation and 60-scene index work', (tester) async {
    await tester.pumpWidget(const CeffloVendorApp());
    expect(find.text('FRIDAY · 4 SEP'), findsOneWidget);
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('#CF-1048'), findsOneWidget);
    await tester.tap(find.byTooltip('Open all 60 scenes'));
    await tester.pumpAndSettle();
    expect(find.text('60-scene prototype'), findsOneWidget);
    expect(find.text('V-01'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(find.text('V-60'), findsOneWidget);
  });

  testWidgets('order and zone controls react locally', (tester) async {
    await tester.pumpWidget(const CeffloVendorApp());
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ready').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('#CF-1048'));
    await tester.pumpAndSettle();
    expect(find.text('Taman Melati'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ongoing'));
    await tester.pumpAndSettle();
    expect(find.text('Zone North'), findsOneWidget);
  });

  testWidgets('global app theme uses one font family', (tester) async {
    await tester.pumpWidget(const CeffloVendorApp());
    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).textTheme.bodyMedium?.fontFamily, 'Roboto');
  });

  testWidgets('scene IDs are removed from the live page header', (
    tester,
  ) async {
    await tester.pumpWidget(const CeffloVendorApp());
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#CF-1048'));
    await tester.pumpAndSettle();
    expect(find.text('Order Detail'), findsOneWidget);
    expect(find.text('V-13'), findsNothing);
  });

  testWidgets('bottom navigation uses a stable glass surface', (tester) async {
    await tester.pumpWidget(const CeffloVendorApp());
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-V-11')), findsOneWidget);
    await tester.tap(find.text('Zones'));
    await tester.pumpAndSettle();
    expect(find.text('Zone North'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('contract-gated subsections are navigable without fake prices', (
    tester,
  ) async {
    await tester.pumpWidget(const CeffloVendorApp());
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Plan'), 280);
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('COMMERCIAL STATUS'), findsOneWidget);
    expect(find.textContaining('RM'), findsNothing);
    await tester.tap(find.text('Compare plan structure'));
    await tester.pumpAndSettle();
    expect(find.text('PLAN OPTION'), findsOneWidget);
  });

  testWidgets('elastic card response yields safely to vertical scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CeffloVendorApp());
    final target = find.text('Orders today');
    final gesture = await tester.startGesture(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.moveBy(const Offset(3, 3));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.moveBy(const Offset(0, 36));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('FRIDAY · 4 SEP'), findsOneWidget);
  });
}
