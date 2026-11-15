import 'package:flutter/foundation.dart';

import '../models/job.dart';

/// One job this phone should ask the worker to announce.
typedef Announcement = ({String id, String key});

/// The jobs [me] changed that the worker has not caught up with, going by
/// what the server has.
///
/// Going by the data and not by the save covers a change made offline, the
/// app closed before it reached the server, and the worker being down: each
/// is picked up on the next change or start. The key changes with every
/// revision, so a second edit is asked about even in the same session.
List<Announcement> pendingAnnouncements({
  required String me,
  required Iterable<Job> jobs,
}) => [
  for (final j in jobs)
    if (j.createdAt != null && j.updatedBy == me && j.pushRev < j.rev)
      (id: j.id, key: '${j.id}:${j.rev}'),
];

/// Watches the live data and asks the worker for each pending announcement,
/// once per key per session.
class Announcer {
  Announcer({
    required this._source,
    required this._pending,
    required this._announce,
  });

  final Listenable _source;
  final List<Announcement> Function() _pending;
  final Future<int> Function(String id) _announce;
  final Set<String> _asked = {};

  void start() {
    _source.addListener(_check);
    _check();
  }

  void dispose() => _source.removeListener(_check);

  void _check() {
    for (final a in _pending()) {
      if (_asked.add(a.key)) {
        _announce(a.id).catchError((Object _) {
          // Offline, or the worker is down: asked again on the next start.
          return 0;
        });
      }
    }
  }
}
