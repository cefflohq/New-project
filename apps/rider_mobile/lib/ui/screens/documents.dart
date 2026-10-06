import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/rider_repository.dart' show RepositoryError;
import '../widgets.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// D37 Documents, real build: Marketplace Verification V1 (Founder
/// 2026-10-06). Needed ONLY for Find Jobs (independent marketplace);
/// Vendor-invited work never needs it. Steps: MyKad IC + driving licence
/// FRONT and BACK, then vehicle type + plate + ONE live camera photo. Screening (OCR)
/// runs on the server; Cefflo staff only see exceptions. Businesses never see
/// any of it. No face scan / biometrics.
class LiveDocumentsScreen extends StatefulWidget {
  const LiveDocumentsScreen({super.key});

  @override
  State<LiveDocumentsScreen> createState() => _LiveDocumentsScreenState();
}

class _LiveDocumentsScreenState extends State<LiveDocumentsScreen> {
  Map<String, dynamic>? _v;
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
      final v = await AppScope.read(context).repo.myMarketplaceVerification();
      if (mounted) setState(() => _v = v);
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final v = _v ?? const {};
    final status = v['status'] as String? ?? 'not_started';
    final retake = v['retake'] as String?;
    final locked = status == 'verified' || status == 'rejected';
    final (label, tone) = switch (status) {
      'verified' => (L.verified, ChipTone.success),
      'pending' => (L.mvChecking, ChipTone.warning),
      'needs_review' => (L.review, ChipTone.warning),
      'rejected' => (L.licenceRejected, ChipTone.attention),
      _ => (L.missing, ChipTone.neutral),
    };
    Widget step(
      IconData icon,
      String title,
      String sub,
      bool done,
      bool redo,
      VoidCallback onTap,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: CeffloCard(
        shadow: false,
        onTap: locked ? null : onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.t.titleSmall),
                  Text(
                    sub,
                    style: context.t.bodySmall?.copyWith(
                      color: context.c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            CeffloStatusChip(
              redo ? L.mvRetake : (done ? L.photoAdded : L.missing),
              tone: redo
                  ? ChipTone.attention
                  : (done ? ChipTone.success : ChipTone.neutral),
            ),
          ],
        ),
      ),
    );
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
            Row(
              children: [
                Expanded(child: Text(L.mvTitle, style: context.t.titleMedium)),
                CeffloStatusChip(label, tone: tone),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              switch (status) {
                'verified' => L.mvVerifiedBody,
                'pending' => L.mvPendingBody,
                'needs_review' => L.mvReviewBody,
                'rejected' => L.mvRejectedBody,
                _ => retake != null ? L.mvRetakeBody : L.mvIntro,
              },
              style: context.t.bodySmall?.copyWith(
                color: context.c.textSecondary,
              ),
            ),
            const SizedBox(height: Gap.md),
            step(
              LucideIcons.idCard,
              L.drivingLicence,
              v['ic_last4'] == null
                  ? L.mvLicenceSub
                  : L.icEnding(v['ic_last4'] as String),
              v['licence_submitted'] == true,
              retake == 'licence',
              () => _open(const _SubmitLicenceSheet()),
            ),
            step(
              LucideIcons.car,
              L.mvVehicle,
              v['vehicle_plate'] == null
                  ? L.mvVehicleSub
                  : '${v['vehicle_plate']}',
              v['vehicle_submitted'] == true,
              retake == 'vehicle',
              () => _open(
                _SubmitVehicleSheet(
                  type: v['vehicle_type'] as String?,
                  plate: v['vehicle_plate'] as String?,
                ),
              ),
            ),
            if (status == 'pending') ...[
              const SizedBox(height: Gap.xs),
              CeffloSecondaryButton(L.mvCheckAgain, onTap: _screen),
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

  Future<void> _screen() async {
    setState(() => _loading = true);
    await AppScope.read(context).repo.requestMarketplaceScreening();
    if (mounted) await _load();
  }

  Future<void> _open(Widget sheet) async {
    final sent = await showCeffloSheet<bool>(context, child: sheet);
    if (sent == true && mounted) {
      showCefToast(context, L.licenceSubmitted);
      await _screen();
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
  XFile? _front, _back;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ic.dispose();
    super.dispose();
  }

  bool get _icValid =>
      RegExp(r'^\d{12}$').hasMatch(_ic.text.replaceAll(RegExp(r'\D'), ''));

  /// Marketplace evidence must be freshly captured: camera only.
  Future<void> _capture(bool front) async {
    final p = await liveCapture();
    if (p != null && mounted) {
      setState(() => front ? _front = p : _back = p);
    }
  }

  Future<void> _submit() async {
    if (!_icValid) return setState(() => _error = L.icInvalid);
    if (_front == null || _back == null) {
      return setState(() => _error = L.licencePhotoNeeded);
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final front = await _front!.readAsBytes();
      final back = await _back!.readAsBytes();
      if (!mounted) return;
      await AppScope.read(context).repo
          .submitLicence(icNumber: _ic.text, front: front, back: back);
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

  Widget _side(String label, String take, XFile? photo, bool front) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: context.t.titleSmall),
      const SizedBox(height: 6),
      CeffloSecondaryButton(
        photo == null ? take : L.mvRetakePhoto(label),
        onTap: _busy ? null : () => _capture(front),
      ),
      if (photo != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            L.photoAdded,
            style: context.t.bodySmall?.copyWith(color: context.c.success),
          ),
        ),
    ],
  );

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
        _side(L.licenceFront, L.takeFrontPhoto, _front, true),
        const SizedBox(height: Gap.md),
        _side(L.licenceBack, L.takeBackPhoto, _back, false),
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
          L.continueLabel,
          busy: _busy,
          onTap: _busy || _front == null || _back == null ? null : _submit,
        ),
      ],
    ),
  );
}

