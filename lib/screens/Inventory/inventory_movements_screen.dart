import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/inventory_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

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
  final _reasonController = TextEditingController();
  final _quantityController = TextEditingController();
  int? _selectedProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchMovements();
      context.read<ProductProvider>().fetchProducts();
      context.read<WarehouseProvider>().fetchWarehouses();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _quantityController.dispose();
    super.dispose();
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

  void _openManualMovementDialog() {
    showDialog(
      context: context,
      builder: (_) => _buildManualMovementDialog(),
    );
  }

  Widget _buildManualMovementDialog() {
    final products = context.watch<ProductProvider>().products;
    final warehouses = context.watch<WarehouseProvider>().warehouses;

    return AlertDialog(
      title: const Text('Manual Inventory Adjustment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedProductId,
              decoration: const InputDecoration(
                labelText: 'Product',
                border: OutlineInputBorder(),
              ),
              items: products.map((p) {
                return DropdownMenuItem(
                  value: p.id,
                  child: Text(p.description ?? 'Product ${p.id}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedProductId = value),
              validator: (value) => value == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Warehouse',
                border: OutlineInputBorder(),
              ),
              value: warehouses.isNotEmpty ? warehouses.first.id : null,
              items: warehouses.map((w) {
                return DropdownMenuItem(
                  value: w.id,
                  child: Text(w.name ?? 'Warehouse ${w.id}'),
                );
              }).toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'IN',
                    decoration: const InputDecoration(
                      labelText: 'Movement Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'IN', child: Text('IN - Add Stock')),
                      DropdownMenuItem(value: 'OUT', child: Text('OUT - Remove Stock')),
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Must be positive';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                hintText: 'e.g., Damaged items, Found during count, etc.',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Reason required';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveManualMovement,
          child: const Text('Record Movement'),
        ),
      ],
    );
  }

  Future<void> _saveManualMovement() async {
    // This would need a new endpoint or method in the provider
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual movement recording - requires backend endpoint')),
    );
    Navigator.pop(context);
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
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _openManualMovementDialog,
            tooltip: 'Manual Adjustment',
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
                  Text('• Manual adjustments are made', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: movements.length,
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
