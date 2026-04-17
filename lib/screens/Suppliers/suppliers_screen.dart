import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/supplier_provider.dart';
import 'package:p_a_jewerly/models/supplier_model.dart';
import 'package:p_a_jewerly/widgets/base_screen.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchSuppliers();
    });
  }

  void _openDialog({SupplierModel? supplier}) {
    showDialog(
      context: context,
      builder: (_) => _SupplierDialog(
        supplier: supplier,
        onSave: (updatedSupplier) async {
          final provider = context.read<SupplierProvider>();
          bool success;
          if (supplier == null) {
            success = await provider.createSupplier(updatedSupplier);
          } else {
            success = await provider.updateSupplier(updatedSupplier);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              success
                  ? successSnackBar('Supplier ${supplier == null ? 'created' : 'updated'}')
                  : errorSnackBar(provider.error ?? 'Operation failed'),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(int id, String name) async {
    final confirmed = await confirmDelete(context, name, 'Supplier');
    if (confirmed && mounted) {
      context.read<SupplierProvider>().deleteSupplier(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D1B4E), Color(0xFF4A3266)],
            ),
          ),
        ),
      ),
      body: Consumer<SupplierProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.suppliers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  ElevatedButton(
                    onPressed: () => provider.fetchSuppliers(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.suppliers.isEmpty) {
            return const EmptyState(
              icon: Icons.business_outlined,
              title: 'No suppliers yet',
              subtitle: 'Tap + to add a supplier',
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
                        color: Colors.red,
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
        backgroundColor: const Color(0xFFD4AF37),
      ),
    );
  }
}

class _SupplierDialog extends StatefulWidget {
  final SupplierModel? supplier;
  final Function(SupplierModel) onSave;

  const _SupplierDialog({required this.supplier, required this.onSave});

  @override
  State<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<_SupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _clientNumberController;
  late final TextEditingController _shipViaController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _clientNumberController = TextEditingController(text: widget.supplier?.clientNumber ?? '');
    _shipViaController = TextEditingController(text: widget.supplier?.shipVia ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientNumberController.dispose();
    _shipViaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.supplier == null ? 'Add Supplier' : 'Edit Supplier'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Supplier Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientNumberController,
                decoration: const InputDecoration(labelText: 'Client Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shipViaController,
                decoration: const InputDecoration(labelText: 'Ship Via', border: OutlineInputBorder(), hintText: 'e.g., FedEx, UPS'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              widget.onSave(SupplierModel(
                id: widget.supplier?.id ?? 0,
                name: _nameController.text.trim(),
                clientNumber: _clientNumberController.text.trim(),
                shipVia: _shipViaController.text.trim(),
              ));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
