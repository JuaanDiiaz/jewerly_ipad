import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/supplier_provider.dart';
import 'package:p_a_jewerly/models/supplier_model.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clientNumberController = TextEditingController();
  final _shipViaController = TextEditingController();
  int? _editingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchSuppliers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientNumberController.dispose();
    _shipViaController.dispose();
    super.dispose();
  }

  void _openDialog({SupplierModel? supplier}) {
    _editingId = supplier?.id;
    _nameController.text = supplier?.name ?? '';
    _clientNumberController.text = supplier?.clientNumber ?? '';
    _shipViaController.text = supplier?.shipVia ?? '';
    showDialog(context: context, builder: (_) => _buildDialog(supplier));
  }

  Widget _buildDialog(SupplierModel? supplier) {
    return AlertDialog(
      title: Text(supplier == null ? 'Add Supplier' : 'Edit Supplier'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Supplier Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientNumberController,
                decoration: const InputDecoration(
                  labelText: 'Client Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shipViaController,
                decoration: const InputDecoration(
                  labelText: 'Ship Via',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., FedEx, UPS, DHL',
                ),
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
          onPressed: _saveSupplier,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    final supplier = SupplierModel(
      id: _editingId ?? 0,
      name: _nameController.text.trim(),
      clientNumber: _clientNumberController.text.trim(),
      shipVia: _shipViaController.text.trim(),
    );

    final provider = context.read<SupplierProvider>();
    bool success;

    if (_editingId == null) {
      success = await provider.createSupplier(supplier);
    } else {
      success = await provider.updateSupplier(supplier);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        success
            ? successSnackBar('Supplier ${_editingId == null ? 'created' : 'updated'}')
            : errorSnackBar(provider.error ?? 'Operation failed'),
      );
    }
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SupplierProvider>().deleteSupplier(id);
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
        title: const Text('Suppliers'),
        backgroundColor: Colors.amber[700],
      ),
      body: Consumer<SupplierProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.suppliers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.fetchSuppliers(),
            );
          }
          if (provider.suppliers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No suppliers yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.suppliers.length,
            itemBuilder: (context, index) {
              final supplier = provider.suppliers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.business, color: Colors.blue),
                  ),
                  title: Text(supplier.name ?? 'Supplier ${supplier.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (supplier.clientNumber != null && supplier.clientNumber!.isNotEmpty)
                        Text('Client #: ${supplier.clientNumber}'),
                      if (supplier.shipVia != null && supplier.shipVia!.isNotEmpty)
                        Text('Ship via: ${supplier.shipVia}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openDialog(supplier: supplier),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(supplier.id, supplier.name ?? ''),
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
        label: const Text('New Supplier'),
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}
