import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/vendor_repository.dart';
import '../system_bars.dart';
import '../../core/routes.dart';
import '../router.dart';
import '../widgets.dart';
import 'directory.dart' show languageName, showLanguageSheet;

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// D-74 Helper workspace (Founder-approved Helper boards): the whole Vendor
/// app for a signed-in member whose role is `helper`.
///
///   Preparation -> Zones -> Packing (incl. sorting) -> Ready for Pickup
///
/// Founder correction: Packing and Sorting are ONE step in the UI. The
/// Helper checks each order once and slides once; the slide records the
/// canonical backend checkpoints in order (confirm_packing, each order
/// sorted, confirm_sorting per Run), so audit truth is unchanged.
///
/// No Vendor shell or navigation exists here. The server is the authority:
/// reads come only from my_fulfilment_tasks (minimised contract), writes
/// only through advance_preparation / confirm_packing / confirm_sorting.
/// "Slide to Confirm Pickup" is the Helper's release of the group; it never
/// records Rider custody (the Rider confirms pickup in the Driver app).
class HelperWorkspaceScreen extends StatefulWidget {
  const HelperWorkspaceScreen({super.key});
  @override
  State<HelperWorkspaceScreen> createState() => _HelperWorkspaceScreenState();
}

// ------------------------------------------------------------------ tokens

/// Cefflo blue header gradient (deep blue -> bright Cefflo blue).
const _headerBlue = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0A2A8A), Color(0xFF0B47D4), Color(0xFF1B7BF0)],
  stops: [0.0, 0.55, 1.0],
);
const _ink = CefColors.navy;
const _muted = Color(0xFF6B7385);
const _line = Color(0xFFE8EBF1);
const _cool = Color(0xFFF3F5F9);
const _green = Color(0xFF1E9E55);
const _greenTint = Color(0xFFE5F6EC);
const _amberTint = Color(0xFFFFF1D6);
const _amberInk = Color(0xFF8A5A00);

const _rank = {
  'not_started': 0,
  'preparing': 1,
  'packed': 2,
  'sorted': 3,
  'ready': 4,
};
int _r(FulfilmentTask t) => _rank[t.status] ?? 0;

enum _Tab { preparation, zones, packing, more }

/// One Zone of the working day: its tasks and derived progress.
class _Zone {
  _Zone(this.id, this.name, this.tasks);
  final String? id;
  final String name;
  final List<FulfilmentTask> tasks;

  int get orders => tasks.length;
  int get items => tasks.fold(0, (s, t) => s + t.itemCount);
  int get packed => tasks.where((t) => _r(t) >= 2).length;
  int get sorted => tasks.where((t) => _r(t) >= 3).length;
  bool get packingConfirmed => tasks.every((t) => t.packingConfirmed);
  bool get ready => tasks.every((t) => _r(t) >= 4);
  DateTime? get pickupAt => tasks
      .map((t) => t.pickupAt)
      .whereType<DateTime>()
      .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
}

