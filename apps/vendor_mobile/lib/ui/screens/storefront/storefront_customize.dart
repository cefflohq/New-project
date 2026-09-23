/// V-33 -- Screen 03, "Customize {Template Name}". Owns its own full header
/// (back arrow, dynamic title, Reset) since the shared [VendorShell] header
/// can't reach this screen's local draft state -- see the
/// `_ownChromeRoutes` note in `shell.dart`.
///
/// Tabs: Branding (fully implemented, per the spec), Banner/Layout/Advanced
/// (structurally present -- the reference shows all 4 -- but honestly
/// scoped as "coming soon" since no real capability backs them yet; the
/// spec explicitly says to "only expose what's genuinely supported").
///
/// Branding tab: Store Logo (text wordmark placeholder -- there is no image
/// upload pipeline in this prototype), Store Name, Tagline, Primary/
/// Secondary Colour (swatch + hex each), Font Style, and a compact live
/// "Preview" strip that updates immediately as any field changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_state.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/storefront_config.dart';
import '../../../data/storefront_templates.dart';
import '../../shell.dart';
import '../../widgets.dart';

class CustomizeStorefrontScreen extends StatefulWidget {
  const CustomizeStorefrontScreen({super.key});

  @override
  State<CustomizeStorefrontScreen> createState() =>
      _CustomizeStorefrontScreenState();
}

class _CustomizeStorefrontScreenState extends State<CustomizeStorefrontScreen> {
  late StorefrontTemplateDef def;
  late StorefrontBranding draft;
  String tab = 'Branding';

