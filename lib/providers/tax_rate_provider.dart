import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/tax_rate_model.dart';

/// Manages the per-category sales tax rates (`/api/TaxRate`). Checkout is
/// priced IVA-exclusive: the POS preview and the backend both add these
/// rates on top of the posted price, so editing a rate here changes new
/// checkouts immediately.
class TaxRateProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<TaxRateModel> _taxRates = [];
  bool _isLoading = false;
  String? _error;

  DateTime _lastFetched = DateTime.fromMillisecondsSinceEpoch(0);
  /// True when no data or the last successful fetch is older than 60s —
  /// HomeScreen refetches on navigation only when this is true.
  bool get isStale =>
      DateTime.now().difference(_lastFetched) > const Duration(seconds: 60);

  List<TaxRateModel> get taxRates => _taxRates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<TaxRateModel> get activeRates =>
      _taxRates.where((r) => r.isActive).toList();

  /// The fallback rate (CategoryId == null) used for products with no
  /// category, when it is active.
  TaxRateModel? get defaultRate =>
      activeRates.isEmpty ? null : activeRates.firstWhere(
        (r) => r.categoryId == null,
        orElse: () => activeRates.first,
      );

  Future<void> fetchTaxRates() async {
    _isLoading = _taxRates.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/TaxRate');
      _taxRates = (response as List)
          .map((json) => TaxRateModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      _lastFetched = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTaxRate(TaxRateModel rate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/TaxRate', body: _payload(rate));
      if (response is Map<String, dynamic>) {
        _taxRates.add(TaxRateModel.fromJson(response));
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchTaxRates();
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

  Future<bool> updateTaxRate(TaxRateModel rate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.put('/TaxRate/${rate.id}', body: _payload(rate));
      if (response is Map<String, dynamic>) {
        final index = _taxRates.indexWhere((r) => r.id == rate.id);
        if (index != -1) _taxRates[index] = TaxRateModel.fromJson(response);
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchTaxRates();
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

  Future<bool> deleteTaxRate(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/TaxRate/$id');
      _taxRates.removeWhere((r) => r.id == id);
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

  Map<String, dynamic> _payload(TaxRateModel rate) => rate.toJson();
}