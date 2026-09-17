/// V-33 -- Customize storefront. Brand Color customization: a saturation
/// /brightness field, hue slider, HEX input, Color/Gradient toggle with an
/// optional secondary colour, and Reset to Template Default -- all driving
/// the live Storefront Preview immediately, before Save. Logo & tagline
/// editing is preserved from the previous Branding screen.
///
/// Accessible foreground colour is always computed automatically
/// (`accessibleForeground`) -- the vendor never picks text colour by hand.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_state.dart';
import '../../../core/theme.dart';
import '../../../data/storefront_config.dart';
import '../../widgets.dart';
import 'storefront_screens.dart';

class CustomizeStorefrontScreen extends StatefulWidget {
  const CustomizeStorefrontScreen({super.key});

  @override
  State<CustomizeStorefrontScreen> createState() => _CustomizeStorefrontScreenState();
}

class _CustomizeStorefrontScreenState extends State<CustomizeStorefrontScreen> {
  late StorefrontBranding draft;
  String tab = 'Preview';
  bool colorSheetOpen = false;
  final tagline = TextEditingController(text: 'A better delivery day. Today.');

  @override
  void initState() {
    super.initState();
    final app = AppScope.of(context);
    draft = app.storefrontBranding;
  }

  @override
  void dispose() {
    tagline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final template = app.selectedStorefrontTemplate;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.sm, Gap.gutter, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Brand identity for ${template.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: () async {
                    app.saveStorefrontBranding(draft);
                    await runAsyncFeedback(
                      context,
                      action: () async {},
                      processingTitle: 'Processing...',
                      processingSubtitle: 'Saving your storefront brand',
                      successTitle: 'Successful',
                      successSubtitle: 'Your storefront branding has been updated.',
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: CefColors.navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text('Publish', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
        SegmentedTabs(labels: const ['Preview', 'Settings'], active: tab, onChange: (v) => setState(() => tab = v)),
        Expanded(
          child: tab == 'Preview'
              ? Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: StorefrontCatalogueBoundPreview(template: template, branding: draft),
                    ),
                    if (colorSheetOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => setState(() => colorSheetOpen = false),
                          child: Container(color: Colors.black.withValues(alpha: .25)),
                        ),
                      ),
                    if (colorSheetOpen)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _BrandColorSheet(
                          initial: draft,
                          template: template,
                          onChanged: (b) => setState(() => draft = b),
                          onDone: () => setState(() => colorSheetOpen = false),
                        ),
                      ),
                  ],
                )
              : _SettingsTab(
                  draft: draft,
                  tagline: tagline,
                  onEditColor: () => setState(() {
                    tab = 'Preview';
                    colorSheetOpen = true;
                  }),
                ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.draft, required this.tagline, required this.onEditColor});
  final StorefrontBranding draft;
  final TextEditingController tagline;
  final VoidCallback onEditColor;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.md, Gap.gutter, Gap.section),
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: CefColors.navy,
                child: Text(
                  (app.business?.name ?? 'Kopi Kita').substring(0, 2).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              const Positioned(
                right: -2,
                bottom: 0,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Icon(LucideIcons.camera, size: 15, color: CefColors.navy),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.section),
        CefListRow(
          title: 'Brand Color',
          subtitle: draft.isGradient ? 'Gradient' : '#${draft.primary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
          icon: LucideIcons.palette,
          trailing: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: draft.isGradient ? null : draft.primary,
              gradient: draft.isGradient ? LinearGradient(colors: [draft.primary, draft.effectiveSecondary]) : null,
              shape: BoxShape.circle,
              border: Border.all(color: context.c.border),
            ),
          ),
          onTap: onEditColor,
        ),
        _TaglineRow(controller: tagline),
      ],
    );
  }
}

class _TaglineRow extends StatelessWidget {
  const _TaglineRow({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tagline', style: TextStyle(fontSize: 12.5, color: CefColors.navy, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDDE1EA)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          ),
        ),
      ],
    ),
  );
}

// --------------------------------------------------------- brand colour sheet

enum _Editing { primary, secondary }

class _BrandColorSheet extends StatefulWidget {
  const _BrandColorSheet({
    required this.initial,
    required this.template,
    required this.onChanged,
    required this.onDone,
  });

  final StorefrontBranding initial;
  final StorefrontTemplate template;
  final ValueChanged<StorefrontBranding> onChanged;
  final VoidCallback onDone;

  @override
  State<_BrandColorSheet> createState() => _BrandColorSheetState();
}

