import 'package:car_detailing/models/price_list.dart';
import 'package:car_detailing/models/pricing.dart';
import 'package:car_detailing/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

JobItem item(int dinars, {int qty = 1, String cat = 'c'}) => JobItem(
  itemId: 'i$dinars',
  categoryId: cat,
  name: 'Item $dinars',
  priceMinor: dinars * 100,
  qty: qty,
);

void main() {
  const rules = PricingRules();

  group('quote: the paper list terms', () {
    test('6.000 exactly gets no discount; "iznad" means strictly above', () {
      final q = quote([item(6000)], rules);
      expect(q.discountPercent, 0);
      expect(q.totalMinor, 600000);
    });

    test('above 6.000 gets 10%', () {
      // Kožni trosed + 2 kožne fotelje = 6.200 → 5.580.
      final q = quote([item(3200), item(1500, qty: 2)], rules);
      expect(q.subtotalMinor, 620000);
      expect(q.discountPercent, 10);
      expect(q.discountMinor, 62000);
      expect(q.totalMinor, 558000);
    });

    test('10.000 exactly is still 10%, above it 15%', () {
      expect(quote([item(10000)], rules).discountPercent, 10);
      final q = quote([item(10800)], rules); // Premium – Veliki
      expect(q.discountPercent, 15);
      expect(q.totalMinor, 918000);
    });

    test('the discount is rounded to whole dinars', () {
      // 6.001 × 10% = 600,10 → 600.
      final q = quote([item(6001)], rules);
      expect(q.discountMinor, 60000);
      expect(q.totalMinor % 100, 0);
    });

    test('quantities multiply: ugaona garnitura × 6 + fotelja', () {
      final q = quote([item(650, qty: 6), item(1100)], rules);
      expect(q.subtotalMinor, 500000);
      expect(q.totalMinor, 500000);
    });

    test('travel is free from 2.500 and when no fee is set', () {
      expect(quote([item(1000)], rules).travelMinor, 0);
      const paid = PricingRules(travelMinor: 50000);
      expect(quote([item(1000)], paid).travelMinor, 50000);
      expect(quote([item(1000)], paid).totalMinor, 150000);
      expect(quote([item(2500)], paid).travelMinor, 0);
      expect(quote([item(1000)], paid, chargeTravel: false).travelMinor, 0);
      expect(quote(const [], paid).travelMinor, 0);
    });
  });

  group('money', () {
    test('formats dinars the Serbian way', () {
      expect(formatMoney(558000, 'sr-Latn'), '5.580 RSD');
      expect(formatMoney(150050, 'sr-Latn'), '1.500,50 RSD');
      expect(formatMoney(650000, 'sr-Latn', unit: false), '6.500');
    });

    test('parses what people type', () {
      expect(parseMoney('5.580'), 558000);
      expect(parseMoney('5580'), 558000);
      expect(parseMoney('1500,5'), 150050);
      expect(parseMoney('12 345 RSD'), 1234500);
      expect(parseMoney('0'), isNull);
      expect(parseMoneyOrZero(''), 0);
      expect(parseMoneyOrZero('0'), 0);
      expect(parseMoneyOrZero('abc'), isNull);
    });
  });
}
