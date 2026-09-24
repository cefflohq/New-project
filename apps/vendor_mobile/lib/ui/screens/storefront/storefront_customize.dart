/// V-33 -- Customize. The vendor customizes the chosen template -- never
/// its layout. Controls are rendered from the template's declared
/// capabilities (`StorefrontTemplateDef.capabilities`), so a template only
/// ever shows the controls it really supports. Every change updates the
/// live preview immediately but stays a DRAFT: nothing reaches the live
/// storefront until Save, which applies template + customization together.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_state.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/storefront_config.dart';
import '../../system_bars.dart';
import '../../widgets.dart';
import 'shared/storefront_surface.dart';
import 'shared/template_definition.dart';
import 'storefront_screens.dart';
import 'templates/template_registry.dart';

/// Brand colour swatches offered after the template's own colour.
const _brandSwatches = [
  Color(0xFF17233D),
  Color(0xFFC8303A),
  Color(0xFF15A66E),
  Color(0xFF2A6EEC),
  Color(0xFF7A4A21),
  Color(0xFF4C6B52),
  Color(0xFF14171C),
];

class CustomizeStorefrontScreen extends StatefulWidget {
  const CustomizeStorefrontScreen({super.key, this.templateId});

  /// The template being customized; the live one when null.
  final String? templateId;

  @override
  State<CustomizeStorefrontScreen> createState() =>
      _CustomizeStorefrontScreenState();
}

