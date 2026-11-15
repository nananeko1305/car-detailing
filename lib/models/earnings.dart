import 'day_key.dart';
import 'job.dart';
import 'wallet_entry.dart';

/// The category key for jobs written without price-list items.
const String kNoCategory = '';

/// What a month or a year earned, computed from the jobs every time and never
/// stored, so it cannot drift. A job counts on its own day, and only once
/// it is done.
class Earnings {
  const Earnings._({
    required this.earnedMinor,
    required this.done,
    required this.cancelled,
    required this.byCategory,
    required this.byWorker,
    required this.unassignedMinor,
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
    final byWorker = <String, int>{};
    var unassigned = 0;
    final byMonth = List<int>.filled(12, 0);
    for (final j in jobs) {
      if (!inRange(j.date)) continue;
      if (j.isCancelled) cancelled++;
      if (!j.isDone) continue;
      done.add(j);
      final earned = j.earnedMinor;
      byMonth[j.day.month - 1] += earned;
      _addAll(byCategory, categoryShares(j));
      if (j.workers.isEmpty) {
        unassigned += earned;
      } else {
        _addAll(byWorker, workerShares(j));
      }
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
      byWorker: byWorker,
      unassignedMinor: unassigned,
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

  /// Worker uid → earned, each job shared equally among its workers.
  final Map<String, int> byWorker;

  /// Earned by jobs nobody was put on.
  final int unassignedMinor;

  /// Money put into the wallet by hand: not earnings, shown apart.
  final int depositsMinor;

  /// Spending from the wallet: the costs.
  final int spendingMinor;

  /// Earned per calendar month, January first (for the year view).
  final List<int> byMonth;

  int get jobCount => done.length;
  int get averageMinor => done.isEmpty ? 0 : earnedMinor ~/ done.length;

  /// What is left after the costs.
  int get netMinor => earnedMinor - spendingMinor;

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

/// The job's earning shared equally among its workers, in whole dinars, a
/// leftover dinar each to the first ones, so it adds up exactly.
Map<String, int> workerShares(Job j) {
  final n = j.workers.length;
  if (n == 0) return const {};
  final parts = _inDinars(j.earnedMinor, (dinars) {
    final each = dinars ~/ n;
    final left = dinars - each * n;
    return [for (var i = 0; i < n; i++) each + (i < left ? 1 : 0)];
  });
  final shares = <String, int>{};
  for (var i = 0; i < n; i++) {
    final uid = j.workers[i];
    shares[uid] = (shares[uid] ?? 0) + parts[i];
  }
  return shares;
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
