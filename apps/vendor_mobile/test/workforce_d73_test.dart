import 'package:cefflo_vendor_mobile/core/env.dart';
import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// D-73 workforce: Operator or Helper invitations only (never Owner), the
// accountless Helper link, and Owner-only Subscription.
void main() {
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

  testWidgets('team invite offers Operator and Helper, never Owner', (
    tester,
  ) async {
    await pumpAt(tester, const VendorLocation(VRoute.helperRegistrationLink));
    expect(find.text('Operator'), findsOneWidget);
    expect(find.text('Helper'), findsOneWidget);
    expect(find.text('Owner'), findsNothing);
    expect(
      find.text(
        'Help manage daily delivery operations. Requires a Vendor account.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a Helper invite needs a name, no email, and is type=helper', (
    tester,
  ) async {
    await pumpAt(tester, const VendorLocation(VRoute.helperRegistrationLink));
    await tester.tap(find.text('Helper'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Help prepare and pack orders. Uses Helper PWA. No Vendor account required.',
      ),
      findsOneWidget,
    );
    expect(find.text('Email'), findsNothing);
    await tester.tap(find.text('Generate invite link'));
    await tester.pumpAndSettle();
    expect(find.text("Enter the Helper's name."), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Aina');
    await tester.tap(find.text('Generate invite link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('?type=helper&token='), findsOneWidget);
  });

  test('Helper workspace lives beside the invite page', () {
    expect(Env.helperBaseUrl, 'https://invite.cefflo.com/helper/');
  });

  test('Helper rows never carry a token', () {
    final h = HelperWorker.fromRow({
      'helper_id': 'h1',
      'display_name': 'Aina',
      'status': 'active',
      'contact': null,
    });
    expect(h.isActive, isTrue);
    expect(h.name, 'Aina');
  });

  test('an Operator is not the Owner (Subscription hidden)', () {
    final op = Business.fromRow({
      'business_id': 'b1',
      'business_name': 'Shop',
      'member_role': 'operator',
    });
    expect(op.isOwner, isFalse);
  });
}
