import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/providers.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/base_screen.dart';

enum _ColKind { text, number, money }

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
  });
}

const _specs = [
  _ReportSpec(
    title: 'Sales Summary',
    icon: Icons.trending_up,
    type: ReportType.salesSummary,
    hasDateRange: true,
    hasGroupBy: true,
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
    columns: [
      _ReportColumn('Salesperson', 'name'),
      _ReportColumn('Orders', 'orderCount', kind: _ColKind.number),
      _ReportColumn('Revenue', 'totalRevenue', kind: _ColKind.money),
    ],
  ),
];

/// Renders any /api/Reports/ endpoint from a column descriptor, so adding a
/// report is just adding a _ReportSpec entry.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  String _formatCell(_ReportColumn col, dynamic value) {
    if (value == null) return col.kind == _ColKind.text ? '' : '0';
    switch (col.kind) {
      case _ColKind.text:
        return value.toString();
      case _ColKind.number:
        return (value is num ? value : num.tryParse(value.toString()) ?? 0)
            .toString();
      case _ColKind.money:
        final n = value is num ? value : num.tryParse(value.toString()) ?? 0;
        return '\$${double.parse(n.toString()).toStringAsFixed(2)}';
    }
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Card(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 40,
                            columns: [
                              for (final c in _spec.columns)
                                DataColumn(label: Text(c.label)),
                            ],
                            rows: [
                              for (final row in reports.rows)
                                DataRow(cells: [
                                  for (final c in _spec.columns)
                                    DataCell(
                                      Text(
                                        _formatCell(c, _val(row, c.key)),
                                        style: TextStyle(
                                          fontWeight: c.kind == _ColKind.text
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                          color: c.key == 'outstanding' &&
                                              (_val(row, c.key) is num
                                                  ? (_val(row, c.key) as num) > 0
                                                  : false)
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .error
                                              : null,
                                        ),
                                      ),
                                    ),
                                ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppTheme.mediumPurple),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _buildReportPicker() {
    final theme = Theme.of(context);
    // Reports screen listens to warehouse changes so the StockLevels filter
    // dropdown stays in sync with WarehouseProvider.
    context.watch<WarehouseProvider>();
    final warehouses = context.read<WarehouseProvider>().warehouses;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
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
                  avatar:
                      Icon(spec.icon, size: 18, color: AppTheme.mediumPurple),
                  label: Text(spec.title),
                  selected: _spec.type == spec.type,
                  selectedColor: AppTheme.lightGold,
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
            ],
          ),
        ],
      ),
    );
  }
}