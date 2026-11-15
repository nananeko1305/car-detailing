import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One month as a calendar grid, weeks starting on the locale's first
/// day. A day shows up to three dots for its jobs; today is ringed and the
/// selected day filled with the pearl.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.today,
    required this.counts,
    required this.onSelect,
  });

  /// Any day of the month to show.
  final DateTime month;

  /// Midnight of the chosen day, and of today.
  final DateTime selected;
  final DateTime today;

  /// Jobs per day, keyed by midnight.
  final Map<DateTime, int> counts;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final ml = MaterialLocalizations.of(context);
    // 0 is Sunday in both MaterialLocalizations and `weekday % 7`.
    final firstDay = ml.firstDayOfWeekIndex;
    final lead = (DateTime(month.year, month.month).weekday % 7 - firstDay) % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  ml.narrowWeekdays[(firstDay + i) % 7],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.colors.muted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var w = 0; w < cells.length; w += 7)
          Row(
            children: [
              for (final day in cells.sublist(w, w + 7))
                Expanded(
                  child: day == null
                      ? const SizedBox(height: _Day.height)
                      : _Day(
                          key: ValueKey(day),
                          day: day,
                          count: counts[day] ?? 0,
                          selected: day == selected,
                          today: day == today,
                          onTap: () => onSelect(day),
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    super.key,
    required this.day,
    required this.count,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  static const height = 48.0;

  final DateTime day;
  final int count;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dots = count.clamp(0, 3);
    final dotColors = [c.primary, c.secondary, c.mint];
    return Semantics(
      selected: selected,
      button: true,
      label:
          '${MaterialLocalizations.of(context).formatMediumDate(day)}, $count',
      excludeSemantics: true,
      // The tap goes on the merged node, or TalkBack could not pick a day.
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          height: height,
          child: Center(
            child: Container(
              width: 40,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: selected ? c.pearlGradient : null,
                border: today && !selected
                    ? Border.all(color: c.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected || today
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected ? c.onPrimary : c.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Keeps its height when empty, so rows never jump.
                  SizedBox(
                    height: 5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < dots; i++)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? c.onPrimary : dotColors[i],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
