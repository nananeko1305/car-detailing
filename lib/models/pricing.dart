import 'price_list.dart';

/// One line of a job: a price-list item copied when the job was booked, so a
/// later price change never rewrites what was agreed.
class JobItem {
  const JobItem({
    required this.itemId,
    required this.categoryId,
    required this.name,
    required this.priceMinor,
    this.qty = 1,
  });

  factory JobItem.of(PriceItem item, {int qty = 1}) => JobItem(
    itemId: item.id,
    categoryId: item.categoryId,
    name: item.name,
    priceMinor: item.priceMinor,
    qty: qty,
  );

  final String itemId;
  final String categoryId;
  final String name;
  final int priceMinor;
  final int qty;

  int get totalMinor => priceMinor * qty;

  JobItem withQty(int q) => JobItem(
    itemId: itemId,
    categoryId: categoryId,
    name: name,
    priceMinor: priceMinor,
    qty: q,
  );

  /// "Fotelja" or "Fotelja × 2".
  String get label => qty > 1 ? '$name × $qty' : name;

  factory JobItem.fromMap(Map<String, dynamic> d) => JobItem(
    itemId: d['itemId'] as String? ?? '',
    categoryId: d['categoryId'] as String? ?? '',
    name: d['name'] as String? ?? '',
    priceMinor: (d['priceMinor'] as num?)?.toInt() ?? 0,
    qty: (d['qty'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'categoryId': categoryId,
    'name': name,
    'priceMinor': priceMinor,
    'qty': qty,
  };
}

/// What a set of items comes to under the price list's terms.
class Quote {
  const Quote({
    required this.subtotalMinor,
    required this.discountPercent,
    required this.discountMinor,
    required this.travelMinor,
  });

  final int subtotalMinor;
  final int discountPercent;
  final int discountMinor;
  final int travelMinor;

  int get totalMinor => subtotalMinor - discountMinor + travelMinor;
}

/// Prices [items] the way the paper list says: the biggest discount whose
/// threshold the order is strictly above, rounded to whole dinars, and the
/// travel fee when the order is below the free-travel amount. With
/// [chargeTravel] off (the client comes to the crew) there is no fee.
Quote quote(
  List<JobItem> items,
  PricingRules rules, {
  bool chargeTravel = true,
}) {
  final subtotal = items.fold<int>(0, (total, i) => total + i.totalMinor);
  var percent = 0;
  for (final d in rules.discounts) {
    if (subtotal > d.overMinor && d.percent > percent) percent = d.percent;
  }
  percent = percent.clamp(0, 100);
  final discount = (subtotal * percent / 10000).round() * 100;
  final travel =
      chargeTravel &&
          subtotal > 0 &&
          subtotal < rules.freeTravelFromMinor &&
          rules.travelMinor > 0
      ? rules.travelMinor
      : 0;
  return Quote(
    subtotalMinor: subtotal,
    discountPercent: percent,
    discountMinor: discount,
    travelMinor: travel,
  );
}
