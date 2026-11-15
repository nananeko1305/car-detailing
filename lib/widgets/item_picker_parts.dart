import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/price_list.dart';
import '../models/pricing.dart';
import '../theme/app_colors.dart';

/// One category of the picker, opening in place: its name, how many items
/// it has and how many are already on the job; tapped, its items unfold
/// below it and push the other categories down.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.itemCount,
    required this.picked,
    required this.open,
    required this.onTap,
    required this.items,
  });

  final PriceCategory category;
  final int itemCount;

  /// Lines of this category already chosen (quantities added up).
  final int picked;
  final bool open;
  final VoidCallback onTap;

  /// The item rows, shown while [open].
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final lit = picked > 0 || open;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: picked > 0 ? c.soft : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lit ? c.primary : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              expanded: open,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.name, style: c.display(16)),
                            const SizedBox(height: 3),
                            Text(
                              picked > 0
                                  ? '${t.itemsCount(itemCount)} · ${t.pickedCount(picked)}'
                                  : t.itemsCount(itemCount),
                              style: TextStyle(
                                fontSize: 12,
                                color: picked > 0 ? c.primary : c.muted,
                                fontWeight: picked > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: open ? c.primary : c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: open
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (category.note.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
                              child: Text(
                                category.note,
                                style: TextStyle(fontSize: 12, color: c.muted),
                              ),
                            ),
                          ...items,
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// A price-list item with its price and, once chosen, a quantity stepper.
class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.name,
    required this.price,
    required this.qty,
    required this.onChanged,
  });

  final String name;
  final String price;
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final picked = qty > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: picked ? c.soft : c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: picked ? c.primary : c.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: picked ? null : () => onChanged(1),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(price, style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              QtyStepper(qty: qty, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// "+" while nothing is chosen, then "− 6 +".
class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.qty, required this.onChanged});

  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    if (qty <= 0) {
      return IconButton(
        tooltip: t.add,
        icon: Icon(Icons.add_circle_outline_rounded, color: c.primary),
        onPressed: () => onChanged(1),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: t.less,
          icon: const Icon(Icons.remove_rounded),
          onPressed: () => onChanged(qty - 1),
        ),
        SizedBox(
          width: 22,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: c.display(16),
          ),
        ),
        IconButton(
          tooltip: t.more,
          icon: const Icon(Icons.add_rounded),
          onPressed: () => onChanged(qty + 1),
        ),
      ],
    );
  }
}

/// The review before closing the picker: every chosen line with its
/// quantity and total, and the sum.
class ReviewList extends StatelessWidget {
  const ReviewList({
    super.key,
    required this.lines,
    required this.price,
    required this.onChanged,
  });

  final List<JobItem> lines;
  final String Function(int minor) price;
  final void Function(JobItem line, int qty) onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final total = lines.fold<int>(0, (a, l) => a + l.totalMinor);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        for (final l in lines)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${l.qty} × ${price(l.priceMinor)} = ${price(l.totalMinor)}',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
                QtyStepper(qty: l.qty, onChanged: (q) => onChanged(l, q)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Row(
            children: [
              Expanded(child: Text(t.subtotal, style: c.display(16))),
              Text(price(total), style: c.display(18)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Text(
            t.reviewHint,
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
        ),
      ],
    );
  }
}
