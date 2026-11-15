import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/price_list.dart';
import '../money/money.dart';
import '../services/background_save.dart';
import '../services/live_data.dart';
import '../services/price_list_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/pearl.dart';
import '../widgets/price_dialogs.dart';

/// The price list by category, with the terms at the end. Everyone reads
/// it; the admin adds, edits and puts away items and categories. Nothing is
/// deleted: a job keeps its own copy of what it was booked with.
class PriceListScreen extends StatelessWidget {
  const PriceListScreen({super.key, required this.data, required this.profile});

  final LiveData data;
  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final admin = profile.isAdmin;
        final categories = data.liveCategories;
        return Scaffold(
          appBar: AppBar(
            title: Text(t.priceList),
            actions: [
              if (admin)
                IconButton(
                  tooltip: t.newCategory,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  onPressed: () async {
                    final c = await showCategoryDialog(
                      context,
                      order: categories.length,
                    );
                    if (c != null && context.mounted) {
                      saveInBackground(
                        context,
                        () => PriceListRepository.instance.saveCategory(c),
                      );
                    }
                  },
                ),
            ],
          ),
          body: data.categories == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    if (categories.isEmpty) _Empty(admin: admin),
                    for (final c in categories)
                      _CategoryCard(data: data, category: c, admin: admin),
                    if (categories.isNotEmpty)
                      _Terms(rules: data.rules, admin: admin),
                  ],
                ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.admin});

  final bool admin;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            admin ? t.priceListEmptyAdmin : t.priceListEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted),
          ),
          if (admin) ...[
            const SizedBox(height: 18),
            PearlButton(
              label: t.loadPriceList,
              icon: Icons.download_rounded,
              onPressed: () =>
                  saveInBackground(context, PriceListRepository.instance.seed),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.data,
    required this.category,
    required this.admin,
  });

  final LiveData data;
  final PriceCategory category;
  final bool admin;

  Future<void> _edit(BuildContext context) async {
    final c = await showCategoryDialog(
      context,
      order: category.order,
      category: category,
    );
    if (c != null && context.mounted) {
      saveInBackground(
        context,
        () => PriceListRepository.instance.saveCategory(c),
      );
    }
  }

  Future<void> _archive(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await confirmDelete(
      context,
      t.archiveCategoryQ(category.name),
      body: t.archiveBody,
      confirmLabel: t.archive,
    );
    if (!ok || !context.mounted) return;
    saveInBackground(
      context,
      () => PriceListRepository.instance.saveCategory(
        PriceCategory(
          id: category.id,
          name: category.name,
          note: category.note,
          order: category.order,
          archived: true,
        ),
      ),
    );
  }

  Future<void> _editItem(
    BuildContext context,
    PriceItem? item,
    int count,
  ) async {
    final i = await showItemDialog(
      context,
      categoryId: category.id,
      order: count,
      item: item,
    );
    if (i != null && context.mounted) {
      saveInBackground(context, () => PriceListRepository.instance.saveItem(i));
    }
  }

  Future<void> _archiveItem(BuildContext context, PriceItem item) async {
    final t = AppLocalizations.of(context);
    final ok = await confirmDelete(
      context,
      t.archiveItemQ(item.name),
      body: t.archiveBody,
      confirmLabel: t.archive,
    );
    if (!ok || !context.mounted) return;
    saveInBackground(
      context,
      () => PriceListRepository.instance.saveItem(
        PriceItem(
          id: item.id,
          categoryId: item.categoryId,
          name: item.name,
          priceMinor: item.priceMinor,
          order: item.order,
          archived: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final items = data.itemsOf(category.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(category.name, style: c.display(17))),
                  if (admin)
                    PopupMenuButton<String>(
                      tooltip: t.more,
                      onSelected: (v) =>
                          v == 'edit' ? _edit(context) : _archive(context),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(t.edit)),
                        PopupMenuItem(value: 'archive', child: Text(t.archive)),
                      ],
                    ),
                ],
              ),
              if (category.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 6),
                  child: Text(
                    category.note,
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ),
              for (final i in items)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: admin
                      ? () => _editItem(context, i, items.length)
                      : null,
                  onLongPress: admin ? () => _archiveItem(context, i) : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 9, 8, 9),
                    child: Row(
                      children: [
                        Expanded(child: Text(i.name)),
                        const SizedBox(width: 10),
                        Text(
                          formatMoney(i.priceMinor, locale),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              if (admin)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _editItem(context, null, items.length),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(t.newItem),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Terms extends StatelessWidget {
  const _Terms({required this.rules, required this.admin});

  final PricingRules rules;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String money(int v) => formatMoney(v, locale);
    final lines = [
      for (final d in rules.discounts)
        t.discountRule(d.percent, money(d.overMinor)),
      t.freeTravelRule(money(rules.freeTravelFromMinor)),
      if (rules.travelMinor > 0) t.travelFeeRule(money(rules.travelMinor)),
    ];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(c.radius),
        onTap: admin
            ? () async {
                final r = await showRulesDialog(context, rules);
                if (r != null && context.mounted) {
                  saveInBackground(
                    context,
                    () => PriceListRepository.instance.saveRules(r),
                  );
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(t.terms, style: c.display(17))),
                  if (admin)
                    Icon(Icons.edit_outlined, size: 18, color: c.muted),
                ],
              ),
              const SizedBox(height: 6),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('• $l'),
                ),
              if (admin) ...[
                const SizedBox(height: 6),
                Text(
                  t.priceListAdminHint,
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
