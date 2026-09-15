import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../../data/driver_models.dart';
import '../widgets.dart';
import 'auth.dart' show showLanguageSheet;

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

/// Initials avatar. No stock portrait is bundled with the prototype, so the
/// reference's photo slot is drawn as the Driver's initials on the brand
/// navy instead of a fabricated likeness.
class DriverAvatar extends StatelessWidget {
  const DriverAvatar({super.key, required this.name, this.size = 72});

  final String name;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '—';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      gradient: cefHeaderGradient,
      shape: BoxShape.circle,
    ),
    child: Text(
      _initials,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: size * 0.36,
        fontWeight: FontWeight.w800,
        color: CefColors.onNavy,
        letterSpacing: -0.5,
      ),
    ),
  );
}

/// A single bordered navigation row, used as its own card — the D38 Settings
/// treatment where every row is a separate outlined surface.
class OutlinedNavRow extends StatelessWidget {
  const OutlinedNavRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(Sizes.innerRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Sizes.innerRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Sizes.innerRadius),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: CefColors.navy),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (value != null) ...[
                Text(value!, style: context.t.bodyMedium),
                const SizedBox(width: 8),
              ],
              Icon(LucideIcons.chevronRight, size: 20, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "About • v1.2.0 (Driver)" / "About | v1.2.0 | Term" footer line.
class AppVersionFooter extends StatelessWidget {
  const AppVersionFooter({super.key, required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('•', style: context.t.labelSmall),
          ),
        Text(items[i], style: context.t.labelSmall),
      ],
    ],
  );
}

// ---------------------------------------------------------------------------
// D34 — Profile
// ---------------------------------------------------------------------------

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final profile = app.profile;
    final c = context.c;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: 'Profile',
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.lg, Gap.gutter, Gap.lg),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DriverAvatar(name: profile.fullName, size: 76),
              const SizedBox(width: Gap.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: context.t.displaySmall?.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 3),
                    Text(profile.phone, style: context.t.bodyMedium),
                    Text(
                      profile.email,
                      style: context.t.bodyMedium?.copyWith(color: c.info),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profile.statusLabel,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.success,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 13,
                          color: c.border,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        InkWell(
                          onTap: () => app.go(DRoute.editProfile),
                          child: Row(
                            children: [
                              Icon(LucideIcons.pencil, size: 14, color: c.textLabel),
                              const SizedBox(width: 5),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          Divider(height: 1, color: c.border),
          CeffloListTile(
            icon: LucideIcons.car,
            label: 'Vehicle Details',
            onTap: () => app.go(DRoute.vehicleDetails),
          ),
          CeffloListTile(
            icon: LucideIcons.fileText,
            label: 'Documents',
            onTap: () => app.go(DRoute.documents),
          ),
          CeffloListTile(
            icon: LucideIcons.globe,
            label: 'Language',
            value: app.language,
            onTap: () async {
              final picked = await showLanguageSheet(context, app.language);
              if (picked != null) app.setLanguage(picked);
            },
          ),
          CeffloListTile(
            icon: LucideIcons.shield,
            label: 'Security',
            onTap: () => app.go(DRoute.settings),
          ),
          CeffloListTile(
            icon: LucideIcons.circleHelp,
            label: 'Help & Support',
            onTap: () => app.go(DRoute.helpSupport),
          ),
          const SizedBox(height: Gap.sm),
          Divider(height: 1, color: c.border),
          const SizedBox(height: Gap.lg),
          Center(
            child: InkWell(
              onTap: () => showLogOutConfirm(context, app),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.logOut, size: 20, color: c.attention),
                    const SizedBox(width: 10),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.attention,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          const AppVersionFooter(items: ['About', 'v1.2.0 (Driver)']),
        ],
      ),
    );
  }
}

