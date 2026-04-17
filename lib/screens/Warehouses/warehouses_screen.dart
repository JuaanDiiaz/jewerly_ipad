import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/widgets/base_screen.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseProvider>().fetchWarehouses();
    });
  }

  void _openDialog({int? id, String? name}) {
    showDialog(
      context: context,
      builder: (_) => FormDialog(
        title: id == null ? 'Add Warehouse' : 'Edit Warehouse',
        labelText: 'Warehouse Name',
        initialValue: name,
        onSave: (value) async {
          final provider = context.read<WarehouseProvider>();
          bool success;
          if (id == null) {
            success = await provider.createWarehouse(value);
          } else {
            success = await provider.updateWarehouse(id, value);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              success
                  ? successSnackBar('Warehouse ${id == null ? 'created' : 'updated'}')
                  : errorSnackBar(provider.error ?? 'Operation failed'),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(int id, String name) async {
    final confirmed = await confirmDelete(context, name, 'Warehouse');
    if (confirmed && mounted) {
      context.read<WarehouseProvider>().deleteWarehouse(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouses'),
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
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.warehouses.isEmpty) {
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
                    onPressed: () => provider.fetchWarehouses(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.warehouses.isEmpty) {
            return const EmptyState(
              icon: Icons.store_outlined,
              title: 'No warehouses yet',
              subtitle: 'Tap + to add your first warehouse',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.warehouses.length,
            itemBuilder: (context, index) {
              final warehouse = provider.warehouses[index];
              return _WarehouseCard(
                warehouse: warehouse,
                onEdit: () => _openDialog(id: warehouse.id, name: warehouse.name),
                onDelete: () => _confirmDelete(warehouse.id, warehouse.name ?? ''),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Warehouse'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final dynamic warehouse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WarehouseCard({
    required this.warehouse,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D1B4E).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.store_outlined, color: Color(0xFFD4AF37)),
        ),
        title: Text(
          warehouse.name ?? 'Unnamed',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('ID: ${warehouse.id}', style: TextStyle(color: Colors.grey[600])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit, color: const Color(0xFF4A3266)),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete, color: Colors.red),
          ],
        ),
      ),
    );
  }
}
