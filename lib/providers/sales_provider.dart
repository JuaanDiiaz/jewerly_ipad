import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/sales_order_header_model.dart';

class CartItem {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;
  final int maxQuantity; // Available inventory quantity

  CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
    this.maxQuantity = 0,
  });

  double get total => quantity * unitPrice;
}

class SalesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<SalesOrderHeaderModel> _sales = [];
  final List<CartItem> _cart = [];
  int? _selectedCustomerId;
  String? _salespersonName;
  int? _paymentMethodId;
  int? _selectedWarehouseId;
  bool _isLoading = false;
  String? _error;

  // Pagination state for the sales history list
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  List<SalesOrderHeaderModel> get sales => _sales;
  List<CartItem> get cart => _cart;
  int? get selectedCustomerId => _selectedCustomerId;
  String? get salespersonName => _salespersonName;
  int? get paymentMethodId => _paymentMethodId;
  int? get selectedWarehouseId => _selectedWarehouseId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  void setWarehouse(int? warehouseId) {
    _selectedWarehouseId = warehouseId;
    notifyListeners();
  }

  void addToCart(CartItem item) {
    final existingIndex = _cart.indexWhere((i) => i.productId == item.productId);
    if (existingIndex != -1) {
      final existing = _cart[existingIndex];
      _cart[existingIndex] = CartItem(
        productId: item.productId,
        productName: item.productName,
        quantity: existing.quantity + item.quantity,
        unitPrice: item.unitPrice != 0 ? item.unitPrice : existing.unitPrice,
        imageUrl: item.imageUrl,
        maxQuantity: item.maxQuantity > 0 ? item.maxQuantity : existing.maxQuantity,
      );
    } else {
      _cart.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void updateCartItemQuantity(int productId, int quantity) {
    final index = _cart.indexWhere((i) => i.productId == productId);
    if (index != -1) {
      final item = _cart[index];
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        // Enforce max quantity limit
        final limitedQuantity = quantity > item.maxQuantity ? item.maxQuantity : quantity;
        _cart[index] = CartItem(
          productId: item.productId,
          productName: item.productName,
          quantity: limitedQuantity,
          unitPrice: item.unitPrice,
          imageUrl: item.imageUrl,
          maxQuantity: item.maxQuantity,
        );
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _selectedCustomerId = null;
    _salespersonName = null;
    _paymentMethodId = null;
    notifyListeners();
  }

  void setCustomer(int? customerId) {
    _selectedCustomerId = customerId;
    notifyListeners();
  }

  void setSalesperson(String? name) {
    _salespersonName = name;
    notifyListeners();
  }

  void setPaymentMethodId(int? methodId) {
    _paymentMethodId = methodId;
    notifyListeners();
  }

  /// [loadMore] appends the next page to [sales]; a plain call resets the
  /// list to page 1. [fetchAll] walks every page in one call — only for
  /// screens that need the complete history (payment status lists).
  Future<void> fetchSales({
    DateTime? fromDate,
    DateTime? toDate,
    bool loadMore = false,
    bool fetchAll = false,
  }) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
      _error = null;
      notifyListeners();
    } else {
      _isLoading = true;
      _error = null;
      _page = 1;
      notifyListeners();
    }

    final keepGoing = fetchAll && !loadMore;
    try {
      var targetPage = loadMore ? _page + 1 : 1;
      final fetched = <SalesOrderHeaderModel>[];
      var totalCount = 0;
      var lastPageSize = 50;
      do {
        final envelope = await _apiService.getPaged('/SalesOrderHeader', params: {
          'page': '$targetPage',
          if (fromDate != null) 'from_date': fromDate.toIso8601String(),
          if (toDate != null) 'to_date': toDate.toIso8601String(),
        });
        fetched.addAll(envelope.data
            .whereType<Map>()
            .map((json) =>
                SalesOrderHeaderModel.fromJson(Map<String, dynamic>.from(json)))
            .toList());
        totalCount = envelope.totalCount;
        lastPageSize = envelope.pageSize > 0 ? envelope.pageSize : 50;
        targetPage++;
      } while (keepGoing &&
          (targetPage - 1) * lastPageSize < totalCount &&
          targetPage <= 25);

      final page = targetPage - 1;
      if (loadMore) {
        _sales.addAll(fetched);
      } else {
        _sales = fetched;
      }
      _page = page;
      _hasMore = !keepGoing && page * lastPageSize < totalCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> checkout() async {
    if (_cart.isEmpty || _selectedCustomerId == null) {
      return false;
    }

    if (_isLoading) {
      // A checkout network call is already in flight — the button's own
      // guard should make this unreachable, but a double POST here would
      // duplicate the sale and double-decrement stock, so refuse it.
      return false;
    }

    if (_selectedWarehouseId == null) {
      _error = 'Please select a warehouse before checkout';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/SalesOrderHeader/CompleteSale', body: {
        'customerId': _selectedCustomerId,
        'paymentMethodId': _paymentMethodId,
        'salespersonName': _salespersonName ?? '',
        'warehouseId': _selectedWarehouseId,
        'saleDate': DateTime.now().toIso8601String().split('T')[0],
        'items': _cart.map((item) => {
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
        }).toList(),
      });

      if (response == null) {
        _error = 'No response from server';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      clearCart();
      await fetchSales();
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
}
