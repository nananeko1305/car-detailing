import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/earnings.dart';
import '../money/money.dart';
import '../services/live_data.dart';
import '../theme/app_colors.dart';
import 'earnings_parts.dart';
import 'month_switcher.dart';

/// One month in the wallet. The admin sees what the month left them, what
/// went to the helpers and what was spent (equipment included, entered by
/// hand); a worker sees what they were paid.
class WalletMonthCard extends StatefulWidget {
  const WalletMonthCard({super.key, required this.data, required this.profile});

  final LiveData data;
  final AppUser profile;

  @override
  State<WalletMonthCard> createState() => _WalletMonthCardState();
}

class _WalletMonthCardState extends State<WalletMonthCard> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String money(int v) => formatMoney(v, locale);
    final data = widget.data;
    final me = data.userById(widget.profile.uid) ?? widget.profile;
    final e = Earnings.of(
      jobs: data.jobs ?? const [],
      entries: data.entries ?? const [],
      from: _month,
      to: DateTime(_month.year, _month.month + 1),
    );
    final now = DateTime.now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MonthSwitcher(
              month: _month,
              first: DateTime(2024),
              last: DateTime(now.year + 1, 12),
              onChanged: (m) => setState(() => _month = m),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: me.isAdmin
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Big(
                          label: t.myEarnings,
                          value: money(e.adminNetMinor),
                          color: e.adminNetMinor < 0 ? c.danger : c.mint,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: StatTile(
                                label: t.givenToHelpers,
                                value: money(e.helpersPaidMinor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StatTile(
                                label: t.costs,
                                value: money(e.spendingMinor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.chargedShort(money(e.earnedMinor)),
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    )
                  : _Big(
                      label: t.iGot,
                      value: money(e.paidTo(me.uid)),
                      color: c.mint,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: c.muted)),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: c.display(24, color: color)),
        ),
      ],
    );
  }
}
