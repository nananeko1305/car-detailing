import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/day_key.dart';
import '../models/job.dart';
import '../models/pricing.dart';
import '../money/money.dart';
import '../services/background_save.dart';
import '../services/job_repository.dart';
import '../services/live_data.dart';
import '../widgets/helpers_editor.dart';
import '../widgets/item_picker_sheet.dart';
import '../widgets/job_form_parts.dart';
import '../widgets/pearl.dart';

/// Books a job, or edits one. The price comes from the chosen price-list
/// items and the terms, and may be typed over. A new job can be saved as
/// already done, for a client who came without booking.
class JobFormScreen extends StatefulWidget {
  const JobFormScreen({
    super.key,
    required this.data,
    required this.profile,
    this.job,
    this.day,
  });

  final LiveData data;
  final AppUser profile;

  /// Null for a new job.
  final Job? job;

  /// The day a new job starts on.
  final DateTime? day;

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Job? _old = widget.job;
  late DateTime _day = _old?.day ?? dayOf(widget.day ?? DateTime.now());
  late String _start = _old?.start ?? '';
  late final _client = TextEditingController(text: _old?.clientName);
  late final _phone = TextEditingController(text: _old?.clientPhone);
  late final _address = TextEditingController(text: _old?.address);
  late final _notes = TextEditingController(text: _old?.notes);
  late final _price = TextEditingController(
    text: _old == null ? '' : moneyToInput(_old.priceMinor),
  );
  late List<JobItem> _items = [...?_old?.items];
  late final _finalDiscount = TextEditingController(
    text: (_old?.finalDiscountPercent ?? 0) == 0
        ? ''
        : '${_old!.finalDiscountPercent}',
  );
  late final _helpers = HelpersController([...?_old?.helpers])
    ..addListener(_refresh);
  late bool _chargeTravel = (_old?.travelMinor ?? 1) > 0;
  late bool _priceTyped = _old != null && _old.priceMinor != _quote.totalMinor;
  bool _alreadyDone = false;
  bool _toWallet = true;

  Quote get _quote => quote(
    _items,
    widget.data.rules,
    chargeTravel: _chargeTravel,
    finalPercent: int.tryParse(_finalDiscount.text.trim()) ?? 0,
  );

  @override
  void dispose() {
    for (final c in [
      _client,
      _phone,
      _address,
      _notes,
      _price,
      _finalDiscount,
    ]) {
      c.dispose();
    }
    _helpers.dispose();
    super.dispose();
  }

  /// Redraws "Ostaje tebi" as amounts are typed.
  void _refresh() {
    if (mounted) setState(() {});
  }

  /// Keeps the price on the list's figure until someone types their own.
  void _repriced() {
    if (!_priceTyped) _price.text = moneyToInput(_quote.totalMinor);
  }

  Future<void> _pickItems() async {
    final picked = await pickItems(context, widget.data, _items);
    if (picked == null) return;
    setState(() {
      _items = picked;
      _repriced();
    });
  }

