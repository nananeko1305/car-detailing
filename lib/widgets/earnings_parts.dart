import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

/// The big number on top of the earnings, on a pearl-edged card.
class HeroTotal extends StatelessWidget {
  const HeroTotal({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(c.radius + 1),
        gradient: c.pearlGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(c.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: c.muted)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: c.display(34)),
            ),
            const SizedBox(height: 4),
            Text(caption, style: TextStyle(fontSize: 13, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

/// A small labelled figure: costs, what is left.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: c.display(18, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: context.colors.display(16)),
  );
}

/// Rows of "name — amount" with a bar for each one's part of [total],
/// biggest first.
class ShareList extends StatelessWidget {
  const ShareList({
    super.key,
    required this.rows,
    required this.total,
    required this.format,
  });

  final List<(String, int)> rows;
  final int total;
  final String Function(int) format;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sorted = [...rows]..sort((a, b) => b.$2.compareTo(a.$2));
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          children: [
            for (final r in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          format(r.$2),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(
                        children: [
                          Container(height: 6, color: c.surfaceHigh),
                          FractionallySizedBox(
                            widthFactor: total <= 0
                                ? 0
                                : (r.$2 / total).clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: c.pearlGradient,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Twelve bars, January to December, each month's earnings.
class MonthBars extends StatelessWidget {
  const MonthBars({super.key, required this.values, required this.locale});

  final List<int> values;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = values.fold<int>(0, (a, v) => v > a ? v : a);
    final names = DateFormat.MMM(locale);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        child: SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var m = 0; m < 12; m++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: top == 0 ? 0 : values[m] / top,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: values[m] == 0
                                  ? null
                                  : LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: c.pearl,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        names.format(DateTime(2026, m + 1)).substring(0, 1),
                        style: TextStyle(fontSize: 11, color: c.muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
