import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/notification_alerts.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/driver_models.dart';
import '../widgets.dart';
import 'operations.dart' show KeyValueRow;

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// D31 — Delivery History
// ---------------------------------------------------------------------------

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final all = app.history;
    final pending = all.where((r) => r.state != RunState.completed).toList();
    final delivered = all.where((r) => r.state == RunState.completed).toList();
    final shown = switch (_tab) {
      1 => pending,
      2 => delivered,
      _ => all,
    };
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.deliveryHistory,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CeffloSegmentedTabs(
            labels: [
              L.all(all.length),
              L.pending(pending.length),
              L.delivered2(delivered.length),
            ],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: Gap.sm),
          if (shown.isEmpty)
            StateBlock.empty(L.noRunsViewYet)
          else
            for (final run in shown) ...[
              _HistoryRow(
                run: run,
                onTap: () => app.go(DRoute.historyDetail, entityId: run.id),
              ),
              if (run != shown.last)
                Divider(height: 1, color: context.c.border),
            ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.run, required this.onTap});
  final DriverRun run;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CefColors.tintNeutral,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(LucideIcons.package, size: 21, color: c.textLabel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            run.reference,
                            style: context.t.titleSmall?.copyWith(
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        Text(run.dateLabel, style: context.t.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      L.stops(
                        run.orderCount,
                        run.distanceText,
                        run.durationLabel ?? '—',
                      ),
                      style: context.t.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(LucideIcons.chevronRight, size: 20, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D32 — History Detail
// ---------------------------------------------------------------------------

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.runId});
  final String runId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final run = app.history.firstWhere(
      (r) => r.id == runId,
      orElse: () => app.history.first,
    );
    final c = context.c;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.historyDetail,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CefColors.tintNeutral,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(LucideIcons.package, size: 22, color: c.textLabel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      run.reference,
                      style: context.t.displaySmall?.copyWith(fontSize: 19),
                    ),
                    Text(run.dateLabel, style: context.t.bodySmall),
                  ],
                ),
              ),
              CeffloStatusChip(run.statusLabel, tone: ChipTone.success),
            ],
          ),
          const SizedBox(height: Gap.lg),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: CefColors.tintNeutral,
              borderRadius: BorderRadius.circular(Sizes.cardRadius),
            ),
            child: Row(
              children: [
                _Stat(
                  icon: LucideIcons.mapPin,
                  label: L.stops2(run.orderCount),
                ),
                _divider(c),
                _Stat(icon: LucideIcons.route, label: run.distanceText),
                _divider(c),
                _Stat(icon: LucideIcons.clock, label: run.durationLabel ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
          KeyValueRow(label: L.zone, value: run.zone),
          KeyValueRow(label: L.vehicle, value: run.vehicleLabel ?? '—'),
          KeyValueRow(label: L.started, value: run.startedAtLabel ?? '—'),
          KeyValueRow(label: L.completed, value: run.completedAtLabel ?? '—'),
          const SizedBox(height: Gap.md),
          Text(L.deliveryStops(run.orderCount), style: context.t.titleMedium),
          const SizedBox(height: Gap.sm),
          for (var i = 0; i < run.stops.length; i++) ...[
            _DeliveredStopRow(index: i + 1, stop: run.stops[i]),
            const SizedBox(height: Gap.sm),
          ],
        ],
      ),
    );
  }

  Widget _divider(CefColors c) =>
      Container(width: 1, height: 34, color: c.border);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 19, color: context.c.textLabel),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: context.c.textPrimary,
          ),
        ),
      ],
    ),
  );
}

