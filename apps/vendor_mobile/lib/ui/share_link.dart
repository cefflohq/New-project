import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import 'widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// One permanent, shareable link (invite links, the public storefront):
/// the link once, grey Copy and QR icons beside it, and one Share action
/// that opens every target in a centred pop-up (Founder, 2026-10-01).
class PermanentLinkSection extends StatelessWidget {
  const PermanentLinkSection({
    super.key,
    required this.title,
    required this.link,
    required this.shareLabel,
    required this.shareText,
    required this.qrTitle,
    required this.qrBody,
  });
  final String title, link, shareLabel, qrTitle, qrBody;

  /// The message without the link; the link is appended on its own line.
  final String shareText;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: text.titleSmall),
        const SizedBox(height: Gap.sm),
        Container(
          padding: const EdgeInsets.only(left: Gap.md),
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(Sizes.inputRadius),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.link, size: 20, color: c.textSecondary),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  link,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ),
              IconButton(
                tooltip: L.copyLink,
                onPressed: () => copyLink(context, link),
                icon: Icon(LucideIcons.copy, size: 20, color: c.textSecondary),
              ),
              IconButton(
                tooltip: L.showQrCode,
                onPressed: () =>
                    showLinkQr(context, link, title: qrTitle, body: qrBody),
                icon: Icon(
                  LucideIcons.qrCode,
                  size: 20,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.xl),
        CefButton(
          shareLabel,
          icon: LucideIcons.share2,
          onTap: () => showShareTargets(context, link: link, text: shareText),
        ),
      ],
    );
  }
}

void copyLink(BuildContext context, String link) {
  Clipboard.setData(ClipboardData(text: link));
  showCefToast(context, L.linkCopied);
}

/// Compact, centred pop-up: the QR of the same link. The link itself is
/// not repeated -- it is already on the screen behind.
void showLinkQr(
  BuildContext context,
  String link, {
  required String title,
  required String body,
}) {
  final text = Theme.of(context).textTheme;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: context.c.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: Gap.xxxl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Gap.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: text.titleMedium),
            const SizedBox(height: Gap.xs),
            Text(body, textAlign: TextAlign.center, style: text.bodySmall),
            const SizedBox(height: Gap.lg),
            QrCodeView(data: link, size: 220),
            const SizedBox(height: Gap.lg),
            CefButton(
              L.done,
              secondary: true,
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _open(BuildContext context, String target, Uri uri) async {
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!opened && context.mounted) {
    showCefToast(context, L.couldNotOpen(target), error: true);
  }
}

