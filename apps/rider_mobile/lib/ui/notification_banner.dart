import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_state.dart';
import '../core/notification_alerts.dart';
import '../core/theme.dart';
import '../data/driver_models.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// Foreground alert banner (NOTIFICATION_EVENT_MATRIX §5): shown once per
/// notification while the app is open. Normal alerts leave after ~6 s;
/// urgent ones (server priority: run assigned / removed) stay until
/// dismissed or opened, with a red edge and alert icon. Tapping opens the
/// deep-link.
/// The notification itself stays in the centre either way.
class NotificationBanner extends StatefulWidget {
  const NotificationBanner({super.key});

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with WidgetsBindingObserver {
  AppState? _app;
  DriverNotification? _shown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _app?.onAppResumed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.read(context);
    if (!identical(app, _app)) {
      _app?.foregroundAlert.removeListener(_onAlert);
      _app = app..foregroundAlert.addListener(_onAlert);
      _onAlert();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _app?.foregroundAlert.removeListener(_onAlert);
    super.dispose();
  }

  void _onAlert() {
    final n = _app?.foregroundAlert.value;
    _timer?.cancel();
    if (n != null && !n.urgent) {
      _timer = Timer(const Duration(seconds: 6), () {
        if (_app?.foregroundAlert.value?.id == n.id) {
          _app?.dismissForegroundAlert();
        }
      });
    }
    if (mounted) setState(() => _shown = n);
  }

  @override
  Widget build(BuildContext context) {
    final n = _shown;
    final c = context.c;
    final top = MediaQuery.paddingOf(context).top + Gap.sm;
    return Positioned(
      top: top,
      left: Gap.lg,
      right: Gap.lg,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: n == null
            ? const SizedBox.shrink()
            : Semantics(
                key: ValueKey(n.id),
                liveRegion: true,
                container: true,
                child: Material(
                  key: const ValueKey('notification-banner'),
                  color: c.card,
                  elevation: 6,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: n.urgent ? c.attention : c.border,
                        width: n.urgent ? 1.5 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        final app = AppScope.read(context);
                        app.dismissForegroundAlert();
                        app.openNotification(n);
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.md,
                          Gap.md,
                          Gap.xs,
                          Gap.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              n.urgent
                                  ? LucideIcons.triangleAlert
                                  : LucideIcons.bell,
                              color: n.urgent ? c.attention : CefColors.navy,
                              size: Sizes.icon,
                            ),
                            const SizedBox(width: Gap.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notificationCopy(n).title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    notificationCopy(n).body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: L.ntDismiss,
                              icon: Icon(
                                LucideIcons.x,
                                size: 20,
                                color: c.textSecondary,
                              ),
                              onPressed: () =>
                                  AppScope.read(context)
                                      .dismissForegroundAlert(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
