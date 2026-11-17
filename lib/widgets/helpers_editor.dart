import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/job.dart';
import '../money/money.dart';
import '../theme/app_colors.dart';

/// The state of "Radim sam | Imam pomoć": whether there is help, who helps,
/// and what each one is paid (as typed). Shared by the booking form and the
/// finish sheet, which both start from the job's helpers.
class HelpersController extends ChangeNotifier {
  HelpersController(List<JobHelper> initial)
    : _withHelp = initial.isNotEmpty,
      _picked = {for (final h in initial) h.uid} {
    for (final h in initial) {
      _payFor(h.uid).text = h.payMinor == 0 ? '' : moneyToInput(h.payMinor);
    }
  }

  bool _withHelp;
  final Set<String> _picked;
  final Map<String, TextEditingController> _pay = {};

  bool get withHelp => _withHelp;
  bool isPicked(String uid) => _picked.contains(uid);

  TextEditingController _payFor(String uid) => _pay.putIfAbsent(
    uid,
    () => TextEditingController()..addListener(notifyListeners),
  );

  TextEditingController payFor(String uid) => _payFor(uid);

  set withHelp(bool v) {
    _withHelp = v;
    notifyListeners();
  }

  void toggle(String uid, bool on) {
    on ? _picked.add(uid) : _picked.remove(uid);
    notifyListeners();
  }

  /// The helpers as they stand; empty when working alone. An amount that
  /// does not parse counts as zero here; [validate] catches it on save.
  List<JobHelper> get helpers => !_withHelp
      ? const []
      : [
          for (final uid in _picked)
            JobHelper(
              uid: uid,
              payMinor: parseMoneyOrZero(_payFor(uid).text) ?? 0,
            ),
        ];

  /// Null when fine, otherwise what to tell the user.
  String? validate(AppLocalizations t) {
    if (!_withHelp) return null;
    if (_picked.isEmpty) return t.pickAHelper;
    for (final uid in _picked) {
      if (parseMoneyOrZero(_payFor(uid).text) == null) return t.invalidAmount;
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in _pay.values) {
      c.dispose();
    }
    super.dispose();
  }
}

/// "Radim sam | Imam pomoć", and with help, a row per worker: tick them and
/// type what they are paid.
class HelpersEditor extends StatelessWidget {
  const HelpersEditor({
    super.key,
    required this.controller,
    required this.candidates,
  });

  final HelpersController controller;

  /// Who can help: the active accounts other than the admin.
  final List<AppUser> candidates;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.person_rounded),
                label: Text(t.workingAlone),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.group_rounded),
                label: Text(t.withHelp),
              ),
            ],
            selected: {controller.withHelp},
            showSelectedIcon: false,
            onSelectionChanged: (s) => controller.withHelp = s.first,
          ),
          if (controller.withHelp) ...[
            const SizedBox(height: 10),
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  t.noWorkersYet,
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
              ),
            for (final u in candidates)
              _HelperRow(controller: controller, user: u),
          ],
        ],
      ),
    );
  }
}

class _HelperRow extends StatelessWidget {
  const _HelperRow({required this.controller, required this.user});

  final HelpersController controller;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final picked = controller.isPicked(user.uid);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      decoration: BoxDecoration(
        color: picked ? c.soft : c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: picked ? c.primary : c.border),
      ),
      child: Row(
        children: [
          Checkbox(
            value: picked,
            onChanged: (v) => controller.toggle(user.uid, v ?? false),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.toggle(user.uid, !picked),
              child: Text(
                user.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            child: TextField(
              controller: controller.payFor(user.uid),
              enabled: picked,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: t.paysThem,
                suffixText: 'RSD',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Ostaje tebi: 5.380 RSD": the price less the helpers' pay.
class LeftOverLine extends StatelessWidget {
  const LeftOverLine({super.key, required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: c.display(15))),
          Text(
            formatMoney(amount, locale),
            style: c.display(17, color: amount < 0 ? c.danger : c.mint),
          ),
        ],
      ),
    );
  }
}
