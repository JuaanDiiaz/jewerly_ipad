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

  DateTime _lastFetched = DateTime.fromMillisecondsSinceEpoch(0);
  /// True when no data or the last successful fetch is older than 60s —
  /// HomeScreen refetches on navigation only when this is true.
  bool get isStale =>
      DateTime.now().difference(_lastFetched) > const Duration(seconds: 60);

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
    _isLoading = _inventory.isEmpty;
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
      _lastFetched = DateTime.now();
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
      _isLoading = _movements.isEmpty;
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
        // Only a plain call refreshes the whole movements list — an
        // item/date-filtered call is a lookup, not a collection refresh.
        if (itemId == null && fromDate == null && toDate == null) {
          _lastFetched = DateTime.now();
        }
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

  // Note: stock changes go through /Inventory/UpdateQuantity (server-applied
  // delta with a below-zero guard) or /InventoryMovement — never a client-
  // computed absolute quantity. The old updateInventoryCount/decrementQuantity
  // helpers (unused) posted client math and, worse, a partial PUT body that
  // the server's blind overwrite would use to blank the other columns.
}
