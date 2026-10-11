/// CEFFLO Page Loader — three bounce dots + a status label.
///
/// The Flutter twin of `shared/loader` (web). Same tokens, timing and
/// behaviour: shown only after 300ms, 200ms fade, slow label after 8s,
/// static under reduced motion. Global API: [showPageLoader] /
/// [hidePageLoader], hosted by [CefLoaderHost] in MaterialApp.builder.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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
                      child: _DelayedFade(
                        child: Semantics(
                          liveRegion: true,
                          label: label,
                          child: const ColoredBox(
                            color: Color(0x2E0A0E16),
                            child: Center(child: CefRingLoader()),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      );
}

// ---------------------------------------------------------------- ring loader
// The global page loader (2026-10-11, Founder): a blue ring spinning around
// the Cefflo vector mark on a dark glass tile, centred on screen. Web twin:
// shared/loader (`data-cf-loader="ring"`). The mark is drawn from the official
// vector paths (docs/cefflo/brand/assets/logo/cefflo-bimi.svg, background
// removed), so no image asset or SVG package is needed.

class _MarkPart {
  const _MarkPart(this.d, {this.color, this.gradient});
  final String d;
  final Color? color;
  final LinearGradient? gradient;
}

const _markParts = <_MarkPart>[
  _MarkPart(
      'M 751 222 C 742 223, 728 227, 721 231 C 714 234, 695 247, 630 291 C 604 308, 574 327, 563 334 C 552 341, 541 348, 538 349 C 536 351, 521 361, 505 371 C 489 381, 472 392, 466 396 C 460 400, 451 405, 446 409 C 404 436, 388 447, 380 456 C 366 470, 358 489, 358 505 C 358 512, 359 514, 372 522 C 382 529, 399 541, 423 557 C 470 590, 502 612, 503 612 C 503 612, 503 586, 504 556 C 504 525, 505 500, 505 501 C 505 501, 505 506, 505 513 C 505 520, 505 524, 506 524 C 506 523, 507 526, 507 531 C 509 549, 510 563, 511 565 C 512 566, 512 567, 512 568 C 512 568, 512 569, 512 570 C 512 570, 512 574, 512 579 C 512 588, 512 589, 515 587 C 517 586, 517 586, 514 590 C 513 592, 511 595, 510 596 C 508 599, 508 599, 510 597 C 516 588, 527 579, 545 568 C 767 436, 891 361, 902 353 C 923 339, 923 320, 902 304 C 900 303, 895 299, 889 294 C 879 287, 853 267, 824 245 C 798 226, 776 219, 751 222 M 498 645 C 495 647, 490 650, 488 652 C 485 653, 469 663, 452 674 C 423 692, 404 704, 395 710 C 393 711, 386 715, 380 719 C 354 735, 355 734, 356 748 C 357 758, 360 767, 365 778 C 373 793, 382 801, 410 820 C 421 827, 437 838, 446 844 C 455 851, 481 868, 504 884 C 556 918, 583 937, 610 956 C 638 976, 687 1010, 696 1015 C 718 1030, 744 1032, 767 1022 C 772 1020, 804 1000, 836 979 C 840 977, 854 968, 868 959 C 881 950, 894 942, 895 940 C 904 932, 904 918, 895 910 C 885 900, 812 853, 665 759 C 636 741, 604 720, 594 714 C 583 707, 568 697, 559 692 C 523 669, 517 664, 509 651 C 506 647, 504 644, 504 643 C 504 641, 503 642, 498 645',
      color: Color(0xFFfbfbfb)),
  _MarkPart(
      'M 730 227 C 728 228, 723 230, 721 231 C 714 234, 674 261, 673 263 C 673 264, 660 273, 645 282 C 601 311, 579 329, 558 352 C 536 377, 521 400, 511 426 C 507 435, 507 436, 508 442 C 508 446, 508 449, 508 449 C 508 450, 508 453, 507 456 C 507 459, 507 462, 506 463 C 505 466, 506 521, 507 530 C 507 534, 508 543, 509 550 C 510 557, 510 564, 511 565 C 512 566, 512 567, 512 568 C 512 568, 512 569, 512 570 C 512 570, 512 573, 512 576 L 512 582 518 582 C 521 582, 524 581, 526 580 C 528 578, 547 567, 654 504 C 703 474, 745 449, 747 448 C 749 447, 750 445, 750 445 C 750 444, 751 444, 751 444 C 754 444, 889 363, 902 353 C 923 339, 923 320, 902 304 C 900 303, 895 299, 889 294 C 879 287, 853 267, 824 245 C 816 239, 806 233, 801 230 L 792 226 764 225 C 739 225, 735 225, 730 227',
      gradient: LinearGradient(colors: [
        Color(0xFF74777e),
        Color(0xFF8e8f95),
        Color(0xFF9d9fa2),
        Color(0xFFbababc),
        Color(0xFFd1d1d3),
        Color(0xFFe6e5e6),
        Color(0xFFf2f2f2),
        Color(0xFFf9f9f9),
        Color(0xFFfbfbfb)
      ], stops: [
        0.0,
        0.119,
        0.186,
        0.322,
        0.458,
        0.593,
        0.729,
        0.864,
        1.0
      ])),
  _MarkPart(
      'M 505 662 C 505 665, 504 667, 501 667 L 499 667 499 728 C 500 786, 500 789, 502 798 C 512 844, 547 901, 585 935 C 588 938, 591 941, 592 942 C 592 943, 599 948, 607 954 L 621 964 741 964 L 860 964 876 953 C 885 948, 894 942, 895 940 C 904 932, 904 918, 895 910 C 885 900, 812 853, 665 759 C 636 741, 604 720, 594 714 C 583 707, 568 697, 559 692 C 535 677, 525 669, 519 665 C 515 660, 514 660, 510 660 C 506 660, 505 660, 505 662',
      gradient: LinearGradient(colors: [
        Color(0xFF84858d),
        Color(0xFFa3a4a8),
        Color(0xFFb9b9bc),
        Color(0xFFc8c8ca),
        Color(0xFFdfdedf),
        Color(0xFFececed),
        Color(0xFFf7f6f6),
        Color(0xFFfbfbfb),
        Color(0xFFfbfbfb)
      ], stops: [
        0.0,
        0.051,
        0.119,
        0.186,
        0.322,
        0.458,
        0.593,
        0.729,
        1.0
      ])),
  _MarkPart(
      'M 351 532 C 349 536, 349 536, 374 605 C 378 615, 381 625, 381 626 C 381 628, 378 636, 375 643 C 358 686, 348 711, 348 714 C 348 718, 351 720, 355 720 C 357 719, 388 700, 464 653 C 477 645, 488 639, 490 638 C 496 634, 499 628, 496 624 C 495 623, 492 621, 489 618 C 486 616, 479 612, 474 608 C 469 604, 456 595, 444 587 C 434 580, 419 569, 412 564 C 404 559, 394 552, 388 548 C 381 544, 373 538, 368 535 C 359 528, 354 527, 351 532',
      color: Color(0xFFfec803)),
];

// Mark bounds in SVG units (gradients run x 505 → 800).
const _markBox = Rect.fromLTWH(336, 207, 599, 837);

Path _parse(String d) {
  final p = Path();
  final tokens =
      RegExp(r'[MCL]|-?\d+(?:\.\d+)?').allMatches(d).map((m) => m[0]!).toList();
  var cmd = 'M';
  var i = 0;
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if (RegExp(r'^[MCL]$').hasMatch(tokens[i])) cmd = tokens[i++];
    switch (cmd) {
      case 'M':
        p.moveTo(n(), n());
        cmd = 'L';
      case 'L':
        p.lineTo(n(), n());
      case 'C':
        p.cubicTo(n(), n(), n(), n(), n(), n());
    }
  }
  return p..close();
}

