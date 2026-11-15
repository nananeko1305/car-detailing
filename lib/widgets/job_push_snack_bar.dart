import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/job_push.dart';

/// The title a job push carries, in the app's language. The same words as
/// the Android titles in `res/values*/strings.xml`.
String jobPushTitle(AppLocalizations t, JobPush push) => switch (push.kind) {
  PushKind.jobNew => t.pushJobNew,
  PushKind.jobChanged => t.pushJobChanged,
  PushKind.jobCancelled => t.pushJobCancelled,
  PushKind.jobTomorrow => t.pushJobTomorrow,
};

/// What a job push says while the app is open, when Android shows nothing
/// by itself. `persist: false`: with an action, Flutter 3.47 would otherwise
/// keep it on screen until closed.
SnackBar jobPushSnackBar(
  AppLocalizations t,
  JobPush push, {
  VoidCallback? onOpen,
}) {
  return SnackBar(
    persist: false,
    duration: const Duration(seconds: 6),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          jobPushTitle(t, push),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (push.text.isNotEmpty)
          Text(push.text, maxLines: 4, overflow: TextOverflow.ellipsis),
      ],
    ),
    action: onOpen == null
        ? null
        : SnackBarAction(label: t.open, onPressed: onOpen),
  );
}
