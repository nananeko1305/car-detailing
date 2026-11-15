import 'package:intl/intl.dart';

// Everything is in dinars, stored as an int in para (minor units), so sums
// never pick up rounding errors.

/// Formats an amount in para: 650000 -> "6.500 RSD", 150050 -> "1.500,50 RSD".
/// Decimals only when there are any; prices rarely have.
String formatMoney(int amountMinor, String locale, {bool unit = true}) {
  final whole = amountMinor % 100 == 0;
  final number = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: whole ? 0 : 2,
  ).format(amountMinor / 100);
  return unit ? '$number RSD' : number;
}

/// Parses user input such as "1.500", "1500,5" or "12 345" into para.
/// Returns null when the input is not a positive amount.
int? parseMoney(String input) {
  var s = input
      .trim()
      .replaceAll(' ', '')
      .replaceAll(RegExp('rsd|din', caseSensitive: false), '');
  if (s.isEmpty) return null;
  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    // Both present: whichever comes last is the decimal separator.
    final decimal = lastComma > lastDot ? ',' : '.';
    final group = decimal == ',' ? '.' : ',';
    s = s.replaceAll(group, '').replaceAll(decimal, '.');
  } else if (lastComma >= 0 || lastDot >= 0) {
    final sep = lastComma >= 0 ? ',' : '.';
    final parts = s.split(sep);
    // "1.500" or "1.250.000" group thousands; "1500,5" is a decimal.
    final grouping =
        parts.length > 2 || (parts.last.length == 3 && parts.first.isNotEmpty);
    s = grouping ? parts.join() : parts.join('.');
  }
  final value = double.tryParse(s);
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}

/// Like [parseMoney], but an empty field or "0" is zero instead of invalid.
int? parseMoneyOrZero(String input) {
  final s = input.trim();
  if (s.isEmpty || RegExp(r'^0+([.,]0*)?$').hasMatch(s)) return 0;
  return parseMoney(s);
}

/// Para back to an editable string, e.g. 150050 -> "1500.50".
String moneyToInput(int amountMinor) {
  final whole = amountMinor ~/ 100;
  final fraction = amountMinor % 100;
  return fraction == 0
      ? '$whole'
      : '$whole.${fraction.toString().padLeft(2, '0')}';
}
