import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/sales_tax_detail_model.dart';

class SalesTaxProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<SalesTaxDetailModel> _salesTaxes = [];
  bool _isLoading = false;
  String? _error;

  List<SalesTaxDetailModel> get salesTaxes => _salesTaxes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSalesTaxes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/SalesTaxDetail');
      _salesTaxes = (response as List)
          .map((json) => SalesTaxDetailModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSalesTax(SalesTaxDetailModel tax) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/SalesTaxDetail', body: tax.toJson());
      if (response != null) {
        _salesTaxes.add(SalesTaxDetailModel.fromJson(response));
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

  Future<bool> updateSalesTax(SalesTaxDetailModel tax) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/SalesTaxDetail/${tax.id}', body: tax.toJson());
      if (response != null) {
        final index = _salesTaxes.indexWhere((t) => t.id == tax.id);
        if (index != -1) {
          _salesTaxes[index] = SalesTaxDetailModel.fromJson(response);
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

  Future<bool> deleteSalesTax(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/SalesTaxDetail/$id');
      _salesTaxes.removeWhere((t) => t.id == id);
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
