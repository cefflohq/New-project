import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../async_view.dart';
import '../shell.dart' show PageBody;
import '../widgets.dart';
import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// Complaints (Prosedur Aduan, Founder 2026-10-16): reports this business
/// made, and reports about it that it can answer within 48 h. Cefflo decides
/// with both sides and the order's own records.

String cmpCategory(String? c) => switch (c) {
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

Widget _statusChip(Map<String, dynamic> c) => switch (c['status']) {
  'awaiting_reply' => StatusChip(L.cmpStatusAwaiting, warning: true),
  'in_review' => StatusChip(L.cmpStatusReview, info: true),
  _ => StatusChip(L.cmpStatusResolved, success: true),
};

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String _tab = '';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tabs = [L.cmpTabOpen, L.cmpTabResolved];
    final active = _tab.isEmpty ? tabs.first : _tab;
    return AsyncView<List<Map<String, dynamic>>>(
      key: ValueKey('complaints-${app.business?.id}'),
      load: app.repo.myComplaints,
      builder: (context, all, reload) {
        final resolved = active == L.cmpTabResolved;
        final list = all
            .where((c) => (c['status'] == 'resolved') == resolved)
            .toList();
        return PageBody(
          grouped: true,
          onRefresh: reload,
          children: [
            SegmentedTabs(
              labels: tabs,
              active: active,
              onChange: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: Gap.md),
            if (list.isEmpty)
              StateBlock.empty(L.cmpEmpty)
            else
              for (final c in list) ...[
                _ComplaintCard(
                  c: c,
                  onTap: () =>
                      app.go(VRoute.complaintDetail, entityId: c['id'] as String),
                ),
                const SizedBox(height: Gap.sm),
              ],
          ],
        );
      },
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.c, required this.onTap});
  final Map<String, dynamic> c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mine = c['side'] == 'complainant';
    final needsReply = !mine && c['status'] == 'awaiting_reply' && c['replied'] != true;
    return CefCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${c['ref']} · ${cmpCategory(c['category'] as String?)}',
                  style: text.titleSmall,
                ),
              ),
              _statusChip(c),
            ],
          ),
          const SizedBox(height: Gap.xs),
          Text(
            mine
                ? '${L.cmpYouReported} · ${c['rider_name'] ?? ''}'
                : '${L.cmpAboutYou} · ${_party(c['complainant_role'] as String?)}',
            style: text.bodySmall,
          ),
          if (needsReply) ...[
            const SizedBox(height: Gap.xs),
            Text(
              L.cmpReplyBy(_when(c['reply_due_at'] as String?)),
              style: text.bodySmall?.copyWith(color: context.c.attention),
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

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _reply = TextEditingController();
  final _photos = <({List<int> bytes, String type})>[];
  bool _busy = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send(VoidCallback reload) async {
    final body = _reply.text.trim();
    if (body.length < 5) {
      showCefToast(context, L.cmpTooShort, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await AppScope.read(context).repo.replyComplaint(
        widget.complaintId,
        body,
        photos: _photos,
      );
      if (!mounted) return;
      _reply.clear();
      _photos.clear();
      showCefToast(context, L.cmpReplySent);
      reload();
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    return AsyncView<List<Map<String, dynamic>>>(
      key: ValueKey('complaint-${widget.complaintId}'),
      load: app.repo.myComplaints,
      builder: (context, all, reload) {
        final c = all.where((x) => x['id'] == widget.complaintId).firstOrNull;
        if (c == null) return PageBody(children: [StateBlock.empty(L.cmpEmpty)]);
        final mine = c['side'] == 'complainant';
        final canReply = !mine && c['status'] != 'resolved';
        final entries = (c['entries'] as List? ?? const []).cast<Map>();
        String who(String? role) => switch (role) {
          'complainant' => mine ? L.cmpYourSide : L.cmpTheirSide,
          'respondent' => mine ? L.cmpTheirSide : L.cmpYourSide,
          _ => L.cmpCefflo,
        };
        return PageBody(
          grouped: true,
          onRefresh: reload,
          bottom: canReply
              ? CefButton(
                  L.cmpSendReply,
                  busy: _busy,
                  onTap: _busy ? null : () => _send(reload),
                )
              : null,
          children: [
            CefCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(c['ref'] as String, style: text.titleMedium)),
                      _statusChip(c),
                    ],
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(cmpCategory(c['category'] as String?), style: text.bodyMedium),
                  if (c['order_ref'] != null)
                    Text(L.cmpOrder(c['order_ref'] as String), style: text.bodySmall),
                  if (c['status'] == 'awaiting_reply')
                    Text(
                      L.cmpReplyBy(_when(c['reply_due_at'] as String?)),
                      style: text.bodySmall,
                    ),
                ],
              ),
            ),
            if (c['status'] == 'resolved') ...[
              const SizedBox(height: Gap.sm),
              CefCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L.cmpOutcome, style: text.titleSmall),
                    const SizedBox(height: Gap.xs),
                    Text(_decision(c['decision'] as String?), style: text.bodyMedium),
                    if ((c['decision_note'] as String?)?.isNotEmpty ?? false)
                      Text(c['decision_note'] as String, style: text.bodySmall),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Gap.sm),
            for (final e in entries) ...[
              CefCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${who(e['author_role'] as String?)} · ${_when(e['created_at'] as String?)}',
                      style: text.labelMedium,
                    ),
                    if (e['body'] != null) ...[
                      const SizedBox(height: Gap.xs),
                      Text(e['body'] as String, style: text.bodyMedium),
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
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Gap.sm),
            ],
            if (!mine && c['replied'] != true && c['status'] != 'resolved')
              Text(L.cmpNoReplyYet, style: text.bodySmall),
            if (canReply) ...[
              SectionHeading(L.cmpGiveYourSide, icon: LucideIcons.messageSquare),
              CefField(
                controller: _reply,
                hint: L.cmpReplyHint,
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: Gap.sm),
              _PhotoPicker(
                photos: _photos,
                onChanged: () => setState(() {}),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Up to 5 photos, picked from the gallery, shrunk before upload.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photos, required this.onChanged});
  final List<({List<int> bytes, String type})> photos;
  final VoidCallback onChanged;

  Future<void> _pick() async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
      limit: 5 - photos.length,
    );
    for (final f in files.take(5 - photos.length)) {
      photos.add((bytes: await f.readAsBytes(), type: 'image/jpeg'));
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L.cmpPhotos, style: text.labelMedium),
        const SizedBox(height: Gap.xs),
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
}

