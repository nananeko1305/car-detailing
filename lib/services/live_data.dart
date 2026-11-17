import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/day_key.dart';
import '../models/job.dart';
import '../models/price_list.dart';
import '../models/wallet_entry.dart';
import 'job_repository.dart';
import 'price_list_repository.dart';
import 'user_repository.dart';
import 'wallet_repository.dart';

/// Live snapshot of the crew, its jobs, wallet and price list. One instance
/// per signed-in session, owned by the home screen; every tab reads from it
/// instead of opening its own Firestore listeners.
class LiveData extends ChangeNotifier {
  LiveData({bool listen = true}) {
    if (!listen) return;
    _watch(UserRepository.instance.watchAll, (v) => users = v);
    _watch(JobRepository.instance.watchAll, (v) => jobs = v);
    _watch(WalletRepository.instance.watchAll, (v) => entries = v);
    final prices = PriceListRepository.instance;
    _watch(prices.watchCategories, (v) => categories = v);
    _watch(prices.watchItems, (v) => items = v);
    _watch(prices.watchRules, (v) => rules = v);
  }

  static const _firstRetry = Duration(seconds: 5);
  static const _longestRetry = Duration(minutes: 1);

  final List<StreamSubscription<Object?>> _subs = [];
  final List<Timer> _retries = [];
  bool _disposed = false;

  List<AppUser>? _users;
  List<AppUser>? get users => _users;
  set users(List<AppUser>? v) {
    _users = v;
    _usersById = {for (final u in v ?? const <AppUser>[]) u.uid: u};
  }

  List<Job>? jobs;
  List<WalletEntry>? entries;
  List<PriceCategory>? categories;
  List<PriceItem>? items;

  /// The price list's terms; the crew's first terms until read.
  PricingRules rules = const PricingRules();
  Object? error;
  Map<String, AppUser> _usersById = const {};

  /// The calendar can show; the price list and wallet catch up on their own.
  bool get ready => users != null && jobs != null;

  /// "First Last", or "—" when unknown.
  String nameOf(String uid) => _usersById[uid]?.displayName ?? '—';

  /// "Marko", or "—" when unknown.
  String shortNameOf(String uid) => _usersById[uid]?.shortName ?? '—';

  AppUser? userById(String uid) => _usersById[uid];

  /// Everyone who can be put on a job.
  List<AppUser> get activeUsers => [
    for (final u in users ?? const <AppUser>[])
      if (!u.disabled) u,
  ];

  /// The admin, to whom every job's profit goes; null until users load.
  AppUser? get admin {
    for (final u in users ?? const <AppUser>[]) {
      if (u.isAdmin) return u;
    }
    return null;
  }

  /// Who can help on a job: the active accounts other than the admin.
  List<AppUser> get helperCandidates => [
    for (final u in activeUsers)
      if (!u.isAdmin) u,
  ];

  Job? jobById(String id) {
    for (final j in jobs ?? const <Job>[]) {
      if (j.id == id) return j;
    }
    return null;
  }

  /// The jobs on one day, by start time.
  List<Job> on(DateTime day) {
    final key = dateKey(day);
    return [
      for (final j in jobs ?? const <Job>[])
        if (j.date == key) j,
    ]..sort(_byTime);
  }

  /// Booked for a day that has passed, oldest first.
  List<Job> overdue(DateTime now) => [
    for (final j in jobs ?? const <Job>[])
      if (j.isOverdue(now)) j,
  ]..sort(_byTime);

  /// Jobs per day that are not cancelled, for the calendar's dots.
  Map<DateTime, int> countsByDay() {
    final counts = <DateTime, int>{};
    for (final j in jobs ?? const <Job>[]) {
      if (j.isCancelled) continue;
      final day = parseDateKey(j.date);
      if (day != null) counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }

  /// The wallet's history, newest first.
  List<WalletMovement> get movements =>
      WalletMovement.merge(jobs ?? const [], entries ?? const []);

  int get balance => WalletMovement.balance(movements);

  /// Categories still offered, in their order.
  List<PriceCategory> get liveCategories => [
    for (final c in categories ?? const <PriceCategory>[])
      if (!c.archived) c,
  ];

  /// A category's items still offered, in their order.
  List<PriceItem> itemsOf(String categoryId) => [
    for (final i in items ?? const <PriceItem>[])
      if (i.categoryId == categoryId && !i.archived) i,
  ];

  String categoryName(String id) {
    for (final c in categories ?? const <PriceCategory>[]) {
      if (c.id == id) return c.name;
    }
    return '';
  }

  static int _byTime(Job a, Job b) {
    final byDay = a.date.compareTo(b.date);
    return byDay != 0 ? byDay : a.start.compareTo(b.start);
  }

  /// Subscribes to a collection, and subscribes again after a failure.
  ///
  /// A Firestore listener that errors is finished: it never recovers on its
  /// own. Rules that have just been deployed, or a worker switched back on a
  /// moment ago, would otherwise leave the app waiting on data that never
  /// arrives until it is force-closed.
  void _watch<T>(
    Stream<T> Function() open,
    void Function(T) set, {
    Duration wait = _firstRetry,
  }) {
    late final StreamSubscription<T> sub;
    sub = open().listen(
      (value) {
        set(value);
        error = null;
        notifyListeners();
      },
      onError: (Object e) {
        error = e;
        notifyListeners();
        sub.cancel();
        _subs.remove(sub);
        _retryLater(open, set, wait);
      },
    );
    _subs.add(sub);
  }

  void _retryLater<T>(
    Stream<T> Function() open,
    void Function(T) set,
    Duration wait,
  ) {
    late final Timer timer;
    timer = Timer(wait, () {
      _retries.remove(timer);
      if (_disposed) return;
      // Backs off, so a collection nobody may read is not retried in a tight
      // loop for as long as the app is open.
      final next = wait * 2;
      _watch(open, set, wait: next > _longestRetry ? _longestRetry : next);
    });
    _retries.add(timer);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    for (final t in _retries) {
      t.cancel();
    }
    super.dispose();
  }
}
