/// Country dial-code picker for phone fields (Founder 2026-10-16): every
/// phone field leads with a country flag; tapping it slides up a sheet
/// (Draft 1: search, then every country A–Z, the current one ticked).
/// Picking a country writes its dial code at the start of the number, so
/// the stored number is international.
library;

import 'package:flutter/material.dart';

part 'src/countries.dart';

final _leadingCode = RegExp(r'^\s*\+\d{1,4}\s*');

/// Brand tokens the sheet draws with; each app passes its own.
class PhonePickerStyle {
  const PhonePickerStyle({
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.selected,
    required this.accent,
    this.title = 'Country code',
    this.searchHint = 'Search country or code',
  });
  final Color surface, text, muted, border, selected, accent;
  final String title, searchHint;
}

Widget _flag(String iso, {double width = 24}) => ClipRRect(
  borderRadius: BorderRadius.circular(3),
  child: Image.asset(
    'flags/${iso.toLowerCase()}.png',
    package: 'country_code_picker',
    width: width,
    height: width * .7,
    fit: BoxFit.cover,
    errorBuilder: (c, e, s) => SizedBox(width: width, height: width * .7),
  ),
);

/// The flag + chevron button placed before a phone field's text.
class PhoneCountryButton extends StatefulWidget {
  const PhoneCountryButton({
    super.key,
    required this.controller,
    required this.style,
    this.enabled = true,
  });
  final TextEditingController controller;
  final PhonePickerStyle style;
  final bool enabled;

  @override
  State<PhoneCountryButton> createState() => _PhoneCountryButtonState();
}

class _PhoneCountryButtonState extends State<PhoneCountryButton> {
  String _iso = 'MY';

  @override
  void initState() {
    super.initState();
    final m = _leadingCode.firstMatch(widget.controller.text);
    if (m != null) {
      final dial = m.group(0)!.trim();
      // Several countries share +1 / +7: keep Malaysia unless it differs.
      if (dial != '+60') {
        _iso = _countries
            .firstWhere((c) => c.$3 == dial, orElse: () => ('', 'MY', ''))
            .$2;
      }
    }
  }

  Future<void> _open() async {
    final picked = await showModalBottomSheet<(String, String, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: widget.style.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CountrySheet(style: widget.style, current: _iso),
    );
    if (picked == null || !mounted) return;
    setState(() => _iso = picked.$2);
    final c = widget.controller;
    final rest = c.text.replaceFirst(_leadingCode, '').trimLeft();
    final text = '${picked.$3} ${rest.startsWith('0') ? rest.substring(1) : rest}';
    c.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: widget.enabled ? _open : null,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _flag(_iso, width: 22),
          Icon(Icons.expand_more, size: 18, color: widget.style.muted),
        ],
      ),
    ),
  );
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.style, required this.current});
  final PhonePickerStyle style;
  final String current;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final q = _q.trim().toLowerCase();
    final list = q.isEmpty
        ? _countries
        : _countries
              .where(
                (c) =>
                    c.$1.toLowerCase().contains(q) ||
                    c.$3.contains(q.replaceAll(' ', '')),
              )
              .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      minChildSize: .4,
      maxChildSize: .95,
      builder: (context, scroll) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: s.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: s.text,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: s.searchHint,
                prefixIcon: Icon(Icons.search, color: s.muted),
                isDense: true,
                filled: true,
                fillColor: s.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: s.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: s.border, width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final c = list[i];
                  final on = c.$2 == widget.current;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).pop(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 13,
                      ),
                      decoration: on
                          ? BoxDecoration(
                              color: s.selected,
                              borderRadius: BorderRadius.circular(14),
                            )
                          : null,
                      child: Row(
                        children: [
                          _flag(c.$2),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c.$1,
                              style: TextStyle(fontSize: 15, color: s.text),
                            ),
                          ),
                          Text(
                            c.$3,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: s.muted,
                            ),
                          ),
                          if (on) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check, size: 18, color: s.accent),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