/// The report sheet: type, description and photos, from a driver's profile
/// (and from an order, with [orderId]).
Future<void> reportProblem(
  BuildContext context, {
  required String riderId,
  String? orderId,
}) async {
  final sent = await showCefSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Sizes.cardRadius)),
    ),
    builder: (sheet) => _ReportSheet(riderId: riderId, orderId: orderId),
  );
  if (sent != null && context.mounted) showCefToast(context, L.cmpSent(sent));
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.riderId, this.orderId});
  final String riderId;
  final String? orderId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _cats = ['damaged_lost', 'conduct', 'safety', 'fraud', 'other'];
  String _cat = _cats.first;
  final _text = TextEditingController();
  final _photos = <({List<int> bytes, String type})>[];
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final d = _text.text.trim();
    if (d.length < 10) {
      setState(() => _error = L.cmpTooShort);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final ref = await AppScope.read(context).repo.fileComplaint(
        category: _cat,
        description: d,
        riderId: widget.riderId,
        orderId: widget.orderId,
        photos: _photos,
      );
      if (mounted) Navigator.of(context).pop(ref);
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.xl,
        Gap.gutter,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(L.cmpReportProblem, style: text.titleMedium),
            const SizedBox(height: Gap.xs),
            Text(L.cmpReportLead, style: text.bodySmall),
            const SizedBox(height: Gap.md),
            Text(L.cmpWhatHappened, style: text.labelMedium),
            const SizedBox(height: Gap.xs),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final k in _cats)
                  CefChoiceChip(
                    label: cmpCategory(k),
                    selected: _cat == k,
                    onTap: () => setState(() => _cat = k),
                  ),
              ],
            ),
            const SizedBox(height: Gap.md),
            CefField(
              label: L.cmpDescribe,
              controller: _text,
              hint: L.cmpDescribeHint,
              minLines: 3,
              maxLines: 6,
              errorText: _error,
            ),
            const SizedBox(height: Gap.sm),
            _PhotoPicker(photos: _photos, onChanged: () => setState(() {})),
            const SizedBox(height: Gap.lg),
            CefButton(L.cmpSend, busy: _busy, onTap: _busy ? null : _send),
          ],
        ),
      ),
    );
  }
}
