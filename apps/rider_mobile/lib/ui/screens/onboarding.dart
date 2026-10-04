import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../../data/driver_models.dart';
import '../../data/rider_repository.dart' show RepositoryError;
import '../brand.dart';
import '../widgets.dart';
import 'auth.dart' show BusinessIdentityRow;

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// D11 — No Business Connected (greeting variant, inside the app shell)
// ---------------------------------------------------------------------------

class NoBusinessConnectedHomeScreen extends StatelessWidget {
  const NoBusinessConnectedHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloNavySheetScaffold(
      header: CeffloBrandHeader(
        onBell: () => app.go(DRoute.notifications),
        child: Padding(
          padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L.goodMorning,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(app.profile.fullName, style: context.t.displayMedium),
              const SizedBox(height: 4),
              Text(
                L.letsGetConnected,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: Gap.sm),
          Container(
            width: 116,
            height: 116,
            decoration: const BoxDecoration(
              color: CefColors.tintInfo,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(LucideIcons.store, size: 52, color: CefColors.navy),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1668E3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          Text(
            L.noBusinessConnected,
            textAlign: TextAlign.center,
            style: context.t.displaySmall,
          ),
          const SizedBox(height: Gap.sm),
          Text(
            L.accountReadyButYoureNotConnected,
            textAlign: TextAlign.center,
            style: context.t.bodyLarge,
          ),
          const SizedBox(height: Gap.section),
          _connectOptions(context, app),
        ],
      ),
    );
  }
}

Widget _connectOptions(BuildContext context, AppState app) => Container(
  decoration: BoxDecoration(
    color: CefColors.tintInfo,
    borderRadius: BorderRadius.circular(Sizes.cardRadius),
  ),
  child: Column(
    children: [
      CeffloOptionRow(
        icon: LucideIcons.mail,
        title: L.iHaveInvitation,
        subtitle: L.joinBusinessInviteLinkCode,
        onTap: () => app.go(DRoute.joinBusiness),
      ),
      Divider(height: 1, color: context.c.border, indent: 12, endIndent: 12),
      CeffloOptionRow(
        icon: LucideIcons.search,
        title: L.checkEmail,
        subtitle: L.ifYouveReceivedInvitationTapLink,
        onTap: () => app.go(DRoute.joinBusiness),
      ),
      Divider(height: 1, color: context.c.border, indent: 12, endIndent: 12),
      CeffloOptionRow(
        icon: LucideIcons.circleHelp,
        title: L.needHelp,
        subtitle: L.contactSupportIfYoureUnsure,
        onTap: () => app.go(DRoute.helpSupport),
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// D12 — Driver Details
// ---------------------------------------------------------------------------

class DriverDetailsScreen extends StatefulWidget {
  const DriverDetailsScreen({super.key});

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  late final _app = AppScope.read(context);
  // The real build seeds from the Driver's own relationship, never demo data.
  late final _name = TextEditingController(
    text: _app.repo.isDemo ? DemoData.profile.fullName : _app.profile.fullName,
  );
  late final _phone = TextEditingController(
    text: _app.repo.isDemo ? '12 345 6789' : _app.profile.phone,
  );
  final _plate = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _plate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloAuthScaffold(
      onBack: app.back,
      title: L.driverDetails,
      subtitle: L.tellUsBitMoreSoBusiness,
      sheetPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.xl,
      ),
      sheet: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionRow(icon: LucideIcons.package, label: L.profileInformation),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              const AvatarPicker(size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L.addPhoto, style: context.t.titleSmall),
                    const SizedBox(height: 2),
                    Text(L.useClearPhotoFace, style: context.t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          CeffloTextField(
            label: L.fullName,
            controller: _name,
            icon: LucideIcons.user,
          ),
          const SizedBox(height: Gap.md),
          CeffloPhoneField(label: L.phoneNumber, controller: _phone),
          const SizedBox(height: Gap.section),
          Divider(height: 1, color: context.c.border),
          const SizedBox(height: Gap.section),
          SectionRow(icon: LucideIcons.bike, label: L.vehicleInformation),
          const SizedBox(height: Gap.lg),
          // Vehicle type follows V2 Choose Your Vehicle (mandatory there);
          // shown here read-only, changed only by going back to V2.
          _ReadOnlyField(
            label: L.vehicleType,
            value: vehicleTypeLabel(app.registrationVehicle),
            icon: LucideIcons.bike,
          ),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: L.vehicleNumberPlate,
            controller: _plate,
            hint: L.eGVaa1234,
            icon: LucideIcons.idCard,
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            L.continueText2,
            onTap: () => app.go(DRoute.personalDetails),
          ),
        ],
      ),
    );
  }
}

/// Icon + bold label section heading used inside the detail forms.
class SectionRow extends StatelessWidget {
  const SectionRow({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 24, color: CefColors.navy),
      const SizedBox(width: 12),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: context.c.textPrimary,
        ),
      ),
    ],
  );
}

