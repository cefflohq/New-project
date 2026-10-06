import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../../core/env.dart';

/// Web: an iframe of the public storefront in preview mode
/// (`?embed=1&template=`). It never calls the backend itself: once it says
/// it is ready, this posts the business's own `storefront_preview` payload
/// (with the vendor's unsaved customisation) to the storefront origin only.
class StorefrontWebFrame extends StatefulWidget {
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

  /// Optional start route inside the storefront, e.g. `p/<id>`, `all`.
  final String route;

  @override
  State<StorefrontWebFrame> createState() => _StorefrontWebFrameState();
}

class _StorefrontWebFrameState extends State<StorefrontWebFrame> {
  web.HTMLIFrameElement? _frame;
  JSFunction? _listener;
  bool _ready = false;

  String get _origin => Uri.parse(Env.storefrontBaseUrl).origin;

  String get _src {
    final base = Uri.parse(Env.storefrontBaseUrl).resolve('preview');
    final q = base.replace(
      queryParameters: {'embed': '1', 'template': widget.templateId},
    );
    return widget.route.isEmpty ? '$q' : '$q#/${widget.route}';
  }

  void _post() {
    final win = _frame?.contentWindow;
    if (win == null || !_ready) return;
    final message = jsonEncode({
      'type': 'cefflo-storefront-preview',
      'store': widget.payload,
    });
    win.postMessage((jsonDecode(message) as Object).jsify(), _origin.toJS);
  }

  @override
  void initState() {
    super.initState();
    _listener = ((web.MessageEvent e) {
      if (e.origin != _origin) return;
      if (_frame == null || e.source != _frame!.contentWindow) return;
      final data = e.data.dartify();
      if (data is Map && data['type'] == 'cefflo-storefront-ready') {
        _ready = true;
        _post();
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void didUpdateWidget(StorefrontWebFrame old) {
    super.didUpdateWidget(old);
    if (old.templateId != widget.templateId || old.route != widget.route) {
      _ready = false;
      _frame?.src = _src;
    } else if (!identical(old.payload, widget.payload)) {
      _post();
    }
    _frame?.style.pointerEvents = widget.interactive ? 'auto' : 'none';
  }

  @override
  void dispose() {
    if (_listener != null) {
      web.window.removeEventListener('message', _listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      final f = element as web.HTMLIFrameElement;
      _frame = f;
      f.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%'
        ..pointerEvents = widget.interactive ? 'auto' : 'none';
      f.title = 'Storefront preview';
      f.setAttribute('loading', 'lazy');
      f.src = _src;
    },
  );
}
