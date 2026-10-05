import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../shell.dart' show PageBody;
import '../widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// Riders page mode (Founder draft D, 2026-10-05): the Owner switches
/// between Riders and Openings; the header "+" adds whatever is showing.
enum RidersMode { riders, openings }

final ridersMode = ValueNotifier<RidersMode>(RidersMode.riders);

/// The business's open openings (null while loading), shared by the switch
/// label, the Openings list and the header "+".
final openOpenings = ValueNotifier<List<Map<String, dynamic>>?>(null);

Future<void> loadOpenOpenings(AppState app) async {
  final b = app.business;
  if (b == null || !b.isOwner) {
    openOpenings.value = const [];
    return;
  }
  try {
    openOpenings.value = await app.repo.jobOpenings(b.id);
  } on RepositoryError {
    openOpenings.value ??= const [];
  }
}

/// Team tab (Founder screen 6); the header "+" invites for the visible tab.
enum TeamTab { drivers, operators, helpers }

final teamTab = ValueNotifier<TeamTab>(TeamTab.drivers);

/// Founder screen 2 — Hiring home: choose who to hire, then the business's
/// hiring posts. Driver opens the existing New opening form; Operator and
/// Helper hiring wait for their phase (pay model not decided).
class HiringScreen extends StatefulWidget {
  const HiringScreen({super.key});

  @override
  State<HiringScreen> createState() => _HiringScreenState();
}

class _HiringScreenState extends State<HiringScreen> {
  @override
  void initState() {
    super.initState();
    loadOpenOpenings(AppScope.read(context));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final text = Theme.of(context).textTheme;
    return PageBody(
      onRefresh: () => loadOpenOpenings(app),
      children: [
        Text(
          L.hiringSub,
          style: text.bodyMedium?.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: Gap.md),
        CefListRow(
          title: L.roleDriver,
          subtitle: L.hiringDriverSub,
          icon: LucideIcons.motorbike,
          onTap: () => openNewOpening(context),
        ),
        CefListRow(
          title: L.roleOperator,
          subtitle: L.hiringOperatorSub,
          subtitleMaxLines: 2,
          icon: LucideIcons.userCog,
          // Live through the existing Operator invite (link / QR): the join
          // request lands in Team for approval (team_join_requests).
          onTap: () {
            teamTab.value = TeamTab.operators;
            app.go(VRoute.helperRegistrationLink);
          },
        ),
        CefListRow(
          title: L.roleHelper,
          subtitle: L.hiringHelperSub,
          subtitleMaxLines: 2,
          icon: LucideIcons.package,
          onTap: () {
            teamTab.value = TeamTab.helpers;
            app.go(VRoute.helperRegistrationLink);
          },
        ),
        // Direct invite (link / QR) for the Team tab the Owner came from.
        CefListRow(
          title: switch (teamTab.value) {
            TeamTab.drivers => L.inviteDriver,
            TeamTab.operators => L.inviteOperator,
            TeamTab.helpers => L.inviteHelper,
          },
          icon: LucideIcons.qrCode,
          onTap: () => app.go(
            teamTab.value == TeamTab.drivers
                ? VRoute.riderRegistrationLink
                : VRoute.helperRegistrationLink,
          ),
        ),
        const SizedBox(height: Gap.md),
        SectionHeading(L.yourHiringPosts, icon: LucideIcons.megaphone),
        ValueListenableBuilder(
          valueListenable: openOpenings,
          builder: (context, list, _) {
            final n = list?.length ?? 0;
            return CefListRow(
              title: L.roleDriver,
              subtitle: n > 0 ? L.hiringActiveCount(n) : L.noActiveHiring,
              icon: LucideIcons.motorbike,
              // The posts live on Drivers > Openings (draft D).
              onTap: () {
                ridersMode.value = RidersMode.openings;
                app.go(VRoute.riders);
              },
            );
          },
        ),
      ],
    );
  }
}

