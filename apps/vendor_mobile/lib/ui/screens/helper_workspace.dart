import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/vendor_repository.dart';
import '../shell.dart';
import '../widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// D-74 Helper workspace: the whole Vendor app for a signed-in member whose
/// role is `helper`. Deliberately narrow — no Vendor navigation exists
/// here, and the server (my_fulfilment_tasks / advance_preparation) is the
/// authority on what a Helper can read or change.
///
/// Functional placeholder only: the Founder-approved Helper UI replaces the
/// presentation of this screen; its data contract stays as is.
class HelperWorkspaceScreen extends StatefulWidget {
  const HelperWorkspaceScreen({super.key});
  @override
  State<HelperWorkspaceScreen> createState() => _HelperWorkspaceScreenState();
}

class _HelperWorkspaceScreenState extends State<HelperWorkspaceScreen> {
  // D-74 Sorting: per-order checkpoints; Ready only via Confirm Sorting.
  static const _stages = [
    'not_started',
    'preparing',
    'packed',
    'sorted',
    'ready',
    'picked_up',
  ];
  static const _next = {
    'not_started': 'preparing',
    'preparing': 'packed',
    'packed': 'sorted',
  };
  static const _rank = {
    'not_started': 0,
    'preparing': 1,
    'packed': 2,
    'sorted': 3,
    'ready': 4,
  };

  String _stageOf(FulfilmentTask t) => t.pickedUp ? 'picked_up' : t.status;

