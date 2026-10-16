import 'package:flutter_test/flutter_test.dart';
import 'package:p_a_jewerly/models/product_category_model.dart';
import 'package:p_a_jewerly/models/tax_rate_model.dart';
import 'package:p_a_jewerly/providers/sales_provider.dart';
import 'package:p_a_jewerly/utils/sales_tax.dart';

void main() {
  group('computeCartTax (mirrors backend CompleteSale rounding)', () {
    final rates = [
      TaxRateModel(
          id: 1, categoryId: null, name: 'IVA 16%', rate: 0.16, isActive: true),
      TaxRateModel(
          id: 2, categoryId: 1, name: 'IVA 0%', rate: 0.0, isActive: true),
      TaxRateModel(
          id: 3,
          categoryId: 2,
          name: 'Old 8%',
          rate: 0.08,
          isActive: false), // inactive: ignored
    ];
    final links = [
      ProductCategoryModel(id: 1, categoryId: 1, productId: 1),
      ProductCategoryModel(id: 2, categoryId: 2, productId: 2),
    ];

    CartItem item(int productId) => CartItem(
          productId: productId,
          productName: 'p$productId',
          quantity: 1,
          unitPrice: 100.50,
        );

    test('categorized product picks its category rate over the default',
        () async {
      // Product 1 -> category 1 -> IVA 0%.
      final tax =
          computeCartTax([item(1)], rates.where((r) => r.id != 1).toList(), links);
      expect(tax.taxTotal, 0.0);
      expect(tax.taxesByType, isEmpty);
    });

    test('uncategorized product falls back to the null-category rate',
        () {
      final tax = computeCartTax([item(9)], rates, links);
      // 100.50 * 0.16 = 16.08, rounded per line.
      expect(tax.subtotal, 100.50);
      expect(tax.taxTotal, 16.08);
      expect(tax.taxesByType.keys, ['IVA 16%']);
      expect(tax.total, 116.58);
    });

    test('two lines round per line, then sum (backend parity)', () {
      // Backend reference values from the dev-API test sale:
      // 2 x 100.50 -> 201.00 base, 32.16 tax; 1 x 50.00 -> 8.00 tax.
      final cart = [
        CartItem(productId: 9, productName: 'a', quantity: 2, unitPrice: 100.50),
        CartItem(productId: 9, productName: 'b', quantity: 1, unitPrice: 50.00),
      ];
      final tax = computeCartTax(cart, rates, links);
      expect(tax.subtotal, 251.00);
      expect(tax.taxTotal, 40.16);
      expect(tax.total, 291.16);
    });

    test('tax accumulates per rate name across lines', () {
      final cart = [
        CartItem(productId: 9, productName: 'a', quantity: 1, unitPrice: 33.33),
        CartItem(productId: 9, productName: 'b', quantity: 1, unitPrice: 33.33),
      ];
      final tax = computeCartTax(cart, rates, links);
      // 5.3328 and 5.3328 rounded per line to 5.33 each -> 10.66.
      expect(tax.taxesByType['IVA 16%'], 10.66);
    });

    test('no active rate means no tax at all', () {
      final tax = computeCartTax([item(9)], [], links);
      expect(tax.taxTotal, 0.0);
      expect(tax.total, 100.50);
    });
  });
}