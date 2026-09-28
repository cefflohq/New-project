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
  static const _stages = ['not_started', 'preparing', 'packed', 'ready'];
  static const _next = {
    'not_started': 'preparing',
    'preparing': 'packed',
    'packed': 'ready',
  };

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
    'ready' => L.stageReady,
    _ => L.toPrepare,
  };

  String _action(String stage) => switch (stage) {
    'preparing' => L.markPacked,
    'packed' => L.markReady,
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
          final rows = all.where((t) => t.status == _stage).toList();
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
                          '${_label(s)} (${all.where((t) => t.status == s).length})',
                      selected: _stage == s,
                      onTap: () => setState(() => _stage = s),
                    ),
                ],
              ),
              const SizedBox(height: Gap.md),
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
                          if (_next.containsKey(t.status))
                            CefButton(
                              _action(t.status),
                              compact: true,
                              busy: _busy.contains(t.orderId),
                              onTap: () => _advance(t),
                            )
                          else
                            Text(
                              t.handoverRiderName != null
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
