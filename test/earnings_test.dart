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
  List<JobHelper> helpers = const [],
  List<JobItem> items = const [],
  bool toWallet = true,
}) => Job(
  id: date + price.toString(),
  date: date,
  start: '09:00',
  priceMinor: price,
  paidMinor: status == JobStatus.done ? (paid ?? price) : null,
  status: status,
  helpers: helpers,
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
      job(
        '2026-11-03',
        price: 500000,
        helpers: const [JobHelper(uid: 'a', payMinor: 100000)],
      ),
      job(
        '2026-11-16',
        price: 918000,
        helpers: const [
          JobHelper(uid: 'a', payMinor: 150000),
          JobHelper(uid: 'b', payMinor: 150000),
        ],
      ),
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

    test('costs are wallet spending; deposits are shown apart', () {
      expect(nov.spendingMinor, 120000);
      expect(nov.depositsMinor, 200000);
    });

    test('helpers get what they were paid, the admin the rest', () {
      expect(nov.helpersPaidMinor, 400000);
      expect(nov.byHelper, {'a': 250000, 'b': 150000});
      expect(nov.paidTo('a'), 250000);
      expect(nov.paidTo('nobody'), 0);
      // Charged, less the helpers and the spending (equipment included).
      expect(nov.adminNetMinor, 1668000 - 400000 - 120000);
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

  group('a job with helpers', () {
    final j = job(
      '2026-11-16',
      price: 918000,
      helpers: const [
        JobHelper(uid: 'a', payMinor: 150000),
        JobHelper(uid: 'b', payMinor: 150000),
      ],
    );

    test('leaves the admin the price less the helpers', () {
      expect(j.helpersPaidMinor, 300000);
      expect(j.netMinor, 918000 - 300000);
      expect(j.workers, ['a', 'b']);
      final booked = job('2026-11-20', status: JobStatus.booked, price: 5000);
      expect(booked.netMinor, 0);
    });

    test('writes helpers and, for older apps, workers and an empty end', () {
      final f = j.formFields();
      expect(f['helpers'], [
        {'uid': 'a', 'payMinor': 150000},
        {'uid': 'b', 'payMinor': 150000},
      ]);
      expect(f['workers'], ['a', 'b']);
      expect(f['end'], '');
      expect(f.containsKey('equipmentMinor'), isFalse);
    });
  });

  group('jobs from v1.0.x, without helpers', () {
    test('the live job: booked by the admin, who works on it alone', () {
      final j = Job.fromMap('x', {
        'ownerId': 'filip',
        'date': '2026-11-19',
        'workers': ['filip'],
        'status': 'booked',
        'priceMinor': 210000,
      });
      expect(j.helpers, isEmpty);
    });

    test('an end time is dropped: a job has only its start', () {
      final j = Job.fromMap('x', {'start': '09:30', 'end': '13:00'});
      expect(j.start, '09:30');
      expect(j.formFields()['end'], '');
    });

    test('other people on it become helpers with no pay recorded', () {
      final j = Job.fromMap('x', {
        'ownerId': 'filip',
        'workers': ['filip', 'petar'],
        'status': 'done',
        'paidMinor': 500000,
      });
      expect(j.helpers.map((h) => (h.uid, h.payMinor)), [('petar', 0)]);
      expect(j.netMinor, 500000);
    });
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

  test('equipment written by v1.1.0 is ignored: it goes in the wallet', () {
    final j = Job.fromMap('x', {
      'status': 'done',
      'paidMinor': 500000,
      'helpers': [
        {'uid': 'a', 'payMinor': 100000},
      ],
      'equipmentMinor': 20000,
    });
    expect(j.netMinor, 400000);
  });

  group('wallet', () {
    final jobs = [
      job(
        '2026-11-03',
        price: 500000,
        helpers: const [JobHelper(uid: 'a', payMinor: 100000)],
      ),
      job('2026-11-04', price: 200000, toWallet: false),
      job('2026-11-05', status: JobStatus.booked),
    ];
    final entries = [entry(DateTime(2026, 11, 5), 120000)];

    test('a finished job brings in what the helpers leave', () {
      final m = WalletMovement.merge(jobs, entries);
      expect(m.length, 2);
      final fromJob = m.firstWhere((x) => x.job != null);
      expect(fromJob.signedMinor, 500000 - 100000);
      expect(WalletMovement.balance(m), 400000 - 120000);
    });

    test('spending cannot take the wallet below zero', () {
      const balance = 400000;
      final ok = entry(DateTime(2026, 11, 6), 400000);
      final tooMuch = entry(DateTime(2026, 11, 6), 400100);
      expect(WalletMovement.overdraws(balance, ok), isFalse);
      expect(WalletMovement.overdraws(balance, tooMuch), isTrue);
    });

    test('editing a spending counts what it already took out', () {
      final old = entry(DateTime(2026, 11, 5), 120000);
      final bigger = entry(DateTime(2026, 11, 5), 500000);
      expect(WalletMovement.available(400000, old: old), 520000);
      expect(WalletMovement.overdraws(400000, bigger, old: old), isFalse);
    });
  });

  test('a booked job whose day passed is overdue', () {
    final now = DateTime(2026, 11, 16, 8);
    expect(job('2026-11-15', status: JobStatus.booked).isOverdue(now), isTrue);
    expect(job('2026-11-16', status: JobStatus.booked).isOverdue(now), isFalse);
    expect(job('2026-11-15').isOverdue(now), isFalse);
  });
}
