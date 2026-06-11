import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/purchase_order_header_model.dart';
import 'package:p_a_jewerly/models/purchase_order_detail_model.dart';

class PurchaseOrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<PurchaseOrderHeaderModel> _orders = [];
  List<PurchaseOrderDetailModel> _orderDetails = [];
  bool _isLoading = false;
  String? _error;

  List<PurchaseOrderHeaderModel> get orders => _orders;
  List<PurchaseOrderDetailModel> get orderDetails => _orderDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/PurchaseOrderHeader');
      _orders = (response as List)
          .map((json) => PurchaseOrderHeaderModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrderDetails(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/PurchaseOrderDetail');
      final allDetails = (response as List)
          .map((json) => PurchaseOrderDetailModel.fromJson(json))
          .toList();
      _orderDetails = allDetails.where((d) => d.purchaseOrderId == orderId).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PurchaseOrderHeaderModel?> createOrder(PurchaseOrderHeaderModel order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/PurchaseOrderHeader', body: order.toJson());
      if (response != null) {
        final newOrder = PurchaseOrderHeaderModel.fromJson(response);
        _orders.add(newOrder);
        _isLoading = false;
        notifyListeners();
        return newOrder;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> updateOrder(PurchaseOrderHeaderModel order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/PurchaseOrderHeader/${order.id}', body: order.toJson());
      if (response != null) {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = PurchaseOrderHeaderModel.fromJson(response);
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

  Future<bool> deleteOrder(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/PurchaseOrderHeader/$id');
      _orders.removeWhere((o) => o.id == id);
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

  Future<bool> addOrderDetail(PurchaseOrderDetailModel detail) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/PurchaseOrderDetail', body: detail.toJson());
      if (response != null) {
        _orderDetails.add(PurchaseOrderDetailModel.fromJson(response));
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

  Future<bool> updateOrderDetail(PurchaseOrderDetailModel detail) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/PurchaseOrderDetail/${detail.id}', body: detail.toJson());
      if (response != null) {
        final index = _orderDetails.indexWhere((d) => d.id == detail.id);
        if (index != -1) {
          _orderDetails[index] = PurchaseOrderDetailModel.fromJson(response);
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

  Future<bool> deleteOrderDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/PurchaseOrderDetail/$id');
      _orderDetails.removeWhere((d) => d.id == id);
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

  /// Get order details for a specific order
  List<PurchaseOrderDetailModel> getDetailsForOrder(int orderId) {
    return _orderDetails.where((d) => d.purchaseOrderId == orderId).toList();
  }

  /// Calculate total for an order from its details
  double calculateOrderTotal(List<PurchaseOrderDetailModel> details) {
    return details.fold(0.0, (sum, d) => sum + (d.total ?? 0));
  }

  /// Complete a purchase order - updates status, creates inventory movements and updates inventory
  Future<bool> completePurchaseOrder(int orderId, {
    required int warehouseId,
    DateTime? receptionDate,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/PurchaseOrderHeader/$orderId/Complete', body: {
        'warehouseId': warehouseId,
        'receptionDate': receptionDate?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
        'notes': notes ?? '',
      });

      if (response != null) {
        // Refresh orders to get updated status
        await fetchOrders();
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