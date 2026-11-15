import 'package:car_detailing/models/earnings.dart';
import 'package:car_detailing/models/job.dart';
import 'package:car_detailing/models/pricing.dart';
import 'package:car_detailing/models/wallet_entry.dart';
import 'package:flutter_test/flutter_test.dart';

Job job(
  String date, {
  JobStatus status = JobStatus.done,
  int price = 500000,
  int? paid,
  List<String> workers = const [],
  List<JobItem> items = const [],
  bool toWallet = true,
}) => Job(
  id: date + price.toString(),
  date: date,
  start: '09:00',
  priceMinor: price,
  paidMinor: status == JobStatus.done ? (paid ?? price) : null,
  status: status,
  workers: workers,
  items: items,
  toWallet: toWallet,
);

WalletEntry entry(DateTime date, int amount, {bool spending = true}) =>
    WalletEntry(
      type: spending ? WalletEntryType.withdrawal : WalletEntryType.deposit,
      amountMinor: amount,
      description: 'x',
      date: date,
      userId: 'u',
      createdBy: 'u',
    );

void main() {
  group('Earnings', () {
    final jobs = [
      job('2026-11-03', price: 500000, workers: ['a']),
      job('2026-11-16', price: 918000, workers: ['a', 'b']),
      job('2026-11-20', status: JobStatus.booked),
      job('2026-11-21', status: JobStatus.cancelled),
      job('2026-10-30', price: 100000),
      job('2026-11-25', price: 300000, paid: 250000),
    ];
    final entries = [
      entry(DateTime(2026, 11, 5), 120000),
      entry(DateTime(2026, 11, 6), 200000, spending: false),
      entry(DateTime(2026, 10, 6), 999900),
    ];
    final nov = Earnings.of(
      jobs: jobs,
      entries: entries,
      from: DateTime(2026, 11),
      to: DateTime(2026, 12),
    );

    test('counts only done jobs of the month, at what was charged', () {
      expect(nov.jobCount, 3);
      expect(nov.earnedMinor, 500000 + 918000 + 250000);
      expect(nov.cancelled, 1);
      expect(nov.averageMinor, (500000 + 918000 + 250000) ~/ 3);
    });

    test('costs are spending; deposits are shown apart', () {
      expect(nov.spendingMinor, 120000);
      expect(nov.depositsMinor, 200000);
      expect(nov.netMinor, nov.earnedMinor - 120000);
    });

    test('workers share a job equally and it adds up', () {
      expect(nov.byWorker['a'], 500000 + 459000);
      expect(nov.byWorker['b'], 459000);
      expect(nov.unassignedMinor, 250000);
      final shared = nov.byWorker.values.fold<int>(0, (a, v) => a + v);
      expect(shared + nov.unassignedMinor, nov.earnedMinor);
    });

    test('a year view sums each month', () {
      final y = Earnings.of(
        jobs: jobs,
        entries: entries,
        from: DateTime(2026),
        to: DateTime(2027),
      );
      expect(y.byMonth[9], 100000);
      expect(y.byMonth[10], nov.earnedMinor);
      expect(y.jobCount, 4);
    });
  });

  test('worker shares are whole dinars, a leftover dinar to the first', () {
    final shares = workerShares(
      job('2026-11-01', price: 1351500, workers: ['a', 'b']),
    );
    expect(shares, {'a': 675800, 'b': 675700});
    final odd = workerShares(
      job('2026-11-01', price: 100050, workers: ['a', 'b', 'c']),
    );
    expect(odd, {'a': 33450, 'b': 33300, 'c': 33300});
  });

  test('category shares follow the list price and add up to what was paid', () {
    final j = job(
      '2026-11-01',
      price: 558000,
      items: const [
        JobItem(
          itemId: '1',
          categoryId: 'koza',
          name: 'Kožni trosed',
          priceMinor: 320000,
        ),
        JobItem(
          itemId: '2',
          categoryId: 'stof',
          name: 'Fotelja',
          priceMinor: 150000,
          qty: 2,
        ),
      ],
    );
    final shares = categoryShares(j);
    expect(shares.values.fold<int>(0, (a, v) => a + v), 558000);
    expect(shares['koza'], 288000);
    expect(shares['stof'], 270000);
  });

  test('a job without items counts as "not from the price list"', () {
    expect(categoryShares(job('2026-11-01', price: 300000)), {
      kNoCategory: 300000,
    });
  });

  test('splitByWeight always adds up exactly', () {
    for (final total in [0, 1, 99, 100001, 918000]) {
      final parts = splitByWeight(total, [3, 7, 11]);
      expect(parts.fold<int>(0, (a, v) => a + v), total);
    }
    expect(splitByWeight(10, [0, 0]), [5, 5]);
  });

  group('wallet', () {
    final jobs = [
      job('2026-11-03', price: 500000),
      job('2026-11-04', price: 200000, toWallet: false),
      job('2026-11-05', status: JobStatus.booked),
    ];
    final entries = [entry(DateTime(2026, 11, 5), 120000)];

    test('finished jobs with "into the wallet" come in by themselves', () {
      final m = WalletMovement.merge(jobs, entries);
      expect(m.length, 2);
      expect(WalletMovement.balance(m), 500000 - 120000);
    });

    test('spending cannot take the wallet below zero', () {
      const balance = 380000;
      final ok = entry(DateTime(2026, 11, 6), 380000);
      final tooMuch = entry(DateTime(2026, 11, 6), 380100);
      expect(WalletMovement.overdraws(balance, ok), isFalse);
      expect(WalletMovement.overdraws(balance, tooMuch), isTrue);
    });

    test('editing a spending counts what it already took out', () {
      final old = entry(DateTime(2026, 11, 5), 120000);
      final bigger = entry(DateTime(2026, 11, 5), 500000);
      expect(WalletMovement.available(380000, old: old), 500000);
      expect(WalletMovement.overdraws(380000, bigger, old: old), isFalse);
    });
  });

  test('a booked job whose day passed is overdue', () {
    final now = DateTime(2026, 11, 16, 8);
    expect(job('2026-11-15', status: JobStatus.booked).isOverdue(now), isTrue);
    expect(job('2026-11-16', status: JobStatus.booked).isOverdue(now), isFalse);
    expect(job('2026-11-15').isOverdue(now), isFalse);
  });
}
