// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get paymentsNotAvailableYet => 'Payments are not available yet.';

  @override
  String get splash => 'Splash';

  @override
  String get sign => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get accountRecovery => 'Account recovery';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get welcome => 'Welcome';

  @override
  String get businessInformation => 'Business information';

  @override
  String get pickupLocation => 'Pickup location';

  @override
  String get serviceArea => 'Service area';

  @override
  String get setupComplete => 'Setup complete';

  @override
  String get today => 'Today';

  @override
  String get orders => 'Orders';

  @override
  String get orderDetail => 'Order detail';

  @override
  String get newOrder => 'New order';

  @override
  String get importOrders => 'Import orders';

  @override
  String get editOrder => 'Edit order';

  @override
  String get zones => 'Zones';

  @override
  String get zone => 'Zone';

  @override
  String get deliveryProgress => 'Delivery progress';

  @override
  String get riders => 'Riders';

  @override
  String get riderDetail => 'Rider detail';

  @override
  String get riderRegistrationLink => 'Rider registration link';

  @override
  String get team => 'Team';

  @override
  String get teamMember => 'Team member';

  @override
  String get teamMemberRegistrationLink => 'Team member registration link';

  @override
  String get coverage => 'Coverage';

  @override
  String get zoneConfiguration => 'Zone configuration';

  @override
  String get createZone => 'Create zone';

  @override
  String get storefront => 'Storefront';

  @override
  String get viewStorefront => 'View storefront';

  @override
  String get templatePreview => 'Template preview';

  @override
  String get customize => 'Customize';

  @override
  String get products => 'Products';

  @override
  String get customers => 'Customers';

  @override
  String get customer => 'Customer';

  @override
  String get editProduct => 'Edit product';

  @override
  String get addProduct => 'Add product';

  @override
  String get businessProfile => 'Business profile';

  @override
  String get businessAddress => 'Business address';

  @override
  String get businessHours => 'Business hours';

  @override
  String get deliverySettings => 'Delivery settings';

  @override
  String get profile => 'Profile';

  @override
  String get security => 'Security';

  @override
  String get changePassword => 'Change password';

  @override
  String get more => 'More';

  @override
  String get notificationPreferences => 'Notification preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get subscription => 'Subscription';

  @override
  String get choosePlan => 'Choose a plan';

  @override
  String get reviewPayment => 'Review & Payment';

  @override
  String get billingHistory => 'Billing History';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get helpCentre => 'Help centre';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsService => 'Terms of service';

  @override
  String get aboutCefflo => 'About Cefflo';

  @override
  String get notifications => 'Notifications';

  @override
  String get pendingApproval => 'Pending approval';

  @override
  String get pickup => 'Pickup';

  @override
  String get pickedUp => 'Picked up';

  @override
  String get way => 'On the way';

  @override
  String get arrived => 'Arrived';

  @override
  String get delivered => 'Delivered';

  @override
  String get issue => 'Issue';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get business => 'Business';

  @override
  String get approved => 'Approved';

  @override
  String get item => 'Item';

  @override
  String get rider => 'Rider';

  @override
  String get product => 'Product';

  @override
  String get serviceAreaNotSet => 'Service area not set';

  @override
  String get awaitingLocation => 'Awaiting location';

  @override
  String get coverage2 => 'In coverage';

  @override
  String get outsideCoverage => 'Outside coverage';

  @override
  String get unknown => 'Unknown';

  @override
  String get addressNotYetLocated => 'Address not yet located';

  @override
  String get addressAmbiguous => 'Address is ambiguous';

  @override
  String get addressCouldNotLocated => 'Address could not be located';

  @override
  String get noRiderCompatibleVehicleEnoughSpare =>
      'No rider with a compatible vehicle and enough spare capacity';

  @override
  String get dispatched => 'Dispatched';

  @override
  String get accepted => 'Accepted';

  @override
  String get pickingUp => 'Picking up';

  @override
  String get completed => 'Completed';

  @override
  String get declined => 'Declined';

  @override
  String capacityExceededActiveRequestedExceeds(
    Object current_load,
    Object requested,
    Object effective_capacity,
  ) {
    return 'Capacity exceeded: $current_load active + $requested requested exceeds $effective_capacity.';
  }

  @override
  String vehicleIncompatibleNeedsRiderHas(
    Object vehicle_requirement,
    Object rider_vehicle_type,
  ) {
    return 'Vehicle incompatible: needs $vehicle_requirement, rider has $rider_vehicle_type.';
  }

  @override
  String get experienceCefflo => 'Experience Cefflo.';

  @override
  String get t100DeliveriesMonth => '100 deliveries a month';

  @override
  String get up3Riders2Zones => 'Up to 3 riders · 2 zones';

  @override
  String get customerTrackingProofDelivery =>
      'Customer tracking and proof of delivery';

  @override
  String get businessesRunningLocalDeliveriesRegularly =>
      'For businesses running local deliveries regularly.';

  @override
  String get t500DeliveriesMonth => '500 deliveries a month';

  @override
  String get up10Riders5Zones => 'Up to 10 riders · 5 zones';

  @override
  String get up3TeamMembers => 'Up to 3 team members';

  @override
  String get standardReportingSupport => 'Standard reporting and support';

  @override
  String get runLocalDeliveryOperationOnePlace =>
      'Run your local delivery operation in one place.';

  @override
  String get t1500DeliveriesMonth => '1,500 deliveries a month';

  @override
  String get unlimitedRidersZones => 'Unlimited riders and zones';

  @override
  String get up10TeamMembers => 'Up to 10 team members';

  @override
  String get advancedOperationalReporting => 'Advanced operational reporting';

  @override
  String get prioritySupport => 'Priority support';

  @override
  String get highVolumeComplexOperations =>
      'For high-volume, complex operations.';

  @override
  String get t5000DeliveriesMonth => '5,000 deliveries a month';

  @override
  String get up25TeamMembers => 'Up to 25 team members';

  @override
  String get advancedControlsIntegrations =>
      'Advanced controls and integrations';

  @override
  String get modernInter => 'Modern (Inter)';

  @override
  String get boldInter => 'Bold (Inter)';

  @override
  String get elegantInterItalic => 'Elegant (Inter Italic)';

  @override
  String get classicInterCaps => 'Classic (Inter Caps)';

  @override
  String get orderWasNotCreatedBackendReturned =>
      'Order was not created: backend returned no id.';

  @override
  String get removingDeliveryFromTodaysPlanNot =>
      'Removing a delivery from today\'s plan is not available yet.';

  @override
  String get runNotFound => 'Run not found.';

  @override
  String get uiPrototypeModeHasNoBackend =>
      'UI prototype mode has no backend connection.';

  @override
  String actionNeedsBackendContractThatNot(Object message) {
    return 'This action needs a backend contract that is not deployed here ($message).';
  }

  @override
  String get unexpectedBackendResponseShape =>
      'Unexpected backend response shape.';

  @override
  String get updatingPassword => 'Updating password…';

  @override
  String get savingNewPassword => 'Saving your new password.';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get canNowSignNewPassword =>
      'You can now sign in with your new password.';

  @override
  String get operateTodayGrowTomorrow => 'Operate Today.\nGrow Tomorrow.';

  @override
  String get back => 'Back';

  @override
  String get emailPasswordIncorrectTryAgain =>
      'Email or password is incorrect. Try again.';

  @override
  String get tooManyAttemptsPleaseWaitBefore =>
      'Too many attempts. Please wait before trying again.';

  @override
  String get unableConnectCheckConnectionTryAgain =>
      'Unable to connect. Check your connection and try again.';

  @override
  String get unableConnect => 'Unable to connect';

  @override
  String get tooManyAttempts => 'Too many attempts';

  @override
  String get continueApple => 'Continue with Apple';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueEmail => 'Continue with Email';

  @override
  String get haveInvite => 'Have an invite? ';

  @override
  String get getStarted => 'Get started';

  @override
  String get language => 'Language';

  @override
  String get signEmail => 'Sign in with Email';

  @override
  String get enterEmailPasswordContinue =>
      'Enter your email and password to continue.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get tryAgain => 'Try again';

  @override
  String get signing => 'Signing in…';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signUp => 'Sign up';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get createAccount2 => 'Create your account';

  @override
  String get startManagingDeliveries => 'Start managing your deliveries.';

  @override
  String get useLeast8Characters => 'Use at least 8 characters.';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPassword2 => 'Confirm your password';

  @override
  String get creatingAccount => 'Creating account…';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get enterEmailWellSendResetLink =>
      'Enter your email and we\'ll send you a 6-digit code.';

  @override
  String get sendResetLink => 'Send code';

  @override
  String get sending => 'Sending…';

  @override
  String get backSign => 'Back to sign in';

  @override
  String get checkEmail => 'Check your email';

  @override
  String get ifAccountExistsEmailYoullReceive =>
      'If an account exists for this email, you\'ll receive a password reset link.';

  @override
  String get checkSpamFolderToo => 'Check your spam folder too.';

  @override
  String get tryAnotherEmail => 'Try another email';

  @override
  String verificationEmailSent(Object email) {
    return 'Verification email sent to $email.';
  }

  @override
  String get verifyEmail => 'Verify your email';

  @override
  String get openVerificationLinkEmailConfirmAccount =>
      'Open the verification link in your email to confirm your account.';

  @override
  String get resendVerificationEmail => 'Resend verification email';

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String get emailVerified => 'Email verified';

  @override
  String get emailConfirmedSignContinue =>
      'Your email is confirmed.\nSign in to continue.';

  @override
  String get continueSign => 'Continue to sign in';

  @override
  String verificationEmailSent2(Object trim) {
    return 'Verification email sent to $trim.';
  }

  @override
  String get verificationLinkExpired => 'Verification link expired';

  @override
  String get linkHasExpiredInvalidRequestNew =>
      'This link has expired or is invalid.\nRequest a new verification email.';

  @override
  String get sendNewVerificationEmail => 'Send new verification email';

  @override
  String get setNewPassword => 'Set a new password';

  @override
  String get chooseStrongPasswordAccount =>
      'Choose a strong password for your account.';

  @override
  String get newPassword => 'New password';

  @override
  String get enterNewPassword => 'Enter a new password';

  @override
  String get updatePassword => 'Update password';

  @override
  String get updating => 'Updating…';

  @override
  String get noBusinessLinked => 'No business linked.';

  @override
  String zones2(Object zonesCount) {
    return 'Zones ($zonesCount)';
  }

  @override
  String get noZonesYetTapCreateFirst =>
      'No zones yet. Tap + to create your first zone.';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get theseZonesDefineWhereDeliverAdd =>
      'These zones define where you deliver. Add, edit or deactivate zones anytime.';

  @override
  String get searchZones => 'Search zones...';

  @override
  String get noZonesConfiguredYet => 'No zones configured yet.';

  @override
  String get zoneNotFound => 'Zone not found';

  @override
  String get zoneOptions => 'Zone options';

  @override
  String get editZoneName => 'Edit zone name';

  @override
  String get deleteZone => 'Delete zone';

  @override
  String get cancel => 'Cancel';

  @override
  String zoneRenamed(Object updated) {
    return 'Zone renamed to $updated';
  }

  @override
  String couldNotRename(Object e) {
    return 'Could not rename: $e';
  }

  @override
  String delete(Object zone) {
    return 'Delete $zone?';
  }

  @override
  String get willRemoveZoneFromDeliverySetup =>
      'This will remove the zone from your delivery setup.';

  @override
  String get delete2 => 'Delete';

  @override
  String removedFromDeliverySetup(Object zone) {
    return '$zone removed from your delivery setup';
  }

  @override
  String couldNotDelete(Object e) {
    return 'Could not delete: $e';
  }

  @override
  String get zoneNameRequired => 'Zone name is required.';

  @override
  String get zoneName => 'Zone name';

  @override
  String get save => 'Save';

  @override
  String get t0Km => '0 km';

  @override
  String km(Object distance) {
    return '$distance km';
  }

  @override
  String get totalDistance => 'Total distance';

  @override
  String get totalOrders => 'Total orders';

  @override
  String get todaysDeliveries => 'Today\'s deliveries';

  @override
  String get noDeliveriesPlannedZoneToday =>
      'No deliveries planned in this zone today.';

  @override
  String get dispatch => 'Dispatch';

  @override
  String get unassignedRider => 'Unassigned rider';

  @override
  String order(Object count, Object s) {
    return '$count order$s';
  }

  @override
  String km2(Object distanceKm) {
    return '$distanceKm km';
  }

  @override
  String min(Object travelMinutes) {
    return '$travelMinutes min';
  }

  @override
  String removedFromToday(Object delivery) {
    return '$delivery removed from today';
  }

  @override
  String get processing => 'Processing...';

  @override
  String get creatingZone => 'Creating your zone';

  @override
  String get successful => 'Successful';

  @override
  String get newZoneHasBeenCreatedSuccessfully =>
      'Your new zone has been created successfully.';

  @override
  String get createZone2 => 'Create Zone';

  @override
  String get zoneWillCoverHighlightedAreaMap =>
      'This zone will cover the highlighted area on the map. You can always edit it later.';

  @override
  String get zoneDetails => 'Zone details';

  @override
  String get nameAreaDeliver => 'Name the area you deliver to';

  @override
  String get enterZoneName => 'Enter zone name';

  @override
  String get all => 'All';

  @override
  String get offline => 'Offline';

  @override
  String get pending => 'Pending';

  @override
  String get noRidersYet => 'No riders yet.';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get may => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  @override
  String get riderNotFound => 'Rider not found';

  @override
  String get pendingReview => 'Pending Review';

  @override
  String get riderApplicant => 'Rider applicant';

  @override
  String get reject => 'Reject';

  @override
  String get rejectingRiders => 'Rejecting riders';

  @override
  String get approveRider => 'Approve Rider';

  @override
  String get approvingRiders => 'Approving riders';

  @override
  String get customerRating => 'Customer rating';

  @override
  String get joined => 'Joined';

  @override
  String get drivingLicence => 'Driving Licence';

  @override
  String get noLicenceDocumentAvailable => 'No licence document available';

  @override
  String get additionalInformation => 'Additional Information';

  @override
  String get noAdditionalInformationAvailable =>
      'No additional information available.';

  @override
  String get searchTeamMembers => 'Search team members...';

  @override
  String get noTeamMembersYet => 'No team members yet.';

  @override
  String get teamMemberNotFound => 'Team member not found';

  @override
  String get notProvided => 'Not provided';

  @override
  String get roleAccess => 'Role & access';

  @override
  String get accountStatus => 'Account status';

  @override
  String get businessOwnerAlwaysKeepsFullAccess =>
      'The business owner always keeps full access and cannot be removed from the team.';

  @override
  String get canManageDailyOperationsOrdersRiders =>
      'Can manage daily operations, orders, riders and team members. Cannot manage billing or subscription.';

  @override
  String get canAccessDailyOperationsOrdersRiders =>
      'Can access daily operations, orders and riders. Cannot manage billing or subscription.';

  @override
  String get remove2 => 'Remove';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get noProductsCatalogueYet => 'No products in the catalogue yet.';

  @override
  String rm(Object displayPrice, Object status) {
    return 'RM $displayPrice · $status';
  }

  @override
  String get searchCustomers => 'Search customers...';

  @override
  String orders2(Object count) {
    return 'Orders ($count)';
  }

  @override
  String get account => 'Account';

  @override
  String get businessProfile2 => 'Business Profile';

  @override
  String get support => 'Support';

  @override
  String get helpSupport2 => 'Help & Support';

  @override
  String get privacy => 'Privacy';

  @override
  String get signOut => 'Sign out';

  @override
  String get version100 => 'Version 1.0.0';

  @override
  String get businessInformation2 => 'Business Information';

  @override
  String get nameTypeContactDetails => 'Name, type and contact details';

  @override
  String get pickupLocation2 => 'Pickup Location';

  @override
  String get whereDeliveriesStartFrom => 'Where deliveries start from';

  @override
  String get serviceArea2 => 'Service Area';

  @override
  String get howFarDeliver => 'How far you deliver';

  @override
  String get letsSetUpBusiness => 'Let’s set up your business';

  @override
  String get justFewDetailsBeforeStartDelivering =>
      'Just a few details before you start delivering with Cefflo. Takes about 2 minutes.';

  @override
  String get getStarted2 => 'Get Started';

  @override
  String step(Object step, Object totalSteps) {
    return 'Step $step of $totalSteps';
  }

  @override
  String get foodBeverage => 'Food & Beverage';

  @override
  String get homeLiving => 'Home & Living';

  @override
  String get retail => 'Retail';

  @override
  String get groceries => 'Groceries';

  @override
  String get other => 'Other';

  @override
  String get businessNameRequired => 'Business name is required.';

  @override
  String get enterValidPhoneNumber => 'Enter a valid phone number.';

  @override
  String get continueText => 'Continue';

  @override
  String get tellUsAboutBusiness => 'Tell us about your business';

  @override
  String get appearsDeliveryOrdersReceipts =>
      'This appears on your delivery orders and receipts.';

  @override
  String get businessName => 'Business Name';

  @override
  String get eGKopiKita => 'e.g. Kopi Kita';

  @override
  String get businessType => 'Business Type';

  @override
  String get contactPhone => 'Contact Phone';

  @override
  String get pickupAddressRequired => 'Pickup address is required.';

  @override
  String get whereDoDeliveriesStartFrom => 'Where do deliveries start from?';

  @override
  String get ridersPickUpOrdersFromLocation =>
      'Riders pick up orders from this location.';

  @override
  String get pickupAddress => 'Pickup Address';

  @override
  String get searchEnterAddress => 'Search or enter your address';

  @override
  String get postcode => 'Postcode';

  @override
  String get city => 'City';

  @override
  String get howFarDoDeliver => 'How far do you deliver?';

  @override
  String get ceffloUsesDecideWhichOrdersCan =>
      'Cefflo uses this to decide which orders you can accept.';

  @override
  String get finishSetup => 'Finish Setup';

  @override
  String get configured => 'Configured';

  @override
  String get teamRiders => 'Team & Riders';

  @override
  String get ready => 'Ready';

  @override
  String get preferences => 'Preferences';

  @override
  String get setText => 'Set';

  @override
  String get business2 => 'Your Business\nis ';

  @override
  String get ready2 => 'Ready!';

  @override
  String get deliverySetupCompleteLetsStartDelivering =>
      'Your delivery setup is complete.\nLet’s start delivering with Cefflo.';

  @override
  String get goToday => 'Go to Today';

  @override
  String get noBusinessLinkedAccountYet =>
      'No business is linked to this account yet.';

  @override
  String noOrders(Object toLowerCase) {
    return 'No $toLowerCase orders.';
  }

  @override
  String todayItem(Object createdAt, Object itemsCount, Object s) {
    return 'Today, $createdAt · $itemsCount item$s';
  }

  @override
  String get editOrder2 => 'Edit Order';

  @override
  String get deliver => 'Deliver to';

  @override
  String get directions => 'Directions';

  @override
  String get notSet => 'Not set';

  @override
  String get deliveryInstruction => 'Delivery Instruction';

  @override
  String items(Object itemsCount) {
    return 'Items ($itemsCount)';
  }

  @override
  String get viewReceipt => 'View receipt';

  @override
  String get receiptView => 'The receipt view';

  @override
  String get noItemsOrder => 'No items on this order.';

  @override
  String viewAllItems(Object itemsCount) {
    return 'View all $itemsCount items';
  }

  @override
  String zoneSet(Object z) {
    return 'Zone set to $z';
  }

  @override
  String couldNotSetZone(Object e) {
    return 'Could not set zone: $e';
  }

  @override
  String get orderApproved => 'Order approved';

  @override
  String couldNotApprove(Object e) {
    return 'Could not approve: $e';
  }

  @override
  String get approveOrder => 'Approve Order';

  @override
  String get approving => 'Approving…';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get createSingleOrderStepByStep =>
      'Create a single order step by step';

  @override
  String get importOrders2 => 'Import Orders';

  @override
  String get importMultipleOrdersFromFiles =>
      'Import multiple orders from your files';

  @override
  String get recentImports => 'Recent Imports';

  @override
  String get viewAll => 'View all';

  @override
  String get importHistory => 'The import history';

  @override
  String get connected => 'Connected';

  @override
  String get openingImport => 'Opening this import';

  @override
  String get googleSheets => 'Google Sheets';

  @override
  String get importFromGoogleSheets => 'Import from your Google Sheets';

  @override
  String get mealPrepOrders => 'Meal Prep Orders';

  @override
  String get t16Sep2026 => '16 Sep 2026';

  @override
  String get excel => 'Excel';

  @override
  String get uploadExcelFileXlsxXls => 'Upload an Excel file (.xlsx, .xls)';

  @override
  String get cateringSept => 'Catering Sept';

  @override
  String get t14Sep2026 => '14 Sep 2026';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get importFromFilesGoogleDrive =>
      'Import from files in your Google Drive';

  @override
  String get hamperOrders => 'Hamper Orders';

  @override
  String get t12Sep2026 => '12 Sep 2026';

  @override
  String get selectSource => 'Select your source';

  @override
  String get googleSheetsExcelGoogleDrive =>
      'Google Sheets, Excel or Google Drive';

  @override
  String get chooseFile => 'Choose a file';

  @override
  String get pickConnectedSheet => 'Or pick a connected sheet';

  @override
  String get mapColumns => 'Map the columns';

  @override
  String get previewOrders => 'And preview your orders';

  @override
  String get importText => 'Import';

  @override
  String get reviewOrders => 'And review the orders';

  @override
  String get chooseSourceImportMultipleOrders =>
      'Choose a source to import multiple orders.';

  @override
  String get howWorks => 'How it works?';

  @override
  String get sources => 'Sources';

  @override
  String importingFrom(Object source) {
    return 'Importing from $source';
  }

  @override
  String get customerNameRequired => 'Customer name is required.';

  @override
  String get deliveryAddressRequired => 'Delivery address is required.';

  @override
  String get creatingOrder => 'Creating your order';

  @override
  String get updatingOrder => 'Updating your order';

  @override
  String get newOrderHasBeenCreatedSuccessfully =>
      'Your new order has been created successfully.';

  @override
  String get orderHasBeenUpdatedSuccessfully =>
      'Your order has been updated successfully.';

  @override
  String get reviewCreate => 'Review & Create';

  @override
  String get updateOrder => 'Update Order';

  @override
  String get createNewOrderStepByStep => 'Create a new order step by step.';

  @override
  String get updateOrderDetails => 'Update order details.';

  @override
  String get selectExistingCustomerAddNewOne =>
      'Select an existing customer or add a new one.';

  @override
  String get customerName => 'Customer name';

  @override
  String get searchCustomerByNamePhoneEmail =>
      'Search customer by name, phone or email...';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get enterPhoneNumber => 'Enter phone number...';

  @override
  String get address => 'Address';

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String get enterDeliveryAddress => 'Enter delivery address...';

  @override
  String get items2 => 'Items';

  @override
  String get addOrderItems => 'Add order items';

  @override
  String get addItemsOrder => 'Add items to this order';

  @override
  String get addingOrderItems => 'Adding order items';

  @override
  String get instructions => 'Instructions';

  @override
  String get specialRequestsOptional => 'Special requests (optional)';

  @override
  String get instruction => 'Instruction';

  @override
  String get addDeliveryNotes => 'Add delivery notes...';

  @override
  String get productNameRequired => 'Product name is required.';

  @override
  String get enterValidPrice => 'Enter a valid price.';

  @override
  String get addingProduct => 'Adding your product';

  @override
  String get updatingProduct => 'Updating your product';

  @override
  String get newProductHasBeenAddedSuccessfully =>
      'Your new product has been added successfully.';

  @override
  String get productHasBeenUpdatedSuccessfully =>
      'Your product has been updated successfully.';

  @override
  String get addProduct2 => 'Add Product';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get productPhoto => 'Product Photo';

  @override
  String get productDetails => 'Product Details';

  @override
  String get productName => 'Product name';

  @override
  String get enterProductName => 'Enter product name';

  @override
  String get description => 'Description';

  @override
  String get enterProductDescription => 'Enter product description';

  @override
  String get priceRm => 'Price (RM)';

  @override
  String get rm000 => 'RM 0.00';

  @override
  String get available => 'Available';

  @override
  String get showProductStorefront => 'Show this product in your storefront';

  @override
  String get way2 => 'On the Way';

  @override
  String get addProductPhoto => 'Add product photo';

  @override
  String get deliveryRun => 'Delivery run';

  @override
  String delivered2(Object done, Object total) {
    return '$done of $total delivered';
  }

  @override
  String remaining(Object done) {
    return '$done remaining';
  }

  @override
  String get nextStop => 'Next stop';

  @override
  String get next => 'Next';

  @override
  String get upcomingStops => 'Upcoming stops';

  @override
  String get everyStopRunFinished => 'Every stop on this run is finished.';

  @override
  String run(Object zone) {
    return '$zone Run';
  }

  @override
  String dispatched2(Object rider) {
    return 'Dispatched to $rider';
  }

  @override
  String dispatchOrder(Object count, Object s) {
    return 'Dispatch $count order$s';
  }

  @override
  String chooseRider(Object zone) {
    return 'Choose the rider for $zone.';
  }

  @override
  String get noActiveRidersYet => 'No active riders yet.';

  @override
  String get checkingVehicleCapacity => 'Checking vehicle and capacity…';

  @override
  String get dispatching => 'Dispatching…';

  @override
  String get savingServiceArea => 'Saving your service area';

  @override
  String get serviceAreaHasBeenSaved => 'Your service area has been saved.';

  @override
  String get coverageConfiguredCeffloDecidesEachOrders =>
      'Coverage is configured. Cefflo decides each order’s coverage from this.';

  @override
  String get noServiceAreaConfiguredYetOrders =>
      'No service area configured yet. Orders will show “Not set” instead of a coverage verdict.';

  @override
  String get saveServiceArea => 'Save service area';

  @override
  String get manageZones => 'Manage zones';

  @override
  String get seeConfigureZonesDeliver =>
      'See and configure the zones you deliver to';

  @override
  String get deliveryRadius => 'Delivery radius';

  @override
  String km3(Object round) {
    return '$round km';
  }

  @override
  String sf(Object padLeft) {
    return 'SF-$padLeft';
  }

  @override
  String get cart => 'Your Cart';

  @override
  String get cartEmpty => 'Your cart is empty.';

  @override
  String rm2(Object price) {
    return 'RM $price';
  }

  @override
  String get addNoteOptional => 'Add a note (optional)';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get deliveryFee => 'Delivery Fee';

  @override
  String get total => 'Total';

  @override
  String get proceedCheckout => 'Proceed to Checkout';

  @override
  String rm3(Object toStringAsFixed) {
    return 'RM $toStringAsFixed';
  }

  @override
  String get checkout => 'Checkout';

  @override
  String get customerInfo => 'Customer Info';

  @override
  String get fullName => 'Full name';

  @override
  String get deliveryAddress2 => 'Delivery Address';

  @override
  String get deliveryOption => 'Delivery Option';

  @override
  String get standardDelivery => 'Standard delivery';

  @override
  String get t3045Min => '30-45 min';

  @override
  String get expressDelivery => 'Express delivery';

  @override
  String get t1520MinRm300 => '15-20 min · +RM 3.00';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cashDelivery => 'Cash on Delivery';

  @override
  String get payWhenOrderArrives => 'Pay when your order arrives';

  @override
  String get card => 'Card';

  @override
  String get prototypeOnlyNoRealPaymentProcessed =>
      'Prototype only -- no real payment is processed';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get orderPlaced => 'Order placed!';

  @override
  String orderHasBeenCreatedPrototypeFlow(Object orderRef) {
    return 'Order $orderRef has been created. This is a prototype flow -- no real order or payment was processed.';
  }

  @override
  String get continueShopping => 'Continue Shopping';

  @override
  String get store => 'Your store';

  @override
  String get defaultText => 'Default';

  @override
  String get white => 'White';

  @override
  String get warm => 'Warm';

  @override
  String get cool => 'Cool';

  @override
  String get discardChanges => 'Discard changes?';

  @override
  String get storefrontStaysChangesMadeHereNot =>
      'Your storefront stays as it is. Changes you made here are not saved.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get saving => 'Saving...';

  @override
  String get updatingStorefront => 'Updating your storefront';

  @override
  String live(Object def) {
    return '$def is live';
  }

  @override
  String get storefrontUpdated => 'Storefront updated';

  @override
  String productsNowShowLayout(Object def) {
    return 'Your products now show in the $def layout.';
  }

  @override
  String get customersNowSeeChanges => 'Customers now see your changes.';

  @override
  String get couldntOpenPhotosPleaseTryAgain =>
      'Couldn\'t open your photos. Please try again.';

  @override
  String customize2(Object def) {
    return 'Customize $def';
  }

  @override
  String get adjustColoursStyleMatchBrand =>
      'Adjust the colours and style to match your brand.';

  @override
  String get resetTemplateDefaults => 'Reset to template defaults';

  @override
  String get brandColour => 'Brand colour';

  @override
  String get customColour => 'Custom colour';

  @override
  String get background => 'Background';

  @override
  String get custom => 'Custom';

  @override
  String get heroImage => 'Hero image';

  @override
  String get shownBehindStorefrontBanner =>
      'Shown behind your storefront banner.';

  @override
  String get upload => 'Upload';

  @override
  String get change => 'Change';

  @override
  String get storeName => 'Store name';

  @override
  String get fromBusinessProfile => 'From your Business Profile.';

  @override
  String get taglineOptional => 'Tagline (optional)';

  @override
  String colour(Object hex) {
    return 'Colour $hex';
  }

  @override
  String background2(Object label) {
    return '$label background';
  }

  @override
  String get pickColour => 'Pick a Colour';

  @override
  String get done => 'Done';

  @override
  String get exploreTemplates => 'Explore Templates';

  @override
  String get previewAnyLayoutOwnProducts =>
      'Preview any layout with your own products.';

  @override
  String get noTemplatesHereYet => 'No templates here yet.';

  @override
  String get everyTemplateShowsTheseProducts =>
      'Every template shows these products';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String customize3(Object join) {
    return 'Customize: $join';
  }

  @override
  String get useTemplate => 'Use This Template';

  @override
  String get close => 'Close';

  @override
  String get storefront2 => 'Your storefront';

  @override
  String rm4(Object amount) {
    return 'RM$amount';
  }

  @override
  String get deliveries => 'Deliveries';

  @override
  String get teamMembers => 'Team members';

  @override
  String plan(Object plan) {
    return '$plan plan';
  }

  @override
  String nextRenewal(Object nextRenewal) {
    return 'Next renewal on $nextRenewal';
  }

  @override
  String get currentUsage => 'Current usage';

  @override
  String get cycle => 'This cycle';

  @override
  String get changePlan => 'Change plan';

  @override
  String get paymentMethod2 => 'Payment method';

  @override
  String get paymentMethods => 'Payment methods';

  @override
  String get billingHistory2 => 'Billing history';

  @override
  String unlimited(Object used) {
    return '$used · Unlimited';
  }

  @override
  String get currentPlan => 'Current plan';

  @override
  String get selectPlanThatFitsBusiness =>
      'Select the plan that fits your business.';

  @override
  String get plansPricesCurrentPricingCandidate =>
      'Plans and prices are the current pricing candidate.';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get t2MonthsFree => '2 months free';

  @override
  String get mostPopular => 'Most Popular';

  @override
  String get current => 'Current';

  @override
  String get processingPayment => 'Processing payment';

  @override
  String get pleaseWaitWhileWeConfirmPayment =>
      'Please wait while we confirm your payment.';

  @override
  String get subscriptionActive => 'Subscription active';

  @override
  String get paymentUnsuccessful => 'Payment unsuccessful';

  @override
  String get weCouldntProcessPaymentNoCharge =>
      'We couldn\'t process your payment.\nNo charge was made.';

  @override
  String get changePaymentMethod => 'Change payment method';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get billingCycle => 'Billing cycle';

  @override
  String get creditDebitCard => 'Credit / Debit card';

  @override
  String get fpxOnlineBanking => 'FPX online banking';

  @override
  String get demoNoRealPaymentProcessed =>
      'Demo — no real payment is processed.';

  @override
  String get noInvoicesYet => 'No invoices yet.';

  @override
  String get paid => 'Paid';

  @override
  String get due => 'Due';

  @override
  String get downloadInvoice => 'Download invoice';

  @override
  String get invoiceDownload => 'Invoice download';

  @override
  String get ahmadRazi => 'Ahmad Razi';

  @override
  String get vfy7281 => 'VFY 7281';

  @override
  String get bangsar => 'Bangsar';

  @override
  String get t224Pm => '2:24 PM';

  @override
  String get sitiAminah => 'Siti Aminah';

  @override
  String get bmd4120 => 'BMD 4120';

  @override
  String get sentul => 'Sentul';

  @override
  String get t156Pm => '1:56 PM';

  @override
  String get jasonLim => 'Jason Lim';

  @override
  String get vdt3302 => 'VDT 3302';

  @override
  String get setapak => 'Setapak';

  @override
  String get t1241Pm => '12:41 PM';

  @override
  String get nurIman => 'Nur Iman';

  @override
  String get vfe9812 => 'VFE 9812';

  @override
  String get shahAlam => 'Shah Alam';

  @override
  String get t1128Am => '11:28 AM';

  @override
  String get danielTan => 'Daniel Tan';

  @override
  String get bpl6683 => 'BPL 6683';

  @override
  String get petalingJaya => 'Petaling Jaya';

  @override
  String get t1054Am => '10:54 AM';

  @override
  String get farahLee => 'Farah Lee';

  @override
  String get vds7721 => 'VDS 7721';

  @override
  String get putrajaya => 'Putrajaya';

  @override
  String get t0917Am => '09:17 AM';

  @override
  String get hafizKhan => 'Hafiz Khan';

  @override
  String get bpq3091 => 'BPQ 3091';

  @override
  String get klang => 'Klang';

  @override
  String get t0836Am => '08:36 AM';

  @override
  String get totalOrders2 => 'Total Orders';

  @override
  String get recentDelivery => 'Recent Delivery';

  @override
  String get noCompletedDeliveriesYet => 'No completed deliveries yet.';

  @override
  String get needAttention => 'Need Attention';

  @override
  String needAttention2(Object issuesCount) {
    return 'Need Attention ($issuesCount)';
  }

  @override
  String get nothingNeedsAttention => 'Nothing needs your attention.';

  @override
  String get needsAction => 'Needs your action';

  @override
  String get activeRun => 'Active run';

  @override
  String get inviteRider => 'Invite rider';

  @override
  String get inviteTeamMember => 'Invite team member';

  @override
  String get online => 'Online';

  @override
  String get youreOfflineNewOrdersPaused =>
      'You\'re offline. New orders are paused.';

  @override
  String get youreOnline => 'You\'re online.';

  @override
  String get businesses => 'Your businesses';

  @override
  String get goodMorning => 'Good Morning,';

  @override
  String get goodAfternoon => 'Good Afternoon,';

  @override
  String get goodEvening => 'Good Evening,';

  @override
  String get heresWhatsHappeningToday => 'Here\'s what\'s happening today.';

  @override
  String get searchOrderNumberCustomer => 'Search order number or customer...';

  @override
  String get searchRiders => 'Search riders...';

  @override
  String get addOrder => 'Add order';

  @override
  String get addZone => 'Add zone';

  @override
  String get notificationOptions => 'Notification options';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get clearAllNotifications => 'Clear all notifications';

  @override
  String get search => 'Search';

  @override
  String notWiredUpYet(Object action) {
    return '$action is not wired up yet.';
  }

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get filter => 'Filter';

  @override
  String get phoneApp => 'the phone app';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String couldNotOpen(Object target) {
    return 'Could not open $target.';
  }

  @override
  String get call => 'Call';

  @override
  String call2(Object phone) {
    return 'Call $phone';
  }

  @override
  String whatsapp2(Object phone) {
    return 'WhatsApp $phone';
  }

  @override
  String get contact => 'Contact';

  @override
  String get loading => 'Loading';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get weCouldntCompleteActionRightNow =>
      'We couldn\'t complete this action right now. Please try again.';

  @override
  String get delivery => 'Delivery';

  @override
  String get activeTeamMemberCanAccessBusiness =>
      'Active · This team member can currently access your business.';

  @override
  String get fullAccessIncludingBillingSubscription =>
      'Full access to every part of the business, including billing and subscription.';

  @override
  String importSampleSubtitle(Object label, Object count, Object date) {
    return '$label · $count orders\n$date';
  }

  @override
  String get nextSetHowFarDeliver => 'Next: set how far you deliver';

  @override
  String get reservedLaterApprovedDeliverySettingsPass =>
      'Reserved for a later approved delivery settings pass.';

  @override
  String get edit => 'Edit';

  @override
  String get rating => 'Rating';

  @override
  String get nameContactDescription => 'Name, contact, description';

  @override
  String get businessAddress2 => 'Business Address';

  @override
  String get storeAddressServiceArea => 'Store address and service area';

  @override
  String get businessHours2 => 'Business Hours';

  @override
  String get setOperatingHours => 'Set your operating hours';

  @override
  String get storeReady => 'Your store is ready';

  @override
  String get keepBusinessInformationUpDate =>
      'Keep your business information up to date.';

  @override
  String get editingBusinessDetailsAppNotConnected =>
      'Editing business details in the app is not connected yet.';

  @override
  String get businessDetails => 'Business details';

  @override
  String get howCustomersRidersSeeBusiness =>
      'How customers and riders see your business.';

  @override
  String get taglineOptional2 => 'Tagline (Optional)';

  @override
  String get shortDescription => 'Short Description';

  @override
  String get whereCustomersRidersCanReach =>
      'Where customers and riders can reach you.';

  @override
  String get code => 'Code';

  @override
  String get businessEmail => 'Business Email';

  @override
  String get editingBusinessAddressAppNotConnected =>
      'Editing the business address in the app is not connected yet.';

  @override
  String get saveAddress => 'Save Address';

  @override
  String get addressDetails => 'Address details';

  @override
  String get addressLine1 => 'Address Line 1';

  @override
  String get addressLine2Optional => 'Address Line 2 (Optional)';

  @override
  String get state => 'State';

  @override
  String get businessHoursNotConnectedYet =>
      'Business hours are not connected yet.';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get saveHours => 'Save Hours';

  @override
  String get operatingHours => 'Operating Hours';

  @override
  String get letCustomersKnowWhenBusinessOpen =>
      'Let your customers know when your business is open.';

  @override
  String get applyMondaysHoursAllDays => 'Apply Monday\'s hours to all days';

  @override
  String get personalDetails => 'Personal details';

  @override
  String get nameShownTeam => 'Your name as shown to your team.';

  @override
  String get fullName2 => 'Full Name';

  @override
  String get signEmailRole => 'Sign-in email and role.';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailCannotChangedApp => 'Email cannot be changed in the app.';

  @override
  String get role => 'Role';

  @override
  String get managedByBusiness => 'Managed by your business.';

  @override
  String get keepAccountSafe => 'Keep your account safe';

  @override
  String get manageHowSignBusinessAccount =>
      'Manage how you sign in to your business account.';

  @override
  String get signAccess => 'Sign-in & access';

  @override
  String get changePassword2 => 'Change your password';

  @override
  String get twoFactorAuthentication => 'Two-Factor Authentication';

  @override
  String get useLeast8CharactersLetterNumber =>
      'Use at least 8 characters with a letter and a number.';

  @override
  String get updatingPassword2 => 'Updating your password';

  @override
  String get passwordHasBeenUpdatedSuccessfully =>
      'Your password has been updated successfully.';

  @override
  String get updatePassword2 => 'Update Password';

  @override
  String get useStrongPasswordKeepAccountSecure =>
      'Use a strong password to keep your account secure.';

  @override
  String get newPassword2 => 'New Password';

  @override
  String get enterNewPassword2 => 'Enter new password';

  @override
  String get minimum8Characters => 'Minimum 8 characters';

  @override
  String get includeLeastOneLetterOneNumber =>
      'Include at least one letter and one number';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get confirmNewPassword2 => 'Confirm new password';

  @override
  String get notificationSettingsNotConnectedYet =>
      'Notification settings are not connected yet.';

  @override
  String get always => 'Always on';

  @override
  String get issuesDeliveryProgressAccountSecurityAlerts =>
      'Issues, delivery progress and account security alerts keep your operation running, so they cannot be turned off.';

  @override
  String get orderIssues => 'Order issues';

  @override
  String get accountSecurity => 'Account & security';

  @override
  String get optional => 'Optional';

  @override
  String get newOrders => 'New orders';

  @override
  String get whenNewOrderComes => 'When a new order comes in.';

  @override
  String get riderStatus => 'Rider status';

  @override
  String get whenRidersGoOnlineOffline => 'When riders go online or offline.';

  @override
  String get productNews => 'Product news';

  @override
  String get tipsNewCeffloFeatures => 'Tips and new Cefflo features.';

  @override
  String get blue => 'Blue';

  @override
  String get navy => 'Navy';

  @override
  String get red => 'Red';

  @override
  String get green => 'Green';

  @override
  String get yellow => 'Yellow';

  @override
  String get orange => 'Orange';

  @override
  String get black => 'Black';

  @override
  String get accentColour => 'Accent colour';

  @override
  String get chooseAccentColourApp => 'Choose the accent colour for the app.';

  @override
  String get hue => 'Hue';

  @override
  String get lightness => 'Lightness';

  @override
  String get apply => 'Apply';

  @override
  String get closed => 'Closed';

  @override
  String get wereHereHelp => 'We’re here to help';

  @override
  String get howCanWeHelp => 'How can we help?';

  @override
  String get searchHelpArticlesTopics =>
      'Search for help, articles or topics...';

  @override
  String get helpCentre2 => 'Help Centre';

  @override
  String get browseArticlesGuidesFaqs => 'Browse articles, guides and FAQs';

  @override
  String get contactSupport2 => 'Contact Support';

  @override
  String get chatSendSupportRequest => 'Chat or send a support request';

  @override
  String get popularTopics => 'Popular Topics';

  @override
  String get accountSecurity2 => 'Account & Security';

  @override
  String get loginProfileSecuritySettings =>
      'Login, profile, security settings';

  @override
  String get ordersDelivery => 'Orders & Delivery';

  @override
  String get orderManagementDeliveryIssues =>
      'Order management, delivery issues';

  @override
  String get ridersTeam => 'Riders & Team';

  @override
  String get riderInvitesApprovalsTeamAccess =>
      'Rider invites, approvals, team access';

  @override
  String get subscriptionBilling => 'Subscription & Billing';

  @override
  String get plansPaymentsInvoices => 'Plans, payments, invoices';

  @override
  String get appGuides => 'App Guides';

  @override
  String get stepByStepTutorials => 'Step-by-step tutorials';

  @override
  String get findAnswers => 'Find answers';

  @override
  String get searchOurHelpCentreBrowseTopics =>
      'Search our help centre or browse topics below.';

  @override
  String get searchHelpEGZonesRiders =>
      'Search for help, e.g. zones, riders...';

  @override
  String get browseTopics => 'Browse topics';

  @override
  String get gettingStarted => 'Getting Started';

  @override
  String get setUpAccountBusiness => 'Set up your account and business';

  @override
  String get manageOrdersRunsZones => 'Manage orders, runs and zones';

  @override
  String get zonesRiders => 'Zones & Riders';

  @override
  String get coverageRidersDispatch => 'Coverage, riders and dispatch';

  @override
  String get profileSecuritySettings => 'Profile, security and settings';

  @override
  String get plansPaymentsInvoices2 => 'Plans, payments and invoices';

  @override
  String get popularQuestions => 'Popular Questions';

  @override
  String get howDoICreateDeliveryZone => 'How do I create a delivery zone?';

  @override
  String get howDoIAddRider => 'How do I add a rider?';

  @override
  String get canIChangeMyPlanLater => 'Can I change my plan later?';

  @override
  String get howDoesRouteOptimizationWork =>
      'How does route optimization work?';

  @override
  String get whereCanMyCustomersTrackTheir =>
      'Where can my customers track their orders?';

  @override
  String get viewingAllQuestions => 'Viewing all questions';

  @override
  String get sendingSupportRequestsFromAppNot =>
      'Sending support requests from the app is not connected yet.';

  @override
  String get wereHereHelp2 => 'We’re here to help.';

  @override
  String get getTouch => 'Get in touch';

  @override
  String get tellUsAboutIssueOurTeam =>
      'Tell us about your issue and our team will get back to you.';

  @override
  String get issueCategory => 'Issue Category';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get subject => 'Subject';

  @override
  String get brieflyDescribeIssue => 'Briefly describe your issue';

  @override
  String get message => 'Message';

  @override
  String get tellUsMoreAboutIssue => 'Tell us more about your issue...';

  @override
  String get addScreenshotsOptional => 'Add Screenshots (Optional)';

  @override
  String get pngJpgUp10mbEach => 'PNG, JPG up to 10MB each';

  @override
  String get tapAttachImages => 'Tap to attach images';

  @override
  String get whereWeWillReply => 'Where we will reply to you.';

  @override
  String get contactEmail => 'Contact Email';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get sendingRequest => 'Sending your request';

  @override
  String get supportRequestHasBeenSent => 'Your support request has been sent.';

  @override
  String get ourSupportTeamWillGetBack =>
      'ⓘ Our support team will get back to you as soon as possible.';

  @override
  String get trustTransparency => 'Trust & Transparency';

  @override
  String get wereCommittedProtectingDataPrivacy =>
      'We’re committed to protecting your data and your privacy.';

  @override
  String get termsThatGuideUseCefflo =>
      'The terms that guide your use of Cefflo.';

  @override
  String get lastUpdated12Sep2026 => 'Last updated: 12 Sep 2026';

  @override
  String get page => 'On this page';

  @override
  String get t1Introduction2InformationWeCollect =>
      '1.  Introduction\n2.  Information We Collect\n3.  How We Use Your Information\n4.  Data Sharing\n5.  Data Security\n6.  Your Rights\n7.  Cookies and Tracking Technologies\n8.  Changes to This Policy\n9.  Contact Us';

  @override
  String get t1AcceptanceTerms2AccountResponsibilities =>
      '1.  Acceptance of Terms\n2.  Account Responsibilities\n3.  Acceptable Use\n4.  Subscription and Billing\n5.  Intellectual Property\n6.  Service Availability\n7.  Limitation of Liability\n8.  Changes to These Terms\n9.  Contact Us';

  @override
  String get t1Introduction => '1. Introduction';

  @override
  String get t1AcceptanceTerms => '1. Acceptance of Terms';

  @override
  String get ceffloWeUsOurValuesPrivacy =>
      'Cefflo (“we”, “us” or “our”) values your privacy. This policy explains how we collect, use, disclose and safeguard your information when you use our services.';

  @override
  String get byAccessingUsingCeffloAgreeThese =>
      'By accessing or using Cefflo, you agree to these terms and to use the service responsibly in accordance with applicable laws.';

  @override
  String get t2InformationWeCollect => '2. Information We Collect';

  @override
  String get t2AccountResponsibilities => '2. Account Responsibilities';

  @override
  String get weCollectInformationThatProvideDirectly =>
      'We collect information that you provide directly to us, together with limited operational data needed to deliver and improve the service.';

  @override
  String get responsibleMaintainingAccurateAccountInformationProtecting =>
      'You are responsible for maintaining accurate account information and protecting access to your account.';

  @override
  String get moreOrdersLessWorkSmootherDelivery =>
      'More orders. Less work. A smoother delivery day.';

  @override
  String get ourPurpose => 'Our purpose';

  @override
  String get operateTodayGrowTomorrow2 => 'Operate Today. Grow Tomorrow.';

  @override
  String get localSameDayDeliveryOperatingSystem =>
      'A local same-day delivery operating system built for businesses.';

  @override
  String get appInformation => 'App information';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy2 => 'Privacy Policy';

  @override
  String get readPolicy => 'Read policy';

  @override
  String get termsService2 => 'Terms of Service';

  @override
  String get readTerms => 'Read terms';

  @override
  String get notificationDeleted => 'Notification deleted';

  @override
  String get undo => 'Undo';

  @override
  String get markUnread => 'Mark as unread';

  @override
  String get markRead => 'Mark as read';

  @override
  String get youreAllCaughtUp => 'You\'re all caught up.';

  @override
  String get enterValidEmailAddress => 'Enter a valid email address.';

  @override
  String get nameRequired => 'Name is required.';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get scanJoin => 'Scan to join';

  @override
  String get invitedPersonCanScanCodeOpen =>
      'The invited person can scan this code to open the invitation.';

  @override
  String get generateInviteLink => 'Generate invite link';

  @override
  String get copyLink => 'Copy link';

  @override
  String get inviteRidersBusiness => 'Invite riders to your business';

  @override
  String get inviteTeamMember2 => 'Invite a team member';

  @override
  String get theyOpenLinkJoinTeamComplete =>
      'They open the link to join your team and complete their profile, vehicle and documents.';

  @override
  String get theyOpenLinkHelpRunDeliveries =>
      'They open the link to help run deliveries and manage orders.';

  @override
  String get riderName => 'Rider name';

  @override
  String get operatorText => 'Operator';

  @override
  String get owner => 'Owner';

  @override
  String get ownerAccessFullBusinessOwnershipIncluding =>
      'Owner access is full business ownership, including billing and team management.';

  @override
  String get invitationLink => 'Invitation link';

  @override
  String get showQrCode => 'Show QR code';

  @override
  String get scanOpenInvitation => 'Scan to open the invitation';

  @override
  String get linkShownOnlyOnceExpires7 =>
      'This link is shown only once and expires in 7 days. Invited riders appear in your Riders list as Pending Review once they complete registration.';

  @override
  String get linkShownOnlyOnceExpires72 =>
      'This link is shown only once and expires in 7 days. Invited team members appear in your Team list once they accept.';

  @override
  String get backSettings => 'Back to Settings';

  @override
  String active2(Object def, Object style) {
    return '$def, $style, active';
  }

  @override
  String zoneOrdersRiders(int orders, int riders) {
    String _temp0 = intl.Intl.pluralLogic(
      orders,
      locale: localeName,
      other: '$orders orders',
      one: '1 order',
    );
    String _temp1 = intl.Intl.pluralLogic(
      riders,
      locale: localeName,
      other: '$riders riders',
      one: '1 rider',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get perMonth => '/ month';

  @override
  String get perYear => '/ year';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleOperator => 'Operator';

  @override
  String get tagFood => 'Food';

  @override
  String get tagFashion => 'Fashion';

  @override
  String get tagBeauty => 'Beauty';

  @override
  String get tagGifts => 'Gifts';

  @override
  String get locatingBusinessAddress => 'Locating your business address…';

  @override
  String get businessAddressLocated => 'Business address located';

  @override
  String get pickupLocationRequired =>
      'Your pickup location is required. We could not locate your business address; make sure it is complete, then try again.';

  @override
  String get tryLocatingAgain => 'Try locating again';

  @override
  String get helperText => 'Helper';

  @override
  String get operatorRoleDescription =>
      'Help manage daily delivery operations. Requires a Vendor account.';

  @override
  String get helperRoleDescription =>
      'Help prepare, pack and hand over orders. Uses the Cefflo Vendor app.';

  @override
  String get ownerCanRunAlone =>
      'You can run your business as the Owner alone. Operators and Helpers are optional.';

  @override
  String get helperWorkspaceTitle => 'Helper';

  @override
  String get toPrepare => 'To prepare';

  @override
  String get stagePreparing => 'Preparing';

  @override
  String get stagePacked => 'Packed';

  @override
  String get stageReady => 'Ready for pickup';

  @override
  String get startPreparing => 'Start preparing';

  @override
  String get markPacked => 'Mark packed';

  @override
  String get markReady => 'Mark ready';

  @override
  String get readyForHandover => 'Ready for handover';

  @override
  String handoverTo(String rider) {
    return 'Hand over to $rider';
  }

  @override
  String runStop(String run, String stop) {
    return '$run · stop $stop';
  }

  @override
  String get noTasksInStage => 'No orders here.';

  @override
  String get newTasksAppearHere => 'New orders to prepare will appear here.';

  @override
  String get stageSorted => 'Sorted';

  @override
  String get markSorted => 'Mark sorted';

  @override
  String get packingNotConfirmed => 'Packing not confirmed yet';

  @override
  String confirmPackingGroup(String zone, String done, String total) {
    return 'Confirm packing · $zone · $done / $total packed';
  }

  @override
  String confirmSortingGroup(String zone, String done, String total) {
    return 'Confirm sorting · $zone · $done / $total sorted';
  }

  @override
  String pickedUpBy(String rider, String time) {
    return 'Picked up • $rider • $time';
  }

  @override
  String get stagePickedUp => 'Picked up';

  @override
  String get noZone => 'No zone';

  @override
  String handoverToProvider(String provider) {
    return 'Hand over to $provider';
  }

  @override
  String get operatorAccess => 'Operator Access';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInStoreOperations => 'Sign in to your store operations';

  @override
  String get noOperatorAccessYet =>
      'This account has no Operator access yet. Accept the invitation link from the business owner, then sign in with the email address it was sent to.';

  @override
  String get helperAccess => 'Helper Access';

  @override
  String get signInPreparationTasks => 'Sign in to your preparation tasks';

  @override
  String get noHelperAccessYet =>
      'This account has no Helper access yet. Accept the invitation link from the business owner, then sign in with the email address it was sent to.';

  @override
  String get hwPreparation => 'Preparation';

  @override
  String get hwZones => 'Zones';

  @override
  String get hwPacking => 'Packing';

  @override
  String get hwSorting => 'Sorting';

  @override
  String get hwMore => 'More';

  @override
  String get hwOrders => 'orders';

  @override
  String get hwItems => 'items';

  @override
  String get hwRequiredItems => 'Required Items';

  @override
  String hwNOrders(int n) {
    return '$n orders';
  }

  @override
  String hwNItems(int n) {
    return '$n items';
  }

  @override
  String hwNItem(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get hwPacked => 'packed';

  @override
  String get hwPending => 'Pending';

  @override
  String get hwPackingStatus => 'Packing';

  @override
  String get hwPackedStatus => 'Packed';

  @override
  String get hwSortingStatus => 'Sorting';

  @override
  String get hwSortedStatus => 'Sorted';

  @override
  String get hwReadyStatus => 'Ready';

  @override
  String get hwSlideConfirmPickup => 'Slide to Confirm Pickup';

  @override
  String get hwPickupTime => 'Pickup Time';

  @override
  String get hwReadyForPickup => 'Ready for Pickup';

  @override
  String get hwZoneReady => 'This zone is ready for rider pickup.';

  @override
  String get hwPickupRider => 'PICKUP RIDER';

  @override
  String get hwRiderNotAssigned => 'Rider not assigned yet';

  @override
  String get hwMotorcycle => 'Motorcycle';

  @override
  String get hwCar => 'Car';

  @override
  String get hwVan => 'Van';

  @override
  String get hwNoZoneToPack => 'No zone to pack right now.';

  @override
  String get hwNoZoneToSort => 'No zone to sort right now.';

  @override
  String get hwNoWork => 'No preparation work right now.';

  @override
  String get hwPackFirst => 'Confirm packing for this zone first.';

  @override
  String get hwExternalProvider => 'External provider';

  @override
  String get hwPasswordSecurity => 'Password & Security';

  @override
  String get hwNotifNewWork => 'New preparation work';

  @override
  String get hwNotifNewWorkSub => 'When new orders are added to your workload.';

  @override
  String get hwNotifChanges => 'Workload changes';

  @override
  String get hwNotifChangesSub =>
      'When tomorrow\'s or today\'s workload is updated.';

  @override
  String ntNewCustomerOrder(Object ref) {
    return 'New customer order $ref';
  }

  @override
  String get ntNewCustomerOrderBody =>
      'A customer placed an order from your order page.';

  @override
  String ntDeliveryIssue(Object ref) {
    return 'Delivery issue on $ref';
  }

  @override
  String get ntRunDeclined => 'A rider declined a run';

  @override
  String get ntRunDeclinedBody => 'Reassign the orders so they can go out.';

  @override
  String get ntRiderJoined => 'A rider accepted your invitation';

  @override
  String get ntRiderJoinedBody =>
      'Review and approve them before assigning runs.';

  @override
  String get ntRunCompleted => 'Run completed';

  @override
  String get ntRunCompletedBody => 'Every stop in the run is finished.';

  @override
  String get ntJustNow => 'just now';

  @override
  String ntMinutesAgo(Object n) {
    return '$n min ago';
  }

  @override
  String ntHoursAgo(Object n) {
    return '$n h ago';
  }

  @override
  String get ntPrefLead => 'Applies to your account on every Cefflo app.';

  @override
  String get ntPrefEnabled => 'Notifications';

  @override
  String get ntPrefEnabledSub =>
      'Show alerts while Cefflo is open. Everything is still kept in the notification centre.';

  @override
  String get ntPrefSound => 'Sound';

  @override
  String get ntPrefSoundSub => 'Play a sound with an alert.';

  @override
  String get ntPushDeferred =>
      'Alerts when the app is closed are not available yet.';

  @override
  String get ntCouldNotUpdate => 'Could not update notifications. Try again.';

  @override
  String get ntDismiss => 'Dismiss';

  @override
  String get linkNoLongerValid => 'This link is no longer valid';

  @override
  String get linkExpiredOrUsedRequestNew =>
      'It has expired or was already used. Request a new verification email, or a new password reset link.';

  @override
  String get sendNewResetLink => 'Send a new reset link';

  @override
  String get supportSendOpensEmailApp =>
      'Send opens your email app with this message addressed to support@cefflo.com. Add screenshots there if they help.';

  @override
  String get writeMessageFirst => 'Write a message first.';

  @override
  String get emailApp => 'your email app';

  @override
  String get otpLead => 'Enter the 6-digit code we sent to';

  @override
  String get otpVerify => 'Verify';

  @override
  String get otpVerifying => 'Verifying…';

  @override
  String get otpNoCode => 'Didn\'t get the code?';

  @override
  String get otpResend => 'Resend code';

  @override
  String otpResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String otpResent(String email) {
    return 'A new code is on its way to $email.';
  }

  @override
  String get otpIncorrect =>
      'That code is incorrect or has expired. Check the digits or request a new code.';

  @override
  String get otpExpired =>
      'This code has expired. Request a new code to continue.';

  @override
  String get otpSendNew => 'Send a new code';

  @override
  String get otpVerifiedLead => 'Your email is confirmed. You can continue.';

  @override
  String get otpContinue => 'Continue';

  @override
  String get otpCodeLabel => '6-digit verification code';

  @override
  String get otpRecoveryTitle => 'Reset your password';

  @override
  String get connectedSources => 'Connected sources';

  @override
  String get noConnectedSourcesYet =>
      'No connected sources yet. Your connected Google Sheets and Drive files will appear here.';

  @override
  String get createOrder => 'Create an order';

  @override
  String get howStepSource => 'Pick a source';

  @override
  String get howStepFile => 'Choose a file';

  @override
  String get howStepMap => 'Match columns';

  @override
  String get howStepImport => 'Import';

  @override
  String get importExcelCsv => 'Excel / CSV';

  @override
  String get importExcelCsvHint => 'Upload a CSV or Excel file (.xlsx)';

  @override
  String get connectGoogle => 'Connect Google';

  @override
  String get googleConnectPending =>
      'Connecting Google isn\'t available yet. For now, download the sheet as CSV or .xlsx and use Excel / CSV.';

  @override
  String get importReadingFile => 'Reading the file';

  @override
  String get importReadFailed =>
      'This file couldn\'t be read. Use a CSV or .xlsx file with a header row.';

  @override
  String get importNoRows => 'No order rows were found under the header row.';

  @override
  String get importMatchHint =>
      'We matched what we could. Check each field and choose the right column.';

  @override
  String get importNotMapped => 'Not matched';

  @override
  String get importRequiredTag => 'Required';

  @override
  String importMatchRequired(Object fields) {
    return 'Match the required fields: $fields';
  }

  @override
  String get importContinueReview => 'Review rows';

  @override
  String get importReviewTitle => 'Review';

  @override
  String get importRowsDetected => 'Rows detected';

  @override
  String get importRowsValid => 'Ready';

  @override
  String get importRowsInvalid => 'Need attention';

  @override
  String get importMappedFields => 'Matched fields';

  @override
  String importRowMissing(Object row, Object fields) {
    return 'Row $row: missing $fields';
  }

  @override
  String get importInvalidNote =>
      'Rows that need attention won\'t be imported. Fix them in the file and import it again.';

  @override
  String importCountOrders(Object count) {
    return 'Import $count orders';
  }

  @override
  String get importingOrders => 'Importing orders';

  @override
  String get importResultDone => 'Import complete';

  @override
  String get importResultPartial => 'Import partly complete';

  @override
  String get importResultNone => 'Nothing was imported';

  @override
  String importCommittedCount(Object count) {
    return '$count orders created';
  }

  @override
  String importRejectedCount(Object count) {
    return '$count rows rejected by Cefflo';
  }

  @override
  String importSkippedCount(Object count) {
    return '$count rows not sent (need attention)';
  }

  @override
  String importRowReason(Object row, Object reason) {
    return 'Row $row: $reason';
  }

  @override
  String get importViewOrders => 'View orders';

  @override
  String get importAnotherFile => 'Import another file';

  @override
  String get importChangeFile => 'Choose another file';

  @override
  String get importBackToMatch => 'Back to matching';

  @override
  String get importFieldPhone => 'Customer phone';

  @override
  String get importFieldZone => 'Zone';

  @override
  String get importFieldItems => 'Items';

  @override
  String get importFieldNotes => 'Notes';

  @override
  String get importKpiCreated => 'Created';

  @override
  String get importKpiRejected => 'Rejected';

  @override
  String get importKpiNotSent => 'Not sent';

  @override
  String get appearanceStandard => 'Cefflo standard';

  @override
  String get appearanceBackground => 'Background';

  @override
  String get appearancePlain => 'Plain';

  @override
  String get appearanceGradient => 'Gradient';

  @override
  String get appearanceSaved => 'Appearance saved on this device.';

  @override
  String get appearanceDeviceOnly =>
      'Applies to this device only. Tap Save to keep it.';

  @override
  String get purple => 'Purple';

  @override
  String get yourInviteLink => 'Your invite link';

  @override
  String get shareMessage => 'Share message';

  @override
  String get shareVia => 'Share via';

  @override
  String get copyText => 'Copy';

  @override
  String get messageCopied => 'Message copied';

  @override
  String inviteMsgRider(Object business, Object link) {
    return 'Hi, you\'re invited to join $business as a rider. Register here: $link';
  }

  @override
  String inviteMsgTeam(Object business, Object link) {
    return 'Hi, you\'re invited to join $business on Cefflo. Open this link: $link';
  }

  @override
  String get noPendingRidersYet => 'No pending riders yet.';

  @override
  String inviteShareMessage(Object business) {
    return 'Hi, you\'re invited to join $business. Click the link below to register.';
  }

  @override
  String get resetLink => 'Reset link';

  @override
  String get resetLinkTitle => 'Reset this invite link?';

  @override
  String get resetLinkBody =>
      'The current link stops working immediately. Share the new link with anyone who hasn\'t joined yet.';

  @override
  String get linkResetDone => 'A new invite link is ready.';

  @override
  String get inviteLinkPermanent =>
      'This link stays the same until you reset it. Everyone who joins waits for your approval.';

  @override
  String get moreText => 'More';

  @override
  String get scanToJoinBody =>
      'Scan with a phone camera to open the invitation.';

  @override
  String get joinRequests => 'Join requests';

  @override
  String get approveText => 'Approve';

  @override
  String get requestApproved => 'Request approved.';

  @override
  String get requestRejected => 'Request rejected.';

  @override
  String get riderApproved => 'Rider approved.';

  @override
  String get riderRejected => 'Rider rejected.';

  @override
  String joinTitle(Object business) {
    return 'Join $business';
  }

  @override
  String get joinBody =>
      'Complete your details. The business approves every request before you get access.';

  @override
  String get joinSubmit => 'Send request';

  @override
  String get joinPendingTitle => 'Waiting for approval';

  @override
  String joinPendingBody(Object business) {
    return 'Your request was sent to $business. You\'ll get access once it\'s approved.';
  }

  @override
  String get joinLinkUnavailable =>
      'This invite link is no longer valid. Ask the business for the new link.';

  @override
  String messageCopiedPasteIn(Object app) {
    return 'Message copied. Paste it in $app.';
  }

  @override
  String get shareInviteLink => 'Share invite link';

  @override
  String get operatingAreaLabel => 'Operating area';

  @override
  String get operatingAreaHint =>
      'Areas you deliver to, e.g. Bangsar, Mont Kiara';

  @override
  String get businessSaved => 'Business details saved.';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get photoFormat => 'Choose a JPG, PNG or WebP photo.';

  @override
  String get photoTooLarge =>
      'This photo is larger than 2 MB. Choose a smaller one.';

  @override
  String get photoUpdated => 'Profile photo updated.';

  @override
  String get photoRemoved => 'Profile photo removed.';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get removePhoto => 'Remove';

  @override
  String get emailChanged => 'Your sign-in email has changed.';

  @override
  String get confirmCurrentEmail => 'Confirm your current email';

  @override
  String get confirmNewEmail => 'Confirm your new email';

  @override
  String get changeEmail => 'Change email';

  @override
  String get changeEmailBody =>
      'We\'ll send a code to your current email and to the new one. Your email changes only after both are confirmed.';

  @override
  String get newEmail => 'New email';

  @override
  String get sendCodes => 'Send codes';

  @override
  String get sameEmail => 'This is already your email.';

  @override
  String get subscriptionManagedTitle => 'Managed by Cefflo';

  @override
  String get subscriptionUnavailable =>
      'Your plan details aren\'t available in the app yet. Contact Cefflo support for your current plan.';

  @override
  String get subscriptionStatus => 'Status';

  @override
  String trialEnds(Object date) {
    return 'Trial ends $date';
  }

  @override
  String get planQuestionSubject => 'Subscription question';

  @override
  String get emailSupportTeam => 'Email the Cefflo support team';

  @override
  String get yourStorefront => 'Your storefront';

  @override
  String get storefrontPublished => 'Published';

  @override
  String get storefrontUnpublished => 'Not published';

  @override
  String get storefrontUnpublishedNote =>
      'Customers can\'t open this link until you publish your storefront.';

  @override
  String get storefrontPublishedNote =>
      'Customers can open this link and order. It stays the same, so you can put it on your website or social media.';

  @override
  String get storefrontLink => 'Storefront link';

  @override
  String get shareStorefront => 'Share storefront';

  @override
  String storefrontShareMessage(Object business) {
    return 'Order from $business online:';
  }

  @override
  String get scanToOrder => 'Scan to order';

  @override
  String get scanToOrderBody =>
      'Customers scan with a phone camera to open your storefront.';

  @override
  String get storefrontLoadFailed => 'Your storefront couldn\'t be loaded.';

  @override
  String get hoursSaved => 'Business hours saved.';

  @override
  String get overnightHint => 'Closes the next day';

  @override
  String get open24h => 'Open 24 hours';

  @override
  String get photosMax5 => 'A product can have up to 5 photos.';

  @override
  String get photoOver5mb =>
      'This photo is larger than 5 MB after compression. Choose a smaller one.';

  @override
  String photoN(Object n) {
    return 'Photo $n';
  }

  @override
  String get moveEarlier => 'Move earlier';

  @override
  String get moveLater => 'Move later';

  @override
  String get photosRules =>
      'Up to 5 photos · JPG, PNG or WebP · 5 MB each. The first photo is the cover.';

  @override
  String get subTrial => 'Trial';

  @override
  String get subActive => 'Active';

  @override
  String get subPastDue => 'Payment overdue';

  @override
  String get subSuspended => 'Suspended';

  @override
  String get subCancelled => 'Cancelled';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'You\'ll need to sign in again to manage your business.';

  @override
  String get yesSignOut => 'Yes, sign out';

  @override
  String get heroTooLarge =>
      'This image is larger than 5 MB. Choose a smaller one.';

  @override
  String signedInAs(Object email) {
    return 'Signed in as $email';
  }

  @override
  String get useAnotherAccount => 'Use another account';

  @override
  String alreadyPartOf(Object business) {
    return 'You\'re already part of $business.';
  }

  @override
  String get alreadyPartOfBody =>
      'This account already has access. No new request was needed.';

  @override
  String get continueToApp => 'Continue';

  @override
  String get ntWebSoundPending =>
      'In this browser version sound is not available yet. The Cefflo notification sound is still being designed; the phone app uses the device\'s alert sound for now.';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryHint => 'e.g. Donuts, Drinks';

  @override
  String get categoryRequired => 'Choose or type a category.';

  @override
  String newCategoryChip(Object name) {
    return 'New: $name';
  }

  @override
  String get unnamedTeamMember => 'Team member';

  @override
  String get emailAlreadyRegistered => 'This email is already registered.';

  @override
  String get productAddedToast => 'Product added successfully';

  @override
  String get productUpdatedToast => 'Product updated successfully';

  @override
  String get removeMember => 'Remove member';

  @override
  String get removeRider => 'Remove rider';

  @override
  String removeMemberTitle(String name) {
    return 'Remove $name from your team?';
  }

  @override
  String removeMemberBody(String name) {
    return '$name will lose access to this business and its permitted workspace.';
  }

  @override
  String removeRiderTitle(String name) {
    return 'Remove $name as a rider?';
  }

  @override
  String removeRiderBody(String name) {
    return '$name will lose access to this business and can no longer receive new delivery assignments from this business.';
  }

  @override
  String get typeConfirmToContinue => 'Type CONFIRM to continue.';

  @override
  String get memberRemoved => 'Member removed';

  @override
  String get riderRemoved => 'Rider removed';

  @override
  String get riderHasActiveWorkCannotRemove =>
      'This rider still has active deliveries. Finish or reassign them, then try again.';

  @override
  String get removalNotConfirmed =>
      'We couldn\'t confirm the removal. Refresh and try again.';

  @override
  String get reportIssue => 'Report issue';

  @override
  String get reportIssueLead =>
      'The order moves to Issue and appears in Need Attention.';

  @override
  String get issueReported => 'Issue reported.';

  @override
  String couldNotReportIssue(Object error) {
    return 'Could not report issue: $error';
  }

  @override
  String get issueCustomerUnreachable => 'Customer unreachable';

  @override
  String get issueAddressProblem => 'Address problem';

  @override
  String get issueAccessProblem => 'Access problem';

  @override
  String get issueVendorNotReady => 'Order not ready';

  @override
  String get issueRiderUnableToProceed => 'Rider unable to proceed';
}
