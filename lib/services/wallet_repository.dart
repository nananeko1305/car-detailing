import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wallet_entry.dart';

/// Manual deposits and spending in `walletEntries/{id}`. Job income is not
/// written here; the wallet reads it from the finished jobs.
class WalletRepository {
  WalletRepository._();
  static final WalletRepository instance = WalletRepository._();

  final CollectionReference<Map<String, dynamic>> _entries = FirebaseFirestore
      .instance
      .collection('walletEntries');

  Stream<List<WalletEntry>> watchAll() =>
      _entries.snapshots().map((s) => s.docs.map(WalletEntry.fromDoc).toList());

  Future<void> save(WalletEntry entry) => entry.id.isEmpty
      ? _entries.add(entry.toMap())
      : _entries.doc(entry.id).update(entry.toMap());

  Future<void> delete(String id) => _entries.doc(id).delete();
}
