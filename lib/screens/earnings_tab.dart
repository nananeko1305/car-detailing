import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/earnings.dart';
import '../models/job.dart';
import '../money/money.dart';
import '../services/live_data.dart';
import '../theme/app_colors.dart';
import '../widgets/earnings_parts.dart';
import '../widgets/job_card.dart';
import '../widgets/month_switcher.dart';
import 'job_detail_screen.dart';

/// The earnings history: a month or a whole year, what it earned, how,
/// by whom, what it cost and what is left, then the finished jobs. A worker
/// sees only what they were paid, and on which jobs.
class EarningsTab extends StatefulWidget {
  const EarningsTab({super.key, required this.data, required this.profile});

  final LiveData data;
  final AppUser profile;

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  DateTime _period = DateTime(DateTime.now().year, DateTime.now().month);
  bool _yearly = false;

  void _setYearly(bool yearly) => setState(() {
    _yearly = yearly;
    final now = DateTime.now();
    _period = yearly
        ? DateTime(_period.year)
        : (_period.year == now.year
              ? DateTime(now.year, now.month)
              : DateTime(_period.year, 12));
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final data = widget.data;
    final me = data.userById(widget.profile.uid) ?? widget.profile;
    if (data.jobs == null || data.entries == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final from = _period;
    final to = _yearly
        ? DateTime(_period.year + 1)
        : DateTime(_period.year, _period.month + 1);
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(t.month)),
            ButtonSegment(value: true, label: Text(t.year)),
          ],
          selected: {_yearly},
          showSelectedIcon: false,
          onSelectionChanged: (s) => _setYearly(s.first),
        ),
        const SizedBox(height: 6),
        MonthSwitcher(
          month: _period,
          first: DateTime(2024),
          last: _yearly ? DateTime(now.year + 1) : DateTime(now.year + 1, 12),
          yearly: _yearly,
          onChanged: (p) => setState(() => _period = p),
        ),
        const SizedBox(height: 6),
        // A worker sees only their own pay; the admin, the whole crew's.
        if (me.isAdmin)
          ..._crew(context, from, to)
        else
          ..._mine(context, me.uid, from, to),
      ],
    );
  }

  /// The admin's view: what the period earned, how, what it cost, what
  /// is left, and the finished jobs.
  List<Widget> _crew(BuildContext context, DateTime from, DateTime to) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final data = widget.data;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String money(int v) => formatMoney(v, locale);
    final e = Earnings.of(
      jobs: data.jobs!,
      entries: data.entries!,
      from: from,
      to: to,
    );
    return [
      HeroTotal(
        label: t.earned,
        value: money(e.earnedMinor),
        caption: t.jobsAndAverage(e.jobCount, money(e.averageMinor)),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: StatTile(
              label: t.givenToHelpers,
              value: money(e.helpersPaidMinor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatTile(label: t.costs, value: money(e.spendingMinor)),
          ),
        ],
      ),
      const SizedBox(height: 10),
      StatTile(
        label: t.myEarnings,
        value: money(e.adminNetMinor),
        color: e.adminNetMinor < 0 ? c.danger : c.mint,
      ),
      if (e.depositsMinor > 0 || e.cancelled > 0) ...[
        const SizedBox(height: 8),
        Text(
          [
            if (e.depositsMinor > 0) t.depositsNote(money(e.depositsMinor)),
            if (e.cancelled > 0) t.cancelledCount(e.cancelled),
          ].join(' · '),
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
      ],
      if (_yearly) ...[
        const SizedBox(height: 18),
        SectionTitle(t.byMonth),
        MonthBars(values: e.byMonth, locale: locale),
      ],
      if (e.byCategory.isNotEmpty) ...[
        const SizedBox(height: 18),
        SectionTitle(t.byCategory),
        ShareList(
          rows: [
            for (final entry in e.byCategory.entries)
              (
                entry.key == kNoCategory
                    ? t.withoutPriceList
                    : (data.categoryName(entry.key).isEmpty
                          ? t.removedCategory
                          : data.categoryName(entry.key)),
                entry.value,
              ),
          ],
          total: e.earnedMinor,
          format: money,
        ),
      ],
      if (e.byHelper.isNotEmpty) ...[
        const SizedBox(height: 18),
        SectionTitle(t.paidToHelpers),
        ShareList(
          rows: [
            for (final entry in e.byHelper.entries)
              (data.nameOf(entry.key), entry.value),
          ],
          total: e.helpersPaidMinor,
          format: money,
        ),
      ],
      ..._jobs(context, e.done, from),
    ];
  }

  /// A worker's view: what they were paid, and on which jobs.
  List<Widget> _mine(
    BuildContext context,
    String uid,
    DateTime from,
    DateTime to,
  ) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    String money(int v) => formatMoney(v, locale);
    final m = HelperEarnings.of(
      jobs: widget.data.jobs!,
      uid: uid,
      from: from,
      to: to,
    );
    return [
      HeroTotal(
        label: t.iGot,
        value: money(m.paidMinor),
        caption: t.jobsAndAverage(m.jobs.length, money(m.averageMinor)),
      ),
      if (_yearly) ...[
        const SizedBox(height: 18),
        SectionTitle(t.byMonth),
        MonthBars(values: m.byMonth, locale: locale),
      ],
      ..._jobs(context, m.jobs, from),
    ];
  }

  /// "Završeni poslovi", or a line saying there were none.
  List<Widget> _jobs(BuildContext context, List<Job> jobs, DateTime from) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final data = widget.data;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return [
      const SizedBox(height: 18),
      SectionTitle(t.finishedJobs),
      if (jobs.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            _yearly
                ? t.noJobsThisYear
                : t.noJobsThisMonth(DateFormat.MMMM(locale).format(from)),
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted),
          ),
        ),
      for (final j in jobs) ...[
        JobCard(
          job: j,
          data: data,
          showDate: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JobDetailScreen(
                data: data,
                profile: widget.profile,
                jobId: j.id,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }
}
