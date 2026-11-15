import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/wallet_entry.dart';
import '../money/money.dart';
import '../services/background_save.dart';
import '../services/live_data.dart';
import '../services/wallet_repository.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/job_form_parts.dart';
import '../widgets/pearl.dart';

/// Money put into the wallet, or spent from it: amount, what for, date and
/// who. Only whoever recorded it (or the admin) can change it.
class WalletEntryScreen extends StatefulWidget {
  const WalletEntryScreen({
    super.key,
    required this.data,
    required this.profile,
    required this.type,
    this.entry,
  });

  final LiveData data;
  final AppUser profile;
  final WalletEntryType type;
  final WalletEntry? entry;

  @override
  State<WalletEntryScreen> createState() => _WalletEntryScreenState();
}

class _WalletEntryScreenState extends State<WalletEntryScreen> {
  final _form = GlobalKey<FormState>();
  late final WalletEntry? _old = widget.entry;
  late final bool _canEdit =
      _old == null || widget.profile.canDelete(_old.createdBy);
  late final bool _spending = widget.type == WalletEntryType.withdrawal;
  late DateTime _date = _old?.date ?? DateUtils.dateOnly(DateTime.now());
  late String _userId = _old?.userId ?? widget.profile.uid;
  late final _amount = TextEditingController(
    text: _old == null ? '' : moneyToInput(_old.amountMinor),
  );
  late final _description = TextEditingController(text: _old?.description);

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final t = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    final entry = WalletEntry(
      id: _old?.id ?? '',
      type: widget.type,
      amountMinor: parseMoney(_amount.text)!,
      description: _description.text,
      date: _date,
      userId: _userId,
      createdBy: _old?.createdBy ?? widget.profile.uid,
    );
    // Checked here, not in the rules: they cannot add up the wallet. Two
    // people spending at the same moment could still both get through.
    final balance = widget.data.balance;
    if (_spending && WalletMovement.overdraws(balance, entry, old: _old)) {
      final locale = Localizations.localeOf(context).toLanguageTag();
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.notEnoughTitle),
          content: Text(
            t.notEnoughBody(
              formatMoney(WalletMovement.available(balance, old: _old), locale),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.ok)),
          ],
        ),
      );
      return;
    }
    saveInBackground(context, () => WalletRepository.instance.save(entry));
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context);
    if (!await confirmDelete(context, t.deleteEntryQ) || !mounted) return;
    final id = _old!.id;
    saveInBackground(context, () => WalletRepository.instance.delete(id));
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = _old != null
        ? t.editEntry
        : (_spending ? t.newSpending : t.newDeposit);
    final users = [
      for (final u in widget.data.users ?? const <AppUser>[])
        if (!u.disabled || u.uid == _userId) u,
    ];
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_old != null && _canEdit)
            IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_canEdit) ...[
              Text(t.readOnlyNotice(widget.data.nameOf(_old!.createdBy))),
              gap,
            ],
            TextFormField(
              controller: _amount,
              enabled: _canEdit,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t.amount,
                suffixText: 'RSD',
                prefixIcon: const Icon(Icons.payments_outlined),
                helperText: _spending && _canEdit
                    ? t.availableInWallet(
                        formatMoney(
                          WalletMovement.available(
                            widget.data.balance,
                            old: _old,
                          ),
                          locale,
                        ),
                      )
                    : null,
              ),
              validator: (v) =>
                  parseMoney(v ?? '') == null ? t.invalidAmount : null,
            ),
            gap,
            TextFormField(
              controller: _description,
              enabled: _canEdit,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _spending ? t.spentOn : t.depositNote,
                hintText: _spending ? t.spentOnHint : t.depositNoteHint,
                alignLabelWithHint: true,
              ),
              // What the money went on is a must; a deposit note is not.
              validator: (v) => _spending && (v == null || v.trim().isEmpty)
                  ? t.required
                  : null,
            ),
            gap,
            TapField(
              label: t.date,
              value: DateFormat.yMMMMd(locale).format(_date),
              icon: Icons.event_rounded,
              onTap: _canEdit ? _pickDate : () {},
            ),
            gap,
            DropdownButtonFormField<String>(
              initialValue: _userId,
              decoration: InputDecoration(
                labelText: _spending ? t.whoSpent : t.whoDeposited,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              items: [
                for (final u in users)
                  DropdownMenuItem(value: u.uid, child: Text(u.displayName)),
              ],
              onChanged: _canEdit
                  ? (v) => setState(() => _userId = v ?? _userId)
                  : null,
            ),
            const SizedBox(height: 24),
            if (_canEdit) PearlButton(label: t.save, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
