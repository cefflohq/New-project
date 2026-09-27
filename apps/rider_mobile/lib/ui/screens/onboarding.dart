import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../brand.dart';
import '../widgets.dart';
import 'auth.dart' show BusinessIdentityRow;

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// D10 — Accept Business Invitation
// ---------------------------------------------------------------------------

class AcceptInvitationScreen extends StatelessWidget {
  const AcceptInvitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final business = DemoData.invitingBusiness;
    return CeffloAuthScaffold(
      onBack: app.back,
      title: L.acceptInvitation,
      subtitle: L.youveBeenInvitedJoinBusinessCefflo,
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
          _tinted(context, BusinessIdentityRow(business: business)),
          const SizedBox(height: Gap.md),
          _tinted(
            context,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.messageSquare,
                  size: 22,
                  color: CefColors.navy,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L.messageFromBusiness, style: context.t.titleSmall),
                      const SizedBox(height: 3),
                      Text(
                        '“${business.invitationMessage}”',
                        style: context.t.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
          _tinted(
            context,
            Column(
              children: [
                CeffloFeatureRow(
                  icon: LucideIcons.package,
                  title: L.makeDeliveriesOurCustomers,
                  body: L.helpUsDeliverOrdersWithinOur,
                ),
                CeffloFeatureRow(
                  icon: LucideIcons.fileText,
                  title: L.simpleStraightforward,
                  body: L.completeDetailsGetApprovedByBusiness,
                ),
                CeffloFeatureRow(
                  icon: LucideIcons.users,
                  title: L.partTeam,
                  body: L.workTrustedLocalBusinessCefflo,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            L.acceptContinue,
            onTap: () => app.go(DRoute.driverDetails),
          ),
          const SizedBox(height: Gap.md),
          Center(
            child: CeffloTextLink(
              L.declineInvitation,
              onTap: () {
                app.setStage(DriverStage.noBusiness);
                app.resetTo(DRoute.noBusinessConnected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tinted(BuildContext context, Widget child) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: CefColors.tintInfo,
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
    ),
    child: child,
  );
}

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
  String _vehicle = L.motorbike;

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
          CeffloSelectField<String>(
            label: L.vehicleType,
            value: _vehicle,
            options: DemoData.vehicleTypes,
            icon: LucideIcons.bike,
            onChanged: (v) => setState(() => _vehicle = v),
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
  final _plate = TextEditingController(text: L.vaa1234);
  String _vehicle = L.motorbike;

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
          CeffloSelectField<String>(
            label: L.vehicleType,
            value: _vehicle,
            options: DemoData.vehicleTypes,
            icon: LucideIcons.bike,
            onChanged: (v) => setState(() => _vehicle = v),
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
          SectionRow(icon: LucideIcons.fileText, label: L.requiredDocuments),
          const SizedBox(height: Gap.sm),
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

class JoinBusinessScreen extends StatefulWidget {
  const JoinBusinessScreen({super.key});

  @override
  State<JoinBusinessScreen> createState() => _JoinBusinessScreenState();
}

class _JoinBusinessScreenState extends State<JoinBusinessScreen> {
  final _link = TextEditingController();
  int _tab = 0;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CeffloSegmentedTabs(
            labels: [L.inviteLink, L.qrCode],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: Gap.lg),
          CeffloTextField(
            label: L.invitationLink,
            controller: _link,
            hint: 'https://...',
            icon: LucideIcons.link,
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            L.continueText2,
            onTap: () => app.go(DRoute.businessJoined),
          ),
          const SizedBox(height: Gap.lg),
          Center(child: Text(L.orSeparator, style: context.t.bodyMedium)),
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
                        child: Text(L.scanQrCode, style: context.t.titleSmall),
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
