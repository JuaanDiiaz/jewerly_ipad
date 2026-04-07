import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/product_category_model.dart';

class ProductCategoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ProductCategoryModel> _productCategories = [];
  bool _isLoading = false;
  String? _error;

  List<ProductCategoryModel> get productCategories => _productCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProductCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/ProductCategory');
      _productCategories = (response as List)
          .map((json) => ProductCategoryModel.fromJson(json))
          .toList();
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
}