  String _stage = 'not_started';
  Future<List<FulfilmentTask>>? _load;
  final _busy = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= _fetch();
  }

  Future<List<FulfilmentTask>> _fetch() {
    final app = AppScope.read(context);
    return app.repo.myFulfilmentTasks(app.business!.id);
  }

  Future<void> _reload() async {
    final next = _fetch();
    setState(() => _load = next);
    await next;
  }

  String _label(String stage) => switch (stage) {
    'preparing' => L.stagePreparing,
    'packed' => L.stagePacked,
    'sorted' => L.stageSorted,
    'ready' => L.stageReady,
    'picked_up' => L.stagePickedUp,
    _ => L.toPrepare,
  };

  String _action(String stage) => switch (stage) {
    'preparing' => L.markPacked,
    'packed' => L.markSorted,
    _ => L.startPreparing,
  };

  Future<void> _advance(FulfilmentTask t) async {
    setState(() => _busy.add(t.orderId));
    try {
      await AppScope.read(context).repo
          .advancePreparation(t.orderId, _next[t.status]!);
      await _reload();
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(t.orderId));
    }
  }

  /// Groups of still-open tasks (picked-up orders are not in any group).
  Map<String, List<FulfilmentTask>> _groups(
    List<FulfilmentTask> all,
    String Function(FulfilmentTask) key,
  ) {
    final out = <String, List<FulfilmentTask>>{};
    for (final t in all.where((t) => !t.pickedUp)) {
      out.putIfAbsent(key(t), () => []).add(t);
    }
    return out;
  }

  Future<void> _confirm(String key, Future<void> Function() call) async {
    setState(() => _busy.add(key));
    try {
      await call();
      await _reload();
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  List<Widget> _groupButtons(List<FulfilmentTask> all) {
    final repo = AppScope.read(context).repo;
    final biz = AppScope.read(context).business!.id;
    if (_stage == 'packed') {
      return [
        for (final e in _groups(
          all,
          (t) => 'pack|${t.zoneId}|${t.orderDate}',
        ).entries)
          if (e.value.any((t) => t.status == 'packed' && !t.packingConfirmed))
            _groupButton(
              e.key,
              L.confirmPackingGroup(
                e.value.first.zoneName ?? L.noZone,
                '${e.value.where((t) => (_rank[t.status] ?? 0) >= 2).length}',
                '${e.value.length}',
              ),
              e.value.every((t) => (_rank[t.status] ?? 0) >= 2),
              () => repo.confirmPacking(
                biz,
                e.value.first.zoneId,
                e.value.first.orderDate,
              ),
            ),
      ];
    }
    if (_stage == 'sorted') {
      return [
        for (final e in _groups(
          all,
          (t) =>
              'sort|${t.zoneId}|${t.runId}|${t.runId == null ? t.orderDate : ''}',
        ).entries)
          if (e.value.any((t) => t.status == 'sorted'))
            _groupButton(
              e.key,
              L.confirmSortingGroup(
                e.value.first.zoneName ?? L.noZone,
                '${e.value.where((t) => (_rank[t.status] ?? 0) >= 3).length}',
                '${e.value.length}',
              ),
              e.value.every((t) => (_rank[t.status] ?? 0) >= 3),
              () => repo.confirmSorting(
                biz,
                e.value.first.zoneId,
                e.value.first.runId,
                e.value.first.orderDate,
              ),
            ),
      ];
    }
    return const [];
  }

  Widget _groupButton(
    String key,
    String label,
    bool complete,
    Future<void> Function() call,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.sm),
    child: CefButton(
      label,
      busy: _busy.contains(key),
      onTap: complete ? () => _confirm(key, call) : null,
    ),
  );

  String _time(DateTime at) {
    final l = at.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.business?.name ?? L.helperWorkspaceTitle),
        actions: [
          IconButton(
            tooltip: L.signOut,
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              await app.repo.signOut();
              app.clearSession();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<FulfilmentTask>>(
        future: _load,
        builder: (context, snap) {
          if (snap.hasError) {
            return StateBlock.error('${snap.error}', onRetry: _reload);
          }
          if (!snap.hasData) return const StateBlock.loading();
          final all = snap.data!;
          final rows = all.where((t) => _stageOf(t) == _stage).toList();
          return PageBody(
            onRefresh: _reload,
            children: [
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final s in _stages)
                    CefChoiceChip(
                      label:
                          '${_label(s)} (${all.where((t) => _stageOf(t) == s).length})',
                      selected: _stage == s,
                      onTap: () => setState(() => _stage = s),
                    ),
                ],
              ),
              const SizedBox(height: Gap.md),
              ..._groupButtons(all),
              if (rows.isEmpty)
                StateBlock.empty(
                  all.isEmpty ? L.newTasksAppearHere : L.noTasksInStage,
                )
              else
                for (final t in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.sm),
                    child: CefCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            cefOrderRef(t.orderNumber, null, t.orderId),
                            style: text.titleMedium,
                          ),
                          Text(t.customerName, style: text.bodyMedium),
                          if (t.zoneName != null)
                            Text(t.zoneName!, style: text.labelLarge),
                          if (t.runName != null)
                            Text(
                              L.runStop(t.runName!, '${t.stopSequence ?? '–'}'),
                              style: text.bodySmall,
                            ),
                          const SizedBox(height: Gap.sm),
                          for (final item in t.items)
                            Text(item, style: text.bodyMedium),
                          if (t.notes != null) ...[
                            const SizedBox(height: Gap.xs),
                            Text(t.notes!, style: text.bodySmall),
                          ],
                          const SizedBox(height: Gap.sm),
                          if (t.pickedUp)
                            Text(
                              L.pickedUpBy(
                                t.handoverRiderName ?? t.handoverProvider ?? '',
                                _time(t.pickedUpAt!),
                              ),
                              style: text.labelLarge,
                            )
                          else if (t.status == 'packed' && !t.packingConfirmed)
                            Text(L.packingNotConfirmed, style: text.bodySmall)
                          else if (_next.containsKey(t.status))
                            CefButton(
                              _action(t.status),
                              compact: true,
                              busy: _busy.contains(t.orderId),
                              onTap: () => _advance(t),
                            )
                          else if (t.status == 'ready')
                            Text(
                              t.handoverProvider != null
                                  ? L.handoverToProvider(t.handoverProvider!)
                                  : t.handoverRiderName != null
                                  ? L.handoverTo(t.handoverRiderName!)
                                  : L.readyForHandover,
                              style: text.labelLarge,
                            ),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
