import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/appearance.dart';
import '../../core/env.dart';
import '../../core/notification_alerts.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/vendor_repository.dart';
import '../share_link.dart';
import '../shell.dart';
import 'auth.dart' show VerifyEmailCodeScreen, otpFailureFrom;
import 'hiring.dart' show TeamTab, teamTab;
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
        // Details (information + address) open from Edit; the week sits
        // right here (Founder, 2026-10-01).
        const SizedBox(height: Gap.lg),
        CefCard(child: _BusinessHoursSection()),
      ],
    );
  }
}

class _BusinessInformationScreen extends StatelessWidget {
  const _BusinessInformationScreen();

  @override
  Widget build(BuildContext context) => _BusinessFieldsForm(
    heading: L.businessDetails,
    icon: LucideIcons.store,
    subtitle: L.howCustomersRidersSeeBusiness,
    fields: [
      _BizField('name', L.businessName, LucideIcons.store, required: true),
      _BizField(
        'phone',
        L.contactPhone,
        LucideIcons.phone,
        keyboard: TextInputType.phone,
      ),
      _BizField(
        'email',
        L.businessEmail,
        LucideIcons.mail,
        keyboard: TextInputType.emailAddress,
      ),
      _BizField('address', L.address, LucideIcons.mapPin, maxLines: 3),
      _BizField(
        'operating_area',
        L.operatingAreaLabel,
        LucideIcons.map,
        hint: L.operatingAreaHint,
      ),
    ],
  );
}

class _BusinessAddressScreen extends StatelessWidget {
  const _BusinessAddressScreen();

  @override
  Widget build(BuildContext context) => _BusinessFieldsForm(
    heading: L.addressDetails,
    icon: LucideIcons.mapPin,
    subtitle: L.storeAddressServiceArea,
    fields: [
      _BizField('address', L.address, LucideIcons.mapPin, maxLines: 3),
      _BizField(
        'operating_area',
        L.operatingAreaLabel,
        LucideIcons.map,
        hint: L.operatingAreaHint,
      ),
    ],
  );
}

class _BizField {
  const _BizField(
    this.key,
    this.label,
    this.icon, {
    this.required = false,
    this.keyboard,
    this.maxLines = 1,
    this.hint,
  });
  final String key, label;
  final IconData icon;
  final bool required;
  final TextInputType? keyboard;
  final int maxLines;
  final String? hint;
}

/// Business details form on the real businesses row: hydrated from the
/// server, saved through the Owner-only update_business_profile. Only the
/// fields that changed are sent.
class _BusinessFieldsForm extends StatefulWidget {
  const _BusinessFieldsForm({
    required this.heading,
    required this.icon,
    required this.subtitle,
    required this.fields,
  });
  final String heading, subtitle;
  final IconData icon;
  final List<_BizField> fields;

  @override
  State<_BusinessFieldsForm> createState() => _BusinessFieldsFormState();
}

