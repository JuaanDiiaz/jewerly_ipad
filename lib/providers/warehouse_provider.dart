import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/warehouse_model.dart';

class WarehouseProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<WarehouseModel> _warehouses = [];
  bool _isLoading = false;
  String? _error;

  List<WarehouseModel> get warehouses => _warehouses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWarehouses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Warehouse');
      _warehouses = (response as List)
          .map((json) => WarehouseModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createWarehouse(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/Warehouse', body: {'name': name});
      if (response != null) {
        _warehouses.add(WarehouseModel.fromJson(response));
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

  Future<bool> updateWarehouse(int id, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/Warehouse/$id', body: {'id': id, 'name': name});
      if (response != null) {
        final index = _warehouses.indexWhere((w) => w.id == id);
        if (index != -1) {
          _warehouses[index] = WarehouseModel.fromJson(response);
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

  Future<bool> deleteWarehouse(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/Warehouse/$id');
      _warehouses.removeWhere((w) => w.id == id);
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
