import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../../data/driver_models.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------
// D40 — Help & Support
// ---------------------------------------------------------------------------

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _search = TextEditingController();

  static const _topicIcons = <IconData>[
    LucideIcons.package,
    LucideIcons.truck,
    LucideIcons.fileText,
    LucideIcons.user,
  ];

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final query = _search.text.trim().toLowerCase();
    final topics = [
      for (var i = 0; i < DemoData.supportTopics.length; i++)
        if (query.isEmpty ||
            DemoData.supportTopics[i].title.toLowerCase().contains(query) ||
            DemoData.supportTopics[i].body.toLowerCase().contains(query))
          (DemoData.supportTopics[i], _topicIcons[i]),
    ];

    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: 'Help & Support',
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.lg, Gap.gutter, Gap.lg),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: Sizes.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: CefColors.tintNeutral,
              borderRadius: BorderRadius.circular(Sizes.cardRadius),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 20, color: c.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _search,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'How can we help?',
                      hintStyle: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          Text('Common Driver Topics', style: context.t.titleMedium),
          const SizedBox(height: Gap.md),
          if (topics.isEmpty)
            StateBlock.empty('No topics match “${_search.text.trim()}”.')
          else
            for (var row = 0; row < (topics.length + 1) ~/ 2; row++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TopicCard(
                      icon: topics[row * 2].$2,
                      topic: topics[row * 2].$1,
                      onTap: () => showContactSupportSheet(context, app),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: row * 2 + 1 < topics.length
                        ? _TopicCard(
                            icon: topics[row * 2 + 1].$2,
                            topic: topics[row * 2 + 1].$1,
                            onTap: () => showContactSupportSheet(context, app),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
            ],
          const SizedBox(height: Gap.sm),
          Text('Need more help?', style: context.t.titleMedium),
          const SizedBox(height: Gap.md),
          _HelpRow(
            icon: LucideIcons.messageSquare,
            title: 'Contact Support',
            subtitle: 'Submit a support ticket',
            onTap: () => showContactSupportSheet(context, app),
          ),
          const SizedBox(height: Gap.md),
          _HelpRow(
            icon: LucideIcons.fileText,
            title: 'My Support Tickets',
            subtitle: 'Check your ticket status',
            onTap: () => _showTickets(context),
          ),
        ],
      ),
    );
  }

  void _showTickets(BuildContext context) => showCeffloSheet<void>(
    context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Gap.gutter, 0, Gap.gutter, Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetGrabber(),
          const SizedBox(height: 6),
          Text('My Support Tickets', style: context.t.titleLarge),
          const SizedBox(height: Gap.lg),
          StateBlock.empty(
            'You have no support tickets yet. Submit one from Contact Support '
            'and it will appear here.',
          ),
        ],
      ),
    ),
  );
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.icon,
    required this.topic,
    required this.onTap,
  });

  final IconData icon;
  final SupportTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CeffloCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    shadow: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26, color: CefColors.navy),
        const SizedBox(height: Gap.md),
        Text(topic.title, style: context.t.titleSmall),
        const SizedBox(height: 3),
        Text(topic.body, style: context.t.bodySmall),
      ],
    ),
  );
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CeffloCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    shadow: false,
    child: Row(
      children: [
        Icon(icon, size: 24, color: CefColors.navy),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.t.titleSmall?.copyWith(fontSize: 15.5)),
              const SizedBox(height: 2),
              Text(subtitle, style: context.t.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D40-A — Contact Support (bottom sheet over D40)
// ---------------------------------------------------------------------------

/// Routes the Driver by who actually owns the problem: a vendor-owned
/// operational issue goes to D40-B (contact the business), everything else
/// opens a Cefflo ticket on D40-C.
Future<void> showContactSupportSheet(BuildContext context, AppState app) =>
    showCeffloSheet<void>(
      context,
      child: Builder(
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(Gap.gutter, 0, Gap.gutter, Gap.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetGrabber(),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: Sizes.tapTarget),
                  Expanded(
                    child: Text(
                      'Contact Support',
                      textAlign: TextAlign.center,
                      style: context.t.titleLarge,
                    ),
                  ),
                  SizedBox(
                    width: Sizes.tapTarget,
                    child: IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: Icon(
                        LucideIcons.x,
                        size: 22,
                        color: context.c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.sm),
              Text(
                'What do you need help with?',
                style: context.t.titleSmall?.copyWith(fontSize: 14.5),
              ),
              const SizedBox(height: Gap.md),
              for (final category in SupportCategory.values) ...[
                CeffloCard(
                  padding: EdgeInsets.zero,
                  shadow: false,
                  radius: Sizes.innerRadius,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    app.setSupportCategory(category);
                    app.go(
                      category.vendorOwned
                          ? DRoute.vendorSupport
                          : DRoute.submitTicket,
                    );
                  },
                  child: CeffloOptionRow(
                    icon: _categoryIcon(category),
                    title: category.title,
                    subtitle: category.body,
                    dense: true,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      app.setSupportCategory(category);
                      app.go(
                        category.vendorOwned
                            ? DRoute.vendorSupport
                            : DRoute.submitTicket,
                      );
                    },
                  ),
                ),
                const SizedBox(height: Gap.sm),
              ],
            ],
          ),
        ),
      ),
    );