/// Every share target in one centred pop-up, official brand marks on their
/// official colours. Instagram and TikTok have no web share link for text:
/// the message is copied and the app's inbox opens to paste it.
void showShareTargets(
  BuildContext context, {
  required String link,
  required String text,
}) {
  final c = context.c;
  final styles = Theme.of(context).textTheme;
  final message = '$text\n$link';
  final encodedMessage = Uri.encodeComponent(message);
  final encodedLink = Uri.encodeComponent(link);
  Future<void> pasteIn(String app, Uri inbox) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (context.mounted) showCefToast(context, L.messageCopiedPasteIn(app));
    if (context.mounted) await _open(context, app, inbox);
  }

  Future<void> systemShare() async {
    try {
      await SharePlus.instance.share(ShareParams(text: message));
    } catch (_) {
      if (context.mounted) copyLink(context, link);
    }
  }

  final targets = <(Widget, String, VoidCallback)>[
    (
      BrandTile(const Color(0xFF25D366), FontAwesomeIcons.whatsapp),
      'WhatsApp',
      () => _open(
        context,
        'WhatsApp',
        Uri.parse('https://wa.me/?text=$encodedMessage'),
      ),
    ),
    (
      BrandTile(const Color(0xFF229ED9), FontAwesomeIcons.telegram),
      'Telegram',
      () => _open(
        context,
        'Telegram',
        Uri.parse(
          'https://t.me/share/url?url=$encodedLink'
          '&text=${Uri.encodeComponent(text)}',
        ),
      ),
    ),
    (
      BrandTile(const Color(0xFF0084FF), FontAwesomeIcons.facebookMessenger),
      'Messenger',
      () => _open(
        context,
        'Messenger',
        Uri.parse('fb-messenger://share/?link=$encodedLink'),
      ),
    ),
    (
      BrandTile(const Color(0xFF1877F2), FontAwesomeIcons.facebook),
      'Facebook',
      () => _open(
        context,
        'Facebook',
        Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$encodedLink'),
      ),
    ),
    (
      BrandTile(const Color(0xFF000000), FontAwesomeIcons.threads),
      'Threads',
      () => _open(
        context,
        'Threads',
        Uri.parse('https://www.threads.net/intent/post?text=$encodedMessage'),
      ),
    ),
    (
      const BrandTile.instagram(),
      'Instagram',
      () => pasteIn(
        'Instagram',
        Uri.parse('https://www.instagram.com/direct/inbox/'),
      ),
    ),
    (
      BrandTile(const Color(0xFF000000), FontAwesomeIcons.tiktok),
      'TikTok',
      () => pasteIn('TikTok', Uri.parse('https://www.tiktok.com/messages')),
    ),
    (
      BrandTile.icon(const Color(0xFF34C759), LucideIcons.messageSquareText),
      'SMS',
      () => _open(context, 'SMS', Uri.parse('sms:?body=$encodedMessage')),
    ),
    (
      BrandTile.icon(c.subtle, LucideIcons.ellipsis, glyph: c.textPrimary),
      L.moreText,
      systemShare,
    ),
  ];
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: c.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: Gap.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L.shareVia, style: styles.titleMedium),
            const SizedBox(height: Gap.lg),
            LayoutBuilder(
              builder: (context, box) => Wrap(
                runSpacing: Gap.md,
                children: [
                  for (final (icon, label, onTap) in targets)
                    SizedBox(
                      width: box.maxWidth / 5,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Sizes.cardRadius),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          onTap();
                        },
                        child: Column(
                          children: [
                            icon,
                            const SizedBox(height: Gap.xs),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: styles.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Gap.sm),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(L.cancel),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A scannable QR code for [data], painted module by module in the text
/// colour on white with the standard quiet zone.
class QrCodeView extends StatelessWidget {
  const QrCodeView({super.key, required this.data, required this.size});
  final String data;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: QrPainter(
        QrImage(
          QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
        ),
        context.c.textPrimary,
      ),
    ),
  );
}

class QrPainter extends CustomPainter {
  QrPainter(this.image, this.color);
  final QrImage image;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const quiet = 2; // modules of white border
    final count = image.moduleCount;
    final cell = size.width / (count + quiet * 2);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final paint = Paint()..color = color;
    for (var y = 0; y < count; y++) {
      for (var x = 0; x < count; x++) {
        if (!image.isDark(y, x)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (x + quiet) * cell,
            (y + quiet) * cell,
            cell + .5,
            cell + .5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(QrPainter old) => old.image != image || old.color != color;
}

/// An official share-target mark: the brand glyph in white on the brand's
/// own colour (Instagram on its gradient), app-icon shaped.
class BrandTile extends StatelessWidget {
  const BrandTile(this.color, this.fa, {super.key})
    : icon = null,
      glyph = Colors.white,
      gradient = null;
  const BrandTile.icon(
    this.color,
    this.icon, {
    super.key,
    this.glyph = Colors.white,
  }) : fa = null,
       gradient = null;
  const BrandTile.instagram({super.key})
    : color = null,
      fa = FontAwesomeIcons.instagram,
      icon = null,
      glyph = Colors.white,
      gradient = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFFFEDA75),
          Color(0xFFFA7E1E),
          Color(0xFFD62976),
          Color(0xFF962FBF),
          Color(0xFF4F5BD5),
        ],
      );

  final Color? color;
  final FaIconData? fa;
  final IconData? icon;
  final Color glyph;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: color,
      gradient: gradient,
      borderRadius: BorderRadius.circular(14),
    ),
    alignment: Alignment.center,
    child: fa != null
        ? FaIcon(fa, size: 24, color: glyph)
        : Icon(icon, size: 24, color: glyph),
  );
}
