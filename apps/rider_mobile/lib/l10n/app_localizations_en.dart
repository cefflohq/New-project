// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get justNow => 'Just now';

  @override
  String get business => 'Business';

  @override
  String get activeDriver => 'Active Driver';

  @override
  String get pendingReview => 'Pending review';

  @override
  String get deliveryRun => 'Delivery run';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

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
  String get reasonCantRecordedYetChooseAnother =>
      'This reason can\'t be recorded yet. Choose another reason or contact the business.';

  @override
  String get splash => 'Splash';

  @override
  String get sign => 'Sign In';

  @override
  String get signEmail => 'Sign In with Email';

  @override
  String get createAccount => 'Create your account';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get checkEmail => 'Check your email';

  @override
  String get setNewPassword => 'Set a new password';

  @override
  String get passwordUpdated => 'Password Updated!';

  @override
  String get invitationLanding => 'Invitation Landing';

  @override
  String get acceptInvitation => 'Accept Invitation';

  @override
  String get noBusinessConnected => 'No Business Connected';

  @override
  String get driverDetails => 'Driver Details';

  @override
  String get personalDetails => 'Personal Details';

  @override
  String get vehicleDocuments => 'Vehicle & Documents';

  @override
  String get applicationUnderReview => 'Application Under Review';

  @override
  String get youreApproved => 'You’re Approved!';

  @override
  String get readyGo => 'Ready to Go';

  @override
  String get joinBusiness => 'Join Business';

  @override
  String get businessJoined => 'Business Joined';

  @override
  String get today => 'Today';

  @override
  String get runDetails => 'Run Details';

  @override
  String get stopList => 'Stop List';

  @override
  String get navigationStop => 'Navigation to Stop';

  @override
  String get confirmDelivery => 'Confirm Delivery';

  @override
  String get deliveryIssue => 'Delivery Issue';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String get runCompleted => 'Run Completed';

  @override
  String get deliveryHistory => 'Delivery History';

  @override
  String get historyDetail => 'History Detail';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get vehicleDetails => 'Vehicle Details';

  @override
  String get documents => 'Documents';

  @override
  String get settings => 'Settings';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get vendorSupport => 'Vendor Support';

  @override
  String get submitTicket => 'Submit Ticket';

  @override
  String km(Object distanceKm) {
    return '$distanceKm km';
  }

  @override
  String get assigned => 'Assigned';

  @override
  String get way => 'On the way';

  @override
  String get completed => 'Completed';

  @override
  String get customerNotAvailable => 'Customer not available';

  @override
  String get wrongAddress => 'Wrong address';

  @override
  String get customerRequestedReschedule => 'Customer requested reschedule';

  @override
  String get itemSNotAvailable => 'Item(s) not available';

  @override
  String get safetyConcern => 'Safety concern';

  @override
  String get other => 'Other';

  @override
  String get customerDidNotAnswerNotLocation =>
      'Customer did not answer or not at location.';

  @override
  String get addressNotFoundIncorrect => 'Address not found or incorrect.';

  @override
  String get customerAskedDeliverLaterTime =>
      'Customer asked to deliver at a later time.';

  @override
  String get itemSNotAvailableStore => 'Item(s) not available at store.';

  @override
  String get unsafeCompleteDelivery => 'Unsafe to complete delivery.';

  @override
  String get tellUsMoreAboutIssue => 'Tell us more about the issue.';

  @override
  String get deliveryRunIssue => 'Delivery / Run Issue';

  @override
  String get vendorBusinessIssue => 'Vendor / Business Issue';

  @override
  String get ceffloAppIssue => 'Cefflo App Issue';

  @override
  String get accountDocuments => 'Account / Documents';

  @override
  String get ordersPickupDeliveryCustomer =>
      'Orders, pickup, delivery, customer';

  @override
  String get assignmentPaymentCustomerIssue =>
      'Assignment, payment, customer issue';

  @override
  String get appBugErrorTechnicalProblem => 'App bug, error, technical problem';

  @override
  String get profileDocumentsVerification => 'Profile, documents, verification';

  @override
  String get somethingElse => 'Something else';

  @override
  String get readyPickup => 'Ready for pickup';

  @override
  String get pickedUp => 'Picked up';

  @override
  String get outDelivery => 'Out for delivery';

  @override
  String get delivered => 'Delivered';

  @override
  String get issue => 'Issue';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get item => 'Item';

  @override
  String get notSigned => 'Not signed in.';

  @override
  String actionNeedsBackendContractThatNot(Object message) {
    return 'This action needs a backend contract that is not deployed here ($message).';
  }

  @override
  String get ceffloDriver => 'Cefflo Driver';

  @override
  String get reCenter => 'Re-center';

  @override
  String get continueApple => 'Continue with Apple';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueEmail => 'Continue with Email';

  @override
  String get haveInvite => 'Have an invite?';

  @override
  String get getStarted => 'Get started';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get done => 'Done';

  @override
  String get enterEmailPasswordContinue =>
      'Enter your email and password\nto continue.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get signing => 'Signing In…';

  @override
  String get continueText => 'Continue with';

  @override
  String get apple => 'Apple';

  @override
  String get google => 'Google';

  @override
  String get dontHaveAccount => 'Don’t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get checkEmailVerifyAccountThenSign =>
      'Check your email to verify this account, then sign in.';

  @override
  String get createAccount2 => 'Create your\naccount';

  @override
  String get letsGetStartedCreateCeffloDriver =>
      'Let’s get you started. Create your\nCefflo Driver account.';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get createPassword => 'Create a password';

  @override
  String get passwordMustLeast8CharactersNumber =>
      'Password must be at least 8 characters\nwith a number and a letter.';

  @override
  String get creatingAccount => 'Creating Account…';

  @override
  String get createAccount3 => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get forgotPassword2 => 'Forgot\nPassword?';

  @override
  String get noWorriesEnterEmailWellSend =>
      'No worries. Enter your email and\nwe’ll send you a reset link.';

  @override
  String get sending => 'Sending…';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backSign => 'Back to Sign In';

  @override
  String get keepAccountSecure => 'Keep your account secure';

  @override
  String get wellSendSecureLinkResetPassword =>
      'We’ll send a secure link to reset your password. The link will expire after a short period.';

  @override
  String get weveSentPasswordResetLink => 'We’ve sent a password reset link to';

  @override
  String get edit => 'Edit';

  @override
  String get openEmailInbox => 'Open your email inbox';

  @override
  String get checkInboxSpamFolder => 'Check your inbox (and spam folder).';

  @override
  String get clickResetLink => 'Click the reset link';

  @override
  String get followInstructionsEmail => 'Follow the instructions in the email.';

  @override
  String get returnAppSign => 'Return to the app and sign in.';

  @override
  String get didntReceiveEmail => 'Didn’t receive the email?';

  @override
  String get canRequestNewLink60Seconds =>
      'You can request a new link in 60 seconds.';

  @override
  String get resendEmail58s => 'Resend Email (58s)';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get setNewPassword2 => 'Set a new\npassword';

  @override
  String get chooseStrongPasswordCeffloDriverAccount =>
      'Choose a strong password for\nyour Cefflo Driver account.';

  @override
  String get newPassword => 'New Password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPassword2 => 'Confirm your password';

  @override
  String get updating => 'Updating…';

  @override
  String get updatePassword => 'Update Password';

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
  String get passwordHasBeenSuccessfullyUpdated =>
      'Your password has been\nsuccessfully updated.';

  @override
  String get accountSecure => 'Your account is secure';

  @override
  String get canNowSignNewPassword =>
      'You can now sign in with your new password.';

  @override
  String get youllStaySigned => 'You’ll stay signed in';

  @override
  String get deviceCanContinueUsingApp =>
      'On this device, you can continue using the app.';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get youreInvited => 'You’re Invited!';

  @override
  String joinCeffloPartTheirDeliveryTeam(Object business) {
    return 'Join $business on Cefflo. Be part of their delivery team and start making deliveries.';
  }

  @override
  String get workTrustedLocalBusiness => 'Work with a trusted local business';

  @override
  String get makeDeliveriesWithinTheirServiceArea =>
      'Make deliveries within their service area.';

  @override
  String get startDeliveringToday => 'Start delivering today';

  @override
  String get getAccessOnceAccountApproved =>
      'Get access once your account is approved.';

  @override
  String get allOneApp => 'All in one app';

  @override
  String get ordersNavigationSupport => 'Orders, navigation and support.';

  @override
  String get decline => 'Decline';

  @override
  String all(Object allCount) {
    return 'All ($allCount)';
  }

  @override
  String pending(Object pendingCount) {
    return 'Pending ($pendingCount)';
  }

  @override
  String delivered2(Object deliveredCount) {
    return 'Delivered ($deliveredCount)';
  }

  @override
  String get noRunsViewYet => 'No runs in this view yet.';

  @override
  String stops(Object orderCount, Object distanceText, Object durationLabel) {
    return '$orderCount stops  •  $distanceText  •  $durationLabel';
  }

  @override
  String stops2(Object orderCount) {
    return '$orderCount stops';
  }

  @override
  String get zone => 'Zone';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get started => 'Started';

  @override
  String deliveryStops(Object orderCount) {
    return 'Delivery Stops ($orderCount)';
  }

  @override
  String unread(Object unreadCount) {
    return 'Unread ($unreadCount)';
  }

  @override
  String archive(Object archivedCount) {
    return 'Archive ($archivedCount)';
  }

  @override
  String get nothingHereRightNow => 'Nothing here right now.';

  @override
  String get youveBeenInvitedJoinBusinessCefflo =>
      'You’ve been invited to join this\nbusiness on Cefflo.';

  @override
  String get messageFromBusiness => 'Message from the business';

  @override
  String get makeDeliveriesOurCustomers => 'Make deliveries for our customers';

  @override
  String get helpUsDeliverOrdersWithinOur =>
      'Help us deliver orders within our service area.';

  @override
  String get simpleStraightforward => 'Simple and straightforward';

  @override
  String get completeDetailsGetApprovedByBusiness =>
      'Complete your details and get approved by the business.';

  @override
  String get partTeam => 'Be part of the team';

  @override
  String get workTrustedLocalBusinessCefflo =>
      'Work with a trusted local business on Cefflo.';

  @override
  String get acceptContinue => 'Accept & Continue';

  @override
  String get declineInvitation => 'Decline Invitation';

  @override
  String get goodMorning => 'Good Morning,';

  @override
  String get letsGetConnected => 'Let’s get you connected.';

  @override
  String get accountReadyButYoureNotConnected =>
      'Your account is ready, but you’re not\nconnected to any business yet.';

  @override
  String get iHaveInvitation => 'I have an invitation';

  @override
  String get joinBusinessInviteLinkCode =>
      'Join a business with an invite link or code.';

  @override
  String get ifYouveReceivedInvitationTapLink =>
      'If you’ve received an invitation, tap the link to join.';

  @override
  String get needHelp => 'Need help?';

  @override
  String get contactSupportIfYoureUnsure => 'Contact support if you’re unsure.';

  @override
  String get motorbike => 'Motorbike';

  @override
  String get tellUsBitMoreSoBusiness =>
      'Tell us a bit more so the business\ncan verify your profile.';

  @override
  String get profileInformation => 'Profile Information';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get useClearPhotoFace => 'Use a clear photo of your face.';

  @override
  String get vehicleInformation => 'Vehicle Information';

  @override
  String get vehicleType => 'Vehicle Type';

  @override
  String get vehicleNumberPlate => 'Vehicle Number Plate';

  @override
  String get eGVaa1234 => 'E.g. VAA 1234';

  @override
  String get continueText2 => 'Continue';

  @override
  String get letsGetKnowInformationWillShared =>
      'Let’s get to know you. This information\nwill be shared with the business.';

  @override
  String get dateBirth => 'Date of Birth';

  @override
  String get verified => 'Verified';

  @override
  String get address => 'Address';

  @override
  String get emergencyContactOptional => 'Emergency Contact (Optional)';

  @override
  String get next => 'Next';

  @override
  String get vaa1234 => 'VAA 1234';

  @override
  String get addVehicleDetailsRequiredDocumentsComplete =>
      'Add your vehicle details and required\ndocuments to complete your profile.';

  @override
  String get requiredDocuments => 'Required Documents';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get submitReview => 'Submit for Review';

  @override
  String get informationSecureOnlySharedBusiness =>
      'Your information is secure and only shared with the business.';

  @override
  String get submittingDetails => 'Submitting your details';

  @override
  String get pleaseWaitWhileWeSendInformation =>
      'Please wait while we send\nyour information to the business.';

  @override
  String get personalDetails2 => 'Personal details';

  @override
  String get vehicleDetails2 => 'Vehicle details';

  @override
  String get applicationSubmitted => 'Application Submitted!';

  @override
  String get detailsHaveBeenSentBusinessReview =>
      'Your details have been sent to\nthe business for review.';

  @override
  String get pendingReview2 => 'Pending Review';

  @override
  String get wellNotifyOnceBusinessHasReviewed =>
      'We’ll notify you once the business has reviewed and approved your application.';

  @override
  String get submitted => 'Submitted';

  @override
  String get thanksSubmittingDetailsWellNotifyOnce =>
      'Thanks for submitting your details.\nWe’ll notify you once the business\nhas reviewed and approved your application.';

  @override
  String get applicationBeingReviewedByBusiness =>
      'Your application is being reviewed by the business.';

  @override
  String get wellNotifyAppOnceAccountApproved =>
      'We’ll notify you in the app once your account is approved. You can close the app and check back later.';

  @override
  String get viewSubmittedDetails => 'View Submitted Details';

  @override
  String get previewSimulateApproval => 'Preview: simulate approval';

  @override
  String get welcomeTeamAccountNowActiveYoure =>
      'Welcome to the team.\nYour account is now active and\nyou’re ready to start delivering.';

  @override
  String get accountActive => 'Your account is active';

  @override
  String get canNowAcceptDeliveryRunsStart =>
      'You can now accept delivery runs and start earning with Cefflo.';

  @override
  String get goToday => 'Go to Today';

  @override
  String get goodSee => 'Good to see you,';

  @override
  String get readyHitRoad => 'Ready to hit the road?';

  @override
  String get accountActive2 => 'Account Active';

  @override
  String get youreAllSetStartDelivering =>
      'You’re all set to start delivering.';

  @override
  String get quickStart => 'Quick Start';

  @override
  String get goOnline => 'Go Online';

  @override
  String get startAcceptingDeliveryRuns => 'Start accepting delivery runs';

  @override
  String get viewAvailableJobs => 'View Available Jobs';

  @override
  String get seeNearbyDeliveryRequests => 'See nearby delivery requests';

  @override
  String get getHelpAnytime => 'Get help anytime';

  @override
  String get deliverMoreLocalBusinesses => 'Deliver More\nFor Local Businesses';

  @override
  String get partGrowingCommunityLocalDeliveryHeroes =>
      'Be part of a growing community of local delivery heroes.';

  @override
  String get youreNotConnectedBusinessYet =>
      'You’re not\nconnected to a\nbusiness yet.';

  @override
  String get joinBusinessStartDelivering =>
      'Join a business to start\ndelivering with ';

  @override
  String get gotInvitation => 'Got an invitation?';

  @override
  String get joinBusinessInviteLinkFromEmployer =>
      'Join your business with an invite link from your employer.';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get useQrCodeFromBusinessJoin =>
      'Use a QR code from your business to join.';

  @override
  String get contactBusinessOwnerInvitation =>
      'Contact your business owner for an invitation.';

  @override
  String get enterInvitationLinkCodeProvidedBy =>
      'Enter the invitation link or code provided\nby your business.';

  @override
  String get inviteLink => 'Invite Link';

  @override
  String get qrCode => 'QR Code';

  @override
  String get invitationLink => 'Invitation Link';

  @override
  String get dontHaveLinkCodeRequestInvitation =>
      'Don’t have a link or code?\nRequest an invitation from your business owner or administrator.';

  @override
  String get youveJoined => 'You’ve Joined!';

  @override
  String get nowPart => 'You are now part of';

  @override
  String get accountConnected => 'Account connected';

  @override
  String get accountLinkedBusiness => 'Your account is linked to the business.';

  @override
  String get businessDetails => 'Business details';

  @override
  String get youreAllSet => 'You’re all set';

  @override
  String get canNowStartReceivingDeliveriesOnce =>
      'You can now start receiving deliveries once assigned by your business.';

  @override
  String get goHome => 'Go to Home';

  @override
  String get goodMorning2 => 'Good morning,';

  @override
  String get letsGetToday => 'Let’s get to it today.';

  @override
  String get todaysOverview => 'Today’s Overview';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get issues => 'Issues';

  @override
  String get currentRun => 'Current Run';

  @override
  String get noRunAssignedYetWhenBusiness =>
      'No run assigned yet. When your business dispatches a run to you, it appears here.';

  @override
  String orders(Object orderCount, Object distanceText) {
    return '$orderCount orders  •  $distanceText';
  }

  @override
  String started2(Object startedAtLabel) {
    return 'Started $startedAtLabel';
  }

  @override
  String get viewRunDetails => 'View Run Details';

  @override
  String orders2(Object orderCount) {
    return '$orderCount orders';
  }

  @override
  String get pickUpFromStore => 'Pick up from store';

  @override
  String deliverOrders(Object orderCount) {
    return 'Deliver $orderCount orders';
  }

  @override
  String get multipleLocations => 'Multiple locations';

  @override
  String get completeRun => 'Complete run';

  @override
  String get markAllOrdersDelivered => 'Mark all orders as delivered';

  @override
  String get acceptRun => 'Accept Run';

  @override
  String get confirmPickup => 'Confirm Pickup';

  @override
  String get viewOrders => 'View Orders';

  @override
  String orders3(Object reference, Object orderCount) {
    return '$reference  •  $orderCount orders';
  }

  @override
  String get noStopsView => 'No stops in this view.';

  @override
  String get list => 'List';

  @override
  String get map => 'Map';

  @override
  String get mapShowsCurrentStopOrder =>
      'This map shows your current stop order.';

  @override
  String get dragDropReorderStops => 'Drag and drop to reorder your stops.';

  @override
  String get switchListViewDragReorder =>
      'Switch to List view to drag and reorder.';

  @override
  String get willUpdateRouteAvailableBeforeStart =>
      'This will update your route. Available before you start.';

  @override
  String get slideConfirmRoute => 'Slide to Confirm Route';

  @override
  String get setapak => 'Setapak';

  @override
  String get tamanSetapak => 'Taman\nSetapak';

  @override
  String get danauKota => 'Danau Kota';

  @override
  String get pending2 => 'Pending';

  @override
  String min(Object etaMinutes) {
    return '$etaMinutes min';
  }

  @override
  String get slideArrive => 'Slide to Arrive';

  @override
  String calling(Object customerName) {
    return 'Calling $customerName…';
  }

  @override
  String get openingChat => 'Opening chat…';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get noItemisedOrderLinesStop =>
      'No itemised order lines for this stop.';

  @override
  String get proofDelivery => 'Proof of Delivery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get photoAdded => 'Photo added';

  @override
  String get unableDeliverReportIssue => 'Unable to deliver? Report an issue';

  @override
  String get slideComplete => 'Slide to Complete';

  @override
  String get takeProofDeliveryPhotoFirst =>
      'Take a proof-of-delivery photo first.';

  @override
  String get confirmingDelivery => 'Confirming delivery…';

  @override
  String get pleaseWaitMoment => 'Please wait a moment.';

  @override
  String get deliveryConfirmed => 'Delivery confirmed';

  @override
  String hasBeenMarkedDelivered(Object reference) {
    return '$reference has been marked as delivered.';
  }

  @override
  String get unableCompleteDelivery => 'Unable to complete delivery?';

  @override
  String get letUsKnowWhatHappened => 'Let us know what happened.';

  @override
  String get selectedIssue => 'Selected Issue';

  @override
  String get notesRequired => 'Notes (Required)';

  @override
  String get addMoreDetailsAboutWhatHappened =>
      'Add more details about what happened…';

  @override
  String get addPhotosOptional => 'Add Photos (Optional)';

  @override
  String get tapReplaceAttachedPhoto => 'Tap to replace the attached photo.';

  @override
  String get takePhotoChooseFromGallery =>
      'Take a photo or choose from gallery';

  @override
  String get reportWillSentBusinessTeamReview =>
      'Your report will be sent to the business team for review. We’ll keep you updated.';

  @override
  String get submit => 'Submit';

  @override
  String get submitting => 'Submitting…';

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String get businessTeamWillReviewReport =>
      'The business team will review your report.';

  @override
  String get runCompleted2 => 'Run Completed!';

  @override
  String get greatJobYouveCompletedAllStops =>
      'Great job! You’ve completed\nall stops in this run.';

  @override
  String completed2(Object deliveredCount, Object orderCount) {
    return '$deliveredCount / $orderCount completed';
  }

  @override
  String get distance => 'Distance';

  @override
  String get time => 'Time';

  @override
  String get allDeliveryDetailsHaveBeenUpdated =>
      'All delivery details have been updated. You can view the run in your history.';

  @override
  String get language => 'Language';

  @override
  String get security => 'Security';

  @override
  String get logOut => 'Log Out';

  @override
  String get about => 'About';

  @override
  String get v120Driver => 'v1.2.0 (Driver)';

  @override
  String get logOut2 => 'Log out?';

  @override
  String get youllNeedSignAgainContinueDelivering =>
      'You’ll need to sign in again to\ncontinue delivering.';

  @override
  String get cancel => 'Cancel';

  @override
  String get photoUploadNotWiredUpPreview =>
      'Photo upload is not wired up in this preview.';

  @override
  String get save => 'Save';

  @override
  String get model => 'Model';

  @override
  String get registrationPlateNumber => 'Registration / Plate Number';

  @override
  String get review => 'In review';

  @override
  String get missing => 'Missing';

  @override
  String get documentSubmitted => 'Document submitted';

  @override
  String hasBeenSentVerification(Object title) {
    return '$title has been sent for verification.';
  }

  @override
  String get notification => 'Notification';

  @override
  String get appearance => 'Appearance';

  @override
  String get light => 'Light';

  @override
  String get lightModeOnlyRelease => 'Light Mode only in this release.';

  @override
  String get securitySettingsNotWiredUpPreview =>
      'Security settings are not wired up in this preview.';

  @override
  String get term => 'Term';

  @override
  String get howCanWeHelp => 'How can we help?';

  @override
  String get commonDriverTopics => 'Common Driver Topics';

  @override
  String noTopicsMatch(Object trim) {
    return 'No topics match “$trim”.';
  }

  @override
  String get needMoreHelp => 'Need more help?';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get submitSupportTicket => 'Submit a support ticket';

  @override
  String get mySupportTickets => 'My Support Tickets';

  @override
  String get checkTicketStatus => 'Check your ticket status';

  @override
  String get haveNoSupportTicketsYetSubmit =>
      'You have no support tickets yet. Submit one from Contact Support and it will appear here.';

  @override
  String get whatDoNeedHelp => 'What do you need help with?';

  @override
  String get contactBusiness => 'Contact Business';

  @override
  String get issueRelatedVendorsBusinessOperationsE =>
      'This issue is related to the vendor’s business operations (e.g. orders, assignments, customer, delivery instructions).';

  @override
  String get pleaseContactBusinessDirectlyFasterAssistance =>
      'Please contact the business directly for faster assistance.';

  @override
  String get call => 'Call';

  @override
  String calling2(Object vendor) {
    return 'Calling $vendor…';
  }

  @override
  String get chat => 'Chat';

  @override
  String get appMessageVendor => 'In-app message to vendor';

  @override
  String get openingVendorChat => 'Opening vendor chat…';

  @override
  String get ceffloDoesNotManageVendorOperations =>
      'Cefflo does not manage vendor operations. For app or account issues, please go back and select the relevant category.';

  @override
  String get backHelpSupport => 'Back to Help & Support';

  @override
  String get ceffloSupport => 'Cefflo Support';

  @override
  String get tellUsAboutIssueWellGet =>
      'Tell us about the issue and we’ll get back to you as soon as possible.';

  @override
  String get category => 'Category';

  @override
  String get describeIssue => 'Describe your issue';

  @override
  String get pleaseProvideMuchDetailPossibleE =>
      'Please provide as much detail as possible…\n(e.g. what happened, when, steps to reproduce)';

  @override
  String get addScreenshotPhotoOptional => 'Add screenshot or photo (optional)';

  @override
  String get photoAttached => 'Photo attached';

  @override
  String get tapAddPhoto => 'Tap to add photo';

  @override
  String get pngJpgMax5mbEach => 'PNG, JPG (Max 5MB each)';

  @override
  String get requestSubmitted => 'Request submitted';

  @override
  String get wellGetBackSoon => 'We’ll get back to you soon.';

  @override
  String get back => 'Back';

  @override
  String get home => 'Home';

  @override
  String get runs => 'Runs';

  @override
  String get history => 'History';

  @override
  String get slideConfirm => 'Slide to confirm';

  @override
  String get tryAgain => 'Try again';

  @override
  String get orSeparator => 'or';

  @override
  String get joinBusinessDeliveryTeamCefflo =>
      'Join a business\'s delivery team on Cefflo. Open the invitation link you received to connect.';

  @override
  String get pasteFullInvitationLink =>
      'Paste the full invitation link you received.';

  @override
  String get car => 'Car';

  @override
  String get van => 'Van';

  @override
  String get detailsManagedByBusiness =>
      'Your details are managed by your business. Ask them to update anything that has changed.';

  @override
  String get supportTicketsNotConnectedYet =>
      'Support tickets are not connected yet. Contact your business directly for help.';

  @override
  String get runsDeliveries => 'Runs & Deliveries';

  @override
  String get ordersNavigationDeliveryProcess =>
      'Orders, navigation, delivery process';

  @override
  String get deliveryIssues => 'Delivery Issues';

  @override
  String get failedDeliveryCustomerNotAvailable =>
      'Failed delivery, customer not available';

  @override
  String get vehicleDocuments2 => 'Vehicle & Documents';

  @override
  String get licenceRegistrationDocumentVerification =>
      'Licence, registration, document verification';

  @override
  String get accountProfile => 'Account & Profile';

  @override
  String get profileSettingsAppAccess => 'Profile, settings, app access';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }
}
