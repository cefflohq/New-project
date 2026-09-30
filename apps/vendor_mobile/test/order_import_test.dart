import 'dart:convert';
import 'dart:typed_data';

import 'package:cefflo_vendor_mobile/core/order_import.dart';
import 'package:cefflo_vendor_mobile/core/routes.dart';
import 'package:cefflo_vendor_mobile/data/vendor_repository.dart';
import 'package:cefflo_vendor_mobile/main.dart';
import 'package:cefflo_vendor_mobile/ui/screens/import_flow.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('parseImportFile', () {
    test('CSV: header, BOM, quoted commas, empty lines dropped', () {
      final t = parseImportFile(
        'orders.csv',
        _bytes(
          '﻿Name,Phone,Address,Notes\n'
          'Aina,0123456789,"12 Jalan A, KL",\n'
          '\n'
          'Ben,,"3 Jalan B",leave at door\n',
        ),
      );
      expect(t.headers, ['Name', 'Phone', 'Address', 'Notes']);
      expect(t.rows.length, 2);
      expect(t.rows.first[2], '12 Jalan A, KL');
      // The CSV decoder itself skips blank lines; rows keep their order.
      expect(t.rowNumbers, [2, 3]);
    });

    test('XLSX: reads the first sheet, whole numbers keep no ".0"', () {
      final book = xl.Excel.createExcel();
      final sheet = book[book.getDefaultSheet()!];
      sheet.appendRow([
        xl.TextCellValue('Customer'),
        xl.TextCellValue('Phone'),
        xl.TextCellValue('Alamat'),
      ]);
      sheet.appendRow([
        xl.TextCellValue('Aina'),
        xl.DoubleCellValue(60123456789),
        xl.TextCellValue('12 Jalan A'),
      ]);
      final t = parseImportFile('o.xlsx', Uint8List.fromList(book.encode()!));
      expect(t.headers, ['Customer', 'Phone', 'Alamat']);
      expect(t.rows.single, ['Aina', '60123456789', '12 Jalan A']);
    });

    test('rejects unsupported and empty files', () {
      expect(
        () => parseImportFile('a.pdf', _bytes('x')),
        throwsA(isA<ImportFormatException>()),
      );
      expect(
        () => parseImportFile('a.csv', _bytes('\n\n')),
        throwsA(isA<ImportFormatException>()),
      );
    });
  });

  test('autoMapColumns pre-selects EN and BM headers, each column once', () {
    final m = autoMapColumns([
      'Nama Pelanggan',
      'No Telefon',
      'Delivery_Address',
      'Zon',
      'Items',
      'Remarks',
    ]);
    expect(m[ImportField.customerName], 0);
    expect(m[ImportField.customerPhone], 1);
    expect(m[ImportField.deliveryAddress], 2);
    expect(m[ImportField.zoneName], 3);
    expect(m[ImportField.itemsDescription], 4);
    expect(m[ImportField.notes], 5);
    expect(autoMapColumns(['Foo', 'Bar'])[ImportField.customerName], isNull);
  });

  test('mapImportRows flags missing required fields, keeps every row', () {
    final t = parseImportFile(
      'o.csv',
      _bytes('Name,Phone,Address\nAina,012,KL\nBen,,PJ\n'),
    );
    final rows = mapImportRows(t, autoMapColumns(t.headers));
    expect(rows.length, 2);
    expect(rows[0].valid, isTrue);
    expect(rows[0].toRpc(), {
      'source_row_ref': '2',
      'customer_name': 'Aina',
      'customer_phone': '012',
      'delivery_address': 'KL',
    });
    expect(rows[1].valid, isFalse);
    expect(rows[1].missing, [ImportField.customerPhone]);
    expect(rows[1].ref, '3');
  });

  testWidgets('Excel / CSV: pick → match → review', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ImportOrdersScreen.debugPickFile = () async => (
      name: 'orders.csv',
      bytes: utf8.encode('Name,Phone,Address\nAina,012,KL\nBen,,PJ\n'),
    );
    addTearDown(() => ImportOrdersScreen.debugPickFile = null);

    await tester.pumpWidget(
      VendorMobileApp(
        repo: VendorRepository.demo(),
        auditLocation: const VendorLocation(VRoute.importOrders),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excel / CSV'));
    await tester.pumpAndSettle();
    expect(find.text('orders.csv'), findsOneWidget);
    expect(find.text('Review rows'), findsOneWidget);

    await tester.tap(find.text('Review rows'));
    await tester.pumpAndSettle();
    expect(find.text('Import 1 orders'), findsOneWidget);
    expect(find.text('Row 3: missing Customer phone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
