import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/inventory_provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class InventoryMainScreen extends StatefulWidget {
  @override
  _InventoryMainScreenState createState() => _InventoryMainScreenState();
}

class _InventoryMainScreenState extends State<InventoryMainScreen> {
  int? _selectedWarehouseId;
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _weightController = TextEditingController();
  int? _editingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchInventory();
      context.read<WarehouseProvider>().fetchWarehouses();
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _openDialog({dynamic inventoryItem}) {
    _editingId = inventoryItem?.id;
    _locationController.text = inventoryItem?.location ?? '';
    _weightController.text = inventoryItem?.weight?.toString() ?? '';
    showDialog(context: context, builder: (_) => _buildDialog(inventoryItem));
  }

  Widget _buildDialog(dynamic inventoryItem) {
    final warehouses = context.watch<WarehouseProvider>().warehouses;
    final products = context.watch<ProductProvider>().products;

    return AlertDialog(
      title: Text(inventoryItem == null ? 'Add Inventory Item' : 'Edit Inventory Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: inventoryItem?.productId ?? (products.isNotEmpty ? products.first.id : null),
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
                onChanged: (value) {},
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: inventoryItem?.warehouseId ?? (warehouses.isNotEmpty ? warehouses.first.id : null),
                decoration: const InputDecoration(
                  labelText: 'Warehouse',
                  border: OutlineInputBorder(),
                ),
                items: warehouses.map((w) {
                  return DropdownMenuItem(
                    value: w.id,
                    child: Text(w.name ?? 'Warehouse ${w.id}'),
                  );
                }).toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., A-01-01',
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
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveInventory,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveInventory() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<InventoryProvider>();
    final warehouses = context.read<WarehouseProvider>().warehouses;
    final products = context.read<ProductProvider>().products;

    final success = await provider.addInventoryItem({
      'productId': products.isNotEmpty ? products.first.id : 0,
      'warehouseId': warehouses.isNotEmpty ? warehouses.first.id : 0,
      'location': _locationController.text.trim(),
      'weight': double.tryParse(_weightController.text) ?? 0.0,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        success
            ? successSnackBar('Inventory item ${_editingId == null ? 'created' : 'updated'}')
            : errorSnackBar(provider.error ?? 'Operation failed'),
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Inventory Item'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Note: You may need to add a delete method to the provider
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: Colors.amber[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<WarehouseProvider>(
              builder: (context, warehouseProvider, _) {
                return DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Warehouse',
                    border: OutlineInputBorder(),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return AppErrorWidget(
                    message: provider.error!,
                    onRetry: () => provider.fetchInventory(),
                  );
                }
                if (provider.inventory.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No inventory items', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.inventory.length,
                  itemBuilder: (context, index) {
                    final item = provider.inventory[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: const Icon(Icons.inventory, color: Colors.blue),
                        ),
                        title: Text('Product ${item.productId}'),
                        subtitle: Text('Warehouse ${item.warehouseId} • Location: ${item.location}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${item.weight ?? 0} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openDialog(inventoryItem: item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}
