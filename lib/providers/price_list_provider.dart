import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/price_list_model.dart';

class PriceListProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<PriceListModel> _priceLists = [];
  bool _isLoading = false;
  String? _error;

  List<PriceListModel> get priceLists => _priceLists;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPriceLists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/PriceList');
      _priceLists = (response as List)
          .map((json) => PriceListModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