class _CustomizeStorefrontScreenState extends State<CustomizeStorefrontScreen> {
  late final StorefrontTemplateDef def;
  late final StorefrontBranding saved;
  late StorefrontBranding draft;
  late final storeNameCtrl = TextEditingController(text: draft.storeName);
  late final taglineCtrl = TextEditingController(text: draft.tagline);

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    def = storefrontTemplateById(
      widget.templateId ?? app.activeStorefrontTemplateId,
    );
    saved = storefrontBrandingFor(app, def);
    draft = saved;
  }

  @override
  void dispose() {
    storeNameCtrl.dispose();
    taglineCtrl.dispose();
    super.dispose();
  }

  bool get _switching =>
      def.id != AppScope.read(context).activeStorefrontTemplateId;

  /// Whether the vendor changed anything here (every edit replaces
  /// [draft], so identity is enough).
  bool get _edited => !identical(draft, saved);

  /// Save is meaningful when switching template or after an edit.
  bool get _canSave => _switching || _edited;

  void _update(StorefrontBranding next) => setState(() => draft = next);

  Future<void> _leave() async {
    final app = AppScope.of(context);
    if (!_edited) {
      app.back();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your storefront stays as it is. Changes you made here are not saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true) app.back();
  }

  Future<void> _save() async {
    final app = AppScope.of(context);
    final switching = _switching;
    final ok = await runAsyncFeedback(
      context,
      action: () async => app.applyStorefront(def.id, draft),
      processingTitle: 'Saving...',
      processingSubtitle: 'Updating your storefront',
      successTitle: switching ? '${def.name} is live' : 'Storefront updated',
      successSubtitle: switching
          ? 'Your products now show in the ${def.name} layout.'
          : 'Customers now see your changes.',
    );
    if (ok && mounted) app.backTo(VRoute.storefront);
  }

  void _reset() {
    final defaults = def.defaults.copyWith(
      storeName: AppScope.read(context).business?.name ?? draft.storeName,
    );
    storeNameCtrl.text = defaults.storeName;
    taglineCtrl.text = defaults.tagline;
    _update(defaults);
  }

  Future<void> _pickColour({
    required Color initial,
    required ValueChanged<Color> onPicked,
  }) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) =>
        _ColorPickerSheet(initial: initial, onPicked: onPicked),
  );

  Future<void> _pickHeroImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) _update(draft.copyWith(heroImage: bytes));
    } catch (_) {
      if (mounted) {
        showCefToast(context, "Couldn't open your photos. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final c = context.c;
    final text = Theme.of(context).textTheme;
    final stage = (media.size.height * .42).clamp(300.0, 420.0);
    return CefSystemBars(
      background: Brightness.light,
      child: ColoredBox(
        color: c.card,
        child: Column(
          children: [
            // Live preview of the draft, always in view while editing.
            Container(
              height: stage + media.padding.top,
              color: c.subtle,
              padding: EdgeInsets.only(top: media.padding.top),
              child: Stack(
                children: [
                  Positioned.fill(
                    top: Sizes.header + Gap.xs,
                    bottom: Gap.lg,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio:
                            kStorefrontViewport.width /
                            kStorefrontViewport.height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .14),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: StorefrontCatalogueLoader(
                              builder: (context, catalogue) =>
                                  StorefrontMiniature(
                                    def: def,
                                    branding: draft,
                                    catalogue: catalogue,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: (Sizes.header - Sizes.tapTarget) / 2,
                    left: Gap.lg,
                    right: Gap.lg,
                    child: Row(
                      children: [
                        StorefrontOverlayButton(
                          icon: LucideIcons.arrowLeft,
                          tooltip: 'Back',
                          light: false,
                          onTap: _leave,
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 96,
                          child: CefButton(
                            'Save',
                            compact: true,
                            onTap: _canSave ? _save : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  Gap.gutter,
                  Gap.xl,
                  Gap.gutter,
                  Gap.xl + media.padding.bottom,
                ),
                children: [
                  Text('Customize ${def.name}', style: text.titleMedium),
                  const SizedBox(height: Gap.xs),
                  Text(
                    'Adjust the colours and style to match your brand.',
                    style: text.bodySmall,
                  ),
                  // One control per declared capability, in a fixed order.
                  for (final cap in StorefrontCapability.values)
                    if (def.supports(cap)) ..._controlFor(cap),
                  const SizedBox(height: Gap.xl),
                  const CefDivider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _reset,
                      style: TextButton.styleFrom(
                        foregroundColor: c.textSecondary,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(LucideIcons.rotateCcw, size: 16),
                      label: const Text('Reset to template defaults'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _controlFor(StorefrontCapability cap) => switch (cap) {
    StorefrontCapability.brandColour => _brandColour(),
    StorefrontCapability.background => _background(),
    StorefrontCapability.heroImage => _heroImage(),
    StorefrontCapability.identity => _identity(),
  };

  Widget _label(String title, {String? hint}) => Padding(
    padding: const EdgeInsets.only(top: Gap.xxl, bottom: Gap.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        if (hint != null)
          Text(hint, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );

  List<Widget> _brandColour() {
    final swatches = <Color>[
      def.defaults.primary,
      for (final s in _brandSwatches)
        if (s != def.defaults.primary) s,
    ];
    final custom = !swatches.contains(draft.primary);
    return [
      _label('Brand colour'),
      Wrap(
        spacing: Gap.md,
        runSpacing: Gap.md,
        children: [
          for (final s in swatches)
            _Swatch(
              color: s,
              selected: draft.primary == s,
              onTap: () => _update(draft.copyWith(primary: s)),
            ),
          _Swatch(
            color: custom ? draft.primary : null,
            selected: custom,
            tooltip: 'Custom colour',
            onTap: () => _pickColour(
              initial: draft.primary,
              onPicked: (c) => _update(draft.copyWith(primary: c)),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _background() {
    final isCustom = draft.backgroundId == kCustomBackgroundId;
    return [
      _label('Background'),
      Wrap(
        spacing: Gap.md,
        runSpacing: Gap.md,
        children: [
          for (final b in def.backgrounds)
            _BackgroundTile(
              label: b.label,
              color: b.color,
              selected: !isCustom && draft.backgroundId == b.id,
              onTap: () => _update(draft.copyWith(backgroundId: b.id)),
            ),
          _BackgroundTile(
            label: 'Custom',
            color: isCustom ? draft.customBackground : null,
            selected: isCustom,
            onTap: () => _pickColour(
              initial: draft.customBackground ?? def.backgroundFor(draft),
              // A soft tint of the picked colour keeps the template's text
              // legible on it.
              onPicked: (c) => _update(
                draft.copyWith(
                  backgroundId: kCustomBackgroundId,
                  customBackground: _softTint(c),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _heroImage() {
    final image = draft.heroImage;
    final c = context.c;
    return [
      _label('Hero image', hint: 'Shown behind your storefront banner.'),
      Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              color: c.subtle,
              child: image == null
                  ? Icon(LucideIcons.image, color: c.textSecondary)
                  : Image.memory(image, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: Gap.lg),
          Expanded(
            child: Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                SizedBox(
                  width: 120,
                  child: CefButton(
                    image == null ? 'Upload' : 'Change',
                    secondary: true,
                    compact: true,
                    onTap: _pickHeroImage,
                  ),
                ),
                if (image != null)
                  TextButton(
                    onPressed: () =>
                        _update(draft.copyWith(clearHeroImage: true)),
                    style: TextButton.styleFrom(foregroundColor: c.attention),
                    child: const Text('Remove'),
                  ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _identity() => [
    _label('Store name', hint: 'From your Business Profile.'),
    CefField(
      label: 'Store name',
      controller: storeNameCtrl,
      onChanged: (v) => _update(draft.copyWith(storeName: v.trim())),
    ),
    CefField(
      label: 'Tagline (optional)',
      controller: taglineCtrl,
      onChanged: (v) => _update(draft.copyWith(tagline: v.trim())),
    ),
  ];
}

/// A picked colour softened into a legible page tint.
Color _softTint(Color c) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness(hsl.lightness < .92 ? .94 : hsl.lightness)
      .withSaturation((hsl.saturation * .6).clamp(0, 1))
      .toColor();
}

/// Round brand-colour swatch; [color] null draws the Custom "+" swatch.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.tooltip,
  });
  final Color? color;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fill = color;
    return Semantics(
      button: true,
      selected: selected,
      label: tooltip ?? 'Colour ${fill?.hex ?? ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: Sizes.tapTarget,
          height: Sizes.tapTarget,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? CefColors.brand : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill ?? c.card,
              border: fill == null ? Border.all(color: c.border) : null,
            ),
            child: fill == null
                ? Icon(LucideIcons.plus, size: 18, color: c.iconColor)
                : selected
                ? Icon(
                    LucideIcons.check,
                    size: 18,
                    color: accessibleForeground(fill),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Background treatment tile; [color] null draws the Custom tile.
class _BackgroundTile extends StatelessWidget {
  const _BackgroundTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label background',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color ?? c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? CefColors.brand : c.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: color == null
                    ? Icon(LucideIcons.palette, size: 20, color: c.iconColor)
                    : selected
                    ? const Icon(
                        LucideIcons.check,
                        size: 18,
                        color: CefColors.brand,
                      )
                    : null,
              ),
              const SizedBox(height: Gap.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------- single-colour picker sheet

class _ColorPickerSheet extends StatefulWidget {
  const _ColorPickerSheet({required this.initial, required this.onPicked});
  final Color initial;
  final ValueChanged<Color> onPicked;

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late Color color = widget.initial;
  late final hexCtrl = TextEditingController(text: widget.initial.hex);

  @override
  void dispose() {
    hexCtrl.dispose();
    super.dispose();
  }

  void _set(Color c) {
    setState(() {
      color = c;
      hexCtrl.text = c.hex;
    });
    widget.onPicked(c);
  }

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(color);
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
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E6EE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pick a Colour',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _SaturationValueField(
              hue: hsv.hue,
              saturation: hsv.saturation,
              value: hsv.value,
              onChanged: (s, v) =>
                  _set(HSVColor.fromAHSV(1, hsv.hue, s, v).toColor()),
            ),
            const SizedBox(height: 14),
            _HueSlider(
              hue: hsv.hue,
              onChanged: (h) => _set(
                HSVColor.fromAHSV(1, h, hsv.saturation, hsv.value).toColor(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE3E6EE)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: hexCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[#0-9A-Fa-f]'),
                      ),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8F9FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDE1EA)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (raw) {
                      final parsed = parseStorefrontHex(raw);
                      if (parsed != null) _set(parsed);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            CefButton('Done', onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
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
                      gradient: LinearGradient(
                        colors: [Colors.white, Color(0x00FFFFFF)],
                      ),
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
                    left: (saturation * constraints.maxWidth - 10).clamp(
                      -10,
                      constraints.maxWidth - 10,
                    ),
                    top: ((1 - value) * constraints.maxHeight - 10).clamp(
                      -10,
                      constraints.maxHeight - 10,
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
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
                left: (hue / 360 * constraints.maxWidth - 13).clamp(
                  -13,
                  constraints.maxWidth - 13,
                ),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
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
