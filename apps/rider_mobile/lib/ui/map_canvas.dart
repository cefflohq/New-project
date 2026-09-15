import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';

/// A painted stand-in for the live map surface D21.2 and D22 render.
///
/// The prototype deliberately does **not** ship a screenshot of a real map
/// provider or a fabricated satellite tile: it paints the same *shapes* the
/// reference shows — a light street grid, park and water blocks, a highway
/// ribbon and the blue route polyline — so the screen reads correctly while
/// staying honest that no map SDK is wired up in this pass.
class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    required this.route,
    this.markers = const [],
    this.showHeading = true,
    this.labels = const [],
  });

  /// Route polyline in unit space (0..1 of the canvas box).
  final List<Offset> route;

  /// Numbered stop pins, positioned in the same unit space.
  final List<MapMarker> markers;

  /// The driver's own heading puck, drawn at the first route point.
  final bool showHeading;

  /// Flat place labels ("Setapak", "Taman Setapak").
  final List<MapLabel> labels;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      Offset at(Offset unit) =>
          Offset(unit.dx * size.width, unit.dy * size.height);
      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MapPainter(route: route)),
          ),
          for (final label in labels)
            Positioned(
              left: at(label.position).dx,
              top: at(label.position).dy,
              child: Text(
                label.text,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: label.big ? 16 : 12,
                  fontWeight: label.big ? FontWeight.w700 : FontWeight.w600,
                  color: const Color(0xFF5A6373),
                ),
              ),
            ),
          if (showHeading && route.isNotEmpty)
            Positioned(
              left: at(route.first).dx - 17,
              top: at(route.first).dy - 17,
              child: const _HeadingPuck(),
            ),
          for (final marker in markers)
            Positioned(
              left: at(marker.position).dx - 15,
              top: at(marker.position).dy - (marker.pin ? 34 : 15),
              child: marker.pin
                  ? const _DestinationPin()
                  : _StopDot(index: marker.index),
            ),
        ],
      );
    },
  );
}

class MapMarker {
  const MapMarker({required this.position, this.index = 0, this.pin = false});

  /// Unit-space position (0..1) inside the map box.
  final Offset position;
  final int index;

  /// Draw the tall red destination pin (D22) instead of a numbered dot.
  final bool pin;
}

class MapLabel {
  const MapLabel(this.text, this.position, {this.big = false});
  final String text;
  final Offset position;
  final bool big;
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.route});

  final List<Offset> route;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEFEDE8),
    );

    // Parks and water — the green and blue blocks the reference shows.
    void block(Color color, double x, double y, double bw, double bh) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * w, y * h, bw * w, bh * h),
          const Radius.circular(6),
        ),
        Paint()..color = color,
      );
    }

    const park = Color(0xFFD9E7CE);
    const water = Color(0xFFBFDCEA);
    block(park, 0.02, 0.10, 0.16, 0.13);
    block(park, 0.72, 0.06, 0.24, 0.11);
    block(park, 0.58, 0.72, 0.18, 0.12);
    block(park, 0.05, 0.62, 0.10, 0.10);
    block(water, -0.04, 0.34, 0.16, 0.20);

    // Street grid.
    final minor = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var i = 1; i < 9; i++) {
      final y = h * i / 9;
      canvas.drawLine(Offset(0, y), Offset(w, y), minor);
    }
    for (var i = 1; i < 7; i++) {
      final x = w * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x, h), minor);
    }

    // A couple of heavier arterials.
    final major = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawLine(Offset(0, h * 0.44), Offset(w, h * 0.40), major);
    canvas.drawLine(Offset(w * 0.30, 0), Offset(w * 0.36, h), major);

    // The yellow highway ribbon in the top-left of D21.2.
    final highway = Paint()
      ..color = const Color(0xFFF6D98A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.20)
        ..quadraticBezierTo(w * 0.18, h * 0.30, w * 0.16, h * 0.62)
        ..lineTo(w * 0.12, h),
      highway,
    );

    // Route polyline — rounded, drawn with a soft outer casing so it reads
    // on top of the street grid exactly as the reference does.
    if (route.length > 1) {
      final path = Path()
        ..moveTo(route.first.dx * w, route.first.dy * h);
      for (final point in route.skip(1)) {
        path.lineTo(point.dx * w, point.dy * h);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x33104C9E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF1668E3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.route != route;
}

class _StopDot extends StatelessWidget {
  const _StopDot({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: CefColors.navy,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x33101C33), blurRadius: 6, offset: Offset(0, 2)),
      ],
    ),
    child: Text(
      '$index',
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30,
    height: 38,
    child: CustomPaint(painter: _PinPainter()),
  );
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const red = Color(0xFFE23B2E);
    final cx = size.width / 2;
    final r = size.width / 2;
    final path = Path()
      ..moveTo(cx, size.height)
      ..quadraticBezierTo(cx - r * 0.95, r * 1.35, cx - r * 0.72, r * 0.86)
      ..addOval(Rect.fromCircle(center: Offset(cx, r), radius: r))
      ..moveTo(cx, size.height)
      ..quadraticBezierTo(cx + r * 0.95, r * 1.35, cx + r * 0.72, r * 0.86)
      ..close();
    canvas.drawShadow(path, const Color(0xFF101C33), 3, false);
    canvas.drawPath(path, Paint()..color = red);
    canvas.drawCircle(
      Offset(cx, r),
      r * 0.36,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) => false;
}

class _HeadingPuck extends StatelessWidget {
  const _HeadingPuck();

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF1668E3),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [
        BoxShadow(color: Color(0x401668E3), blurRadius: 10, offset: Offset(0, 3)),
      ],
    ),
    child: Transform.rotate(
      angle: -math.pi / 4,
      child: const Icon(LucideIcons.navigation, size: 15, color: Colors.white),
    ),
  );
}

/// The circular floating map controls (sound, layers, locate) stacked down
/// the left edge in D21.2 and D22.
class MapControlButton extends StatelessWidget {
  const MapControlButton({super.key, required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 3,
    shadowColor: const Color(0x33101C33),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 21, color: CefColors.navy),
      ),
    ),
  );
}

/// The white "Re-center" pill in the bottom-right of the map.
class MapRecenterPill extends StatelessWidget {
  const MapRecenterPill({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(999),
    elevation: 3,
    shadowColor: const Color(0x33101C33),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.locateFixed, size: 17, color: Color(0xFF1668E3)),
            const SizedBox(width: 7),
            Text(
              'Re-center',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: context.c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
