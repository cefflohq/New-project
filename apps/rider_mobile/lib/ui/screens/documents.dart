import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/rider_repository.dart' show RepositoryError;
import '../widgets.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// D37 Documents, real build (Founder 2026-10-06): the Driver's identity —
/// typed MyKad IC number + a photo of their driving licence. Malaysia only.
/// One IC = one account (server-enforced); reviewed by Cefflo only, never by
/// a business (PDPA); kept while the account exists.
class LiveDocumentsScreen extends StatefulWidget {
  const LiveDocumentsScreen({super.key});

  @override
  State<LiveDocumentsScreen> createState() => _LiveDocumentsScreenState();
}

class _LiveDocumentsScreenState extends State<LiveDocumentsScreen> {
  Map<String, dynamic>? _licence;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final l = await AppScope.read(context).repo.myLicence();
      if (mounted) setState(() => _licence = l);
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final status = _licence?['status'] as String?;
    final (label, tone) = switch (status) {
      'verified' => (L.verified, ChipTone.success),
      'submitted' => (L.review, ChipTone.warning),
      'rejected' => (L.licenceRejected, ChipTone.attention),
      _ => (L.missing, ChipTone.neutral),
    };
    final canSubmit = status != 'verified' && status != 'submitted';
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.documents,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(Gap.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            CeffloCard(
              shadow: false,
              onTap: canSubmit ? () => _openSubmit(context) : null,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Icon(LucideIcons.idCard, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(L.drivingLicence, style: context.t.titleSmall),
                        Text(
                          _licence == null
                              ? L.licenceNeeded
                              : L.icEnding(_licence!['ic_last4'] as String),
                          style: context.t.bodySmall?.copyWith(
                            color: context.c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CeffloStatusChip(label, tone: tone),
                ],
              ),
            ),
            if (status == 'rejected' && _licence?['reject_reason'] != null) ...[
              const SizedBox(height: Gap.sm),
              CeffloNote(
                icon: LucideIcons.triangleAlert,
                tone: CeffloNoteTone.warning,
                body: _licence!['reject_reason'] as String,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Gap.sm),
              Text(_error!, style: TextStyle(color: context.c.attention)),
            ],
            const SizedBox(height: Gap.lg),
            CeffloNote(icon: LucideIcons.shieldCheck, body: L.licencePrivacy),
          ],
        ],
      ),
    );
  }

  Future<void> _openSubmit(BuildContext context) async {
    final sent = await showCeffloSheet<bool>(
      context,
      child: const _SubmitLicenceSheet(),
    );
    if (sent == true && mounted) {
      showCefToast(this.context, L.licenceSubmitted);
      _load();
    }
  }
}

class _SubmitLicenceSheet extends StatefulWidget {
  const _SubmitLicenceSheet();

  @override
  State<_SubmitLicenceSheet> createState() => _SubmitLicenceSheetState();
}

class _SubmitLicenceSheetState extends State<_SubmitLicenceSheet> {
  final _ic = TextEditingController();
  XFile? _photo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ic.dispose();
    super.dispose();
  }

  bool get _icValid =>
      RegExp(r'^\d{12}$').hasMatch(_ic.text.replaceAll(RegExp(r'\D'), ''));

  Future<void> _pick(ImageSource source) async {
    final p = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (p != null && mounted) setState(() => _photo = p);
  }

  Future<void> _submit() async {
    if (!_icValid) return setState(() => _error = L.icInvalid);
    if (_photo == null) return setState(() => _error = L.licencePhotoNeeded);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await _photo!.readAsBytes();
      final ext = _photo!.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      if (!mounted) return;
      await AppScope.read(context).repo
          .submitLicence(icNumber: _ic.text, photo: bytes, extension: ext);
      if (mounted) Navigator.of(context).pop(true);
    } on RepositoryError catch (e) {
      if (mounted) {
        setState(
          () => _error = e.message.contains('already registered')
              ? L.icAlreadyRegistered
              : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      Gap.gutter,
      0,
      Gap.gutter,
      Gap.lg + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetGrabber(),
        const SizedBox(height: 6),
        Center(child: Text(L.drivingLicence, style: context.t.titleLarge)),
        const SizedBox(height: Gap.lg),
        CeffloTextField(
          label: L.icNumber,
          controller: _ic,
          hint: '900101-14-5678',
          icon: LucideIcons.idCard,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: Gap.md),
        Text(L.licencePhoto, style: context.t.titleSmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CeffloSecondaryButton(
                _photo == null ? L.takePhoto : L.photoAdded,
                onTap: _busy ? null : () => _pick(ImageSource.camera),
              ),
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: CeffloSecondaryButton(
                L.chooseFromGallery,
                onTap: _busy ? null : () => _pick(ImageSource.gallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        Text(
          L.licencePhotoHint,
          style: context.t.bodySmall?.copyWith(color: context.c.textSecondary),
        ),
        if (_error != null) ...[
          const SizedBox(height: Gap.sm),
          Text(_error!, style: TextStyle(color: context.c.attention)),
        ],
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton(
          L.submitReview,
          busy: _busy,
          onTap: _busy ? null : _submit,
        ),
      ],
    ),
  );
}
