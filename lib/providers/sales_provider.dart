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

  List<SalesOrderHeaderModel> get sales => _sales;
  List<CartItem> get cart => _cart;
  int? get selectedCustomerId => _selectedCustomerId;
  String? get salespersonName => _salespersonName;
  int? get paymentMethodId => _paymentMethodId;
  int? get selectedWarehouseId => _selectedWarehouseId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  void setWarehouse(int? warehouseId) {
    _selectedWarehouseId = warehouseId;
    notifyListeners();
  }

  void addToCart(CartItem item) {
    final existingIndex = _cart.indexWhere((i) => i.productId == item.productId);
    if (existingIndex != -1) {
      _cart[existingIndex] = CartItem(
        productId: item.productId,
        productName: item.productName,
        quantity: _cart[existingIndex].quantity + item.quantity,
        unitPrice: item.unitPrice,
        imageUrl: item.imageUrl,
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

  Future<void> fetchSales({DateTime? fromDate, DateTime? toDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getWithParams(
        '/SalesOrderHeader',
        params: {
          if (fromDate != null) 'from_date': fromDate.toIso8601String(),
          if (toDate != null) 'to_date': toDate.toIso8601String(),
        },
      );
      _sales = (response as List)
          .map((json) => SalesOrderHeaderModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkout() async {
    if (_cart.isEmpty || _selectedCustomerId == null) {
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Backend expects SalesOrderHeader with Notes field for salesperson
      final orderData = {
        'customerId': _selectedCustomerId,
        'paymentMethodId': _paymentMethodId,
        'notes': _salespersonName ?? '',
        'saleDate': DateTime.now().toIso8601String().split('T')[0],
        'total': cartTotal,
      };

      final headerResponse = await _apiService.post('/SalesOrderHeader', body: orderData);

      if (headerResponse == null) {
        _error = 'No response from server';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final salesOrderId = headerResponse['id'];
      if (salesOrderId == null) {
        _error = 'Invalid response: missing id';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create sales order details for each cart item
      for (final item in _cart) {
        final detailData = {
          'salesOrderId': salesOrderId,
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'total': item.total,
        };
        await _apiService.post('/SalesOrderDetail', body: detailData);

        // Create inventory movement for the sale (OUT movement)
        final movementData = {
          'productId': item.productId,
          'warehouseId': _selectedWarehouseId ?? 1,
          'movementType': 'OUT',
          'quantity': item.quantity,
          'movementDate': DateTime.now().toIso8601String().split('T')[0],
          'salesOrderId': salesOrderId,
          'notes': 'Sale by $_salespersonName',
        };
        await _apiService.post('/InventoryMovement', body: movementData);
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
