import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/product_category_model.dart';

class ProductCategoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ProductCategoryModel> _productCategories = [];
  bool _isLoading = false;
  String? _error;

  DateTime _lastFetched = DateTime.fromMillisecondsSinceEpoch(0);
  /// True when no data or the last successful fetch is older than 60s —
  /// HomeScreen refetches on navigation only when this is true.
  bool get isStale =>
      DateTime.now().difference(_lastFetched) > const Duration(seconds: 60);

  List<ProductCategoryModel> get productCategories => _productCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProductCategories() async {
    _isLoading = _productCategories.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/ProductCategory');
      _productCategories = (response as List)
          .map((json) => ProductCategoryModel.fromJson(json))
          .toList();
      _lastFetched = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get product IDs for a specific category
  List<int> getProductIdsByCategory(int categoryId) {
    return _productCategories
        .where((pc) => pc.categoryId == categoryId)
        .map((pc) => pc.productId)
        .toList();
  }

  /// Get category IDs for a specific product
  List<int> getCategoryIdsByProduct(int productId) {
    return _productCategories
        .where((pc) => pc.productId == productId)
        .map((pc) => pc.categoryId)
        .toList();
  }

  /// First category link (row id) for a product, if any — used by the product
  /// dialog to load and replace the primary category assignment.
  ProductCategoryModel? linkForProduct(int productId) {
    for (final link in _productCategories) {
      if (link.productId == productId) return link;
    }
    return null;
  }

  /// Sets (or replaces) the product's primary category. Products carry their
  /// category through this join link, which drives per-category tax rates
  /// and the category-share report.
  Future<bool> upsertProductCategory(int productId, int categoryId) async {
    final existing = linkForProduct(productId);
    try {
      if (existing?.categoryId == categoryId) return true;
      if (existing != null) {
        final updated = ProductCategoryModel(
          id: existing.id,
          categoryId: categoryId,
          productId: productId,
        );
        final response = await _apiService
            .put('/ProductCategory/${existing.id}', body: updated.toJson());
        if (response is Map<String, dynamic>) {
          final index =
              _productCategories.indexWhere((pc) => pc.id == existing.id);
          if (index != -1) {
            _productCategories[index] =
                ProductCategoryModel.fromJson(response);
          }
        } else {
          await fetchProductCategories();
        }
      } else {
        final response = await _apiService.post('/ProductCategory',
            body: ProductCategoryModel(
                    id: 0, categoryId: categoryId, productId: productId)
                .toJson());
        if (response is Map<String, dynamic>) {
          _productCategories.add(ProductCategoryModel.fromJson(response));
        } else {
          await fetchProductCategories();
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}