import 'package:cefflo_loader/cefflo_loader.dart';

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/order_import.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../shell.dart';
import '../widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// Bumped after an import commits orders, so order lists (keyed on it)
/// load again.
final ValueNotifier<int> ordersRevision = ValueNotifier(0);

/// Where bulk orders come from. Excel / CSV is a real device file; the two
/// Google sources need Google sign-in, which is not connected yet (Batch E),
/// so they say so honestly instead of pretending to connect.
enum _ImportSource {
  excel('assets/brand/microsoft-excel-logo.png'),
  googleSheets('assets/brand/google-sheets-logo.png'),
  googleDrive('assets/brand/google-drive-logo.png');

  const _ImportSource(this.assetPath);
  final String assetPath;

  bool get needsGoogle => this != _ImportSource.excel;

  String get label => switch (this) {
    _ImportSource.googleSheets => L.googleSheets,
    _ImportSource.excel => L.importExcelCsv,
    _ImportSource.googleDrive => L.googleDrive,
  };

  String get description => switch (this) {
    _ImportSource.googleSheets => L.importFromGoogleSheets,
    _ImportSource.excel => L.importExcelCsvHint,
    _ImportSource.googleDrive => L.importFromFilesGoogleDrive,
  };
}

String importFieldLabel(ImportField f) => switch (f) {
  ImportField.customerName => L.customerName,
  ImportField.customerPhone => L.importFieldPhone,
  ImportField.deliveryAddress => L.deliveryAddress,
  ImportField.zoneName => L.importFieldZone,
  ImportField.itemsDescription => L.importFieldItems,
  ImportField.notes => L.importFieldNotes,
};

enum _Stage { source, match, review, result }

/// X-04 — Bulk import: pick a source → choose a file → match columns →
/// review → import through `import_orders_batch` → the server's result.
class ImportOrdersScreen extends StatefulWidget {
  const ImportOrdersScreen({super.key});

  /// Test seam: returns (file name, bytes) or null when cancelled.
  @visibleForTesting
  static Future<({String name, List<int> bytes})?> Function()? debugPickFile;

  @override
  State<ImportOrdersScreen> createState() => _ImportOrdersScreenState();
}

class _ImportOrdersScreenState extends State<ImportOrdersScreen> {
  _Stage _stage = _Stage.source;
  bool _busy = false;
  String? _error;
  String _fileName = '';
  ImportTable? _table;
  Map<ImportField, int?> _mapping = {};
  List<ImportRow> _rows = [];
  String? _idempotencyKey;
  List<Map<String, dynamic>> _committed = [];
  List<Map<String, dynamic>> _rejected = [];

  static List<(IconData, String)> get _steps => [
    (LucideIcons.layers, L.howStepSource),
    (LucideIcons.fileSpreadsheet, L.howStepFile),
    (LucideIcons.columns3, L.howStepMap),
    (LucideIcons.circleCheck, L.howStepImport),
  ];