/// Live camera capture only (Marketplace Verification evidence): never the
/// gallery, files or an existing image. Rear camera.
Future<XFile?> liveCapture() => ImagePicker().pickImage(
  source: ImageSource.camera,
  preferredCameraDevice: CameraDevice.rear,
  maxWidth: 2000,
  imageQuality: 85,
);

/// Vehicle type + declared plate + ONE live photo (camera only, no gallery).
/// Cefflo does not verify ownership; it checks the plate in the photo
/// matches the declared plate.
class _SubmitVehicleSheet extends StatefulWidget {
  const _SubmitVehicleSheet({this.type, this.plate});
  final String? type, plate;

  @override
  State<_SubmitVehicleSheet> createState() => _SubmitVehicleSheetState();
}

class _SubmitVehicleSheetState extends State<_SubmitVehicleSheet> {
  late String _type = widget.type ?? 'motorcycle';
  late final _plate = TextEditingController(text: widget.plate ?? '');
  XFile? _photo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final p = await liveCapture();
    if (p != null && mounted) setState(() => _photo = p);
  }

  Future<void> _submit() async {
    final plate = _plate.text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    if (!RegExp(r'^[A-Z]{1,4}[0-9]{1,4}[A-Z]{0,3}$').hasMatch(plate)) {
      return setState(() => _error = L.mvPlateInvalid);
    }
    if (_photo == null) return setState(() => _error = L.mvVehiclePhotoNeeded);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await _photo!.readAsBytes();
      if (!mounted) return;
      await AppScope.read(context).repo.submitMarketplaceVehicle(
        vehicleType: _type,
        plate: plate,
        photo: bytes,
        extension: 'jpg',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
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
        Center(child: Text(L.mvVehicle, style: context.t.titleLarge)),
        const SizedBox(height: Gap.lg),
        CeffloSelectField<String>(
          label: L.vehicleType,
          value: _type,
          options: const ['motorcycle', 'car', 'van'],
          optionLabel: (t) => switch (t) {
            'car' => L.car,
            'van' => L.van,
            _ => L.motorbike,
          },
          onChanged: (t) => setState(() => _type = t),
        ),
        const SizedBox(height: Gap.md),
        CeffloTextField(
          label: L.mvPlate,
          controller: _plate,
          hint: 'VAB 1234',
          icon: LucideIcons.rectangleHorizontal,
        ),
        const SizedBox(height: Gap.md),
        CeffloSecondaryButton(
          _photo == null ? L.takePhoto : L.mvRetakePhoto(L.mvVehicle),
          onTap: _busy ? null : _capture,
        ),
        const SizedBox(height: Gap.sm),
        Text(
          L.mvVehiclePhotoHint,
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