/// Prototype log-out: returns the app to the locked D02 Sign In surface.
Future<void> showLogOutConfirm(BuildContext context, AppState app) =>
    showCeffloModal<void>(
      context,
      Builder(
        builder: (modalContext) => CeffloModal(
          child: Column(
            children: [
              Icon(LucideIcons.logOut, size: 34, color: modalContext.c.attention),
              const SizedBox(height: Gap.lg),
              Text(
                'Log out?',
                style: modalContext.t.displaySmall?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                'You’ll need to sign in again to\ncontinue delivering.',
                textAlign: TextAlign.center,
                style: modalContext.t.bodyMedium,
              ),
              const SizedBox(height: Gap.lg),
              CeffloPrimaryButton(
                'Log Out',
                height: 52,
                pill: false,
                onTap: () {
                  Navigator.of(modalContext).pop();
                  app.signOutPrototype();
                },
              ),
              const SizedBox(height: Gap.sm),
              CeffloSecondaryButton(
                'Cancel',
                pill: false,
                onTap: () => Navigator.of(modalContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// D35 — Edit Profile
// ---------------------------------------------------------------------------

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AppState _app = AppScope.read(context);
  late final _name = TextEditingController(text: _app.profile.fullName);
  late final _phone = TextEditingController(text: _app.profile.phone);
  late final _email = TextEditingController(text: _app.profile.email);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: 'Edit Profile',
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.xl, Gap.gutter, Gap.lg),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DriverAvatar(name: _name.text, size: 100),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Material(
                    color: CefColors.navy,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Photo upload is not wired up in this preview.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: CefColors.navy,
                        ),
                      ),
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(LucideIcons.camera, size: 17, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
          CeffloTextField(
            label: 'Full Name',
            controller: _name,
            onTap: null,
          ),
          const SizedBox(height: Gap.lg),
          CeffloPhoneField(label: 'Phone Number', controller: _phone),
          const SizedBox(height: Gap.lg),
          CeffloTextField(
            label: 'Email',
            controller: _email,
            readOnly: true,
          ),
          const SizedBox(height: Gap.xl),
          CeffloPrimaryButton(
            'Save',
            pill: false,
            onTap: () {
              app.updateProfile(
                app.profile.copyWith(
                  fullName: _name.text.trim(),
                  phone: _phone.text.trim(),
                ),
              );
              app.back();
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D36 — Vehicle Details
// ---------------------------------------------------------------------------

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late final AppState _app = AppScope.read(context);
  late String _type = _app.profile.vehicleType;
  late final _model = TextEditingController(text: _app.profile.vehicleModel);
  late final _plate = TextEditingController(text: _app.profile.plateNumber);

  @override
  void dispose() {
    _model.dispose();
    _plate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: 'Vehicle Details',
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.xl, Gap.gutter, Gap.lg),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CeffloSelectField<String>(
            label: 'Vehicle Type',
            value: _type,
            icon: LucideIcons.bike,
            options: DemoData.vehicleTypes,
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: Gap.lg),
          CeffloTextField(label: 'Model', controller: _model),
          const SizedBox(height: Gap.lg),
          CeffloTextField(
            label: 'Registration / Plate Number',
            controller: _plate,
          ),
          const SizedBox(height: Gap.xl),
          CeffloPrimaryButton(
            'Save',
            onTap: () {
              app.updateProfile(
                app.profile.copyWith(
                  vehicleType: _type,
                  vehicleModel: _model.text.trim(),
                  plateNumber: _plate.text.trim(),
                ),
              );
              app.back();
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D37 — Documents
// ---------------------------------------------------------------------------

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  static IconData _icon(String id) => switch (id) {
    'licence' => LucideIcons.idCard,
    'roadtax' => LucideIcons.car,
    _ => LucideIcons.fileText,
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: 'Documents',
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.lg, Gap.gutter, Gap.lg),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final doc in app.documents) ...[
            CeffloCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              onTap: () => _open(context, app, doc),
              child: CeffloDocumentRow(
                icon: _icon(doc.id),
                title: doc.title,
                subtitle: doc.expiryLabel ?? '',
                statusLabel: switch (doc.state) {
                  DocumentState.verified => 'Verified',
                  DocumentState.uploaded => 'In review',
                  DocumentState.missing => 'Missing',
                },
                statusTone: switch (doc.state) {
                  DocumentState.verified => ChipTone.success,
                  DocumentState.uploaded => ChipTone.warning,
                  DocumentState.missing => ChipTone.attention,
                },
                onTap: () => _open(context, app, doc),
              ),
            ),
            const SizedBox(height: Gap.md),
          ],
        ],
      ),
    );
  }

  void _open(BuildContext context, AppState app, DriverDocument doc) {
    showCeffloSheet<void>(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.gutter, 0, Gap.gutter, Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetGrabber(),
            const SizedBox(height: 6),
            Center(child: Text(doc.title, style: context.t.titleLarge)),
            const SizedBox(height: Gap.lg),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: CefColors.tintNeutral,
                borderRadius: BorderRadius.circular(Sizes.cardRadius),
                border: Border.all(color: context.c.border),
              ),
              child: DocumentThumbPlaceholder(icon: _icon(doc.id)),
            ),
            const SizedBox(height: Gap.md),
            if (doc.expiryLabel != null)
              CeffloNote(
                icon: LucideIcons.calendar,
                body: doc.expiryLabel!,
                tone: CeffloNoteTone.neutral,
              ),
            const SizedBox(height: Gap.lg),
            Builder(
              builder: (sheetContext) => CeffloPrimaryButton(
                'Submit for Review',
                trailingArrow: true,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await showCeffloSubmitFlow(
                    context,
                    submittingTitle: 'Submitting…',
                    submittingBody: 'Please wait a moment.',
                    successTitle: 'Document submitted',
                    successBody: '${doc.title} has been sent for verification.',
                    onDone: () =>
                        app.setDocumentState(doc.id, DocumentState.uploaded),
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

// ---------------------------------------------------------------------------
// D38 — Settings (D39 Select Language opens over it)
// ---------------------------------------------------------------------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: 'Settings',
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(Gap.gutter, Gap.lg, Gap.gutter, Gap.lg),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedNavRow(
            icon: LucideIcons.globe,
            label: 'Language',
            value: app.language,
            onTap: () async {
              final picked = await showLanguageSheet(context, app.language);
              if (picked != null) app.setLanguage(picked);
            },
          ),
          const SizedBox(height: Gap.md),
          OutlinedNavRow(
            icon: LucideIcons.bell,
            label: 'Notification',
            onTap: () => app.go(DRoute.notifications),
          ),
          const SizedBox(height: Gap.md),
          OutlinedNavRow(
            icon: LucideIcons.moon,
            label: 'Appearance',
            value: 'Light',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Light Mode only in this release.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: CefColors.navy,
              ),
            ),
          ),
          const SizedBox(height: Gap.md),
          OutlinedNavRow(
            icon: LucideIcons.lock,
            label: 'Security',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Security settings are not wired up in this preview.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: CefColors.navy,
              ),
            ),
          ),
          const SizedBox(height: Gap.md),
          OutlinedNavRow(
            icon: LucideIcons.circleHelp,
            label: 'Help & Support',
            onTap: () => app.go(DRoute.helpSupport),
          ),
          const SizedBox(height: Gap.xl),
          SizedBox(
            height: Sizes.buttonHeight,
            child: Material(
              color: c.card,
              borderRadius: BorderRadius.circular(Sizes.buttonRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                onTap: () => showLogOutConfirm(context, app),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                    border: Border.all(color: c.attention.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.logOut, size: 20, color: c.attention),
                      const SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.attention,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          const AppVersionFooter(items: ['About', 'v1.2.0', 'Term']),
        ],
      ),
    );
  }
}