/// New opening form (Owner only; the server enforces it too).
Future<void> openNewOpening(BuildContext context) async {
  final app = AppScope.read(context);
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    // White surface (the theme default is a tinted cream).
    backgroundColor: Colors.white,
    builder: (_) => const _OpeningForm(),
  );
  if (saved == true) {
    await loadOpenOpenings(app);
    if (context.mounted) showCefToast(context, L.openingPosted);
  }
}

/// Riders | Openings (n): a small two-option switch at the top of Riders.
class RidersModeSwitch extends StatelessWidget {
  const RidersModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ValueListenableBuilder<RidersMode>(
      valueListenable: ridersMode,
      builder: (context, mode, _) => ValueListenableBuilder(
        valueListenable: openOpenings,
        builder: (context, list, _) {
          final n = list?.length ?? 0;
          Widget seg(String label, RidersMode m) {
            final on = mode == m;
            return Expanded(
              child: Semantics(
                button: true,
                selected: on,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ridersMode.value = m,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: on
                          ? const [
                              BoxShadow(
                                color: Color(0x1F0B1220),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: on ? CefColors.navy : c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: c.subtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                seg(L.ridersTab, RidersMode.riders),
                seg(
                  n > 0 ? '${L.openingsTab} ($n)' : L.openingsTab,
                  RidersMode.openings,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The Owner's open openings, each with Close; an empty state offers New
/// opening. Riders who apply arrive in Riders > Pending as today.
class OpeningsList extends StatefulWidget {
  const OpeningsList({super.key});

  @override
  State<OpeningsList> createState() => _OpeningsListState();
}

class _OpeningsListState extends State<OpeningsList> {
  String? _closing;

  Future<void> _close(String id) async {
    final app = AppScope.read(context);
    setState(() => _closing = id);
    try {
      await app.repo.closeJobOpening(id);
      await loadOpenOpenings(app);
      if (mounted) showCefToast(context, L.openingClosed);
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _closing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ValueListenableBuilder(
      valueListenable: openOpenings,
      builder: (context, list, _) {
        if (list == null) return const StateBlock.loading();
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.xl),
            child: Column(
              children: [
                Text(
                  L.noOpenOpenings,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.textSecondary),
                ),
                const SizedBox(height: Gap.lg),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: CefColors.standardBrand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => openNewOpening(context),
                    child: Text(L.newOpening),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final o in list)
              _OpeningRow(
                opening: o,
                onClose: _closing == null
                    ? () => _close(o['id'] as String)
                    : null,
              ),
          ],
        );
      },
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
    final c = context.c;
    final days = [for (final d in (o['days'] as List)) (d as num).toInt()]
      ..sort();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.briefcase,
              size: 18,
              color: CefColors.standardBrand,
            ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_hhmm(o['shift_start'] as String)} – ${_hhmm(o['shift_end'] as String)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CefColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    days.map((d) => _short(_days[d - 1])).join(', '),
                    _vehicle(o['vehicle_type'] as String),
                    'RM ${_num(o['pay_amount'] as num)} / ${_unit(o['pay_unit'] as String)}',
                    '× ${o['riders_needed']}',
                  ].join(' · '),
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
                Text(
                  '${o['area_label']} · ${_num(o['radius_km'] as num)} km',
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClose,
            child: Text(
              L.closeOpening,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC2410C),
              ),
            ),
          ),
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
    final c = context.c;
    final media = MediaQuery.of(context);
    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    // One white surface: sections are separated by spacing and a hairline,
    // never by cards. Yellow marks a selection; blue is the action.
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(
          left: Gap.gutter,
          right: Gap.gutter,
          bottom: media.viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                L.newOpening,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                  color: CefColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                L.newOpeningSub,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
              _FormSection(
                label: L.openingArea,
                first: true,
                child: _OutlinedInput(
                  controller: _area,
                  hint: L.openingAreaHint,
                  icon: LucideIcons.mapPin,
                ),
              ),
              _FormSection(
                label: L.openingDays,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      _Chip(
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
              ),
              _FormSection(
                label: L.openingTime,
                child: Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: L.openingStart,
                        value: _start.format(context),
                        onTap: () => _pick(true),
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: _TimeField(
                        label: L.openingEnd,
                        value: _end.format(context),
                        onTap: () => _pick(false),
                      ),
                    ),
                  ],
                ),
              ),
              _FormSection(
                label: L.openingVehicle,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (v, icon) in const [
                      ('motorcycle', LucideIcons.motorbike),
                      ('car', LucideIcons.car),
                      ('van', LucideIcons.truck),
                    ])
                      _Chip(
                        label: _vehicle(v),
                        icon: icon,
                        selected: _vehicleType == v,
                        onTap: () => setState(() => _vehicleType = v),
                      ),
                  ],
                ),
              ),
              _FormSection(
                label: L.openingPayLabel,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 128,
                      child: _OutlinedInput(
                        controller: _pay,
                        prefix: 'RM',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final u in const ['shift', 'drop', 'hour'])
                            _Chip(
                              label: cap(_unit(u)),
                              selected: _payUnit == u,
                              onTap: () => setState(() => _payUnit = u),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _FormSection(
                label: L.openingRidersNeeded,
                child: Row(
                  children: [
                    _StepButton(
                      icon: LucideIcons.minus,
                      onTap: _needed > 1
                          ? () => setState(() => _needed--)
                          : null,
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        '$_needed',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: CefColors.navy,
                        ),
                      ),
                    ),
                    _StepButton(
                      icon: LucideIcons.plus,
                      onTap: _needed < 50
                          ? () => setState(() => _needed++)
                          : null,
                    ),
                  ],
                ),
              ),
              _FormSection(
                label: L.openingRadiusLabel,
                trailing: Text(
                  '${_radius.round()} km',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CefColors.navy,
                  ),
                ),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: CefColors.standardBrand,
                    inactiveTrackColor: c.border,
                    thumbColor: Colors.white,
                    overlayColor: CefColors.standardBrand.withValues(alpha: .1),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                      elevation: 2,
                    ),
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: Slider(
                    value: _radius,
                    min: 5,
                    max: 20,
                    divisions: 15,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: Gap.sm),
                Text(
                  _error!,
                  style: TextStyle(fontSize: 13, color: c.attention),
                ),
              ],
              const SizedBox(height: Gap.lg),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: CefColors.standardBrand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(L.publishOpening),
                ),
              ),
              SizedBox(height: Gap.md + media.viewPadding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

/// A form section on the single white surface: hairline above (except the
/// first), label (and an optional value on the right), then the control.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.label,
    required this.child,
    this.trailing,
    this.first = false,
  });

  final String label;
  final Widget child;
  final Widget? trailing;
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: first ? Gap.lg : 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) ...[
          const SizedBox(height: Gap.md),
          Divider(height: 1, thickness: 1, color: context.c.border),
          const SizedBox(height: Gap.md),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CefColors.navy,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: Gap.sm),
        child,
      ],
    ),
  );
}

OutlineInputBorder _outline(Color color, [double width = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );

/// White field, light-grey outline, moderate radius; blue on focus.
class _OutlinedInput extends StatelessWidget {
  const _OutlinedInput({
    required this.controller,
    this.hint,
    this.icon,
    this.prefix,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final String? prefix;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: CefColors.navy,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: TextStyle(
          color: c.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: c.textSecondary),
        prefixText: prefix == null ? null : '$prefix  ',
        prefixStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: c.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: _outline(c.border),
        focusedBorder: _outline(CefColors.standardBrand, 1.5),
        border: _outline(c.border),
      ),
    );
  }
}

/// Start / End: a small label over the time, outlined like the inputs.
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label, value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CefColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.clock, size: 18, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact selection chip: yellow only when selected.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? CefColors.ceffloMustard : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? CefColors.ceffloMustard : c.border,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: CefColors.navy),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: CefColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small outlined round button for the riders stepper (44px touch target).
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox.square(
      dimension: 44,
      child: Material(
        color: Colors.white,
        shape: CircleBorder(side: BorderSide(color: c.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? c.border : CefColors.navy,
          ),
        ),
      ),
    );
  }
}
