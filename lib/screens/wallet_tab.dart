import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/wallet_entry.dart';
import '../money/money.dart';
import '../services/live_data.dart';
import '../theme/app_colors.dart';
import '../widgets/wallet_month_card.dart';
import 'job_detail_screen.dart';
import 'wallet_entry_screen.dart';

/// The shared cash box: the balance, buttons to put money in or spend it,
/// and every movement, newest first. Finished jobs come in by themselves.
class WalletTab extends StatelessWidget {
  const WalletTab({super.key, required this.data, required this.profile});

  final LiveData data;
  final AppUser profile;

  void _openEntry(
    BuildContext context,
    WalletEntryType type, [
    WalletEntry? e,
  ]) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          WalletEntryScreen(data: data, profile: profile, type: type, entry: e),
    ),
  );

  void _openMovement(BuildContext context, WalletMovement m) {
    if (m.job != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              JobDetailScreen(data: data, profile: profile, jobId: m.job!.id),
        ),
      );
    } else if (m.entry != null) {
      _openEntry(context, m.entry!.type, m.entry);
    }
  }

  /// "naplaćeno 7.380 · radnicima 2.000 · oprema 500" under a finished job
  /// whose helpers or equipment took part of the money; null otherwise.
  String? _jobDetail(AppLocalizations t, WalletMovement m, String locale) {
    final j = m.job;
    if (j == null || (j.helpers.isEmpty && j.equipmentMinor == 0)) return null;
    String money(int v) => formatMoney(v, locale, unit: false);
    return [
      t.chargedShort(money(j.earnedMinor)),
      if (j.helpers.isNotEmpty) t.toHelpersShort(money(j.helpersPaidMinor)),
      if (j.equipmentMinor > 0) t.equipmentShort(money(j.equipmentMinor)),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (data.jobs == null || data.entries == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final movements = data.movements;
    final balance = WalletMovement.balance(movements);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.inWallet, style: TextStyle(color: c.muted)),
                const SizedBox(height: 4),
                Text(
                  formatMoney(balance, locale),
                  style: c.display(32, color: balance < 0 ? c.danger : c.ink),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openEntry(context, WalletEntryType.deposit),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(t.putIn),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openEntry(context, WalletEntryType.withdrawal),
                        icon: const Icon(Icons.remove_rounded),
                        label: Text(t.spend),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        WalletMonthCard(data: data, profile: profile),
        const SizedBox(height: 18),
        Text(t.history, style: c.display(17)),
        const SizedBox(height: 8),
        if (movements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              t.walletEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted),
            ),
          ),
        for (final m in movements)
          _MovementTile(
            movement: m,
            who: data.nameOf(m.userId),
            date: DateFormat.MMMd(locale).format(m.date),
            amount: formatMoney(m.signedMinor.abs(), locale),
            detail: _jobDetail(t, m, locale),
            onTap: () => _openMovement(context, m),
          ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({
    required this.movement,
    required this.who,
    required this.date,
    required this.amount,
    required this.onTap,
    this.detail,
  });

  final WalletMovement movement;
  final String who;
  final String date;
  final String amount;
  final VoidCallback onTap;

  /// A job's split: charged, helpers, equipment.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final incoming = movement.signedMinor >= 0;
    final icon = movement.job != null
        ? Icons.local_car_wash_rounded
        : incoming
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: incoming ? c.soft : c.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: incoming ? c.primary : c.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.description.isEmpty
                        ? (incoming ? t.deposit : t.spending)
                        : movement.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$date · $who',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.secondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${incoming ? '+' : '−'} $amount',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: incoming ? c.success : c.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
