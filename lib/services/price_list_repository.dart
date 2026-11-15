import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/price_list.dart';

/// The price list: `priceCategories`, `priceItems` and the terms in
/// `meta/pricing`. Everyone reads it; only the admin writes (the rules say
/// so). Nothing is ever deleted, only archived.
class PriceListRepository {
  PriceListRepository._();
  static final PriceListRepository instance = PriceListRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection('priceCategories');
  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('priceItems');
  DocumentReference<Map<String, dynamic>> get _rules => _db.doc('meta/pricing');

  Stream<List<PriceCategory>> watchCategories() => _categories.snapshots().map(
    (s) =>
        s.docs.map(PriceCategory.fromDoc).toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
  );

  Stream<List<PriceItem>> watchItems() => _items.snapshots().map(
    (s) =>
        s.docs.map(PriceItem.fromDoc).toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
  );

  Stream<PricingRules> watchRules() =>
      _rules.snapshots().map((d) => PricingRules.fromMap(d.data()));

  Future<void> saveCategory(PriceCategory c) => c.id.isEmpty
      ? _categories.add(c.toMap())
      : _categories.doc(c.id).set(c.toMap());

  Future<void> saveItem(PriceItem i) =>
      i.id.isEmpty ? _items.add(i.toMap()) : _items.doc(i.id).set(i.toMap());

  Future<void> saveRules(PricingRules r) => _rules.set(r.toMap());

  /// Writes the crew's paper price list (`assets/price_list.json`) in one
  /// batch: its categories, items and terms. Offered only while the list is
  /// empty, so it never doubles anything.
  Future<void> seed() async {
    final raw = await rootBundle.loadString('assets/price_list.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final batch = _db.batch();
    var catOrder = 0;
    for (final c in json['categories'] as List) {
      final cat = c as Map<String, dynamic>;
      final catRef = _categories.doc();
      batch.set(
        catRef,
        PriceCategory(
          id: catRef.id,
          name: cat['name'] as String,
          note: cat['note'] as String? ?? '',
          order: catOrder++,
        ).toMap(),
      );
      var itemOrder = 0;
      for (final i in cat['items'] as List) {
        final item = i as Map<String, dynamic>;
        batch.set(
          _items.doc(),
          PriceItem(
            id: '',
            categoryId: catRef.id,
            name: item['name'] as String,
            priceMinor: (item['price'] as num).toInt() * 100,
            order: itemOrder++,
          ).toMap(),
        );
      }
    }
    final terms = json['terms'] as Map<String, dynamic>;
    batch.set(
      _rules,
      PricingRules(
        discounts: [
          for (final d in terms['discounts'] as List)
            Discount(
              overMinor: ((d as Map)['over'] as num).toInt() * 100,
              percent: (d['percent'] as num).toInt(),
            ),
        ],
        freeTravelFromMinor: (terms['freeTravelFrom'] as num).toInt() * 100,
      ).toMap(),
    );
    await batch.commit();
  }
}