  late final storeNameCtrl = TextEditingController();
  late final taglineCtrl = TextEditingController();
  late final primaryHexCtrl = TextEditingController();
  late final secondaryHexCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // initState may not subscribe to inherited widgets; read the state once.
    final app = AppScope.read(context);
    def = app.activeStorefrontTemplate;
    draft = app.brandingFor(def.id);
    _syncControllers();
  }

  void _syncControllers() {
    storeNameCtrl.text = draft.storeName;
    taglineCtrl.text = draft.tagline;
    primaryHexCtrl.text = draft.primary.hex;
    secondaryHexCtrl.text = draft.effectiveSecondary.hex;
  }

  @override
  void dispose() {
    storeNameCtrl.dispose();
    taglineCtrl.dispose();
    primaryHexCtrl.dispose();
    secondaryHexCtrl.dispose();
    super.dispose();
  }

  void _apply(StorefrontBranding next) => setState(() => draft = next);

  void _resetToDefault() {
    final app = AppScope.of(context);
    app.resetStorefrontBranding(def.id);
    setState(() {
      draft = def.defaultBranding;
      _syncControllers();
    });
  }

  Future<void> _save() async {
    final app = AppScope.of(context);
    app.saveStorefrontBranding(def.id, draft);
    await runAsyncFeedback(
      context,
      action: () async {},
      processingTitle: 'Saving...',
      processingSubtitle: 'Updating your storefront branding',
      successTitle: 'Saved',
      successSubtitle: 'Your storefront branding has been updated.',
    );
  }

  Future<void> _changeLogo() async {
    final ctrl = TextEditingController(text: draft.effectiveLogoText);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Logo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Wordmark text, e.g. LUMA',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      _apply(draft.copyWith(logoText: result.trim(), hasLogo: true));
    }
  }

  Future<void> _pickColor({required bool primary}) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _ColorPickerSheet(
          initial: primary ? draft.primary : draft.effectiveSecondary,
          onPicked: (c) {
            if (primary) {
              primaryHexCtrl.text = c.hex;
              _apply(draft.copyWith(primary: c));
            } else {
              secondaryHexCtrl.text = c.hex;
              _apply(draft.copyWith(secondary: c));
            }
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: _CustomizeHeader(
            templateName: def.name,
            onBack: app.back,
            onReset: _resetToDefault,
          ),
        ),
        Expanded(
          child: ContentSurface(
            child: Column(
              children: [
                SegmentedTabs(
                  labels: const ['Branding', 'Banner', 'Layout', 'Advanced'],
                  active: tab,
                  onChange: (v) => setState(() => tab = v),
                ),
                Expanded(
                  child: tab == 'Branding'
                      ? _buildBrandingTab(context)
                      : _ComingSoonTab(label: tab),
                ),
                _SaveBar(onSave: _save),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingTab(BuildContext context) {
    final app = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.md,
        Gap.gutter,
        Gap.section,
      ),
      children: [
        const SectionHeading('Brand Identity'),
        Text('Store Logo', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Gap.xs),
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.c.border),
              ),
              child: draft.hasLogo
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: FittedBox(
                        child: Text(
                          draft.font.transform(
                            draft.effectiveLogoText.isEmpty
                                ? 'BRAND'
                                : draft.effectiveLogoText,
                          ),
                          style: draft.font.apply(
                            const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF14171C),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      LucideIcons.image,
                      color: context.c.textSecondary,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _changeLogo,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.c.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Change Logo',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _apply(draft.copyWith(hasLogo: false)),
              child: Text(
                'Remove',
                style: TextStyle(
                  color: context.c.attention,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        CefField(
          label: 'Store Name',
          controller: storeNameCtrl,
          onChanged: (v) => _apply(draft.copyWith(storeName: v)),
        ),
        CefField(
          label: 'Tagline (Optional)',
          controller: taglineCtrl,
          onChanged: (v) => _apply(draft.copyWith(tagline: v)),
        ),
        const SectionHeading('Brand Colours'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ColorField(
                label: 'Primary Colour',
                color: draft.primary,
                hexCtrl: primaryHexCtrl,
                onColorTap: () => _pickColor(primary: true),
                onHexSubmit: (raw) {
                  final c = parseStorefrontHex(raw);
                  if (c != null) _apply(draft.copyWith(primary: c));
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ColorField(
                label: 'Secondary Colour',
                color: draft.effectiveSecondary,
                hexCtrl: secondaryHexCtrl,
                onColorTap: () => _pickColor(primary: false),
                onHexSubmit: (raw) {
                  final c = parseStorefrontHex(raw);
                  if (c != null) _apply(draft.copyWith(secondary: c));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        Text('Font Style', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Gap.xs),
        _FontDropdown(
          value: draft.font,
          onChanged: (f) => _apply(draft.copyWith(font: f)),
        ),
        SectionHeading(
          'Preview',
          trailing: TextButton.icon(
            onPressed: () {
              app.saveStorefrontBranding(def.id, draft);
              app.go(VRoute.storefrontTemplatePreview, entityId: def.id);
            },
            style: TextButton.styleFrom(foregroundColor: context.c.info),
            icon: const Icon(LucideIcons.externalLink, size: 13),
            label: const Text(
              'See Live Preview',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _BrandingPreviewStrip(branding: draft),
      ],
    );
  }
}

/// Back-navigation header row drawn in white on the shell's brand
/// backdrop. Owned by this screen only because Reset acts on screen-local
/// draft state.
class _CustomizeHeader extends StatelessWidget {
  const _CustomizeHeader({
    required this.templateName,
    required this.onBack,
    required this.onReset,
  });
  final String templateName;
  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: Sizes.subHeader),
    alignment: Alignment.center,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xs, 0, Gap.sm, Gap.xs),
      child: Row(
        children: [
          IconAction(
            icon: LucideIcons.arrowLeft,
            tooltip: 'Back',
            color: Colors.white,
            onTap: onBack,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: Gap.xs),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageTitle('Customize $templateName'),
                  Text(
                    'Make it yours with your brand identity',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: .82),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onReset,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(LucideIcons.rotateCcw, size: 16),
            label: Text(
              'Reset',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.construction,
            size: 34,
            color: context.c.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            '$label controls aren\'t available for this template yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.c.textSecondary, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onSave});
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.md, Gap.gutter, Gap.md),
    decoration: BoxDecoration(
      color: context.c.card,
      border: Border(top: BorderSide(color: context.c.border)),
    ),
    child: CefButton('Save Changes', onTap: onSave),
  );
}

class _ColorField extends StatelessWidget {
  const _ColorField({
    required this.label,
    required this.color,
    required this.hexCtrl,
    required this.onColorTap,
    required this.onHexSubmit,
  });

  final String label;
  final Color color;
  final TextEditingController hexCtrl;
  final VoidCallback onColorTap;
  final ValueChanged<String> onHexSubmit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: Gap.xs),
      Row(
        children: [
          InkWell(
            onTap: onColorTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: context.c.border),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: hexCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
                LengthLimitingTextInputFormatter(7),
              ],
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDDE1EA)),
                ),
              ),
              onSubmitted: onHexSubmit,
            ),
          ),
        ],
      ),
    ],
  );
}

class _FontDropdown extends StatelessWidget {
  const _FontDropdown({required this.value, required this.onChanged});
  final StorefrontFontTreatment value;
  final ValueChanged<StorefrontFontTreatment> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 13),
    decoration: BoxDecoration(
      color: context.c.card,
      borderRadius: BorderRadius.circular(Sizes.inputRadius),
      border: Border.all(color: context.c.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<StorefrontFontTreatment>(
        value: value,
        isExpanded: true,
        icon: Icon(
          LucideIcons.chevronDown,
          size: 18,
          color: context.c.iconColor,
        ),
        items: [
          for (final f in StorefrontFontTreatment.values)
            DropdownMenuItem(
              value: f,
              child: Text(f.label, style: const TextStyle(fontSize: 14)),
            ),
        ],
        onChanged: (f) {
          if (f != null) onChanged(f);
        },
      ),
    ),
  );
}

class _BrandingPreviewStrip extends StatelessWidget {
  const _BrandingPreviewStrip({required this.branding});
  final StorefrontBranding branding;

  @override
  Widget build(BuildContext context) {
    final fg = accessibleForeground(branding.primary);
    final logo = branding.font.transform(
      branding.effectiveLogoText.isEmpty ? 'BRAND' : branding.effectiveLogoText,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: context.c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      logo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: branding.font.apply(
                        const TextStyle(fontSize: 15, color: Color(0xFF14171C)),
                      ),
                    ),
                  ),
                  const Icon(
                    LucideIcons.search,
                    size: 16,
                    color: Color(0xFF6C7280),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    LucideIcons.shoppingCart,
                    size: 16,
                    color: Color(0xFF6C7280),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    LucideIcons.menu,
                    size: 16,
                    color: Color(0xFF6C7280),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 8,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [branding.primary, branding.effectiveSecondary],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      branding.tagline.isEmpty
                          ? 'Your tagline here.'
                          : branding.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: branding.font.apply(
                        TextStyle(fontSize: 16, color: fg, height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: fg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Shop Now',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: branding.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: CefColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
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