class _BusinessFieldsFormState extends State<_BusinessFieldsForm> {
  late final Map<String, TextEditingController> _c = {
    for (final f in widget.fields) f.key: TextEditingController(),
  };
  Map<String, String> _loaded = {};
  bool _loading = true, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final app = AppScope.read(context);
    try {
      final row = await app.repo.business(app.business!.id);
      _loaded = {
        for (final f in widget.fields) f.key: (row[f.key] ?? '').toString(),
      };
      for (final e in _loaded.entries) {
        _c[e.key]!.text = e.value;
      }
    } on RepositoryError catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    for (final f in widget.fields) {
      if (f.required && _c[f.key]!.text.trim().isEmpty) {
        setState(() => _error = L.businessNameRequired);
        return;
      }
    }
    final changed = {
      for (final f in widget.fields)
        if (_c[f.key]!.text.trim() != _loaded[f.key])
          f.key: _c[f.key]!.text.trim(),
    };
    if (changed.isEmpty) return AppScope.read(context).back();
    final app = AppScope.read(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (!app.repo.isDemo) {
        await app.repo.updateBusinessProfile(
          businessId: app.business!.id,
          name: changed['name'],
          phone: changed['phone'],
          email: changed['email'],
          address: changed['address'],
          operatingArea: changed['operating_area'],
        );
      }
      if (changed['name'] != null) app.renameBusiness(changed['name']!);
      if (!mounted) return;
      showCefToast(context, L.businessSaved);
      app.back();
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SkeletonForm();
    final text = Theme.of(context).textTheme;
    return PageBody(
      bottom: CefButton(L.saveChanges, busy: _saving, onTap: _save),
      children: [
        SectionHeading(
          widget.heading,
          icon: widget.icon,
          subtitle: widget.subtitle,
        ),
        for (final f in widget.fields)
          CefField(
            label: f.label,
            controller: _c[f.key],
            prefixIcon: f.icon,
            keyboardType: f.keyboard,
            maxLines: f.maxLines,
            hint: f.hint,
            enabled: !_saving,
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              _error!,
              style: text.bodySmall?.copyWith(color: context.c.attention),
            ),
          ),
      ],
    );
  }
}

/// One weekday: closed, or open from [opens] to [closes] (wall-clock, the
/// business's timezone). [closes] before [opens] = closes the next day;
/// equal = open 24 hours.
class _DayHours {
  _DayHours(this.weekday, this.open, this.opens, this.closes);
  final int weekday;
  bool open;
  TimeOfDay opens, closes;
}

/// Business Hours on the real backend (20260930090613): Owner-only, the
/// whole week saved at once through set_business_hours.
class _BusinessHoursScreen extends StatelessWidget {
  const _BusinessHoursScreen();

  @override
  Widget build(BuildContext context) =>
      const PageBody(children: [_BusinessHoursSection()]);
}

/// The week editor, shown inside Business Profile (Founder, 2026-10-01)
/// with its own Save.
class _BusinessHoursSection extends StatefulWidget {
  const _BusinessHoursSection();

  @override
  State<_BusinessHoursSection> createState() => _BusinessHoursSectionState();
}

class _BusinessHoursSectionState extends State<_BusinessHoursSection> {
  List<_DayHours>? _days;
  bool _saving = false;
  String? _error;

