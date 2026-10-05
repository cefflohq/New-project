import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import 'screens/history.dart';
import 'screens/jobs.dart';
import 'screens/onboarding.dart';
import 'screens/operations.dart';
import 'screens/profile.dart';
import 'screens/support.dart';

/// Maps a typed [RiderLocation] to its screen — the signed-in half of the
/// Cefflo Driver inventory (D10–D40C). D01–D09 are owned by `AuthFlow`,
/// which runs before this graph exists.
///
/// Same shape as Vendor Mobile's `buildScreen`, so both Flutter clients
/// route identically.
Widget buildScreen(BuildContext context, RiderLocation loc) {
  final id = loc.entityId;
  // Live: invitation acceptance happens once, in the Invitation PWA; the
  // app claims it after sign-in (claim_my_rider_invitations). D17 Join
  // Business stays for an existing account joining by link. The designed
  // D12 onboarding forms have no backend yet, so they are prototype-only.
  final live = !AppScope.of(context).repo.isDemo;
  return switch (loc.route) {
    // --- Onboarding / business join -------------------------------------
    DRoute.driverDetails ||
    DRoute.personalDetails ||
    DRoute.vehicleAndDocuments when live => const JoinBusinessScreen(),
    DRoute.businessJoined when live && AppScope.of(context).business == null =>
      const JoinBusinessScreen(),
    DRoute.chooseVehicle => const ChooseVehicleScreen(),
    DRoute.yourDriverDetails => const YourDriverDetailsScreen(),
    DRoute.noBusinessConnectedHome => const NoBusinessConnectedHomeScreen(),
    DRoute.driverDetails => const DriverDetailsScreen(),
    DRoute.personalDetails => const PersonalDetailsScreen(),
    DRoute.vehicleAndDocuments => const VehicleAndDocumentsScreen(),
    DRoute.pendingReview => const PendingReviewScreen(),
    DRoute.approved => const ApprovedScreen(),
    DRoute.readyToGo => const ReadyToGoScreen(),
    DRoute.noBusinessConnected => const NoBusinessConnectedScreen(),
    DRoute.joinBusiness => const JoinBusinessScreen(),
    DRoute.businessJoined => const BusinessJoinedScreen(),

    // --- Operational loop -----------------------------------------------
    DRoute.today => const TodayScreen(),
    DRoute.runDetails => const RunDetailsScreen(),
    DRoute.stopList => const StopListScreen(),
    DRoute.navigationToStop => const NavigationToStopScreen(),
    DRoute.confirmDelivery => const ConfirmDeliveryScreen(),
    DRoute.deliveryIssue => const DeliveryIssueScreen(),
    DRoute.reportIssue => const ReportIssueScreen(),
    DRoute.runCompleted => const RunCompletedScreen(),

    // --- History & notifications ----------------------------------------
    DRoute.deliveryHistory => const DeliveryHistoryScreen(),
    DRoute.historyDetail => HistoryDetailScreen(runId: id ?? 'run-cf1003'),
    DRoute.notifications => const NotificationsScreen(),

    // --- Profile, settings & support ------------------------------------
    DRoute.profile => const ProfileScreen(),
    DRoute.findJobs => const FindJobsScreen(),
    DRoute.jobDetail => JobDetailScreen(jobId: id ?? ''),
    DRoute.mySchedule => const MyScheduleScreen(),
    DRoute.editProfile => const EditProfileScreen(),
    DRoute.vehicleDetails => const VehicleDetailsScreen(),
    DRoute.documents => const DocumentsScreen(),
    DRoute.settings => const SettingsScreen(),
    DRoute.helpSupport => const HelpSupportScreen(),
    DRoute.vendorSupport => const VendorSupportScreen(),
    DRoute.submitTicket => const SubmitTicketScreen(),

    // D01–D09 never reach the signed-in graph; if one somehow does, land on
    // the Driver's real home rather than pretending an auth screen belongs
    // inside the shell.
    _ => const TodayScreen(),
  };
}
