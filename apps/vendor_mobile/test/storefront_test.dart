import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/storefront_catalog.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:cefflo_vendor_mobile/ui/screens/storefront/shared/storefront_surface.dart';
import 'package:cefflo_vendor_mobile/ui/screens/storefront/shared/template_definition.dart';
import 'package:cefflo_vendor_mobile/ui/screens/storefront/templates/template_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpAt(WidgetTester tester, VendorLocation location) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    VendorMobileApp(repo: VendorRepository.demo(), auditLocation: location),
  );
  await tester.pumpAndSettle();
}

AppState _app(WidgetTester tester) =>
    AppScope.read(tester.element(find.byType(Scaffold).first));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('template registry', () {
    test('ids are unique and every entry is complete', () {
      final ids = kStorefrontTemplates.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final t in kStorefrontTemplates) {
        expect(t.name, isNotEmpty, reason: t.id);
        expect(t.style, isNotEmpty, reason: t.id);
        expect(t.tags, isNotEmpty, reason: t.id);
        expect(t.highlights, isNotEmpty, reason: t.id);
        // Store identity always comes from the vendor, never the template.
        expect(t.defaults.storeName, isEmpty, reason: t.id);
        if (t.supports(StorefrontCapability.background)) {
          expect(t.backgrounds, isNotEmpty, reason: t.id);
        }
      }
      expect(
        kStorefrontTemplates.any((t) => t.id == kDefaultStorefrontTemplateId),
        isTrue,
      );
    });

    test('filters are derived from template tags', () {
      final tags = storefrontTemplateTags();
      for (final t in kStorefrontTemplates) {
        expect(tags, containsAll(t.tags));
      }
      expect(tags.toSet().length, tags.length);
    });

    test('an unknown id falls back to the default template', () {
      expect(
        storefrontTemplateById('no-such-template').id,
        kDefaultStorefrontTemplateId,
      );
    });
  });

  for (final def in kStorefrontTemplates) {
    testWidgets('${def.id} renders vendor data in a phone viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final catalogue = StorefrontCatalogue.from(const []);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StorefrontSurface(
              def: def,
              branding: def.defaults.copyWith(storeName: 'Kopi Kita'),
              catalogue: catalogue,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Storefront gallery lists every registered template', (
    tester,
  ) async {
    await _pumpAt(tester, const VendorLocation(VRoute.storefront));
    expect(tester.takeException(), isNull);
    // The gallery is lazily built below the hero; scroll through it.
    for (final t in kStorefrontTemplates) {
      await tester.scrollUntilVisible(
        find.text(t.style).last,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(t.style), findsWidgets);
    }
    expect(find.text('Explore Templates'), findsOneWidget);
  });

  testWidgets('Customize hides controls a template does not support', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      const VendorLocation(VRoute.branding, entityId: 'stride'),
    );
    expect(find.text('Brand colour'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Background'), findsNothing);
    expect(find.text('Hero image'), findsNothing);
  });

  testWidgets('Customize shows every control a template declares', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      const VendorLocation(VRoute.branding, entityId: 'market'),
    );
    for (final label in ['Brand colour', 'Background', 'Hero image']) {
      await tester.scrollUntilVisible(
        find.text(label),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Use This Template activates only on Save, keeping products', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      const VendorLocation(VRoute.storefrontTemplatePreview, entityId: 'feast'),
    );
    final app = _app(tester);
    final before = await app.repo.products(app.business!.id);

    await tester.tap(find.text('Use This Template'));
    await tester.pumpAndSettle();
    expect(app.current.route, VRoute.branding);
    // Previewing and entering Customize never changes the live storefront.
    expect(app.activeStorefrontTemplateId, kDefaultStorefrontTemplateId);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(app.activeStorefrontTemplateId, 'feast');
    expect(app.current.route, VRoute.storefront);
    final after = await app.repo.products(app.business!.id);
    expect(after.map((p) => p.id), before.map((p) => p.id));
  });

  test('product art is inferred from product names', () {
    expect(productArtFor('Matcha Latte', 0), ProductArt.cup);
    expect(productArtFor('Chocolate Cake', 0), ProductArt.cake);
    expect(productArtFor('Croissant', 0), ProductArt.pastry);
  });
}
