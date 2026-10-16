import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/inventory_provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class InventoryMainScreen extends StatefulWidget {
  const InventoryMainScreen({super.key});

  @override
  State<InventoryMainScreen> createState() => _InventoryMainScreenState();
}

class _InventoryMainScreenState extends State<InventoryMainScreen> {
  int? _selectedWarehouseId;
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _weightController = TextEditingController();
  final _quantityController = TextEditingController();
  int? _editingId;
  // Dialog selections — captured from the dropdowns (they were previously
  // ignored and the save hardcoded the first product/warehouse in the list)
  int? _dialogProductId;
  int? _dialogWarehouseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchInventory();
      context.read<WarehouseProvider>().fetchWarehouses();
      context.read<ProductProvider>().fetchProducts(fetchAll: true);
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _weightController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _openDialog({dynamic inventoryItem}) {
    _editingId = inventoryItem?.id;
    _locationController.text = inventoryItem?.location ?? '';
    _weightController.text = inventoryItem?.weight?.toString() ?? '';
    _quantityController.text = inventoryItem?.quantity?.toString() ?? '';
    _dialogProductId = inventoryItem?.productId;
    _dialogWarehouseId = inventoryItem?.warehouseId;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) =>
            _buildDialog(inventoryItem, setDialogState),
      ),
    );
  }

  Widget _buildDialog(dynamic inventoryItem, void Function(VoidCallback) setDialogState) {
    final warehouses = context.watch<WarehouseProvider>().warehouses;
    final products = context.watch<ProductProvider>().products;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.gradientDecoration(radius: 12),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGold, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    inventoryItem == null ? 'Add Inventory Item' : 'Edit Inventory Item',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: _dialogProductId,
                    decoration: InputDecoration(
                      labelText: 'Product',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: products.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(p.description ?? 'Product ${p.id}'),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => _dialogProductId = value),
                    validator: (value) =>
                        value == null ? 'Please select a product' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _dialogWarehouseId,
                    decoration: InputDecoration(
                      labelText: 'Warehouse',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: warehouses.map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text(w.name ?? 'Warehouse ${w.id}'),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => _dialogWarehouseId = value),
                    validator: (value) =>
                        value == null ? 'Please select a warehouse' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g., A-01-01',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Location is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'Weight (g)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final qty = int.tryParse(value ?? '');
                      if (value == null || value.trim().isEmpty) {
                        return 'Quantity is required';
                      }
                      if (qty == null || qty < 0) {
                        return 'Quantity must be 0 or more';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveInventory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: AppTheme.textColor,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveInventory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dialogProductId == null || _dialogWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('Please select a product and a warehouse'),
      );
      return;
    }

    final provider = context.read<InventoryProvider>();
    final data = {
      'productId': _dialogProductId,
      'warehouseId': _dialogWarehouseId,
      'location': _locationController.text.trim(),
      'weight': double.tryParse(_weightController.text) ?? 0.0,
      'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
    };

    final bool success;
    if (_editingId != null) {
      // Editing updates the existing row instead of creating a duplicate
      success = await provider.updateInventoryItem(_editingId!, data);
    } else {
      success = await provider.addInventoryItem(data);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Inventory item ${_editingId == null ? 'created' : 'updated'}'
              : (provider.error ?? 'Operation failed')),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        flexibleSpace: Container(
          decoration: AppTheme.gradientDecoration(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepPurple.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<WarehouseProvider>(
              builder: (context, warehouseProvider, _) {
                return DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Filter by Warehouse',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppTheme.background,
                  ),
                  value: _selectedWarehouseId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Warehouses')),
                    ...warehouseProvider.warehouses.map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text(w.name ?? 'Warehouse ${w.id}'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedWarehouseId = value;
                    });
                    if (value != null) {
                      context.read<InventoryProvider>().fetchInventory(warehouseId: value.toString());
                    } else {
                      context.read<InventoryProvider>().fetchInventory();
                    }
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.inventory.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGold),
                  );
                }
                if (provider.error != null && provider.inventory.isEmpty) {
                  return AppErrorWidget(
                    message: provider.error!,
                    onRetry: () => provider.fetchInventory(),
                  );
                }
                if (provider.inventory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.primaryGold.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No inventory items',
                          style: TextStyle(fontSize: 18, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  );
                }
                // A refresh failure with stale rows keeps the list visible
                // and surfaces the failure as a banner instead of swallowing it.
                if (provider.error != null) {
                  return Column(
                    children: [
                      ErrorBanner(message: provider.error!, onRetry: () => provider.fetchInventory()),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => provider.fetchInventory(warehouseId: _selectedWarehouseId?.toString()),
                          child: _buildInventoryList(),
                        ),
                      ),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => provider.fetchInventory(warehouseId: _selectedWarehouseId?.toString()),
                  child: _buildInventoryList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Item'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.textColor,
      ),
    );
  }

  Widget _buildInventoryList() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.inventory.length,
          itemBuilder: (context, index) {
            final item = provider.inventory[index];
            final products = context.watch<ProductProvider>().products;
            final product = products.where((p) => p.id == item.productId).firstOrNull;
            final productName = product?.description ?? 'Product #${item.productId}';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: AppTheme.goldBorderDecoration(),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGold),
                ),
                title: Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'WH #${item.warehouseId} • ${item.location}',
                  style: TextStyle(color: AppTheme.mutedText),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${item.weight ?? 0} g',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openDialog(inventoryItem: item),
                      color: AppTheme.mediumPurple,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}