/// Circular avatar with the small camera badge (D12, D12.1, D35).
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key, this.size = 72, this.onTap});
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Color(0xFFDDE4EF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.user,
              size: size * 0.52,
              color: const Color(0xFF9AA8BF),
            ),
          ),
          Positioned(
            right: -2,
            bottom: 0,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: CefColors.navy,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                LucideIcons.camera,
                size: size * 0.16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// D12.1 — Personal Details
// ---------------------------------------------------------------------------

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late final _app = AppScope.read(context);
  late final _demo = _app.repo.isDemo;
  // The real build seeds from the Driver's own relationship, never demo data.
  late final _name = TextEditingController(
    text: _demo ? DemoData.profile.fullName : _app.profile.fullName,
  );
  late final _phone = TextEditingController(
    text: _demo ? '12 345 6789' : _app.profile.phone,
  );
  late final _dob = TextEditingController(
    text: _demo ? DemoData.profile.dateOfBirth : '',
  );
  late final _email = TextEditingController(
    text: _demo ? DemoData.profile.email : _app.profile.email,
  );
  late final _address = TextEditingController(
    text: _demo ? DemoData.profile.address : '',
  );
  final _emergency = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _dob.dispose();
    _email.dispose();
    _address.dispose();
    _emergency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloAuthScaffold(
      onBack: app.back,
      title: L.personalDetails,
      subtitle: L.letsGetKnowInformationWillShared,
      headerTrailing: const AvatarPicker(size: 66),
      sheetPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.xl,
      ),
      sheet: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CeffloTextField(
            label: L.fullName,
            controller: _name,
            icon: LucideIcons.user,
          ),
          const SizedBox(height: Gap.md),
          CeffloPhoneField(label: L.phoneNumber, controller: _phone),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: L.dateBirth,
            controller: _dob,
            icon: LucideIcons.calendar,
            readOnly: true,
          ),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: L.email,
            controller: _email,
            icon: LucideIcons.mail,
            readOnly: true,
            suffix: CeffloStatusChip(L.verified),
          ),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: L.address,
            controller: _address,
            icon: LucideIcons.mapPin,
          ),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: L.emergencyContactOptional,
            controller: _emergency,
            hint: 'e.g. 16 123 4567',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            L.next,
            onTap: () => app.go(DRoute.vehicleAndDocuments),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D12.2 — Vehicle & Documents  (+ D12.3 submitting / success pop-ups)
// ---------------------------------------------------------------------------

class VehicleAndDocumentsScreen extends StatefulWidget {
  const VehicleAndDocumentsScreen({super.key});

  @override
  State<VehicleAndDocumentsScreen> createState() =>
      _VehicleAndDocumentsScreenState();
}

