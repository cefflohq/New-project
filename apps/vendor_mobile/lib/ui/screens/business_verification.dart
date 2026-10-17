import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../async_view.dart';
import '../shell.dart' show PageBody;
import '../widgets.dart';
import 'id_capture.dart';
import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

typedef _Doc = ({List<int> bytes, String type});

/// Business verification (Founder 2026-10-17): the owner photographs both
/// sides of their IC with the camera (no gallery, so the photo is taken
/// now); the SSM certificate is optional and may come from files. Nothing
/// is typed: the server reads the name and IC number from the IC photo.
/// One white page, no grey ground.
class BusinessVerificationScreen extends StatefulWidget {
  const BusinessVerificationScreen({super.key});

  @override
  State<BusinessVerificationScreen> createState() =>
      _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState
    extends State<BusinessVerificationScreen> {
  _Doc? _front, _back, _ssm;
  String? _error;
  bool _busy = false;

  /// The IC camera with a card frame (no gallery: the photo is taken now).
  Future<_Doc?> _snap(String title) async {
    final bytes = await captureIdCard(context, title: title);
    return bytes == null ? null : (bytes: bytes, type: 'image/jpeg');
  }

  Future<_Doc?> _pickSsm() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (f == null) return null;
    final name = f.name.toLowerCase();
    return (
      bytes: await f.readAsBytes(),
      type: name.endsWith('.pdf')
          ? 'application/pdf'
          : name.endsWith('.png')
          ? 'image/png'
          : 'image/jpeg',
    );
  }

  Future<void> _submit(VoidCallback reload) async {
    if (_front == null || _back == null) {
      setState(() => _error = L.bvIcMissing);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    final app = AppScope.read(context);
    try {
      final r = await app.repo.submitBusinessVerification(
        businessId: app.business!.id,
        icFront: _front!,
        icBack: _back!,
        ssm: _ssm,
      );
      if (!mounted) return;
      final read = r['read'] == true;
      showCefToast(
        context,
        read
            ? L.bvReadResult('${r['owner_name']}', '${r['owner_ic_last4']}')
            : L.bvSent,
      );
      setState(() => _front = _back = _ssm = null);
      reload();
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final business = app.business;
    if (business == null || !business.isOwner) {
      return PageBody(children: [StateBlock.blocked(L.bvOwnerOnly)]);
    }
    return AsyncView<Map<String, dynamic>?>(
      key: ValueKey('bv-${business.id}'),
      // The prototype shows the empty form so it can be reviewed.
      load: () async =>
          app.repo.isDemo ? null : app.repo.businessVerification(business.id),
      builder: (context, v, reload) {
        final status = v?['status'] as String?;
        final canSubmit = status == null || status == 'rejected';
        final (label, body) = switch (status) {
          'pending' => (L.bvPending, L.bvPendingBody),
          'verified' => (L.bvVerified, L.bvVerifiedBody),
          'rejected' => (
            L.bvRejected,
            L.bvRejectedBecause((v?['reject_reason'] as String?) ?? ''),
          ),
          _ => (L.bvNone, L.bvLead),
        };
        final name = v?['owner_name'] as String?;
        final last4 = v?['owner_ic_last4'] as String?;
        return PageBody(
          bottom: canSubmit
              ? CefButton(
                  L.bvSubmit,
                  busy: _busy,
                  onTap: _busy ? null : () => _submit(reload),
                )
              : null,
          children: [
            Row(
              children: [
                Expanded(child: Text(L.bvTitle, style: text.titleLarge)),
                StatusChip(
                  label,
                  success: status == 'verified',
                  info: status == 'pending',
                  attention: status == 'rejected',
                  warning: status == null,
                ),
              ],
            ),
            const SizedBox(height: Gap.xs),
            Text(body, style: text.bodyMedium),
            if (name != null && last4 != null) ...[
              const SizedBox(height: Gap.xs),
              Text(L.bvReadResult(name, last4), style: text.bodySmall),
            ],
            if (canSubmit) ...[
              const SizedBox(height: Gap.lg),
              Text(L.bvAutoRead, style: text.bodySmall),
              const SizedBox(height: Gap.md),
              _DocTile(
                label: L.bvIcFront,
                icon: LucideIcons.idCard,
                doc: _front,
                action: _front == null ? L.bvSnap : L.bvRetake,
                onTap: () async {
                  final d = await _snap(L.bvIcFront);
                  if (d != null) setState(() => _front = d);
                },
              ),
              _DocTile(
                label: L.bvIcBack,
                icon: LucideIcons.idCard,
                doc: _back,
                action: _back == null ? L.bvSnap : L.bvRetake,
                onTap: () async {
                  final d = await _snap(L.bvIcBack);
                  if (d != null) setState(() => _back = d);
                },
              ),
              _DocTile(
                label: L.bvSsmOptional,
                icon: LucideIcons.fileText,
                doc: _ssm,
                action: _ssm == null ? L.bvAddFile : L.bvChosen,
                onTap: () async {
                  final d = await _pickSsm();
                  if (d != null) setState(() => _ssm = d);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: Gap.sm),
                Text(
                  _error!,
                  style: text.bodySmall?.copyWith(color: context.c.attention),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

/// One document: a thumbnail once taken (images), the action on the right.
class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.label,
    required this.icon,
    required this.doc,
    required this.action,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final _Doc? doc;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = doc;
    final image = d != null && d.type.startsWith('image/');
    return CefListRow(
      title: label,
      icon: d == null ? icon : null,
      leading: image
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                Uint8List.fromList(d.bytes),
                width: 44,
                height: 30,
                fit: BoxFit.cover,
              ),
            )
          : d != null
          ? const Icon(LucideIcons.circleCheck)
          : null,
      trailing: StatusChip(action, success: d != null, info: d == null),
      showChevron: false,
      onTap: onTap,
    );
  }
}
