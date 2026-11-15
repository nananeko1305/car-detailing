import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/job.dart';
import '../money/money.dart';
import '../services/background_save.dart';
import '../services/job_repository.dart';
import '../services/live_data.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/finish_job_sheet.dart';
import '../widgets/pearl.dart';
import 'job_form_screen.dart';

/// One job: what, for whom, where, who and how much, and what can be done
/// with it next. Follows the live data, so a change from another phone shows
/// at once.
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({
    super.key,
    required this.data,
    required this.profile,
    required this.jobId,
  });

  final LiveData data;
  final AppUser profile;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final job = data.jobById(jobId);
        if (job == null) {
          final t = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(data.ready ? t.jobGone : '…')),
          );
        }
        return _Detail(data: data, profile: profile, job: job);
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.data, required this.profile, required this.job});

  final LiveData data;
  final AppUser profile;
  final Job job;

  void _edit(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => JobFormScreen(data: data, profile: profile, job: job),
    ),
  );

  Future<void> _cancel(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await confirmDelete(
      context,
      t.cancelJobTitle,
      body: t.cancelJobBody,
      confirmLabel: t.cancelJob,
    );
    if (!ok || !context.mounted) return;
    saveInBackground(
      context,
      () => JobRepository.instance.cancel(job.id, profile.uid),
    );
  }

  Future<void> _reopen(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await confirmDelete(
      context,
      t.reopenTitle,
      body: job.isDone ? t.reopenDoneBody : t.reopenCancelledBody,
      confirmLabel: t.reopen,
    );
    if (!ok || !context.mounted) return;
    saveInBackground(
      context,
      () => JobRepository.instance.reopen(job.id, profile.uid),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await confirmDelete(
      context,
      t.deleteJobTitle,
      body: t.deleteJobBody,
    );
    if (!ok || !context.mounted) return;
    final navigator = Navigator.of(context);
    saveInBackground(context, () => JobRepository.instance.delete(job.id));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String money(int v) => formatMoney(v, locale);
    final dateText = toBeginningOfSentenceCase(
      DateFormat.yMMMMEEEEd(locale).format(job.day),
      locale,
    );
    final status = switch (job.status) {
      JobStatus.done => (t.statusDone, c.success),
      JobStatus.cancelled => (t.statusCancelled, c.muted),
      JobStatus.booked when job.isOverdue(DateTime.now()) => (
        t.statusOverdue,
        c.warning,
      ),
      JobStatus.booked => (t.statusBooked, c.primary),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(t.job),
        actions: [
          IconButton(
            tooltip: t.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context),
          ),
          if (profile.canDelete(job.ownerId))
            IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(
            status.$1.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: status.$2,
            ),
          ),
          const SizedBox(height: 6),
          Text(dateText, style: c.display(22)),
          Text(
            job.timeRange,
            style: c.display(18, color: c.primary, weight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final i in job.items) _Row(i.label, money(i.totalMinor)),
                  if (job.discountPercent > 0)
                    _Row(
                      t.discountPercent(job.discountPercent),
                      '− ${money((job.subtotalMinor * job.discountPercent / 10000).round() * 100)}',
                    ),
                  if (job.travelMinor > 0)
                    _Row(t.travel, money(job.travelMinor)),
                  if (job.items.isNotEmpty)
                    Divider(color: c.border, height: 18),
                  _Row(
                    t.agreedPrice,
                    money(job.priceMinor),
                    strong: !job.isDone,
                  ),
                  if (job.isDone) ...[
                    _Row(t.charged, money(job.earnedMinor), strong: true),
                    Text(
                      job.toWallet ? t.wentIntoWallet : t.notIntoWallet,
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (job.clientName.isNotEmpty)
            _Info(icon: Icons.person_outline_rounded, text: job.clientName),
          if (job.clientPhone.isNotEmpty)
            _Info(
              icon: Icons.phone_rounded,
              text: job.clientPhone,
              link: true,
              onTap: () => launchUrl(
                Uri(scheme: 'tel', path: job.clientPhone.replaceAll(' ', '')),
              ),
            ),
          if (job.address.isNotEmpty)
            _Info(
              icon: Icons.place_outlined,
              text: job.address,
              link: true,
              onTap: () => launchUrl(
                Uri.parse('geo:0,0?q=${Uri.encodeComponent(job.address)}'),
              ),
            ),
          _Info(
            icon: Icons.groups_outlined,
            text: job.workers.isEmpty
                ? t.nobodyAssigned
                : job.workers.map(data.nameOf).join(', '),
          ),
          if (job.notes.isNotEmpty)
            _Info(icon: Icons.notes_rounded, text: job.notes),
          _Info(
            icon: Icons.history_rounded,
            text: [
              t.bookedBy(data.nameOf(job.ownerId)),
              if (job.isDone && job.doneBy.isNotEmpty)
                t.finishedBy(data.nameOf(job.doneBy)),
            ].join('\n'),
            muted: true,
          ),
          const SizedBox(height: 20),
          if (job.status == JobStatus.booked) ...[
            PearlButton(
              label: t.finishJob,
              icon: Icons.check_rounded,
              onPressed: () => showFinishJobSheet(
                context,
                data: data,
                job: job,
                me: profile.uid,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _cancel(context),
              icon: const Icon(Icons.event_busy_outlined),
              label: Text(t.cancelJob),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: () => _reopen(context),
              icon: const Icon(Icons.undo_rounded),
              label: Text(t.reopen),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: strong ? c.ink : c.muted),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: strong
                ? c.display(17)
                : TextStyle(color: c.ink, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.text,
    this.onTap,
    this.link = false,
    this.muted = false,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool link;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: link ? c.primary : c.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: muted ? 13 : 15,
                  color: link ? c.primary : (muted ? c.muted : c.ink),
                  fontWeight: link ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
