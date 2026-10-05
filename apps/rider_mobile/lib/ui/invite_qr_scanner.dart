import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// Full-screen camera that returns the first QR code it reads (the business
/// invite link). Nothing is decided here: the caller validates the value
/// and the backend decides whether the invite is valid.
class InviteQrScanner extends StatefulWidget {
  const InviteQrScanner({super.key});

  @override
  State<InviteQrScanner> createState() => _InviteQrScannerState();
}

class _InviteQrScannerState extends State<InviteQrScanner> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final code in capture.barcodes) {
      final value = code.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        _done = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        // Square guide in the middle of the view.
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
                const SizedBox(width: Gap.sm),
                Text(
                  L.scanQrCode,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
