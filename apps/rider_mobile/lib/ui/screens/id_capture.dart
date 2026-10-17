import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../widgets.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// ID card camera (Founder 2026-10-17): a card-shaped frame over the live
/// camera, with light and position tips, so the IC is straight, close and
/// readable. Only the part inside the frame is kept. Returns JPEG bytes, or
/// null when cancelled.
///
/// On phones the card is found live (ML Kit text recognition, on device):
/// the frame turns blue when the card's printed text sits inside it, the
/// phone vibrates when a card is seen but not inside the frame, and the
/// photo is taken by itself after the card has stayed in place for about a
/// second. On the web there is no live detection, so the shutter shows.
Future<Uint8List?> captureIdCard(
  BuildContext context, {
  required String title,
}) => Navigator.of(context).push<Uint8List>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _IdCaptureScreen(title: title),
  ),
);

/// ID-1 card (MyKad, licence): 85.6 × 54 mm.
const _cardRatio = 85.6 / 54;

/// The frame spans this share of the preview width.
const _frameWidth = 0.88;

class _IdCaptureScreen extends StatefulWidget {
  const _IdCaptureScreen({required this.title});
  final String title;

  @override
  State<_IdCaptureScreen> createState() => _IdCaptureScreenState();
}

class _IdCaptureScreenState extends State<_IdCaptureScreen> {
  CameraController? _cam;
  String? _error;
  Uint8List? _shot;
  bool _busy = false;

