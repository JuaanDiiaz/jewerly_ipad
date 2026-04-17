import 'dart:io';
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
import 'package:p_a_jewerly/theme/app_theme.dart';
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
                // Image Carousel
                _buildProductImageCarousel(product),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImageCarousel(dynamic product) {
    final imageProvider = context.watch<ProductImageProvider>();
    final productImages = imageProvider.getImagesForProduct(product.id);
    final allImages = <String>[];

    // Add primary image first
    if (product.picture != null && product.picture.isNotEmpty) {
      allImages.add(product.picture);
    }
    // Add additional images
    for (final img in productImages) {
      if (img.imageUrl.isNotEmpty && !allImages.contains(img.imageUrl)) {
        allImages.add(img.imageUrl);
      }
    }

    if (allImages.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(Icons.shopping_bag, size: 80, color: Colors.amber[800]),
        ),
      );
    }

    return _ProductImageCarousel(images: allImages);
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
          Flexible(
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
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
    final isTablet = screenWidth > 900;

    // Calculate grid columns based on available space
    // Products get ~65% of screen, cart sidebar gets ~35%
    int crossAxisCount;
    if (screenWidth > 1400) {
      crossAxisCount = 4;
    } else if (screenWidth > 1000) {
      crossAxisCount = 3;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return Form(
      key: _formKey,
      child: Container(
        color: AppTheme.cream,
        child: Column(
          children: [
            // Header with search and filters
            _buildHeader(),
            // Main content - split view for tablets
            Expanded(
              child: isTablet
                  ? Row(
                      children: [
                        // Products grid - 65% width
                        Expanded(
                          flex: 65,
                          child: _buildProductsGrid(crossAxisCount),
                        ),
                        // Cart sidebar - 35% width, min 300, max 400
                        Container(
                          width: screenWidth * 0.35,
                          constraints: const BoxConstraints(minWidth: 300, maxWidth: 400),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(-2, 0),
                              ),
                            ],
                          ),
                          child: _buildCartPanel(),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: _buildProductsGrid(crossAxisCount)),
                        _buildBottomBar(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.point_of_sale, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'New Sale',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQuickStats(),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search products by name or ID...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, _) {
        if (salesProvider.cart.isEmpty) return const SizedBox.shrink();
        return Flexible(
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${salesProvider.cart.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${salesProvider.cartTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid(int crossAxisCount) {
    return Consumer4<SalesProvider, ProductProvider, InventoryProvider, PriceListDetailProvider>(
      builder: (context, salesProvider, productProvider, inventoryProvider, priceDetailProvider, _) {
        if (productProvider.isLoading && productProvider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
        }
        if (productProvider.error != null) {
          return _buildErrorState(productProvider.error!, () => productProvider.fetchProducts());
        }
        if (productProvider.products.isEmpty) {
          return _buildEmptyState();
        }

        final filteredProducts = _filterProducts(productProvider.products);
        final inventoryMap = <int, InventoryModel>{};
        for (final inv in inventoryProvider.inventory) {
          if (inv.productId != null && inv.warehouseId == salesProvider.selectedWarehouseId) {
            inventoryMap[inv.productId!] = inv;
          }
        }

        final productsWithInventory = filteredProducts.where((p) {
          final inv = inventoryMap[p.id];
          return inv != null && (inv.quantity ?? 0) > 0;
        }).toList();

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
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemCount: productsWithInventory.length,
          itemBuilder: (context, index) {
            final product = productsWithInventory[index];
            final inventory = inventoryMap[product.id];
            final availablePrices = priceDetailProvider.priceListDetails
                .where((d) => d.productId == product.id)
                .toList();
            final imageProvider = context.read<ProductImageProvider>();
            final productImages = imageProvider.getImagesForProduct(product.id);
            final imageUrl = product.picture ??
                (productImages.isNotEmpty ? productImages.first.imageUrl : null);

            return _ProductCard(
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
    );
  }

  Widget _buildCartPanel() {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, _) {
        return Column(
          children: [
            // Cart header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Current Sale',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${salesProvider.cart.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Warehouse selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<WarehouseProvider>(
                builder: (context, warehouseProvider, _) {
                  return DropdownButtonFormField<int?>(
                    decoration: InputDecoration(
                      labelText: 'Warehouse',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.warehouse),
                      filled: true,
                      fillColor: AppTheme.cream,
                    ),
                    value: salesProvider.selectedWarehouseId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select warehouse')),
                      ...warehouseProvider.warehouses.map((wh) {
                        return DropdownMenuItem(
                          value: wh.id,
                          child: Text(wh.name ?? 'Warehouse ${wh.id}'),
                        );
                      }),
                    ],
                    onChanged: (value) => salesProvider.setWarehouse(value),
                  );
                },
              ),
            ),
            // Cart items
            Expanded(
              child: salesProvider.cart.isEmpty
                  ? _buildEmptyCart()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: salesProvider.cart.length,
                      itemBuilder: (context, index) {
                        final item = salesProvider.cart[index];
                        return _CartItemTile(
                          item: item,
                          onRemove: () => salesProvider.removeFromCart(item.productId),
                          onQuantityChanged: (qty) {
                            // Update quantity logic would go here
                          },
                        );
                      },
                    ),
            ),
            // Cart summary
            if (salesProvider.cart.isNotEmpty) _buildCartSummary(salesProvider),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Cart is empty',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products from the grid',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(SalesProvider salesProvider) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text('\$${salesProvider.cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          // Customer
          Consumer<CustomerProvider>(
            builder: (context, customerProvider, _) {
              return SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<int?>(
                  decoration: InputDecoration(
                    labelText: 'Customer',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  value: salesProvider.selectedCustomerId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Customer', style: TextStyle(fontSize: 13))),
                    ...customerProvider.customers.map((customer) {
                      return DropdownMenuItem(
                        value: customer.id,
                        child: Text(customer.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      );
                    }),
                  ],
                  onChanged: (value) => salesProvider.setCustomer(value),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          // Payment
          Consumer<PaymentMethodProvider>(
            builder: (context, pmProvider, _) {
              return SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<int?>(
                  decoration: InputDecoration(
                    labelText: 'Payment',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  value: salesProvider.paymentMethodId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Payment', style: TextStyle(fontSize: 13))),
                    ...pmProvider.paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method.id,
                        child: Text(method.description ?? 'Method ${method.id}', style: const TextStyle(fontSize: 13)),
                      );
                    }),
                  ],
                  onChanged: (value) => salesProvider.setPaymentMethodId(value),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          // Salesperson
          TextFormField(
            controller: _salespersonController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Salesperson',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.badge, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            onChanged: (value) => salesProvider.setSalesperson(value),
          ),
          const SizedBox(height: 10),
          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_checkout, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Checkout \$${salesProvider.cartTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: SafeArea(
        top: false,
        child: Consumer<SalesProvider>(
          builder: (context, salesProvider, _) {
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: salesProvider.cart.isEmpty ? null : _showSummary,
                    icon: const Icon(Icons.shopping_cart),
                    label: Text(
                      salesProvider.cart.isEmpty
                          ? 'Cart Empty'
                          : '${salesProvider.cart.length} items - \$${salesProvider.cartTotal.toStringAsFixed(2)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _showQuickCustomerPaymentSheet(),
                    icon: const Icon(Icons.person_add, color: AppTheme.deepPurple),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No products available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showQuickCustomerPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sale Details',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Consumer<CustomerProvider>(
                  builder: (context, customerProvider, _) {
                    return DropdownButtonFormField<int?>(
                      decoration: InputDecoration(
                        labelText: 'Customer',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      value: context.read<SalesProvider>().selectedCustomerId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Select customer')),
                        ...customerProvider.customers.map((customer) {
                          return DropdownMenuItem(
                            value: customer.id,
                            child: Text(customer.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        context.read<SalesProvider>().setCustomer(value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer<PaymentMethodProvider>(
                  builder: (context, pmProvider, _) {
                    return DropdownButtonFormField<int?>(
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.payment),
                      ),
                      value: context.read<SalesProvider>().paymentMethodId,
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
                        context.read<SalesProvider>().setPaymentMethodId(value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: _salespersonController,
                    decoration: InputDecoration(
                      labelText: 'Salesperson',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.badge, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      context.read<SalesProvider>().setSalesperson(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final dynamic product;
  final InventoryModel? inventory;
  final List<PriceListDetailModel> availablePrices;
  final String? imageUrl;
  final VoidCallback onAddToCart;
  final VoidCallback onViewDetails;

  const _ProductCard({
    required this.product,
    this.inventory,
    required this.availablePrices,
    this.imageUrl,
    required this.onAddToCart,
    required this.onViewDetails,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final lowestPrice = widget.availablePrices.isNotEmpty
        ? widget.availablePrices.map((p) => p.price ?? 0).reduce((a, b) => a < b ? a : b)
        : null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onViewDetails,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        child: Card(
          elevation: _isPressed ? 2 : 4,
          shadowColor: AppTheme.deepPurple.withOpacity(0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image section
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                          ? Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                    // Price badge
                    if (lowestPrice != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryGold, AppTheme.secondaryGold],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGold.withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '\$${lowestPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    // Stock badge
                    if (widget.inventory?.quantity != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Stock: ${widget.inventory!.quantity}',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    // Quick add button
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onAddToCart,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade600, Colors.green.shade400],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info section
              Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.description ?? 'Product ${widget.product.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.inventory?.weight != null)
                      Row(
                        children: [
                          Icon(Icons.scale, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.inventory!.weight} g',
                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                          ),
                        ],
                      ),
                    if (widget.inventory?.location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.inventory!.location!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightGold.withOpacity(0.3),
            AppTheme.lightGold.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.diamond_outlined,
          size: 48,
          color: AppTheme.primaryGold.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.unitPrice.toStringAsFixed(2)} each',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            // Quantity
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: () {
                      if (item.quantity > 1) {
                        onQuantityChanged(item.quantity - 1);
                      } else {
                        onRemove();
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => onQuantityChanged(item.quantity + 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImageCarousel extends StatefulWidget {
  final List<String> images;

  const _ProductImageCarousel({required this.images});

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.lightGold),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepPurple.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final isNetwork = widget.images[index].startsWith('http');
                    return isNetwork
                        ? Image.network(widget.images[index], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder())
                        : Image.file(File(widget.images[index]), fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder());
                  },
                ),
                if (widget.images.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentIndex > 0) {
                            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.deepPurple.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_left, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentIndex < widget.images.length - 1) {
                            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.deepPurple.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentIndex;
                final isNetwork = widget.images[index].startsWith('http');
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = index);
                    _pageController.jumpToPage(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryGold : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryGold.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: isNetwork
                          ? Image.network(widget.images[index], fit: BoxFit.cover)
                          : Image.file(File(widget.images[index]), fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.lightGold.withOpacity(0.3), AppTheme.lightGold.withOpacity(0.1)],
        ),
      ),
      child: Center(
        child: Icon(Icons.diamond_outlined, size: 80, color: AppTheme.primaryGold.withOpacity(0.5)),
      ),
    );
  }
}
