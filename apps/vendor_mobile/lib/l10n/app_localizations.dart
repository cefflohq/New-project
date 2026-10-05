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

  /// No description provided for @paymentsNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Payments are not available yet.'**
  String get paymentsNotAvailableYet;

  /// No description provided for @splash.
  ///
  /// In en, this message translates to:
  /// **'Splash'**
  String get splash;

  /// No description provided for @sign.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @accountRecovery.
  ///
  /// In en, this message translates to:
  /// **'Account recovery'**
  String get accountRecovery;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business information'**
  String get businessInformation;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocation;

  /// No description provided for @serviceArea.
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get serviceArea;

  /// No description provided for @setupComplete.
  ///
  /// In en, this message translates to:
  /// **'Setup complete'**
  String get setupComplete;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @orderDetail.
  ///
  /// In en, this message translates to:
  /// **'Order detail'**
  String get orderDetail;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get newOrder;

  /// No description provided for @importOrders.
  ///
  /// In en, this message translates to:
  /// **'Import orders'**
  String get importOrders;

  /// No description provided for @editOrder.
  ///
  /// In en, this message translates to:
  /// **'Edit order'**
  String get editOrder;

  /// No description provided for @zones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get zones;

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @deliveryProgress.
  ///
  /// In en, this message translates to:
  /// **'Delivery progress'**
  String get deliveryProgress;

  /// No description provided for @riders.
  ///
  /// In en, this message translates to:
  /// **'Riders'**
  String get riders;

  /// No description provided for @riderDetail.
  ///
  /// In en, this message translates to:
  /// **'Rider detail'**
  String get riderDetail;

  /// No description provided for @riderRegistrationLink.
  ///
  /// In en, this message translates to:
  /// **'Rider registration link'**
  String get riderRegistrationLink;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @teamMember.
  ///
  /// In en, this message translates to:
  /// **'Team member'**
  String get teamMember;

  /// No description provided for @teamMemberRegistrationLink.
  ///
  /// In en, this message translates to:
  /// **'Team member registration link'**
  String get teamMemberRegistrationLink;

  /// No description provided for @coverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get coverage;

  /// No description provided for @zoneConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Zone configuration'**
  String get zoneConfiguration;

  /// No description provided for @createZone.
  ///
  /// In en, this message translates to:
  /// **'Create zone'**
  String get createZone;

  /// No description provided for @storefront.
  ///
  /// In en, this message translates to:
  /// **'Storefront'**
  String get storefront;

  /// No description provided for @viewStorefront.
  ///
  /// In en, this message translates to:
  /// **'View storefront'**
  String get viewStorefront;

  /// No description provided for @templatePreview.
  ///
  /// In en, this message translates to:
  /// **'Template preview'**
  String get templatePreview;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @businessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business profile'**
  String get businessProfile;

  /// No description provided for @businessAddress.
  ///
  /// In en, this message translates to:
  /// **'Business address'**
  String get businessAddress;

  /// No description provided for @businessHours.
  ///
  /// In en, this message translates to:
  /// **'Business hours'**
  String get businessHours;

  /// No description provided for @deliverySettings.
  ///
  /// In en, this message translates to:
  /// **'Delivery settings'**
  String get deliverySettings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferences;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get choosePlan;

  /// No description provided for @reviewPayment.
  ///
  /// In en, this message translates to:
  /// **'Review & Payment'**
  String get reviewPayment;

  /// No description provided for @billingHistory.
  ///
  /// In en, this message translates to:
  /// **'Billing History'**
  String get billingHistory;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupport;

  /// No description provided for @helpCentre.
  ///
  /// In en, this message translates to:
  /// **'Help centre'**
  String get helpCentre;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsService;

  /// No description provided for @aboutCefflo.
  ///
  /// In en, this message translates to:
  /// **'About Cefflo'**
  String get aboutCefflo;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get pendingApproval;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get pickedUp;

  /// No description provided for @way.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get way;

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrived;

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

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @rider.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get rider;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @serviceAreaNotSet.
  ///
  /// In en, this message translates to:
  /// **'Service area not set'**
  String get serviceAreaNotSet;

  /// No description provided for @awaitingLocation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting location'**
  String get awaitingLocation;

  /// No description provided for @coverage2.
  ///
  /// In en, this message translates to:
  /// **'In coverage'**
  String get coverage2;

  /// No description provided for @outsideCoverage.
  ///
  /// In en, this message translates to:
  /// **'Outside coverage'**
  String get outsideCoverage;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @addressNotYetLocated.
  ///
  /// In en, this message translates to:
  /// **'Address not yet located'**
  String get addressNotYetLocated;

  /// No description provided for @addressAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'Address is ambiguous'**
  String get addressAmbiguous;

  /// No description provided for @addressCouldNotLocated.
  ///
  /// In en, this message translates to:
  /// **'Address could not be located'**
  String get addressCouldNotLocated;

  /// No description provided for @noRiderCompatibleVehicleEnoughSpare.
  ///
  /// In en, this message translates to:
  /// **'No rider with a compatible vehicle and enough spare capacity'**
  String get noRiderCompatibleVehicleEnoughSpare;

  /// No description provided for @dispatched.
  ///
  /// In en, this message translates to:
  /// **'Dispatched'**
  String get dispatched;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @pickingUp.
  ///
  /// In en, this message translates to:
  /// **'Picking up'**
  String get pickingUp;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @capacityExceededActiveRequestedExceeds.
  ///
  /// In en, this message translates to:
  /// **'Capacity exceeded: {current_load} active + {requested} requested exceeds {effective_capacity}.'**
  String capacityExceededActiveRequestedExceeds(
    Object current_load,
    Object requested,
    Object effective_capacity,
  );

  /// No description provided for @vehicleIncompatibleNeedsRiderHas.
  ///
  /// In en, this message translates to:
  /// **'Vehicle incompatible: needs {vehicle_requirement}, rider has {rider_vehicle_type}.'**
  String vehicleIncompatibleNeedsRiderHas(
    Object vehicle_requirement,
    Object rider_vehicle_type,
  );

  /// No description provided for @experienceCefflo.
  ///
  /// In en, this message translates to:
  /// **'Experience Cefflo.'**
  String get experienceCefflo;

  /// No description provided for @t100DeliveriesMonth.
  ///
  /// In en, this message translates to:
  /// **'100 deliveries a month'**
  String get t100DeliveriesMonth;

  /// No description provided for @up3Riders2Zones.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 riders · 2 zones'**
  String get up3Riders2Zones;

  /// No description provided for @customerTrackingProofDelivery.
  ///
  /// In en, this message translates to:
  /// **'Customer tracking and proof of delivery'**
  String get customerTrackingProofDelivery;

  /// No description provided for @businessesRunningLocalDeliveriesRegularly.
  ///
  /// In en, this message translates to:
  /// **'For businesses running local deliveries regularly.'**
  String get businessesRunningLocalDeliveriesRegularly;

  /// No description provided for @t500DeliveriesMonth.
  ///
  /// In en, this message translates to:
  /// **'500 deliveries a month'**
  String get t500DeliveriesMonth;

  /// No description provided for @up10Riders5Zones.
  ///
  /// In en, this message translates to:
  /// **'Up to 10 riders · 5 zones'**
  String get up10Riders5Zones;

  /// No description provided for @up3TeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 team members'**
  String get up3TeamMembers;

  /// No description provided for @standardReportingSupport.
  ///
  /// In en, this message translates to:
  /// **'Standard reporting and support'**
  String get standardReportingSupport;

  /// No description provided for @runLocalDeliveryOperationOnePlace.
  ///
  /// In en, this message translates to:
  /// **'Run your local delivery operation in one place.'**
  String get runLocalDeliveryOperationOnePlace;

  /// No description provided for @t1500DeliveriesMonth.
  ///
  /// In en, this message translates to:
  /// **'1,500 deliveries a month'**
  String get t1500DeliveriesMonth;

  /// No description provided for @unlimitedRidersZones.
  ///
  /// In en, this message translates to:
  /// **'Unlimited riders and zones'**
  String get unlimitedRidersZones;

  /// No description provided for @up10TeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Up to 10 team members'**
  String get up10TeamMembers;

  /// No description provided for @advancedOperationalReporting.
  ///
  /// In en, this message translates to:
  /// **'Advanced operational reporting'**
  String get advancedOperationalReporting;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get prioritySupport;

  /// No description provided for @highVolumeComplexOperations.
  ///
  /// In en, this message translates to:
  /// **'For high-volume, complex operations.'**
  String get highVolumeComplexOperations;

  /// No description provided for @t5000DeliveriesMonth.
  ///
  /// In en, this message translates to:
  /// **'5,000 deliveries a month'**
  String get t5000DeliveriesMonth;

  /// No description provided for @up25TeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Up to 25 team members'**
  String get up25TeamMembers;

  /// No description provided for @advancedControlsIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Advanced controls and integrations'**
  String get advancedControlsIntegrations;

  /// No description provided for @modernInter.
  ///
  /// In en, this message translates to:
  /// **'Modern (Inter)'**
  String get modernInter;

  /// No description provided for @boldInter.
  ///
  /// In en, this message translates to:
  /// **'Bold (Inter)'**
  String get boldInter;

  /// No description provided for @elegantInterItalic.
  ///
  /// In en, this message translates to:
  /// **'Elegant (Inter Italic)'**
  String get elegantInterItalic;

  /// No description provided for @classicInterCaps.
  ///
  /// In en, this message translates to:
  /// **'Classic (Inter Caps)'**
  String get classicInterCaps;

  /// No description provided for @orderWasNotCreatedBackendReturned.
  ///
  /// In en, this message translates to:
  /// **'Order was not created: backend returned no id.'**
  String get orderWasNotCreatedBackendReturned;

  /// No description provided for @removingDeliveryFromTodaysPlanNot.
  ///
  /// In en, this message translates to:
  /// **'Removing a delivery from today\'s plan is not available yet.'**
  String get removingDeliveryFromTodaysPlanNot;

  /// No description provided for @runNotFound.
  ///
  /// In en, this message translates to:
  /// **'Run not found.'**
  String get runNotFound;

  /// No description provided for @uiPrototypeModeHasNoBackend.
  ///
  /// In en, this message translates to:
  /// **'UI prototype mode has no backend connection.'**
  String get uiPrototypeModeHasNoBackend;

  /// No description provided for @actionNeedsBackendContractThatNot.
  ///
  /// In en, this message translates to:
  /// **'This action needs a backend contract that is not deployed here ({message}).'**
  String actionNeedsBackendContractThatNot(Object message);

  /// No description provided for @unexpectedBackendResponseShape.
  ///
  /// In en, this message translates to:
  /// **'Unexpected backend response shape.'**
  String get unexpectedBackendResponseShape;

  /// No description provided for @updatingPassword.
  ///
  /// In en, this message translates to:
  /// **'Updating password…'**
  String get updatingPassword;

  /// No description provided for @savingNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Saving your new password.'**
  String get savingNewPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @canNowSignNewPassword.
  ///
  /// In en, this message translates to:
  /// **'You can now sign in with your new password.'**
  String get canNowSignNewPassword;

  /// No description provided for @operateTodayGrowTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Operate Today.\nGrow Tomorrow.'**
  String get operateTodayGrowTomorrow;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

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

  /// No description provided for @unableConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect'**
  String get unableConnect;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts'**
  String get tooManyAttempts;

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
  /// **'Have an invite? '**
  String get haveInvite;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @signEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get signEmail;

  /// No description provided for @enterEmailPasswordContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to continue.'**
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

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @signing.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signing;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @createAccount2.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount2;

  /// No description provided for @startManagingDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Start managing your deliveries.'**
  String get startManagingDeliveries;

  /// No description provided for @useLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get useLeast8Characters;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmPassword2.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPassword2;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account…'**
  String get creatingAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @enterEmailWellSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a 6-digit code.'**
  String get enterEmailWellSendResetLink;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendResetLink;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @backSign.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backSign;

  /// No description provided for @checkEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmail;

  /// No description provided for @ifAccountExistsEmailYoullReceive.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, you\'ll receive a password reset link.'**
  String get ifAccountExistsEmailYoullReceive;

  /// No description provided for @checkSpamFolderToo.
  ///
  /// In en, this message translates to:
  /// **'Check your spam folder too.'**
  String get checkSpamFolderToo;

  /// No description provided for @tryAnotherEmail.
  ///
  /// In en, this message translates to:
  /// **'Try another email'**
  String get tryAnotherEmail;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent to {email}.'**
  String verificationEmailSent(Object email);

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmail;

  /// No description provided for @openVerificationLinkEmailConfirmAccount.
  ///
  /// In en, this message translates to:
  /// **'Open the verification link in your email to confirm your account.'**
  String get openVerificationLinkEmailConfirmAccount;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationEmail;

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useDifferentEmail;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerified;

  /// No description provided for @emailConfirmedSignContinue.
  ///
  /// In en, this message translates to:
  /// **'Your email is confirmed.\nSign in to continue.'**
  String get emailConfirmedSignContinue;

  /// No description provided for @continueSign.
  ///
  /// In en, this message translates to:
  /// **'Continue to sign in'**
  String get continueSign;

  /// No description provided for @verificationEmailSent2.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent to {trim}.'**
  String verificationEmailSent2(Object trim);

  /// No description provided for @verificationLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification link expired'**
  String get verificationLinkExpired;

  /// No description provided for @linkHasExpiredInvalidRequestNew.
  ///
  /// In en, this message translates to:
  /// **'This link has expired or is invalid.\nRequest a new verification email.'**
  String get linkHasExpiredInvalidRequestNew;

  /// No description provided for @sendNewVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Send new verification email'**
  String get sendNewVerificationEmail;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get setNewPassword;

  /// No description provided for @chooseStrongPasswordAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password for your account.'**
  String get chooseStrongPasswordAccount;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get enterNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @noBusinessLinked.
  ///
  /// In en, this message translates to:
  /// **'No business linked.'**
  String get noBusinessLinked;

  /// No description provided for @zones2.
  ///
  /// In en, this message translates to:
  /// **'Zones ({zonesCount})'**
  String zones2(Object zonesCount);

  /// No description provided for @noZonesYetTapCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'No zones yet. Tap + to create your first zone.'**
  String get noZonesYetTapCreateFirst;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @theseZonesDefineWhereDeliverAdd.
  ///
  /// In en, this message translates to:
  /// **'These zones define where you deliver. Add, edit or deactivate zones anytime.'**
  String get theseZonesDefineWhereDeliverAdd;

  /// No description provided for @searchZones.
  ///
  /// In en, this message translates to:
  /// **'Search zones...'**
  String get searchZones;

  /// No description provided for @noZonesConfiguredYet.
  ///
  /// In en, this message translates to:
  /// **'No zones configured yet.'**
  String get noZonesConfiguredYet;

  /// No description provided for @zoneNotFound.
  ///
  /// In en, this message translates to:
  /// **'Zone not found'**
  String get zoneNotFound;

  /// No description provided for @zoneOptions.
  ///
  /// In en, this message translates to:
  /// **'Zone options'**
  String get zoneOptions;

  /// No description provided for @editZoneName.
  ///
  /// In en, this message translates to:
  /// **'Edit zone name'**
  String get editZoneName;

  /// No description provided for @deleteZone.
  ///
  /// In en, this message translates to:
  /// **'Delete zone'**
  String get deleteZone;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @zoneRenamed.
  ///
  /// In en, this message translates to:
  /// **'Zone renamed to {updated}'**
  String zoneRenamed(Object updated);

  /// No description provided for @couldNotRename.
  ///
  /// In en, this message translates to:
  /// **'Could not rename: {e}'**
  String couldNotRename(Object e);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete {zone}?'**
  String delete(Object zone);

  /// No description provided for @willRemoveZoneFromDeliverySetup.
  ///
  /// In en, this message translates to:
  /// **'This will remove the zone from your delivery setup.'**
  String get willRemoveZoneFromDeliverySetup;

  /// No description provided for @delete2.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete2;

  /// No description provided for @removedFromDeliverySetup.
  ///
  /// In en, this message translates to:
  /// **'{zone} removed from your delivery setup'**
  String removedFromDeliverySetup(Object zone);

  /// No description provided for @couldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {e}'**
  String couldNotDelete(Object e);

  /// No description provided for @zoneNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Zone name is required.'**
  String get zoneNameRequired;

  /// No description provided for @zoneName.
  ///
  /// In en, this message translates to:
  /// **'Zone name'**
  String get zoneName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @t0Km.
  ///
  /// In en, this message translates to:
  /// **'0 km'**
  String get t0Km;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String km(Object distance);

  /// No description provided for @totalDistance.
  ///
  /// In en, this message translates to:
  /// **'Total distance'**
  String get totalDistance;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total orders'**
  String get totalOrders;

  /// No description provided for @todaysDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Today\'s deliveries'**
  String get todaysDeliveries;

  /// No description provided for @noDeliveriesPlannedZoneToday.
  ///
  /// In en, this message translates to:
  /// **'No deliveries planned in this zone today.'**
  String get noDeliveriesPlannedZoneToday;

  /// No description provided for @dispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get dispatch;

  /// No description provided for @unassignedRider.
  ///
  /// In en, this message translates to:
  /// **'Unassigned rider'**
  String get unassignedRider;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'{count} order{s}'**
  String order(Object count, Object s);

  /// No description provided for @km2.
  ///
  /// In en, this message translates to:
  /// **'{distanceKm} km'**
  String km2(Object distanceKm);

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'{travelMinutes} min'**
  String min(Object travelMinutes);

  /// No description provided for @removedFromToday.
  ///
  /// In en, this message translates to:
  /// **'{delivery} removed from today'**
  String removedFromToday(Object delivery);

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @creatingZone.
  ///
  /// In en, this message translates to:
  /// **'Creating your zone'**
  String get creatingZone;

  /// No description provided for @successful.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get successful;

  /// No description provided for @newZoneHasBeenCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your new zone has been created successfully.'**
  String get newZoneHasBeenCreatedSuccessfully;

  /// No description provided for @createZone2.
  ///
  /// In en, this message translates to:
  /// **'Create Zone'**
  String get createZone2;

  /// No description provided for @zoneWillCoverHighlightedAreaMap.
  ///
  /// In en, this message translates to:
  /// **'This zone will cover the highlighted area on the map. You can always edit it later.'**
  String get zoneWillCoverHighlightedAreaMap;

  /// No description provided for @zoneDetails.
  ///
  /// In en, this message translates to:
  /// **'Zone details'**
  String get zoneDetails;

  /// No description provided for @nameAreaDeliver.
  ///
  /// In en, this message translates to:
  /// **'Name the area you deliver to'**
  String get nameAreaDeliver;

  /// No description provided for @enterZoneName.
  ///
  /// In en, this message translates to:
  /// **'Enter zone name'**
  String get enterZoneName;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @noRidersYet.
  ///
  /// In en, this message translates to:
  /// **'No riders yet.'**
  String get noRidersYet;

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

  /// No description provided for @riderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Rider not found'**
  String get riderNotFound;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get pendingReview;

  /// No description provided for @riderApplicant.
  ///
  /// In en, this message translates to:
  /// **'Rider applicant'**
  String get riderApplicant;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectingRiders.
  ///
  /// In en, this message translates to:
  /// **'Rejecting riders'**
  String get rejectingRiders;

  /// No description provided for @approveRider.
  ///
  /// In en, this message translates to:
  /// **'Approve Rider'**
  String get approveRider;

  /// No description provided for @approvingRiders.
  ///
  /// In en, this message translates to:
  /// **'Approving riders'**
  String get approvingRiders;

  /// No description provided for @customerRating.
  ///
  /// In en, this message translates to:
  /// **'Customer rating'**
  String get customerRating;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @drivingLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving Licence'**
  String get drivingLicence;

  /// No description provided for @noLicenceDocumentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No licence document available'**
  String get noLicenceDocumentAvailable;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// No description provided for @noAdditionalInformationAvailable.
  ///
  /// In en, this message translates to:
  /// **'No additional information available.'**
  String get noAdditionalInformationAvailable;

  /// No description provided for @searchTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Search team members...'**
  String get searchTeamMembers;

  /// No description provided for @noTeamMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No team members yet.'**
  String get noTeamMembersYet;

  /// No description provided for @teamMemberNotFound.
  ///
  /// In en, this message translates to:
  /// **'Team member not found'**
  String get teamMemberNotFound;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @roleAccess.
  ///
  /// In en, this message translates to:
  /// **'Role & access'**
  String get roleAccess;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get accountStatus;

  /// No description provided for @businessOwnerAlwaysKeepsFullAccess.
  ///
  /// In en, this message translates to:
  /// **'The business owner always keeps full access and cannot be removed from the team.'**
  String get businessOwnerAlwaysKeepsFullAccess;

  /// No description provided for @canManageDailyOperationsOrdersRiders.
  ///
  /// In en, this message translates to:
  /// **'Can manage daily operations, orders, riders and team members. Cannot manage billing or subscription.'**
  String get canManageDailyOperationsOrdersRiders;

  /// No description provided for @canAccessDailyOperationsOrdersRiders.
  ///
  /// In en, this message translates to:
  /// **'Can access daily operations, orders and riders. Cannot manage billing or subscription.'**
  String get canAccessDailyOperationsOrdersRiders;

  /// No description provided for @remove2.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove2;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @noProductsCatalogueYet.
  ///
  /// In en, this message translates to:
  /// **'No products in the catalogue yet.'**
  String get noProductsCatalogueYet;

  /// No description provided for @rm.
  ///
  /// In en, this message translates to:
  /// **'RM {displayPrice} · {status}'**
  String rm(Object displayPrice, Object status);

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomers;

  /// No description provided for @orders2.
  ///
  /// In en, this message translates to:
  /// **'Orders ({count})'**
  String orders2(Object count);

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @businessProfile2.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfile2;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpSupport2.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport2;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @version100.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version100;

  /// No description provided for @businessInformation2.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation2;

  /// No description provided for @nameTypeContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Name, type and contact details'**
  String get nameTypeContactDetails;

  /// No description provided for @pickupLocation2.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation2;

  /// No description provided for @whereDeliveriesStartFrom.
  ///
  /// In en, this message translates to:
  /// **'Where deliveries start from'**
  String get whereDeliveriesStartFrom;

  /// No description provided for @serviceArea2.
  ///
  /// In en, this message translates to:
  /// **'Service Area'**
  String get serviceArea2;

  /// No description provided for @howFarDeliver.
  ///
  /// In en, this message translates to:
  /// **'How far you deliver'**
  String get howFarDeliver;

  /// No description provided for @letsSetUpBusiness.
  ///
  /// In en, this message translates to:
  /// **'Let’s set up your business'**
  String get letsSetUpBusiness;

  /// No description provided for @justFewDetailsBeforeStartDelivering.
  ///
  /// In en, this message translates to:
  /// **'Just a few details before you start delivering with Cefflo. Takes about 2 minutes.'**
  String get justFewDetailsBeforeStartDelivering;

  /// No description provided for @getStarted2.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted2;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {totalSteps}'**
  String step(Object step, Object totalSteps);

  /// No description provided for @foodBeverage.
  ///
  /// In en, this message translates to:
  /// **'Food & Beverage'**
  String get foodBeverage;

  /// No description provided for @homeLiving.
  ///
  /// In en, this message translates to:
  /// **'Home & Living'**
  String get homeLiving;

  /// No description provided for @retail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get retail;

  /// No description provided for @groceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get groceries;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @businessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required.'**
  String get businessNameRequired;

  /// No description provided for @enterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get enterValidPhoneNumber;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @tellUsAboutBusiness.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your business'**
  String get tellUsAboutBusiness;

  /// No description provided for @appearsDeliveryOrdersReceipts.
  ///
  /// In en, this message translates to:
  /// **'This appears on your delivery orders and receipts.'**
  String get appearsDeliveryOrdersReceipts;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @eGKopiKita.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kopi Kita'**
  String get eGKopiKita;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessType;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone'**
  String get contactPhone;

  /// No description provided for @pickupAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Pickup address is required.'**
  String get pickupAddressRequired;

  /// No description provided for @whereDoDeliveriesStartFrom.
  ///
  /// In en, this message translates to:
  /// **'Where do deliveries start from?'**
  String get whereDoDeliveriesStartFrom;

  /// No description provided for @ridersPickUpOrdersFromLocation.
  ///
  /// In en, this message translates to:
  /// **'Riders pick up orders from this location.'**
  String get ridersPickUpOrdersFromLocation;

  /// No description provided for @pickupAddress.
  ///
  /// In en, this message translates to:
  /// **'Pickup Address'**
  String get pickupAddress;

  /// No description provided for @searchEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Search or enter your address'**
  String get searchEnterAddress;

  /// No description provided for @postcode.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get postcode;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @howFarDoDeliver.
  ///
  /// In en, this message translates to:
  /// **'How far do you deliver?'**
  String get howFarDoDeliver;

  /// No description provided for @ceffloUsesDecideWhichOrdersCan.
  ///
  /// In en, this message translates to:
  /// **'Cefflo uses this to decide which orders you can accept.'**
  String get ceffloUsesDecideWhichOrdersCan;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get finishSetup;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// No description provided for @teamRiders.
  ///
  /// In en, this message translates to:
  /// **'Team & Riders'**
  String get teamRiders;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @setText.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setText;

  /// No description provided for @business2.
  ///
  /// In en, this message translates to:
  /// **'Your Business\nis '**
  String get business2;

  /// No description provided for @ready2.
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get ready2;

  /// No description provided for @deliverySetupCompleteLetsStartDelivering.
  ///
  /// In en, this message translates to:
  /// **'Your delivery setup is complete.\nLet’s start delivering with Cefflo.'**
  String get deliverySetupCompleteLetsStartDelivering;

  /// No description provided for @goToday.
  ///
  /// In en, this message translates to:
  /// **'Go to Today'**
  String get goToday;

  /// No description provided for @noBusinessLinkedAccountYet.
  ///
  /// In en, this message translates to:
  /// **'No business is linked to this account yet.'**
  String get noBusinessLinkedAccountYet;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No {toLowerCase} orders.'**
  String noOrders(Object toLowerCase);

  /// No description provided for @todayItem.
  ///
  /// In en, this message translates to:
  /// **'Today, {createdAt} · {itemsCount} item{s}'**
  String todayItem(Object createdAt, Object itemsCount, Object s);

  /// No description provided for @editOrder2.
  ///
  /// In en, this message translates to:
  /// **'Edit Order'**
  String get editOrder2;

  /// No description provided for @deliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get deliver;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @deliveryInstruction.
  ///
  /// In en, this message translates to:
  /// **'Delivery Instruction'**
  String get deliveryInstruction;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items ({itemsCount})'**
  String items(Object itemsCount);

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get viewReceipt;

  /// No description provided for @receiptView.
  ///
  /// In en, this message translates to:
  /// **'The receipt view'**
  String get receiptView;

  /// No description provided for @noItemsOrder.
  ///
  /// In en, this message translates to:
  /// **'No items on this order.'**
  String get noItemsOrder;

  /// No description provided for @viewAllItems.
  ///
  /// In en, this message translates to:
  /// **'View all {itemsCount} items'**
  String viewAllItems(Object itemsCount);

  /// No description provided for @zoneSet.
  ///
  /// In en, this message translates to:
  /// **'Zone set to {z}'**
  String zoneSet(Object z);

  /// No description provided for @couldNotSetZone.
  ///
  /// In en, this message translates to:
  /// **'Could not set zone: {e}'**
  String couldNotSetZone(Object e);

  /// No description provided for @orderApproved.
  ///
  /// In en, this message translates to:
  /// **'Order approved'**
  String get orderApproved;

  /// No description provided for @couldNotApprove.
  ///
  /// In en, this message translates to:
  /// **'Could not approve: {e}'**
  String couldNotApprove(Object e);

  /// No description provided for @approveOrder.
  ///
  /// In en, this message translates to:
  /// **'Approve Order'**
  String get approveOrder;

  /// No description provided for @approving.
  ///
  /// In en, this message translates to:
  /// **'Approving…'**
  String get approving;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @createSingleOrderStepByStep.
  ///
  /// In en, this message translates to:
  /// **'Create a single order step by step'**
  String get createSingleOrderStepByStep;

  /// No description provided for @importOrders2.
  ///
  /// In en, this message translates to:
  /// **'Import Orders'**
  String get importOrders2;

  /// No description provided for @importMultipleOrdersFromFiles.
  ///
  /// In en, this message translates to:
  /// **'Import multiple orders from your files'**
  String get importMultipleOrdersFromFiles;

  /// No description provided for @recentImports.
  ///
  /// In en, this message translates to:
  /// **'Recent Imports'**
  String get recentImports;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @importHistory.
  ///
  /// In en, this message translates to:
  /// **'The import history'**
  String get importHistory;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @openingImport.
  ///
  /// In en, this message translates to:
  /// **'Opening this import'**
  String get openingImport;

  /// No description provided for @googleSheets.
  ///
  /// In en, this message translates to:
  /// **'Google Sheets'**
  String get googleSheets;

  /// No description provided for @importFromGoogleSheets.
  ///
  /// In en, this message translates to:
  /// **'Import from your Google Sheets'**
  String get importFromGoogleSheets;

  /// No description provided for @mealPrepOrders.
  ///
  /// In en, this message translates to:
  /// **'Meal Prep Orders'**
  String get mealPrepOrders;

  /// No description provided for @t16Sep2026.
  ///
  /// In en, this message translates to:
  /// **'16 Sep 2026'**
  String get t16Sep2026;

  /// No description provided for @excel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get excel;

  /// No description provided for @uploadExcelFileXlsxXls.
  ///
  /// In en, this message translates to:
  /// **'Upload an Excel file (.xlsx, .xls)'**
  String get uploadExcelFileXlsxXls;

  /// No description provided for @cateringSept.
  ///
  /// In en, this message translates to:
  /// **'Catering Sept'**
  String get cateringSept;

  /// No description provided for @t14Sep2026.
  ///
  /// In en, this message translates to:
  /// **'14 Sep 2026'**
  String get t14Sep2026;

  /// No description provided for @googleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// No description provided for @importFromFilesGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Import from files in your Google Drive'**
  String get importFromFilesGoogleDrive;

  /// No description provided for @hamperOrders.
  ///
  /// In en, this message translates to:
  /// **'Hamper Orders'**
  String get hamperOrders;

  /// No description provided for @t12Sep2026.
  ///
  /// In en, this message translates to:
  /// **'12 Sep 2026'**
  String get t12Sep2026;

  /// No description provided for @selectSource.
  ///
  /// In en, this message translates to:
  /// **'Select your source'**
  String get selectSource;

  /// No description provided for @googleSheetsExcelGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Sheets, Excel or Google Drive'**
  String get googleSheetsExcelGoogleDrive;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get chooseFile;

  /// No description provided for @pickConnectedSheet.
  ///
  /// In en, this message translates to:
  /// **'Or pick a connected sheet'**
  String get pickConnectedSheet;

  /// No description provided for @mapColumns.
  ///
  /// In en, this message translates to:
  /// **'Map the columns'**
  String get mapColumns;

  /// No description provided for @previewOrders.
  ///
  /// In en, this message translates to:
  /// **'And preview your orders'**
  String get previewOrders;

  /// No description provided for @importText.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importText;

  /// No description provided for @reviewOrders.
  ///
  /// In en, this message translates to:
  /// **'And review the orders'**
  String get reviewOrders;

  /// No description provided for @chooseSourceImportMultipleOrders.
  ///
  /// In en, this message translates to:
  /// **'Choose a source to import multiple orders.'**
  String get chooseSourceImportMultipleOrders;

  /// No description provided for @howWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works?'**
  String get howWorks;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @importingFrom.
  ///
  /// In en, this message translates to:
  /// **'Importing from {source}'**
  String importingFrom(Object source);

  /// No description provided for @customerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer name is required.'**
  String get customerNameRequired;

  /// No description provided for @deliveryAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Delivery address is required.'**
  String get deliveryAddressRequired;

  /// No description provided for @creatingOrder.
  ///
  /// In en, this message translates to:
  /// **'Creating your order'**
  String get creatingOrder;

  /// No description provided for @updatingOrder.
  ///
  /// In en, this message translates to:
  /// **'Updating your order'**
  String get updatingOrder;

  /// No description provided for @newOrderHasBeenCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your new order has been created successfully.'**
  String get newOrderHasBeenCreatedSuccessfully;

  /// No description provided for @orderHasBeenUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your order has been updated successfully.'**
  String get orderHasBeenUpdatedSuccessfully;

  /// No description provided for @reviewCreate.
  ///
  /// In en, this message translates to:
  /// **'Review & Create'**
  String get reviewCreate;

  /// No description provided for @updateOrder.
  ///
  /// In en, this message translates to:
  /// **'Update Order'**
  String get updateOrder;

  /// No description provided for @createNewOrderStepByStep.
  ///
  /// In en, this message translates to:
  /// **'Create a new order step by step.'**
  String get createNewOrderStepByStep;

  /// No description provided for @updateOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Update order details.'**
  String get updateOrderDetails;

  /// No description provided for @selectExistingCustomerAddNewOne.
  ///
  /// In en, this message translates to:
  /// **'Select an existing customer or add a new one.'**
  String get selectExistingCustomerAddNewOne;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customerName;

  /// No description provided for @searchCustomerByNamePhoneEmail.
  ///
  /// In en, this message translates to:
  /// **'Search customer by name, phone or email...'**
  String get searchCustomerByNamePhoneEmail;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number...'**
  String get enterPhoneNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddress;

  /// No description provided for @enterDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter delivery address...'**
  String get enterDeliveryAddress;

  /// No description provided for @items2.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items2;

  /// No description provided for @addOrderItems.
  ///
  /// In en, this message translates to:
  /// **'Add order items'**
  String get addOrderItems;

  /// No description provided for @addItemsOrder.
  ///
  /// In en, this message translates to:
  /// **'Add items to this order'**
  String get addItemsOrder;

  /// No description provided for @addingOrderItems.
  ///
  /// In en, this message translates to:
  /// **'Adding order items'**
  String get addingOrderItems;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @specialRequestsOptional.
  ///
  /// In en, this message translates to:
  /// **'Special requests (optional)'**
  String get specialRequestsOptional;

  /// No description provided for @instruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get instruction;

  /// No description provided for @addDeliveryNotes.
  ///
  /// In en, this message translates to:
  /// **'Add delivery notes...'**
  String get addDeliveryNotes;

  /// No description provided for @productNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Product name is required.'**
  String get productNameRequired;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price.'**
  String get enterValidPrice;

  /// No description provided for @addingProduct.
  ///
  /// In en, this message translates to:
  /// **'Adding your product'**
  String get addingProduct;

  /// No description provided for @updatingProduct.
  ///
  /// In en, this message translates to:
  /// **'Updating your product'**
  String get updatingProduct;

  /// No description provided for @newProductHasBeenAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your new product has been added successfully.'**
  String get newProductHasBeenAddedSuccessfully;

  /// No description provided for @productHasBeenUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your product has been updated successfully.'**
  String get productHasBeenUpdatedSuccessfully;

  /// No description provided for @addProduct2.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct2;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @productPhoto.
  ///
  /// In en, this message translates to:
  /// **'Product Photo'**
  String get productPhoto;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @enterProductName.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get enterProductName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @enterProductDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter product description'**
  String get enterProductDescription;

  /// No description provided for @priceRm.
  ///
  /// In en, this message translates to:
  /// **'Price (RM)'**
  String get priceRm;

  /// No description provided for @rm000.
  ///
  /// In en, this message translates to:
  /// **'RM 0.00'**
  String get rm000;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @showProductStorefront.
  ///
  /// In en, this message translates to:
  /// **'Show this product in your storefront'**
  String get showProductStorefront;

  /// No description provided for @way2.
  ///
  /// In en, this message translates to:
  /// **'On the Way'**
  String get way2;

  /// No description provided for @addProductPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add product photo'**
  String get addProductPhoto;

  /// No description provided for @deliveryRun.
  ///
  /// In en, this message translates to:
  /// **'Delivery run'**
  String get deliveryRun;

  /// No description provided for @delivered2.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} delivered'**
  String delivered2(Object done, Object total);

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'{done} remaining'**
  String remaining(Object done);

  /// No description provided for @nextStop.
  ///
  /// In en, this message translates to:
  /// **'Next stop'**
  String get nextStop;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @upcomingStops.
  ///
  /// In en, this message translates to:
  /// **'Upcoming stops'**
  String get upcomingStops;

  /// No description provided for @everyStopRunFinished.
  ///
  /// In en, this message translates to:
  /// **'Every stop on this run is finished.'**
  String get everyStopRunFinished;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'{zone} Run'**
  String run(Object zone);

  /// No description provided for @dispatched2.
  ///
  /// In en, this message translates to:
  /// **'Dispatched to {rider}'**
  String dispatched2(Object rider);

  /// No description provided for @dispatchOrder.
  ///
  /// In en, this message translates to:
  /// **'Dispatch {count} order{s}'**
  String dispatchOrder(Object count, Object s);

  /// No description provided for @chooseRider.
  ///
  /// In en, this message translates to:
  /// **'Choose the rider for {zone}.'**
  String chooseRider(Object zone);

  /// No description provided for @noActiveRidersYet.
  ///
  /// In en, this message translates to:
  /// **'No active riders yet.'**
  String get noActiveRidersYet;

  /// No description provided for @checkingVehicleCapacity.
  ///
  /// In en, this message translates to:
  /// **'Checking vehicle and capacity…'**
  String get checkingVehicleCapacity;

  /// No description provided for @dispatching.
  ///
  /// In en, this message translates to:
  /// **'Dispatching…'**
  String get dispatching;

  /// No description provided for @savingServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Saving your service area'**
  String get savingServiceArea;

  /// No description provided for @serviceAreaHasBeenSaved.
  ///
  /// In en, this message translates to:
  /// **'Your service area has been saved.'**
  String get serviceAreaHasBeenSaved;

  /// No description provided for @coverageConfiguredCeffloDecidesEachOrders.
  ///
  /// In en, this message translates to:
  /// **'Coverage is configured. Cefflo decides each order’s coverage from this.'**
  String get coverageConfiguredCeffloDecidesEachOrders;

  /// No description provided for @noServiceAreaConfiguredYetOrders.
  ///
  /// In en, this message translates to:
  /// **'No service area configured yet. Orders will show “Not set” instead of a coverage verdict.'**
  String get noServiceAreaConfiguredYetOrders;

  /// No description provided for @saveServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Save service area'**
  String get saveServiceArea;

  /// No description provided for @manageZones.
  ///
  /// In en, this message translates to:
  /// **'Manage zones'**
  String get manageZones;

  /// No description provided for @seeConfigureZonesDeliver.
  ///
  /// In en, this message translates to:
  /// **'See and configure the zones you deliver to'**
  String get seeConfigureZonesDeliver;

  /// No description provided for @deliveryRadius.
  ///
  /// In en, this message translates to:
  /// **'Delivery radius'**
  String get deliveryRadius;

  /// No description provided for @km3.
  ///
  /// In en, this message translates to:
  /// **'{round} km'**
  String km3(Object round);

  /// No description provided for @sf.
  ///
  /// In en, this message translates to:
  /// **'SF-{padLeft}'**
  String sf(Object padLeft);

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Your Cart'**
  String get cart;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get cartEmpty;

  /// No description provided for @rm2.
  ///
  /// In en, this message translates to:
  /// **'RM {price}'**
  String rm2(Object price);

  /// No description provided for @addNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get addNoteOptional;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @proceedCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get proceedCheckout;

  /// No description provided for @rm3.
  ///
  /// In en, this message translates to:
  /// **'RM {toStringAsFixed}'**
  String rm3(Object toStringAsFixed);

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @customerInfo.
  ///
  /// In en, this message translates to:
  /// **'Customer Info'**
  String get customerInfo;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @deliveryAddress2.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress2;

  /// No description provided for @deliveryOption.
  ///
  /// In en, this message translates to:
  /// **'Delivery Option'**
  String get deliveryOption;

  /// No description provided for @standardDelivery.
  ///
  /// In en, this message translates to:
  /// **'Standard delivery'**
  String get standardDelivery;

  /// No description provided for @t3045Min.
  ///
  /// In en, this message translates to:
  /// **'30-45 min'**
  String get t3045Min;

  /// No description provided for @expressDelivery.
  ///
  /// In en, this message translates to:
  /// **'Express delivery'**
  String get expressDelivery;

  /// No description provided for @t1520MinRm300.
  ///
  /// In en, this message translates to:
  /// **'15-20 min · +RM 3.00'**
  String get t1520MinRm300;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @cashDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashDelivery;

  /// No description provided for @payWhenOrderArrives.
  ///
  /// In en, this message translates to:
  /// **'Pay when your order arrives'**
  String get payWhenOrderArrives;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @prototypeOnlyNoRealPaymentProcessed.
  ///
  /// In en, this message translates to:
  /// **'Prototype only -- no real payment is processed'**
  String get prototypeOnlyNoRealPaymentProcessed;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed!'**
  String get orderPlaced;

  /// No description provided for @orderHasBeenCreatedPrototypeFlow.
  ///
  /// In en, this message translates to:
  /// **'Order {orderRef} has been created. This is a prototype flow -- no real order or payment was processed.'**
  String orderHasBeenCreatedPrototypeFlow(Object orderRef);

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continueShopping;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Your store'**
  String get store;

  /// No description provided for @defaultText.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultText;

  /// No description provided for @white.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get white;

  /// No description provided for @warm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get warm;

  /// No description provided for @cool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get cool;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// No description provided for @storefrontStaysChangesMadeHereNot.
  ///
  /// In en, this message translates to:
  /// **'Your storefront stays as it is. Changes you made here are not saved.'**
  String get storefrontStaysChangesMadeHereNot;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @updatingStorefront.
  ///
  /// In en, this message translates to:
  /// **'Updating your storefront'**
  String get updatingStorefront;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'{def} is live'**
  String live(Object def);

  /// No description provided for @storefrontUpdated.
  ///
  /// In en, this message translates to:
  /// **'Storefront updated'**
  String get storefrontUpdated;

  /// No description provided for @productsNowShowLayout.
  ///
  /// In en, this message translates to:
  /// **'Your products now show in the {def} layout.'**
  String productsNowShowLayout(Object def);

  /// No description provided for @customersNowSeeChanges.
  ///
  /// In en, this message translates to:
  /// **'Customers now see your changes.'**
  String get customersNowSeeChanges;

  /// No description provided for @couldntOpenPhotosPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your photos. Please try again.'**
  String get couldntOpenPhotosPleaseTryAgain;

  /// No description provided for @customize2.
  ///
  /// In en, this message translates to:
  /// **'Customize {def}'**
  String customize2(Object def);

  /// No description provided for @adjustColoursStyleMatchBrand.
  ///
  /// In en, this message translates to:
  /// **'Adjust the colours and style to match your brand.'**
  String get adjustColoursStyleMatchBrand;

  /// No description provided for @resetTemplateDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to template defaults'**
  String get resetTemplateDefaults;

  /// No description provided for @brandColour.
  ///
  /// In en, this message translates to:
  /// **'Brand colour'**
  String get brandColour;

  /// No description provided for @customColour.
  ///
  /// In en, this message translates to:
  /// **'Custom colour'**
  String get customColour;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @heroImage.
  ///
  /// In en, this message translates to:
  /// **'Hero image'**
  String get heroImage;

  /// No description provided for @shownBehindStorefrontBanner.
  ///
  /// In en, this message translates to:
  /// **'Shown behind your storefront banner.'**
  String get shownBehindStorefrontBanner;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get storeName;

  /// No description provided for @fromBusinessProfile.
  ///
  /// In en, this message translates to:
  /// **'From your Business Profile.'**
  String get fromBusinessProfile;

  /// No description provided for @taglineOptional.
  ///
  /// In en, this message translates to:
  /// **'Tagline (optional)'**
  String get taglineOptional;

  /// No description provided for @colour.
  ///
  /// In en, this message translates to:
  /// **'Colour {hex}'**
  String colour(Object hex);

  /// No description provided for @background2.
  ///
  /// In en, this message translates to:
  /// **'{label} background'**
  String background2(Object label);

  /// No description provided for @pickColour.
  ///
  /// In en, this message translates to:
  /// **'Pick a Colour'**
  String get pickColour;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @exploreTemplates.
  ///
  /// In en, this message translates to:
  /// **'Explore Templates'**
  String get exploreTemplates;

  /// No description provided for @previewAnyLayoutOwnProducts.
  ///
  /// In en, this message translates to:
  /// **'Preview any layout with your own products.'**
  String get previewAnyLayoutOwnProducts;

  /// No description provided for @noTemplatesHereYet.
  ///
  /// In en, this message translates to:
  /// **'No templates here yet.'**
  String get noTemplatesHereYet;

  /// No description provided for @everyTemplateShowsTheseProducts.
  ///
  /// In en, this message translates to:
  /// **'Every template shows these products'**
  String get everyTemplateShowsTheseProducts;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @customize3.
  ///
  /// In en, this message translates to:
  /// **'Customize: {join}'**
  String customize3(Object join);

  /// No description provided for @useTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use This Template'**
  String get useTemplate;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @storefront2.
  ///
  /// In en, this message translates to:
  /// **'Your storefront'**
  String get storefront2;

  /// No description provided for @rm4.
  ///
  /// In en, this message translates to:
  /// **'RM{amount}'**
  String rm4(Object amount);

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team members'**
  String get teamMembers;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'{plan} plan'**
  String plan(Object plan);

  /// No description provided for @nextRenewal.
  ///
  /// In en, this message translates to:
  /// **'Next renewal on {nextRenewal}'**
  String nextRenewal(Object nextRenewal);

  /// No description provided for @currentUsage.
  ///
  /// In en, this message translates to:
  /// **'Current usage'**
  String get currentUsage;

  /// No description provided for @cycle.
  ///
  /// In en, this message translates to:
  /// **'This cycle'**
  String get cycle;

  /// No description provided for @changePlan.
  ///
  /// In en, this message translates to:
  /// **'Change plan'**
  String get changePlan;

  /// No description provided for @paymentMethod2.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod2;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @billingHistory2.
  ///
  /// In en, this message translates to:
  /// **'Billing history'**
  String get billingHistory2;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'{used} · Unlimited'**
  String unlimited(Object used);

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @selectPlanThatFitsBusiness.
  ///
  /// In en, this message translates to:
  /// **'Select the plan that fits your business.'**
  String get selectPlanThatFitsBusiness;

  /// No description provided for @plansPricesCurrentPricingCandidate.
  ///
  /// In en, this message translates to:
  /// **'Plans and prices are the current pricing candidate.'**
  String get plansPricesCurrentPricingCandidate;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @t2MonthsFree.
  ///
  /// In en, this message translates to:
  /// **'2 months free'**
  String get t2MonthsFree;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing payment'**
  String get processingPayment;

  /// No description provided for @pleaseWaitWhileWeConfirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we confirm your payment.'**
  String get pleaseWaitWhileWeConfirmPayment;

  /// No description provided for @subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription active'**
  String get subscriptionActive;

  /// No description provided for @paymentUnsuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment unsuccessful'**
  String get paymentUnsuccessful;

  /// No description provided for @weCouldntProcessPaymentNoCharge.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t process your payment.\nNo charge was made.'**
  String get weCouldntProcessPaymentNoCharge;

  /// No description provided for @changePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Change payment method'**
  String get changePaymentMethod;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @billingCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing cycle'**
  String get billingCycle;

  /// No description provided for @creditDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit card'**
  String get creditDebitCard;

  /// No description provided for @fpxOnlineBanking.
  ///
  /// In en, this message translates to:
  /// **'FPX online banking'**
  String get fpxOnlineBanking;

  /// No description provided for @demoNoRealPaymentProcessed.
  ///
  /// In en, this message translates to:
  /// **'Demo — no real payment is processed.'**
  String get demoNoRealPaymentProcessed;

  /// No description provided for @noInvoicesYet.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet.'**
  String get noInvoicesYet;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @downloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download invoice'**
  String get downloadInvoice;

  /// No description provided for @invoiceDownload.
  ///
  /// In en, this message translates to:
  /// **'Invoice download'**
  String get invoiceDownload;

  /// No description provided for @ahmadRazi.
  ///
  /// In en, this message translates to:
  /// **'Ahmad Razi'**
  String get ahmadRazi;

  /// No description provided for @vfy7281.
  ///
  /// In en, this message translates to:
  /// **'VFY 7281'**
  String get vfy7281;

  /// No description provided for @bangsar.
  ///
  /// In en, this message translates to:
  /// **'Bangsar'**
  String get bangsar;

  /// No description provided for @t224Pm.
  ///
  /// In en, this message translates to:
  /// **'2:24 PM'**
  String get t224Pm;

  /// No description provided for @sitiAminah.
  ///
  /// In en, this message translates to:
  /// **'Siti Aminah'**
  String get sitiAminah;

  /// No description provided for @bmd4120.
  ///
  /// In en, this message translates to:
  /// **'BMD 4120'**
  String get bmd4120;

  /// No description provided for @sentul.
  ///
  /// In en, this message translates to:
  /// **'Sentul'**
  String get sentul;

  /// No description provided for @t156Pm.
  ///
  /// In en, this message translates to:
  /// **'1:56 PM'**
  String get t156Pm;

  /// No description provided for @jasonLim.
  ///
  /// In en, this message translates to:
  /// **'Jason Lim'**
  String get jasonLim;

  /// No description provided for @vdt3302.
  ///
  /// In en, this message translates to:
  /// **'VDT 3302'**
  String get vdt3302;

  /// No description provided for @setapak.
  ///
  /// In en, this message translates to:
  /// **'Setapak'**
  String get setapak;

  /// No description provided for @t1241Pm.
  ///
  /// In en, this message translates to:
  /// **'12:41 PM'**
  String get t1241Pm;

  /// No description provided for @nurIman.
  ///
  /// In en, this message translates to:
  /// **'Nur Iman'**
  String get nurIman;

  /// No description provided for @vfe9812.
  ///
  /// In en, this message translates to:
  /// **'VFE 9812'**
  String get vfe9812;

  /// No description provided for @shahAlam.
  ///
  /// In en, this message translates to:
  /// **'Shah Alam'**
  String get shahAlam;

  /// No description provided for @t1128Am.
  ///
  /// In en, this message translates to:
  /// **'11:28 AM'**
  String get t1128Am;

  /// No description provided for @danielTan.
  ///
  /// In en, this message translates to:
  /// **'Daniel Tan'**
  String get danielTan;

  /// No description provided for @bpl6683.
  ///
  /// In en, this message translates to:
  /// **'BPL 6683'**
  String get bpl6683;

  /// No description provided for @petalingJaya.
  ///
  /// In en, this message translates to:
  /// **'Petaling Jaya'**
  String get petalingJaya;

  /// No description provided for @t1054Am.
  ///
  /// In en, this message translates to:
  /// **'10:54 AM'**
  String get t1054Am;

  /// No description provided for @farahLee.
  ///
  /// In en, this message translates to:
  /// **'Farah Lee'**
  String get farahLee;

  /// No description provided for @vds7721.
  ///
  /// In en, this message translates to:
  /// **'VDS 7721'**
  String get vds7721;

  /// No description provided for @putrajaya.
  ///
  /// In en, this message translates to:
  /// **'Putrajaya'**
  String get putrajaya;

  /// No description provided for @t0917Am.
  ///
  /// In en, this message translates to:
  /// **'09:17 AM'**
  String get t0917Am;

  /// No description provided for @hafizKhan.
  ///
  /// In en, this message translates to:
  /// **'Hafiz Khan'**
  String get hafizKhan;

  /// No description provided for @bpq3091.
  ///
  /// In en, this message translates to:
  /// **'BPQ 3091'**
  String get bpq3091;

  /// No description provided for @klang.
  ///
  /// In en, this message translates to:
  /// **'Klang'**
  String get klang;

  /// No description provided for @t0836Am.
  ///
  /// In en, this message translates to:
  /// **'08:36 AM'**
  String get t0836Am;

  /// No description provided for @totalOrders2.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders2;

  /// No description provided for @recentDelivery.
  ///
  /// In en, this message translates to:
  /// **'Recent Delivery'**
  String get recentDelivery;

  /// No description provided for @noCompletedDeliveriesYet.
  ///
  /// In en, this message translates to:
  /// **'No completed deliveries yet.'**
  String get noCompletedDeliveriesYet;

  /// No description provided for @needAttention.
  ///
  /// In en, this message translates to:
  /// **'Need Attention'**
  String get needAttention;

  /// No description provided for @needAttention2.
  ///
  /// In en, this message translates to:
  /// **'Need Attention ({issuesCount})'**
  String needAttention2(Object issuesCount);

  /// No description provided for @nothingNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs your attention.'**
  String get nothingNeedsAttention;

  /// No description provided for @needsAction.
  ///
  /// In en, this message translates to:
  /// **'Needs your action'**
  String get needsAction;

  /// No description provided for @activeRun.
  ///
  /// In en, this message translates to:
  /// **'Active run'**
  String get activeRun;

  /// No description provided for @inviteRider.
  ///
  /// In en, this message translates to:
  /// **'Invite rider'**
  String get inviteRider;

  /// No description provided for @inviteTeamMember.
  ///
  /// In en, this message translates to:
  /// **'Invite team member'**
  String get inviteTeamMember;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @youreOfflineNewOrdersPaused.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. New orders are paused.'**
  String get youreOfflineNewOrdersPaused;

  /// No description provided for @youreOnline.
  ///
  /// In en, this message translates to:
  /// **'You\'re online.'**
  String get youreOnline;

  /// No description provided for @businesses.
  ///
  /// In en, this message translates to:
  /// **'Your businesses'**
  String get businesses;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon,'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening,'**
  String get goodEvening;

  /// No description provided for @heresWhatsHappeningToday.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what\'s happening today.'**
  String get heresWhatsHappeningToday;

  /// No description provided for @searchOrderNumberCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search order number or customer...'**
  String get searchOrderNumberCustomer;

  /// No description provided for @searchRiders.
  ///
  /// In en, this message translates to:
  /// **'Search riders...'**
  String get searchRiders;

  /// No description provided for @addOrder.
  ///
  /// In en, this message translates to:
  /// **'Add order'**
  String get addOrder;

  /// No description provided for @addZone.
  ///
  /// In en, this message translates to:
  /// **'Add zone'**
  String get addZone;

  /// No description provided for @notificationOptions.
  ///
  /// In en, this message translates to:
  /// **'Notification options'**
  String get notificationOptions;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get clearAllNotifications;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @notWiredUpYet.
  ///
  /// In en, this message translates to:
  /// **'{action} is not wired up yet.'**
  String notWiredUpYet(Object action);

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @phoneApp.
  ///
  /// In en, this message translates to:
  /// **'the phone app'**
  String get phoneApp;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @couldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open {target}.'**
  String couldNotOpen(Object target);

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @call2.
  ///
  /// In en, this message translates to:
  /// **'Call {phone}'**
  String call2(Object phone);

  /// No description provided for @whatsapp2.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp {phone}'**
  String whatsapp2(Object phone);

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @weCouldntCompleteActionRightNow.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete this action right now. Please try again.'**
  String get weCouldntCompleteActionRightNow;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @activeTeamMemberCanAccessBusiness.
  ///
  /// In en, this message translates to:
  /// **'Active · This team member can currently access your business.'**
  String get activeTeamMemberCanAccessBusiness;

  /// No description provided for @fullAccessIncludingBillingSubscription.
  ///
  /// In en, this message translates to:
  /// **'Full access to every part of the business, including billing and subscription.'**
  String get fullAccessIncludingBillingSubscription;

  /// No description provided for @importSampleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count} orders\n{date}'**
  String importSampleSubtitle(Object label, Object count, Object date);

  /// No description provided for @nextSetHowFarDeliver.
  ///
  /// In en, this message translates to:
  /// **'Next: set how far you deliver'**
  String get nextSetHowFarDeliver;

  /// No description provided for @reservedLaterApprovedDeliverySettingsPass.
  ///
  /// In en, this message translates to:
  /// **'Reserved for a later approved delivery settings pass.'**
  String get reservedLaterApprovedDeliverySettingsPass;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @nameContactDescription.
  ///
  /// In en, this message translates to:
  /// **'Name, contact, description'**
  String get nameContactDescription;

  /// No description provided for @businessAddress2.
  ///
  /// In en, this message translates to:
  /// **'Business Address'**
  String get businessAddress2;

  /// No description provided for @storeAddressServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Store address and service area'**
  String get storeAddressServiceArea;

  /// No description provided for @businessHours2.
  ///
  /// In en, this message translates to:
  /// **'Business Hours'**
  String get businessHours2;

  /// No description provided for @setOperatingHours.
  ///
  /// In en, this message translates to:
  /// **'Set your operating hours'**
  String get setOperatingHours;

  /// No description provided for @storeReady.
  ///
  /// In en, this message translates to:
  /// **'Your store is ready'**
  String get storeReady;

  /// No description provided for @keepBusinessInformationUpDate.
  ///
  /// In en, this message translates to:
  /// **'Keep your business information up to date.'**
  String get keepBusinessInformationUpDate;

  /// No description provided for @editingBusinessDetailsAppNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Editing business details in the app is not connected yet.'**
  String get editingBusinessDetailsAppNotConnected;

  /// No description provided for @businessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business details'**
  String get businessDetails;

  /// No description provided for @howCustomersRidersSeeBusiness.
  ///
  /// In en, this message translates to:
  /// **'How customers and riders see your business.'**
  String get howCustomersRidersSeeBusiness;

  /// No description provided for @taglineOptional2.
  ///
  /// In en, this message translates to:
  /// **'Tagline (Optional)'**
  String get taglineOptional2;

  /// No description provided for @shortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short Description'**
  String get shortDescription;

  /// No description provided for @whereCustomersRidersCanReach.
  ///
  /// In en, this message translates to:
  /// **'Where customers and riders can reach you.'**
  String get whereCustomersRidersCanReach;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @businessEmail.
  ///
  /// In en, this message translates to:
  /// **'Business Email'**
  String get businessEmail;

  /// No description provided for @editingBusinessAddressAppNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Editing the business address in the app is not connected yet.'**
  String get editingBusinessAddressAppNotConnected;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddress;

  /// No description provided for @addressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address details'**
  String get addressDetails;

  /// No description provided for @addressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get addressLine1;

  /// No description provided for @addressLine2Optional.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2 (Optional)'**
  String get addressLine2Optional;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @businessHoursNotConnectedYet.
  ///
  /// In en, this message translates to:
  /// **'Business hours are not connected yet.'**
  String get businessHoursNotConnectedYet;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @saveHours.
  ///
  /// In en, this message translates to:
  /// **'Save Hours'**
  String get saveHours;

  /// No description provided for @operatingHours.
  ///
  /// In en, this message translates to:
  /// **'Operating Hours'**
  String get operatingHours;

  /// No description provided for @letCustomersKnowWhenBusinessOpen.
  ///
  /// In en, this message translates to:
  /// **'Let your customers know when your business is open.'**
  String get letCustomersKnowWhenBusinessOpen;

  /// No description provided for @applyMondaysHoursAllDays.
  ///
  /// In en, this message translates to:
  /// **'Apply Monday\'s hours to all days'**
  String get applyMondaysHoursAllDays;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetails;

  /// No description provided for @nameShownTeam.
  ///
  /// In en, this message translates to:
  /// **'Your name as shown to your team.'**
  String get nameShownTeam;

  /// No description provided for @fullName2.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName2;

  /// No description provided for @signEmailRole.
  ///
  /// In en, this message translates to:
  /// **'Sign-in email and role.'**
  String get signEmailRole;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailCannotChangedApp.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed in the app.'**
  String get emailCannotChangedApp;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @managedByBusiness.
  ///
  /// In en, this message translates to:
  /// **'Managed by your business.'**
  String get managedByBusiness;

  /// No description provided for @keepAccountSafe.
  ///
  /// In en, this message translates to:
  /// **'Keep your account safe'**
  String get keepAccountSafe;

  /// No description provided for @manageHowSignBusinessAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage how you sign in to your business account.'**
  String get manageHowSignBusinessAccount;

  /// No description provided for @signAccess.
  ///
  /// In en, this message translates to:
  /// **'Sign-in & access'**
  String get signAccess;

  /// No description provided for @changePassword2.
  ///
  /// In en, this message translates to:
  /// **'Change your password'**
  String get changePassword2;

  /// No description provided for @twoFactorAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuthentication;

  /// No description provided for @useLeast8CharactersLetterNumber.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters with a letter and a number.'**
  String get useLeast8CharactersLetterNumber;

  /// No description provided for @updatingPassword2.
  ///
  /// In en, this message translates to:
  /// **'Updating your password'**
  String get updatingPassword2;

  /// No description provided for @passwordHasBeenUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated successfully.'**
  String get passwordHasBeenUpdatedSuccessfully;

  /// No description provided for @updatePassword2.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword2;

  /// No description provided for @useStrongPasswordKeepAccountSecure.
  ///
  /// In en, this message translates to:
  /// **'Use a strong password to keep your account secure.'**
  String get useStrongPasswordKeepAccountSecure;

  /// No description provided for @newPassword2.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword2;

  /// No description provided for @enterNewPassword2.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword2;

  /// No description provided for @minimum8Characters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get minimum8Characters;

  /// No description provided for @includeLeastOneLetterOneNumber.
  ///
  /// In en, this message translates to:
  /// **'Include at least one letter and one number'**
  String get includeLeastOneLetterOneNumber;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNewPassword2.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword2;

  /// No description provided for @notificationSettingsNotConnectedYet.
  ///
  /// In en, this message translates to:
  /// **'Notification settings are not connected yet.'**
  String get notificationSettingsNotConnectedYet;

  /// No description provided for @always.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get always;

  /// No description provided for @issuesDeliveryProgressAccountSecurityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Issues, delivery progress and account security alerts keep your operation running, so they cannot be turned off.'**
  String get issuesDeliveryProgressAccountSecurityAlerts;

  /// No description provided for @orderIssues.
  ///
  /// In en, this message translates to:
  /// **'Order issues'**
  String get orderIssues;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account & security'**
  String get accountSecurity;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @newOrders.
  ///
  /// In en, this message translates to:
  /// **'New orders'**
  String get newOrders;

  /// No description provided for @whenNewOrderComes.
  ///
  /// In en, this message translates to:
  /// **'When a new order comes in.'**
  String get whenNewOrderComes;

  /// No description provided for @riderStatus.
  ///
  /// In en, this message translates to:
  /// **'Rider status'**
  String get riderStatus;

  /// No description provided for @whenRidersGoOnlineOffline.
  ///
  /// In en, this message translates to:
  /// **'When riders go online or offline.'**
  String get whenRidersGoOnlineOffline;

  /// No description provided for @productNews.
  ///
  /// In en, this message translates to:
  /// **'Product news'**
  String get productNews;

  /// No description provided for @tipsNewCeffloFeatures.
  ///
  /// In en, this message translates to:
  /// **'Tips and new Cefflo features.'**
  String get tipsNewCeffloFeatures;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @navy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get navy;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// No description provided for @yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get yellow;

  /// No description provided for @orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// No description provided for @black.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get black;

  /// No description provided for @accentColour.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get accentColour;

  /// No description provided for @chooseAccentColourApp.
  ///
  /// In en, this message translates to:
  /// **'Choose the accent colour for the app.'**
  String get chooseAccentColourApp;

  /// No description provided for @hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hue;

  /// No description provided for @lightness.
  ///
  /// In en, this message translates to:
  /// **'Lightness'**
  String get lightness;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @wereHereHelp.
  ///
  /// In en, this message translates to:
  /// **'We’re here to help'**
  String get wereHereHelp;

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get howCanWeHelp;

  /// No description provided for @searchHelpArticlesTopics.
  ///
  /// In en, this message translates to:
  /// **'Search for help, articles or topics...'**
  String get searchHelpArticlesTopics;

  /// No description provided for @helpCentre2.
  ///
  /// In en, this message translates to:
  /// **'Help Centre'**
  String get helpCentre2;

  /// No description provided for @browseArticlesGuidesFaqs.
  ///
  /// In en, this message translates to:
  /// **'Browse articles, guides and FAQs'**
  String get browseArticlesGuidesFaqs;

  /// No description provided for @contactSupport2.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport2;

  /// No description provided for @chatSendSupportRequest.
  ///
  /// In en, this message translates to:
  /// **'Chat or send a support request'**
  String get chatSendSupportRequest;

  /// No description provided for @popularTopics.
  ///
  /// In en, this message translates to:
  /// **'Popular Topics'**
  String get popularTopics;

  /// No description provided for @accountSecurity2.
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountSecurity2;

  /// No description provided for @loginProfileSecuritySettings.
  ///
  /// In en, this message translates to:
  /// **'Login, profile, security settings'**
  String get loginProfileSecuritySettings;

  /// No description provided for @ordersDelivery.
  ///
  /// In en, this message translates to:
  /// **'Orders & Delivery'**
  String get ordersDelivery;

  /// No description provided for @orderManagementDeliveryIssues.
  ///
  /// In en, this message translates to:
  /// **'Order management, delivery issues'**
  String get orderManagementDeliveryIssues;

  /// No description provided for @ridersTeam.
  ///
  /// In en, this message translates to:
  /// **'Riders & Team'**
  String get ridersTeam;

  /// No description provided for @riderInvitesApprovalsTeamAccess.
  ///
  /// In en, this message translates to:
  /// **'Rider invites, approvals, team access'**
  String get riderInvitesApprovalsTeamAccess;

  /// No description provided for @subscriptionBilling.
  ///
  /// In en, this message translates to:
  /// **'Subscription & Billing'**
  String get subscriptionBilling;

  /// No description provided for @plansPaymentsInvoices.
  ///
  /// In en, this message translates to:
  /// **'Plans, payments, invoices'**
  String get plansPaymentsInvoices;

  /// No description provided for @appGuides.
  ///
  /// In en, this message translates to:
  /// **'App Guides'**
  String get appGuides;

  /// No description provided for @stepByStepTutorials.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step tutorials'**
  String get stepByStepTutorials;

  /// No description provided for @findAnswers.
  ///
  /// In en, this message translates to:
  /// **'Find answers'**
  String get findAnswers;

  /// No description provided for @searchOurHelpCentreBrowseTopics.
  ///
  /// In en, this message translates to:
  /// **'Search our help centre or browse topics below.'**
  String get searchOurHelpCentreBrowseTopics;

  /// No description provided for @searchHelpEGZonesRiders.
  ///
  /// In en, this message translates to:
  /// **'Search for help, e.g. zones, riders...'**
  String get searchHelpEGZonesRiders;

  /// No description provided for @browseTopics.
  ///
  /// In en, this message translates to:
  /// **'Browse topics'**
  String get browseTopics;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get gettingStarted;

  /// No description provided for @setUpAccountBusiness.
  ///
  /// In en, this message translates to:
  /// **'Set up your account and business'**
  String get setUpAccountBusiness;

  /// No description provided for @manageOrdersRunsZones.
  ///
  /// In en, this message translates to:
  /// **'Manage orders, runs and zones'**
  String get manageOrdersRunsZones;

  /// No description provided for @zonesRiders.
  ///
  /// In en, this message translates to:
  /// **'Zones & Riders'**
  String get zonesRiders;

  /// No description provided for @coverageRidersDispatch.
  ///
  /// In en, this message translates to:
  /// **'Coverage, riders and dispatch'**
  String get coverageRidersDispatch;

  /// No description provided for @profileSecuritySettings.
  ///
  /// In en, this message translates to:
  /// **'Profile, security and settings'**
  String get profileSecuritySettings;

  /// No description provided for @plansPaymentsInvoices2.
  ///
  /// In en, this message translates to:
  /// **'Plans, payments and invoices'**
  String get plansPaymentsInvoices2;

  /// No description provided for @popularQuestions.
  ///
  /// In en, this message translates to:
  /// **'Popular Questions'**
  String get popularQuestions;

  /// No description provided for @howDoICreateDeliveryZone.
  ///
  /// In en, this message translates to:
  /// **'How do I create a delivery zone?'**
  String get howDoICreateDeliveryZone;

  /// No description provided for @howDoIAddRider.
  ///
  /// In en, this message translates to:
  /// **'How do I add a rider?'**
  String get howDoIAddRider;

  /// No description provided for @canIChangeMyPlanLater.
  ///
  /// In en, this message translates to:
  /// **'Can I change my plan later?'**
  String get canIChangeMyPlanLater;

  /// No description provided for @howDoesRouteOptimizationWork.
  ///
  /// In en, this message translates to:
  /// **'How does route optimization work?'**
  String get howDoesRouteOptimizationWork;

  /// No description provided for @whereCanMyCustomersTrackTheir.
  ///
  /// In en, this message translates to:
  /// **'Where can my customers track their orders?'**
  String get whereCanMyCustomersTrackTheir;

  /// No description provided for @viewingAllQuestions.
  ///
  /// In en, this message translates to:
  /// **'Viewing all questions'**
  String get viewingAllQuestions;

  /// No description provided for @sendingSupportRequestsFromAppNot.
  ///
  /// In en, this message translates to:
  /// **'Sending support requests from the app is not connected yet.'**
  String get sendingSupportRequestsFromAppNot;

  /// No description provided for @wereHereHelp2.
  ///
  /// In en, this message translates to:
  /// **'We’re here to help.'**
  String get wereHereHelp2;

  /// No description provided for @getTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in touch'**
  String get getTouch;

  /// No description provided for @tellUsAboutIssueOurTeam.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your issue and our team will get back to you.'**
  String get tellUsAboutIssueOurTeam;

  /// No description provided for @issueCategory.
  ///
  /// In en, this message translates to:
  /// **'Issue Category'**
  String get issueCategory;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategory;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @brieflyDescribeIssue.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe your issue'**
  String get brieflyDescribeIssue;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @tellUsMoreAboutIssue.
  ///
  /// In en, this message translates to:
  /// **'Tell us more about your issue...'**
  String get tellUsMoreAboutIssue;

  /// No description provided for @addScreenshotsOptional.
  ///
  /// In en, this message translates to:
  /// **'Add Screenshots (Optional)'**
  String get addScreenshotsOptional;

  /// No description provided for @pngJpgUp10mbEach.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG up to 10MB each'**
  String get pngJpgUp10mbEach;

  /// No description provided for @tapAttachImages.
  ///
  /// In en, this message translates to:
  /// **'Tap to attach images'**
  String get tapAttachImages;

  /// No description provided for @whereWeWillReply.
  ///
  /// In en, this message translates to:
  /// **'Where we will reply to you.'**
  String get whereWeWillReply;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get contactEmail;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @sendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Sending your request'**
  String get sendingRequest;

  /// No description provided for @supportRequestHasBeenSent.
  ///
  /// In en, this message translates to:
  /// **'Your support request has been sent.'**
  String get supportRequestHasBeenSent;

  /// No description provided for @ourSupportTeamWillGetBack.
  ///
  /// In en, this message translates to:
  /// **'ⓘ Our support team will get back to you as soon as possible.'**
  String get ourSupportTeamWillGetBack;

  /// No description provided for @trustTransparency.
  ///
  /// In en, this message translates to:
  /// **'Trust & Transparency'**
  String get trustTransparency;

  /// No description provided for @wereCommittedProtectingDataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'We’re committed to protecting your data and your privacy.'**
  String get wereCommittedProtectingDataPrivacy;

  /// No description provided for @termsThatGuideUseCefflo.
  ///
  /// In en, this message translates to:
  /// **'The terms that guide your use of Cefflo.'**
  String get termsThatGuideUseCefflo;

  /// No description provided for @lastUpdated12Sep2026.
  ///
  /// In en, this message translates to:
  /// **'Last updated: 12 Sep 2026'**
  String get lastUpdated12Sep2026;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'On this page'**
  String get page;

  /// No description provided for @t1Introduction2InformationWeCollect.
  ///
  /// In en, this message translates to:
  /// **'1.  Introduction\n2.  Information We Collect\n3.  How We Use Your Information\n4.  Data Sharing\n5.  Data Security\n6.  Your Rights\n7.  Cookies and Tracking Technologies\n8.  Changes to This Policy\n9.  Contact Us'**
  String get t1Introduction2InformationWeCollect;

  /// No description provided for @t1AcceptanceTerms2AccountResponsibilities.
  ///
  /// In en, this message translates to:
  /// **'1.  Acceptance of Terms\n2.  Account Responsibilities\n3.  Acceptable Use\n4.  Subscription and Billing\n5.  Intellectual Property\n6.  Service Availability\n7.  Limitation of Liability\n8.  Changes to These Terms\n9.  Contact Us'**
  String get t1AcceptanceTerms2AccountResponsibilities;

  /// No description provided for @t1Introduction.
  ///
  /// In en, this message translates to:
  /// **'1. Introduction'**
  String get t1Introduction;

  /// No description provided for @t1AcceptanceTerms.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get t1AcceptanceTerms;

  /// No description provided for @ceffloWeUsOurValuesPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Cefflo (“we”, “us” or “our”) values your privacy. This policy explains how we collect, use, disclose and safeguard your information when you use our services.'**
  String get ceffloWeUsOurValuesPrivacy;

  /// No description provided for @byAccessingUsingCeffloAgreeThese.
  ///
  /// In en, this message translates to:
  /// **'By accessing or using Cefflo, you agree to these terms and to use the service responsibly in accordance with applicable laws.'**
  String get byAccessingUsingCeffloAgreeThese;

  /// No description provided for @t2InformationWeCollect.
  ///
  /// In en, this message translates to:
  /// **'2. Information We Collect'**
  String get t2InformationWeCollect;

  /// No description provided for @t2AccountResponsibilities.
  ///
  /// In en, this message translates to:
  /// **'2. Account Responsibilities'**
  String get t2AccountResponsibilities;

  /// No description provided for @weCollectInformationThatProvideDirectly.
  ///
  /// In en, this message translates to:
  /// **'We collect information that you provide directly to us, together with limited operational data needed to deliver and improve the service.'**
  String get weCollectInformationThatProvideDirectly;

  /// No description provided for @responsibleMaintainingAccurateAccountInformationProtecting.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for maintaining accurate account information and protecting access to your account.'**
  String get responsibleMaintainingAccurateAccountInformationProtecting;

  /// No description provided for @moreOrdersLessWorkSmootherDelivery.
  ///
  /// In en, this message translates to:
  /// **'More orders. Less work. A smoother delivery day.'**
  String get moreOrdersLessWorkSmootherDelivery;

  /// No description provided for @ourPurpose.
  ///
  /// In en, this message translates to:
  /// **'Our purpose'**
  String get ourPurpose;

  /// No description provided for @operateTodayGrowTomorrow2.
  ///
  /// In en, this message translates to:
  /// **'Operate Today. Grow Tomorrow.'**
  String get operateTodayGrowTomorrow2;

  /// No description provided for @localSameDayDeliveryOperatingSystem.
  ///
  /// In en, this message translates to:
  /// **'A local same-day delivery operating system built for businesses.'**
  String get localSameDayDeliveryOperatingSystem;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get appInformation;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy2.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy2;

  /// No description provided for @readPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read policy'**
  String get readPolicy;

  /// No description provided for @termsService2.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsService2;

  /// No description provided for @readTerms.
  ///
  /// In en, this message translates to:
  /// **'Read terms'**
  String get readTerms;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @markUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get markUnread;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markRead;

  /// No description provided for @youreAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get youreAllCaughtUp;

  /// No description provided for @enterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get enterValidEmailAddress;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequired;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @scanJoin.
  ///
  /// In en, this message translates to:
  /// **'Scan to join'**
  String get scanJoin;

  /// No description provided for @invitedPersonCanScanCodeOpen.
  ///
  /// In en, this message translates to:
  /// **'The invited person can scan this code to open the invitation.'**
  String get invitedPersonCanScanCodeOpen;

  /// No description provided for @generateInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Generate invite link'**
  String get generateInviteLink;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @inviteRidersBusiness.
  ///
  /// In en, this message translates to:
  /// **'Invite riders to your business'**
  String get inviteRidersBusiness;

  /// No description provided for @inviteTeamMember2.
  ///
  /// In en, this message translates to:
  /// **'Invite a team member'**
  String get inviteTeamMember2;

  /// No description provided for @theyOpenLinkJoinTeamComplete.
  ///
  /// In en, this message translates to:
  /// **'They open the link to join your team and complete their profile, vehicle and documents.'**
  String get theyOpenLinkJoinTeamComplete;

  /// No description provided for @theyOpenLinkHelpRunDeliveries.
  ///
  /// In en, this message translates to:
  /// **'They open the link to help run deliveries and manage orders.'**
  String get theyOpenLinkHelpRunDeliveries;

  /// No description provided for @riderName.
  ///
  /// In en, this message translates to:
  /// **'Rider name'**
  String get riderName;

  /// No description provided for @operatorText.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operatorText;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @ownerAccessFullBusinessOwnershipIncluding.
  ///
  /// In en, this message translates to:
  /// **'Owner access is full business ownership, including billing and team management.'**
  String get ownerAccessFullBusinessOwnershipIncluding;

  /// No description provided for @invitationLink.
  ///
  /// In en, this message translates to:
  /// **'Invitation link'**
  String get invitationLink;

  /// No description provided for @showQrCode.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get showQrCode;

  /// No description provided for @scanOpenInvitation.
  ///
  /// In en, this message translates to:
  /// **'Scan to open the invitation'**
  String get scanOpenInvitation;

  /// No description provided for @linkShownOnlyOnceExpires7.
  ///
  /// In en, this message translates to:
  /// **'This link is shown only once and expires in 7 days. Invited riders appear in your Riders list as Pending Review once they complete registration.'**
  String get linkShownOnlyOnceExpires7;

  /// No description provided for @linkShownOnlyOnceExpires72.
  ///
  /// In en, this message translates to:
  /// **'This link is shown only once and expires in 7 days. Invited team members appear in your Team list once they accept.'**
  String get linkShownOnlyOnceExpires72;

  /// No description provided for @backSettings.
  ///
  /// In en, this message translates to:
  /// **'Back to Settings'**
  String get backSettings;

  /// No description provided for @active2.
  ///
  /// In en, this message translates to:
  /// **'{def}, {style}, active'**
  String active2(Object def, Object style);

  /// No description provided for @zoneOrdersRiders.
  ///
  /// In en, this message translates to:
  /// **'{orders, plural, =1{1 order} other{{orders} orders}} · {riders, plural, =1{1 rider} other{{riders} riders}}'**
  String zoneOrdersRiders(int orders, int riders);

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonth;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get perYear;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get roleOperator;

  /// No description provided for @tagFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get tagFood;

  /// No description provided for @tagFashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get tagFashion;

  /// No description provided for @tagBeauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get tagBeauty;

  /// No description provided for @tagGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get tagGifts;

  /// No description provided for @locatingBusinessAddress.
  ///
  /// In en, this message translates to:
  /// **'Locating your business address…'**
  String get locatingBusinessAddress;

  /// No description provided for @businessAddressLocated.
  ///
  /// In en, this message translates to:
  /// **'Business address located'**
  String get businessAddressLocated;

  /// No description provided for @pickupLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Your pickup location is required. We could not locate your business address; make sure it is complete, then try again.'**
  String get pickupLocationRequired;

  /// No description provided for @tryLocatingAgain.
  ///
  /// In en, this message translates to:
  /// **'Try locating again'**
  String get tryLocatingAgain;

  /// No description provided for @helperText.
  ///
  /// In en, this message translates to:
  /// **'Helper'**
  String get helperText;

  /// No description provided for @operatorRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Help manage daily delivery operations. Requires a Vendor account.'**
  String get operatorRoleDescription;

  /// No description provided for @helperRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Help prepare, pack and hand over orders. Uses the Cefflo Vendor app.'**
  String get helperRoleDescription;

  /// No description provided for @ownerCanRunAlone.
  ///
  /// In en, this message translates to:
  /// **'You can run your business as the Owner alone. Operators and Helpers are optional.'**
  String get ownerCanRunAlone;

  /// No description provided for @helperWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Helper'**
  String get helperWorkspaceTitle;

  /// No description provided for @toPrepare.
  ///
  /// In en, this message translates to:
  /// **'To prepare'**
  String get toPrepare;

  /// No description provided for @stagePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get stagePreparing;

  /// No description provided for @stagePacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get stagePacked;

  /// No description provided for @stageReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get stageReady;

  /// No description provided for @startPreparing.
  ///
  /// In en, this message translates to:
  /// **'Start preparing'**
  String get startPreparing;

  /// No description provided for @markPacked.
  ///
  /// In en, this message translates to:
  /// **'Mark packed'**
  String get markPacked;

  /// No description provided for @markReady.
  ///
  /// In en, this message translates to:
  /// **'Mark ready'**
  String get markReady;

  /// No description provided for @readyForHandover.
  ///
  /// In en, this message translates to:
  /// **'Ready for handover'**
  String get readyForHandover;

  /// No description provided for @handoverTo.
  ///
  /// In en, this message translates to:
  /// **'Hand over to {rider}'**
  String handoverTo(String rider);

  /// No description provided for @runStop.
  ///
  /// In en, this message translates to:
  /// **'{run} · stop {stop}'**
  String runStop(String run, String stop);

  /// No description provided for @noTasksInStage.
  ///
  /// In en, this message translates to:
  /// **'No orders here.'**
  String get noTasksInStage;

  /// No description provided for @newTasksAppearHere.
  ///
  /// In en, this message translates to:
  /// **'New orders to prepare will appear here.'**
  String get newTasksAppearHere;

  /// No description provided for @stageSorted.
  ///
  /// In en, this message translates to:
  /// **'Sorted'**
  String get stageSorted;

  /// No description provided for @markSorted.
  ///
  /// In en, this message translates to:
  /// **'Mark sorted'**
  String get markSorted;

  /// No description provided for @packingNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Packing not confirmed yet'**
  String get packingNotConfirmed;

  /// No description provided for @confirmPackingGroup.
  ///
  /// In en, this message translates to:
  /// **'Confirm packing · {zone} · {done} / {total} packed'**
  String confirmPackingGroup(String zone, String done, String total);

  /// No description provided for @confirmSortingGroup.
  ///
  /// In en, this message translates to:
  /// **'Confirm sorting · {zone} · {done} / {total} sorted'**
  String confirmSortingGroup(String zone, String done, String total);

  /// No description provided for @pickedUpBy.
  ///
  /// In en, this message translates to:
  /// **'Picked up • {rider} • {time}'**
  String pickedUpBy(String rider, String time);

  /// No description provided for @stagePickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get stagePickedUp;

  /// No description provided for @noZone.
  ///
  /// In en, this message translates to:
  /// **'No zone'**
  String get noZone;

  /// No description provided for @handoverToProvider.
  ///
  /// In en, this message translates to:
  /// **'Hand over to {provider}'**
  String handoverToProvider(String provider);

  /// No description provided for @operatorAccess.
  ///
  /// In en, this message translates to:
  /// **'Operator Access'**
  String get operatorAccess;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInStoreOperations.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your store operations'**
  String get signInStoreOperations;

  /// No description provided for @operatorRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Your Operator request has been sent. You can start once the business owner approves it.'**
  String get operatorRequestPending;

  /// No description provided for @helperRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Your Helper request has been sent. You can start once the business owner approves it.'**
  String get helperRequestPending;

  /// No description provided for @noOperatorAccessYet.
  ///
  /// In en, this message translates to:
  /// **'This account has no Operator access yet. Open the invite link or scan the QR code from the business owner, then send your join request.'**
  String get noOperatorAccessYet;

  /// No description provided for @helperAccess.
  ///
  /// In en, this message translates to:
  /// **'Helper Access'**
  String get helperAccess;

  /// No description provided for @signInPreparationTasks.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your preparation tasks'**
  String get signInPreparationTasks;

  /// No description provided for @noHelperAccessYet.
  ///
  /// In en, this message translates to:
  /// **'This account has no Helper access yet. Open the invite link or scan the QR code from the business owner, then send your join request.'**
  String get noHelperAccessYet;

  /// No description provided for @hwPreparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get hwPreparation;

  /// No description provided for @hwZones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get hwZones;

  /// No description provided for @hwPacking.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get hwPacking;

  /// No description provided for @hwSorting.
  ///
  /// In en, this message translates to:
  /// **'Sorting'**
  String get hwSorting;

  /// No description provided for @hwMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get hwMore;

  /// No description provided for @hwOrders.
  ///
  /// In en, this message translates to:
  /// **'orders'**
  String get hwOrders;

  /// No description provided for @hwItems.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get hwItems;

  /// No description provided for @hwRequiredItems.
  ///
  /// In en, this message translates to:
  /// **'Required Items'**
  String get hwRequiredItems;

  /// No description provided for @hwNOrders.
  ///
  /// In en, this message translates to:
  /// **'{n} orders'**
  String hwNOrders(int n);

  /// No description provided for @hwNItems.
  ///
  /// In en, this message translates to:
  /// **'{n} items'**
  String hwNItems(int n);

  /// No description provided for @hwNItem.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 item} other{{n} items}}'**
  String hwNItem(int n);

  /// No description provided for @hwPacked.
  ///
  /// In en, this message translates to:
  /// **'packed'**
  String get hwPacked;

  /// No description provided for @hwPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get hwPending;

  /// No description provided for @hwPackingStatus.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get hwPackingStatus;

  /// No description provided for @hwPackedStatus.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get hwPackedStatus;

  /// No description provided for @hwSortingStatus.
  ///
  /// In en, this message translates to:
  /// **'Sorting'**
  String get hwSortingStatus;

  /// No description provided for @hwSortedStatus.
  ///
  /// In en, this message translates to:
  /// **'Sorted'**
  String get hwSortedStatus;

  /// No description provided for @hwReadyStatus.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get hwReadyStatus;

  /// No description provided for @hwSlideConfirmPickup.
  ///
  /// In en, this message translates to:
  /// **'Slide to Confirm Pickup'**
  String get hwSlideConfirmPickup;

  /// No description provided for @hwPickupTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup Time'**
  String get hwPickupTime;

  /// No description provided for @hwReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get hwReadyForPickup;

  /// No description provided for @hwZoneReady.
  ///
  /// In en, this message translates to:
  /// **'This zone is ready for rider pickup.'**
  String get hwZoneReady;

  /// No description provided for @hwPickupRider.
  ///
  /// In en, this message translates to:
  /// **'PICKUP RIDER'**
  String get hwPickupRider;

  /// No description provided for @hwRiderNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Rider not assigned yet'**
  String get hwRiderNotAssigned;

  /// No description provided for @hwMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get hwMotorcycle;

  /// No description provided for @hwCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get hwCar;

  /// No description provided for @hwVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get hwVan;

  /// No description provided for @hwNoZoneToPack.
  ///
  /// In en, this message translates to:
  /// **'No zone to pack right now.'**
  String get hwNoZoneToPack;

  /// No description provided for @hwNoZoneToSort.
  ///
  /// In en, this message translates to:
  /// **'No zone to sort right now.'**
  String get hwNoZoneToSort;

  /// No description provided for @hwNoWork.
  ///
  /// In en, this message translates to:
  /// **'No preparation work right now.'**
  String get hwNoWork;

  /// No description provided for @hwPackFirst.
  ///
  /// In en, this message translates to:
  /// **'Confirm packing for this zone first.'**
  String get hwPackFirst;

  /// No description provided for @hwExternalProvider.
  ///
  /// In en, this message translates to:
  /// **'External provider'**
  String get hwExternalProvider;

  /// No description provided for @hwPasswordSecurity.
  ///
  /// In en, this message translates to:
  /// **'Password & Security'**
  String get hwPasswordSecurity;

  /// No description provided for @hwNotifNewWork.
  ///
  /// In en, this message translates to:
  /// **'New preparation work'**
  String get hwNotifNewWork;

  /// No description provided for @hwNotifNewWorkSub.
  ///
  /// In en, this message translates to:
  /// **'When new orders are added to your workload.'**
  String get hwNotifNewWorkSub;

  /// No description provided for @hwNotifChanges.
  ///
  /// In en, this message translates to:
  /// **'Workload changes'**
  String get hwNotifChanges;

  /// No description provided for @hwNotifChangesSub.
  ///
  /// In en, this message translates to:
  /// **'When tomorrow\'s or today\'s workload is updated.'**
  String get hwNotifChangesSub;

  /// No description provided for @ntNewCustomerOrder.
  ///
  /// In en, this message translates to:
  /// **'New customer order {ref}'**
  String ntNewCustomerOrder(Object ref);

  /// No description provided for @ntNewCustomerOrderBody.
  ///
  /// In en, this message translates to:
  /// **'A customer placed an order from your order page.'**
  String get ntNewCustomerOrderBody;

  /// No description provided for @ntDeliveryIssue.
  ///
  /// In en, this message translates to:
  /// **'Delivery issue on {ref}'**
  String ntDeliveryIssue(Object ref);

  /// No description provided for @ntRunDeclined.
  ///
  /// In en, this message translates to:
  /// **'A rider declined a run'**
  String get ntRunDeclined;

  /// No description provided for @ntRunDeclinedBody.
  ///
  /// In en, this message translates to:
  /// **'Reassign the orders so they can go out.'**
  String get ntRunDeclinedBody;

  /// No description provided for @ntRiderJoined.
  ///
  /// In en, this message translates to:
  /// **'A rider accepted your invitation'**
  String get ntRiderJoined;

  /// No description provided for @ntRiderJoinedBody.
  ///
  /// In en, this message translates to:
  /// **'Review and approve them before assigning runs.'**
  String get ntRiderJoinedBody;

  /// No description provided for @ntRunCompleted.
  ///
  /// In en, this message translates to:
  /// **'Run completed'**
  String get ntRunCompleted;

  /// No description provided for @ntRunCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'Every stop in the run is finished.'**
  String get ntRunCompletedBody;

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
  /// **'Show alerts while Cefflo is open. Everything is still kept in the notification centre.'**
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

  /// No description provided for @ntDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get ntDismiss;

  /// No description provided for @linkNoLongerValid.
  ///
  /// In en, this message translates to:
  /// **'This link is no longer valid'**
  String get linkNoLongerValid;

  /// No description provided for @linkExpiredOrUsedRequestNew.
  ///
  /// In en, this message translates to:
  /// **'It has expired or was already used. Request a new verification email, or a new password reset link.'**
  String get linkExpiredOrUsedRequestNew;

  /// No description provided for @sendNewResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send a new reset link'**
  String get sendNewResetLink;

  /// No description provided for @supportSendOpensEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Send opens your email app with this message addressed to support@cefflo.com. Add screenshots there if they help.'**
  String get supportSendOpensEmailApp;

  /// No description provided for @writeMessageFirst.
  ///
  /// In en, this message translates to:
  /// **'Write a message first.'**
  String get writeMessageFirst;

  /// No description provided for @emailApp.
  ///
  /// In en, this message translates to:
  /// **'your email app'**
  String get emailApp;

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

  /// No description provided for @otpRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get otpRecoveryTitle;

  /// No description provided for @connectedSources.
  ///
  /// In en, this message translates to:
  /// **'Connected sources'**
  String get connectedSources;

  /// No description provided for @noConnectedSourcesYet.
  ///
  /// In en, this message translates to:
  /// **'No connected sources yet. Your connected Google Sheets and Drive files will appear here.'**
  String get noConnectedSourcesYet;

  /// No description provided for @createOrder.
  ///
  /// In en, this message translates to:
  /// **'Create an order'**
  String get createOrder;

  /// No description provided for @howStepSource.
  ///
  /// In en, this message translates to:
  /// **'Pick a source'**
  String get howStepSource;

  /// No description provided for @howStepFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get howStepFile;

  /// No description provided for @howStepMap.
  ///
  /// In en, this message translates to:
  /// **'Match columns'**
  String get howStepMap;

  /// No description provided for @howStepImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get howStepImport;

  /// No description provided for @importExcelCsv.
  ///
  /// In en, this message translates to:
  /// **'Excel / CSV'**
  String get importExcelCsv;

  /// No description provided for @importExcelCsvHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a CSV or Excel file (.xlsx)'**
  String get importExcelCsvHint;

  /// No description provided for @connectGoogle.
  ///
  /// In en, this message translates to:
  /// **'Connect Google'**
  String get connectGoogle;

  /// No description provided for @googleConnectPending.
  ///
  /// In en, this message translates to:
  /// **'Connecting Google isn\'t available yet. For now, download the sheet as CSV or .xlsx and use Excel / CSV.'**
  String get googleConnectPending;

  /// No description provided for @importReadingFile.
  ///
  /// In en, this message translates to:
  /// **'Reading the file'**
  String get importReadingFile;

  /// No description provided for @importReadFailed.
  ///
  /// In en, this message translates to:
  /// **'This file couldn\'t be read. Use a CSV or .xlsx file with a header row.'**
  String get importReadFailed;

  /// No description provided for @importNoRows.
  ///
  /// In en, this message translates to:
  /// **'No order rows were found under the header row.'**
  String get importNoRows;

  /// No description provided for @importMatchHint.
  ///
  /// In en, this message translates to:
  /// **'We matched what we could. Check each field and choose the right column.'**
  String get importMatchHint;

  /// No description provided for @importNotMapped.
  ///
  /// In en, this message translates to:
  /// **'Not matched'**
  String get importNotMapped;

  /// No description provided for @importRequiredTag.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get importRequiredTag;

  /// No description provided for @importMatchRequired.
  ///
  /// In en, this message translates to:
  /// **'Match the required fields: {fields}'**
  String importMatchRequired(Object fields);

  /// No description provided for @importContinueReview.
  ///
  /// In en, this message translates to:
  /// **'Review rows'**
  String get importContinueReview;

  /// No description provided for @importReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get importReviewTitle;

  /// No description provided for @importRowsDetected.
  ///
  /// In en, this message translates to:
  /// **'Rows detected'**
  String get importRowsDetected;

  /// No description provided for @importRowsValid.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get importRowsValid;

  /// No description provided for @importRowsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Need attention'**
  String get importRowsInvalid;

  /// No description provided for @importMappedFields.
  ///
  /// In en, this message translates to:
  /// **'Matched fields'**
  String get importMappedFields;

  /// No description provided for @importRowMissing.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: missing {fields}'**
  String importRowMissing(Object row, Object fields);

  /// No description provided for @importInvalidNote.
  ///
  /// In en, this message translates to:
  /// **'Rows that need attention won\'t be imported. Fix them in the file and import it again.'**
  String get importInvalidNote;

  /// No description provided for @importCountOrders.
  ///
  /// In en, this message translates to:
  /// **'Import {count} orders'**
  String importCountOrders(Object count);

  /// No description provided for @importingOrders.
  ///
  /// In en, this message translates to:
  /// **'Importing orders'**
  String get importingOrders;

  /// No description provided for @importResultDone.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get importResultDone;

  /// No description provided for @importResultPartial.
  ///
  /// In en, this message translates to:
  /// **'Import partly complete'**
  String get importResultPartial;

  /// No description provided for @importResultNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing was imported'**
  String get importResultNone;

  /// No description provided for @importCommittedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders created'**
  String importCommittedCount(Object count);

  /// No description provided for @importRejectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rows rejected by Cefflo'**
  String importRejectedCount(Object count);

  /// No description provided for @importSkippedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rows not sent (need attention)'**
  String importSkippedCount(Object count);

  /// No description provided for @importRowReason.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {reason}'**
  String importRowReason(Object row, Object reason);

  /// No description provided for @importViewOrders.
  ///
  /// In en, this message translates to:
  /// **'View orders'**
  String get importViewOrders;

  /// No description provided for @importAnotherFile.
  ///
  /// In en, this message translates to:
  /// **'Import another file'**
  String get importAnotherFile;

  /// No description provided for @importChangeFile.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get importChangeFile;

  /// No description provided for @importBackToMatch.
  ///
  /// In en, this message translates to:
  /// **'Back to matching'**
  String get importBackToMatch;

  /// No description provided for @importFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer phone'**
  String get importFieldPhone;

  /// No description provided for @importFieldZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get importFieldZone;

  /// No description provided for @importFieldItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get importFieldItems;

  /// No description provided for @importFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get importFieldNotes;

  /// No description provided for @importKpiCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get importKpiCreated;

  /// No description provided for @importKpiRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get importKpiRejected;

  /// No description provided for @importKpiNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get importKpiNotSent;

  /// No description provided for @appearanceStandard.
  ///
  /// In en, this message translates to:
  /// **'Cefflo standard'**
  String get appearanceStandard;

  /// No description provided for @appearanceBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get appearanceBackground;

  /// No description provided for @appearancePlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get appearancePlain;

  /// No description provided for @appearanceGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get appearanceGradient;

  /// No description provided for @appearanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Appearance saved on this device.'**
  String get appearanceSaved;

  /// No description provided for @appearanceDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Applies to this device only. Tap Save to keep it.'**
  String get appearanceDeviceOnly;

  /// No description provided for @purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purple;

  /// No description provided for @yourInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Your invite link'**
  String get yourInviteLink;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Share message'**
  String get shareMessage;

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via'**
  String get shareVia;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyText;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get messageCopied;

  /// No description provided for @inviteMsgRider.
  ///
  /// In en, this message translates to:
  /// **'Hi, you\'re invited to join {business} as a rider. Register here: {link}'**
  String inviteMsgRider(Object business, Object link);

  /// No description provided for @inviteMsgTeam.
  ///
  /// In en, this message translates to:
  /// **'Hi, you\'re invited to join {business} on Cefflo. Open this link: {link}'**
  String inviteMsgTeam(Object business, Object link);

  /// No description provided for @noPendingRidersYet.
  ///
  /// In en, this message translates to:
  /// **'No pending riders yet.'**
  String get noPendingRidersYet;

  /// No description provided for @inviteShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Hi, you\'re invited to join {business}. Click the link below to register.'**
  String inviteShareMessage(Object business);

  /// No description provided for @resetLink.
  ///
  /// In en, this message translates to:
  /// **'Reset link'**
  String get resetLink;

  /// No description provided for @resetLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset this invite link?'**
  String get resetLinkTitle;

  /// No description provided for @resetLinkBody.
  ///
  /// In en, this message translates to:
  /// **'The current link stops working immediately. Share the new link with anyone who hasn\'t joined yet.'**
  String get resetLinkBody;

  /// No description provided for @linkResetDone.
  ///
  /// In en, this message translates to:
  /// **'A new invite link is ready.'**
  String get linkResetDone;

  /// No description provided for @inviteLinkPermanent.
  ///
  /// In en, this message translates to:
  /// **'This link stays the same until you reset it. Everyone who joins waits for your approval.'**
  String get inviteLinkPermanent;

  /// No description provided for @moreText.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreText;

  /// No description provided for @scanToJoinBody.
  ///
  /// In en, this message translates to:
  /// **'Scan with a phone camera to open the invitation.'**
  String get scanToJoinBody;

  /// No description provided for @joinRequests.
  ///
  /// In en, this message translates to:
  /// **'Join requests'**
  String get joinRequests;

  /// No description provided for @approveText.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveText;

  /// No description provided for @requestApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved.'**
  String get requestApproved;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected.'**
  String get requestRejected;

  /// No description provided for @riderApproved.
  ///
  /// In en, this message translates to:
  /// **'Rider approved.'**
  String get riderApproved;

  /// No description provided for @riderRejected.
  ///
  /// In en, this message translates to:
  /// **'Rider rejected.'**
  String get riderRejected;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join {business}'**
  String joinTitle(Object business);

  /// No description provided for @joinBody.
  ///
  /// In en, this message translates to:
  /// **'Complete your details. The business approves every request before you get access.'**
  String get joinBody;

  /// No description provided for @joinSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get joinSubmit;

  /// No description provided for @joinPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get joinPendingTitle;

  /// No description provided for @joinPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your request was sent to {business}. You\'ll get access once it\'s approved.'**
  String joinPendingBody(Object business);

  /// No description provided for @joinLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This invite link is no longer valid. Ask the business for the new link.'**
  String get joinLinkUnavailable;

  /// No description provided for @messageCopiedPasteIn.
  ///
  /// In en, this message translates to:
  /// **'Message copied. Paste it in {app}.'**
  String messageCopiedPasteIn(Object app);

  /// No description provided for @shareInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Share invite link'**
  String get shareInviteLink;

  /// No description provided for @operatingAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Operating area'**
  String get operatingAreaLabel;

  /// No description provided for @operatingAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Areas you deliver to, e.g. Bangsar, Mont Kiara'**
  String get operatingAreaHint;

  /// No description provided for @businessSaved.
  ///
  /// In en, this message translates to:
  /// **'Business details saved.'**
  String get businessSaved;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @photoFormat.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPG, PNG or WebP photo.'**
  String get photoFormat;

  /// No description provided for @photoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This photo is larger than 2 MB. Choose a smaller one.'**
  String get photoTooLarge;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get photoUpdated;

  /// No description provided for @photoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed.'**
  String get photoRemoved;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePhoto;

  /// No description provided for @emailChanged.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in email has changed.'**
  String get emailChanged;

  /// No description provided for @confirmCurrentEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your current email'**
  String get confirmCurrentEmail;

  /// No description provided for @confirmNewEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new email'**
  String get confirmNewEmail;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @changeEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a code to your current email and to the new one. Your email changes only after both are confirmed.'**
  String get changeEmailBody;

  /// No description provided for @newEmail.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get newEmail;

  /// No description provided for @sendCodes.
  ///
  /// In en, this message translates to:
  /// **'Send codes'**
  String get sendCodes;

  /// No description provided for @sameEmail.
  ///
  /// In en, this message translates to:
  /// **'This is already your email.'**
  String get sameEmail;

  /// No description provided for @subscriptionManagedTitle.
  ///
  /// In en, this message translates to:
  /// **'Managed by Cefflo'**
  String get subscriptionManagedTitle;

  /// No description provided for @subscriptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your plan details aren\'t available in the app yet. Contact Cefflo support for your current plan.'**
  String get subscriptionUnavailable;

  /// No description provided for @subscriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get subscriptionStatus;

  /// No description provided for @trialEnds.
  ///
  /// In en, this message translates to:
  /// **'Trial ends {date}'**
  String trialEnds(Object date);

  /// No description provided for @planQuestionSubject.
  ///
  /// In en, this message translates to:
  /// **'Subscription question'**
  String get planQuestionSubject;

  /// No description provided for @emailSupportTeam.
  ///
  /// In en, this message translates to:
  /// **'Email the Cefflo support team'**
  String get emailSupportTeam;

  /// No description provided for @yourStorefront.
  ///
  /// In en, this message translates to:
  /// **'Your storefront'**
  String get yourStorefront;

  /// No description provided for @storefrontPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get storefrontPublished;

  /// No description provided for @storefrontUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Not published'**
  String get storefrontUnpublished;

  /// No description provided for @storefrontUnpublishedNote.
  ///
  /// In en, this message translates to:
  /// **'Customers can\'t open this link until you publish your storefront.'**
  String get storefrontUnpublishedNote;

  /// No description provided for @storefrontPublishedNote.
  ///
  /// In en, this message translates to:
  /// **'Customers can open this link and order. It stays the same, so you can put it on your website or social media.'**
  String get storefrontPublishedNote;

  /// No description provided for @storefrontLink.
  ///
  /// In en, this message translates to:
  /// **'Storefront link'**
  String get storefrontLink;

  /// No description provided for @shareStorefront.
  ///
  /// In en, this message translates to:
  /// **'Share storefront'**
  String get shareStorefront;

  /// No description provided for @storefrontShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Order from {business} online:'**
  String storefrontShareMessage(Object business);

  /// No description provided for @scanToOrder.
  ///
  /// In en, this message translates to:
  /// **'Scan to order'**
  String get scanToOrder;

  /// No description provided for @scanToOrderBody.
  ///
  /// In en, this message translates to:
  /// **'Customers scan with a phone camera to open your storefront.'**
  String get scanToOrderBody;

  /// No description provided for @storefrontLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your storefront couldn\'t be loaded.'**
  String get storefrontLoadFailed;

  /// No description provided for @hoursSaved.
  ///
  /// In en, this message translates to:
  /// **'Business hours saved.'**
  String get hoursSaved;

  /// No description provided for @overnightHint.
  ///
  /// In en, this message translates to:
  /// **'Closes the next day'**
  String get overnightHint;

  /// No description provided for @open24h.
  ///
  /// In en, this message translates to:
  /// **'Open 24 hours'**
  String get open24h;

  /// No description provided for @photosMax5.
  ///
  /// In en, this message translates to:
  /// **'A product can have up to 5 photos.'**
  String get photosMax5;

  /// No description provided for @photoOver5mb.
  ///
  /// In en, this message translates to:
  /// **'This photo is larger than 5 MB after compression. Choose a smaller one.'**
  String get photoOver5mb;

  /// No description provided for @photoN.
  ///
  /// In en, this message translates to:
  /// **'Photo {n}'**
  String photoN(Object n);

  /// No description provided for @moveEarlier.
  ///
  /// In en, this message translates to:
  /// **'Move earlier'**
  String get moveEarlier;

  /// No description provided for @moveLater.
  ///
  /// In en, this message translates to:
  /// **'Move later'**
  String get moveLater;

  /// No description provided for @photosRules.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 photos · JPG, PNG or WebP · 5 MB each. The first photo is the cover.'**
  String get photosRules;

  /// No description provided for @subTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get subTrial;

  /// No description provided for @subActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subActive;

  /// No description provided for @subPastDue.
  ///
  /// In en, this message translates to:
  /// **'Payment overdue'**
  String get subPastDue;

  /// No description provided for @subSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get subSuspended;

  /// No description provided for @subCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get subCancelled;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to manage your business.'**
  String get signOutConfirmBody;

  /// No description provided for @yesSignOut.
  ///
  /// In en, this message translates to:
  /// **'Yes, sign out'**
  String get yesSignOut;

  /// No description provided for @heroTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This image is larger than 5 MB. Choose a smaller one.'**
  String get heroTooLarge;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(Object email);

  /// No description provided for @useAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use another account'**
  String get useAnotherAccount;

  /// No description provided for @alreadyPartOf.
  ///
  /// In en, this message translates to:
  /// **'You\'re already part of {business}.'**
  String alreadyPartOf(Object business);

  /// No description provided for @alreadyPartOfBody.
  ///
  /// In en, this message translates to:
  /// **'This account already has access. No new request was needed.'**
  String get alreadyPartOfBody;

  /// No description provided for @continueToApp.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueToApp;

  /// No description provided for @ntWebSoundPending.
  ///
  /// In en, this message translates to:
  /// **'In this browser version sound is not available yet. The Cefflo notification sound is still being designed; the phone app uses the device\'s alert sound for now.'**
  String get ntWebSoundPending;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Donuts, Drinks'**
  String get categoryHint;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose or type a category.'**
  String get categoryRequired;

  /// No description provided for @newCategoryChip.
  ///
  /// In en, this message translates to:
  /// **'New: {name}'**
  String newCategoryChip(Object name);

  /// No description provided for @unnamedTeamMember.
  ///
  /// In en, this message translates to:
  /// **'Team member'**
  String get unnamedTeamMember;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailAlreadyRegistered;

  /// No description provided for @productAddedToast.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully'**
  String get productAddedToast;

  /// No description provided for @productUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully'**
  String get productUpdatedToast;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMember;

  /// No description provided for @removeRider.
  ///
  /// In en, this message translates to:
  /// **'Remove rider'**
  String get removeRider;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your team?'**
  String removeMemberTitle(String name);

  /// No description provided for @removeMemberBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will lose access to this business and its permitted workspace.'**
  String removeMemberBody(String name);

  /// No description provided for @removeRiderTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} as a rider?'**
  String removeRiderTitle(String name);

  /// No description provided for @removeRiderBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will lose access to this business and can no longer receive new delivery assignments from this business.'**
  String removeRiderBody(String name);

  /// No description provided for @typeConfirmToContinue.
  ///
  /// In en, this message translates to:
  /// **'Type CONFIRM to continue.'**
  String get typeConfirmToContinue;

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemoved;

  /// No description provided for @riderRemoved.
  ///
  /// In en, this message translates to:
  /// **'Rider removed'**
  String get riderRemoved;

  /// No description provided for @riderHasActiveWorkCannotRemove.
  ///
  /// In en, this message translates to:
  /// **'This rider still has active deliveries. Finish or reassign them, then try again.'**
  String get riderHasActiveWorkCannotRemove;

  /// No description provided for @removalNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm the removal. Refresh and try again.'**
  String get removalNotConfirmed;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssue;

  /// No description provided for @reportIssueLead.
  ///
  /// In en, this message translates to:
  /// **'The order moves to Issue and appears in Need Attention.'**
  String get reportIssueLead;

  /// No description provided for @issueReported.
  ///
  /// In en, this message translates to:
  /// **'Issue reported.'**
  String get issueReported;

  /// No description provided for @couldNotReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Could not report issue: {error}'**
  String couldNotReportIssue(Object error);

  /// No description provided for @issueCustomerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Customer unreachable'**
  String get issueCustomerUnreachable;

  /// No description provided for @issueAddressProblem.
  ///
  /// In en, this message translates to:
  /// **'Address problem'**
  String get issueAddressProblem;

  /// No description provided for @issueAccessProblem.
  ///
  /// In en, this message translates to:
  /// **'Access problem'**
  String get issueAccessProblem;

  /// No description provided for @issueVendorNotReady.
  ///
  /// In en, this message translates to:
  /// **'Order not ready'**
  String get issueVendorNotReady;

  /// No description provided for @issueRiderUnableToProceed.
  ///
  /// In en, this message translates to:
  /// **'Rider unable to proceed'**
  String get issueRiderUnableToProceed;

  /// No description provided for @recoverDelivery.
  ///
  /// In en, this message translates to:
  /// **'Recover delivery'**
  String get recoverDelivery;

  /// No description provided for @recoverDeliveryLead.
  ///
  /// In en, this message translates to:
  /// **'Release the order from its rider so it can be planned again.'**
  String get recoverDeliveryLead;

  /// No description provided for @deliveryRecovered.
  ///
  /// In en, this message translates to:
  /// **'Order released for re-planning.'**
  String get deliveryRecovered;

  /// No description provided for @deliveryActivity.
  ///
  /// In en, this message translates to:
  /// **'Delivery activity'**
  String get deliveryActivity;

  /// No description provided for @noDeliveryActivity.
  ///
  /// In en, this message translates to:
  /// **'No delivery activity yet.'**
  String get noDeliveryActivity;

  /// No description provided for @customerTrackingLink.
  ///
  /// In en, this message translates to:
  /// **'Customer tracking link'**
  String get customerTrackingLink;

  /// No description provided for @customerTrackingLinkLead.
  ///
  /// In en, this message translates to:
  /// **'Send this link to your customer so they can follow the delivery.'**
  String get customerTrackingLinkLead;

  /// No description provided for @customerTrackingLinkOnce.
  ///
  /// In en, this message translates to:
  /// **'For security this link is shown only now. Copy or share it before closing.'**
  String get customerTrackingLinkOnce;

  /// No description provided for @keepLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep me logged in'**
  String get keepLoggedIn;

  /// No description provided for @lookingForRiders.
  ///
  /// In en, this message translates to:
  /// **'Looking for riders'**
  String get lookingForRiders;

  /// No description provided for @lookingForRidersOff.
  ///
  /// In en, this message translates to:
  /// **'Off. Only riders you invite can join.'**
  String get lookingForRidersOff;

  /// No description provided for @lookingForRidersOn.
  ///
  /// In en, this message translates to:
  /// **'On. Drivers can see your openings in Find Jobs.'**
  String get lookingForRidersOn;

  /// No description provided for @addOpening.
  ///
  /// In en, this message translates to:
  /// **'Add opening'**
  String get addOpening;

  /// No description provided for @postOpening.
  ///
  /// In en, this message translates to:
  /// **'Post opening'**
  String get postOpening;

  /// No description provided for @closeOpening.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeOpening;

  /// No description provided for @openingArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get openingArea;

  /// No description provided for @openingAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Taman Uda, Alor Setar'**
  String get openingAreaHint;

  /// No description provided for @openingDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get openingDays;

  /// No description provided for @openingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get openingStart;

  /// No description provided for @openingEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get openingEnd;

  /// No description provided for @openingVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get openingVehicle;

  /// No description provided for @openingPay.
  ///
  /// In en, this message translates to:
  /// **'Pay (RM)'**
  String get openingPay;

  /// No description provided for @openingPayUnit.
  ///
  /// In en, this message translates to:
  /// **'Per'**
  String get openingPayUnit;

  /// No description provided for @payShift.
  ///
  /// In en, this message translates to:
  /// **'shift'**
  String get payShift;

  /// No description provided for @payDrop.
  ///
  /// In en, this message translates to:
  /// **'drop'**
  String get payDrop;

  /// No description provided for @payHour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get payHour;

  /// No description provided for @openingRidersNeeded.
  ///
  /// In en, this message translates to:
  /// **'Riders needed'**
  String get openingRidersNeeded;

  /// No description provided for @openingRadius.
  ///
  /// In en, this message translates to:
  /// **'Rider radius: {km} km'**
  String openingRadius(String km);

  /// No description provided for @openingPosted.
  ///
  /// In en, this message translates to:
  /// **'Opening posted'**
  String get openingPosted;

  /// No description provided for @openingClosed.
  ///
  /// In en, this message translates to:
  /// **'Opening closed'**
  String get openingClosed;

  /// No description provided for @newOpening.
  ///
  /// In en, this message translates to:
  /// **'New opening'**
  String get newOpening;

  /// No description provided for @openingFixFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in the area, days, a valid time and pay.'**
  String get openingFixFields;

  /// No description provided for @turnOffHiringTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop looking for riders?'**
  String get turnOffHiringTitle;

  /// No description provided for @turnOffHiringBody.
  ///
  /// In en, this message translates to:
  /// **'All your open openings will close. Requests already sent stay in Pending.'**
  String get turnOffHiringBody;

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get turnOff;

  /// No description provided for @vehMotorbike.
  ///
  /// In en, this message translates to:
  /// **'Motorbike'**
  String get vehMotorbike;

  /// No description provided for @vehCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get vehCar;

  /// No description provided for @vehVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get vehVan;

  /// No description provided for @newOpeningSub.
  ///
  /// In en, this message translates to:
  /// **'Create an opening to find riders for your delivery runs.'**
  String get newOpeningSub;

  /// No description provided for @openingTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get openingTime;

  /// No description provided for @publishOpening.
  ///
  /// In en, this message translates to:
  /// **'Publish opening'**
  String get publishOpening;

  /// No description provided for @openingRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Rider radius'**
  String get openingRadiusLabel;

  /// No description provided for @openingPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get openingPayLabel;
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
