// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get add => 'Dodaj';

  @override
  String get addFromPriceList => 'Dodaj iz cenovnika';

  @override
  String get addItemOrNote => 'Dodaj stavku iz cenovnika ili napomenu.';

  @override
  String get addWorker => 'Dodaj radnika';

  @override
  String get address => 'Adresa (nije obavezno)';

  @override
  String adminEarnings(String name) {
    return 'Zarada: $name';
  }

  @override
  String get agreedPrice => 'Dogovorena cena';

  @override
  String get alreadyDone => 'Već završeno';

  @override
  String get alreadyDoneHint => 'Klijent koji je došao bez zakazivanja';

  @override
  String get amount => 'Iznos';

  @override
  String get appTagline => 'Termini, novčanik i zarada za celu ekipu.';

  @override
  String get appTitle => 'Car Detailing';

  @override
  String appVersion(String version) {
    return 'Verzija $version';
  }

  @override
  String get archive => 'Skloni';

  @override
  String get archiveBody =>
      'Više se ne nudi za nove poslove. Poslovi koji je imaju zadržavaju je.';

  @override
  String archiveCategoryQ(String name) {
    return 'Skloniti „$name”?';
  }

  @override
  String archiveItemQ(String name) {
    return 'Skloniti „$name”?';
  }

  @override
  String availableInWallet(String amount) {
    return 'U novčaniku: $amount';
  }

  @override
  String get backToPriceList => 'Nazad na cenovnik';

  @override
  String bookedBy(String name) {
    return 'Zakazao/la: $name';
  }

  @override
  String get byCategory => 'Po kategoriji';

  @override
  String get byMonth => 'Po mesecima';

  @override
  String get byPriceList => 'Po cenovniku';

  @override
  String get call => 'Pozovi';

  @override
  String get cancel => 'Otkaži';

  @override
  String get cancelJob => 'Otkaži termin';

  @override
  String get cancelJobBody =>
      'Ostaje u istoriji, precrtan, i svi dobijaju obaveštenje.';

  @override
  String get cancelJobTitle => 'Otkazati termin?';

  @override
  String cancelledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count otkazanih',
      few: '$count otkazana',
      one: '$count otkazan',
    );
    return '$_temp0';
  }

  @override
  String get categoryName => 'Naziv kategorije';

  @override
  String get categoryNote => 'Opis (nije obavezno)';

  @override
  String get categoryNoteHint => 'Šta ulazi, koja auta su koje veličine';

  @override
  String get changePassword => 'Promeni lozinku';

  @override
  String get chargeTravel => 'Naplati dolazak';

  @override
  String get charged => 'Naplaćeno';

  @override
  String chargedShort(String amount) {
    return 'naplaćeno $amount';
  }

  @override
  String get checkUpdates => 'Proveri ažuriranja';

  @override
  String get chooseLanguage => 'Jezik';

  @override
  String get claimAdminBody =>
      'Ovo je prvi nalog. Upiši ime i postani admin: ti dodaješ radnike i vodiš cenovnik.';

  @override
  String get claimAdminButton => 'Postani admin';

  @override
  String get claimAdminTitle => 'Postani admin';

  @override
  String get clear => 'Obriši';

  @override
  String get clientName => 'Klijent (nije obavezno)';

  @override
  String get clientPhone => 'Telefon klijenta (nije obavezno)';

  @override
  String get confirmPassword => 'Potvrdi novu lozinku';

  @override
  String get copyLink => 'Kopiraj link';

  @override
  String get currentPassword => 'Trenutna lozinka';

  @override
  String get date => 'Datum';

  @override
  String get delete => 'Obriši';

  @override
  String get deleteEntryQ => 'Obrisati unos?';

  @override
  String get deleteJobBody =>
      'Samo za posao unet greškom. Niko ne dobija obaveštenje. Ako je otkazan, radije ga otkaži.';

  @override
  String get deleteJobTitle => 'Obrisati posao?';

  @override
  String get deposit => 'Ubačeno';

  @override
  String get depositNote => 'Napomena (nije obavezno)';

  @override
  String get depositNoteHint => 'Sitno za kusur, pozajmica…';

  @override
  String depositsNote(String amount) {
    return 'Ubačeno ručno: $amount';
  }

  @override
  String get disable => 'Isključi';

  @override
  String get disableWorkerBody =>
      'Više ne može da se prijavi. Poslovi zadržavaju njegovo ime.';

  @override
  String disableWorkerQ(String name) {
    return 'Isključiti: $name?';
  }

  @override
  String get disabledBody =>
      'Admin je isključio ovaj nalog. Pitaj ga ako je greška.';

  @override
  String get disabledTitle => 'Nalog je isključen';

  @override
  String get discount => 'Popust';

  @override
  String discountPercent(int percent) {
    return 'Popust $percent%';
  }

  @override
  String discountRule(int percent, String amount) {
    return 'Popust $percent% iznad $amount';
  }

  @override
  String get done => 'Gotovo';

  @override
  String doneWithTotal(String total) {
    return 'Gotovo · $total';
  }

  @override
  String get download => 'Preuzmi';

  @override
  String get earned => 'Naplaćeno';

  @override
  String get edit => 'Izmeni';

  @override
  String get editCategory => 'Izmeni kategoriju';

  @override
  String get editEntry => 'Izmeni unos';

  @override
  String get editItem => 'Izmeni stavku';

  @override
  String get editJob => 'Izmeni termin';

  @override
  String get editWorker => 'Izmeni';

  @override
  String get email => 'Email';

  @override
  String get enable => 'Uključi';

  @override
  String enableWorkerQ(String name) {
    return 'Ponovo uključiti: $name?';
  }

  @override
  String get endTime => 'Kraj';

  @override
  String get equipment => 'Oprema';

  @override
  String get equipmentHint => 'Hemija, krpe… za ovaj posao';

  @override
  String equipmentShort(String amount) {
    return 'oprema $amount';
  }

  @override
  String get equipmentSpent => 'Potrošeno na opremu';

  @override
  String get errEmailInUse => 'Nalog sa ovim emailom već postoji.';

  @override
  String get errGeneric => 'Nešto nije u redu. Pokušaj ponovo.';

  @override
  String get errInvalidEmail => 'Email nije ispravan.';

  @override
  String get errNoNetwork => 'Nema internet konekcije.';

  @override
  String get errPermission => 'Nemaš dozvolu za ovo.';

  @override
  String get errRecentLogin =>
      'Odjavi se, prijavi se ponovo i pokušaj još jednom.';

  @override
  String get errTooMany =>
      'Previše pokušaja. Pokušaj ponovo za nekoliko minuta.';

  @override
  String get errUserDisabled => 'Ovaj nalog je isključen.';

  @override
  String get errWeakPassword => 'Lozinka je preslaba (min. 6 karaktera).';

  @override
  String get errWrongCredentials => 'Pogrešan email ili lozinka.';

  @override
  String get finishJob => 'Završi posao';

  @override
  String finishedBy(String name) {
    return 'Završio/la: $name';
  }

  @override
  String get finishedJobs => 'Završeni poslovi';

  @override
  String get firstName => 'Ime';

  @override
  String get forgotPassword => 'Zaboravljena lozinka?';

  @override
  String get freeTravelFrom => 'Besplatan dolazak od';

  @override
  String freeTravelRule(String amount) {
    return 'Besplatan dolazak za porudžbine od $amount';
  }

  @override
  String get givenToHelpers => 'Dato radnicima';

  @override
  String get goBack => 'Nazad';

  @override
  String helpedBy(String names) {
    return 'Pomoć: $names';
  }

  @override
  String helperPay(String name) {
    return 'Pomoćnik: $name';
  }

  @override
  String get history => 'Istorija';

  @override
  String get iGot => 'Moja zarada';

  @override
  String get inWallet => 'U novčaniku';

  @override
  String get intoWallet => 'U novčanik';

  @override
  String get intoWalletHint => 'Novac je predat u kasu';

  @override
  String get invalidAmount => 'Upiši iznos';

  @override
  String get invalidEmail => 'Unesi ispravan email';

  @override
  String get invalidPercent => 'Od 0 do 100';

  @override
  String get itemName => 'Naziv';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stavki',
      few: '$count stavke',
      one: '$count stavka',
    );
    return '$_temp0';
  }

  @override
  String get job => 'Posao';

  @override
  String get jobGone => 'Ovaj posao više ne postoji.';

  @override
  String get jobNoItems => 'Bez stavki';

  @override
  String jobsAndAverage(int count, String average) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count poslova · prosek $average',
      few: '$count posla · prosek $average',
      one: '$count posao · prosek $average',
      zero: 'Nema poslova',
    );
    return '$_temp0';
  }

  @override
  String jobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count poslova',
      few: '$count posla',
      one: '$count posao',
      zero: 'Nema poslova',
    );
    return '$_temp0';
  }

  @override
  String get language => 'Jezik';

  @override
  String get languagePhone => 'Jezik telefona';

  @override
  String get lastName => 'Prezime (nije obavezno)';

  @override
  String get later => 'Kasnije';

  @override
  String leftForAdmin(String name) {
    return '$name dobija';
  }

  @override
  String get leftForYou => 'Ostaje tebi';

  @override
  String get less => 'Manje';

  @override
  String get licenses => 'Licence';

  @override
  String get linkCopied => 'Link je kopiran.';

  @override
  String get loadPriceList => 'Učitaj cenovnik';

  @override
  String get loginSubtitle => 'Koristi nalog koji ti je napravio admin.';

  @override
  String get minChars6 => 'Najmanje 6 karaktera';

  @override
  String get month => 'Mesec';

  @override
  String get more => 'Više';

  @override
  String get myEarnings => 'Moja zarada';

  @override
  String get newCategory => 'Nova kategorija';

  @override
  String get newDeposit => 'Ubaci novac';

  @override
  String get newItem => 'Nova stavka';

  @override
  String get newJob => 'Novi termin';

  @override
  String get newPassword => 'Nova lozinka';

  @override
  String get newSpending => 'Potroši novac';

  @override
  String newVersionBody(String version, String current) {
    return 'Verzija $version je spremna za preuzimanje. Ti imaš $current.';
  }

  @override
  String get newVersionTitle => 'Dostupna je nova verzija';

  @override
  String get next => 'Dalje';

  @override
  String get nextMonth => 'Sledeći mesec';

  @override
  String get nextYear => 'Sledeća godina';

  @override
  String get noAccessBody => 'Zamoli admina da te doda.';

  @override
  String get noAccessTitle => 'Nemaš pristup';

  @override
  String get noJobsThatDay => 'Za ovaj dan nema termina.';

  @override
  String noJobsThisMonth(String month) {
    return 'Nema završenih poslova za $month.';
  }

  @override
  String get noJobsThisYear => 'Nema završenih poslova te godine.';

  @override
  String get noWorkersYet =>
      'Još nema radnika. Admin ih dodaje u meniju Radnici.';

  @override
  String notEnoughBody(String amount) {
    return 'Može da se potroši najviše $amount. Prvo ubaci novac ili potroši manje.';
  }

  @override
  String get notEnoughTitle => 'Nema dovoljno u novčaniku';

  @override
  String notFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nije završeno · $count',
      few: 'Nije završeno · $count',
      one: 'Nije završeno · $count',
    );
    return '$_temp0';
  }

  @override
  String get notIntoWallet => 'Nije ušlo u novčanik';

  @override
  String get notes => 'Napomena (nije obavezno)';

  @override
  String get notesHint => 'Koji auto, sprat, interfon…';

  @override
  String get notifications => 'Obaveštenja';

  @override
  String get notificationsHint => 'Izaberi koja dobijaš';

  @override
  String get ok => 'U redu';

  @override
  String get onEquipment => 'Na opremu';

  @override
  String get open => 'Otvori';

  @override
  String get otherCosts => 'Ostali troškovi';

  @override
  String otherCostsShort(String amount) {
    return 'ostali troškovi $amount';
  }

  @override
  String get over => 'Iznad';

  @override
  String get paidToHelpers => 'Isplaćeno radnicima';

  @override
  String get password => 'Lozinka';

  @override
  String get passwordChanged => 'Lozinka je promenjena.';

  @override
  String get passwordsNoMatch => 'Lozinke se ne poklapaju';

  @override
  String get paysThem => 'Iznos';

  @override
  String get phone => 'Telefon (nije obavezno)';

  @override
  String get pickAHelper => 'Izaberi ko pomaže ili prebaci na „Radim sam”.';

  @override
  String get pickStartTime => 'Izaberi vreme početka.';

  @override
  String pickedCount(int count) {
    return 'izabrano: $count';
  }

  @override
  String get previousMonth => 'Prethodni mesec';

  @override
  String get previousYear => 'Prethodna godina';

  @override
  String get price => 'Cena';

  @override
  String get priceList => 'Cenovnik';

  @override
  String get priceListAdminHint =>
      'Dodir na stavku je menja, dugi pritisak je sklanja. Dodir na uslove ih menja.';

  @override
  String get priceListEmpty => 'Cenovnik je prazan. Postavlja ga admin.';

  @override
  String get priceListEmptyAdmin =>
      'Cenovnik je prazan. Učitaj vaš cenovnik jednim dodirom, pa izmeni šta želiš.';

  @override
  String get priceTypedOver => 'Upisano ručno, ne po cenovniku';

  @override
  String get profile => 'Profil';

  @override
  String get pushJobCancelled => 'Termin otkazan';

  @override
  String get pushJobChanged => 'Termin izmenjen';

  @override
  String get pushJobNew => 'Novi termin';

  @override
  String get pushJobTomorrow => 'Sutra';

  @override
  String get putIn => 'Ubaci';

  @override
  String readOnlyNotice(String name) {
    return 'Uneo/la: $name. Menjati može samo on/a ili admin.';
  }

  @override
  String get removedCategory => 'Sklonjena kategorija';

  @override
  String get reopen => 'Vrati u zakazano';

  @override
  String get reopenCancelledBody => 'Termin ponovo važi.';

  @override
  String get reopenDoneBody => 'Naplaćeno izlazi iz novčanika i iz zarade.';

  @override
  String get reopenTitle => 'Vratiti u zakazano?';

  @override
  String get required => 'Obavezno';

  @override
  String get resetSent => 'Poslat je email za promenu lozinke.';

  @override
  String get review => 'Pregled';

  @override
  String get reviewHint =>
      'Ovde menjaš količine, a za još stavki se vrati na cenovnik.';

  @override
  String reviewWithTotal(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pregled · $count stavki · $total',
      few: 'Pregled · $count stavke · $total',
      one: 'Pregled · $count stavka · $total',
    );
    return '$_temp0';
  }

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleWorker => 'Radnik';

  @override
  String get save => 'Sačuvaj';

  @override
  String get sendLink => 'Pošalji';

  @override
  String get settings => 'Podešavanja';

  @override
  String get shareApp => 'Podeli aplikaciju';

  @override
  String get shareAppHint =>
      'Skeniraj kod kamerom drugog telefona ili pošalji link. Android će tražiti dozvolu za instalaciju iz tog izvora.';

  @override
  String get shareAppMessage =>
      'Car Detailing: termini, novčanik i zarada ekipe.';

  @override
  String get signIn => 'Prijavi se';

  @override
  String get signOut => 'Odjavi se';

  @override
  String get spend => 'Potroši';

  @override
  String get spending => 'Potrošeno';

  @override
  String get spentOn => 'Za šta';

  @override
  String get spentOnHint => 'Hemija, krpe, gorivo…';

  @override
  String get startPassword => 'Početna lozinka';

  @override
  String get startPasswordHint =>
      'Javi je radniku; može da je promeni u Podešavanjima.';

  @override
  String get startTime => 'Početak';

  @override
  String get statusBooked => 'Zakazano';

  @override
  String get statusCancelled => 'Otkazano';

  @override
  String get statusDone => 'Završeno';

  @override
  String get statusOverdue => 'Nije završeno';

  @override
  String get subtotal => 'Zbir';

  @override
  String get switchedOff => 'Isključeni';

  @override
  String get synced => 'Sinhronizovano';

  @override
  String get syncing => 'Sinhronizujem…';

  @override
  String get tabCalendar => 'Kalendar';

  @override
  String get tabEarnings => 'Zarada';

  @override
  String get tabWallet => 'Novčanik';

  @override
  String get terms => 'Uslovi';

  @override
  String toHelpersShort(String amount) {
    return 'radnicima $amount';
  }

  @override
  String get travel => 'Dolazak';

  @override
  String get travelFee => 'Dolazak ispod toga';

  @override
  String get travelFeeHint => '0 = uvek besplatno';

  @override
  String travelFeeRule(String amount) {
    return 'Dolazak ispod toga: $amount';
  }

  @override
  String get tryAgain => 'Pokušaj ponovo';

  @override
  String untilTime(String time) {
    return 'do $time';
  }

  @override
  String get upToDate => 'Imaš najnoviju verziju.';

  @override
  String get updateCheckFailed => 'Provera ažuriranja nije uspela.';

  @override
  String get usePriceListPrice => 'Vrati cenu po cenovniku';

  @override
  String get wait => 'Sačekaj…';

  @override
  String get walletEmpty => 'Još ništa. Završeni poslovi ovde ulaze sami.';

  @override
  String get wentIntoWallet => 'Ušlo u novčanik';

  @override
  String get whatIsDone => 'Šta se radi';

  @override
  String get whoDeposited => 'Ko je ubacio';

  @override
  String get whoSpent => 'Ko je potrošio';

  @override
  String get whoWorked => 'Ko je radio';

  @override
  String get whoWorks => 'Ko radi';

  @override
  String get withHelp => 'Imam pomoć';

  @override
  String get withoutPriceList => 'Van cenovnika';

  @override
  String get workerAdded => 'Radnik je dodat. Javi mu email i početnu lozinku.';

  @override
  String get workers => 'Radnici';

  @override
  String get workingAlone => 'Radim sam';

  @override
  String get workingAloneShort => 'Radi sam';

  @override
  String get year => 'Godina';
}
