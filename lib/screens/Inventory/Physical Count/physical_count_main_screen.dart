import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/inventory_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/models/product_model.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class PhysicalCountSession {
  final int id;
  final int warehouseId;
  final DateTime countDate;
  String status;
  final List<PhysicalCountItem> items;

  PhysicalCountSession({
    required this.id,
    required this.warehouseId,
    required this.countDate,
    required this.status,
    required this.items,
  });

  double get completionPercentage => items.isEmpty ? 0 : (items.where((i) => i.counted).length / items.length) * 100;
}

class PhysicalCountItem {
  final int inventoryId;
  final int productId;
  final String productName;
  final int systemQuantity;
  int? countedQuantity;
  int? variance;
  bool counted;
  String? notes;

  PhysicalCountItem({
    required this.inventoryId,
    required this.productId,
    required this.productName,
    required this.systemQuantity,
    this.countedQuantity,
    this.variance,
    this.counted = false,
    this.notes,
  });

  void calculateVariance() {
    if (countedQuantity != null) {
      variance = countedQuantity! - systemQuantity;
      counted = true;
    }
  }
}

class PhysicalCountMainScreen extends StatefulWidget {
  const PhysicalCountMainScreen({super.key});

  @override
  State<PhysicalCountMainScreen> createState() => _PhysicalCountMainScreenState();
}

