import 'package:car_detailing/l10n/app_localizations.dart';
import 'package:car_detailing/l10n/locale_controller.dart';
import 'package:car_detailing/models/app_user.dart';
import 'package:car_detailing/models/day_key.dart';
import 'package:car_detailing/models/job.dart';
import 'package:car_detailing/models/price_list.dart';
import 'package:car_detailing/models/pricing.dart';
import 'package:car_detailing/models/wallet_entry.dart';
import 'package:car_detailing/services/live_data.dart';
import 'package:car_detailing/theme/app_colors.dart';
import 'package:car_detailing/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// [child] in the app's theme and language, as the real app shows it.
Widget inApp(Widget child, {Locale? locale, bool scaffold = true}) =>
    MaterialApp(
      theme: AppTheme.build(kCeramic),
      locale: locale ?? kSerbianLatin,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: scaffold ? Scaffold(body: child) : child,
    );

const admin = AppUser(
  uid: 'stefan',
  email: 'stefan@x.rs',
  role: UserRole.admin,
  disabled: false,
  firstName: 'Stefan',
  lastName: 'Petrović',
  phone: '061 123 4567',
);

const worker = AppUser(
  uid: 'marko',
  email: 'marko@x.rs',
  role: UserRole.worker,
  disabled: false,
  firstName: 'Marko',
  lastName: 'Jovanović-Stefanović',
);

const gone = AppUser(
  uid: 'nikola',
  email: 'nikola@x.rs',
  role: UserRole.worker,
  disabled: true,
  firstName: 'Nikola',
);

const helper2 = AppUser(
  uid: 'ana',
  email: 'ana@x.rs',
  role: UserRole.worker,
  disabled: false,
  firstName: 'Ana-Marija',
  lastName: 'Radosavljević-Petrović',
);

/// A day relative to today, as a date key.
String dayFromToday(int offset) =>
    dateKey(DateTime.now().add(Duration(days: offset)));

const sofa = JobItem(
  itemId: 'i1',
  categoryId: 'stof',
  name: 'Ugaona garnitura (po sednom mestu)',
  priceMinor: 65000,
  qty: 6,
);
const premium = JobItem(
  itemId: 'i2',
  categoryId: 'premium',
  name: 'Premium – SUV / 7 sedišta',
  priceMinor: 1200000,
);

Job jobOn(
  String date, {
  String id = 'j',
  JobStatus status = JobStatus.booked,
  List<JobItem> items = const [sofa, premium],
  List<JobHelper> helpers = const [JobHelper(uid: 'marko', payMinor: 300000)],
  int finalDiscountPercent = 0,
}) => Job(
  id: id,
  ownerId: 'stefan',
  date: date,
  start: '09:30',
  clientName: 'Jelena Marković-Radosavljević',
  clientPhone: '064 987 6543',
  address: 'Bulevar kralja Aleksandra 123, stan 45, Beograd',
  items: items,
  subtotalMinor: 1590000,
  discountPercent: 15,
  priceMinor: 1351500,
  finalDiscountPercent: finalDiscountPercent,
  helpers: helpers,
  notes: 'Audi Q7 crni, BG-123-XY. Interfon ne radi, zvati.',
  status: status,
  paidMinor: status == JobStatus.done ? 1351500 : null,
  rev: 1,
  updatedBy: 'stefan',
  createdAt: DateTime(2026),
);

/// Live data that never touches Firestore.
LiveData fakeData() {
  final now = DateTime.now();
  return LiveData(listen: false)
    ..users = const [admin, worker, helper2, gone]
    ..jobs = [
      jobOn(dayFromToday(0), id: 'today'),
      jobOn(dayFromToday(0), id: 'today2', items: const [sofa]),
      jobOn(dayFromToday(-2), id: 'late'),
      jobOn(dayFromToday(-1), id: 'done', status: JobStatus.done),
      jobOn(dayFromToday(-1), id: 'off', status: JobStatus.cancelled),
      jobOn(dayFromToday(-1), id: 'plain', items: const [], helpers: const []),
    ]
    ..entries = [
      WalletEntry(
        id: 'e1',
        type: WalletEntryType.withdrawal,
        amountMinor: 450000,
        description: 'Hemija za dubinsko pranje i nove mikrofiber krpe',
        date: now,
        userId: 'marko',
        createdBy: 'marko',
      ),
      WalletEntry(
        id: 'e2',
        type: WalletEntryType.deposit,
        amountMinor: 1000000,
        description: '',
        date: now,
        userId: 'stefan',
        createdBy: 'stefan',
      ),
    ]
    ..categories = const [
      PriceCategory(id: 'stof', name: 'Nameštaj od štofa i mebla', order: 0),
      PriceCategory(
        id: 'premium',
        name: 'Premium detailing',
        note:
            'Standard + tapacirung vrata, detaljno čišćenje plastike, '
            'ventilacija, šina i pukotina četkicama, stakla iznutra.',
        order: 1,
      ),
    ]
    ..items = const [
      PriceItem(
        id: 'i1',
        categoryId: 'stof',
        name: 'Ugaona garnitura (po sednom mestu)',
        priceMinor: 65000,
      ),
      PriceItem(
        id: 'i2',
        categoryId: 'premium',
        name: 'Premium – SUV / 7 sedišta',
        priceMinor: 1200000,
      ),
    ];
}
