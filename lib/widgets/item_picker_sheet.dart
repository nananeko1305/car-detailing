import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/pricing.dart';
import '../money/money.dart';
import '../services/live_data.dart';
import '../theme/app_colors.dart';
import 'item_picker_parts.dart';
import 'pearl.dart';

/// The price list as categories that open in place: tapping one unfolds its
/// items below it, with a quantity each, so nobody scrolls through the whole
/// list. One category is open at a time. The button at the bottom leads to a
/// review of everything chosen, and only there is "Gotovo". Returns the
/// chosen lines, or null when dismissed. Lines already on the job keep their
/// booked price even if the list has changed since.
Future<List<JobItem>?> pickItems(
  BuildContext context,
  LiveData data,
  List<JobItem> current,
) => showModalBottomSheet<List<JobItem>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _ItemPicker(data: data, initial: current),
);

class _ItemPicker extends StatefulWidget {
  const _ItemPicker({required this.data, required this.initial});

  final LiveData data;
  final List<JobItem> initial;

  @override
  State<_ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<_ItemPicker> {
  /// itemId → line, in the order they were first picked.
  late final Map<String, JobItem> _lines = {
    for (final i in widget.initial) i.itemId: i,
  };

  /// The open category, or null when all are closed.
  String? _open;

  /// Showing the review of the chosen lines instead of the categories.
  bool _review = false;
  final Map<String, GlobalKey> _keys = {};

  void _set(String itemId, JobItem Function() line, int qty) => setState(() {
    if (qty <= 0) {
      _lines.remove(itemId);
      // Nothing left to review: back to the price list.
      if (_lines.isEmpty) _review = false;
    } else {
      _lines[itemId] = (_lines[itemId] ?? line()).withQty(qty);
    }
  });

  int _pickedIn(String categoryId) => _lines.values
      .where((l) => l.categoryId == categoryId)
      .fold(0, (a, l) => a + l.qty);

  /// Opens [id] (closing the one before), or closes it when it is open. An
  /// opened category is scrolled up into view, since closing one above it
  /// moves it.
  void _toggle(String id) {
    setState(() => _open = _open == id ? null : id);
    if (_open == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[id]?.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String price(int minor) => formatMoney(minor, locale);
    final subtotal = _lines.values.fold<int>(0, (a, i) => a + i.totalMinor);
    final data = widget.data;
    final categories = data.liveCategories;
    return PopScope(
      // The phone's back button leaves the review before closing.
      canPop: !_review,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _review = false);
      },
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(_review ? 8 : 20, 0, 20, 6),
              child: Row(
                children: [
                  if (_review)
                    IconButton(
                      tooltip: t.backToPriceList,
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => setState(() => _review = false),
                    ),
                  Expanded(
                    child: Text(
                      _review ? t.review : t.priceList,
                      style: c.display(20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _review
                  ? ReviewList(
                      lines: _lines.values.toList(),
                      price: price,
                      onChanged: (l, q) => _set(l.itemId, () => l, q),
                    )
                  : categories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          t.priceListEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.muted),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        for (final cat in categories)
                          CategoryTile(
                            key: _keys.putIfAbsent(cat.id, GlobalKey.new),
                            category: cat,
                            itemCount: data.itemsOf(cat.id).length,
                            picked: _pickedIn(cat.id),
                            open: _open == cat.id,
                            onTap: () => _toggle(cat.id),
                            items: [
                              for (final item in data.itemsOf(cat.id))
                                ItemRow(
                                  name: item.name,
                                  price: price(item.priceMinor),
                                  qty: _lines[item.id]?.qty ?? 0,
                                  onChanged: (q) =>
                                      _set(item.id, () => JobItem.of(item), q),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _review || _lines.isEmpty
                    ? PearlButton(
                        label: _lines.isEmpty
                            ? t.done
                            : t.doneWithTotal(price(subtotal)),
                        icon: _lines.isEmpty ? null : Icons.check_rounded,
                        onPressed: () =>
                            Navigator.of(context).pop(_lines.values.toList()),
                      )
                    : PearlButton(
                        label: t.reviewWithTotal(
                          _lines.values.fold(0, (a, l) => a + l.qty),
                          price(subtotal),
                        ),
                        onPressed: () => setState(() => _review = true),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
