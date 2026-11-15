// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get add => 'Add';

  @override
  String get addFromPriceList => 'Add from the price list';

  @override
  String get addItemOrNote => 'Add an item from the price list, or a note.';

  @override
  String get addWorker => 'Add worker';

  @override
  String get address => 'Address (optional)';

  @override
  String get agreedPrice => 'Agreed price';

  @override
  String get alreadyDone => 'Already done';

  @override
  String get alreadyDoneHint => 'A client who came without booking';

  @override
  String get amount => 'Amount';

  @override
  String get appTagline => 'Bookings, wallet and earnings for the whole crew.';

  @override
  String get appTitle => 'Car Detailing';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get archive => 'Put away';

  @override
  String get archiveBody =>
      'It is no longer offered for new jobs. Jobs that have it keep it.';

  @override
  String archiveCategoryQ(String name) {
    return 'Put away “$name”?';
  }

  @override
  String archiveItemQ(String name) {
    return 'Put away “$name”?';
  }

  @override
  String availableInWallet(String amount) {
    return 'In the wallet: $amount';
  }

  @override
  String get backToPriceList => 'Back to the price list';

  @override
  String bookedBy(String name) {
    return 'Booked by $name';
  }

  @override
  String get byCategory => 'By category';

  @override
  String get byMonth => 'By month';

  @override
  String get byPriceList => 'By the price list';

  @override
  String get byWorker => 'By worker';

  @override
  String get call => 'Call';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelJob => 'Cancel booking';

  @override
  String get cancelJobBody =>
      'It stays in the history, crossed out, and everyone is told.';

  @override
  String get cancelJobTitle => 'Cancel this booking?';

  @override
  String cancelledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cancelled',
      one: '$count cancelled',
    );
    return '$_temp0';
  }

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryNote => 'Note (optional)';

  @override
  String get categoryNoteHint =>
      'What is included, which cars count as which size';

  @override
  String get changePassword => 'Change password';

  @override
  String get chargeTravel => 'Charge for travel';

  @override
  String get charged => 'Charged';

  @override
  String get checkUpdates => 'Check for updates';

  @override
  String get chooseLanguage => 'Language';

  @override
  String get claimAdminBody =>
      'This is the first account. Enter your name and become the admin: you add the workers and keep the price list.';

  @override
  String get claimAdminButton => 'Become the admin';

  @override
  String get claimAdminTitle => 'Become the admin';

  @override
  String get clear => 'Clear';

  @override
  String get clientName => 'Client (optional)';

  @override
  String get clientPhone => 'Client\'s phone (optional)';

  @override
  String get confirmPassword => 'Confirm new password';

  @override
  String get copyLink => 'Copy link';

  @override
  String get costs => 'Costs';

  @override
  String get currentPassword => 'Current password';

  @override
  String get date => 'Date';

  @override
  String get delete => 'Delete';

  @override
  String get deleteEntryQ => 'Delete this entry?';

  @override
  String get deleteJobBody =>
      'Only for a job entered by mistake. Nobody is told. To call it off, cancel it instead.';

  @override
  String get deleteJobTitle => 'Delete this job?';

  @override
  String get deposit => 'Deposit';

  @override
  String get depositNote => 'Note (optional)';

  @override
  String get depositNoteHint => 'Change for the till, a loan…';

  @override
  String depositsNote(String amount) {
    return 'Put in by hand: $amount';
  }

  @override
  String get disable => 'Switch off';

  @override
  String get disableWorkerBody =>
      'They can no longer sign in. Their jobs keep their name.';

  @override
  String disableWorkerQ(String name) {
    return 'Switch off $name?';
  }

  @override
  String get disabledBody =>
      'The admin has switched this account off. Ask them if it is a mistake.';

  @override
  String get disabledTitle => 'Account switched off';

  @override
  String get discount => 'Discount';

  @override
  String discountPercent(int percent) {
    return 'Discount $percent%';
  }

  @override
  String discountRule(int percent, String amount) {
    return '$percent% off above $amount';
  }

  @override
  String get done => 'Done';

  @override
  String doneWithTotal(String total) {
    return 'Done · $total';
  }

  @override
  String get download => 'Download';

  @override
  String get earned => 'Earned';

  @override
  String get edit => 'Edit';

  @override
  String get editCategory => 'Edit category';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get editItem => 'Edit item';

  @override
  String get editJob => 'Edit booking';

  @override
  String get editWorker => 'Edit';

  @override
  String get email => 'Email';

  @override
  String get enable => 'Switch on';

  @override
  String enableWorkerQ(String name) {
    return 'Switch $name back on?';
  }

  @override
  String get endTime => 'End';

  @override
  String get errEmailInUse => 'An account with this email already exists.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get errInvalidEmail => 'The email is not valid.';

  @override
  String get errNoNetwork => 'No internet connection.';

  @override
  String get errPermission => 'You don\'t have permission for this.';

  @override
  String get errRecentLogin => 'Sign out, sign in again and try once more.';

  @override
  String get errTooMany => 'Too many attempts. Try again in a few minutes.';

  @override
  String get errUserDisabled => 'This account is switched off.';

  @override
  String get errWeakPassword => 'Password is too weak (min. 6 characters).';

  @override
  String get errWrongCredentials => 'Wrong email or password.';

  @override
  String get finishJob => 'Finish job';

  @override
  String finishedBy(String name) {
    return 'Finished by $name';
  }

  @override
  String get finishedJobs => 'Finished jobs';

  @override
  String get firstName => 'First name';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get freeTravelFrom => 'Free travel from';

  @override
  String freeTravelRule(String amount) {
    return 'Free travel for orders from $amount';
  }

  @override
  String get goBack => 'Back';

  @override
  String get history => 'History';

  @override
  String get inWallet => 'In the wallet';

  @override
  String get intoWallet => 'Into the wallet';

  @override
  String get intoWalletHint => 'The money was handed in as cash';

  @override
  String get invalidAmount => 'Enter an amount';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get invalidPercent => '0 to 100';

  @override
  String get itemName => 'Name';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get job => 'Job';

  @override
  String get jobGone => 'This job no longer exists.';

  @override
  String get jobNoItems => 'No items';

  @override
  String jobsAndAverage(int count, String average) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs · $average average',
      one: '$count job · $average average',
      zero: 'No jobs',
    );
    return '$_temp0';
  }

  @override
  String jobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs',
      one: '$count job',
      zero: 'No jobs',
    );
    return '$_temp0';
  }

  @override
  String get language => 'Language';

  @override
  String get languagePhone => 'Phone language';

  @override
  String get lastName => 'Last name (optional)';

  @override
  String get later => 'Later';

  @override
  String get left => 'Left';

  @override
  String get less => 'Fewer';

  @override
  String get licenses => 'Licenses';

  @override
  String get linkCopied => 'Link copied.';

  @override
  String get loadPriceList => 'Load the price list';

  @override
  String get loginSubtitle => 'Use the account your admin made for you.';

  @override
  String get minChars6 => 'At least 6 characters';

  @override
  String get month => 'Month';

  @override
  String get more => 'More';

  @override
  String get newCategory => 'New category';

  @override
  String get newDeposit => 'Put money in';

  @override
  String get newItem => 'New item';

  @override
  String get newJob => 'New booking';

  @override
  String get newPassword => 'New password';

  @override
  String get newSpending => 'Spend money';

  @override
  String newVersionBody(String version, String current) {
    return 'Version $version is ready to download. You have $current.';
  }

  @override
  String get newVersionTitle => 'New version available';

  @override
  String get next => 'Next';

  @override
  String get nextMonth => 'Next month';

  @override
  String get nextYear => 'Next year';

  @override
  String get noAccessBody => 'Ask the admin to add you.';

  @override
  String get noAccessTitle => 'No access';

  @override
  String get noJobsThatDay => 'Nothing booked for this day.';

  @override
  String noJobsThisMonth(String month) {
    return 'No finished jobs in $month.';
  }

  @override
  String get noJobsThisYear => 'No finished jobs this year.';

  @override
  String get nobodyAssigned => 'Nobody assigned';

  @override
  String notEnoughBody(String amount) {
    return 'Only $amount can be spent. Put money in first, or spend less.';
  }

  @override
  String get notEnoughTitle => 'Not enough in the wallet';

  @override
  String notFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Not finished · $count',
      one: 'Not finished · $count',
    );
    return '$_temp0';
  }

  @override
  String get notIntoWallet => 'Not in the wallet';

  @override
  String get notes => 'Notes (optional)';

  @override
  String get notesHint => 'Which car, floor, intercom…';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsHint => 'Choose which ones you get';

  @override
  String get ok => 'OK';

  @override
  String get open => 'Open';

  @override
  String get over => 'Above';

  @override
  String get password => 'Password';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String get passwordsNoMatch => 'Passwords do not match';

  @override
  String get phone => 'Phone (optional)';

  @override
  String get pickStartTime => 'Pick the start time.';

  @override
  String pickedCount(int count) {
    return '$count chosen';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get price => 'Price';

  @override
  String get priceList => 'Price list';

  @override
  String get priceListAdminHint =>
      'Tap an item to change it, hold it to put it away. Tap the terms to change them.';

  @override
  String get priceListEmpty => 'The price list is empty. The admin sets it up.';

  @override
  String get priceListEmptyAdmin =>
      'The price list is empty. Load the crew\'s list in one tap, then change what you like.';

  @override
  String get priceTypedOver => 'Typed by hand, not from the price list';

  @override
  String get profile => 'Profile';

  @override
  String get pushJobCancelled => 'Booking cancelled';

  @override
  String get pushJobChanged => 'Booking changed';

  @override
  String get pushJobNew => 'New booking';

  @override
  String get pushJobTomorrow => 'Tomorrow';

  @override
  String get putIn => 'Put in';

  @override
  String readOnlyNotice(String name) {
    return 'Entered by $name. Only they or the admin can change it.';
  }

  @override
  String get removedCategory => 'Removed category';

  @override
  String get reopen => 'Back to booked';

  @override
  String get reopenCancelledBody => 'The booking is on again.';

  @override
  String get reopenDoneBody =>
      'What was charged leaves the wallet and the earnings.';

  @override
  String get reopenTitle => 'Back to booked?';

  @override
  String get required => 'Required';

  @override
  String get resetSent => 'Password reset email sent.';

  @override
  String get review => 'Review';

  @override
  String get reviewHint =>
      'Change a quantity here, or go back to the price list for more.';

  @override
  String reviewWithTotal(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review · $count items · $total',
      one: 'Review · $count item · $total',
    );
    return '$_temp0';
  }

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleWorker => 'Worker';

  @override
  String get save => 'Save';

  @override
  String get sendLink => 'Send';

  @override
  String get settings => 'Settings';

  @override
  String get shareApp => 'Share the app';

  @override
  String get shareAppHint =>
      'Scan the code with another phone\'s camera, or send the link. Android will ask to allow installing from that source.';

  @override
  String get shareAppMessage =>
      'Car Detailing: bookings, wallet and earnings of the crew.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get spend => 'Spend';

  @override
  String get spending => 'Spending';

  @override
  String get spentOn => 'What for';

  @override
  String get spentOnHint => 'Chemicals, cloths, fuel…';

  @override
  String get startPassword => 'Starting password';

  @override
  String get startPasswordHint =>
      'Tell it to the worker; they can change it in Settings.';

  @override
  String get startTime => 'Start';

  @override
  String get statusBooked => 'Booked';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusDone => 'Done';

  @override
  String get statusOverdue => 'Not finished';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get switchedOff => 'Switched off';

  @override
  String get synced => 'Synced';

  @override
  String get syncing => 'Syncing…';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabEarnings => 'Earnings';

  @override
  String get tabWallet => 'Wallet';

  @override
  String get terms => 'Terms';

  @override
  String get travel => 'Travel';

  @override
  String get travelFee => 'Travel fee below that';

  @override
  String get travelFeeHint => '0 = always free';

  @override
  String travelFeeRule(String amount) {
    return 'Travel below that: $amount';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String untilTime(String time) {
    return 'until $time';
  }

  @override
  String get upToDate => 'You have the latest version.';

  @override
  String get updateCheckFailed => 'Couldn\'t check for updates.';

  @override
  String get usePriceListPrice => 'Use the price-list price';

  @override
  String get wait => 'Please wait…';

  @override
  String get walletEmpty =>
      'Nothing yet. Finished jobs come in here by themselves.';

  @override
  String get wentIntoWallet => 'Went into the wallet';

  @override
  String get whatIsDone => 'What is done';

  @override
  String get whoDeposited => 'Who put it in';

  @override
  String get whoSpent => 'Who spent it';

  @override
  String get whoWorked => 'Who did the work';

  @override
  String get whoWorks => 'Who works on it';

  @override
  String get withoutPriceList => 'Not from the price list';

  @override
  String get workerAdded =>
      'Worker added. Give them the email and the starting password.';

  @override
  String get workers => 'Workers';

  @override
  String get year => 'Year';
}
