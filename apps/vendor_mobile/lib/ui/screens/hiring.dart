import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// D-75 "Looking for riders" (Owner only): the business's openings shown to
/// Drivers in Find Jobs. Riders who request one arrive in Riders > Pending,
/// and the Owner approves them as today. Server: save_job_opening /
/// close_job_opening (Owner only), rider_job_openings (members read).
class LookingForRidersCard extends StatefulWidget {
  const LookingForRidersCard({super.key});

  @override
  State<LookingForRidersCard> createState() => _LookingForRidersCardState();
}

class _LookingForRidersCardState extends State<LookingForRidersCard> {
  List<Map<String, dynamic>>? _openings;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final app = AppScope.read(context);
    final b = app.business;
    if (b == null) return;
    try {
      final rows = await app.repo.jobOpenings(b.id);
      if (mounted) setState(() => _openings = rows);
    } on RepositoryError catch (e) {
      if (mounted) {
        setState(() => _openings = const []);
        showCefToast(context, e.message, error: true);
      }
    }
  }

  Future<void> _add() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _OpeningForm(),
    );
    if (saved == true) {
      await _load();
      if (mounted) showCefToast(context, L.openingPosted);
    }
  }

  Future<void> _close(String id) async {
    final app = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await app.repo.closeJobOpening(id);
      await _load();
      if (mounted) showCefToast(context, L.openingClosed);
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(bool on) async {
    final list = _openings ?? const [];
    if (on) return _add();
    if (list.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(L.turnOffHiringTitle),
        content: Text(L.turnOffHiringBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(L.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(L.turnOff),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final app = AppScope.read(context);
    setState(() => _busy = true);
    try {
      for (final o in list) {
        await app.repo.closeJobOpening(o['id'] as String);
      }
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      await _load();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final list = _openings;
    final on = (list ?? const []).isNotEmpty;
    return CefCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L.lookingForRiders, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      on ? L.lookingForRidersOn : L.lookingForRidersOff,
                      style: text.bodySmall?.copyWith(
                        color: context.c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CefSwitch(
                value: on,
                onChanged: list == null || _busy ? (_) {} : _toggle,
              ),
            ],
          ),
          if (on) ...[
            const SizedBox(height: Gap.md),
            for (final o in list!) ...[
              _OpeningRow(
                opening: o,
                onClose: _busy ? null : () => _close(o['id'] as String),
              ),
              const SizedBox(height: Gap.sm),
            ],
            CefButton(
              L.addOpening,
              secondary: true,
              icon: LucideIcons.plus,
              onTap: _busy ? null : _add,
            ),
          ],
        ],
      ),
    );
  }
}

String _hhmm(String t) {
  final p = t.split(':');
  final h = int.parse(p[0]), m = int.parse(p[1]);
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}

List<String> get _days => [
  L.monday,
  L.tuesday,
  L.wednesday,
  L.thursday,
  L.friday,
  L.saturday,
  L.sunday,
];

String _short(String day) => day.length <= 3 ? day : day.substring(0, 3);

String _vehicle(String v) => switch (v) {
  'car' => L.vehCar,
  'van' => L.vehVan,
  _ => L.vehMotorbike,
};

String _unit(String u) => switch (u) {
  'drop' => L.payDrop,
  'hour' => L.payHour,
  _ => L.payShift,
};

String _num(num v) =>
    v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);

class _OpeningRow extends StatelessWidget {
  const _OpeningRow({required this.opening, required this.onClose});
  final Map<String, dynamic> opening;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final o = opening;
    final text = Theme.of(context).textTheme;
    final days = [for (final d in (o['days'] as List)) (d as num).toInt()]
      ..sort();
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: context.c.subtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_hhmm(o['shift_start'] as String)} – ${_hhmm(o['shift_end'] as String)}',
                  style: text.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    days.map((d) => _short(_days[d - 1])).join(', '),
                    _vehicle(o['vehicle_type'] as String),
                    'RM ${_num(o['pay_amount'] as num)} / ${_unit(o['pay_unit'] as String)}',
                    '× ${o['riders_needed']}',
                    L.openingRadius(_num(o['radius_km'] as num)),
                  ].join(' · '),
                  style: text.bodySmall?.copyWith(
                    color: context.c.textSecondary,
                  ),
                ),
                Text(
                  o['area_label'] as String,
                  style: text.bodySmall?.copyWith(
                    color: context.c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onClose, child: Text(L.closeOpening)),
        ],
      ),
    );
  }
}

