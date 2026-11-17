import 'package:cloud_firestore/cloud_firestore.dart';

import 'job.dart';

/// Manual wallet movements. Job income is not stored here; it comes straight
/// from finished jobs with `toWallet` on (see [WalletMovement]): what was
/// charged, less the helpers' pay and the equipment, which leave the wallet
/// with it.
enum WalletEntryType { deposit, withdrawal }

/// A manual deposit into, or spending from, the shared wallet, stored in
/// `walletEntries/{id}`.
class WalletEntry {
  const WalletEntry({
    this.id = '',
    required this.type,
    required this.amountMinor,
    required this.description,
    required this.date,
    required this.userId,
    required this.createdBy,
  });

  final String id;
  final WalletEntryType type;
  final int amountMinor;
  final String description;
  final DateTime date;

  /// Who added or spent the money.
  final String userId;

  /// Who recorded the entry; only they (or the admin) may change it.
  final String createdBy;

  bool get isSpending => type == WalletEntryType.withdrawal;

  factory WalletEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return WalletEntry(
      id: doc.id,
      type: data['type'] == 'withdrawal'
          ? WalletEntryType.withdrawal
          : WalletEntryType.deposit,
      amountMinor: (data['amountMinor'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'amountMinor': amountMinor,
    'description': description.trim(),
    'date': Timestamp.fromDate(date),
    'userId': userId,
    'createdBy': createdBy,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// One line in the wallet history: a finished job, a deposit or spending.
/// [signedMinor] is positive for money in, negative for out.
class WalletMovement {
  const WalletMovement._({
    required this.date,
    required this.signedMinor,
    required this.description,
    required this.userId,
    this.job,
    this.entry,
  });

  /// A finished job: charged in, helpers and equipment out, as one line.
  factory WalletMovement.fromJob(Job j) => WalletMovement._(
    date: j.doneAt ?? j.day,
    signedMinor: j.netMinor,
    description: j.title,
    userId: j.doneBy,
    job: j,
  );

  factory WalletMovement.fromEntry(WalletEntry e) => WalletMovement._(
    date: e.date,
    signedMinor: e.isSpending ? -e.amountMinor : e.amountMinor,
    description: e.description,
    userId: e.userId,
    entry: e,
  );

  final DateTime date;
  final int signedMinor;
  final String description;
  final String userId;
  final Job? job;
  final WalletEntry? entry;

  /// Job income and manual entries, newest first.
  static List<WalletMovement> merge(
    List<Job> jobs,
    List<WalletEntry> entries,
  ) => [
    for (final j in jobs)
      if (j.isDone && j.toWallet) WalletMovement.fromJob(j),
    for (final e in entries) WalletMovement.fromEntry(e),
  ]..sort((a, b) => b.date.compareTo(a.date));

  static int balance(List<WalletMovement> movements) =>
      movements.fold(0, (total, m) => total + m.signedMinor);

  /// What can be spent: the balance, plus what [old] took out already when
  /// that spending is the one being edited.
  static int available(int balance, {WalletEntry? old}) =>
      balance + (old != null && old.isSpending ? old.amountMinor : 0);

  /// Whether [spending], saved in place of [old], would take the wallet below
  /// zero. The wallet is real cash and cannot go short.
  ///
  /// A change that leaves the balance no lower than it is now always passes,
  /// so a wallet that is short from before can still be corrected.
  static bool overdraws(int balance, WalletEntry spending, {WalletEntry? old}) {
    final after = available(balance, old: old) - spending.amountMinor;
    return after < 0 && after < balance;
  }
}