class _VehicleAndDocumentsScreenState extends State<VehicleAndDocumentsScreen> {
  late final _app = AppScope.read(context);
  // Carried from V3 Your Driver Details (not asked twice).
  late final _plate = TextEditingController(
    text: _app.registrationPlate.isNotEmpty
        ? _app.registrationPlate
        : (_app.repo.registration['vehicle_plate']?.toString() ?? ''),
  );

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.read(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    showCeffloModal(context, const SubmittingDetailsModal());
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    navigator.pop();
    await showCeffloModal(
      context,
      ApplicationSubmittedModal(
        onDone: () {
          navigator.pop();
          app.setStage(DriverStage.pendingReview);
          app.resetTo(DRoute.pendingReview);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloAuthScaffold(
      onBack: app.back,
      title: L.vehicleDocuments,
      subtitle: L.addVehicleDetailsRequiredDocumentsComplete,
      sheetPadding: const EdgeInsets.fromLTRB(
        Gap.gutter,
        Gap.lg,
        Gap.gutter,
        Gap.xl,
      ),
      sheet: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionRow(icon: LucideIcons.bike, label: L.vehicleInformation),
          const SizedBox(height: Gap.lg),
          // Vehicle type follows V2 Choose Your Vehicle (read-only here).
          _ReadOnlyField(
            label: L.vehicleType,
            value: vehicleTypeLabel(app.registrationVehicle),
            icon: LucideIcons.bike,
          ),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: L.vehicleNumberPlate,
            controller: _plate,
            icon: LucideIcons.idCard,
          ),
          const SizedBox(height: Gap.section),
          Divider(height: 1, color: context.c.border),
          const SizedBox(height: Gap.section),
          if (app.onboardingDocuments.isNotEmpty) ...[
            SectionRow(icon: LucideIcons.fileText, label: L.requiredDocuments),
            const SizedBox(height: Gap.sm),
          ],
          for (final doc in app.onboardingDocuments)
            CeffloDocumentRow(
              icon: doc.id == 'licence' ? LucideIcons.idCard : LucideIcons.bike,
              title: doc.title,
              subtitle: doc.helper,
              statusLabel: L.uploaded,
              thumbnail: DocumentThumbPlaceholder(
                icon: doc.id == 'licence'
                    ? LucideIcons.idCard
                    : LucideIcons.fileText,
              ),
              onRemove: () {},
            ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(L.submitReview, onTap: _submit),
          const SizedBox(height: Gap.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.lock, size: 18, color: context.c.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  L.informationSecureOnlySharedBusiness,
                  style: context.t.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The D12.2 "Submitting your details" pop-up: an arc ring (the reference
/// draws a partial-ring spinner here, not the four-dot motif) over a
/// checklist of what is being sent.
class SubmittingDetailsModal extends StatelessWidget {
  const SubmittingDetailsModal({super.key});

  @override
  Widget build(BuildContext context) => CeffloModal(
    width: 320,
    child: Column(
      children: [
        const SizedBox(
          width: 62,
          height: 62,
          child: CircularProgressIndicator(
            strokeWidth: 7,
            strokeCap: StrokeCap.round,
            color: Color(0xFF1668E3),
            backgroundColor: Color(0xFFE2EAF7),
          ),
        ),
        const SizedBox(height: Gap.lg),
        Text(
          L.submittingDetails,
          style: context.t.displaySmall?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: Gap.sm),
        Text(
          L.pleaseWaitWhileWeSendInformation,
          textAlign: TextAlign.center,
          style: context.t.bodyMedium,
        ),
        const SizedBox(height: Gap.lg),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: CefColors.tintInfo,
            borderRadius: BorderRadius.circular(Sizes.innerRadius),
          ),
          child: Column(
            children: [
              _row(context, LucideIcons.user, L.personalDetails2),
              _row(context, LucideIcons.bike, L.vehicleDetails2),
              _row(context, LucideIcons.fileText, L.documents),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _row(BuildContext context, IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 21, color: CefColors.navy),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: context.t.titleSmall)),
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF1668E3),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, size: 13, color: Colors.white),
        ),
      ],
    ),
  );
}

/// D12.3 — "Application Submitted!". Same modal geometry as the processing
/// state it replaces.
class ApplicationSubmittedModal extends StatelessWidget {
  const ApplicationSubmittedModal({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => CeffloModal(
    width: 320,
    child: Column(
      children: [
        const CeffloSuccessTick(size: 74, glow: true),
        const SizedBox(height: Gap.lg),
        Text(
          L.applicationSubmitted,
          style: context.t.displaySmall?.copyWith(fontSize: 21),
        ),
        const SizedBox(height: Gap.sm),
        Text(
          L.detailsHaveBeenSentBusinessReview,
          textAlign: TextAlign.center,
          style: context.t.bodyMedium,
        ),
        const SizedBox(height: Gap.lg),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: CefColors.tintNeutral,
            borderRadius: BorderRadius.circular(Sizes.innerRadius),
          ),
          child: Column(
            children: [
              _row(context, LucideIcons.user, L.personalDetails2),
              _row(context, LucideIcons.bike, L.vehicleDetails2),
              _row(context, LucideIcons.fileText, L.documents),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        CeffloNote(
          icon: LucideIcons.clock,
          title: L.pendingReview2,
          body: L.wellNotifyOnceBusinessHasReviewed,
          tone: CeffloNoteTone.warning,
        ),
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton(L.done, onTap: onDone, height: 52),
      ],
    ),
  );

  Widget _row(BuildContext context, IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: CefColors.navy),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: context.t.titleSmall)),
        Icon(LucideIcons.circleCheck, size: 17, color: context.c.success),
        const SizedBox(width: 5),
        Text(
          L.submitted,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.c.success,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D14.1 — Pending Review
// ---------------------------------------------------------------------------

class PendingReviewScreen extends StatelessWidget {
  const PendingReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloNavySheetScaffold(
      header: CeffloBrandHeader(
        onBell: () => app.go(DRoute.notifications),
        child: Padding(
          padding: const EdgeInsets.only(
            top: Gap.lg,
            bottom: Gap.xl,
            right: Gap.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L.applicationUnderReview,
                style: context.t.displayMedium?.copyWith(fontSize: 25),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                L.thanksSubmittingDetailsWellNotifyOnce,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CeffloNote(
            icon: LucideIcons.clock,
            title: L.pendingReview2,
            body: L.applicationBeingReviewedByBusiness,
            tone: CeffloNoteTone.warning,
          ),
          const SizedBox(height: Gap.md),
          ChecklistBlock(
            rows: [
              (L.personalDetails, L.submitted, LucideIcons.user),
              (L.vehicleDetails, L.submitted, LucideIcons.bike),
              (L.documents, L.submitted, LucideIcons.fileText),
            ],
          ),
          const SizedBox(height: Gap.md),
          CeffloNote(
            icon: LucideIcons.info,
            body: L.wellNotifyAppOnceAccountApproved,
          ),
          const SizedBox(height: Gap.lg),
          CeffloSecondaryButton(
            L.viewSubmittedDetails,
            trailingChevron: true,
            onTap: () => app.go(DRoute.personalDetails),
          ),
          const SizedBox(height: Gap.md),
          // Prototype scaffolding, labelled as such. In the product this
          // screen advances when the *business* approves the Driver, and no
          // reference draws a CTA out of it — so the preview needs a way to
          // reach D14.2 without inventing a product control. The real build
          // never shows it: approval only comes from the business.
          if (app.repo.isDemo)
            Center(
              child: CeffloTextLink(
                L.previewSimulateApproval,
                fontSize: 13,
                weight: FontWeight.w600,
                color: context.c.textSecondary,
                onTap: () {
                  app.setStage(DriverStage.approved);
                  app.resetTo(DRoute.approved);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// The repeated "three completed steps" block (D14.1, D14.2, D18).
class ChecklistBlock extends StatelessWidget {
  const ChecklistBlock({super.key, required this.rows});

  /// (title, supporting line, leading icon)
  final List<(String, String, IconData)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: CefColors.tintNeutral,
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
    ),
    child: Column(
      children: [
        for (final (title, body, icon) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: CefColors.navy),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.t.titleSmall),
                      const SizedBox(height: 1),
                      Text(body, style: context.t.bodySmall),
                    ],
                  ),
                ),
                const CeffloSuccessTick(size: 26),
              ],
            ),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D14.2 — Approved
// ---------------------------------------------------------------------------

class ApprovedScreen extends StatelessWidget {
  const ApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloNavySheetScaffold(
      header: CeffloBrandHeader(
        onBell: () => app.go(DRoute.notifications),
        child: Padding(
          padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Center(child: CeffloSuccessTick(size: 88, glow: true)),
              const SizedBox(height: Gap.lg),
              Center(
                child: Text(L.youreApproved, style: context.t.displayMedium),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                L.welcomeTeamAccountNowActiveYoure,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChecklistBlock(
            rows: [
              (L.personalDetails, L.verified, LucideIcons.user),
              (L.vehicleDetails, L.verified, LucideIcons.bike),
              (L.documents, L.verified, LucideIcons.fileText),
            ],
          ),
          const SizedBox(height: Gap.md),
          CeffloNote(
            icon: LucideIcons.shieldCheck,
            title: L.accountActive,
            body: L.canNowAcceptDeliveryRunsStart,
            tone: CeffloNoteTone.success,
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            L.goToday,
            onTap: () {
              app.setStage(DriverStage.active);
              app.resetTo(DRoute.today);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D14.3 — Ready to Go
// ---------------------------------------------------------------------------

class ReadyToGoScreen extends StatelessWidget {
  const ReadyToGoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloNavySheetScaffold(
      header: CeffloBrandHeader(
        onBell: () => app.go(DRoute.notifications),
        child: Padding(
          padding: const EdgeInsets.only(
            top: Gap.lg,
            bottom: Gap.lg,
            right: Gap.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L.goodSee,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(app.profile.fullName, style: context.t.displayMedium),
              const SizedBox(height: 4),
              Text(
                L.readyHitRoad,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
              const SizedBox(height: Gap.lg),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF071A33).withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(Sizes.cardRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF17A34A).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            L.accountActive2,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            L.youreAllSetStartDelivering,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CefColors.onNavyMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(L.quickStart, style: context.t.titleLarge),
          const SizedBox(height: Gap.md),
          CeffloCard(
            padding: EdgeInsets.zero,
            child: CeffloOptionRow(
              icon: LucideIcons.play,
              title: L.goOnline,
              subtitle: L.startAcceptingDeliveryRuns,
              onTap: () => AppScope.read(context).resetTo(DRoute.today),
            ),
          ),
          const SizedBox(height: Gap.cardGap),
          CeffloCard(
            padding: EdgeInsets.zero,
            child: CeffloOptionRow(
              icon: LucideIcons.map,
              title: L.viewAvailableJobs,
              subtitle: L.seeNearbyDeliveryRequests,
              onTap: () =>
                  app.go(DRoute.runDetails, entityId: app.currentRun.id),
            ),
          ),
          const SizedBox(height: Gap.cardGap),
          CeffloCard(
            padding: EdgeInsets.zero,
            child: CeffloOptionRow(
              icon: LucideIcons.circleHelp,
              title: L.helpSupport,
              subtitle: L.getHelpAnytime,
              onTap: () => app.go(DRoute.helpSupport),
            ),
          ),
          const SizedBox(height: Gap.lg),
          const DeliverMorePromo(),
        ],
      ),
    );
  }
}

/// The "Deliver More For Local Businesses" promotional panel at the foot of
/// D14.3. No photographic asset for it exists in the repo, so the rider
/// silhouette the reference shows is represented by the Cefflo mark on a
/// tinted panel rather than a fabricated photo.
class DeliverMorePromo extends StatelessWidget {
  const DeliverMorePromo({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Gap.cardPadding),
    decoration: BoxDecoration(
      color: const Color(0xFFDDE7F5),
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L.deliverMoreLocalBusinesses,
                style: context.t.titleMedium?.copyWith(height: 1.25),
              ),
              const SizedBox(height: 6),
              Text(
                L.partGrowingCommunityLocalDeliveryHeroes,
                style: context.t.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: Gap.md),
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: CefColors.navy,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: CeffloLogoMark(size: 46),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D16 — No Business Connected
// ---------------------------------------------------------------------------

class NoBusinessConnectedScreen extends StatelessWidget {
  const NoBusinessConnectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CeffloNavySheetScaffold(
      header: CeffloBrandHeader(
        onBell: () => app.go(DRoute.notifications),
        child: Padding(
          padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L.youreNotConnectedBusinessYet,
                      style: context.t.displayMedium?.copyWith(fontSize: 25),
                    ),
                    const SizedBox(height: Gap.md),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: L.joinBusinessStartDelivering),
                          TextSpan(
                            text: 'Cefflo',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: CefColors.onNavy.withValues(alpha: 0.95),
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: CefColors.onNavyMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gap.md),
              const _StorefrontBadge(),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: CefColors.tintNeutral,
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
        ),
        child: Column(
          children: [
            CeffloOptionRow(
              icon: LucideIcons.link,
              title: L.gotInvitation,
              subtitle: L.joinBusinessInviteLinkFromEmployer,
              onTap: () => app.go(DRoute.joinBusiness),
            ),
            Divider(
              height: 1,
              color: context.c.border,
              indent: 12,
              endIndent: 12,
            ),
            CeffloOptionRow(
              icon: LucideIcons.qrCode,
              title: L.scanQrCode,
              subtitle: L.useQrCodeFromBusinessJoin,
              onTap: () => app.go(DRoute.joinBusiness),
            ),
            Divider(
              height: 1,
              color: context.c.border,
              indent: 12,
              endIndent: 12,
            ),
            CeffloOptionRow(
              icon: LucideIcons.mail,
              title: L.needHelp,
              subtitle: L.contactBusinessOwnerInvitation,
              onTap: () => app.go(DRoute.helpSupport),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorefrontBadge extends StatelessWidget {
  const _StorefrontBadge();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 104,
    height: 104,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(LucideIcons.store, size: 52, color: CefColors.navy),
        ),
        Positioned(
          right: 0,
          bottom: 10,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: CefColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.link,
              size: 20,
              color: CefColors.onAccent,
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// D17 — Join Business
// ---------------------------------------------------------------------------

/// The invitation token from a pasted invite link (`?token=`), or a bare
/// pasted token. Null when neither is present.
String? invitationTokenFrom(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  final fromQuery = Uri.tryParse(text)?.queryParameters['token'];
  if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
  return RegExp(r'^[0-9a-fA-F]{32,}$').hasMatch(text) ? text : null;
}

/// The token of a business's permanent invite link (`?link=` / `?join=`),
/// or a bare 48-hex token. Null for anything else.
String? openInviteTokenFrom(String input) {
  final text = input.trim();
  final uri = Uri.tryParse(text);
  final fromQuery =
      uri?.queryParameters['link'] ?? uri?.queryParameters['join'];
  final token = fromQuery ?? text;
  return RegExp(r'^[0-9a-f]{48}$').hasMatch(token) ? token : null;
}

class JoinBusinessScreen extends StatefulWidget {
  const JoinBusinessScreen({super.key});

  @override
  State<JoinBusinessScreen> createState() => _JoinBusinessScreenState();
}

class _JoinBusinessScreenState extends State<JoinBusinessScreen> {
  late final _link = TextEditingController(
    text: AppScope.read(context).joinToken ?? '',
  );
  final _name = TextEditingController();
  final _phone = TextEditingController();
  int _tab = 0;
  bool _busy = false;
  String? _error;

  /// A business's permanent invite link (or its bare token).
  String? get _openToken => openInviteTokenFrom(_link.text);

  @override
  void initState() {
    super.initState();
    // The name / phone fields appear as soon as a permanent link is pasted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _link.addListener(() => setState(() {}));
      final open = _openToken;
      if (open != null) _resolveTarget(open);
    });
  }

  /// The target business of the permanent link (shown before joining).
  String? _targetBusiness;

  /// Set when this account is already part of the target business.
  bool _alreadyJoined = false;

  Future<void> _resolveTarget(String token) async {
    try {
      final link = await AppScope.read(context).repo.resolveInviteLink(token);
      if (mounted) {
        setState(() => _targetBusiness = link?['business_name'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _joinOpenLink(String token) async {
    final app = AppScope.read(context);
    if (_name.text.trim().isEmpty || _phone.text.trim().length < 7) {
      setState(() => _error = L.enterNamePhone);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await app.repo.joinViaInviteLink(
        token: token,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      final business = _targetBusiness ?? 'Cefflo';
      // Already a rider of this business: a terminal state the rider
      // acknowledges -- never a silent return to home.
      if (res['status'] == 'active' || res['status'] == 'inactive') {
        await app.finishJoin();
        if (mounted) setState(() => _alreadyJoined = true);
        return;
      }
      await app.finishJoin();
      if (mounted) showCefToast(context, L.joinRequestSentTo(business));
      // Pending until the business approves: reloading lands on the stage
      // the backend now reports (Pending Review, or the rider's existing
      // active business).
      await app.loadSession();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final app = AppScope.read(context);
    if (app.repo.isDemo) {
      app.go(DRoute.businessJoined);
      return;
    }
    final open = _openToken;
    if (open != null) return _joinOpenLink(open);
    final token = invitationTokenFrom(_link.text);
    if (token == null) {
      setState(() => _error = L.pasteFullInvitationLink);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await app.repo.acceptRiderInvitation(token);
      // The accepted relationship is pending until the business approves
      // it; reloading lands on the stage the backend now reports.
      await app.loadSession();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _link.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // QR scanning is not built yet: the live app offers the link only.
    final demo = app.repo.isDemo;
    return CeffloNavySheetScaffold(
      header: CeffloBrandHeader(
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
        centerWordmark: true,
        child: Padding(
          padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L.joinBusiness,
                style: context.t.displayMedium?.copyWith(fontSize: 26),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                L.enterInvitationLinkCodeProvidedBy,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _alreadyJoined
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  L.alreadyPartOf(_targetBusiness ?? 'Cefflo'),
                  textAlign: TextAlign.center,
                  style: context.t.titleMedium,
                ),
                const SizedBox(height: Gap.lg),
                CeffloPrimaryButton(
                  L.continueText3,
                  onTap: () => app.loadSession(),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_targetBusiness != null && _openToken != null) ...[
                  Text(
                    L.joiningBusiness(_targetBusiness!),
                    style: context.t.titleMedium,
                  ),
                  const SizedBox(height: Gap.md),
                ],
                if (demo) ...[
                  CeffloSegmentedTabs(
                    labels: [L.inviteLink, L.qrCode],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: Gap.lg),
                ],
                CeffloTextField(
                  label: L.invitationLink,
                  controller: _link,
                  hint: 'https://...',
                  icon: LucideIcons.link,
                ),
                // A permanent invite link asks who is joining (phone required);
                // the business approves before any access.
                if (_openToken != null) ...[
                  const SizedBox(height: Gap.md),
                  CeffloTextField(
                    label: L.fullName,
                    controller: _name,
                    icon: LucideIcons.user,
                  ),
                  const SizedBox(height: Gap.md),
                  CeffloTextField(
                    label: L.phoneNumber,
                    controller: _phone,
                    icon: LucideIcons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: Gap.sm),
                  Text(
                    _error!,
                    style: context.t.bodySmall?.copyWith(
                      color: context.c.attention,
                    ),
                  ),
                ],
                const SizedBox(height: Gap.lg),
                CeffloPrimaryButton(L.continueText2, busy: _busy, onTap: _join),
                if (demo) ...[
                  const SizedBox(height: Gap.lg),
                  Center(
                    child: Text(L.orSeparator, style: context.t.bodyMedium),
                  ),
                  const SizedBox(height: Gap.md),
                  Container(
                    decoration: BoxDecoration(
                      color: CefColors.tintNeutral,
                      borderRadius: BorderRadius.circular(Sizes.cardRadius),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Sizes.cardRadius),
                        onTap: () => setState(() => _tab = 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.qrCode,
                                size: 24,
                                color: CefColors.navy,
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Text(
                                  L.scanQrCode,
                                  style: context.t.titleSmall,
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 20,
                                color: context.c.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Gap.lg),
                CeffloNote(
                  icon: LucideIcons.info,
                  body: L.dontHaveLinkCodeRequestInvitation,
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// D18 — Business Joined
// ---------------------------------------------------------------------------

class BusinessJoinedScreen extends StatelessWidget {
  const BusinessJoinedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = app.business ?? DemoData.business;
    return CeffloNavySheetScaffold(
      header: CeffloBrandHeader(
        onBack: app.back,
        onBell: () => app.go(DRoute.notifications),
        centerWordmark: true,
        child: Padding(
          padding: const EdgeInsets.only(top: Gap.md, bottom: Gap.lg),
          child: Column(
            children: [
              const Center(child: CeffloSuccessTick(size: 84, glow: true)),
              const SizedBox(height: Gap.lg),
              Center(
                child: Text(
                  L.youveJoined,
                  style: context.t.displayMedium?.copyWith(fontSize: 27),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                L.nowPart,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CefColors.onNavyMuted,
                ),
              ),
              const SizedBox(height: Gap.md),
              CeffloCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: BusinessIdentityRow(
                  business: business,
                  compact: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChecklistBlock(
            rows: [
              (L.accountConnected, L.accountLinkedBusiness, LucideIcons.user),
              (L.businessDetails, 'Bakes & Co.', LucideIcons.fileText),
              (
                L.youreAllSet,
                L.canNowStartReceivingDeliveriesOnce,
                LucideIcons.shieldCheck,
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            L.goHome,
            onTap: () {
              app.setStage(DriverStage.active);
              app.resetTo(DRoute.today);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// V2 Choose Your Vehicle / V3 Your Driver Details (Founder reference,
// 2026-10-04). Registration steps 2/4 and 3/4 (V1 Splash, V4 Documents).
// Vehicle values are the stored `rider_vehicle_type` enum.
// ---------------------------------------------------------------------------
const _vehicles = [
  ('motorcycle', 'assets/vehicles/vehicle_motorcycle.png'),
  ('car', 'assets/vehicles/vehicle_car.png'),
  ('van', 'assets/vehicles/vehicle_van.png'),
];

String _vehicleName(String v) => switch (v) {
  'car' => L.vehicleCar,
  'van' => L.vehicleVan,
  _ => L.vehicleMotorbike,
};

String _vehicleSub(String v) => switch (v) {
  'car' => L.vehicleCarSub,
  'van' => L.vehicleVanSub,
  _ => L.vehicleMotorbikeSub,
};

String _vehicleImage(String v) =>
    _vehicles.firstWhere((e) => e.$1 == v, orElse: () => _vehicles.first).$2;

/// Registration page in the Driver DNA (same as D12/D12.1/D12.2): the navy
/// header is a transparent window onto the shell gradient, with back, title
/// and subtitle; the content sits on the white sheet with rounded top
/// corners. The step indicator closes the sheet.
class _RegistrationPage extends StatelessWidget {
  const _RegistrationPage({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onBack,
    this.fill = false,
  });
  final String title, subtitle;
  final List<Widget> children;
  final VoidCallback onBack;

  /// Fill the sheet to the bottom edge (children may use Expanded), so the
  /// primary action sits at the bottom instead of leaving empty space.
  final bool fill;

  @override
  Widget build(BuildContext context) => CeffloAuthScaffold(
    onBack: onBack,
    title: title,
    subtitle: subtitle,
    scrollable: !fill,
    sheetPadding: const EdgeInsets.fromLTRB(
      Gap.gutter,
      Gap.lg,
      Gap.gutter,
      Gap.xl,
    ),
    sheet: Column(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class ChooseVehicleScreen extends StatefulWidget {
  const ChooseVehicleScreen({super.key});

  @override
  State<ChooseVehicleScreen> createState() => _ChooseVehicleScreenState();
}

class _ChooseVehicleScreenState extends State<ChooseVehicleScreen> {
  late String _selected = AppScope.read(context).registrationVehicle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return _RegistrationPage(
      title: L.chooseYourVehicle,
      subtitle: L.selectVehicleUseDelivery,
      onBack: app.back,
      fill: true,
      // Choosing a vehicle is required (no Skip): the three options share
      // the sheet's height and Next sits at the bottom.
      children: [
        for (final (index, (v, img)) in _vehicles.indexed) ...[
          if (index > 0) const SizedBox(height: Gap.md),
          Expanded(
            child: _VehicleOption(
              value: v,
              image: img,
              selected: v == _selected,
              onTap: () => setState(() => _selected = v),
            ),
          ),
        ],
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton(
          L.next,
          onTap: () {
            app.registrationVehicle = _selected;
            app.go(DRoute.yourDriverDetails);
          },
        ),
      ],
    );
  }
}

class _VehicleOption extends StatelessWidget {
  const _VehicleOption({
    required this.value,
    required this.image,
    required this.selected,
    required this.onTap,
  });
  final String value, image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: _vehicleName(value),
    child: InkWell(
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.md, Gap.md),
        decoration: BoxDecoration(
          color: selected ? CefColors.tintInfo : context.c.card,
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
          border: Border.all(
            color: selected
                ? context.c.info.withValues(alpha: .45)
                : context.c.border,
          ),
          boxShadow: selected
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0F101C33),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? context.c.info : context.c.textSecondary,
              size: 24,
            ),
            const SizedBox(width: Gap.md),
            // Studio photos on white: multiplied with the card colour so the
            // white backdrop disappears into both the plain and the selected
            // card. Fixed box + contain keeps proportions; a wider box lets
            // the three vehicles read at a similar visual size.
            SizedBox(
              width: 128,
              height: 84,
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                color: selected ? CefColors.tintInfo : context.c.card,
                colorBlendMode: BlendMode.multiply,
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _vehicleName(value),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _vehicleSub(value),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: context.c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class YourDriverDetailsScreen extends StatefulWidget {
  const YourDriverDetailsScreen({super.key});

  @override
  State<YourDriverDetailsScreen> createState() =>
      _YourDriverDetailsScreenState();
}

class _YourDriverDetailsScreenState extends State<YourDriverDetailsScreen> {
  late final _app = AppScope.read(context);
  late final _saved = _app.repo.registration;
  late final _name = TextEditingController(
    text: _app.repo.isDemo
        ? ''
        : (_saved['full_name'] ?? _app.profile.fullName)?.toString(),
  );
  late final _phone = TextEditingController(
    text: _app.repo.isDemo
        ? ''
        : (_saved['phone'] ?? _app.profile.phone)?.toString(),
  );
  late final _plate = TextEditingController(
    text: _saved['vehicle_plate']?.toString() ?? '',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _name.text.trim(),
        phone = _phone.text.trim(),
        plate = _plate.text.trim();
    if (name.isEmpty || phone.isEmpty || plate.isEmpty) {
      setState(() => _error = L.enterNamePhonePlate);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _app.registrationPlate = plate;
      await _app.repo.saveRegistration(
        vehicleType: _app.registrationVehicle,
        fullName: name,
        phone: phone,
        plate: plate,
      );
      if (!mounted) return;
      // Prototype walks on to the designed documents step (V4 / D12.2);
      // live, the rider joins a business next.
      if (_app.repo.isDemo) {
        _app.go(DRoute.vehicleAndDocuments);
      } else {
        _app.resetTo(_app.homeRoute);
      }
    } on RepositoryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final v = app.registrationVehicle;
    return _RegistrationPage(
      title: L.yourDriverDetails,
      subtitle: L.infoSharedDeliveryPartner,
      onBack: app.back,
      children: [
        const Center(child: AvatarPicker(size: 84)),
        const SizedBox(height: 6),
        Text(
          L.addPhoto,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.c.textSecondary,
          ),
        ),
        const SizedBox(height: Gap.lg),
        CeffloTextField(
          label: L.fullName,
          controller: _name,
          hint: L.enterFullName,
          icon: LucideIcons.user,
        ),
        const SizedBox(height: Gap.md),
        CeffloPhoneField(label: L.phoneNumber, controller: _phone),
        const SizedBox(height: Gap.md),
        CeffloTextField(
          label: L.vehicleNumberPlate,
          controller: _plate,
          hint: L.eGVaa1234,
          icon: LucideIcons.car,
        ),
        const SizedBox(height: Gap.lg),
        // Selected vehicle (from V2), with Change back to V2.
        Container(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CefColors.gradientBright, Color(0xFF3C8DF0)],
            ),
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 96,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(_vehicleImage(v), fit: BoxFit.contain),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L.selectedVehicle,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CefColors.onNavyMuted,
                      ),
                    ),
                    Text(
                      _vehicleName(v),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: CefColors.onNavy,
                      ),
                    ),
                    Text(
                      _vehicleSub(v),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: CefColors.onNavy,
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => app.back(),
                  child: Text(
                    L.change,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CefColors.onNavy,
                      decoration: TextDecoration.underline,
                      decorationColor: CefColors.onNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: Gap.sm),
          Text(
            _error!,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.c.attention,
            ),
          ),
        ],
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton(
          L.continueText2,
          busy: _busy,
          onTap: _busy ? null : _continue,
        ),
      ],
    );
  }
}

/// A filled, non-editable field in the form style (no chevron, no cursor).
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    readOnly: true,
    label: '$label: $value',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CeffloFieldLabel(label),
        const SizedBox(height: 6),
        Container(
          height: Sizes.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: CefColors.tintNeutral,
            borderRadius: BorderRadius.circular(Sizes.inputRadius),
            border: Border.all(color: context.c.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: context.c.textSecondary),
              const SizedBox(width: 10),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
