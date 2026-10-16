import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/price_list_model.dart';

class PriceListProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<PriceListModel> _priceLists = [];
  bool _isLoading = false;
  String? _error;

  DateTime _lastFetched = DateTime.fromMillisecondsSinceEpoch(0);
  /// True when no data or the last successful fetch is older than 60s —
  /// HomeScreen refetches on navigation only when this is true.
  bool get isStale =>
      DateTime.now().difference(_lastFetched) > const Duration(seconds: 60);

  List<PriceListModel> get priceLists => _priceLists;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPriceLists() async {
    _isLoading = _priceLists.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/PriceList');
      _priceLists = (response as List)
          .map((json) => PriceListModel.fromJson(json))
          .toList();
      // MySQL has no ORDER BY here — without a sort the segmented control and
      // the "first list" default flip between runs.
      _priceLists.sort((a, b) => a.id.compareTo(b.id));
      _lastFetched = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
