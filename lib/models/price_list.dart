import 'package:cloud_firestore/cloud_firestore.dart';

/// A section of the price list, such as "Dušeci", in `priceCategories/{id}`.
/// Archived instead of deleted, so old jobs never point at nothing.
class PriceCategory {
  const PriceCategory({
    required this.id,
    required this.name,
    this.note = '',
    this.order = 0,
    this.archived = false,
  });

  final String id;
  final String name;

  /// What is included, or which cars count as which size.
  final String note;
  final int order;
  final bool archived;

  factory PriceCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return PriceCategory(
      id: doc.id,
      name: d['name'] as String? ?? '',
      note: d['note'] as String? ?? '',
      order: (d['order'] as num?)?.toInt() ?? 0,
      archived: d['archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'note': note,
    'order': order,
    'archived': archived,
  };
}

/// One priced service in a category, in `priceItems/{id}`.
class PriceItem {
  const PriceItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.priceMinor,
    this.order = 0,
    this.archived = false,
  });

  final String id;
  final String categoryId;
  final String name;
  final int priceMinor;
  final int order;

  /// Hidden from new jobs; jobs that have it keep their copy.
  final bool archived;

  factory PriceItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return PriceItem(
      id: doc.id,
      categoryId: d['categoryId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      priceMinor: (d['priceMinor'] as num?)?.toInt() ?? 0,
      order: (d['order'] as num?)?.toInt() ?? 0,
      archived: d['archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'name': name,
    'priceMinor': priceMinor,
    'order': order,
    'archived': archived,
  };
}

/// A discount for orders strictly above [overMinor] ("iznad 6.000").
class Discount {
  const Discount({required this.overMinor, required this.percent});

  final int overMinor;
  final int percent;

  Map<String, dynamic> toMap() => {'overMinor': overMinor, 'percent': percent};
}

/// The terms under the price list, in `meta/pricing`.
class PricingRules {
  const PricingRules({
    this.discounts = defaultDiscounts,
    this.freeTravelFromMinor = 250000,
    this.travelMinor = 0,
  });

  /// The crew's terms when the list was first set up (2026-11-15).
  static const defaultDiscounts = [
    Discount(overMinor: 600000, percent: 10),
    Discount(overMinor: 1000000, percent: 15),
  ];

  final List<Discount> discounts;

  /// Coming to the client is free from this order value on.
  final int freeTravelFromMinor;

  /// What coming to the client costs below that; 0 = always free.
  final int travelMinor;

  factory PricingRules.fromMap(Map<String, dynamic>? d) {
    if (d == null) return const PricingRules();
    final raw = d['discounts'];
    return PricingRules(
      discounts: raw is List
          ? [
              for (final x in raw)
                if (x is Map)
                  Discount(
                    overMinor: (x['overMinor'] as num?)?.toInt() ?? 0,
                    percent: (x['percent'] as num?)?.toInt() ?? 0,
                  ),
            ]
          : defaultDiscounts,
      freeTravelFromMinor:
          (d['freeTravelFromMinor'] as num?)?.toInt() ?? 250000,
      travelMinor: (d['travelMinor'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'discounts': [for (final x in discounts) x.toMap()],
    'freeTravelFromMinor': freeTravelFromMinor,
    'travelMinor': travelMinor,
  };
}