  static TimeOfDay _parse(Object? v, TimeOfDay fallback) {
    final p = '${v ?? ''}'.split(':');
    if (p.length < 2) return fallback;
    return TimeOfDay(
      hour: int.tryParse(p[0]) ?? 0,
      minute: int.tryParse(p[1]) ?? 0,
    );
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = AppScope.read(context);
    try {
      final rows = await app.repo.businessHours(app.business!.id);
      final byDay = {for (final r in rows) r['weekday'] as int: r};
      _days = [
        for (var d = 1; d <= 7; d++)
          _DayHours(
            d,
            byDay[d]?['is_open'] == true,
            _parse(byDay[d]?['opens_at'], const TimeOfDay(hour: 9, minute: 0)),
            _parse(
              byDay[d]?['closes_at'],
              const TimeOfDay(hour: 18, minute: 0),
            ),
          ),
      ];
    } on RepositoryError catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() {});
  }

  Future<void> _pick(_DayHours d, bool opening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: opening ? d.opens : d.closes,
    );
    if (picked == null) return;
    setState(() => opening ? d.opens = picked : d.closes = picked);
  }

  void _copyMonday() {
    final m = _days!.first;
    setState(() {
      for (final d in _days!.skip(1)) {
        d
          ..open = m.open
          ..opens = m.opens
          ..closes = m.closes;
      }
    });
  }

  Future<void> _save() async {
    final app = AppScope.read(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await app.repo.setBusinessHours(app.business!.id, [
        for (final d in _days!)
          {
            'weekday': d.weekday,
            'is_open': d.open,
            if (d.open) 'opens_at': _fmt(d.opens),
            if (d.open) 'closes_at': _fmt(d.closes),
          },
      ]);
      if (!mounted) return;
      showCefToast(context, L.hoursSaved);
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    if (days == null && _error == null) return const SkeletonForm(fields: 3);
    if (days == null) return StateBlock.error(_error!);
    final text = Theme.of(context).textTheme;
    final names = [
      L.monday,
      L.tuesday,
      L.wednesday,
      L.thursday,
      L.friday,
      L.saturday,
      L.sunday,
    ];
    Widget time(_DayHours d, bool opening) => OutlinedButton(
      onPressed: _saving ? null : () => _pick(d, opening),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(72, 40),
        side: BorderSide(color: context.c.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.inputRadius),
        ),
      ),
      child: Text(_fmt(opening ? d.opens : d.closes), style: text.bodyMedium),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          L.operatingHours,
          icon: LucideIcons.clock3,
          subtitle: L.letCustomersKnowWhenBusinessOpen,
        ),
        for (final d in days)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(names[d.weekday - 1], style: text.titleSmall),
                    ),
                    if (!d.open) ...[
                      Text(L.closed, style: text.bodyMedium),
                      const SizedBox(width: Gap.md),
                    ] else ...[
                      time(d, true),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                        child: Text('–', style: text.bodyMedium),
                      ),
                      time(d, false),
                      const SizedBox(width: Gap.sm),
                    ],
                    CefSwitch(
                      value: d.open,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => d.open = v),
                    ),
                  ],
                ),
                if (d.open && d.opens == d.closes)
                  Text(
                    L.open24h,
                    textAlign: TextAlign.end,
                    style: text.bodySmall,
                  )
                else if (d.open &&
                    (d.closes.hour * 60 + d.closes.minute) <
                        (d.opens.hour * 60 + d.opens.minute))
                  Text(
                    L.overnightHint,
                    textAlign: TextAlign.end,
                    style: text.bodySmall,
                  ),
              ],
            ),
          ),
        const SizedBox(height: Gap.sm),
        CefActionRow(
          icon: LucideIcons.copy,
          label: L.applyMondaysHoursAllDays,
          chevron: false,
          onTap: _copyMonday,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              _error!,
              style: text.bodySmall?.copyWith(color: context.c.attention),
            ),
          ),
        const SizedBox(height: Gap.md),
        CefButton(L.saveHours, busy: _saving, onTap: _save),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Account
// ---------------------------------------------------------------------------

