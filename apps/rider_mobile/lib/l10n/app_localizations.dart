import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
  ];

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @activeDriver.
  ///
  /// In en, this message translates to:
  /// **'Active Driver'**
  String get activeDriver;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get pendingReview;

  /// No description provided for @deliveryRun.
  ///
  /// In en, this message translates to:
  /// **'Delivery run'**
  String get deliveryRun;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @reasonCantRecordedYetChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'This reason can\'t be recorded yet. Choose another reason or contact the business.'**
  String get reasonCantRecordedYetChooseAnother;

  /// No description provided for @splash.
  ///
  /// In en, this message translates to:
  /// **'Splash'**
  String get splash;

  /// No description provided for @sign.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign;

  /// No description provided for @signEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Email'**
  String get signEmail;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @checkEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmail;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get setNewPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password Updated!'**
  String get passwordUpdated;

  /// No description provided for @noBusinessConnected.
  ///
  /// In en, this message translates to:
  /// **'No Business Connected'**
  String get noBusinessConnected;

  /// No description provided for @driverDetails.
  ///
  /// In en, this message translates to:
  /// **'Driver Details'**
  String get driverDetails;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @vehicleDocuments.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & Documents'**
  String get vehicleDocuments;

  /// No description provided for @applicationUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Application Under Review'**
  String get applicationUnderReview;

  /// No description provided for @youreApproved.
  ///
  /// In en, this message translates to:
  /// **'You’re Approved!'**
  String get youreApproved;

  /// No description provided for @readyGo.
  ///
  /// In en, this message translates to:
  /// **'Ready to Go'**
  String get readyGo;

  /// No description provided for @joinBusiness.
  ///
  /// In en, this message translates to:
  /// **'Join Business'**
  String get joinBusiness;

  /// No description provided for @businessJoined.
  ///
  /// In en, this message translates to:
  /// **'Business Joined'**
  String get businessJoined;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @runDetails.
  ///
  /// In en, this message translates to:
  /// **'Run Details'**
  String get runDetails;

  /// No description provided for @stopList.
  ///
  /// In en, this message translates to:
  /// **'Stop List'**
  String get stopList;

  /// No description provided for @navigationStop.
  ///
  /// In en, this message translates to:
  /// **'Navigation to Stop'**
  String get navigationStop;

  /// No description provided for @confirmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery'**
  String get confirmDelivery;

  /// No description provided for @deliveryIssue.
  ///
  /// In en, this message translates to:
  /// **'Delivery Issue'**
  String get deliveryIssue;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @runCompleted.
  ///
  /// In en, this message translates to:
  /// **'Run Completed'**
  String get runCompleted;

  /// No description provided for @deliveryHistory.
  ///
  /// In en, this message translates to:
  /// **'Delivery History'**
  String get deliveryHistory;

  /// No description provided for @historyDetail.
  ///
  /// In en, this message translates to:
  /// **'History Detail'**
  String get historyDetail;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @vehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get vehicleDetails;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @vendorSupport.
  ///
  /// In en, this message translates to:
  /// **'Vendor Support'**
  String get vendorSupport;

  /// No description provided for @submitTicket.
  ///
  /// In en, this message translates to:
  /// **'Submit Ticket'**
  String get submitTicket;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'{distanceKm} km'**
  String km(Object distanceKm);

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @way.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get way;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @customerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Customer not available'**
  String get customerNotAvailable;

  /// No description provided for @wrongAddress.
  ///
  /// In en, this message translates to:
  /// **'Wrong address'**
  String get wrongAddress;

  /// No description provided for @customerRequestedReschedule.
  ///
  /// In en, this message translates to:
  /// **'Customer requested reschedule'**
  String get customerRequestedReschedule;

  /// No description provided for @itemSNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Item(s) not available'**
  String get itemSNotAvailable;

  /// No description provided for @safetyConcern.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get safetyConcern;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @customerDidNotAnswerNotLocation.
  ///
  /// In en, this message translates to:
  /// **'Customer did not answer or not at location.'**
  String get customerDidNotAnswerNotLocation;

  /// No description provided for @addressNotFoundIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Address not found or incorrect.'**
  String get addressNotFoundIncorrect;

  /// No description provided for @customerAskedDeliverLaterTime.
  ///
  /// In en, this message translates to:
  /// **'Customer asked to deliver at a later time.'**
  String get customerAskedDeliverLaterTime;

  /// No description provided for @itemSNotAvailableStore.
  ///
  /// In en, this message translates to:
  /// **'Item(s) not available at store.'**
  String get itemSNotAvailableStore;

  /// No description provided for @unsafeCompleteDelivery.
  ///
  /// In en, this message translates to:
  /// **'Unsafe to complete delivery.'**
  String get unsafeCompleteDelivery;

  /// No description provided for @tellUsMoreAboutIssue.
  ///
  /// In en, this message translates to:
  /// **'Tell us more about the issue.'**
  String get tellUsMoreAboutIssue;

  /// No description provided for @deliveryRunIssue.
  ///
  /// In en, this message translates to:
  /// **'Delivery / Run Issue'**
  String get deliveryRunIssue;

  /// No description provided for @vendorBusinessIssue.
  ///
  /// In en, this message translates to:
  /// **'Vendor / Business Issue'**
  String get vendorBusinessIssue;

  /// No description provided for @ceffloAppIssue.
  ///
  /// In en, this message translates to:
  /// **'Cefflo App Issue'**
  String get ceffloAppIssue;

  /// No description provided for @accountDocuments.
  ///
  /// In en, this message translates to:
  /// **'Account / Documents'**
  String get accountDocuments;

  /// No description provided for @ordersPickupDeliveryCustomer.
  ///
  /// In en, this message translates to:
  /// **'Orders, pickup, delivery, customer'**
  String get ordersPickupDeliveryCustomer;

  /// No description provided for @assignmentPaymentCustomerIssue.
  ///
  /// In en, this message translates to:
  /// **'Assignment, payment, customer issue'**
  String get assignmentPaymentCustomerIssue;

  /// No description provided for @appBugErrorTechnicalProblem.
  ///
  /// In en, this message translates to:
  /// **'App bug, error, technical problem'**
  String get appBugErrorTechnicalProblem;

  /// No description provided for @profileDocumentsVerification.
  ///
  /// In en, this message translates to:
  /// **'Profile, documents, verification'**
  String get profileDocumentsVerification;

  /// No description provided for @somethingElse.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get somethingElse;

  /// No description provided for @readyPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get readyPickup;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get pickedUp;

  /// No description provided for @outDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get outDelivery;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @issue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issue;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @notSigned.
  ///
  /// In en, this message translates to:
  /// **'Not signed in.'**
  String get notSigned;

  /// No description provided for @actionNeedsBackendContractThatNot.
  ///
  /// In en, this message translates to:
  /// **'This action needs a backend contract that is not deployed here ({message}).'**
  String actionNeedsBackendContractThatNot(Object message);

  /// No description provided for @ceffloDriver.
  ///
  /// In en, this message translates to:
  /// **'Cefflo Driver'**
  String get ceffloDriver;

  /// No description provided for @reCenter.
  ///
  /// In en, this message translates to:
  /// **'Re-center'**
  String get reCenter;

  /// No description provided for @continueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueApple;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @continueEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueEmail;

  /// No description provided for @haveInvite.
  ///
  /// In en, this message translates to:
  /// **'Have an invite?'**
  String get haveInvite;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @enterEmailPasswordContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password\nto continue.'**
  String get enterEmailPasswordContinue;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @signing.
  ///
  /// In en, this message translates to:
  /// **'Signing In…'**
  String get signing;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue with'**
  String get continueText;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @checkEmailVerifyAccountThenSign.
  ///
  /// In en, this message translates to:
  /// **'Check your email to verify this account, then sign in.'**
  String get checkEmailVerifyAccountThenSign;

  /// No description provided for @createAccount2.
  ///
  /// In en, this message translates to:
  /// **'Create your\naccount'**
  String get createAccount2;

  /// No description provided for @letsGetStartedCreateCeffloDriver.
  ///
  /// In en, this message translates to:
  /// **'Let’s get you started. Create your\nCefflo Driver account.'**
  String get letsGetStartedCreateCeffloDriver;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPassword;

  /// No description provided for @passwordMustLeast8CharactersNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters\nwith a number and a letter.'**
  String get passwordMustLeast8CharactersNumber;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating Account…'**
  String get creatingAccount;

  /// No description provided for @createAccount3.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount3;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPassword2.
  ///
  /// In en, this message translates to:
  /// **'Forgot\nPassword?'**
  String get forgotPassword2;

  /// No description provided for @noWorriesEnterEmailWellSend.
  ///
  /// In en, this message translates to:
  /// **'No worries. Enter your email and\nwe’ll send you a 6-digit code.'**
  String get noWorriesEnterEmailWellSend;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendResetLink;

  /// No description provided for @backSign.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backSign;

  /// No description provided for @keepAccountSecure.
  ///
  /// In en, this message translates to:
  /// **'Keep your account secure'**
  String get keepAccountSecure;

  /// No description provided for @wellSendSecureLinkResetPassword.
  ///
  /// In en, this message translates to:
  /// **'We’ll email you a 6-digit code to reset your password.'**
  String get wellSendSecureLinkResetPassword;

  /// No description provided for @weveSentPasswordResetLink.
  ///
  /// In en, this message translates to:
  /// **'We’ve sent a password reset link to'**
  String get weveSentPasswordResetLink;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @openEmailInbox.
  ///
  /// In en, this message translates to:
  /// **'Open your email inbox'**
  String get openEmailInbox;

  /// No description provided for @checkInboxSpamFolder.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox (and spam folder).'**
  String get checkInboxSpamFolder;

  /// No description provided for @clickResetLink.
  ///
  /// In en, this message translates to:
  /// **'Click the reset link'**
  String get clickResetLink;

  /// No description provided for @followInstructionsEmail.
  ///
  /// In en, this message translates to:
  /// **'Follow the instructions in the email.'**
  String get followInstructionsEmail;

  /// No description provided for @returnAppSign.
  ///
  /// In en, this message translates to:
  /// **'Return to the app and sign in.'**
  String get returnAppSign;

  /// No description provided for @didntReceiveEmail.
  ///
  /// In en, this message translates to:
  /// **'Didn’t receive the email?'**
  String get didntReceiveEmail;

  /// No description provided for @canRequestNewLink60Seconds.
  ///
  /// In en, this message translates to:
  /// **'You can request a new link in 60 seconds.'**
  String get canRequestNewLink60Seconds;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @setNewPassword2.
  ///
  /// In en, this message translates to:
  /// **'Set a new\npassword'**
  String get setNewPassword2;

  /// No description provided for @chooseStrongPasswordCeffloDriverAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password for\nyour Cefflo Driver account.'**
  String get chooseStrongPasswordCeffloDriverAccount;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPassword2.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPassword2;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @emailPasswordIncorrectTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect. Try again.'**
  String get emailPasswordIncorrectTryAgain;

  /// No description provided for @tooManyAttemptsPleaseWaitBefore.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait before trying again.'**
  String get tooManyAttemptsPleaseWaitBefore;

  /// No description provided for @unableConnectCheckConnectionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your connection and try again.'**
  String get unableConnectCheckConnectionTryAgain;

  /// No description provided for @passwordHasBeenSuccessfullyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your password has been\nsuccessfully updated.'**
  String get passwordHasBeenSuccessfullyUpdated;

  /// No description provided for @accountSecure.
  ///
  /// In en, this message translates to:
  /// **'Your account is secure'**
  String get accountSecure;

  /// No description provided for @canNowSignNewPassword.
  ///
  /// In en, this message translates to:
  /// **'You can now sign in with your new password.'**
  String get canNowSignNewPassword;

  /// No description provided for @youllStaySigned.
  ///
  /// In en, this message translates to:
  /// **'You’ll stay signed in'**
  String get youllStaySigned;

  /// No description provided for @deviceCanContinueUsingApp.
  ///
  /// In en, this message translates to:
  /// **'On this device, you can continue using the app.'**
  String get deviceCanContinueUsingApp;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All ({allCount})'**
  String all(Object allCount);

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending ({pendingCount})'**
  String pending(Object pendingCount);

  /// No description provided for @delivered2.
  ///
  /// In en, this message translates to:
  /// **'Delivered ({deliveredCount})'**
  String delivered2(Object deliveredCount);

  /// No description provided for @noRunsViewYet.
  ///
  /// In en, this message translates to:
  /// **'No runs in this view yet.'**
  String get noRunsViewYet;

  /// No description provided for @stops.
  ///
  /// In en, this message translates to:
  /// **'{orderCount} stops  •  {distanceText}  •  {durationLabel}'**
  String stops(Object orderCount, Object distanceText, Object durationLabel);

  /// No description provided for @stops2.
  ///
  /// In en, this message translates to:
  /// **'{orderCount} stops'**
  String stops2(Object orderCount);

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @deliveryStops.
  ///
  /// In en, this message translates to:
  /// **'Delivery Stops ({orderCount})'**
  String deliveryStops(Object orderCount);

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread ({unreadCount})'**
  String unread(Object unreadCount);

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive ({archivedCount})'**
  String archive(Object archivedCount);

  /// No description provided for @nothingHereRightNow.
  ///
  /// In en, this message translates to:
  /// **'Nothing here right now.'**
  String get nothingHereRightNow;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get goodMorning;

  /// No description provided for @letsGetConnected.
  ///
  /// In en, this message translates to:
  /// **'Let’s get you connected.'**
  String get letsGetConnected;

  /// No description provided for @accountReadyButYoureNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready, but you’re not\nconnected to any business yet.'**
  String get accountReadyButYoureNotConnected;

  /// No description provided for @iHaveInvitation.
  ///
  /// In en, this message translates to:
  /// **'I have an invitation'**
  String get iHaveInvitation;

  /// No description provided for @joinBusinessInviteLinkCode.
  ///
  /// In en, this message translates to:
  /// **'Join a business with an invite link or code.'**
  String get joinBusinessInviteLinkCode;

  /// No description provided for @ifYouveReceivedInvitationTapLink.
  ///
  /// In en, this message translates to:
  /// **'If you’ve received an invitation, tap the link to join.'**
  String get ifYouveReceivedInvitationTapLink;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelp;

  /// No description provided for @contactSupportIfYoureUnsure.
  ///
  /// In en, this message translates to:
  /// **'Contact support if you’re unsure.'**
  String get contactSupportIfYoureUnsure;

  /// No description provided for @motorbike.
  ///
  /// In en, this message translates to:
  /// **'Motorbike'**
  String get motorbike;

  /// No description provided for @tellUsBitMoreSoBusiness.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit more so the business\ncan verify your profile.'**
  String get tellUsBitMoreSoBusiness;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @useClearPhotoFace.
  ///
  /// In en, this message translates to:
  /// **'Use a clear photo of your face.'**
  String get useClearPhotoFace;

  /// No description provided for @vehicleInformation.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInformation;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @vehicleNumberPlate.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number Plate'**
  String get vehicleNumberPlate;

  /// No description provided for @eGVaa1234.
  ///
  /// In en, this message translates to:
  /// **'E.g. VAA 1234'**
  String get eGVaa1234;

  /// No description provided for @continueText2.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText2;

  /// No description provided for @letsGetKnowInformationWillShared.
  ///
  /// In en, this message translates to:
  /// **'Let’s get to know you. This information\nwill be shared with the business.'**
  String get letsGetKnowInformationWillShared;

  /// No description provided for @dateBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateBirth;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @emergencyContactOptional.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact (Optional)'**
  String get emergencyContactOptional;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @vaa1234.
  ///
  /// In en, this message translates to:
  /// **'VAA 1234'**
  String get vaa1234;

  /// No description provided for @addVehicleDetailsRequiredDocumentsComplete.
  ///
  /// In en, this message translates to:
  /// **'Add your vehicle details and required\ndocuments to complete your profile.'**
  String get addVehicleDetailsRequiredDocumentsComplete;

  /// No description provided for @requiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get requiredDocuments;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get submitReview;

  /// No description provided for @informationSecureOnlySharedBusiness.
  ///
  /// In en, this message translates to:
  /// **'Your information is secure and only shared with the business.'**
  String get informationSecureOnlySharedBusiness;

  /// No description provided for @submittingDetails.
  ///
  /// In en, this message translates to:
  /// **'Submitting your details'**
  String get submittingDetails;

  /// No description provided for @pleaseWaitWhileWeSendInformation.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we send\nyour information to the business.'**
  String get pleaseWaitWhileWeSendInformation;

  /// No description provided for @personalDetails2.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetails2;

  /// No description provided for @vehicleDetails2.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details'**
  String get vehicleDetails2;

  /// No description provided for @applicationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application Submitted!'**
  String get applicationSubmitted;

  /// No description provided for @detailsHaveBeenSentBusinessReview.
  ///
  /// In en, this message translates to:
  /// **'Your details have been sent to\nthe business for review.'**
  String get detailsHaveBeenSentBusinessReview;

  /// No description provided for @pendingReview2.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get pendingReview2;

  /// No description provided for @wellNotifyOnceBusinessHasReviewed.
  ///
  /// In en, this message translates to:
  /// **'We’ll notify you once the business has reviewed and approved your application.'**
  String get wellNotifyOnceBusinessHasReviewed;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @thanksSubmittingDetailsWellNotifyOnce.
  ///
  /// In en, this message translates to:
  /// **'Thanks for submitting your details.\nWe’ll notify you once the business\nhas reviewed and approved your application.'**
  String get thanksSubmittingDetailsWellNotifyOnce;

  /// No description provided for @applicationBeingReviewedByBusiness.
  ///
  /// In en, this message translates to:
  /// **'Your application is being reviewed by the business.'**
  String get applicationBeingReviewedByBusiness;

  /// No description provided for @wellNotifyAppOnceAccountApproved.
  ///
  /// In en, this message translates to:
  /// **'We’ll notify you in the app once your account is approved. You can close the app and check back later.'**
  String get wellNotifyAppOnceAccountApproved;

  /// No description provided for @viewSubmittedDetails.
  ///
  /// In en, this message translates to:
  /// **'View Submitted Details'**
  String get viewSubmittedDetails;

  /// No description provided for @previewSimulateApproval.
  ///
  /// In en, this message translates to:
  /// **'Preview: simulate approval'**
  String get previewSimulateApproval;

  /// No description provided for @welcomeTeamAccountNowActiveYoure.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the team.\nYour account is now active and\nyou’re ready to start delivering.'**
  String get welcomeTeamAccountNowActiveYoure;

  /// No description provided for @accountActive.
  ///
  /// In en, this message translates to:
  /// **'Your account is active'**
  String get accountActive;

  /// No description provided for @canNowAcceptDeliveryRunsStart.
  ///
  /// In en, this message translates to:
  /// **'You can now accept delivery runs and start earning with Cefflo.'**
  String get canNowAcceptDeliveryRunsStart;

  /// No description provided for @goToday.
  ///
  /// In en, this message translates to:
  /// **'Go to Today'**
  String get goToday;

  /// No description provided for @goodSee.
  ///
  /// In en, this message translates to:
  /// **'Good to see you,'**
  String get goodSee;

  /// No description provided for @readyHitRoad.
  ///
  /// In en, this message translates to:
  /// **'Ready to hit the road?'**
  String get readyHitRoad;

  /// No description provided for @accountActive2.
  ///
  /// In en, this message translates to:
  /// **'Account Active'**
  String get accountActive2;

  /// No description provided for @youreAllSetStartDelivering.
  ///
  /// In en, this message translates to:
  /// **'You’re all set to start delivering.'**
  String get youreAllSetStartDelivering;

  /// No description provided for @quickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get quickStart;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go Online'**
  String get goOnline;

  /// No description provided for @startAcceptingDeliveryRuns.
  ///
  /// In en, this message translates to:
  /// **'Start accepting delivery runs'**
  String get startAcceptingDeliveryRuns;

  /// No description provided for @viewAvailableJobs.
  ///
  /// In en, this message translates to:
  /// **'View Available Jobs'**
  String get viewAvailableJobs;

  /// No description provided for @seeNearbyDeliveryRequests.
  ///
  /// In en, this message translates to:
  /// **'See nearby delivery requests'**
  String get seeNearbyDeliveryRequests;

  /// No description provided for @getHelpAnytime.
  ///
  /// In en, this message translates to:
  /// **'Get help anytime'**
  String get getHelpAnytime;

  /// No description provided for @deliverMoreLocalBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Deliver More\nFor Local Businesses'**
  String get deliverMoreLocalBusinesses;

  /// No description provided for @partGrowingCommunityLocalDeliveryHeroes.
  ///
  /// In en, this message translates to:
  /// **'Be part of a growing community of local delivery heroes.'**
  String get partGrowingCommunityLocalDeliveryHeroes;

  /// No description provided for @youreNotConnectedBusinessYet.
  ///
  /// In en, this message translates to:
  /// **'You’re not\nconnected to a\nbusiness yet.'**
  String get youreNotConnectedBusinessYet;

  /// No description provided for @joinBusinessStartDelivering.
  ///
  /// In en, this message translates to:
  /// **'Join a business to start\ndelivering with '**
  String get joinBusinessStartDelivering;

  /// No description provided for @gotInvitation.
  ///
  /// In en, this message translates to:
  /// **'Got an invitation?'**
  String get gotInvitation;

  /// No description provided for @joinBusinessInviteLinkFromEmployer.
  ///
  /// In en, this message translates to:
  /// **'Join your business with an invite link from your employer.'**
  String get joinBusinessInviteLinkFromEmployer;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @useQrCodeFromBusinessJoin.
  ///
  /// In en, this message translates to:
  /// **'Use a QR code from your business to join.'**
  String get useQrCodeFromBusinessJoin;

  /// No description provided for @contactBusinessOwnerInvitation.
  ///
  /// In en, this message translates to:
  /// **'Contact your business owner for an invitation.'**
  String get contactBusinessOwnerInvitation;

  /// No description provided for @enterInvitationLinkCodeProvidedBy.
  ///
  /// In en, this message translates to:
  /// **'Enter the invitation link or code provided\nby your business.'**
  String get enterInvitationLinkCodeProvidedBy;

  /// No description provided for @inviteLink.
  ///
  /// In en, this message translates to:
  /// **'Invite Link'**
  String get inviteLink;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @invitationLink.
  ///
  /// In en, this message translates to:
  /// **'Invitation Link'**
  String get invitationLink;

  /// No description provided for @dontHaveLinkCodeRequestInvitation.
  ///
  /// In en, this message translates to:
  /// **'Don’t have a link or code?\nRequest an invitation from your business owner or administrator.'**
  String get dontHaveLinkCodeRequestInvitation;

  /// No description provided for @youveJoined.
  ///
  /// In en, this message translates to:
  /// **'You’ve Joined!'**
  String get youveJoined;

  /// No description provided for @nowPart.
  ///
  /// In en, this message translates to:
  /// **'You are now part of'**
  String get nowPart;

  /// No description provided for @accountConnected.
  ///
  /// In en, this message translates to:
  /// **'Account connected'**
  String get accountConnected;

  /// No description provided for @accountLinkedBusiness.
  ///
  /// In en, this message translates to:
  /// **'Your account is linked to the business.'**
  String get accountLinkedBusiness;

  /// No description provided for @businessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business details'**
  String get businessDetails;

  /// No description provided for @youreAllSet.
  ///
  /// In en, this message translates to:
  /// **'You’re all set'**
  String get youreAllSet;

  /// No description provided for @canNowStartReceivingDeliveriesOnce.
  ///
  /// In en, this message translates to:
  /// **'You can now start receiving deliveries once assigned by your business.'**
  String get canNowStartReceivingDeliveriesOnce;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goHome;

  /// No description provided for @goodMorning2.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorning2;

  /// No description provided for @letsGetToday.
  ///
  /// In en, this message translates to:
  /// **'Let’s get to it today.'**
  String get letsGetToday;

  /// No description provided for @todaysOverview.
  ///
  /// In en, this message translates to:
  /// **'Today’s Overview'**
  String get todaysOverview;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issues;

  /// No description provided for @currentRun.
  ///
  /// In en, this message translates to:
  /// **'Current Run'**
  String get currentRun;

  /// No description provided for @noRunAssignedYetWhenBusiness.
  ///
  /// In en, this message translates to:
  /// **'No run assigned yet. When your business dispatches a run to you, it appears here.'**
  String get noRunAssignedYetWhenBusiness;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'{orderCount} orders  •  {distanceText}'**
  String orders(Object orderCount, Object distanceText);

  /// No description provided for @started2.
  ///
  /// In en, this message translates to:
  /// **'Started {startedAtLabel}'**
  String started2(Object startedAtLabel);

  /// No description provided for @viewRunDetails.
  ///
  /// In en, this message translates to:
  /// **'View Run Details'**
  String get viewRunDetails;

  /// No description provided for @orders2.
  ///
  /// In en, this message translates to:
  /// **'{orderCount} orders'**
  String orders2(Object orderCount);

  /// No description provided for @pickUpFromStore.
  ///
  /// In en, this message translates to:
  /// **'Pick up from store'**
  String get pickUpFromStore;

  /// No description provided for @deliverOrders.
  ///
  /// In en, this message translates to:
  /// **'Deliver {orderCount} orders'**
  String deliverOrders(Object orderCount);

  /// No description provided for @multipleLocations.
  ///
  /// In en, this message translates to:
  /// **'Multiple locations'**
  String get multipleLocations;

  /// No description provided for @completeRun.
  ///
  /// In en, this message translates to:
  /// **'Complete run'**
  String get completeRun;

  /// No description provided for @markAllOrdersDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark all orders as delivered'**
  String get markAllOrdersDelivered;

  /// No description provided for @acceptRun.
  ///
  /// In en, this message translates to:
  /// **'Accept Run'**
  String get acceptRun;

  /// No description provided for @confirmPickup.
  ///
  /// In en, this message translates to:
  /// **'Confirm Pickup'**
  String get confirmPickup;

  /// No description provided for @viewOrders.
  ///
  /// In en, this message translates to:
  /// **'View Orders'**
  String get viewOrders;

  /// No description provided for @orders3.
  ///
  /// In en, this message translates to:
  /// **'{reference}  •  {orderCount} orders'**
  String orders3(Object reference, Object orderCount);

  /// No description provided for @noStopsView.
  ///
  /// In en, this message translates to:
  /// **'No stops in this view.'**
  String get noStopsView;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @mapShowsCurrentStopOrder.
  ///
  /// In en, this message translates to:
  /// **'This map shows your current stop order.'**
  String get mapShowsCurrentStopOrder;

  /// No description provided for @dragDropReorderStops.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop to reorder your stops.'**
  String get dragDropReorderStops;

  /// No description provided for @switchListViewDragReorder.
  ///
  /// In en, this message translates to:
  /// **'Switch to List view to drag and reorder.'**
  String get switchListViewDragReorder;

  /// No description provided for @willUpdateRouteAvailableBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'This will update your route. Available before you start.'**
  String get willUpdateRouteAvailableBeforeStart;

  /// No description provided for @slideConfirmRoute.
  ///
  /// In en, this message translates to:
  /// **'Slide to Confirm Route'**
  String get slideConfirmRoute;

  /// No description provided for @setapak.
  ///
  /// In en, this message translates to:
  /// **'Setapak'**
  String get setapak;

  /// No description provided for @tamanSetapak.
  ///
  /// In en, this message translates to:
  /// **'Taman\nSetapak'**
  String get tamanSetapak;

  /// No description provided for @danauKota.
  ///
  /// In en, this message translates to:
  /// **'Danau Kota'**
  String get danauKota;

  /// No description provided for @pending2.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending2;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'{etaMinutes} min'**
  String min(Object etaMinutes);

  /// No description provided for @slideArrive.
  ///
  /// In en, this message translates to:
  /// **'Slide to Arrive'**
  String get slideArrive;

  /// No description provided for @calling.
  ///
  /// In en, this message translates to:
  /// **'Calling {customerName}…'**
  String calling(Object customerName);

  /// No description provided for @phoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'No phone number available'**
  String get phoneNotAvailable;

  /// No description provided for @openingChat.
  ///
  /// In en, this message translates to:
  /// **'Opening chat…'**
  String get openingChat;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @noItemisedOrderLinesStop.
  ///
  /// In en, this message translates to:
  /// **'No itemised order lines for this stop.'**
  String get noItemisedOrderLinesStop;

  /// No description provided for @proofDelivery.
  ///
  /// In en, this message translates to:
  /// **'Proof of Delivery'**
  String get proofDelivery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @photoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get photoAdded;

  /// No description provided for @unableDeliverReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Unable to deliver? Report an issue'**
  String get unableDeliverReportIssue;

  /// No description provided for @slideComplete.
  ///
  /// In en, this message translates to:
  /// **'Slide to Complete'**
  String get slideComplete;

  /// No description provided for @takeProofDeliveryPhotoFirst.
  ///
  /// In en, this message translates to:
  /// **'Take a proof-of-delivery photo first.'**
  String get takeProofDeliveryPhotoFirst;

  /// No description provided for @confirmingDelivery.
  ///
  /// In en, this message translates to:
  /// **'Confirming delivery…'**
  String get confirmingDelivery;

  /// No description provided for @pleaseWaitMoment.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment.'**
  String get pleaseWaitMoment;

  /// No description provided for @deliveryConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Delivery confirmed'**
  String get deliveryConfirmed;

  /// No description provided for @hasBeenMarkedDelivered.
  ///
  /// In en, this message translates to:
  /// **'{reference} has been marked as delivered.'**
  String hasBeenMarkedDelivered(Object reference);

  /// No description provided for @unableCompleteDelivery.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete delivery?'**
  String get unableCompleteDelivery;

  /// No description provided for @letUsKnowWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'Let us know what happened.'**
  String get letUsKnowWhatHappened;

  /// No description provided for @selectedIssue.
  ///
  /// In en, this message translates to:
  /// **'Selected Issue'**
  String get selectedIssue;

  /// No description provided for @notesRequired.
  ///
  /// In en, this message translates to:
  /// **'Notes (Required)'**
  String get notesRequired;

  /// No description provided for @addMoreDetailsAboutWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'Add more details about what happened…'**
  String get addMoreDetailsAboutWhatHappened;

  /// No description provided for @addPhotosOptional.
  ///
  /// In en, this message translates to:
  /// **'Add Photos (Optional)'**
  String get addPhotosOptional;

  /// No description provided for @tapReplaceAttachedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to replace the attached photo.'**
  String get tapReplaceAttachedPhoto;

  /// No description provided for @takePhotoChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose from gallery'**
  String get takePhotoChooseFromGallery;

  /// No description provided for @reportWillSentBusinessTeamReview.
  ///
  /// In en, this message translates to:
  /// **'Your report will be sent to the business team for review. We’ll keep you updated.'**
  String get reportWillSentBusinessTeamReview;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @businessTeamWillReviewReport.
  ///
  /// In en, this message translates to:
  /// **'The business team will review your report.'**
  String get businessTeamWillReviewReport;

  /// No description provided for @runCompleted2.
  ///
  /// In en, this message translates to:
  /// **'Run Completed!'**
  String get runCompleted2;

  /// No description provided for @greatJobYouveCompletedAllStops.
  ///
  /// In en, this message translates to:
  /// **'Great job! You’ve completed\nall stops in this run.'**
  String get greatJobYouveCompletedAllStops;

  /// No description provided for @completed2.
  ///
  /// In en, this message translates to:
  /// **'{deliveredCount} / {orderCount} completed'**
  String completed2(Object deliveredCount, Object orderCount);

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @allDeliveryDetailsHaveBeenUpdated.
  ///
  /// In en, this message translates to:
  /// **'All delivery details have been updated. You can view the run in your history.'**
  String get allDeliveryDetailsHaveBeenUpdated;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @v120Driver.
  ///
  /// In en, this message translates to:
  /// **'v1.2.0 (Driver)'**
  String get v120Driver;

  /// No description provided for @logOut2.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOut2;

  /// No description provided for @youllNeedSignAgainContinueDelivering.
  ///
  /// In en, this message translates to:
  /// **'You’ll need to sign in again to\ncontinue delivering.'**
  String get youllNeedSignAgainContinueDelivering;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @photoUploadNotWiredUpPreview.
  ///
  /// In en, this message translates to:
  /// **'Photo upload is not wired up in this preview.'**
  String get photoUploadNotWiredUpPreview;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @registrationPlateNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration / Plate Number'**
  String get registrationPlateNumber;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get review;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @documentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Document submitted'**
  String get documentSubmitted;

  /// No description provided for @hasBeenSentVerification.
  ///
  /// In en, this message translates to:
  /// **'{title} has been sent for verification.'**
  String hasBeenSentVerification(Object title);

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @lightModeOnlyRelease.
  ///
  /// In en, this message translates to:
  /// **'Light Mode only in this release.'**
  String get lightModeOnlyRelease;

  /// No description provided for @securitySettingsNotWiredUpPreview.
  ///
  /// In en, this message translates to:
  /// **'Security settings are not wired up in this preview.'**
  String get securitySettingsNotWiredUpPreview;

  /// No description provided for @term.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get term;

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get howCanWeHelp;

  /// No description provided for @commonDriverTopics.
  ///
  /// In en, this message translates to:
  /// **'Common Driver Topics'**
  String get commonDriverTopics;

  /// No description provided for @noTopicsMatch.
  ///
  /// In en, this message translates to:
  /// **'No topics match “{trim}”.'**
  String noTopicsMatch(Object trim);

  /// No description provided for @needMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Need more help?'**
  String get needMoreHelp;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @submitSupportTicket.
  ///
  /// In en, this message translates to:
  /// **'Submit a support ticket'**
  String get submitSupportTicket;

  /// No description provided for @mySupportTickets.
  ///
  /// In en, this message translates to:
  /// **'My Support Tickets'**
  String get mySupportTickets;

  /// No description provided for @checkTicketStatus.
  ///
  /// In en, this message translates to:
  /// **'Check your ticket status'**
  String get checkTicketStatus;

  /// No description provided for @haveNoSupportTicketsYetSubmit.
  ///
  /// In en, this message translates to:
  /// **'You have no support tickets yet. Submit one from Contact Support and it will appear here.'**
  String get haveNoSupportTicketsYetSubmit;

  /// No description provided for @whatDoNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'What do you need help with?'**
  String get whatDoNeedHelp;

  /// No description provided for @contactBusiness.
  ///
  /// In en, this message translates to:
  /// **'Contact Business'**
  String get contactBusiness;

  /// No description provided for @issueRelatedVendorsBusinessOperationsE.
  ///
  /// In en, this message translates to:
  /// **'This issue is related to the vendor’s business operations (e.g. orders, assignments, customer, delivery instructions).'**
  String get issueRelatedVendorsBusinessOperationsE;

  /// No description provided for @pleaseContactBusinessDirectlyFasterAssistance.
  ///
  /// In en, this message translates to:
  /// **'Please contact the business directly for faster assistance.'**
  String get pleaseContactBusinessDirectlyFasterAssistance;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @calling2.
  ///
  /// In en, this message translates to:
  /// **'Calling {vendor}…'**
  String calling2(Object vendor);

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @appMessageVendor.
  ///
  /// In en, this message translates to:
  /// **'In-app message to vendor'**
  String get appMessageVendor;

  /// No description provided for @openingVendorChat.
  ///
  /// In en, this message translates to:
  /// **'Opening vendor chat…'**
  String get openingVendorChat;

  /// No description provided for @ceffloDoesNotManageVendorOperations.
  ///
  /// In en, this message translates to:
  /// **'Cefflo does not manage vendor operations. For app or account issues, please go back and select the relevant category.'**
  String get ceffloDoesNotManageVendorOperations;

  /// No description provided for @backHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Back to Help & Support'**
  String get backHelpSupport;

  /// No description provided for @ceffloSupport.
  ///
  /// In en, this message translates to:
  /// **'Cefflo Support'**
  String get ceffloSupport;

  /// No description provided for @tellUsAboutIssueWellGet.
  ///
  /// In en, this message translates to:
  /// **'Tell us about the issue and we’ll get back to you as soon as possible.'**
  String get tellUsAboutIssueWellGet;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue'**
  String get describeIssue;

  /// No description provided for @pleaseProvideMuchDetailPossibleE.
  ///
  /// In en, this message translates to:
  /// **'Please provide as much detail as possible…\n(e.g. what happened, when, steps to reproduce)'**
  String get pleaseProvideMuchDetailPossibleE;

  /// No description provided for @addScreenshotPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Add screenshot or photo (optional)'**
  String get addScreenshotPhotoOptional;

  /// No description provided for @photoAttached.
  ///
  /// In en, this message translates to:
  /// **'Photo attached'**
  String get photoAttached;

  /// No description provided for @tapAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get tapAddPhoto;

  /// No description provided for @pngJpgMax5mbEach.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG (Max 5MB each)'**
  String get pngJpgMax5mbEach;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get requestSubmitted;

  /// No description provided for @wellGetBackSoon.
  ///
  /// In en, this message translates to:
  /// **'We’ll get back to you soon.'**
  String get wellGetBackSoon;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @runs.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get runs;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @slideConfirm.
  ///
  /// In en, this message translates to:
  /// **'Slide to confirm'**
  String get slideConfirm;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @orSeparator.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orSeparator;

  /// No description provided for @pasteFullInvitationLink.
  ///
  /// In en, this message translates to:
  /// **'Paste the full invitation link you received.'**
  String get pasteFullInvitationLink;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// No description provided for @van.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get van;

  /// No description provided for @detailsManagedByBusiness.
  ///
  /// In en, this message translates to:
  /// **'Your details are managed by your business. Ask them to update anything that has changed.'**
  String get detailsManagedByBusiness;

  /// No description provided for @supportTicketsNotConnectedYet.
  ///
  /// In en, this message translates to:
  /// **'Support tickets are not connected yet. Contact your business directly for help.'**
  String get supportTicketsNotConnectedYet;

  /// No description provided for @runsDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Runs & Deliveries'**
  String get runsDeliveries;

  /// No description provided for @ordersNavigationDeliveryProcess.
  ///
  /// In en, this message translates to:
  /// **'Orders, navigation, delivery process'**
  String get ordersNavigationDeliveryProcess;

  /// No description provided for @deliveryIssues.
  ///
  /// In en, this message translates to:
  /// **'Delivery Issues'**
  String get deliveryIssues;

  /// No description provided for @failedDeliveryCustomerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Failed delivery, customer not available'**
  String get failedDeliveryCustomerNotAvailable;

  /// No description provided for @vehicleDocuments2.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & Documents'**
  String get vehicleDocuments2;

  /// No description provided for @licenceRegistrationDocumentVerification.
  ///
  /// In en, this message translates to:
  /// **'Licence, registration, document verification'**
  String get licenceRegistrationDocumentVerification;

  /// No description provided for @accountProfile.
  ///
  /// In en, this message translates to:
  /// **'Account & Profile'**
  String get accountProfile;

  /// No description provided for @profileSettingsAppAccess.
  ///
  /// In en, this message translates to:
  /// **'Profile, settings, app access'**
  String get profileSettingsAppAccess;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// No description provided for @ntNewRun.
  ///
  /// In en, this message translates to:
  /// **'New run'**
  String get ntNewRun;

  /// No description provided for @ntNewRunFrom.
  ///
  /// In en, this message translates to:
  /// **'New run from {business}'**
  String ntNewRunFrom(Object business);

  /// No description provided for @ntRunOrdersAssigned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order assigned to you. Open it to accept.} other{{count} orders assigned to you. Open it to accept.}}'**
  String ntRunOrdersAssigned(int count);

  /// No description provided for @ntRunReassigned.
  ///
  /// In en, this message translates to:
  /// **'Run reassigned to you'**
  String get ntRunReassigned;

  /// No description provided for @ntRunReassignedBody.
  ///
  /// In en, this message translates to:
  /// **'Your business moved a run to you. Open it to accept.'**
  String get ntRunReassignedBody;

  /// No description provided for @ntRunRemoved.
  ///
  /// In en, this message translates to:
  /// **'Run moved to another driver'**
  String get ntRunRemoved;

  /// No description provided for @ntRunRemovedBody.
  ///
  /// In en, this message translates to:
  /// **'Your business reassigned a run you were on.'**
  String get ntRunRemovedBody;

  /// No description provided for @ntApproved.
  ///
  /// In en, this message translates to:
  /// **'You are approved'**
  String get ntApproved;

  /// No description provided for @ntApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'The business approved you as a driver.'**
  String get ntApprovedBody;

  /// No description provided for @ntAccessChanged.
  ///
  /// In en, this message translates to:
  /// **'Access changed'**
  String get ntAccessChanged;

  /// No description provided for @ntAccessChangedBody.
  ///
  /// In en, this message translates to:
  /// **'A business deactivated you as a driver.'**
  String get ntAccessChangedBody;

  /// No description provided for @ntJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get ntJustNow;

  /// No description provided for @ntMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String ntMinutesAgo(Object n);

  /// No description provided for @ntHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String ntHoursAgo(Object n);

  /// No description provided for @ntSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get ntSettings;

  /// No description provided for @ntPrefLead.
  ///
  /// In en, this message translates to:
  /// **'Applies to your account on every Cefflo app.'**
  String get ntPrefLead;

  /// No description provided for @ntPrefEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get ntPrefEnabled;

  /// No description provided for @ntPrefEnabledSub.
  ///
  /// In en, this message translates to:
  /// **'Show alerts while the app is open. Everything is still kept here.'**
  String get ntPrefEnabledSub;

  /// No description provided for @ntPrefSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get ntPrefSound;

  /// No description provided for @ntPrefSoundSub.
  ///
  /// In en, this message translates to:
  /// **'Play a sound with an alert.'**
  String get ntPrefSoundSub;

  /// No description provided for @ntPushDeferred.
  ///
  /// In en, this message translates to:
  /// **'Alerts when the app is closed are not available yet.'**
  String get ntPushDeferred;

  /// No description provided for @ntCouldNotUpdate.
  ///
  /// In en, this message translates to:
  /// **'Could not update notifications. Try again.'**
  String get ntCouldNotUpdate;

  /// No description provided for @ntUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get ntUrgent;

  /// No description provided for @ntDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get ntDismiss;

  /// No description provided for @ntMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get ntMarkAllRead;

  /// No description provided for @ntMarkUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get ntMarkUnread;

  /// No description provided for @ntMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get ntMarkRead;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyYourEmail;

  /// No description provided for @weSentVerificationLinkTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to'**
  String get weSentVerificationLinkTo;

  /// No description provided for @openLinkOnThisPhone.
  ///
  /// In en, this message translates to:
  /// **'Open the link on this phone to activate your account, then you\'re signed in.'**
  String get openLinkOnThisPhone;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendEmail;

  /// No description provided for @resendEmailIn.
  ///
  /// In en, this message translates to:
  /// **'Resend email ({seconds}s)'**
  String resendEmailIn(int seconds);

  /// No description provided for @emailSentCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'Email sent. Check your inbox and spam folder.'**
  String get emailSentCheckInbox;

  /// No description provided for @linkNoLongerValid.
  ///
  /// In en, this message translates to:
  /// **'This link is no longer valid'**
  String get linkNoLongerValid;

  /// No description provided for @linkExpiredOrUsedRequestNew.
  ///
  /// In en, this message translates to:
  /// **'It has expired or was already used. Request a new one below.'**
  String get linkExpiredOrUsedRequestNew;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationEmail;

  /// No description provided for @sendNewResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send a new reset link'**
  String get sendNewResetLink;

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useDifferentEmail;

  /// No description provided for @otpLead.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to'**
  String get otpLead;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// No description provided for @otpVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get otpVerifying;

  /// No description provided for @otpNoCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the code?'**
  String get otpNoCode;

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String otpResendIn(int seconds);

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way to {email}.'**
  String otpResent(String email);

  /// No description provided for @otpIncorrect.
  ///
  /// In en, this message translates to:
  /// **'That code is incorrect or has expired. Check the digits or request a new code.'**
  String get otpIncorrect;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Request a new code to continue.'**
  String get otpExpired;

  /// No description provided for @otpSendNew.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get otpSendNew;

  /// No description provided for @otpVerifiedLead.
  ///
  /// In en, this message translates to:
  /// **'Your email is confirmed. You can continue.'**
  String get otpVerifiedLead;

  /// No description provided for @otpContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get otpContinue;

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit verification code'**
  String get otpCodeLabel;

  /// No description provided for @otpEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get otpEmailVerified;

  /// No description provided for @otpRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get otpRecoveryTitle;

  /// No description provided for @enterNamePhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name and phone number.'**
  String get enterNamePhone;

  /// No description provided for @alreadyPartOf.
  ///
  /// In en, this message translates to:
  /// **'You\'re already part of {business}.'**
  String alreadyPartOf(Object business);

  /// No description provided for @joinRequestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {business}. You\'ll get access once it\'s approved.'**
  String joinRequestSentTo(Object business);

  /// No description provided for @joiningBusiness.
  ///
  /// In en, this message translates to:
  /// **'Joining {business}'**
  String joiningBusiness(Object business);

  /// No description provided for @continueText3.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText3;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailAlreadyRegistered;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @chooseYourVehicle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Vehicle'**
  String get chooseYourVehicle;

  /// No description provided for @selectVehicleUseDelivery.
  ///
  /// In en, this message translates to:
  /// **'Select the vehicle you will use for delivery.'**
  String get selectVehicleUseDelivery;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @vehicleMotorbike.
  ///
  /// In en, this message translates to:
  /// **'Motorbike'**
  String get vehicleMotorbike;

  /// No description provided for @vehicleCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get vehicleCar;

  /// No description provided for @vehicleVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get vehicleVan;

  /// No description provided for @vehicleMotorbikeSub.
  ///
  /// In en, this message translates to:
  /// **'Best for short distance and fast delivery.'**
  String get vehicleMotorbikeSub;

  /// No description provided for @vehicleCarSub.
  ///
  /// In en, this message translates to:
  /// **'More space for larger orders.'**
  String get vehicleCarSub;

  /// No description provided for @vehicleVanSub.
  ///
  /// In en, this message translates to:
  /// **'Ideal for bulk orders and business delivery.'**
  String get vehicleVanSub;

  /// No description provided for @yourDriverDetails.
  ///
  /// In en, this message translates to:
  /// **'Your Driver Details'**
  String get yourDriverDetails;

  /// No description provided for @infoSharedDeliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'This information will be shared with your delivery partner.'**
  String get infoSharedDeliveryPartner;

  /// No description provided for @selectedVehicle.
  ///
  /// In en, this message translates to:
  /// **'Selected Vehicle'**
  String get selectedVehicle;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'{step} / {total}'**
  String stepOf(int step, int total);

  /// No description provided for @enterNamePhonePlate.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name, phone number and vehicle number plate.'**
  String get enterNamePhonePlate;

  /// No description provided for @keepLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep me logged in'**
  String get keepLoggedIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @findJobs.
  ///
  /// In en, this message translates to:
  /// **'Find Jobs'**
  String get findJobs;

  /// No description provided for @findJobsSub.
  ///
  /// In en, this message translates to:
  /// **'Vendors near you that are looking for drivers'**
  String get findJobsSub;

  /// No description provided for @changeArea.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeArea;

  /// No description provided for @shiftAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get shiftAll;

  /// No description provided for @shiftMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get shiftMorning;

  /// No description provided for @shiftNoon.
  ///
  /// In en, this message translates to:
  /// **'Noon'**
  String get shiftNoon;

  /// No description provided for @shiftNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get shiftNight;

  /// No description provided for @myWeek.
  ///
  /// In en, this message translates to:
  /// **'My week'**
  String get myWeek;

  /// No description provided for @openSchedule.
  ///
  /// In en, this message translates to:
  /// **'Open schedule'**
  String get openSchedule;

  /// No description provided for @openingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} openings'**
  String openingsCount(int count);

  /// No description provided for @noOpeningsShift.
  ///
  /// In en, this message translates to:
  /// **'No openings for this shift yet.'**
  String get noOpeningsShift;

  /// No description provided for @jobNeeded.
  ///
  /// In en, this message translates to:
  /// **'{count} needed'**
  String jobNeeded(int count);

  /// No description provided for @jobClash.
  ///
  /// In en, this message translates to:
  /// **'Clash'**
  String get jobClash;

  /// No description provided for @jobRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get jobRequested;

  /// No description provided for @findJobsComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Jobs is coming soon'**
  String get findJobsComingSoonTitle;

  /// No description provided for @findJobsComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Soon you can see vendors in your area that are looking for drivers, and send a request to join them. Your current business is not affected.'**
  String get findJobsComingSoonBody;

  /// No description provided for @jobShift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get jobShift;

  /// No description provided for @jobRequirements.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get jobRequirements;

  /// No description provided for @jobTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get jobTime;

  /// No description provided for @jobDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get jobDays;

  /// No description provided for @jobPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get jobPay;

  /// No description provided for @jobPayPerDrop.
  ///
  /// In en, this message translates to:
  /// **'Pay per drop'**
  String get jobPayPerDrop;

  /// No description provided for @jobPickupTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup time'**
  String get jobPickupTime;

  /// No description provided for @jobPickupAt.
  ///
  /// In en, this message translates to:
  /// **'Pickup {time}'**
  String jobPickupAt(String time);

  /// No description provided for @jobAbout.
  ///
  /// In en, this message translates to:
  /// **'About this hiring'**
  String get jobAbout;

  /// No description provided for @jobApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get jobApply;

  /// No description provided for @jobApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get jobApplied;

  /// No description provided for @jobRidersNeeded.
  ///
  /// In en, this message translates to:
  /// **'Drivers needed'**
  String get jobRidersNeeded;

  /// No description provided for @jobVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get jobVehicle;

  /// No description provided for @requestToJoin.
  ///
  /// In en, this message translates to:
  /// **'Request to join'**
  String get requestToJoin;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestSent;

  /// No description provided for @nextOpening.
  ///
  /// In en, this message translates to:
  /// **'Next opening'**
  String get nextOpening;

  /// No description provided for @jobOwnerReviews.
  ///
  /// In en, this message translates to:
  /// **'The owner reviews your request. Nothing is booked until they approve.'**
  String get jobOwnerReviews;

  /// No description provided for @jobWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the owner to approve. You will get a notification.'**
  String get jobWaitingApproval;

  /// No description provided for @mySchedule.
  ///
  /// In en, this message translates to:
  /// **'My Schedule'**
  String get mySchedule;

  /// No description provided for @scheduleWeekSub.
  ///
  /// In en, this message translates to:
  /// **'6 – 12 Oct · 3 vendors approved'**
  String get scheduleWeekSub;

  /// No description provided for @slotBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get slotBooked;

  /// No description provided for @slotRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get slotRequested;

  /// No description provided for @slotTravelBuffer.
  ///
  /// In en, this message translates to:
  /// **'Travel buffer'**
  String get slotTravelBuffer;

  /// No description provided for @scheduleNote.
  ///
  /// In en, this message translates to:
  /// **'You can work for the same vendor in more than one slot, or for different vendors, as long as the times don\'t overlap.'**
  String get scheduleNote;

  /// No description provided for @releaseSlot.
  ///
  /// In en, this message translates to:
  /// **'Release a slot'**
  String get releaseSlot;

  /// No description provided for @previewOnly.
  ///
  /// In en, this message translates to:
  /// **'Preview: example openings'**
  String get previewOnly;

  /// No description provided for @perShift.
  ///
  /// In en, this message translates to:
  /// **'/ shift'**
  String get perShift;

  /// No description provided for @perDrop.
  ///
  /// In en, this message translates to:
  /// **'/ drop'**
  String get perDrop;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'/ hour'**
  String get perHour;

  /// No description provided for @jobWithin.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km'**
  String jobWithin(String km);

  /// No description provided for @jobAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String jobAway(String km);

  /// No description provided for @jobsNearestFirst.
  ///
  /// In en, this message translates to:
  /// **'Nearest first · all of Malaysia'**
  String get jobsNearestFirst;

  /// No description provided for @jobsAllAreas.
  ///
  /// In en, this message translates to:
  /// **'All areas · turn on location for distance'**
  String get jobsAllAreas;

  /// No description provided for @jobDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get jobDaily;

  /// No description provided for @scheduleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bookings'**
  String scheduleCount(int count);

  /// No description provided for @withdrawBooking.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawBooking;

  /// No description provided for @bookingWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Booking withdrawn'**
  String get bookingWithdrawn;

  /// No description provided for @noBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet. Request an opening in Find Jobs.'**
  String get noBookingsYet;

  /// No description provided for @jobsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load openings. Pull to try again.'**
  String get jobsLoadFailed;

  /// No description provided for @retry2.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry2;

  /// No description provided for @jobRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get jobRadius;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get changeLocation;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @searchTown.
  ///
  /// In en, this message translates to:
  /// **'Search a town'**
  String get searchTown;

  /// No description provided for @withinKm.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km'**
  String withinKm(String km);

  /// No description provided for @noJobsWithin.
  ///
  /// In en, this message translates to:
  /// **'No jobs within {km} km of {place}.'**
  String noJobsWithin(String km, String place);

  /// No description provided for @expandTo50.
  ///
  /// In en, this message translates to:
  /// **'Expand to 50 km'**
  String get expandTo50;

  /// No description provided for @tryAnotherLocation.
  ///
  /// In en, this message translates to:
  /// **'Try another location.'**
  String get tryAnotherLocation;

  /// No description provided for @needLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to work?'**
  String get needLocationTitle;

  /// No description provided for @needLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to see jobs near you, or choose a town.'**
  String get needLocationBody;

  /// No description provided for @chooseTown.
  ///
  /// In en, this message translates to:
  /// **'Choose a town'**
  String get chooseTown;

  /// No description provided for @locationOffNote.
  ///
  /// In en, this message translates to:
  /// **'Location is off. Showing the town you chose.'**
  String get locationOffNote;

  /// No description provided for @differentVehicle.
  ///
  /// In en, this message translates to:
  /// **'Different vehicle'**
  String get differentVehicle;

  /// No description provided for @documentsNotYet.
  ///
  /// In en, this message translates to:
  /// **'Document uploads are not available yet. The business checks your licence and vehicle documents directly for now.'**
  String get documentsNotYet;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordChanged;

  /// No description provided for @detailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Details saved'**
  String get detailsSaved;

  /// No description provided for @changeFee.
  ///
  /// In en, this message translates to:
  /// **'Change fee'**
  String get changeFee;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @changeAfterPayment.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle details change only after the payment is confirmed. Each vehicle or plate change costs RM50.'**
  String get changeAfterPayment;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmount(String amount);

  /// No description provided for @paymentsNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment not available yet'**
  String get paymentsNotConnectedTitle;

  /// No description provided for @paymentsNotConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Online payment is not connected yet, so nothing was charged and your vehicle details are unchanged.'**
  String get paymentsNotConnectedBody;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Nothing was changed.'**
  String get paymentFailed;

  /// No description provided for @vehicleChangePaid.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed. Vehicle details updated.'**
  String get vehicleChangePaid;

  /// No description provided for @okGotIt.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okGotIt;

  /// No description provided for @vehicleChangePaidNote.
  ///
  /// In en, this message translates to:
  /// **'A vehicle or plate change costs RM50.'**
  String get vehicleChangePaidNote;

  /// No description provided for @payGroupBanking.
  ///
  /// In en, this message translates to:
  /// **'Online banking'**
  String get payGroupBanking;

  /// No description provided for @payFpx.
  ///
  /// In en, this message translates to:
  /// **'Online banking (FPX)'**
  String get payFpx;

  /// No description provided for @payFpxSub.
  ///
  /// In en, this message translates to:
  /// **'Maybank2u, CIMB Clicks, Public Bank, RHB and other Malaysian banks'**
  String get payFpxSub;

  /// No description provided for @payGroupWallet.
  ///
  /// In en, this message translates to:
  /// **'E-wallet'**
  String get payGroupWallet;

  /// No description provided for @payGroupLater.
  ///
  /// In en, this message translates to:
  /// **'Pay later'**
  String get payGroupLater;

  /// No description provided for @payAtomeSub.
  ///
  /// In en, this message translates to:
  /// **'Split into 3 instalments'**
  String get payAtomeSub;

  /// No description provided for @payGroupCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payGroupCard;

  /// No description provided for @payCardMy.
  ///
  /// In en, this message translates to:
  /// **'Debit / credit card'**
  String get payCardMy;

  /// No description provided for @payCardIntl.
  ///
  /// In en, this message translates to:
  /// **'International card'**
  String get payCardIntl;

  /// No description provided for @licenceRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get licenceRejected;

  /// No description provided for @drivingLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get drivingLicence;

  /// No description provided for @licenceNeeded.
  ///
  /// In en, this message translates to:
  /// **'Needed for Find Jobs'**
  String get licenceNeeded;

  /// No description provided for @icEnding.
  ///
  /// In en, this message translates to:
  /// **'IC ending {last4}'**
  String icEnding(String last4);

  /// No description provided for @licencePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only Cefflo uses these to check Find Jobs drivers; businesses never see your IC, licence or photos. Your IC number stays hidden (last 4 digits only). Not needed for deliveries from businesses that invited you.'**
  String get licencePrivacy;

  /// No description provided for @licenceSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Licence sent for review'**
  String get licenceSubmitted;

  /// No description provided for @icInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your 12-digit MyKad IC number.'**
  String get icInvalid;

  /// No description provided for @licencePhotoNeeded.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of your driving licence.'**
  String get licencePhotoNeeded;

  /// No description provided for @icAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This IC number is already registered to another Cefflo account. Sign in with that account instead.'**
  String get icAlreadyRegistered;

  /// No description provided for @icNumber.
  ///
  /// In en, this message translates to:
  /// **'MyKad IC number'**
  String get icNumber;

  /// No description provided for @licencePhoto.
  ///
  /// In en, this message translates to:
  /// **'Driving licence photo'**
  String get licencePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get chooseFromGallery;

  /// No description provided for @licencePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'One photo of your Malaysian driving licence, sharp and readable. Only Malaysian licences are accepted for now.'**
  String get licencePhotoHint;

  /// No description provided for @mvTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketplace verification'**
  String get mvTitle;

  /// No description provided for @mvIntro.
  ///
  /// In en, this message translates to:
  /// **'To apply for jobs in Find Jobs, add your licence and your vehicle. Deliveries from businesses that invited you do not need this.'**
  String get mvIntro;

  /// No description provided for @mvChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get mvChecking;

  /// No description provided for @mvPendingBody.
  ///
  /// In en, this message translates to:
  /// **'We are checking your documents. This usually takes a moment.'**
  String get mvPendingBody;

  /// No description provided for @mvVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'You are verified for Find Jobs.'**
  String get mvVerifiedBody;

  /// No description provided for @mvReviewBody.
  ///
  /// In en, this message translates to:
  /// **'The Cefflo team is taking a closer look. We will let you know.'**
  String get mvReviewBody;

  /// No description provided for @mvRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Verification was not approved. Contact Cefflo support.'**
  String get mvRejectedBody;

  /// No description provided for @mvRetakeBody.
  ///
  /// In en, this message translates to:
  /// **'We could not read one of your photos. Please take it again.'**
  String get mvRetakeBody;

  /// No description provided for @mvRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get mvRetake;

  /// No description provided for @mvLicenceSub.
  ///
  /// In en, this message translates to:
  /// **'MyKad IC number + one licence photo'**
  String get mvLicenceSub;

  /// No description provided for @mvVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get mvVehicle;

  /// No description provided for @mvVehicleSub.
  ///
  /// In en, this message translates to:
  /// **'Type, plate and one live photo'**
  String get mvVehicleSub;

  /// No description provided for @mvPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get mvPlate;

  /// No description provided for @mvPlateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid plate number, e.g. VAB 1234.'**
  String get mvPlateInvalid;

  /// No description provided for @mvVehiclePhotoNeeded.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your vehicle.'**
  String get mvVehiclePhotoNeeded;

  /// No description provided for @mvVehiclePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your vehicle with the license plate clearly visible.'**
  String get mvVehiclePhotoHint;

  /// No description provided for @mvCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get mvCheckAgain;

  /// No description provided for @mvRequiredToApply.
  ///
  /// In en, this message translates to:
  /// **'Complete marketplace verification to apply for jobs.'**
  String get mvRequiredToApply;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
