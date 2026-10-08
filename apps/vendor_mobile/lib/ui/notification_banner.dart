import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/notification_alerts.dart';
import '../core/theme.dart';
import '../data/models.dart';

/// Foreground alert banner (NOTIFICATION_EVENT_MATRIX §5,
/// CEFFLO_NOTIFICATION_SYSTEM_MASTER_SPEC): shown once per notification
/// while the app is open. A compact grey glass card from Cefflo — the
/// official mark on its brand-blue tile, sender, relative time, title and
/// body. Slides down, stays ~3 s (5 s for server-urgent rows), then slides
/// up. Tap opens the deep-link; swipe up dismisses. The notification itself
/// stays in the centre either way.
class NotificationBanner extends StatefulWidget {
  const NotificationBanner({super.key});

  static const visible = Duration(seconds: 3);
  static const visibleUrgent = Duration(seconds: 5);

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  AppState? _app;
  AppNotification? _shown;
  Timer? _timer;
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 250),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _motion,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

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
    _motion.dispose();
    _app?.foregroundAlert.removeListener(_onAlert);
    super.dispose();
  }

  void _onAlert() {
    final n = _app?.foregroundAlert.value;
    _timer?.cancel();
    if (!mounted) return;
    if (n == null) {
      // Exit: slide up + fade, then drop the card.
      _motion.reverse().whenComplete(() {
        if (mounted && _app?.foregroundAlert.value == null) {
          setState(() => _shown = null);
        }
      });
      return;
    }
    _timer = Timer(
      n.urgent ? NotificationBanner.visibleUrgent : NotificationBanner.visible,
      () {
        if (_app?.foregroundAlert.value?.id == n.id) {
          _app?.dismissForegroundAlert();
        }
      },
    );
    setState(() => _shown = n);
    _motion.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final n = _shown;
    if (n == null) return const SizedBox.shrink();
    final top = MediaQuery.paddingOf(context).top + Gap.sm;
    return Positioned(
      top: top,
      left: Gap.md,
      right: Gap.md,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.6),
            end: Offset.zero,
          ).animate(_curve),
          child: Semantics(
            key: ValueKey(n.id),
            liveRegion: true,
            container: true,
            button: true,
            child: GestureDetector(
              key: const ValueKey('notification-banner'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final app = AppScope.read(context);
                app.dismissForegroundAlert();
                app.openNotification(n);
              },
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < -150) {
                  AppScope.read(context).dismissForegroundAlert();
                }
              },
              child: _GlassCard(n: n),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.n});
  final AppNotification n;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final copy = notificationCopy(n);
    final primary = dark ? Colors.white : const Color(0xFF111418);
    final secondary = dark ? const Color(0xFFC4C8CF) : const Color(0xFF3F454D);
    const radius = BorderRadius.all(Radius.circular(22));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: dark
                  ? const Color(0xFF2A2D32).withValues(alpha: 0.78)
                  : const Color(0xFFF1F2F4).withValues(alpha: 0.80),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.70),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _CeffloTile(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Cefflo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: secondary,
                              ),
                            ),
                          ),
                          Text(
                            notificationWhen(n),
                            style: TextStyle(fontSize: 12, color: secondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        copy.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        copy.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          color: secondary,
                        ),
                      ),
                    ],
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

/// The official Cefflo mark (canonical asset, D-35) on the brand gradient.
class _CeffloTile extends StatelessWidget {
  const _CeffloTile();

  @override
  Widget build(BuildContext context) {
    // The canonical mark is ~56% of its canvas tall; scale it so
    // the mark fills the tile with even, padding (~65% of the tile, as the app icon).
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(gradient: CefGradients.brand),
        child: Transform.scale(
          scale: 1.15,
          child: Image.asset(
            'assets/brand/cefflo-logo-mark.png',
            fit: BoxFit.cover,
            cacheWidth: 256,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
