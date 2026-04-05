import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/supplier_provider.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class PurchasesMainScreen extends StatefulWidget {
  const PurchasesMainScreen({super.key});

  @override
  State<PurchasesMainScreen> createState() => _PurchasesMainScreenState();
}

class _PurchasesMainScreenState extends State<PurchasesMainScreen> {
  int? _selectedSupplierId;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchSuppliers();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in transit':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        backgroundColor: Colors.amber[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status Filter',
                      border: OutlineInputBorder(),
                    ),
                    value: _statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'In Transit', child: Text('In Transit')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                    ],
                    onChanged: (value) {
                      setState(() => _statusFilter = value ?? 'All');
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SupplierProvider>(
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
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No suppliers available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add suppliers first to create purchase orders',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                // Note: This shows suppliers as a placeholder until PurchaseOrder provider is added
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = provider.suppliers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: const Icon(Icons.shopping_bag, color: Colors.blue),
                        ),
                        title: Text(
                          supplier.name ?? 'Supplier ${supplier.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (supplier.clientNumber != null && supplier.clientNumber!.isNotEmpty)
                              Text('Client #: ${supplier.clientNumber}'),
                            if (supplier.shipVia != null && supplier.shipVia!.isNotEmpty)
                              Text('Ship via: ${supplier.shipVia}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => _showSupplierDetails(supplier),
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
        onPressed: () => _showCreatePurchaseOrderDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
        backgroundColor: Colors.amber[700],
      ),
    );
  }

  void _showSupplierDetails(dynamic supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supplier Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Supplier ID', '#${supplier.id}'),
                _buildDetailRow('Name', supplier.name ?? 'N/A'),
                if (supplier.clientNumber != null && supplier.clientNumber!.isNotEmpty)
                  _buildDetailRow('Client Number', supplier.clientNumber!),
                if (supplier.shipVia != null && supplier.shipVia!.isNotEmpty)
                  _buildDetailRow('Ship Via', supplier.shipVia!),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showCreatePurchaseOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Purchase Order'),
        content: const Text('Purchase order creation requires a PurchaseOrderProvider. This feature can be added by creating a new provider similar to existing ones.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