class _DeliveredStopRow extends StatelessWidget {
  const _DeliveredStopRow({required this.index, required this.stop});
  final int index;
  final DriverStop stop;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CefColors.tintNeutral,
        borderRadius: BorderRadius.circular(Sizes.innerRadius),
      ),
      child: Row(
        children: [
          CeffloIndexBadge(index, tone: ChipTone.info, size: 28),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.reference,
                  style: context.t.titleSmall?.copyWith(fontSize: 14.5),
                ),
                const SizedBox(height: 1),
                Text(stop.addressLine1, style: context.t.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(stop.deliveredAt ?? '', style: context.t.bodySmall),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(LucideIcons.circleCheck, size: 15, color: c.success),
                  const SizedBox(width: 4),
                  Text(
                    L.delivered,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: c.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D33 — Notifications
// ---------------------------------------------------------------------------

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _tab = 0;

  static final _compact = TextButton.styleFrom(
    minimumSize: const Size(0, Sizes.tapTarget),
    padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
  );

  void _guard(Future<void> action) {
    action.catchError((Object _) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L.ntCouldNotUpdate),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _rowOptions(DriverNotification n) {
    final app = AppScope.read(context);
    showCeffloSheet<void>(
      context,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetGrabber(),
            ListTile(
              leading: Icon(n.unread ? LucideIcons.mailOpen : LucideIcons.mail),
              title: Text(n.unread ? L.ntMarkRead : L.ntMarkUnread),
              onTap: () {
                Navigator.of(context).pop();
                _guard(
                  n.unread
                      ? app.markNotificationRead(n)
                      : app.markNotificationUnread(n),
                );
              },
            ),
            const SizedBox(height: Gap.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final all = app.notifications.where((n) => !n.archived).toList();
    final unread = all.where((n) => n.unread).toList();
    final archived = app.notifications.where((n) => n.archived).toList();
    final shown = switch (_tab) {
      1 => unread,
      2 => archived,
      _ => all,
    };
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.notifications,
        onBack: app.back,
        // D33's reference carries the same bell as every other inner header;
        // it is inert here because this *is* the notifications screen.
        onBell: () {},
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CeffloSegmentedTabs(
            labels: [
              L.all(all.length),
              L.unread(unread.length),
              L.archive(archived.length),
            ],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Gap.sm,
            children: [
              TextButton.icon(
                key: const ValueKey('notif-settings'),
                style: _compact,
                onPressed: () => showNotificationPrefsSheet(context),
                icon: const Icon(LucideIcons.settings, size: 18),
                label: Text(L.ntSettings),
              ),
              if (unread.isNotEmpty)
                TextButton(
                  style: _compact,
                  onPressed: () => _guard(app.markAllNotificationsRead()),
                  child: Text(L.ntMarkAllRead),
                ),
            ],
          ),
          if (shown.isEmpty && app.notificationsError != null)
            StateBlock.error(
              app.notificationsError!,
              onRetry: app.refreshNotifications,
            )
          else if (shown.isEmpty)
            StateBlock.empty(L.nothingHereRightNow)
          else
            for (final n in shown) ...[
              _NotificationRow(
                notification: n,
                onTap: () => app.openNotification(n),
                onLongPress: () => _rowOptions(n),
              ),
              if (n != shown.last) Divider(height: 1, color: context.c.border),
            ],
        ],
      ),
    );
  }
}

/// Notifications + Sound, stored in public.notification_preferences (the
/// same row every Cefflo app of this account reads).
Future<void> showNotificationPrefsSheet(BuildContext context) {
  final app = AppScope.read(context);
  // The sheet is a new route; carry the app state into it explicitly.
  return showCeffloSheet<void>(
    context,
    child: Material(
      type: MaterialType.transparency,
      child: AppScope(state: app, child: const _NotificationPrefsSheet()),
    ),
  );
}

class _NotificationPrefsSheet extends StatefulWidget {
  const _NotificationPrefsSheet();

  @override
  State<_NotificationPrefsSheet> createState() =>
      _NotificationPrefsSheetState();
}

class _NotificationPrefsSheetState extends State<_NotificationPrefsSheet> {
  bool _saving = false;
  String? _error;

  Future<void> _save(NotificationPrefs next) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppScope.read(context).setNotificationPrefs(next);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.notificationPrefs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.gutter, 0, Gap.gutter, Gap.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetGrabber(),
          const SizedBox(height: Gap.sm),
          Text(L.ntSettings, style: context.t.titleMedium),
          const SizedBox(height: 4),
          Text(L.ntPrefLead, style: context.t.bodySmall),
          SwitchListTile(
            key: const ValueKey('pref-enabled'),
            contentPadding: EdgeInsets.zero,
            title: Text(L.ntPrefEnabled),
            subtitle: Text(L.ntPrefEnabledSub),
            value: p.enabled,
            onChanged: _saving
                ? null
                : (v) => _save(NotificationPrefs(enabled: v, sound: p.sound)),
          ),
          SwitchListTile(
            key: const ValueKey('pref-sound'),
            contentPadding: EdgeInsets.zero,
            title: Text(L.ntPrefSound),
            subtitle: Text(L.ntPrefSoundSub),
            value: p.sound,
            onChanged: _saving || !p.enabled
                ? null
                : (v) => _save(NotificationPrefs(enabled: p.enabled, sound: v)),
          ),
          if (_error != null)
            Text(
              _error!,
              style: context.t.bodySmall?.copyWith(color: context.c.attention),
            ),
          const SizedBox(height: Gap.sm),
          Text(L.ntPushDeferred, style: context.t.bodySmall),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.onTap,
    this.onLongPress,
  });
  final DriverNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  static (IconData, Color, Color) _style(NotificationKind kind) =>
      switch (kind) {
        NotificationKind.runAssigned => (
          LucideIcons.package,
          CefColors.tintNeutral,
          CefColors.navy,
        ),
        NotificationKind.deliveryIssue => (
          LucideIcons.triangleAlert,
          Color(0xFFFCE9E7),
          Color(0xFFD73C2B),
        ),
        NotificationKind.customerUpdate => (
          LucideIcons.messageSquare,
          CefColors.tintNeutral,
          CefColors.navy,
        ),
        NotificationKind.runCompleted => (
          LucideIcons.circleCheck,
          CefColors.tintSuccess,
          Color(0xFF17A34A),
        ),
        NotificationKind.documentApproved => (
          LucideIcons.fileText,
          CefColors.tintNeutral,
          CefColors.navy,
        ),
        NotificationKind.appUpdate => (
          LucideIcons.info,
          CefColors.tintInfo,
          Color(0xFF2A6EEC),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = notification.urgent
        ? (
            LucideIcons.triangleAlert,
            const Color(0xFFFCE9E7),
            const Color(0xFFD73C2B),
          )
        : _style(notification.kind);
    final copy = notificationCopy(notification);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            copy.title,
                            style: context.t.titleSmall?.copyWith(fontSize: 15),
                          ),
                        ),
                        Text(
                          notificationWhen(notification),
                          style: context.t.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(copy.body, style: context.t.bodySmall),
                    if (notification.urgent) ...[
                      const SizedBox(height: 4),
                      Text(
                        L.ntUrgent,
                        style: context.t.labelSmall?.copyWith(
                          color: const Color(0xFFD73C2B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: notification.unread
                        ? const Color(0xFF1668E3)
                        : Colors.transparent,
                    shape: BoxShape.circle,
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