class _BrandColorSheetState extends State<_BrandColorSheet> {
  late BrandColorMode mode = widget.initial.mode;
  late Color primary = widget.initial.primary;
  late Color secondary = widget.initial.secondary ?? widget.initial.primary;
  _Editing editing = _Editing.primary;
  late final hexCtrl = TextEditingController(text: _hex(primary));

  Color get active => editing == _Editing.primary ? primary : secondary;
  set active(Color c) {
    setState(() {
      if (editing == _Editing.primary) {
        primary = c;
      } else {
        secondary = c;
      }
      hexCtrl.text = _hex(c);
    });
    _emit();
  }

  @override
  void dispose() {
    hexCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(
    StorefrontBranding(primary: primary, secondary: mode == BrandColorMode.gradient ? secondary : null, mode: mode),
  );

  String _hex(Color c) => '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(active);
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: const Color(0xFFE3E6EE), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text('Brand Color', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      primary = widget.template.defaultColor;
                      secondary = primary;
                      mode = BrandColorMode.solid;
                      hexCtrl.text = _hex(active);
                    });
                    _emit();
                  },
                  icon: const Icon(LucideIcons.rotateCcw, size: 14),
                  label: const Text('Reset', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
                IconButton(onPressed: widget.onDone, icon: const Icon(LucideIcons.x, size: 20)),
              ],
            ),
            SegmentedTabs(
              labels: const ['Color', 'Gradient'],
              active: mode == BrandColorMode.solid ? 'Color' : 'Gradient',
              onChange: (v) {
                setState(() => mode = v == 'Color' ? BrandColorMode.solid : BrandColorMode.gradient);
                _emit();
              },
            ),
            const SizedBox(height: 14),
            if (mode == BrandColorMode.gradient)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _swatchTab('Primary', primary, editing == _Editing.primary, () => setState(() {
                        editing = _Editing.primary;
                        hexCtrl.text = _hex(primary);
                      })),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _swatchTab('Secondary', secondary, editing == _Editing.secondary, () => setState(() {
                        editing = _Editing.secondary;
                        hexCtrl.text = _hex(secondary);
                      })),
                    ),
                  ],
                ),
              ),
            _SaturationValueField(
              hue: hsv.hue,
              saturation: hsv.saturation,
              value: hsv.value,
              onChanged: (s, v) => active = HSVColor.fromAHSV(1, hsv.hue, s, v).toColor(),
            ),
            const SizedBox(height: 14),
            _HueSlider(hue: hsv.hue, onChanged: (h) => active = HSVColor.fromAHSV(1, h, hsv.saturation, hsv.value).toColor()),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: active, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE3E6EE))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: hexCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8F9FB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDE1EA))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                    ),
                    onSubmitted: (raw) {
                      final parsed = _parseHex(raw);
                      if (parsed != null) active = parsed;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: widget.onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: CefColors.navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatchTab(String label, Color color, bool active, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? CefColors.navy : const Color(0xFFE3E6EE), width: active ? 1.6 : 1),
      ),
      child: Row(
        children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );

  Color? _parseHex(String raw) {
    var v = raw.trim();
    if (v.startsWith('#')) v = v.substring(1);
    if (v.length != 6) return null;
    final value = int.tryParse(v, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}

class _SaturationValueField extends StatelessWidget {
  const _SaturationValueField({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
        builder: (context, constraints) {
          void handle(Offset local) {
            final s = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
            final v = 1 - (local.dy / constraints.maxHeight).clamp(0.0, 1.0);
            onChanged(s, v);
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onPanDown: (d) => handle(d.localPosition),
              onPanUpdate: (d) => handle(d.localPosition),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: hueColor),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.white, Color(0x00FFFFFF)]),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Colors.black],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (saturation * constraints.maxWidth - 10).clamp(-10, constraints.maxWidth - 10),
                    top: ((1 - value) * constraints.maxHeight - 10).clamp(-10, constraints.maxHeight - 10),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hue, required this.onChanged});
  final double hue;
  final ValueChanged<double> onChanged;

  static const _stops = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      void handle(Offset local) {
        final h = (local.dx / constraints.maxWidth).clamp(0.0, 1.0) * 360;
        onChanged(h);
      }

      return SizedBox(
        height: 26,
        child: GestureDetector(
          onPanDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 14,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(colors: _stops),
                ),
              ),
              Positioned(
                left: (hue / 360 * constraints.maxWidth - 13).clamp(-13, constraints.maxWidth - 13),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
