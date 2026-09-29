import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('V-57 hands support to support@cefflo.com, never fakes "sent"', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      VendorMobileApp(
        repo: VendorRepository.demo(),
        auditLocation: const VendorLocation(VRoute.contactSupport),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('support@cefflo.com'), findsWidgets);
    // No demo contact prefilled, no fake attachment picker.
    expect(find.text('yusuf@kopikita.my'), findsNothing);
    expect(find.text('Tap to attach images'), findsNothing);

    // An empty message is not "sent" anywhere.
    await tester.ensureVisible(find.text('Send Request'));
    await tester.tap(find.text('Send Request'));
    await tester.pumpAndSettle();
    expect(find.text('Write a message first.'), findsOneWidget);
    expect(find.text('Your support request has been sent.'), findsNothing);
    expect(find.byType(AppScope), findsOneWidget);
  });
}
