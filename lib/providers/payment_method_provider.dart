import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/payment_method_model.dart';

class PaymentMethodProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<PaymentMethodModel> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;

  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPaymentMethods() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/PaymentMethod');
      _paymentMethods = (response as List)
          .map((json) => PaymentMethodModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPaymentMethod(String description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/PaymentMethod', body: {'description': description});
      if (response != null) {
        _paymentMethods.add(PaymentMethodModel.fromJson(response));
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

  Future<bool> updatePaymentMethod(int id, String description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/PaymentMethod/$id', body: {'id': id, 'description': description});
      if (response != null) {
        final index = _paymentMethods.indexWhere((p) => p.id == id);
        if (index != -1) {
          _paymentMethods[index] = PaymentMethodModel.fromJson(response);
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

  Future<bool> deletePaymentMethod(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/PaymentMethod/$id');
      _paymentMethods.removeWhere((p) => p.id == id);
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

  /// Ensures a "Multiple Payments" payment method exists.
  /// Returns the ID of the existing or newly created method.
  Future<int?> ensureMultiplePaymentsMethod() async {
    // Check if it already exists
    final existing = _paymentMethods.where((m) {
      final desc = m.description?.toLowerCase() ?? '';
      return desc.contains('multiple') || desc.contains('varias') || desc.contains('parcial');
    }).toList();

    if (existing.isNotEmpty) {
      return existing.first.id;
    }

    // Create it
    try {
      final response = await _apiService.post('/PaymentMethod', body: {
        'description': 'Multiple Payments',
      });
      if (response != null) {
        final newMethod = PaymentMethodModel.fromJson(response);
        _paymentMethods.add(newMethod);
        notifyListeners();
        return newMethod.id;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating Multiple Payments method: $e');
    }
    return null;
  }

  /// Find a payment method by description (case-insensitive partial match)
  PaymentMethodModel? findByDescription(String searchTerm) {
    final lowerSearch = searchTerm.toLowerCase();
    try {
      return _paymentMethods.firstWhere((m) =>
        (m.description?.toLowerCase() ?? '').contains(lowerSearch)
      );
    } catch (_) {
      return null;
    }
  }
}
