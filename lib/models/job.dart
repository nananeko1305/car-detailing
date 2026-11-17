import 'package:cloud_firestore/cloud_firestore.dart';

import 'day_key.dart';
import 'pricing.dart';

/// booked → done (charged, maybe into the wallet) or cancelled.
enum JobStatus { booked, done, cancelled }

JobStatus statusFromName(String? name) => switch (name) {
  'done' => JobStatus.done,
  'cancelled' => JobStatus.cancelled,
  _ => JobStatus.booked,
};

/// Someone who helps on a job, and what they are paid for it.
class JobHelper {
  const JobHelper({required this.uid, this.payMinor = 0});

  final String uid;
  final int payMinor;

  JobHelper withPay(int pay) => JobHelper(uid: uid, payMinor: pay);

  factory JobHelper.fromMap(Map<String, dynamic> d) => JobHelper(
    uid: d['uid'] as String? ?? '',
    payMinor: (d['payMinor'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {'uid': uid, 'payMinor': payMinor};
}

/// One visit to a client, in `jobs/{id}`: the booking and, once finished,
/// the earning. There is no separate record of the money.
class Job {
  const Job({
    this.id = '',
    this.ownerId = '',
    required this.date,
    this.start = '',
    this.end = '',
    this.clientName = '',
    this.clientPhone = '',
    this.address = '',
    this.items = const [],
    this.subtotalMinor = 0,
    this.discountPercent = 0,
    this.travelMinor = 0,
    this.priceMinor = 0,
    this.helpers = const [],
    this.equipmentMinor = 0,
    this.notes = '',
    this.status = JobStatus.booked,
    this.paidMinor,
    this.toWallet = true,
    this.doneBy = '',
    this.doneAt,
    this.rev = 0,
    this.pushRev = 0,
    this.updatedBy = '',
    this.createdAt,
  });

  final String id;

  /// Who booked it; only they or the admin may delete it.
  final String ownerId;

  /// `yyyy-MM-dd`, see [dateKey].
  final String date;

  /// `HH:mm`; [end] may be empty.
  final String start;
  final String end;
  final String clientName;
  final String clientPhone;
  final String address;
  final List<JobItem> items;
  final int subtotalMinor;
  final int discountPercent;
  final int travelMinor;

  /// The agreed price, after the discount; may be typed over.
  final int priceMinor;

  /// Who helps the admin on it, each with their pay; empty = working alone.
  /// The profit always stays with the admin.
  final List<JobHelper> helpers;

  /// Spent on equipment and supplies for this job.
  final int equipmentMinor;

  /// Anything else, such as which car it is.
  final String notes;
  final JobStatus status;

  /// What was charged, once done.
  final int? paidMinor;

  /// Whether the charged money went into the shared wallet.
  final bool toWallet;
  final String doneBy;
  final DateTime? doneAt;

  /// Bumped by every write from the app; the push worker sets [pushRev] to it
  /// once it has told everyone.
  final int rev;
  final int pushRev;
  final String updatedBy;

  /// Null while the write is still on its way to the server.
  final DateTime? createdAt;

  DateTime get day => parseDateKey(date) ?? DateTime(1970);

  bool get isDone => status == JobStatus.done;
  bool get isCancelled => status == JobStatus.cancelled;

  /// Booked for a day that has passed: nobody marked it done or cancelled.
  bool isOverdue(DateTime now) =>
      status == JobStatus.booked && date.compareTo(dateKey(now)) < 0;

  /// What the job earned: the charged amount once done, otherwise nothing.
  int get earnedMinor => isDone ? (paidMinor ?? priceMinor) : 0;

  /// The helpers' uids, as the older `workers` field holds them.
  List<String> get workers => [for (final h in helpers) h.uid];

  int get helpersPaidMinor => helpers.fold(0, (a, h) => a + h.payMinor);

  /// What a price leaves the admin after the helpers and the equipment.
  int netOf(int priceMinor) => priceMinor - helpersPaidMinor - equipmentMinor;

  /// What the finished job left the admin; nothing until it is done.
  int get netMinor => isDone ? netOf(earnedMinor) : 0;

  /// "Ugaona garnitura × 6 · Fotelja", or the notes when there are no items.
  String get title {
    if (items.isNotEmpty) return items.map((i) => i.label).join(' · ');
    return notes.split('\n').first.trim();
  }

  /// "09:00", or "09:00–11:00".
  String get timeRange => end.isEmpty ? start : '$start–$end';

  factory Job.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Job.fromMap(doc.id, doc.data() ?? const {});

  factory Job.fromMap(String id, Map<String, dynamic> d) {
    final rawItems = d['items'];
    final rawWorkers = d['workers'];
    final rawHelpers = d['helpers'];
    final ownerId = d['ownerId'] as String? ?? '';
    return Job(
      id: id,
      ownerId: ownerId,
      date: d['date'] as String? ?? '',
      start: d['start'] as String? ?? '',
      end: d['end'] as String? ?? '',
      clientName: d['clientName'] as String? ?? '',
      clientPhone: d['clientPhone'] as String? ?? '',
      address: d['address'] as String? ?? '',
      items: rawItems is List
          ? [
              for (final x in rawItems)
                if (x is Map) JobItem.fromMap(Map<String, dynamic>.from(x)),
            ]
          : const [],
      subtotalMinor: (d['subtotalMinor'] as num?)?.toInt() ?? 0,
      discountPercent: (d['discountPercent'] as num?)?.toInt() ?? 0,
      travelMinor: (d['travelMinor'] as num?)?.toInt() ?? 0,
      priceMinor: (d['priceMinor'] as num?)?.toInt() ?? 0,
      // Jobs from before helpers (v1.0.x) only list `workers`: the others
      // than whoever booked it become helpers with no pay recorded.
      helpers: rawHelpers is List
          ? [
              for (final h in rawHelpers)
                if (h is Map) JobHelper.fromMap(Map<String, dynamic>.from(h)),
            ]
          : rawWorkers is List
          ? [
              for (final w in rawWorkers)
                if (w is String && w != ownerId) JobHelper(uid: w),
            ]
          : const [],
      equipmentMinor: (d['equipmentMinor'] as num?)?.toInt() ?? 0,
      notes: d['notes'] as String? ?? '',
      status: statusFromName(d['status'] as String?),
      paidMinor: (d['paidMinor'] as num?)?.toInt(),
      toWallet: d['toWallet'] as bool? ?? true,
      doneBy: d['doneBy'] as String? ?? '',
      doneAt: (d['doneAt'] as Timestamp?)?.toDate(),
      rev: (d['rev'] as num?)?.toInt() ?? 0,
      pushRev: (d['pushRev'] as num?)?.toInt() ?? 0,
      updatedBy: d['updatedBy'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// The fields the booking form edits. The repository adds the author,
  /// `rev`, `updatedBy` and the timestamps.
  Map<String, dynamic> formFields() => {
    'date': date,
    'start': start,
    'end': end,
    'clientName': clientName.trim(),
    'clientPhone': clientPhone.trim(),
    'address': address.trim(),
    'items': [for (final i in items) i.toMap()],
    'subtotalMinor': subtotalMinor,
    'discountPercent': discountPercent,
    'travelMinor': travelMinor,
    'priceMinor': priceMinor,
    'helpers': [for (final h in helpers) h.toMap()],
    'equipmentMinor': equipmentMinor,
    'workers': workers,
    'notes': notes.trim(),
  };

  /// [formFields] plus the outcome, for a job written as already done.
  Map<String, dynamic> outcomeFields() => {
    'status': status.name,
    'paidMinor': paidMinor,
    'toWallet': toWallet,
    'doneBy': doneBy,
    'doneAt': doneAt == null ? null : Timestamp.fromDate(doneAt!),
  };
}