class _HelperWorkspaceScreenState extends State<HelperWorkspaceScreen> {
  Future<FulfilmentBoard>? _load;
  FulfilmentBoard? _board;
  _Tab _tab = _Tab.preparation;
  String? _zoneKey; // selected Zone for Packing / Sorting
  bool _showReady = false;
  final _busy = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= _fetch();
  }

  Future<FulfilmentBoard> _fetch() async {
    final app = AppScope.read(context);
    final b = await app.repo.myFulfilmentBoard(app.business!.id);
    if (mounted) setState(() => _board = b);
    return b;
  }

  Future<void> _reload() async {
    final next = _fetch();
    setState(() {
      _load = next;
    });
    await next;
  }

  // ---------------------------------------------------------- working set

  /// Open work of the earliest working day (not yet picked up).
  List<FulfilmentTask> get _open {
    final all = (_board?.tasks ?? const <FulfilmentTask>[])
        .where((t) => !t.pickedUp)
        .toList();
    final days = all.map((t) => t.orderDate).whereType<String>().toList()
      ..sort();
    if (days.isEmpty) return all;
    return all.where((t) => t.orderDate == days.first).toList();
  }

  DateTime get _day =>
      DateTime.tryParse(_open.firstOrNull?.orderDate ?? '') ?? DateTime.now();

  /// Zones prioritised by pickup time, earliest first (Founder rule).
  List<_Zone> get _zones {
    final byZone = <String, List<FulfilmentTask>>{};
    for (final t in _open) {
      byZone.putIfAbsent(t.zoneId ?? '', () => []).add(t);
    }
    final zones = [
      for (final e in byZone.entries)
        _Zone(
          e.key.isEmpty ? null : e.key,
          e.value.first.zoneName ?? L.noZone,
          e.value,
        ),
    ];
    zones.sort((a, b) {
      final pa = a.pickupAt, pb = b.pickupAt;
      if (pa != null && pb != null && pa != pb) return pa.compareTo(pb);
      if (pa == null && pb != null) return 1;
      if (pa != null && pb == null) return -1;
      return a.name.compareTo(b.name);
    });
    return zones;
  }

  _Zone? _zone(String? key) =>
      _zones.where((z) => (z.id ?? '') == key).firstOrNull;

  _Zone? get _packingZone =>
      _zone(_zoneKey) ?? _zones.where((z) => !z.ready).firstOrNull;

  void _openZone(_Zone z) => setState(() {
    _zoneKey = z.id ?? '';
    _tab = _Tab.packing;
    _showReady = z.ready;
  });

  // -------------------------------------------------------------- actions

  Future<void> _run(String key, Future<void> Function() action) async {
    setState(() => _busy.add(key));
    try {
      await action();
      await _reload();
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
      await _reload();
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  /// Tap an order on Packing: it becomes Packed (via Preparing).
  Future<void> _pack(FulfilmentTask t) => _run(t.orderId, () async {
    final repo = AppScope.read(context).repo;
    if (t.status == 'not_started') {
      await repo.advancePreparation(t.orderId, 'preparing');
    }
    await repo.advancePreparation(t.orderId, 'packed');
  });

  /// The one slide: packing confirmation, each order sorted, then sorting
  /// confirmation per Run -> Ready for Pickup. Steps already done are
  /// skipped, so a retry after a failure continues where it stopped.
  /// Never Rider custody.
  Future<bool> _confirmZone(_Zone z) async {
    final app = AppScope.read(context);
    final repo = app.repo;
    final biz = app.business!.id;
    try {
      if (!z.packingConfirmed) {
        await repo.confirmPacking(biz, z.id, z.tasks.first.orderDate);
      }
      for (final t in z.tasks.where((t) => t.status == 'packed')) {
        await repo.advancePreparation(t.orderId, 'sorted');
      }
      for (final run in z.tasks.map((t) => t.runId).toSet()) {
        final inRun = z.tasks.where((t) => t.runId == run);
        if (inRun.every((t) => _r(t) >= 4)) continue;
        await repo.confirmSorting(
          biz,
          z.id,
          run,
          run == null ? inRun.first.orderDate : null,
        );
      }
      await _reload();
      if (mounted) setState(() => _showReady = true);
      return true;
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
      await _reload();
      return false;
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return CefSystemBars(
      background: Brightness.dark,
      browserChromeColor: const Color(0xFF0A2A8A),
      child: FutureBuilder<FulfilmentBoard>(
        future: _load,
        builder: (context, snap) {
          if (_board == null) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: snap.hasError
                  ? StateBlock.error('${snap.error}', onRetry: _reload)
                  : const StateBlock.loading(),
            );
          }
          final zone = _tab == _Tab.packing ? _packingZone : null;
          if (_showReady && zone != null && zone.ready) {
            return _ReadyScreen(
              zone: zone,
              onBack: () => setState(() {
                _showReady = false;
                _zoneKey = null;
                _tab = _Tab.zones;
              }),
            );
          }
          return Scaffold(
            backgroundColor: Colors.white,
            body: switch (_tab) {
              _Tab.preparation => _preparation(),
              _Tab.zones => _zonesScreen(),
              _Tab.packing => _packing(),
              _Tab.more => _more(),
            },
            bottomNavigationBar: _BottomNav(
              tab: _tab,
              onTap: (t) => setState(() {
                _tab = t;
                _zoneKey = null;
                _showReady = false;
              }),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------ 1 · Preparation

  Widget _preparation() {
    final text = Theme.of(context).textTheme;
    final open = _open;
    final totals = <String, int>{};
    for (final t in open) {
      for (final l in t.lines) {
        totals[l.name] = (totals[l.name] ?? 0) + l.qty;
      }
    }
    final items = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final images = _board?.itemImages ?? const {};
    return _Page(
      title: _board?.businessName ?? '',
      subtitle: DateFormat(
        'EEE, d MMM y',
        Localizations.localeOf(context).toString(),
      ).format(_day),
      trailing: const _Avatar(label: 'H'),
      onRefresh: _reload,
      children: [
        Text(L.hwPreparation, style: _h2(text)),
        const SizedBox(height: Gap.md),
        _Card(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: _Stat(value: '${open.length}', label: L.hwOrders),
              ),
              Container(width: 1, height: 56, color: _line),
              Expanded(
                child: _Stat(
                  value: '${open.fold(0, (s, t) => s + t.itemCount)}',
                  label: L.hwItems,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.xl),
        Text(L.hwRequiredItems, style: _h2(text)),
        const SizedBox(height: Gap.md),
        if (items.isEmpty)
          _Empty(L.hwNoWork)
        else
          _Card(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (final (i, e) in items.indexed)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: i == items.length - 1
                          ? null
                          : const Border(bottom: BorderSide(color: _line)),
                    ),
                    child: Row(
                      children: [
                        _ItemImage(url: images[e.key.toLowerCase()]),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            e.key,
                            style: text.titleMedium?.copyWith(
                              color: _ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${e.value}',
                              style: text.titleLarge?.copyWith(
                                color: _ink,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(L.hwItems, style: _sub(text)),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------- 2 · Zones

  Widget _zonesScreen() {
    final text = Theme.of(context).textTheme;
    final zones = _zones;
    return _Page(
      title: L.hwZones,
      subtitle: _board?.businessName ?? '',
      onBack: () => setState(() => _tab = _Tab.preparation),
      onRefresh: _reload,
      children: [
        if (zones.isEmpty) _Empty(L.hwNoWork),
        for (final z in zones)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _Card(
              onTap: () => _openZone(z),
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          z.name,
                          style: text.titleLarge?.copyWith(
                            color: _ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (z.pickupAt != null) ...[
                        const Icon(LucideIcons.clock, size: 16, color: _muted),
                        const SizedBox(width: 4),
                        Text(
                          _time(context, z.pickupAt!),
                          key: ValueKey('zone-pickup-${z.name}'),
                          style: text.labelLarge?.copyWith(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: Gap.sm),
                      ],
                      const Icon(LucideIcons.chevronRight, color: _muted),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${L.hwNOrders(z.orders)}     ${L.hwNItems(z.items)}',
                    style: _sub(text),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _zoneChip(z),
                      const Spacer(),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${z.packed}',
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' / ${z.orders} ${L.hwPacked}'),
                          ],
                        ),
                        style: text.bodyLarge?.copyWith(color: _muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: z.orders == 0 ? 0 : z.packed / z.orders,
                      minHeight: 7,
                      backgroundColor: _line,
                      color: CefColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _zoneChip(_Zone z) {
    if (z.ready) return _Chip(L.hwReadyStatus, bg: _greenTint, fg: _green);
    if (z.packed > 0) {
      return _Chip(
        L.hwPackingStatus,
        bg: CefColors.brandTint,
        fg: CefColors.brand,
      );
    }
    return _Chip(L.hwPending, bg: _cool, fg: _ink);
  }

  // ----------------------------------------------------- 3 · Packing

  Widget _packing() {
    final z = _packingZone;
    if (z == null) {
      return _Page(
        title: L.hwPacking,
        subtitle: '',
        onBack: () => setState(() => _tab = _Tab.zones),
        children: [_Empty(L.hwNoZoneToPack)],
      );
    }
    final complete = z.packed == z.orders;
    return _Page(
      title: L.hwPacking,
      subtitle: z.name,
      trailing: _CountPill('${z.packed} / ${z.orders}'),
      onBack: () => setState(() {
        _tab = _Tab.zones;
        _zoneKey = null;
      }),
      onRefresh: _reload,
      bottom: SlideToConfirm(
        key: const ValueKey('packing-slider'),
        label: L.hwSlideConfirmPickup,
        enabled: complete && !z.ready,
        onConfirm: () => _confirmZone(z),
      ),
      children: [
        for (final t in z.tasks)
          _OrderRow(
            task: t,
            done: _r(t) >= 2,
            busy: _busy.contains(t.orderId),
            chip: _r(t) >= 2
                ? _Chip(L.hwPackedStatus, bg: _greenTint, fg: _green)
                : _Chip(L.hwPending, bg: _amberTint, fg: _amberInk),
            onTap: _r(t) >= 2 ? null : () => _pack(t),
          ),
      ],
    );
  }

  // -------------------------------------------------------- More

  /// Opens a shared account screen (Profile, Security, Privacy, About)
  /// on top of the Helper workspace, never inside the Vendor shell.
  void _push(String title, Widget body) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: body,
      ),
    ),
  );

  Widget _more() {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final email = app.repo.currentUser?.email ?? '';
    final name = (app.repo.currentUser?.userMetadata?['full_name'] as String?)
        ?.trim();
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.sm, left: 4),
      child: Text(
        t.toUpperCase(),
        style: text.labelMedium?.copyWith(
          color: _muted,
          letterSpacing: .8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    Widget group(List<Widget> rows) => _Card(
      padding: EdgeInsets.zero,
      child: Column(children: rows),
    );
    Widget row(
      IconData icon,
      String title,
      VoidCallback onTap, {
      String? trailing,
      bool last = false,
    }) => CefListRow(
      title: title,
      icon: icon,
      trailing: trailing == null ? null : Text(trailing, style: _sub(text)),
      showDivider: !last,
      onTap: onTap,
    );
    return _Page(
      title: L.hwMore,
      subtitle: _board?.businessName ?? '',
      children: [
        _Card(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              _Avatar(
                label: (name?.isNotEmpty ?? false)
                    ? name!
                    : (email.isEmpty ? 'H' : email),
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (name?.isNotEmpty ?? false) ? name! : L.helperText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _sub(text),
                      ),
                    const SizedBox(height: 6),
                    _Chip(
                      '${L.helperText} · ${_board?.businessName ?? ''}',
                      bg: CefColors.brandTint,
                      fg: CefColors.brand,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        label(L.account),
        group([
          row(
            LucideIcons.user,
            L.profile,
            () => _push(
              L.profile,
              buildScreen(context, const VendorLocation(VRoute.editProfile)),
            ),
          ),
          row(
            LucideIcons.lock,
            L.hwPasswordSecurity,
            () => _push(
              L.security,
              buildScreen(context, const VendorLocation(VRoute.security)),
            ),
          ),
          row(
            LucideIcons.bell,
            L.notifications,
            () => _push(L.notifications, const _HelperNotifications()),
          ),
          row(
            LucideIcons.globe,
            L.language,
            () => showLanguageSheet(context),
            trailing: languageName(app.uiLocale),
            last: true,
          ),
        ]),
        label(L.support),
        group([
          row(
            LucideIcons.shieldCheck,
            L.privacy,
            () => _push(
              L.privacy,
              buildScreen(context, const VendorLocation(VRoute.privacyPolicy)),
            ),
          ),
          row(
            LucideIcons.info,
            L.aboutCefflo,
            () => _push(
              L.aboutCefflo,
              buildScreen(context, const VendorLocation(VRoute.about)),
            ),
            last: true,
          ),
        ]),
        const SizedBox(height: Gap.lg),
        group([
          CefListRow(
            title: L.signOut,
            leading: const IconTile(
              LucideIcons.logOut,
              color: Color(0xFFD73C2B),
            ),
            titleColor: const Color(0xFFD73C2B),
            showChevron: false,
            showDivider: false,
            onTap: () async {
              await app.repo.signOut();
              app.clearSession();
            },
          ),
        ]),
      ],
    );
  }
}

/// Helper notification preferences: only fulfilment signals (the Helper
/// workspace itself stays the source of truth; notifications are secondary).
class _HelperNotifications extends StatefulWidget {
  const _HelperNotifications();
  @override
  State<_HelperNotifications> createState() => _HelperNotificationsState();
}

class _HelperNotificationsState extends State<_HelperNotifications> {
  bool _work = true, _changes = true;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget tile(String title, String sub, bool v, ValueChanged<bool> on) =>
        SwitchListTile(
          value: v,
          onChanged: on,
          activeThumbColor: CefColors.brand,
          title: Text(title, style: text.titleMedium?.copyWith(fontSize: 16)),
          subtitle: Text(sub, style: _sub(text)),
        );
    return ListView(
      padding: const EdgeInsets.all(Gap.gutter),
      children: [
        _Card(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              tile(
                L.hwNotifNewWork,
                L.hwNotifNewWorkSub,
                _work,
                (v) => setState(() => _work = v),
              ),
              tile(
                L.hwNotifChanges,
                L.hwNotifChangesSub,
                _changes,
                (v) => setState(() => _changes = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        Text(L.notificationSettingsNotConnectedYet, style: _sub(text)),
      ],
    );
  }
}

// ============================================================ 5 · Ready

class _ReadyScreen extends StatelessWidget {
  const _ReadyScreen({required this.zone, required this.onBack});
  final _Zone zone;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // One card per pickup party (a Zone may span more than one Run).
    final parties = <String, FulfilmentTask>{};
    for (final t in zone.tasks) {
      parties.putIfAbsent(
        t.handoverRiderName ?? t.handoverProvider ?? '',
        () => t,
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: _Page(
        title: L.hwReadyForPickup,
        subtitle: '',
        onBack: onBack,
        children: [
          const SizedBox(height: Gap.lg),
          const Center(child: _SuccessMark()),
          const SizedBox(height: Gap.xl),
          Text(
            L.hwReadyForPickup,
            textAlign: TextAlign.center,
            style: text.headlineMedium?.copyWith(
              color: _ink,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: Gap.sm),
          Text(
            L.hwZoneReady,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: _muted, fontSize: 17),
          ),
          const SizedBox(height: Gap.xl),
          _Card(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                const Icon(LucideIcons.clock, color: CefColors.brand, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L.hwPickupTime, style: _sub(text)),
                      Text(
                        zone.pickupAt == null
                            ? '—'
                            : _time(context, zone.pickupAt!),
                        maxLines: 1,
                        softWrap: false,
                        style: text.titleLarge?.copyWith(
                          color: _ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 44, color: _line),
                Expanded(
                  flex: 2,
                  child: _Stat(value: '${zone.orders}', label: L.hwOrders),
                ),
                Container(width: 1, height: 44, color: _line),
                Expanded(
                  flex: 2,
                  child: _Stat(value: '${zone.items}', label: L.hwItems),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          for (final t in parties.values)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: _RiderCard(task: t),
            ),
        ],
      ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({required this.task});
  final FulfilmentTask task;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = task.handoverRiderName ?? task.handoverProvider;
    final type = task.riderVehicleType;
    return _Card(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.hwPickupRider,
            style: text.labelLarge?.copyWith(
              color: _muted,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (name == null)
            Text(L.hwRiderNotAssigned, style: text.titleMedium)
          else
            Row(
              children: [
                _Avatar(label: name, size: 80),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: text.headlineSmall?.copyWith(
                          color: _ink,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (task.handoverRiderName == null)
                        _Chip(L.hwExternalProvider, bg: _cool, fg: _ink)
                      else if (type != null)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: _cool,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                switch (type) {
                                  'car' => LucideIcons.car,
                                  'van' => LucideIcons.truck,
                                  _ => LucideIcons.motorbike,
                                },
                                size: 18,
                                color: _ink,
                              ),
                            ),
                            _Chip(
                              switch (type) {
                                'car' => L.hwCar,
                                'van' => L.hwVan,
                                _ => L.hwMotorcycle,
                              },
                              bg: _cool,
                              fg: _ink,
                            ),
                          ],
                        ),
                      if (task.handoverRiderName != null) ...[
                        const SizedBox(height: 10),
                        // Plate is required to identify the pickup vehicle;
                        // "—" when the Rider's plate is not recorded yet.
                        Text(
                          task.riderVehiclePlate ?? '—',
                          key: const ValueKey('rider-plate'),
                          style: text.titleLarge?.copyWith(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ================================================================ parts

TextStyle? _h2(TextTheme t) => t.titleLarge?.copyWith(
  color: _ink,
  fontSize: 20,
  fontWeight: FontWeight.w700,
);
TextStyle? _sub(TextTheme t) =>
    t.bodyMedium?.copyWith(color: _muted, fontSize: 14);

String _time(BuildContext context, DateTime at) =>
    DateFormat.jm(Localizations.localeOf(context).toString())
        .format(at.toLocal());

/// Blue header with centred title/subtitle, then the white working sheet.
class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
    this.trailing,
    this.bottom,
    this.onRefresh,
  });
  final String title, subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? trailing, bottom;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final list = ListView(
      // Each screen starts at the top (no scroll carried across screens).
      key: ValueKey('page-$title-$subtitle'),
      padding: EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.xl,
        Gap.gutter,
        bottom == null ? Gap.xl : 110,
      ),
      children: children,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _headerBlue),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 76,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 70),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: .92),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onBack != null)
                    Positioned(
                      left: 4,
                      child: IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        onPressed: onBack,
                        icon: const Icon(
                          LucideIcons.arrowLeft,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (trailing != null)
                    Positioned(right: Gap.gutter, child: trailing!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: ColoredBox(
                color: Colors.white,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: onRefresh == null
                          ? list
                          : RefreshIndicator(
                              onRefresh: onRefresh!,
                              child: list,
                            ),
                    ),
                    if (bottom != null)
                      Positioned(
                        left: Gap.gutter,
                        right: Gap.gutter,
                        bottom: 14,
                        child: bottom!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFEEF0F5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F0B1220),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: text.headlineMedium?.copyWith(
            color: _ink,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: _sub(text)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.bg, required this.fg});
  final String label;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: fg, fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );
}

class _CountPill extends StatelessWidget {
  const _CountPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: _ink, fontSize: 16, fontWeight: FontWeight.w800),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, this.size = 38});
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parts = label.trim().split(RegExp(r'\s+'));
    final initials = parts.length > 1
        ? '${parts.first.characters.first}${parts.last.characters.first}'
        : label.trim().characters.first;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: size > 50 ? CefColors.brandTint : Colors.white,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: CefColors.brand,
          fontWeight: FontWeight.w800,
          fontSize: size * .38,
        ),
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: CefColors.brandTint,
      alignment: Alignment.center,
      child: const Icon(LucideIcons.utensils, color: CefColors.brand),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 54,
        height: 54,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: _sub(Theme.of(context).textTheme),
    ),
  );
}

/// Order row on Packing / Sorting: tap the row to check the order.
class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.task,
    required this.done,
    required this.busy,
    required this.chip,
    this.onTap,
  });
  final FulfilmentTask task;
  final bool done, busy;
  final Widget chip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      key: ValueKey('order-${task.orderId}'),
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: busy
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? CefColors.brand : Colors.transparent,
                        border: done
                            ? null
                            : Border.all(
                                color: const Color(0xFF7C8495),
                                width: 2,
                              ),
                      ),
                      child: done
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.orderNumber,
                    style: text.titleMedium?.copyWith(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(L.hwNItem(task.itemCount), style: _sub(text)),
                  Text(
                    task.lines.map((l) => '${l.qty}× ${l.name}').join(', '),
                    style: _sub(text),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.sm),
            chip,
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronRight, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 160,
    height: 160,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFFEAF7EF),
    ),
    child: Container(
      width: 116,
      height: 116,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: _green),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 72),
    ),
  );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.tab, required this.onTap});
  final _Tab tab;
  final ValueChanged<_Tab> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_Tab.preparation, LucideIcons.utensils, L.hwPreparation),
      (_Tab.zones, LucideIcons.map, L.hwZones),
      (_Tab.packing, LucideIcons.package, L.hwPacking),
      (_Tab.more, LucideIcons.menu, L.hwMore),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final (t, icon, label) in items)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(t),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 24,
                          color: t == tab ? CefColors.brand : _muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: t == tab ? CefColors.brand : _muted,
                            fontWeight: t == tab
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Slide to Confirm Pickup". Always visible; grey and inert until the
/// group is complete (N / N), then a Cefflo-blue track with a yellow handle.
/// Completing N / N only ENABLES it -- the Helper must deliberately slide.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.enabled,
    required this.onConfirm,
  });
  final String label;
  final bool enabled;

  /// Returns whether the server confirmed; the handle springs back if not.
  final Future<bool> Function() onConfirm;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  static const _height = 66.0;
  double _dx = 0;
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled && !_working;
    return LayoutBuilder(
      builder: (context, box) {
        final max = box.maxWidth - _height;
        return Semantics(
          button: true,
          enabled: on,
          label: widget.label,
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              color: widget.enabled ? CefColors.brand : const Color(0xFFE4E8EF),
              borderRadius: BorderRadius.circular(_height),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(left: _height),
                    child: Center(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: widget.enabled
                                  ? Colors.white
                                  : const Color(0xFF9AA3B5),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _dx,
                  child: GestureDetector(
                    key: const ValueKey('slide-handle'),
                    onHorizontalDragUpdate: on
                        ? (d) => setState(
                            () => _dx = (_dx + d.delta.dx).clamp(0, max),
                          )
                        : null,
                    onHorizontalDragEnd: on
                        ? (_) async {
                            if (_dx < max * .85) {
                              setState(() => _dx = 0);
                              return;
                            }
                            setState(() {
                              _dx = max;
                              _working = true;
                            });
                            final ok = await widget.onConfirm();
                            if (mounted) {
                              setState(() {
                                _working = false;
                                if (!ok) _dx = 0;
                              });
                            }
                          }
                        : null,
                    child: Container(
                      width: _height,
                      height: _height,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.enabled
                            ? CefColors.ceffloMustard
                            : const Color(0xFFC9D0DB),
                      ),
                      child: _working
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _ink,
                              ),
                            )
                          : Icon(
                              LucideIcons.chevronRight,
                              size: 30,
                              color: widget.enabled ? _ink : Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