/// New opening: area, days, start/end, vehicle, pay, riders needed and the
/// rider radius (5–20 km). The server validates everything again.
class _OpeningForm extends StatefulWidget {
  const _OpeningForm();

  @override
  State<_OpeningForm> createState() => _OpeningFormState();
}

class _OpeningFormState extends State<_OpeningForm> {
  final _area = TextEditingController();
  final _pay = TextEditingController(text: '45');
  final Set<int> _picked = {1, 2, 3, 4, 5};
  TimeOfDay _start = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 11, minute: 0);
  String _vehicleType = 'motorcycle';
  String _payUnit = 'shift';
  int _needed = 1;
  double _radius = 10;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _area.dispose();
    _pay.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    final t = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (t != null) setState(() => start ? _start = t : _end = t);
  }

  Future<void> _save() async {
    final pay = num.tryParse(_pay.text.trim().replaceAll(',', '.'));
    final startM = _start.hour * 60 + _start.minute;
    final endM = _end.hour * 60 + _end.minute;
    if (_area.text.trim().length < 2 ||
        _picked.isEmpty ||
        endM <= startM ||
        pay == null ||
        pay <= 0) {
      setState(() => _error = L.openingFixFields);
      return;
    }
    final app = AppScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await app.repo.saveJobOpening(
        businessId: app.business!.id,
        areaLabel: _area.text.trim(),
        shiftStart: _fmt(_start),
        shiftEnd: _fmt(_end),
        days: (_picked.toList()..sort()),
        vehicleType: _vehicleType,
        payAmount: pay,
        payUnit: _payUnit,
        ridersNeeded: _needed,
        radiusKm: _radius.round(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: Gap.md, bottom: Gap.xs),
      child: Text(s, style: text.labelLarge),
    );
    return Padding(
      padding: EdgeInsets.only(
        left: Gap.gutter,
        right: Gap.gutter,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Gap.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(L.newOpening, style: text.titleLarge),
            label(L.openingArea),
            CefField(controller: _area, hint: L.openingAreaHint),
            label(L.openingDays),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 1; d <= 7; d++)
                  CefChoiceChip(
                    label: _short(_days[d - 1]),
                    selected: _picked.contains(d),
                    onTap: () => setState(
                      () => _picked.contains(d)
                          ? _picked.remove(d)
                          : _picked.add(d),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label(L.openingStart),
                      CefButton(
                        _start.format(context),
                        secondary: true,
                        onTap: () => _pick(true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label(L.openingEnd),
                      CefButton(
                        _end.format(context),
                        secondary: true,
                        onTap: () => _pick(false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            label(L.openingVehicle),
            Wrap(
              spacing: 6,
              children: [
                for (final v in const ['motorcycle', 'car', 'van'])
                  CefChoiceChip(
                    label: _vehicle(v),
                    selected: _vehicleType == v,
                    onTap: () => setState(() => _vehicleType = v),
                  ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label(L.openingPay),
                      CefField(
                        controller: _pay,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      label(L.openingPayUnit),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final u in const ['shift', 'drop', 'hour'])
                            CefChoiceChip(
                              label: _unit(u),
                              selected: _payUnit == u,
                              onTap: () => setState(() => _payUnit = u),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            label(L.openingRidersNeeded),
            Row(
              children: [
                IconButton(
                  onPressed: _needed > 1
                      ? () => setState(() => _needed--)
                      : null,
                  icon: const Icon(LucideIcons.minus),
                ),
                Text('$_needed', style: text.titleMedium),
                IconButton(
                  onPressed: _needed < 50
                      ? () => setState(() => _needed++)
                      : null,
                  icon: const Icon(LucideIcons.plus),
                ),
              ],
            ),
            label(L.openingRadius(_radius.round().toString())),
            Slider(
              value: _radius,
              min: 5,
              max: 20,
              divisions: 15,
              label: '${_radius.round()} km',
              onChanged: (v) => setState(() => _radius = v),
            ),
            if (_error != null) ...[
              Text(
                _error!,
                style: text.bodySmall?.copyWith(color: context.c.attention),
              ),
              const SizedBox(height: Gap.sm),
            ],
            const SizedBox(height: Gap.sm),
            CefButton(L.postOpening, busy: _busy, onTap: _busy ? null : _save),
          ],
        ),
      ),
    );
  }
}
