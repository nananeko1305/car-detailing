import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/job.dart';

/// Reads and writes `jobs/{id}`. Every write bumps `rev` by one and names the
/// writer in `updatedBy`, which is how the push worker knows what to announce
/// and the rules know who did it.
class JobRepository {
  JobRepository._();
  static final JobRepository instance = JobRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _jobs => _db.collection('jobs');

  Stream<List<Job>> watchAll() =>
      _jobs.snapshots().map((s) => s.docs.map(Job.fromDoc).toList());

  /// A new id, so a screen can open the job before the server has it.
  String newId() => _jobs.doc().id;

  /// Saves a new job; as booked, or as already done for a walk-in.
  Future<void> create(String id, Job job, String me) => _jobs.doc(id).set({
    ...job.formFields(),
    ...job.outcomeFields(),
    'ownerId': me,
    'rev': 1,
    'updatedBy': me,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Saves the booking form over an existing job; its outcome stays.
  Future<void> update(Job job, String me) =>
      _write(job.id, me, job.formFields());

  /// Marks the job done with what was charged, who helped for how much, and
  /// what the equipment cost: the same fields the booking had, as they
  /// turned out.
  Future<void> finish(
    String id,
    String me, {
    required int paidMinor,
    required bool toWallet,
    required List<JobHelper> helpers,
    required int equipmentMinor,
  }) => _write(id, me, {
    'status': JobStatus.done.name,
    'paidMinor': paidMinor,
    'toWallet': toWallet,
    'helpers': [for (final h in helpers) h.toMap()],
    'equipmentMinor': equipmentMinor,
    'workers': [for (final h in helpers) h.uid],
    'doneBy': me,
    'doneAt': FieldValue.serverTimestamp(),
  });

  /// Cancelled jobs stay in the history, out of the earnings.
  Future<void> cancel(String id, String me) =>
      _write(id, me, {'status': JobStatus.cancelled.name});

  /// Back to booked, from done or cancelled: the money leaves the wallet.
  Future<void> reopen(String id, String me) => _write(id, me, {
    'status': JobStatus.booked.name,
    'paidMinor': null,
    'doneBy': '',
    'doneAt': null,
  });

  /// For jobs entered by mistake; tells nobody.
  Future<void> delete(String id) => _jobs.doc(id).delete();

  Future<void> _write(String id, String me, Map<String, dynamic> fields) =>
      _jobs.doc(id).update({
        ...fields,
        'rev': FieldValue.increment(1),
        'updatedBy': me,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
