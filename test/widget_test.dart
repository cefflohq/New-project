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
}
