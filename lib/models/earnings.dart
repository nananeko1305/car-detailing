import 'day_key.dart';
import 'job.dart';
import 'wallet_entry.dart';

/// The category key for jobs written without price-list items.
const String kNoCategory = '';

/// What a month or a year earned, computed from the jobs every time and never
/// stored, so it cannot drift. A job counts on its own day, and only once
/// it is done. The profit is the admin's: what was charged, less the
/// helpers' pay, the equipment and the other spending.
class Earnings {
  const Earnings._({
    required this.earnedMinor,
    required this.done,
    required this.cancelled,
    required this.byCategory,
    required this.byHelper,
    required this.helpersPaidMinor,
    required this.equipmentMinor,
    required this.depositsMinor,
    required this.spendingMinor,
    required this.byMonth,
  });

  /// From the first day of [from] up to, not including, [to].
  factory Earnings.of({
    required List<Job> jobs,
    required List<WalletEntry> entries,
    required DateTime from,
    required DateTime to,
  }) {
    final fromKey = dateKey(from);
    final toKey = dateKey(to);
    bool inRange(String key) =>
        key.compareTo(fromKey) >= 0 && key.compareTo(toKey) < 0;

    final done = <Job>[];
    var cancelled = 0;
    final byCategory = <String, int>{};
    final byHelper = <String, int>{};
    var helpersPaid = 0;
    var equipment = 0;
    final byMonth = List<int>.filled(12, 0);
    for (final j in jobs) {
      if (!inRange(j.date)) continue;
      if (j.isCancelled) cancelled++;
      if (!j.isDone) continue;
      done.add(j);
      final earned = j.earnedMinor;
      byMonth[j.day.month - 1] += earned;
      _addAll(byCategory, categoryShares(j));
      for (final h in j.helpers) {
        byHelper[h.uid] = (byHelper[h.uid] ?? 0) + h.payMinor;
      }
      helpersPaid += j.helpersPaidMinor;
      equipment += j.equipmentMinor;
    }
    done.sort((a, b) {
      final byDay = b.date.compareTo(a.date);
      return byDay != 0 ? byDay : b.start.compareTo(a.start);
    });

    var deposits = 0;
    var spending = 0;
    for (final e in entries) {
      if (!inRange(dateKey(e.date))) continue;
      if (e.isSpending) {
        spending += e.amountMinor;
      } else {
        deposits += e.amountMinor;
      }
    }

    return Earnings._(
      earnedMinor: done.fold(0, (total, j) => total + j.earnedMinor),
      done: done,
      cancelled: cancelled,
      byCategory: byCategory,
      byHelper: byHelper,
      helpersPaidMinor: helpersPaid,
      equipmentMinor: equipment,
      depositsMinor: deposits,
      spendingMinor: spending,
      byMonth: byMonth,
    );
  }

  final int earnedMinor;

  /// Finished jobs, newest first.
  final List<Job> done;
  final int cancelled;

  /// Category id → earned; [kNoCategory] for jobs without items.
  final Map<String, int> byCategory;

  /// Helper uid → what they were paid, over the finished jobs.
  final Map<String, int> byHelper;

  /// Paid to helpers, all of them together.
  final int helpersPaidMinor;

  /// Spent on equipment for the finished jobs.
  final int equipmentMinor;

  /// Money put into the wallet by hand: not earnings, shown apart.
  final int depositsMinor;

  /// Spending from the wallet by hand: the other costs.
  final int spendingMinor;

  /// Earned per calendar month, January first (for the year view).
  final List<int> byMonth;

  int get jobCount => done.length;
  int get averageMinor => done.isEmpty ? 0 : earnedMinor ~/ done.length;

  /// The admin's profit: charged, less helpers, equipment and other costs.
  int get adminNetMinor =>
      earnedMinor - helpersPaidMinor - equipmentMinor - spendingMinor;

  /// What one helper got.
  int paidTo(String uid) => byHelper[uid] ?? 0;

  static void _addAll(Map<String, int> into, Map<String, int> add) {
    for (final e in add.entries) {
      into[e.key] = (into[e.key] ?? 0) + e.value;
    }
  }
}

/// The job's earning spread over its items' categories in proportion to
/// their list price, so a discount lowers each category alike. Whole dinars;
/// adds up to the earning exactly.
Map<String, int> categoryShares(Job j) {
  final earned = j.earnedMinor;
  if (j.items.isEmpty || earned == 0) return {kNoCategory: earned};
  final weights = <String, int>{};
  for (final i in j.items) {
    weights[i.categoryId] = (weights[i.categoryId] ?? 0) + i.totalMinor;
  }
  final keys = weights.keys.toList();
  final parts = _inDinars(
    earned,
    (dinars) => splitByWeight(dinars, [for (final k in keys) weights[k]!]),
  );
  return {for (var i = 0; i < keys.length; i++) keys[i]: parts[i]};
}

/// Splits [minor] with [split] in whole dinars, nobody gets para; the odd
/// para of an amount that has any go to the first part.
List<int> _inDinars(int minor, List<int> Function(int dinars) split) {
  final parts = [for (final d in split(minor ~/ 100)) d * 100];
  if (parts.isNotEmpty) parts[0] += minor % 100;
  return parts;
}

/// Splits [total] in proportion to [weights], rounding down and handing the
/// rest out by largest remainder. Equal parts when every weight is zero.
List<int> splitByWeight(int total, List<int> weights) {
  if (weights.isEmpty) return const [];
  final weightSum = weights.fold<int>(0, (a, x) => a + x);
  final w = weightSum == 0 ? List.filled(weights.length, 1) : weights;
  final wSum = weightSum == 0 ? weights.length : weightSum;
  final parts = [for (final x in w) total * x ~/ wSum];
  var left = total - parts.fold<int>(0, (a, p) => a + p);
  final order = List.generate(w.length, (i) => i)
    ..sort((a, b) => (total * w[b] % wSum).compareTo(total * w[a] % wSum));
  for (var i = 0; left > 0; i = (i + 1) % order.length, left--) {
    parts[order[i]]++;
  }
  return parts;
}
