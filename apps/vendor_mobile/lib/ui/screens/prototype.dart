import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr/qr.dart';

import '../../core/app_state.dart';
import '../../core/appearance.dart';
import '../../core/env.dart';
import '../../core/notification_alerts.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/vendor_repository.dart';
import '../shell.dart';
import '../widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

class UiPrototypeScreen extends StatelessWidget {
  const UiPrototypeScreen({super.key, required this.spec});

  final RouteSpec spec;

  @override
  Widget build(BuildContext context) => switch (spec.route) {
    VRoute.riderRegistrationLink => const _InviteLinkScreen(rider: true),
    VRoute.helperRegistrationLink => const _InviteLinkScreen(rider: false),
    VRoute.businessProfile => const _BusinessProfileScreen(),
    VRoute.businessInformation => const _BusinessInformationScreen(),
    VRoute.businessAddress => const _BusinessAddressScreen(),
    VRoute.businessHours => const _BusinessHoursScreen(),
    VRoute.deliverySettings => _ComingSoonScreen(
      title: L.deliverySettings,
      message: L.reservedLaterApprovedDeliverySettingsPass,
    ),
    VRoute.editProfile => const _EditProfileScreen(),
    VRoute.security => const _SecurityScreen(),
    VRoute.changePassword => const _ChangePasswordScreen(),
    VRoute.notificationSettings => const _NotificationPreferencesScreen(),
    VRoute.appearance => const _AppearanceScreen(),
    VRoute.helpSupport => const _HelpSupportScreen(),
    VRoute.faq => const _FaqScreen(),
    VRoute.contactSupport => const _ContactSupportScreen(),
    VRoute.privacyPolicy => const _PolicyScreen(privacy: true),
    VRoute.termsOfService => const _PolicyScreen(privacy: false),
    VRoute.about => const _AboutScreen(),
    VRoute.notificationInbox => const _NotificationInboxScreen(),
    _ => _ComingSoonScreen(
      title: spec.title,
      message: '${spec.id} is in the approved inventory.',
    ),
  };
}

/// Kicker / title / subtitle composition on the one [HeroSurface].
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.kicker, required this.title, this.subtitle});
  final String kicker;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Colors.white.withValues(alpha: .72);
    return HeroSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: text.bodySmall?.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: text.titleMedium?.copyWith(color: Colors.white)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: text.bodyMedium?.copyWith(color: muted)),
          ],
          const SizedBox(height: Gap.sm),
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: CefColors.ceffloMustard,
              borderRadius: BorderRadius.circular(Sizes.buttonRadius),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact intro at the top of a grouped settings page: a CEFFLO Blue
