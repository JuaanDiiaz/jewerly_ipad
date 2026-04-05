import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class PricesMainScreen extends StatefulWidget {
  const PricesMainScreen({super.key});

  @override
  State<PricesMainScreen> createState() => _PricesMainScreenState();
}

class _PricesMainScreenState extends State<PricesMainScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _priceLists = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPriceLists();
  }

  Future<void> _fetchPriceLists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with actual API call when endpoint is available
      // final response = await _apiService.get('/price-lists');

      // Mock data for now
      _priceLists = [
        {'id': 1, 'name': 'Retail Prices', 'description': 'Standard retail pricing', 'items': 150, 'lastUpdated': '2024-01-15'},
        {'id': 2, 'name': 'Wholesale Prices', 'description': 'Bulk purchase pricing', 'items': 120, 'lastUpdated': '2024-01-10'},
        {'id': 3, 'name': 'VIP Prices', 'description': 'Special customer pricing', 'items': 150, 'lastUpdated': '2024-02-01'},
        {'id': 4, 'name': 'Gold Market Prices', 'description': 'Daily gold market rates', 'items': 45, 'lastUpdated': '2024-02-05'},
      ];
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPriceLists {
    if (_searchQuery.isEmpty) {
      return _priceLists;
    }
    return _priceLists.where((list) {
      return list['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             list['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Lists'),
        backgroundColor: Colors.amber[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPriceLists,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search price lists...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AppErrorWidget(
                        message: _error!,
                        onRetry: _fetchPriceLists,
                      )
                    : _filteredPriceLists.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.price_check, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No price lists found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredPriceLists.length,
                            itemBuilder: (context, index) {
                              final priceList = _filteredPriceLists[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber[100],
                                    child: const Icon(Icons.attach_money, color: Colors.amber),
                                  ),
                                  title: Text(
                                    priceList['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(priceList['description']),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text('${priceList['items']} items'),
                                          const SizedBox(width: 16),
                                          Icon(Icons.update, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text('Updated: ${priceList['lastUpdated']}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditPriceListDialog(priceList),
                                  ),
                                  onTap: () => _showPriceListDetails(priceList),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePriceListDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New List'),
        backgroundColor: Colors.amber[700],
      ),
    );
  }

  void _showPriceListDetails(Map<String, dynamic> priceList) {
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
                  'Price List Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Name', priceList['name']),
                _buildDetailRow('Description', priceList['description']),
                _buildDetailRow('Total Items', '${priceList['items']}'),
                _buildDetailRow('Last Updated', priceList['lastUpdated']),
                const SizedBox(height: 24),
                const Text(
                  'Items in this price list:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...List.generate(5, (index) => ListTile(
                  leading: const Icon(Icons.tag),
                  title: Text('Product ${index + 1}'),
                  trailing: Text(
                    '\$${(100 + index * 50).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                )),
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePriceListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Price List'),
        content: const Text('Price list creation form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Price list creation coming soon')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditPriceListDialog(Map<String, dynamic> priceList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Price List'),
        content: const Text('Price list editing form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Price list editing coming soon')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
