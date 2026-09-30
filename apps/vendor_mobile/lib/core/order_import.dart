import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart' as csv_pkg;
import 'package:excel/excel.dart' as xl;

/// Order-import fields, matching the canonical `import_orders_batch` row
/// contract. The first three are required by the server.
enum ImportField {
  customerName('customer_name', required: true),
  customerPhone('customer_phone', required: true),
  deliveryAddress('delivery_address', required: true),
  zoneName('zone_name'),
  itemsDescription('items_description'),
  notes('notes');

  const ImportField(this.key, {this.required = false});
  final String key;
  final bool required;

  /// Header words that auto-match this field (lower-case, EN + BM).
  List<String> get aliases => switch (this) {
    customerName => [
      'customer name',
      'customer',
      'name',
      'nama',
      'nama pelanggan',
      'pelanggan',
      'recipient',
      'penerima',
    ],
    customerPhone => [
      'customer phone',
      'phone',
      'phone number',
      'mobile',
      'tel',
      'telephone',
      'contact',
      'no telefon',
      'telefon',
      'no tel',
      'hp',
    ],
    deliveryAddress => [
      'delivery address',
      'address',
      'alamat',
      'alamat penghantaran',
      'shipping address',
      'location',
    ],
    zoneName => ['zone', 'zone name', 'zon', 'area', 'kawasan'],
    itemsDescription => [
      'items',
      'item',
      'items description',
      'products',
      'product',
      'order',
      'barang',
      'produk',
      'pesanan',
    ],
    notes => [
      'notes',
      'note',
      'remarks',
      'remark',
      'catatan',
      'nota',
      'comment',
      'comments',
    ],
  };
}

/// A parsed spreadsheet: one header row and the data rows under it.
class ImportTable {
  const ImportTable(this.headers, this.rows, this.rowNumbers);
  final List<String> headers;
  final List<List<String>> rows;

  /// The spreadsheet row number of each entry in [rows] (header row = 1).
  final List<int> rowNumbers;
}

class ImportFormatException implements Exception {
  const ImportFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Parses a CSV or Excel (.xlsx) file. Empty lines are dropped; every other
/// row is kept (validation decides, never silent discard).
ImportTable parseImportFile(String fileName, Uint8List bytes) {
  final ext = fileName.toLowerCase().split('.').last;
  final List<List<String>> grid;
  if (ext == 'csv' || ext == 'txt') {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1);
    grid = [
      for (final r in csv_pkg.csv.decode(text))
        [for (final c in r) '${c ?? ''}'.trim()],
    ];
  } else if (ext == 'xlsx') {
    final book = xl.Excel.decodeBytes(bytes);
    final sheet = book.tables.values.firstWhere(
      (s) => s.maxRows > 0,
      orElse: () => throw const ImportFormatException('empty'),
    );
    grid = [
      for (final r in sheet.rows) [for (final d in r) _cellText(d?.value)],
    ];
  } else {
    throw const ImportFormatException('unsupported');
  }
  final nonEmpty = [
    for (final (i, r) in grid.indexed)
      if (r.any((c) => c.isNotEmpty)) (i + 1, r),
  ];
  if (nonEmpty.isEmpty) throw const ImportFormatException('empty');
  final headers = nonEmpty.first.$2;
  final width = headers.length;
  final rows = [
    for (final (_, r) in nonEmpty.skip(1))
      [for (var i = 0; i < width; i++) i < r.length ? r[i] : ''],
  ];
  return ImportTable(headers, rows, [for (final (n, _) in nonEmpty.skip(1)) n]);
}

String _cellText(xl.CellValue? v) => switch (v) {
  null => '',
  // Whole numbers (phone numbers typed as numbers) must not gain ".0".
  xl.DoubleCellValue(:final value) when value == value.truncateToDouble() =>
    value.toStringAsFixed(0),
  _ => v.toString().trim(),
};

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[_\-./]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Pre-selects a column for each field: an exact alias match first, then a
/// header that contains an alias. A column is used at most once.
Map<ImportField, int?> autoMapColumns(List<String> headers) {
  final norm = headers.map(_norm).toList();
  final used = <int>{};
  final map = <ImportField, int?>{};
  for (final pass in [true, false]) {
    for (final f in ImportField.values) {
      if (map[f] != null) continue;
      for (var i = 0; i < norm.length; i++) {
        if (used.contains(i) || norm[i].isEmpty) continue;
        final hit = pass
            ? f.aliases.contains(norm[i])
            : f.aliases.any((a) => a.length > 3 && norm[i].contains(a));
        if (hit) {
          map[f] = i;
          used.add(i);
          break;
        }
      }
    }
  }
  return {for (final f in ImportField.values) f: map[f]};
}

/// One source row after mapping. [ref] is the 1-based spreadsheet row
/// (header = row 1) sent as `source_row_ref`.
class ImportRow {
  ImportRow(this.ref, this.values, this.missing);
  final String ref;
  final Map<ImportField, String> values;
  final List<ImportField> missing;
  bool get valid => missing.isEmpty;

  Map<String, dynamic> toRpc() => {
    'source_row_ref': ref,
    for (final e in values.entries)
      if (e.value.isNotEmpty) e.key.key: e.value,
  };
}

List<ImportRow> mapImportRows(ImportTable t, Map<ImportField, int?> mapping) =>
    [
      for (final (i, r) in t.rows.indexed)
        () {
          final values = {
            for (final e in mapping.entries)
              if (e.value != null) e.key: r[e.value!].trim(),
          };
          final missing = [
            for (final f in ImportField.values)
              if (f.required && (values[f] ?? '').isEmpty) f,
          ];
          return ImportRow('${t.rowNumbers[i]}', values, missing);
        }(),
    ];
