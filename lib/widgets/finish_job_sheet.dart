import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/job.dart';
import '../money/money.dart';
import '../services/background_save.dart';
import '../services/job_repository.dart';
import '../services/live_data.dart';
import '../theme/app_colors.dart';
import 'helpers_editor.dart';
import 'pearl.dart';

/// "Završi posao": what was charged (the agreed price unless it changed on
/// the spot), whether it goes into the wallet, and who helped for how much,
/// as booked unless it turned out otherwise.
Future<void> showFinishJobSheet(
  BuildContext context, {
  required LiveData data,
  required Job job,
  required String me,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _FinishSheet(data: data, job: job, me: me),
);

class _FinishSheet extends StatefulWidget {
  const _FinishSheet({required this.data, required this.job, required this.me});

  final LiveData data;
  final Job job;
  final String me;

  @override
  State<_FinishSheet> createState() => _FinishSheetState();
}

class _FinishSheetState extends State<_FinishSheet> {
  final _form = GlobalKey<FormState>();
  late final _paid = TextEditingController(
    text: moneyToInput(widget.job.priceMinor),
  );
  late final _helpers = HelpersController(widget.job.helpers)
    ..addListener(_refresh);
  bool _toWallet = true;

  @override
  void initState() {
    super.initState();
    _paid.addListener(_refresh);
  }

  @override
  void dispose() {
    _paid.dispose();
    _helpers.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  int get _leftOver =>
      (parseMoneyOrZero(_paid.text) ?? 0) -
      _helpers.helpers.fold<int>(0, (a, h) => a + h.payMinor);

  void _finish() {
    final t = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    final problem = _helpers.validate(t);
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    final paid = parseMoneyOrZero(_paid.text)!;
    final job = widget.job;
    final me = widget.me;
    final helpers = _helpers.helpers;
    final toWallet = _toWallet;
    final navigator = Navigator.of(context);
    saveInBackground(
      context,
      () => JobRepository.instance.finish(
        job.id,
        me,
        paidMinor: paid,
        toWallet: toWallet,
        helpers: helpers,
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(t.finishJob, style: c.display(20)),
            const SizedBox(height: 4),
            Text(
              widget.job.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.muted),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paid,
              autofocus: false,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t.charged,
                suffixText: 'RSD',
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: (v) =>
                  parseMoneyOrZero(v ?? '') == null ? t.invalidAmount : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.intoWallet),
              subtitle: Text(t.intoWalletHint),
              value: _toWallet,
              onChanged: (v) => setState(() => _toWallet = v),
            ),
            const SizedBox(height: 6),
            Text(t.whoWorked),
            const SizedBox(height: 8),
            HelpersEditor(
              controller: _helpers,
              candidates: widget.data.helperCandidates,
            ),
            LeftOverLine(
              label: widget.data.userById(widget.me)?.isAdmin ?? false
                  ? t.leftForYou
                  : t.leftForAdmin(widget.data.admin?.shortName ?? t.roleAdmin),
              amount: _leftOver,
            ),
            const SizedBox(height: 18),
            PearlButton(
              label: t.finishJob,
              icon: Icons.check_rounded,
              onPressed: _finish,
            ),
          ],
        ),
      ),
    );
  }
}