/// V-43 — Profile (Founder, 2026-10-01): the same backend Vendor Web uses.
/// Name and phone save to public.profiles (own row only); the photo lives
/// in the private cefflo-avatars bucket at `<uid>/avatar`; email changes
/// only through Secure Email Change codes. Role is read-only.
class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _savedName = '', _savedPhone = '';
  String? _avatarPath, _avatarUrl, _email, _error;
  bool _loading = true, _saving = false, _photoBusy = false;

  static const _maxPhotoBytes = 2 * 1024 * 1024; // cefflo-avatars limit

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final app = AppScope.read(context);
    try {
      final row = await app.repo.myProfile();
      _savedName = (row?['display_name'] as String?) ?? app.userDisplayName;
      _savedPhone = (row?['phone'] as String?) ?? '';
      _avatarPath = row?['avatar_url'] as String?;
      _avatarUrl = await app.repo.avatarUrl(_avatarPath);
      _email = app.repo.isDemo ? null : app.repo.currentUser?.email;
      _name.text = _savedName;
      _phone.text = _savedPhone;
    } on RepositoryError catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _dirty =>
      _name.text.trim() != _savedName || _phone.text.trim() != _savedPhone;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = L.nameRequired);
      return;
    }
    final app = AppScope.read(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final phone = _phone.text.trim();
      await app.repo.saveProfile(
        name: name,
        phone: phone.isEmpty ? null : phone,
      );
      _savedName = name;
      _savedPhone = phone;
      app.dataChanged();
      if (mounted) showCefToast(context, L.profileSaved);
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhoto() async {
    final app = AppScope.read(context);
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final name = file.name.toLowerCase();
    final type = name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
        ? 'image/webp'
        : (name.endsWith('.jpg') || name.endsWith('.jpeg'))
        ? 'image/jpeg'
        : file.mimeType;
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(type)) {
      showCefToast(context, L.photoFormat, error: true);
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxPhotoBytes) {
      showCefToast(context, L.photoTooLarge, error: true);
      return;
    }
    setState(() => _photoBusy = true);
    try {
      final saved = await app.repo.uploadAvatar(bytes, type!);
      // Shown only once the server has the photo and the profile says so.
      _avatarPath = saved;
      _avatarUrl = await app.repo.avatarUrl(saved);
      if (mounted) showCefToast(context, L.photoUpdated);
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    final app = AppScope.read(context);
    setState(() => _photoBusy = true);
    try {
      await app.repo.removeAvatar();
      _avatarPath = null;
      _avatarUrl = null;
      if (mounted) showCefToast(context, L.photoRemoved);
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _changeEmail() async {
    final current = _email;
    if (current == null) return;
    final changed = await startEmailChange(context, current);
    if (changed != null && mounted) {
      setState(() => _email = changed);
      showCefToast(context, L.emailChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SkeletonForm();
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final live = !app.repo.isDemo;
    final name = _name.text.trim().isEmpty ? app.userDisplayName : _name.text;
    return PageBody(
      bottom: live
          ? CefButton(
              L.saveChanges,
              busy: _saving,
              onTap: _dirty ? _save : null,
            )
          : null,
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: SizedBox.square(
                  dimension: 88,
                  child: _avatarUrl != null
                      ? Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => CefAvatar(name, size: 88),
                        )
                      : CefAvatar(name, size: 88),
                ),
              ),
              if (_photoBusy)
                const SizedBox.square(
                  dimension: 88,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        // Photo actions only where the backend can perform them.
        if (live)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _photoBusy ? null : _pickPhoto,
                icon: const Icon(LucideIcons.imagePlus, size: 18),
                label: Text(_avatarPath == null ? L.addPhoto : L.changePhoto),
              ),
              if (_avatarPath != null)
                TextButton.icon(
                  onPressed: _photoBusy ? null : _removePhoto,
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: context.c.attention,
                  ),
                  label: Text(
                    L.removePhoto,
                    style: TextStyle(color: context.c.attention),
                  ),
                ),
            ],
          ),
        SectionHeading(
          L.personalDetails,
          icon: LucideIcons.user,
          subtitle: L.nameShownTeam,
        ),
        CefField(
          label: L.fullName2,
          controller: _name,
          prefixIcon: LucideIcons.user,
          enabled: live && !_saving,
          onChanged: (_) => setState(() {}),
        ),
        CefField(
          label: L.phoneNumber,
          controller: _phone,
          prefixIcon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
          enabled: live && !_saving,
          onChanged: (_) => setState(() {}),
        ),
        SectionHeading(
          L.account,
          icon: LucideIcons.briefcase,
          subtitle: L.signEmailRole,
        ),
        CefListRow(
          icon: LucideIcons.mail,
          title: L.emailAddress,
          subtitle: _email ?? 'yusuf@kopikita.my',
          showChevron: live,
          trailing: live
              ? Text(
                  L.change,
                  style: text.labelLarge?.copyWith(color: CefColors.brand),
                )
              : null,
          onTap: live ? _changeEmail : null,
        ),
        CefField(
          label: L.role,
          initialValue: roleLabel(app.business?.role ?? ''),
          prefixIcon: LucideIcons.briefcase,
          enabled: false,
          helperText: L.managedByBusiness,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.md),
            child: Text(
              _error!,
              style: text.bodySmall?.copyWith(color: context.c.attention),
            ),
          ),
      ],
    );
  }
}

