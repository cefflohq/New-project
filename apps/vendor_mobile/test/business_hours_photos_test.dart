import 'dart:typed_data';

import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:cefflo_vendor_mobile/ui/screens/product_photos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('Business Hours: seven days, a day can be opened', (
    tester,
  ) async {
    await pumpAt(tester, const VendorLocation(VRoute.businessHours));
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Sunday'), findsOneWidget);
    // No saved hours yet: every day starts closed, no sample times.
    expect(find.text('Closed'), findsNWidgets(7));
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Closed'), findsNWidgets(6));
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
  });

  testWidgets('product form shows the 5-photo field, not a dead dropzone', (
    tester,
  ) async {
    await pumpAt(tester, const VendorLocation(VRoute.addProduct));
    expect(find.text('0/5'), findsOneWidget);
    expect(find.textContaining('Up to 5 photos'), findsOneWidget);
  });

  test('photo controller: order, remove and the 5 limit', () {
    final c = ProductPhotosController();
    for (var i = 0; i < 3; i++) {
      c.add(ProductPhoto.local(Uint8List.fromList([i]), 'image/jpeg'));
    }
    c.move(2, 0);
    expect(c.photos.first.bytes!.first, 2);
    c.remove(0);
    expect(c.photos.length, 2);
    expect(ProductPhotosController.maxPhotos, 5);
    expect(ProductPhotosController.maxBytes, 5 * 1024 * 1024);
  });
}
