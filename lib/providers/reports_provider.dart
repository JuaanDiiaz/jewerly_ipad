import 'package:flutter/foundation.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';

/// Identifies the available reports; each maps to an /api/Reports/ endpoint.
enum ReportType {
  salesSummary,
  topProducts,
  categoryShare,
  stockLevels,
  customerBalances,
  purchasesBySupplier,
  taxTotals,
  salespersonPerformance,
}

/// Fetches /api/Reports/* aggregates. Rows are generic maps (the server
/// serialized DTOs are flat), so the Reports screen can render any report
/// from a column descriptor.
class ReportsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = false;
  String? _error;
  ReportType _currentType = ReportType.salesSummary;

  List<Map<String, dynamic>> get rows => _rows;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ReportType get currentType => _currentType;

  /// [params] holds the endpoint's query parameters (from_date, to_date,
  /// warehouse_id, below_quantity, group_by, limit, only_with_balance...).
  Future<void> fetchReport(
    ReportType type, {
    Map<String, String> params = const {},
  }) async {
    _isLoading = true;
    _error = null;
    _currentType = type;
    notifyListeners();

    try {
      final path = _endpointFor(type);
      final response =
          await _apiService.getWithParams(path, params: params);
      if (response is List) {
        _rows = response
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      } else {
        _rows = [];
      }
    } catch (e) {
      _error = e.toString();
      _rows = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _endpointFor(ReportType type) {
    switch (type) {
      case ReportType.salesSummary:
        return '/Reports/SalesSummary';
      case ReportType.topProducts:
        return '/Reports/TopProducts';
      case ReportType.categoryShare:
        return '/Reports/CategoryShare';
      case ReportType.stockLevels:
        return '/Reports/StockLevels';
      case ReportType.customerBalances:
        return '/Reports/CustomerBalances';
      case ReportType.purchasesBySupplier:
        return '/Reports/PurchasesBySupplier';
      case ReportType.taxTotals:
        return '/Reports/TaxTotals';
      case ReportType.salespersonPerformance:
        return '/Reports/SalespersonPerformance';
    }
  }
}