/// Secure Email Change (Founder-approved P1-B): ask for the new address,
/// then one 6-digit code per address (current, then new). The email is
/// shown as changed only when the server reports the new address.
/// Returns the new confirmed email, or null when not completed.
Future<String?> startEmailChange(BuildContext context, String current) async {
  final app = AppScope.read(context);
  final navigator = Navigator.of(context);
  final next = await showDialog<String>(
    context: context,
    builder: (_) => _NewEmailDialog(current: current),
  );
  if (next == null) return null;

  Future<bool> done() async =>
      (await app.repo.confirmedEmail())?.toLowerCase() == next.toLowerCase();

  Future<bool> step(String email, String title) async {
    var verified = false;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (routeContext) => VerifyEmailCodeScreen(
          email: email,
          title: title,
          showVerifiedState: false,
          onVerify: (code) async {
            try {
              await app.repo.verifyEmailChange(email, code);
            } on RepositoryError catch (e) {
              throw otpFailureFrom(e);
            }
          },
          onResend: () async {
            try {
              await app.repo.resendEmailChange(next);
            } on RepositoryError catch (e) {
              throw otpFailureFrom(e);
            }
          },
          onContinue: () {
            verified = true;
            Navigator.of(routeContext).pop();
          },
          onBack: () => Navigator.of(routeContext).pop(),
          onUseDifferentEmail: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
    return verified;
  }

  if (!await step(current, L.confirmCurrentEmail)) return null;
  if (await done()) return next;
  if (!await step(next, L.confirmNewEmail)) return null;
  return await done() ? next : null;
}

class _NewEmailDialog extends StatefulWidget {
  const _NewEmailDialog({required this.current});
  final String current;

  @override
  State<_NewEmailDialog> createState() => _NewEmailDialogState();
}

class _NewEmailDialogState extends State<_NewEmailDialog> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final next = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(next)) {
      setState(() => _error = L.enterValidEmailAddress);
      return;
    }
    if (next.toLowerCase() == widget.current.toLowerCase()) {
      setState(() => _error = L.sameEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(context).repo.requestEmailChange(next);
      if (mounted) Navigator.of(context).pop(next);
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: context.c.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: Gap.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(L.changeEmail, style: text.titleMedium),
            const SizedBox(height: Gap.xs),
            Text(L.changeEmailBody, style: text.bodySmall),
            const SizedBox(height: Gap.lg),
            CefField(
              controller: _email,
              label: L.newEmail,
              prefixIcon: LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
              errorText: _error,
              enabled: !_busy,
            ),
            const SizedBox(height: Gap.md),
            CefButton(L.sendCodes, busy: _busy, onTap: _send),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: Text(L.cancel),
            ),
          ],
        ),
      ),
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
    if (ok && mounted) {
      // Opened as its own page (Helper More): close it; inside the Vendor
      // shell it is a shell route, so go back there.
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        app.back();
      }
    }
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
          ? Icon(LucideIcons.check, color: CefColors.brand)
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
    // Honest interim (Founder, 2026-10-01): only what works today. Help
    // articles and KIM (Cefflo AI support) arrive here as their own
    // workstream -- no search or topics that open nothing.
    return PageBody(
      grouped: true,
      children: [
        _HeroPanel(kicker: L.wereHereHelp, title: L.howCanWeHelp),
        const SizedBox(height: Gap.md),
        _SupportTile(
          icon: LucideIcons.mail,
          title: L.contactSupport2,
          subtitle: L.emailSupportTeam,
          onTap: () => app.go(VRoute.contactSupport),
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
              trailing: AppVersionText(style: text.bodyMedium),
            ),
            CefListRow(
              title: L.privacyPolicy2,
              subtitle: L.readPolicy,
              icon: LucideIcons.shieldCheck,
              onTap: () => AppScope.read(context).go(VRoute.privacyPolicy),
            ),
            CefListRow(
              title: L.termsService2,
              subtitle: L.readTerms,
              icon: LucideIcons.fileText,
              onTap: () => AppScope.read(context).go(VRoute.termsOfService),
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

/// V-22 / V-25 — Rider / team invite (Founder, 2026-10-01). Each business
/// has ONE permanent invite link per role (rider, operator, helper), made by
/// the server on first open (get_invite_link) and kept until Reset. Anyone
/// who joins through it waits as pending until the business approves.
/// Rider links: Owner or Operator. Operator / Helper links: Owner only
/// (enforced server-side).
class _InviteLinkScreen extends StatefulWidget {
  const _InviteLinkScreen({required this.rider});
  final bool rider;

  @override
  State<_InviteLinkScreen> createState() => _InviteLinkScreenState();
}

class _InviteLinkScreenState extends State<_InviteLinkScreen> {
  // D-73: Operator or Helper only. Owner is never invited. Opens on the role
  // the Owner came from (Team tab / Hiring row).
  String role = teamTab.value == TeamTab.helpers ? 'helper' : 'operator';

  /// M2: an Operator may invite Helpers only (Operator links are Owner-only;
  /// the server refuses them too).
  bool get _ownerInvites => AppScope.read(context).business?.isOwner ?? true;
  final Map<String, String> _tokens = {};
  bool _loading = false;
  String? error;

  bool get rider => widget.rider;
  String get kind => rider ? 'rider' : role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!rider && !_ownerInvites) role = 'helper';
    if (_tokens.containsKey(kind)) return setState(() {});
    final app = AppScope.read(context);
    final businessId = app.business?.id;
    if (businessId == null) {
      setState(() => error = L.noBusinessLinked);
      return;
    }
    final wanted = kind;
    setState(() {
      _loading = true;
      error = null;
    });
    try {
      final token = await app.repo.inviteLinkToken(businessId, wanted);
      if (mounted) setState(() => _tokens[wanted] = token);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? get link {
    final token = _tokens[kind];
    if (token == null) return null;
    return Uri.parse(Env.inviteBaseUrl)
        .replace(queryParameters: {'link': token})
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final link = this.link;
    // Centred in the white surface: identity, link, one Share action.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.gutter,
          vertical: Gap.xl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (box.maxHeight - Gap.xl * 2).clamp(0, double.infinity),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PageBody.maxContentWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: IconTile(LucideIcons.userPlus)),
                  const SizedBox(height: Gap.md),
                  Text(
                    rider ? L.inviteRidersBusiness : L.inviteTeamMember2,
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    L.inviteLinkPermanent,
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: Gap.lg),
                  if (!rider && _ownerInvites) ...[
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: Gap.sm,
                      children: [
                        for (final (value, label) in [
                          ('operator', L.operatorText),
                          ('helper', L.helperText),
                        ])
                          CefChoiceChip(
                            label: label,
                            selected: role == value,
                            onTap: () {
                              setState(() => role = value);
                              _load();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: Gap.sm),
                    Text(
                      role == 'helper'
                          ? L.helperRoleDescription
                          : L.operatorRoleDescription,
                      textAlign: TextAlign.center,
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: Gap.lg),
                  ],
                  if (link == null && error == null)
                    const SkeletonPulse(child: SkeletonBox(height: 52))
                  else if (link != null)
                    ..._linkSection(text, link),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.md),
                      child: Text(
                        error!,
                        style: text.bodySmall?.copyWith(
                          color: context.c.attention,
                        ),
                      ),
                    ),
                  if (_loading && link != null) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _linkSection(TextTheme text, String link) {
    final business = AppScope.read(context).business?.name ?? 'Cefflo';
    return [
      PermanentLinkSection(
        title: L.yourInviteLink,
        link: link,
        shareLabel: L.shareInviteLink,
        shareText: L.inviteShareMessage(business),
        qrTitle: L.scanJoin,
        qrBody: L.scanToJoinBody,
      ),
    ];
  }
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
