import 'package:intl/intl.dart';

/// Formats a numeric value as currency. Accepts dynamic (API values can be
/// num, string, or null) so call sites don't need their own parse guards.
String formatCurrency(dynamic value, {String symbol = r'$', int decimalDigits = 2}) {
  final amount = value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
  return NumberFormat.currency(symbol: symbol, decimalDigits: decimalDigits)
      .format(amount ?? 0);
}