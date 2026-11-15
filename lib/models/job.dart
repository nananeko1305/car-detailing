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
    this.workers = const [],
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

  /// Who works on it.
  final List<String> workers;

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
    return Job(
      id: id,
      ownerId: d['ownerId'] as String? ?? '',
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
      workers: rawWorkers is List
          ? [
              for (final w in rawWorkers)
                if (w is String) w,
            ]
          : const [],
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