final _markPaths = [for (final m in _markParts) _parse(m.d)];

class _MarkPainter extends CustomPainter {
  const _MarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final s =
        math.min(size.width / _markBox.width, size.height / _markBox.height);
    canvas
      ..translate((size.width - _markBox.width * s) / 2,
          (size.height - _markBox.height * s) / 2)
      ..scale(s)
      ..translate(-_markBox.left, -_markBox.top);
    for (var i = 0; i < _markParts.length; i++) {
      final m = _markParts[i];
      final paint = Paint()..isAntiAlias = true;
      if (m.gradient != null) {
        paint.shader =
            m.gradient!.createShader(const Rect.fromLTRB(505, 0, 800, 1));
      } else {
        paint.color = m.color!;
      }
      canvas.drawPath(_markPaths[i], paint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}

/// The Cefflo vector mark.
class CefMark extends StatelessWidget {
  const CefMark({super.key, this.height = 36});
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: height * _markBox.width / _markBox.height,
        height: height,
        child: const CustomPaint(painter: _MarkPainter()),
      );
}

/// Blue ring + Cefflo mark on a rounded dark glass tile.
class CefRingLoader extends StatefulWidget {
  const CefRingLoader({super.key});
  @override
  State<CefRingLoader> createState() => _CefRingLoaderState();
}

class _CefRingLoaderState extends State<CefRingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
    ..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _c.duration = Duration(milliseconds: still ? 2400 : 800);
    if (!_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xB8101218),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x1FFFFFFF)),
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _c,
                    child: const SizedBox(
                        width: 68,
                        height: 68,
                        child: CustomPaint(painter: _RingPainter())),
                  ),
                  const CefMark(height: 36),
                ],
              ),
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter();
  @override
  void paint(Canvas canvas, Size size) {
    const w = 4.0;
    final r = Rect.fromLTWH(w / 2, w / 2, size.width - w, size.height - w);
    canvas.drawArc(
        r,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = const Color(0x24FFFFFF));
    canvas.drawArc(
        r,
        -math.pi / 2,
        math.pi / 2 * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            colors: [CefLoaderTokens.blueEnd, CefLoaderTokens.blueStart],
            stops: [0, .5],
            transform: GradientRotation(-math.pi / 2),
          ).createShader(r));
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => false;
}

/// Shown after 300ms with a 200ms fade (no flash on quick work).
class _DelayedFade extends StatefulWidget {
  const _DelayedFade({required this.child});
  final Widget child;
  @override
  State<_DelayedFade> createState() => _DelayedFadeState();
}

class _DelayedFadeState extends State<_DelayedFade> {
  Timer? _t;
  bool _on = false;
  @override
  void initState() {
    super.initState();
    _t = Timer(CefLoaderTokens.delay, () => setState(() => _on = true));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _on ? 1 : 0,
        duration: CefLoaderTokens.fade,
        child: widget.child,
      );
}
