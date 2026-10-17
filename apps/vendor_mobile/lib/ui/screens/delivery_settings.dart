import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../async_view.dart';
import '../shell.dart' show PageBody;
import '../widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// V-41 Delivery settings (Founder 2026-10-17): how many orders the planner
/// puts in one run (set_business_run_size, used by propose_delivery_plan).
/// Service area and zones keep their own screens.
class DeliverySettingsScreen extends StatefulWidget {
  const DeliverySettingsScreen({super.key});

  @override
  State<DeliverySettingsScreen> createState() => _DeliverySettingsScreenState();
}

class _DeliverySettingsScreenState extends State<DeliverySettingsScreen> {
  int? _min, _max;
  bool _busy = false;

  Future<void> _save() async {
    final app = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await app.repo.setRunSize(app.business!.id, _min!, _max!);
      if (!mounted) return;
      showCefToast(context, L.dsSaved);
      app.back();
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _stepper(
    String label,
    int value,
    int lo,
    int hi,
    ValueChanged<int> set,
  ) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: text.bodyLarge)),
        IconButton.outlined(
          onPressed: value > lo ? () => set(value - 1) : null,
          icon: const Icon(LucideIcons.minus, size: 18),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
        ),
        IconButton.outlined(
          onPressed: value < hi ? () => set(value + 1) : null,
          icon: const Icon(LucideIcons.plus, size: 18),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    return AsyncView<(int, int)>(
      key: ValueKey('run-size-${app.business?.id}'),
      load: () => app.repo.runSize(app.business!.id),
      builder: (context, saved, reload) {
        final min = _min ??= saved.$1;
        final max = _max ??= saved.$2;
        final dirty = min != saved.$1 || max != saved.$2;
        return PageBody(
          bottom: CefButton(
            L.saveChanges,
            busy: _busy,
            onTap: dirty && !_busy ? _save : null,
          ),
          children: [
            SectionHeading(
              L.dsRunSize,
              icon: LucideIcons.route,
              subtitle: L.dsLead,
            ),
            const SizedBox(height: Gap.md),
            _stepper(L.dsMin, min, 1, max, (v) => setState(() => _min = v)),
            const SizedBox(height: Gap.sm),
            _stepper(L.dsMax, max, min, 50, (v) => setState(() => _max = v)),
            const SizedBox(height: Gap.md),
            Text(L.dsHint, style: text.bodySmall),
            const SizedBox(height: Gap.xl),
            const StorefrontDeliverySection(),
            const SizedBox(height: Gap.xl),
            const StorefrontPaymentsSection(),
          ],
        );
      },
    );
  }
}

/// Storefront delivery plan (Founder 2026-10-17): fee per drop (the driver's
/// pay, never free), delivery weekdays, batches and package lengths.
class StorefrontDeliverySection extends StatefulWidget {
  const StorefrontDeliverySection({super.key});

  @override
  State<StorefrontDeliverySection> createState() =>
      _StorefrontDeliverySectionState();
}

class _StorefrontDeliverySectionState extends State<StorefrontDeliverySection> {
  final _fee = TextEditingController();
  List<int> _days = const [1, 2, 3, 4, 5];
  List<int> _weeks = const [1, 2, 4];
  final List<
    (TextEditingController, TextEditingController, TextEditingController)
  >
  _batches = [];
  bool _loaded = false, _busy = false;

