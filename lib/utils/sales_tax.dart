import 'package:p_a_jewerly/models/product_category_model.dart';
import 'package:p_a_jewerly/models/tax_rate_model.dart';
import 'package:p_a_jewerly/providers/sales_provider.dart';

/// IVA-exclusive checkout math, shared by the POS preview (cart summary and
/// checkout button) wherever the sale total needs the tax split before the
/// backend sees the sale. The backend's CompleteSale is authoritative and
/// rounds line tax away from zero to 2 decimals — this helper mirrors that
/// exactly, so the preview matches what the server records.
class CartTaxBreakdown {
  final double subtotal;

  /// Tax charged per rate name, e.g. {'IVA 16%': 40.16}.
  final Map<String, double> taxesByType;

  CartTaxBreakdown._(this.subtotal, this.taxesByType);

  double get taxTotal => _round2(
      taxesByType.values.fold(0, (sum, tax) => sum + tax));

  double get total => _round2(subtotal + taxTotal);
}

/// Money rounding on the line, matching C#'s `Math.Round(value, 2,
/// AwayFromZero)` for the positive amounts a cart produces.
double _round2(double value) => (value * 100).round().toDouble() / 100;

/// Computes the tax for a cart of items. Each item's rate comes from its
/// product-category link; an item not linked to any category falls back to
/// the active rate whose categoryId is null (the default row). With no rate
/// at all, the item simply contributes no tax.
CartTaxBreakdown computeCartTax(
  List<CartItem> cart,
  List<TaxRateModel> rates,
  List<ProductCategoryModel> links,
) {
  final activeRates = rates.where((r) => r.isActive).toList();
  final defaultRate =
      activeRates.where((r) => r.categoryId == null).isEmpty
          ? null
          : activeRates.where((r) => r.categoryId == null).first;

  TaxRateModel? rateFor(int productId) {
    final categoryIds = links
        .where((link) => link.productId == productId)
        .map((link) => link.categoryId)
        .toSet();
    for (final categoryId in categoryIds) {
      for (final rate in activeRates) {
        if (rate.categoryId == categoryId) return rate;
      }
    }
    return defaultRate;
  }

  final taxesByType = <String, double>{};
  var subtotal = 0.0;

  for (final item in cart) {
    subtotal += item.total;
    final rate = rateFor(item.productId);
    if (rate == null || (rate.rate ?? 0) <= 0) continue;
    final lineTax = _round2(item.total * rate.rate!);
    if (lineTax <= 0) continue;
    final key = rate.name ?? 'Tax';
    taxesByType[key] = _round2((taxesByType[key] ?? 0) + lineTax);
  }

  return CartTaxBreakdown._(_round2(subtotal), taxesByType);
}