import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/env.dart';
import '../core/theme.dart';
import 'delivery_pin.dart';

/// Google Places suggestions under every address and area field
/// (Founder 2026-10-15/16). Same restricted key as the map tiles, so requests
/// carry the package + signing cert; without a key, or when Places refuses,
/// the field simply stays a plain text field.
const _package = 'com.cefflo.vendor';
const _certSha1 = 'B545297662DAAC96A6935870895AF1173732F099';

Map<String, String> get _headers => {
  'Content-Type': 'application/json',
  'X-Goog-Api-Key': Env.googleMapsApiKey,
  if (!kIsWeb) 'X-Android-Package': _package,
  if (!kIsWeb) 'X-Android-Cert': _certSha1,
};

typedef AddressSuggestion = ({
  String placeId,
  String text,
  String main,
  String? secondary,
});

/// Google Places suggestions for [query] in Malaysia. [regions] limits them
/// to areas (towns, neighbourhoods) for zone names. Throws on a refusal.
Future<List<AddressSuggestion>> placeSuggestions(
  String query,
  String language, {
  bool regions = false,
  String? session,
}) async {
  final res = await http.post(
    Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
    headers: _headers,
    body: jsonEncode({
      'input': query,
      'includedRegionCodes': ['my'],
      'languageCode': language,
      'includedPrimaryTypes': ?(regions ? ['(regions)'] : null),
      'sessionToken': ?session,
    }),
  );
  if (res.statusCode != 200) throw StateError('places ${res.statusCode}');
  return (jsonDecode(res.body)['suggestions'] as List? ?? const [])
      .map((s) => s['placePrediction'])
      .whereType<Map>()
      .map<AddressSuggestion>((p) {
        final f = p['structuredFormat'];
        final text = (p['text']?['text'] ?? '') as String;
        String? part(String key) =>
            f is Map && f[key] is Map ? f[key]['text'] as String? : null;
        return (
          placeId: p['placeId'] as String,
          text: text,
          main: part('mainText') ?? text,
          secondary: part('secondaryText'),
        );
      })
      .where((s) => s.text.isNotEmpty)
      .take(5)
      .toList();
}

/// The map point of a suggested place; null when Places can't say.
Future<PinPoint?> placeLocation(String placeId, {String? session}) async {
  try {
    final res = await http.get(
      Uri.parse(
        'https://places.googleapis.com/v1/places/$placeId'
        '${session == null ? '' : '?sessionToken=$session'}',
      ),
      headers: {..._headers, 'X-Goog-FieldMask': 'location'},
    );
    if (res.statusCode != 200) return null;
    final loc = jsonDecode(res.body)['location'];
    if (loc is! Map) return null;
    return (
      lat: (loc['latitude'] as num).toDouble(),
      lng: (loc['longitude'] as num).toDouble(),
    );
  } catch (e) {
    debugPrint('Place location unavailable: $e');
    return null;
  }
}

/// Lists suggestions for [controller]'s text and, on a pick, fills the field
/// and reports the place's map point through [onPicked].
class AddressSuggestions extends StatefulWidget {
  const AddressSuggestions({
    super.key,
    required this.controller,
    this.onPicked,
    this.regions = false,
  });
  final TextEditingController controller;
  final ValueChanged<PinPoint?>? onPicked;

  /// Areas only (towns, neighbourhoods), for area fields.
  final bool regions;

  @override
  State<AddressSuggestions> createState() => _AddressSuggestionsState();
}

class _AddressSuggestionsState extends State<AddressSuggestions> {
  Timer? _debounce;
  List<AddressSuggestion> _items = const [];
  String _last = '';
  // The text a pick just wrote, so it doesn't trigger a fresh lookup.
  String? _picked;
  String _session = _newSession();

  static String _newSession() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    final q = widget.controller.text.trim();
    if (q == _last) return;
    _last = q;
    _debounce?.cancel();
    if (q == _picked || q.length < 3 || Env.googleMapsApiKey.isEmpty) {
      if (_items.isNotEmpty) setState(() => _items = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetch(q));
  }

  Future<void> _fetch(String q) async {
    try {
      final list = await placeSuggestions(
        q,
        Localizations.localeOf(context).languageCode,
        regions: widget.regions,
        session: _session,
      );
      if (mounted && widget.controller.text.trim() == q) {
        setState(() => _items = list);
      }
    } catch (e) {
      debugPrint('Address suggestions unavailable: $e');
      if (mounted) setState(() => _items = const []);
    }
  }

  Future<void> _pick(AddressSuggestion s) async {
    _picked = s.text;
    widget.controller.text = s.text;
    widget.controller.selection = TextSelection.collapsed(
      offset: s.text.length,
    );
    setState(() => _items = const []);
    FocusScope.of(context).unfocus();
    final onPicked = widget.onPicked;
    if (onPicked == null) {
      _session = _newSession();
      return;
    }
    final point = await placeLocation(s.placeId, session: _session);
    _session = _newSession();
    onPicked(point);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            for (final (i, s) in _items.indexed) ...[
              if (i > 0) Divider(height: 1, color: c.border),
              InkWell(
                onTap: () => _pick(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 18,
                        color: c.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Google',
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
