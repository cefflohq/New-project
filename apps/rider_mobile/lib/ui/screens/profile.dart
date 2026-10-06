import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../../data/driver_models.dart';
import '../widgets.dart';
import 'auth.dart' show showLanguageSheet, SetNewPasswordScreen;

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

import '../../core/ui_locale.dart';

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
        title: L.profile,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              DriverAvatar(name: profile.fullName, size: 82),
              const SizedBox(height: Gap.md),
              Text(
                profile.fullName,
                textAlign: TextAlign.center,
                style: context.t.displaySmall?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 3),
              Text(
                profile.phone,
                textAlign: TextAlign.center,
                style: context.t.bodyMedium,
              ),
              Text(
                profile.email,
                textAlign: TextAlign.center,
                style: context.t.bodyMedium?.copyWith(color: c.info),
              ),
              const SizedBox(height: Gap.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.pencil,
                            size: 14,
                            color: c.textLabel,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            L.edit,
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
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          Divider(height: 1, color: c.border),
          CeffloListTile(
            icon: LucideIcons.car,
            label: L.vehicleDetails,
            onTap: () => app.go(DRoute.vehicleDetails),
          ),
          CeffloListTile(
            icon: LucideIcons.fileText,
            label: L.documents,
            onTap: () => app.go(DRoute.documents),
          ),
          CeffloListTile(
            icon: LucideIcons.globe,
            label: L.language,
            value: uiLanguageNames[app.uiLocale.languageCode]!,
            onTap: () async {
              final picked = await showLanguageSheet(context, app.uiLocale);
              if (picked != null) await app.setUiLocale(picked);
            },
          ),
          CeffloListTile(
            icon: LucideIcons.shield,
            label: L.security,
            onTap: () => app.go(DRoute.settings),
          ),
          CeffloListTile(
            icon: LucideIcons.circleHelp,
            label: L.helpSupport,
            onTap: () => app.go(DRoute.helpSupport),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: c.border),
          const SizedBox(height: Gap.md),
          InkWell(
            onTap: () => showLogOutConfirm(context, app),
            borderRadius: BorderRadius.circular(Sizes.buttonRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.logOut, size: 20, color: c.attention),
                  const SizedBox(width: 10),
                  Text(
                    L.logOut,
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
          const SizedBox(height: Gap.sm),
          AppVersionFooter(items: [L.about, L.v120Driver]),
        ],
      ),
    );
  }
}

