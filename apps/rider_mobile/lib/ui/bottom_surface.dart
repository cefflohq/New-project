import 'package:flutter/widgets.dart';

import '../core/bottom_surface.dart';

/// Declares the colour at the bottom edge of the screen it wraps, so on web
/// the Android gesture / navigation area continues that surface instead of
/// showing a separate strip (see [syncBrowserBottomColor]). The newest
/// mounted screen decides; removing it hands the bottom back to the one
/// below. Layout and safe-area padding are untouched.
class CefBottomSurface extends StatefulWidget {
  const CefBottomSurface({super.key, required this.color, required this.child});

  /// Bottom stop of the brand gradient (splash / welcome backdrop).
  static const gradientBottom = Color(0xFF0592EB);

  final Color color;
  final Widget child;

  @override
  State<CefBottomSurface> createState() => _CefBottomSurfaceState();
}

class _CefBottomSurfaceState extends State<CefBottomSurface> {
  final Object _owner = Object();

  @override
  void initState() {
    super.initState();
    _set(_owner, widget.color);
  }

  @override
  void didUpdateWidget(CefBottomSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) _set(_owner, widget.color);
  }

  @override
  void dispose() {
    _stack.removeWhere((e) => identical(e.owner, _owner));
    if (_stack.isNotEmpty) syncBrowserBottomColor(_stack.last.color);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

final List<({Object owner, Color color})> _stack = [];

void _set(Object owner, Color color) {
  _stack.removeWhere((e) => identical(e.owner, owner));
  _stack.add((owner: owner, color: color));
  syncBrowserBottomColor(color);
}
