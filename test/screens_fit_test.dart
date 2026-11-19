import 'package:car_detailing/l10n/locale_controller.dart';
import 'package:car_detailing/screens/calendar_tab.dart';
import 'package:car_detailing/screens/earnings_tab.dart';
import 'package:car_detailing/screens/job_detail_screen.dart';
import 'package:car_detailing/screens/job_form_screen.dart';
import 'package:car_detailing/screens/price_list_screen.dart';
import 'package:car_detailing/screens/wallet_tab.dart';
import 'package:car_detailing/screens/welcome_screen.dart';
import 'package:car_detailing/screens/workers_screen.dart';
import 'package:car_detailing/widgets/app_drawer.dart';
import 'package:car_detailing/widgets/bottom_nav.dart';
import 'package:car_detailing/models/day_key.dart';
import 'package:car_detailing/models/job.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// Every screen, both languages, on a small phone, with long names and
/// addresses: nothing may overflow.
void main() {
  for (final locale in [kSerbianLatin, const Locale('en')]) {
    final lang = locale.languageCode;
    final sr = lang == 'sr';

    Future<void> fits(
      WidgetTester tester,
      Widget screen, {
      bool scaffold = true,
    }) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        inApp(screen, locale: locale, scaffold: scaffold),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    testWidgets('calendar fits 360 px ($lang)', (tester) async {
      await fits(
        tester,
        CalendarTab(
          data: fakeData(),
          profile: admin,
          selected: dayOf(DateTime.now()),
          onSelect: (_) {},
        ),
      );
      expect(
        find.text(
          (sr ? 'Nije završeno · 2' : 'Not finished · 2').toUpperCase(),
        ),
        findsOneWidget,
      );
    });

    testWidgets('wallet fits 360 px ($lang)', (tester) async {
      await fits(tester, WalletTab(data: fakeData(), profile: worker));
    });

    testWidgets('booking with two helpers fits 360 px ($lang)', (tester) async {
      final data = fakeData();
      await fits(
        tester,
        JobFormScreen(data: data, profile: admin, day: DateTime.now()),
        scaffold: false,
      );
      final withHelp = find.text(sr ? 'Imam pomoć' : 'I have help');
      await tester.ensureVisible(withHelp);
      await tester.tap(withHelp);
      await tester.pumpAndSettle();
      // Only the active workers, never the admin or someone switched off.
      expect(find.text('Marko Jovanović-Stefanović'), findsOneWidget);
      expect(find.text('Ana-Marija Radosavljević-Petrović'), findsOneWidget);
      expect(find.text('Nikola'), findsNothing);
      for (final name in [
        'Marko Jovanović-Stefanović',
        'Ana-Marija Radosavljević-Petrović',
      ]) {
        await tester.ensureVisible(find.text(name));
        await tester.tap(find.text(name));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(find.text(sr ? 'Ostaje tebi' : 'Left for you'), findsOneWidget);
      // No equipment: that goes in the wallet.
      expect(find.textContaining(sr ? 'oprem' : 'quipment'), findsNothing);
    });

    testWidgets('finishing a job with helpers fits 360 px ($lang)', (
      tester,
    ) async {
      await fits(
        tester,
        JobDetailScreen(data: fakeData(), profile: admin, jobId: 'today'),
        scaffold: false,
      );
      final finish = find.text(sr ? 'Završi posao' : 'Finish job');
      await tester.scrollUntilVisible(
        finish,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(finish);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Prefilled from the booking: Marko's pay; no equipment field.
      expect(find.text('3000'), findsOneWidget);
      expect(find.textContaining(sr ? 'oprem' : 'quipment'), findsNothing);
    });

    testWidgets(
      'a worker only looks at a job, and sees only their pay ($lang)',
      (tester) async {
        final data = fakeData()
          ..jobs = [
            for (final (id, status) in [
              ('b', JobStatus.booked),
              ('d', JobStatus.done),
            ])
              jobOn(
                dayFromToday(0),
                id: id,
                status: status,
                helpers: const [
                  JobHelper(uid: 'marko', payMinor: 300000),
                  JobHelper(uid: 'ana', payMinor: 250000),
                ],
              ),
          ];
        for (final id in ['b', 'd']) {
          await fits(
            tester,
            JobDetailScreen(
              key: ValueKey(id),
              data: data,
              profile: worker,
              jobId: id,
            ),
            scaffold: false,
          );
          // The client's price, and their own pay; nobody else's, nothing
          // of what the admin keeps or of the wallet.
          expect(
            find.text(sr ? 'Dogovorena cena' : 'Agreed price'),
            findsOneWidget,
          );
          expect(find.text(sr ? 'Moja zarada' : 'My earnings'), findsOneWidget);
          expect(
            find.textContaining(sr ? 'Pomoćnik:' : 'Helper:'),
            findsNothing,
          );
          expect(find.text(sr ? 'Ostaje tebi' : 'Left for you'), findsNothing);
          expect(find.textContaining(sr ? 'novčanik' : 'wallet'), findsNothing);
          // No way to change it, down to the bottom of the screen.
          expect(find.byIcon(Icons.edit_outlined), findsNothing);
          expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -800),
          );
          await tester.pump();
          for (final label
              in sr
                  ? ['Završi posao', 'Otkaži termin', 'Vrati u zakazano']
                  : ['Finish job', 'Cancel booking', 'Back to booked']) {
            expect(find.text(label), findsNothing);
          }
        }
      },
    );

    testWidgets('the admin sees every helper and what is left ($lang)', (
      tester,
    ) async {
      await fits(
        tester,
        JobDetailScreen(data: fakeData(), profile: admin, jobId: 'today'),
        scaffold: false,
      );
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.textContaining(sr ? 'Pomoćnik:' : 'Helper:'), findsOneWidget);
      expect(find.text(sr ? 'Ostaje tebi' : 'Left for you'), findsOneWidget);
    });

    testWidgets('a final discount shows on the job ($lang)', (tester) async {
      final data = fakeData()
        ..jobs = [jobOn(dayFromToday(0), id: 'fd', finalDiscountPercent: 10)];
      await fits(
        tester,
        JobDetailScreen(data: data, profile: admin, jobId: 'fd'),
        scaffold: false,
      );
      expect(
        find.text(sr ? 'Konačan popust 10%' : 'Final discount 10%'),
        findsOneWidget,
      );
    });

    testWidgets('wallet month: the admin sees the split ($lang)', (
      tester,
    ) async {
      await fits(tester, WalletTab(data: fakeData(), profile: admin));
      expect(find.text(sr ? 'Moja zarada' : 'My earnings'), findsOneWidget);
      expect(
        find.text(sr ? 'Dato radnicima' : 'Given to helpers'),
        findsOneWidget,
      );
      expect(find.text(sr ? 'Troškovi' : 'Costs'), findsOneWidget);
    });

    testWidgets('a worker has no wallet tab ($lang)', (tester) async {
      await fits(tester, BottomNav(index: 0, onSelect: (_) {}, wallet: false));
      expect(find.text(sr ? 'Kalendar' : 'Calendar'), findsOneWidget);
      expect(find.text(sr ? 'Zarada' : 'Earnings'), findsOneWidget);
      expect(find.text(sr ? 'Novčanik' : 'Wallet'), findsNothing);
    });

    testWidgets('a worker sees only their own earnings ($lang)', (
      tester,
    ) async {
      await fits(tester, EarningsTab(data: fakeData(), profile: worker));
      expect(find.text(sr ? 'Moja zarada' : 'My earnings'), findsOneWidget);
      for (final label
          in sr
              ? [
                  'Naplaćeno',
                  'Dato radnicima',
                  'Troškovi',
                  'Isplaćeno radnicima',
                ]
              : ['Charged', 'Given to helpers', 'Costs', 'Paid to helpers']) {
        expect(find.text(label), findsNothing);
      }
    });

    testWidgets('earnings fit 360 px, month and year ($lang)', (tester) async {
      await fits(tester, EarningsTab(data: fakeData(), profile: worker));
      await tester.tap(find.text(sr ? 'Godina' : 'Year'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    for (final id in ['today', 'done', 'off', 'plain']) {
      testWidgets('job "$id" fits 360 px ($lang)', (tester) async {
        await fits(
          tester,
          JobDetailScreen(data: fakeData(), profile: worker, jobId: id),
          scaffold: false,
        );
      });
    }

    testWidgets('job form fits 360 px ($lang)', (tester) async {
      final data = fakeData();
      await fits(
        tester,
        JobFormScreen(data: data, profile: admin, job: data.jobById('today')),
        scaffold: false,
      );
      // A job has only a start time.
      expect(find.text(sr ? 'Početak' : 'Start'), findsOneWidget);
      expect(find.text(sr ? 'Kraj' : 'End'), findsNothing);
      // The final discount sets the agreed price: 13.515 − 10% = 12.163.
      final discount = find.widgetWithText(
        TextFormField,
        sr ? 'Konačan popust' : 'Final discount',
      );
      await tester.scrollUntilVisible(
        discount,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(discount, '10');
      await tester.pump();
      expect(find.text('12163'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await fits(
        tester,
        JobFormScreen(data: data, profile: admin, day: DateTime.now()),
        scaffold: false,
      );
    });

    testWidgets('item picker fits 360 px, categories open in place ($lang)', (
      tester,
    ) async {
      final data = fakeData();
      await fits(
        tester,
        JobFormScreen(data: data, profile: admin, job: data.jobById('today')),
        scaffold: false,
      );
      await tester.tap(
        find.text(sr ? 'Dodaj iz cenovnika' : 'Add from the price list'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Closed: the category shows, its note does not.
      expect(find.textContaining('tapacirung vrata'), findsNothing);
      await tester.tap(find.text('Premium detailing'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Open in place: the note shows and the other category stays.
      expect(find.textContaining('tapacirung vrata'), findsOneWidget);
      expect(find.text('Nameštaj od štofa i mebla'), findsOneWidget);
      // Opening another closes the first.
      await tester.tap(find.text('Nameštaj od štofa i mebla'));
      await tester.pumpAndSettle();
      expect(find.textContaining('tapacirung vrata'), findsNothing);
      expect(tester.takeException(), isNull);
      // The button leads to the review; only there is "Done".
      expect(find.textContaining(sr ? 'Gotovo' : 'Done'), findsNothing);
      await tester.tap(find.textContaining(sr ? 'Pregled · 7' : 'Review · 7'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining(
          sr ? '1 × 12.000 RSD = 12.000 RSD' : '1 × 12,000 RSD = 12,000 RSD',
        ),
        findsOneWidget,
      );
      expect(find.textContaining(sr ? 'Gotovo' : 'Done'), findsOneWidget);
      await tester.tap(
        find.byTooltip(sr ? 'Nazad na cenovnik' : 'Back to the price list'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Premium detailing'), findsOneWidget);
    });

    testWidgets('price list fits 360 px ($lang)', (tester) async {
      await fits(
        tester,
        PriceListScreen(data: fakeData(), profile: admin),
        scaffold: false,
      );
    });

    testWidgets('workers fit 360 px ($lang)', (tester) async {
      await fits(
        tester,
        WorkersScreen(data: fakeData(), profile: admin),
        scaffold: false,
      );
    });

    testWidgets('side menu fits 360 px, sign-out last ($lang)', (tester) async {
      final key = GlobalKey<ScaffoldState>();
      await fits(
        tester,
        Scaffold(
          key: key,
          drawer: AppDrawer(data: fakeData(), profile: worker),
          body: const SizedBox(),
        ),
        scaffold: false,
      );
      key.currentState!.openDrawer();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final signOut = find.text(sr ? 'Odjavi se' : 'Sign out');
      final share = find.text(sr ? 'Podeli aplikaciju' : 'Share the app');
      expect(signOut, findsOneWidget);
      // At the bottom of the menu, below everything else.
      expect(
        tester.getTopLeft(signOut).dy,
        greaterThan(tester.getTopLeft(share).dy + 200),
      );
    });

    testWidgets('welcome fits 360 px ($lang)', (tester) async {
      await fits(tester, WelcomeScreen(onDone: () {}), scaffold: false);
    });
  }
}
