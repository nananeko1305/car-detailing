import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sr.dart';

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
    Locale('sr'),
  ];

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addFromPriceList.
  ///
  /// In en, this message translates to:
  /// **'Add from the price list'**
  String get addFromPriceList;

  /// No description provided for @addItemOrNote.
  ///
  /// In en, this message translates to:
  /// **'Add an item from the price list, or a note.'**
  String get addItemOrNote;

  /// No description provided for @addWorker.
  ///
  /// In en, this message translates to:
  /// **'Add worker'**
  String get addWorker;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get address;

  /// No description provided for @adminEarnings.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s earnings'**
  String adminEarnings(String name);

  /// No description provided for @agreedPrice.
  ///
  /// In en, this message translates to:
  /// **'Agreed price'**
  String get agreedPrice;

  /// No description provided for @alreadyDone.
  ///
  /// In en, this message translates to:
  /// **'Already done'**
  String get alreadyDone;

  /// No description provided for @alreadyDoneHint.
  ///
  /// In en, this message translates to:
  /// **'A client who came without booking'**
  String get alreadyDoneHint;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Bookings, wallet and earnings for the whole crew.'**
  String get appTagline;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Car Detailing'**
  String get appTitle;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Put away'**
  String get archive;

  /// No description provided for @archiveBody.
  ///
  /// In en, this message translates to:
  /// **'It is no longer offered for new jobs. Jobs that have it keep it.'**
  String get archiveBody;

  /// No description provided for @archiveCategoryQ.
  ///
  /// In en, this message translates to:
  /// **'Put away “{name}”?'**
  String archiveCategoryQ(String name);

  /// No description provided for @archiveItemQ.
  ///
  /// In en, this message translates to:
  /// **'Put away “{name}”?'**
  String archiveItemQ(String name);

  /// No description provided for @availableInWallet.
  ///
  /// In en, this message translates to:
  /// **'In the wallet: {amount}'**
  String availableInWallet(String amount);

  /// No description provided for @backToPriceList.
  ///
  /// In en, this message translates to:
  /// **'Back to the price list'**
  String get backToPriceList;

  /// No description provided for @bookedBy.
  ///
  /// In en, this message translates to:
  /// **'Booked by {name}'**
  String bookedBy(String name);

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// No description provided for @byMonth.
  ///
  /// In en, this message translates to:
  /// **'By month'**
  String get byMonth;

  /// No description provided for @byPriceList.
  ///
  /// In en, this message translates to:
  /// **'By the price list'**
  String get byPriceList;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelJob.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelJob;

  /// No description provided for @cancelJobBody.
  ///
  /// In en, this message translates to:
  /// **'It stays in the history, crossed out, and everyone is told.'**
  String get cancelJobBody;

  /// No description provided for @cancelJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get cancelJobTitle;

  /// No description provided for @cancelledCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} cancelled} other{{count} cancelled}}'**
  String cancelledCount(int count);

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get categoryNote;

  /// No description provided for @categoryNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What is included, which cars count as which size'**
  String get categoryNoteHint;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @chargeTravel.
  ///
  /// In en, this message translates to:
  /// **'Charge for travel'**
  String get chargeTravel;

  /// No description provided for @charged.
  ///
  /// In en, this message translates to:
  /// **'Charged'**
  String get charged;

  /// No description provided for @chargedShort.
  ///
  /// In en, this message translates to:
  /// **'charged {amount}'**
  String chargedShort(String amount);

  /// No description provided for @checkUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkUpdates;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get chooseLanguage;

  /// No description provided for @claimAdminBody.
  ///
  /// In en, this message translates to:
  /// **'This is the first account. Enter your name and become the admin: you add the workers and keep the price list.'**
  String get claimAdminBody;

  /// No description provided for @claimAdminButton.
  ///
  /// In en, this message translates to:
  /// **'Become the admin'**
  String get claimAdminButton;

  /// No description provided for @claimAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Become the admin'**
  String get claimAdminTitle;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client (optional)'**
  String get clientName;

  /// No description provided for @clientPhone.
  ///
  /// In en, this message translates to:
  /// **'Client\'s phone (optional)'**
  String get clientPhone;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmPassword;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @costs.
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get costs;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteEntryQ.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntryQ;

  /// No description provided for @deleteJobBody.
  ///
  /// In en, this message translates to:
  /// **'Only for a job entered by mistake. Nobody is told. To call it off, cancel it instead.'**
  String get deleteJobBody;

  /// No description provided for @deleteJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this job?'**
  String get deleteJobTitle;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @depositNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get depositNote;

  /// No description provided for @depositNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Change for the till, a loan…'**
  String get depositNoteHint;

  /// No description provided for @depositsNote.
  ///
  /// In en, this message translates to:
  /// **'Put in by hand: {amount}'**
  String depositsNote(String amount);

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Switch off'**
  String get disable;

  /// No description provided for @disableWorkerBody.
  ///
  /// In en, this message translates to:
  /// **'They can no longer sign in. Their jobs keep their name.'**
  String get disableWorkerBody;

  /// No description provided for @disableWorkerQ.
  ///
  /// In en, this message translates to:
  /// **'Switch off {name}?'**
  String disableWorkerQ(String name);

  /// No description provided for @disabledBody.
  ///
  /// In en, this message translates to:
  /// **'The admin has switched this account off. Ask them if it is a mistake.'**
  String get disabledBody;

  /// No description provided for @disabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Account switched off'**
  String get disabledTitle;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @discountPercent.
  ///
  /// In en, this message translates to:
  /// **'Discount {percent}%'**
  String discountPercent(int percent);

  /// No description provided for @discountRule.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off above {amount}'**
  String discountRule(int percent, String amount);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @doneWithTotal.
  ///
  /// In en, this message translates to:
  /// **'Done · {total}'**
  String doneWithTotal(String total);

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Charged'**
  String get earned;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @editJob.
  ///
  /// In en, this message translates to:
  /// **'Edit booking'**
  String get editJob;

  /// No description provided for @editWorker.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editWorker;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Switch on'**
  String get enable;

  /// No description provided for @enableWorkerQ.
  ///
  /// In en, this message translates to:
  /// **'Switch {name} back on?'**
  String enableWorkerQ(String name);

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errEmailInUse;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email is not valid.'**
  String get errInvalidEmail;

  /// No description provided for @errNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errNoNetwork;

  /// No description provided for @errPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission for this.'**
  String get errPermission;

  /// No description provided for @errRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign out, sign in again and try once more.'**
  String get errRecentLogin;

  /// No description provided for @errTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a few minutes.'**
  String get errTooMany;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is switched off.'**
  String get errUserDisabled;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak (min. 6 characters).'**
  String get errWeakPassword;

  /// No description provided for @errWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errWrongCredentials;

  /// No description provided for @finishJob.
  ///
  /// In en, this message translates to:
  /// **'Finish job'**
  String get finishJob;

  /// No description provided for @finishedBy.
  ///
  /// In en, this message translates to:
  /// **'Finished by {name}'**
  String finishedBy(String name);

  /// No description provided for @finishedJobs.
  ///
  /// In en, this message translates to:
  /// **'Finished jobs'**
  String get finishedJobs;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @freeTravelFrom.
  ///
  /// In en, this message translates to:
  /// **'Free travel from'**
  String get freeTravelFrom;

  /// No description provided for @freeTravelRule.
  ///
  /// In en, this message translates to:
  /// **'Free travel for orders from {amount}'**
  String freeTravelRule(String amount);

  /// No description provided for @givenToHelpers.
  ///
  /// In en, this message translates to:
  /// **'Given to helpers'**
  String get givenToHelpers;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get goBack;

  /// No description provided for @helpedBy.
  ///
  /// In en, this message translates to:
  /// **'Help: {names}'**
  String helpedBy(String names);

  /// No description provided for @helperPay.
  ///
  /// In en, this message translates to:
  /// **'Helper: {name}'**
  String helperPay(String name);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @iGot.
  ///
  /// In en, this message translates to:
  /// **'My earnings'**
  String get iGot;

  /// No description provided for @inWallet.
  ///
  /// In en, this message translates to:
  /// **'In the wallet'**
  String get inWallet;

  /// No description provided for @intoWallet.
  ///
  /// In en, this message translates to:
  /// **'Into the wallet'**
  String get intoWallet;

  /// No description provided for @intoWalletHint.
  ///
  /// In en, this message translates to:
  /// **'The money was handed in as cash'**
  String get intoWalletHint;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get invalidAmount;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @invalidPercent.
  ///
  /// In en, this message translates to:
  /// **'0 to 100'**
  String get invalidPercent;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get itemName;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @job.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get job;

  /// No description provided for @jobGone.
  ///
  /// In en, this message translates to:
  /// **'This job no longer exists.'**
  String get jobGone;

  /// No description provided for @jobNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get jobNoItems;

  /// No description provided for @jobsAndAverage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jobs} one{{count} job · {average} average} other{{count} jobs · {average} average}}'**
  String jobsAndAverage(int count, String average);

  /// No description provided for @jobsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jobs} one{{count} job} other{{count} jobs}}'**
  String jobsCount(int count);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languagePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get languagePhone;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name (optional)'**
  String get lastName;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @leftForAdmin.
  ///
  /// In en, this message translates to:
  /// **'Left for {name}'**
  String leftForAdmin(String name);

  /// No description provided for @leftForYou.
  ///
  /// In en, this message translates to:
  /// **'Left for you'**
  String get leftForYou;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get less;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get linkCopied;

  /// No description provided for @loadPriceList.
  ///
  /// In en, this message translates to:
  /// **'Load the price list'**
  String get loadPriceList;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the account your admin made for you.'**
  String get loginSubtitle;

  /// No description provided for @minChars6.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get minChars6;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @myEarnings.
  ///
  /// In en, this message translates to:
  /// **'My earnings'**
  String get myEarnings;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @newDeposit.
  ///
  /// In en, this message translates to:
  /// **'Put money in'**
  String get newDeposit;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get newItem;

  /// No description provided for @newJob.
  ///
  /// In en, this message translates to:
  /// **'New booking'**
  String get newJob;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @newSpending.
  ///
  /// In en, this message translates to:
  /// **'Spend money'**
  String get newSpending;

  /// No description provided for @newVersionBody.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready to download. You have {current}.'**
  String newVersionBody(String version, String current);

  /// No description provided for @newVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get newVersionTitle;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @nextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get nextYear;

  /// No description provided for @noAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Ask the admin to add you.'**
  String get noAccessBody;

  /// No description provided for @noAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get noAccessTitle;

  /// No description provided for @noJobsThatDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing booked for this day.'**
  String get noJobsThatDay;

  /// No description provided for @noJobsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No finished jobs in {month}.'**
  String noJobsThisMonth(String month);

  /// No description provided for @noJobsThisYear.
  ///
  /// In en, this message translates to:
  /// **'No finished jobs this year.'**
  String get noJobsThisYear;

  /// No description provided for @noWorkersYet.
  ///
  /// In en, this message translates to:
  /// **'No workers yet. The admin adds them under Workers.'**
  String get noWorkersYet;

  /// No description provided for @notEnoughBody.
  ///
  /// In en, this message translates to:
  /// **'Only {amount} can be spent. Put money in first, or spend less.'**
  String notEnoughBody(String amount);

  /// No description provided for @notEnoughTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough in the wallet'**
  String get notEnoughTitle;

  /// No description provided for @notFinished.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Not finished · {count}} other{Not finished · {count}}}'**
  String notFinished(int count);

  /// No description provided for @notIntoWallet.
  ///
  /// In en, this message translates to:
  /// **'Not in the wallet'**
  String get notIntoWallet;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Which car, floor, intercom…'**
  String get notesHint;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which ones you get'**
  String get notificationsHint;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @over.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get over;

  /// No description provided for @paidToHelpers.
  ///
  /// In en, this message translates to:
  /// **'Paid to helpers'**
  String get paidToHelpers;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get passwordChanged;

  /// No description provided for @passwordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsNoMatch;

  /// No description provided for @paysThem.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get paysThem;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phone;

  /// No description provided for @pickAHelper.
  ///
  /// In en, this message translates to:
  /// **'Pick who helps, or switch to “Working alone”.'**
  String get pickAHelper;

  /// No description provided for @pickStartTime.
  ///
  /// In en, this message translates to:
  /// **'Pick the start time.'**
  String get pickStartTime;

  /// No description provided for @pickedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} chosen'**
  String pickedCount(int count);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @previousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get previousYear;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @priceList.
  ///
  /// In en, this message translates to:
  /// **'Price list'**
  String get priceList;

  /// No description provided for @priceListAdminHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an item to change it, hold it to put it away. Tap the terms to change them.'**
  String get priceListAdminHint;

  /// No description provided for @priceListEmpty.
  ///
  /// In en, this message translates to:
  /// **'The price list is empty. The admin sets it up.'**
  String get priceListEmpty;

  /// No description provided for @priceListEmptyAdmin.
  ///
  /// In en, this message translates to:
  /// **'The price list is empty. Load the crew\'s list in one tap, then change what you like.'**
  String get priceListEmptyAdmin;

  /// No description provided for @priceTypedOver.
  ///
  /// In en, this message translates to:
  /// **'Typed by hand, not from the price list'**
  String get priceTypedOver;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @pushJobCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get pushJobCancelled;

  /// No description provided for @pushJobChanged.
  ///
  /// In en, this message translates to:
  /// **'Booking changed'**
  String get pushJobChanged;

  /// No description provided for @pushJobNew.
  ///
  /// In en, this message translates to:
  /// **'New booking'**
  String get pushJobNew;

  /// No description provided for @pushJobTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get pushJobTomorrow;

  /// No description provided for @putIn.
  ///
  /// In en, this message translates to:
  /// **'Put in'**
  String get putIn;

  /// No description provided for @readOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Entered by {name}. Only they or the admin can change it.'**
  String readOnlyNotice(String name);

  /// No description provided for @removedCategory.
  ///
  /// In en, this message translates to:
  /// **'Removed category'**
  String get removedCategory;

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Back to booked'**
  String get reopen;

  /// No description provided for @reopenCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'The booking is on again.'**
  String get reopenCancelledBody;

  /// No description provided for @reopenDoneBody.
  ///
  /// In en, this message translates to:
  /// **'What was charged leaves the wallet and the earnings.'**
  String get reopenDoneBody;

  /// No description provided for @reopenTitle.
  ///
  /// In en, this message translates to:
  /// **'Back to booked?'**
  String get reopenTitle;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get resetSent;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Change a quantity here, or go back to the price list for more.'**
  String get reviewHint;

  /// No description provided for @reviewWithTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Review · {count} item · {total}} other{Review · {count} items · {total}}}'**
  String reviewWithTotal(int count, String total);

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get roleWorker;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendLink;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share the app'**
  String get shareApp;

  /// No description provided for @shareAppHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the code with another phone\'s camera, or send the link. Android will ask to allow installing from that source.'**
  String get shareAppHint;

  /// No description provided for @shareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Car Detailing: bookings, wallet and earnings of the crew.'**
  String get shareAppMessage;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @spend.
  ///
  /// In en, this message translates to:
  /// **'Spend'**
  String get spend;

  /// No description provided for @spending.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get spending;

  /// No description provided for @spentOn.
  ///
  /// In en, this message translates to:
  /// **'What for'**
  String get spentOn;

  /// No description provided for @spentOnHint.
  ///
  /// In en, this message translates to:
  /// **'Chemicals, cloths, fuel…'**
  String get spentOnHint;

  /// No description provided for @startPassword.
  ///
  /// In en, this message translates to:
  /// **'Starting password'**
  String get startPassword;

  /// No description provided for @startPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Tell it to the worker; they can change it in Settings.'**
  String get startPasswordHint;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startTime;

  /// No description provided for @statusBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get statusBooked;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Not finished'**
  String get statusOverdue;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @switchedOff.
  ///
  /// In en, this message translates to:
  /// **'Switched off'**
  String get switchedOff;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get tabEarnings;

  /// No description provided for @tabWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get tabWallet;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @toHelpersShort.
  ///
  /// In en, this message translates to:
  /// **'helpers {amount}'**
  String toHelpersShort(String amount);

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @travelFee.
  ///
  /// In en, this message translates to:
  /// **'Travel fee below that'**
  String get travelFee;

  /// No description provided for @travelFeeHint.
  ///
  /// In en, this message translates to:
  /// **'0 = always free'**
  String get travelFeeHint;

  /// No description provided for @travelFeeRule.
  ///
  /// In en, this message translates to:
  /// **'Travel below that: {amount}'**
  String travelFeeRule(String amount);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version.'**
  String get upToDate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates.'**
  String get updateCheckFailed;

  /// No description provided for @usePriceListPrice.
  ///
  /// In en, this message translates to:
  /// **'Use the price-list price'**
  String get usePriceListPrice;

  /// No description provided for @wait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get wait;

  /// No description provided for @walletEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Finished jobs come in here by themselves.'**
  String get walletEmpty;

  /// No description provided for @wentIntoWallet.
  ///
  /// In en, this message translates to:
  /// **'Went into the wallet'**
  String get wentIntoWallet;

  /// No description provided for @whatIsDone.
  ///
  /// In en, this message translates to:
  /// **'What is done'**
  String get whatIsDone;

  /// No description provided for @whoDeposited.
  ///
  /// In en, this message translates to:
  /// **'Who put it in'**
  String get whoDeposited;

  /// No description provided for @whoSpent.
  ///
  /// In en, this message translates to:
  /// **'Who spent it'**
  String get whoSpent;

  /// No description provided for @whoWorked.
  ///
  /// In en, this message translates to:
  /// **'Who did the work'**
  String get whoWorked;

  /// No description provided for @whoWorks.
  ///
  /// In en, this message translates to:
  /// **'Who works on it'**
  String get whoWorks;

  /// No description provided for @withHelp.
  ///
  /// In en, this message translates to:
  /// **'I have help'**
  String get withHelp;

  /// No description provided for @withoutPriceList.
  ///
  /// In en, this message translates to:
  /// **'Not from the price list'**
  String get withoutPriceList;

  /// No description provided for @workerAdded.
  ///
  /// In en, this message translates to:
  /// **'Worker added. Give them the email and the starting password.'**
  String get workerAdded;

  /// No description provided for @workers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workers;

  /// No description provided for @workingAlone.
  ///
  /// In en, this message translates to:
  /// **'Working alone'**
  String get workingAlone;

  /// No description provided for @workingAloneShort.
  ///
  /// In en, this message translates to:
  /// **'Working alone'**
  String get workingAloneShort;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;
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
      <String>['en', 'sr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sr':
      return AppLocalizationsSr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
