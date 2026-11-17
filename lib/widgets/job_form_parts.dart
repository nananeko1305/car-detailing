import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/pricing.dart';
import '../money/money.dart';
import '../theme/app_colors.dart';

/// A field that opens a picker: the date, a time.
class TapField extends StatelessWidget {
  const TapField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onClear == null || value.isEmpty
              ? null
              : IconButton(
                  tooltip: t.clear,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
                ),
        ),
        isEmpty: value.isEmpty,
        child: Text(value, maxLines: 1),
      ),
    );
  }
}

/// The chosen price-list lines, each with its quantity and line total.
class ItemLines extends StatelessWidget {
  const ItemLines({
    super.key,
    required this.items,
    required this.onQty,
    required this.onPick,
  });

  final List<JobItem> items;
  final void Function(int index, int qty) onQty;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.whatIsDone, style: c.display(15)),
            const SizedBox(height: 4),
            for (var i = 0; i < items.length; i++)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${items[i].qty} × ${formatMoney(items[i].priceMinor, locale)}',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: t.less,
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: () => onQty(i, items[i].qty - 1),
                  ),
                  Text('${items[i].qty}', style: c.display(15)),
                  IconButton(
                    tooltip: t.more,
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => onQty(i, items[i].qty + 1),
                  ),
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.playlist_add_rounded),
                label: Text(t.addFromPriceList),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtotal, discount and travel, the way the price list works them out.
class QuoteSummary extends StatelessWidget {
  const QuoteSummary({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget line(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: strong ? c.ink : c.muted),
            ),
          ),
          Text(
            value,
            style: strong
                ? c.display(16)
                : TextStyle(color: c.ink, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          line(t.subtotal, formatMoney(quote.subtotalMinor, locale)),
          if (quote.discountPercent > 0)
            line(
              t.discountPercent(quote.discountPercent),
              '− ${formatMoney(quote.discountMinor, locale)}',
            ),
          if (quote.travelMinor > 0)
            line(t.travel, formatMoney(quote.travelMinor, locale)),
          line(
            t.byPriceList,
            formatMoney(quote.totalMinor, locale),
            strong: true,
          ),
        ],
      ),
    );
  }
}
