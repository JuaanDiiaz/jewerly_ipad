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

  // Pagination state for the movements list
  int _movementPage = 1;
  bool _movementsHasMore = true;
  bool _isLoadingMoreMovements = false;

  List<InventoryModel> get inventory => _inventory;
  List<InventoryMovementModel> get movements => _movements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get movementsHasMore => _movementsHasMore;
  bool get isLoadingMoreMovements => _isLoadingMoreMovements;

  Future<void> fetchInventory({String? warehouseId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getWithParams(
        '/Inventory',
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

  /// [loadMore] appends the next page to [movements]; a plain call resets
  /// the list to page 1.
  Future<void> fetchMovements({
    String? itemId,
    DateTime? fromDate,
    DateTime? toDate,
    bool loadMore = false,
  }) async {
    if (loadMore) {
      if (_isLoadingMoreMovements || !_movementsHasMore) return;
      _isLoadingMoreMovements = true;
      _error = null;
      notifyListeners();
    } else {
      _isLoading = true;
      _error = null;
      _movementPage = 1;
      notifyListeners();
    }

    final targetPage = loadMore ? _movementPage + 1 : 1;

    try {
      final envelope = await _apiService.getPaged('/InventoryMovement', params: {
        'page': '$targetPage',
        if (itemId != null) 'item_id': itemId,
        if (fromDate != null) 'from_date': fromDate.toIso8601String(),
        if (toDate != null) 'to_date': toDate.toIso8601String(),
      });
      final fetched = envelope.data
          .whereType<Map>()
          .map((json) => InventoryMovementModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      if (loadMore) {
        _movements.addAll(fetched);
        _movementPage = targetPage;
      } else {
        _movements = fetched;
      }
      _movementsHasMore = envelope.hasMore;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMoreMovements = false;
      notifyListeners();
    }
  }

  Future<bool> addInventoryItem(Map<String, dynamic> itemData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/Inventory', body: itemData);
      if (response is Map<String, dynamic>) {
        _inventory.add(InventoryModel.fromJson(response));
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchInventory();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Updates an existing inventory row (PUT /Inventory/{id}).
  Future<bool> updateInventoryItem(int id, Map<String, dynamic> itemData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.put(
        '/Inventory/$id',
        body: {'id': id, ...itemData},
      );
      // Refresh so the row reflects whatever the server stored
      await fetchInventory();
      return true;
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
        '/Inventory/$id',
        body: {'quantity': count},
      );
      if (response is Map<String, dynamic>) {
        final index = _inventory.indexWhere((i) => i.id == id);
        if (index != -1) {
          _inventory[index] = InventoryModel.fromJson(response);
        }
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchInventory();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> decrementQuantity(int productId, int warehouseId, int amount) async {
    // Find inventory by product and warehouse
    try {
      final inv = _inventory.firstWhere(
        (i) => i.productId == productId && i.warehouseId == warehouseId,
      );
      final newQuantity = (inv.quantity ?? 0) - amount;
      return updateInventoryCount(inv.id, newQuantity < 0 ? 0 : newQuantity);
    } catch (_) {
      return false;
    }
  }
}