IconData _categoryIcon(SupportCategory category) => switch (category) {
  SupportCategory.deliveryRunIssue => LucideIcons.truck,
  SupportCategory.vendorBusinessIssue => LucideIcons.store,
  SupportCategory.ceffloAppIssue => LucideIcons.smartphone,
  SupportCategory.accountDocuments => LucideIcons.fileText,
  SupportCategory.other => LucideIcons.ellipsis,
};

// ---------------------------------------------------------------------------
// D40-B — Vendor Support
// ---------------------------------------------------------------------------

class VendorSupportScreen extends StatelessWidget {
  const VendorSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final vendor = DemoData.supportVendor;
    final c = context.c;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: 'Vendor Support',
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.xl, Gap.gutter, Gap.lg),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: CefColors.tintInfo,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.store, size: 32, color: CefColors.navy),
            ),
          ),
          const SizedBox(height: Gap.lg),
          Center(
            child: Text(
              'Contact Business',
              style: context.t.displaySmall?.copyWith(fontSize: 21),
            ),
          ),
          const SizedBox(height: Gap.md),
          Text(
            'This issue is related to the vendor’s business operations (e.g. '
            'orders, assignments, customer, delivery instructions).',
            textAlign: TextAlign.center,
            style: context.t.bodyMedium,
          ),
          const SizedBox(height: Gap.md),
          Text(
            'Please contact the business directly for faster assistance.',
            textAlign: TextAlign.center,
            style: context.t.bodyMedium,
          ),
          const SizedBox(height: Gap.lg),
          CeffloCard(
            padding: const EdgeInsets.all(14),
            shadow: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: CefColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'KK',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: CefColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.name,
                            style: context.t.titleMedium?.copyWith(fontSize: 16.5),
                          ),
                          Text(vendor.category, style: context.t.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.md),
                Divider(height: 1, color: c.border),
                _ContactRow(
                  icon: LucideIcons.phone,
                  title: 'Call',
                  subtitle: vendor.phone ?? '',
                  onTap: () => _toast(context, 'Calling ${vendor.name}…'),
                ),
                Divider(height: 1, color: c.border),
                _ContactRow(
                  icon: LucideIcons.messageSquare,
                  title: 'Chat',
                  subtitle: 'In-app message to vendor',
                  onTap: () => _toast(context, 'Opening vendor chat…'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
          const CeffloNote(
            icon: LucideIcons.info,
            body: 'Cefflo does not manage vendor operations. For app or account '
                'issues, please go back and select the relevant category.',
          ),
          const SizedBox(height: Gap.lg),
          CeffloSecondaryButton(
            'Back to Help & Support',
            pill: false,
            onTap: app.back,
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: CefColors.navy,
        ),
      );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 24, color: CefColors.navy),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.t.titleSmall?.copyWith(fontSize: 15.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.t.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// D40-C — Submit Ticket
// ---------------------------------------------------------------------------

class SubmitTicketScreen extends StatefulWidget {
  const SubmitTicketScreen({super.key});

  @override
  State<SubmitTicketScreen> createState() => _SubmitTicketScreenState();
}

class _SubmitTicketScreenState extends State<SubmitTicketScreen> {
  final _description = TextEditingController();
  late SupportCategory _category = AppScope.read(context).supportCategory;
  bool _photoAdded = false;

  @override
  void initState() {
    super.initState();
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: 'Submit Ticket',
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.xl, Gap.gutter, Gap.lg),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: CefColors.tintInfo,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.fileText,
                size: 30,
                color: CefColors.navy,
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          Center(
            child: Text(
              'Cefflo Support',
              style: context.t.displaySmall?.copyWith(fontSize: 21),
            ),
          ),
          const SizedBox(height: Gap.sm),
          Text(
            'Tell us about the issue and we’ll get back to you as soon as possible.',
            textAlign: TextAlign.center,
            style: context.t.bodyMedium,
          ),
          const SizedBox(height: Gap.lg),
          CeffloSelectField<SupportCategory>(
            label: 'Category',
            value: _category,
            options: SupportCategory.values,
            optionLabel: (v) => v.title,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: Gap.lg),
          CeffloTextField(
            label: 'Describe your issue',
            controller: _description,
            hint: 'Please provide as much detail as possible…\n'
                '(e.g. what happened, when, steps to reproduce)',
            maxLines: 4,
          ),
          const SizedBox(height: Gap.lg),
          const CeffloFieldLabel('Add screenshot or photo (optional)'),
          const SizedBox(height: 6),
          Material(
            color: c.card,
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(Sizes.cardRadius),
              onTap: () => setState(() => _photoAdded = !_photoAdded),
              child: DottedBorderBox(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Gap.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _photoAdded ? LucideIcons.imageUp : LucideIcons.image,
                        size: 26,
                        color: c.textLabel,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _photoAdded ? 'Photo attached' : 'Tap to add photo',
                            style: context.t.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PNG, JPG (Max 5MB each)',
                            style: context.t.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      footer: CeffloPrimaryButton(
        'Submit Ticket',
        pill: false,
        onTap: _description.text.trim().isEmpty
            ? null
            : () async {
                await showCeffloSubmitFlow(
                  context,
                  successTitle: 'Request submitted',
                  successBody: 'We’ll get back to you soon.',
                  onDone: () => app.resetTo(DRoute.helpSupport),
                );
              },
      ),
    );
  }
}

/// Dashed outline for the upload drop-zone D40-C draws.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedRectPainter(color: context.c.border),
    child: child,
  );
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(Sizes.cardRadius),
    );
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + 6),
          paint,
        );
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
