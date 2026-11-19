import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/price_list.dart';
import '../money/money.dart';
import '../services/background_save.dart';
import '../services/live_data.dart';
import '../services/price_list_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/earnings_parts.dart';
import '../widgets/pearl.dart';

/// "Pogodnosti": the discounts by order size and the travel terms that new
/// jobs are priced by. The admin edits them; a worker reads them. Booked
/// jobs keep the terms they were booked with.
class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key, required this.data, required this.profile});

  final LiveData data;
  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.deals)),
      body: ListenableBuilder(
        listenable: data,
        // The terms arrive with the price list; until then they are only
        // the defaults, which the admin must not save over the real ones.
        builder: (context, _) => data.categories == null
            ? const Center(child: CircularProgressIndicator())
            : profile.isAdmin
            ? _DealsForm(rules: data.rules)
            : _DealsView(rules: data.rules),
      ),
    );
  }
}

/// The terms as a list, for a worker.
class _DealsView extends StatelessWidget {
  const _DealsView({required this.rules});

  final PricingRules rules;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    String money(int v) => formatMoney(v, locale);
    Widget line(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('• $text'),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        SectionTitle(t.dealsDiscounts),
        for (final d in rules.discounts)
          line(t.discountRule(d.percent, money(d.overMinor))),
        const SizedBox(height: 14),
        SectionTitle(t.travel),
        line(t.freeTravelRule(money(rules.freeTravelFromMinor))),
        if (rules.travelMinor > 0)
          line(t.travelFeeRule(money(rules.travelMinor))),
      ],
    );
  }
}

/// The admin's editor: any number of discounts, then travel, then save.
class _DealsForm extends StatefulWidget {
  const _DealsForm({required this.rules});

  final PricingRules rules;

  @override
  State<_DealsForm> createState() => _DealsFormState();
}

class _DealsFormState extends State<_DealsForm> {
  /// The rules allow at most this many discounts.
  static const _maxDiscounts = 20;

  final _form = GlobalKey<FormState>();
  late final List<(TextEditingController, TextEditingController)> _rows = [
    for (final d in [
      ...widget.rules.discounts,
    ]..sort((a, b) => a.overMinor.compareTo(b.overMinor)))
      _row(moneyToInput(d.overMinor), '${d.percent}'),
  ];
  late final _free = TextEditingController(
    text: moneyToInput(widget.rules.freeTravelFromMinor),
  );
  late final _fee = TextEditingController(
    text: moneyToInput(widget.rules.travelMinor),
  );

  /// Rows taken out; their fields may still be on screen this frame, so
  /// they are disposed with the rest.
  final _removed = <(TextEditingController, TextEditingController)>[];

  static (TextEditingController, TextEditingController) _row(
    String over,
    String percent,
  ) =>
      (TextEditingController(text: over), TextEditingController(text: percent));

  @override
  void dispose() {
    for (final (over, pct) in [..._rows, ..._removed]) {
      over.dispose();
      pct.dispose();
    }
    _free.dispose();
    _fee.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final rules = PricingRules(
      // A 0% row gives nothing: it is left out.
      discounts: [
        for (final (over, pct) in _rows)
          if (int.parse(pct.text.trim()) > 0)
            Discount(
              overMinor: parseMoneyOrZero(over.text)!,
              percent: int.parse(pct.text.trim()),
            ),
      ]..sort((a, b) => a.overMinor.compareTo(b.overMinor)),
      freeTravelFromMinor: parseMoneyOrZero(_free.text)!,
      travelMinor: parseMoneyOrZero(_fee.text)!,
    );
    saveInBackground(
      context,
      () => PriceListRepository.instance.saveRules(rules),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    String? money(String? v) =>
        parseMoneyOrZero(v ?? '') == null ? t.invalidAmount : null;
    String? percent(String? v) {
      final p = int.tryParse(v?.trim() ?? '');
      return p == null || p < 0 || p > 100 ? t.invalidPercent : null;
    }

    const gap = SizedBox(height: 12);
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionTitle(t.dealsDiscounts),
          Text(t.dealsHint, style: TextStyle(fontSize: 12, color: c.muted)),
          gap,
          for (final (i, (over, pct)) in _rows.indexed) ...[
            Row(
              key: ObjectKey(over),
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: over,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t.over,
                      suffixText: 'RSD',
                    ),
                    validator: money,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: pct,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t.discount,
                      suffixText: '%',
                    ),
                    validator: percent,
                  ),
                ),
                IconButton(
                  tooltip: t.delete,
                  icon: Icon(Icons.close_rounded, color: c.muted),
                  onPressed: () =>
                      setState(() => _removed.add(_rows.removeAt(i))),
                ),
              ],
            ),
            gap,
          ],
          if (_rows.length < _maxDiscounts)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _rows.add(_row('', ''))),
                icon: const Icon(Icons.add_rounded),
                label: Text(t.addDiscount),
              ),
            ),
          const SizedBox(height: 18),
          SectionTitle(t.travel),
          TextFormField(
            controller: _free,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.freeTravelFrom,
              suffixText: 'RSD',
            ),
            validator: money,
          ),
          gap,
          TextFormField(
            controller: _fee,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.travelFee,
              helperText: t.travelFeeHint,
              suffixText: 'RSD',
            ),
            validator: money,
          ),
          const SizedBox(height: 24),
          PearlButton(
            label: t.save,
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