  void _setQty(int i, int qty) => setState(() {
    if (qty <= 0) {
      _items = [..._items]..removeAt(i);
    } else {
      _items = [..._items]..[i] = _items[i].withQty(qty);
    }
    _repriced();
  });

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 3, 12, 31),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _pickStart() async {
    final parts = (_start.isEmpty ? '09:00' : _start).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 9,
        minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final text =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    setState(() => _start = text);
  }

  void _save() {
    final t = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    if (_start.isEmpty) {
      _snack(t.pickStartTime);
      return;
    }
    if (_items.isEmpty && _notes.text.trim().isEmpty) {
      _snack(t.addItemOrNote);
      return;
    }
    final helpersProblem = _helpers.validate(t);
    if (helpersProblem != null) {
      _snack(helpersProblem);
      return;
    }
    final q = _quote;
    final price = parseMoneyOrZero(_price.text)!;
    final me = widget.profile.uid;
    final job = Job(
      id: _old?.id ?? '',
      date: dateKey(_day),
      start: _start,
      clientName: _client.text,
      clientPhone: _phone.text,
      address: _address.text,
      items: _items,
      subtotalMinor: q.subtotalMinor,
      discountPercent: q.discountPercent,
      travelMinor: q.travelMinor,
      priceMinor: price,
      finalDiscountPercent: _items.isEmpty ? 0 : q.finalPercent,
      helpers: _helpers.helpers,
      notes: _notes.text,
      status: _alreadyDone ? JobStatus.done : JobStatus.booked,
      paidMinor: _alreadyDone ? price : null,
      toWallet: _toWallet,
      doneBy: _alreadyDone ? me : '',
      doneAt: _alreadyDone ? DateTime.now() : null,
    );
    final repo = JobRepository.instance;
    if (_old == null) {
      final id = repo.newId();
      saveInBackground(context, () => repo.create(id, job, me));
    } else {
      saveInBackground(context, () => repo.update(job, me));
    }
    Navigator.of(context).pop();
  }

  /// What the price leaves the admin after the helpers' pay.
  int get _leftOver =>
      (parseMoneyOrZero(_price.text) ?? 0) -
      _helpers.helpers.fold<int>(0, (a, h) => a + h.payMinor);

  String _leftLabel(AppLocalizations t) => widget.profile.isAdmin
      ? t.leftForYou
      : t.leftForAdmin(widget.data.admin?.shortName ?? t.roleAdmin);

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final rules = widget.data.rules;
    final q = _quote;
    final travelApplies =
        rules.travelMinor > 0 &&
        q.subtotalMinor > 0 &&
        q.subtotalMinor < rules.freeTravelFromMinor;
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: Text(_old == null ? t.newJob : t.editJob)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TapField(
              label: t.date,
              value: toBeginningOfSentenceCase(
                DateFormat.yMMMMEEEEd(locale).format(_day),
                locale,
              ),
              icon: Icons.event_rounded,
              onTap: _pickDay,
            ),
            gap,
            TapField(
              label: t.startTime,
              value: _start,
              icon: Icons.schedule_rounded,
              onTap: _pickStart,
            ),
            gap,
            TextFormField(
              controller: _client,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: t.clientName,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            gap,
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: t.clientPhone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            gap,
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.address,
                prefixIcon: const Icon(Icons.place_outlined),
              ),
            ),
            gap,
            ItemLines(items: _items, onQty: _setQty, onPick: _pickItems),
            const SizedBox(height: 10),
            if (_items.isNotEmpty) QuoteSummary(quote: q),
            if (travelApplies)
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(t.chargeTravel),
                value: _chargeTravel,
                onChanged: (v) => setState(() {
                  _chargeTravel = v;
                  _repriced();
                }),
              ),
            if (_items.isNotEmpty) ...[
              gap,
              TextFormField(
                controller: _finalDiscount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.finalDiscount,
                  suffixText: '%',
                  prefixIcon: const Icon(Icons.percent_rounded),
                  helperText: q.finalDiscountMinor > 0
                      ? '− ${formatMoney(q.finalDiscountMinor, locale)}'
                      : null,
                ),
                // A new discount sets the price again, even a typed one.
                onChanged: (_) => setState(() {
                  _priceTyped = false;
                  _repriced();
                }),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  final p = int.tryParse(text);
                  return text.isEmpty || (p != null && p >= 0 && p <= 100)
                      ? null
                      : t.invalidPercent;
                },
              ),
            ],
            gap,
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t.agreedPrice,
                suffixText: 'RSD',
                prefixIcon: const Icon(Icons.payments_outlined),
                helperText: _priceTyped && _items.isNotEmpty
                    ? t.priceTypedOver
                    : null,
              ),
              onChanged: (_) => setState(() => _priceTyped = true),
              validator: (v) =>
                  parseMoneyOrZero(v ?? '') == null ? t.invalidAmount : null,
            ),
            if (_priceTyped && _items.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() {
                    _priceTyped = false;
                    _repriced();
                  }),
                  child: Text(t.usePriceListPrice),
                ),
              ),
            gap,
            Text(t.whoWorks),
            const SizedBox(height: 8),
            HelpersEditor(
              controller: _helpers,
              candidates: widget.data.helperCandidates,
            ),
            LeftOverLine(label: _leftLabel(t), amount: _leftOver),
            gap,
            TextFormField(
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.notes,
                hintText: t.notesHint,
                alignLabelWithHint: true,
              ),
            ),
            if (_old == null) ...[
              gap,
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(t.alreadyDone),
                subtitle: Text(t.alreadyDoneHint),
                value: _alreadyDone,
                onChanged: (v) => setState(() => _alreadyDone = v),
              ),
              if (_alreadyDone)
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(t.intoWallet),
                  value: _toWallet,
                  onChanged: (v) => setState(() => _toWallet = v),
                ),
            ],
            const SizedBox(height: 22),
            PearlButton(label: t.save, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
