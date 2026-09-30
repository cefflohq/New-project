import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Cefflo Vendor',
      packageName: 'cefflo_vendor_mobile',
      version: '0.1.0',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  Future<void> pumpAt(WidgetTester tester, VendorLocation location) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      VendorMobileApp(repo: VendorRepository.demo(), auditLocation: location),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Security has no 2FA placeholder', (tester) async {
    await pumpAt(tester, const VendorLocation(VRoute.security));
    expect(find.text('Two-factor authentication'), findsNothing);
    expect(find.text('Coming soon'), findsNothing);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('Help & Support shows only what works', (tester) async {
    await pumpAt(tester, const VendorLocation(VRoute.helpSupport));
    expect(find.byType(TextField), findsNothing); // no dead search
    expect(find.text('Popular topics'), findsNothing);
    expect(find.text('Contact Support'), findsOneWidget);
  });

  testWidgets('About and More read the real build version', (tester) async {
    await pumpAt(tester, const VendorLocation(VRoute.about));
    expect(find.text('0.1.0 (7)'), findsOneWidget);
    expect(find.text('1.0.0'), findsNothing);
  });

  testWidgets('Business Profile: no decorative Store ready panel', (
    tester,
  ) async {
    await pumpAt(tester, const VendorLocation(VRoute.businessProfile));
    expect(find.text('Store ready'), findsNothing);
  });

  testWidgets('Business Information hydrates from the business row', (
    tester,
  ) async {
    await pumpAt(tester, const VendorLocation(VRoute.businessInformation));
    expect(find.text('Kopi Kita'), findsWidgets);
    expect(find.text('Save Changes'), findsOneWidget);
  });
}
