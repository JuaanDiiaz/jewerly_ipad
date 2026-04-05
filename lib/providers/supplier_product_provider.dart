import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/supplier_product_model.dart';

class SupplierProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<SupplierProductModel> _supplierProducts = [];
  bool _isLoading = false;
  String? _error;

  List<SupplierProductModel> get supplierProducts => _supplierProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSupplierProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/SupplierProduct');
      _supplierProducts = (response as List)
          .map((json) => SupplierProductModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSupplierProduct(SupplierProductModel product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/SupplierProduct', body: product.toJson());
      if (response != null) {
        _supplierProducts.add(SupplierProductModel.fromJson(response));
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

  Future<bool> updateSupplierProduct(SupplierProductModel product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/SupplierProduct/${product.id}', body: product.toJson());
      if (response != null) {
        final index = _supplierProducts.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _supplierProducts[index] = SupplierProductModel.fromJson(response);
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

  Future<bool> deleteSupplierProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/SupplierProduct/$id');
      _supplierProducts.removeWhere((p) => p.id == id);
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