/// [IconTile] beside a section title and its supporting line.
class _GroupedIntro extends StatelessWidget {
  const _GroupedIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xs, 0, 0, Gap.xl),
      child: Row(
        children: [
          IconTile(icon),
          const SizedBox(width: Gap.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Business
// ---------------------------------------------------------------------------

class _BusinessProfileScreen extends StatelessWidget {
  const _BusinessProfileScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final demo = app.repo.isDemo;
    final name = app.business?.name ?? (demo ? 'Kopi Kita' : '');
    // Archetype F: compact identity + stats card, grouped rows, then the
    // store panel -- all inside the first viewport.
    return PageBody(
      grouped: true,
      children: [
        CefCard(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.sm),
          child: Column(
            children: [
              Row(
                children: [
                  CefAvatar(name, size: 48),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: text.titleMedium),
                        Text(
                          demo
                              ? 'A better delivery day. Today.'
                              : roleLabel(app.business?.role ?? ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  CefButton(
                    L.edit,
                    secondary: true,
                    compact: true,
                    icon: LucideIcons.pencil,
                    onTap: () => app.go(VRoute.businessInformation),
                  ),
                ],
              ),
              // Business stats have no backend yet; only the demo shows them.
              if (demo) ...[
                const SizedBox(height: Gap.md),
                Divider(height: 1, color: context.c.border),
                KpiStrip(
                  items: [
                    KpiItem('24', L.products, icon: LucideIcons.package),
                    KpiItem('128', L.orders, icon: LucideIcons.shoppingCart),
                    KpiItem('4.8', L.rating, icon: LucideIcons.star),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Gap.lg),
        CefListGroup(
          label: L.business,
          children: [
            CefListRow(
              title: L.businessInformation2,
              subtitle: L.nameContactDescription,
              icon: LucideIcons.fileText,
              onTap: () => app.go(VRoute.businessInformation),
            ),
            CefListRow(
              title: L.businessAddress2,
              subtitle: L.storeAddressServiceArea,
              icon: LucideIcons.mapPin,
              onTap: () => app.go(VRoute.businessAddress),
            ),
            CefListRow(
              title: L.businessHours2,
              subtitle: L.setOperatingHours,
              icon: LucideIcons.clock,
              onTap: () => app.go(VRoute.businessHours),
            ),
          ],
        ),
        _HeroPanel(
          kicker: L.storeReady,
          title: L.keepBusinessInformationUpDate,
        ),
      ],
    );
  }
}

class _BusinessInformationScreen extends StatelessWidget {
  const _BusinessInformationScreen();

  @override
  Widget build(BuildContext context) {
    if (!AppScope.read(context).repo.isDemo) {
      return _ComingSoonScreen(
        title: '',
        message: L.editingBusinessDetailsAppNotConnected,
      );
    }
    return PageBody(
      bottom: CefButton(L.saveChanges, onTap: () {}),
      // Archetype G (multi-section form).
      children: [
        const _EditableAvatar(name: 'Kopi Kita'),
        SectionHeading(
          L.businessDetails,
          icon: LucideIcons.store,
          subtitle: L.howCustomersRidersSeeBusiness,
        ),
        CefField(
          label: L.businessName,
          initialValue: 'Kopi Kita',
          prefixIcon: LucideIcons.store,
        ),
        CefField(
          label: L.taglineOptional2,
          initialValue: 'A better delivery day. Today.',
        ),
        CefField(
          label: L.businessType,
          initialValue: 'Food & Beverage',
          prefixIcon: LucideIcons.package,
          suffixIcon: LucideIcons.chevronDown,
        ),
        CefField(
          label: L.shortDescription,
          initialValue: 'Handcrafted coffee and light bites, delivered fresh across Kuala Lumpur.',
          maxLines: 3,
          maxLength: 160,
        ),
        SectionHeading(
          L.contact,
          icon: LucideIcons.phone,
          subtitle: L.whereCustomersRidersCanReach,
        ),
        _SplitFields(
          leftLabel: L.code,
          left: '+60',
          rightLabel: L.contactPhone,
          right: '12 345 6789',
          keyboardType: TextInputType.phone,
        ),
        CefField(
          label: L.businessEmail,
          initialValue: 'hello@kopikita.my',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }
}

class _BusinessAddressScreen extends StatelessWidget {
  const _BusinessAddressScreen();

  @override
  Widget build(BuildContext context) {
    if (!AppScope.read(context).repo.isDemo) {
      return _ComingSoonScreen(
        title: '',
        message: L.editingBusinessAddressAppNotConnected,
      );
    }
    final c = context.c;
    // Archetype G (multi-section form).
    return PageBody(
      bottom: CefButton(L.saveAddress, onTap: () {}),
      children: [
        CefSearchField(hint: L.searchEnterAddress),
        const SizedBox(height: Gap.md),
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: c.grouped,
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            border: Border.all(color: c.border),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  LucideIcons.mapPin,
                  size: 52,
                  color: CefColors.brand,
                ),
              ),
              Positioned(
                right: Gap.md,
                bottom: Gap.md,
                child: Container(
                  width: Sizes.tapTarget,
                  height: Sizes.tapTarget,
                  decoration: BoxDecoration(
                    color: c.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border),
                  ),
                  child: Icon(
                    LucideIcons.locateFixed,
                    size: Sizes.icon,
                    color: c.iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionHeading(
          L.addressDetails,
          icon: LucideIcons.mapPin,
          subtitle: L.storeAddressServiceArea,
        ),
        CefField(label: L.addressLine1, initialValue: 'No. 12, Jalan Damai 3'),
        CefField(label: L.addressLine2Optional, initialValue: 'Taman Melati'),
        _SplitFields(
          leftLabel: L.postcode,
          left: '53100',
          rightLabel: L.city,
          right: 'Kuala Lumpur',
        ),
        CefField(
          label: L.state,
          initialValue: 'Wilayah Persekutuan Kuala Lumpur',
          suffixIcon: LucideIcons.chevronDown,
        ),
      ],
    );
  }
}

class _BusinessHoursScreen extends StatelessWidget {
  const _BusinessHoursScreen();

  @override
  Widget build(BuildContext context) {
    if (!AppScope.read(context).repo.isDemo) {
      return _ComingSoonScreen(
        title: '',
        message: L.businessHoursNotConnectedYet,
      );
    }
    final days = [
      L.monday,
      L.tuesday,
      L.wednesday,
      L.thursday,
      L.friday,
      L.saturday,
      L.sunday,
    ];
    // Archetype G (form).
    return PageBody(
      bottom: CefButton(L.saveHours, onTap: () {}),
      children: [
        SectionHeading(
          L.operatingHours,
          icon: LucideIcons.clock3,
          subtitle: L.letCustomersKnowWhenBusinessOpen,
        ),
        // Demo schedule by weekday index (0 = Monday): Sunday closed,
        // Friday/Saturday open late.
        for (final (i, day) in days.indexed)
          _BusinessHourRow(
            day: day,
            enabled: i != 6,
            close: i == 4 || i == 5 ? '21:00' : '20:00',
          ),
        const SizedBox(height: Gap.sm),
        CefActionRow(
          icon: LucideIcons.copy,
          label: L.applyMondaysHoursAllDays,
          chevron: false,
          onTap: () {},
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Account
// ---------------------------------------------------------------------------

class _EditProfileScreen extends StatelessWidget {
  const _EditProfileScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final demo = app.repo.isDemo;
    final name = app.userDisplayName;
    final email = demo
        ? 'yusuf@kopikita.my'
        : (app.repo.currentUser?.email ?? '');
    // Read-only: profile editing has no backend contract yet, so there is no
    // Save action that would pretend to store changes.
    return PageBody(
      children: [
        if (name.isNotEmpty) _EditableAvatar(name: name),
        SectionHeading(
          L.personalDetails,
          icon: LucideIcons.user,
          subtitle: L.nameShownTeam,
        ),
        CefField(
          label: L.fullName2,
          initialValue: name.isEmpty ? '—' : name,
          prefixIcon: LucideIcons.user,
          enabled: false,
        ),
        SectionHeading(
          L.account,
          icon: LucideIcons.briefcase,
          subtitle: L.signEmailRole,
        ),
        CefField(
          label: L.emailAddress,
          initialValue: email,
          prefixIcon: LucideIcons.mail,
          enabled: false,
          helperText: L.emailCannotChangedApp,
        ),
        CefField(
          label: L.role,
          initialValue: roleLabel(app.business?.role ?? ''),
          prefixIcon: LucideIcons.briefcase,
          enabled: false,
          helperText: L.managedByBusiness,
        ),
      ],
    );
  }
}

class _SecurityScreen extends StatelessWidget {
  const _SecurityScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      grouped: true,
      children: [
        _GroupedIntro(
          icon: LucideIcons.shield,
          title: L.keepAccountSafe,
          subtitle: L.manageHowSignBusinessAccount,
        ),
        CefListGroup(
          label: L.signAccess,
          children: [
            CefListRow(
              title: L.password,
              subtitle: L.changePassword2,
              subtitleMaxLines: 2,
              icon: LucideIcons.lock,
              onTap: () => app.go(VRoute.changePassword),
            ),
            // Unavailable feature: no switch or on/off state, just an honest
            // "Coming soon" subtitle on a non-tappable row.
            CefListRow(
              title: L.twoFactorAuthentication,
              subtitle: L.comingSoon,
              subtitleMaxLines: 2,
              icon: LucideIcons.smartphone,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final password = TextEditingController();
  final confirm = TextEditingController();
  String? error;

  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  bool get _longEnough => password.text.length >= 8;
  bool get _letterAndNumber =>
      RegExp(r'[A-Za-z]').hasMatch(password.text) &&
      RegExp(r'\d').hasMatch(password.text);

  Future<void> _submit() async {
    if (!_longEnough || !_letterAndNumber) {
      setState(() => error = L.useLeast8CharactersLetterNumber);
      return;
    }
    if (password.text != confirm.text) {
      setState(() => error = L.passwordsDoNotMatch);
      return;
    }
    setState(() => error = null);
    final app = AppScope.read(context);
    final value = password.text;
    final ok = await runAsyncFeedback(
      context,
      action: app.repo.isDemo
          ? () async {}
          : () => app.repo.updatePassword(value),
      processingTitle: L.processing,
      processingSubtitle: L.updatingPassword2,
      successTitle: L.successful,
      successSubtitle: L.passwordHasBeenUpdatedSuccessfully,
    );
    if (ok && mounted) app.back();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageBody(
      bottom: CefButton(L.updatePassword2, onTap: _submit),
      children: [
        SectionHeading(
          L.setNewPassword,
          icon: LucideIcons.lock,
          subtitle: L.useStrongPasswordKeepAccountSecure,
        ),
        CefField(
          label: L.newPassword2,
          hint: L.enterNewPassword2,
          controller: password,
          prefixIcon: LucideIcons.keyRound,
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),
        _Requirement(L.minimum8Characters, met: _longEnough),
        _Requirement(L.includeLeastOneLetterOneNumber, met: _letterAndNumber),
        const SizedBox(height: Gap.md),
        CefField(
          label: L.confirmNewPassword,
          hint: L.confirmNewPassword2,
          controller: confirm,
          prefixIcon: LucideIcons.keyRound,
          obscureText: true,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              error!,
              style: text.bodySmall?.copyWith(color: context.c.attention),
            ),
          ),
      ],
    );
  }
}

/// V-47 — Notifications. Two account-level switches stored in
/// public.notification_preferences (the same row every Cefflo app reads):
/// Notifications (alerts while the app is open) and Sound. The centre always
/// keeps every notification; operational truth is never hidden.
class _NotificationPreferencesScreen extends StatefulWidget {
  const _NotificationPreferencesScreen();

  @override
  State<_NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<_NotificationPreferencesScreen> {
  bool _saving = false;

  Future<void> _save(NotificationPrefs next) async {
    final app = AppScope.read(context);
    setState(() => _saving = true);
    try {
      await app.setNotificationPrefs(next);
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final prefs = app.notificationPrefs;
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Text(L.ntPrefLead, style: text.bodySmall),
        const SizedBox(height: Gap.xs),
        CefListRow(
          title: L.ntPrefEnabled,
          subtitle: L.ntPrefEnabledSub,
          subtitleMaxLines: 3,
          icon: LucideIcons.bell,
          showChevron: false,
          trailing: CefSwitch(
            value: prefs.enabled,
            onChanged: _saving
                ? null
                : (v) =>
                      _save(NotificationPrefs(enabled: v, sound: prefs.sound)),
          ),
        ),
        CefListRow(
          title: L.ntPrefSound,
          subtitle: L.ntPrefSoundSub,
          subtitleMaxLines: 2,
          icon: LucideIcons.volume2,
          showChevron: false,
          trailing: CefSwitch(
            value: prefs.sound,
            onChanged: _saving || !prefs.enabled
                ? null
                : (v) => _save(
                    NotificationPrefs(enabled: prefs.enabled, sound: v),
                  ),
          ),
        ),
        const SizedBox(height: Gap.md),
        Text(L.ntPushDeferred, style: text.bodySmall),
      ],
    );
  }
}

/// V-49 — Appearance (Founder, 2026-09-30): the app backdrop colour, one
/// named colour per row, Plain or Gradient, and Custom. Choosing previews
/// app-wide at once; only Save keeps it, on this device only (never
/// synced). Leaving without saving restores the saved appearance. The
/// white content surface, semantic status colours and the mustard CTA
/// never change.
class _AppearanceScreen extends StatefulWidget {
  const _AppearanceScreen();

  @override
  State<_AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<_AppearanceScreen> {
  static List<(String, int?)> get colours => [
    (L.appearanceStandard, null),
    (L.blue, 0xFF0060FE),
    (L.navy, 0xFF0B1220),
    (L.green, 0xFF12A150),
    (L.red, 0xFFE5484D),
    (L.orange, 0xFFF97316),
    (L.purple, 0xFF7C3AED),
    (L.black, 0xFF1C1D20),
  ];

  late AppState _app;
  late Appearance _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _app = AppScope.read(context);
    _draft = _app.appearance;
  }

  @override
  void dispose() {
    // Back / cancel: an unsaved preview never outlives the screen.
    final app = _app;
    Future.microtask(app.discardAppearancePreview);
    super.dispose();
  }

  void _choose(Appearance next) {
    setState(() => _draft = next);
    _app.previewAppearance(next);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _app.saveAppearance(_draft);
    if (!mounted) return;
    setState(() => _saving = false);
    showCefToast(context, L.appearanceSaved);
  }

  Future<void> _pickCustom() async {
    final picked = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Sizes.cardRadius),
        ),
      ),
      builder: (_) =>
          _ColourPickerSheet(initial: Color(_draft.color ?? 0xFF0060FE)),
    );
    if (picked != null) {
      _choose(Appearance(color: picked.toARGB32(), gradient: _draft.gradient));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isCustom =
        _draft.color != null && !colours.any((c) => c.$2 == _draft.color);
    final plain = L.appearancePlain, gradient = L.appearanceGradient;
    return PageBody(
      bottom: CefButton(
        L.save,
        busy: _saving,
        onTap: _draft == _app.appearance ? null : _save,
      ),
      children: [
        SectionHeading(L.appearanceBackground, icon: LucideIcons.palette),
        Text(L.appearanceDeviceOnly, style: text.bodySmall),
        const SizedBox(height: Gap.md),
        SegmentedTabs(
          labels: [plain, gradient],
          active: _draft.gradient ? gradient : plain,
          onChange: (l) =>
              _choose(Appearance(color: _draft.color, gradient: l == gradient)),
        ),
        const SizedBox(height: Gap.md),
        for (final (name, value) in colours)
          _ColourRow(
            label: name,
            look: Appearance(color: value, gradient: _draft.gradient),
            selected: _draft.color == value,
            onTap: () =>
                _choose(Appearance(color: value, gradient: _draft.gradient)),
          ),
        _ColourRow(
          label: L.custom,
          look: isCustom ? _draft : null,
          selected: isCustom,
          onTap: _pickCustom,
        ),
      ],
    );
  }
}

/// One colour choice: a swatch painted exactly as the backdrop would be,
/// the colour name, and a check when selected.
class _ColourRow extends StatelessWidget {
  const _ColourRow({
    required this.label,
    required this.look,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Appearance? look;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: CefListRow(
      title: label,
      showChevron: look == null,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              look?.backdrop ??
              const SweepGradient(
                colors: [
                  Colors.red,
                  Colors.yellow,
                  Colors.green,
                  Colors.cyan,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
              ),
          border: Border.all(color: context.c.border),
        ),
      ),
      trailing: selected
          ? const Icon(LucideIcons.check, color: CefColors.brand)
          : null,
      onTap: onTap,
    ),
  );
}

/// Small custom colour picker: hue and lightness sliders over a preview.
class _ColourPickerSheet extends StatefulWidget {
  const _ColourPickerSheet({required this.initial});
  final Color initial;

  @override
  State<_ColourPickerSheet> createState() => _ColourPickerSheetState();
}

class _ColourPickerSheetState extends State<_ColourPickerSheet> {
  late HSLColor _hsl = HSLColor.fromColor(widget.initial);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colour = _hsl.withSaturation(.85).toColor();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Gap.gutter,
          Gap.xl,
          Gap.gutter,
          Gap.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(L.customColour, style: text.titleMedium)),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colour,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.c.border),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            Text(L.hue, style: text.labelLarge),
            Slider(
              value: _hsl.hue,
              max: 360,
              onChanged: (v) => setState(() => _hsl = _hsl.withHue(v)),
            ),
            Text(L.lightness, style: text.labelLarge),
            Slider(
              value: _hsl.lightness.clamp(.15, .85),
              min: .15,
              max: .85,
              onChanged: (v) => setState(() => _hsl = _hsl.withLightness(v)),
            ),
            const SizedBox(height: Gap.md),
            CefButton(L.apply, onTap: () => Navigator.of(context).pop(colour)),
          ],
        ),
      ),
    );
  }
}

/// Profile photo placeholder on a form: the standard initials avatar with a
/// camera badge signalling the photo can be changed.
class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CefAvatar(name, size: 84),
          Positioned(
            right: -Gap.xs,
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: c.card,
                shape: BoxShape.circle,
                border: Border.all(color: c.border),
              ),
              child: Icon(LucideIcons.camera, size: 16, color: c.iconColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two labelled fields side by side (e.g. country code + number,
/// postcode + city) at a 2:4 split.
class _SplitFields extends StatelessWidget {
  const _SplitFields({
    required this.leftLabel,
    required this.left,
    required this.rightLabel,
    required this.right,
    this.keyboardType,
  });
  final String leftLabel, left, rightLabel, right;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 2,
        child: CefField(
          label: leftLabel,
          initialValue: left,
          keyboardType: keyboardType,
        ),
      ),
      const SizedBox(width: Gap.md),
      Expanded(
        flex: 4,
        child: CefField(
          label: rightLabel,
          initialValue: right,
          keyboardType: keyboardType,
        ),
      ),
    ],
  );
}

class _BusinessHourRow extends StatelessWidget {
  const _BusinessHourRow({
    required this.day,
    required this.enabled,
    required this.close,
  });
  final String day;
  final bool enabled;
  final String close;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Day label, switch and separator share the field's control height so
    // they line up with the CefFields (which carry their own bottom gap).
    Widget control(Widget child, {double? width}) => SizedBox(
      width: width,
      height: Sizes.controlHeight,
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
    final dayLabel = Text(
      day,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.titleSmall,
    );
    final toggle = CefSwitch(value: enabled, onChanged: (_) {});
    final times = [
      const Expanded(child: CefField(initialValue: '08:00')),
      control(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
          child: Text('–', style: text.bodyMedium),
        ),
      ),
      Expanded(child: CefField(initialValue: close)),
    ];
    final closed = Text(L.closed, style: text.bodyMedium);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        // One line needs the day label (~92 * scale), switch + separator
        // (~77) and two time fields (28 padding + ~44 * scale text each);
        // with less room (narrow phone, large text) the times drop below.
        final inline = constraints.maxWidth >= 133 + 180 * scale;
        if (inline) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              control(dayLabel, width: 92 * scale),
              control(toggle),
              const SizedBox(width: Gap.sm),
              if (enabled)
                ...times
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: control(closed),
                  ),
                ),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: control(dayLabel)),
                if (!enabled) ...[closed, const SizedBox(width: Gap.md)],
                toggle,
              ],
            ),
            if (enabled)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: times)
            else
              const SizedBox(height: Gap.sm),
          ],
        );
      },
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement(this.text, {this.met = false});
  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.xs),
    child: Row(
      children: [
        Icon(
          met ? LucideIcons.circleCheck : LucideIcons.circle,
          size: 14,
          color: met ? context.c.success : context.c.textSecondary,
        ),
        const SizedBox(width: Gap.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Support & information
// ---------------------------------------------------------------------------

class _HelpSupportScreen extends StatelessWidget {
  const _HelpSupportScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // Archetype F: hero, search, support tiles, grouped topics.
    return PageBody(
      grouped: true,
      children: [
        _HeroPanel(kicker: L.wereHereHelp, title: L.howCanWeHelp),
        const SizedBox(height: Gap.md),
        CefSearchField(hint: L.searchHelpArticlesTopics, onFilter: () {}),
        const SizedBox(height: Gap.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SupportTile(
                  icon: LucideIcons.bookOpen,
                  title: L.helpCentre2,
                  subtitle: L.browseArticlesGuidesFaqs,
                  onTap: () => app.go(VRoute.faq),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: _SupportTile(
                  icon: LucideIcons.messageCircle,
                  title: L.contactSupport2,
                  subtitle: L.chatSendSupportRequest,
                  onTap: () => app.go(VRoute.contactSupport),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.xl),
        CefListGroup(
          label: L.popularTopics,
          children: [
            CefListRow(
              title: L.accountSecurity2,
              subtitle: L.loginProfileSecuritySettings,
              subtitleMaxLines: 2,
              icon: LucideIcons.circleUserRound,
            ),
            CefListRow(
              title: L.ordersDelivery,
              subtitle: L.orderManagementDeliveryIssues,
              subtitleMaxLines: 2,
              icon: LucideIcons.truck,
            ),
            CefListRow(
              title: L.ridersTeam,
              subtitle: L.riderInvitesApprovalsTeamAccess,
              subtitleMaxLines: 2,
              icon: LucideIcons.users,
            ),
            CefListRow(
              title: L.subscriptionBilling,
              subtitle: L.plansPaymentsInvoices,
              subtitleMaxLines: 2,
              icon: LucideIcons.calendarDays,
            ),
            CefListRow(
              title: L.appGuides,
              subtitle: L.stepByStepTutorials,
              subtitleMaxLines: 2,
              icon: LucideIcons.bookOpen,
            ),
          ],
        ),
      ],
    );
  }
}

class _FaqScreen extends StatelessWidget {
  const _FaqScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    // Archetype F, same language as Help & Support.
    grouped: true,
    children: [
      _HeroPanel(
        kicker: L.howCanWeHelp,
        title: L.findAnswers,
        subtitle: L.searchOurHelpCentreBrowseTopics,
      ),
      const SizedBox(height: Gap.md),
      CefSearchField(hint: L.searchHelpEGZonesRiders, onFilter: () {}),
      const SizedBox(height: Gap.xl),
      CefListGroup(
        label: L.browseTopics,
        children: [
          CefListRow(
            title: L.gettingStarted,
            subtitle: L.setUpAccountBusiness,
            icon: LucideIcons.bookOpen,
          ),
          CefListRow(
            title: L.ordersDelivery,
            subtitle: L.manageOrdersRunsZones,
            icon: LucideIcons.truck,
          ),
          CefListRow(
            title: L.zonesRiders,
            subtitle: L.coverageRidersDispatch,
            icon: LucideIcons.users,
          ),
          CefListRow(
            title: L.account,
            subtitle: L.profileSecuritySettings,
            icon: LucideIcons.bookOpen,
          ),
          CefListRow(
            title: L.subscriptionBilling,
            subtitle: L.plansPaymentsInvoices2,
            icon: LucideIcons.calendarDays,
          ),
        ],
      ),
      CefListGroup(
        label: L.popularQuestions,
        children: [
          for (final question in [
            L.howDoICreateDeliveryZone,
            L.howDoIAddRider,
            L.canIChangeMyPlanLater,
            L.howDoesRouteOptimizationWork,
            L.whereCanMyCustomersTrackTheir,
          ])
            CefListRow(title: question, icon: LucideIcons.circleHelp),
          CefListRow(
            title: L.viewAll,
            icon: LucideIcons.list,
            onTap: () =>
                showNotWiredYetSnackBar(context, L.viewingAllQuestions),
          ),
        ],
      ),
    ],
  );
}

/// V-57 Contact Support (FG-4): hands the request to the real support
/// channel, support@cefflo.com, through the user's own email app, with the
/// business and account context attached. There is no in-app ticket
/// backend, so the app never claims a request was sent.
class _ContactSupportScreen extends StatefulWidget {
  const _ContactSupportScreen();

  @override
  State<_ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<_ContactSupportScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _compose() async {
    final message = _message.text.trim();
    if (message.isEmpty) {
      setState(() => _error = L.writeMessageFirst);
      return;
    }
    setState(() => _error = null);
    final app = AppScope.read(context);
    final business = app.business;
    final email = app.repo.currentUser?.email;
    final subject = _subject.text.trim().isEmpty
        ? 'Cefflo Vendor support'
        : _subject.text.trim();
    final body = [
      message,
      '',
      '--',
      if (business != null) 'Business: ${business.name} (${business.id})',
      if (business != null) 'Role: ${business.role}',
      if (email != null) 'Account: $email',
      'App: Cefflo Vendor',
    ].join('\n');
    await launchSupportEmail(context, subject: subject, body: body);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Text(L.wereHereHelp2, style: text.bodyMedium),
        SectionHeading(
          L.getTouch,
          icon: LucideIcons.messageCircle,
          subtitle: L.tellUsAboutIssueOurTeam,
        ),
        CefField(
          label: L.subject,
          hint: L.brieflyDescribeIssue,
          controller: _subject,
        ),
        CefField(
          label: L.message,
          hint: L.tellUsMoreAboutIssue,
          controller: _message,
          maxLines: 4,
          maxLength: 500,
          errorText: _error,
        ),
        SectionHeading(
          L.contact,
          icon: LucideIcons.mail,
          subtitle: supportEmail,
        ),
        Text(L.supportSendOpensEmailApp, style: text.bodySmall),
        const SizedBox(height: Gap.md),
        CefButton(L.sendRequest, onTap: _compose),
      ],
    );
  }
}

class _PolicyScreen extends StatelessWidget {
  const _PolicyScreen({required this.privacy});
  final bool privacy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Document on the white surface.
    return PageBody(
      children: [
        SectionHeading(
          L.trustTransparency,
          icon: privacy ? LucideIcons.shieldCheck : LucideIcons.fileText,
          subtitle: privacy
              ? L.wereCommittedProtectingDataPrivacy
              : L.termsThatGuideUseCefflo,
        ),
        Text(L.lastUpdated12Sep2026, style: text.bodySmall),
        const SizedBox(height: Gap.lg),
        Divider(height: 1, color: context.c.border),
        SectionHeading(L.page),
        Text(
          privacy
              ? L.t1Introduction2InformationWeCollect
              : L.t1AcceptanceTerms2AccountResponsibilities,
          style: text.bodyMedium?.copyWith(height: 1.6),
        ),
        SectionHeading(privacy ? L.t1Introduction : L.t1AcceptanceTerms),
        Text(
          privacy
              ? L.ceffloWeUsOurValuesPrivacy
              : L.byAccessingUsingCeffloAgreeThese,
          style: text.bodyMedium,
        ),
        SectionHeading(
          privacy ? L.t2InformationWeCollect : L.t2AccountResponsibilities,
        ),
        Text(
          privacy
              ? L.weCollectInformationThatProvideDirectly
              : L.responsibleMaintainingAccurateAccountInformationProtecting,
          style: text.bodyMedium,
        ),
      ],
    );
  }
}

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Archetype F: identity block, grouped information rows.
    return PageBody(
      grouped: true,
      children: [
        const Center(child: CefAvatar('Cefflo', size: 84)),
        const SizedBox(height: Gap.md),
        Text('Cefflo', textAlign: TextAlign.center, style: text.titleMedium),
        const SizedBox(height: Gap.xs),
        Text(
          L.moreOrdersLessWorkSmootherDelivery,
          textAlign: TextAlign.center,
          style: text.bodyMedium,
        ),
        const SizedBox(height: Gap.xxl),
        CefListGroup(
          label: L.ourPurpose,
          children: [
            CefListRow(
              title: L.operateTodayGrowTomorrow2,
              subtitle: L.localSameDayDeliveryOperatingSystem,
              subtitleMaxLines: 2,
              icon: LucideIcons.target,
            ),
          ],
        ),
        CefListGroup(
          label: L.appInformation,
          children: [
            CefListRow(
              title: L.version,
              icon: LucideIcons.smartphone,
              trailing: Text('1.0.0', style: text.bodyMedium),
            ),
            CefListRow(
              title: L.privacyPolicy2,
              subtitle: L.readPolicy,
              icon: LucideIcons.shieldCheck,
            ),
            CefListRow(
              title: L.termsService2,
              subtitle: L.readTerms,
              icon: LucideIcons.fileText,
            ),
          ],
        ),
        Text(
          '© 2026 Cefflo. All rights reserved.',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CefCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon),
        const SizedBox(height: Gap.md),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

/// X-01 — Notification centre. Unread entries carry a blue dot and a bold
/// title; read ones step back. Tap opens (marks read); swipe left deletes
/// (with Undo), swipe right toggles read; the row's overflow menu does the
/// same. Mark all / Clear all live in the header menu.
class _NotificationInboxScreen extends StatelessWidget {
  const _NotificationInboxScreen();

  static IconData _icon(NotificationKind kind) => switch (kind) {
    NotificationKind.attention => LucideIcons.triangleAlert,
    NotificationKind.order => LucideIcons.package,
    NotificationKind.rider => LucideIcons.users,
    NotificationKind.system => LucideIcons.info,
  };

  static void _delete(BuildContext context, AppNotification n) {
    final app = AppScope.read(context);
    final undo = app.deleteNotification(n.id);
    if (undo == null) return;
    showCefToast(
      context,
      L.notificationDeleted,
      actionLabel: L.undo,
      onAction: () => app.restoreNotification(undo),
    );
  }

  static void _guard(BuildContext context, Future<void> action) {
    action.catchError((Object _) {
      if (context.mounted) {
        showCefToast(context, L.ntCouldNotUpdate, error: true);
      }
    });
  }

  static void _showRowOptions(BuildContext context, AppNotification n) {
    final app = AppScope.read(context);
    showListSheet(
      context,
      title: notificationCopy(n).title,
      children: [
        CefListRow(
          title: n.read ? L.markUnread : L.markRead,
          icon: n.read ? LucideIcons.mail : LucideIcons.mailOpen,
          showChevron: false,
          onTap: () {
            Navigator.of(context).pop();
            _guard(context, app.setNotificationRead(n.id, read: !n.read));
          },
        ),
        CefListRow(
          title: L.delete2,
          icon: LucideIcons.trash2,
          showChevron: false,
          onTap: () {
            Navigator.of(context).pop();
            _delete(context, n);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final items = app.notifications;
    if (items.isEmpty && app.notificationsError != null) {
      return PageBody(
        children: [
          StateBlock.error(
            app.notificationsError!,
            onRetry: app.refreshNotifications,
          ),
        ],
      );
    }
    if (items.isEmpty) {
      return PageBody(children: [StateBlock.empty(L.youreAllCaughtUp)]);
    }
    Widget swipeBackground(Color color, IconData icon, Alignment align) =>
        Container(
          color: color,
          alignment: align,
          padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
          child: Icon(icon, color: Colors.white, size: Sizes.icon),
        );
    return PageBody(
      children: [
        for (final n in items)
          Dismissible(
            key: ValueKey(n.id),
            background: swipeBackground(
              CefColors.brand,
              n.read ? LucideIcons.mail : LucideIcons.mailOpen,
              Alignment.centerLeft,
            ),
            secondaryBackground: swipeBackground(
              c.attention,
              LucideIcons.trash2,
              Alignment.centerRight,
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                _guard(context, app.setNotificationRead(n.id, read: !n.read));
                return false;
              }
              return true;
            },
            onDismissed: (_) => _delete(context, n),
            child: CefListRow(
              title: notificationCopy(n).title,
              subtitle: '${notificationCopy(n).body}\n${notificationWhen(n)}',
              subtitleMaxLines: 2,
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconTile(_icon(n.kind), color: n.urgent ? c.attention : null),
                  if (!n.read)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: CefColors.brand,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.card, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              emphasis: !n.read,
              trailing: IconAction(
                icon: LucideIcons.ellipsis,
                tooltip: L.notificationOptions,
                onTap: () => _showRowOptions(context, n),
              ),
              showChevron: false,
              onTap: () => app.openNotification(n),
            ),
          ),
      ],
    );
  }
}

/// V-22 / V-25 — Rider/Team invitation. The Vendor names who is invited;
/// the backend (create_rider_invitation / create_team_invitation) returns a
/// one-time token, which becomes the invite.cefflo.com link. The raw token is
/// shown only here, never stored on the device.
class _InviteLinkScreen extends StatefulWidget {
  const _InviteLinkScreen({required this.rider});
  final bool rider;

  @override
  State<_InviteLinkScreen> createState() => _InviteLinkScreenState();
}

class _InviteLinkScreenState extends State<_InviteLinkScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  // D-73: Operator or Helper only. Owner is never invited.
  String role = 'operator';
  bool busy = false;
  String? error;
  String? link;

  bool get rider => widget.rider;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  bool get helper => !rider && role == 'helper';

  String? _validate() {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
      return L.enterValidEmailAddress;
    }
    if (rider && name.text.trim().isEmpty) return L.nameRequired;
    if (rider && phone.text.trim().length < 7) {
      return L.enterValidPhoneNumber;
    }
    return null;
  }

  Future<void> _generate() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    final app = AppScope.read(context);
    final businessId = app.business?.id;
    if (businessId == null) {
      setState(() => error = L.noBusinessLinked);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = rider
          ? await app.repo.createRiderInvitation(
              businessId: businessId,
              email: email.text.trim(),
              name: name.text.trim(),
              phone: phone.text.trim(),
            )
          : await app.repo.createTeamInvitation(
              businessId: businessId,
              email: email.text.trim(),
              role: helper ? 'helper' : 'operator',
            );
      final token = result['token'];
      if (token is! String || token.isEmpty) {
        throw RepositoryError(L.unexpectedBackendResponseShape);
      }
      if (!mounted) return;
      setState(
        () => link = Uri.parse(Env.inviteBaseUrl)
            .replace(
              queryParameters: {
                'type': rider ? 'rider' : 'team',
                'token': token,
              },
            )
            .toString(),
      );
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    showCefToast(context, L.linkCopied);
  }

  /// Compact, centred modal over a dimmed page: the real QR code for [link].
  void _showQrModal(String link) {
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
              Text(L.scanJoin, style: text.titleMedium),
              const SizedBox(height: Gap.xs),
              Text(
                L.invitedPersonCanScanCodeOpen,
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
              const SizedBox(height: Gap.lg),
              _QrCode(data: link, size: 200),
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

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final link = this.link;
    return PageBody(
      bottom: link == null
          ? CefButton(L.generateInviteLink, busy: busy, onTap: _generate)
          : CefButton(
              L.copyLink,
              icon: LucideIcons.copy,
              onTap: () => _copyLink(link),
            ),
      children: [
        Row(
          children: [
            const IconTile(LucideIcons.userPlus),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider ? L.inviteRidersBusiness : L.inviteTeamMember2,
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rider
                        ? L.theyOpenLinkJoinTeamComplete
                        : L.theyOpenLinkHelpRunDeliveries,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.md),
        if (link == null) ..._form(text) else ..._result(text, link),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              error!,
              style: text.bodySmall?.copyWith(color: context.c.attention),
            ),
          ),
      ],
    );
  }

  List<Widget> _form(TextTheme text) => [
    if (!rider) ...[
      Text(L.role, style: text.labelLarge),
      const SizedBox(height: Gap.sm),
      Wrap(
        spacing: Gap.sm,
        children: [
          CefChoiceChip(
            label: L.operatorText,
            selected: role == 'operator',
            onTap: () => setState(() => role = 'operator'),
          ),
          CefChoiceChip(
            label: L.helperText,
            selected: role == 'helper',
            onTap: () => setState(() => role = 'helper'),
          ),
        ],
      ),
      const SizedBox(height: Gap.sm),
      Text(
        helper ? L.helperRoleDescription : L.operatorRoleDescription,
        style: text.bodySmall,
      ),
      const SizedBox(height: Gap.md),
    ],
    if (rider) ...[
      CefField(
        label: L.riderName,
        controller: name,
        prefixIcon: LucideIcons.user,
      ),
      const SizedBox(height: Gap.md),
      CefField(
        label: L.phoneNumber,
        controller: phone,
        keyboardType: TextInputType.phone,
        prefixIcon: LucideIcons.phone,
      ),
      const SizedBox(height: Gap.md),
    ],
    CefField(
      label: L.email,
      controller: email,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: LucideIcons.mail,
    ),
  ];

  List<Widget> _result(TextTheme text, String link) => [
    HeroSurface(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.link,
                size: Sizes.icon,
                color: Colors.white,
              ),
              const SizedBox(width: Gap.sm),
              Text(
                L.invitationLink,
                style: text.titleSmall?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Container(
            padding: const EdgeInsets.only(left: Gap.md),
            decoration: BoxDecoration(
              color: context.c.card,
              borderRadius: BorderRadius.circular(Sizes.inputRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                ),
                IconAction(
                  icon: LucideIcons.copy,
                  tooltip: L.copyLink,
                  onTap: () => _copyLink(link),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: Gap.sm),
    CefActionRow(
      icon: LucideIcons.qrCode,
      label: L.showQrCode,
      subtitle: L.scanOpenInvitation,
      onTap: () => _showQrModal(link),
    ),
    const SizedBox(height: Gap.sm),
    Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: CefColors.brandTint,
        borderRadius: BorderRadius.circular(Sizes.inputRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: Sizes.icon, color: context.c.iconColor),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(
              rider
                  ? L.linkShownOnlyOnceExpires7
                  : L.linkShownOnlyOnceExpires72,
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    ),
  ];
}

/// A scannable QR code for [data], painted module by module in the text
/// colour on white with the standard quiet zone.
class _QrCode extends StatelessWidget {
  const _QrCode({required this.data, required this.size});
  final String data;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _QrPainter(
        QrImage(
          QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
        ),
        context.c.textPrimary,
      ),
    ),
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image, this.color);
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
  bool shouldRepaint(_QrPainter old) =>
      old.image != image || old.color != color;
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      StateBlock.blocked(message),
      const SizedBox(height: Gap.md),
      CefButton(
        L.backSettings,
        secondary: true,
        onTap: () => AppScope.read(context).resetTo(VRoute.settings),
      ),
    ],
  );
}
