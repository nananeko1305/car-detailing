/// The kinds of push the worker sends. The names travel in `data.kind` and
/// must match `push_worker/src/message.js`.
enum PushKind { jobNew, jobChanged, jobCancelled, jobTomorrow }

/// A push from the worker, read from its data. Android shows it by itself
/// while the app is closed; while it is open, the app shows it instead.
class JobPush {
  const JobPush({
    required this.kind,
    this.jobId = '',
    this.date = '',
    this.text = '',
  });

  final PushKind kind;

  /// The job to open on a tap; empty for the evening reminder.
  final String jobId;

  /// The day it is about, `yyyy-MM-dd`.
  final String date;

  /// The body, as sent.
  final String text;

  /// Null for anything that is not a job push (a release, say).
  static JobPush? fromData(Map<String, dynamic> data) {
    final type = data['type'];
    if (type != 'job' && type != 'reminder') return null;
    final name = data['kind'] ?? (type == 'reminder' ? 'jobTomorrow' : null);
    for (final k in PushKind.values) {
      if (k.name == name) {
        return JobPush(
          kind: k,
          jobId: data['jobId'] as String? ?? '',
          date: data['date'] as String? ?? '',
          text: data['text'] as String? ?? '',
        );
      }
    }
    return null;
  }
}