/// Log-out: prototype returns to the locked D02 Sign In surface; the real
/// build revokes the Supabase session through [AppState.signOut].
Future<void> showLogOutConfirm(BuildContext context, AppState app) =>
    showCeffloModal<void>(
      context,
      Builder(
        builder: (modalContext) => CeffloModal(
          child: Column(
            children: [
              Icon(
                LucideIcons.logOut,
                size: 34,
                color: modalContext.c.attention,
              ),
              const SizedBox(height: Gap.lg),
              Text(
                L.logOut2,
                style: modalContext.t.displaySmall?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                L.youllNeedSignAgainContinueDelivering,
                textAlign: TextAlign.center,
                style: modalContext.t.bodyMedium,
              ),
              const SizedBox(height: Gap.lg),
              CeffloPrimaryButton(
                L.logOut,
                height: 52,
                pill: false,
                onTap: () {
                  Navigator.of(modalContext).pop();
                  if (app.repo.isDemo) {
                    app.signOutPrototype();
                  } else {
                    app.signOut();
                  }
                },
              ),
              const SizedBox(height: Gap.sm),
              CeffloSecondaryButton(
                L.cancel,
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
    // Live: profile details come from the business's rider record and there
    // is no Driver-side update contract, so the screen is read-only rather
    // than a Save that would not persist.
    final live = !app.repo.isDemo;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.editProfile,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.xl,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DriverAvatar(name: _name.text, size: 100),
                if (!live)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: CefColors.navy,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => showCefToast(
                          context,
                          L.photoUploadNotWiredUpPreview,
                          error: false,
                        ),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            LucideIcons.camera,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
          CeffloTextField(label: L.fullName, controller: _name, readOnly: live),
          const SizedBox(height: Gap.lg),
          if (live)
            CeffloTextField(
              label: L.phoneNumber,
              controller: _phone,
              readOnly: true,
            )
          else
            CeffloPhoneField(label: L.phoneNumber, controller: _phone),
          const SizedBox(height: Gap.lg),
          CeffloTextField(label: L.email, controller: _email, readOnly: true),
          const SizedBox(height: Gap.xl),
          if (live)
            CeffloNote(icon: LucideIcons.info, body: L.detailsManagedByBusiness)
          else
            CeffloPrimaryButton(
              L.save,
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
    final live = !app.repo.isDemo;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.vehicleDetails,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.xl,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CeffloSelectField<String>(
            label: L.vehicleType,
            value: _type,
            icon: LucideIcons.bike,
            options: [
              ...DemoData.vehicleTypes,
              if (!DemoData.vehicleTypes.contains(_type) && _type.isNotEmpty)
                _type,
            ],
            optionLabel: vehicleTypeLabel,
            onChanged: live ? (_) {} : (v) => setState(() => _type = v),
          ),
          const SizedBox(height: Gap.lg),
          CeffloTextField(label: L.model, controller: _model, readOnly: live),
          const SizedBox(height: Gap.lg),
          CeffloTextField(
            label: L.registrationPlateNumber,
            controller: _plate,
            readOnly: live,
          ),
          const SizedBox(height: Gap.xl),
          if (live)
            CeffloNote(icon: LucideIcons.info, body: L.detailsManagedByBusiness)
          else
            CeffloPrimaryButton(
              L.save,
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
        title: L.documents,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (app.documents.isEmpty)
            CeffloNote(icon: LucideIcons.info, body: L.documentsNotYet),
          for (final doc in app.documents) ...[
            CeffloCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              onTap: () => _open(context, app, doc),
              child: CeffloDocumentRow(
                icon: _icon(doc.id),
                title: doc.title,
                subtitle: doc.expiryLabel ?? '',
                statusLabel: switch (doc.state) {
                  DocumentState.verified => L.verified,
                  DocumentState.uploaded => L.review,
                  DocumentState.missing => L.missing,
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
                L.submitReview,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await showCeffloSubmitFlow(
                    context,
                    submittingTitle: L.submitting,
                    submittingBody: L.pleaseWaitMoment,
                    successTitle: L.documentSubmitted,
                    successBody: L.hasBeenSentVerification(doc.title),
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
        title: L.settings,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedNavRow(
            icon: LucideIcons.globe,
            label: L.language,
            value: uiLanguageNames[app.uiLocale.languageCode]!,
            onTap: () async {
              final picked = await showLanguageSheet(context, app.uiLocale);
              if (picked != null) await app.setUiLocale(picked);
            },
          ),
          const SizedBox(height: Gap.md),
          OutlinedNavRow(
            icon: LucideIcons.bell,
            label: L.notification,
            onTap: () => app.go(DRoute.notifications),
          ),
          const SizedBox(height: Gap.md),
          OutlinedNavRow(
            icon: LucideIcons.moon,
            label: L.appearance,
            value: L.light,
            onTap: () =>
                showCefToast(context, L.lightModeOnlyRelease, error: false),
          ),
          const SizedBox(height: Gap.md),
          OutlinedNavRow(
            icon: LucideIcons.lock,
            label: L.security,
            // Change password with Supabase Auth (updateUser) -- the same
            // screen as password recovery, opened over Settings.
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (route) => SetNewPasswordScreen(
                  onBack: () => Navigator.of(route).pop(),
                  onUpdated: () {
                    Navigator.of(route).pop();
                    showCefToast(context, L.passwordChanged);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: Gap.md),
          OutlinedNavRow(
            icon: LucideIcons.circleHelp,
            label: L.helpSupport,
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
                    border: Border.all(
                      color: c.attention.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.logOut, size: 20, color: c.attention),
                      const SizedBox(width: 10),
                      Text(
                        L.logOut,
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
          AppVersionFooter(items: [L.about, 'v1.2.0', L.term]),
        ],
      ),
    );
  }
}
