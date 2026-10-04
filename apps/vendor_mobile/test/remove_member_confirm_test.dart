import 'package:cefflo_vendor_mobile/core/theme.dart';
import 'package:cefflo_vendor_mobile/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Security & Access Master Part III §19-20: removing an active member or
/// rider needs the Owner to type CONFIRM exactly before the action enables.
void main() {
  Future<bool?> open(WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVendorTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showTypedConfirmDialog(
                context,
                title: 'Remove Sarah from your team?',
                message: 'Sarah will lose access.',
                actionLabel: 'Remove member',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  TextButton action(WidgetTester tester) => tester.widget<TextButton>(
    find.ancestor(
      of: find.text('Remove member'),
      matching: find.byType(TextButton),
    ),
  );

  testWidgets('action stays disabled until CONFIRM is typed exactly', (
    tester,
  ) async {
    await open(tester);
    expect(action(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'confirm');
    await tester.pump();
    expect(action(tester).onPressed, isNull, reason: 'case must match');

    await tester.enterText(find.byType(TextField), 'CONFIRM');
    await tester.pump();
    expect(action(tester).onPressed, isNotNull);
  });

  testWidgets('cancel never confirms', (tester) async {
    bool? result = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVendorTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showTypedConfirmDialog(
                context,
                title: 't',
                message: 'm',
                actionLabel: 'Remove rider',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'CONFIRM');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
