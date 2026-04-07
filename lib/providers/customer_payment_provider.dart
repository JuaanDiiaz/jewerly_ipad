import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/customer_payment_model.dart';

class CustomerPaymentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<CustomerPaymentModel> _payments = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerPaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/CustomerPayment');
      _payments = (response as List)
          .map((json) => CustomerPaymentModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get payments for a specific sales order
  List<CustomerPaymentModel> getPaymentsForSalesOrder(int salesOrderId) {
    return _payments.where((p) => p.salesOrderId == salesOrderId).toList();
  }

  /// Calculate total paid for a sales order
  double getTotalPaidForSalesOrder(int salesOrderId) {
    return getPaymentsForSalesOrder(salesOrderId)
        .fold(0.0, (sum, p) => sum + ((p.amount as num?)?.toDouble() ?? 0));
  }

  Future<bool> createPayment(CustomerPaymentModel payment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/CustomerPayment', body: payment.toJson());
      if (response != null) {
        _payments.add(CustomerPaymentModel.fromJson(response));
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

  Future<bool> deletePayment(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/CustomerPayment/$id');
      _payments.removeWhere((p) => p.id == id);
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
