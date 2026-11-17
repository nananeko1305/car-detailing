import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/job.dart';
import '../money/money.dart';
import '../services/live_data.dart';
import '../theme/app_colors.dart';

/// One job in a list: its time, what is done, for whom and where, who works
/// on it and the price. Done jobs show what was charged; cancelled ones are
/// struck through.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.data,
    required this.onTap,
    this.showDate = false,
  });

  final Job job;
  final LiveData data;
  final VoidCallback onTap;

  /// For lists that span days (overdue, history): the date above the time.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final cancelled = job.isCancelled;
    final strike = cancelled ? TextDecoration.lineThrough : null;
    final who = job.helpers.isEmpty
        ? t.workingAloneShort
        : t.helpedBy(
            job.helpers.map((h) => data.shortNameOf(h.uid)).join(', '),
          );
    final place = [
      job.clientName,
      job.address,
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    final amount = job.isDone ? job.earnedMinor : job.priceMinor;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(c.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 54,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDate)
                      Text(
                        shortDate(context, job.day),
                        style: TextStyle(fontSize: 11, color: c.muted),
                      ),
                    Text(
                      job.start,
                      style: c.display(
                        16,
                        color: cancelled ? c.muted : c.primary,
                      ),
                    ),
                    if (job.end.isNotEmpty)
                      Text(
                        t.untilTime(job.end),
                        style: TextStyle(fontSize: 11, color: c.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title.isEmpty ? t.jobNoItems : job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cancelled ? c.muted : c.ink,
                        decoration: strike,
                      ),
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      cancelled ? t.statusCancelled : who,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cancelled || job.helpers.isEmpty
                            ? c.muted
                            : c.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(amount, locale, unit: false),
                    style: c
                        .display(15, color: cancelled ? c.muted : c.ink)
                        .copyWith(decoration: strike),
                  ),
                  if (job.isDone) ...[
                    const SizedBox(height: 4),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: c.success,
                      semanticLabel: t.statusDone,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "pon 16. nov" in the app's language.
String shortDate(BuildContext context, DateTime d) {
  final ml = MaterialLocalizations.of(context);
  return ml.formatShortMonthDay(d);
}
