/// Neutral product illustrations for storefront imagery.
///
/// The catalogue has no product photos yet (`Product` carries no image), so
/// every template draws products with these brand-free vector drawings
/// instead of generic icons. Each family is painted in a unit box with soft
/// shading and a ground shadow so a template reads as a real, product-led
/// storefront. Garments take the storefront accent colour; everything else
/// keeps its own natural palette.
library;

import 'package:flutter/material.dart';

import '../../../../data/storefront_catalog.dart';

class ProductArtView extends StatelessWidget {
  const ProductArtView(this.art, {super.key, this.accent});

  final ProductArt art;

  /// Garment colour (tee / sneaker / bag). Defaults to a neutral navy.
  final Color? accent;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ProductArtPainter(art, accent ?? const Color(0xFF26324A)),
    child: const SizedBox.expand(),
  );
}

class _ProductArtPainter extends CustomPainter {
  _ProductArtPainter(this.art, this.accent);
  final ProductArt art;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / 100);
    _shadow(canvas);
    switch (art) {
      case ProductArt.tee:
        _tee(canvas);
      case ProductArt.sneaker:
        _sneaker(canvas);
      case ProductArt.jar:
        _jar(canvas);
      case ProductArt.bottle:
        _bottle(canvas);
      case ProductArt.cup:
        _cup(canvas);
      case ProductArt.bowl:
        _bowl(canvas);
      case ProductArt.cake:
        _cake(canvas);
      case ProductArt.pastry:
        _pastry(canvas);
      case ProductArt.bag:
        _bag(canvas);
      case ProductArt.gift:
        _gift(canvas);
      case ProductArt.parcel:
        _parcel(canvas);
    }
    canvas.restore();
  }

  // ---- helpers -------------------------------------------------------

  static Paint _fill(Color c) => Paint()..color = c;

  static Paint _shade(
    Rect r,
    Color light,
    Color dark, {
    bool vertical = false,
  }) => Paint()
    ..shader = LinearGradient(
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: [light, dark],
    ).createShader(r);

  static Color _lighten(Color c, double t) => Color.lerp(c, Colors.white, t)!;
  static Color _darken(Color c, double t) => Color.lerp(c, Colors.black, t)!;

  void _shadow(Canvas canvas) => canvas.drawOval(
    const Rect.fromLTWH(18, 86, 64, 8),
    Paint()
      ..color = Colors.black.withValues(alpha: .16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );

  // ---- families ------------------------------------------------------

  void _tee(Canvas c) {
    final body = Path()
      ..moveTo(36, 16)
      ..quadraticBezierTo(50, 24, 64, 16)
      ..lineTo(86, 26)
      ..lineTo(80, 42)
      ..lineTo(70, 38)
      ..lineTo(70, 86)
      ..lineTo(30, 86)
      ..lineTo(30, 38)
      ..lineTo(20, 42)
      ..lineTo(14, 26)
      ..close();
    const r = Rect.fromLTWH(14, 16, 72, 70);
    c.drawPath(body, _shade(r, _lighten(accent, .18), _darken(accent, .22)));
    // Centre stripe and collar trim.
    c.drawRect(
      const Rect.fromLTWH(47, 22, 6, 64),
      _fill(Colors.white.withValues(alpha: .5)),
    );
    c.drawPath(
      Path()
        ..moveTo(36, 16)
        ..quadraticBezierTo(50, 30, 64, 16),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _darken(accent, .45),
    );
    // Crest.
    c.drawCircle(
      const Offset(61, 36),
      4,
      _fill(Colors.white.withValues(alpha: .8)),
    );
  }

  void _sneaker(Canvas c) {
    final upper = Path()
      ..moveTo(12, 70)
      ..quadraticBezierTo(14, 52, 30, 50)
      ..lineTo(44, 36)
      ..quadraticBezierTo(52, 30, 58, 38)
      ..lineTo(64, 50)
      ..quadraticBezierTo(84, 54, 90, 66)
      ..lineTo(90, 72)
      ..lineTo(12, 72)
      ..close();
    const r = Rect.fromLTWH(12, 30, 78, 42);
    c.drawPath(upper, _shade(r, _lighten(accent, .25), _darken(accent, .15)));
    // Sole.
    final sole = RRect.fromLTRBR(10, 70, 92, 80, const Radius.circular(5));
    c.drawRRect(sole, _fill(const Color(0xFFF4F4F2)));
    c.drawRRect(
      sole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFD9D9D6),
    );
    // Swoosh-free neutral stripe and laces.
    c.drawPath(
      Path()
        ..moveTo(28, 64)
        ..quadraticBezierTo(52, 56, 74, 62),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .85),
    );
    final lace = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .9);
    for (var i = 0; i < 3; i++) {
      c.drawLine(
        Offset(44 + i * 5.0, 42 + i * 3.0),
        Offset(52 + i * 5.0, 40 + i * 3.0),
        lace,
      );
    }
  }

  void _jar(Canvas c) {
    const glass = Rect.fromLTWH(24, 42, 52, 44);
    c.drawRRect(
      RRect.fromRectAndRadius(glass, const Radius.circular(10)),
      _shade(glass, const Color(0xFF4F7A60), const Color(0xFF223A2C)),
    );
    const lid = Rect.fromLTWH(22, 28, 56, 16);
    c.drawRRect(
      RRect.fromRectAndRadius(lid, const Radius.circular(5)),
      _shade(
        lid,
        const Color(0xFF3A3F45),
        const Color(0xFF111418),
        vertical: true,
      ),
    );
    // Label.
    c.drawRect(const Rect.fromLTWH(32, 56, 36, 1.4), _fill(Colors.white70));
    c.drawRect(const Rect.fromLTWH(38, 61, 24, 1), _fill(Colors.white54));
    c.drawRect(
      const Rect.fromLTWH(26, 46, 5, 34),
      _fill(Colors.white.withValues(alpha: .14)),
    );
  }

  void _bottle(Canvas c) {
    const body = Rect.fromLTWH(32, 38, 36, 50);
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(8)),
      _shade(body, const Color(0xFFE9C79E), const Color(0xFFB0773F)),
    );
    c.drawRect(
      const Rect.fromLTWH(44, 26, 12, 13),
      _fill(const Color(0xFF2B2F36)),
    );
    c.drawRRect(
      RRect.fromLTRBR(40, 10, 60, 28, const Radius.circular(6)),
      _fill(const Color(0xFF1C1F24)),
    );
    c.drawRRect(
      RRect.fromLTRBR(38, 54, 62, 74, const Radius.circular(2)),
      _fill(Colors.white.withValues(alpha: .8)),
    );
    c.drawRect(
      const Rect.fromLTWH(42, 60, 16, 1.2),
      _fill(const Color(0xFF9A6A3A)),
    );
  }

  void _cup(Canvas c) {
    final cup = Path()
      ..moveTo(26, 34)
      ..lineTo(74, 34)
      ..lineTo(68, 86)
      ..lineTo(32, 86)
      ..close();
    const r = Rect.fromLTWH(26, 34, 48, 52);
    c.drawPath(
      cup,
      _shade(r, const Color(0xFFF7F3EE), const Color(0xFFD8CFC4)),
    );
    // Latte layers through the glass.
    c.drawPath(
      Path()
        ..moveTo(30, 58)
        ..lineTo(70, 58)
        ..lineTo(68, 84)
        ..lineTo(32, 84)
        ..close(),
      _shade(
        r,
        const Color(0xFFB9865A),
        const Color(0xFF7A4E2B),
        vertical: true,
      ),
    );
    c.drawOval(
      const Rect.fromLTWH(26, 28, 48, 12),
      _fill(const Color(0xFFF1E4D3)),
    );
    c.drawOval(
      const Rect.fromLTWH(38, 31, 24, 6),
      _fill(const Color(0xFFC89A6C)),
    );
    c.drawRect(
      const Rect.fromLTWH(33, 40, 3, 40),
      _fill(Colors.white.withValues(alpha: .45)),
    );
  }

  void _bowl(Canvas c) {
    // Food mound.
    c.drawOval(
      const Rect.fromLTWH(20, 36, 60, 28),
      _fill(const Color(0xFFF2EBDD)),
    );
    c.drawCircle(const Offset(38, 44), 8, _fill(const Color(0xFF6BA36A)));
    c.drawCircle(const Offset(56, 42), 7, _fill(const Color(0xFFE0703E)));
    c.drawCircle(const Offset(48, 50), 6, _fill(const Color(0xFFF2C14E)));
    c.drawCircle(const Offset(64, 50), 5, _fill(const Color(0xFF8C5A3C)));
    final bowl = Path()
      ..moveTo(12, 52)
      ..lineTo(88, 52)
      ..quadraticBezierTo(84, 84, 50, 86)
      ..quadraticBezierTo(16, 84, 12, 52)
      ..close();
    c.drawPath(
      bowl,
      _shade(
        const Rect.fromLTWH(12, 52, 76, 34),
        const Color(0xFF2E3238),
        const Color(0xFF0E1013),
      ),
    );
    c.drawRect(
      const Rect.fromLTWH(12, 51, 76, 2.5),
      _fill(const Color(0xFF454A52)),
    );
  }

  void _cake(Canvas c) {
    final slice = Path()
      ..moveTo(14, 60)
      ..lineTo(70, 40)
      ..lineTo(88, 52)
      ..lineTo(88, 78)
      ..lineTo(14, 84)
      ..close();
    c.drawPath(slice, _fill(const Color(0xFF4A2A1C)));
    c.drawRect(
      const Rect.fromLTWH(14, 68, 74, 4),
      _fill(const Color(0xFFE9C9A6)),
    );
    final top = Path()
      ..moveTo(14, 60)
      ..lineTo(70, 40)
      ..lineTo(88, 52)
      ..lineTo(32, 70)
      ..close();
    c.drawPath(top, _fill(const Color(0xFF2E1810)));
    c.drawCircle(const Offset(70, 42), 5, _fill(const Color(0xFFC8303A)));
  }

  void _pastry(Canvas c) {
    const colors = [Color(0xFFE3A55B), Color(0xFFC9803A), Color(0xFFB36B2A)];
    for (var i = 0; i < 5; i++) {
      final w = 24.0 - (i - 2).abs() * 4;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(26 + i * 12.0, 62 - (i == 2 ? 6 : 0)),
          width: w,
          height: 30,
        ),
        _fill(colors[i % 3]),
      );
    }
    c.drawPath(
      Path()
        ..moveTo(20, 60)
        ..quadraticBezierTo(50, 44, 80, 60),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: .35),
    );
  }

  void _bag(Canvas c) {
    c.drawPath(
      Path()
        ..moveTo(36, 36)
        ..quadraticBezierTo(36, 16, 50, 16)
        ..quadraticBezierTo(64, 16, 64, 36),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = _darken(accent, .35),
    );
    const body = Rect.fromLTWH(22, 34, 56, 52);
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(8)),
      _shade(body, _lighten(accent, .2), _darken(accent, .2)),
    );
    c.drawRRect(
      RRect.fromLTRBR(34, 52, 66, 66, const Radius.circular(3)),
      _fill(Colors.white.withValues(alpha: .18)),
    );
  }

  void _gift(Canvas c) {
    const box = Rect.fromLTWH(20, 44, 60, 42);
    c.drawRect(
      box,
      _shade(box, const Color(0xFFF1DCC6), const Color(0xFFD9B894)),
    );
    c.drawRect(
      const Rect.fromLTWH(16, 36, 68, 12),
      _fill(const Color(0xFFE9CDB0)),
    );
    final ribbon = _fill(const Color(0xFFB4413C));
    c.drawRect(const Rect.fromLTWH(46, 36, 8, 50), ribbon);
    c.drawOval(const Rect.fromLTWH(32, 24, 18, 14), ribbon);
    c.drawOval(const Rect.fromLTWH(50, 24, 18, 14), ribbon);
  }

  void _parcel(Canvas c) {
    const box = Rect.fromLTWH(20, 34, 60, 52);
    c.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(4)),
      _shade(box, const Color(0xFFD8B98F), const Color(0xFFB38F62)),
    );
    c.drawRect(
      const Rect.fromLTWH(20, 34, 60, 10),
      _fill(const Color(0xFFC9A677)),
    );
    c.drawRect(
      const Rect.fromLTWH(44, 34, 12, 20),
      _fill(const Color(0xFFEFE2CC)),
    );
  }

  @override
  bool shouldRepaint(_ProductArtPainter old) =>
      old.art != art || old.accent != accent;
}
