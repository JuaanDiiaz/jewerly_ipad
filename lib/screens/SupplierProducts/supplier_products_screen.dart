import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/supplier_product_provider.dart';
import 'package:p_a_jewerly/providers/supplier_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/models/supplier_product_model.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class SupplierProductsScreen extends StatefulWidget {
  const SupplierProductsScreen({super.key});

  @override
  State<SupplierProductsScreen> createState() => _SupplierProductsScreenState();
}

class _SupplierProductsScreenState extends State<SupplierProductsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artCodeController = TextEditingController();
  final _styleCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  int? _editingId;
  int? _selectedSupplierId;
  int? _selectedProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProductProvider>().fetchSupplierProducts();
      context.read<SupplierProvider>().fetchSuppliers();
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _artCodeController.dispose();
    _styleCodeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _openDialog({SupplierProductModel? product}) {
    _editingId = product?.id;
    _selectedSupplierId = product?.supplierId;
    _selectedProductId = product?.productId;
    _artCodeController.text = product?.artCode ?? '';
    _styleCodeController.text = product?.styleCode ?? '';
    _descriptionController.text = product?.description ?? '';
    _priceController.text = product?.price?.toString() ?? '';
    showDialog(context: context, builder: (_) => _buildDialog(product), barrierDismissible: false);
  }

  Widget _buildDialog(SupplierProductModel? product) {
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final products = context.watch<ProductProvider>().products;
    return AlertDialog(
      title: Text(product == null ? 'Add Supplier Product' : 'Edit Supplier Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedSupplierId,
                decoration: const InputDecoration(
                  labelText: 'Supplier',
                  border: OutlineInputBorder(),
                ),
                items: suppliers.map((s) {
                  return DropdownMenuItem(value: s.id, child: Text(s.name ?? 'Supplier ${s.id}'));
                }).toList(),
                onChanged: (value) => _selectedSupplierId = value,
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                ),
                items: products.map((p) {
                  return DropdownMenuItem(value: p.id, child: Text(p.description ?? 'Product ${p.id}'));
                }).toList(),
                onChanged: (value) => _selectedProductId = value,
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _artCodeController,
                decoration: const InputDecoration(
                  labelText: 'Art Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _styleCodeController,
                decoration: const InputDecoration(
                  labelText: 'Style Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
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
          onPressed: _saveSupplierProduct,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveSupplierProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = SupplierProductModel(
      id: _editingId ?? 0,
      supplierId: _selectedSupplierId,
      productId: _selectedProductId,
      artCode: _artCodeController.text.trim(),
      styleCode: _styleCodeController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
    );

    final provider = context.read<SupplierProductProvider>();
    bool success;

    if (_editingId == null) {
      success = await provider.createSupplierProduct(product);
    } else {
      success = await provider.updateSupplierProduct(product);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        success
            ? successSnackBar('Supplier product ${_editingId == null ? 'created' : 'updated'}')
            : errorSnackBar(provider.error ?? 'Operation failed'),
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Supplier Product'),
        content: const Text('Are you sure you want to delete this supplier product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SupplierProductProvider>().deleteSupplierProduct(id);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Products'),
        backgroundColor: Colors.amber[700],
      ),
      body: Consumer<SupplierProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.supplierProducts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.fetchSupplierProducts(),
            );
          }
          if (provider.supplierProducts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No supplier products', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.supplierProducts.length,
            itemBuilder: (context, index) {
              final sp = provider.supplierProducts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    child: const Icon(Icons.production_quantity_limits, color: Colors.purple),
                  ),
                  title: Text(sp.description ?? 'Product ${sp.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sp.artCode != null && sp.artCode!.isNotEmpty) Text('Art: ${sp.artCode}'),
                      if (sp.styleCode != null && sp.styleCode!.isNotEmpty) Text('Style: ${sp.styleCode}'),
                      Text('Supplier ID: ${sp.supplierId ?? 'N/A'}'),
                      Text('Product ID: ${sp.productId ?? 'N/A'}'),
                      if (sp.price != null) Text('Price: \$${sp.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openDialog(product: sp),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(sp.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}
