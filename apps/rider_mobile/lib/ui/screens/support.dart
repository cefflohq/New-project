import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/legal_content.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/dial.dart';
import '../../data/demo_data.dart';
import '../../data/driver_models.dart';
import '../../data/rider_repository.dart' show RepositoryError;
import '../widgets.dart';
import 'driver_faq.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

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
        title: L.helpSupport,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.sheet,
        Gap.lg,
        Gap.sheet,
        Gap.lg,
      ),
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
                      hintText: L.howCanWeHelp,
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
          Text(L.commonDriverTopics, style: context.t.titleMedium),
          const SizedBox(height: Gap.md),
          if (topics.isEmpty)
            StateBlock.empty(L.noTopicsMatch(_search.text.trim()))
          else
            for (var row = 0; row < (topics.length + 1) ~/ 2; row++) ...[
              // IntrinsicHeight so the two cards in a row match height even
              // when their body copy wraps to a different number of lines.
              // (A bare stretch here would hand the cards unbounded height,
              // because the column scrolls.)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _TopicCard(
                        icon: topics[row * 2].$2,
                        topic: topics[row * 2].$1,
                        onTap: () => _faq(context, app, topics[row * 2].$1),
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: row * 2 + 1 < topics.length
                          ? _TopicCard(
                              icon: topics[row * 2 + 1].$2,
                              topic: topics[row * 2 + 1].$1,
                              onTap: () =>
                                  _faq(context, app, topics[row * 2 + 1].$1),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.md),
            ],
          const SizedBox(height: Gap.sm),
          Text(L.needMoreHelp, style: context.t.titleMedium),
          const SizedBox(height: Gap.md),
          _HelpRow(
            icon: LucideIcons.messageSquare,
            title: L.contactSupport,
            subtitle: L.submitSupportTicket,
            onTap: () => showContactSupportSheet(context, app),
          ),
          const SizedBox(height: Gap.md),
          _HelpRow(
            icon: LucideIcons.shieldAlert,
            title: L.cmpTitle,
            subtitle: L.cmpLead,
            onTap: () => app.go(DRoute.complaints),
          ),
          const SizedBox(height: Gap.md),
          _HelpRow(
            icon: LucideIcons.fileText,
            title: L.mySupportTickets,
            subtitle: L.checkTicketStatus,
            onTap: () => _showTickets(context),
          ),
        ],
      ),
    );
  }

  /// A topic opens its answers; "Still need help?" goes to Contact Support.
  void _faq(BuildContext context, AppState app, SupportTopic topic) {
    final i = DemoData.supportTopics.indexWhere((t) => t.title == topic.title);
    showDriverFaq(
      context,
      index: i < 0 ? 0 : i,
      title: topic.title,
      onContact: () => showContactSupportSheet(context, app),
    );
  }

  void _showTickets(BuildContext context) => showCeffloSheet<void>(
    context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Gap.gutter, 0, Gap.gutter, Gap.xl),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: AppScope.read(context).repo.mySupportTickets(),
        builder: (context, snap) {
          final list = snap.data ?? const [];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetGrabber(),
              const SizedBox(height: 6),
              Text(L.mySupportTickets, style: context.t.titleLarge),
              const SizedBox(height: Gap.lg),
              if (snap.connectionState != ConnectionState.done)
                const StateBlock.loading()
              else if (snap.hasError)
                StateBlock.error(L.couldNotLoad)
              else if (list.isEmpty)
                StateBlock.empty(L.haveNoSupportTicketsYetSubmit)
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
                    itemBuilder: (context, i) => _TicketCard(t: list[i]),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

/// One ticket: what was sent, its status and the reply once there is one.
class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.t});
  final Map<String, dynamic> t;

  @override
  Widget build(BuildContext context) {
    final resolved = t['status'] == 'resolved';
    final reply = t['reply'] as String?;
    final when = DateTime.tryParse('${t['created_at']}')?.toLocal();
    return CeffloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  when == null ? '' : '${when.day}/${when.month}/${when.year}',
                  style: context.t.labelMedium,
                ),
              ),
              CeffloStatusChip(
                resolved ? L.ticketAnswered : L.ticketOpen,
                tone: resolved ? ChipTone.success : ChipTone.warning,
              ),
            ],
          ),
          const SizedBox(height: Gap.xs),
          Text('${t['description']}', style: context.t.bodyMedium),
          if (reply != null && reply.isNotEmpty) ...[
            const SizedBox(height: Gap.sm),
            Text(L.ticketReply, style: context.t.labelMedium),
            Text(reply, style: context.t.bodyMedium),
          ],
        ],
      ),
    );
  }
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
              Text(
                title,
                style: context.t.titleSmall?.copyWith(fontSize: 15.5),
              ),
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
                      L.contactSupport,
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
                L.whatDoNeedHelp,
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
        title: L.vendorSupport,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.xl,
        Gap.gutter,
        Gap.lg,
      ),
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
                LucideIcons.store,
                size: 32,
                color: CefColors.navy,
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          Center(
            child: Text(
              L.contactBusiness,
              style: context.t.displaySmall?.copyWith(fontSize: 21),
            ),
          ),
          const SizedBox(height: Gap.md),
          Text(
            L.issueRelatedVendorsBusinessOperationsE,
            textAlign: TextAlign.center,
            style: context.t.bodyMedium,
          ),
          const SizedBox(height: Gap.md),
          Text(
            L.pleaseContactBusinessDirectlyFasterAssistance,
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
                            style: context.t.titleMedium?.copyWith(
                              fontSize: 16.5,
                            ),
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
                  title: L.call,
                  subtitle: vendor.phone ?? '',
                  onTap: () async {
                    if (!await dialPhone(vendor.phone) && context.mounted) {
                      showCefToast(context, L.phoneNotAvailable);
                    }
                  },
                ),
                Divider(height: 1, color: c.border),
                _ContactRow(
                  icon: LucideIcons.messageSquare,
                  title: L.chat,
                  subtitle: 'WhatsApp',
                  onTap: () async {
                    if (!await openWhatsApp(vendor.phone) && context.mounted) {
                      showCefToast(context, L.phoneNotAvailable);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
          CeffloNote(
            icon: LucideIcons.info,
            body: L.ceffloDoesNotManageVendorOperations,
          ),
          const SizedBox(height: Gap.lg),
          CeffloSecondaryButton(
            L.backHelpSupport,
            pill: false,
            onTap: app.back,
          ),
        ],
      ),
    );
  }
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
                  Text(
                    title,
                    style: context.t.titleSmall?.copyWith(fontSize: 15.5),
                  ),
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
  bool _sending = false;
  late SupportCategory _category = AppScope.read(context).supportCategory;
  final _photos = <List<int>>[];

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
        title: L.submitTicket,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.sheet,
        Gap.xl,
        Gap.sheet,
        Gap.lg,
      ),
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
              L.ceffloSupport,
              style: context.t.displaySmall?.copyWith(fontSize: 21),
            ),
          ),
          const SizedBox(height: Gap.sm),
          Text(
            L.tellUsAboutIssueWellGet,
            textAlign: TextAlign.center,
            style: context.t.bodyMedium,
          ),
          const SizedBox(height: Gap.lg),
          CeffloSelectField<SupportCategory>(
            label: L.category,
            value: _category,
            options: SupportCategory.values,
            optionLabel: (v) => v.title,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: Gap.lg),
          CeffloTextField(
            label: L.describeIssue,
            controller: _description,
            hint: L.pleaseProvideMuchDetailPossibleE,
            maxLines: 4,
          ),
          // Up to 3 photos, stored with the ticket (cefflo-support-photos).
          const SizedBox(height: Gap.lg),
          CeffloFieldLabel(L.addScreenshotPhotoOptional),
          const SizedBox(height: 6),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (var i = 0; i < _photos.length; i++)
                InputChip(
                  label: Text('${i + 1}'),
                  avatar: const Icon(LucideIcons.image, size: 16),
                  onDeleted: () => setState(() => _photos.removeAt(i)),
                ),
              if (_photos.length < 3)
                ActionChip(
                  avatar: Icon(
                    LucideIcons.imageUp,
                    size: 16,
                    color: c.textLabel,
                  ),
                  label: Text(L.tapAddPhoto),
                  onPressed: () async {
                    final files = await ImagePicker().pickMultiImage(
                      maxWidth: 1600,
                      imageQuality: 82,
                      limit: 3 - _photos.length,
                    );
                    for (final f in files.take(3 - _photos.length)) {
                      _photos.add(await f.readAsBytes());
                    }
                    if (mounted) setState(() {});
                  },
                ),
            ],
          ),
        ],
      ),
      // Sent to the vendor (customer / delivery / business issues) or to
      // Cefflo (app, account, other) by submit_support_ticket.
      footer: CeffloPrimaryButton(
        L.submitTicket,
        pill: false,
        busy: _sending,
        onTap: _description.text.trim().isEmpty || _sending
            ? null
            : () async {
                if (!app.repo.isDemo) {
                  setState(() => _sending = true);
                  try {
                    await app.repo.submitSupportTicket(
                      category: _category.wire,
                      description: _description.text.trim(),
                      riderId: app.active?.id,
                      photos: _photos,
                    );
                  } on RepositoryError catch (e) {
                    if (mounted) {
                      setState(() => _sending = false);
                      showCefToast(this.context, e.message, error: true);
                    }
                    return;
                  }
                  if (!mounted) return;
                  setState(() => _sending = false);
                }
                if (!context.mounted) return;
                await showCeffloSubmitFlow(
                  context,
                  successTitle: L.requestSubmitted,
                  successBody: L.wellGetBackSoon,
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
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// D40.2 / D40.3: the shared Privacy Policy or Terms of Service
/// (shared/legal), identical to the website, Vendor app and Vendor Web.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.privacy});
  final bool privacy;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = L.localeName == 'ms' ? 'ms' : 'en';
    final sections = (privacy ? legalPrivacy : legalTerms)[lang]!;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: privacy ? L.legalPrivacyPolicy : L.legalTerms,
        onBack: app.back,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${L.legalLastUpdated}: ${legalUpdated[lang]}',
            style: context.t.bodySmall,
          ),
          for (final (i, s) in sections.indexed) ...[
            const SizedBox(height: Gap.lg),
            Text('${i + 1}. ${s.h}', style: context.t.titleSmall),
            const SizedBox(height: 4),
            Text(s.p, style: context.t.bodyMedium?.copyWith(height: 1.6)),
          ],
        ],
      ),
    );
  }
}