  Future<({String name, List<int> bytes})?> _pickNative() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx'],
    );
    if (f == null) return null;
    return (name: f.name, bytes: await f.readAsBytes());
  }

  Future<void> _chooseFile() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await (ImportOrdersScreen.debugPickFile ?? _pickNative)();
      if (picked == null) return;
      final table = parseImportFile(
        picked.name,
        Uint8List.fromList(picked.bytes),
      );
      if (table.rows.isEmpty) throw const ImportFormatException('norows');
      setState(() {
        _fileName = picked.name;
        _table = table;
        _mapping = autoMapColumns(table.headers);
        _idempotencyKey = VendorRepository.newIdempotencyKey();
        _stage = _Stage.match;
      });
    } on ImportFormatException catch (e) {
      setState(
        () => _error = e.message == 'norows'
            ? L.importNoRows
            : L.importReadFailed,
      );
    } catch (_) {
      setState(() => _error = L.importReadFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<ImportField> get _missingRequired => [
    for (final f in ImportField.values)
      if (f.required && _mapping[f] == null) f,
  ];

  void _toReview() {
    setState(() {
      _rows = mapImportRows(_table!, _mapping);
      _stage = _Stage.review;
    });
  }

  Future<void> _import() async {
    final app = AppScope.read(context);
    final valid = _rows.where((r) => r.valid).toList();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await app.repo.importOrdersBatch(
        businessId: app.business!.id,
        rows: [for (final r in valid) r.toRpc()],
        idempotencyKey: _idempotencyKey!,
      );
      if (!mounted) return;
      setState(() {
        _committed = res.committed;
        _rejected = res.rejected;
        _stage = _Stage.result;
      });
      if (res.committed.isNotEmpty) {
        ordersRevision.value++;
        app.dataChanged();
      }
    } catch (e) {
      // Nothing is claimed: the same key is kept, so a retry is replay-safe.
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _restart() => setState(() {
    _stage = _Stage.source;
    _table = null;
    _rows = [];
    _error = null;
    _committed = [];
    _rejected = [];
  });

  Future<void> _pickColumn(ImportField f) async {
    final headers = _table!.headers;
    await showListSheet(
      context,
      title: importFieldLabel(f),
      children: [
        for (final (i, h) in headers.indexed)
          CefListRow(
            title: h.isEmpty ? '—' : h,
            subtitle: _sample(i),
            showChevron: false,
            trailing: _mapping[f] == i
                ? Icon(LucideIcons.check, color: CefColors.brand)
                : null,
            onTap: () {
              setState(() {
                // A column feeds one field: take it from any other field.
                for (final k in ImportField.values) {
                  if (_mapping[k] == i) _mapping[k] = null;
                }
                _mapping[f] = i;
              });
              Navigator.of(context).pop();
            },
          ),
        if (!f.required)
          CefListRow(
            title: L.importNotMapped,
            showChevron: false,
            onTap: () {
              setState(() => _mapping[f] = null);
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }

  String? _sample(int column) {
    for (final r in _table!.rows) {
      if (r[column].isNotEmpty) return r[column];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => switch (_stage) {
    _Stage.source => _sourceView(context),
    _Stage.match => _matchView(context),
    _Stage.review => _reviewView(context),
    _Stage.result => _resultView(context),
  };

  Widget _errorLine(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.md),
    child: Text(
      _error!,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: context.c.attention),
    ),
  );

  Widget _sourceView(BuildContext context) => PageBody(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, step) in _steps.indexed)
            Expanded(
              child: _HowStep(icon: step.$1, label: step.$2, n: index + 1),
            ),
        ],
      ),
      SectionHeading(L.sources, icon: LucideIcons.cloudUpload),
      for (final source in _ImportSource.values)
        CefListRow(
          leading: _ImportSourceMark(source: source),
          title: source.label,
          subtitle: source.description,
          subtitleMaxLines: 2,
          trailing: source.needsGoogle
              ? _Pill(L.connectGoogle)
              : _busy
              ? const CefDots()
              : null,
          showChevron: !source.needsGoogle,
          onTap: _busy
              ? null
              : source.needsGoogle
              ? () => showCefToast(context, L.googleConnectPending)
              : _chooseFile,
        ),
      if (_error != null) _errorLine(context),
    ],
  );

  Widget _matchView(BuildContext context) {
    final missing = _missingRequired;
    return PageBody(
      bottom: CefButton(
        L.importContinueReview,
        onTap: missing.isEmpty ? _toReview : null,
      ),
      children: [
        CefListRow(
          icon: LucideIcons.fileSpreadsheet,
          title: _fileName,
          subtitle: '${_table!.rows.length} · ${L.importRowsDetected}',
          showChevron: false,
          trailing: TextButton(
            onPressed: _restart,
            child: Text(L.importChangeFile),
          ),
        ),
        SectionHeading(
          L.howStepMap,
          icon: LucideIcons.columns3,
          subtitle: L.importMatchHint,
        ),
        for (final f in ImportField.values)
          CefListRow(
            title: importFieldLabel(f) + (f.required ? ' *' : ''),
            subtitle: _mapping[f] == null
                ? L.importNotMapped
                : '${_table!.headers[_mapping[f]!]}${_sample(_mapping[f]!) == null ? '' : ' · e.g. ${_sample(_mapping[f]!)}'}',
            titleColor: f.required && _mapping[f] == null
                ? context.c.attention
                : null,
            onTap: () => _pickColumn(f),
          ),
        if (missing.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              L.importMatchRequired(missing.map(importFieldLabel).join(', ')),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.c.attention),
            ),
          ),
      ],
    );
  }

  Widget _reviewView(BuildContext context) {
    final valid = _rows.where((r) => r.valid).length;
    final invalid = _rows.where((r) => !r.valid).toList();
    final mapped = [
      for (final f in ImportField.values)
        if (_mapping[f] != null) importFieldLabel(f),
    ];
    return PageBody(
      bottom: CefButton(
        L.importCountOrders(valid),
        busy: _busy,
        busyLabel: L.importingOrders,
        onTap: valid == 0 ? null : _import,
      ),
      children: [
        StatsCard(
          items: [
            KpiItem('${_rows.length}', L.importRowsDetected),
            KpiItem('$valid', L.importRowsValid, color: context.c.success),
            KpiItem(
              '${invalid.length}',
              L.importRowsInvalid,
              color: invalid.isEmpty ? null : context.c.attention,
            ),
          ],
        ),
        SectionHeading(L.importMappedFields, icon: LucideIcons.columns3),
        Text(mapped.join(' · '), style: Theme.of(context).textTheme.bodyMedium),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _stage = _Stage.match),
          child: Text(L.importBackToMatch),
        ),
        if (invalid.isNotEmpty) ...[
          SectionHeading(
            L.importRowsInvalid,
            icon: LucideIcons.circleAlert,
            subtitle: L.importInvalidNote,
          ),
          for (final r in invalid)
            CefListRow(
              icon: LucideIcons.circleAlert,
              title: L.importRowMissing(
                r.ref,
                r.missing.map(importFieldLabel).join(', '),
              ),
              subtitle: r.values[ImportField.customerName],
              showChevron: false,
              dense: true,
            ),
        ],
        if (_error != null) _errorLine(context),
      ],
    );
  }

  Widget _resultView(BuildContext context) {
    final app = AppScope.of(context);
    final skipped = _rows.where((r) => !r.valid).toList();
    final title = _committed.isEmpty
        ? L.importResultNone
        : (_rejected.isEmpty && skipped.isEmpty)
        ? L.importResultDone
        : L.importResultPartial;
    return PageBody(
      bottom: CefButton(L.importViewOrders, onTap: () => app.go(VRoute.orders)),
      children: [
        StateBlock.empty(title),
        StatsCard(
          items: [
            KpiItem(
              '${_committed.length}',
              L.importKpiCreated,
              color: context.c.success,
            ),
            KpiItem(
              '${_rejected.length}',
              L.importKpiRejected,
              color: _rejected.isEmpty ? null : context.c.attention,
            ),
            KpiItem(
              '${skipped.length}',
              L.importKpiNotSent,
              color: skipped.isEmpty ? null : context.c.warning,
            ),
          ],
        ),
        if (_rejected.isNotEmpty) ...[
          SectionHeading(
            L.importRejectedCount(_rejected.length),
            icon: LucideIcons.circleAlert,
          ),
          for (final r in _rejected)
            CefListRow(
              icon: LucideIcons.circleAlert,
              title: L.importRowReason(
                '${r['source_row_ref']}',
                '${r['reason']}',
              ),
              showChevron: false,
              dense: true,
            ),
        ],
        if (skipped.isNotEmpty) ...[
          SectionHeading(
            L.importSkippedCount(skipped.length),
            icon: LucideIcons.circleAlert,
          ),
          for (final r in skipped)
            CefListRow(
              icon: LucideIcons.circleAlert,
              title: L.importRowMissing(
                r.ref,
                r.missing.map(importFieldLabel).join(', '),
              ),
              showChevron: false,
              dense: true,
            ),
        ],
        const SizedBox(height: Gap.md),
        CefButton(L.importAnotherFile, secondary: true, onTap: _restart),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Gap.md,
      vertical: Gap.xs + 2,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: context.c.border),
      borderRadius: BorderRadius.circular(Sizes.buttonRadius),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelMedium),
  );
}

class _ImportSourceMark extends StatelessWidget {
  const _ImportSourceMark({required this.source});
  final _ImportSource source;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: Sizes.avatar,
    height: Sizes.avatar,
    child: Center(
      child: Image.asset(
        source.assetPath,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    ),
  );
}

class _HowStep extends StatelessWidget {
  const _HowStep({required this.icon, required this.label, required this.n});
  final IconData icon;
  final String label;
  final int n;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: context.c.subtle,
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
        ),
        child: Icon(icon, size: 24, color: CefColors.navy),
      ),
      const SizedBox(height: Gap.sm),
      Text(
        '$n. $label',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    ],
  );
}
