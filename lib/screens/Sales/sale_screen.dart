import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/sales_provider.dart';
import 'package:p_a_jewerly/providers/customer_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/providers/inventory_provider.dart';
import 'package:p_a_jewerly/providers/price_list_provider.dart';
import 'package:p_a_jewerly/providers/price_list_detail_provider.dart';
import 'package:p_a_jewerly/providers/payment_method_provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/providers/product_image_provider.dart';
import 'package:p_a_jewerly/models/inventory_model.dart';
import 'package:p_a_jewerly/models/price_list_model.dart';
import 'package:p_a_jewerly/models/price_list_detail_model.dart';
import 'package:p_a_jewerly/models/product_image_model.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  _SaleScreenState createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final _salespersonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<CustomerProvider>().fetchCustomers();
      context.read<InventoryProvider>().fetchInventory();
      context.read<PriceListProvider>().fetchPriceLists();
      context.read<PriceListDetailProvider>().fetchPriceListDetails();
      context.read<PaymentMethodProvider>().fetchPaymentMethods();
      context.read<WarehouseProvider>().fetchWarehouses();
      context.read<ProductImageProvider>().fetchAllImages();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _salespersonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(dynamic product, double price, {int maxQuantity = 0}) {
    final salesProvider = context.read<SalesProvider>();

    // Get existing cart quantity for this product
    final existingCartItem = salesProvider.cart.where((i) => i.productId == product.id).firstOrNull;
    final existingQty = existingCartItem?.quantity ?? 0;

    // Check if trying to add more than available
    if (maxQuantity > 0 && existingQty >= maxQuantity) {
      Fluttertoast.showToast(
        msg: "No more stock available for ${product.description ?? 'Product'}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    salesProvider.addToCart(CartItem(
      productId: product.id,
      productName: product.description ?? 'Product ${product.id}',
      quantity: 1,
      unitPrice: price,
      maxQuantity: maxQuantity,
    ));

    Fluttertoast.showToast(
      msg: "${product.description ?? 'Product'} added to cart",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showProductDetails(dynamic product, InventoryModel? inventory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Product Details',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_bag,
                      size: 80,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow('ID', '#${product.id}'),
                _buildDetailRow('Description', product.description ?? 'N/A'),
                _buildDetailRow(
                  'Weight',
                  inventory?.weight != null ? '${inventory!.weight} g' : 'Not specified',
                ),
                _buildDetailRow(
                  'Location',
                  inventory?.location ?? 'Not specified',
                ),
                _buildDetailRow(
                  'Warehouse',
                  inventory?.warehouseId != null ? 'WH #${inventory!.warehouseId}' : 'Not assigned',
                ),
                const SizedBox(height: 24),
                Consumer2<PriceListProvider, PriceListDetailProvider>(
                  builder: (context, priceListProvider, priceDetailProvider, _) {
                    final productPrices = priceDetailProvider.priceListDetails
                        .where((d) => d.productId == product.id)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (productPrices.isEmpty)
                          const Text(
                            'No prices available for this product',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          )
                        else
                          ...productPrices.map((priceDetail) {
                            final priceList = priceListProvider.priceLists
                                .firstWhere((pl) => pl.id == priceDetail.priceListId, orElse: () => PriceListModel(id: 0, description: 'Unknown'));
                            return Card(
                              child: ListTile(
                                title: Text(
                                  '\$${priceDetail.price?.toStringAsFixed(2) ?? "N/A"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                subtitle: Text(priceList.description),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _addToCart(product, (priceDetail.price ?? 0).toDouble());
                                  },
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _addToCart(product, 0.0);
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to Cart (Default Price)', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showSummary() {
    if (context.read<SalesProvider>().cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Add items before checkout.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<SalesProvider>(
          builder: (context, salesProvider, _) {
            return DraggableScrollableSheet(
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sale Summary',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow('Customer', _getCustomerName(salesProvider.selectedCustomerId)),
                        _buildSummaryRow('Salesperson', salesProvider.salespersonName ?? 'Not specified'),
                        _buildSummaryRow('Payment Method', _getPaymentMethodName(salesProvider.paymentMethodId)),
                        const SizedBox(height: 16),
                        const Text(
                          'Cart Items:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...salesProvider.cart.map((item) => Card(
                          child: ListTile(
                            title: Text(item.productName),
                            subtitle: Text('\$${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_shopping_cart, color: Colors.red),
                                  onPressed: () => salesProvider.removeFromCart(item.productId),
                                ),
                              ],
                            ),
                          ),
                        )),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${salesProvider.cartTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Consumer<SalesProvider>(
                          builder: (context, provider, _) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: provider.isLoading ? null : _processCheckout,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: provider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Checkout', style: TextStyle(fontSize: 16)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getCustomerName(int? customerId) {
    if (customerId == null) return 'Not selected';
    final customerProvider = context.read<CustomerProvider>();
    try {
      final customer = customerProvider.customers.firstWhere(
        (c) => c.id == customerId,
      );
      return customer.name;
    } catch (_) {
      return 'Customer #$customerId';
    }
  }

  String _getPaymentMethodName(int? methodId) {
    if (methodId == null) return 'Not selected';
    final pmProvider = context.read<PaymentMethodProvider>();
    try {
      final method = pmProvider.paymentMethods.firstWhere((m) => m.id == methodId);
      return method.description ?? 'Method #$methodId';
    } catch (_) {
      return 'Method #$methodId';
    }
  }

  Future<void> _processCheckout() async {
    final salesProvider = context.read<SalesProvider>();

    if (salesProvider.selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('Please select a customer'),
      );
      return;
    }

    if (salesProvider.paymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('Please select a payment method'),
      );
      return;
    }

    final success = await salesProvider.checkout();

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        successSnackBar('Sale completed successfully!'),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar(salesProvider.error ?? 'Failed to complete sale'),
      );
    }
  }

  List<dynamic> _filterProducts(List<dynamic> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((product) {
      final description = (product.description ?? '').toLowerCase();
      final id = product.id.toString();
      return description.contains(_searchQuery) || id.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    int crossAxisCount;
    if (screenWidth > 1000) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return Form(
      key: _formKey,
      child: Scaffold(
        body: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by product name or ID...',
                  prefixIcon: const Icon(Icons.search, color: Colors.amber),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            Expanded(
              child: Consumer4<SalesProvider, ProductProvider, InventoryProvider, PriceListDetailProvider>(
                builder: (context, salesProvider, productProvider, inventoryProvider, priceDetailProvider, _) {
                  if (productProvider.isLoading && productProvider.products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (productProvider.error != null) {
                    return AppErrorWidget(
                      message: productProvider.error!,
                      onRetry: () => productProvider.fetchProducts(),
                    );
                  }
                  if (productProvider.products.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No products available',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredProducts = _filterProducts(productProvider.products);
                  final inventoryMap = <int, InventoryModel>{};
                  for (final inv in inventoryProvider.inventory) {
                    // Only include inventory from the selected warehouse
                    if (inv.productId != null && inv.warehouseId == salesProvider.selectedWarehouseId) {
                      inventoryMap[inv.productId!] = inv;
                    }
                  }

                  // Filter to only products that have inventory with quantity > 0 in the selected warehouse
                  final productsWithInventory = filteredProducts.where((p) {
                    final inv = inventoryMap[p.id];
                    return inv != null && (inv.quantity ?? 0) > 0;
                  }).toList();

                  final priceDetails = priceDetailProvider.priceListDetails;

                  if (productsWithInventory.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            filteredProducts.isEmpty
                                ? 'No products found for "$_searchQuery"'
                                : 'No products in stock',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: screenWidth > 800 ? 16 : 10,
                      mainAxisSpacing: screenWidth > 800 ? 16 : 10,
                      childAspectRatio: isPortrait ? 0.7 : 0.85,
                    ),
                    itemCount: productsWithInventory.length,
                    itemBuilder: (context, index) {
                      final product = productsWithInventory[index];
                      final inventory = inventoryMap[product.id];
                      final availablePrices = priceDetails.where((d) => d.productId == product.id).toList();
                      // Get product image
                      final imageProvider = context.read<ProductImageProvider>();
                      final productImages = imageProvider.getImagesForProduct(product.id);
                      final imageUrl = product.picture ?? (productImages.isNotEmpty ? productImages.first.imageUrl : null);

                      return _AnimatedItemCard(
                        product: product,
                        inventory: inventory,
                        availablePrices: availablePrices,
                        imageUrl: imageUrl,
                        onAddToCart: () => _addToCart(product, 0.0, maxQuantity: inventory?.quantity ?? 0),
                        onViewDetails: () => _showProductDetails(product, inventory),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              constraints: BoxConstraints(maxHeight: screenWidth > 600 ? 180 : 220),
              padding: EdgeInsets.all(screenWidth > 800 ? 20 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Consumer<SalesProvider>(
                builder: (context, salesProvider, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (screenWidth > 600)
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Consumer<CustomerProvider>(
                                builder: (context, customerProvider, _) {
                                  return DropdownButtonFormField<int?>(
                                    decoration: const InputDecoration(
                                      labelText: 'Customer',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    value: salesProvider.selectedCustomerId,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('Select customer')),
                                      ...customerProvider.customers.map((customer) {
                                        return DropdownMenuItem(
                                          value: customer.id,
                                          child: Text(customer.name.length > 15 ? '${customer.name.substring(0, 15)}...' : customer.name),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      salesProvider.setCustomer(value);
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Consumer<WarehouseProvider>(
                                builder: (context, warehouseProvider, _) {
                                  return DropdownButtonFormField<int?>(
                                    decoration: const InputDecoration(
                                      labelText: 'Warehouse',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.warehouse),
                                    ),
                                    value: salesProvider.selectedWarehouseId,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('Select')),
                                      ...warehouseProvider.warehouses.map((wh) {
                                        return DropdownMenuItem(
                                          value: wh.id,
                                          child: Text(wh.name ?? 'Warehouse ${wh.id}'),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      salesProvider.setWarehouse(value);
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Consumer<PaymentMethodProvider>(
                                builder: (context, pmProvider, _) {
                                  return DropdownButtonFormField<int?>(
                                    decoration: const InputDecoration(
                                      labelText: 'Payment',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.payment),
                                    ),
                                    value: salesProvider.paymentMethodId,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('Select')),
                                      ...pmProvider.paymentMethods.map((method) {
                                        return DropdownMenuItem(
                                          value: method.id,
                                          child: Text(method.description ?? 'Method ${method.id}'),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      salesProvider.setPaymentMethodId(value);
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _salespersonController,
                                decoration: const InputDecoration(
                                  labelText: 'Salesperson',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.badge),
                                ),
                                onChanged: (value) {
                                  salesProvider.setSalesperson(value);
                                },
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _showSummary,
                              icon: const Icon(Icons.shopping_cart),
                              label: Text('${salesProvider.cart.length}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    decoration: const InputDecoration(
                                      labelText: 'Customer',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    value: salesProvider.selectedCustomerId,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('Select customer')),
                                      ...(context.watch<CustomerProvider>().customers.map((customer) {
                                        return DropdownMenuItem(
                                          value: customer.id,
                                          child: Text(customer.name.length > 15 ? '${customer.name.substring(0, 15)}...' : customer.name),
                                        );
                                      })),
                                    ],
                                    onChanged: (value) {
                                      salesProvider.setCustomer(value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Consumer<PaymentMethodProvider>(
                                    builder: (context, pmProvider, _) {
                                      return DropdownButtonFormField<int?>(
                                        decoration: const InputDecoration(
                                          labelText: 'Payment Method',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.payment),
                                        ),
                                        value: salesProvider.paymentMethodId,
                                        items: [
                                          const DropdownMenuItem(value: null, child: Text('Select method')),
                                          ...pmProvider.paymentMethods.map((method) {
                                            return DropdownMenuItem(
                                              value: method.id,
                                              child: Text(method.description ?? 'Method ${method.id}'),
                                            );
                                          }),
                                        ],
                                        onChanged: (value) {
                                          salesProvider.setPaymentMethodId(value);
                                        },
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Consumer<WarehouseProvider>(
                                    builder: (context, warehouseProvider, _) {
                                      return DropdownButtonFormField<int?>(
                                        decoration: const InputDecoration(
                                          labelText: 'Warehouse',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.warehouse),
                                        ),
                                        value: salesProvider.selectedWarehouseId,
                                        items: [
                                          const DropdownMenuItem(value: null, child: Text('Select')),
                                          ...warehouseProvider.warehouses.map((wh) {
                                            return DropdownMenuItem(
                                              value: wh.id,
                                              child: Text(wh.name ?? 'Warehouse ${wh.id}'),
                                            );
                                          }),
                                        ],
                                        onChanged: (value) {
                                          salesProvider.setWarehouse(value);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _salespersonController,
                                    decoration: const InputDecoration(
                                      labelText: 'Salesperson',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.badge),
                                    ),
                                    onChanged: (value) {
                                      salesProvider.setSalesperson(value);
                                    },
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _showSummary,
                                  icon: const Icon(Icons.shopping_cart),
                                  label: Text('Cart (${salesProvider.cart.length})'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedItemCard extends StatefulWidget {
  final dynamic product;
  final InventoryModel? inventory;
  final List<PriceListDetailModel> availablePrices;
  final String? imageUrl;
  final VoidCallback onAddToCart;
  final VoidCallback onViewDetails;

  const _AnimatedItemCard({
    required this.product,
    this.inventory,
    required this.availablePrices,
    this.imageUrl,
    required this.onAddToCart,
    required this.onViewDetails,
  });

  @override
  __AnimatedItemCardState createState() => __AnimatedItemCardState();
}

class __AnimatedItemCardState extends State<_AnimatedItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAddToCart() {
    widget.onAddToCart();
    setState(() {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _handleAddToCart,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: _isHovered ? 8 : 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                          ? Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.shopping_bag,
                                  size: 50,
                                  color: Colors.amber[800],
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.shopping_bag,
                                size: 50,
                                color: Colors.amber[800],
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: widget.onViewDetails,
                      tooltip: 'View Details',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.description ?? 'Product ${widget.product.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.inventory?.weight != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.scale, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.inventory!.weight} g',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    if (widget.availablePrices.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: widget.availablePrices.take(3).map((priceDetail) {
                          return Chip(
                            label: Text(
                              '\$${priceDetail.price?.toStringAsFixed(2) ?? "0.00"}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Center(
                      child: ScaleTransition(
                        scale: _animation,
                        child: ElevatedButton(
                          onPressed: _handleAddToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
