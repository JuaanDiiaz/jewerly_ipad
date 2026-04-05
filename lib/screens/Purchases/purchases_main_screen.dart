import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class PurchasesMainScreen extends StatefulWidget {
  const PurchasesMainScreen({super.key});

  @override
  State<PurchasesMainScreen> createState() => _PurchasesMainScreenState();
}

class _PurchasesMainScreenState extends State<PurchasesMainScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _purchaseOrders = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPurchaseOrders();
  }

  Future<void> _fetchPurchaseOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with actual API call when endpoint is available
      // final response = await _apiService.get('/purchase-orders');
      // _purchaseOrders = (response as List).map((json) => json).toList();

      // Mock data for now
      _purchaseOrders = [
        {'id': 1, 'supplier': 'Gold Suppliers Inc.', 'date': '2024-01-15', 'total': 5000.00, 'status': 'Completed'},
        {'id': 2, 'supplier': 'Diamond World', 'date': '2024-01-20', 'total': 12000.00, 'status': 'Pending'},
        {'id': 3, 'supplier': 'Silver Express', 'date': '2024-02-01', 'total': 3500.00, 'status': 'In Transit'},
      ];
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases'),
        backgroundColor: Colors.amber[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPurchaseOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _fetchPurchaseOrders,
                )
              : _purchaseOrders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No purchase orders yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _purchaseOrders.length,
                      itemBuilder: (context, index) {
                        final order = _purchaseOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(order['status']),
                              child: const Icon(Icons.shopping_bag, color: Colors.white),
                            ),
                            title: Text(
                              order['supplier'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Date: ${order['date']}'),
                                Text('Total: \$${order['total'].toStringAsFixed(2)}'),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order['status']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order['status'],
                                style: TextStyle(
                                  color: _getStatusColor(order['status']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap: () => _showOrderDetails(order),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePurchaseOrderDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
        backgroundColor: Colors.amber[700],
      ),
    );
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

  void _showOrderDetails(Map<String, dynamic> order) {
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
                  'Purchase Order Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Order ID', '#${order['id']}'),
                _buildDetailRow('Supplier', order['supplier']),
                _buildDetailRow('Date', order['date']),
                _buildDetailRow('Status', order['status']),
                _buildDetailRow('Total', '\$${order['total'].toStringAsFixed(2)}'),
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
        content: const Text('Purchase order creation form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement purchase order creation
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchase order creation coming soon')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
