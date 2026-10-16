import 'package:flutter/material.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _error;

  // Pagination state for the customers list
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _searchQuery;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// [loadMore] appends the next page to [customers]; a plain call resets
  /// the list. [query] filters server-side and resets to page 1. [fetchAll]
  /// walks every page in one call — for screens that need the whole
  /// customer list (name lookups, selects), not for the paged list.
  Future<void> fetchCustomers({
    String? query,
    bool loadMore = false,
    bool fetchAll = false,
  }) async {
    if (!loadMore) {
      _searchQuery = (query != null && query.trim().isNotEmpty)
          ? query.trim()
          : null;
      _isLoading = true;
      _error = null;
      _page = 1;
      notifyListeners();
    } else {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
      _error = null;
      notifyListeners();
    }

    final keepGoing = fetchAll && !loadMore;
    try {
      var targetPage = loadMore ? _page + 1 : 1;
      final fetched = <CustomerModel>[];
      var totalCount = 0;
      var lastPageSize = 50;
      do {
        final envelope = await _apiService.getPaged('/Customer', params: {
          'page': '$targetPage',
          if (_searchQuery != null) 'q': _searchQuery!,
        });
        fetched.addAll(envelope.data
            .whereType<Map>()
            .map((json) =>
                CustomerModel.fromJson(Map<String, dynamic>.from(json)))
            .toList());
        totalCount = envelope.totalCount;
        lastPageSize = envelope.pageSize > 0 ? envelope.pageSize : 50;
        targetPage++;
      } while (keepGoing &&
          (targetPage - 1) * lastPageSize < totalCount &&
          targetPage <= 25);

      final page = targetPage - 1;
      if (loadMore) {
        _customers.addAll(fetched);
      } else {
        _customers = fetched;
      }
      _page = page;
      _hasMore = !keepGoing && page * lastPageSize < totalCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
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
      if (response is Map<String, dynamic>) {
        _customers.insert(0, CustomerModel.fromJson(response));
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchCustomers();
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

  Future<bool> updateCustomer(int id, Map<String, dynamic> customerData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/Customer/$id', body: customerData);
      if (response is Map<String, dynamic>) {
        final index = _customers.indexWhere((c) => c.id == id);
        if (index != -1) {
          _customers[index] = CustomerModel.fromJson(response);
        }
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchCustomers();
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