  // Live detection (phones only).
  final _ocr = kIsWeb
      ? null
      : TextRecognizer(script: TextRecognitionScript.latin);
  bool _scanning = false;
  bool _inFrame = false;
  int _steady = 0;
  DateTime _lastBuzz = DateTime(0), _lastScan = DateTime(0);
  bool get _auto => !kIsWeb;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: kIsWeb ? null : ImageFormatGroup.nv21,
      );
      await c.initialize();
      await c.setFlashMode(FlashMode.off).catchError((_) {});
      if (_auto) {
        await c.startImageStream((f) => _detect(f, back.sensorOrientation));
      }
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _cam = c);
    } catch (_) {
      if (mounted) setState(() => _error = L.idCamUnavailable);
    }
  }

  @override
  void dispose() {
    _cam?.dispose();
    _ocr?.close();
    super.dispose();
  }

  /// Looks at a camera frame about three times a second: where is the
  /// card's printed text, and is all of it inside the frame?
  Future<void> _detect(CameraImage f, int sensorDegrees) async {
    final ocr = _ocr;
    if (ocr == null || _scanning || _shot != null || _busy) return;
    if (DateTime.now().difference(_lastScan).inMilliseconds < 300) return;
    _scanning = true;
    _lastScan = DateTime.now();
    try {
      final rotation =
          InputImageRotationValue.fromRawValue(sensorDegrees) ??
          InputImageRotation.rotation90deg;
      final input = InputImage.fromBytes(
        bytes: f.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(f.width.toDouble(), f.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: f.planes.first.bytesPerRow,
        ),
      );
      final text = await ocr.processImage(input);
      // Boxes come back in the upright image; portrait swaps the sides.
      final sideways =
          rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      final w = (sideways ? f.height : f.width).toDouble();
      final h = (sideways ? f.width : f.height).toDouble();
      final state = _frameState(text, w, h);
      if (!mounted) return;
      if (state == _Fit.inside) {
        _steady++;
        if (!_inFrame) setState(() => _inFrame = true);
        if (_steady >= 3) _take();
      } else {
        _steady = 0;
        if (_inFrame) setState(() => _inFrame = false);
        if (state == _Fit.outside &&
            DateTime.now().difference(_lastBuzz).inMilliseconds > 1200) {
          _lastBuzz = DateTime.now();
          HapticFeedback.heavyImpact();
        }
      }
    } catch (_) {
      // A dropped frame is fine; the next one is checked.
    } finally {
      _scanning = false;
    }
  }

  /// Inside: the card's text sits within the frame and fills enough of it
  /// (close enough to read). Outside: text is seen but crosses the frame or
  /// is too small. None: no card in view.
  static _Fit _frameState(RecognizedText text, double w, double h) {
    final fw = w * _frameWidth, fh = fw / _cardRatio;
    final frame = Rect.fromCenter(
      center: Offset(w / 2, h / 2),
      width: fw,
      height: fh,
    );
    final blocks = text.blocks.where((b) => b.text.trim().length >= 3).toList();
    if (blocks.isEmpty) return _Fit.none;
    // The card's text: blocks near the frame (ignore far background).
    final near = blocks
        .where((b) => frame.inflate(fw * 0.25).contains(b.boundingBox.center))
        .toList();
    if (near.isEmpty) return _Fit.outside;
    final union = near
        .map((b) => b.boundingBox)
        .reduce((a, b) => a.expandToInclude(b));
    final margin = fw * 0.02;
    final inside =
        frame.inflate(margin).contains(union.topLeft) &&
        frame.inflate(margin).contains(union.bottomRight);
    final bigEnough = union.width >= fw * 0.5;
    return inside && bigEnough ? _Fit.inside : _Fit.outside;
  }

  Future<void> _take() async {
    final c = _cam;
    if (c == null || _busy || _shot != null) return;
    setState(() => _busy = true);
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
      if (_auto) HapticFeedback.mediumImpact();
      final file = await c.takePicture();
      final raw = await file.readAsBytes();
      final cropped = await Future(() => _cropToFrame(raw));
      if (mounted) setState(() => _shot = cropped);
    } catch (_) {
      if (mounted) showCefToast(context, L.idCamFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Keeps the frame's area (same proportions as on screen) as JPEG.
  static Uint8List _cropToFrame(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;
    final photo = img.bakeOrientation(decoded);
    final w = (photo.width * _frameWidth).round();
    final h = (w / _cardRatio).round().clamp(1, photo.height);
    final x = ((photo.width - w) / 2).round();
    final y = ((photo.height - h) / 2).round();
    final card = img.copyCrop(photo, x: x, y: y, width: w, height: h);
    return Uint8List.fromList(img.encodeJpg(card, quality: 88));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = _cam;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _shot != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Gap.gutter),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_shot!),
                        ),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: text.bodyMedium?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : c == null
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: AspectRatio(
                        aspectRatio: 1 / c.value.aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(c),
                            CustomPaint(
                              painter: _FramePainter(ready: _inFrame),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.gutter,
                Gap.md,
                Gap.gutter,
                24,
              ),
              child: _shot != null
                  ? Column(
                      children: [
                        Text(
                          L.idCamCheck,
                          style: text.bodyMedium?.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Gap.md),
                        CeffloPrimaryButton(
                          L.idCamUse,
                          pill: false,
                          onTap: () => Navigator.of(context).pop(_shot),
                        ),
                        const SizedBox(height: Gap.sm),
                        TextButton(
                          onPressed: () async {
                            setState(() {
                              _shot = null;
                              _inFrame = false;
                              _steady = 0;
                            });
                            final cam = _cam;
                            if (_auto &&
                                cam != null &&
                                !cam.value.isStreamingImages) {
                              await cam.startImageStream(
                                (f) => _detect(
                                  f,
                                  cam.description.sensorOrientation,
                                ),
                              );
                            }
                          },
                          child: Text(
                            L.idCamRetake,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        for (final (icon, tip) in [
                          (LucideIcons.scan, L.idCamTipFrame),
                          (LucideIcons.sun, L.idCamTipLight),
                          (LucideIcons.sparkles, L.idCamTipGlare),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(icon, size: 18, color: Colors.white70),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: text.bodySmall?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: Gap.sm),
                        if (_auto)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _inFrame ? _blue : Colors.white12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _busy
                                  ? L.idCamTaking
                                  : _inFrame
                                  ? L.idCamHold
                                  : L.idCamFindCard,
                              style: text.titleSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          CeffloPrimaryButton(
                            L.idCamSnap,
                            pill: false,
                            busy: _busy,
                            onTap: c == null || _busy ? null : _take,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Fit { none, outside, inside }

const _blue = Color(0xFF0060FE);

/// Darkens everything outside an ID-card-shaped window with rounded corners.
/// Mustard while looking for the card; blue once it is inside the frame.
class _FramePainter extends CustomPainter {
  const _FramePainter({this.ready = false});
  final bool ready;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * _frameWidth;
    final h = w / _cardRatio;
    final card = RRect.fromRectAndRadius(
      Rect.fromCenter(center: size.center(Offset.zero), width: w, height: h),
      const Radius.circular(14),
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(card),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeWidth = ready ? 4 : 3
        ..color = ready ? _blue : const Color(0xFFFFC93C),
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.ready != ready;
}
