import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// The Cefflo map pin (Founder 2026-10-16): a glossy blue teardrop with a
/// round hole, tip on the point. Drawn, so it stays sharp at any size.
class CefPin extends StatelessWidget {
  const CefPin({super.key, this.size = 28, this.color = pinBlue, this.label});
  final double size;
  final Color color;

  /// Short text (a stop number) shown in the hole when the pin is big enough.
  final String? label;

  static const pinBlue = Color(0xFF1E88F5);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * .78,
    height: size,
    child: CustomPaint(
      painter: _PinPainter(color),
      child: label == null || size < 26
          ? null
          : Align(
              alignment: const Alignment(0, -.38),
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: size * .3,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
            ),
    ),
  );
}

class _PinPainter extends CustomPainter {
  _PinPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final r = w / 2;
    final c = Offset(r, r);
    // Teardrop: circle on top, tangents meeting at the bottom tip.
    final tip = Offset(r, h);
    final d = h - r;
    final a = math.asin(r / d);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(c.dx - r * math.cos(a), c.dy + r * math.sin(a))
      ..arcTo(
        Rect.fromCircle(center: c, radius: r),
        math.pi - a,
        math.pi + 2 * a,
        false,
      )
      ..close();
    canvas.drawShadow(path, Colors.black54, 2, false);
    final hsl = HSLColor.fromColor(color);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hsl.withLightness((hsl.lightness + .15).clamp(0, 1)).toColor(),
            color,
            hsl.withLightness((hsl.lightness - .15).clamp(0, 1)).toColor(),
          ],
        ).createShader(Offset.zero & s),
    );
    // The hole.
    canvas.drawCircle(c, r * .46, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

/// Pin size for the map's zoom: small when zoomed out so a wide map stays
/// calm, larger close up.
double pinSizeForZoom(double zoom) => (zoom * 2.6 - 10).clamp(16, 34);

/// A [CefPin] that resizes with the map's zoom. Use inside a marker whose
/// box is [pinBox] and alignment is [Alignment.topCenter].
class ZoomPin extends StatelessWidget {
  const ZoomPin({super.key, this.color = CefPin.pinBlue, this.label});
  final Color color;
  final String? label;

  static const pinBox = 34.0;

  @override
  Widget build(BuildContext context) {
    final size = pinSizeForZoom(MapCamera.of(context).zoom);
    return Align(
      alignment: Alignment.bottomCenter,
      child: CefPin(size: size, color: color, label: label),
    );
  }
}