  static const _dayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final app = AppScope.read(context);
    app.repo
        .storefrontDelivery(app.business!.id)
        .then((d) {
          if (!mounted) return;
          setState(() {
            _fee.text = d.fee == null ? '' : d.fee!.toStringAsFixed(2);
            _days = [...d.days];
            _weeks = [...d.weeks];
            for (final b in d.shifts) {
              _batches.add((
                TextEditingController(text: b.name),
                TextEditingController(text: b.from),
                TextEditingController(text: b.to),
              ));
            }
          });
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _fee.dispose();
    for (final b in _batches) {
      b.$1.dispose();
      b.$2.dispose();
      b.$3.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final fee = double.tryParse(_fee.text.trim());
    if (fee == null || fee < 0) {
      showCefToast(context, L.sdFeeNeeded, error: true);
      return;
    }
    final app = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await app.repo.saveStorefrontDelivery(
        app.business!.id,
        StorefrontDelivery(
          fee: fee,
          days: _days,
          weeks: _weeks,
          shifts: [
            for (final b in _batches)
              if (b.$1.text.trim().isNotEmpty)
                (
                  name: b.$1.text.trim(),
                  from: b.$2.text.trim(),
                  to: b.$3.text.trim(),
                ),
          ],
        ),
      );
      if (mounted) showCefToast(context, L.dsSaved);
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _chips(
    List<int> all,
    List<int> on,
    String Function(int) label,
    ValueChanged<List<int>> set,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final v in all)
          FilterChip(
            label: Text(label(v)),
            selected: on.contains(v),
            onSelected: (sel) {
              final next = {...on};
              sel ? next.add(v) : (next.length > 1 ? next.remove(v) : null);
              set(next.toList()..sort());
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(L.sdTitle, icon: LucideIcons.truck, subtitle: L.sdLead),
        const SizedBox(height: Gap.md),
        TextField(
          controller: _fee,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: L.sdFee, prefixText: 'RM '),
        ),
        const SizedBox(height: Gap.xs),
        Text(L.sdFeeHint, style: text.bodySmall),
        const SizedBox(height: Gap.md),
        Text(L.sdDays, style: text.titleSmall),
        const SizedBox(height: Gap.xs),
        _chips(
          [1, 2, 3, 4, 5, 6, 7],
          _days,
          (d) => _dayKeys[d - 1],
          (v) => setState(() => _days = v),
        ),
        const SizedBox(height: Gap.md),
        Text(L.sdWeeks, style: text.titleSmall),
        const SizedBox(height: Gap.xs),
        _chips(
          [1, 2, 3, 4],
          _weeks,
          (w) => w == 1 ? L.sdWeek1 : L.sdWeekN(w),
          (v) => setState(() => _weeks = v),
        ),
        const SizedBox(height: Gap.md),
        Text(L.sdBatches, style: text.titleSmall),
        const SizedBox(height: Gap.xs),
        for (final (i, b) in _batches.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.xs),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: b.$1,
                    decoration: InputDecoration(labelText: L.sdBatchName),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: b.$2,
                    decoration: const InputDecoration(hintText: '18:00'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: b.$3,
                    decoration: const InputDecoration(hintText: '20:00'),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _batches.removeAt(i)),
                  icon: const Icon(LucideIcons.x, size: 18),
                ),
              ],
            ),
          ),
        if (_batches.length < 4)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(
                () => _batches.add((
                  TextEditingController(),
                  TextEditingController(text: '18:00'),
                  TextEditingController(text: '20:00'),
                )),
              ),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(L.sdAddBatch),
            ),
          ),
        Text(L.sdBatchesHint, style: text.bodySmall),
        const SizedBox(height: Gap.md),
        CefButton(L.saveChanges, busy: _busy, onTap: _busy ? null : _save),
      ],
    );
  }
}

/// Storefront payments (Founder 2026-10-17): connect the vendor's own Curlec
/// account (write-only secret) and the cash-on-delivery switch.
class StorefrontPaymentsSection extends StatefulWidget {
  const StorefrontPaymentsSection({super.key});

  @override
  State<StorefrontPaymentsSection> createState() =>
      _StorefrontPaymentsSectionState();
}

class _StorefrontPaymentsSectionState extends State<StorefrontPaymentsSection> {
  final _brand = TextEditingController();
  final _secret = TextEditingController();
  Map<String, dynamic>? _s;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_s == null) _load();
  }

  Future<void> _load() async {
    final app = AppScope.read(context);
    try {
      final s = await app.repo.paymentSettings(app.business!.id);
      if (mounted) setState(() => _s = s);
    } catch (_) {
      if (mounted) {
        setState(() => _s = {'connected': false, 'accept_cod': true});
      }
    }
  }

  @override
  void dispose() {
    _brand.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _do(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
      await _load();
      if (mounted) showCefToast(context, L.dsSaved);
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final s = _s;
    if (s == null) return const SizedBox.shrink();
    final connected = s['connected'] == true;
    final id = app.business!.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          L.spTitle,
          icon: LucideIcons.creditCard,
          subtitle: L.spLead,
        ),
        const SizedBox(height: Gap.md),
        if (connected) ...[
          Text(L.spConnected, style: text.bodyLarge),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => _do(() => app.repo.disconnectCurlec(id)),
              child: Text(L.spDisconnect),
            ),
          ),
        ] else ...[
          TextField(
            controller: _brand,
            decoration: InputDecoration(labelText: L.spBrand),
          ),
          const SizedBox(height: Gap.sm),
          TextField(
            controller: _secret,
            obscureText: true,
            decoration: InputDecoration(labelText: L.spSecret),
          ),
          const SizedBox(height: Gap.xs),
          Text(L.spHint, style: text.bodySmall),
          const SizedBox(height: Gap.sm),
          CefButton(
            L.spConnect,
            busy: _busy,
            onTap: _busy
                ? null
                : () => _do(
                    () => app.repo.connectCurlec(
                      id,
                      _brand.text.trim(),
                      _secret.text.trim(),
                    ),
                  ),
          ),
        ],
        const SizedBox(height: Gap.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(L.spCod),
          subtitle: Text(connected ? L.spCodHint : L.spCodOnly),
          value: !connected || s['accept_cod'] != false,
          onChanged: !connected || _busy
              ? null
              : (v) => _do(() => app.repo.setStorefrontCod(id, v)),
        ),
      ],
    );
  }
}
