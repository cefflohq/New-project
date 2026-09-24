import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../async_view.dart';
import '../shell.dart';
import '../widgets.dart';

/// V-19 — Active Run presentation. This is a preview/read model shell until
/// the repo exposes a dedicated run read endpoint for the route id.
class RunDetailScreen extends StatelessWidget {
  const RunDetailScreen({super.key, required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Row(
          children: [
            Flexible(child: Text(runId, style: text.titleMedium)),
            const SizedBox(width: Gap.md),
            const StatusChip('Active', success: true),
          ],
        ),
        const SizedBox(height: Gap.xs),
        Text('Bangsar · Ahmad Razi · VFY 7281', style: text.bodySmall),
        const SizedBox(height: Gap.md),
        SizedBox(
          height: 240,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            child: CustomPaint(
              painter: _RoutePreviewPainter(
                ground: c.subtle,
                route: c.info,
                road: c.card,
              ),
            ),
          ),
        ),
        const SizedBox(height: Gap.lg),
        Row(
          children: [
            Expanded(child: Text('3 of 7 delivered', style: text.titleMedium)),
            Text('4 remaining', style: text.bodySmall),
          ],
        ),
        const SizedBox(height: Gap.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(Sizes.buttonRadius),
          child: LinearProgressIndicator(
            value: 3 / 7,
            minHeight: Gap.sm,
            backgroundColor: c.subtle,
            valueColor: AlwaysStoppedAnimation(c.info),
          ),
        ),
        const SectionHeading('Next stop'),
        const CefListRow(
          title: 'Nadia Rahman',
          subtitle: 'Bangsar · 1.2 km · 8 min',
          icon: LucideIcons.mapPin,
          trailing: StatusChip('Next'),
        ),
        const SectionHeading('Upcoming stops'),
        for (final i in const [
          ('Firdaus Cafe', 'Mont Kiara · 2.1 km'),
          ('Amy Lee', 'Damansara · 3.4 km'),
          ('Restoran Ali', 'Petaling Jaya · 4.0 km'),
        ])
          CefListRow(title: i.$1, subtitle: i.$2, icon: LucideIcons.mapPin),
        const SizedBox(height: Gap.md),
        const StateBlock.blocked(
          'Route sequencing and live ETA are backend-owned. This screen is presentation-only until Phase 3 wiring.',
        ),
      ],
    );
  }
}

