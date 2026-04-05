import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/inventory_model.dart';
import 'package:p_a_jewerly/models/inventory_movement_model.dart';

class InventoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<InventoryModel> _inventory = [];
  List<InventoryMovementModel> _movements = [];
  bool _isLoading = false;
  String? _error;

  List<InventoryModel> get inventory => _inventory;
  List<InventoryMovementModel> get movements => _movements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchInventory({String? warehouseId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getWithParams(
        '/inventory',
        params: warehouseId != null ? {'warehouse_id': warehouseId} : null,
      );
      _inventory = (response as List)
          .map((json) => InventoryModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMovements({String? itemId, DateTime? fromDate, DateTime? toDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getWithParams(
        '/inventory/movements',
        params: {
          if (itemId != null) 'item_id': itemId,
          if (fromDate != null) 'from_date': fromDate.toIso8601String(),
          if (toDate != null) 'to_date': toDate.toIso8601String(),
        },
      );
      _movements = (response as List)
          .map((json) => InventoryMovementModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addInventoryItem(Map<String, dynamic> itemData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/inventory', body: itemData);
      if (response != null) {
        _inventory.add(InventoryModel.fromJson(response));
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

  Future<bool> updateInventoryCount(int id, int count) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '/inventory/$id/count',
        body: {'count': count},
      );
      if (response != null) {
        final index = _inventory.indexWhere((i) => i.id == id);
        if (index != -1) {
          _inventory[index] = InventoryModel.fromJson(response);
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
}
