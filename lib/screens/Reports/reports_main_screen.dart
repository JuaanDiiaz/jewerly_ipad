import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/providers.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/utils/format.dart';
import 'package:p_a_jewerly/widgets/base_screen.dart';
import 'report_visuals.dart';

enum _ColKind { text, number, money }

enum _ChartKind { line, rankedBar, donut }

class _ReportColumn {
  final String label;
  final String key;
  final _ColKind kind;
  const _ReportColumn(this.label, this.key, {this.kind = _ColKind.text});
}

class _ReportSpec {
  final String title;
  final IconData icon;
  final ReportType type;
  final List<_ReportColumn> columns;
  final bool hasDateRange;
  final bool hasGroupBy;
  final bool hasWarehouse;
  final bool hasBelowQuantity;
  final bool hasOnlyWithBalance;
  // Dashboard visuals
  final _ChartKind? chartKind;
  final String? chartValueKey;
  final String? chartLabelKey;
  final bool hasLimit;
  final bool showFooter;
  final String? percentOfKey;
  final String? sortKey;
  final bool sortAsc;
  const _ReportSpec({
    required this.title,
    required this.icon,
    required this.type,
    required this.columns,
    this.hasDateRange = false,
    this.hasGroupBy = false,
    this.hasWarehouse = false,
    this.hasBelowQuantity = false,
    this.hasOnlyWithBalance = false,
    this.chartKind,
    this.chartValueKey,
    this.chartLabelKey,
    this.hasLimit = false,
    this.showFooter = false,
    this.percentOfKey,
    this.sortKey,
    this.sortAsc = false,
  });
}

const _specs = [
  _ReportSpec(
    title: 'Sales Summary',
    icon: Icons.trending_up,
    type: ReportType.salesSummary,
    hasDateRange: true,
    hasGroupBy: true,
    chartKind: _ChartKind.line,
    chartValueKey: 'revenue',
    chartLabelKey: 'period',
    columns: [
      _ReportColumn('Period', 'period'),
      _ReportColumn('Revenue', 'revenue', kind: _ColKind.money),
      _ReportColumn('Orders', 'orderCount', kind: _ColKind.number),
      _ReportColumn('Average Ticket', 'averageTicket', kind: _ColKind.money),
    ],
  ),
  _ReportSpec(
    title: 'Top Products',
    icon: Icons.star_outline,
    type: ReportType.topProducts,
    hasDateRange: true,
    hasLimit: true,
    showFooter: true,
    sortKey: 'revenue',
    chartKind: _ChartKind.rankedBar,
    chartValueKey: 'revenue',
    chartLabelKey: 'description',
    columns: [
      _ReportColumn('Product', 'description'),
      _ReportColumn('Units Sold', 'quantitySold', kind: _ColKind.number),
      _ReportColumn('Revenue', 'revenue', kind: _ColKind.money),
    ],
  ),
  _ReportSpec(
    title: 'Category Share',
    icon: Icons.pie_chart_outline,
    type: ReportType.categoryShare,
    hasDateRange: true,
    showFooter: true,
    percentOfKey: 'revenue',
    sortKey: 'revenue',
    chartKind: _ChartKind.donut,
    chartValueKey: 'revenue',
    chartLabelKey: 'categoryName',
    columns: [
      _ReportColumn('Category', 'categoryName'),
      _ReportColumn('Units Sold', 'quantitySold', kind: _ColKind.number),
      _ReportColumn('Revenue', 'revenue', kind: _ColKind.money),
    ],
  ),
  _ReportSpec(
    title: 'Stock Levels',
    icon: Icons.inventory_2_outlined,
    type: ReportType.stockLevels,
    hasWarehouse: true,
    hasBelowQuantity: true,
    showFooter: true,
    sortKey: 'quantity',
    sortAsc: true,
    columns: [
      _ReportColumn('Product', 'description'),
      _ReportColumn('Warehouse', 'warehouseName'),
      _ReportColumn('Quantity', 'quantity', kind: _ColKind.number),
    ],
  ),
  _ReportSpec(
    title: 'Customer Balances',
    icon: Icons.account_balance_wallet_outlined,
    type: ReportType.customerBalances,
    hasOnlyWithBalance: true,
    showFooter: true,
    sortKey: 'outstanding',
    chartKind: _ChartKind.rankedBar,
    chartValueKey: 'outstanding',
    chartLabelKey: 'name',
    columns: [
      _ReportColumn('Customer', 'name'),
      _ReportColumn('Total Sales', 'totalSales', kind: _ColKind.money),
      _ReportColumn('Total Paid', 'totalPaid', kind: _ColKind.money),
      _ReportColumn('Outstanding', 'outstanding', kind: _ColKind.money),
    ],
  ),
  _ReportSpec(
    title: 'Purchases by Supplier',
    icon: Icons.local_shipping_outlined,
    type: ReportType.purchasesBySupplier,
    hasDateRange: true,
    showFooter: true,
    sortKey: 'totalSpent',
    chartKind: _ChartKind.rankedBar,
    chartValueKey: 'totalSpent',
    chartLabelKey: 'supplierName',
    columns: [
      _ReportColumn('Supplier', 'supplierName'),
      _ReportColumn('Purchases', 'purchaseCount', kind: _ColKind.number),
      _ReportColumn('Total Spent', 'totalSpent', kind: _ColKind.money),
    ],
  ),
  _ReportSpec(
    title: 'Tax Totals',
    icon: Icons.percent_outlined,
    type: ReportType.taxTotals,
    hasDateRange: true,
    showFooter: true,
    percentOfKey: 'totalAmount',
    sortKey: 'totalAmount',
    chartKind: _ChartKind.donut,
    chartValueKey: 'totalAmount',
    chartLabelKey: 'taxType',
    columns: [
      _ReportColumn('Tax Type', 'taxType'),
      _ReportColumn('Total Amount', 'totalAmount', kind: _ColKind.money),
    ],
  ),
  _ReportSpec(
    title: 'Salesperson Performance',
    icon: Icons.badge_outlined,
    type: ReportType.salespersonPerformance,
    hasDateRange: true,
    showFooter: true,
    sortKey: 'totalRevenue',
    chartKind: _ChartKind.rankedBar,
    chartValueKey: 'totalRevenue',
    chartLabelKey: 'name',
    columns: [
      _ReportColumn('Salesperson', 'name'),
      _ReportColumn('Orders', 'orderCount', kind: _ColKind.number),
      _ReportColumn('Revenue', 'totalRevenue', kind: _ColKind.money),
    ],
  ),
];