/// Locked V-19 direction: a blue route with a Yellow driver marker, never a
/// bare placeholder box. Illustrative only — real polylines/ETA are
/// backend-owned and land in Phase 3.
class _RoutePreviewPainter extends CustomPainter {
  _RoutePreviewPainter({
    required this.ground,
    required this.route,
    required this.road,
  });
  final Color ground, route, road;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final roads = Paint()
      ..color = road
      ..strokeWidth = 5;
    for (var i = -2; i < 8; i++) {
      canvas.drawLine(
        Offset(0, i * 40.0),
        Offset(size.width, i * 40.0 + 90),
        roads,
      );
    }
    final path = Path()
      ..moveTo(size.width * .12, size.height * .82)
      ..quadraticBezierTo(
        size.width * .35,
        size.height * .30,
        size.width * .58,
        size.height * .48,
      )
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .62,
        size.width * .90,
        size.height * .18,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    for (final stop in [
      Offset(size.width * .12, size.height * .82),
      Offset(size.width * .58, size.height * .48),
    ]) {
      canvas.drawCircle(stop, 5, Paint()..color = route);
      canvas.drawCircle(
        stop,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    for (final fraction in const [
      Offset(.25, .58),
      Offset(.43, .43),
      Offset(.73, .48),
    ]) {
      final center = Offset(
        size.width * fraction.dx,
        size.height * fraction.dy,
      );
      canvas.drawCircle(center, 12, Paint()..color = route);
      final check = Path()
        ..moveTo(center.dx - 4, center.dy)
        ..lineTo(center.dx - 1, center.dy + 3)
        ..lineTo(center.dx + 5, center.dy - 4);
      canvas.drawPath(
        check,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final driver = Offset(size.width * .90, size.height * .18);
    canvas.drawCircle(driver, 20, Paint()..color = CefColors.accent);
    final marker = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(LucideIcons.motorbike.codePoint),
        style: TextStyle(
          fontFamily: LucideIcons.motorbike.fontFamily,
          package: LucideIcons.motorbike.fontPackage,
          fontSize: 22,
          color: CefColors.navy,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    marker.paint(canvas, driver - Offset(marker.width / 2, marker.height / 2));
    canvas.drawCircle(
      driver,
      20,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) =>
      oldDelegate.ground != ground ||
      oldDelegate.route != route ||
      oldDelegate.road != road;
}

/// V-26 / V-27 — Service area. Coverage is a server decision; this screen
/// only configures the origin and radius the server uses. The origin is
/// carried as plain doubles rather than shown as raw latitude/longitude —
/// the locked guidance is to avoid technical geometry language, so the
/// vendor only ever sees a delivery-radius slider and a coverage preview.
class ServiceAreaScreen extends StatefulWidget {
  const ServiceAreaScreen({super.key});
  @override
  State<ServiceAreaScreen> createState() => _ServiceAreaScreenState();
}

class _ServiceAreaScreenState extends State<ServiceAreaScreen> {
  // Kuala Lumpur city-centre fallback: the demo/UI-only origin used until a
  // real pickup-location picker is wired in Phase 3.
  double latitude = 3.1390;
  double longitude = 101.6869;
  double radiusKm = 5;
  bool busy = false;
  String? error;
  bool loaded = false;

  void _prefill(Map<String, dynamic> b) {
    if (loaded) return;
    loaded = true;
    latitude = (b['service_origin_latitude'] as num?)?.toDouble() ?? latitude;
    longitude =
        (b['service_origin_longitude'] as num?)?.toDouble() ?? longitude;
    radiusKm =
        (b['service_coverage_radius_km'] as num?)?.toDouble() ?? radiusKm;
  }

  Future<void> _save(Future<void> Function() reload) async {
    final app = AppScope.read(context);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await app.repo.setServiceArea(
        businessId: app.business!.id,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      if (!mounted) return;
      await runAsyncFeedback(
        context,
        action: () async {},
        processingTitle: 'Processing...',
        processingSubtitle: 'Saving your service area',
        successTitle: 'Successful',
        successSubtitle: 'Your service area has been saved.',
      );
      if (!mounted) return;
      await reload();
    } on RepositoryError catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business;
    if (business == null) {
      return const PageBody(
        children: [StateBlock.empty('No business linked.')],
      );
    }
    return AsyncView<Map<String, dynamic>>(
      key: ValueKey('service-area-${business.id}'),
      load: () => app.repo.business(business.id),
      builder: (context, b, reload) {
        _prefill(b);
        final configured = b['service_coverage_radius_km'] != null;
        return PageBody(
          children: [
            CefListRow(
              icon: LucideIcons.map,
              title: 'Coverage',
              subtitle: configured
                  ? 'Coverage is configured. Cefflo decides each '
                        'order’s coverage from this.'
                  : 'No service area configured yet. Orders will show '
                        '“Not set” instead of a coverage verdict.',
              subtitleMaxLines: 5,
              trailing: StatusChip(
                configured ? 'Configured' : 'Not set',
                attention: !configured,
              ),
            ),
            const SectionHeading('How far do you deliver?'),
            SizedBox(height: 190, child: CoveragePreview(radiusKm: radiusKm)),
            const SizedBox(height: Gap.md),
            RadiusSlider(
              radiusKm: radiusKm,
              onChanged: (v) => setState(() => radiusKm = v),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Text(
                  error!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.c.attention),
                ),
              ),
            const SizedBox(height: Gap.sm),
            CefButton(
              'Save service area',
              busy: busy,
              onTap: () => _save(reload),
            ),
            const SizedBox(height: Gap.section),
            CefListRow(
              title: 'Manage zones',
              subtitle: 'See and configure the zones you deliver to',
              icon: LucideIcons.mapPin,
              onTap: () => app.go(VRoute.zoneConfiguration),
            ),
          ],
        );
      },
    );
  }
}

/// Illustrative coverage circle around the pickup pin, shared by the setup
/// wizard (V-09) and the Service Area screen (V-26) so both draw the same
/// preview. Fills whatever box its parent gives it.
class CoveragePreview extends StatelessWidget {
  const CoveragePreview({super.key, required this.radiusKm});
  final double radiusKm;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      child: CustomPaint(
        painter: _CoveragePreviewPainter(
          radiusKm: radiusKm,
          ground: c.subtle,
          coverage: c.info,
        ),
        child: const Center(
          child: Icon(LucideIcons.mapPin, color: CefColors.navy, size: 30),
        ),
      ),
    );
  }
}

/// "Delivery radius" label + value and the 2–20 km slider, shared by V-09
/// and V-26 so the radius control has one treatment.
class RadiusSlider extends StatelessWidget {
  const RadiusSlider({
    super.key,
    required this.radiusKm,
    required this.onChanged,
  });
  final double radiusKm;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Delivery radius', style: text.titleSmall),
            Text('${radiusKm.round()} km', style: text.titleSmall),
          ],
        ),
        Slider(
          value: radiusKm,
          min: 2,
          max: 20,
          divisions: 18,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CoveragePreviewPainter extends CustomPainter {
  _CoveragePreviewPainter({
    required this.radiusKm,
    required this.ground,
    required this.coverage,
  });
  final double radiusKm;
  final Color ground, coverage;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide * .42;
    final r = maxRadius * (radiusKm / 20).clamp(.25, 1.0);
    canvas.drawCircle(
      center,
      r,
      Paint()..color = coverage.withValues(alpha: .2),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = coverage
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CoveragePreviewPainter oldDelegate) =>
      oldDelegate.radiusKm != radiusKm ||
      oldDelegate.ground != ground ||
      oldDelegate.coverage != coverage;
}
