import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/inventory_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';
import 'package:p_a_jewerly/widgets/paged_list_view.dart';

class InventoryMovementsScreen extends StatefulWidget {
  const InventoryMovementsScreen({super.key});

  @override
  State<InventoryMovementsScreen> createState() => _InventoryMovementsScreenState();
}

class _InventoryMovementsScreenState extends State<InventoryMovementsScreen> {
  String _filterType = 'All';
  int? _selectedWarehouseId;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchMovements();
      context.read<ProductProvider>().fetchProducts();
      context.read<WarehouseProvider>().fetchWarehouses();
    });
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
      });
      _filterMovements();
    }
  }

  void _filterMovements() {
    context.read<InventoryProvider>().fetchMovements(
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Movements'),
        backgroundColor: Colors.amber[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.movements.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.fetchMovements(),
            );
          }
          if (provider.movements.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No inventory movements', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Movements are created when:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Text('• Sales are completed (OUT)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Text('• Purchases are received (IN)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Text('• Quantity adjustments in Inventory', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }

          // Filter movements by type
          var movements = provider.movements;
          if (_filterType != 'All') {
            movements = movements.where((m) => m.movementType == _filterType).toList();
          }
          if (_selectedWarehouseId != null) {
            movements = movements.where((m) => m.warehouseId == _selectedWarehouseId).toList();
          }

          return Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterType == 'All',
                      onSelected: (selected) => setState(() => _filterType = 'All'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('IN'),
                      selected: _filterType == 'IN',
                      onSelected: (selected) => setState(() => _filterType = 'IN'),
                      backgroundColor: Colors.green[100],
                      selectedColor: Colors.green[300],
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('OUT'),
                      selected: _filterType == 'OUT',
                      onSelected: (selected) => setState(() => _filterType = 'OUT'),
                      backgroundColor: Colors.red[100],
                      selectedColor: Colors.red[300],
                    ),
                    if (_selectedWarehouseId != null) ...[
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Warehouse $_selectedWarehouseId'),
                        selected: true,
                        onSelected: (selected) => setState(() => _selectedWarehouseId = null),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => setState(() => _selectedWarehouseId = null),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: PagedListView(
                  padding: const EdgeInsets.all(16),
                  itemCount: movements.length,
                  hasMore: provider.movementsHasMore,
                  isLoadingMore: provider.isLoadingMoreMovements,
                  onLoadMore: () => provider.fetchMovements(
                    fromDate: _fromDate,
                    toDate: _toDate,
                    loadMore: true,
                  ),
                  onRefresh: () => provider.fetchMovements(),
                  itemBuilder: (context, index) {
                    final movement = movements[index];
                    final isIN = movement.movementType == 'IN';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIN ? Colors.green[100] : Colors.red[100],
                          child: Icon(
                            isIN ? Icons.add : Icons.remove,
                            color: isIN ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          'Product ${movement.productId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${movement.movementDate.toString().split('.')[0]}'),
                            Text('Warehouse: ${movement.warehouseId}'),
                            if (movement.notes != null && movement.notes!.isNotEmpty)
                              Text('Notes: ${movement.notes}'),
                            if (movement.manualEntryReason != null && movement.manualEntryReason!.isNotEmpty)
                              Text('Reason: ${movement.manualEntryReason}', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${isIN ? '+' : '-'}${movement.quantity}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isIN ? Colors.green : Colors.red,
                              ),
                            ),
                            if (movement.salesOrderId != null && movement.salesOrderId! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Sale', style: TextStyle(fontSize: 10)),
                              ),
                            if (movement.purchaseOrderId != null && movement.purchaseOrderId! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Purchase', style: TextStyle(fontSize: 10)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Movements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date Range'),
              subtitle: Text(_fromDate != null ? '${_fromDate!.toString().split(' ')[0]} - ${_toDate!.toString().split(' ')[0]}' : 'All time'),
              onTap: () {
                Navigator.pop(context);
                _selectDateRange();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Warehouse Filter'),
              subtitle: Text(_selectedWarehouseId != null ? 'Warehouse $_selectedWarehouseId' : 'All warehouses'),
              onTap: () {
                Navigator.pop(context);
                _showWarehouseFilter();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterType = 'All';
                _selectedWarehouseId = null;
                _fromDate = null;
                _toDate = null;
              });
              context.read<InventoryProvider>().fetchMovements();
              Navigator.pop(context);
            },
            child: const Text('Clear Filters'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showWarehouseFilter() {
    final warehouses = context.read<WarehouseProvider>().warehouses;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Warehouse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Warehouses'),
              selected: _selectedWarehouseId == null,
              onTap: () {
                setState(() => _selectedWarehouseId = null);
                Navigator.pop(context);
              },
            ),
            ...warehouses.map((w) => ListTile(
              leading: const Icon(Icons.store),
              title: Text(w.name ?? 'Warehouse ${w.id}'),
              selected: _selectedWarehouseId == w.id,
              onTap: () {
                setState(() => _selectedWarehouseId = w.id);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}
