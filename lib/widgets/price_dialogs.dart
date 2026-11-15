import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/price_list.dart';
import '../money/money.dart';

/// Edits or adds a price-list item: its name and price. Returns the item to
/// save, or null when dismissed.
Future<PriceItem?> showItemDialog(
  BuildContext context, {
  required String categoryId,
  required int order,
  PriceItem? item,
}) {
  final t = AppLocalizations.of(context);
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: item?.name);
  final price = TextEditingController(
    text: item == null ? '' : moneyToInput(item.priceMinor),
  );
  return showDialog<PriceItem>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(item == null ? t.newItem : t.editItem),
      content: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              autofocus: item == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: t.itemName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t.price,
                suffixText: 'RSD',
              ),
              validator: (v) =>
                  parseMoneyOrZero(v ?? '') == null ? t.invalidAmount : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.goBack)),
        TextButton(
          onPressed: () {
            if (!form.currentState!.validate()) return;
            Navigator.pop(
              ctx,
              PriceItem(
                id: item?.id ?? '',
                categoryId: categoryId,
                name: name.text.trim(),
                priceMinor: parseMoneyOrZero(price.text)!,
                order: item?.order ?? order,
                archived: item?.archived ?? false,
              ),
            );
          },
          child: Text(t.save),
        ),
      ],
    ),
  );
}

/// Edits or adds a category: its name and the note under it.
Future<PriceCategory?> showCategoryDialog(
  BuildContext context, {
  required int order,
  PriceCategory? category,
}) {
  final t = AppLocalizations.of(context);
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: category?.name);
  final note = TextEditingController(text: category?.note);
  return showDialog<PriceCategory>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(category == null ? t.newCategory : t.editCategory),
      content: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              autofocus: category == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: t.categoryName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: note,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.categoryNote,
                hintText: t.categoryNoteHint,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.goBack)),
        TextButton(
          onPressed: () {
            if (!form.currentState!.validate()) return;
            Navigator.pop(
              ctx,
              PriceCategory(
                id: category?.id ?? '',
                name: name.text.trim(),
                note: note.text.trim(),
                order: category?.order ?? order,
                archived: category?.archived ?? false,
              ),
            );
          },
          child: Text(t.save),
        ),
      ],
    ),
  );
}

/// Edits the terms: the two discounts, free travel and the travel fee.
Future<PricingRules?> showRulesDialog(BuildContext context, PricingRules r) {
  final t = AppLocalizations.of(context);
  final form = GlobalKey<FormState>();
  final d = [
    ...r.discounts,
    for (var i = r.discounts.length; i < 2; i++)
      const Discount(overMinor: 0, percent: 0),
  ];
  final over1 = TextEditingController(text: moneyToInput(d[0].overMinor));
  final pct1 = TextEditingController(text: '${d[0].percent}');
  final over2 = TextEditingController(text: moneyToInput(d[1].overMinor));
  final pct2 = TextEditingController(text: '${d[1].percent}');
  final free = TextEditingController(text: moneyToInput(r.freeTravelFromMinor));
  final fee = TextEditingController(text: moneyToInput(r.travelMinor));
  String? money(String? v) =>
      parseMoneyOrZero(v ?? '') == null ? t.invalidAmount : null;
  String? percent(String? v) {
    final p = int.tryParse(v?.trim() ?? '');
    return p == null || p < 0 || p > 100 ? t.invalidPercent : null;
  }

  Widget pair(TextEditingController over, TextEditingController pct) => Row(
    children: [
      Expanded(
        flex: 3,
        child: TextFormField(
          controller: over,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: t.over, suffixText: 'RSD'),
          validator: money,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 2,
        child: TextFormField(
          controller: pct,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: t.discount, suffixText: '%'),
          validator: percent,
        ),
      ),
    ],
  );

  return showDialog<PricingRules>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.terms),
      content: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              pair(over1, pct1),
              const SizedBox(height: 12),
              pair(over2, pct2),
              const SizedBox(height: 12),
              TextFormField(
                controller: free,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.freeTravelFrom,
                  suffixText: 'RSD',
                ),
                validator: money,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fee,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.travelFee,
                  helperText: t.travelFeeHint,
                  suffixText: 'RSD',
                ),
                validator: money,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.goBack)),
        TextButton(
          onPressed: () {
            if (!form.currentState!.validate()) return;
            Navigator.pop(
              ctx,
              PricingRules(
                discounts: [
                  for (final p in [(over1, pct1), (over2, pct2)])
                    if (int.parse(p.$2.text.trim()) > 0)
                      Discount(
                        overMinor: parseMoneyOrZero(p.$1.text)!,
                        percent: int.parse(p.$2.text.trim()),
                      ),
                ],
                freeTravelFromMinor: parseMoneyOrZero(free.text)!,
                travelMinor: parseMoneyOrZero(fee.text)!,
              ),
            );
          },
          child: Text(t.save),
        ),
      ],
    ),
  );
}
