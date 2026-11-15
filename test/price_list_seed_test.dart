import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The price list the app loads must be the crew's paper list (2026-11-15):
/// same categories, same items, same prices, same terms.
void main() {
  final json = jsonDecode(
    File('assets/price_list.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final categories = (json['categories'] as List).cast<Map<String, dynamic>>();
  int price(String name) {
    for (final c in categories) {
      for (final i in (c['items'] as List).cast<Map<String, dynamic>>()) {
        if (i['name'] == name) return i['price'] as int;
      }
    }
    throw StateError('missing $name');
  }

  test('five categories, 31 items, the same total as the paper list', () {
    expect(categories.length, 5);
    final items = [
      for (final c in categories) ...(c['items'] as List).cast<Map>(),
    ];
    expect(items.length, 31);
    // Every price of the paper list added up.
    expect(items.fold<int>(0, (a, i) => a + (i['price'] as int)), 100550);
    expect(
      [for (final c in categories) (c['items'] as List).length],
      [14, 4, 5, 4, 4],
    );
  });

  test('spot checks', () {
    expect(price('Ugaona garnitura (po sednom mestu)'), 650);
    expect(price('Tapacirani bračni krevet'), 2500);
    expect(price('Kožni trosed'), 3200);
    expect(price('Bebi dušek obostrano'), 1200);
    expect(price('Standard – Srednji'), 6500);
    expect(price('Premium – SUV / 7 sedišta'), 12000);
  });

  test('the terms', () {
    final terms = json['terms'] as Map<String, dynamic>;
    expect(terms['freeTravelFrom'], 2500);
    expect(terms['discounts'], [
      {'over': 6000, 'percent': 10},
      {'over': 10000, 'percent': 15},
    ]);
  });

  test('no contact details from the paper list', () {
    final raw = File('assets/price_list.json').readAsStringSync();
    expect(raw.contains('381'), isFalse);
    expect(raw.contains('Filip'), isFalse);
  });
}
