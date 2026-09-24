import 'package:cefflo_vendor_mobile/core/theme.dart';
import 'package:cefflo_vendor_mobile/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a failing action ends on the failure state with its actions', (
    tester,
  ) async {
    var secondary = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVendorTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => runAsyncFeedback(
                  context,
                  action: () async => throw StateError('declined'),
                  processingTitle: 'Processing payment',
                  processingSubtitle: 'Please wait.',
                  successTitle: 'Subscription active',
                  failureTitle: 'Payment unsuccessful',
                  failureMessage: "We couldn't process your payment.",
                  failureSecondaryLabel: 'Change payment method',
                  onFailureSecondary: () => secondary = true,
                ),
                child: const Text('Pay'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pay'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Processing payment'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Payment unsuccessful'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Change payment method'));
    await tester.pumpAndSettle();
    expect(find.text('Payment unsuccessful'), findsNothing);
    expect(secondary, isTrue);
  });
}
