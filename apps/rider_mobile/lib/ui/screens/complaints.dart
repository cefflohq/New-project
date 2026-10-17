import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/rider_repository.dart';
import '../widgets.dart';
import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// Complaints (Prosedur Aduan, Founder 2026-10-16): the driver reports a
/// business (not paid, behaviour, safety, fraud) and answers reports about
/// them within 48 h. Cefflo decides with both sides and the order records.

String _category(String? c) => switch (c) {
  'damaged_lost' => L.cmpCatDamaged,
  'conduct' => L.cmpCatConduct,
  'safety' => L.cmpCatSafety,
  'unpaid' => L.cmpCatUnpaid,
  'fraud' => L.cmpCatFraud,
  _ => L.cmpCatOther,
};

String _decision(String? d) => switch (d) {
  'settled' => L.cmpDecSettled,
  'no_fault' => L.cmpDecNoFault,
  'warning' => L.cmpDecWarning,
  'driver_at_fault' => L.cmpDecDriver,
  'vendor_at_fault' => L.cmpDecVendor,
  'customer_at_fault' => L.cmpDecCustomer,
  'false_report' => L.cmpDecFalse,
  _ => L.cmpStatusResolved,
};

String _party(String? role) => switch (role) {
  'customer' => L.cmpFromCustomer,
  'driver' => L.cmpFromDriver,
  _ => L.cmpFromBusiness,
};

String _when(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.day}/${d.month} ${two(d.hour)}:${two(d.minute)}';
}

Widget _chip(Map<String, dynamic> c) => switch (c['status']) {
  'awaiting_reply' => CeffloStatusChip(L.cmpStatusAwaiting, tone: ChipTone.warning),
  'in_review' => CeffloStatusChip(L.cmpStatusReview, tone: ChipTone.info),
  _ => CeffloStatusChip(L.cmpStatusResolved, tone: ChipTone.success),
};

/// Loads the driver's complaints once per screen, with pull-to-refresh.
mixin _ComplaintsLoader<T extends StatefulWidget> on State<T> {
  List<Map<String, dynamic>>? items;
  String? error;

  Future<void> reload() async {
    try {
      final r = await AppScope.read(context).repo.myComplaints();
      if (mounted) {
        setState(() {
          items = r;
          error = null;
        });
      }
    } on RepositoryError catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  Widget? stateBlock() => error != null
      ? StateBlock.error(error!, onRetry: reload)
      : items == null
      ? const StateBlock.loading()
      : null;
}

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with _ComplaintsLoader {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final list = (items ?? const <Map<String, dynamic>>[])
        .where((c) => (c['status'] == 'resolved') == (_tab == 1))
        .toList();
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.cmpTitle,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      onRefresh: reload,
      footer: app.active == null
          ? null
          : CeffloPrimaryButton(
              L.cmpReportProblem,
              pill: false,
              onTap: () => app.go(DRoute.reportProblem),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CeffloSegmentedTabs(
            labels: [L.cmpTabOpen, L.cmpTabResolved],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: Gap.md),
          ?stateBlock(),
          if (stateBlock() == null && list.isEmpty) StateBlock.empty(L.cmpEmpty),
          if (stateBlock() == null)
            for (final c in list) ...[
              _Card(
                c: c,
                onTap: () => app.go(
                  DRoute.complaintDetail,
                  entityId: c['id'] as String,
                ),
              ),
              const SizedBox(height: Gap.sm),
            ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.c, required this.onTap});
  final Map<String, dynamic> c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mine = c['side'] == 'complainant';
    final needsReply =
        !mine && c['status'] == 'awaiting_reply' && c['replied'] != true;
    return CeffloCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${c['ref']} · ${_category(c['category'] as String?)}',
                  style: context.t.titleSmall,
                ),
              ),
              _chip(c),
            ],
          ),
          const SizedBox(height: Gap.xs),
          Text(
            mine
                ? '${L.cmpYouReported} · ${c['business_name'] ?? ''}'
                : '${L.cmpAboutYou} · ${_party(c['complainant_role'] as String?)}',
            style: context.t.bodySmall,
          ),
          if (needsReply) ...[
            const SizedBox(height: Gap.xs),
            Text(
              L.cmpReplyBy(_when(c['reply_due_at'] as String?)),
              style: context.t.bodySmall?.copyWith(color: context.c.attention),
            ),
          ],
        ],
      ),
    );
  }
}

