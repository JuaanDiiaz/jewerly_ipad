import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/price_list_detail_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class PricesMainScreen extends StatefulWidget {
  const PricesMainScreen({super.key});

  @override
  State<PricesMainScreen> createState() => _PricesMainScreenState();
}

class _PricesMainScreenState extends State<PricesMainScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PriceListDetailProvider>().fetchPriceListDetails();
    });
  }

  List<dynamic> get _filteredPriceLists {
    final provider = context.read<PriceListDetailProvider>();
    if (_searchQuery.isEmpty) {
      return provider.priceListDetails;
    }
    return provider.priceListDetails.where((item) {
      return item.productId.toString().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price List Details'),
        backgroundColor: Colors.amber[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PriceListDetailProvider>().fetchPriceListDetails(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by product ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.hairline,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: Consumer<PriceListDetailProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.priceListDetails.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null && provider.priceListDetails.isEmpty) {
                  return AppErrorWidget(
                    message: provider.error!,
                    onRetry: () => provider.fetchPriceListDetails(),
                  );
                }
                if (provider.priceListDetails.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.price_check, size: 64, color: AppTheme.mutedText),
                        SizedBox(height: 16),
                        Text(
                          'No price list details found',
                          style: TextStyle(fontSize: 18, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  );
                }
                // A refresh failure with stale rows keeps the list visible
                // and surfaces the failure as a banner instead of swallowing it.
                return Column(
                  children: [
                    if (provider.error != null)
                      ErrorBanner(
                        message: provider.error!,
                        onRetry: () => provider.fetchPriceListDetails(),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => provider.fetchPriceListDetails(),
                        child: _buildList(provider),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(PriceListDetailProvider provider) {
    final filtered = _filteredPriceLists;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.mutedText),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No price list details found' : 'No results for "$_searchQuery"',
              style: TextStyle(fontSize: 18, color: AppTheme.mutedText),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
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
              'Product ${item.productId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Price List ID: ${item.priceListId}'),
                Text('Price: \$${item.price?.toStringAsFixed(2) ?? '0.00'}'),
                if (item.validFrom != null)
                  Text('Valid from: ${item.validFrom}'),
                if (item.validTo != null)
                  Text('Valid to: ${item.validTo}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(item.id),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Price List Detail'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDetail(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDetail(int id) async {
    // The confirm dialog closed before the await; the messenger capture and
    // mounted check keep the snackbar on the right target across the gap.
    final messenger = ScaffoldMessenger.of(context);
    final success = await context
        .read<PriceListDetailProvider>()
        .deletePriceListDetail(id);
    if (!mounted) return;
    messenger.showSnackBar(
      success
          ? successSnackBar('Price list entry deleted')
          : errorSnackBar('Delete failed'),
    );
  }
}
