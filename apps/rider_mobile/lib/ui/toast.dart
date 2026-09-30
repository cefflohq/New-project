import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The one toast (Founder, 2026-09-30): fitted to its message, floating just
/// under the header at eye level, dark translucent glass with white text.
/// Shown for 3 seconds; a new toast replaces the current one. Never covers
/// the bottom navigation.
OverlayEntry? _current;

void showCefToast(
  BuildContext context,
  String message, {
  bool error = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _current?.remove();
  _current = null;
  late final OverlayEntry entry;
  void close() {
    if (identical(_current, entry)) {
      entry.remove();
      _current = null;
    }
  }

  entry = OverlayEntry(
    builder: (_) => _Toast(
      message: message,
      error: error,
      onTimeout: close,
      actionLabel: actionLabel,
      onAction: onAction == null
          ? null
          : () {
              onAction();
              close();
            },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.error,
    required this.onTimeout,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final bool error;
  final VoidCallback onTimeout;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_Toast> createState() => _ToastState();
}

/// The 3-second timer lives with the toast, so it ends with it.
class _ToastState extends State<_Toast> {
  late final Timer _timer = Timer(const Duration(seconds: 3), widget.onTimeout);

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Top bar height used across the apps; the toast sits just below it.
  static const _header = 56.0;

  @override
  Widget build(BuildContext context) {
    final message = widget.message, error = widget.error;
    final actionLabel = widget.actionLabel, onAction = widget.onAction;
    final top = MediaQuery.paddingOf(context).top + _header + 8;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: onAction == null,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, -8 * (1 - t)),
                child: child,
              ),
            ),
            child: Semantics(
              liveRegion: true,
              child: Material(
                type: MaterialType.transparency,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      color: Colors.black.withValues(alpha: .62),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            error
                                ? LucideIcons.circleAlert
                                : LucideIcons.circleCheck,
                            size: 18,
                            color: error
                                ? const Color(0xFFFF8A8A)
                                : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (actionLabel != null) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: onAction,
                              child: Text(
                                actionLabel,
                                style: const TextStyle(
                                  color: Color(0xFFFFC93C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
