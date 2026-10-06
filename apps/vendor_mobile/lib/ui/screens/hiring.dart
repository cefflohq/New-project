import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../shell.dart' show PageBody;
import '../async_view.dart';
import '../widgets.dart';
import 'directory.dart' show TeamRequestRow;

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
  if (b == null || !b.canHire) {
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
        // An Operator never invites Operators (Owner only).
        if (app.business?.isOwner ?? false)
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
        // M2 follow-up: the Operator approves Helper join requests here (the
        // Owner does it in Team). Server: decide_team_join_request.
        if (app.business?.role == 'operator') const _HelperRequests(),
        const SizedBox(height: Gap.md),
        SectionHeading(L.yourHiringPosts, icon: LucideIcons.megaphone),
        ValueListenableBuilder(
          valueListenable: openOpenings,
          builder: (context, list, _) {
            final n = list?.length ?? 0;
            final m = (list ?? const []).fold<int>(
              0,
              (t, o) => t + pendingApplicants(o),
            );
            return CefListRow(
              title: L.roleDriver,
              subtitle: n > 0 ? L.hrPostsSummary(n, m) : L.noActiveHiring,
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

/// "RM3.50 / drop" for per-drop posts; legacy units keep their own label.
String _payLabel(Map<String, dynamic> o) {
  final amount = (o['pay_amount'] as num).toStringAsFixed(2);
  return o['pay_unit'] == 'drop'
      ? L.hrPerDrop(amount)
      : 'RM $amount / ${_unit(o['pay_unit'] as String)}';
}

/// Applicants still waiting on a post (pending requests).
int pendingApplicants(Map<String, dynamic> o) => [
  for (final r in (o['rider_job_requests'] as List? ?? const []))
    if ((r as Map)['status'] == 'pending') r,
].length;

class _OpeningRow extends StatelessWidget {
  const _OpeningRow({required this.opening, required this.onClose});
  final Map<String, dynamic> opening;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final o = opening;
    final c = context.c;
    final app = AppScope.of(context);
    final waiting = pendingApplicants(o);
    final days = [for (final d in (o['days'] as List)) (d as num).toInt()]
      ..sort();
    // Tap: the post's Driver Hiring page (applicants + details).
    return InkWell(
      onTap: () => app.go(VRoute.hiringPost, entityId: o['id'] as String),
      child: Container(
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
                    o['shift_end'] == null
                        ? L.hrPickupAt(_hhmm(o['shift_start'] as String))
                        : '${_hhmm(o['shift_start'] as String)} – ${_hhmm(o['shift_end'] as String)}',
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
                      _payLabel(o),
                      '× ${o['riders_needed']}',
                    ].join(' · '),
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                  Text(
                    '${o['area_label']} · ${_num(o['radius_km'] as num)} km',
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                  if (waiting > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: StatusChip(L.hrApplicantsTab(waiting), info: true),
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
      ),
    );
  }
}

/// Hiring Driver (M1 contract, Founder screen 3): area, days, pickup time
/// (no end time), vehicle, pay per drop (minimum RM3.00), drivers needed and
/// driver reach (1–15 km, default 10). The server validates everything again.
class _OpeningForm extends StatefulWidget {
  const _OpeningForm();

  @override
  State<_OpeningForm> createState() => _OpeningFormState();
}

class _OpeningFormState extends State<_OpeningForm> {
  final _area = TextEditingController();
  final _pay = TextEditingController(text: '3.00');
  final Set<int> _picked = {1, 2, 3, 4, 5};
  TimeOfDay _pickup = const TimeOfDay(hour: 7, minute: 0);
  String _vehicleType = 'motorcycle';
  int _needed = 1;
  double _reach = 10;
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

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _pickup);
    if (t != null) setState(() => _pickup = t);
  }

  num? get _payValue => num.tryParse(_pay.text.trim().replaceAll(',', '.'));
  bool get _payTooLow => (_payValue ?? 0) < 3;

  Future<void> _save() async {
    final pay = _payValue;
    if (_area.text.trim().length < 2 ||
        _picked.isEmpty ||
        pay == null ||
        pay < 3) {
      setState(() => _error = L.hrFix);
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
        pickupTime: _fmt(_pickup),
        days: (_picked.toList()..sort()),
        vehicleType: _vehicleType,
        payPerDrop: pay,
        driversNeeded: _needed,
        reachKm: _reach.round(),
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
    Widget hint(String t, {bool error = false}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 12.5,
          color: error ? c.attention : c.textSecondary,
        ),
      ),
    );
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
                L.hrTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                  color: CefColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                L.hiringDriverSub,
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
                label: L.hrPickupTime,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180,
                      child: _TimeField(
                        label: L.hrPickupTime,
                        value: _pickup.format(context),
                        onTap: _pickTime,
                      ),
                    ),
                    hint(L.hrPickupHint),
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
                label: L.hrPayPerDrop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 160,
                      child: _OutlinedInput(
                        controller: _pay,
                        prefix: 'RM',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    hint(L.hrPayMin, error: _payTooLow),
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
                label: L.hrReach,
                trailing: Text(
                  '${_reach.round()} km',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: _reach,
                        min: 1,
                        max: 15,
                        divisions: 14,
                        onChanged: (v) => setState(() => _reach = v),
                      ),
                      hint(L.hrReachHint('${_reach.round()}')),
                    ],
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
                      : Text(L.hrPublish),
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
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final String? prefix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
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

/// Founder screen 10 — one Driver hiring post: "Active · N applicants",
/// Applicants | Details. Approve / Reject use the existing rider approval
/// flow (approve_pending_rider / deactivate_rider, Owner-only server-side).
class HiringPostScreen extends StatefulWidget {
  const HiringPostScreen({super.key, required this.openingId});
  final String openingId;

  @override
  State<HiringPostScreen> createState() => _HiringPostScreenState();
}

class _HiringPostScreenState extends State<HiringPostScreen> {
  int _tab = 0;
  String? _busy;

  Future<(Map<String, dynamic>?, List<Map<String, dynamic>>)> _load() async {
    final app = AppScope.read(context);
    await loadOpenOpenings(app);
    final post = (openOpenings.value ?? const [])
        .where((o) => o['id'] == widget.openingId)
        .firstOrNull;
    return (post, await app.repo.openingApplicants(widget.openingId));
  }

  Future<void> _decide(
    Map<String, dynamic> r,
    bool approve,
    VoidCallback reload,
  ) async {
    final app = AppScope.read(context);
    final riderId = r['rider_id'] as String;
    setState(() => _busy = riderId);
    try {
      approve
          ? await app.repo.approvePendingRider(riderId)
          : await app.repo.rejectPendingRider(riderId);
      if (mounted) {
        showCefToast(context, approve ? L.hrApprovedToast : L.hrRejectedToast);
      }
      reload();
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AsyncView<(Map<String, dynamic>?, List<Map<String, dynamic>>)>(
      key: ValueKey('hiring-post-${widget.openingId}'),
      load: _load,
      builder: (context, data, reload) {
        final (post, applicants) = data;
        if (post == null) {
          return PageBody(children: [StateBlock.empty(L.noOpenOpenings)]);
        }
        final waiting = applicants
            .where((r) => r['status'] == 'pending')
            .length;
        final tabs = [L.hrApplicantsTab(applicants.length), L.hrDetailsTab];
        final days = [
          for (final d in (post['days'] as List)) (d as num).toInt(),
        ]..sort();
        Widget kv(String k, String v) => CefListRow(title: k, subtitle: v);
        return PageBody(
          onRefresh: () async => reload(),
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  L.hrActiveApplicants(waiting),
                  style: TextStyle(fontSize: 14, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            SegmentedTabs(
              labels: tabs,
              active: tabs[_tab],
              onChange: (l) => setState(() => _tab = tabs.indexOf(l)),
            ),
            const SizedBox(height: Gap.md),
            if (_tab == 1) ...[
              kv(L.hrArea, post['area_label'] as String),
              kv(L.hrDays, days.map((d) => _short(_days[d - 1])).join(', ')),
              kv(L.hrPickupTime, _hhmm(post['shift_start'] as String)),
              kv(L.hrVehicle, _vehicle(post['vehicle_type'] as String)),
              kv(L.hrPayPerDrop, _payLabel(post)),
              kv(L.hrDriversNeeded, '${post['riders_needed']}'),
              kv(L.hrReach, '${_num(post['radius_km'] as num)} km'),
            ] else if (applicants.isEmpty)
              StateBlock.empty(L.hrNoApplicants)
            else
              for (final r in applicants) _applicant(context, r, reload),
          ],
        );
      },
    );
  }

  Widget _applicant(
    BuildContext context,
    Map<String, dynamic> r,
    VoidCallback reload,
  ) {
    final rider = (r['riders'] as Map?) ?? const {};
    final name = (rider['name'] as String?) ?? L.rider;
    final created = DateTime.parse(r['created_at'] as String).toLocal();
    final status = r['status'] as String;
    final isNew =
        status == 'pending' &&
        DateTime.now().difference(created) < const Duration(hours: 24);
    final chip = switch (status) {
      'approved' => StatusChip(L.hrApproved, success: true),
      'rejected' || 'withdrawn' => StatusChip(L.hrRejected),
      _ =>
        isNew
            ? StatusChip(L.hrNew, info: true)
            : StatusChip(L.hrPending, warning: true),
    };
    final date =
        '${created.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][created.month - 1]} ${created.year}';
    final pending = status == 'pending' && rider['status'] == 'pending';
    final busy = _busy == r['rider_id'];
    return CefListRow(
      title: name,
      subtitle: [
        [
          if (rider['vehicle_type'] != null)
            _vehicle(rider['vehicle_type'] as String),
          if (rider['vehicle_plate'] != null) rider['vehicle_plate'] as String,
        ].join(' · '),
        L.hrAppliedVia(date),
      ].where((x) => x.isNotEmpty).join('\n'),
      subtitleMaxLines: 2,
      leading: CefAvatar(name, filled: true),
      trailing: chip,
      onTap: !pending || busy
          ? null
          : () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.white,
              showDragHandle: true,
              builder: (sheet) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.gutter,
                    0,
                    Gap.gutter,
                    Gap.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: Gap.md),
                      CefButton(
                        L.hrApprove,
                        onTap: () {
                          Navigator.of(sheet).pop();
                          _decide(r, true, reload);
                        },
                      ),
                      const SizedBox(height: Gap.sm),
                      CefButton(
                        L.hrReject,
                        destructive: true,
                        onTap: () {
                          Navigator.of(sheet).pop();
                          _decide(r, false, reload);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Pending Helper join requests for the Operator (RLS shows role = helper
/// only), with the same Approve / Reject row as Team.
class _HelperRequests extends StatelessWidget {
  const _HelperRequests();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AsyncView<List<Map<String, dynamic>>>(
      key: ValueKey('helper-requests-${app.business?.id}'),
      load: () async =>
          (await app.repo.pendingTeamRequests(app.business!.id))
              .where((r) => r['role'] == 'helper')
              .toList(),
      builder: (context, requests, reload) => requests.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Gap.md),
                SectionHeading(L.joinRequests, icon: LucideIcons.userPlus),
                for (final r in requests)
                  TeamRequestRow(request: r, onDecided: () async => reload()),
              ],
            ),
    );
  }
}
