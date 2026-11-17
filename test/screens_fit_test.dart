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
import 'package:car_detailing/models/day_key.dart';
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
      // Prefilled from the booking: Marko's pay and the equipment.
      expect(find.text('3000'), findsOneWidget);
      expect(find.text('800'), findsOneWidget);
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
      expect(find.text(sr ? 'Na opremu' : 'On equipment'), findsOneWidget);
    });

    testWidgets('wallet month: a worker sees what they got ($lang)', (
      tester,
    ) async {
      await fits(tester, WalletTab(data: fakeData(), profile: worker));
      expect(find.text(sr ? 'Moja zarada' : 'My earnings'), findsOneWidget);
      // Not the admin's split.
      expect(
        find.text(sr ? 'Dato radnicima' : 'Given to helpers'),
        findsNothing,
      );
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
