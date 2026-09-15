import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../brand.dart';
import '../widgets.dart';
import 'auth.dart' show BusinessIdentityRow;

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
      step: const CeffloStepProgress(current: 2, total: 2, segments: 3),
      title: 'Accept Invitation',
      subtitle: 'You’ve been invited to join this\nbusiness on Cefflo.',
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
                      Text(
                        'Message from the business',
                        style: context.t.titleSmall,
                      ),
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
            const Column(
              children: [
                CeffloFeatureRow(
                  icon: LucideIcons.package,
                  title: 'Make deliveries for our customers',
                  body: 'Help us deliver orders within our service area.',
                ),
                CeffloFeatureRow(
                  icon: LucideIcons.fileText,
                  title: 'Simple and straightforward',
                  body:
                      'Complete your details and get approved by the business.',
                ),
                CeffloFeatureRow(
                  icon: LucideIcons.users,
                  title: 'Be part of the team',
                  body: 'Work with a trusted local business on Cefflo.',
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            'Accept & Continue',
            trailingArrow: true,
            onTap: () => app.go(DRoute.driverDetails),
          ),
          const SizedBox(height: Gap.md),
          Center(
            child: CeffloTextLink(
              'Decline Invitation',
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
              const Text(
                'Good Morning,',
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
              const Text(
                'Let’s get you connected.',
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
            'No Business Connected',
            textAlign: TextAlign.center,
            style: context.t.displaySmall,
          ),
          const SizedBox(height: Gap.sm),
          Text(
            'Your account is ready, but you’re not\nconnected to any business yet.',
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
        title: 'I have an invitation',
        subtitle: 'Join a business with an invite link or code.',
        onTap: () => app.go(DRoute.joinBusiness),
      ),
      Divider(height: 1, color: context.c.border, indent: 12, endIndent: 12),
      CeffloOptionRow(
        icon: LucideIcons.search,
        title: 'Check your email',
        subtitle: 'If you’ve received an invitation, tap the link to join.',
        onTap: () => app.go(DRoute.joinBusiness),
      ),
      Divider(height: 1, color: context.c.border, indent: 12, endIndent: 12),
      CeffloOptionRow(
        icon: LucideIcons.circleHelp,
        title: 'Need help?',
        subtitle: 'Contact support if you’re unsure.',
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
  final _name = TextEditingController(text: DemoData.profile.fullName);
  final _phone = TextEditingController(text: '12 345 6789');
  final _plate = TextEditingController();
  String _vehicle = 'Motorbike';

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
      headerAction: const CeffloStepProgress(current: 2, total: 2, segments: 2),
      title: 'Driver Details',
      subtitle: 'Tell us a bit more so the business\ncan verify your profile.',
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
          const SectionRow(
            icon: LucideIcons.package,
            label: 'Profile Information',
          ),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              const AvatarPicker(size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Photo', style: context.t.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Use a clear photo of your face.',
                      style: context.t.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          CeffloTextField(
            label: 'Full Name',
            controller: _name,
            icon: LucideIcons.user,
          ),
          const SizedBox(height: Gap.md),
          CeffloPhoneField(label: 'Phone Number', controller: _phone),
          const SizedBox(height: Gap.section),
          Divider(height: 1, color: context.c.border),
          const SizedBox(height: Gap.section),
          const SectionRow(
            icon: LucideIcons.bike,
            label: 'Vehicle Information',
          ),
          const SizedBox(height: Gap.lg),
          CeffloSelectField<String>(
            label: 'Vehicle Type',
            value: _vehicle,
            options: DemoData.vehicleTypes,
            icon: LucideIcons.bike,
            onChanged: (v) => setState(() => _vehicle = v),
          ),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: 'Vehicle Number Plate',
            controller: _plate,
            hint: 'E.g. VAA 1234',
            icon: LucideIcons.idCard,
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            'Continue',
            trailingArrow: true,
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
  final _name = TextEditingController(text: DemoData.profile.fullName);
  final _phone = TextEditingController(text: '12 345 6789');
  final _dob = TextEditingController(text: DemoData.profile.dateOfBirth);
  final _email = TextEditingController(text: DemoData.profile.email);
  final _address = TextEditingController(text: DemoData.profile.address);
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
      step: const CeffloStepProgress(current: 1, total: 2, segments: 4),
      title: 'Personal Details',
      subtitle: 'Let’s get to know you. This information\nwill be shared with the business.',
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
            label: 'Full Name',
            controller: _name,
            icon: LucideIcons.user,
          ),
          const SizedBox(height: Gap.md),
          CeffloPhoneField(label: 'Phone Number', controller: _phone),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: 'Date of Birth',
            controller: _dob,
            icon: LucideIcons.calendar,
            readOnly: true,
          ),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: 'Email',
            controller: _email,
            icon: LucideIcons.mail,
            readOnly: true,
            suffix: const CeffloStatusChip('Verified'),
          ),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: 'Address',
            controller: _address,
            icon: LucideIcons.mapPin,
          ),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: 'Emergency Contact (Optional)',
            controller: _emergency,
            hint: 'e.g. 16 123 4567',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            'Next',
            trailingArrow: true,
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
  final _plate = TextEditingController(text: 'VAA 1234');
  String _vehicle = 'Motorbike';

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
      step: const CeffloStepProgress(current: 2, total: 2, segments: 3),
      title: 'Vehicle & Documents',
      subtitle: 'Add your vehicle details and required\ndocuments to complete your profile.',
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
          const SectionRow(
            icon: LucideIcons.bike,
            label: 'Vehicle Information',
          ),
          const SizedBox(height: Gap.lg),
          CeffloSelectField<String>(
            label: 'Vehicle Type',
            value: _vehicle,
            options: DemoData.vehicleTypes,
            icon: LucideIcons.bike,
            onChanged: (v) => setState(() => _vehicle = v),
          ),
          const SizedBox(height: Gap.md),
          CeffloTextField(
            label: 'Vehicle Number Plate',
            controller: _plate,
            icon: LucideIcons.idCard,
          ),
          const SizedBox(height: Gap.section),
          Divider(height: 1, color: context.c.border),
          const SizedBox(height: Gap.section),
          const SectionRow(
            icon: LucideIcons.fileText,
            label: 'Required Documents',
          ),
          const SizedBox(height: Gap.sm),
          for (final doc in app.onboardingDocuments)
            CeffloDocumentRow(
              icon: doc.id == 'licence' ? LucideIcons.idCard : LucideIcons.bike,
              title: doc.title,
              subtitle: doc.helper,
              statusLabel: 'Uploaded',
              thumbnail: DocumentThumbPlaceholder(
                icon: doc.id == 'licence'
                    ? LucideIcons.idCard
                    : LucideIcons.fileText,
              ),
              onRemove: () {},
            ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            'Submit for Review',
            trailingArrow: true,
            onTap: _submit,
          ),
          const SizedBox(height: Gap.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.lock, size: 18, color: context.c.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your information is secure and only shared with the business.',
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
          'Submitting your details',
          style: context.t.displaySmall?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: Gap.sm),
        Text(
          'Please wait while we send\nyour information to the business.',
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
              _row(context, LucideIcons.user, 'Personal details'),
              _row(context, LucideIcons.bike, 'Vehicle details'),
              _row(context, LucideIcons.fileText, 'Documents'),
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
          'Application Submitted!',
          style: context.t.displaySmall?.copyWith(fontSize: 21),
        ),
        const SizedBox(height: Gap.sm),
        Text(
          'Your details have been sent to\nthe business for review.',
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
              _row(context, LucideIcons.user, 'Personal details'),
              _row(context, LucideIcons.bike, 'Vehicle details'),
              _row(context, LucideIcons.fileText, 'Documents'),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        const CeffloNote(
          icon: LucideIcons.clock,
          title: 'Pending Review',
          body: 'We’ll notify you once the business has reviewed and approved your application.',
          tone: CeffloNoteTone.warning,
        ),
        const SizedBox(height: Gap.lg),
        CeffloPrimaryButton('Done', onTap: onDone, height: 52),
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
          'Submitted',
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
                'Application Under Review',
                style: context.t.displayMedium?.copyWith(fontSize: 25),
              ),
              const SizedBox(height: Gap.sm),
              const Text(
                'Thanks for submitting your details.\nWe’ll notify you once the business\nhas reviewed and approved your application.',
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
          const CeffloNote(
            icon: LucideIcons.clock,
            title: 'Pending Review',
            body: 'Your application is being reviewed by the business.',
            tone: CeffloNoteTone.warning,
          ),
          const SizedBox(height: Gap.md),
          const ChecklistBlock(
            rows: [
              ('Personal Details', 'Submitted', LucideIcons.user),
              ('Vehicle Details', 'Submitted', LucideIcons.bike),
              ('Documents', 'Submitted', LucideIcons.fileText),
            ],
          ),
          const SizedBox(height: Gap.md),
          const CeffloNote(
            icon: LucideIcons.info,
            body: 'We’ll notify you in the app once your account is approved. You can close the app and check back later.',
          ),
          const SizedBox(height: Gap.lg),
          CeffloSecondaryButton(
            'View Submitted Details',
            trailingChevron: true,
            onTap: () => app.go(DRoute.personalDetails),
          ),
          const SizedBox(height: Gap.md),
          // Prototype scaffolding, labelled as such. In the product this
          // screen advances when the *business* approves the Driver, and no
          // reference draws a CTA out of it — so the preview needs a way to
          // reach D14.2 without inventing a product control.
          Center(
            child: CeffloTextLink(
              'Preview: simulate approval',
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
                child: Text('You’re Approved!', style: context.t.displayMedium),
              ),
              const SizedBox(height: Gap.sm),
              const Text(
                'Welcome to the team.\nYour account is now active and\nyou’re ready to start delivering.',
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
          const ChecklistBlock(
            rows: [
              ('Personal Details', 'Verified', LucideIcons.user),
              ('Vehicle Details', 'Verified', LucideIcons.bike),
              ('Documents', 'Verified', LucideIcons.fileText),
            ],
          ),
          const SizedBox(height: Gap.md),
          const CeffloNote(
            icon: LucideIcons.shieldCheck,
            title: 'Your account is active',
            body: 'You can now accept delivery runs and start earning with Cefflo.',
            tone: CeffloNoteTone.success,
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            'Go to Today',
            trailingArrow: true,
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
              const Text(
                'Good to see you,',
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
              const Text(
                'Ready to hit the road?',
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Active',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'You’re all set to start delivering.',
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
          Text('Quick Start', style: context.t.titleLarge),
          const SizedBox(height: Gap.md),
          CeffloCard(
            padding: EdgeInsets.zero,
            child: CeffloOptionRow(
              icon: LucideIcons.play,
              title: 'Go Online',
              subtitle: 'Start accepting delivery runs',
              onTap: () => AppScope.read(context).resetTo(DRoute.today),
            ),
          ),
          const SizedBox(height: Gap.cardGap),
          CeffloCard(
            padding: EdgeInsets.zero,
            child: CeffloOptionRow(
              icon: LucideIcons.map,
              title: 'View Available Jobs',
              subtitle: 'See nearby delivery requests',
              onTap: () =>
                  app.go(DRoute.runDetails, entityId: app.currentRun.id),
            ),
          ),
          const SizedBox(height: Gap.cardGap),
          CeffloCard(
            padding: EdgeInsets.zero,
            child: CeffloOptionRow(
              icon: LucideIcons.circleHelp,
              title: 'Help & Support',
              subtitle: 'Get help anytime',
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
                'Deliver More\nFor Local Businesses',
                style: context.t.titleMedium?.copyWith(height: 1.25),
              ),
              const SizedBox(height: 6),
              Text(
                'Be part of a growing community of local delivery heroes.',
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
                      'You’re not\nconnected to a\nbusiness yet.',
                      style: context.t.displayMedium?.copyWith(fontSize: 25),
                    ),
                    const SizedBox(height: Gap.md),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Join a business to start\ndelivering with ',
                          ),
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
              title: 'Got an invitation?',
              subtitle:
                  'Join your business with an invite link from your employer.',
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
              title: 'Scan QR Code',
              subtitle: 'Use a QR code from your business to join.',
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
              title: 'Need help?',
              subtitle: 'Contact your business owner for an invitation.',
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
                'Join Business',
                style: context.t.displayMedium?.copyWith(fontSize: 26),
              ),
              const SizedBox(height: Gap.sm),
              const Text(
                'Enter the invitation link or code provided\nby your business.',
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
            labels: const ['Invite Link', 'QR Code'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: Gap.lg),
          CeffloTextField(
            label: 'Invitation Link',
            controller: _link,
            hint: 'https://...',
            icon: LucideIcons.link,
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            'Continue',
            trailingArrow: true,
            onTap: () => app.go(DRoute.businessJoined),
          ),
          const SizedBox(height: Gap.lg),
          Center(child: Text('or', style: context.t.bodyMedium)),
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
                          'Scan QR Code',
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
          const SizedBox(height: Gap.lg),
          const CeffloNote(
            icon: LucideIcons.info,
            body: 'Don’t have a link or code?\nRequest an invitation from your business owner or administrator.',
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
                  'You’ve Joined!',
                  style: context.t.displayMedium?.copyWith(fontSize: 27),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'You are now part of',
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
          const ChecklistBlock(
            rows: [
              (
                'Account connected',
                'Your account is linked to the business.',
                LucideIcons.user,
              ),
              ('Business details', 'Bakes & Co.', LucideIcons.fileText),
              (
                'You’re all set',
                'You can now start receiving deliveries once assigned by your business.',
                LucideIcons.shieldCheck,
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          CeffloPrimaryButton(
            'Go to Home',
            trailingArrow: true,
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
