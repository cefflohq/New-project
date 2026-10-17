import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../../data/driver_models.dart';
import '../../data/rider_repository.dart' show RepositoryError;
import '../widgets.dart';
import 'auth.dart' show showLanguageSheet, SetNewPasswordScreen;
import 'payment.dart' show VehicleChangePaymentScreen;
import 'documents.dart' show LiveDocumentsScreen;

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

import '../../core/ui_locale.dart';

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

/// Initials avatar. No stock portrait is bundled with the prototype, so the
/// reference's photo slot is drawn as the Driver's initials on the brand
/// navy instead of a fabricated likeness.
/// The signed-in driver's photo URL, shared by Profile and Edit Profile.
final ValueNotifier<String?> driverAvatarUrl = ValueNotifier(null);
String? _avatarFor;

/// Loads the driver's photo once per signed-in account (live builds).
void loadDriverAvatar(AppState app) {
  final uid = app.repo.currentUser?.id;
  if (app.repo.isDemo || uid == null || _avatarFor == uid) return;
  _avatarFor = uid;
  driverAvatarUrl.value = null;
  app.repo.myAvatarUrl().then((u) => driverAvatarUrl.value = u);
}

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
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: driverAvatarUrl,
    builder: (context, url, _) => url != null
        ? ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialsCircle(),
            ),
          )
        : _initialsCircle(),
  );

  Widget _initialsCircle() => Container(
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
  const AppVersionFooter({
    super.key,
    required this.items,
    this.taps = const {},
  });
  final List<String> items;

  /// Items that open something (Privacy, Terms), by index.
  final Map<int, VoidCallback> taps;

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
        if (taps[i] == null)
          Text(items[i], style: context.t.labelSmall)
        else
          InkWell(
            onTap: taps[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                items[i],
                style: context.t.labelSmall?.copyWith(
                  color: const Color(0xFF0060FE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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
    loadDriverAvatar(app);
    final profile = app.profile;
    final c = context.c;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.profile,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.sheet,
        Gap.lg,
        Gap.sheet,
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
            // Straight to Change password (it opened Settings, a screen
            // repeating Profile's own rows).
            onTap: () => openChangePassword(context),
          ),
          CeffloListTile(
            icon: LucideIcons.circleHelp,
            label: L.helpSupport,
            onTap: () => app.go(DRoute.helpSupport),
          ),
          // Log out and the version line scroll with the menu: one white
          // card, no pinned strip or edge above them (Founder 2026-10-17).
          const SizedBox(height: Gap.lg),
          Center(
            child: InkWell(
              onTap: () => showLogOutConfirm(context, app),
              borderRadius: BorderRadius.circular(Sizes.buttonRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
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
          ),
          Center(
            child: TextButton(
              onPressed: () => showDeleteAccount(context, app),
              child: Text(
                L.delLink,
                style: context.t.labelMedium?.copyWith(
                  color: context.c.textSecondary,
                ),
              ),
            ),
          ),
          // Privacy and Terms sit with About, keeping the menu short
          // (Founder 2026-10-16).
          AppVersionFooter(
            items: [L.legalPrivacyShort, L.legalTermsShort, L.v120Driver],
            taps: {
              0: () => app.go(DRoute.privacyPolicy),
              1: () => app.go(DRoute.termsOfService),
            },
          ),
        ],
      ),
    );
  }
}

/// Log-out: prototype returns to the locked D02 Sign In surface; the real
/// build revokes the Supabase session through [AppState.signOut].
/// Delete account (Google Play / PDPA): explained, then closed for good.
Future<void> showDeleteAccount(BuildContext context, AppState app) {
  final reason = TextEditingController();
  return showCeffloModal<void>(
    context,
    Builder(
      builder: (modalContext) => CeffloModal(
        child: Column(
          children: [
            Icon(LucideIcons.userX, size: 34, color: modalContext.c.attention),
            const SizedBox(height: Gap.lg),
            Text(
              L.delTitle,
              style: modalContext.t.displaySmall?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: Gap.sm),
            Text(
              L.delBody,
              textAlign: TextAlign.center,
              style: modalContext.t.bodyMedium,
            ),
            const SizedBox(height: Gap.md),
            CeffloTextField(
              label: L.delReasonHint,
              controller: reason,
              maxLines: 2,
            ),
            const SizedBox(height: Gap.lg),
            CeffloPrimaryButton(
              L.delConfirm,
              height: 52,
              pill: false,
              onTap: () async {
                final why = reason.text.trim();
                Navigator.of(modalContext).pop();
                if (app.repo.isDemo) return app.signOutPrototype();
                try {
                  await app.repo.deleteAccount(why.isEmpty ? null : why);
                  if (context.mounted) showCefToast(context, L.delDone);
                  await app.signOut();
                } on RepositoryError catch (e) {
                  if (context.mounted) {
                    showCefToast(context, e.message, error: true);
                  }
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
}

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

  /// A new profile photo: camera or gallery, square-cropped by the circle.
  Future<void> _changePhoto(bool live) async {
    if (!live) {
      showCefToast(context, L.photoUploadNotWiredUpPreview);
      return;
    }
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (f == null || !mounted) return;
    setState(() => _busy = true);
    try {
      driverAvatarUrl.value = await _app.repo.uploadAvatar(
        await f.readAsBytes(),
      );
      if (mounted) showCefToast(context, L.detailsSaved);
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  late final _name = TextEditingController(text: _app.profile.fullName);
  late final _phone = TextEditingController(text: _app.profile.phone);
  late final _email = TextEditingController(text: _app.profile.email);
  bool _busy = false;

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
    // Live: the Driver edits their own name and phone (update_my_driver_profile;
    // email stays the sign-in identity).
    final live = !app.repo.isDemo;
    return CeffloNavySheetScaffold(
      header: CeffloScreenHeader(
        title: L.editProfile,
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        Gap.sheet,
        Gap.xl,
        Gap.sheet,
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
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Material(
                    color: CefColors.navy,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _changePhoto(live),
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
          CeffloTextField(label: L.fullName, controller: _name),
          const SizedBox(height: Gap.lg),
          CeffloPhoneField(label: L.phoneNumber, controller: _phone),
          const SizedBox(height: Gap.lg),
          CeffloTextField(label: L.email, controller: _email, readOnly: true),
          const SizedBox(height: Gap.xl),
          CeffloPrimaryButton(
            L.save,
            pill: false,
            busy: _busy,
            onTap: _busy
                ? null
                : () async {
                    if (!live) {
                      app.updateProfile(
                        app.profile.copyWith(
                          fullName: _name.text.trim(),
                          phone: _phone.text.trim(),
                        ),
                      );
                      app.back();
                      return;
                    }
                    setState(() => _busy = true);
                    try {
                      await app.saveMyDriverProfile(
                        fullName: _name.text.trim(),
                        phone: _phone.text.trim(),
                        vehicleType: app.myVehicleType,
                        plate: app.profile.plateNumber,
                      );
                      if (!context.mounted) return;
                      showCefToast(context, L.detailsSaved);
                      app.back();
                    } on RepositoryError catch (e) {
                      if (context.mounted) {
                        showCefToast(context, e.message, error: true);
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
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
  late String _type = _app.myVehicleType;
  bool _busy = false;
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
        Gap.sheet,
        Gap.xl,
        Gap.sheet,
        Gap.lg,
      ),
      footer: CeffloPrimaryButton(
        L.save,
        busy: _busy,
        onTap: _busy
            ? null
            : () async {
                if (!live) {
                  app.updateProfile(
                    app.profile.copyWith(
                      vehicleType: _type,
                      vehicleModel: _model.text.trim(),
                      plateNumber: _plate.text.trim(),
                    ),
                  );
                  app.back();
                  return;
                }
                // The model is free: save it on its own first.
                final model = _model.text.trim();
                if (model != app.profile.vehicleModel) {
                  setState(() => _busy = true);
                  try {
                    await app.repo.saveVehicleModel(model);
                    app.updateProfile(
                      app.profile.copyWith(vehicleModel: model),
                    );
                  } on RepositoryError catch (e) {
                    if (context.mounted) {
                      showCefToast(context, e.message, error: true);
                    }
                    return;
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                }
                if (!context.mounted) return;
                // Founder 2026-10-06: a vehicle / plate change is paid
                // (RM50). It goes through the change-fee screen and is
                // applied only after a confirmed payment.
                final plate = _plate.text.trim();
                if (_type == app.myVehicleType &&
                    plate == app.profile.plateNumber) {
                  showCefToast(context, L.detailsSaved);
                  app.back();
                  return;
                }
                final paid = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => VehicleChangePaymentScreen(
                      fromVehicle: app.myVehicleType,
                      toVehicle: _type,
                      fromPlate: app.profile.plateNumber,
                      toPlate: plate,
                    ),
                  ),
                );
                if (paid == true && context.mounted) app.back();
              },
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
            onChanged: (v) => setState(() => _type = v),
          ),
          // Model: free to change, kept with the registration details.
          const SizedBox(height: Gap.lg),
          CeffloTextField(label: L.model, controller: _model),
          const SizedBox(height: Gap.lg),
          CeffloTextField(label: L.registrationPlateNumber, controller: _plate),
          if (live) ...[
            const SizedBox(height: Gap.md),
            CeffloNote(icon: LucideIcons.wallet, body: L.vehicleChangePaidNote),
          ],
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

  // Real and prototype builds share the Marketplace verification screen
  // (Founder 2026-10-13); the old three-document demo list is gone.
  @override
  Widget build(BuildContext context) => const LiveDocumentsScreen();
}

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
        Gap.sheet,
        Gap.lg,
        Gap.sheet,
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
            onTap: () => openChangePassword(context),
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

/// Security: change password with Supabase Auth (updateUser), the same
/// screen as password recovery, opened over the current screen.
void openChangePassword(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (route) => SetNewPasswordScreen(
      onBack: () => Navigator.of(route).pop(),
      onUpdated: () {
        Navigator.of(route).pop();
        showCefToast(context, L.passwordChanged);
      },
    ),
  ),
);
