import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Customer');
      _customers = (response as List)
          .map((json) => CustomerModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCustomer(Map<String, dynamic> customerData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Backend expects PascalCase field names
      final backendData = {
        'name': customerData['name'],
        'email': customerData['email'],
        'phone': customerData['phone'],
        'address': customerData['address'] ?? '',
        'city': customerData['city'] ?? '',
        'postalCode': customerData['postalCode'] ?? '',
        'country': customerData['country'] ?? '',
      };
      final response = await _apiService.post('/Customer', body: backendData);
      if (response != null) {
        _customers.add(CustomerModel.fromJson(response));
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

  Future<bool> updateCustomer(int id, Map<String, dynamic> customerData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/Customer/$id', body: customerData);
      if (response != null) {
        final index = _customers.indexWhere((c) => c.id == id);
        if (index != -1) {
          _customers[index] = CustomerModel.fromJson(response);
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

  Future<bool> deleteCustomer(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/Customer/$id');
      _customers.removeWhere((c) => c.id == id);
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
