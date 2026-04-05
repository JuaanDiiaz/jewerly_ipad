import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/sales_order_header_model.dart';

class CartItem {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;

  CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
  });

  double get total => quantity * unitPrice;
}

class SalesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<SalesOrderHeaderModel> _sales = [];
  final List<CartItem> _cart = [];
  int? _selectedCustomerId;
  String? _salespersonName;
  String? _paymentMethod;
  bool _isLoading = false;
  String? _error;

  List<SalesOrderHeaderModel> get sales => _sales;
  List<CartItem> get cart => _cart;
  int? get selectedCustomerId => _selectedCustomerId;
  String? get salespersonName => _salespersonName;
  String? get paymentMethod => _paymentMethod;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

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
        _cart[index] = CartItem(
          productId: item.productId,
          productName: item.productName,
          quantity: quantity,
          unitPrice: item.unitPrice,
          imageUrl: item.imageUrl,
        );
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _selectedCustomerId = null;
    _salespersonName = null;
    _paymentMethod = null;
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

  void setPaymentMethod(String? method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<void> fetchSales({DateTime? fromDate, DateTime? toDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getWithParams(
        '/sales',
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
        'paymentMethodId': _paymentMethod == 'Cash' ? 1 : (_paymentMethod == 'Credit Card' ? 2 : 3),
        'notes': _salespersonName ?? '',
        'saleDate': DateTime.now().toIso8601String(),
        'total': cartTotal,
      };

      final headerResponse = await _apiService.post('/SalesOrderHeader', body: orderData);

      if (headerResponse != null) {
        final salesOrderId = headerResponse['id'];

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
        }

        clearCart();
        await fetchSales();
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
