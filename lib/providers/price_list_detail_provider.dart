import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/price_list_detail_model.dart';

class PriceListDetailProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<PriceListDetailModel> _priceListDetails = [];
  bool _isLoading = false;
  String? _error;

  DateTime _lastFetched = DateTime.fromMillisecondsSinceEpoch(0);
  /// True when no data or the last successful fetch is older than 60s —
  /// HomeScreen refetches on navigation only when this is true.
  bool get isStale =>
      DateTime.now().difference(_lastFetched) > const Duration(seconds: 60);

  List<PriceListDetailModel> get priceListDetails => _priceListDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPriceListDetails() async {
    _isLoading = _priceListDetails.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/PriceListDetail');
      _priceListDetails = (response as List)
          .map((json) => PriceListDetailModel.fromJson(json))
          .toList();
      _lastFetched = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPriceListDetail(PriceListDetailModel detail) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/PriceListDetail', body: detail.toJson());
      if (response is Map<String, dynamic>) {
        _priceListDetails.add(PriceListDetailModel.fromJson(response));
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchPriceListDetails();
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

  Future<bool> updatePriceListDetail(PriceListDetailModel detail) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/PriceListDetail/${detail.id}', body: detail.toJson());
      if (response is Map<String, dynamic>) {
        final index = _priceListDetails.indexWhere((d) => d.id == detail.id);
        if (index != -1) {
          _priceListDetails[index] = PriceListDetailModel.fromJson(response);
        }
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchPriceListDetails();
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

  Future<bool> deletePriceListDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/PriceListDetail/$id');
      _priceListDetails.removeWhere((d) => d.id == id);
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
