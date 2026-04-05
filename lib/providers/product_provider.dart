import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Product');
      _products = (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.get('/products/$id');
      // Handle single product response
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Backend expects: { id, description }
      final backendData = {
        'description': productData['description'] ?? productData['name'],
      };
      final response = await _apiService.post('/Product', body: backendData);
      if (response != null) {
        _products.add(ProductModel.fromJson(response));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/products/$id', body: productData);
      if (response != null) {
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          _products[index] = ProductModel.fromJson(response);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/products/$id');
      _products.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