class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({super.key, required this.complaintId});
  final String complaintId;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen>
    with _ComplaintsLoader {
  final _reply = TextEditingController();
  final _photos = <List<int>>[];
  bool _busy = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _reply.text.trim();
    if (body.length < 5) {
      showCefToast(context, L.cmpTooShort, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await AppScope.read(
        context,
      ).repo.replyComplaint(widget.complaintId, body, photos: _photos);
      if (!mounted) return;
      _reply.clear();
      _photos.clear();
      showCefToast(context, L.cmpReplySent);
      await reload();
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = items?.where((x) => x['id'] == widget.complaintId).firstOrNull;
    final mine = c?['side'] == 'complainant';
    final canReply = c != null && !mine && c['status'] != 'resolved';
    String who(String? role) => switch (role) {
      'complainant' => mine ? L.cmpYourSide : L.cmpTheirSide,
      'respondent' => mine ? L.cmpTheirSide : L.cmpYourSide,
      _ => L.cmpCefflo,
    };
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: (c?['ref'] as String?) ?? L.cmpTitle,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      onRefresh: reload,
      footer: canReply
          ? CeffloPrimaryButton(
              L.cmpSendReply,
              pill: false,
              busy: _busy,
              onTap: _busy ? null : _send,
            )
          : null,
      body: c == null
          ? (stateBlock() ?? StateBlock.empty(L.cmpEmpty))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CeffloCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _category(c['category'] as String?),
                              style: context.t.titleMedium,
                            ),
                          ),
                          _chip(c),
                        ],
                      ),
                      if (c['business_name'] != null)
                        Text(
                          '${L.cmpBusiness}: ${c['business_name']}',
                          style: context.t.bodySmall,
                        ),
                      if (c['order_ref'] != null)
                        Text(
                          L.cmpOrder(c['order_ref'] as String),
                          style: context.t.bodySmall,
                        ),
                      if (c['status'] == 'awaiting_reply')
                        Text(
                          L.cmpReplyBy(_when(c['reply_due_at'] as String?)),
                          style: context.t.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (c['status'] == 'resolved') ...[
                  const SizedBox(height: Gap.sm),
                  CeffloCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(L.cmpOutcome, style: context.t.titleSmall),
                        const SizedBox(height: Gap.xs),
                        Text(
                          _decision(c['decision'] as String?),
                          style: context.t.bodyMedium,
                        ),
                        if ((c['decision_note'] as String?)?.isNotEmpty ??
                            false)
                          Text(
                            c['decision_note'] as String,
                            style: context.t.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Gap.sm),
                for (final e in (c['entries'] as List? ?? const []).cast<Map>()) ...[
                  CeffloCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${who(e['author_role'] as String?)} · ${_when(e['created_at'] as String?)}',
                          style: context.t.labelMedium,
                        ),
                        if (e['body'] != null) ...[
                          const SizedBox(height: Gap.xs),
                          Text(e['body'] as String, style: context.t.bodyMedium),
                        ],
                        if (e['url'] != null) ...[
                          const SizedBox(height: Gap.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              e['url'] as String,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.sm),
                ],
                if (canReply && c['replied'] != true)
                  Text(L.cmpNoReplyYet, style: context.t.bodySmall),
                if (canReply) ...[
                  const SizedBox(height: Gap.md),
                  CeffloTextField(
                    label: L.cmpGiveYourSide,
                    controller: _reply,
                    hint: L.cmpReplyHint,
                    maxLines: 5,
                  ),
                  const SizedBox(height: Gap.md),
                  _Photos(photos: _photos, onChanged: () => setState(() {})),
                ],
              ],
            ),
    );
  }
}

/// The driver's report about the business they deliver for.
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  static const _cats = ['unpaid', 'conduct', 'safety', 'fraud', 'other'];
  String _cat = _cats.first;
  final _text = TextEditingController();
  final _photos = <List<int>>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final app = AppScope.read(context);
    final d = _text.text.trim();
    if (d.length < 10) {
      showCefToast(context, L.cmpTooShort, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final ref = await app.repo.fileComplaint(
        category: _cat,
        description: d,
        riderId: app.active!.id,
        photos: _photos,
      );
      if (!mounted) return;
      showCefToast(context, L.cmpSent(ref));
      app.back();
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.active;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.cmpReportProblem,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      footer: business == null
          ? null
          : CeffloPrimaryButton(
              L.cmpSend,
              pill: false,
              busy: _busy,
              onTap: _busy || _text.text.trim().isEmpty ? null : _send,
            ),
      body: business == null
          ? StateBlock.empty(L.cmpNoBusiness)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(L.cmpReportLead, style: context.t.bodyMedium),
                const SizedBox(height: Gap.lg),
                CeffloFieldLabel(L.cmpBusiness),
                const SizedBox(height: 6),
                Text(business.businessName ?? '', style: context.t.titleMedium),
                const SizedBox(height: Gap.lg),
                CeffloSelectField<String>(
                  label: L.cmpWhatHappened,
                  value: _cat,
                  options: _cats,
                  optionLabel: _category,
                  onChanged: (v) => setState(() => _cat = v),
                ),
                const SizedBox(height: Gap.lg),
                CeffloTextField(
                  label: L.cmpDescribe,
                  controller: _text,
                  hint: L.cmpDescribeHint,
                  maxLines: 5,
                ),
                const SizedBox(height: Gap.lg),
                _Photos(photos: _photos, onChanged: () => setState(() {})),
              ],
            ),
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.photos, required this.onChanged});
  final List<List<int>> photos;
  final VoidCallback onChanged;

  Future<void> _pick() async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
      limit: 5 - photos.length,
    );
    for (final f in files.take(5 - photos.length)) {
      photos.add(await f.readAsBytes());
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CeffloFieldLabel(L.cmpPhotos),
      const SizedBox(height: 6),
      Wrap(
        spacing: Gap.sm,
        runSpacing: Gap.sm,
        children: [
          for (var i = 0; i < photos.length; i++)
            InputChip(
              label: Text('${i + 1}'),
              avatar: const Icon(LucideIcons.image, size: 16),
              onDeleted: () {
                photos.removeAt(i);
                onChanged();
              },
            ),
          if (photos.length < 5)
            ActionChip(
              avatar: const Icon(LucideIcons.camera, size: 16),
              label: Text(L.cmpAddPhoto),
              onPressed: _pick,
            ),
        ],
      ),
    ],
  );
}
