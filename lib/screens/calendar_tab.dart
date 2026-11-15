import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/day_key.dart';
import '../services/live_data.dart';
import '../theme/app_colors.dart';
import '../widgets/job_card.dart';
import '../widgets/month_grid.dart';
import '../widgets/month_switcher.dart';
import 'job_detail_screen.dart';

/// The month with a dot per job, the chosen day's jobs below, and on top the
/// jobs whose day has passed without anyone finishing them.
class CalendarTab extends StatefulWidget {
  const CalendarTab({
    super.key,
    required this.data,
    required this.profile,
    required this.selected,
    required this.onSelect,
  });

  final LiveData data;
  final AppUser profile;

  /// The chosen day, owned by the home screen so "+" books on it.
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  void _open(String id) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => JobDetailScreen(
        data: widget.data,
        profile: widget.profile,
        jobId: id,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final data = widget.data;
    if (!data.ready) {
      return const Center(child: CircularProgressIndicator());
    }
    final now = DateTime.now();
    final today = dayOf(now);
    final overdue = data.overdue(now);
    final dayJobs = data.on(widget.selected);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayLabel = toBeginningOfSentenceCase(
      DateFormat.MMMMEEEEd(locale).format(widget.selected),
      locale,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        if (overdue.isNotEmpty) ...[
          _Label(
            icon: Icons.schedule_rounded,
            text: t.notFinished(overdue.length),
            color: c.warning,
          ),
          const SizedBox(height: 8),
          for (final j in overdue) ...[
            JobCard(
              job: j,
              data: data,
              showDate: true,
              onTap: () => _open(j.id),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Column(
              children: [
                MonthSwitcher(
                  month: _month,
                  first: DateTime(today.year - 5),
                  last: DateTime(today.year + 2, 12),
                  onChanged: (m) => setState(() => _month = m),
                ),
                MonthGrid(
                  month: _month,
                  selected: widget.selected,
                  today: today,
                  counts: data.countsByDay(),
                  onSelect: widget.onSelect,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(dayLabel, style: c.display(17))),
            Text(
              t.jobsCount(dayJobs.where((j) => !j.isCancelled).length),
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (dayJobs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              t.noJobsThatDay,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted),
            ),
          ),
        for (final j in dayJobs) ...[
          JobCard(job: j, data: data, onTap: () => _open(j.id)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    ],
  );
}
