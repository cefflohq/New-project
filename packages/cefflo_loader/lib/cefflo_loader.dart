/// CEFFLO Page Loader — three bounce dots + a status label.
///
/// The Flutter twin of `shared/loader` (web). Same tokens, timing and
/// behaviour: shown only after 300ms, 200ms fade, slow label after 8s,
/// static under reduced motion. Global API: [showPageLoader] /
/// [hidePageLoader], hosted by [CefLoaderHost] in MaterialApp.builder.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Brand tokens (mirror `--cf-*` in shared/loader/loader.css).
abstract final class CefLoaderTokens {
  static const blueStart = Color(0xFF0060FE);
  static const blueEnd = Color(0xFF0592EB);
  static const blueStartBright = Color(0xFF4D8DFF);
  static const blueEndBright = Color(0xFF48B6F5);
  static const mustard = Color(0xFFFFC93C);
  static const white = Color(0xFFFFFFFF);
  static const dot = 8.0;
  static const gap = 6.0;
  static const outline = 1.5;
  static const labelGap = 12.0;
  static const delay = Duration(milliseconds: 300);
  static const fade = Duration(milliseconds: 200);
  static const slowAfter = Duration(seconds: 8);
  static const period = Duration(milliseconds: 900);
  static String defaultLabel = 'Memuatkan…';
  static String slowLabel = 'Masih memuatkan, sila tunggu sebentar';
}

/// The three dots. [onBlue]: dark mode / blue background variant.
class CefDots extends StatefulWidget {
  const CefDots({super.key, this.onBlue, this.size = CefLoaderTokens.dot});
  final bool? onBlue;
  final double size;
  @override
  State<CefDots> createState() => _CefDotsState();
}

class _CefDotsState extends State<CefDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: CefLoaderTokens.period,
  );
  static const _curve = Cubic(.45, 0, .55, 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // 0/60/100%: rest · 30%: up 1.1× dot, scale 1.1, opacity 1.
  (double, double, double) _frame(double t) {
    double k;
    if (t < .3) {
      k = _curve.transform(t / .3);
    } else if (t < .6) {
      k = 1 - _curve.transform((t - .3) / .3);
    } else {
      k = 0;
    }
    return (-1.1 * widget.size * k, 1 + .1 * k, .6 + .4 * k);
  }

  @override
  Widget build(BuildContext context) {
    final onBlue =
        widget.onBlue ?? Theme.of(context).brightness == Brightness.dark;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final s = widget.size;
    final blue = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: onBlue
          ? const [
              CefLoaderTokens.blueStartBright,
              CefLoaderTokens.blueEndBright,
            ]
          : const [CefLoaderTokens.blueStart, CefLoaderTokens.blueEnd],
    );
    final decorations = [
      BoxDecoration(shape: BoxShape.circle, gradient: blue),
      BoxDecoration(
        shape: BoxShape.circle,
        color: CefLoaderTokens.white,
        border: onBlue
            ? null
            : Border.all(
                color: CefLoaderTokens.blueStart,
                width: CefLoaderTokens.outline,
              ),
      ),
      const BoxDecoration(
        shape: BoxShape.circle,
        color: CefLoaderTokens.mustard,
      ),
    ];
    return ExcludeSemantics(
      child: SizedBox(
        height: s * 2.2,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: CefLoaderTokens.gap),
                Builder(
                  builder: (context) {
                    final period = CefLoaderTokens.period.inMilliseconds;
                    final t = still
                        ? 0.0
                        : ((_c.value * period - i * 120) % period) / period;
                    final (dy, scale, op) = still ? (0.0, 1.0, 1.0) : _frame(t);
                    return Opacity(
                      opacity: op,
                      child: Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: s,
                            height: s,
                            decoration: decorations[i],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dots + label, centred. Appears only after 300ms (no flash), fades in
/// 200ms, and switches to the slow label after 8s.
class CefPageLoader extends StatefulWidget {
  const CefPageLoader({
    super.key,
    this.label,
    this.onBlue,
    this.delay = true,
    this.backdrop,
  });
  final String? label;

  /// Painted behind the loader, inside the same delayed fade.
  final Color? backdrop;
  final bool? onBlue;

  /// false: visible at once (inside buttons / already-delayed overlays).
  final bool delay;
  @override
  State<CefPageLoader> createState() => _CefPageLoaderState();
}

class _CefPageLoaderState extends State<CefPageLoader> {
  Timer? _show, _slow;
  bool _visible = false, _isSlow = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay) {
      _show = Timer(
        CefLoaderTokens.delay,
        () => setState(() => _visible = true),
      );
    } else {
      _visible = true;
    }
    _slow = Timer(
      CefLoaderTokens.slowAfter,
      () => setState(() => _isSlow = true),
    );
  }

  @override
  void dispose() {
    _show?.cancel();
    _slow?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBlue = widget.onBlue ?? theme.brightness == Brightness.dark;
    final label = _isSlow
        ? CefLoaderTokens.slowLabel
        : (widget.label ?? CefLoaderTokens.defaultLabel);
    final color = onBlue
        ? Colors.white.withValues(alpha: .78)
        : theme.colorScheme.onSurfaceVariant;
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: CefLoaderTokens.fade,
      child: Container(
        color: widget.backdrop,
        child: Semantics(
          liveRegion: true,
          label: label,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CefDots(onBlue: onBlue),
                const SizedBox(height: CefLoaderTokens.labelGap),
                ExcludeSemantics(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: 12.5,
                      height: 1.4,
                      color: color,
                    ),
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

final ValueNotifier<String?> _overlayLabel = ValueNotifier<String?>(null);
int _depth = 0;

/// Shows the global page loader (after 300ms). Calls nest; each needs a
/// matching [hidePageLoader].
void showPageLoader([String? label]) {
  _depth++;
  _overlayLabel.value = label ?? CefLoaderTokens.defaultLabel;
  if (_depth == 1) {
    SemanticsService.sendAnnouncement(
      WidgetsBinding.instance.platformDispatcher.views.first,
      _overlayLabel.value!,
      TextDirection.ltr,
    );
  }
}

/// Hides the global page loader. [force] clears every pending call.
void hidePageLoader({bool force = false}) {
  _depth = force ? 0 : (_depth - 1).clamp(0, 1 << 30);
  if (_depth == 0) _overlayLabel.value = null;
}

/// Runs [work] with the global loader; always hidden afterwards.
Future<T> withPageLoader<T>(String? label, Future<T> Function() work) async {
  showPageLoader(label);
  try {
    return await work();
  } finally {
    hidePageLoader();
  }
}

/// Put in MaterialApp.builder: paints the global loader over every route.
class CefLoaderHost extends StatelessWidget {
  const CefLoaderHost({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      ValueListenableBuilder<String?>(
        valueListenable: _overlayLabel,
        builder: (context, label, _) => label == null
            ? const SizedBox.shrink()
            : Positioned.fill(
                child: AbsorbPointer(
                  child: CefPageLoader(
                    label: label,
                    backdrop: Theme.of(context).colorScheme.surface
                        .withValues(alpha: .72),
                  ),
                ),
              ),
      ),
    ],
  );
}