/// Renders any /api/Reports/ endpoint as a dashboard: KPI cards, a chart
/// where the data warrants one, and the detail table. Adding a report is
/// still just adding a _ReportSpec entry.
class ReportsMainScreen extends StatefulWidget {
  const ReportsMainScreen({super.key});

  @override
  State<ReportsMainScreen> createState() => _ReportsMainScreenState();
}

class _ReportsMainScreenState extends State<ReportsMainScreen> {
  _ReportSpec _spec = _specs.first;
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _warehouseId;
  final _belowQuantityController = TextEditingController();
  bool _onlyWithBalance = false;
  bool _groupByDay = true;
  int _limit = 10;

  final _numberFormat = NumberFormat('#,##0');
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WarehouseProvider>().fetchWarehouses();
      _refresh();
    });
  }

  @override
  void dispose() {
    _belowQuantityController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final params = <String, String>{};
    if (_spec.hasDateRange) {
      if (_fromDate != null) {
        params['from_date'] = _fmtDate(_fromDate!);
      }
      if (_toDate != null) {
        params['to_date'] = _fmtDate(_toDate!);
      }
      if (_spec.hasGroupBy) {
        params['group_by'] = _groupByDay ? 'day' : 'month';
      }
    }
    if (_spec.hasLimit) {
      params['limit'] = '$_limit';
    }
    if (_spec.hasWarehouse) {
      if (_warehouseId != null) params['warehouse_id'] = '$_warehouseId';
      final belowQty = int.tryParse(_belowQuantityController.text.trim());
      if (belowQty != null) params['below_quantity'] = '$belowQty';
    }
    if (_spec.hasOnlyWithBalance && _onlyWithBalance) {
      params['only_with_balance'] = 'true';
    }
    await context.read<ReportsProvider>().fetchReport(_spec.type, params: params);
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isFrom}) async {
    final current = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          // Reset the opposite bound if the range became invalid
          if (_toDate != null && _toDate!.isBefore(picked)) _toDate = null;
        } else {
          _toDate = picked;
          if (_fromDate != null && picked.isBefore(_fromDate!)) _fromDate = null;
        }
      });
      _refresh();
    }
  }

  void _selectSpec(_ReportSpec spec) {
    if (spec.type == _spec.type) return;
    setState(() {
      _spec = spec;
      _fromDate = null;
      _toDate = null;
      _warehouseId = null;
      _belowQuantityController.clear();
      _onlyWithBalance = false;
      _groupByDay = true;
      _limit = 10;
    });
    _refresh();
  }

  /// Server DTOs may arrive camelCase or PascalCase depending on serializer
  /// settings — accept both.
  static dynamic _val(Map<String, dynamic> row, String key) {
    if (row.containsKey(key)) return row[key];
    final pascal = key[0].toUpperCase() + key.substring(1);
    return row[pascal];
  }

  static double _num(Map<String, dynamic> row, String key) {
    final v = _val(row, key);
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  static double _sum(List<Map<String, dynamic>> rows, String key) =>
      rows.fold(0.0, (acc, row) => acc + _num(row, key));

  String _formatNum(double v) => _numberFormat.format(v.round());

  /// Compact money for chart axes ("$1.2k", "$3.4M").
  String _compactMoney(double v) {
    if (v.abs() >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v.abs() >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  /// "2025-09-15" → "Sep 15"; "2025-09" → "Sep '25"; anything else verbatim.
  String _shortLabel(String label) {
    if (label.length == 10 && label[4] == '-' && label[7] == '-') {
      final m = int.tryParse(label.substring(5, 7));
      final d = int.tryParse(label.substring(8, 10));
      if (m != null && m >= 1 && m <= 12 && d != null) {
        return '${_months[m - 1]} $d';
      }
    }
    if (label.length == 7 && label[4] == '-') {
      final m = int.tryParse(label.substring(5, 7));
      if (m != null && m >= 1 && m <= 12) return "${_months[m - 1]} '${label.substring(2, 4)}";
    }
    return label;
  }

  /// Rows in display order (server usually pre-sorts; the spec's sortKey is
  /// the fallback / guarantee for ranked charts and the table).
  List<Map<String, dynamic>> _sortedRows(List<Map<String, dynamic>> rows) {
    if (_spec.sortKey == null) return rows;
    final sorted = [...rows];
    sorted.sort((a, b) {
      final cmp = _num(a, _spec.sortKey!).compareTo(_num(b, _spec.sortKey!));
      return _spec.sortAsc ? cmp : -cmp;
    });
    return sorted;
  }

  /// Display highlight threshold for stock levels: the below-quantity filter
  /// when set, otherwise 0 ("zero stock" is the only clear signal).
  int get _stockThreshold =>
      int.tryParse(_belowQuantityController.text.trim()) ?? 0;

  Color? _cellColor(_ReportColumn col, Map<String, dynamic> row) {
    if (_spec.type == ReportType.customerBalances &&
        col.key == 'outstanding' &&
        _num(row, 'outstanding') > 0) {
      return AppTheme.error;
    }
    if (_spec.type == ReportType.stockLevels && col.key == 'quantity') {
      final q = _num(row, 'quantity');
      final t = _stockThreshold;
      if (q <= t) return AppTheme.error;
      if (t > 0 && q <= t * 2) return AppTheme.warning;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportsProvider>();

    return BaseScreen(
      title: _spec.title,
      onRetry: _refresh,
      isLoading: reports.isLoading,
      error: reports.error,
      body: Column(
        children: [
          _buildReportPicker(),
          Expanded(
            child: reports.rows.isEmpty && !reports.isLoading
                ? EmptyState(
                    icon: Icons.assessment_outlined,
                    title: 'No data',
                    subtitle:
                        'No rows for "${_spec.title}" with the current filters.',
                    action: ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Refresh'),
                    ),
                  )
                : _buildDashboard(reports.rows),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(List<Map<String, dynamic>> rows) {
    final sorted = _sortedRows(rows);
    final kpis = _buildKpiCards(rows, sorted);
    final chart = _buildChart(rows, sorted);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildKpiRow(kpis),
          if (chart != null) ...[
            const SizedBox(height: 16),
            chart,
          ],
          const SizedBox(height: 16),
          _buildDetailCard(sorted),
        ],
      ),
    );
  }

  // ── KPI cards ────────────────────────────────────────────────────────────

  List<StatCard> _buildKpiCards(
    List<Map<String, dynamic>> rows,
    List<Map<String, dynamic>> sorted,
  ) {
    const dash = '—';
    switch (_spec.type) {
      case ReportType.salesSummary:
        final revenue = _sum(rows, 'revenue');
        final orders = _sum(rows, 'orderCount');
        final best = sorted.isNotEmpty
            ? sorted.reduce(
                (a, b) => _num(a, 'revenue') >= _num(b, 'revenue') ? a : b)
            : null;
        return [
          StatCard(
            label: 'Total Revenue',
            value: formatCurrency(revenue),
            icon: Icons.payments_outlined,
            caption: '${rows.length} periods',
          ),
          StatCard(
            label: 'Orders',
            value: _formatNum(orders),
            icon: Icons.receipt_long_outlined,
          ),
          StatCard(
            label: 'Average Ticket',
            value: orders > 0 ? formatCurrency(revenue / orders) : dash,
            icon: Icons.local_atm_outlined,
          ),
          StatCard(
            label: 'Best Period',
            value: best != null ? formatCurrency(_num(best, 'revenue')) : dash,
            icon: Icons.emoji_events_outlined,
            caption: best != null ? _shortLabel('${_val(best, 'period')}') : null,
          ),
        ];
      case ReportType.topProducts:
        final top = sorted.isNotEmpty ? sorted.first : null;
        return [
          StatCard(
            label: 'Top Product',
            value: top != null ? '${_val(top, 'description')}' : dash,
            icon: Icons.star_outline,
            caption: top != null ? '${_formatNum(_num(top, 'quantitySold'))} units' : null,
          ),
          StatCard(
            label: 'Units Sold (top $_limit)',
            value: _formatNum(_sum(rows, 'quantitySold')),
            icon: Icons.sell_outlined,
          ),
          StatCard(
            label: 'Revenue (top $_limit)',
            value: formatCurrency(_sum(rows, 'revenue')),
            icon: Icons.payments_outlined,
          ),
        ];
      case ReportType.categoryShare:
        final best = sorted.isNotEmpty
            ? (sorted.first)
            : null;
        return [
          StatCard(
            label: 'Categories',
            value: _formatNum(rows.length.toDouble()),
            icon: Icons.category_outlined,
          ),
          StatCard(
            label: 'Best Category',
            value: best != null ? '${_val(best, 'categoryName')}' : dash,
            icon: Icons.emoji_events_outlined,
            caption:
                best != null ? formatCurrency(_num(best, 'revenue')) : null,
          ),
          StatCard(
            label: 'Total Revenue',
            value: formatCurrency(_sum(rows, 'revenue')),
            icon: Icons.payments_outlined,
          ),
        ];
      case ReportType.stockLevels:
        final t = _stockThreshold;
        final low = rows.where((r) => _num(r, 'quantity') <= t).length;
        final skus = rows.map((r) => _num(r, 'productId')).toSet();
        final warehouses = rows
            .map((r) => '${_val(r, 'warehouseName') ?? ''}')
            .where((n) => n.isNotEmpty)
            .toSet();
        return [
          StatCard(
            label: 'Distinct SKUs',
            value: _formatNum(skus.length.toDouble()),
            icon: Icons.inventory_2_outlined,
          ),
          StatCard(
            label: 'Total Units',
            value: _formatNum(_sum(rows, 'quantity')),
            icon: Icons.sell_outlined,
          ),
          StatCard(
            label: t > 0 ? 'Low Stock (≤ $t)' : 'Zero Stock',
            value: _formatNum(low.toDouble()),
            icon: Icons.warning_amber_outlined,
            valueColor: low > 0 ? AppTheme.error : AppTheme.success,
          ),
          StatCard(
            label: 'Warehouses',
            value: _formatNum(warehouses.length.toDouble()),
            icon: Icons.warehouse_outlined,
          ),
        ];
      case ReportType.customerBalances:
        final outstanding = _sum(rows, 'outstanding');
        final sales = _sum(rows, 'totalSales');
        final paid = _sum(rows, 'totalPaid');
        return [
          StatCard(
            label: 'Total Outstanding',
            value: formatCurrency(outstanding),
            icon: Icons.account_balance_wallet_outlined,
            valueColor:
                outstanding > 0 ? AppTheme.error : AppTheme.success,
          ),
          StatCard(
            label: 'Customers with Balance',
            value: _formatNum(
                rows.where((r) => _num(r, 'outstanding') > 0).length.toDouble()),
            icon: Icons.people_outline,
          ),
          StatCard(
            label: 'Total Paid',
            value: formatCurrency(paid),
            icon: Icons.check_circle_outline,
          ),
          StatCard(
            label: 'Collection Rate',
            value: sales > 0
                ? '${(paid / sales * 100).toStringAsFixed(1)}%'
                : dash,
            icon: Icons.percent_outlined,
            valueColor: sales > 0 && paid / sales >= 1
                ? AppTheme.success
                : null,
          ),
        ];
      case ReportType.purchasesBySupplier:
        final spent = _sum(rows, 'totalSpent');
        final orders = _sum(rows, 'purchaseCount');
        return [
          StatCard(
            label: 'Total Spent',
            value: formatCurrency(spent),
            icon: Icons.payments_outlined,
          ),
          StatCard(
            label: 'Suppliers',
            value: _formatNum(rows.length.toDouble()),
            icon: Icons.local_shipping_outlined,
          ),
          StatCard(
            label: 'Avg per Purchase',
            value: orders > 0 ? formatCurrency(spent / orders) : dash,
            icon: Icons.local_atm_outlined,
          ),
          StatCard(
            label: 'Top Supplier',
            value: sorted.isNotEmpty ? '${_val(sorted.first, 'supplierName')}' : dash,
            icon: Icons.emoji_events_outlined,
            caption: sorted.isNotEmpty
                ? formatCurrency(_num(sorted.first, 'totalSpent'))
                : null,
          ),
        ];
      case ReportType.taxTotals:
        final largest =
            sorted.isNotEmpty ? sorted.reduce((a, b) => _num(a, 'totalAmount') >= _num(b, 'totalAmount') ? a : b) : null;
        return [
          StatCard(
            label: 'Total Tax',
            value: formatCurrency(_sum(rows, 'totalAmount')),
            icon: Icons.receipt_long_outlined,
          ),
          StatCard(
            label: 'Tax Types',
            value: _formatNum(rows.length.toDouble()),
            icon: Icons.percent_outlined,
          ),
          StatCard(
            label: 'Largest Tax Type',
            value: largest != null ? '${_val(largest, 'taxType')}' : dash,
            icon: Icons.tag,
            caption: largest != null
                ? formatCurrency(_num(largest, 'totalAmount'))
                : null,
          ),
        ];
      case ReportType.salespersonPerformance:
        final revenue = _sum(rows, 'totalRevenue');
        return [
          StatCard(
            label: 'Total Revenue',
            value: formatCurrency(revenue),
            icon: Icons.payments_outlined,
          ),
          StatCard(
            label: 'Orders',
            value: _formatNum(_sum(rows, 'orderCount')),
            icon: Icons.receipt_long_outlined,
          ),
          StatCard(
            label: 'Top Salesperson',
            value: sorted.isNotEmpty ? '${_val(sorted.first, 'name')}' : dash,
            icon: Icons.emoji_events_outlined,
            caption: sorted.isNotEmpty
                ? formatCurrency(_num(sorted.first, 'totalRevenue'))
                : null,
          ),
          StatCard(
            label: 'Avg per Salesperson',
            value: rows.isNotEmpty ? formatCurrency(revenue / rows.length) : dash,
            icon: Icons.local_atm_outlined,
          ),
        ];
    }
  }

  Widget _buildKpiRow(List<StatCard> cards) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return Row(
            children: [for (final card in cards) Expanded(child: card)],
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final card in cards) SizedBox(width: 240, child: card)],
        );
      },
    );
  }

  // ── Chart ────────────────────────────────────────────────────────────────

  Widget? _buildChart(
    List<Map<String, dynamic>> rows,
    List<Map<String, dynamic>> sorted,
  ) {
    if (_spec.chartKind == null || rows.isEmpty) return null;
    final palette = ChartPalette.of(AppTheme.isDark);
    final valueKey = _spec.chartValueKey!;
    final labelKey = _spec.chartLabelKey!;

    switch (_spec.chartKind!) {
      case _ChartKind.line:
        if (sorted.length < 2) {
          // A single point paints an empty chart — the table carries it.
          return null;
        }
        return DashboardCard(
          title: 'Revenue Trend',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
            child: SizedBox(
              height: 240,
              child: buildTimeSeriesChart(
                xLabels: [for (final row in sorted) '${_val(row, labelKey)}'],
                values: [for (final row in sorted) _num(row, valueKey)],
                palette: palette,
                axisFormatter: _compactMoney,
                tooltipFormatter: formatCurrency,
                shortLabel: _shortLabel,
              ),
            ),
          ),
        );
      case _ChartKind.rankedBar:
        var chartRows = sorted;
        if (_spec.type == ReportType.customerBalances) {
          chartRows = sorted.take(8).toList();
          if (chartRows.every((r) => _num(r, 'outstanding') <= 0)) {
            return null; // everything settled — nothing to compare
          }
        } else {
          chartRows = sorted.take(8).toList();
        }
        final chartRowsList =
            chartRows.where((r) => _num(r, valueKey) > 0).toList();
        if (chartRowsList.isEmpty) return null;
        return DashboardCard(
          title: 'Top ${chartRowsList.length}',
          trailing: _spec.hasLimit
              ? Text(
                  'of ${sorted.length}',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
            child: SizedBox(
              height: 240,
              child: buildRankedBarChart(
                labels: [
                  for (final row in chartRowsList) '${_val(row, labelKey)}',
                ],
                values: [
                  for (final row in chartRowsList) _num(row, valueKey),
                ],
                palette: palette,
                axisFormatter: _compactMoney,
                tooltipFormatter: formatCurrency,
              ),
            ),
          ),
        );
      case _ChartKind.donut:
        final sliced = sorted
            .map((r) => ('${_val(r, labelKey)}', _num(r, valueKey)))
            .where((s) => s.$2 > 0)
            .toList();
        if (sliced.isEmpty) return null;
        final fold = sliced.length > 6;
        final kept = fold ? sliced.sublist(0, 5) : sliced;
        final otherSum = fold
            ? sliced.sublist(5).fold(0.0, (acc, s) => acc + s.$2)
            : 0.0;
        final slices = [
          ...kept.map((s) => (s.$1, s.$2)),
          if (fold && otherSum > 0) (otherSliceLabel, otherSum),
        ];
        return DashboardCard(
          title: 'Share',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 250,
              child: buildShareDonutChart(
                slices: slices,
                isDark: AppTheme.isDark,
              ),
            ),
          ),
        );
    }
  }

  // ── Detail table ─────────────────────────────────────────────────────────

  Widget _buildDetailCard(List<Map<String, dynamic>> rows) {
    var columns = [
      for (final c in _spec.columns)
        DataColumn(
          label: Text(
            c.label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
            ),
          ),
        ),
    ];
    if (_spec.percentOfKey != null) {
      columns.add(
        DataColumn(
          label: Text(
            '% of total',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
            ),
          ),
        ),
      );
    }

    final total =
        _spec.percentOfKey != null ? _sum(rows, _spec.percentOfKey!) : 0.0;

    final dataRows = [
      for (final row in rows)
        DataRow(cells: [
          for (final c in _spec.columns)
            DataCell(
              Text(
                _formatCell(c, _val(row, c.key)),
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight:
                      c.kind == _ColKind.text ? FontWeight.w500 : FontWeight.normal,
                  color: _cellColor(c, row),
                ),
              ),
            ),
          if (_spec.percentOfKey != null)
            DataCell(
              Text(
                total > 0
                    ? '${(_num(row, _spec.percentOfKey!) / total * 100).toStringAsFixed(1)}%'
                    : '—',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                ),
              ),
            ),
        ]),
    ];

    if (_spec.showFooter && rows.isNotEmpty) {
      final footerLabel =
          _spec.hasLimit ? 'Total (top $_limit)' : 'Total';
      dataRows.add(
        DataRow(
          color: WidgetStatePropertyAll(
            AppTheme.hairline.withOpacity(0.35),
          ),
          cells: [
            for (final c in _spec.columns)
              DataCell(
                Text(
                  c == _spec.columns.first
                      ? footerLabel
                      : c.kind == _ColKind.text
                          ? ''
                          : c.kind == _ColKind.money
                              ? formatCurrency(_sum(rows, c.key))
                              : _formatNum(_sum(rows, c.key)),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
            if (_spec.percentOfKey != null)
              const DataCell(
                Text(
                  '100%',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return DashboardCard(
      title: 'Detail',
      trailing: Text(
        '${rows.length} rows',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          color: AppTheme.mutedText,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: DataTable(
            columnSpacing: 40,
            columns: columns,
            rows: dataRows,
          ),
        ),
      ),
    );
  }

  String _formatCell(_ReportColumn col, dynamic value) {
    if (value == null) return col.kind == _ColKind.text ? '' : '—';
    switch (col.kind) {
      case _ColKind.text:
        return value.toString();
      case _ColKind.number:
        final n = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
        return _formatNum(n);
      case _ColKind.money:
        final n = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
        return formatCurrency(n);
    }
  }

  // ── Filter header ────────────────────────────────────────────────────────

  Widget _buildFilterChipButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppTheme.primaryGold),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _buildReportPicker() {
    final theme = Theme.of(context);
    final chip = Theme.of(context).brightness;
    // Reports screen listens to warehouse changes so the StockLevels filter
    // dropdown stays in sync with WarehouseProvider.
    context.watch<WarehouseProvider>();
    final warehouses = context.read<WarehouseProvider>().warehouses;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final spec in _specs)
                ChoiceChip(
                  avatar: Icon(
                    spec.icon,
                    size: 18,
                    color: chip == Brightness.dark
                        ? AppTheme.primaryGold
                        : AppTheme.mediumPurple,
                  ),
                  // Gold fill reads on both surfaces; the label keeps the
                  // theme's text color so it never washes out.
                  label: Text(spec.title),
                  selected: _spec.type == spec.type,
                  selectedColor: chip == Brightness.dark
                      ? AppTheme.primaryGold
                      : AppTheme.lightGold,
                  labelStyle: TextStyle(color: AppTheme.textColor),
                  onSelected: (_) => _selectSpec(spec),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_spec.hasDateRange) ...[
                _buildFilterChipButton(
                  icon: Icons.calendar_today_outlined,
                  label: _fromDate == null
                      ? 'From: any date'
                      : 'From: ${_fmtDate(_fromDate!)}',
                  onTap: () => _pickDate(isFrom: true),
                ),
                _buildFilterChipButton(
                  icon: Icons.calendar_today_outlined,
                  label:
                      _toDate == null ? 'To: any date' : 'To: ${_fmtDate(_toDate!)}',
                  onTap: () => _pickDate(isFrom: false),
                ),
                if (_spec.hasGroupBy)
                  FilterChip(
                    label: Text(_groupByDay ? 'Grouped by day' : 'Grouped by month'),
                    selected: !_groupByDay,
                    onSelected: (v) {
                      setState(() => _groupByDay = !v);
                      _refresh();
                    },
                  ),
              ],
              if (_spec.hasLimit)
                DropdownButton<int>(
                  value: _limit,
                  items: [
                    for (final l in const [10, 25, 50])
                      DropdownMenuItem(value: l, child: Text('Top $l')),
                  ],
                  onChanged: (v) {
                    if (v == null || v == _limit) return;
                    setState(() => _limit = v);
                    _refresh();
                  },
                ),
              if (_spec.hasWarehouse)
                DropdownButton<int?>(
                  value: _warehouseId,
                  hint: const Text('All warehouses'),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All warehouses'),
                    ),
                    for (final w in warehouses)
                      DropdownMenuItem<int?>(
                        value: w.id,
                        child: Text(w.name ?? 'Warehouse ${w.id}'),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() => _warehouseId = v);
                    _refresh();
                  },
                ),
              if (_spec.hasBelowQuantity)
                SizedBox(
                  width: 190,
                  child: TextField(
                    controller: _belowQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Quantity at or below',
                      hintText: 'e.g. 5',
                    ),
                    onSubmitted: (_) => _refresh(),
                  ),
                ),
              if (_spec.hasOnlyWithBalance)
                FilterChip(
                  label: const Text('Only with balance'),
                  selected: _onlyWithBalance,
                  onSelected: (v) {
                    setState(() => _onlyWithBalance = v);
                    _refresh();
                  },
                ),
              // Explicit refresh: navigation doesn't auto-refetch reports, so
              // this is the way to pull the latest numbers on demand.
              _buildRefreshChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshChip() {
    final isLoading = context.watch<ReportsProvider>().isLoading;
    return ActionChip(
      avatar: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : const Icon(Icons.refresh, size: 18, color: AppTheme.primaryGold),
      label: const Text('Refresh'),
      onPressed: isLoading ? null : _refresh,
    );
  }
}