class _PhysicalCountMainScreenState extends State<PhysicalCountMainScreen> {
  PhysicalCountSession? _currentSession;
  int? _selectedWarehouseId;
  bool _showCountedOnly = false;
  bool _showVarianceOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseProvider>().fetchWarehouses();
      context.read<ProductProvider>().fetchProducts();
      context.read<InventoryProvider>().fetchInventory();
    });
  }

  void _startNewCount() {
    final warehouses = context.read<WarehouseProvider>().warehouses;
    if (warehouses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('No warehouses available. Add warehouses first.'),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start New Physical Count'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a warehouse to count:'),
            const SizedBox(height: 16),
            ...warehouses.map((w) => ListTile(
              leading: const Icon(Icons.store),
              title: Text(w.name ?? 'Warehouse ${w.id}'),
              onTap: () {
                Navigator.pop(context);
                _initializeCountSession(w.id);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _initializeCountSession(int warehouseId) {
    final inventory = context.read<InventoryProvider>().inventory
        .where((i) => i.warehouseId == warehouseId)
        .toList();

    final products = context.read<ProductProvider>().products;

    setState(() {
      _selectedWarehouseId = warehouseId;
      _currentSession = PhysicalCountSession(
        id: DateTime.now().millisecondsSinceEpoch,
        warehouseId: warehouseId,
        countDate: DateTime.now(),
        status: 'In Progress',
        items: inventory.map((inv) {
          final product = products.firstWhere(
            (p) => p.id == inv.productId,
            orElse: () => ProductModel(id: inv.productId ?? 0, description: 'Product ${inv.productId}'),
          );
          return PhysicalCountItem(
            inventoryId: inv.id,
            productId: inv.productId ?? 0,
            productName: product.description ?? 'Product ${inv.productId}',
            systemQuantity: inv.quantity ?? 0,
          );
        }).toList(),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      successSnackBar('Started counting ${_currentSession!.items.length} items in warehouse'),
    );
  }

  void _recordCount(PhysicalCountItem item, int quantity, String notes) {
    setState(() {
      final sessionItem = _currentSession!.items.firstWhere((i) => i.inventoryId == item.inventoryId);
      sessionItem.countedQuantity = quantity;
      sessionItem.notes = notes;
      sessionItem.calculateVariance();
    });
  }

  void _completeCount() {
    if (_currentSession == null) return;

    final uncountedItems = _currentSession!.items.where((i) => !i.counted).length;

    if (uncountedItems > 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Incomplete Count'),
          content: Text('You have $uncountedItems items that haven\'t been counted yet. Are you sure you want to complete?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Counting'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _finalizeCount();
              },
              child: const Text('Complete Anyway'),
            ),
          ],
        ),
      );
      return;
    }

    _finalizeCount();
  }

  void _finalizeCount() {
    if (_currentSession == null) return;

    final adjustments = _currentSession!.items.where((i) => i.variance != null && i.variance! != 0).toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete Physical Count'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_currentSession!.items.length} items counted'),
            const SizedBox(height: 8),
            Text('${adjustments.length} items with variances'),
            const SizedBox(height: 16),
            const Text('This will create inventory adjustment movements for all variances.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentSession!.status = 'Completed';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                successSnackBar('Physical count completed! ${adjustments.length} adjustments recorded.'),
              );
            },
            child: const Text('Complete & Adjust'),
          ),
        ],
      ),
    );
  }

  void _cancelCount() {
    if (_currentSession == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Physical Count'),
        content: const Text('Are you sure? All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentSession = null;
                _selectedWarehouseId = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Physical count cancelled')),
              );
            },
            child: const Text('Cancel Count', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCountDialog(PhysicalCountItem item) {
    final countController = TextEditingController(text: item.countedQuantity?.toString() ?? '');
    final notesController = TextEditingController(text: item.notes ?? '');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Count: ${item.productName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text('System Quantity', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('${item.systemQuantity}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text('Physical Count', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            TextFormField(
                              controller: countController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              onChanged: (value) => setDialogState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (item.countedQuantity != null)
                Card(
                  color: item.variance! > 0 ? Colors.orange[50] : (item.variance! < 0 ? Colors.red[50] : Colors.grey[50]),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Variance: ${item.variance! > 0 ? '+' : ''}${item.variance}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: item.variance! > 0 ? Colors.orange : (item.variance! < 0 ? Colors.red : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Found in different location, damaged, etc.',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            if (item.countedQuantity != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _recordCount(item, 0, '');
                },
                child: const Text('Clear'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final count = int.tryParse(countController.text);
                if (count == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    errorSnackBar('Please enter a valid quantity'),
                  );
                  return;
                }
                Navigator.pop(context);
                _recordCount(item, count, notesController.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Physical Count'),
        backgroundColor: Colors.amber[700],
        actions: [
          if (_currentSession != null) ...[
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelCount,
              tooltip: 'Cancel Count',
            ),
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _completeCount,
              tooltip: 'Complete Count',
            ),
          ],
        ],
      ),
      body: _currentSession == null
          ? _buildNoSessionView()
          : _buildCountView(),
    );
  }

  Widget _buildNoSessionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 100, color: Colors.amber[700]),
          const SizedBox(height: 24),
          const Text(
            'Physical Inventory Count',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Verify physical stock matches system records',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _startNewCount,
            icon: const Icon(Icons.add),
            label: const Text('Start New Count'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountView() {
    final items = _currentSession!.items;
    final filteredItems = items.where((item) {
      if (_showCountedOnly && !item.counted) return false;
      if (_showVarianceOnly && (item.variance == null || item.variance! == 0)) return false;
      return true;
    }).toList();

    final countedCount = items.where((i) => i.counted).length;
    final varianceCount = items.where((i) => i.variance != null && i.variance! != 0).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.amber[50],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Total Items', '${items.length}', Icons.inventory),
                  _buildStatCard('Counted', '$countedCount', Icons.check_circle, color: Colors.green),
                  _buildStatCard('Variances', '$varianceCount', Icons.warning, color: varianceCount > 0 ? Colors.orange : Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _currentSession!.completionPercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentSession!.completionPercentage.toStringAsFixed(1)}% Complete',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('Counted Only'),
                    selected: _showCountedOnly,
                    onSelected: (selected) => setState(() => _showCountedOnly = selected),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('With Variance'),
                    selected: _showVarianceOnly,
                    onSelected: (selected) => setState(() => _showVarianceOnly = selected),
                    backgroundColor: Colors.orange[100],
                    selectedColor: Colors.orange[300],
                  ),
                  if (_showCountedOnly || _showVarianceOnly)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _showCountedOnly = false;
                        _showVarianceOnly = false;
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.counted
                        ? (item.variance != null && item.variance! != 0
                            ? Colors.orange[100]
                            : Colors.green[100])
                        : Colors.grey[200],
                    child: item.counted
                        ? Icon(
                            item.variance != null && item.variance! != 0
                                ? Icons.warning
                                : Icons.check,
                            color: item.variance != null && item.variance! != 0
                                ? Colors.orange
                                : Colors.green,
                          )
                        : const Icon(Icons.hourglass_empty),
                  ),
                  title: Text(
                    item.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: item.counted ? null : TextDecoration.underline,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System: ${item.systemQuantity}'),
                      if (item.countedQuantity != null)
                        Text(
                          'Counted: ${item.countedQuantity}${item.variance != null && item.variance! != 0 ? ' (${item.variance! > 0 ? "+" : ""}${item.variance})' : ''}',
                          style: TextStyle(
                            color: item.variance != null && item.variance! != 0
                                ? Colors.orange
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        Text('Notes: ${item.notes}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                    ],
                  ),
                  trailing: item.counted
                      ? const Icon(Icons.edit, color: Colors.amber)
                      : const Icon(Icons.add, color: Colors.amber),
                  onTap: () => _showCountDialog(item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.amber, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
