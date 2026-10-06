import 'package:flutter/material.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// Non-web builds: the storefront preview runs in the web app only.
class StorefrontWebFrame extends StatelessWidget {
  const StorefrontWebFrame({
    super.key,
    required this.templateId,
    required this.payload,
    this.interactive = true,
    this.route = '',
  });

  final String templateId;
  final Map<String, dynamic> payload;
  final bool interactive;
  final String route;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF5F6F8),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(L.storefrontPreviewWebOnly, textAlign: TextAlign.center),
      ),
    ),
  );
}
